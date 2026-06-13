@Tags(<String>['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/features/lifestyle/domain/value_objects/log_category.dart';
import 'package:polaris/features/lifestyle/presentation/widgets/category_summary_card.dart';

import '../golden_harness.dart';

void main() {
  testWidgets('CategorySummaryCard — water with 3 entries today (EN)', (
    WidgetTester tester,
  ) async {
    await pumpGolden(
      tester,
      SizedBox(
        width: 180,
        child: CategorySummaryCard(
          category: LogCategory.water,
          displayValue: '6',
          entriesCount: 3,
          onTap: () {},
        ),
      ),
      size: const Size(220, 260),
    );
    await expectLater(
      find.byType(CategorySummaryCard),
      matchesGoldenFile('goldens/category_summary_water_en.png'),
    );
  });

  testWidgets('CategorySummaryCard — mood empty placeholder (ID)', (
    WidgetTester tester,
  ) async {
    await pumpGolden(
      tester,
      SizedBox(
        width: 180,
        child: CategorySummaryCard(
          category: LogCategory.mood,
          displayValue: '—',
          entriesCount: null,
          onTap: () {},
        ),
      ),
      size: const Size(220, 260),
      locale: const Locale('id'),
    );
    await expectLater(
      find.byType(CategorySummaryCard),
      matchesGoldenFile('goldens/category_summary_mood_empty_id.png'),
    );
  });
}
