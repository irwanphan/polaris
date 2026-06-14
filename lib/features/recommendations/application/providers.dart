import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/features/life_countdown/application/life_countdown_controller.dart';
import 'package:polaris/features/life_countdown/application/providers.dart';
import 'package:polaris/features/life_countdown/domain/entities/life_estimate.dart';
import 'package:polaris/features/lifestyle/application/providers.dart';
import 'package:polaris/features/lifestyle/domain/entities/lifestyle_log.dart';
import 'package:polaris/features/lifestyle/domain/repositories/lifestyle_log_repository.dart';
import 'package:polaris/features/recommendations/application/recommendation_engine.dart';
import 'package:polaris/features/recommendations/application/snapshot_builder.dart';
import 'package:polaris/features/recommendations/data/repositories/insight_dismissal_repository.dart';
import 'package:polaris/features/recommendations/domain/entities/insight_spec.dart';
import 'package:polaris/features/recommendations/domain/rules/exercise_streak_rule.dart';
import 'package:polaris/features/recommendations/domain/rules/life_phase_rule.dart';
import 'package:polaris/features/recommendations/domain/rules/logging_streak_milestone_rule.dart';
import 'package:polaris/features/recommendations/domain/rules/low_sleep_hydration_rule.dart';
import 'package:polaris/features/recommendations/domain/rules/mood_trend_rule.dart';
import 'package:polaris/features/recommendations/domain/rules/no_data_rule.dart';
import 'package:polaris/features/recommendations/domain/rules/positive_exercise_streak_rule.dart';
import 'package:polaris/features/recommendations/domain/rules/recommendation_rule.dart';
import 'package:polaris/features/recommendations/domain/rules/sleep_regularity_rule.dart';
import 'package:polaris/features/recommendations/domain/rules/water_target_rule.dart';
import 'package:polaris/features/recommendations/domain/snapshot/lifestyle_snapshot.dart';

/// Configured rule set the engine uses in production.
///
/// Order is irrelevant after the engine re-sorts by severity, but
/// kept thematic for readability:
///   1. Lifestyle nudges (per-category warn + positive)
///   2. Cross-category compound nudges
///   3. Streak / milestone celebrations
///   4. Meta (life phase, onboarding)
///
/// Add a rule: append it here. Engine code does not change.
final Provider<List<RecommendationRule>> defaultRuleSetProvider =
    Provider<List<RecommendationRule>>((ref) {
      return const <RecommendationRule>[
        WaterTargetRule(),
        SleepRegularityRule(),
        ExerciseStreakRule(),
        PositiveExerciseStreakRule(),
        MoodTrendRule(),
        LowSleepHydrationRule(),
        LoggingStreakMilestoneRule(),
        LifePhaseRule(),
        NoDataRule(),
      ];
    });

final Provider<SnapshotBuilder> snapshotBuilderProvider =
    Provider<SnapshotBuilder>((ref) => const SnapshotBuilder());

final Provider<RecommendationEngine> recommendationEngineProvider =
    Provider<RecommendationEngine>(
      (ref) => RecommendationEngine(ref.watch(defaultRuleSetProvider)),
    );

/// Width of the lifestyle window the engine consumes. Kept here so
/// every consumer (UI, builder, tests) sees the same value.
const int kInsightWindowDays = 14;

/// Reactive stream of the last [kInsightWindowDays] of lifestyle
/// logs. M4 exposed `weekLogsStreamProvider` (7 days); rules need a
/// wider window for trend detection so we wire a parallel
/// 14-day stream here rather than widening M4's surface.
final StreamProvider<List<LifestyleLog>> insightWindowLogsStreamProvider =
    StreamProvider<List<LifestyleLog>>((ref) {
      final DateTime now = DateTime.now();
      final DateTime endOfToday = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
      final DateTime windowStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: kInsightWindowDays - 1));

      final LifestyleLogRepository repo = ref.watch(
        lifestyleLogRepositoryProvider,
      );
      return repo.watchBetween(from: windowStart, to: endOfToday);
    });

/// Engine output — every spec the rules decided to fire, in
/// severity order. NOT filtered by dismissals; callers compose with
/// [insightDismissalsStreamProvider] when rendering.
final Provider<AsyncValue<List<InsightSpec>>> insightSpecsProvider =
    Provider<AsyncValue<List<InsightSpec>>>((ref) {
      final AsyncValue<List<LifestyleLog>> logsAsync = ref.watch(
        insightWindowLogsStreamProvider,
      );
      final AsyncValue<LifeEstimate?> estAsync = ref.watch(
        lifeCountdownControllerProvider,
      );

      if (logsAsync.isLoading) {
        return const AsyncValue<List<InsightSpec>>.loading();
      }
      if (logsAsync.hasError) {
        return AsyncValue<List<InsightSpec>>.error(
          logsAsync.error!,
          logsAsync.stackTrace ?? StackTrace.current,
        );
      }

      final SnapshotBuilder builder = ref.watch(snapshotBuilderProvider);
      final RecommendationEngine engine = ref.watch(
        recommendationEngineProvider,
      );

      final LifestyleSnapshot snapshot = builder.build(
        logs: logsAsync.value ?? const <LifestyleLog>[],
        now: DateTime.now(),
        windowDays: kInsightWindowDays,
        lifeEstimate: estAsync.value,
      );

      return AsyncValue<List<InsightSpec>>.data(engine.evaluate(snapshot));
    });

/// Single-instance [InsightDismissalRepository] backed by the
/// bootstrap-supplied [SharedPreferences].
final Provider<InsightDismissalRepository>
insightDismissalRepositoryProvider = Provider<InsightDismissalRepository>(
  (ref) => InsightDismissalRepository(ref.watch(sharedPreferencesProvider)),
);

/// Reactive snapshot of `{insightId → cooldownUntilEpochMs}`.
///
/// Re-evaluation is cheap, and downstream filtering uses the wall
/// clock so expired entries are ignored even before the underlying
/// prefs blob is rewritten.
final StreamProvider<Map<String, int>> insightDismissalsStreamProvider =
    StreamProvider<Map<String, int>>(
      (ref) => ref.watch(insightDismissalRepositoryProvider).watch(),
    );

/// Specs that survive the current dismissal filter — what the UI
/// actually renders. We do the filter here (not in the engine) so
/// the engine stays oblivious to "view state".
final Provider<AsyncValue<List<InsightSpec>>>
visibleInsightSpecsProvider = Provider<AsyncValue<List<InsightSpec>>>((ref) {
  final AsyncValue<List<InsightSpec>> specsAsync = ref.watch(
    insightSpecsProvider,
  );
  final AsyncValue<Map<String, int>> dismissalsAsync = ref.watch(
    insightDismissalsStreamProvider,
  );

  return specsAsync.whenData((List<InsightSpec> specs) {
    // Dismissals stream may still be loading on the very first
    // frame after launch — treat that as "nothing dismissed yet"
    // so the cards render immediately rather than waiting for the
    // SharedPreferences read to land.
    final Map<String, int> dismissals = dismissalsAsync.hasValue
        ? dismissalsAsync.value!
        : const <String, int>{};
    if (dismissals.isEmpty) return specs;
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    return List<InsightSpec>.unmodifiable(
      specs.where((InsightSpec s) {
        final int? until = dismissals[s.id];
        if (until == null) return true;
        return until <= nowMs; // cooldown expired → re-surface
      }),
    );
  });
});
