import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/core/errors/failure.dart';
import 'package:polaris/core/result/result.dart';
import 'package:polaris/core/widgets/home_widget_updater.dart';
import 'package:polaris/core/widgets/providers.dart' as widget_providers;
import 'package:polaris/features/event_countdown/application/providers.dart';
import 'package:polaris/features/event_countdown/domain/entities/event.dart';
import 'package:polaris/features/event_countdown/domain/repositories/event_repository.dart';
import 'package:polaris/features/event_countdown/domain/value_objects/recurrence.dart';
import 'package:polaris/features/event_countdown/presentation/pages/event_detail_page.dart';
import 'package:polaris/l10n/generated/app_localizations.dart';

/// Read-only fake — every mutating method just delegates to the
/// in-memory list / controller so the EventDetailPage's
/// pin / delete / edit interactions remain functional during the
/// smoke test if the test wants to exercise them.
class _FakeEventRepo implements EventRepository {
  _FakeEventRepo(List<Event> seed) {
    _events.addAll(seed);
  }

  final List<Event> _events = <Event>[];
  final StreamController<List<Event>> _controller =
      StreamController<List<Event>>.broadcast();

  @override
  Stream<List<Event>> watchAll() async* {
    yield List<Event>.unmodifiable(_events);
    yield* _controller.stream;
  }

  @override
  Future<Result<Event?, Failure>> getById(String id) async =>
      Result.ok(_events.where((e) => e.id == id).firstOrNull);

  @override
  Future<Result<Event?, Failure>> getPinned() async =>
      Result.ok(_events.where((e) => e.isPinnedToWidget).firstOrNull);

  @override
  Future<Result<List<Event>, Failure>> getAllPinned() async =>
      Result.ok(_events.where((e) => e.isPinnedToWidget).toList());

  @override
  Future<Result<void, Failure>> upsert(Event event) async {
    _events
      ..removeWhere((e) => e.id == event.id)
      ..add(event);
    _controller.add(List<Event>.unmodifiable(_events));
    return const Result.ok(null);
  }

  @override
  Future<Result<void, Failure>> delete(String id) async {
    _events.removeWhere((e) => e.id == id);
    _controller.add(List<Event>.unmodifiable(_events));
    return const Result.ok(null);
  }

  @override
  Future<Result<void, Failure>> setPinned(String id, bool isPinned) async {
    final int idx = _events.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      _events[idx] = _events[idx].copyWith(isPinnedToWidget: isPinned);
      _controller.add(List<Event>.unmodifiable(_events));
    }
    return const Result.ok(null);
  }

  @override
  Future<Result<void, Failure>> pinExclusive(String? id) async =>
      const Result.ok(null);
}

class _NoopWidgetUpdater implements HomeWidgetUpdater {
  @override
  Future<void> refresh() async {}
}

Widget _harness({required Event seed}) {
  return ProviderScope(
    overrides: [
      eventRepositoryProvider.overrideWithValue(_FakeEventRepo(<Event>[seed])),
      widget_providers.homeWidgetUpdaterProvider.overrideWithValue(
        _NoopWidgetUpdater(),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppL.localizationsDelegates,
      supportedLocales: AppL.supportedLocales,
      home: EventDetailPage(eventId: seed.id),
    ),
  );
}

Event _sampleEvent() {
  return Event(
    id: 'evt-1',
    title: 'Wedding Anniversary',
    targetAt: DateTime(2027, 6, 30, 18, 0),
    colorHex: '#6366F1',
    iconKey: 'event',
    note: 'Reservation at Locavore.',
    widgetMessage: 'Locavore at 6pm',
    recurrence: Recurrence.yearly,
    isPinnedToWidget: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  testWidgets('EventDetailPage renders title, note, widget message, badges', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_harness(seed: _sampleEvent()));
    await tester.pumpAndSettle();

    expect(find.text('Wedding Anniversary'), findsOneWidget);
    expect(find.text('Reservation at Locavore.'), findsOneWidget);
    expect(find.text('Locavore at 6pm'), findsOneWidget);
    // Localized "Pinned to widget" affordance from app_en.arb
    // (`eventsPinnedSemanticLabel`).
    expect(find.text('Pinned to widget'), findsOneWidget);
    // Hero unit label
    expect(find.text('DAYS'), findsOneWidget);
    // Recurrence pill text — yearly repeat.
    expect(find.text('Repeats Yearly'), findsOneWidget);
  });

  testWidgets('EventDetailPage renders not-found view for unknown id', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventRepositoryProvider.overrideWithValue(_FakeEventRepo(<Event>[])),
          widget_providers.homeWidgetUpdaterProvider.overrideWithValue(
            _NoopWidgetUpdater(),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppL.localizationsDelegates,
          supportedLocales: AppL.supportedLocales,
          home: EventDetailPage(eventId: 'does-not-exist'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Event not found'), findsOneWidget);
    // Action button label from arb (must be `findsAtLeastNWidgets(1)` to be
    // tolerant of duplicate text matches across nested layouts).
    expect(find.text('Back to events'), findsAtLeastNWidgets(1));
  });

  testWidgets('EventDetailPage renders fallback copy when note is null', (
    WidgetTester tester,
  ) async {
    final Event bare = _sampleEvent().copyWith(clearWidgetMessage: true);
    await tester.pumpWidget(
      _harness(
        seed: Event(
          id: bare.id,
          title: bare.title,
          targetAt: bare.targetAt,
          colorHex: bare.colorHex,
          iconKey: bare.iconKey,
          // note explicitly left null
          widgetMessage: null,
          recurrence: bare.recurrence,
          isPinnedToWidget: bare.isPinnedToWidget,
          createdAt: bare.createdAt,
          updatedAt: bare.updatedAt,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No note added.'), findsOneWidget);
    expect(
      find.text('Uses the automatic subtitle on the widget.'),
      findsOneWidget,
    );
  });
}
