import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/data/database/providers.dart';
import 'package:polaris/features/event_countdown/data/repositories/event_repository_impl.dart';
import 'package:polaris/features/event_countdown/domain/entities/event.dart';
import 'package:polaris/features/event_countdown/domain/repositories/event_repository.dart';

final Provider<EventRepository> eventRepositoryProvider =
    Provider<EventRepository>(
  (ref) => EventRepositoryImpl(ref.watch(appDatabaseProvider).eventsDao),
);

/// Reactive event list, sorted by target date ascending.
final StreamProvider<List<Event>> eventsStreamProvider =
    StreamProvider<List<Event>>(
  (ref) => ref.watch(eventRepositoryProvider).watchAll(),
);
