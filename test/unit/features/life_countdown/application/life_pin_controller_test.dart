import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/core/errors/failure.dart';
import 'package:polaris/core/logging/app_logger.dart';
import 'package:polaris/core/notifications/notification_dispatcher.dart';
import 'package:polaris/core/result/result.dart';
import 'package:polaris/core/widgets/home_widget_updater.dart';
import 'package:polaris/data/database/app_database.dart';
import 'package:polaris/features/event_countdown/application/events_controller.dart';
import 'package:polaris/features/event_countdown/application/notification_scheduler.dart';
import 'package:polaris/features/event_countdown/domain/entities/event.dart';
import 'package:polaris/features/event_countdown/domain/repositories/event_repository.dart';
import 'package:polaris/features/life_countdown/application/life_pin_controller.dart';
import 'package:polaris/features/life_countdown/data/repositories/life_pin_repository.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/life_pin_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoopDispatcher implements NotificationDispatcher {
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> ensurePermission() async => false;
  @override
  Future<void> scheduleAt({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    String? payload,
  }) async {}
  @override
  Future<void> cancel(int id) async {}
  @override
  Future<void> cancelAll() async {}
}

/// Records every mutating call so we can assert ordering and arguments.
class _SpyEventRepo implements EventRepository {
  String? lastPinExclusiveArg;
  int pinExclusiveCalls = 0;

  @override
  Future<Result<void, Failure>> pinExclusive(String? id) async {
    pinExclusiveCalls += 1;
    lastPinExclusiveArg = id;
    return const Result.ok(null);
  }

  @override
  Stream<List<Event>> watchAll() => const Stream<List<Event>>.empty();
  @override
  Future<Result<Event?, Failure>> getPinned() async => const Result.ok(null);
  @override
  Future<Result<Event?, Failure>> getById(String id) async =>
      const Result.ok(null);
  @override
  Future<Result<void, Failure>> upsert(Event event) async =>
      const Result.ok(null);
  @override
  Future<Result<void, Failure>> delete(String id) async =>
      const Result.ok(null);
}

/// Real scheduler wired with no-op deps so the dispatcher path never
/// touches a real plugin. Only [rescheduleFor]/[cancelFor] are exercised
/// indirectly via [EventsController].
NotificationScheduler _scheduler() {
  return NotificationScheduler(
    dispatcher: _NoopDispatcher(),
    dao: AppDatabase.forTesting(NativeDatabase.memory()).notificationsDao,
    logger: AppLogger.silent(),
  );
}

class _CountingWidget implements HomeWidgetUpdater {
  int calls = 0;
  @override
  Future<void> refresh() async => calls += 1;
}

Future<LifePinRepository> _lifeRepo() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  return LifePinRepository(prefs);
}

void main() {
  // Each `_scheduler()` call constructs an in-memory AppDatabase; the
  // resulting "multiple databases" warning is benign here because each
  // is owned by exactly one isolate-local executor.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('LifePinController.pin', () {
    test('persists pinned + message, unpins events, refreshes widget',
        () async {
      final lifeRepo = await _lifeRepo();
      final eventRepo = _SpyEventRepo();
      final widget = _CountingWidget();
      final ctrl = LifePinController(
        lifePinRepository: lifeRepo,
        eventRepository: eventRepo,
        widgetUpdater: widget,
      );

      await ctrl.pin(customMessage: 'breathe in');

      final after = lifeRepo.read();
      expect(after.pinned, isTrue);
      expect(after.customMessage, 'breathe in');
      expect(eventRepo.pinExclusiveCalls, 1);
      expect(eventRepo.lastPinExclusiveArg, isNull,
          reason: 'pinExclusive(null) unpins everything');
      expect(widget.calls, 1);
    });

    test('whitespace-only message is normalized to null', () async {
      final lifeRepo = await _lifeRepo();
      final ctrl = LifePinController(
        lifePinRepository: lifeRepo,
        eventRepository: _SpyEventRepo(),
        widgetUpdater: _CountingWidget(),
      );

      await ctrl.pin(customMessage: '   ');

      expect(lifeRepo.read().customMessage, isNull);
    });
  });

  group('LifePinController.unpin', () {
    test('preserves custom message but flips pinned to false', () async {
      final lifeRepo = await _lifeRepo();
      await lifeRepo.save(
        LifePinPreferences(pinned: true, customMessage: 'one breath'),
      );
      final widget = _CountingWidget();
      final ctrl = LifePinController(
        lifePinRepository: lifeRepo,
        eventRepository: _SpyEventRepo(),
        widgetUpdater: widget,
      );

      await ctrl.unpin();

      final after = lifeRepo.read();
      expect(after.pinned, isFalse);
      expect(after.customMessage, 'one breath',
          reason: 'unpin keeps message so re-pin restores it');
      expect(widget.calls, 1);
    });
  });

  group('LifePinController.updateMessage', () {
    test('refreshes widget only when life is currently pinned', () async {
      final lifeRepo = await _lifeRepo();
      final widget = _CountingWidget();
      final ctrl = LifePinController(
        lifePinRepository: lifeRepo,
        eventRepository: _SpyEventRepo(),
        widgetUpdater: widget,
      );

      // Not pinned → message saved but widget not refreshed.
      await ctrl.updateMessage('whisper');
      expect(lifeRepo.read().customMessage, 'whisper');
      expect(widget.calls, 0);

      // Now pinned → message update refreshes the widget.
      await lifeRepo.save(
        LifePinPreferences(pinned: true, customMessage: 'whisper'),
      );
      await ctrl.updateMessage('shout');
      expect(widget.calls, 1);
    });
  });

  group('EventsController.togglePin × LifePinRepository (mutual exclusivity)',
      () {
    test('pinning an event unpins the life countdown', () async {
      final lifeRepo = await _lifeRepo();
      await lifeRepo.save(
        LifePinPreferences(pinned: true, customMessage: 'grounding'),
      );
      final widget = _CountingWidget();
      final events = EventsController(
        _SpyEventRepo(),
        _scheduler(),
        widget,
        lifeRepo,
      );

      final result = await events.togglePin(
        id: 'evt-1',
        isCurrentlyPinned: false,
      );

      expect(result.isOk, isTrue);
      expect(lifeRepo.read().pinned, isFalse,
          reason: 'mutual exclusivity: only one subject at a time');
      expect(lifeRepo.read().customMessage, 'grounding',
          reason: 'message is kept for the next pin');
      expect(widget.calls, 1);
    });

    test('unpinning an event does NOT auto-pin life', () async {
      final lifeRepo = await _lifeRepo();
      final widget = _CountingWidget();
      final events = EventsController(
        _SpyEventRepo(),
        _scheduler(),
        widget,
        lifeRepo,
      );

      await events.togglePin(id: 'evt-1', isCurrentlyPinned: true);

      expect(lifeRepo.read().pinned, isFalse);
    });
  });
}
