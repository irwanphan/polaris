/// How far ahead of an event the user gets reminded.
///
/// Currently a hard-coded triple (T-7d / T-1d / T-1h) matching the MVP
/// spec in `BRD §11 M2`. A future iteration will let the user
/// customize the set per-event; the enum already encodes the metadata
/// needed for that UI (label, duration, stable key).
enum ReminderOffset {
  oneWeek('t-7d', Duration(days: 7), 'in 1 week'),
  oneDay('t-1d', Duration(days: 1), 'tomorrow'),
  oneHour('t-1h', Duration(hours: 1), 'in 1 hour');

  const ReminderOffset(this.storageKey, this.before, this.humanLabel);

  /// Stable identifier persisted in the notifications table — never
  /// derived from the enum index, so reordering values is safe.
  final String storageKey;

  /// Lead time relative to the event's `nextOccurrence`.
  final Duration before;

  /// Short copy used inside the notification body.
  final String humanLabel;

  static ReminderOffset? fromStorageKey(String value) {
    for (final ReminderOffset offset in ReminderOffset.values) {
      if (offset.storageKey == value) return offset;
    }
    return null;
  }
}
