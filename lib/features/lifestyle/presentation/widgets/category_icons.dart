import 'package:flutter/material.dart';
import 'package:polaris/features/lifestyle/domain/value_objects/log_category.dart';

/// Maps each [LogCategory] to a `const IconData`.
///
/// Lives in presentation, not domain, so the domain layer stays
/// Flutter-free. Using `const` Material `Icons` lets call sites
/// satisfy `IconData`-as-const-required APIs (e.g. `Icon(const X)`)
/// without runtime `IconData` constructors that the analyzer flags
/// as `non_const_argument_for_const_parameter`.
IconData iconFor(LogCategory category) {
  return switch (category) {
    LogCategory.water => Icons.water_drop_outlined,
    LogCategory.sleep => Icons.bedtime_outlined,
    LogCategory.exercise => Icons.fitness_center,
    LogCategory.mood => Icons.mood_outlined,
  };
}
