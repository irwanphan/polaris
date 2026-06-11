import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/date_of_birth.dart';

void main() {
  final DateTime today = DateTime(2026, 6, 12);

  group('DateOfBirth.tryFromDateTime', () {
    test('accepts a past date and normalizes to start of day', () {
      final result = DateOfBirth.tryFromDateTime(
        DateTime(1990, 7, 15, 13, 45),
        today: today,
      );
      expect(result.isOk, isTrue);
      expect(result.valueOrNull!.date, DateTime(1990, 7, 15));
    });

    test('accepts today as a degenerate but valid case', () {
      final result = DateOfBirth.tryFromDateTime(today, today: today);
      expect(result.isOk, isTrue);
    });

    test('rejects future dates', () {
      final result = DateOfBirth.tryFromDateTime(
        today.add(const Duration(days: 1)),
        today: today,
      );
      expect(result.isErr, isTrue);
      expect(result.failureOrNull!.field, 'birthDate');
    });

    test('rejects implausibly old dates (> 130 years)', () {
      final result = DateOfBirth.tryFromDateTime(
        DateTime(1850, 1, 1),
        today: today,
      );
      expect(result.isErr, isTrue);
    });

    test('equality is structural', () {
      final a = DateOfBirth.tryFromDateTime(
        DateTime(1990, 7, 15),
        today: today,
      ).valueOrNull;
      final b = DateOfBirth.tryFromDateTime(
        DateTime(1990, 7, 15, 9),
        today: today,
      ).valueOrNull;
      expect(a, b);
    });
  });
}
