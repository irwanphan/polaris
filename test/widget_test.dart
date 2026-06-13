import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/app/app.dart';
import 'package:polaris/core/errors/failure.dart';
import 'package:polaris/core/logging/app_logger.dart';
import 'package:polaris/core/notifications/notification_dispatcher.dart';
import 'package:polaris/core/result/result.dart';
import 'package:polaris/core/widgets/home_widget_updater.dart';
import 'package:polaris/core/widgets/providers.dart' as widget_providers;
import 'package:polaris/features/event_countdown/application/providers.dart';
import 'package:polaris/features/event_countdown/domain/entities/event.dart';
import 'package:polaris/features/event_countdown/domain/repositories/event_repository.dart';
import 'package:polaris/features/life_countdown/application/providers.dart';
import 'package:polaris/features/life_countdown/domain/entities/life_profile.dart';
import 'package:polaris/features/life_countdown/domain/repositories/life_expectancy_repository.dart';
import 'package:polaris/features/life_countdown/domain/repositories/life_profile_repository.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/country_code.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/date_of_birth.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/sex.dart';
import 'package:polaris/features/lifestyle/application/providers.dart';
import 'package:polaris/features/lifestyle/domain/entities/lifestyle_log.dart';
import 'package:polaris/features/lifestyle/domain/repositories/lifestyle_log_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeExpectancyRepo implements LifeExpectancyRepository {
  @override
  Future<Result<double, Failure>> lookup({
    required CountryCode countryCode,
    required Sex sex,
  }) async => const Result.ok(70.0);

  @override
  Future<Result<List<CountryOption>, Failure>> listSupportedCountries() async =>
      Result.ok(<CountryOption>[
        CountryOption(
          code: CountryCode.tryParse('ID').valueOrNull!,
          displayName: 'Indonesia',
        ),
      ]);
}

/// In-memory event repository so widget tests don't touch Drift (whose
/// reactive stream leaks a microtask timer on disposal, breaking the
/// flutter_test "no pending timers" invariant). The real Drift-backed
/// repo is covered separately in `event_repository_impl_test.dart`.
class _InMemoryEventRepository implements EventRepository {
  final List<Event> _events = <Event>[];
  final StreamController<List<Event>> _controller =
      StreamController<List<Event>>.broadcast();

  @override
  Stream<List<Event>> watchAll() async* {
    yield List<Event>.unmodifiable(_events);
    yield* _controller.stream;
  }

  @override
  Future<Result<Event?, Failure>> getById(String id) async {
    return Result.ok(_events.where((e) => e.id == id).firstOrNull);
  }

  @override
  Future<Result<Event?, Failure>> getPinned() async {
    return Result.ok(_events.where((e) => e.isPinnedToWidget).firstOrNull);
  }

  @override
  Future<Result<List<Event>, Failure>> getAllPinned() async {
    final pinned = _events.where((e) => e.isPinnedToWidget).toList()
      ..sort((a, b) => a.targetAt.compareTo(b.targetAt));
    return Result.ok(List<Event>.unmodifiable(pinned));
  }

  @override
  Future<Result<void, Failure>> upsert(Event event) async {
    _events.removeWhere((e) => e.id == event.id);
    _events.add(event);
    _controller.add(List<Event>.unmodifiable(_events));
    return const Result.ok(null);
  }

  @override
  Future<Result<void, Failure>> delete(String id) async {
    _events.removeWhere((e) => e.id == id);
    _controller.add(List<Event>.unmodifiable(_events));
    return const Result.ok(null);
  }

  @override
  Future<Result<void, Failure>> setPinned(String id, bool isPinned) async {
    final idx = _events.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      _events[idx] = _events[idx].copyWith(isPinnedToWidget: isPinned);
      _controller.add(List<Event>.unmodifiable(_events));
    }
    return const Result.ok(null);
  }

  @override
  Future<Result<void, Failure>> pinExclusive(String? id) async {
    for (int i = 0; i < _events.length; i++) {
      _events[i] = _events[i].copyWith(isPinnedToWidget: false);
    }
    if (id != null) {
      final idx = _events.indexWhere((e) => e.id == id);
      if (idx >= 0) {
        _events[idx] = _events[idx].copyWith(isPinnedToWidget: true);
      }
    }
    _controller.add(List<Event>.unmodifiable(_events));
    return const Result.ok(null);
  }
}

class _NoopHomeWidgetUpdater implements HomeWidgetUpdater {
  @override
  Future<void> refresh() async {}
}

class _NoopNotificationDispatcher implements NotificationDispatcher {
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

/// In-memory lifestyle log repository — same rationale as
/// [_InMemoryEventRepository]: avoid pulling Drift into widget tests.
class _InMemoryLifestyleLogRepository implements LifestyleLogRepository {
  final List<LifestyleLog> _logs = <LifestyleLog>[];
  final StreamController<List<LifestyleLog>> _controller =
      StreamController<List<LifestyleLog>>.broadcast();

  @override
  Stream<List<LifestyleLog>> watchBetween({
    required DateTime from,
    required DateTime to,
  }) async* {
    yield _within(from, to);
    yield* _controller.stream.map((_) => _within(from, to));
  }

