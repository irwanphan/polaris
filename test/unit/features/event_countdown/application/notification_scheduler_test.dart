import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/core/logging/app_logger.dart';
import 'package:polaris/core/notifications/notification_dispatcher.dart';
import 'package:polaris/data/database/app_database.dart';
import 'package:polaris/features/event_countdown/application/notification_scheduler.dart';
import 'package:polaris/features/event_countdown/domain/entities/event.dart';
import 'package:polaris/features/event_countdown/domain/value_objects/recurrence.dart';
import 'package:polaris/features/event_countdown/domain/value_objects/reminder_offset.dart';

class _RecordedSchedule {
  _RecordedSchedule({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final DateTime when;
  final String title;
  final String body;
  final String? payload;
}

class _FakeDispatcher implements NotificationDispatcher {
  _FakeDispatcher();

  final List<_RecordedSchedule> scheduled = <_RecordedSchedule>[];
  final List<int> cancelled = <int>[];
  bool initialiseCalled = false;
  bool permissionGranted = true;
  Object? throwOnSchedule;

  @override
  Future<void> initialize() async {
    initialiseCalled = true;
  }

  @override
  Future<bool> ensurePermission() async => permissionGranted;

  @override
  Future<void> scheduleAt({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (throwOnSchedule != null) {
      throw throwOnSchedule!;
    }
    scheduled.add(
      _RecordedSchedule(
        id: id,
        when: when,
        title: title,
        body: body,
        payload: payload,
      ),
    );
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelled
      ..clear()
      ..addAll(scheduled.map((s) => s.id));
    scheduled.clear();
  }
}

Event _event({
  required DateTime targetAt,
  String id = 'evt-1',
  String title = 'Holiday',
  Recurrence recurrence = Recurrence.none,
}) {
  return Event(
    id: id,
    title: title,
    targetAt: targetAt,
    colorHex: '#6366F1',
    iconKey: 'event',
    recurrence: recurrence,
    isPinnedToWidget: false,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late _FakeDispatcher dispatcher;
  late NotificationScheduler scheduler;

  final DateTime now = DateTime(2026, 6, 12, 9);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dispatcher = _FakeDispatcher();
    scheduler = NotificationScheduler(
      dispatcher: dispatcher,
      dao: db.notificationsDao,
      logger: AppLogger.silent(),
      now: () => now,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('NotificationScheduler.rescheduleFor', () {
    test(
      'schedules all three reminders when the event is far in the future',
      () async {
        final Event event = _event(targetAt: DateTime(2026, 12, 25, 9));
        await scheduler.rescheduleFor(event);

        expect(dispatcher.scheduled, hasLength(3));
        final kinds = dispatcher.scheduled.map((s) => s.body).toList()..sort();
        expect(kinds, <String>[
          'Coming up in 1 hour',
          'Coming up in 1 week',
          'Coming up tomorrow',
        ]);
      },
    );

    test('skips offsets that already lie in the past', () async {
      final Event event = _event(targetAt: now.add(const Duration(hours: 2)));
      await scheduler.rescheduleFor(event);

      // Only T-1h fits in the [now, target] window.
      expect(dispatcher.scheduled, hasLength(1));
      expect(dispatcher.scheduled.single.body, 'Coming up in 1 hour');
    });

    test('schedules nothing when the event is already in the past', () async {
      final Event event = _event(
        targetAt: now.subtract(const Duration(days: 1)),
      );
      await scheduler.rescheduleFor(event);

      expect(dispatcher.scheduled, isEmpty);
    });

    test('records each schedule in the DAO with the matching id', () async {
      final Event event = _event(targetAt: DateTime(2026, 12, 25, 9));
      await scheduler.rescheduleFor(event);

      final rows = await db.notificationsDao.listForEvent(event.id);
      expect(rows, hasLength(3));
      final dbIds = rows.map((r) => r.id).toSet();
      final dispatchedIds = dispatcher.scheduled.map((s) => s.id).toSet();
      expect(dbIds, dispatchedIds);
    });

    test('rescheduling cancels prior schedules first (idempotent)', () async {
      final Event event = _event(targetAt: DateTime(2026, 12, 25, 9));
      await scheduler.rescheduleFor(event);
      final firstIds = dispatcher.scheduled.map((s) => s.id).toList();

      dispatcher.scheduled.clear();
      await scheduler.rescheduleFor(event);

      // First run's ids were cancelled.
      expect(dispatcher.cancelled, containsAll(firstIds));
      // Second run produced 3 fresh schedules.
      expect(dispatcher.scheduled, hasLength(3));
      // DB never accumulates stale rows.
      final rows = await db.notificationsDao.listForEvent(event.id);
      expect(rows, hasLength(3));
    });

    test('does nothing when permission is denied', () async {
      dispatcher.permissionGranted = false;
      final Event event = _event(targetAt: DateTime(2026, 12, 25, 9));
      await scheduler.rescheduleFor(event);

      expect(dispatcher.scheduled, isEmpty);
      final rows = await db.notificationsDao.listForEvent(event.id);
      expect(rows, isEmpty);
    });

    test(
      'uses the next yearly recurrence rather than the past targetAt',
      () async {
        // Birthday in 1990 — next occurrence after `now` (2026-06-12) is
        // 2026-12-25, so T-1w / T-1d / T-1h all fit.
        final Event event = _event(
          targetAt: DateTime(1990, 12, 25, 9),
          recurrence: Recurrence.yearly,
        );
        await scheduler.rescheduleFor(event);

        expect(dispatcher.scheduled, hasLength(3));
        for (final s in dispatcher.scheduled) {
          expect(s.when.year, 2026);
          expect(s.when.month, 12);
        }
      },
    );

    test('rolls back the DB row when the dispatcher throws', () async {
      dispatcher.throwOnSchedule = StateError('plugin offline');
      final Event event = _event(targetAt: DateTime(2026, 12, 25, 9));
      await scheduler.rescheduleFor(event);

      expect(dispatcher.scheduled, isEmpty);
      final rows = await db.notificationsDao.listForEvent(event.id);
      expect(rows, isEmpty);
    });

    test('uses ReminderOffset metadata for all enum values', () {
      expect(ReminderOffset.values, hasLength(3));
      expect(ReminderOffset.oneWeek.before, const Duration(days: 7));
      expect(ReminderOffset.oneDay.before, const Duration(days: 1));
      expect(ReminderOffset.oneHour.before, const Duration(hours: 1));
    });
  });

  group('NotificationScheduler.cancelFor', () {
    test('cancels every notification and deletes its DB rows', () async {
      final Event event = _event(targetAt: DateTime(2026, 12, 25, 9));
      await scheduler.rescheduleFor(event);
      final scheduledIds = dispatcher.scheduled
          .map((s) => s.id)
          .toList(growable: false);

      await scheduler.cancelFor(event.id);

      expect(dispatcher.cancelled, containsAll(scheduledIds));
      final rows = await db.notificationsDao.listForEvent(event.id);
      expect(rows, isEmpty);
    });

    test('is a no-op when no schedules exist', () async {
      await scheduler.cancelFor('unknown-id');
      expect(dispatcher.cancelled, isEmpty);
    });
  });
}
