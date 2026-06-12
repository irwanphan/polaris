import 'package:polaris/core/extensions/date_x.dart';
import 'package:polaris/features/event_countdown/domain/value_objects/recurrence.dart';
import 'package:uuid/uuid.dart';

/// A user-defined countdown event (birthday, deadline, trip, …).
///
/// Immutable. Mutate via [copyWith]. Persisted as a single row by the data
/// layer; recurring instances are computed on-the-fly via
/// [nextOccurrence] rather than materialised in the database.
final class Event {
  const Event({
    required this.id,
    required this.title,
    required this.targetAt,
    required this.colorHex,
    required this.iconKey,
    required this.recurrence,
    required this.isPinnedToWidget,
    required this.createdAt,
    required this.updatedAt,
    this.note,
  });

  /// Creates a brand-new event with a freshly-generated id and matching
  /// `createdAt` / `updatedAt` timestamps.
  factory Event.create({
    required String title,
    required DateTime targetAt,
    String colorHex = '#6366F1',
    String iconKey = 'event',
    String? note,
    Recurrence recurrence = Recurrence.none,
    bool isPinnedToWidget = false,
    DateTime? now,
  }) {
    final DateTime stamp = now ?? DateTime.now();
    return Event(
      id: _uuid.v4(),
      title: title,
      targetAt: targetAt,
      colorHex: colorHex,
      iconKey: iconKey,
      note: note,
      recurrence: recurrence,
      isPinnedToWidget: isPinnedToWidget,
      createdAt: stamp,
      updatedAt: stamp,
    );
  }

  static const Uuid _uuid = Uuid();

  final String id;
  final String title;
  final DateTime targetAt;
  final String colorHex;
  final String iconKey;
  final String? note;
  final Recurrence recurrence;
  final bool isPinnedToWidget;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Returns a copy with the supplied fields replaced.
  ///
  /// Passing `null` for a nullable field means "leave unchanged". To
  /// **clear** [note], construct a new [Event] directly instead.
  Event copyWith({
    String? title,
    DateTime? targetAt,
    String? colorHex,
    String? iconKey,
    String? note,
    Recurrence? recurrence,
    bool? isPinnedToWidget,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id,
      title: title ?? this.title,
      targetAt: targetAt ?? this.targetAt,
      colorHex: colorHex ?? this.colorHex,
      iconKey: iconKey ?? this.iconKey,
      note: note ?? this.note,
      recurrence: recurrence ?? this.recurrence,
      isPinnedToWidget: isPinnedToWidget ?? this.isPinnedToWidget,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Returns the next occurrence on or after [now], honoring [recurrence].
  ///
  /// For one-time events this is always [targetAt] (may be in the past).
  /// Calendar quirks handled:
  ///  - Yearly on Feb 29 of a non-leap year falls back to Feb 28.
  ///  - Monthly on day 31 in a 30-day month falls back to the last day.
  DateTime nextOccurrence(DateTime now) {
    if (recurrence == Recurrence.none) return targetAt;
    if (!targetAt.isBefore(now)) return targetAt;

    return switch (recurrence) {
      Recurrence.none => targetAt,
      Recurrence.yearly => _nextYearly(now),
      Recurrence.monthly => _nextMonthly(now),
      Recurrence.weekly => _nextWeekly(now),
    };
  }

  /// Whole days from [now] (at start of day) until the next occurrence,
  /// clamped to a minimum of 0. For one-time events that already passed,
  /// returns 0 — UI typically renders this with a "passed" badge.
  int daysUntil(DateTime now) {
    final DateTime nextDay = nextOccurrence(now).atStartOfDay;
    final int diff = now.atStartOfDay.daysUntil(nextDay);
    return diff < 0 ? 0 : diff;
  }

  bool get isPast => targetAt.isBefore(DateTime.now());

  // --- Recurrence math ----------------------------------------------------

  DateTime _nextYearly(DateTime now) {
    final int year = now.year;
    DateTime candidate =
        _withSameTime(_safeDate(year, targetAt.month, targetAt.day));
    if (candidate.isBefore(now)) {
      candidate =
          _withSameTime(_safeDate(year + 1, targetAt.month, targetAt.day));
    }
    return candidate;
  }

  DateTime _nextMonthly(DateTime now) {
    int year = now.year;
    int month = now.month;
    DateTime candidate = _withSameTime(_safeDate(year, month, targetAt.day));
    if (candidate.isBefore(now)) {
      month += 1;
      if (month > 12) {
        year += 1;
        month = 1;
      }
      candidate = _withSameTime(_safeDate(year, month, targetAt.day));
    }
    return candidate;
  }

  DateTime _nextWeekly(DateTime now) {
    final int targetWeekday = targetAt.weekday;
    int delta = (targetWeekday - now.weekday) % 7;
    if (delta < 0) delta += 7;
    DateTime candidate = _withSameTime(
      DateTime(now.year, now.month, now.day).add(Duration(days: delta)),
    );
    if (candidate.isBefore(now)) {
      candidate = candidate.add(const Duration(days: 7));
    }
    return candidate;
  }

  DateTime _withSameTime(DateTime date) => DateTime(
        date.year,
        date.month,
        date.day,
        targetAt.hour,
        targetAt.minute,
        targetAt.second,
      );

  /// Returns a date clamped to the last valid day of the month — handles
  /// Feb 29 → Feb 28 and 31st → 30th/last day gracefully.
  static DateTime _safeDate(int year, int month, int day) {
    final int lastDay = DateTime(year, month + 1, 0).day;
    final int safeDay = day > lastDay ? lastDay : day;
    return DateTime(year, month, safeDay);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Event &&
        other.id == id &&
        other.title == title &&
        other.targetAt == targetAt &&
        other.colorHex == colorHex &&
        other.iconKey == iconKey &&
        other.note == note &&
        other.recurrence == recurrence &&
        other.isPinnedToWidget == isPinnedToWidget &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        targetAt,
        colorHex,
        iconKey,
        note,
        recurrence,
        isPinnedToWidget,
        createdAt,
        updatedAt,
      );
}
