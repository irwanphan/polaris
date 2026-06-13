@Tags(<String>['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/features/life_countdown/application/display_mode.dart';
import 'package:polaris/features/life_countdown/domain/entities/life_estimate.dart';
import 'package:polaris/features/life_countdown/presentation/widgets/countdown_display.dart';

import '../golden_harness.dart';

LifeEstimate _sample() {
  return LifeEstimate(
    referenceDate: DateTime(2026, 6, 12),
    expectancyYears: 72.5,
    expectedTotalDays: 72 * 365 + 18,
    livedDays: 30 * 365 + 9,
    remainingDays: 15522,
    estimatedEndDate: DateTime(2068, 12, 1),
  );
}

void main() {
  testWidgets('CountdownDisplay — days mode (EN, light)', (
    WidgetTester tester,
  ) async {
    await pumpGolden(
      tester,
      CountdownDisplay(estimate: _sample(), mode: DisplayMode.days),
      size: const Size(380, 260),
    );
    await expectLater(
      find.byType(CountdownDisplay),
      matchesGoldenFile('goldens/countdown_days_en_light.png'),
    );
  });

  testWidgets('CountdownDisplay — percent mode (ID, dark)', (
    WidgetTester tester,
  ) async {
    await pumpGolden(
      tester,
      CountdownDisplay(estimate: _sample(), mode: DisplayMode.percent),
      size: const Size(380, 220),
      locale: const Locale('id'),
      brightness: Brightness.dark,
    );
    await expectLater(
      find.byType(CountdownDisplay),
      matchesGoldenFile('goldens/countdown_percent_id_dark.png'),
    );
  });
}
