import 'package:polaris/features/life_countdown/domain/entities/life_estimate.dart';
import 'package:polaris/features/recommendations/domain/entities/insight_spec.dart';
import 'package:polaris/features/recommendations/domain/rules/recommendation_rule.dart';
import 'package:polaris/features/recommendations/domain/snapshot/lifestyle_snapshot.dart';
import 'package:polaris/features/recommendations/domain/value_objects/insight_severity.dart';

/// "You've lived ~25 / 50 / 75 / 90% of your expected life".
///
/// Picks the highest threshold the user has crossed and emits a
/// gentle, reflective nudge. Each threshold gets its own [InsightSpec.id]
/// (`life_phase:25`, `life_phase:50`, …) so dismissing the 25%
/// milestone does NOT silence the 50% one when it eventually
/// arrives. The shared `contentKey: 'life_phase'` keeps l10n
/// templating in one bucket.
///
/// Skipped entirely when there is no [LifeEstimate] (router would
/// have redirected to onboarding anyway) or when `percentLived` is
/// below the smallest threshold.
class LifePhaseRule implements RecommendationRule {
  const LifePhaseRule({this.thresholds = const <double>[25, 50, 75, 90]});

  /// Sorted ascending. We use the largest one ≤ `percentLived`.
  final List<double> thresholds;

  @override
  String get id => 'life_phase';

  @override
  InsightSpec? evaluate(LifestyleSnapshot snapshot) {
    final LifeEstimate? est = snapshot.lifeEstimate;
    if (est == null) return null;

    final double pct = est.percentLived;
    double? matched;
    for (final double t in thresholds) {
      if (pct >= t) matched = t;
    }
    if (matched == null) return null;

    final int milestone = matched.toInt();
    return InsightSpec(
      id: '$id:$milestone',
      contentKey: 'life_phase',
      severity: InsightSeverity.info,
      ctaRoute: '/events',
      // 30 days — milestones change very slowly, so a once-a-month
      // re-surface keeps the moment without nagging.
      dismissCooldown: const Duration(days: 30),
      args: <String, Object>{
        'pct': milestone,
        'remainingYears': est.remainingYears,
        'remainingDays': est.remainingDays,
      },
    );
  }
}
