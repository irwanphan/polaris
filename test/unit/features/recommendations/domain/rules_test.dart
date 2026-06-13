import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/features/life_countdown/domain/entities/life_estimate.dart';
import 'package:polaris/features/lifestyle/domain/entities/lifestyle_log.dart';
import 'package:polaris/features/lifestyle/domain/value_objects/log_category.dart';
import 'package:polaris/features/recommendations/application/snapshot_builder.dart';
import 'package:polaris/features/recommendations/domain/entities/insight.dart';
import 'package:polaris/features/recommendations/domain/rules/exercise_streak_rule.dart';
import 'package:polaris/features/recommendations/domain/rules/life_phase_rule.dart';
import 'package:polaris/features/recommendations/domain/rules/mood_trend_rule.dart';
import 'package:polaris/features/recommendations/domain/rules/no_data_rule.dart';
import 'package:polaris/features/recommendations/domain/rules/sleep_regularity_rule.dart';
import 'package:polaris/features/recommendations/domain/rules/water_target_rule.dart';
import 'package:polaris/features/recommendations/domain/snapshot/lifestyle_snapshot.dart';
import 'package:polaris/features/recommendations/domain/value_objects/insight_severity.dart';

final DateTime _now = DateTime(2026, 6, 13, 10);
const SnapshotBuilder _builder = SnapshotBuilder();

LifestyleLog _log({
  required LogCategory category,
  required double value,
  required DateTime loggedAt,
  String? id,
}) {
  return LifestyleLog(
    id: id ?? '${category.storageKey}-${loggedAt.toIso8601String()}',
    category: category,
    value: value,
    loggedAt: loggedAt,
    createdAt: loggedAt,
  );
}

LifestyleSnapshot _snapshot(List<LifestyleLog> logs, {LifeEstimate? estimate}) {
  return _builder.build(logs: logs, now: _now, lifeEstimate: estimate);
}

LifeEstimate _estimate({required double percent}) {
  // expectedTotalDays = 30000 (~82 years). livedDays scaled by pct.
  const int expectedTotalDays = 30000;
  final int lived = (expectedTotalDays * percent / 100).round();
  return LifeEstimate(
    referenceDate: DateTime(2026, 6, 13),
    expectancyYears: 82.0,
    expectedTotalDays: expectedTotalDays,
    livedDays: lived,
    remainingDays: expectedTotalDays - lived,
    estimatedEndDate: DateTime(2078, 1, 1),
  );
}

