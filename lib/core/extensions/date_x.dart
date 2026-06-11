/// Date / time helpers used across features.
///
/// Keep this small — anything specific to a feature belongs in that
/// feature's `domain/` layer (e.g. life-expectancy math lives in
/// `features/life_countdown/domain/`).
extension DateTimeX on DateTime {
  /// `DateTime` with hour/minute/second/ms truncated to midnight, preserving
  /// the original timezone.
  DateTime get atStartOfDay => DateTime(year, month, day);

  /// `DateTime` at 23:59:59.999 on the same calendar day.
  DateTime get atEndOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Whole days between `this` and [other], ignoring time of day.
  /// Result is positive if [other] is in the future.
  int daysUntil(DateTime other) =>
      other.atStartOfDay.difference(atStartOfDay).inDays;

  /// True when `this` and [other] fall on the same calendar day.
  bool isSameDayAs(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}

extension DurationX on Duration {
  /// Returns the duration as a clamped non-negative value.
  Duration get nonNegative => isNegative ? Duration.zero : this;
}
