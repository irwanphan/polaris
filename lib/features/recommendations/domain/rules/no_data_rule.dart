import 'package:polaris/features/recommendations/domain/entities/insight.dart';
import 'package:polaris/features/recommendations/domain/rules/recommendation_rule.dart';
import 'package:polaris/features/recommendations/domain/snapshot/lifestyle_snapshot.dart';
import 'package:polaris/features/recommendations/domain/value_objects/insight_severity.dart';

/// "Log your first entry" — gentle onboarding nudge.
///
/// Fires when the user has *no* lifestyle logs in the last
/// [windowDays] days across any category. Pairs with the
/// [ExerciseStreakRule] guard so we never stack the two together.
class NoDataRule implements RecommendationRule {
  const NoDataRule({this.windowDays = 14});

  final int windowDays;

  @override
  String get id => 'no_data';

  @override
  Insight? evaluate(LifestyleSnapshot snapshot) {
    if (snapshot.hasAnyLogIn(days: windowDays)) return null;

    return Insight(
      id: id,
      severity: InsightSeverity.encourage,
      title: 'Log your first entry',
      body:
          'Polaris gets sharper once it learns your rhythm. Tap '
          '"Quick log" on the Lifestyle tab to record water, sleep, '
          'exercise, or mood.',
      ctaLabel: 'Open Lifestyle',
      ctaRoute: '/lifestyle',
    );
  }
}
