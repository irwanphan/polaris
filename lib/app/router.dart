import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polaris/features/event_countdown/presentation/pages/event_countdown_page.dart';
import 'package:polaris/features/home/presentation/pages/home_shell_page.dart';
import 'package:polaris/features/life_countdown/application/life_profile_controller.dart';
import 'package:polaris/features/life_countdown/presentation/pages/life_countdown_page.dart';
import 'package:polaris/features/life_countdown/presentation/pages/onboarding_page.dart';
import 'package:polaris/features/lifestyle/presentation/pages/lifestyle_page.dart';
import 'package:polaris/features/settings/presentation/pages/settings_page.dart';

/// Centralized route table for Polaris.
///
/// All four primary surfaces (Life, Events, Lifestyle, Settings) are
/// branches of a [StatefulShellRoute] so they share a persistent
/// bottom navigation. Onboarding is a standalone full-screen route
/// outside the shell.
abstract final class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String life = '/life';
  static const String events = '/events';
  static const String lifestyle = '/lifestyle';
  static const String settings = '/settings';
}

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.life,
    redirect: (context, state) {
      // Onboarding must be reachable even without a profile, otherwise
      // the user is stuck in a redirect loop.
      if (state.matchedLocation == AppRoutes.onboarding) return null;
      if (state.matchedLocation != AppRoutes.life) return null;

      final profileAsync = ref.read(lifeProfileControllerProvider);
      return profileAsync.maybeWhen(
        data: (profile) => profile == null ? AppRoutes.onboarding : null,
        orElse: () => null,
      );
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShellPage(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.life,
                name: 'life',
                builder: (context, state) => const LifeCountdownPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.events,
                name: 'events',
                builder: (context, state) => const EventCountdownPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.lifestyle,
                name: 'lifestyle',
                builder: (context, state) => const LifestylePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.settings,
                name: 'settings',
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
