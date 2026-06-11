import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/app/app.dart';
import 'package:polaris/core/logging/app_logger.dart';

void main() {
  testWidgets('LauncherPage renders title and all destinations',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLoggerProvider.overrideWithValue(AppLogger.silent()),
        ],
        child: const PolarisApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Polaris'), findsOneWidget);
    expect(find.text('Your countdown companion'), findsOneWidget);
    expect(find.text('Sisa Hariku'), findsOneWidget);
    expect(find.text('Events'), findsOneWidget);
    expect(find.text('Lifestyle'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Tapping a launcher card navigates to its route',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLoggerProvider.overrideWithValue(AppLogger.silent()),
        ],
        child: const PolarisApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sisa Hariku'));
    await tester.pumpAndSettle();

    expect(find.text('Sisa Hariku di Dunia'), findsOneWidget);
    expect(find.text('Planned for M1'), findsOneWidget);
  });
}
