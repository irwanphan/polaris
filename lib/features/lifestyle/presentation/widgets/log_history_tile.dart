import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:polaris/app/theme/color_tokens.dart';
import 'package:polaris/features/lifestyle/domain/entities/lifestyle_log.dart';
import 'package:polaris/features/lifestyle/presentation/widgets/category_icons.dart';

/// Compact single-row history entry. Used inside the 7-day history
/// list under the today summary.
///
/// Renders: [category icon] [value + unit + label] [note] [time ago].
/// Delegates the actual delete confirmation to the parent so this
/// widget stays presentation-only.
class LogHistoryTile extends StatelessWidget {
  const LogHistoryTile({required this.log, required this.onDelete, super.key});

  final LifestyleLog log;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final String valueText = _formatValue(log);
    final String whenText = _formatWhen(log.loggedAt);

    return Dismissible(
      key: ValueKey<String>('log-${log.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.x4),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        child: Icon(Icons.delete_outline, color: cs.onErrorContainer),
      ),
      confirmDismiss: (_) async {
        onDelete();
        // Returning false keeps the row visible until the parent
        // confirms the delete and the underlying stream removes it.
        // Avoids "ghost" flicker if the user cancels.
        return false;
      },
      child: Container(
        padding: const EdgeInsets.all(Spacing.x3),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Icon(
                iconFor(log.category),
                size: 18,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: Spacing.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    valueText,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (log.note != null) ...<Widget>[
                    const SizedBox(height: Spacing.x1),
                    Text(
                      log.note!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Text(
              whenText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatValue(LifestyleLog log) {
    final String number = log.category.isInteger
        ? log.value.toInt().toString()
        : log.value.toStringAsFixed(1);
    return '${log.category.label} • $number ${log.category.unit}';
  }

  static String _formatWhen(DateTime when) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime entryDay = DateTime(when.year, when.month, when.day);
    final int daysAgo = today.difference(entryDay).inDays;
    if (daysAgo == 0) return DateFormat.jm().format(when);
    if (daysAgo == 1) return 'Yesterday';
    if (daysAgo < 7) return '${daysAgo}d ago';
    return DateFormat.MMMd().format(when);
  }
}
