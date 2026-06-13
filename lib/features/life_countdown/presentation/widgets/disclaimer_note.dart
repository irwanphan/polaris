import 'package:flutter/material.dart';
import 'package:polaris/app/theme/color_tokens.dart';
import 'package:polaris/l10n/generated/app_localizations.dart';

/// Tone-conscious disclaimer attached to every life-countdown surface.
///
/// Required by `BRD §5.1` ("Disclaimer: Estimation only, not medical
/// prediction") and risk R2 in `BRD §13`.
class DisclaimerNote extends StatelessWidget {
  const DisclaimerNote({super.key});

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
            AppL.of(context).onboardingDisclaimer,
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
