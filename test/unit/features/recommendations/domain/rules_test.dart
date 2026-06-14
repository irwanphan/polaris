import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/features/life_countdown/domain/entities/life_estimate.dart';
import 'package:polaris/features/lifestyle/domain/entities/lifestyle_log.dart';
import 'package:polaris/features/lifestyle/domain/value_objects/log_category.dart';
import 'package:polaris/features/recommendations/application/snapshot_builder.dart';
import 'package:polaris/features/recommendations/domain/entities/insight_spec.dart';
import 'package:polaris/features/recommendations/domain/rules/exercise_streak_rule.dart';
import 'package:polaris/features/recommendations/domain/rules/life_phase_rule.dart';
import 'package:polaris/features/recommendations/domain/rules/logging_streak_milestone_rule.dart';
import 'package:polaris/features/recommendations/domain/rules/low_sleep_hydration_rule.dart';
import 'package:polaris/features/recommendations/domain/rules/mood_trend_rule.dart';
import 'package:polaris/features/recommendations/domain/rules/no_data_rule.dart';
import 'package:polaris/features/recommendations/domain/rules/positive_exercise_streak_rule.dart';
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

    test('fires when average is below target — emits typed args', () {
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
      final InsightSpec? out = rule.evaluate(s);
      expect(out, isNotNull);
      expect(out!.id, 'water_target');
      expect(out.contentKey, 'water_target');
      expect(out.severity, InsightSeverity.warn);
      expect(out.relatedCategory, LogCategory.water);
      expect(out.ctaRoute, '/lifestyle');
      expect(out.args['target'], 6.0);
      expect(out.args['windowDays'], 7);
      expect(out.args['avg'], closeTo(3.0, 0.01));
      expect(out.dismissCooldown, const Duration(days: 3));
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
      final InsightSpec? out = rule.evaluate(s);
      expect(out, isNotNull);
      expect(out!.id, 'sleep_regularity');
      expect(out.args['shortCount'], 3);
      expect(out.args['totalCount'], 3);
    });
  });

  group('ExerciseStreakRule', () {
    const ExerciseStreakRule rule = ExerciseStreakRule();

    test('skips when user has not logged anything in the wider window', () {
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
      final InsightSpec? out = rule.evaluate(s);
      expect(out, isNotNull);
      expect(out!.severity, InsightSeverity.encourage);
      expect(out.contentKey, 'exercise_streak');
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

  group('PositiveExerciseStreakRule', () {
    const PositiveExerciseStreakRule rule = PositiveExerciseStreakRule();

    test('skips when active days < threshold (4/7)', () {
      final List<LifestyleLog> logs = <LifestyleLog>[
        for (int i = 0; i < 4; i++)
          _log(
            category: LogCategory.exercise,
            value: 20,
            loggedAt: DateTime(2026, 6, 13 - i),
          ),
      ];
      expect(rule.evaluate(_snapshot(logs)), isNull);
    });

    test('fires when active days ≥ threshold (5/7) — emits args', () {
      final List<LifestyleLog> logs = <LifestyleLog>[
        for (int i = 0; i < 5; i++)
          _log(
            category: LogCategory.exercise,
            value: 30,
            loggedAt: DateTime(2026, 6, 13 - i),
          ),
      ];
      final InsightSpec? out = rule.evaluate(_snapshot(logs));
      expect(out, isNotNull);
      expect(out!.id, 'positive_exercise_streak');
      expect(out.severity, InsightSeverity.encourage);
      expect(out.args['activeDays'], 5);
      expect(out.args['windowDays'], 7);
      expect(out.args['totalMinutes'], 150.0);
    });
  });

  group('LowSleepHydrationRule', () {
    const LowSleepHydrationRule rule = LowSleepHydrationRule();

    test('skips when only sleep is short (water normal)', () {
      final List<LifestyleLog> logs = <LifestyleLog>[
        for (int i = 0; i < 3; i++) ...<LifestyleLog>[
          _log(
            category: LogCategory.sleep,
            value: 5,
            loggedAt: DateTime(2026, 6, 13 - i),
          ),
          _log(
            category: LogCategory.water,
            value: 7,
            loggedAt: DateTime(2026, 6, 13 - i),
          ),
        ],
      ];
      expect(rule.evaluate(_snapshot(logs)), isNull);
    });

    test('fires when BOTH sleep short AND water low', () {
      final List<LifestyleLog> logs = <LifestyleLog>[
        for (int i = 0; i < 3; i++) ...<LifestyleLog>[
          _log(
            category: LogCategory.sleep,
            value: 5,
            loggedAt: DateTime(2026, 6, 13 - i),
          ),
          _log(
            category: LogCategory.water,
            value: 3,
            loggedAt: DateTime(2026, 6, 13 - i),
          ),
        ],
      ];
      final InsightSpec? out = rule.evaluate(_snapshot(logs));
      expect(out, isNotNull);
      expect(out!.id, 'low_sleep_hydration');
      expect(out.relatedCategory, LogCategory.water);
      expect(out.severity, InsightSeverity.warn);
    });
  });

  group('LoggingStreakMilestoneRule', () {
    const LoggingStreakMilestoneRule rule = LoggingStreakMilestoneRule();

    test('skips when today has no log', () {
      final LifestyleSnapshot s = _snapshot(<LifestyleLog>[
        _log(
          category: LogCategory.mood,
          value: 4,
          loggedAt: DateTime(2026, 6, 12),
        ),
      ]);
      expect(rule.evaluate(s), isNull);
    });

    test('fires at 7-day streak with id `logging_streak:7`', () {
      final List<LifestyleLog> logs = <LifestyleLog>[
        for (int i = 0; i < 7; i++)
          _log(
            category: LogCategory.mood,
            value: 4,
            loggedAt: DateTime(2026, 6, 13 - i),
          ),
      ];
      final InsightSpec? out = rule.evaluate(_snapshot(logs));
      expect(out, isNotNull);
      expect(out!.id, 'logging_streak:7');
      expect(out.contentKey, 'logging_streak');
      expect(out.args['streak'], 7);
      expect(out.severity, InsightSeverity.encourage);
    });

    test('picks the largest tier crossed (14 > 7)', () {
      final List<LifestyleLog> logs = <LifestyleLog>[
        for (int i = 0; i < 14; i++)
          _log(
            category: LogCategory.mood,
            value: 4,
            loggedAt: DateTime(2026, 6, 13 - i),
          ),
      ];
      final InsightSpec? out = rule.evaluate(_snapshot(logs));
      expect(out!.id, 'logging_streak:14');
      expect(out.args['streak'], 14);
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
      final InsightSpec? out = rule.evaluate(s);
      expect(out, isNotNull);
      expect(out!.id, 'mood_trend');
      expect(out.args['run'], 3);
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

    test('id encodes the matched threshold so dismissal is per-milestone', () {
      final LifestyleSnapshot s = _snapshot(
        const <LifestyleLog>[],
        estimate: _estimate(percent: 52),
      );
      final InsightSpec? out = rule.evaluate(s);
      expect(out, isNotNull);
      expect(out!.id, 'life_phase:50');
      expect(out.contentKey, 'life_phase');
      expect(out.args['pct'], 50);
      expect(out.severity, InsightSeverity.info);
      expect(out.dismissCooldown, const Duration(days: 30));
    });

    test('matches 90 over 75 when both crossed', () {
      final LifestyleSnapshot s = _snapshot(
        const <LifestyleLog>[],
        estimate: _estimate(percent: 92),
      );
      final InsightSpec? out = rule.evaluate(s);
      expect(out!.id, 'life_phase:90');
      expect(out.args['pct'], 90);
    });
  });

  group('NoDataRule', () {
    const NoDataRule rule = NoDataRule();

    test('fires when zero logs in the last 14 days', () {
      final InsightSpec? out = rule.evaluate(_snapshot(const <LifestyleLog>[]));
      expect(out, isNotNull);
      expect(out!.contentKey, 'no_data');
      expect(out.dismissCooldown, const Duration(days: 1));
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
