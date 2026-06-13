import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/app/theme/color_tokens.dart';
import 'package:polaris/core/l10n/locale_controller.dart';
import 'package:polaris/features/settings/presentation/widgets/language_picker_tile.dart';
import 'package:polaris/l10n/generated/app_localizations.dart';
import 'package:polaris/shared/widgets/polaris_scaffold.dart';
import 'package:polaris/shared/widgets/section_card.dart';

/// User-facing preferences screen.
///
/// M6 ships the language picker (system / EN / ID) so beta testers
/// in ID can validate Bahasa Indonesia copy. Other knobs (theme,
/// hide-countdown, danger zone) are stubbed with empty handlers
/// here and will be wired in follow-up milestones.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL l = AppL.of(context);
    final Locale? selected = ref.watch(localeControllerProvider);
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
              selected: selected,
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
