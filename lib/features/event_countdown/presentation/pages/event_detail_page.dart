import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:polaris/app/router.dart';
import 'package:polaris/app/theme/color_tokens.dart';
import 'package:polaris/core/l10n/enum_labels.dart';
import 'package:polaris/features/event_countdown/application/events_controller.dart';
import 'package:polaris/features/event_countdown/application/providers.dart';
import 'package:polaris/features/event_countdown/domain/entities/event.dart';
import 'package:polaris/features/event_countdown/domain/value_objects/recurrence.dart';
import 'package:polaris/features/event_countdown/presentation/widgets/event_editor_sheet.dart';
import 'package:polaris/l10n/generated/app_localizations.dart';
import 'package:polaris/shared/widgets/polaris_scaffold.dart';
import 'package:polaris/shared/widgets/section_card.dart';

/// Standalone page for one event.
///
/// Routed under the events branch as `/events/:id` (see `app/router.dart`),
/// reachable from:
///   - tapping a row in the events list,
///   - tapping a row in the home-screen widget (deep link →
///     `polaris://events/<id>`),
///   - tapping a scheduled notification (payload carries the event id).
///
/// Reads the event reactively via [eventByIdProvider] so edits, pin
/// toggles, and deletes propagate without an extra fetch. When the
/// id no longer resolves (typical right after the user deletes the
/// event from this very page), the page pops automatically back to
/// the list.
class EventDetailPage extends ConsumerStatefulWidget {
  const EventDetailPage({required this.eventId, super.key});

  final String eventId;

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage> {
  /// Tracks whether we've already navigated away in response to a
  /// data(null) state. Without this the listener can fire repeatedly
  /// (the provider re-emits whenever upstream data changes) and try
  /// to pop a page that is no longer on the stack.
  bool _navigatedAway = false;

  @override
  Widget build(BuildContext context) {
    final AppL l = AppL.of(context);
    final AsyncValue<Event?> async = ref.watch(eventByIdProvider(widget.eventId));

    // Listen separately so the auto-pop fires once when the event
    // disappears (e.g. user tapped Delete on this page).
    ref.listen<AsyncValue<Event?>>(eventByIdProvider(widget.eventId), (
      AsyncValue<Event?>? prev,
      AsyncValue<Event?> next,
    ) {
      final bool wasPresent = prev?.value != null;
      final bool isAbsent = next.hasValue && next.value == null;
      if (!wasPresent || !isAbsent || _navigatedAway) return;
      _navigatedAway = true;
      if (!context.mounted) return;
      // Prefer pop() so we land back on the previous route in the
      // navigation stack; fall back to the events list as a hard
      // safety if this page was the first route (shouldn't happen
      // in practice — deep links always push above the list).
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.events);
      }
    });

    return PolarisScaffold(
      appBar: AppBar(
        title: Text(l.eventDetailTitle),
        actions: <Widget>[
          _PinActionButton(event: async.value),
          _OverflowMenu(event: async.value),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => _NotFoundView(message: e.toString()),
        data: (Event? event) {
          if (event == null) return const _NotFoundView();
          return _DetailBody(event: event);
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppL l = AppL.of(context);
    final String localeTag = Localizations.localeOf(context).toString();
    final DateTime now = DateTime.now();
    final DateTime next = event.nextOccurrence(now);
    final int days = event.daysUntil(now);
    final Color accent = _parseColor(event.colorHex, theme.colorScheme.primary);
    final DateFormat fullDate = DateFormat.yMMMMEEEEd(localeTag);
    final DateFormat shortDate = DateFormat.yMMMd(localeTag);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            event.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Spacing.x2),
          _BadgeRow(event: event, accent: accent),
          const SizedBox(height: Spacing.x4),
          _HeroCountdownCard(
            days: days,
            accent: accent,
            nextDateLabel: fullDate.format(next),
            unit: l.eventDetailUnitDays,
            isPast: days <= 0 && event.recurrence == Recurrence.none,
          ),
          const SizedBox(height: Spacing.x4),
          _Section(
            title: l.eventDetailNextOccurrence,
            child: Text(
              fullDate.format(next),
              style: theme.textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: Spacing.x3),
          _Section(
            title: l.eventDetailSectionNote,
            child: Text(
              event.note ?? l.eventDetailSectionNoNote,
              style: event.note == null
                  ? theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    )
                  : theme.textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: Spacing.x3),
          _Section(
            title: l.eventDetailSectionWidgetMessage,
            child: Text(
              event.widgetMessage ?? l.eventDetailSectionNoWidgetMessage,
              style: event.widgetMessage == null
                  ? theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    )
                  : theme.textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: Spacing.x4),
          Text(
            l.eventDetailMetaCreated(shortDate.format(event.createdAt)),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (event.updatedAt != event.createdAt)
            Text(
              l.eventDetailMetaUpdated(shortDate.format(event.updatedAt)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: Spacing.x6),
        ],
      ),
    );
  }

  static Color _parseColor(String hex, Color fallback) {
    String clean = hex.replaceFirst('#', '');
    if (clean.length == 6) clean = 'FF$clean';
    if (clean.length != 8) return fallback;
    final int? value = int.tryParse(clean, radix: 16);
    return value == null ? fallback : Color(value);
  }
}

/// Compact row of "Repeats Yearly" / "One-off" + "Pinned" affordances.
class _BadgeRow extends StatelessWidget {
  const _BadgeRow({required this.event, required this.accent});

  final Event event;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final AppL l = AppL.of(context);
    return Wrap(
      spacing: Spacing.x2,
      runSpacing: Spacing.x2,
      children: <Widget>[
        _Pill(
          color: accent,
          label: event.recurrence == Recurrence.none
              ? l.eventDetailLifetimeBadge
              : l.eventDetailRepeatsBadge(
                  recurrenceLabel(context, event.recurrence),
                ),
          icon: event.recurrence == Recurrence.none
              ? Icons.event_outlined
              : Icons.autorenew,
        ),
        if (event.isPinnedToWidget)
          _Pill(
            color: Theme.of(context).colorScheme.secondary,
            label: l.eventsPinnedSemanticLabel,
            icon: Icons.push_pin,
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.color,
    required this.label,
    required this.icon,
  });

  final Color color;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.x3,
        vertical: Spacing.x1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Radii.full),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: Spacing.x1),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Large hero card showing the days-remaining number + unit + next
/// date. Mirrors the energy of the Life tab's countdown so the user
/// gets the same "this is the headline" affordance.
class _HeroCountdownCard extends StatelessWidget {
  const _HeroCountdownCard({
    required this.days,
    required this.accent,
    required this.nextDateLabel,
    required this.unit,
    required this.isPast,
  });

  final int days;
  final Color accent;
  final String nextDateLabel;
  final String unit;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppL l = AppL.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.x4,
        vertical: Spacing.x6,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: <Widget>[
          Text(
            isPast ? l.eventDetailPast : '$days',
            style: theme.textTheme.displayMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: Spacing.x2),
          Text(
            unit,
            style: theme.textTheme.labelLarge?.copyWith(
              color: accent,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: Spacing.x3),
          Text(
            nextDateLabel,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.0,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.x2),
          child,
        ],
      ),
    );
  }
}

