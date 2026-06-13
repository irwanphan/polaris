import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/core/result/result.dart';
import 'package:polaris/core/widgets/home_widget_updater.dart';
import 'package:polaris/core/widgets/providers.dart';
import 'package:polaris/features/event_countdown/application/notification_scheduler.dart';
import 'package:polaris/features/event_countdown/application/providers.dart';
import 'package:polaris/features/event_countdown/domain/entities/event.dart';
import 'package:polaris/features/event_countdown/domain/repositories/event_repository.dart';
import 'package:polaris/features/event_countdown/domain/value_objects/recurrence.dart';

/// Imperative commands for the events feature.
///
/// Reactive reads are exposed via [eventsStreamProvider] — the controller
/// only owns write operations so the read path stays a pure pull stream.
///
/// Side effects (notification scheduling) are dispatched after the
/// repository write succeeds. A scheduling failure is logged inside the
/// scheduler and never propagates — the event always persists.
class EventsController {
  const EventsController(
    this._repository,
    this._scheduler,
    this._widgetUpdater,
  );

  final EventRepository _repository;
  final NotificationScheduler _scheduler;
  final HomeWidgetUpdater _widgetUpdater;

  Future<Result<Event, Object>> createEvent({
    required String title,
    required DateTime targetAt,
    String colorHex = '#6366F1',
    String iconKey = 'event',
    String? note,
    Recurrence recurrence = Recurrence.none,
  }) async {
    final Event event = Event.create(
      title: title.trim(),
      targetAt: targetAt,
      colorHex: colorHex,
      iconKey: iconKey,
      note: _normalizeNote(note),
      recurrence: recurrence,
    );
    final result = await _repository.upsert(event);
    if (result.isOk) {
      await _scheduler.rescheduleFor(event);
      await _widgetUpdater.refresh();
    }
    return result.fold(
      onOk: (_) => Result<Event, Object>.ok(event),
      onErr: Result<Event, Object>.err,
    );
  }

  Future<Result<Event, Object>> updateEvent({
    required Event original,
    required String title,
    required DateTime targetAt,
    required String colorHex,
    required String iconKey,
    required String? note,
    required Recurrence recurrence,
  }) async {
    final Event updated = Event(
      id: original.id,
      title: title.trim(),
      targetAt: targetAt,
      colorHex: colorHex,
      iconKey: iconKey,
      note: _normalizeNote(note),
      recurrence: recurrence,
      isPinnedToWidget: original.isPinnedToWidget,
      createdAt: original.createdAt,
      updatedAt: DateTime.now(),
    );
    final result = await _repository.upsert(updated);
    if (result.isOk) {
      await _scheduler.rescheduleFor(updated);
      await _widgetUpdater.refresh();
    }
    return result.fold(
      onOk: (_) => Result<Event, Object>.ok(updated),
      onErr: Result<Event, Object>.err,
    );
  }

  Future<Result<void, Object>> deleteEvent(String id) async {
    final result = await _repository.delete(id);
    if (result.isOk) {
      await _scheduler.cancelFor(id);
      await _widgetUpdater.refresh();
    }
    return result.fold(
      onOk: (_) => const Result<void, Object>.ok(null),
      onErr: Result<void, Object>.err,
    );
  }

  /// Pins [id], unpinning anything else. Toggling a currently-pinned event
  /// clears the pin entirely.
  Future<Result<void, Object>> togglePin({
    required String id,
    required bool isCurrentlyPinned,
  }) async {
    final result = await _repository.pinExclusive(
      isCurrentlyPinned ? null : id,
    );
    if (result.isOk) {
      await _widgetUpdater.refresh();
    }
    return result.fold(
      onOk: (_) => const Result<void, Object>.ok(null),
      onErr: Result<void, Object>.err,
    );
  }

  static String? _normalizeNote(String? raw) {
    if (raw == null) return null;
    final String trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

final Provider<EventsController> eventsControllerProvider =
    Provider<EventsController>(
      (ref) => EventsController(
        ref.watch(eventRepositoryProvider),
        ref.watch(notificationSchedulerProvider),
        ref.watch(homeWidgetUpdaterProvider),
      ),
    );
