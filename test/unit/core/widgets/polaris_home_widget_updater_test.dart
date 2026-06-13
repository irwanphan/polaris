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
  Recurrence recurrence = Recurrence.none,
  String? widgetMessage,
}) {
  return Event(
    id: id,
    title: title,
    targetAt: targetAt,
    colorHex: '#6366F1',
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

  group('PolarisHomeWidgetUpdater.refresh — event pin', () {
    test('writes the pinned event title, days, and subtitle (EN)', () async {
      final saved = _SavedData();
      final updater = await _build(
        saved: saved,
        events: _StubEventRepository(
          pinned: _event(targetAt: DateTime(2026, 6, 25, 9)),
        ),
        now: () => DateTime(2026, 6, 12, 9),
        localePref: 'en',
      );

      await updater.refresh();

      expect(saved.entries['polaris_pinned_title'], 'Concert');
      expect(saved.entries['polaris_pinned_days'], '13 days');
      expect(saved.entries['polaris_pinned_subtitle'], contains('Jun 25'));
      expect(saved.updateCalls, 1);
      expect(saved.lastAndroidName, 'PolarisWidgetProvider');
    });

    test('widgetMessage on the event overrides the auto subtitle', () async {
      final saved = _SavedData();
      final updater = await _build(
        saved: saved,
        events: _StubEventRepository(
          pinned: _event(
            targetAt: DateTime(2026, 6, 25, 9),
            recurrence: Recurrence.yearly,
            widgetMessage: "Don't forget the gift",
          ),
        ),
        now: () => DateTime(2026, 6, 12, 9),
        localePref: 'en',
      );

      await updater.refresh();

      expect(
        saved.entries['polaris_pinned_subtitle'],
        "Don't forget the gift",
      );
    });

    test('writes nulls when nothing is pinned (empty state)', () async {
      final saved = _SavedData();
      final updater = await _build(saved: saved);

      await updater.refresh();

      expect(saved.entries['polaris_pinned_title'], isNull);
      expect(saved.entries['polaris_pinned_days'], isNull);
      expect(saved.entries['polaris_pinned_subtitle'], isNull);
      expect(saved.updateCalls, 1);
    });

    test('formats "Today" when daysUntil is 0', () async {
      final saved = _SavedData();
      final updater = await _build(
        saved: saved,
        events: _StubEventRepository(
          pinned: _event(targetAt: DateTime(2026, 6, 12, 18)),
        ),
        now: () => DateTime(2026, 6, 12, 9),
        localePref: 'en',
      );

      await updater.refresh();

      expect(saved.entries['polaris_pinned_days'], 'Today');
    });

    test('appends localized recurrence label for yearly events', () async {
      final saved = _SavedData();
      final updater = await _build(
        saved: saved,
        events: _StubEventRepository(
          pinned: _event(
            targetAt: DateTime(1990, 12, 25, 9),
            recurrence: Recurrence.yearly,
          ),
        ),
        now: () => DateTime(2026, 6, 12, 9),
        localePref: 'en',
      );

      await updater.refresh();

      // Should use the next occurrence (2026-12-25), not the historic
      // 1990 birthdate.
      expect(saved.entries['polaris_pinned_subtitle'], contains('Dec 25'));
      expect(saved.entries['polaris_pinned_subtitle'], contains('Yearly'));
    });

    test('treats repository failure as empty state (does not throw)', () async {
      final saved = _SavedData();
      final updater = await _build(
        saved: saved,
        events: _StubEventRepository(
          failure: const StorageFailure(message: 'disk fire'),
        ),
      );

      await updater.refresh();

      expect(saved.entries['polaris_pinned_title'], isNull);
      expect(saved.updateCalls, 1);
    });
  });

  group('PolarisHomeWidgetUpdater.refresh — life pin priority', () {
    test('life pin wins over event pin (mutual exclusivity)', () async {
      final saved = _SavedData();
      final updater = await _build(
        saved: saved,
        events: _StubEventRepository(
          pinned: _event(targetAt: DateTime(2026, 6, 25, 9)),
        ),
        lifePin: LifePinPreferences(pinned: true),
        profile: _profile(),
        now: () => DateTime(2026, 6, 12, 9),
        localePref: 'en',
      );

      await updater.refresh();

      expect(saved.entries['polaris_pinned_title'], 'Sisa Hariku');
      // Event was Concert — must NOT leak through.
      expect(saved.entries['polaris_pinned_title'], isNot('Concert'));
      expect(saved.entries['polaris_pinned_days'], contains('days left'));
      expect(saved.entries['polaris_pinned_subtitle'], contains('Ends'));
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

      expect(
        saved.entries['polaris_pinned_subtitle'],
        'One breath at a time.',
      );
    });

    test('life pin without profile falls back to event pin', () async {
      final saved = _SavedData();
      final updater = await _build(
        saved: saved,
        events: _StubEventRepository(
          pinned: _event(
            targetAt: DateTime(2026, 6, 25, 9),
            title: 'Fallback Event',
          ),
        ),
        lifePin: LifePinPreferences(pinned: true),
        // profile: null → life estimate cannot be built.
        now: () => DateTime(2026, 6, 12, 9),
        localePref: 'en',
      );

      await updater.refresh();

      expect(saved.entries['polaris_pinned_title'], 'Fallback Event');
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

      expect(saved.entries['polaris_pinned_title'], 'Sisa Hariku');
      expect(saved.entries['polaris_pinned_days'], contains('hari lagi'));
      expect(saved.entries['polaris_pinned_subtitle'], contains('Sekitar'));
    });
  });
}
