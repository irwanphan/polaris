import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/app/theme/color_tokens.dart';
import 'package:polaris/core/l10n/enum_labels.dart';
import 'package:polaris/features/lifestyle/application/lifestyle_controller.dart';
import 'package:polaris/features/lifestyle/application/providers.dart';
import 'package:polaris/features/lifestyle/domain/entities/lifestyle_log.dart';
import 'package:polaris/features/lifestyle/domain/value_objects/log_category.dart';
import 'package:polaris/features/lifestyle/presentation/widgets/category_summary_card.dart';
import 'package:polaris/features/lifestyle/presentation/widgets/log_history_tile.dart';
import 'package:polaris/features/lifestyle/presentation/widgets/quick_log_sheet.dart';
import 'package:polaris/l10n/generated/app_localizations.dart';
import 'package:polaris/shared/widgets/polaris_scaffold.dart';

/// M4 home for lifestyle logging.
///
/// Composition:
///   1. Today summary — 2-column grid of [CategorySummaryCard], one
///      per [LogCategory]. Tap a card to open [QuickLogSheet] with
///      that category pre-selected.
///   2. Recent history — flat list of the past 7 days' entries
///      (`weekLogsStreamProvider`), newest first.
///   3. Floating "Quick log" FAB — opens [QuickLogSheet] with no
///      pre-selection.
class LifestylePage extends ConsumerWidget {
  const LifestylePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<LifestyleLog>> todayAsync = ref.watch(
      todayLogsStreamProvider,
    );
    final AsyncValue<List<LifestyleLog>> weekAsync = ref.watch(
      weekLogsStreamProvider,
    );

    final AppL l = AppL.of(context);
    return PolarisScaffold(
      appBar: AppBar(title: Text(l.navLifestyle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => QuickLogSheet.show(context),
        icon: const Icon(Icons.add),
        label: Text(l.lifestyleQuickLog),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Streams refresh automatically; we keep the gesture as
          // an explicit affordance for users used to pull-to-refresh.
          ref
            ..invalidate(todayLogsStreamProvider)
            ..invalidate(weekLogsStreamProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            SliverToBoxAdapter(child: _TodaySummary(asyncLogs: todayAsync)),
            const SliverToBoxAdapter(child: SizedBox(height: Spacing.x6)),
            SliverToBoxAdapter(child: _HistoryHeader()),
            const SliverToBoxAdapter(child: SizedBox(height: Spacing.x3)),
            _HistorySliver(asyncLogs: weekAsync),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }
}

// --- Today summary -----------------------------------------------------------

class _TodaySummary extends StatelessWidget {
  const _TodaySummary({required this.asyncLogs});

  final AsyncValue<List<LifestyleLog>> asyncLogs;

  @override
  Widget build(BuildContext context) {
    return asyncLogs.when(
      loading: () => const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (Object e, _) => Padding(
        padding: const EdgeInsets.all(Spacing.x4),
        child: Text(AppL.of(context).lifestyleLoadFailed(e.toString())),
      ),
      data: (List<LifestyleLog> logs) {
        final Map<LogCategory, CategoryRollupView> rollups = rollupByCategory(
          logs,
        );
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: Spacing.x3,
          crossAxisSpacing: Spacing.x3,
          childAspectRatio: 1.05,
          children: <Widget>[
            for (final LogCategory c in LogCategory.values)
              CategorySummaryCard(
                category: c,
                displayValue: rollups[c]?.displayValue ?? '—',
                entriesCount: rollups[c]?.entriesCount,
                onTap: () => QuickLogSheet.show(context, initialCategory: c),
              ),
          ],
        );
      },
    );
  }
}

/// Pure aggregation used by the today summary grid.
///
/// Cumulative categories sum every entry today; snapshot categories
/// take the latest one. Returned as a public class + top-level
/// function so it can be unit-tested without spinning up a widget.
class CategoryRollupView {
  const CategoryRollupView({
    required this.displayValue,
    required this.entriesCount,
  });
  final String displayValue;
  final int entriesCount;
}

Map<LogCategory, CategoryRollupView> rollupByCategory(List<LifestyleLog> logs) {
  final Map<LogCategory, List<LifestyleLog>> byCat =
      <LogCategory, List<LifestyleLog>>{};
  for (final LifestyleLog log in logs) {
    byCat.putIfAbsent(log.category, () => <LifestyleLog>[]).add(log);
  }
  final Map<LogCategory, CategoryRollupView> out =
      <LogCategory, CategoryRollupView>{};
  byCat.forEach((LogCategory cat, List<LifestyleLog> rows) {
    if (rows.isEmpty) return;
    final int count = rows.length;
    final double resolved = switch (cat.aggregation) {
      LogAggregation.cumulative => rows.fold<double>(
        0,
        (double acc, LifestyleLog r) => acc + r.value,
      ),
      LogAggregation.snapshot =>
        (rows.toList()..sort(
              (LifestyleLog a, LifestyleLog b) =>
                  b.loggedAt.compareTo(a.loggedAt),
            ))
            .first
            .value,
    };
    final String display = cat.isInteger
        ? resolved.toInt().toString()
        : resolved.toStringAsFixed(1);
    out[cat] = CategoryRollupView(displayValue: display, entriesCount: count);
  });
  return out;
}

// --- History -----------------------------------------------------------------

class _HistoryHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppL l = AppL.of(context);
    return Row(
      children: <Widget>[
        Text(l.lifestyleHistoryHeader, style: theme.textTheme.titleMedium),
        const Spacer(),
        Flexible(
          child: Text(
            l.lifestyleHistoryHelper,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _HistorySliver extends ConsumerWidget {
  const _HistorySliver({required this.asyncLogs});

  final AsyncValue<List<LifestyleLog>> asyncLogs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncLogs.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: Spacing.x6),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (Object e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.x4),
          child: Text(AppL.of(context).lifestyleLoadFailed(e.toString())),
        ),
      ),
      data: (List<LifestyleLog> logs) {
        if (logs.isEmpty) {
          return const SliverToBoxAdapter(child: _HistoryEmpty());
        }
        return SliverList.separated(
          itemCount: logs.length,
          separatorBuilder: (_, _) => const SizedBox(height: Spacing.x2),
          itemBuilder: (BuildContext ctx, int i) {
            final LifestyleLog log = logs[i];
            return LogHistoryTile(
              log: log,
              onDelete: () => _confirmDelete(ctx, ref, log),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    LifestyleLog log,
  ) async {
    final AppL l = AppL.of(context);
    final String categoryLabel = logCategoryLabel(
      context,
      log.category,
    ).toLowerCase();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        final AppL dl = AppL.of(ctx);
        return AlertDialog(
          title: Text(dl.lifestyleDeleteConfirmTitle),
          content: Text(dl.lifestyleDeleteConfirmBody(categoryLabel)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(dl.commonCancel),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(dl.commonDelete),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref.read(lifestyleControllerProvider).delete(log.id);
    if (!context.mounted) return;
    if (result.isErr) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l.lifestyleDeleteFailed(result.failureOrNull.toString()),
          ),
        ),
      );
    }
  }
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppL l = AppL.of(context);
    return Padding(
      padding: const EdgeInsets.all(Spacing.x4),
      child: Container(
        padding: const EdgeInsets.all(Spacing.x6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        child: Column(
          children: <Widget>[
            Icon(Icons.history, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: Spacing.x2),
            Text(
              l.lifestyleHistoryEmpty,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.x1),
            Text(
              l.lifestyleHistoryEmptyHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
