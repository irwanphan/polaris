import 'package:flutter/painting.dart';

/// Theme color palettes for Polaris.
///
/// Each palette defines a complete set of colors that map to Material 3's
/// ColorScheme. The existing Midnight palette (indigo+amber) is retained
/// alongside new pastel options inspired by the Lovable prototype.
enum ColorPalette {
  midnight('midnight'),
  blush('blush'),
  lavender('lavender'),
  mint('mint'),
  peach('peach');

  const ColorPalette(this.key);

  /// Stable storage key (never rename without migration).
  final String key;

  String label() {
    return switch (this) {
      ColorPalette.midnight => 'Midnight',
      ColorPalette.blush => 'Blush',
      ColorPalette.lavender => 'Lavender',
      ColorPalette.mint => 'Mint',
      ColorPalette.peach => 'Peach',
    };
  }

  /// Parse from storage key; returns null for unknown keys (forward-compat).
  static ColorPalette? fromKey(String key) {
    return ColorPalette.values.cast<ColorPalette?>().firstWhere(
          (ColorPalette? p) => p?.key == key,
          orElse: () => null,
        );
  }
}

/// Pastel color tokens for each palette.
///
/// Organized as primary/secondary/accent sets with light/dark variants.
/// Midnight retains the existing indigo+amber scheme; new palettes use
/// soft pastels inspired by the Lovable prototype.
abstract final class PaletteTokens {
  // --- Midnight (existing indigo + amber) ----------------------------------
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

  static const Color starlightMidnight50 = Color(0xFFFFFBEB);
  static const Color starlightMidnight100 = Color(0xFFFEF3C7);
  static const Color starlightMidnight200 = Color(0xFFFDE68A);
  static const Color starlightMidnight300 = Color(0xFFFCD34D);
  static const Color starlightMidnight400 = Color(0xFFFBBF24);
  static const Color starlightMidnight500 = Color(0xFFF59E0B);
  static const Color starlightMidnight600 = Color(0xFFD97706);
  static const Color starlightMidnight700 = Color(0xFFB45309);
  static const Color starlightMidnight800 = Color(0xFF92400E);
  static const Color starlightMidnight900 = Color(0xFF78350F);

  // --- Blush (pastel pink primary, like Lovable prototype) -----------------
  static const Color blush50 = Color(0xFFFFF5F7);
  static const Color blush100 = Color(0xFFFFE4E9);
  static const Color blush200 = Color(0xFFFFCDD7);
  static const Color blush300 = Color(0xFFFFA5BA);
  static const Color blush400 = Color(0xFFFF7399);
  static const Color blush500 = Color(0xFFFF4D7D);
  static const Color blush600 = Color(0xFFED2660);
  static const Color blush700 = Color(0xFFCA1A4F);
  static const Color blush800 = Color(0xFFA91A4A);
  static const Color blush900 = Color(0xFF8F1946);
  static const Color blush950 = Color(0xFF500823);

  static const Color accentBlush50 = Color(0xFFFFF0F5);
  static const Color accentBlush100 = Color(0xFFFFE3EE);
  static const Color accentBlush200 = Color(0xFFFFC7DE);
  static const Color accentBlush300 = Color(0xFFFFA0C8);
  static const Color accentBlush400 = Color(0xFFFF69AA);
  static const Color accentBlush500 = Color(0xFFFB3A8F);
  static const Color accentBlush600 = Color(0xFFE91A70);
  static const Color accentBlush700 = Color(0xFFCB0D58);
  static const Color accentBlush800 = Color(0xFFA7104A);
  static const Color accentBlush900 = Color(0xFF8A1242);

