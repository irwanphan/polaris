import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:polaris/app/theme/color_tokens.dart';
import 'package:polaris/shared/widgets/polaris_scaffold.dart';
import 'package:polaris/shared/widgets/section_card.dart';

/// Temporary landing page used during M0.
///
/// It links to each top-level route so wiring can be verified end-to-end
/// before the real home shell (bottom navigation + life-countdown hero) is
/// built in M1. Replace with `HomeShellPage` once `features/home/` lands.
class LauncherPage extends StatelessWidget {
  const LauncherPage({super.key});

  static const List<_LauncherDestination> _destinations =
      <_LauncherDestination>[
    _LauncherDestination(
      title: 'Sisa Hariku',
      subtitle: 'Life countdown',
      route: '/life',
      icon: Icons.hourglass_bottom_outlined,
      milestone: 'M1',
    ),
    _LauncherDestination(
      title: 'Events',
      subtitle: 'Birthdays, deadlines, trips',
      route: '/events',
      icon: Icons.event_outlined,
      milestone: 'M2',
    ),
    _LauncherDestination(
      title: 'Lifestyle',
      subtitle: 'Sleep, exercise, habits',
      route: '/lifestyle',
      icon: Icons.favorite_outline,
      milestone: 'M4',
    ),
    _LauncherDestination(
      title: 'Settings',
      subtitle: 'Preferences, locale, theme',
      route: '/settings',
      icon: Icons.settings_outlined,
      milestone: 'M0',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return PolarisScaffold(
      appBar: AppBar(
        title: const Text('Polaris'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
            onPressed: () => _showAbout(context),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          Text(
            'Your countdown companion',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: Spacing.x2),
          Text(
            'Pick a surface to explore. The real home will land in M1.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: Spacing.x6),
          for (final _LauncherDestination dest in _destinations) ...<Widget>[
            SectionCard(
              onTap: () => context.go(dest.route),
              leading: Icon(
                dest.icon,
                size: 28,
                color: theme.colorScheme.primary,
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(dest.title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: Spacing.x1),
                  Text(
                    '${dest.subtitle} · ${dest.milestone}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.x3),
          ],
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Polaris',
      applicationVersion: '0.1.0 (M0 scaffold)',
      applicationLegalese: '© Phandarian Studio',
      children: <Widget>[
        const SizedBox(height: Spacing.x2),
        const Text(
          'Polaris — your countdown companion. '
          'Track meaningful days, lifestyle, and life moments.',
        ),
      ],
    );
  }
}

class _LauncherDestination {
  const _LauncherDestination({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.milestone,
  });

  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final String milestone;
}
