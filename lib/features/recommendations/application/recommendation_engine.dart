import 'package:polaris/features/recommendations/domain/entities/insight.dart';
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
/// Adding a rule means appending to the list passed at construction
/// — no change here. Adding a new severity tier also requires no
/// change here because we sort on the enum `index`.
class RecommendationEngine {
  const RecommendationEngine(this.rules);

  final List<RecommendationRule> rules;

  List<Insight> evaluate(LifestyleSnapshot snapshot) {
    final List<Insight> raw = <Insight>[];
    for (final RecommendationRule rule in rules) {
      final Insight? out = rule.evaluate(snapshot);
      if (out != null) raw.add(out);
    }
    raw.sort(
      (Insight a, Insight b) => b.severity.index.compareTo(a.severity.index),
    );
    return List<Insight>.unmodifiable(raw);
  }

  /// Convenience for callers that want to enforce a maximum number
  /// of cards on screen (the home insight slot only has room for a
  /// few).
  List<Insight> evaluateTop(LifestyleSnapshot snapshot, {required int max}) {
    final List<Insight> all = evaluate(snapshot);
    if (all.length <= max) return all;
    return List<Insight>.unmodifiable(all.take(max));
  }
}

/// Re-exported so call sites have a single import for the type +
/// the constants they need (e.g. when toggling visibility of the
/// "critical" tier).
typedef Severity = InsightSeverity;
