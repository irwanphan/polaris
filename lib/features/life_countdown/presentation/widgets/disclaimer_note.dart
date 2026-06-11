import 'package:flutter/material.dart';
import 'package:polaris/app/theme/color_tokens.dart';

/// Tone-conscious disclaimer attached to every life-countdown surface.
///
/// Required by `BRD §5.1` ("Disclaimer: Estimation only, not medical
/// prediction") and risk R2 in `BRD §13`.
class DisclaimerNote extends StatelessWidget {
  const DisclaimerNote({super.key});

  static const String _text =
      'Estimation only — based on public life-expectancy tables (WHO, BPS). '
      'Not a medical prediction.';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          Icons.info_outline,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: Spacing.x2),
        Expanded(
          child: Text(
            _text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}
