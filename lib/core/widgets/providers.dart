import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/core/widgets/home_widget_updater.dart';

/// Concrete [HomeWidgetUpdater]. Overridden in `bootstrap()` so the
/// provider tree stays platform-agnostic for tests; tests inject an
/// in-memory fake instead of touching the `home_widget` MethodChannel.
final Provider<HomeWidgetUpdater> homeWidgetUpdaterProvider =
    Provider<HomeWidgetUpdater>(
  (ref) => throw UnimplementedError(
    'homeWidgetUpdaterProvider must be overridden in bootstrap() '
    '(or in tests).',
  ),
);
