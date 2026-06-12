import 'package:drift/drift.dart';

/// Tracks every scheduled local notification.
///
/// One row per (event, offset) pair. The auto-increment primary key
/// **is** the platform notification id we hand to the OS — this lets
/// us cancel notifications later without having to remember a separate
/// mapping. Cascade-delete is enforced in code by the
/// notifications repository on event deletion.
///
/// `kind` stores the offset bucket as a stable string ("t-7d", "t-1d",
/// "t-1h"). We deliberately do **not** model rolling recurrence here:
/// the scheduler re-evaluates from `Event.nextOccurrence(now)` on every
/// upsert and every cold boot.
@DataClassName('NotificationScheduleRow')
class NotificationSchedulesTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get eventId => text()();
  TextColumn get kind => text().withLength(min: 1, max: 16)();
  IntColumn get scheduledForEpochMs => integer()();
  IntColumn get createdAtEpochMs => integer()();
}
