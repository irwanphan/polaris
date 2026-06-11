import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polaris/features/event_countdown/presentation/pages/event_countdown_page.dart';
import 'package:polaris/features/launcher/presentation/pages/launcher_page.dart';
import 'package:polaris/features/life_countdown/presentation/pages/life_countdown_page.dart';
import 'package:polaris/features/lifestyle/presentation/pages/lifestyle_page.dart';
import 'package:polaris/features/settings/presentation/pages/settings_page.dart';

/// Centralized route table for Polaris.
///
/// Adding a new top-level surface? Append a [GoRoute] here and add the
/// page widget under its feature folder. Avoid declaring routes inside
/// feature code so navigation stays auditable.
abstract final class AppRoutes {
  static const String launcher = '/';
  static const String life = '/life';
  static const String events = '/events';
  static const String lifestyle = '/lifestyle';
  static const String settings = '/settings';
}

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.launcher,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.launcher,
        name: 'launcher',
        builder: (context, state) => const LauncherPage(),
      ),
      GoRoute(
        path: AppRoutes.life,
        name: 'life',
        builder: (context, state) => const LifeCountdownPage(),
      ),
      GoRoute(
        path: AppRoutes.events,
        name: 'events',
        builder: (context, state) => const EventCountdownPage(),
      ),
      GoRoute(
        path: AppRoutes.lifestyle,
        name: 'lifestyle',
        builder: (context, state) => const LifestylePage(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});
