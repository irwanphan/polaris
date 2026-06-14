import 'package:polaris/features/recommendations/domain/entities/insight_spec.dart';
import 'package:polaris/features/recommendations/domain/rules/recommendation_rule.dart';
import 'package:polaris/features/recommendations/domain/snapshot/lifestyle_snapshot.dart';
import 'package:polaris/features/recommendations/domain/value_objects/insight_severity.dart';

/// Composes a [RecommendationRule] list into a single evaluation.
///
/// The engine is intentionally thin — every "interesting" decision
/// lives in rules. Its only own behaviour is:
///   1. Iterate rules in the order given (deterministic for tests).
///   2. Drop `null` returns (no insight from that rule this time).
///   3. Stable-sort by severity descending so the most urgent card
///      lands at the top of the UI.
///
/// Output is a list of [InsightSpec] — the engine is l10n-free by
/// design. The presentation layer's `InsightContent` resolver maps
/// each spec into a renderable, localized `Insight`. Filtering
/// dismissed specs is the consumer's job (see `insightsProvider`).
class RecommendationEngine {
  const RecommendationEngine(this.rules);

  final List<RecommendationRule> rules;

  List<InsightSpec> evaluate(LifestyleSnapshot snapshot) {
    final List<InsightSpec> raw = <InsightSpec>[];
    for (final RecommendationRule rule in rules) {
      final InsightSpec? out = rule.evaluate(snapshot);
      if (out != null) raw.add(out);
    }
    raw.sort(
      (InsightSpec a, InsightSpec b) =>
          b.severity.index.compareTo(a.severity.index),
    );
    return List<InsightSpec>.unmodifiable(raw);
  }

  /// Convenience for callers that want to enforce a maximum number
  /// of cards on screen (the home insight slot only has room for a
  /// few).
  List<InsightSpec> evaluateTop(
    LifestyleSnapshot snapshot, {
    required int max,
  }) {
    final List<InsightSpec> all = evaluate(snapshot);
    if (all.length <= max) return all;
    return List<InsightSpec>.unmodifiable(all.take(max));
  }
}

/// Re-exported so call sites have a single import for the type +
/// the constants they need (e.g. when toggling visibility of the
/// "critical" tier).
typedef Severity = InsightSeverity;
