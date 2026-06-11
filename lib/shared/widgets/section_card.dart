import 'package:flutter/material.dart';
import 'package:polaris/app/theme/color_tokens.dart';

/// A bordered, rounded surface for grouping related content on a page.
///
/// Use a [SectionCard] to wrap any logically-grouped block (countdown,
/// event item, insight card). Avoid nesting cards inside cards — prefer a
/// `Column` of cards on a flat surface.
class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(Spacing.x4),
    this.onTap,
    this.leading,
    this.trailing,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BorderRadius radius = BorderRadius.circular(Radii.xl);

    final Widget content = Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (leading != null) ...<Widget>[
            leading!,
            const SizedBox(width: Spacing.x3),
          ],
          Expanded(child: child),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: Spacing.x3),
            trailing!,
          ],
        ],
      ),
    );

    final Widget card = Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: radius,
      child: onTap == null
          ? content
          : InkWell(
              borderRadius: radius,
              onTap: onTap,
              child: content,
            ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: ClipRRect(borderRadius: radius, child: card),
    );
  }
}
