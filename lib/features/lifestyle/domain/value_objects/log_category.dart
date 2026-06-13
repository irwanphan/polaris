/// How a [LogCategory] aggregates entries over a single day.
enum LogAggregation {
  /// Multiple entries per day are summed (water glasses, exercise
  /// minutes). The UI shows "X glasses so far" with a +1 affordance.
  cumulative,

  /// Only the latest entry per day is meaningful (sleep hours last
  /// night, today's mood rating). The UI shows the single number
  /// and offers an "Update" affordance instead of "+1".
  snapshot,
}

/// The trackable lifestyle dimensions Polaris supports in M4.
///
/// Each enum value carries its display metadata so the UI never
/// hard-codes labels or units — add a new category here once and
/// every screen picks it up automatically.
///
/// `storageKey` is the wire-stable identifier persisted in the
/// `lifestyle_logs.category` column. Never rename without a Drift
/// migration that rewrites old rows.
enum LogCategory {
  water(
    storageKey: 'water',
    label: 'Water',
    unit: 'glasses',
    aggregation: LogAggregation.cumulative,
    minValue: 0,
    maxValue: 30,
    defaultStep: 1,
    isInteger: true,
  ),
  sleep(
    storageKey: 'sleep',
    label: 'Sleep',
    unit: 'hours',
    aggregation: LogAggregation.snapshot,
    minValue: 0,
    maxValue: 24,
    defaultStep: 0.5,
    isInteger: false,
  ),
  exercise(
    storageKey: 'exercise',
    label: 'Exercise',
    unit: 'minutes',
    aggregation: LogAggregation.cumulative,
    minValue: 0,
    maxValue: 600,
    defaultStep: 5,
    isInteger: true,
  ),
  mood(
    storageKey: 'mood',
    label: 'Mood',
    unit: '/5',
    aggregation: LogAggregation.snapshot,
    minValue: 1,
    maxValue: 5,
    defaultStep: 1,
    isInteger: true,
  );

  const LogCategory({
    required this.storageKey,
    required this.label,
    required this.unit,
    required this.aggregation,
    required this.minValue,
    required this.maxValue,
    required this.defaultStep,
    required this.isInteger,
  });

  final String storageKey;
  final String label;
  final String unit;
  final LogAggregation aggregation;
  final double minValue;
  final double maxValue;
  final double defaultStep;
  final bool isInteger;

  /// Resolves [storageKey] back to a category. Returns `null` for
  /// unknown keys so the caller can decide whether to log + skip or
  /// raise — never throws so a forward-compatible DB read of an
  /// unknown row stays recoverable.
  static LogCategory? fromStorageKey(String key) {
    for (final LogCategory c in LogCategory.values) {
      if (c.storageKey == key) return c;
    }
    return null;
  }

  /// `true` when [value] falls within [minValue]..[maxValue] inclusive
  /// and respects [isInteger]. Used by the entity constructor + the
  /// UI form to gate Save.
  bool isValid(double value) {
    if (value < minValue || value > maxValue) return false;
    if (isInteger && value != value.roundToDouble()) return false;
    return true;
  }
}
