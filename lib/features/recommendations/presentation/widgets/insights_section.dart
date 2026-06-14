import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polaris/app/theme/color_tokens.dart';
import 'package:polaris/features/recommendations/application/providers.dart';
import 'package:polaris/features/recommendations/data/repositories/insight_dismissal_repository.dart';
import 'package:polaris/features/recommendations/domain/entities/insight.dart';
import 'package:polaris/features/recommendations/domain/entities/insight_spec.dart';
import 'package:polaris/features/recommendations/presentation/insight_content.dart';
import 'package:polaris/features/recommendations/presentation/widgets/insight_card.dart';
import 'package:polaris/l10n/generated/app_localizations.dart';

/// Drop-in section that renders the top N insights for the current
/// snapshot.
///
/// Hides itself entirely when there is nothing to show (no logs +
/// no life-phase milestone + everything dismissed) so the host page
/// doesn't grow an empty "Insights" header that ages badly. The
/// host decides padding / surrounding spacers.
///
/// Dismissals are first-class: each card carries a hide button that
/// puts the rule on a per-rule cooldown (3–30 days depending on the
/// rule). Undo is one tap from the Snackbar.
class InsightsSection extends ConsumerWidget {
  const InsightsSection({this.maxCards = 3, super.key});

  /// Cap on how many cards appear at once. The home surface is
  /// attention-limited; rules can fire more than this.
  final int maxCards;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<InsightSpec>> async = ref.watch(
      visibleInsightSpecsProvider,
    );

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (Object e, _) => const SizedBox.shrink(),
      data: (List<InsightSpec> all) {
        if (all.isEmpty) return const SizedBox.shrink();
        final List<InsightSpec> top = all.length > maxCards
            ? all.sublist(0, maxCards)
            : all;
        final ThemeData theme = Theme.of(context);
        final AppL l = AppL.of(context);
        final Locale locale = Localizations.localeOf(context);

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
                    l.insightsSectionTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            for (int i = 0; i < top.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: Spacing.x3),
              _SpecCard(spec: top[i], locale: locale, l: l),
            ],
          ],
        );
      },
    );
  }
}

/// Internal wrapper that resolves one [InsightSpec] into a rendered
/// [InsightCard] and owns the dismiss + Undo plumbing.
///
/// Pulled out so [InsightsSection] stays a list-renderer and the
/// per-card lifecycle (snackbar, repository call, optimistic
/// behaviour) lives next to the card it controls.
class _SpecCard extends ConsumerWidget {
  const _SpecCard({required this.spec, required this.locale, required this.l});

  final InsightSpec spec;
  final Locale locale;
  final AppL l;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Insight insight = InsightContent.resolve(
      spec: spec,
      l: l,
      locale: locale,
    );

    return InsightCard(
      key: ValueKey<String>('insight-${spec.id}'),
      insight: insight,
      onActionTap: spec.ctaRoute == null
          ? null
          : () => context.go(spec.ctaRoute!),
      onDismiss: () => _dismiss(context, ref),
    );
  }

  Future<void> _dismiss(BuildContext context, WidgetRef ref) async {
    final InsightDismissalRepository repo = ref.read(
      insightDismissalRepositoryProvider,
    );
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
    final int days = _coolDownInDays(spec.dismissCooldown);

    // Fire-and-forget the write so the UI re-renders immediately
    // via the dismissals stream — the snackbar handles user-facing
    // confirmation while the prefs write completes.
    await repo.dismiss(spec.id, cooldown: spec.dismissCooldown);

    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l.insightDismissedFor(days)),
        action: SnackBarAction(
          label: l.insightUndo,
          onPressed: () {
            ref.read(insightDismissalRepositoryProvider).undo(spec.id);
          },
        ),
      ),
    );
  }

  /// Rounds the duration up to whole days so the snackbar never
  /// says "Hidden for 0 days" (all current cooldowns are ≥ 1 day,
  /// but cheap insurance against future shorter ones).
  static int _coolDownInDays(Duration d) {
    final int floor = d.inDays;
    if (floor == 0) return 1;
    if (d.inHours % 24 != 0) return floor + 1;
    return floor;
  }
}
