import 'package:polaris/features/lifestyle/domain/value_objects/log_category.dart';
import 'package:polaris/features/recommendations/domain/entities/insight_spec.dart';
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
  InsightSpec? evaluate(LifestyleSnapshot snapshot) {
    if (!snapshot.hasAnyLogIn(days: requireRecentActivityWindow)) return null;

    final double minutes = snapshot.sumOverWindow(
      LogCategory.exercise,
      days: windowDays,
    );
    if (minutes > 0) return null;

    return InsightSpec(
      id: id,
      contentKey: 'exercise_streak',
      severity: InsightSeverity.encourage,
      relatedCategory: LogCategory.exercise,
      ctaRoute: '/lifestyle',
      // 7 days mirrors the rule's own evaluation window — dismiss
      // once, re-evaluate at the start of the next week.
      args: <String, Object>{'windowDays': windowDays},
    );
  }
}