  // --- Lavender (soft purple, inspired by Lovable secondary) ---------------
  static const Color lavender50 = Color(0xFFFAF7FD);
  static const Color lavender100 = Color(0xFFF3EEFA);
  static const Color lavender200 = Color(0xFFE9DDF7);
  static const Color lavender300 = Color(0xFFD6C2F0);
  static const Color lavender400 = Color(0xFFBB9BE6);
  static const Color lavender500 = Color(0xFFA076D8);
  static const Color lavender600 = Color(0xFF8857C4);
  static const Color lavender700 = Color(0xFF7545A7);
  static const Color lavender800 = Color(0xFF623C88);
  static const Color lavender900 = Color(0xFF52336F);
  static const Color lavender950 = Color(0xFF341D4C);

  static const Color accentLavender50 = Color(0xFFFBF5FF);
  static const Color accentLavender100 = Color(0xFFF4E8FF);
  static const Color accentLavender200 = Color(0xFFEBD6FF);
  static const Color accentLavender300 = Color(0xFFDBB5FF);
  static const Color accentLavender400 = Color(0xFFC485FF);
  static const Color accentLavender500 = Color(0xFFAE5AFF);
  static const Color accentLavender600 = Color(0xFF9833F5);
  static const Color accentLavender700 = Color(0xFF8520D8);
  static const Color accentLavender800 = Color(0xFF6F1CB0);
  static const Color accentLavender900 = Color(0xFF5D1B8F);

  // --- Mint (soft green/teal) ----------------------------------------------
  static const Color mint50 = Color(0xFFF0FDF9);
  static const Color mint100 = Color(0xFFCCFBEF);
  static const Color mint200 = Color(0xFF9AF6E1);
  static const Color mint300 = Color(0xFF5FEACF);
  static const Color mint400 = Color(0xFF2DD4BA);
  static const Color mint500 = Color(0xFF14B8A6);
  static const Color mint600 = Color(0xFF0D9488);
  static const Color mint700 = Color(0xFF0F766E);
  static const Color mint800 = Color(0xFF115E59);
  static const Color mint900 = Color(0xFF134E4A);
  static const Color mint950 = Color(0xFF042F2E);

  static const Color accentMint50 = Color(0xFFECFDF5);
  static const Color accentMint100 = Color(0xFFD1FAE5);
  static const Color accentMint200 = Color(0xFFA7F3D0);
  static const Color accentMint300 = Color(0xFF6EE7B7);
  static const Color accentMint400 = Color(0xFF34D399);
  static const Color accentMint500 = Color(0xFF10B981);
  static const Color accentMint600 = Color(0xFF059669);
  static const Color accentMint700 = Color(0xFF047857);
  static const Color accentMint800 = Color(0xFF065F46);
  static const Color accentMint900 = Color(0xFF064E3B);

  // --- Peach (warm coral/orange) -------------------------------------------
  static const Color peach50 = Color(0xFFFFF8F0);
  static const Color peach100 = Color(0xFFFFEDD5);
  static const Color peach200 = Color(0xFFFED7AA);
  static const Color peach300 = Color(0xFFFDBB74);
  static const Color peach400 = Color(0xFFFB923C);
  static const Color peach500 = Color(0xFFF97316);
  static const Color peach600 = Color(0xFFEA580C);
  static const Color peach700 = Color(0xFFC2410C);
  static const Color peach800 = Color(0xFF9A3412);
  static const Color peach900 = Color(0xFF7C2D12);
  static const Color peach950 = Color(0xFF431407);

  static const Color accentPeach50 = Color(0xFFFFF7ED);
  static const Color accentPeach100 = Color(0xFFFFEDD5);
  static const Color accentPeach200 = Color(0xFFFED7AA);
  static const Color accentPeach300 = Color(0xFFFDBB74);
  static const Color accentPeach400 = Color(0xFFFF9F59);
  static const Color accentPeach500 = Color(0xFFFF7A33);
  static const Color accentPeach600 = Color(0xFFED5C0D);
  static const Color accentPeach700 = Color(0xFFC54309);
  static const Color accentPeach800 = Color(0xFF9C360F);
  static const Color accentPeach900 = Color(0xFF7E2E10);
}
