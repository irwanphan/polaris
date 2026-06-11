import 'package:polaris/core/errors/failure.dart';
import 'package:polaris/core/extensions/date_x.dart';
import 'package:polaris/core/result/result.dart';

/// User's date of birth, validated to a sensible human range.
///
/// Stored as a `DateTime` at the start of the local day to avoid timezone
/// drift causing the displayed age to "flicker" near midnight.
final class DateOfBirth {
  const DateOfBirth._(this.date);

  /// Hard upper bound on plausible age — refuse anything older than this.
  static const int maxPlausibleYears = 130;

  final DateTime date;

  /// Parses a [DateTime] into a [DateOfBirth].
  ///
  /// [today] is injected so tests stay deterministic; defaults to
  /// `DateTime.now()` at the start of day.
  static Result<DateOfBirth, ValidationFailure> tryFromDateTime(
    DateTime input, {
    DateTime? today,
  }) {
    final DateTime now = (today ?? DateTime.now()).atStartOfDay;
    final DateTime candidate = input.atStartOfDay;

    if (candidate.isAfter(now)) {
      return const Result.err(
        ValidationFailure(
          message: 'Date of birth cannot be in the future.',
          field: 'birthDate',
        ),
      );
    }

    final int ageYears = _approxYearsBetween(candidate, now);
    if (ageYears > maxPlausibleYears) {
      return const Result.err(
        ValidationFailure(
          message:
              'Date of birth implies an age greater than $maxPlausibleYears years.',
          field: 'birthDate',
        ),
      );
    }

    return Result.ok(DateOfBirth._(candidate));
  }

  static int _approxYearsBetween(DateTime from, DateTime to) {
    int years = to.year - from.year;
    final bool hasReachedBirthdayThisYear = to.month > from.month ||
        (to.month == from.month && to.day >= from.day);
    if (!hasReachedBirthdayThisYear) {
      years -= 1;
    }
    return years;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DateOfBirth && other.date == date);

  @override
  int get hashCode => date.hashCode;

  @override
  String toString() => 'DateOfBirth(${date.toIso8601String()})';
}
