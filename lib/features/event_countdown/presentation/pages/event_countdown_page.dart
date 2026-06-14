import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polaris/app/router.dart';
import 'package:polaris/app/theme/color_tokens.dart';
import 'package:polaris/features/event_countdown/application/events_controller.dart';
import 'package:polaris/features/event_countdown/application/providers.dart';
import 'package:polaris/features/event_countdown/domain/entities/event.dart';
import 'package:polaris/features/event_countdown/presentation/widgets/event_card.dart';
import 'package:polaris/features/event_countdown/presentation/widgets/event_editor_sheet.dart';
import 'package:polaris/l10n/generated/app_localizations.dart';
import 'package:polaris/shared/widgets/polaris_scaffold.dart';

class EventCountdownPage extends ConsumerWidget {
  const EventCountdownPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Event>> events = ref.watch(eventsStreamProvider);
    final DateTime now = DateTime.now();
    final AppL l = AppL.of(context);

    return PolarisScaffold(
      appBar: AppBar(title: Text(l.navEvents)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => EventEditorSheet.show(context),
        icon: const Icon(Icons.add),
        label: Text(l.eventsNewEvent),
      ),
      body: events.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) =>
            Center(child: Text(l.lifestyleLoadFailed(e.toString()))),
        data: (List<Event> list) {
          if (list.isEmpty) return const _EmptyState();
          return _EventsList(events: list, now: now);
        },
      ),
    );
  }
}

class _EventsList extends ConsumerWidget {
  const _EventsList({required this.events, required this.now});

  final List<Event> events;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 96), // breathing room for FAB
      itemCount: events.length,
      separatorBuilder: (_, _) => const SizedBox(height: Spacing.x3),
      itemBuilder: (BuildContext context, int index) {
        final Event event = events[index];
        return EventCard(
          event: event,
          now: now,
          // Tapping a row now opens the detail page (Event Detail
          // route added alongside the widget / notification deep
          // links). Edit lives behind the detail page's overflow
          // menu — the row tap is read-mostly.
          onTap: () => context.push(AppRoutes.eventDetail(event.id)),
          onPinToggle: () => _handlePinToggle(context, ref, event),
          onDelete: () => _confirmDelete(context, ref, event),
        );
      },
    );
  }

  Future<void> _handlePinToggle(
    BuildContext context,
    WidgetRef ref,
    Event event,
  ) async {
    final AppL l = AppL.of(context);
    final result = await ref
        .read(eventsControllerProvider)
        .togglePin(id: event.id, isCurrentlyPinned: event.isPinnedToWidget);
    if (!context.mounted) return;
    if (result.isErr) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.eventsPinFailed(result.failureOrNull.toString())),
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Event event,
  ) async {
    final AppL l = AppL.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        final AppL dl = AppL.of(ctx);
        return AlertDialog(
          title: Text(dl.eventsDeleteConfirmTitle),
          content: Text(dl.eventsDeleteConfirmBody(event.title)),
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

    final result = await ref
        .read(eventsControllerProvider)
        .deleteEvent(event.id);
    if (!context.mounted) return;
    if (result.isErr) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.eventsDeleteFailed(result.failureOrNull.toString())),
        ),
      );
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              Icons.event_available_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: Spacing.x4),
            Text(
              l.eventsEmptyTitle,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.x2),
            Text(
              l.eventsEmptyBody,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
