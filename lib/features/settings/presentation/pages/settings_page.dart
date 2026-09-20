import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/app/theme/color_tokens.dart';
import 'package:polaris/app/theme/theme_controller.dart';
import 'package:polaris/core/l10n/locale_controller.dart';
import 'package:polaris/features/settings/presentation/widgets/language_picker_tile.dart';
import 'package:polaris/features/settings/presentation/widgets/theme_picker_tile.dart';
import 'package:polaris/l10n/generated/app_localizations.dart';
import 'package:polaris/shared/widgets/polaris_scaffold.dart';
import 'package:polaris/shared/widgets/section_card.dart';

/// User-facing preferences screen.
///
/// P0 ships the theme palette picker (Midnight / Blush / Lavender / Mint /
/// Peach) so users can customize the app's visual feel. Language picker
/// allows switching between system / EN / ID.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL l = AppL.of(context);
    final Locale? selectedLocale = ref.watch(localeControllerProvider);
    final ThemePreferences themePrefs = ref.watch(themeControllerProvider);
    final ThemeData theme = Theme.of(context);

    return PolarisScaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.x1,
              vertical: Spacing.x2,
            ),
            child: Text(
              'APPEARANCE',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
          ),
          SectionCard(
            child: ThemePickerTile(
              selected: themePrefs.palette,
              onChanged: (palette) async {
                await ref.read(themeControllerProvider.notifier).setPalette(palette);
              },
            ),
          ),
          const SizedBox(height: Spacing.x6),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.x1,
              vertical: Spacing.x2,
            ),
            child: Text(
              l.settingsLanguage.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
          ),
          SectionCard(
            padding: EdgeInsets.zero,
            child: LanguagePickerTile(
              selected: selectedLocale,
              onChanged: (Locale? next) {
                ref.read(localeControllerProvider.notifier).setLocale(next);
              },
            ),
          ),
        ],
      ),
    );
  }
}
