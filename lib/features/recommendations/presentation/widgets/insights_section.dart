import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polaris/app/theme/color_tokens.dart';
import 'package:polaris/features/recommendations/application/providers.dart';
import 'package:polaris/features/recommendations/domain/entities/insight.dart';
import 'package:polaris/features/recommendations/presentation/widgets/insight_card.dart';

/// Drop-in section that renders the top N insights for the current
/// snapshot.
///
/// Hides itself entirely when there is nothing to show (no logs +
/// no life-phase milestone) so the host page doesn't grow an empty
/// "Insights" header that ages badly. The host decides padding /
/// surrounding spacers.
class InsightsSection extends ConsumerWidget {
  const InsightsSection({this.maxCards = 3, super.key});

  /// Cap on how many cards appear at once. The home surface is
  /// attention-limited; rules can fire more than this.
  final int maxCards;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Insight>> async = ref.watch(insightsProvider);

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (Object e, _) => const SizedBox.shrink(),
      data: (List<Insight> all) {
        if (all.isEmpty) return const SizedBox.shrink();
        final List<Insight> top = all.length > maxCards
            ? all.sublist(0, maxCards)
            : all;
        final ThemeData theme = Theme.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.x3),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: Spacing.x2),
                  Text(
                    'Insights for you',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            for (int i = 0; i < top.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: Spacing.x3),
              InsightCard(
                key: ValueKey<String>('insight-${top[i].id}'),
                insight: top[i],
                onActionTap: top[i].ctaRoute == null
                    ? null
                    : () => context.go(top[i].ctaRoute!),
              ),
            ],
          ],
        );
      },
    );
  }
}
