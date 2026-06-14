import 'package:flutter/painting.dart';

/// Semantic typography scale for Polaris.
///
/// Sizes follow a ~1.125 (minor third) modular scale, which Tailwind also
/// uses for its `text-*` utilities. Always reference semantic roles
/// (`displayLg`, `headingMd`, `bodyMd`, ...) instead of raw sizes so that
/// screens stay visually coherent.
///
/// The font family is intentionally left unset on each [TextStyle]. The
/// brand font ("Montserrat") is applied once at the [ThemeData] level in
/// `app_theme.dart` and inherits down through the [TextTheme]. Keep it
/// that way — overriding `fontFamily` per-style would silently bypass any
/// future theme change (e.g. swapping to Inter or pairing display+body).
abstract final class TextStyles {
  // --- Display: hero / countdown numbers ----------------------------------
  static const TextStyle displayXl = TextStyle(
    fontSize: 60,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -1.0,
  );

  static const TextStyle displayLg = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMd = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.25,
  );

  // --- Heading: section titles --------------------------------------------
  static const TextStyle headingLg = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  static const TextStyle headingMd = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle headingSm = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  // --- Body: paragraph copy -----------------------------------------------
  static const TextStyle bodyLg = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMd = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodySm = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  // --- Label / UI chrome --------------------------------------------------
  static const TextStyle labelLg = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMd = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.15,
  );

  static const TextStyle labelSm = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.2,
  );
}
