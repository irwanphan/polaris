import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:polaris/app/theme/color_tokens.dart';
import 'package:polaris/app/theme/text_styles.dart';
import 'package:polaris/core/l10n/enum_labels.dart';
import 'package:polaris/features/life_countdown/application/display_mode.dart';
import 'package:polaris/features/life_countdown/domain/entities/life_estimate.dart';
import 'package:polaris/l10n/generated/app_localizations.dart';

/// Hero countdown display with soft pastel gradients and radial glow.
///
/// Inspired by the Lovable prototype: prominent number, soft elevation,
/// rounded card with gradient background and glow effect for a "gemas"
/// (charming/cute) aesthetic that feels motivational rather than clinical.
class CountdownDisplay extends StatelessWidget {
  const CountdownDisplay({
    required this.estimate,
    required this.mode,
    super.key,
  });

  final LifeEstimate estimate;
  final DisplayMode mode;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final _DisplayValue value = _resolve(context, estimate, mode);
    final AppL l = AppL.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Semantics(
      label: l.lifeCountdownSemanticLabel(value.primary, value.unit),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.x4),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.xl2),
            gradient: RadialGradient(
              colors: isDark
                  ? <Color>[
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                      theme.colorScheme.surface,
                    ]
                  : <Color>[
                      theme.colorScheme.primary.withValues(alpha: 0.08),
                      theme.colorScheme.surface,
                    ],
              center: Alignment.topCenter,
              radius: 1.5,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                blurRadius: 32,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.x6,
              vertical: Spacing.x8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.xl2),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        colors: <Color>[
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds);
                    },
                    child: Text(
                      value.primary,
                      style: TextStyles.displayXl.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.x3),
                Text(
                  value.unit,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (value.secondary != null) ...<Widget>[
                  const SizedBox(height: Spacing.x6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.x4,
                      vertical: Spacing.x2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(Radii.full),
                    ),
                    child: Text(
                      value.secondary!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                if (mode == DisplayMode.days) ...<Widget>[
                  const SizedBox(height: Spacing.x4),
                  _LifeProgressChips(estimate: estimate),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  _DisplayValue _resolve(
    BuildContext context,
    LifeEstimate est,
    DisplayMode mode,
  ) {
    final String localeTag = Localizations.localeOf(context).toString();
    final NumberFormat thousands = NumberFormat.decimalPattern(localeTag);
    final NumberFormat oneDecimal = NumberFormat('#,##0.0', localeTag);
    final NumberFormat twoDecimal = NumberFormat('#,##0.00', localeTag);
    final AppL l = AppL.of(context);

    return switch (mode) {
      DisplayMode.days => _DisplayValue(
        primary: thousands.format(est.remainingDays),
        unit: displayModeUnitLabel(context, mode),
        secondary: l.lifeAlreadyLived(
          est.livedDays,
          thousands.format(est.livedDays),
        ),
      ),
      DisplayMode.weeks => _DisplayValue(
        primary: thousands.format(est.remainingWeeks),
        unit: displayModeUnitLabel(context, mode),
      ),
      DisplayMode.months => _DisplayValue(
        primary: thousands.format(est.remainingMonths),
        unit: displayModeUnitLabel(context, mode),
      ),
      DisplayMode.years => _DisplayValue(
        primary: oneDecimal.format(est.remainingYears),
        unit: displayModeUnitLabel(context, mode),
      ),
      DisplayMode.percent => _DisplayValue(
        primary: '${twoDecimal.format(est.percentLived)}%',
        unit: displayModeUnitLabel(context, mode),
      ),
    };
  }
}

class _DisplayValue {
  const _DisplayValue({
    required this.primary,
    required this.unit,
    this.secondary,
  });

  final String primary;
  final String unit;
  final String? secondary;
}

/// Life progress chips showing days lived and percentage.
///
/// Displayed as small rounded badges below the main countdown number
/// in days mode only, providing additional context without overwhelming
/// the hero display.
class _LifeProgressChips extends StatelessWidget {
  const _LifeProgressChips({required this.estimate});

  final LifeEstimate estimate;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String localeTag = Localizations.localeOf(context).toString();
    final NumberFormat thousands = NumberFormat.decimalPattern(localeTag);
    final NumberFormat twoDecimal = NumberFormat('#,##0.00', localeTag);
    final AppL l = AppL.of(context);

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: Spacing.x2,
      runSpacing: Spacing.x2,
      children: <Widget>[
        _ProgressChip(
          label: l.lifeAlreadyLived(
            estimate.livedDays,
            thousands.format(estimate.livedDays),
          ),
          color: theme.colorScheme.tertiary,
        ),
        _ProgressChip(
          label: '${twoDecimal.format(estimate.percentLived)}% ${l.lifePercentLived}',
          color: theme.colorScheme.secondary,
        ),
      ],
    );
  }
}

class _ProgressChip extends StatelessWidget {
  const _ProgressChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.x3,
        vertical: Spacing.x1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
