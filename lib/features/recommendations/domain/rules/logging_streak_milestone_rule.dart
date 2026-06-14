import 'package:polaris/features/recommendations/domain/entities/insight_spec.dart';
import 'package:polaris/features/recommendations/domain/rules/recommendation_rule.dart';
import 'package:polaris/features/recommendations/domain/snapshot/lifestyle_snapshot.dart';
import 'package:polaris/features/recommendations/domain/value_objects/insight_severity.dart';

/// "You've logged every day for N days — keep going".
///
/// Celebrates *any-category* daily logging at the milestones in
/// [milestones]. Picks the largest milestone the current streak
/// reaches (so the user sees the 14-day card after they cross 14,
/// not the 7-day one again).
///
/// Each milestone has its own [InsightSpec.id] (`logging_streak:7`,
/// `:14`, …) so dismissing one doesn't silence the next. The
/// shared `contentKey` keeps l10n compact.
///
/// Snapshot window today is 14 days, so only the {7, 14} tier ever
/// fires; the larger tiers (30, 90, 365) are wired in but only
/// reachable once the snapshot window widens — they cost nothing
/// to leave here as forward-looking targets.
class LoggingStreakMilestoneRule implements RecommendationRule {
  const LoggingStreakMilestoneRule({
    this.milestones = const <int>[7, 14, 30, 90, 365],
  });

  /// Sorted ascending. We pick the largest one ≤ the current streak.
  final List<int> milestones;

  @override
  String get id => 'logging_streak';

  @override
  InsightSpec? evaluate(LifestyleSnapshot snapshot) {
    final int streak = snapshot.currentLoggingStreak();
    if (streak <= 0) return null;

    int? matched;
    for (final int m in milestones) {
      if (streak >= m) matched = m;
    }
    if (matched == null) return null;

    return InsightSpec(
      id: '$id:$matched',
      contentKey: 'logging_streak',
      severity: InsightSeverity.encourage,
      ctaRoute: '/lifestyle',
      // 14 days — milestones are sparse by design; once celebrated,
      // wait at least two weeks before re-surfacing (which only
      // happens if the streak advances to the next tier anyway).
      dismissCooldown: const Duration(days: 14),
      args: <String, Object>{'streak': matched},
    );
  }
}
