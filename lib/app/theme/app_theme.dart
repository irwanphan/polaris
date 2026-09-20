import 'package:flutter/material.dart';
import 'package:polaris/app/theme/color_palette.dart';
import 'package:polaris/app/theme/color_tokens.dart';
import 'package:polaris/app/theme/text_styles.dart';

/// Builds the Polaris [ThemeData] for both brightness modes.
///
/// Single Responsibility: this class only composes tokens into a Material 3
/// theme. It owns no widgets and no state. Feature widgets must read colors
/// via `Theme.of(context).colorScheme` (and never reference [ColorTokens]
/// directly) so that dark-mode and future themes Just Work.
abstract final class AppTheme {
  static ThemeData light({ColorPalette palette = ColorPalette.midnight}) =>
      _buildTheme(brightness: Brightness.light, palette: palette);

  static ThemeData dark({ColorPalette palette = ColorPalette.midnight}) =>
      _buildTheme(brightness: Brightness.dark, palette: palette);

  static ThemeData _buildTheme({
    required Brightness brightness,
    required ColorPalette palette,
  }) {
    final ColorScheme colorScheme = _buildColorScheme(brightness, palette);
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

  static ColorScheme _buildColorScheme(
    Brightness brightness,
    ColorPalette palette,
  ) {
    final bool isDark = brightness == Brightness.dark;

    return switch (palette) {
      ColorPalette.midnight => ColorScheme(
          brightness: brightness,
          primary: isDark
              ? PaletteTokens.midnight300
              : PaletteTokens.midnight700,
          onPrimary: isDark ? PaletteTokens.midnight950 : ColorTokens.white,
          primaryContainer: isDark
              ? PaletteTokens.midnight800
              : PaletteTokens.midnight100,
          onPrimaryContainer: isDark
              ? PaletteTokens.midnight100
              : PaletteTokens.midnight900,
          secondary: isDark
              ? PaletteTokens.starlightMidnight300
              : PaletteTokens.starlightMidnight600,
          onSecondary: isDark
              ? PaletteTokens.starlightMidnight900
              : ColorTokens.white,
          secondaryContainer: isDark
              ? PaletteTokens.starlightMidnight800
              : PaletteTokens.starlightMidnight100,
          onSecondaryContainer: isDark
              ? PaletteTokens.starlightMidnight100
              : PaletteTokens.starlightMidnight900,
          tertiary: isDark ? ColorTokens.info500 : ColorTokens.info500,
          onTertiary: ColorTokens.white,
          error: ColorTokens.danger500,
          onError: ColorTokens.white,
          surface: isDark ? ColorTokens.slate950 : ColorTokens.slate50,
          onSurface: isDark ? ColorTokens.slate100 : ColorTokens.slate900,
          surfaceContainerLowest:
              isDark ? ColorTokens.black : ColorTokens.white,
          surfaceContainerLow:
              isDark ? ColorTokens.slate900 : ColorTokens.slate100,
          surfaceContainer:
              isDark ? ColorTokens.slate800 : ColorTokens.slate100,
          surfaceContainerHigh:
              isDark ? ColorTokens.slate800 : ColorTokens.white,
          surfaceContainerHighest:
              isDark ? ColorTokens.slate700 : ColorTokens.slate200,
          onSurfaceVariant:
              isDark ? ColorTokens.slate300 : ColorTokens.slate600,
          outline: isDark ? ColorTokens.slate600 : ColorTokens.slate300,
          outlineVariant: isDark ? ColorTokens.slate700 : ColorTokens.slate200,
          shadow: ColorTokens.black,
          scrim: ColorTokens.black,
          inverseSurface:
              isDark ? ColorTokens.slate100 : ColorTokens.slate900,
          onInverseSurface:
              isDark ? ColorTokens.slate900 : ColorTokens.slate100,
          inversePrimary: isDark
              ? PaletteTokens.midnight700
              : PaletteTokens.midnight300,
        ),
      ColorPalette.blush => ColorScheme(
          brightness: brightness,
          primary: isDark ? PaletteTokens.blush300 : PaletteTokens.blush600,
          onPrimary: isDark ? PaletteTokens.blush950 : ColorTokens.white,
          primaryContainer:
              isDark ? PaletteTokens.blush800 : PaletteTokens.blush100,
          onPrimaryContainer:
              isDark ? PaletteTokens.blush100 : PaletteTokens.blush900,
          secondary:
              isDark ? PaletteTokens.accentBlush300 : PaletteTokens.accentBlush600,
          onSecondary:
              isDark ? PaletteTokens.accentBlush900 : ColorTokens.white,
          secondaryContainer:
              isDark ? PaletteTokens.accentBlush800 : PaletteTokens.accentBlush100,
          onSecondaryContainer:
              isDark ? PaletteTokens.accentBlush100 : PaletteTokens.accentBlush900,
          tertiary: isDark ? ColorTokens.info500 : ColorTokens.info500,
          onTertiary: ColorTokens.white,
          error: ColorTokens.danger500,
          onError: ColorTokens.white,
          surface: isDark ? ColorTokens.slate950 : ColorTokens.slate50,
          onSurface: isDark ? ColorTokens.slate100 : ColorTokens.slate900,
          surfaceContainerLowest:
              isDark ? ColorTokens.black : ColorTokens.white,
          surfaceContainerLow:
              isDark ? ColorTokens.slate900 : ColorTokens.slate100,
          surfaceContainer:
              isDark ? ColorTokens.slate800 : ColorTokens.slate100,
          surfaceContainerHigh:
              isDark ? ColorTokens.slate800 : ColorTokens.white,
          surfaceContainerHighest:
              isDark ? ColorTokens.slate700 : ColorTokens.slate200,
          onSurfaceVariant:
              isDark ? ColorTokens.slate300 : ColorTokens.slate600,
          outline: isDark ? ColorTokens.slate600 : ColorTokens.slate300,
          outlineVariant: isDark ? ColorTokens.slate700 : ColorTokens.slate200,
          shadow: ColorTokens.black,
          scrim: ColorTokens.black,
          inverseSurface:
              isDark ? ColorTokens.slate100 : ColorTokens.slate900,
          onInverseSurface:
              isDark ? ColorTokens.slate900 : ColorTokens.slate100,
          inversePrimary:
              isDark ? PaletteTokens.blush600 : PaletteTokens.blush300,
        ),
      ColorPalette.lavender => ColorScheme(
          brightness: brightness,
          primary:
              isDark ? PaletteTokens.lavender300 : PaletteTokens.lavender600,
          onPrimary: isDark ? PaletteTokens.lavender950 : ColorTokens.white,
          primaryContainer:
              isDark ? PaletteTokens.lavender800 : PaletteTokens.lavender100,
          onPrimaryContainer:
              isDark ? PaletteTokens.lavender100 : PaletteTokens.lavender900,
          secondary: isDark
              ? PaletteTokens.accentLavender300
              : PaletteTokens.accentLavender600,
          onSecondary:
              isDark ? PaletteTokens.accentLavender900 : ColorTokens.white,
          secondaryContainer: isDark
              ? PaletteTokens.accentLavender800
              : PaletteTokens.accentLavender100,
          onSecondaryContainer: isDark
              ? PaletteTokens.accentLavender100
              : PaletteTokens.accentLavender900,
          tertiary: isDark ? ColorTokens.info500 : ColorTokens.info500,
          onTertiary: ColorTokens.white,
          error: ColorTokens.danger500,
          onError: ColorTokens.white,
          surface: isDark ? ColorTokens.slate950 : ColorTokens.slate50,
          onSurface: isDark ? ColorTokens.slate100 : ColorTokens.slate900,
          surfaceContainerLowest:
              isDark ? ColorTokens.black : ColorTokens.white,
          surfaceContainerLow:
              isDark ? ColorTokens.slate900 : ColorTokens.slate100,
          surfaceContainer:
              isDark ? ColorTokens.slate800 : ColorTokens.slate100,
          surfaceContainerHigh:
              isDark ? ColorTokens.slate800 : ColorTokens.white,
          surfaceContainerHighest:
              isDark ? ColorTokens.slate700 : ColorTokens.slate200,
          onSurfaceVariant:
              isDark ? ColorTokens.slate300 : ColorTokens.slate600,
          outline: isDark ? ColorTokens.slate600 : ColorTokens.slate300,
          outlineVariant: isDark ? ColorTokens.slate700 : ColorTokens.slate200,
          shadow: ColorTokens.black,
          scrim: ColorTokens.black,
          inverseSurface:
              isDark ? ColorTokens.slate100 : ColorTokens.slate900,
          onInverseSurface:
              isDark ? ColorTokens.slate900 : ColorTokens.slate100,
          inversePrimary:
              isDark ? PaletteTokens.lavender600 : PaletteTokens.lavender300,
        ),
      ColorPalette.mint => ColorScheme(
          brightness: brightness,
          primary: isDark ? PaletteTokens.mint300 : PaletteTokens.mint600,
          onPrimary: isDark ? PaletteTokens.mint950 : ColorTokens.white,
          primaryContainer:
              isDark ? PaletteTokens.mint800 : PaletteTokens.mint100,
          onPrimaryContainer:
              isDark ? PaletteTokens.mint100 : PaletteTokens.mint900,
          secondary:
              isDark ? PaletteTokens.accentMint300 : PaletteTokens.accentMint600,
          onSecondary: isDark ? PaletteTokens.accentMint900 : ColorTokens.white,
          secondaryContainer:
              isDark ? PaletteTokens.accentMint800 : PaletteTokens.accentMint100,
          onSecondaryContainer:
              isDark ? PaletteTokens.accentMint100 : PaletteTokens.accentMint900,
          tertiary: isDark ? ColorTokens.info500 : ColorTokens.info500,
          onTertiary: ColorTokens.white,
          error: ColorTokens.danger500,
          onError: ColorTokens.white,
          surface: isDark ? ColorTokens.slate950 : ColorTokens.slate50,
          onSurface: isDark ? ColorTokens.slate100 : ColorTokens.slate900,
          surfaceContainerLowest:
              isDark ? ColorTokens.black : ColorTokens.white,
          surfaceContainerLow:
              isDark ? ColorTokens.slate900 : ColorTokens.slate100,
          surfaceContainer:
              isDark ? ColorTokens.slate800 : ColorTokens.slate100,
          surfaceContainerHigh:
              isDark ? ColorTokens.slate800 : ColorTokens.white,
          surfaceContainerHighest:
              isDark ? ColorTokens.slate700 : ColorTokens.slate200,
          onSurfaceVariant:
              isDark ? ColorTokens.slate300 : ColorTokens.slate600,
          outline: isDark ? ColorTokens.slate600 : ColorTokens.slate300,
          outlineVariant: isDark ? ColorTokens.slate700 : ColorTokens.slate200,
          shadow: ColorTokens.black,
          scrim: ColorTokens.black,
          inverseSurface:
              isDark ? ColorTokens.slate100 : ColorTokens.slate900,
          onInverseSurface:
              isDark ? ColorTokens.slate900 : ColorTokens.slate100,
          inversePrimary: isDark ? PaletteTokens.mint600 : PaletteTokens.mint300,
        ),
      ColorPalette.peach => ColorScheme(
          brightness: brightness,
          primary: isDark ? PaletteTokens.peach300 : PaletteTokens.peach600,
          onPrimary: isDark ? PaletteTokens.peach950 : ColorTokens.white,
          primaryContainer:
              isDark ? PaletteTokens.peach800 : PaletteTokens.peach100,
          onPrimaryContainer:
              isDark ? PaletteTokens.peach100 : PaletteTokens.peach900,
          secondary:
              isDark ? PaletteTokens.accentPeach300 : PaletteTokens.accentPeach600,
          onSecondary: isDark ? PaletteTokens.accentPeach900 : ColorTokens.white,
          secondaryContainer:
              isDark ? PaletteTokens.accentPeach800 : PaletteTokens.accentPeach100,
          onSecondaryContainer:
              isDark ? PaletteTokens.accentPeach100 : PaletteTokens.accentPeach900,
          tertiary: isDark ? ColorTokens.info500 : ColorTokens.info500,
          onTertiary: ColorTokens.white,
          error: ColorTokens.danger500,
          onError: ColorTokens.white,
          surface: isDark ? ColorTokens.slate950 : ColorTokens.slate50,
          onSurface: isDark ? ColorTokens.slate100 : ColorTokens.slate900,
          surfaceContainerLowest:
              isDark ? ColorTokens.black : ColorTokens.white,
          surfaceContainerLow:
              isDark ? ColorTokens.slate900 : ColorTokens.slate100,
          surfaceContainer:
              isDark ? ColorTokens.slate800 : ColorTokens.slate100,
          surfaceContainerHigh:
              isDark ? ColorTokens.slate800 : ColorTokens.white,
          surfaceContainerHighest:
              isDark ? ColorTokens.slate700 : ColorTokens.slate200,
          onSurfaceVariant:
              isDark ? ColorTokens.slate300 : ColorTokens.slate600,
          outline: isDark ? ColorTokens.slate600 : ColorTokens.slate300,
          outlineVariant: isDark ? ColorTokens.slate700 : ColorTokens.slate200,
          shadow: ColorTokens.black,
          scrim: ColorTokens.black,
          inverseSurface:
              isDark ? ColorTokens.slate100 : ColorTokens.slate900,
          onInverseSurface:
              isDark ? ColorTokens.slate900 : ColorTokens.slate100,
          inversePrimary:
              isDark ? PaletteTokens.peach600 : PaletteTokens.peach300,
        ),
    };
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
