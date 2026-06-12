import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/core/logging/app_logger.dart';
import 'package:polaris/core/notifications/notification_dispatcher.dart';
import 'package:polaris/data/database/providers.dart';
import 'package:polaris/features/event_countdown/application/notification_scheduler.dart';
import 'package:polaris/features/event_countdown/data/repositories/event_repository_impl.dart';
import 'package:polaris/features/event_countdown/domain/entities/event.dart';
import 'package:polaris/features/event_countdown/domain/repositories/event_repository.dart';

final Provider<EventRepository> eventRepositoryProvider =
    Provider<EventRepository>(
  (ref) => EventRepositoryImpl(ref.watch(appDatabaseProvider).eventsDao),
);

/// Cross-cutting platform plumbing for local notifications. Overridden
/// in `bootstrap.dart` (production) and in widget / unit tests with a
/// no-op fake.
final Provider<NotificationDispatcher> notificationDispatcherProvider =
    Provider<NotificationDispatcher>(
  (ref) => throw UnimplementedError(
    'notificationDispatcherProvider must be overridden in bootstrap()',
  ),
);

final Provider<NotificationScheduler> notificationSchedulerProvider =
    Provider<NotificationScheduler>(
  (ref) => NotificationScheduler(
    dispatcher: ref.watch(notificationDispatcherProvider),
    dao: ref.watch(appDatabaseProvider).notificationsDao,
    logger: ref.watch(appLoggerProvider),
  ),
);

/// Reactive event list, sorted by target date ascending.
final StreamProvider<List<Event>> eventsStreamProvider =
    StreamProvider<List<Event>>(
  (ref) => ref.watch(eventRepositoryProvider).watchAll(),
);
