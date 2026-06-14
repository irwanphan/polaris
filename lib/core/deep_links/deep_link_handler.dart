import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';
import 'package:polaris/app/router.dart';
import 'package:polaris/core/deep_links/deep_link_router.dart';
import 'package:polaris/core/logging/app_logger.dart';
import 'package:polaris/features/event_countdown/application/providers.dart';

/// Listens to every external launch surface and forwards a single
/// navigation intent to the app's [GoRouter].
///
/// Funnel:
///
///   ┌────────────────────────┐
///   │ HomeWidget cold start  │─┐
///   │ HomeWidget warm taps   │─┤
///   │ Notification cold pay. │─┼──→  Uri → DeepLinkRouter.resolve()
///   │ Notification taps      │─┘                  │
///                                                 ▼
///                                       GoRouter.go(path)
///
/// The widget is mounted high in the tree (right under [PolarisApp])
/// so it boots once per process and lives for the whole session.
/// Subscriptions cancel cleanly on dispose to keep hot-reload sane.
///
/// Cold-start handling intentionally runs in [didChangeDependencies]
/// (the first frame after the router is available) rather than the
/// constructor so the router has time to settle on its initial
/// location — otherwise the deep-link `go()` races the boot redirect.
class PolarisDeepLinkHandler extends ConsumerStatefulWidget {
  const PolarisDeepLinkHandler({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<PolarisDeepLinkHandler> createState() =>
      _PolarisDeepLinkHandlerState();
}

class _PolarisDeepLinkHandlerState
    extends ConsumerState<PolarisDeepLinkHandler> {
  StreamSubscription<Uri?>? _widgetTapSub;
  StreamSubscription<String?>? _notifTapSub;
  bool _coldStartHandled = false;

  @override
  void initState() {
    super.initState();
    _wireWarmListeners();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Schedule the cold-start drain after the first frame: the
    // router needs to mount and execute its initial redirect before
    // we push another navigation onto it.
    if (!_coldStartHandled) {
      _coldStartHandled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _drainColdStart());
    }
  }

  @override
  void dispose() {
    _widgetTapSub?.cancel();
    _notifTapSub?.cancel();
    super.dispose();
  }

  void _wireWarmListeners() {
    // Home-screen widget warm taps. The home_widget plugin emits a
    // Uri (potentially null) for every tap on a widget pendingIntent
    // template + fill-in pair set up natively.
    _widgetTapSub = HomeWidget.widgetClicked.listen(
      _navigate,
      onError: (Object e, StackTrace st) {
        _safeLogger?.warn(
          'home_widget tap stream errored',
          error: e,
          stackTrace: st,
        );
      },
    );

    // Notification foreground/background taps — bridged by the
    // dispatcher's broadcast controller (see
    // `FlutterLocalNotificationsDispatcher.tapPayloads`).
    _notifTapSub = ref
        .read(notificationDispatcherProvider)
        .tapPayloads
        .listen(
          (String? payload) =>
              _navigate(DeepLinkRouter.notificationPayloadToUri(payload)),
          onError: (Object e, StackTrace st) {
            _safeLogger?.warn(
              'notification tap stream errored',
              error: e,
              stackTrace: st,
            );
          },
        );
  }

  Future<void> _drainColdStart() async {
    // Widget cold start.
    try {
      final Uri? widgetUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (widgetUri != null) _navigate(widgetUri);
    } catch (e, st) {
      _safeLogger?.warn(
        'initiallyLaunchedFromHomeWidget failed',
        error: e,
        stackTrace: st,
      );
    }

    // Notification cold start.
    try {
      final String? payload = await ref
          .read(notificationDispatcherProvider)
          .consumeColdStartPayload();
      _navigate(DeepLinkRouter.notificationPayloadToUri(payload));
    } catch (e, st) {
      _safeLogger?.warn(
        'consumeColdStartPayload failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  void _navigate(Uri? uri) {
    final String? path = DeepLinkRouter.resolve(uri);
    if (path == null) return;
    if (!mounted) return;
    final GoRouter router = GoRouter.of(context);

    // For event detail we want to land on the page *with* the
    // events list underneath in the back stack — so the user can
    // pop back to the list and see other pinned items. Switch the
    // shell branch to events first, then push the detail child.
    if (path.startsWith('${AppRoutes.events}/')) {
      router.go(AppRoutes.events);
      // microtask so the branch swap renders before the detail
      // pushes; avoids a frame where the wrong tab is visible.
      scheduleMicrotask(() {
        if (!mounted) return;
        router.push(path);
      });
      return;
    }

    router.go(path);
  }

  AppLogger? get _safeLogger {
    // Tests / early-boot calls may not have the logger override in
    // place. Tolerate both cases so deep-link wiring never crashes
    // the app shell.
    try {
      return ref.read(appLoggerProvider);
    } on Object {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
