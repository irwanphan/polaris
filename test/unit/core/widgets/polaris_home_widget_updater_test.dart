import 'dart:convert' as convert;

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:polaris/core/errors/failure.dart';
import 'package:polaris/core/logging/app_logger.dart';
import 'package:polaris/core/result/result.dart';
import 'package:polaris/core/widgets/polaris_home_widget_updater.dart';
import 'package:polaris/features/event_countdown/domain/entities/event.dart';
import 'package:polaris/features/event_countdown/domain/repositories/event_repository.dart';
import 'package:polaris/features/event_countdown/domain/value_objects/recurrence.dart';
import 'package:polaris/features/life_countdown/data/repositories/life_pin_repository.dart';
import 'package:polaris/features/life_countdown/domain/entities/life_profile.dart';
import 'package:polaris/features/life_countdown/domain/repositories/life_expectancy_repository.dart';
import 'package:polaris/features/life_countdown/domain/repositories/life_profile_repository.dart';
import 'package:polaris/features/life_countdown/domain/usecases/compute_life_estimate.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/country_code.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/date_of_birth.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/life_pin_preferences.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/sex.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Captures every saveWidgetData call so tests can assert the wire
/// contract. Uses a Map so later writes overwrite earlier values
/// (mirrors the SharedPreferences behaviour the plugin uses).
class _SavedData {
  final Map<String, String?> entries = <String, String?>{};
  int updateCalls = 0;
  String? lastAndroidName;

  List<Map<String, Object?>> get items {
    final raw = entries[PolarisHomeWidgetUpdater.kItemsJsonKey];
    if (raw == null) return const <Map<String, Object?>>[];
    final List<dynamic> decoded = convert.json.decode(raw) as List<dynamic>;
    return decoded
        .cast<Map<String, dynamic>>()
        .map<Map<String, Object?>>(Map<String, Object?>.from)
        .toList(growable: false);
  }
}

class _StubEventRepository implements EventRepository {
  _StubEventRepository({this.pinned = const <Event>[], this.failure});

  List<Event> pinned;
  Failure? failure;

  @override
  Future<Result<Event?, Failure>> getPinned() async {
    if (failure != null) return Result.err(failure!);
    return Result.ok(pinned.isEmpty ? null : pinned.first);
  }

  @override
  Future<Result<List<Event>, Failure>> getAllPinned() async {
    if (failure != null) return Result.err(failure!);
    return Result.ok(pinned);
  }

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
  Future<Result<void, Failure>> setPinned(String id, bool isPinned) async =>
      const Result.ok(null);
  @override
  Future<Result<void, Failure>> pinExclusive(String? id) async =>
      const Result.ok(null);
}

class _StubLifeProfileRepository implements LifeProfileRepository {
  _StubLifeProfileRepository({this.profile});
  LifeProfile? profile;

  @override
  Future<Result<LifeProfile?, Failure>> read() async => Result.ok(profile);
  @override
  Future<Result<void, Failure>> save(LifeProfile profile) async =>
      const Result.ok(null);
  @override
  Future<Result<void, Failure>> clear() async => const Result.ok(null);
}

class _FakeExpectancyRepository implements LifeExpectancyRepository {
  _FakeExpectancyRepository(this.years);
  final double years;

  @override
  Future<Result<double, Failure>> lookup({
    required CountryCode countryCode,
    required Sex sex,
  }) async =>
      Result.ok(years);

  @override
  Future<Result<List<CountryOption>, Failure>> listSupportedCountries() async =>
      const Result.ok(<CountryOption>[]);
}

