import 'package:polaris/features/lifestyle/domain/value_objects/log_category.dart';
import 'package:polaris/features/recommendations/domain/entities/insight_spec.dart';
import 'package:polaris/features/recommendations/domain/rules/recommendation_rule.dart';
import 'package:polaris/features/recommendations/domain/snapshot/lifestyle_snapshot.dart';
import 'package:polaris/features/recommendations/domain/value_objects/insight_severity.dart';

/// "Great week — you logged exercise on N of the last [windowDays]
/// days".
///
/// Positive counterweight to [ExerciseStreakRule], which only fires
/// in the *absence* of exercise. A rules deck that only ever scolds
/// gets stale; this rule celebrates consistency once it crosses
/// [minActiveDays] within the window.
///
/// Mutually exclusive with [ExerciseStreakRule] in practice (one
/// needs > 0 minutes total, the other needs N+ active days), so the
/// engine never stacks both.
class PositiveExerciseStreakRule implements RecommendationRule {
  const PositiveExerciseStreakRule({
    this.minActiveDays = 5,
    this.windowDays = 7,
  });

  /// Number of *days with at least one exercise log* required to
  /// fire. 5/7 is the conventional "active week" bar used in most
  /// public-health guidance.
  final int minActiveDays;
  final int windowDays;

  @override
  String get id => 'positive_exercise_streak';

  @override
  InsightSpec? evaluate(LifestyleSnapshot snapshot) {
    final int active = snapshot.activeDays(
      LogCategory.exercise,
      days: windowDays,
    );
    if (active < minActiveDays) return null;

    final double totalMinutes = snapshot.sumOverWindow(
      LogCategory.exercise,
      days: windowDays,
    );

    return InsightSpec(
      id: id,
      contentKey: 'positive_exercise_streak',
      severity: InsightSeverity.encourage,
      relatedCategory: LogCategory.exercise,
      ctaRoute: '/lifestyle',
      // 7 days — same cadence as the window itself; we don't want
      // to celebrate the same streak twice in one week.
      args: <String, Object>{
        'activeDays': active,
        'windowDays': windowDays,
        'totalMinutes': totalMinutes,
      },
    );
  }
}
