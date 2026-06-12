import 'package:drift/drift.dart';
import 'package:polaris/data/database/app_database.dart';
import 'package:polaris/data/database/tables/notification_schedules_table.dart';

part 'notifications_dao.g.dart';

/// Bookkeeping for scheduled notifications.
///
/// The DAO returns plain rows; mapping to a domain VO happens in the
/// scheduler so the rest of the app never sees Drift types.
@DriftAccessor(tables: <Type>[NotificationSchedulesTable])
class NotificationsDao extends DatabaseAccessor<AppDatabase>
    with _$NotificationsDaoMixin {
  NotificationsDao(super.db);

  /// Inserts a new schedule and returns the assigned auto-increment id
  /// (which is also the platform notification id).
  Future<int> insertReturningId(NotificationSchedulesTableCompanion row) {
    return into(notificationSchedulesTable).insert(row);
  }

  Future<List<NotificationScheduleRow>> listForEvent(String eventId) {
    return (select(notificationSchedulesTable)
          ..where((t) => t.eventId.equals(eventId)))
        .get();
  }

  Future<List<NotificationScheduleRow>> listAll() {
    return select(notificationSchedulesTable).get();
  }

  Future<int> deleteForEvent(String eventId) {
    return (delete(notificationSchedulesTable)
          ..where((t) => t.eventId.equals(eventId)))
        .go();
  }

  Future<int> deleteById(int id) {
    return (delete(notificationSchedulesTable)
          ..where((t) => t.id.equals(id)))
        .go();
  }
}
