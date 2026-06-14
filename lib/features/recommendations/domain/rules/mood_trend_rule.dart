import 'package:polaris/features/lifestyle/domain/value_objects/log_category.dart';
import 'package:polaris/features/recommendations/domain/entities/insight_spec.dart';
import 'package:polaris/features/recommendations/domain/rules/recommendation_rule.dart';
import 'package:polaris/features/recommendations/domain/snapshot/lifestyle_snapshot.dart';
import 'package:polaris/features/recommendations/domain/value_objects/insight_severity.dart';

/// "Your mood has trended down for [requiredRun] consecutive logged
/// days".
///
/// Looks at the latest [requiredRun] mood entries within the window
/// and fires only when they form a strictly descending run. Strict
/// descent is intentional — flat (3,3,3) isn't a trend.
///
/// Sensitive territory: tone is supportive, not clinical, and we
/// route the CTA to logging (not to an external resource).
class MoodTrendRule implements RecommendationRule {
  const MoodTrendRule({this.requiredRun = 3, this.windowDays = 7});

  final int requiredRun;
  final int windowDays;

  @override
  String get id => 'mood_trend';

  @override
  InsightSpec? evaluate(LifestyleSnapshot snapshot) {
    final List<DailyAggregate> moods = snapshot.recentDays(
      LogCategory.mood,
      days: windowDays,
    );
    if (moods.length < requiredRun) return null;

    final List<DailyAggregate> tail = moods.sublist(moods.length - requiredRun);
    for (int i = 1; i < tail.length; i++) {
      if (tail[i].value >= tail[i - 1].value) return null;
    }

    return InsightSpec(
      id: id,
      contentKey: 'mood_trend',
      severity: InsightSeverity.warn,
      relatedCategory: LogCategory.mood,
      ctaRoute: '/lifestyle',
      dismissCooldown: const Duration(days: 3),
      args: <String, Object>{'run': requiredRun},
    );
  }
}
