import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/app/theme/color_tokens.dart';
import 'package:polaris/features/life_countdown/application/life_pin_controller.dart';
import 'package:polaris/features/life_countdown/application/providers.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/life_pin_preferences.dart';
import 'package:polaris/l10n/generated/app_localizations.dart';

/// Modal bottom sheet for pinning the life countdown to the home-screen
/// widget with an optional custom message.
///
/// Behaviour:
///   - Reads the current [LifePinPreferences] from the repository so
///     the toggle and message field preserve prior choices.
///   - On Save: routes through [LifePinController] which enforces the
///     mutual-exclusivity invariant (pinning life unpins any pinned
///     event) and triggers a widget refresh.
///   - The custom message survives unpinning so re-pinning later
///     restores it without retyping.
class LifePinSheet extends ConsumerStatefulWidget {
  const LifePinSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const LifePinSheet(),
    );
  }

  @override
  ConsumerState<LifePinSheet> createState() => _LifePinSheetState();
}

class _LifePinSheetState extends ConsumerState<LifePinSheet> {
  late final TextEditingController _messageCtrl;
  late bool _pinned;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final LifePinPreferences current =
        ref.read(lifePinRepositoryProvider).read();
    _pinned = current.pinned;
    _messageCtrl = TextEditingController(text: current.customMessage ?? '');
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _submitting = true);
    try {
      final LifePinController ctrl = ref.read(lifePinControllerProvider);
      final String? msg = _messageCtrl.text.trim().isEmpty
          ? null
          : _messageCtrl.text.trim();
      if (_pinned) {
        await ctrl.pin(customMessage: msg);
      } else {
        await ctrl.updateMessage(msg);
        await ctrl.unpin();
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppL l = AppL.of(context);
    final EdgeInsets viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Spacing.x4,
          Spacing.x2,
          Spacing.x4,
          Spacing.x6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
          Text(
            l.lifePinSheetTitle,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: Spacing.x4),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(l.lifePinToggleLabel),
            subtitle: Text(
              l.lifePinToggleHelper,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            value: _pinned,
            onChanged: _submitting
                ? null
                : (bool next) => setState(() => _pinned = next),
          ),
          const SizedBox(height: Spacing.x3),
          TextField(
            controller: _messageCtrl,
            enabled: !_submitting,
            minLines: 2,
            maxLines: 3,
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l.lifePinCustomMessageLabel,
              helperText: l.lifePinCustomMessageHelper,
              helperMaxLines: 3,
              prefixIcon: const Icon(Icons.format_quote_outlined),
            ),
          ),
          const SizedBox(height: Spacing.x4),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: Text(l.commonCancel),
                ),
              ),
              const SizedBox(width: Spacing.x3),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _save,
                  icon: Icon(
                    _pinned ? Icons.push_pin : Icons.push_pin_outlined,
                  ),
                  label: Text(
                    _submitting
                        ? l.commonSaving
                        : (_pinned ? l.lifePinAction : l.lifePinUnpinAction),
                  ),
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }
}
