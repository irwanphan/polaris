import 'package:polaris/features/recommendations/domain/entities/insight_spec.dart';
import 'package:polaris/features/recommendations/domain/rules/recommendation_rule.dart';
import 'package:polaris/features/recommendations/domain/snapshot/lifestyle_snapshot.dart';
import 'package:polaris/features/recommendations/domain/value_objects/insight_severity.dart';

/// "Log your first entry" — gentle onboarding nudge.
///
/// Fires when the user has *no* lifestyle logs in the last
/// [windowDays] days across any category. Pairs with the
/// [ExerciseStreakRule] guard so we never stack the two together.
///
/// Dismissal cooldown is 1 day — if the user dismisses this they
/// probably just want quiet for the session, but the nudge should
/// still be available tomorrow until they actually log something.
class NoDataRule implements RecommendationRule {
  const NoDataRule({this.windowDays = 14});

  final int windowDays;

  @override
  String get id => 'no_data';

  @override
  InsightSpec? evaluate(LifestyleSnapshot snapshot) {
    if (snapshot.hasAnyLogIn(days: windowDays)) return null;

    return InsightSpec(
      id: id,
      contentKey: 'no_data',
      severity: InsightSeverity.encourage,
      ctaRoute: '/lifestyle',
      dismissCooldown: const Duration(days: 1),
    );
  }
}
