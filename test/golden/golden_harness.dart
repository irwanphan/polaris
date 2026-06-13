import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/app/theme/app_theme.dart';
import 'package:polaris/l10n/generated/app_localizations.dart';

/// Wraps a widget under test with the same MaterialApp theming and
/// localization delegates the real app uses, sized to a phone-like
/// viewport so the golden has a consistent canvas across files.
///
/// Goldens are notoriously sensitive to OS-level font fallbacks.
/// Strategy used here:
///   1. Render everything inside [Material] with an explicit theme
///      so colors are deterministic.
///   2. Disable shadows + ripple animations.
///   3. Pin the [Locale] explicitly per call so EN vs ID variants
///      are intentional.
///
/// All callers should still use `--update-goldens` only when the
/// visual change is reviewed. Add `@Tags(['golden'])` to test files
/// so CI can skip them when running on a non-macOS host.
Future<void> pumpGolden(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(380, 200),
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() async => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppL.supportedLocales,
      localizationsDelegates: AppL.localizationsDelegates,
      theme: brightness == Brightness.light
          ? AppTheme.light()
          : AppTheme.dark(),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
