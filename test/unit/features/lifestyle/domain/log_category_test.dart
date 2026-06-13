import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/features/lifestyle/domain/value_objects/log_category.dart';

void main() {
  group('LogCategory', () {
    test('all storageKeys are unique', () {
      final Set<String> keys = LogCategory.values
          .map((c) => c.storageKey)
          .toSet();
      expect(keys.length, LogCategory.values.length);
    });

    test('fromStorageKey round-trips every value', () {
      for (final LogCategory c in LogCategory.values) {
        expect(LogCategory.fromStorageKey(c.storageKey), c);
      }
    });

    test('fromStorageKey returns null for unknown', () {
      expect(LogCategory.fromStorageKey('unknown_xyz'), isNull);
    });

    group('isValid', () {
      test('water accepts whole numbers in 0..30', () {
        expect(LogCategory.water.isValid(0), isTrue);
        expect(LogCategory.water.isValid(8), isTrue);
        expect(LogCategory.water.isValid(30), isTrue);
        expect(LogCategory.water.isValid(31), isFalse);
        expect(LogCategory.water.isValid(-1), isFalse);
        // Integer category rejects fractional values.
        expect(LogCategory.water.isValid(2.5), isFalse);
      });

      test('sleep accepts halves in 0..24', () {
        expect(LogCategory.sleep.isValid(0), isTrue);
        expect(LogCategory.sleep.isValid(7.5), isTrue);
        expect(LogCategory.sleep.isValid(24), isTrue);
        expect(LogCategory.sleep.isValid(24.1), isFalse);
        expect(LogCategory.sleep.isValid(-0.5), isFalse);
      });

      test('mood accepts integers 1..5 only', () {
        expect(LogCategory.mood.isValid(0), isFalse);
        expect(LogCategory.mood.isValid(1), isTrue);
        expect(LogCategory.mood.isValid(5), isTrue);
        expect(LogCategory.mood.isValid(6), isFalse);
        expect(LogCategory.mood.isValid(3.5), isFalse);
      });

      test('exercise accepts integer minutes 0..600', () {
        expect(LogCategory.exercise.isValid(0), isTrue);
        expect(LogCategory.exercise.isValid(30), isTrue);
        expect(LogCategory.exercise.isValid(600), isTrue);
        expect(LogCategory.exercise.isValid(601), isFalse);
      });
    });

    test('aggregation kinds map to expected categories', () {
      expect(LogCategory.water.aggregation, LogAggregation.cumulative);
      expect(LogCategory.exercise.aggregation, LogAggregation.cumulative);
      expect(LogCategory.sleep.aggregation, LogAggregation.snapshot);
      expect(LogCategory.mood.aggregation, LogAggregation.snapshot);
    });
  });
}
