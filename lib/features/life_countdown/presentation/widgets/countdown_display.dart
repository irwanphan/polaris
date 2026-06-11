import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:polaris/app/theme/color_tokens.dart';
import 'package:polaris/app/theme/text_styles.dart';
import 'package:polaris/features/life_countdown/application/display_mode.dart';
import 'package:polaris/features/life_countdown/domain/entities/life_estimate.dart';

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
    final _DisplayValue value = _resolve(estimate, mode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          value.primary,
          style: TextStyles.displayXl.copyWith(
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
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
    );
  }

  _DisplayValue _resolve(LifeEstimate est, DisplayMode mode) {
    final NumberFormat thousands = NumberFormat.decimalPattern();
    final NumberFormat oneDecimal = NumberFormat('#,##0.0');
    final NumberFormat twoDecimal = NumberFormat('#,##0.00');

    return switch (mode) {
      DisplayMode.days => _DisplayValue(
          primary: thousands.format(est.remainingDays),
          unit: 'DAYS REMAINING',
          secondary:
              '${thousands.format(est.livedDays)} days already lived',
        ),
      DisplayMode.weeks => _DisplayValue(
          primary: thousands.format(est.remainingWeeks),
          unit: 'WEEKS REMAINING',
        ),
      DisplayMode.months => _DisplayValue(
          primary: thousands.format(est.remainingMonths),
          unit: 'MONTHS REMAINING',
        ),
      DisplayMode.years => _DisplayValue(
          primary: oneDecimal.format(est.remainingYears),
          unit: 'YEARS REMAINING',
        ),
      DisplayMode.percent => _DisplayValue(
          primary: '${twoDecimal.format(est.percentLived)}%',
          unit: 'OF LIFE LIVED',
          secondary:
              '${twoDecimal.format(100 - est.percentLived)}% remaining',
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
