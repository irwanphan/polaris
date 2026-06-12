import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/features/event_countdown/domain/entities/event.dart';
import 'package:polaris/features/event_countdown/domain/value_objects/recurrence.dart';

Event _event({
  required DateTime targetAt,
  Recurrence recurrence = Recurrence.none,
}) {
  return Event(
    id: 'fixed-id',
    title: 'Test',
    targetAt: targetAt,
    colorHex: '#6366F1',
    iconKey: 'event',
    recurrence: recurrence,
    isPinnedToWidget: false,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

void main() {
  group('Event.daysUntil (none)', () {
    final DateTime now = DateTime(2026, 6, 12);

    test('counts whole days to a future target', () {
      final e = _event(targetAt: DateTime(2026, 6, 19));
      expect(e.daysUntil(now), 7);
    });

    test('returns 0 when target is today', () {
      final e = _event(targetAt: DateTime(2026, 6, 12, 18));
      expect(e.daysUntil(now), 0);
    });

    test('clamps past targets to 0 (one-time)', () {
      final e = _event(targetAt: DateTime(2026, 6, 1));
      expect(e.daysUntil(now), 0);
    });
  });

  group('Event.nextOccurrence (yearly)', () {
    test('rolls to next year when this year passed', () {
      final now = DateTime(2026, 6, 12);
      final e = _event(
        targetAt: DateTime(1990, 5, 1),
        recurrence: Recurrence.yearly,
      );
      expect(e.nextOccurrence(now), DateTime(2027, 5, 1));
    });

    test('uses this year when anniversary still upcoming', () {
      final now = DateTime(2026, 6, 12);
      final e = _event(
        targetAt: DateTime(1990, 12, 25),
        recurrence: Recurrence.yearly,
      );
      expect(e.nextOccurrence(now), DateTime(2026, 12, 25));
    });

    test('Feb 29 in a non-leap year falls back to Feb 28', () {
      final now = DateTime(2026, 1, 1); // 2026 is not a leap year
      final e = _event(
        targetAt: DateTime(2000, 2, 29),
        recurrence: Recurrence.yearly,
      );
      expect(e.nextOccurrence(now), DateTime(2026, 2, 28));
    });
  });

  group('Event.nextOccurrence (monthly)', () {
    test('rolls to next month when this month passed', () {
      final now = DateTime(2026, 6, 12);
      final e = _event(
        targetAt: DateTime(2020, 1, 5),
        recurrence: Recurrence.monthly,
      );
      expect(e.nextOccurrence(now), DateTime(2026, 7, 5));
    });

    test('day 31 falls back to last day of a short month', () {
      final now = DateTime(2026, 4, 1);
      final e = _event(
        targetAt: DateTime(2020, 1, 31),
        recurrence: Recurrence.monthly,
      );
      expect(e.nextOccurrence(now), DateTime(2026, 4, 30));
    });
  });

  group('Event.nextOccurrence (weekly)', () {
    test('rolls to the same weekday this week if not yet passed', () {
      // 2026-06-12 is a Friday. Target Friday.
      final now = DateTime(2026, 6, 12, 8);
      final e = _event(
        targetAt: DateTime(2020, 1, 3, 18), // Friday at 18:00
        recurrence: Recurrence.weekly,
      );
      expect(e.nextOccurrence(now), DateTime(2026, 6, 12, 18));
    });

    test('rolls to next week if this week\'s slot already passed', () {
      final now = DateTime(2026, 6, 12, 20); // Friday 20:00
      final e = _event(
        targetAt: DateTime(2020, 1, 3, 18), // Friday at 18:00
        recurrence: Recurrence.weekly,
      );
      expect(e.nextOccurrence(now), DateTime(2026, 6, 19, 18));
    });
  });

  group('Event.copyWith', () {
    test('only the supplied fields change; createdAt is preserved', () {
      final original = _event(targetAt: DateTime(2026, 7, 1));
      final updated = original.copyWith(title: 'New title');
      expect(updated.title, 'New title');
      expect(updated.targetAt, original.targetAt);
      expect(updated.createdAt, original.createdAt);
    });
  });

  group('Event.create factory', () {
    test('generates a non-empty UUID and stamps timestamps', () {
      final now = DateTime(2026, 6, 12);
      final e = Event.create(
        title: 'Hello',
        targetAt: DateTime(2026, 12, 25),
        now: now,
      );
      expect(e.id, isNotEmpty);
      expect(e.createdAt, now);
      expect(e.updatedAt, now);
      expect(e.title, 'Hello');
    });
  });
}
