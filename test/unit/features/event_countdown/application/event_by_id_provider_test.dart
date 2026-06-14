import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/features/event_countdown/application/providers.dart';
import 'package:polaris/features/event_countdown/domain/entities/event.dart';
import 'package:polaris/features/event_countdown/domain/value_objects/recurrence.dart';

void main() {
  group('eventByIdProvider', () {
    late StreamController<List<Event>> controller;
    late ProviderContainer container;

    setUp(() {
      controller = StreamController<List<Event>>.broadcast();
      container = ProviderContainer(
        overrides: [
          // Override the upstream stream provider with an in-memory
          // stream so the test does not need Drift / SharedPreferences.
          eventsStreamProvider.overrideWith(
            (Ref ref) => controller.stream,
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(controller.close);
    });

    test('starts in loading until the upstream stream emits', () async {
      // Reading once before any controller.add — provider must
      // forward the upstream loading state through whenData.
      container.listen(eventByIdProvider('id-1'), (_, _) {});
      final AsyncValue<Event?> v = container.read(eventByIdProvider('id-1'));
      expect(v.isLoading, isTrue);
      expect(v.hasValue, isFalse);
      // Allow the underlying stream subscription a microtask to
      // wire up — otherwise the test framework reports a pending
      // timer when tearDown closes the controller.
      await _waitForStream();
    });

    test('returns data(null) when id is not present in the list', () async {
      // Subscribe first so the broadcast controller has a listener
      // before we emit (broadcast streams don't buffer for late
      // subscribers).
      container.listen(eventByIdProvider('id-1'), (_, _) {});
      controller.add(<Event>[]);
      await _waitForStream();
      final AsyncValue<Event?> v = container.read(eventByIdProvider('id-1'));
      expect(v.hasValue, isTrue);
      expect(v.value, isNull);
    });

    test('returns data(event) when id matches a row in the list', () async {
      container.listen(eventByIdProvider('id-1'), (_, _) {});
      final Event e = _event(id: 'id-1', title: 'Trip');
      controller.add(<Event>[e]);
      await _waitForStream();
      final AsyncValue<Event?> v = container.read(eventByIdProvider('id-1'));
      expect(v.hasValue, isTrue);
      expect(v.value, isNotNull);
      expect(v.value!.title, equals('Trip'));
    });

    test('flips to data(null) when the row disappears upstream', () async {
      // Simulates a delete: the detail page is open, the list
      // re-emits without the event, the page should observe
      // data(null) so its auto-pop listener can fire.
      container.listen(eventByIdProvider('id-1'), (_, _) {});
      final Event e = _event(id: 'id-1', title: 'Trip');
      controller.add(<Event>[e]);
      await _waitForStream();
      expect(container.read(eventByIdProvider('id-1')).value, isNotNull);

      controller.add(<Event>[]);
      await _waitForStream();
      final AsyncValue<Event?> v = container.read(eventByIdProvider('id-1'));
      expect(v.hasValue, isTrue);
      expect(v.value, isNull);
    });

    test('disambiguates across different ids in the same list', () async {
      container
        ..listen(eventByIdProvider('id-1'), (_, _) {})
        ..listen(eventByIdProvider('id-2'), (_, _) {})
        ..listen(eventByIdProvider('id-3'), (_, _) {});
      controller.add(<Event>[
        _event(id: 'id-1', title: 'A'),
        _event(id: 'id-2', title: 'B'),
      ]);
      await _waitForStream();

      expect(container.read(eventByIdProvider('id-1')).value?.title, 'A');
      expect(container.read(eventByIdProvider('id-2')).value?.title, 'B');
      expect(container.read(eventByIdProvider('id-3')).value, isNull);
    });
  });
}

/// Yields one microtask + one event-loop turn so the StreamProvider
/// has a chance to propagate the latest emission to listeners.
Future<void> _waitForStream() async {
  await Future<void>.delayed(Duration.zero);
}

Event _event({required String id, required String title}) {
  return Event(
    id: id,
    title: title,
    targetAt: DateTime(2027, 1, 1),
    colorHex: '#6366F1',
    iconKey: 'event',
    recurrence: Recurrence.none,
    isPinnedToWidget: false,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}