void main() {
  group('WaterTargetRule', () {
    const WaterTargetRule rule = WaterTargetRule();

    test('skips when not enough sample days', () {
      // 2 active days < minSampleDays (3).
      final LifestyleSnapshot s = _snapshot(<LifestyleLog>[
        _log(
          category: LogCategory.water,
          value: 1,
          loggedAt: DateTime(2026, 6, 12),
        ),
        _log(
          category: LogCategory.water,
          value: 2,
          loggedAt: DateTime(2026, 6, 11),
        ),
      ]);
      expect(rule.evaluate(s), isNull);
    });

    test('skips when average meets the target', () {
      final LifestyleSnapshot s = _snapshot(<LifestyleLog>[
        _log(
          category: LogCategory.water,
          value: 8,
          loggedAt: DateTime(2026, 6, 13),
        ),
        _log(
          category: LogCategory.water,
          value: 6,
          loggedAt: DateTime(2026, 6, 12),
        ),
        _log(
          category: LogCategory.water,
          value: 6,
          loggedAt: DateTime(2026, 6, 11),
        ),
      ]);
      expect(rule.evaluate(s), isNull);
    });

    test('fires when average is below target', () {
      final LifestyleSnapshot s = _snapshot(<LifestyleLog>[
        _log(
          category: LogCategory.water,
          value: 3,
          loggedAt: DateTime(2026, 6, 13),
        ),
        _log(
          category: LogCategory.water,
          value: 2,
          loggedAt: DateTime(2026, 6, 12),
        ),
        _log(
          category: LogCategory.water,
          value: 4,
          loggedAt: DateTime(2026, 6, 11),
        ),
      ]);
      final Insight? out = rule.evaluate(s);
      expect(out, isNotNull);
      expect(out!.id, 'water_target');
      expect(out.severity, InsightSeverity.warn);
      expect(out.relatedCategory, LogCategory.water);
    });
  });

  group('SleepRegularityRule', () {
    const SleepRegularityRule rule = SleepRegularityRule();

    test('skips when fewer than threshold short nights', () {
      final LifestyleSnapshot s = _snapshot(<LifestyleLog>[
        _log(
          category: LogCategory.sleep,
          value: 5,
          loggedAt: DateTime(2026, 6, 13),
        ),
        _log(
          category: LogCategory.sleep,
          value: 7,
          loggedAt: DateTime(2026, 6, 12),
        ),
        _log(
          category: LogCategory.sleep,
          value: 8,
          loggedAt: DateTime(2026, 6, 11),
        ),
      ]);
      expect(rule.evaluate(s), isNull);
    });

    test('fires when ≥3 nights short in last 7 days', () {
      final LifestyleSnapshot s = _snapshot(<LifestyleLog>[
        _log(
          category: LogCategory.sleep,
          value: 5,
          loggedAt: DateTime(2026, 6, 13),
        ),
        _log(
          category: LogCategory.sleep,
          value: 4.5,
          loggedAt: DateTime(2026, 6, 12),
        ),
        _log(
          category: LogCategory.sleep,
          value: 5.5,
          loggedAt: DateTime(2026, 6, 11),
        ),
      ]);
      final Insight? out = rule.evaluate(s);
      expect(out, isNotNull);
      expect(out!.id, 'sleep_regularity');
    });
  });

  group('ExerciseStreakRule', () {
    const ExerciseStreakRule rule = ExerciseStreakRule();

    test('skips when user has not logged anything in the wider window', () {
      // No logs at all → defer to NoDataRule.
      final LifestyleSnapshot s = _snapshot(const <LifestyleLog>[]);
      expect(rule.evaluate(s), isNull);
    });

    test('fires when other categories logged but exercise is zero', () {
      final LifestyleSnapshot s = _snapshot(<LifestyleLog>[
        _log(
          category: LogCategory.water,
          value: 6,
          loggedAt: DateTime(2026, 6, 13),
        ),
      ]);
      final Insight? out = rule.evaluate(s);
      expect(out, isNotNull);
      expect(out!.severity, InsightSeverity.encourage);
    });

    test('skips when exercise minutes recorded', () {
      final LifestyleSnapshot s = _snapshot(<LifestyleLog>[
        _log(
          category: LogCategory.exercise,
          value: 15,
          loggedAt: DateTime(2026, 6, 12),
        ),
      ]);
      expect(rule.evaluate(s), isNull);
    });
  });

  group('MoodTrendRule', () {
    const MoodTrendRule rule = MoodTrendRule();

    test('skips when fewer than 3 mood entries', () {
      final LifestyleSnapshot s = _snapshot(<LifestyleLog>[
        _log(
          category: LogCategory.mood,
          value: 5,
          loggedAt: DateTime(2026, 6, 13),
        ),
        _log(
          category: LogCategory.mood,
          value: 4,
          loggedAt: DateTime(2026, 6, 12),
        ),
      ]);
      expect(rule.evaluate(s), isNull);
    });

    test('skips on flat moods (3,3,3)', () {
      final LifestyleSnapshot s = _snapshot(<LifestyleLog>[
        _log(
          category: LogCategory.mood,
          value: 3,
          loggedAt: DateTime(2026, 6, 13),
        ),
        _log(
          category: LogCategory.mood,
          value: 3,
          loggedAt: DateTime(2026, 6, 12),
        ),
        _log(
          category: LogCategory.mood,
          value: 3,
          loggedAt: DateTime(2026, 6, 11),
        ),
      ]);
      expect(rule.evaluate(s), isNull);
    });

    test('fires on strictly descending mood (5→4→3)', () {
      final LifestyleSnapshot s = _snapshot(<LifestyleLog>[
        _log(
          category: LogCategory.mood,
          value: 3,
          loggedAt: DateTime(2026, 6, 13),
        ),
        _log(
          category: LogCategory.mood,
          value: 4,
          loggedAt: DateTime(2026, 6, 12),
        ),
        _log(
          category: LogCategory.mood,
          value: 5,
          loggedAt: DateTime(2026, 6, 11),
        ),
      ]);
      final Insight? out = rule.evaluate(s);
      expect(out, isNotNull);
      expect(out!.id, 'mood_trend');
    });
  });

  group('LifePhaseRule', () {
    const LifePhaseRule rule = LifePhaseRule();

    test('skips when life estimate missing', () {
      expect(rule.evaluate(_snapshot(const <LifestyleLog>[])), isNull);
    });

    test('skips when below the smallest threshold', () {
      final LifestyleSnapshot s = _snapshot(
        const <LifestyleLog>[],
        estimate: _estimate(percent: 10),
      );
      expect(rule.evaluate(s), isNull);
    });

    test('matches the largest threshold ≤ percentLived (52% → 50)', () {
      final LifestyleSnapshot s = _snapshot(
        const <LifestyleLog>[],
        estimate: _estimate(percent: 52),
      );
      final Insight? out = rule.evaluate(s);
      expect(out, isNotNull);
      expect(out!.title.contains('50%'), isTrue);
      expect(out.severity, InsightSeverity.info);
    });

    test('matches 90 over 75 when both crossed', () {
      final LifestyleSnapshot s = _snapshot(
        const <LifestyleLog>[],
        estimate: _estimate(percent: 92),
      );
      final Insight? out = rule.evaluate(s);
      expect(out!.title.contains('90%'), isTrue);
    });
  });

  group('NoDataRule', () {
    const NoDataRule rule = NoDataRule();

    test('fires when zero logs in the last 14 days', () {
      expect(rule.evaluate(_snapshot(const <LifestyleLog>[])), isNotNull);
    });

    test('skips when any recent log exists', () {
      final LifestyleSnapshot s = _snapshot(<LifestyleLog>[
        _log(
          category: LogCategory.mood,
          value: 4,
          loggedAt: DateTime(2026, 6, 11),
        ),
      ]);
      expect(rule.evaluate(s), isNull);
    });
  });
}
