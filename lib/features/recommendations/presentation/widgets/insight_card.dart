import 'package:flutter/material.dart';
import 'package:polaris/app/theme/color_tokens.dart';
import 'package:polaris/features/lifestyle/domain/value_objects/log_category.dart';
import 'package:polaris/features/lifestyle/presentation/widgets/category_icons.dart';
import 'package:polaris/features/recommendations/domain/entities/insight.dart';
import 'package:polaris/features/recommendations/domain/value_objects/insight_severity.dart';

/// One [Insight] rendered as a card.
///
/// Stateless and presentation-only — the parent supplies an
/// [onActionTap] when the [Insight.ctaLabel] should be actionable.
/// Severity drives the accent colour via a tiny mapper so the rule
/// authors never reach for a `Color`.
class InsightCard extends StatelessWidget {
  const InsightCard({required this.insight, this.onActionTap, super.key});

  final Insight insight;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final _Tone tone = _toneFor(cs, insight.severity);
    final IconData icon = _iconFor(insight);

    return Container(
      decoration: BoxDecoration(
        color: tone.background,
        border: Border.all(color: tone.border),
        borderRadius: BorderRadius.circular(Radii.xl),
      ),
      padding: const EdgeInsets.all(Spacing.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tone.iconBg,
                  borderRadius: BorderRadius.circular(Radii.lg),
                ),
                child: Icon(icon, size: 20, color: tone.iconFg),
              ),
              const SizedBox(width: Spacing.x3),
              Expanded(
                child: Text(
                  insight.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: tone.title,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.x3),
          Text(
            insight.body,
            style: theme.textTheme.bodyMedium?.copyWith(color: tone.body),
          ),
          if (insight.ctaLabel != null) ...<Widget>[
            const SizedBox(height: Spacing.x3),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onActionTap,
                style: TextButton.styleFrom(foregroundColor: tone.cta),
                child: Text(insight.ctaLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static IconData _iconFor(Insight insight) {
    final LogCategory? category = insight.relatedCategory;
    if (category != null) return iconFor(category);
    return switch (insight.severity) {
      InsightSeverity.info => Icons.lightbulb_outline,
      InsightSeverity.encourage => Icons.favorite_outline,
      InsightSeverity.warn => Icons.warning_amber_outlined,
      InsightSeverity.critical => Icons.priority_high,
    };
  }

  static _Tone _toneFor(ColorScheme cs, InsightSeverity severity) {
    // We keep palette decisions in one place so adding a 5th
    // severity (or rebranding) is a single switch case rather than
    // a hunt across files. Colours are chosen from the existing
    // ColorScheme — never hard-coded — so dark mode just works.
    return switch (severity) {
      InsightSeverity.info => _Tone(
        background: cs.primaryContainer.withValues(alpha: 0.35),
        border: cs.primary.withValues(alpha: 0.25),
        iconBg: cs.primary.withValues(alpha: 0.15),
        iconFg: cs.primary,
        title: cs.onSurface,
        body: cs.onSurfaceVariant,
        cta: cs.primary,
      ),
      InsightSeverity.encourage => _Tone(
        background: cs.secondaryContainer.withValues(alpha: 0.35),
        border: cs.secondary.withValues(alpha: 0.25),
        iconBg: cs.secondary.withValues(alpha: 0.15),
        iconFg: cs.secondary,
        title: cs.onSurface,
        body: cs.onSurfaceVariant,
        cta: cs.secondary,
      ),
      InsightSeverity.warn => _Tone(
        background: cs.tertiaryContainer.withValues(alpha: 0.35),
        border: cs.tertiary.withValues(alpha: 0.4),
        iconBg: cs.tertiary.withValues(alpha: 0.15),
        iconFg: cs.tertiary,
        title: cs.onSurface,
        body: cs.onSurfaceVariant,
        cta: cs.tertiary,
      ),
      InsightSeverity.critical => _Tone(
        background: cs.errorContainer.withValues(alpha: 0.35),
        border: cs.error.withValues(alpha: 0.5),
        iconBg: cs.error.withValues(alpha: 0.15),
        iconFg: cs.error,
        title: cs.onSurface,
        body: cs.onSurfaceVariant,
        cta: cs.error,
      ),
    };
  }
}

class _Tone {
  const _Tone({
    required this.background,
    required this.border,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.body,
    required this.cta,
  });

  final Color background;
  final Color border;
  final Color iconBg;
  final Color iconFg;
  final Color title;
  final Color body;
  final Color cta;
}
