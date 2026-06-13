import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:polaris/app/router.dart';
import 'package:polaris/app/theme/color_tokens.dart';
import 'package:polaris/features/life_countdown/application/display_mode.dart';
import 'package:polaris/features/life_countdown/application/life_countdown_controller.dart';
import 'package:polaris/features/life_countdown/domain/entities/life_estimate.dart';
import 'package:polaris/features/life_countdown/presentation/widgets/countdown_display.dart';
import 'package:polaris/features/life_countdown/presentation/widgets/disclaimer_note.dart';
import 'package:polaris/features/life_countdown/presentation/widgets/display_mode_segmented.dart';
import 'package:polaris/features/recommendations/presentation/widgets/insights_section.dart';
import 'package:polaris/shared/widgets/polaris_scaffold.dart';
import 'package:polaris/shared/widgets/section_card.dart';

/// Live life-countdown screen.
///
/// Re-runs the estimator every minute so day/week/month figures update
/// without requiring a navigation.
class LifeCountdownPage extends ConsumerStatefulWidget {
  const LifeCountdownPage({super.key});

  @override
  ConsumerState<LifeCountdownPage> createState() => _LifeCountdownPageState();
}

class _LifeCountdownPageState extends ConsumerState<LifeCountdownPage> {
  DisplayMode _mode = DisplayMode.days;
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _tickTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      ref.invalidate(lifeCountdownControllerProvider);
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<LifeEstimate?> estimate = ref.watch(
      lifeCountdownControllerProvider,
    );

    return PolarisScaffold(
      appBar: AppBar(title: const Text('Sisa Hariku')),
      body: estimate.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) =>
            Center(child: Text('Failed to compute estimate: $e')),
        data: (LifeEstimate? value) {
          if (value == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.go(AppRoutes.onboarding);
            });
            return const SizedBox.shrink();
          }
          return _Loaded(
            estimate: value,
            mode: _mode,
            onModeChanged: (m) {
              setState(() => _mode = m);
            },
          );
        },
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.estimate,
    required this.mode,
    required this.onModeChanged,
  });

  final LifeEstimate estimate;
  final DisplayMode mode;
  final ValueChanged<DisplayMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateFormat dateFmt = DateFormat.yMMMMd();

    return ListView(
      children: <Widget>[
        const SizedBox(height: Spacing.x6),
        CountdownDisplay(estimate: estimate, mode: mode),
        const SizedBox(height: Spacing.x8),
        Center(
          child: DisplayModeSegmented(selected: mode, onChanged: onModeChanged),
        ),
        const SizedBox(height: Spacing.x8),
        const InsightsSection(),
        const SizedBox(height: Spacing.x6),
        SectionCard(
          leading: Icon(Icons.timeline, color: theme.colorScheme.primary),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Estimated end date', style: theme.textTheme.labelLarge),
              const SizedBox(height: Spacing.x1),
              Text(
                dateFmt.format(estimate.estimatedEndDate),
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.x3),
        SectionCard(
          leading: Icon(Icons.bar_chart, color: theme.colorScheme.primary),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Expectancy used', style: theme.textTheme.labelLarge),
              const SizedBox(height: Spacing.x1),
              Text(
                '${estimate.expectancyYears.toStringAsFixed(1)} years',
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.x6),
        const DisclaimerNote(),
      ],
    );
  }
}
