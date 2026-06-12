import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/app/app.dart';
import 'package:polaris/core/errors/failure.dart';
import 'package:polaris/core/logging/app_logger.dart';
import 'package:polaris/core/result/result.dart';
import 'package:polaris/features/event_countdown/application/providers.dart';
import 'package:polaris/features/event_countdown/domain/entities/event.dart';
import 'package:polaris/features/event_countdown/domain/repositories/event_repository.dart';
import 'package:polaris/features/life_countdown/application/providers.dart';
import 'package:polaris/features/life_countdown/domain/repositories/life_expectancy_repository.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/country_code.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/sex.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeExpectancyRepo implements LifeExpectancyRepository {
  @override
  Future<Result<double, Failure>> lookup({
    required CountryCode countryCode,
    required Sex sex,
  }) async =>
      const Result.ok(70.0);

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

Future<ProviderScope> _bootApp({Map<String, Object>? prefs}) async {
  SharedPreferences.setMockInitialValues(prefs ?? <String, Object>{});
  final SharedPreferences sp = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      appLoggerProvider.overrideWithValue(AppLogger.silent()),
      sharedPreferencesProvider.overrideWithValue(sp),
      lifeExpectancyRepositoryProvider
          .overrideWithValue(_FakeExpectancyRepo()),
      eventRepositoryProvider
          .overrideWithValue(_InMemoryEventRepository()),
    ],
    child: const PolarisApp(),
  );
}

void main() {
  testWidgets('Launcher renders title and all destinations',
      (WidgetTester tester) async {
    await tester.pumpWidget(await _bootApp());
    await tester.pumpAndSettle();

    expect(find.text('Polaris'), findsOneWidget);
    expect(find.text('Your countdown companion'), findsOneWidget);
    expect(find.text('Sisa Hariku'), findsOneWidget);
    expect(find.text('Events'), findsOneWidget);
    expect(find.text('Lifestyle'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets(
      'Tapping Sisa Hariku with no profile redirects to onboarding',
      (WidgetTester tester) async {
    await tester.pumpWidget(await _bootApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sisa Hariku'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Polaris'), findsOneWidget);
    expect(find.text('Set up your countdown'), findsOneWidget);
    expect(find.text('Start countdown'), findsOneWidget);
  });

  testWidgets('Events page shows empty state when nothing is stored',
      (WidgetTester tester) async {
    await tester.pumpWidget(await _bootApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle();

    expect(find.text('No events yet'), findsOneWidget);
    expect(find.text('New event'), findsOneWidget);
  });

  testWidgets('Lifestyle and Settings placeholder pages still render',
      (WidgetTester tester) async {
    await tester.pumpWidget(await _bootApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lifestyle'));
    await tester.pumpAndSettle();
    expect(find.text('Lifestyle Logging'), findsOneWidget);
    expect(find.text('Planned for M4'), findsOneWidget);
  });
}
