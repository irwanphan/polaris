import 'dart:math' as math;

import 'package:polaris/core/errors/failure.dart';
import 'package:polaris/core/extensions/date_x.dart';
import 'package:polaris/core/result/result.dart';
import 'package:polaris/features/life_countdown/domain/entities/life_estimate.dart';
import 'package:polaris/features/life_countdown/domain/entities/life_profile.dart';
import 'package:polaris/features/life_countdown/domain/repositories/life_expectancy_repository.dart';

/// Single Responsibility: turn a [LifeProfile] into a [LifeEstimate].
///
/// Pure with respect to its inputs once the repository call resolves —
/// given the same `now`, profile, and table state, it always returns the
/// same estimate. That makes it trivial to unit-test without mocking time.
class ComputeLifeEstimate {
  const ComputeLifeEstimate(this._expectancyRepository);

  /// Number of days per Julian year. Used to convert expectancy-in-years
  /// into expectancy-in-days while accounting for leap years on average.
  static const double daysPerYear = 365.25;

  final LifeExpectancyRepository _expectancyRepository;

  Future<Result<LifeEstimate, Failure>> call(
    LifeProfile profile, {
    DateTime? now,
  }) async {
    final Result<double, Failure> lookup =
        await _expectancyRepository.lookup(
      countryCode: profile.countryCode,
      sex: profile.sex,
    );

    return lookup.fold<Result<LifeEstimate, Failure>>(
      onOk: (double expectancyYears) {
        final DateTime today = (now ?? DateTime.now()).atStartOfDay;
        return Result.ok(
          _build(profile, expectancyYears: expectancyYears, today: today),
        );
      },
      onErr: Result<LifeEstimate, Failure>.err,
    );
  }

  /// Pure helper for tests that already know the expectancy value.
  LifeEstimate buildFor(
    LifeProfile profile, {
    required double expectancyYears,
    required DateTime today,
  }) =>
      _build(profile, expectancyYears: expectancyYears, today: today);

  LifeEstimate _build(
    LifeProfile profile, {
    required double expectancyYears,
    required DateTime today,
  }) {
    final DateTime birth = profile.dateOfBirth.date;
    final int expectedTotalDays =
        (expectancyYears * daysPerYear).round();
    final DateTime estimatedEnd =
        birth.add(Duration(days: expectedTotalDays));

    final int livedDays = math.max(0, birth.daysUntil(today));
    final int remainingDaysRaw = today.daysUntil(estimatedEnd);
    final int remainingDays = math.max(0, remainingDaysRaw);

    return LifeEstimate(
      referenceDate: today,
      expectancyYears: expectancyYears,
      expectedTotalDays: expectedTotalDays,
      livedDays: livedDays,
      remainingDays: remainingDays,
      estimatedEndDate: estimatedEnd,
    );
  }
}
