import 'package:flutter/material.dart';
import 'package:polaris/app/theme/color_tokens.dart';
import 'package:polaris/app/theme/text_styles.dart';

/// Builds the Polaris [ThemeData] for both brightness modes.
///
/// Single Responsibility: this class only composes tokens into a Material 3
/// theme. It owns no widgets and no state. Feature widgets must read colors
/// via `Theme.of(context).colorScheme` (and never reference [ColorTokens]
/// directly) so that dark-mode and future themes Just Work.
abstract final class AppTheme {
  static ThemeData light() => _buildTheme(brightness: Brightness.light);

  static ThemeData dark() => _buildTheme(brightness: Brightness.dark);

  static ThemeData _buildTheme({required Brightness brightness}) {
    final ColorScheme colorScheme = _buildColorScheme(brightness);
    final TextTheme textTheme = _buildTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      // Brand font. Registered in `pubspec.yaml` under family "Montserrat"
      // with weights 300/400/500/600/700 (+ italic@400). Setting it here on
      // ThemeData propagates to every TextStyle in `textTheme` because the
      // TextStyles in `lib/app/theme/text_styles.dart` intentionally leave
      // `fontFamily` unset.
      fontFamily: 'Montserrat',
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHigh,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.lg),
          ),
          textStyle: TextStyles.labelLg,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.x6,
            vertical: Spacing.x3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.lg),
          ),
          textStyle: TextStyles.labelLg,
          side: BorderSide(color: colorScheme.outline),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.x6,
            vertical: Spacing.x3,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: TextStyles.labelMd,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.x3,
            vertical: Spacing.x2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.x4,
          vertical: Spacing.x3,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  static ColorScheme _buildColorScheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    return ColorScheme(
      brightness: brightness,
      primary: isDark ? ColorTokens.midnight300 : ColorTokens.midnight700,
      onPrimary: isDark ? ColorTokens.midnight950 : ColorTokens.white,
      primaryContainer: isDark
          ? ColorTokens.midnight800
          : ColorTokens.midnight100,
      onPrimaryContainer: isDark
          ? ColorTokens.midnight100
          : ColorTokens.midnight900,
      secondary: isDark ? ColorTokens.starlight300 : ColorTokens.starlight600,
      onSecondary: isDark ? ColorTokens.starlight900 : ColorTokens.white,
      secondaryContainer: isDark
          ? ColorTokens.starlight800
          : ColorTokens.starlight100,
      onSecondaryContainer: isDark
          ? ColorTokens.starlight100
          : ColorTokens.starlight900,
      tertiary: isDark ? ColorTokens.info500 : ColorTokens.info500,
      onTertiary: ColorTokens.white,
      error: ColorTokens.danger500,
      onError: ColorTokens.white,
      surface: isDark ? ColorTokens.slate950 : ColorTokens.slate50,
      onSurface: isDark ? ColorTokens.slate100 : ColorTokens.slate900,
      surfaceContainerLowest: isDark ? ColorTokens.black : ColorTokens.white,
      surfaceContainerLow: isDark ? ColorTokens.slate900 : ColorTokens.slate100,
      surfaceContainer: isDark ? ColorTokens.slate800 : ColorTokens.slate100,
      surfaceContainerHigh: isDark ? ColorTokens.slate800 : ColorTokens.white,
      surfaceContainerHighest: isDark
          ? ColorTokens.slate700
          : ColorTokens.slate200,
      onSurfaceVariant: isDark ? ColorTokens.slate300 : ColorTokens.slate600,
      outline: isDark ? ColorTokens.slate600 : ColorTokens.slate300,
      outlineVariant: isDark ? ColorTokens.slate700 : ColorTokens.slate200,
      shadow: ColorTokens.black,
      scrim: ColorTokens.black,
      inverseSurface: isDark ? ColorTokens.slate100 : ColorTokens.slate900,
      onInverseSurface: isDark ? ColorTokens.slate900 : ColorTokens.slate100,
      inversePrimary: isDark
          ? ColorTokens.midnight700
          : ColorTokens.midnight300,
    );
  }

  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    final Color onSurface = colorScheme.onSurface;
    final Color onSurfaceMuted = colorScheme.onSurfaceVariant;

    TextStyle apply(TextStyle base, {Color? color}) =>
        base.copyWith(color: color ?? onSurface);

    return TextTheme(
      displayLarge: apply(TextStyles.displayXl),
      displayMedium: apply(TextStyles.displayLg),
      displaySmall: apply(TextStyles.displayMd),
      headlineLarge: apply(TextStyles.displayMd),
      headlineMedium: apply(TextStyles.headingLg),
      headlineSmall: apply(TextStyles.headingMd),
      titleLarge: apply(TextStyles.headingMd),
      titleMedium: apply(TextStyles.headingSm),
      titleSmall: apply(TextStyles.labelLg),
      bodyLarge: apply(TextStyles.bodyLg),
      bodyMedium: apply(TextStyles.bodyMd),
      bodySmall: apply(TextStyles.bodySm, color: onSurfaceMuted),
      labelLarge: apply(TextStyles.labelLg),
      labelMedium: apply(TextStyles.labelMd, color: onSurfaceMuted),
      labelSmall: apply(TextStyles.labelSm, color: onSurfaceMuted),
    );
  }
}
