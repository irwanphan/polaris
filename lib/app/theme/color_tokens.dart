import 'package:flutter/painting.dart';

/// Color palette for Polaris, organized in Tailwind-style numeric scales.
///
/// Brand metaphor: Polaris is the North Star — a deep night-sky indigo
/// ("midnight") with warm golden starlight ("starlight") accents.
///
/// Tokens are raw values; never reference them directly from feature widgets.
/// Always read colors through [Theme.of(context).colorScheme] or the semantic
/// roles defined in `app_theme.dart`.
abstract final class ColorTokens {
  // --- Primary: Midnight (Indigo) -----------------------------------------
  static const Color midnight50 = Color(0xFFEEF2FF);
  static const Color midnight100 = Color(0xFFE0E7FF);
  static const Color midnight200 = Color(0xFFC7D2FE);
  static const Color midnight300 = Color(0xFFA5B4FC);
  static const Color midnight400 = Color(0xFF818CF8);
  static const Color midnight500 = Color(0xFF6366F1);
  static const Color midnight600 = Color(0xFF4F46E5);
  static const Color midnight700 = Color(0xFF4338CA);
  static const Color midnight800 = Color(0xFF3730A3);
  static const Color midnight900 = Color(0xFF312E81);
  static const Color midnight950 = Color(0xFF1E1B4B);

  // --- Accent: Starlight (Amber) ------------------------------------------
  static const Color starlight50 = Color(0xFFFFFBEB);
  static const Color starlight100 = Color(0xFFFEF3C7);
  static const Color starlight200 = Color(0xFFFDE68A);
  static const Color starlight300 = Color(0xFFFCD34D);
  static const Color starlight400 = Color(0xFFFBBF24);
  static const Color starlight500 = Color(0xFFF59E0B);
  static const Color starlight600 = Color(0xFFD97706);
  static const Color starlight700 = Color(0xFFB45309);
  static const Color starlight800 = Color(0xFF92400E);
  static const Color starlight900 = Color(0xFF78350F);

  // --- Neutral: Slate -----------------------------------------------------
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF020617);

  // --- Semantic ------------------------------------------------------------
  static const Color success500 = Color(0xFF10B981); // emerald
  static const Color warning500 = Color(0xFFF59E0B); // amber
  static const Color danger500 = Color(0xFFF43F5E); // rose
  static const Color info500 = Color(0xFF0EA5E9); // sky

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}

/// Spacing scale (4px base) — mirrors Tailwind's spacing primitives so
/// designers can communicate in `gap-4`, `p-6` terms.
abstract final class Spacing {
  static const double x0 = 0;
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x10 = 40;
  static const double x12 = 48;
  static const double x16 = 64;
  static const double x20 = 80;
  static const double x24 = 96;
}

/// Border-radius scale.
abstract final class Radii {
  static const double none = 0;
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xl2 = 24;
  static const double xl3 = 32;
  static const double full = 9999;
}

/// Elevation scale (used sparingly — Polaris prefers borders over shadows).
abstract final class Elevations {
  static const double none = 0;
  static const double sm = 1;
  static const double md = 2;
  static const double lg = 4;
  static const double xl = 8;
}
