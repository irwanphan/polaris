@Tags(<String>['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/features/lifestyle/domain/value_objects/log_category.dart';
import 'package:polaris/features/recommendations/domain/entities/insight.dart';
import 'package:polaris/features/recommendations/domain/value_objects/insight_severity.dart';
import 'package:polaris/features/recommendations/presentation/widgets/insight_card.dart';

import '../golden_harness.dart';

Insight _insight({
  required InsightSeverity severity,
  required String title,
  required String body,
  LogCategory? category,
  String? cta,
}) {
  return Insight(
    id: 'g-${severity.name}',
    severity: severity,
    title: title,
    body: body,
    relatedCategory: category,
    ctaLabel: cta,
    ctaRoute: cta == null ? null : '/lifestyle',
  );
}

void main() {
  testWidgets('InsightCard — info (no CTA)', (WidgetTester tester) async {
    await pumpGolden(
      tester,
      InsightCard(
        insight: _insight(
          severity: InsightSeverity.info,
          title: 'Log your first entry',
          body: 'Polaris gets sharper once it learns your rhythm.',
        ),
      ),
      size: const Size(380, 220),
    );
    await expectLater(
      find.byType(InsightCard),
      matchesGoldenFile('goldens/insight_info.png'),
    );
  });

  testWidgets('InsightCard — encourage (with CTA)', (
    WidgetTester tester,
  ) async {
    await pumpGolden(
      tester,
      InsightCard(
        insight: _insight(
          severity: InsightSeverity.encourage,
          title: 'Keep your streak going',
          body: 'You logged exercise 4 days in a row. Nice rhythm.',
          category: LogCategory.exercise,
          cta: 'Log exercise',
        ),
        onActionTap: () {},
      ),
      size: const Size(380, 280),
    );
    await expectLater(
      find.byType(InsightCard),
      matchesGoldenFile('goldens/insight_encourage.png'),
    );
  });

  testWidgets('InsightCard — warn (water)', (WidgetTester tester) async {
    await pumpGolden(
      tester,
      InsightCard(
        insight: _insight(
          severity: InsightSeverity.warn,
          title: 'Drink more water',
          body: 'Last 7 days you averaged 3.0 glasses (target 6).',
          category: LogCategory.water,
          cta: 'Log water',
        ),
        onActionTap: () {},
      ),
      size: const Size(380, 280),
    );
    await expectLater(
      find.byType(InsightCard),
      matchesGoldenFile('goldens/insight_warn.png'),
    );
  });

  testWidgets('InsightCard — critical (life phase)', (
    WidgetTester tester,
  ) async {
    await pumpGolden(
      tester,
      InsightCard(
        insight: _insight(
          severity: InsightSeverity.critical,
          title: 'Milestone reached',
          body: 'You\'ve lived 50% of your expected lifetime.',
        ),
      ),
      size: const Size(380, 220),
    );
    await expectLater(
      find.byType(InsightCard),
      matchesGoldenFile('goldens/insight_critical.png'),
    );
  });
}
