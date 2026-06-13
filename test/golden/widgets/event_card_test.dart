@Tags(<String>['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/features/event_countdown/domain/entities/event.dart';
import 'package:polaris/features/event_countdown/domain/value_objects/recurrence.dart';
import 'package:polaris/features/event_countdown/presentation/widgets/event_card.dart';

import '../golden_harness.dart';

Event _sampleEvent({
  required String id,
  required String title,
  required int daysFromNow,
  bool pinned = false,
  Recurrence recurrence = Recurrence.none,
  String colorHex = '#3478F6',
}) {
  final DateTime now = DateTime(2026, 6, 12, 9);
  return Event(
    id: id,
    title: title,
    targetAt: now.add(Duration(days: daysFromNow)),
    colorHex: colorHex,
    iconKey: 'star',
    note: null,
    recurrence: recurrence,
    createdAt: now.subtract(const Duration(days: 30)),
    updatedAt: now.subtract(const Duration(days: 1)),
    isPinnedToWidget: pinned,
  );
}

void main() {
  testWidgets('EventCard — unpinned, one-off, 14 days away (EN)', (
    WidgetTester tester,
  ) async {
    await pumpGolden(
      tester,
      EventCard(
        event: _sampleEvent(id: 'g1', title: 'Trip to Bali', daysFromNow: 14),
        now: DateTime(2026, 6, 12, 9),
        onTap: () {},
        onPinToggle: () {},
        onDelete: () {},
      ),
      size: const Size(380, 160),
    );
    await expectLater(
      find.byType(EventCard),
      matchesGoldenFile('goldens/event_card_unpinned_en.png'),
    );
  });

  testWidgets('EventCard — pinned, yearly, 30 days away (ID)', (
    WidgetTester tester,
  ) async {
    await pumpGolden(
      tester,
      EventCard(
        event: _sampleEvent(
          id: 'g2',
          title: 'Ulang tahun Mama',
          daysFromNow: 30,
          pinned: true,
          recurrence: Recurrence.yearly,
          colorHex: '#FF7849',
        ),
        now: DateTime(2026, 6, 12, 9),
        onTap: () {},
        onPinToggle: () {},
        onDelete: () {},
      ),
      size: const Size(380, 160),
      locale: const Locale('id'),
    );
    await expectLater(
      find.byType(EventCard),
      matchesGoldenFile('goldens/event_card_pinned_yearly_id.png'),
    );
  });
}
