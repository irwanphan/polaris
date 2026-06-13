import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/features/recommendations/application/recommendation_engine.dart';
import 'package:polaris/features/recommendations/domain/entities/insight.dart';
import 'package:polaris/features/recommendations/domain/rules/recommendation_rule.dart';
import 'package:polaris/features/recommendations/domain/snapshot/lifestyle_snapshot.dart';
import 'package:polaris/features/recommendations/domain/value_objects/insight_severity.dart';

/// Fake rule that always returns a fixed [Insight] (or null).
class _StaticRule implements RecommendationRule {
  const _StaticRule(this._insight);
  final Insight? _insight;

  @override
  String get id => _insight?.id ?? 'noop';

  @override
  Insight? evaluate(LifestyleSnapshot snapshot) => _insight;
}

LifestyleSnapshot _emptySnapshot() => LifestyleSnapshot(
  referenceDate: DateTime(2026, 6, 13),
  windowDays: 14,
  dailyByCategory: const {},
);

Insight _insight(String id, InsightSeverity severity) =>
    Insight(id: id, severity: severity, title: id, body: id);

void main() {
  group('RecommendationEngine.evaluate', () {
    test('returns empty when no rule fires', () {
      const RecommendationEngine engine = RecommendationEngine(
        <RecommendationRule>[_StaticRule(null), _StaticRule(null)],
      );
      expect(engine.evaluate(_emptySnapshot()), isEmpty);
    });

    test('drops nulls and keeps only fired insights', () {
      final RecommendationEngine engine =
          RecommendationEngine(<RecommendationRule>[
            _StaticRule(_insight('a', InsightSeverity.info)),
            const _StaticRule(null),
            _StaticRule(_insight('b', InsightSeverity.warn)),
          ]);
      final List<Insight> out = engine.evaluate(_emptySnapshot());
      expect(out.map((i) => i.id).toList(), <String>['b', 'a']);
    });

    test(
      'sorts by severity descending (critical > warn > encourage > info)',
      () {
        final RecommendationEngine engine =
            RecommendationEngine(<RecommendationRule>[
              _StaticRule(_insight('info', InsightSeverity.info)),
              _StaticRule(_insight('crit', InsightSeverity.critical)),
              _StaticRule(_insight('warn', InsightSeverity.warn)),
              _StaticRule(_insight('enc', InsightSeverity.encourage)),
            ]);
        final List<Insight> out = engine.evaluate(_emptySnapshot());
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
        <RecommendationRule>[_StaticRule(_insight('a', InsightSeverity.info))],
      );
      final List<Insight> out = engine.evaluate(_emptySnapshot());
      expect(
        () => out.add(_insight('x', InsightSeverity.warn)),
        throwsUnsupportedError,
      );
    });
  });

  group('RecommendationEngine.evaluateTop', () {
    test('caps the returned list', () {
      final RecommendationEngine engine =
          RecommendationEngine(<RecommendationRule>[
            _StaticRule(_insight('a', InsightSeverity.warn)),
            _StaticRule(_insight('b', InsightSeverity.encourage)),
            _StaticRule(_insight('c', InsightSeverity.info)),
          ]);
      expect(engine.evaluateTop(_emptySnapshot(), max: 2), hasLength(2));
    });

    test('returns the full list when below the cap', () {
      final RecommendationEngine engine = RecommendationEngine(
        <RecommendationRule>[_StaticRule(_insight('a', InsightSeverity.warn))],
      );
      expect(engine.evaluateTop(_emptySnapshot(), max: 5), hasLength(1));
    });
  });
}
