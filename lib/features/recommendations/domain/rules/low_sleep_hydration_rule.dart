import 'package:polaris/features/lifestyle/domain/value_objects/log_category.dart';
import 'package:polaris/features/recommendations/domain/entities/insight_spec.dart';
import 'package:polaris/features/recommendations/domain/rules/recommendation_rule.dart';
import 'package:polaris/features/recommendations/domain/snapshot/lifestyle_snapshot.dart';
import 'package:polaris/features/recommendations/domain/value_objects/insight_severity.dart';

/// Cross-category rule: short sleep + low hydration compound.
///
/// Fires when, in the last [windowDays] days:
///   - the user logged sleep on at least [minSampleDays] of them,
///   - average sleep across those nights is below [minHours],
///   - they also logged water on at least [minSampleDays] of them,
///   - and average water (per active day) is below [waterFloor]
///     glasses.
///
/// Rationale: dehydration amplifies the cognitive cost of poor
/// sleep (headache, focus dip). The nudge is "drink one extra glass
/// today" — small, actionable, free.
///
/// This is the first rule that pulls signal from *two* categories
/// at once; the snapshot abstraction already supports this cleanly
/// without any builder changes.
class LowSleepHydrationRule implements RecommendationRule {
  const LowSleepHydrationRule({
    this.minHours = 6.0,
    this.waterFloor = 5.0,
    this.minSampleDays = 3,
    this.windowDays = 3,
  });

  final double minHours;
  final double waterFloor;
  final int minSampleDays;
  final int windowDays;

  @override
  String get id => 'low_sleep_hydration';

  @override
  InsightSpec? evaluate(LifestyleSnapshot snapshot) {
    final int sleepDays = snapshot.activeDays(
      LogCategory.sleep,
      days: windowDays,
    );
    if (sleepDays < minSampleDays) return null;
    final double? avgSleep = snapshot.averagePerActiveDay(
      LogCategory.sleep,
      days: windowDays,
    );
    if (avgSleep == null || avgSleep >= minHours) return null;

    final int waterDays = snapshot.activeDays(
      LogCategory.water,
      days: windowDays,
    );
    if (waterDays < minSampleDays) return null;
    final double? avgWater = snapshot.averagePerActiveDay(
      LogCategory.water,
      days: windowDays,
    );
    if (avgWater == null || avgWater >= waterFloor) return null;

    return InsightSpec(
      id: id,
      contentKey: 'low_sleep_hydration',
      severity: InsightSeverity.warn,
      // Lean into water as the actionable side — sleep "fix"
      // happens at night and Lifestyle Hydration is one tap away.
      relatedCategory: LogCategory.water,
      ctaRoute: '/lifestyle',
      dismissCooldown: const Duration(days: 2),
      args: <String, Object>{
        'avgSleep': avgSleep,
        'avgWater': avgWater,
        'minHours': minHours,
      },
    );
  }
}
