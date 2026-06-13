import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/data/database/providers.dart';
import 'package:polaris/features/lifestyle/data/repositories/lifestyle_log_repository_impl.dart';
import 'package:polaris/features/lifestyle/domain/entities/lifestyle_log.dart';
import 'package:polaris/features/lifestyle/domain/repositories/lifestyle_log_repository.dart';

/// Drift-backed [LifestyleLogRepository]. Override in tests with an
/// in-memory fake to keep widget specs hermetic.
final Provider<LifestyleLogRepository> lifestyleLogRepositoryProvider =
    Provider<LifestyleLogRepository>(
      (ref) => LifestyleLogRepositoryImpl(
        ref.watch(appDatabaseProvider).lifestyleLogsDao,
      ),
    );

/// Reactive stream of every log within today's local-midnight window.
/// Powers the per-category summary cards on the LifestylePage.
final StreamProvider<List<LifestyleLog>> todayLogsStreamProvider =
    StreamProvider<List<LifestyleLog>>((ref) {
      final DateTime now = DateTime.now();
      final DateTime start = DateTime(now.year, now.month, now.day);
      // End of day = next midnight minus 1 ms. Inclusive bounds in
      // the DAO mean we cover everything stamped within today.
      final DateTime end = start
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));
      return ref
          .watch(lifestyleLogRepositoryProvider)
          .watchBetween(from: start, to: end);
    });

/// Reactive stream of the rolling 7-day history (today + previous 6
/// days), newest first. Used by the history list under the today
/// summary on LifestylePage.
final StreamProvider<List<LifestyleLog>> weekLogsStreamProvider =
    StreamProvider<List<LifestyleLog>>((ref) {
      final DateTime now = DateTime.now();
      final DateTime endOfToday = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
      final DateTime startOfWindow = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 6));
      return ref
          .watch(lifestyleLogRepositoryProvider)
          .watchBetween(from: startOfWindow, to: endOfToday);
    });
