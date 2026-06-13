import 'package:polaris/features/life_countdown/domain/entities/life_estimate.dart';
import 'package:polaris/features/lifestyle/domain/entities/lifestyle_log.dart';
import 'package:polaris/features/lifestyle/domain/value_objects/log_category.dart';
import 'package:polaris/features/recommendations/domain/snapshot/lifestyle_snapshot.dart';

/// Pure function: raw logs + (optional) life estimate → a
/// [LifestyleSnapshot] ready for the rule engine.
///
/// Aggregation policy per [LogAggregation]:
///   - cumulative → sum every entry that falls on the same local day
///   - snapshot   → take the entry with the latest `loggedAt`
/// Both branches still report `entryCount` so the UI / future rules
/// can distinguish "1 careful nap entry" from "5 quick taps".
///
/// Kept outside the engine so it can be unit-tested in isolation and
/// reused by other surfaces (e.g. a future weekly digest) without
/// dragging the rules along.
class SnapshotBuilder {
  const SnapshotBuilder();

  LifestyleSnapshot build({
    required List<LifestyleLog> logs,
    required DateTime now,
    int windowDays = 14,
    LifeEstimate? lifeEstimate,
  }) {
    final DateTime referenceDate = DateTime(now.year, now.month, now.day);
    final DateTime cutoff = referenceDate.subtract(
      Duration(days: windowDays - 1),
    );

    // Bucket by (category, local-day) first, then resolve the
    // aggregation rule once per bucket. Doing it in two passes
    // keeps the resolution logic in one place rather than scattered
    // through the loop.
    final Map<LogCategory, Map<DateTime, List<LifestyleLog>>> buckets =
        <LogCategory, Map<DateTime, List<LifestyleLog>>>{};

    for (final LifestyleLog log in logs) {
      final DateTime day = DateTime(
        log.loggedAt.year,
        log.loggedAt.month,
        log.loggedAt.day,
      );
      if (day.isBefore(cutoff) || day.isAfter(referenceDate)) continue;

      final Map<DateTime, List<LifestyleLog>> perDay = buckets.putIfAbsent(
        log.category,
        () => <DateTime, List<LifestyleLog>>{},
      );
      perDay.putIfAbsent(day, () => <LifestyleLog>[]).add(log);
    }

    final Map<LogCategory, Map<DateTime, DailyAggregate>> dailyByCategory =
        <LogCategory, Map<DateTime, DailyAggregate>>{};

    buckets.forEach((
      LogCategory category,
      Map<DateTime, List<LifestyleLog>> perDay,
    ) {
      final Map<DateTime, DailyAggregate> resolved =
          <DateTime, DailyAggregate>{};
      perDay.forEach((DateTime day, List<LifestyleLog> entries) {
        final double value = switch (category.aggregation) {
          LogAggregation.cumulative => entries.fold<double>(
            0,
            (acc, l) => acc + l.value,
          ),
          LogAggregation.snapshot =>
            (entries.toList()..sort(
                  (LifestyleLog a, LifestyleLog b) =>
                      b.loggedAt.compareTo(a.loggedAt),
                ))
                .first
                .value,
        };
        resolved[day] = DailyAggregate(
          date: day,
          category: category,
          value: value,
          entryCount: entries.length,
        );
      });
      dailyByCategory[category] = resolved;
    });

    return LifestyleSnapshot(
      referenceDate: referenceDate,
      windowDays: windowDays,
      dailyByCategory: dailyByCategory,
      lifeEstimate: lifeEstimate,
    );
  }
}