/// AppBar pin-toggle. Renders as a filled-or-outlined push pin and
/// is gated on the event being loaded.
class _PinActionButton extends ConsumerWidget {
  const _PinActionButton({required this.event});

  final Event? event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Event? e = event;
    if (e == null) return const SizedBox.shrink();
    final AppL l = AppL.of(context);
    return IconButton(
      tooltip: e.isPinnedToWidget ? l.eventsActionUnpin : l.eventsActionPin,
      icon: Icon(e.isPinnedToWidget ? Icons.push_pin : Icons.push_pin_outlined),
      onPressed: () async {
        final result = await ref.read(eventsControllerProvider).togglePin(
          id: e.id,
          isCurrentlyPinned: e.isPinnedToWidget,
        );
        if (!context.mounted) return;
        if (result.isErr) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l.eventsPinFailed(result.failureOrNull.toString())),
            ),
          );
        }
      },
    );
  }
}

/// AppBar overflow menu — Edit (opens the editor sheet) + Delete
/// (with confirm dialog). Edit / Delete live behind the menu instead
/// of as primary actions because the page is read-mostly: most
/// users open the detail to look, not to act.
class _OverflowMenu extends ConsumerWidget {
  const _OverflowMenu({required this.event});

  final Event? event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Event? e = event;
    if (e == null) return const SizedBox.shrink();
    final AppL l = AppL.of(context);
    return PopupMenuButton<_Action>(
      tooltip: l.eventsActionsMenuLabel,
      onSelected: (action) {
        switch (action) {
          case _Action.edit:
            EventEditorSheet.show(context, original: e);
          case _Action.delete:
            _confirmDelete(context, ref, e);
        }
      },
      itemBuilder: (BuildContext context) {
        final AppL m = AppL.of(context);
        return <PopupMenuEntry<_Action>>[
          PopupMenuItem<_Action>(
            value: _Action.edit,
            child: Row(
              children: <Widget>[
                const Icon(Icons.edit_outlined),
                const SizedBox(width: Spacing.x2),
                Text(m.eventDetailEdit),
              ],
            ),
          ),
          PopupMenuItem<_Action>(
            value: _Action.delete,
            child: Row(
              children: <Widget>[
                const Icon(Icons.delete_outline),
                const SizedBox(width: Spacing.x2),
                Text(m.eventDetailDelete),
              ],
            ),
          ),
        ];
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Event e,
  ) async {
    final AppL l = AppL.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        final AppL dl = AppL.of(ctx);
        return AlertDialog(
          title: Text(dl.eventsDeleteConfirmTitle),
          content: Text(dl.eventsDeleteConfirmBody(e.title)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(dl.commonCancel),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(dl.commonDelete),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    final result = await ref.read(eventsControllerProvider).deleteEvent(e.id);
    if (!context.mounted) return;
    if (result.isErr) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.eventsDeleteFailed(result.failureOrNull.toString())),
        ),
      );
    }
    // Pop is handled by the auto-pop listener in [_EventDetailPageState]
    // once the underlying event stream emits the deletion.
  }
}

enum _Action { edit, delete }

/// Rendered when the requested id no longer exists (deleted between
/// the deep link being fired and resolving) or fails to load.
class _NotFoundView extends StatelessWidget {
  const _NotFoundView({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppL l = AppL.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.search_off,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: Spacing.x4),
            Text(
              l.eventDetailNotFoundTitle,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.x2),
            Text(
              message ?? l.eventDetailNotFoundBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.x4),
            FilledButton.tonal(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.events);
                }
              },
              child: Text(l.eventDetailBackToList),
            ),
          ],
        ),
      ),
    );
  }
}
