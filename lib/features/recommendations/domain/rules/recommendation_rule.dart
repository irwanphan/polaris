import 'package:polaris/features/recommendations/domain/entities/insight.dart';
import 'package:polaris/features/recommendations/domain/snapshot/lifestyle_snapshot.dart';

/// Single-rule contract: take a snapshot, decide whether *this* rule
/// has something to say. Returning `null` means "no insight from me
/// right now" — far cleaner than throwing or returning a sentinel.
///
/// Rules are pure functions of the snapshot: same input → same
/// output. No `BuildContext`, no `Ref`, no I/O. This makes every
/// rule a one-file, one-test unit; the engine just orchestrates.
///
/// Add a rule: implement this interface, register it in
/// `application/providers.dart::defaultRuleSet`. Engine code does
/// not change.
abstract interface class RecommendationRule {
  /// Stable identifier — matches the [Insight.id] this rule emits so
  /// the UI can attach widget keys + analytics without ever knowing
  /// concrete rule classes.
  String get id;

  Insight? evaluate(LifestyleSnapshot snapshot);
}
