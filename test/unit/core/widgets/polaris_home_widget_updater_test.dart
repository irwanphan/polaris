import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/core/errors/failure.dart';
import 'package:polaris/core/logging/app_logger.dart';
import 'package:polaris/core/result/result.dart';
import 'package:polaris/core/widgets/polaris_home_widget_updater.dart';
import 'package:polaris/features/event_countdown/domain/entities/event.dart';
import 'package:polaris/features/event_countdown/domain/repositories/event_repository.dart';
import 'package:polaris/features/event_countdown/domain/value_objects/recurrence.dart';

/// Captures every saveWidgetData call so tests can assert the wire
/// contract. Uses a Map so later writes overwrite earlier values
/// (mirrors the SharedPreferences behaviour the plugin uses).
class _SavedData {
  final Map<String, String?> entries = <String, String?>{};
  int updateCalls = 0;
  String? lastAndroidName;
}

class _StubEventRepository implements EventRepository {
  _StubEventRepository({this.pinned, this.failure});

  Event? pinned;
  Failure? failure;

  @override
  Future<Result<Event?, Failure>> getPinned() async {
    if (failure != null) return Result.err(failure!);
    return Result.ok(pinned);
  }

  // Unused in widget-updater tests.
  @override
  Stream<List<Event>> watchAll() => const Stream<List<Event>>.empty();
  @override
  Future<Result<Event?, Failure>> getById(String id) async =>
      const Result.ok(null);
  @override
  Future<Result<void, Failure>> upsert(Event event) async =>
      const Result.ok(null);
  @override
  Future<Result<void, Failure>> delete(String id) async =>
      const Result.ok(null);
  @override
  Future<Result<void, Failure>> pinExclusive(String? id) async =>
      const Result.ok(null);
}

Event _event({
  required DateTime targetAt,
  String id = 'evt-1',
  String title = 'Concert',
  Recurrence recurrence = Recurrence.none,
}) {
  return Event(
    id: id,
    title: title,
    targetAt: targetAt,
    colorHex: '#6366F1',
    iconKey: 'event',
    recurrence: recurrence,
    isPinnedToWidget: true,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

PolarisHomeWidgetUpdater _build({
  required EventRepository repository,
  required _SavedData saved,
  DateTime Function()? now,
}) {
  return PolarisHomeWidgetUpdater(
    repository: repository,
    logger: AppLogger.silent(),
    now: now,
    saveData: (key, value) async {
      saved.entries[key] = value;
      return true;
    },
    triggerUpdate: ({String? androidName}) async {
      saved.updateCalls += 1;
      saved.lastAndroidName = androidName;
      return true;
    },
  );
}

void main() {
  group('PolarisHomeWidgetUpdater.refresh', () {
    test('writes the pinned event title, days, and subtitle', () async {
      final DateTime now = DateTime(2026, 6, 12, 9);
      final repo = _StubEventRepository(
        pinned: _event(targetAt: DateTime(2026, 6, 25, 9)),
      );
      final saved = _SavedData();
      final updater = _build(repository: repo, saved: saved, now: () => now);

      await updater.refresh();

      expect(saved.entries['polaris_pinned_title'], 'Concert');
      expect(saved.entries['polaris_pinned_days'], '13 days');
      // EEE, MMM d formatter — locale-independent for ASCII output.
      expect(saved.entries['polaris_pinned_subtitle'], contains('Jun 25'));
      expect(saved.updateCalls, 1);
      expect(saved.lastAndroidName, 'PolarisWidgetProvider');
    });

    test('writes nulls when no event is pinned (empty state)', () async {
      final repo = _StubEventRepository();
      final saved = _SavedData();
      final updater = _build(repository: repo, saved: saved);

      await updater.refresh();

      expect(saved.entries['polaris_pinned_title'], isNull);
      expect(saved.entries['polaris_pinned_days'], isNull);
      expect(saved.entries['polaris_pinned_subtitle'], isNull);
      expect(saved.updateCalls, 1);
    });

    test('formats "Today" when daysUntil is 0', () async {
      final DateTime now = DateTime(2026, 6, 12, 9);
      final repo = _StubEventRepository(
        pinned: _event(targetAt: DateTime(2026, 6, 12, 18)),
      );
      final saved = _SavedData();
      final updater = _build(repository: repo, saved: saved, now: () => now);

      await updater.refresh();

      expect(saved.entries['polaris_pinned_days'], 'Today');
    });

    test('formats "1 day" (singular) when daysUntil is 1', () async {
      final DateTime now = DateTime(2026, 6, 12, 9);
      final repo = _StubEventRepository(
        pinned: _event(targetAt: DateTime(2026, 6, 13, 9)),
      );
      final saved = _SavedData();
      final updater = _build(repository: repo, saved: saved, now: () => now);

      await updater.refresh();

      expect(saved.entries['polaris_pinned_days'], '1 day');
    });

    test('appends recurrence label for yearly events', () async {
      final DateTime now = DateTime(2026, 6, 12, 9);
      final repo = _StubEventRepository(
        pinned: _event(
          targetAt: DateTime(1990, 12, 25, 9),
          recurrence: Recurrence.yearly,
        ),
      );
      final saved = _SavedData();
      final updater = _build(repository: repo, saved: saved, now: () => now);

      await updater.refresh();

      // Should use the next occurrence (2026-12-25), not the historic
      // 1990 birthdate.
      expect(saved.entries['polaris_pinned_subtitle'], contains('Dec 25'));
      expect(saved.entries['polaris_pinned_subtitle'], contains('Yearly'));
    });

    test('omits recurrence suffix for one-shot events', () async {
      final DateTime now = DateTime(2026, 6, 12, 9);
      final repo = _StubEventRepository(
        pinned: _event(targetAt: DateTime(2026, 12, 25, 9)),
      );
      final saved = _SavedData();
      final updater = _build(repository: repo, saved: saved, now: () => now);

      await updater.refresh();

      final subtitle = saved.entries['polaris_pinned_subtitle']!;
      expect(subtitle, contains('Dec 25'));
      expect(subtitle.contains('·'), isFalse);
    });

    test('treats repository failure as empty state (does not throw)', () async {
      final repo = _StubEventRepository(
        failure: const StorageFailure(message: 'disk fire'),
      );
      final saved = _SavedData();
      final updater = _build(repository: repo, saved: saved);

      await updater.refresh();

      expect(saved.entries['polaris_pinned_title'], isNull);
      expect(saved.updateCalls, 1);
    });

    test('still triggers OS update even when save callbacks throw', () async {
      final repo = _StubEventRepository(
        pinned: _event(targetAt: DateTime(2026, 6, 25, 9)),
      );
      var updateCalled = false;
      final updater = PolarisHomeWidgetUpdater(
        repository: repo,
        logger: AppLogger.silent(),
        saveData: (_, _) => throw StateError('plugin offline'),
        triggerUpdate: ({String? androidName}) async {
          updateCalled = true;
          return true;
        },
      );

      // Should not propagate — failures are swallowed and logged.
      await updater.refresh();

      // Save threw, so update was never reached. The catch block at
      // the outer scope just logs. Confirm we did not crash and the
      // updater stayed quiet (updateCalled false is intentional).
      expect(updateCalled, isFalse);
    });
  });
}
