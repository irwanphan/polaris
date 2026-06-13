import 'package:flutter/material.dart';
import 'package:polaris/app/theme/color_tokens.dart';
import 'package:polaris/l10n/generated/app_localizations.dart';

/// Three-state language picker (system / en / id).
///
/// Stateless and presentation-only — emits a [Locale]? to its parent
/// (null means "follow the system locale"). The parent owns
/// persistence and applies the choice to `MaterialApp.locale`.
///
/// SOLID: open for extension (add a 4th locale by appending to
/// `_choices`), closed to modification of the tile itself.
class LanguagePickerTile extends StatelessWidget {
  const LanguagePickerTile({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  /// `null` represents "follow the system locale".
  final Locale? selected;
  final ValueChanged<Locale?> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppL l = AppL.of(context);
    final ThemeData theme = Theme.of(context);
    final List<_Choice> choices = <_Choice>[
      _Choice(value: null, label: l.settingsLanguageSystem),
      _Choice(value: const Locale('en'), label: l.settingsLanguageEnglish),
      _Choice(value: const Locale('id'), label: l.settingsLanguageIndonesian),
    ];

    return RadioGroup<Locale?>(
      groupValue: selected,
      onChanged: onChanged,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < choices.length; i++) ...<Widget>[
            if (i > 0)
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
            RadioListTile<Locale?>(
              value: choices[i].value,
              title: Text(choices[i].label),
              secondary: Icon(_iconFor(choices[i].value)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Spacing.x3,
              ),
              visualDensity: VisualDensity.standard,
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(Locale? locale) {
    if (locale == null) return Icons.devices_outlined;
    return Icons.translate_outlined;
  }
}

class _Choice {
  const _Choice({required this.value, required this.label});
  final Locale? value;
  final String label;
}
