import 'package:polaris/features/life_countdown/domain/entities/life_estimate.dart';
import 'package:polaris/features/recommendations/domain/entities/insight.dart';
import 'package:polaris/features/recommendations/domain/rules/recommendation_rule.dart';
import 'package:polaris/features/recommendations/domain/snapshot/lifestyle_snapshot.dart';
import 'package:polaris/features/recommendations/domain/value_objects/insight_severity.dart';

/// "You've lived ~25 / 50 / 75 / 90% of your expected life".
///
/// Picks the highest threshold the user has crossed and emits a
/// gentle, reflective nudge. We don't re-fire every day — the M5
/// surface is stateless and shows whatever the rule returns each
/// time the snapshot is recomputed; rate-limiting belongs in a
/// future "dismiss this card" / cooldown layer (M6).
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
  Insight? evaluate(LifestyleSnapshot snapshot) {
    final LifeEstimate? est = snapshot.lifeEstimate;
    if (est == null) return null;

    final double pct = est.percentLived;
    double? matched;
    for (final double t in thresholds) {
      if (pct >= t) matched = t;
    }
    if (matched == null) return null;

    return Insight(
      id: id,
      severity: InsightSeverity.info,
      title:
          'You\'ve lived ${matched.toStringAsFixed(0)}% '
          'of your estimated life',
      body:
          'About ${est.remainingYears.toStringAsFixed(1)} years (~'
          '${est.remainingDays} days) on the public-table '
          'estimate. Pin one event that matters most to you.',
      ctaLabel: 'Pin an event',
      ctaRoute: '/events',
    );
  }
}
