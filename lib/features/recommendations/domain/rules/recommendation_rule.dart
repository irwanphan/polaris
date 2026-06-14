import 'package:polaris/features/recommendations/domain/entities/insight_spec.dart';
import 'package:polaris/features/recommendations/domain/snapshot/lifestyle_snapshot.dart';

/// Single-rule contract: take a snapshot, decide whether *this* rule
/// has something to say. Returning `null` means "no insight from me
/// right now" — far cleaner than throwing or returning a sentinel.
///
/// Rules are pure functions of the snapshot: same input → same
/// output. No `BuildContext`, no `Ref`, no I/O, no `AppL` — strings
/// are resolved later by the presentation-layer `InsightContent`
/// resolver from the spec's `contentKey` + `args`. This makes every
/// rule a one-file, one-test unit; the engine just orchestrates.
///
/// Add a rule: implement this interface, register it in
/// `application/providers.dart::defaultRuleSet`. Engine code does
/// not change.
abstract interface class RecommendationRule {
  /// Stable identifier — matches the [InsightSpec.id] prefix this
  /// rule emits so the UI / analytics / dismissal layer can attach
  /// without knowing concrete rule classes. Rules that emit variant
  /// ids (e.g. `life_phase:25`) document the convention in their
  /// implementation.
  String get id;

  InsightSpec? evaluate(LifestyleSnapshot snapshot);
}
