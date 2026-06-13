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

/// Records every pin-related call so we can assert that
/// [EventsController] talks to the new per-event [setPinned] API
/// instead of the old exclusive entrypoint.
class _SpyEventRepo implements EventRepository {
  String? lastSetPinnedId;
  bool? lastSetPinnedValue;
  int setPinnedCalls = 0;
  int pinExclusiveCalls = 0;

  @override
  Future<Result<void, Failure>> setPinned(String id, bool isPinned) async {
    setPinnedCalls += 1;
    lastSetPinnedId = id;
    lastSetPinnedValue = isPinned;
    return const Result.ok(null);
  }

  @override
  Future<Result<void, Failure>> pinExclusive(String? id) async {
    pinExclusiveCalls += 1;
    return const Result.ok(null);
  }

  @override
  Stream<List<Event>> watchAll() => const Stream<List<Event>>.empty();
  @override
  Future<Result<Event?, Failure>> getPinned() async => const Result.ok(null);
  @override
  Future<Result<List<Event>, Failure>> getAllPinned() async =>
      const Result.ok(<Event>[]);
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
    test(
        'persists pinned + message and refreshes widget without touching events',
        () async {
      final lifeRepo = await _lifeRepo();
      final widget = _CountingWidget();
      final ctrl = LifePinController(
        lifePinRepository: lifeRepo,
        widgetUpdater: widget,
      );

      await ctrl.pin(customMessage: 'breathe in');

      final after = lifeRepo.read();
      expect(after.pinned, isTrue);
      expect(after.customMessage, 'breathe in');
      expect(widget.calls, 1);
    });

    test('whitespace-only message is normalized to null', () async {
      final lifeRepo = await _lifeRepo();
      final ctrl = LifePinController(
        lifePinRepository: lifeRepo,
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

  group('EventsController.togglePin (independent pin)', () {
    test('uses setPinned and does not invoke pinExclusive', () async {
      final widget = _CountingWidget();
      final eventRepo = _SpyEventRepo();
      final events = EventsController(eventRepo, _scheduler(), widget);

      final result = await events.togglePin(
        id: 'evt-1',
        isCurrentlyPinned: false,
      );

      expect(result.isOk, isTrue);
      expect(eventRepo.setPinnedCalls, 1);
      expect(eventRepo.lastSetPinnedId, 'evt-1');
      expect(eventRepo.lastSetPinnedValue, isTrue);
      expect(eventRepo.pinExclusiveCalls, 0,
          reason: 'multi-pin: must not use the legacy exclusive entrypoint');
      expect(widget.calls, 1);
    });

    test('toggling a currently-pinned event flips it to unpinned', () async {
      final widget = _CountingWidget();
      final eventRepo = _SpyEventRepo();
      final events = EventsController(eventRepo, _scheduler(), widget);

      await events.togglePin(id: 'evt-1', isCurrentlyPinned: true);

      expect(eventRepo.lastSetPinnedValue, isFalse);
    });

    test('pinning an event does NOT unpin the life countdown', () async {
      final lifeRepo = await _lifeRepo();
      await lifeRepo.save(
        LifePinPreferences(pinned: true, customMessage: 'grounding'),
      );
      final widget = _CountingWidget();
      final events = EventsController(_SpyEventRepo(), _scheduler(), widget);

      await events.togglePin(id: 'evt-1', isCurrentlyPinned: false);

      expect(lifeRepo.read().pinned, isTrue,
          reason:
              'life and event pins are independent — both can coexist in the widget list');
    });
  });
}
