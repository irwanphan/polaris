import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:polaris/app/theme/color_tokens.dart';
import 'package:polaris/features/event_countdown/domain/entities/event.dart';
import 'package:polaris/features/event_countdown/domain/value_objects/recurrence.dart';
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
    final Color accent = _parseColor(event.colorHex, theme.colorScheme.primary);
    final DateTime next = event.nextOccurrence(now);
    final int days = event.daysUntil(now);
    final String subLine = _buildSubLine(next, days);

    return SectionCard(
      onTap: onTap,
      leading: _CountdownBadge(days: days, accent: accent),
      trailing: PopupMenuButton<_EventAction>(
        icon: const Icon(Icons.more_vert),
        onSelected: (action) {
          switch (action) {
            case _EventAction.pin:
              onPinToggle();
            case _EventAction.delete:
              onDelete();
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<_EventAction>>[
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
                Text(event.isPinnedToWidget ? 'Unpin' : 'Pin to widget'),
              ],
            ),
          ),
          const PopupMenuItem<_EventAction>(
            value: _EventAction.delete,
            child: Row(
              children: <Widget>[
                Icon(Icons.delete_outline),
                SizedBox(width: Spacing.x2),
                Text('Delete'),
              ],
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (event.isPinnedToWidget) ...<Widget>[
                Icon(
                  Icons.push_pin,
                  size: 14,
                  color: theme.colorScheme.secondary,
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

  String _buildSubLine(DateTime next, int days) {
    final String dateLabel = DateFormat.yMMMMd().format(next);
    final String recurrenceLabel = event.recurrence == Recurrence.none
        ? ''
        : ' · ${event.recurrence.label}';
    final String daysLabel = switch (days) {
      0 => 'Today',
      1 => 'Tomorrow',
      _ => 'in $days days',
    };
    return '$dateLabel · $daysLabel$recurrenceLabel';
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
    return Container(
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
            'days',
            style: theme.textTheme.labelSmall?.copyWith(
              color: accent,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
