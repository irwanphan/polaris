import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/features/lifestyle/domain/entities/lifestyle_log.dart';
import 'package:polaris/features/lifestyle/domain/value_objects/log_category.dart';
import 'package:polaris/features/recommendations/application/snapshot_builder.dart';
import 'package:polaris/features/recommendations/domain/snapshot/lifestyle_snapshot.dart';

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
  const SnapshotBuilder builder = SnapshotBuilder();
  final DateTime now = DateTime(2026, 6, 13, 10);
  final DateTime today = DateTime(2026, 6, 13);

  group('SnapshotBuilder', () {
    test('produces an empty snapshot when no logs', () {
      final LifestyleSnapshot snap = builder.build(
        logs: const <LifestyleLog>[],
        now: now,
      );
      expect(snap.referenceDate, today);
      expect(snap.windowDays, 14);
      expect(snap.dailyByCategory, isEmpty);
      expect(snap.hasAnyLogIn(days: 14), isFalse);
    });

    test('cumulative categories sum entries on the same local day', () {
      final List<LifestyleLog> logs = <LifestyleLog>[
        _log(
          id: 'w1',
          category: LogCategory.water,
          value: 2,
          loggedAt: DateTime(2026, 6, 13, 8),
        ),
        _log(
          id: 'w2',
          category: LogCategory.water,
          value: 3,
          loggedAt: DateTime(2026, 6, 13, 18),
        ),
      ];

      final LifestyleSnapshot snap = builder.build(logs: logs, now: now);
      final DailyAggregate row =
          snap.dailyByCategory[LogCategory.water]![today]!;
      expect(row.value, 5);
      expect(row.entryCount, 2);
    });

    test('snapshot categories take the latest entry per day', () {
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
      ];

      final LifestyleSnapshot snap = builder.build(logs: logs, now: now);
      expect(snap.dailyByCategory[LogCategory.mood]![today]!.value, 5);
      expect(snap.dailyByCategory[LogCategory.mood]![today]!.entryCount, 2);
    });

    test('drops entries outside the rolling window', () {
      final List<LifestyleLog> logs = <LifestyleLog>[
        _log(
          id: 'old',
          category: LogCategory.water,
          value: 4,
          loggedAt: DateTime(2026, 5, 1),
        ),
        _log(
          id: 'today',
          category: LogCategory.water,
          value: 1,
          loggedAt: DateTime(2026, 6, 13, 9),
        ),
      ];
      final LifestyleSnapshot snap = builder.build(
        logs: logs,
        now: now,
        windowDays: 7,
      );
      expect(snap.dailyByCategory[LogCategory.water]!.length, 1);
      expect(snap.dailyByCategory[LogCategory.water]![today]!.value, 1);
    });

    test('recentDays returns chronological order with no padding', () {
      final List<LifestyleLog> logs = <LifestyleLog>[
        _log(
          id: 'today',
          category: LogCategory.sleep,
          value: 8,
          loggedAt: DateTime(2026, 6, 13, 7),
        ),
        _log(
          id: 'yesterday',
          category: LogCategory.sleep,
          value: 6,
          loggedAt: DateTime(2026, 6, 12, 7),
        ),
        _log(
          id: 'gap',
          category: LogCategory.sleep,
          value: 7,
          loggedAt: DateTime(2026, 6, 10, 7),
        ),
      ];
      final LifestyleSnapshot snap = builder.build(logs: logs, now: now);
      final List<DailyAggregate> last7 = snap.recentDays(
        LogCategory.sleep,
        days: 7,
      );
      expect(last7.map((a) => a.value).toList(), <double>[7, 6, 8]);
    });

    test('averagePerActiveDay ignores days with no entries', () {
      final List<LifestyleLog> logs = <LifestyleLog>[
        _log(
          id: 'a',
          category: LogCategory.water,
          value: 4,
          loggedAt: DateTime(2026, 6, 13, 8),
        ),
        _log(
          id: 'b',
          category: LogCategory.water,
          value: 6,
          loggedAt: DateTime(2026, 6, 11, 8),
        ),
      ];
      final LifestyleSnapshot snap = builder.build(logs: logs, now: now);
      // 2 active days summing to 10 → avg 5 (not 10/7).
      expect(snap.averagePerActiveDay(LogCategory.water, days: 7), 5);
    });

    test('sumOverWindow returns zero when nothing logged', () {
      final LifestyleSnapshot snap = builder.build(
        logs: const <LifestyleLog>[],
        now: now,
      );
      expect(snap.sumOverWindow(LogCategory.exercise, days: 7), 0);
    });

    test('hasAnyLogIn returns true once any category has a recent entry', () {
      final LifestyleSnapshot snap = builder.build(
        logs: <LifestyleLog>[
          _log(
            id: 'm',
            category: LogCategory.mood,
            value: 4,
            loggedAt: DateTime(2026, 6, 10),
          ),
        ],
        now: now,
      );
      expect(snap.hasAnyLogIn(days: 7), isTrue);
      expect(snap.hasAnyLogIn(days: 2), isFalse);
    });
  });
}
