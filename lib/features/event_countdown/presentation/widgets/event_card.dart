import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:polaris/app/theme/color_tokens.dart';
import 'package:polaris/core/l10n/enum_labels.dart';
import 'package:polaris/features/event_countdown/domain/entities/event.dart';
import 'package:polaris/features/event_countdown/domain/value_objects/recurrence.dart';
import 'package:polaris/l10n/generated/app_localizations.dart';
import 'package:polaris/shared/widgets/section_card.dart';

/// One event in the list. Renders countdown badge + title + sub-line +
/// pin / overflow actions. Composable: actions are passed in by the
/// parent so this widget stays generic.
class EventCard extends StatelessWidget {
  const EventCard({
    required this.event,
    required this.now,
    required this.onTap,
    required this.onPinToggle,
    required this.onDelete,
    super.key,
  });

  final Event event;
  final DateTime now;
  final VoidCallback onTap;
  final VoidCallback onPinToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppL l = AppL.of(context);
    final Color accent = _parseColor(event.colorHex, theme.colorScheme.primary);
    final DateTime next = event.nextOccurrence(now);
    final int days = event.daysUntil(now);
    final String subLine = _buildSubLine(context, next, days);

    return SectionCard(
      onTap: onTap,
      leading: _CountdownBadge(days: days, accent: accent),
      trailing: PopupMenuButton<_EventAction>(
        icon: const Icon(Icons.more_vert),
        tooltip: l.eventsActionsMenuLabel,
        onSelected: (action) {
          switch (action) {
            case _EventAction.pin:
              onPinToggle();
            case _EventAction.delete:
              onDelete();
          }
        },
        itemBuilder: (BuildContext context) {
          final AppL m = AppL.of(context);
          return <PopupMenuEntry<_EventAction>>[
            PopupMenuItem<_EventAction>(
              value: _EventAction.pin,
              child: Row(
                children: <Widget>[
                  Icon(
                    event.isPinnedToWidget
                        ? Icons.push_pin
                        : Icons.push_pin_outlined,
                  ),
                  const SizedBox(width: Spacing.x2),
                  Text(
                    event.isPinnedToWidget
                        ? m.eventsActionUnpin
                        : m.eventsActionPin,
                  ),
                ],
              ),
            ),
            PopupMenuItem<_EventAction>(
              value: _EventAction.delete,
              child: Row(
                children: <Widget>[
                  const Icon(Icons.delete_outline),
                  const SizedBox(width: Spacing.x2),
                  Text(m.eventsActionDelete),
                ],
              ),
            ),
          ];
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (event.isPinnedToWidget) ...<Widget>[
                Semantics(
                  label: l.eventsPinnedSemanticLabel,
                  child: Icon(
                    Icons.push_pin,
                    size: 14,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: Spacing.x1),
              ],
              Expanded(
                child: Text(
                  event.title,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.x1),
          Text(subLine, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  String _buildSubLine(BuildContext context, DateTime next, int days) {
    final AppL l = AppL.of(context);
    final String localeTag = Localizations.localeOf(context).toString();
    final String dateLabel = DateFormat.yMMMMd(localeTag).format(next);
    final String recurrenceSuffix = event.recurrence == Recurrence.none
        ? ''
        : ' · ${recurrenceLabel(context, event.recurrence)}';
    final String daysLabel = switch (days) {
      0 => l.eventsCountdownToday,
      1 => l.eventsCountdownTomorrow,
      _ => l.eventsCountdownDays(days),
    };
    return '$dateLabel · $daysLabel$recurrenceSuffix';
  }

  static Color _parseColor(String hex, Color fallback) {
    String clean = hex.replaceFirst('#', '');
    if (clean.length == 6) clean = 'FF$clean';
    if (clean.length != 8) return fallback;
    final int? value = int.tryParse(clean, radix: 16);
    return value == null ? fallback : Color(value);
  }
}

enum _EventAction { pin, delete }

class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({required this.days, required this.accent});

  final int days;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Semantics(
      label: AppL.of(context).eventsCountdownBadgeSemanticLabel(days),
      excludeSemantics: true,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: accent.withValues(alpha: 0.4)),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '$days',
              style: theme.textTheme.titleLarge?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
            Text(
              AppL.of(context).lifeDisplayDays.toLowerCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: accent,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
