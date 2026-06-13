import 'package:polaris/features/lifestyle/domain/value_objects/log_category.dart';
import 'package:uuid/uuid.dart';

/// A single lifestyle observation: "I drank one glass of water at
/// 09:15", "I slept 7.5 hours last night", "Mood today: 4/5".
///
/// Immutable by design; `copyWith` mints a new instance so the
/// Riverpod / Drift layers can reason about equality without ever
/// mutating shared state.
class LifestyleLog {
  /// Use [LifestyleLog.create] when minting a new log inside the app
  /// (it generates the uuid and timestamps for you). This raw
  /// constructor is here so the data layer can rehydrate rows.
  LifestyleLog({
    required this.id,
    required this.category,
    required this.value,
    required this.loggedAt,
    required this.createdAt,
    this.note,
  }) : assert(
         category.isValid(value),
         'Value $value out of range for $category',
       );

  /// Factory for the UI / controller layer. Stamps both timestamps
  /// to "now" and trims notes.
  factory LifestyleLog.create({
    required LogCategory category,
    required double value,
    DateTime? loggedAt,
    String? note,
  }) {
    final DateTime now = DateTime.now();
    return LifestyleLog(
      id: const Uuid().v4(),
      category: category,
      value: value,
      loggedAt: loggedAt ?? now,
      createdAt: now,
      note: _normalizeNote(note),
    );
  }

  final String id;
  final LogCategory category;
  final double value;
  final String? note;
  final DateTime loggedAt;
  final DateTime createdAt;

  LifestyleLog copyWith({
    String? id,
    LogCategory? category,
    double? value,
    String? note,
    DateTime? loggedAt,
    DateTime? createdAt,
  }) {
    // Passing `null` keeps the existing note — to clear, construct a
    // new instance directly.
    return LifestyleLog(
      id: id ?? this.id,
      category: category ?? this.category,
      value: value ?? this.value,
      note: note ?? this.note,
      loggedAt: loggedAt ?? this.loggedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static String? _normalizeNote(String? raw) {
    if (raw == null) return null;
    final String trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LifestyleLog &&
        other.id == id &&
        other.category == category &&
        other.value == value &&
        other.note == note &&
        other.loggedAt == loggedAt &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode =>
      Object.hash(id, category, value, note, loggedAt, createdAt);
}
