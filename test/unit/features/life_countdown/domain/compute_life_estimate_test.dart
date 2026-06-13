import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/core/errors/failure.dart';
import 'package:polaris/core/result/result.dart';
import 'package:polaris/features/life_countdown/domain/entities/life_estimate.dart';
import 'package:polaris/features/life_countdown/domain/entities/life_profile.dart';
import 'package:polaris/features/life_countdown/domain/repositories/life_expectancy_repository.dart';
import 'package:polaris/features/life_countdown/domain/usecases/compute_life_estimate.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/country_code.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/date_of_birth.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/sex.dart';

class _FakeExpectancyRepo implements LifeExpectancyRepository {
  _FakeExpectancyRepo(this.value);

  final double value;

  @override
  Future<Result<double, Failure>> lookup({
    required CountryCode countryCode,
    required Sex sex,
  }) async => Result.ok(value);

  @override
  Future<Result<List<CountryOption>, Failure>> listSupportedCountries() async =>
      const Result.ok(<CountryOption>[]);
}

class _ErroringExpectancyRepo implements LifeExpectancyRepository {
  @override
  Future<Result<double, Failure>> lookup({
    required CountryCode countryCode,
    required Sex sex,
  }) async => const Result.err(NotFoundFailure(message: 'no data'));

  @override
  Future<Result<List<CountryOption>, Failure>> listSupportedCountries() async =>
      const Result.ok(<CountryOption>[]);
}

LifeProfile _profile({required DateTime birth, Sex sex = Sex.male}) {
  final DateTime today = DateTime(2026, 6, 12);
  return LifeProfile(
    dateOfBirth: DateOfBirth.tryFromDateTime(birth, today: today).valueOrNull!,
    sex: sex,
    countryCode: CountryCode.indonesia,
    createdAt: today,
    updatedAt: today,
  );
}

void main() {
  group('ComputeLifeEstimate', () {
    test(
      'computes lived, remaining, total, and percent for a typical case',
      () async {
        final usecase = ComputeLifeEstimate(_FakeExpectancyRepo(70.0));
        final LifeProfile profile = _profile(birth: DateTime(1990, 6, 12));
        final today = DateTime(2026, 6, 12);

        final result = await usecase(profile, now: today);

        expect(result.isOk, isTrue);
        final LifeEstimate est = result.valueOrNull!;
        expect(est.expectancyYears, 70.0);
        expect(
          est.expectedTotalDays,
          (70 * ComputeLifeEstimate.daysPerYear).round(),
        );

        const int expectedLived =
            36 * 365 + 9; // 9 leap days between 1990 and 2026
        expect(est.livedDays, expectedLived);

        expect(est.remainingDays, est.expectedTotalDays - est.livedDays);
        expect(
          est.percentLived,
          closeTo(est.livedDays / est.expectedTotalDays * 100, 0.001),
        );
        expect(est.estimatedEndDate.year, greaterThanOrEqualTo(2060));
      },
    );

    test('remainingDays is clamped to 0 for an expired estimate', () async {
      final usecase = ComputeLifeEstimate(_FakeExpectancyRepo(20.0));
      final profile = _profile(birth: DateTime(1990, 6, 12));
      final today = DateTime(2026, 6, 12); // already 36 yrs > 20 yrs expectancy

      final result = await usecase(profile, now: today);
      final est = result.valueOrNull!;

      expect(est.remainingDays, 0);
      expect(est.percentLived, 100.0);
      expect(est.isCompleted, isTrue);
    });

    test('a newborn profile is 100% future', () async {
      final usecase = ComputeLifeEstimate(_FakeExpectancyRepo(70.0));
      final birth = DateTime(2026, 6, 12);
      final profile = _profile(birth: birth);

      final result = await usecase(profile, now: birth);
      final est = result.valueOrNull!;

      expect(est.livedDays, 0);
      expect(est.remainingDays, est.expectedTotalDays);
      expect(est.percentLived, 0.0);
    });

    test('forwards repository failures unchanged', () async {
      final usecase = ComputeLifeEstimate(_ErroringExpectancyRepo());
      final profile = _profile(birth: DateTime(1990, 6, 12));

      final result = await usecase(profile);

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('derived helpers (weeks/months/years) round consistently', () async {
      final usecase = ComputeLifeEstimate(_FakeExpectancyRepo(80.0));
      final profile = _profile(birth: DateTime(2000, 1, 1));
      final today = DateTime(2025, 1, 1);

      final est = (await usecase(profile, now: today)).valueOrNull!;
      expect(est.remainingWeeks, est.remainingDays ~/ 7);
      expect(est.remainingMonths, (est.remainingDays / 30.4375).floor());
      expect(est.remainingYears, closeTo(est.remainingDays / 365.25, 0.001));
    });
  });
}
