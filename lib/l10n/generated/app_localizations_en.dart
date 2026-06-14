// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLEn extends AppL {
  AppLEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Polaris';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSaving => 'Saving…';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonOk => 'OK';

  @override
  String get commonRetry => 'Retry';

  @override
  String get navLife => 'Life';

  @override
  String get navEvents => 'Events';

  @override
  String get navLifestyle => 'Lifestyle';

  @override
  String get navSettings => 'Settings';

  @override
  String get onboardingWelcome => 'Welcome to Polaris';

  @override
  String get onboardingSetup => 'Set up your countdown';

  @override
  String get onboardingDescription =>
      'These details stay on your device. They are used to estimate your remaining time using public life-expectancy tables.';

  @override
  String get onboardingBirthDate => 'Birth date';

  @override
  String get onboardingSex => 'Biological sex';

  @override
  String get onboardingCountry => 'Country';

  @override
  String get onboardingStart => 'Start countdown';

  @override
  String get onboardingDisclaimer =>
      'Estimation only — based on public life-expectancy tables (WHO, BPS). Not a medical prediction.';

  @override
  String get sexFemale => 'Female';

  @override
  String get sexMale => 'Male';

  @override
  String get sexUndisclosed => 'Prefer not';

  @override
  String get lifeTitle => 'Sisa Hariku';

  @override
  String get lifeDisplayDays => 'Days';

  @override
  String get lifeDisplayWeeks => 'Weeks';

  @override
  String get lifeDisplayMonths => 'Months';

  @override
  String get lifeDisplayYears => 'Years';

  @override
  String get lifeDisplayPercent => '%';

  @override
  String lifeAlreadyLived(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formatted days already lived',
      one: '1 day already lived',
    );
    return '$_temp0';
  }

  @override
  String get lifeEstimatedEndDate => 'Estimated end date';

  @override
  String get lifeExpectancyUsed => 'Expectancy used';

  @override
  String lifeExpectancyYears(String years) {
    return '$years years';
  }

  @override
  String lifeFailedToCompute(String error) {
    return 'Failed to compute estimate: $error';
  }

  @override
  String get lifeUnitDays => 'DAYS REMAINING';

  @override
  String get lifeUnitWeeks => 'WEEKS REMAINING';

  @override
  String get lifeUnitMonths => 'MONTHS REMAINING';

  @override
  String get lifeUnitYears => 'YEARS REMAINING';

  @override
  String get lifeUnitPercent => 'LIVED';

  @override
  String get eventsNewEvent => 'New event';

  @override
  String get eventsEmptyTitle => 'No events yet';

  @override
  String get eventsEmptyBody =>
      'Tap \"New event\" to add a birthday, deadline, or trip — then pin one to your home-screen widget.';

  @override
  String get eventsEditTitle => 'Edit event';

  @override
  String get eventsNewTitle => 'New event';

  @override
  String get eventsFieldTitle => 'Title';

  @override
  String get eventsFieldTitleRequired => 'Title is required.';

  @override
  String get eventsFieldWhen => 'When';

  @override
  String get eventsFieldRepeats => 'Repeats';

  @override
  String get eventsFieldNote => 'Note (optional)';

  @override
  String get eventsFieldWidgetMessage => 'Widget message (optional)';

  @override
  String get eventsFieldWidgetMessageHelper =>
      'Shown on the home-screen widget when this event is pinned. Replaces the auto date · recurrence line.';

  @override
  String get eventsAccentColor => 'Accent color';

  @override
  String get eventsDeleteConfirmTitle => 'Delete event?';

  @override
  String eventsDeleteConfirmBody(String title) {
    return '\"$title\" will be removed.';
  }

  @override
  String eventsPinFailed(String error) {
    return 'Pin failed: $error';
  }

  @override
  String eventsDeleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String eventsSaveFailed(String error) {
    return 'Could not save: $error';
  }

  @override
  String get eventsCountdownToday => 'Today';

  @override
  String get eventsCountdownTomorrow => 'Tomorrow';

  @override
  String eventsCountdownDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get eventsCountdownPast => 'Past';

  @override
  String get eventsActionPin => 'Pin';

  @override
  String get eventsActionUnpin => 'Unpin';

  @override
  String get eventsActionDelete => 'Delete';

  @override
  String get eventsActionsMenuLabel => 'More actions';

  @override
  String get eventsPinnedSemanticLabel => 'Pinned to widget';

  @override
  String eventsCountdownBadgeSemanticLabel(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days remaining',
      one: '1 day remaining',
      zero: 'Today',
    );
    return '$_temp0';
  }

  @override
  String lifeCountdownSemanticLabel(String value, String unit) {
    return '$value $unit';
  }

  @override
  String get recurrenceNone => 'Does not repeat';

  @override
  String get recurrenceYearly => 'Yearly';

  @override
  String get recurrenceMonthly => 'Monthly';

  @override
  String get recurrenceWeekly => 'Weekly';

  @override
  String get lifestyleQuickLog => 'Quick log';

  @override
  String get lifestyleHistoryHeader => 'Last 7 days';

  @override
  String get lifestyleHistoryHelper => 'Swipe a row to delete';

  @override
  String get lifestyleHistoryEmpty => 'No entries in the last 7 days.';

  @override
  String get lifestyleHistoryEmptyHint =>
      'Tap \"Quick log\" to record your first entry.';

  @override
  String get lifestyleCategoryWater => 'Water';

  @override
  String get lifestyleCategorySleep => 'Sleep';

  @override
  String get lifestyleCategoryExercise => 'Exercise';

  @override
  String get lifestyleCategoryMood => 'Mood';

  @override
  String get lifestyleUnitGlasses => 'glasses';

  @override
  String get lifestyleUnitHours => 'hours';

  @override
  String get lifestyleUnitMinutes => 'minutes';

  @override
  String get lifestyleUnitMood => '/5';

  @override
  String lifestyleEntriesToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries today',
      one: '1 entry today',
    );
    return '$_temp0';
  }

  @override
  String get lifestyleDeleteConfirmTitle => 'Delete entry?';

  @override
  String lifestyleDeleteConfirmBody(String category) {
    return 'Remove this $category log?';
  }

  @override
  String get lifestyleQuickLogCategory => 'Category';

  @override
  String get lifestyleQuickLogValue => 'Value';

  @override
  String lifestyleQuickLogRange(String min, String max, String unit) {
    return '$min–$max $unit';
  }

  @override
  String get lifestyleQuickLogValueRequired => 'Enter a number.';

  @override
  String lifestyleQuickLogValueOutOfRange(String range, String unit) {
    return 'Must be $range $unit.';
  }

  @override
  String get lifestyleNoteOptional => 'Note (optional)';

  @override
  String lifestyleSaveFailed(String error) {
    return 'Could not save: $error';
  }

  @override
  String lifestyleDeleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get lifestyleHistoryYesterday => 'Yesterday';

  @override
  String lifestyleHistoryDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String lifestyleLoadFailed(String error) {
    return 'Failed to load: $error';
  }

  @override
  String get insightsSectionTitle => 'Insights for you';

  @override
  String get insightDismiss => 'Dismiss';

  @override
  String get insightDismissSemanticLabel => 'Hide this insight';

  @override
  String insightDismissedFor(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Hidden for $days days',
      one: 'Hidden for 1 day',
    );
    return '$_temp0';
  }

  @override
  String get insightUndo => 'Undo';

  @override
  String get insightWaterTargetTitle => 'Drink a bit more water';

  @override
  String insightWaterTargetBody(int windowDays, String avg, String target) {
    return 'Last $windowDays days you averaged $avg glasses/day. A common target is $target+. Add a glass at the next break.';
  }

  @override
  String get insightWaterTargetCta => 'Log water';

  @override
  String get insightSleepRegularityTitle => 'Short on sleep this week';

  @override
  String insightSleepRegularityBody(
    int shortCount,
    int totalCount,
    String minHours,
  ) {
    return '$shortCount of the last $totalCount logged nights were under ${minHours}h. Try an earlier wind-down tonight.';
  }

  @override
  String get insightSleepRegularityCta => 'Log sleep';

  @override
  String get insightExerciseStreakTitle => 'Move a bit this week';

  @override
  String insightExerciseStreakBody(int windowDays) {
    return 'No exercise logged in the last $windowDays days. Even a 10-minute walk counts — log it and start a streak.';
  }

  @override
  String get insightExerciseStreakCta => 'Log exercise';

  @override
  String get insightMoodTrendTitle => 'Mood trending down';

  @override
  String insightMoodTrendBody(int run) {
    return 'The last $run mood logs were each lower than the day before. Something on your mind — short walk, call a friend, or just log how today felt.';
  }

  @override
  String get insightMoodTrendCta => 'Log mood';

  @override
  String insightLifePhaseTitle(int pct) {
    return 'You\'ve lived $pct% of your estimated life';
  }

  @override
  String insightLifePhaseBody(String remainingYears, int remainingDays) {
    final intl.NumberFormat remainingDaysNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String remainingDaysString = remainingDaysNumberFormat.format(
      remainingDays,
    );

    return 'About $remainingYears years (~$remainingDaysString days) left on the public-table estimate. Pin one event that matters most to you.';
  }

  @override
  String get insightLifePhaseCta => 'Pin an event';

  @override
  String get insightNoDataTitle => 'Log your first entry';

  @override
  String get insightNoDataBody =>
      'Polaris gets sharper once it learns your rhythm. Tap \"Quick log\" on the Lifestyle tab to record water, sleep, exercise, or mood.';

  @override
  String get insightNoDataCta => 'Open Lifestyle';

  @override
  String get insightPositiveExerciseStreakTitle => 'Great week on the move';

  @override
  String insightPositiveExerciseStreakBody(
    int activeDays,
    int windowDays,
    String totalMinutes,
  ) {
    return 'You logged exercise on $activeDays of the last $windowDays days — $totalMinutes minutes total. Keep the rhythm.';
  }

  @override
  String get insightPositiveExerciseStreakCta => 'Log today';

  @override
  String get insightLowSleepHydrationTitle => 'Hydrate to soften a tough week';

  @override
  String insightLowSleepHydrationBody(String minHours) {
    return 'Average sleep was under ${minHours}h and water is below your usual pace. An extra glass today eases the cost.';
  }

  @override
  String get insightLowSleepHydrationCta => 'Log water';

  @override
  String insightLoggingStreakTitle(int streak) {
    return '$streak-day streak';
  }

  @override
  String insightLoggingStreakBody(int streak) {
    return 'You\'ve logged something every day for $streak days. Small consistency, big compound. Keep going.';
  }

  @override
  String get insightLoggingStreakCta => 'Log today';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'Follow system';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageIndonesian => 'Bahasa Indonesia';

  @override
  String get settingsAbout => 'About';

  @override
  String settingsAboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsHideLifeCountdown => 'Hide life countdown';

  @override
  String get settingsHideLifeCountdownHint =>
      'Quiet the home countdown if it feels too heavy.';

  @override
  String get settingsDangerZone => 'Danger zone';

  @override
  String get settingsClearAllData => 'Clear all data';

  @override
  String get settingsClearAllDataConfirmTitle => 'Clear everything?';

  @override
  String get settingsClearAllDataConfirmBody =>
      'Removes your profile, events, lifestyle logs, and pinned widget state. This cannot be undone.';

  @override
  String get lifePinSheetTitle => 'Pin to home widget';

  @override
  String get lifePinToggleLabel => 'Show life countdown on the widget';

  @override
  String get lifePinToggleHelper =>
      'Show the life countdown at the top of your home-screen widget.';

  @override
  String get lifePinCustomMessageLabel => 'Custom message (optional)';

  @override
  String get lifePinCustomMessageHelper =>
      'Replaces the auto subtitle. Try something grounding — e.g. \"One breath at a time.\"';

  @override
  String get lifePinAction => 'Pin';

  @override
  String get lifePinUnpinAction => 'Unpin';

  @override
  String get lifePinTooltip => 'Pin to widget';

  @override
  String get lifePinUnpinTooltip => 'Currently pinned to widget';

  @override
  String lifeWidgetDaysRemainingShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String lifeWidgetSubtitleDefault(String date) {
    return 'Ends ~$date';
  }

  @override
  String widgetEventSubtitleDefault(String date, String recurrence) {
    return '$date · $recurrence';
  }

  @override
  String widgetEventDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
      zero: 'Today',
    );
    return '$_temp0';
  }

  @override
  String get widgetEmptyTitle => 'Nothing pinned yet';

  @override
  String get widgetEmptySubtitle =>
      'Pin your life countdown or events to see them here.';

  @override
  String widgetGreeting(String name) {
    return 'Hello, $name';
  }
}
