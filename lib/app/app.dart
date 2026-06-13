import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/app/router.dart';
import 'package:polaris/app/theme/app_theme.dart';
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
    return MaterialApp.router(
      onGenerateTitle: (BuildContext context) => AppL.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      locale: userLocale,
      supportedLocales: AppL.supportedLocales,
      localizationsDelegates: AppL.localizationsDelegates,
      routerConfig: router,
    );
  }
}
