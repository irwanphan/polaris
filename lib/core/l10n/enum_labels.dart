import 'package:flutter/widgets.dart';
import 'package:polaris/features/event_countdown/domain/value_objects/recurrence.dart';
import 'package:polaris/features/life_countdown/application/display_mode.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/sex.dart';
import 'package:polaris/features/lifestyle/domain/value_objects/log_category.dart';
import 'package:polaris/l10n/generated/app_localizations.dart';

/// Presentation-side mappers from domain enums → localized labels.
///
/// Domain layers keep their enums Flutter-free (no `BuildContext`,
/// no `AppL`). The UI uses these helpers whenever it needs a
/// user-visible string. Add a new enum value: extend the relevant
/// switch — the compiler will yell at every missing branch because
/// every `switch` here is exhaustive.
String sexLabel(BuildContext context, Sex sex) {
  final AppL l = AppL.of(context);
  return switch (sex) {
    Sex.female => l.sexFemale,
    Sex.male => l.sexMale,
    Sex.undisclosed => l.sexUndisclosed,
  };
}

String displayModeLabel(BuildContext context, DisplayMode mode) {
  final AppL l = AppL.of(context);
  return switch (mode) {
    DisplayMode.days => l.lifeDisplayDays,
    DisplayMode.weeks => l.lifeDisplayWeeks,
    DisplayMode.months => l.lifeDisplayMonths,
    DisplayMode.years => l.lifeDisplayYears,
    DisplayMode.percent => l.lifeDisplayPercent,
  };
}

/// All-caps unit shown under the big countdown number.
String displayModeUnitLabel(BuildContext context, DisplayMode mode) {
  final AppL l = AppL.of(context);
  return switch (mode) {
    DisplayMode.days => l.lifeUnitDays,
    DisplayMode.weeks => l.lifeUnitWeeks,
    DisplayMode.months => l.lifeUnitMonths,
    DisplayMode.years => l.lifeUnitYears,
    DisplayMode.percent => l.lifeUnitPercent,
  };
}

String recurrenceLabel(BuildContext context, Recurrence r) {
  final AppL l = AppL.of(context);
  return switch (r) {
    Recurrence.none => l.recurrenceNone,
    Recurrence.yearly => l.recurrenceYearly,
    Recurrence.monthly => l.recurrenceMonthly,
    Recurrence.weekly => l.recurrenceWeekly,
  };
}

String logCategoryLabel(BuildContext context, LogCategory c) {
  final AppL l = AppL.of(context);
  return switch (c) {
    LogCategory.water => l.lifestyleCategoryWater,
    LogCategory.sleep => l.lifestyleCategorySleep,
    LogCategory.exercise => l.lifestyleCategoryExercise,
    LogCategory.mood => l.lifestyleCategoryMood,
  };
}

String logCategoryUnit(BuildContext context, LogCategory c) {
  final AppL l = AppL.of(context);
  return switch (c) {
    LogCategory.water => l.lifestyleUnitGlasses,
    LogCategory.sleep => l.lifestyleUnitHours,
    LogCategory.exercise => l.lifestyleUnitMinutes,
    LogCategory.mood => l.lifestyleUnitMood,
  };
}
