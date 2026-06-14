import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL
/// returned by `AppL.of(context)`.
///
/// Applications need to include `AppL.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL.localizationsDelegates,
///   supportedLocales: AppL.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL.supportedLocales
/// property.
abstract class AppL {
  AppL(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL of(BuildContext context) {
    return Localizations.of<AppL>(context, AppL)!;
  }

  static const LocalizationsDelegate<AppL> delegate = _AppLDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// Application name shown in the OS task switcher and splash.
  ///
  /// In en, this message translates to:
  /// **'Polaris'**
  String get appTitle;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get commonSaving;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @navLife.
  ///
  /// In en, this message translates to:
  /// **'Life'**
  String get navLife;

  /// No description provided for @navEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get navEvents;

  /// No description provided for @navLifestyle.
  ///
  /// In en, this message translates to:
  /// **'Lifestyle'**
  String get navLifestyle;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @onboardingWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Polaris'**
  String get onboardingWelcome;

  /// No description provided for @onboardingSetup.
  ///
  /// In en, this message translates to:
  /// **'Set up your countdown'**
  String get onboardingSetup;

  /// No description provided for @onboardingDescription.
  ///
  /// In en, this message translates to:
  /// **'These details stay on your device. They are used to estimate your remaining time using public life-expectancy tables.'**
  String get onboardingDescription;

  /// No description provided for @onboardingBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Birth date'**
  String get onboardingBirthDate;

  /// No description provided for @onboardingSex.
  ///
  /// In en, this message translates to:
  /// **'Biological sex'**
  String get onboardingSex;

  /// No description provided for @onboardingCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get onboardingCountry;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Start countdown'**
  String get onboardingStart;

  /// No description provided for @onboardingDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Estimation only — based on public life-expectancy tables (WHO, BPS). Not a medical prediction.'**
  String get onboardingDisclaimer;

  /// No description provided for @sexFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get sexFemale;

  /// No description provided for @sexMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get sexMale;

  /// No description provided for @sexUndisclosed.
  ///
  /// In en, this message translates to:
  /// **'Prefer not'**
  String get sexUndisclosed;

  /// Indonesian phrase meaning 'My Remaining Days' — used as the screen title in both locales to preserve brand identity.
  ///
  /// In en, this message translates to:
  /// **'Sisa Hariku'**
  String get lifeTitle;

  /// No description provided for @lifeDisplayDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get lifeDisplayDays;

  /// No description provided for @lifeDisplayWeeks.
  ///
  /// In en, this message translates to:
  /// **'Weeks'**
  String get lifeDisplayWeeks;

  /// No description provided for @lifeDisplayMonths.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get lifeDisplayMonths;

  /// No description provided for @lifeDisplayYears.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get lifeDisplayYears;

  /// No description provided for @lifeDisplayPercent.
  ///
  /// In en, this message translates to:
  /// **'%'**
  String get lifeDisplayPercent;

  /// No description provided for @lifeAlreadyLived.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day already lived} other{{formatted} days already lived}}'**
  String lifeAlreadyLived(int count, String formatted);

  /// No description provided for @lifeEstimatedEndDate.
  ///
  /// In en, this message translates to:
  /// **'Estimated end date'**
  String get lifeEstimatedEndDate;

  /// No description provided for @lifeExpectancyUsed.
  ///
  /// In en, this message translates to:
  /// **'Expectancy used'**
  String get lifeExpectancyUsed;

  /// No description provided for @lifeExpectancyYears.
  ///
  /// In en, this message translates to:
  /// **'{years} years'**
  String lifeExpectancyYears(String years);

  /// No description provided for @lifeFailedToCompute.
  ///
  /// In en, this message translates to:
  /// **'Failed to compute estimate: {error}'**
  String lifeFailedToCompute(String error);

  /// No description provided for @lifeUnitDays.
  ///
  /// In en, this message translates to:
  /// **'DAYS REMAINING'**
  String get lifeUnitDays;

  /// No description provided for @lifeUnitWeeks.
  ///
  /// In en, this message translates to:
  /// **'WEEKS REMAINING'**
  String get lifeUnitWeeks;

  /// No description provided for @lifeUnitMonths.
  ///
  /// In en, this message translates to:
  /// **'MONTHS REMAINING'**
  String get lifeUnitMonths;

  /// No description provided for @lifeUnitYears.
  ///
  /// In en, this message translates to:
  /// **'YEARS REMAINING'**
  String get lifeUnitYears;

  /// No description provided for @lifeUnitPercent.
  ///
  /// In en, this message translates to:
  /// **'LIVED'**
  String get lifeUnitPercent;

  /// No description provided for @eventsNewEvent.
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get eventsNewEvent;

  /// No description provided for @eventsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No events yet'**
  String get eventsEmptyTitle;

  /// No description provided for @eventsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap \"New event\" to add a birthday, deadline, or trip — then pin one to your home-screen widget.'**
  String get eventsEmptyBody;

  /// No description provided for @eventsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit event'**
  String get eventsEditTitle;

  /// No description provided for @eventsNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get eventsNewTitle;

  /// No description provided for @eventsFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get eventsFieldTitle;

  /// No description provided for @eventsFieldTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required.'**
  String get eventsFieldTitleRequired;

  /// No description provided for @eventsFieldWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get eventsFieldWhen;

  /// No description provided for @eventsFieldRepeats.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get eventsFieldRepeats;

  /// No description provided for @eventsFieldNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get eventsFieldNote;

  /// No description provided for @eventsFieldWidgetMessage.
  ///
  /// In en, this message translates to:
  /// **'Widget message (optional)'**
  String get eventsFieldWidgetMessage;

  /// No description provided for @eventsFieldWidgetMessageHelper.
  ///
  /// In en, this message translates to:
  /// **'Shown on the home-screen widget when this event is pinned. Replaces the auto date · recurrence line.'**
  String get eventsFieldWidgetMessageHelper;

  /// No description provided for @eventsAccentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get eventsAccentColor;

  /// No description provided for @eventsDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete event?'**
  String get eventsDeleteConfirmTitle;

  /// No description provided for @eventsDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" will be removed.'**
  String eventsDeleteConfirmBody(String title);

  /// No description provided for @eventsPinFailed.
  ///
  /// In en, this message translates to:
  /// **'Pin failed: {error}'**
  String eventsPinFailed(String error);

  /// No description provided for @eventsDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String eventsDeleteFailed(String error);

  /// No description provided for @eventsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {error}'**
  String eventsSaveFailed(String error);

  /// No description provided for @eventsCountdownToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get eventsCountdownToday;

  /// No description provided for @eventsCountdownTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get eventsCountdownTomorrow;

  /// No description provided for @eventsCountdownDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String eventsCountdownDays(int count);

  /// No description provided for @eventsCountdownPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get eventsCountdownPast;

  /// No description provided for @eventsActionPin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get eventsActionPin;

  /// No description provided for @eventsActionUnpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get eventsActionUnpin;

  /// No description provided for @eventsActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get eventsActionDelete;

  /// No description provided for @eventsActionsMenuLabel.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get eventsActionsMenuLabel;

  /// No description provided for @eventsPinnedSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Pinned to widget'**
  String get eventsPinnedSemanticLabel;

  /// No description provided for @eventsCountdownBadgeSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Today} =1{1 day remaining} other{{days} days remaining}}'**
  String eventsCountdownBadgeSemanticLabel(int days);

  /// No description provided for @lifeCountdownSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'{value} {unit}'**
  String lifeCountdownSemanticLabel(String value, String unit);

  /// No description provided for @recurrenceNone.
  ///
  /// In en, this message translates to:
  /// **'Does not repeat'**
  String get recurrenceNone;

  /// No description provided for @recurrenceYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get recurrenceYearly;

  /// No description provided for @recurrenceMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get recurrenceMonthly;

  /// No description provided for @recurrenceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get recurrenceWeekly;

  /// No description provided for @eventDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get eventDetailTitle;

  /// No description provided for @eventDetailEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get eventDetailEdit;

  /// No description provided for @eventDetailDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get eventDetailDelete;

  /// No description provided for @eventDetailNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Event not found'**
  String get eventDetailNotFoundTitle;

  /// No description provided for @eventDetailNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'This event was deleted or could not be loaded.'**
  String get eventDetailNotFoundBody;

  /// No description provided for @eventDetailBackToList.
  ///
  /// In en, this message translates to:
  /// **'Back to events'**
  String get eventDetailBackToList;

  /// No description provided for @eventDetailNextOccurrence.
  ///
  /// In en, this message translates to:
  /// **'Next occurrence'**
  String get eventDetailNextOccurrence;

  /// No description provided for @eventDetailSectionNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get eventDetailSectionNote;

  /// No description provided for @eventDetailSectionWidgetMessage.
  ///
  /// In en, this message translates to:
  /// **'Widget message'**
  String get eventDetailSectionWidgetMessage;

  /// No description provided for @eventDetailSectionNoNote.
  ///
  /// In en, this message translates to:
  /// **'No note added.'**
  String get eventDetailSectionNoNote;

  /// No description provided for @eventDetailSectionNoWidgetMessage.
  ///
  /// In en, this message translates to:
  /// **'Uses the automatic subtitle on the widget.'**
  String get eventDetailSectionNoWidgetMessage;

  /// No description provided for @eventDetailMetaCreated.
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String eventDetailMetaCreated(String date);

  /// No description provided for @eventDetailMetaUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String eventDetailMetaUpdated(String date);

  /// No description provided for @eventDetailUnitDays.
  ///
  /// In en, this message translates to:
  /// **'DAYS'**
  String get eventDetailUnitDays;

  /// No description provided for @eventDetailPast.
  ///
  /// In en, this message translates to:
  /// **'Already passed'**
  String get eventDetailPast;

  /// No description provided for @eventDetailLifetimeBadge.
  ///
  /// In en, this message translates to:
  /// **'One-off'**
  String get eventDetailLifetimeBadge;

  /// No description provided for @eventDetailRepeatsBadge.
  ///
  /// In en, this message translates to:
  /// **'Repeats {recurrence}'**
  String eventDetailRepeatsBadge(String recurrence);

  /// No description provided for @lifestyleQuickLog.
  ///
  /// In en, this message translates to:
  /// **'Quick log'**
  String get lifestyleQuickLog;

  /// No description provided for @lifestyleHistoryHeader.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get lifestyleHistoryHeader;

  /// No description provided for @lifestyleHistoryHelper.
  ///
  /// In en, this message translates to:
  /// **'Swipe a row to delete'**
  String get lifestyleHistoryHelper;

  /// No description provided for @lifestyleHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No entries in the last 7 days.'**
  String get lifestyleHistoryEmpty;

  /// No description provided for @lifestyleHistoryEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Quick log\" to record your first entry.'**
  String get lifestyleHistoryEmptyHint;

  /// No description provided for @lifestyleCategoryWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get lifestyleCategoryWater;

  /// No description provided for @lifestyleCategorySleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get lifestyleCategorySleep;

  /// No description provided for @lifestyleCategoryExercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get lifestyleCategoryExercise;

  /// No description provided for @lifestyleCategoryMood.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get lifestyleCategoryMood;

  /// No description provided for @lifestyleUnitGlasses.
  ///
  /// In en, this message translates to:
  /// **'glasses'**
  String get lifestyleUnitGlasses;

  /// No description provided for @lifestyleUnitHours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get lifestyleUnitHours;

  /// No description provided for @lifestyleUnitMinutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get lifestyleUnitMinutes;

  /// No description provided for @lifestyleUnitMood.
  ///
  /// In en, this message translates to:
  /// **'/5'**
  String get lifestyleUnitMood;

  /// No description provided for @lifestyleEntriesToday.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 entry today} other{{count} entries today}}'**
  String lifestyleEntriesToday(int count);

  /// No description provided for @lifestyleDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete entry?'**
  String get lifestyleDeleteConfirmTitle;

  /// No description provided for @lifestyleDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Remove this {category} log?'**
  String lifestyleDeleteConfirmBody(String category);

  /// No description provided for @lifestyleQuickLogCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get lifestyleQuickLogCategory;

  /// No description provided for @lifestyleQuickLogValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get lifestyleQuickLogValue;

  /// No description provided for @lifestyleQuickLogRange.
  ///
  /// In en, this message translates to:
  /// **'{min}–{max} {unit}'**
  String lifestyleQuickLogRange(String min, String max, String unit);

  /// No description provided for @lifestyleQuickLogValueRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a number.'**
  String get lifestyleQuickLogValueRequired;

  /// No description provided for @lifestyleQuickLogValueOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'Must be {range} {unit}.'**
  String lifestyleQuickLogValueOutOfRange(String range, String unit);

  /// No description provided for @lifestyleNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get lifestyleNoteOptional;

  /// No description provided for @lifestyleSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {error}'**
  String lifestyleSaveFailed(String error);

  /// No description provided for @lifestyleDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String lifestyleDeleteFailed(String error);

  /// No description provided for @lifestyleHistoryYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get lifestyleHistoryYesterday;

  /// No description provided for @lifestyleHistoryDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String lifestyleHistoryDaysAgo(int count);

  /// No description provided for @lifestyleLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load: {error}'**
  String lifestyleLoadFailed(String error);

  /// No description provided for @insightsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Insights for you'**
  String get insightsSectionTitle;

  /// No description provided for @insightDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get insightDismiss;

  /// No description provided for @insightDismissSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Hide this insight'**
  String get insightDismissSemanticLabel;

  /// No description provided for @insightDismissedFor.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Hidden for 1 day} other{Hidden for {days} days}}'**
  String insightDismissedFor(int days);

  /// No description provided for @insightUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get insightUndo;

  /// No description provided for @insightWaterTargetTitle.
  ///
  /// In en, this message translates to:
  /// **'Drink a bit more water'**
  String get insightWaterTargetTitle;

  /// No description provided for @insightWaterTargetBody.
  ///
  /// In en, this message translates to:
  /// **'Last {windowDays} days you averaged {avg} glasses/day. A common target is {target}+. Add a glass at the next break.'**
  String insightWaterTargetBody(int windowDays, String avg, String target);

  /// No description provided for @insightWaterTargetCta.
  ///
  /// In en, this message translates to:
  /// **'Log water'**
  String get insightWaterTargetCta;

  /// No description provided for @insightSleepRegularityTitle.
  ///
  /// In en, this message translates to:
  /// **'Short on sleep this week'**
  String get insightSleepRegularityTitle;

  /// No description provided for @insightSleepRegularityBody.
  ///
  /// In en, this message translates to:
  /// **'{shortCount} of the last {totalCount} logged nights were under {minHours}h. Try an earlier wind-down tonight.'**
  String insightSleepRegularityBody(
    int shortCount,
    int totalCount,
    String minHours,
  );

  /// No description provided for @insightSleepRegularityCta.
  ///
  /// In en, this message translates to:
  /// **'Log sleep'**
  String get insightSleepRegularityCta;

  /// No description provided for @insightExerciseStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'Move a bit this week'**
  String get insightExerciseStreakTitle;

  /// No description provided for @insightExerciseStreakBody.
  ///
  /// In en, this message translates to:
  /// **'No exercise logged in the last {windowDays} days. Even a 10-minute walk counts — log it and start a streak.'**
  String insightExerciseStreakBody(int windowDays);

  /// No description provided for @insightExerciseStreakCta.
  ///
  /// In en, this message translates to:
  /// **'Log exercise'**
  String get insightExerciseStreakCta;

  /// No description provided for @insightMoodTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Mood trending down'**
  String get insightMoodTrendTitle;

  /// No description provided for @insightMoodTrendBody.
  ///
  /// In en, this message translates to:
  /// **'The last {run} mood logs were each lower than the day before. Something on your mind — short walk, call a friend, or just log how today felt.'**
  String insightMoodTrendBody(int run);

  /// No description provided for @insightMoodTrendCta.
  ///
  /// In en, this message translates to:
  /// **'Log mood'**
  String get insightMoodTrendCta;

  /// No description provided for @insightLifePhaseTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve lived {pct}% of your estimated life'**
  String insightLifePhaseTitle(int pct);

  /// No description provided for @insightLifePhaseBody.
  ///
  /// In en, this message translates to:
  /// **'About {remainingYears} years (~{remainingDays} days) left on the public-table estimate. Pin one event that matters most to you.'**
  String insightLifePhaseBody(String remainingYears, int remainingDays);

  /// No description provided for @insightLifePhaseCta.
  ///
  /// In en, this message translates to:
  /// **'Pin an event'**
  String get insightLifePhaseCta;

  /// No description provided for @insightNoDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Log your first entry'**
  String get insightNoDataTitle;

  /// No description provided for @insightNoDataBody.
  ///
  /// In en, this message translates to:
  /// **'Polaris gets sharper once it learns your rhythm. Tap \"Quick log\" on the Lifestyle tab to record water, sleep, exercise, or mood.'**
  String get insightNoDataBody;

  /// No description provided for @insightNoDataCta.
  ///
  /// In en, this message translates to:
  /// **'Open Lifestyle'**
  String get insightNoDataCta;

  /// No description provided for @insightPositiveExerciseStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'Great week on the move'**
  String get insightPositiveExerciseStreakTitle;

  /// No description provided for @insightPositiveExerciseStreakBody.
  ///
  /// In en, this message translates to:
  /// **'You logged exercise on {activeDays} of the last {windowDays} days — {totalMinutes} minutes total. Keep the rhythm.'**
  String insightPositiveExerciseStreakBody(
    int activeDays,
    int windowDays,
    String totalMinutes,
  );

  /// No description provided for @insightPositiveExerciseStreakCta.
  ///
  /// In en, this message translates to:
  /// **'Log today'**
  String get insightPositiveExerciseStreakCta;

  /// No description provided for @insightLowSleepHydrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Hydrate to soften a tough week'**
  String get insightLowSleepHydrationTitle;

  /// No description provided for @insightLowSleepHydrationBody.
  ///
  /// In en, this message translates to:
  /// **'Average sleep was under {minHours}h and water is below your usual pace. An extra glass today eases the cost.'**
  String insightLowSleepHydrationBody(String minHours);

  /// No description provided for @insightLowSleepHydrationCta.
  ///
  /// In en, this message translates to:
  /// **'Log water'**
  String get insightLowSleepHydrationCta;

  /// No description provided for @insightLoggingStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'{streak}-day streak'**
  String insightLoggingStreakTitle(int streak);

  /// No description provided for @insightLoggingStreakBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve logged something every day for {streak} days. Small consistency, big compound. Keep going.'**
  String insightLoggingStreakBody(int streak);

  /// No description provided for @insightLoggingStreakCta.
  ///
  /// In en, this message translates to:
  /// **'Log today'**
  String get insightLoggingStreakCta;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageIndonesian.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Indonesia'**
  String get settingsLanguageIndonesian;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsAboutVersion(String version);

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfile;

  /// No description provided for @settingsHideLifeCountdown.
  ///
  /// In en, this message translates to:
  /// **'Hide life countdown'**
  String get settingsHideLifeCountdown;

  /// No description provided for @settingsHideLifeCountdownHint.
  ///
  /// In en, this message translates to:
  /// **'Quiet the home countdown if it feels too heavy.'**
  String get settingsHideLifeCountdownHint;

  /// No description provided for @settingsDangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get settingsDangerZone;

  /// No description provided for @settingsClearAllData.
  ///
  /// In en, this message translates to:
  /// **'Clear all data'**
  String get settingsClearAllData;

  /// No description provided for @settingsClearAllDataConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear everything?'**
  String get settingsClearAllDataConfirmTitle;

  /// No description provided for @settingsClearAllDataConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Removes your profile, events, lifestyle logs, and pinned widget state. This cannot be undone.'**
  String get settingsClearAllDataConfirmBody;

  /// No description provided for @lifePinSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Pin to home widget'**
  String get lifePinSheetTitle;

  /// No description provided for @lifePinToggleLabel.
  ///
  /// In en, this message translates to:
  /// **'Show life countdown on the widget'**
  String get lifePinToggleLabel;

  /// No description provided for @lifePinToggleHelper.
  ///
  /// In en, this message translates to:
  /// **'Show the life countdown at the top of your home-screen widget.'**
  String get lifePinToggleHelper;

  /// No description provided for @lifePinCustomMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom message (optional)'**
  String get lifePinCustomMessageLabel;

  /// No description provided for @lifePinCustomMessageHelper.
  ///
  /// In en, this message translates to:
  /// **'Replaces the auto subtitle. Try something grounding — e.g. \"One breath at a time.\"'**
  String get lifePinCustomMessageHelper;

  /// No description provided for @lifePinAction.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get lifePinAction;

  /// No description provided for @lifePinUnpinAction.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get lifePinUnpinAction;

  /// No description provided for @lifePinTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pin to widget'**
  String get lifePinTooltip;

  /// No description provided for @lifePinUnpinTooltip.
  ///
  /// In en, this message translates to:
  /// **'Currently pinned to widget'**
  String get lifePinUnpinTooltip;

  /// No description provided for @lifeWidgetDaysRemainingShort.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day left} other{{count} days left}}'**
  String lifeWidgetDaysRemainingShort(int count);

  /// No description provided for @lifeWidgetSubtitleDefault.
  ///
  /// In en, this message translates to:
  /// **'Ends ~{date}'**
  String lifeWidgetSubtitleDefault(String date);

  /// No description provided for @widgetEventSubtitleDefault.
  ///
  /// In en, this message translates to:
  /// **'{date} · {recurrence}'**
  String widgetEventSubtitleDefault(String date, String recurrence);

  /// No description provided for @widgetEventDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Today} =1{1 day} other{{count} days}}'**
  String widgetEventDays(int count);

  /// No description provided for @widgetEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing pinned yet'**
  String get widgetEmptyTitle;

  /// No description provided for @widgetEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pin your life countdown or events to see them here.'**
  String get widgetEmptySubtitle;

  /// Header greeting on the home-screen widget. {name} is the logged-in user (placeholder string until auth lands).
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String widgetGreeting(String name);
}

class _AppLDelegate extends LocalizationsDelegate<AppL> {
  const _AppLDelegate();

  @override
  Future<AppL> load(Locale locale) {
    return SynchronousFuture<AppL>(lookupAppL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLDelegate old) => false;
}

AppL lookupAppL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLEn();
    case 'id':
      return AppLId();
  }

  throw FlutterError(
    'AppL.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
