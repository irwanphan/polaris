import 'package:flutter/material.dart';
import 'package:polaris/app/theme/color_palette.dart';
import 'package:polaris/app/theme/color_tokens.dart';

/// Theme palette picker that displays color swatches for each available palette.
///
/// Shows a horizontal scrollable row of palette cards with visual previews
/// of the primary and secondary colors.
class ThemePickerTile extends StatelessWidget {
  const ThemePickerTile({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final ColorPalette selected;
  final ValueChanged<ColorPalette> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.x4,
            vertical: Spacing.x2,
          ),
          child: Text(
            'Color Palette',
            style: theme.textTheme.labelLarge,
          ),
        ),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.x4),
            itemCount: ColorPalette.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: Spacing.x3),
            itemBuilder: (BuildContext context, int index) {
              final ColorPalette palette = ColorPalette.values[index];
              final bool isSelected = palette == selected;

              return _PaletteCard(
                palette: palette,
                isSelected: isSelected,
                onTap: () => onChanged(palette),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PaletteCard extends StatelessWidget {
  const _PaletteCard({
    required this.palette,
    required this.isSelected,
    required this.onTap,
  });

  final ColorPalette palette;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color primaryColor = _getPrimaryColor(palette);
    final Color secondaryColor = _getSecondaryColor(palette);

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(Radii.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.lg),
        child: Container(
          width: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: Spacing.x1),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: secondaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.x2),
              Text(
                palette.label(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPrimaryColor(ColorPalette palette) {
    return switch (palette) {
      ColorPalette.midnight => PaletteTokens.midnight600,
      ColorPalette.blush => PaletteTokens.blush500,
      ColorPalette.lavender => PaletteTokens.lavender500,
      ColorPalette.mint => PaletteTokens.mint500,
      ColorPalette.peach => PaletteTokens.peach500,
    };
  }

  Color _getSecondaryColor(ColorPalette palette) {
    return switch (palette) {
      ColorPalette.midnight => PaletteTokens.starlightMidnight500,
      ColorPalette.blush => PaletteTokens.accentBlush500,
      ColorPalette.lavender => PaletteTokens.accentLavender500,
      ColorPalette.mint => PaletteTokens.accentMint500,
      ColorPalette.peach => PaletteTokens.accentPeach500,
    };
  }
}