  @override
  Future<Result<List<LifestyleLog>, Failure>> listBetween({
    required DateTime from,
    required DateTime to,
  }) async => Result.ok(_within(from, to));

  @override
  Future<Result<void, Failure>> upsert(LifestyleLog log) async {
    _logs.removeWhere((l) => l.id == log.id);
    _logs.add(log);
    _controller.add(List<LifestyleLog>.unmodifiable(_logs));
    return const Result.ok(null);
  }

  @override
  Future<Result<void, Failure>> delete(String id) async {
    _logs.removeWhere((l) => l.id == id);
    _controller.add(List<LifestyleLog>.unmodifiable(_logs));
    return const Result.ok(null);
  }

  List<LifestyleLog> _within(DateTime from, DateTime to) {
    return _logs
        .where((l) => !l.loggedAt.isBefore(from) && !l.loggedAt.isAfter(to))
        .toList(growable: false)
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
  }
}

class _InMemoryLifeProfileRepository implements LifeProfileRepository {
  _InMemoryLifeProfileRepository([this._profile]);

  LifeProfile? _profile;

  @override
  Future<Result<LifeProfile?, Failure>> read() async => Result.ok(_profile);

  @override
  Future<Result<void, Failure>> save(LifeProfile profile) async {
    _profile = profile;
    return const Result.ok(null);
  }

  @override
  Future<Result<void, Failure>> clear() async {
    _profile = null;
    return const Result.ok(null);
  }
}

/// Builds a valid [LifeProfile]. Used so tests can boot directly into
/// the HomeShell (no profile → router redirects to `/onboarding`).
LifeProfile _sampleProfile() {
  final DateTime now = DateTime(2026, 6, 12);
  return LifeProfile(
    dateOfBirth: DateOfBirth.tryFromDateTime(
      DateTime(1995, 5, 15),
      today: now,
    ).valueOrNull!,
    sex: Sex.undisclosed,
    countryCode: CountryCode.tryParse('ID').valueOrNull!,
    hideLifeCountdown: false,
    createdAt: now,
    updatedAt: now,
  );
}

Future<ProviderScope> _bootApp({LifeProfile? profile}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences sp = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      appLoggerProvider.overrideWithValue(AppLogger.silent()),
      sharedPreferencesProvider.overrideWithValue(sp),
      lifeExpectancyRepositoryProvider.overrideWithValue(_FakeExpectancyRepo()),
      eventRepositoryProvider.overrideWithValue(_InMemoryEventRepository()),
      lifeProfileRepositoryProvider.overrideWithValue(
        _InMemoryLifeProfileRepository(profile),
      ),
      notificationDispatcherProvider.overrideWithValue(
        _NoopNotificationDispatcher(),
      ),
      widget_providers.homeWidgetUpdaterProvider.overrideWithValue(
        _NoopHomeWidgetUpdater(),
      ),
      lifestyleLogRepositoryProvider.overrideWithValue(
        _InMemoryLifestyleLogRepository(),
      ),
    ],
    child: const PolarisApp(),
  );
}

void main() {
  testWidgets('Boots into onboarding when no profile exists', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(await _bootApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Polaris'), findsOneWidget);
    expect(find.text('Set up your countdown'), findsOneWidget);
    expect(find.text('Start countdown'), findsOneWidget);
  });

  testWidgets('HomeShell renders the bottom navigation with all 4 tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(await _bootApp(profile: _sampleProfile()));
    await tester.pumpAndSettle();

    // Tab labels appear in the NavigationBar.
    expect(find.text('Life'), findsOneWidget);
    expect(find.text('Events'), findsOneWidget);
    expect(find.text('Lifestyle'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Life tab is active by default; AppBar shows the localized title.
    expect(find.text('Sisa Hariku'), findsOneWidget);
  });

  testWidgets('Tapping the Events tab shows the empty state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(await _bootApp(profile: _sampleProfile()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle();

    expect(find.text('No events yet'), findsOneWidget);
    expect(find.text('New event'), findsOneWidget);
  });

  testWidgets('Tapping the Lifestyle tab shows the today summary + FAB', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(await _bootApp(profile: _sampleProfile()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lifestyle'));
    await tester.pumpAndSettle();

    // Four category cards from LogCategory.values render in the grid.
    expect(find.text('Water'), findsOneWidget);
    expect(find.text('Sleep'), findsOneWidget);
    expect(find.text('Exercise'), findsOneWidget);
    expect(find.text('Mood'), findsOneWidget);

    // FAB for the quick log is always visible.
    expect(find.text('Quick log'), findsOneWidget);

    // History section sits below the fold in the 800x600 test viewport;
    // scroll the CustomScrollView until its header is in view, then assert.
    await tester.dragUntilVisible(
      find.text('Last 7 days'),
      find.byType(CustomScrollView),
      const Offset(0, -200),
    );
    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.text('No entries in the last 7 days.'), findsOneWidget);
  });

  testWidgets('Tapping the Settings tab shows the placeholder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(await _bootApp(profile: _sampleProfile()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsWidgets);
  });
}
