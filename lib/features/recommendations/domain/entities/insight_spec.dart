import 'package:polaris/features/lifestyle/domain/value_objects/log_category.dart';
import 'package:polaris/features/recommendations/domain/value_objects/insight_severity.dart';

/// Domain-side description of a single insight, free of any
/// presentation or localization concerns.
///
/// Rules emit specs (pure data); the presentation layer's
/// [InsightContent] resolver turns each spec into a localized
/// [Insight] just before rendering. The split keeps:
///
///   - **Rules pure**: no `AppL`, no `BuildContext`, no string
///     constants. A rule is "I see N short nights, fire spec
///     `sleep_regularity` with `{shortCount, totalCount}`".
///   - **L10n centralized**: every title / body / CTA lookup lives
///     in `InsightContent`, so adding a language is one file.
///   - **Tests stable**: assert on spec ids and args — no fragile
///     copy-comparison tests that break every wording tweak.
class InsightSpec {
  const InsightSpec({
    required this.id,
    required this.contentKey,
    required this.severity,
    this.relatedCategory,
    this.ctaRoute,
    this.args = const <String, Object>{},
    this.dismissCooldown = const Duration(days: 7),
  });

  /// Stable, dismissal-grade identifier. Two specs with the same
  /// [id] are treated as "the same nudge" by the dismissal layer,
  /// so variants that should be dismissed independently must use
  /// distinct ids (e.g. `life_phase:25` vs `life_phase:50`).
  final String id;

  /// L10n template selector. Multiple [id]s can share a
  /// [contentKey] when they only differ in arguments — e.g. every
  /// `life_phase:*` id resolves through the single `life_phase`
  /// content key, with `args['pct']` controlling the headline.
  final String contentKey;

  final InsightSeverity severity;

  /// Optional accent — drives the icon + tint on the card. Null
  /// for rules that aren't tied to a single lifestyle dimension
  /// (e.g. `LifePhaseRule`).
  final LogCategory? relatedCategory;

  /// Optional `go_router` path the CTA pushes to (e.g.
  /// `/lifestyle`). Null with a non-null CTA label is allowed —
  /// the parent decides what to do.
  final String? ctaRoute;

  /// Per-spec interpolation arguments. Keys are agreed-upon
  /// strings (documented per [contentKey] in `InsightContent`).
  /// Values are restricted to `int`, `double`, `String` so the
  /// resolver can pattern-match safely.
  final Map<String, Object> args;

  /// How long this insight should stay hidden after the user
  /// dismisses it. Rules surface this so the cooldown can match
  /// the cadence of the underlying signal (e.g. a 30-day life-
  /// phase milestone vs a 3-day water-target nudge).
  final Duration dismissCooldown;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InsightSpec &&
        other.id == id &&
        other.contentKey == contentKey &&
        other.severity == severity &&
        other.relatedCategory == relatedCategory &&
        other.ctaRoute == ctaRoute &&
        _argsEqual(other.args, args) &&
        other.dismissCooldown == dismissCooldown;
  }

  @override
  int get hashCode => Object.hash(
    id,
    contentKey,
    severity,
    relatedCategory,
    ctaRoute,
    // Map.hashCode is identity-based; round-trip via a sorted
    // entry list so two specs with the same args hash equal.
    Object.hashAll(
      (args.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
          .map((e) => Object.hash(e.key, e.value)),
    ),
    dismissCooldown,
  );

  static bool _argsEqual(Map<String, Object> a, Map<String, Object> b) {
    if (a.length != b.length) return false;
    for (final MapEntry<String, Object> entry in a.entries) {
      if (!b.containsKey(entry.key)) return false;
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
