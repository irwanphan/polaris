import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/data/database/app_database.dart';
import 'package:polaris/features/event_countdown/data/repositories/event_repository_impl.dart';
import 'package:polaris/features/event_countdown/domain/entities/event.dart';
import 'package:polaris/features/event_countdown/domain/repositories/event_repository.dart';

/// Single Drift database instance for the whole app. Overridden in
/// `bootstrap.dart` so the connection can be eagerly opened (and so tests
/// can swap it for an in-memory executor).
final Provider<AppDatabase> appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError(
    'appDatabaseProvider must be overridden in bootstrap()',
  ),
);

final Provider<EventRepository> eventRepositoryProvider =
    Provider<EventRepository>(
  (ref) => EventRepositoryImpl(ref.watch(appDatabaseProvider).eventsDao),
);

/// Reactive event list, sorted by target date ascending.
final StreamProvider<List<Event>> eventsStreamProvider =
    StreamProvider<List<Event>>(
  (ref) => ref.watch(eventRepositoryProvider).watchAll(),
);
