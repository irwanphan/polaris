import 'package:polaris/features/lifestyle/domain/value_objects/log_category.dart';
import 'package:polaris/features/recommendations/domain/value_objects/insight_severity.dart';

/// One actionable nudge surfaced to the user.
///
/// Insights are *content*: rules produce them, the UI renders them.
/// The model is intentionally light — no rendering hints beyond
/// [severity] and [relatedCategory] so we can swap surfaces (card,
/// banner, notification, widget) without changing the rules.
class Insight {
  const Insight({
    required this.id,
    required this.severity,
    required this.title,
    required this.body,
    this.relatedCategory,
    this.ctaLabel,
    this.ctaRoute,
  });

  /// Stable, human-readable identifier — same value across runs for
  /// the same rule. Used as a Flutter widget key and for analytics
  /// dedupe (a rule that fires every day shouldn't show twice).
  final String id;

  final InsightSeverity severity;
  final String title;
  final String body;

  /// Optional accent — drives the icon + tint on the card. Null for
  /// rules that aren't tied to a single lifestyle dimension (e.g.
  /// `LifePhaseRule`).
  final LogCategory? relatedCategory;

  /// Optional call-to-action label (e.g. "Log water"). Null hides
  /// the button on the card.
  final String? ctaLabel;

  /// Optional `go_router` path the CTA pushes to (e.g.
  /// `AppRoutes.lifestyle`). Null with a non-null [ctaLabel] is
  /// allowed — the parent decides what to do.
  final String? ctaRoute;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Insight &&
        other.id == id &&
        other.severity == severity &&
        other.title == title &&
        other.body == body &&
        other.relatedCategory == relatedCategory &&
        other.ctaLabel == ctaLabel &&
        other.ctaRoute == ctaRoute;
  }

  @override
  int get hashCode => Object.hash(
    id,
    severity,
    title,
    body,
    relatedCategory,
    ctaLabel,
    ctaRoute,
  );
}
