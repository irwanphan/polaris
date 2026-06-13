import 'package:polaris/features/lifestyle/domain/value_objects/log_category.dart';
import 'package:polaris/features/recommendations/domain/entities/insight.dart';
import 'package:polaris/features/recommendations/domain/rules/recommendation_rule.dart';
import 'package:polaris/features/recommendations/domain/snapshot/lifestyle_snapshot.dart';
import 'package:polaris/features/recommendations/domain/value_objects/insight_severity.dart';

/// "No exercise logged in the last [windowDays] days".
///
/// Soft nudge (encourage, not warn) — absence of data could also
/// mean the user exercised but didn't log. Tone reflects that.
/// Requires that the user has logged *something* lifestyle-wise in
/// the wider 14-day window; otherwise [NoDataRule] handles it more
/// generally and we don't want to double-up.
class ExerciseStreakRule implements RecommendationRule {
  const ExerciseStreakRule({
    this.windowDays = 7,
    this.requireRecentActivityWindow = 14,
  });

  final int windowDays;
  final int requireRecentActivityWindow;

  @override
  String get id => 'exercise_streak';

  @override
  Insight? evaluate(LifestyleSnapshot snapshot) {
    // Hand off to NoDataRule when the user has effectively stopped
    // using the app — avoids stacking insights on top of the
    // onboarding nudge.
    if (!snapshot.hasAnyLogIn(days: requireRecentActivityWindow)) return null;

    final double minutes = snapshot.sumOverWindow(
      LogCategory.exercise,
      days: windowDays,
    );
    if (minutes > 0) return null;

    return Insight(
      id: id,
      severity: InsightSeverity.encourage,
      relatedCategory: LogCategory.exercise,
      title: 'Move a bit this week',
      body:
          'No exercise logged in the last $windowDays days. '
          'Even a 10-minute walk counts — log it and start a streak.',
      ctaLabel: 'Log exercise',
      ctaRoute: '/lifestyle',
    );
  }
}