Event _event({
  required DateTime targetAt,
  String id = 'evt-1',
  String title = 'Concert',
  String colorHex = '#6366F1',
  Recurrence recurrence = Recurrence.none,
  String? widgetMessage,
}) {
  return Event(
    id: id,
    title: title,
    targetAt: targetAt,
    colorHex: colorHex,
    iconKey: 'event',
    recurrence: recurrence,
    isPinnedToWidget: true,
    widgetMessage: widgetMessage,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

LifeProfile _profile() {
  final dob = DateOfBirth.tryFromDateTime(
    DateTime(1990, 1, 1),
    today: DateTime(2026, 6, 12),
  ).valueOrNull!;
  return LifeProfile(
    dateOfBirth: dob,
    sex: Sex.female,
    countryCode: CountryCode.indonesia,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

Future<PolarisHomeWidgetUpdater> _build({
  required _SavedData saved,
  EventRepository? events,
  LifePinPreferences? lifePin,
  LifeProfile? profile,
  String? localePref,
  DateTime Function()? now,
}) async {
  final initialValues = <String, Object>{};
  if (localePref != null) {
    initialValues['polaris.locale.v1'] = localePref;
  }
  SharedPreferences.setMockInitialValues(initialValues);
  final prefs = await SharedPreferences.getInstance();
  final lifePinRepo = LifePinRepository(prefs);
  if (lifePin != null) {
    await lifePinRepo.save(lifePin);
  }
  return PolarisHomeWidgetUpdater(
    eventRepository: events ?? _StubEventRepository(),
    lifePinRepository: lifePinRepo,
    lifeProfileRepository: _StubLifeProfileRepository(profile: profile),
    computeLifeEstimate:
        ComputeLifeEstimate(_FakeExpectancyRepository(80)),
    sharedPreferences: prefs,
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
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeDateFormatting('id', null);
    await initializeDateFormatting('en', null);
  });

  group('PolarisHomeWidgetUpdater.refresh — event list', () {
    test('serializes a single pinned event into the items JSON (EN)',
        () async {
      final saved = _SavedData();
      final updater = await _build(
        saved: saved,
        events: _StubEventRepository(
          pinned: <Event>[_event(targetAt: DateTime(2026, 6, 25, 9))],
        ),
        now: () => DateTime(2026, 6, 12, 9),
        localePref: 'en',
      );

      await updater.refresh();

      expect(saved.items, hasLength(1));
      expect(saved.items.first['title'], 'Concert');
      expect(saved.items.first['hero'], '13 days');
      expect(saved.items.first['subtitle'], contains('Jun 25'));
      expect(saved.items.first['kind'], 'event');
      expect(saved.items.first['accent'], '#6366F1');
      expect(saved.updateCalls, 1);
      expect(saved.lastAndroidName, 'PolarisWidgetProvider');
    });

    test('widgetMessage on the event overrides the auto subtitle', () async {
      final saved = _SavedData();
      final updater = await _build(
        saved: saved,
        events: _StubEventRepository(
          pinned: <Event>[
            _event(
              targetAt: DateTime(2026, 6, 25, 9),
              recurrence: Recurrence.yearly,
              widgetMessage: "Don't forget the gift",
            ),
          ],
        ),
        now: () => DateTime(2026, 6, 12, 9),
        localePref: 'en',
      );

      await updater.refresh();

      expect(saved.items.first['subtitle'], "Don't forget the gift");
    });

    test('writes an empty items array when nothing is pinned', () async {
      final saved = _SavedData();
      final updater = await _build(saved: saved);

      await updater.refresh();

      expect(saved.items, isEmpty);
      // Empty-state text is still written so the native layout has
      // copy to render.
      expect(
        saved.entries[PolarisHomeWidgetUpdater.kEmptyTitleKey],
        isNotNull,
      );
      expect(saved.updateCalls, 1);
    });

    test('formats "Today" when daysUntil is 0', () async {
      final saved = _SavedData();
      final updater = await _build(
        saved: saved,
        events: _StubEventRepository(
          pinned: <Event>[_event(targetAt: DateTime(2026, 6, 12, 18))],
        ),
        now: () => DateTime(2026, 6, 12, 9),
        localePref: 'en',
      );

      await updater.refresh();

      expect(saved.items.first['hero'], 'Today');
    });

    test('appends localized recurrence label for yearly events', () async {
      final saved = _SavedData();
      final updater = await _build(
        saved: saved,
        events: _StubEventRepository(
          pinned: <Event>[
            _event(
              targetAt: DateTime(1990, 12, 25, 9),
              recurrence: Recurrence.yearly,
            ),
          ],
        ),
        now: () => DateTime(2026, 6, 12, 9),
        localePref: 'en',
      );

      await updater.refresh();

      // Should use the next occurrence (2026-12-25), not the historic
      // 1990 birthdate.
      expect(saved.items.first['subtitle'], contains('Dec 25'));
      expect(saved.items.first['subtitle'], contains('Yearly'));
    });

    test('treats repository failure as empty list (does not throw)', () async {
      final saved = _SavedData();
      final updater = await _build(
        saved: saved,
        events: _StubEventRepository(
          failure: const StorageFailure(message: 'disk fire'),
        ),
      );

      await updater.refresh();

      expect(saved.items, isEmpty);
      expect(saved.updateCalls, 1);
    });

    test('serializes multiple pinned events preserving repo order',
        () async {
      final saved = _SavedData();
      final updater = await _build(
        saved: saved,
        events: _StubEventRepository(
          pinned: <Event>[
            _event(
              id: 'evt-soon',
              title: 'Wedding',
              targetAt: DateTime(2026, 6, 20, 9),
              colorHex: '#F472B6',
            ),
            _event(
              id: 'evt-later',
              title: 'Conference',
              targetAt: DateTime(2026, 8, 1, 9),
              colorHex: '#34D399',
            ),
          ],
        ),
        now: () => DateTime(2026, 6, 12, 9),
        localePref: 'en',
      );

      await updater.refresh();

      expect(saved.items, hasLength(2));
      expect(saved.items[0]['title'], 'Wedding');
      expect(saved.items[0]['accent'], '#F472B6');
      expect(saved.items[1]['title'], 'Conference');
      expect(saved.items[1]['accent'], '#34D399');
    });
  });

  group('PolarisHomeWidgetUpdater.refresh — life + event composition', () {
    test('life pin appears first, then events in repo order', () async {
      final saved = _SavedData();
      final updater = await _build(
        saved: saved,
        events: _StubEventRepository(
          pinned: <Event>[_event(targetAt: DateTime(2026, 6, 25, 9))],
        ),
        lifePin: LifePinPreferences(pinned: true),
        profile: _profile(),
        now: () => DateTime(2026, 6, 12, 9),
        localePref: 'en',
      );

      await updater.refresh();

      expect(saved.items, hasLength(2));
      expect(saved.items[0]['kind'], 'life');
      expect(saved.items[0]['title'], 'Sisa Hariku');
      expect(saved.items[1]['kind'], 'event');
      expect(saved.items[1]['title'], 'Concert');
    });

    test('custom life message overrides auto subtitle', () async {
      final saved = _SavedData();
      final updater = await _build(
        saved: saved,
        lifePin: LifePinPreferences(
          pinned: true,
          customMessage: 'One breath at a time.',
        ),
        profile: _profile(),
        now: () => DateTime(2026, 6, 12, 9),
        localePref: 'en',
      );

      await updater.refresh();

      expect(saved.items.first['subtitle'], 'One breath at a time.');
    });

    test('life pin without profile is silently skipped (events still emitted)',
        () async {
      final saved = _SavedData();
      final updater = await _build(
        saved: saved,
        events: _StubEventRepository(
          pinned: <Event>[
            _event(
              targetAt: DateTime(2026, 6, 25, 9),
              title: 'Fallback Event',
            ),
          ],
        ),
        lifePin: LifePinPreferences(pinned: true),
        // profile: null → life estimate cannot be built.
        now: () => DateTime(2026, 6, 12, 9),
        localePref: 'en',
      );

      await updater.refresh();

      expect(saved.items, hasLength(1));
      expect(saved.items.first['title'], 'Fallback Event');
    });

    test('Indonesian locale renders ID strings for life pin', () async {
      final saved = _SavedData();
      final updater = await _build(
        saved: saved,
        lifePin: LifePinPreferences(pinned: true),
        profile: _profile(),
        now: () => DateTime(2026, 6, 12, 9),
        localePref: 'id',
      );

      await updater.refresh();

      expect(saved.items.first['title'], 'Sisa Hariku');
      expect(saved.items.first['hero'] as String, contains('hari lagi'));
      expect(saved.items.first['subtitle'] as String, contains('Sekitar'));
    });
  });
}
