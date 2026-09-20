import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/app/router.dart';
import 'package:polaris/app/theme/app_theme.dart';
import 'package:polaris/app/theme/theme_controller.dart';
import 'package:polaris/core/deep_links/deep_link_handler.dart';
import 'package:polaris/core/l10n/locale_controller.dart';
import 'package:polaris/l10n/generated/app_localizations.dart';

/// Root widget. Listens to the router provider and wires the theme.
///
/// Keep this widget thin: it owns no business state. Any feature-level
/// state lives in feature providers consumed by their pages.
class PolarisApp extends ConsumerWidget {
  const PolarisApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final Locale? userLocale = ref.watch(localeControllerProvider);
    final AsyncValue<ThemeController> themeAsync = ref.watch(themeStreamProvider);
    
    final ThemeController themeCtrl = themeAsync.maybeWhen(
      data: (ThemeController ctrl) => ctrl,
      orElse: () => ref.read(themeControllerProvider),
    );
    
    return MaterialApp.router(
      onGenerateTitle: (BuildContext context) => AppL.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(palette: themeCtrl.palette),
      darkTheme: AppTheme.dark(palette: themeCtrl.palette),
      themeMode: themeCtrl.themeMode,
      locale: userLocale,
      supportedLocales: AppL.supportedLocales,
      localizationsDelegates: AppL.localizationsDelegates,
      routerConfig: router,
      // Wrap every routed page in the deep-link handler so the home
      // widget + notification tap listeners are always live, no
      // matter which surface the user opens first. Builder runs
      // *inside* the Router scope, so `GoRouter.of(context)` works.
      builder: (BuildContext context, Widget? child) {
        return PolarisDeepLinkHandler(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
