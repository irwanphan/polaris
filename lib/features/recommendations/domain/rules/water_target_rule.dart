import 'package:polaris/features/lifestyle/domain/value_objects/log_category.dart';
import 'package:polaris/features/recommendations/domain/entities/insight.dart';
import 'package:polaris/features/recommendations/domain/rules/recommendation_rule.dart';
import 'package:polaris/features/recommendations/domain/snapshot/lifestyle_snapshot.dart';
import 'package:polaris/features/recommendations/domain/value_objects/insight_severity.dart';

/// "Your weekly water average is below the target".
///
/// Fires when the user has logged on at least [minSampleDays] days
/// out of the last 7 (so we don't ship advice from a single thirsty
/// Tuesday) and their average is below [targetGlasses].
///
/// The threshold is conservative on purpose — Polaris is not a
/// medical device; we surface the gentlest actionable nudge and
/// link the CTA to the Lifestyle tab so logging more is one tap
/// away.
class WaterTargetRule implements RecommendationRule {
  const WaterTargetRule({
    this.targetGlasses = 6,
    this.minSampleDays = 3,
    this.windowDays = 7,
  });

  final double targetGlasses;
  final int minSampleDays;
  final int windowDays;

  @override
  String get id => 'water_target';

  @override
  Insight? evaluate(LifestyleSnapshot snapshot) {
    final int active = snapshot.activeDays(LogCategory.water, days: windowDays);
    if (active < minSampleDays) return null;

    final double? avg = snapshot.averagePerActiveDay(
      LogCategory.water,
      days: windowDays,
    );
    if (avg == null || avg >= targetGlasses) return null;

    return Insight(
      id: id,
      severity: InsightSeverity.warn,
      relatedCategory: LogCategory.water,
      title: 'Drink a bit more water',
      body:
          'Last $windowDays days you averaged ${avg.toStringAsFixed(1)} '
          'glasses/day. A common target is $targetGlasses+. '
          'Add a glass next break.',
      ctaLabel: 'Log water',
      ctaRoute: '/lifestyle',
    );
  }
}
