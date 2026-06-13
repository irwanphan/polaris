import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/features/life_countdown/application/life_countdown_controller.dart';
import 'package:polaris/features/life_countdown/domain/entities/life_estimate.dart';
import 'package:polaris/features/lifestyle/application/providers.dart';
import 'package:polaris/features/lifestyle/domain/entities/lifestyle_log.dart';
import 'package:polaris/features/lifestyle/domain/repositories/lifestyle_log_repository.dart';
import 'package:polaris/features/recommendations/application/recommendation_engine.dart';
import 'package:polaris/features/recommendations/application/snapshot_builder.dart';
import 'package:polaris/features/recommendations/domain/entities/insight.dart';
import 'package:polaris/features/recommendations/domain/rules/exercise_streak_rule.dart';
import 'package:polaris/features/recommendations/domain/rules/life_phase_rule.dart';
import 'package:polaris/features/recommendations/domain/rules/mood_trend_rule.dart';
import 'package:polaris/features/recommendations/domain/rules/no_data_rule.dart';
import 'package:polaris/features/recommendations/domain/rules/recommendation_rule.dart';
import 'package:polaris/features/recommendations/domain/rules/sleep_regularity_rule.dart';
import 'package:polaris/features/recommendations/domain/rules/water_target_rule.dart';
import 'package:polaris/features/recommendations/domain/snapshot/lifestyle_snapshot.dart';

/// Configured rule set the engine uses in production.
///
/// Add a rule: append it here. Order is irrelevant after the engine
/// re-sorts by severity, but kept thematic for readability:
/// lifestyle nudges first, then meta (life phase / onboarding).
final Provider<List<RecommendationRule>> defaultRuleSetProvider =
    Provider<List<RecommendationRule>>((ref) {
      return const <RecommendationRule>[
        WaterTargetRule(),
        SleepRegularityRule(),
        ExerciseStreakRule(),
        MoodTrendRule(),
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

/// The fully-evaluated insight feed. Recomputes whenever logs *or*
/// the life estimate change. Lazy by design — only built when the
/// UI watches it.
final Provider<AsyncValue<List<Insight>>> insightsProvider =
    Provider<AsyncValue<List<Insight>>>((ref) {
      final AsyncValue<List<LifestyleLog>> logsAsync = ref.watch(
        insightWindowLogsStreamProvider,
      );
      final AsyncValue<LifeEstimate?> estAsync = ref.watch(
        lifeCountdownControllerProvider,
      );

      // Surface the loading state of whichever upstream is still
      // pending — render once both have data.
      if (logsAsync.isLoading) {
        return const AsyncValue<List<Insight>>.loading();
      }
      if (logsAsync.hasError) {
        return AsyncValue<List<Insight>>.error(
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

      return AsyncValue<List<Insight>>.data(engine.evaluate(snapshot));
    });
