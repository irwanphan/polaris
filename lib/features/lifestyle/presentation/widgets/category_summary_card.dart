import 'package:flutter/material.dart';
import 'package:polaris/app/theme/color_tokens.dart';
import 'package:polaris/core/l10n/enum_labels.dart';
import 'package:polaris/features/lifestyle/domain/value_objects/log_category.dart';
import 'package:polaris/features/lifestyle/presentation/widgets/category_icons.dart';
import 'package:polaris/l10n/generated/app_localizations.dart';

/// Visual summary card for one [LogCategory] on the today dashboard.
///
/// Hosts whatever rollup makes sense per [LogAggregation]:
///   - cumulative: shows "N unit" (sum across the day)
///   - snapshot: shows the latest single value (or em dash if empty)
///
/// Stateless and presentation-only — the parent injects the already
/// computed [displayValue] string so this widget never reaches into
/// providers. That keeps it cheap to reuse from goldens, settings
/// previews, or future M5 recommendation cards.
class CategorySummaryCard extends StatelessWidget {
  const CategorySummaryCard({
    required this.category,
    required this.displayValue,
    required this.onTap,
    this.entriesCount,
    super.key,
  });

  final LogCategory category;
  final String displayValue;
  final VoidCallback onTap;

  /// Optional subtitle — e.g. "3 entries today" for cumulative
  /// categories. Hidden when null.
  final int? entriesCount;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Material(
      color: cs.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(Radii.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.xl),
        child: Container(
          padding: const EdgeInsets.all(Spacing.x4),
          decoration: BoxDecoration(
            border: Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(Radii.xl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(Radii.lg),
                    ),
                    child: Icon(
                      iconFor(category),
                      size: 20,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: Spacing.x3),
                  Expanded(
                    child: Text(
                      logCategoryLabel(context, category),
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ExcludeSemantics(
                    child: Icon(
                      Icons.add_circle,
                      size: 22,
                      color: cs.primary.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.x4),
              Text(
                displayValue,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Spacing.x1),
              Text(
                logCategoryUnit(context, category),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              if (entriesCount != null && entriesCount! > 0) ...<Widget>[
                const SizedBox(height: Spacing.x2),
                Text(
                  AppL.of(context).lifestyleEntriesToday(entriesCount!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
