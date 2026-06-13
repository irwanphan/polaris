import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/core/extensions/date_x.dart';

void main() {
  group('DateTimeX', () {
    test('atStartOfDay zeroes the time portion', () {
      final DateTime dt = DateTime(2026, 6, 12, 14, 30, 45, 123);
      expect(dt.atStartOfDay, DateTime(2026, 6, 12));
    });

    test('atEndOfDay returns 23:59:59.999 same day', () {
      final DateTime dt = DateTime(2026, 6, 12, 1, 0);
      expect(dt.atEndOfDay, DateTime(2026, 6, 12, 23, 59, 59, 999));
    });

    test('daysUntil ignores time of day', () {
      final DateTime a = DateTime(2026, 6, 12, 22, 0);
      final DateTime b = DateTime(2026, 6, 15, 1, 0);
      expect(a.daysUntil(b), 3);
    });

    test('daysUntil is negative for past targets', () {
      final DateTime a = DateTime(2026, 6, 12);
      final DateTime b = DateTime(2026, 6, 10);
      expect(a.daysUntil(b), -2);
    });

    test('isSameDayAs is independent of time', () {
      expect(
        DateTime(2026, 6, 12, 1).isSameDayAs(DateTime(2026, 6, 12, 23)),
        isTrue,
      );
      expect(DateTime(2026, 6, 12).isSameDayAs(DateTime(2026, 6, 13)), isFalse);
    });
  });

  group('DurationX', () {
    test('nonNegative clamps negative durations to zero', () {
      expect(const Duration(seconds: -5).nonNegative, Duration.zero);
      expect(
        const Duration(seconds: 7).nonNegative,
        const Duration(seconds: 7),
      );
    });
  });
}
