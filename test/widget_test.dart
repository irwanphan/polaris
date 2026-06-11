import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/app/app.dart';
import 'package:polaris/core/errors/failure.dart';
import 'package:polaris/core/logging/app_logger.dart';
import 'package:polaris/core/result/result.dart';
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

Future<ProviderScope> _bootApp({Map<String, Object>? prefs}) async {
  SharedPreferences.setMockInitialValues(prefs ?? <String, Object>{});
  final SharedPreferences sp = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      appLoggerProvider.overrideWithValue(AppLogger.silent()),
      sharedPreferencesProvider.overrideWithValue(sp),
      lifeExpectancyRepositoryProvider
          .overrideWithValue(_FakeExpectancyRepo()),
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

  testWidgets('Other placeholder routes still render', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(await _bootApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle();
    expect(find.text('Event Countdown'), findsOneWidget);
    expect(find.text('Planned for M2'), findsOneWidget);
  });
}
