import 'package:drift/drift.dart';
import 'package:polaris/core/logging/app_logger.dart';
import 'package:polaris/core/notifications/notification_dispatcher.dart';
import 'package:polaris/data/database/app_database.dart';
import 'package:polaris/data/database/daos/notifications_dao.dart';
import 'package:polaris/features/event_countdown/domain/entities/event.dart';
import 'package:polaris/features/event_countdown/domain/value_objects/reminder_offset.dart';

/// Bridges a domain [Event] and the OS notification queue.
///
/// Owns the "cancel-then-reschedule" loop so feature code (the
/// `EventsController`) never has to know about platform plumbing.
/// All persistence goes through [NotificationsDao] so the set of
/// active platform notifications can be reconstructed after a process
/// restart.
///
/// Failures are logged and swallowed: a scheduling glitch should not
/// block an event from being saved. The user's data always wins.
class NotificationScheduler {
  NotificationScheduler({
    required this.dispatcher,
    required this.dao,
    required this.logger,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final NotificationDispatcher dispatcher;
  final NotificationsDao dao;
  final AppLogger logger;
  final DateTime Function() _now;

  /// Cancels every prior schedule for [event] and queues fresh
  /// reminders for the offsets in [ReminderOffset] that still lie in
  /// the future. No-ops gracefully when the OS denies notification
  /// permission.
  Future<void> rescheduleFor(Event event) async {
    await cancelFor(event.id);

    final bool allowed = await dispatcher.ensurePermission();
    if (!allowed) {
      logger.info(
        'Notification permission not granted; skipping reminders for '
        'event "${event.title}" (${event.id}).',
      );
      return;
    }

    final DateTime now = _now();
    final DateTime next = event.nextOccurrence(now);

    for (final ReminderOffset offset in ReminderOffset.values) {
      final DateTime when = next.subtract(offset.before);
      if (!when.isAfter(now)) continue;

      int? insertedId;
      try {
        insertedId = await dao.insertReturningId(
          NotificationSchedulesTableCompanion(
            eventId: Value(event.id),
            kind: Value(offset.storageKey),
            scheduledForEpochMs: Value(when.toUtc().millisecondsSinceEpoch),
            createdAtEpochMs: Value(now.toUtc().millisecondsSinceEpoch),
          ),
        );
        await dispatcher.scheduleAt(
          id: insertedId,
          when: when,
          title: event.title,
          body: 'Coming up ${offset.humanLabel}',
          payload: event.id,
        );
      } catch (e, st) {
        logger.warn(
          'Failed to schedule ${offset.storageKey} reminder for '
          'event "${event.title}"',
          error: e,
          stackTrace: st,
        );
        // Roll back the DB row we may have inserted — keeps the
        // bookkeeping table in sync with what the OS actually knows.
        if (insertedId != null) {
          await dao.deleteById(insertedId);
        }
      }
    }
  }

  /// Cancels every notification (and DB row) for [eventId]. Safe to
  /// call when the event has no schedules.
  Future<void> cancelFor(String eventId) async {
    final List<NotificationScheduleRow> existing = await dao.listForEvent(
      eventId,
    );
    for (final NotificationScheduleRow row in existing) {
      try {
        await dispatcher.cancel(row.id);
      } catch (e, st) {
        logger.warn(
          'Failed to cancel platform notification ${row.id}',
          error: e,
          stackTrace: st,
        );
      }
    }
    await dao.deleteForEvent(eventId);
  }
}
