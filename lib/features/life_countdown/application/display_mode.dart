/// How the life-countdown screen presents the remaining lifetime.
enum DisplayMode {
  days,
  weeks,
  months,
  years,
  percent;

  String get label => switch (this) {
    DisplayMode.days => 'Days',
    DisplayMode.weeks => 'Weeks',
    DisplayMode.months => 'Months',
    DisplayMode.years => 'Years',
    DisplayMode.percent => '%',
  };
}
