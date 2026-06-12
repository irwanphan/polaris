/// How an [Event] repeats over time.
enum Recurrence {
  none('none', 'One-time'),
  yearly('yearly', 'Yearly'),
  monthly('monthly', 'Monthly'),
  weekly('weekly', 'Weekly');

  const Recurrence(this.storageKey, this.label);

  /// Stable string used by the database — never localized.
  final String storageKey;

  /// English UI label (l10n hook will replace this in a later milestone).
  final String label;

  static Recurrence fromStorageKey(String value) {
    return Recurrence.values.firstWhere(
      (Recurrence r) => r.storageKey == value,
      orElse: () => Recurrence.none,
    );
  }
}
