import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polaris/core/deep_links/deep_link_router.dart';
import 'package:polaris/features/event_countdown/presentation/pages/event_countdown_page.dart';
import 'package:polaris/features/event_countdown/presentation/pages/event_detail_page.dart';
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

  /// Helper for callers that need to build an event detail location
  /// from a known id. Centralized so the path-template lives next
  /// to its sibling constants and is the one source of truth used
  /// by deep-link handlers, list-tap navigation, and tests.
  static String eventDetail(String id) => '$events/$id';
}

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.life,
    redirect: (context, state) {
      // Cold-start deep links: when the OS hands Flutter a launch
      // URI like `polaris://events/<id>` (from a widget tap on a
      // freshly-killed process), `state.uri` arrives with a non-
      // empty scheme that no GoRoute matches. Rewrite it through
      // the canonical resolver so it lands on the proper in-app
      // route. Warm taps go through `PolarisDeepLinkHandler` and
      // never reach this branch.
      final Uri rawUri = state.uri;
      if (rawUri.hasScheme) {
        final String? resolved = DeepLinkRouter.resolve(rawUri);
        if (resolved != null) return resolved;
      }

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
                routes: <RouteBase>[
                  // `/events/:id` — pushed above the bottom-nav shell
                  // so the page gets a Back affordance and the user
                  // can return to the list with a single gesture.
                  // Deep links from the home-screen widget and from
                  // tapped notifications also land here.
                  GoRoute(
                    path: ':id',
                    name: 'eventDetail',
                    builder: (BuildContext context, GoRouterState state) {
                      final String id = state.pathParameters['id']!;
                      return EventDetailPage(eventId: id);
                    },
                  ),
                ],
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
