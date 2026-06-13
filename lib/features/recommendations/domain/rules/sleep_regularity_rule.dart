import 'package:polaris/features/lifestyle/domain/value_objects/log_category.dart';
import 'package:polaris/features/recommendations/domain/entities/insight.dart';
import 'package:polaris/features/recommendations/domain/rules/recommendation_rule.dart';
import 'package:polaris/features/recommendations/domain/snapshot/lifestyle_snapshot.dart';
import 'package:polaris/features/recommendations/domain/value_objects/insight_severity.dart';

/// "You've slept less than [minHours] on [shortNightThreshold]+ of
/// the last [windowDays] days".
///
/// Sleep is a snapshot category (one log per day), so the "value"
/// for each day is the latest recorded hours. We count short nights
/// rather than averaging — three terrible nights matter more than a
/// smooth average that hides them.
class SleepRegularityRule implements RecommendationRule {
  const SleepRegularityRule({
    this.minHours = 6.0,
    this.shortNightThreshold = 3,
    this.windowDays = 7,
  });

  final double minHours;
  final int shortNightThreshold;
  final int windowDays;

  @override
  String get id => 'sleep_regularity';

  @override
  Insight? evaluate(LifestyleSnapshot snapshot) {
    final List<DailyAggregate> nights = snapshot.recentDays(
      LogCategory.sleep,
      days: windowDays,
    );
    final int shortCount = nights.where((n) => n.value < minHours).length;
    if (shortCount < shortNightThreshold) return null;

    return Insight(
      id: id,
      severity: InsightSeverity.warn,
      relatedCategory: LogCategory.sleep,
      title: 'Short on sleep this week',
      body:
          '$shortCount of the last ${nights.length} logged nights '
          'were under ${minHours.toStringAsFixed(0)}h. '
          'Try an earlier wind-down tonight.',
      ctaLabel: 'Log sleep',
      ctaRoute: '/lifestyle',
    );
  }
}
