/// A snapshot of the user's life countdown at a given moment.
///
/// All fields are derived deterministically from a [LifeProfile] and a
/// `now` instant; the entity is therefore safe to recompute on every frame
/// or to cache between rebuilds.
final class LifeEstimate {
  const LifeEstimate({
    required this.referenceDate,
    required this.expectancyYears,
    required this.expectedTotalDays,
    required this.livedDays,
    required this.remainingDays,
    required this.estimatedEndDate,
  });

  /// The instant this estimate was computed (normalized to start of day).
  final DateTime referenceDate;

  /// Life expectancy in years used to derive this estimate.
  final double expectancyYears;

  /// Total expected lifespan in whole days.
  final int expectedTotalDays;

  /// Days already lived between birth and [referenceDate].
  final int livedDays;

  /// Days remaining until [estimatedEndDate], never negative.
  final int remainingDays;

  /// Estimated end-of-life date (calendar day).
  final DateTime estimatedEndDate;

  // --- Derived display helpers (cheap, kept on the entity for cohesion) --

  int get remainingWeeks => remainingDays ~/ 7;

  /// Approximate remaining months on an average-month basis (30.4375 days).
  int get remainingMonths => (remainingDays / 30.4375).floor();

  /// Approximate remaining years on a Julian-year basis (365.25 days).
  double get remainingYears => remainingDays / 365.25;

  /// Percentage of the expected lifespan already lived, 0–100.
  double get percentLived {
    if (expectedTotalDays <= 0) return 0;
    final double pct = (livedDays / expectedTotalDays) * 100.0;
    if (pct.isNaN || pct.isInfinite) return 0;
    return pct.clamp(0.0, 100.0);
  }

  /// True when the estimated end date has already passed.
  bool get isCompleted => remainingDays == 0;
}
