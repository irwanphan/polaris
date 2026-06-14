import 'package:polaris/features/life_countdown/domain/entities/life_estimate.dart';
import 'package:polaris/features/lifestyle/domain/value_objects/log_category.dart';

/// A single day's rollup for one category.
///
/// `cumulative` categories sum every entry into [value]; `snapshot`
/// categories take the latest entry of the day. [entryCount]
/// preserves the audit count regardless of aggregation.
class DailyAggregate {
  const DailyAggregate({
    required this.date,
    required this.category,
    required this.value,
    required this.entryCount,
  });

  /// Local midnight of the day this aggregate represents. Acts as
  /// the per-day map key inside [LifestyleSnapshot] — comparing
  /// `DateTime` values is structural in Dart, so two midnights for
  /// the same calendar day compare equal.
  final DateTime date;

  final LogCategory category;
  final double value;
  final int entryCount;
}

/// Pre-aggregated view of the user's lifestyle data over a fixed
/// rolling window, paired with the optional [LifeEstimate].
///
/// All recommendation rules consume *only* this snapshot — they
/// never see raw logs, the database, or providers. That makes them
/// pure functions (snapshot → insight) and trivially testable.
///
/// The builder ([SnapshotBuilder]) is responsible for shaping the
/// raw data; rules are responsible for interpreting it. Keeping
/// these concerns split lets us add a rule without touching the
/// builder, and add a data dimension without touching every rule.
class LifestyleSnapshot {
  const LifestyleSnapshot({
    required this.referenceDate,
    required this.windowDays,
    required this.dailyByCategory,
    this.lifeEstimate,
  });

  /// Local midnight of "today" — every offset (last N days, etc.)
  /// is measured backwards from here. Pinned by the builder so unit
  /// tests are deterministic.
  final DateTime referenceDate;

  /// Width of the window the snapshot covers (default 14 days). The
  /// builder fetches at least this many days; rules ask for shorter
  /// sub-windows via [_recentDays].
  final int windowDays;

  /// Per-category aggregates keyed by local midnight (`DateTime`s
  /// without time components). Missing days simply have no entry.
  final Map<LogCategory, Map<DateTime, DailyAggregate>> dailyByCategory;

  /// Snapshot of the life-countdown side of the app. Optional
  /// because the user may not have completed onboarding when the
  /// engine runs (rare in practice — the router redirects to
  /// onboarding when missing — but defensible).
  final LifeEstimate? lifeEstimate;

  // --- Query helpers -------------------------------------------------------

  /// Aggregates for the last [days] days (inclusive of today),
  /// chronological order (oldest → newest). Days with no entries
  /// are omitted; callers that need a "zero" should pad themselves.
  List<DailyAggregate> recentDays(LogCategory category, {required int days}) {
    final Map<DateTime, DailyAggregate>? perDay = dailyByCategory[category];
    if (perDay == null) return const <DailyAggregate>[];
    final DateTime cutoff = referenceDate.subtract(Duration(days: days - 1));
    final List<DailyAggregate> result =
        perDay.values
            .where((a) => !a.date.isBefore(cutoff))
            .toList(growable: false)
          ..sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  /// Calendar-day count with at least one entry in the last [days]
  /// days. Used by streak rules.
  int activeDays(LogCategory category, {required int days}) {
    return recentDays(category, days: days).length;
  }

  /// Mean value per *day with data* in the last [days] days. Returns
  /// `null` when there is no data (callers decide what that means —
  /// usually "skip this rule, not enough signal").
  double? averagePerActiveDay(LogCategory category, {required int days}) {
    final List<DailyAggregate> rows = recentDays(category, days: days);
    if (rows.isEmpty) return null;
    final double sum = rows.fold<double>(0, (acc, a) => acc + a.value);
    return sum / rows.length;
  }

  /// Sum across the last [days] days. Returns `0` when no data
  /// (different semantic from [averagePerActiveDay] — zero is a
  /// meaningful answer for "minutes exercised this week").
  double sumOverWindow(LogCategory category, {required int days}) {
    return recentDays(
      category,
      days: days,
    ).fold<double>(0, (acc, a) => acc + a.value);
  }

  /// `true` when the snapshot contains *any* entry across *any*
  /// category in the last [days] days. Drives the onboarding nudge.
  bool hasAnyLogIn({required int days}) {
    final DateTime cutoff = referenceDate.subtract(Duration(days: days - 1));
    for (final Map<DateTime, DailyAggregate> perDay in dailyByCategory.values) {
      for (final DailyAggregate a in perDay.values) {
        if (!a.date.isBefore(cutoff)) return true;
      }
    }
    return false;
  }

  /// Number of consecutive days ending at [referenceDate] (today)
  /// on which the user logged *something* in any category.
  ///
  /// Returns `0` when today has no log at all (streak breaks if
  /// the user hasn't logged today yet — a common product choice
  /// for habit-style streaks). Capped at [windowDays] because the
  /// snapshot only holds that much data; callers wanting a longer
  /// streak need a wider window.
  int currentLoggingStreak() {
    // Build a Set<DateTime> of every day-with-any-log within the
    // window so the per-day lookup is O(1) and order-independent.
    final Set<DateTime> daysWithLogs = <DateTime>{};
    for (final Map<DateTime, DailyAggregate> perDay in dailyByCategory.values) {
      daysWithLogs.addAll(perDay.keys);
    }
    if (daysWithLogs.isEmpty) return 0;

    int streak = 0;
    for (int offset = 0; offset < windowDays; offset++) {
      final DateTime day = referenceDate.subtract(Duration(days: offset));
      if (daysWithLogs.contains(day)) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
