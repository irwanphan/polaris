import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:polaris/app/theme/color_tokens.dart';
import 'package:polaris/app/theme/text_styles.dart';
import 'package:polaris/core/l10n/enum_labels.dart';
import 'package:polaris/features/life_countdown/application/display_mode.dart';
import 'package:polaris/features/life_countdown/domain/entities/life_estimate.dart';
import 'package:polaris/l10n/generated/app_localizations.dart';

/// Hero number for the life-countdown screen.
///
/// Stateless — given a [LifeEstimate] and a [DisplayMode] it always
/// renders the same output. Animations and tickers live in the parent.
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

    return Semantics(
      label: l.lifeCountdownSemanticLabel(value.primary, value.unit),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // FittedBox guarantees the hero number stays on one line at
          // any text-scale factor (a11y) and at any horizontal width.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value.primary,
              style: TextStyles.displayXl.copyWith(
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: Spacing.x2),
          Text(
            value.unit,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (value.secondary != null) ...<Widget>[
            const SizedBox(height: Spacing.x4),
            Text(
              value.secondary!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
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
