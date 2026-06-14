import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/features/recommendations/application/recommendation_engine.dart';
import 'package:polaris/features/recommendations/domain/entities/insight_spec.dart';
import 'package:polaris/features/recommendations/domain/rules/recommendation_rule.dart';
import 'package:polaris/features/recommendations/domain/snapshot/lifestyle_snapshot.dart';
import 'package:polaris/features/recommendations/domain/value_objects/insight_severity.dart';

/// Fake rule that always returns a fixed [InsightSpec] (or null).
class _StaticRule implements RecommendationRule {
  const _StaticRule(this._spec);
  final InsightSpec? _spec;

  @override
  String get id => _spec?.id ?? 'noop';

  @override
  InsightSpec? evaluate(LifestyleSnapshot snapshot) => _spec;
}

LifestyleSnapshot _emptySnapshot() => LifestyleSnapshot(
  referenceDate: DateTime(2026, 6, 13),
  windowDays: 14,
  dailyByCategory: const {},
);

InsightSpec _spec(String id, InsightSeverity severity) =>
    InsightSpec(id: id, contentKey: id, severity: severity);

void main() {
  group('RecommendationEngine.evaluate', () {
    test('returns empty when no rule fires', () {
      const RecommendationEngine engine = RecommendationEngine(
        <RecommendationRule>[_StaticRule(null), _StaticRule(null)],
      );
      expect(engine.evaluate(_emptySnapshot()), isEmpty);
    });

    test('drops nulls and keeps only fired specs', () {
      final RecommendationEngine engine =
          RecommendationEngine(<RecommendationRule>[
            _StaticRule(_spec('a', InsightSeverity.info)),
            const _StaticRule(null),
            _StaticRule(_spec('b', InsightSeverity.warn)),
          ]);
      final List<InsightSpec> out = engine.evaluate(_emptySnapshot());
      expect(out.map((i) => i.id).toList(), <String>['b', 'a']);
    });

    test(
      'sorts by severity descending (critical > warn > encourage > info)',
      () {
        final RecommendationEngine engine =
            RecommendationEngine(<RecommendationRule>[
              _StaticRule(_spec('info', InsightSeverity.info)),
              _StaticRule(_spec('crit', InsightSeverity.critical)),
              _StaticRule(_spec('warn', InsightSeverity.warn)),
              _StaticRule(_spec('enc', InsightSeverity.encourage)),
            ]);
        final List<InsightSpec> out = engine.evaluate(_emptySnapshot());
        expect(out.map((i) => i.id).toList(), <String>[
          'crit',
          'warn',
          'enc',
          'info',
        ]);
      },
    );

    test('returns an unmodifiable list (defensive)', () {
      final RecommendationEngine engine = RecommendationEngine(
        <RecommendationRule>[_StaticRule(_spec('a', InsightSeverity.info))],
      );
      final List<InsightSpec> out = engine.evaluate(_emptySnapshot());
      expect(
        () => out.add(_spec('x', InsightSeverity.warn)),
        throwsUnsupportedError,
      );
    });
  });

  group('RecommendationEngine.evaluateTop', () {
    test('caps the returned list', () {
      final RecommendationEngine engine =
          RecommendationEngine(<RecommendationRule>[
            _StaticRule(_spec('a', InsightSeverity.warn)),
            _StaticRule(_spec('b', InsightSeverity.encourage)),
            _StaticRule(_spec('c', InsightSeverity.info)),
          ]);
      expect(engine.evaluateTop(_emptySnapshot(), max: 2), hasLength(2));
    });

    test('returns the full list when below the cap', () {
      final RecommendationEngine engine = RecommendationEngine(
        <RecommendationRule>[_StaticRule(_spec('a', InsightSeverity.warn))],
      );
      expect(engine.evaluateTop(_emptySnapshot(), max: 5), hasLength(1));
    });
  });
}
