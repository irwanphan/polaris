import 'package:flutter/material.dart';
import 'package:polaris/app/theme/color_tokens.dart';

/// Placeholder body for routes whose feature has not been built yet.
///
/// Replace each call site with the real feature page as milestones land
/// (see `docs/BRD Polaris.md §11`).
class ComingSoonView extends StatelessWidget {
  const ComingSoonView({
    required this.title,
    required this.milestone,
    this.description,
    super.key,
  });

  final String title;
  final String milestone;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.auto_awesome_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: Spacing.x4),
            Text(
              title,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.x2),
            Text(
              'Planned for $milestone',
              style: theme.textTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
            if (description != null) ...<Widget>[
              const SizedBox(height: Spacing.x4),
              Text(
                description!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
