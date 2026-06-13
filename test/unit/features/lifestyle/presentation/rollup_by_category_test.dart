import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/features/lifestyle/domain/entities/lifestyle_log.dart';
import 'package:polaris/features/lifestyle/domain/value_objects/log_category.dart';
import 'package:polaris/features/lifestyle/presentation/pages/lifestyle_page.dart';

LifestyleLog _log({
  required LogCategory category,
  required double value,
  required DateTime loggedAt,
  String id = 'x',
}) {
  return LifestyleLog(
    id: id,
    category: category,
    value: value,
    loggedAt: loggedAt,
    createdAt: loggedAt,
  );
}

void main() {
  group('rollupByCategory', () {
    test('returns empty map when no logs', () {
      expect(rollupByCategory(<LifestyleLog>[]), isEmpty);
    });

    test('cumulative categories sum across the day', () {
      final List<LifestyleLog> logs = <LifestyleLog>[
        _log(
          id: 'a',
          category: LogCategory.water,
          value: 2,
          loggedAt: DateTime(2026, 6, 13, 8),
        ),
        _log(
          id: 'b',
          category: LogCategory.water,
          value: 3,
          loggedAt: DateTime(2026, 6, 13, 12),
        ),
        _log(
          id: 'c',
          category: LogCategory.water,
          value: 1,
          loggedAt: DateTime(2026, 6, 13, 18),
        ),
      ];

      final result = rollupByCategory(logs);
      expect(result[LogCategory.water]!.displayValue, '6');
      expect(result[LogCategory.water]!.entriesCount, 3);
    });

    test('snapshot categories take the latest entry', () {
      final List<LifestyleLog> logs = <LifestyleLog>[
        _log(
          id: 'morning',
          category: LogCategory.mood,
          value: 3,
          loggedAt: DateTime(2026, 6, 13, 8),
        ),
        _log(
          id: 'evening',
          category: LogCategory.mood,
          value: 5,
          loggedAt: DateTime(2026, 6, 13, 20),
        ),
        _log(
          id: 'noon',
          category: LogCategory.mood,
          value: 4,
          loggedAt: DateTime(2026, 6, 13, 12),
        ),
      ];

      final result = rollupByCategory(logs);
      expect(result[LogCategory.mood]!.displayValue, '5');
      expect(result[LogCategory.mood]!.entriesCount, 3);
    });

    test('formats decimal vs integer per category', () {
      final List<LifestyleLog> logs = <LifestyleLog>[
        _log(
          category: LogCategory.sleep,
          value: 7.5,
          loggedAt: DateTime(2026, 6, 13, 7),
        ),
      ];

      final result = rollupByCategory(logs);
      // Sleep is non-integer → "7.5".
      expect(result[LogCategory.sleep]!.displayValue, '7.5');
    });

    test('mixed categories rollup independently', () {
      final DateTime now = DateTime(2026, 6, 13, 9);
      final List<LifestyleLog> logs = <LifestyleLog>[
        _log(id: 'w1', category: LogCategory.water, value: 2, loggedAt: now),
        _log(id: 'w2', category: LogCategory.water, value: 3, loggedAt: now),
        _log(id: 's1', category: LogCategory.sleep, value: 6.5, loggedAt: now),
        _log(
          id: 'e1',
          category: LogCategory.exercise,
          value: 30,
          loggedAt: now,
        ),
      ];

      final result = rollupByCategory(logs);
      expect(result[LogCategory.water]!.displayValue, '5');
      expect(result[LogCategory.sleep]!.displayValue, '6.5');
      expect(result[LogCategory.exercise]!.displayValue, '30');
      expect(result.containsKey(LogCategory.mood), isFalse);
    });
  });
}
