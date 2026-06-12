import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Top-level shell that owns the persistent bottom navigation.
///
/// Each tab is a [StatefulNavigationShell] branch so its widget tree
/// (including scroll positions, controllers, and Riverpod
/// auto-disposers) survives tab switches. Deep links to `/life`,
/// `/events`, `/lifestyle`, `/settings` switch the active tab and
/// preserve back-stacks per-branch.
class HomeShellPage extends StatelessWidget {
  const HomeShellPage({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const List<_NavItem> _items = <_NavItem>[
    _NavItem(
      label: 'Life',
      icon: Icons.hourglass_bottom_outlined,
      selectedIcon: Icons.hourglass_bottom,
    ),
    _NavItem(
      label: 'Events',
      icon: Icons.event_outlined,
      selectedIcon: Icons.event,
    ),
    _NavItem(
      label: 'Lifestyle',
      icon: Icons.favorite_outline,
      selectedIcon: Icons.favorite,
    ),
    _NavItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  void _onTap(int index) {
    // Tapping the active tab pops the branch to its root for a
    // familiar "return to start" gesture.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: <NavigationDestination>[
          for (final _NavItem item in _items)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
