# Handoff Document — Polaris

> **Purpose:** Hand this file to a new AI chat session (or a new collaborator)
> to continue development without losing context.
> **Last updated:** 2026-06-14 by Cursor AI session — **Multi-Pin Widget (Widget Pin v3) shipped**: home-screen widget is now a native `RemoteViews` ListView that renders every pinned subject (life + N events) in one scrollable surface. Mutual exclusivity dropped — life and event pins are independent.

---

## 1. What This Project Is

Read [`BRD Polaris.md`](./BRD%20Polaris.md) first. TL;DR:

- Mobile app called **Polaris**.
- Concept: **"Sisa Hariku di Dunia"** — life countdown + event countdown +
  lifestyle tracking + rule-based recommendations.
- Studio: **Phandarian** | Owner: **Irwan Phan**.
- Bundle ID: `com.phandarian.polaris`.
- **Android-first**, iOS-second.
- Tech: **Flutter 3.44.1 stable** + Dart 3.12.1, Riverpod, Drift, go_router,
  native widgets (Glance for Android, WidgetKit for iOS Phase 2).
- Architecture: feature-based modular + SOLID — see `BRD §9`.

---

## 2. Current Status (As of 2026-06-14, **M0–M2 + CI + M4 + M5 + M6 + Widget Pin v2 + Multi-Pin Widget (v3) shipped**)

### Completed
- Flutter 3.44.1 stable installed at `~/TurbidDev/flutter/`.
  - Verified: `Flutter 3.44.1 • channel stable` / `Dart 3.12.1` /
    `DevTools 2.57.0` / Framework revision `924134a44c`.
- PATH configured in `~/.zshrc` so `flutter` resolves to
  `/Users/irwanphan/TurbidDev/flutter/bin/flutter`.
- Flutter project scaffolded at `~/TurbidDev/project-polaris/` via
  `flutter create` (`name: polaris`, bundle ID
  `com.phandarian.polaris`).
- Git repository initialized and pushed to GitHub
  (`https://github.com/irwanphan/polaris.git`, branch `main`).
- BRD `docs/BRD Polaris.md` drafted to **v0.2.0** (sections 1–16,
  including Architecture, Data Model, Roadmap, Risks, Acceptance
  Criteria, Glossary).
- **M0 — Foundation** shipped:
  - **Runtime deps** added: `flutter_riverpod ^3.3.2`,
    `riverpod_annotation ^4.0.3`, `go_router ^17.3.0`, `drift ^2.34.0`,
    `drift_flutter ^0.3.0`, `sqlite3_flutter_libs ^0.6.0+eol`,
    `path_provider ^2.1.5`, `shared_preferences ^2.5.5`, `intl ^0.20.2`,
    `logger ^2.7.0`, `freezed_annotation ^3.1.0`,
    `json_annotation ^4.12.0`, `uuid ^4.5.3`.
  - **Dev deps** added: `build_runner ^2.15.0`, `freezed ^3.2.6-dev.1`,
    `json_serializable ^6.14.0`, `drift_dev ^2.34.0`,
    `riverpod_generator ^4.0.4`, `mocktail ^1.0.5`,
    `riverpod_lint ^3.1.4`.
  - **Native plugins deferred**: `home_widget`, `workmanager`,
    `flutter_local_notifications` will land in M2/M3 when their
    milestones require platform setup.
  - **Lints tightened** in `analysis_options.yaml`: strict-casts,
    strict-inference, strict-raw-types, `avoid_relative_lib_imports`,
    `always_use_package_imports`, `prefer_single_quotes`, `avoid_print`,
    `unawaited_futures`, and a stricter `prefer_const_*` set.
  - **`.gitignore`** updated to ignore generated files (`*.g.dart`,
    `*.freezed.dart`, …) per Decision D1.
  - **Folder structure** per `BRD §9.1` created under `lib/`:
    - `app/` — `bootstrap.dart`, `app.dart`, `router.dart`,
      `theme/{color_tokens, text_styles, app_theme}.dart`.
    - `core/` — `result/result.dart`, `errors/failure.dart`,
      `logging/app_logger.dart`, `extensions/date_x.dart`.
    - `shared/widgets/` — `polaris_scaffold.dart`, `section_card.dart`,
      `coming_soon_view.dart` (atomic, reusable, SOLID).
    - `features/launcher/`, `features/life_countdown/`,
      `features/event_countdown/`, `features/lifestyle/`,
      `features/settings/` — each with `presentation/pages/` and a
      thin placeholder page wired to a route.
  - **Theme**: Tailwind-flavored token system — Midnight/Indigo +
    Starlight/Amber + Slate neutrals, Material 3 ColorScheme for both
    light & dark, semantic text styles (`displayXl`…`caption`),
    spacing scale on a 4-px base, radius scale, elevation scale.
  - **Routing**: `go_router` with named routes `/`, `/life`, `/events`,
    `/lifestyle`, `/settings`. Router exposed via
    `appRouterProvider`.
  - **Composition root**: `bootstrap()` initializes binding, installs
    `FlutterError.onError` / `PlatformDispatcher.instance.onError`
    handlers wired to the logger, wraps `runApp` in
    `runZonedGuarded`, mounts `ProviderScope` with logger override.
  - **`flutter analyze`**: zero issues with the new lint profile.

- **M1 — Life Countdown vertical slice** shipped:
  - **Domain** (pure Dart, framework-free):
    - Value objects: `Sex`, `CountryCode` (validated, structurally equal),
      `DateOfBirth` (rejects future + > 130 years).
    - Entities: `LifeProfile` (with `copyWith` + structural equality),
      `LifeEstimate` (derived fields: weeks / months / years /
      percentLived / isCompleted).
    - Abstract repositories: `LifeProfileRepository`,
      `LifeExpectancyRepository` + `CountryOption` view-model.
    - Use case: `ComputeLifeEstimate` (pure builder + `call` variant
      that fetches expectancy from the repository).
  - **Data**:
    - Seed asset `assets/seed/life_expectancy.json` — 12 countries
      (ID, SG, MY, JP, US, GB, DE, AU, IN, PH, TH, VN) + global
      fallback, sourced from WHO GHO 2024 + BPS 2024.
    - `LifeExpectancyAssetDataSource` (bundle loader + parser).
    - `LifeExpectancyRepositoryImpl` (caches the parsed table; maps
      `Sex.undisclosed` to the average of male/female).
    - `LifeProfileRepositoryImpl` backed by `SharedPreferences`
      (single JSON blob, key `polaris.life_profile.v1`). Drift
      migration deferred to M2.
    - `pubspec.yaml` registers `assets/seed/` as a Flutter asset.
  - **Application** (Riverpod 3):
    - `sharedPreferencesProvider` (overridden in `bootstrap.dart`).
    - `lifeExpectancyAssetDataSourceProvider`,
      `lifeExpectancyRepositoryProvider`,
      `lifeProfileRepositoryProvider`,
      `computeLifeEstimateProvider`.
    - `LifeProfileController` (`AsyncNotifier<LifeProfile?>`) with
      `completeOnboarding`, `setHideLifeCountdown`, `reset`.
    - `LifeCountdownController` (`AsyncNotifier<LifeEstimate?>`) that
      re-runs the estimator whenever the profile changes.
    - `DisplayMode` enum: days / weeks / months / years / percent.
  - **Presentation**:
    - Reusable widgets: `CountdownDisplay`, `DisplayModeSegmented`,
      `DisclaimerNote` (BRD §5.1 + risk R2 mitigation).
    - `OnboardingPage`: date picker, sex segmented control
      (female / male / prefer-not), country dropdown sourced from the
      repository, validation + snack-bar error path.
    - `LifeCountdownPage`: real screen with hero number, mode toggle,
      "Estimated end date" + "Expectancy used" cards, disclaimer; a
      1-minute `Timer.periodic` keeps the day count fresh while the
      page is visible. Redirects to `/onboarding` when no profile
      exists.
  - **Router**: added `/onboarding`; `/life` redirects to
    `/onboarding` when the profile is missing (handled at both the
    GoRouter `redirect` level and inside the page for the async-load
    edge case).
  - **Bootstrap**: now awaits `SharedPreferences.getInstance()` and
    overrides `sharedPreferencesProvider`.
  - **Tests**: 34/34 passing.
    - Domain: `country_code_test`, `date_of_birth_test`,
      `compute_life_estimate_test` (5 cases incl. expired estimate,
      newborn, repo failure forwarding, derived helpers).
    - Data: `life_profile_repository_impl_test` (read null, save/read
      round-trip, clear, overwrite — driven by
      `SharedPreferences.setMockInitialValues`).
    - Widget: launcher render, `/life` → onboarding redirect (no
      profile), placeholder routes still render. Uses a fake
      `LifeExpectancyRepository` to avoid bundling assets in tests.
  - **`flutter analyze`**: still zero issues.

- **M2 — Event Countdown (CRUD slice)** shipped:
  - **Drift foundation** in `lib/data/database/`:
    - `app_database.dart` — `@DriftDatabase(tables: [EventsTable],
      daos: [EventsDao])`, schema v1, opened via
      `drift_flutter`'s `driftDatabase(name: 'polaris')` helper. A
      `forTesting(executor)` constructor allows in-memory tests.
    - `tables/events_table.dart` — `EventsTable` with the columns
      from `BRD §10` (`id`, `title`, `targetAtEpochMs`, `colorHex`,
      `iconKey`, `note?`, `recurrence`, `isPinnedToWidget`,
      `createdAtEpochMs`, `updatedAtEpochMs`). Times stored as UTC
      milliseconds; enums stored as their `storageKey`.
    - `daos/events_dao.dart` — `EventsDao` with a reactive
      `watchAll()` (sorted by `targetAtEpochMs` ascending),
      `getById`, `upsert` (insert-or-replace), `deleteById`, and
      an atomic `pinExclusive(id?)` that clears any existing pin
      and (optionally) sets exactly one.
  - **Build runner**: `dart run build_runner build` regenerates
    `*.g.dart` (still git-ignored per D1). Generated outputs:
    `app_database.g.dart`, `daos/events_dao.g.dart`. Must run after
    a fresh checkout before `flutter test`.
  - **Domain** (`features/event_countdown/domain/`):
    - `value_objects/recurrence.dart` — `Recurrence` enum (none /
      yearly / monthly / weekly) with stable `storageKey` and UI
      `label`, plus `fromStorageKey` decoder.
    - `entities/event.dart` — immutable `Event` with `copyWith`
      (note: passing `null` keeps the existing value; construct a
      new `Event` to clear), `Event.create` factory (uuid v4 +
      synced `createdAt`/`updatedAt`), and `nextOccurrence(now)` /
      `daysUntil(now)` helpers. Recurrence math handles Feb 29 →
      Feb 28 and "day 31 → last day of month" edge cases.
    - `repositories/event_repository.dart` — abstract interface:
      `watchAll`, `getById`, `upsert`, `delete`, `pinExclusive`.
  - **Data** (`features/event_countdown/data/`):
    - `repositories/event_repository_impl.dart` —
      `EventRepositoryImpl` wraps the DAO, maps `EventRow` ↔
      `Event` (UTC ms ↔ local `DateTime`, `Recurrence.storageKey`
      ↔ enum), and wraps every call in `Result.ok / Result.err`
      with a `StorageFailure` carrying cause + stack trace.
  - **Application** (`features/event_countdown/application/`):
    - `providers.dart`:
      - `appDatabaseProvider` — overridden in `bootstrap.dart` with
        the real `AppDatabase()`; thrown unimplemented otherwise so
        tests must supply their own.
      - `eventRepositoryProvider` — provides the Drift-backed
        repo; widget tests override this with an in-memory fake.
      - `eventsStreamProvider` — `StreamProvider<List<Event>>`
        backed by `repository.watchAll()`.
    - `events_controller.dart` — `EventsController` (Riverpod
      `Provider`) owns the write commands:
      `createEvent`, `updateEvent`, `deleteEvent`, `togglePin`. All
      string inputs are trimmed; empty notes normalize to `null`.
      Returns `Result<…, Object>` so the UI can surface failures.
  - **Bootstrap**: now opens `AppDatabase()` and overrides
    `appDatabaseProvider` alongside the logger and shared-prefs
    overrides.
  - **Presentation** (`features/event_countdown/presentation/`):
    - `widgets/event_card.dart` — accent-colored countdown badge
      (`N days`), pinned indicator, sub-line with date + recurrence
      label, popup menu for **Pin / Unpin** and **Delete**. Built
      on the existing `SectionCard` (composition over inheritance).
    - `widgets/event_editor_sheet.dart` — modal bottom sheet that
      handles both **Create** and **Edit** flows: title (required,
      max 200), datetime picker (date → time), recurrence
      dropdown, optional note (max 500), and a 6-swatch accent
      color picker. Calls `EventsController.createEvent` or
      `updateEvent`; surfaces `Result` errors via SnackBar.
    - `pages/event_countdown_page.dart` — real implementation
      (replaces the M0 placeholder): `eventsStreamProvider`
      → loading / error / data, list of `EventCard`s, FAB
      "New event", empty state with iconography + copy, delete
      confirmation dialog.
  - **Router**: no change — the existing `/events` route now lands
    on the real page since we overwrote the placeholder.
  - **Tests**: 57/57 passing (up from 34).
    - Domain: `event_test` — 12 cases covering `daysUntil` (future
      / today / past), yearly (roll-forward, leap-year fallback),
      monthly (roll-forward, day-31 fallback), weekly (same-week
      vs next-week), `copyWith` preserves immutables, `Event.create`
      factory stamps timestamps and generates a UUID.
    - Data: `event_repository_impl_test` — 10 cases using
      `AppDatabase.forTesting(NativeDatabase.memory())`: empty
      stream, upsert + watch, replace-by-id, getById hit/miss,
      delete, `pinExclusive` exclusive set, `pinExclusive(null)`
      clears all, ordering by `targetAt`, note round-trip
      including `null`.
    - Widget: existing tests adjusted + new "Events page shows
      empty state when nothing is stored". Widget tests inject an
      in-memory `EventRepository` fake via
      `eventRepositoryProvider.overrideWithValue(...)` to bypass
      Drift (Drift's stream queries leak a 0-duration timer when
      the `ProviderScope` disposes, which trips
      `flutter_test`'s "no pending timers" invariant — the real
      DAO is fully exercised in the data unit test instead).
  - **`flutter analyze`**: still zero issues.

- **M2 — HomeShell navigation + LifeProfile → Drift** shipped:
  - **`HomeShellPage`** (`lib/features/home/presentation/pages/`)
    wraps a `StatefulNavigationShell` and renders a Material 3
    `NavigationBar` with four tabs: **Life / Events / Lifestyle /
    Settings**. Tapping the active tab resets the branch to its
    root, mimicking the Twitter / Instagram gesture.
  - **Router** rewritten in `lib/app/router.dart` to use
    `StatefulShellRoute.indexedStack` with four
    `StatefulShellBranch`es (one per tab). Each tab keeps its
    own back-stack, scroll position, and Riverpod scopes when the
    user switches away and back. Deep links like `/events` switch
    the active tab. `/onboarding` stays outside the shell so the
    first-run flow is full-screen.
  - **`LauncherPage`** removed (`lib/features/launcher/` deleted).
    It served only as M0 wiring scaffolding; the HomeShell
    replaces it for production use.
  - **Initial location** changed from `/` (launcher) to `/life`.
    The existing redirect rule (no profile → `/onboarding`) still
    applies and now triggers on first launch.
  - **`LifeProfilesTable`** added to Drift schema (singleton row,
    `id = 1` enforced):
    - Table: `lib/data/database/tables/life_profiles_table.dart`.
    - DAO: `lib/data/database/daos/life_profiles_dao.dart` with
      `read`, `upsert` (id pinned to 1), and `clear`.
    - `AppDatabase.schemaVersion` bumped from **1 → 2** with an
      `onUpgrade` handler that creates the new table on devices
      that already had the v1 events table. Fresh installs use
      `onCreate.createAll()` as before.
  - **`appDatabaseProvider`** moved from
    `features/event_countdown/application/providers.dart` to
    `lib/data/database/providers.dart` so it can be referenced
    by multiple features without violating the "no
    cross-feature imports" rule (`BRD §9.2`).
  - **`LifeProfileDriftRepository`** (new) implements the same
    `LifeProfileRepository` interface as the M1 SharedPreferences
    impl. Mapping rules match `EventRepositoryImpl`: timestamps as
    UTC milliseconds, enums via `storageKey`. All failures wrapped
    in `Result.err(StorageFailure)`.
  - **`lifeProfileRepositoryProvider`** default switched to the
    Drift implementation. The SP-backed
    `LifeProfileRepositoryImpl` is retained as the legacy reader
    for the one-shot migration only — no production read path
    touches it anymore.
  - **One-shot SP → Drift migration**
    (`features/life_countdown/data/migrations/life_profile_sp_to_drift.dart`):
    - `LifeProfileSpToDriftMigration.run()` is idempotent: returns
      `false` (no-op) if the Drift store already has a profile or
      if the SP store is empty; otherwise it copies the profile
      into Drift and clears the SP key. Save failures keep the
      legacy data intact for next-boot retry.
    - Bootstrap awaits this migration before mounting
      `ProviderScope`, so the first launch after upgrading is
      indistinguishable from any subsequent launch.
  - **Tests**: 68/68 passing (up from 57).
    - `life_profile_drift_repository_test` — 5 cases via
      `AppDatabase.forTesting(NativeDatabase.memory())`:
      empty-read, save+read round-trip, singleton-row overwrite,
      clear, `hideLifeCountdown` both values round-trip.
    - `life_profile_sp_to_drift_test` — 5 cases via in-memory
      fakes: no-op empty source, no-op when target populated,
      successful migration clears source, save failure
      preserves source, idempotent on second run.
    - Widget tests rewritten for the new shell:
      "Boots into onboarding when no profile exists",
      "HomeShell renders bottom nav with 4 tabs", and one
      test per tab (Events / Lifestyle / Settings). The
      `lifeProfileRepositoryProvider` is now overridden with
      `_InMemoryLifeProfileRepository` (seeded from a sample
      `LifeProfile` directly), so widget tests no longer
      touch SharedPreferences or Drift for the life profile.
  - **`flutter analyze`**: still zero issues.

- **M2 — Local notification scheduler** shipped:
  - **New runtime deps** in `pubspec.yaml`:
    `flutter_local_notifications ^19.4.2` (the plugin),
    `timezone ^0.10.1` (TZ math), and `flutter_timezone ^4.1.2`
    (host timezone lookup). `permission_handler` is *not* needed
    because the plugin handles `POST_NOTIFICATIONS` and
    `SCHEDULE_EXACT_ALARM` flow internally.
  - **Android manifest** (`android/app/src/main/AndroidManifest.xml`)
    declares `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`,
    `USE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`, `VIBRATE`, and
    registers the plugin's `ScheduledNotificationReceiver`,
    `ScheduledNotificationBootReceiver`, and
    `ActionBroadcastReceiver` so reminders survive reboots.
  - **NDK pinned** to `30.0.14904198` (the version already
    installed locally) so the build doesn't try to download
    Flutter's default NDK (~3 GB). Set in **two** places:
    - `android/app/build.gradle.kts` for `:app`.
    - `android/build.gradle.kts` for every `:plugin` subproject
      via a `subprojects { plugins.withId("com.android.library")
      { extensions.configure<LibraryExtension>("android") {
      ndkVersion = "30.0.14904198" } } }` block — without this
      transitive plugins like `jni` / `jni_flutter` (pulled in
      by `flutter_timezone`) re-ask for Flutter's default NDK
      and break the build. Bump in lockstep when Flutter raises
      the floor.
  - **Core library desugaring** enabled in
    `android/app/build.gradle.kts` (`isCoreLibraryDesugaringEnabled
    = true` + `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`).
    Required by `flutter_local_notifications` ≥ 18 so
    `java.time` works on `minSdk < 26`.
  - **Drift schema v3** — `NotificationSchedulesTable` added with
    `id` (auto-increment, doubles as the platform notification
    id), `eventId`, `kind` (`t-7d` / `t-1d` / `t-1h`),
    `scheduledForEpochMs`, `createdAtEpochMs`. `onUpgrade`
    creates the new table for users coming from v1/v2.
    Generated `app_database.g.dart` regenerated via
    `dart run build_runner build`.
  - **`NotificationsDao`** (`lib/data/database/daos/`) exposes
    `insertReturningId`, `listForEvent`, `listAll`,
    `deleteForEvent`, `deleteById`.
  - **`NotificationDispatcher`** abstract interface
    (`lib/core/notifications/notification_dispatcher.dart`) is
    the platform-agnostic seam: `initialize`, `ensurePermission`,
    `scheduleAt`, `cancel`, `cancelAll`. Lives in `core/`
    because it has zero domain knowledge.
  - **`FlutterLocalNotificationsDispatcher`** (same folder)
    wraps the plugin: initializes the TZ database via
    `flutter_timezone`, creates a single Android notification
    channel ("Polaris reminders", high importance), routes
    iOS/Darwin alert permission requests, and schedules with
    `AndroidScheduleMode.exactAllowWhileIdle`.
  - **`ReminderOffset`** value object
    (`features/event_countdown/domain/value_objects/`) — enum
    with `oneWeek`, `oneDay`, `oneHour` carrying `storageKey`,
    `before` (`Duration`), and `humanLabel`. Single source of
    truth for the offset matrix.
  - **`NotificationScheduler`** service
    (`features/event_countdown/application/notification_scheduler.dart`)
    composes `NotificationDispatcher` + `NotificationsDao`:
    - `rescheduleFor(event)` — cancels every prior schedule
      for `event.id`, requests permission lazily, computes
      `event.nextOccurrence(now)`, then iterates
      `ReminderOffset.values`. Each offset that still lies in
      the future is inserted into `NotificationSchedulesTable`
      (auto-id) and that id is reused as the platform
      notification id. Plugin failures roll back the DB row
      so the bookkeeping table stays in sync with the OS.
    - `cancelFor(eventId)` — cancels every platform
      notification listed in the table and clears the rows.
    - All failures are logged via `AppLogger.warn`/`info` and
      swallowed; a notification glitch never blocks an event
      save.
  - **Provider tree** in
    `features/event_countdown/application/providers.dart`:
    - `notificationDispatcherProvider` — throws unimplemented
      by default; overridden in `bootstrap.dart` with the
      Flutter Local Notifications impl.
    - `notificationSchedulerProvider` — composes the dispatcher
      + the `NotificationsDao` from `appDatabaseProvider`.
  - **`EventsController`** now takes a `NotificationScheduler`
    and calls `rescheduleFor(event)` on every successful
    `createEvent` / `updateEvent`, and `cancelFor(id)` on
    every successful `deleteEvent`. `togglePin` does **not**
    touch the scheduler — pinning is a UI affordance, not a
    reminder change.
  - **Bootstrap**: now initializes the dispatcher (TZ database
    + plugin) once at startup, before mounting `ProviderScope`,
    and overrides `notificationDispatcherProvider`. The
    one-shot LifeProfile SP→Drift migration still runs first.
  - **Tests**: 79/79 passing (up from 68).
    - `notification_scheduler_test` — 11 cases via a hand-rolled
      `_FakeDispatcher` + in-memory Drift:
      schedules-all-three, skips past offsets, no-op when fully
      past, DAO rows match dispatched ids, rescheduling is
      idempotent (cancels prior + leaves no stale rows),
      permission-denied is silent, yearly recurrence uses the
      *next* occurrence (not the historical `targetAt`),
      dispatcher exceptions roll back the DB row, plus
      `cancelFor` happy path and unknown-id no-op. Also pins
      `ReminderOffset` enum metadata.
    - Widget tests gained a `_NoopNotificationDispatcher`
      override so the events-page tests stay hermetic even
      though they don't exercise the editor sheet today.
  - **`flutter analyze`**: still zero issues.

- **M2 — Android home-screen widget** shipped:
  - **`home_widget ^0.9.3`** added to runtime deps. Uses
    `SharedPreferences`-based wire contract (key/value strings)
    between Dart and the native `AppWidgetProvider` — keeps the
    Kotlin side a dumb RemoteViews renderer.
  - **Native AppWidget** (Android):
    - `android/app/src/main/res/xml/polaris_widget_info.xml` —
      2×2 target cell, `updatePeriodMillis=0` (we trigger
      updates explicitly from Dart, not via the OS scheduler).
    - `android/app/src/main/res/layout/polaris_widget_layout.xml`
      — RemoteViews: indigo-700 card, 20dp radius, title row
      with amber "POLARIS" pill badge, hero days number (34sp),
      subtitle row.
    - `android/app/src/main/res/drawable/polaris_widget_background.xml`
      + `polaris_widget_brand_pill.xml` — shape drawables for
      the card + brand pill.
    - `android/app/src/main/res/values/strings.xml` — widget
      description shown in the launcher's widget picker.
    - `PolarisWidgetProvider.kt` (`com.phandarian.polaris`)
      extends the plugin's `HomeWidgetProvider`. Reads three
      string keys (`polaris_pinned_title`, `polaris_pinned_days`,
      `polaris_pinned_subtitle`) from `SharedPreferences` and
      pours them into the RemoteViews. Empty-state copy
      ("Pin an event in Polaris") shown when title is blank.
      Tapping anywhere launches `MainActivity`.
    - `AndroidManifest.xml` registers
      `.PolarisWidgetProvider` with the `APPWIDGET_UPDATE`
      intent filter + `appwidget-provider` meta-data.
  - **Dart abstraction** (`lib/core/widgets/`):
    - `home_widget_updater.dart` — `HomeWidgetUpdater` interface
      with a single `refresh()` method. Lives in `core/` so
      multiple features can request a re-render without taking
      a dependency on the plugin.
    - `polaris_home_widget_updater.dart` —
      `PolarisHomeWidgetUpdater` reads the pinned event via
      the new `EventRepository.getPinned()`, formats the
      user-visible strings in Dart (`"12 days"`, `"Today"`,
      `"1 day"`, `"EEE, MMM d · Yearly"`), and pushes them via
      `HomeWidget.saveWidgetData` + `HomeWidget.updateWidget`.
      Plugin calls are injected as function thunks so unit
      tests don't hit MethodChannel.
    - `providers.dart` — `homeWidgetUpdaterProvider` (throws
      until overridden in `bootstrap()`).
  - **Repository surface** — added
    `Future<Result<Event?, Failure>> getPinned()` to
    `EventRepository`, backed by a new `EventsDao.getPinned()`
    that does `SELECT … WHERE is_pinned_to_widget LIMIT 1`.
    Generated Drift code regenerated (no schema bump — the
    column already existed since M2 v1).
  - **EventsController integration**: every successful
    `createEvent` / `updateEvent` / `deleteEvent` /
    `togglePin` now also calls
    `_widgetUpdater.refresh()`. Failures inside the updater
    are logged and swallowed (the user's mutation always wins).
  - **Bootstrap**: constructs a `PolarisHomeWidgetUpdater`
    wired to the same `EventRepository` the rest of the app
    uses, calls an initial `refresh()` so the widget reflects
    the latest pin even if the user hasn't touched the app
    since reboot, and overrides
    `homeWidgetUpdaterProvider` in the ProviderScope.
  - **Tests**: 89/89 passing (up from 79).
    - `polaris_home_widget_updater_test` — 8 cases via a
      hand-rolled `_StubEventRepository` + a `_SavedData`
      sink: writes title/days/subtitle, empty state when no
      pin, "Today" / "1 day" / "N days" pluralisation,
      recurrence suffix only for non-`none` recurrences,
      next-occurrence math for yearly, repo failure treated
      as empty state, dispatcher exception is swallowed.
    - `event_repository_impl_test` gained 2 cases for
      `getPinned()` (null when nothing pinned, returns the
      pinned event after `pinExclusive`).
    - Widget tests gained a `_NoopHomeWidgetUpdater` override
      so the events-page UI tests stay hermetic.
  - **`flutter analyze`**: still zero issues.

- **CI — GitHub Actions** shipped:
  - `.github/workflows/ci.yml` runs on every push to `main`
    and every pull request (incl. from forks). In-flight runs
    are auto-cancelled when a newer commit arrives on the
    same ref (`concurrency` block) to save Actions minutes.
  - Single `analyze-and-test` job on `ubuntu-latest`,
    15-minute timeout.
  - Pipeline: `subosito/flutter-action@v2` pinned to
    **Flutter 3.44.1 / channel stable** with pub-cache, then
    `flutter pub get` → `dart run build_runner build
    --delete-conflicting-outputs` (must come before analyze
    because we git-ignore generated files per D1) → `dart
    format --output=none --set-exit-if-changed .` (formatting
    gate) → `flutter analyze` → `flutter test --coverage`.
  - Coverage `lcov.info` uploaded as an Actions artifact
    (`coverage-lcov`, 14-day retention) — wire Codecov /
    Coveralls later if useful.
  - Android APK / iOS build jobs intentionally **not** in CI
    yet — they need the Android SDK + NDK download (multi-GB,
    slow) and we don't ship release builds from CI. Add as a
    separate `release.yml` workflow once we cut Play Store
    tracks.
  - **One-time format pass** applied to the entire codebase
    (`dart format .`) — 50 files re-formatted to satisfy the
    new gate. All 89 tests still pass.

- **M4 — Lifestyle Logging** shipped:
  - **Drift schema v3 → v4**: new `lifestyle_logs` table
    (`tables/lifestyle_logs_table.dart`) — one row per
    observation, `value REAL` so the same column type handles
    integer categories (water/exercise/mood) and decimal
    categories (sleep), UTC-ms timestamps for `loggedAt` and
    `createdAt`. Generated code regenerated; `schemaVersion`
    bumped to 4 with a single-line `onUpgrade` step
    (`m.createTable(lifestyleLogsTable)`).
  - **`LifestyleLogsDao`** exposes the typed reactive surface:
    `watchBetween(fromEpochMs, toEpochMs)` for the today /
    history streams, `listBetween` for one-shot reads,
    `upsert` (insertOnConflictUpdate by id), `deleteById`.
    All range bounds are inclusive on both ends so callers
    pass the local-midnight window they want.
  - **Domain** (`features/lifestyle/domain/`):
    - `LogAggregation` enum — `cumulative` (sum across the
      day: water glasses, exercise minutes) vs `snapshot`
      (latest entry wins: sleep hours, today's mood). The UI
      switches affordance + rollup math based on this flag.
    - `LogCategory` enum carries its display metadata —
      `storageKey` (wire-stable, never rename without a
      migration), `label`, `unit`, `aggregation`, `minValue`,
      `maxValue`, `defaultStep`, `isInteger`. Categories
      shipped: **water** (0–30 glasses, cumulative),
      **sleep** (0–24 hours, snapshot), **exercise** (0–600
      minutes, cumulative), **mood** (1–5, snapshot).
      `isValid()` and `fromStorageKey()` keep validation +
      forward-compat parsing in the same place.
    - `LifestyleLog` entity (immutable, `copyWith`,
      structural equality). `LifestyleLog.create()` factory
      stamps a fresh uuid + `loggedAt`/`createdAt = now` and
      trims notes.
    - `LifestyleLogRepository` abstract interface — range
      queries expressed in local `DateTime` (data layer
      converts to/from UTC at the boundary, mirroring
      `EventRepository`).
  - **Data**: `LifestyleLogRepositoryImpl` translates between
    Drift rows and domain objects, including the
    storageKey ↔ enum mapping. Rows with an unknown
    storageKey are silently dropped from reads — keeps the
    app forward-compatible if a newer schema is rolled back.
  - **Application** (Riverpod): `lifestyleLogRepositoryProvider`
    (Drift-backed), `lifestyleControllerProvider` (write-side
    `log()` + `delete()` with validation + structured logging
    via `AppLogger`), `todayLogsStreamProvider` (local
    midnight window), `weekLogsStreamProvider` (rolling 7-day
    window). The two stream providers drive the today
    dashboard and the history list respectively.
  - **Presentation** — `LifestylePage` replaces the M0
    placeholder:
    - `CategorySummaryCard` — one tile per `LogCategory`
      (2×2 grid), shows the rolled-up value + unit + entries
      today + add affordance. Tap to open the quick-log sheet
      pre-selected to that category.
    - `QuickLogSheet` — modal bottom sheet with
      `ChoiceChip`s for category, numeric input gated by
      `LogCategory.isValid()` + `TextInputType` /
      `inputFormatters` matching `isInteger`, optional note.
      Save uses `LifestyleController.log()` and surfaces
      failures via SnackBar.
    - `LogHistoryTile` — last-7-days entries with swipe-to-
      delete (delegated to the page so the swipe gesture
      pops a confirm dialog before mutating).
    - `category_icons.dart` — static `iconFor(LogCategory)`
      switch mapper so the domain layer stays Flutter-free
      while UI call sites still satisfy const-`IconData`
      constraints.
    - `rollupByCategory()` is a top-level pure function next
      to the page so it can be unit-tested without a widget
      tree (returns `Map<LogCategory, CategoryRollupView>`).
  - **Tests** — 110/110 passing (up from 89):
    - `log_category_test`: storageKey uniqueness +
      round-trip, validation per category (water rejects
      fractions / out-of-range, sleep accepts halves, mood
      `[1..5]` integers, exercise `[0..600]`), aggregation
      kind mapping.
    - `lifestyle_log_repository_impl_test`: empty start,
      upsert + watch, replace-by-id, range exclusion,
      newest-first ordering, listBetween parity,
      delete, note round-trip including null.
    - `rollup_by_category_test`: cumulative sums, snapshot
      latest-wins, decimal vs integer formatting, mixed
      categories aggregate independently.
    - `widget_test.dart`: in-memory
      `_InMemoryLifestyleLogRepository`; lifestyle tab test
      asserts the 4 category cards + Quick log FAB above the
      fold, then `dragUntilVisible` to verify "Last 7 days"
      + empty-state copy.
  - **`flutter analyze`**: still zero issues.
  - **APK build verified**: debug APK builds, installs on
    `emulator-5554`, app boots through the fresh-install
    `onCreate` path and the v3→v4 `onUpgrade` migration
    without crashes (logcat clean — only a benign HWUI EGL
    notice).

- **M5 — Recommendation Engine v1** shipped:
  - **Domain** (`features/recommendations/domain/`):
    - `InsightSeverity` enum (`info` / `encourage` / `warn` /
      `critical`) — drives card colour + sort order via
      `index`. `critical` reserved for future health flags;
      no M5 rule emits it yet, but UI styling is already
      wired so adding the first one is zero-friction.
    - `Insight` entity — `id`, `severity`, `title`, `body`,
      optional `relatedCategory` (for icon tint), optional
      `ctaLabel` + `ctaRoute`. Immutable + structural
      equality so widget keys + analytics dedupe work.
    - `LifestyleSnapshot` value object — pre-aggregated
      `Map<LogCategory, Map<DateTime, DailyAggregate>>`
      keyed by local midnight, plus optional
      `LifeEstimate`, `referenceDate`, `windowDays`. Helpers
      (`recentDays`, `activeDays`, `averagePerActiveDay`,
      `sumOverWindow`, `hasAnyLogIn`) keep rule code
      one-liners.
    - `DailyAggregate` — per (date, category) value +
      entryCount.
    - `RecommendationRule` abstract interface — pure
      function `evaluate(snapshot) -> Insight?`. No
      `BuildContext`, no `Ref`, no I/O.
    - **Six starter rules** (one file each → Open/Closed):
      - `WaterTargetRule` (≥3 sample days, avg < 6 glasses
        over last 7 days) — `warn`.
      - `SleepRegularityRule` (≥3 nights < 6h in last 7
        days) — `warn`.
      - `ExerciseStreakRule` (0 exercise minutes in last 7
        days; guarded by "user is actively logging
        something else" so it never stacks with
        `NoDataRule`) — `encourage`.
      - `MoodTrendRule` (last 3 logged moods strictly
        descending) — `warn`. Strict descent avoids firing
        on flat `(3,3,3)`.
      - `LifePhaseRule` (percentLived crosses 25/50/75/90)
        — `info`. Picks the largest matched threshold.
      - `NoDataRule` (zero lifestyle logs in last 14 days)
        — `encourage`. Onboarding nudge.
  - **Application** (`features/recommendations/application/`):
    - `SnapshotBuilder` — pure transformer `(logs, now,
      windowDays, lifeEstimate?) -> LifestyleSnapshot`.
      Honours `LogAggregation` (cumulative sums per day,
      snapshot picks latest), drops entries outside the
      window. Reusable from any future surface (weekly
      digest, push payload, …).
    - `RecommendationEngine` — composes the rule list,
      drops nulls, sorts by severity descending, returns
      `List<Insight>` (unmodifiable). `evaluateTop(max:)`
      caps for attention-limited surfaces.
    - `providers.dart`:
      - `defaultRuleSetProvider` (all 6 rules; add a rule =
        append here, no engine change).
      - `snapshotBuilderProvider`, `recommendationEngineProvider`.
      - `insightWindowLogsStreamProvider` — 14-day rolling
        window query against the M4 lifestyle repository
        (doesn't widen M4's 7-day `weekLogsStreamProvider`).
      - `insightsProvider` — composes the logs stream + the
        existing `lifeCountdownControllerProvider` into the
        evaluated insight feed. Recomputes whenever either
        upstream changes; surfaces loading/error from
        whichever is pending.
      - `kInsightWindowDays = 14` — single source of truth
        shared with the builder and tests.
  - **Presentation** (`features/recommendations/presentation/`):
    - `InsightCard` — stateless, severity drives the
      colour mapper (`_toneFor`) which reads from the
      app's `ColorScheme` (no hard-coded hex → dark mode
      free, rebrand free). Icon falls back to
      severity-specific glyphs when `relatedCategory` is
      null. `ctaLabel` renders a `TextButton` that the
      parent wires.
    - `InsightsSection` — `ConsumerWidget`, watches
      `insightsProvider`, hides itself when empty (loading,
      error, or zero insights — never grows an empty
      "Insights" header). Caps at `maxCards: 3`. CTA taps
      route via `context.go(ctaRoute)`.
    - Surfaced inline on `LifeCountdownPage` between the
      display-mode segmented control and the existing
      estimate/expectancy cards. Justification in BRD §5.4:
      Life is the most-opened screen, insights piggyback
      on that attention.
  - **Tests** — 141/141 passing (up from 110):
    - `snapshot_builder_test`: empty snapshot, cumulative
      day-sum, snapshot latest-wins, window drop,
      chronological `recentDays`, `averagePerActiveDay`
      (ignores empty days), `sumOverWindow`, `hasAnyLogIn`.
    - `rules_test`: every rule covered with both fire and
      skip cases; `MoodTrendRule` explicitly asserts flat
      `(3,3,3)` does *not* fire; `LifePhaseRule` asserts
      it picks the highest crossed threshold.
    - `recommendation_engine_test`: drops nulls, sorts by
      severity descending (verifies all 4 tiers in order),
      returns an unmodifiable list, `evaluateTop` caps.
  - **`flutter analyze`**: still zero issues.
  - **APK build verified + live on emulator**: debug APK
    installs over the existing app, freshly-onboarded
    profile triggers `NoDataRule` + `LifePhaseRule` (50%
    bucket), both render with their per-severity tones and
    the CTAs route to `/lifestyle` and `/events`
    respectively. Screenshot in chat history.

- **M6 — Polish & beta (l10n + a11y + goldens)** shipped:
  - **Localization (ID + EN)** — full `flutter_localizations`
    + `gen-l10n` pipeline. Two ARB files at `lib/l10n/`,
    generated `AppL` lives at `lib/l10n/generated/`.
    `l10n.yaml` pins `output-class: AppL` so the generated
    helper is short to type. **80+ keys** covering every
    surface string: nav chrome, onboarding, life
    countdown, events (cards, editor, dialogs), lifestyle
    (today summary, quick log, history, delete dialog,
    empty state), insights section header, common
    buttons/snackbars, and Settings.
    - ICU plurals used for: `lifeAlreadyLived`,
      `eventsCountdownDays`, `lifestyleEntriesToday`,
      `lifestyleHistoryDaysAgo`,
      `eventsCountdownBadgeSemanticLabel`.
    - **Domain layers kept Flutter-free**: enum→label
      mappers live in `lib/core/l10n/enum_labels.dart`
      (presentation-side helpers for `Sex`, `DisplayMode`,
      `Recurrence`, `LogCategory`). Domain enums still
      expose stable storage keys + diagnostic English
      labels for logs.
    - **`NumberFormat` and `DateFormat` are locale-aware**:
      every call passes `Localizations.localeOf(context).toString()`
      so "10,907" in EN becomes "10.907" in ID, and
      `DateFormat.yMMMMd` reads "June 20, 2026" vs
      "20 Juni 2026" automatically.
    - **`MaterialApp`** picks up `localizationsDelegates`
      and `supportedLocales` from `AppL`, and a new
      `LocaleController` (`lib/core/l10n/locale_controller.dart`)
      persists the user's choice into the existing
      `SharedPreferences` seam under key
      `polaris.locale.v1`. `null` = follow system.
  - **Settings page upgraded** (was a "Coming Soon"
    placeholder): real `ListView` with a "Language"
    section + new `LanguagePickerTile` widget (radio
    group with Follow system / English / Bahasa
    Indonesia). Tile uses Material 3's `RadioGroup` API.
    Toggling the radio updates `MaterialApp.locale` in
    real time across all 4 tabs.
  - **Accessibility pass**:
    - **Semantics labels** on icon-only buttons + decorative
      icons: `PopupMenuButton` on `EventCard` now has a
      proper tooltip (`eventsActionsMenuLabel`); pinned-pin
      icon announces `eventsPinnedSemanticLabel`; the
      `_CountdownBadge` collapses its number + "days"
      stack into a single `excludeSemantics` `Semantics`
      node labelled "14 days remaining"; the hero
      `CountdownDisplay` announces e.g. "10,907 DAYS
      REMAINING" as one a11y node; `add_circle`
      decorative icon on `CategorySummaryCard` wrapped in
      `ExcludeSemantics`.
    - **Text-scale safety**: hero countdown number wrapped
      in `FittedBox(BoxFit.scaleDown, maxLines: 1)` so
      it never overflows at 1.5× / 2× text scale or on
      narrower screens.
    - **Tap targets**: `LanguagePickerTile` uses
      `RadioListTile` (>= 48dp by default with
      `VisualDensity.standard`). Existing FABs and the
      pin/delete popup menu already exceed 48dp; no
      shrinkage needed.
    - **Contrast**: `InsightCard` titles use `onSurface`
      and bodies use `onSurfaceVariant` against
      `*Container` backgrounds — Material's contract
      already guarantees WCAG AA; severity tones use
      `withValues(alpha: 0.35)` on the container which
      preserves the on-surface contrast envelope.
  - **Golden tests** — new `test/golden/` tree, 10
    baselines, **tagged `@Tags(<String>['golden'])`** so
    CI on Linux can skip via `--exclude-tags=golden`
    (font rendering differs across hosts). All goldens
    generated on macOS:
    - `event_card_unpinned_en.png`,
      `event_card_pinned_yearly_id.png`
    - `category_summary_water_en.png`,
      `category_summary_mood_empty_id.png`
    - `insight_info.png`, `insight_encourage.png`,
      `insight_warn.png`, `insight_critical.png`
    - `countdown_days_en_light.png`,
      `countdown_percent_id_dark.png`
    - **Harness** at `test/golden/golden_harness.dart`
      pumps each widget inside a real `MaterialApp` with
      `AppTheme.light()/dark()` and pins a locale per
      call so EN vs ID variants are explicit. Body text
      renders as Roboto placeholder rectangles in the
      Flutter test runtime (no system font); the
      diff comparator still catches layout/color/spacing
      regressions byte-for-byte. To regen after a UI
      change: `flutter test test/golden --update-goldens`.
    - **`dart_test.yaml`** declares the `golden` tag so
      runners don't warn about an unknown tag.
    - **`.github/workflows/ci.yml`** now invokes
      `flutter test --coverage --exclude-tags=golden`.
  - **Test totals**: **141 unit + widget tests** (no
    regressions from M5) + **10 golden tests** = 151
    passing locally.
  - **APK verified on emulator**: built debug APK
    installed over the existing app, switched language
    to "Bahasa Indonesia" via Settings → Life tab
    re-rendered with localized chrome (`HARI TERSISA`,
    `Saran untuk Anda`, `Hari / Minggu / Bulan / Tahun`)
    and ID number format (`10.907`). Screenshots in
    chat history.
  - **Known gaps deferred to M7+**:
    - **Insight title + body strings are still English**
      because they're emitted from `RecommendationRule`s
      in the domain layer. Refactor plan: have rules
      emit an `id` + a `Map<String, Object?> params`,
      then a presentation-side `InsightContent` resolver
      looks them up in ARB. Out of scope here to keep
      M6 a single sitting.
    - **Internal Play Store track** (sub-deliverable D)
      not started — needs the owner to set up the Play
      Console + a signing keystore + service account.
      Once those are in place we add `key.properties` +
      a `release.yml` workflow that builds a signed AAB
      on `v*` tag push and uploads via
      `r0adkll/upload-google-play`.
    - ~~**Android home-screen widget text** still uses
      `event.recurrence.label` (English)~~ — **resolved
      by Widget Pin v2**: `PolarisHomeWidgetUpdater` now
      loads `AppL` for the user's preferred locale on
      every refresh and routes recurrence labels through
      a local switch. Date/number formatting also locale-
      aware. The Glance Compose migration is now purely
      a rendering-engine concern, not a localization gap.

- **Widget Pin v2 (life pin + custom message)** shipped on
  top of M6:
  - **Drift schema v5** adds a nullable `widget_message`
    column to `events_table`. Migration runs idempotently
    on launch via `addColumn` — verified live on the
    emulator (existing test event survived intact).
  - **`Event.widgetMessage`** is the per-event override
    line. Trimmed + normalized to `null` on empty in the
    entity factory so the widget code never has to
    special-case empty strings. Mapped through both
    directions of `EventRepositoryImpl`. Surfaced in
    `EventEditorSheet` as a dedicated TextField below
    `note` (kept separate because note = private context,
    `widgetMessage` = what the widget shows).
  - **`LifePinPreferences` + `LifePinRepository`**
    (SharedPreferences-backed, broadcast `watch()` stream)
    persist `{pinned, customMessage}` under the
    `polaris.life_pin.v1.*` keys. Unpinning preserves the
    message so re-pinning later restores it without
    retyping.
  - **`LifePinController`** owns the write path:
    `pin(customMessage:)`, `updateMessage(...)`, `unpin()`.
    `pin()` enforces the mutual-exclusivity invariant by
    calling `eventRepository.pinExclusive(null)` before
    refreshing the widget — only one subject can occupy
    the pinned slot at a time. Symmetric guard lives in
    `EventsController.togglePin`, which clears the life
    pin when pinning an event (unpinning an event does
    NOT auto-pin life — that would be surprising).
  - **`LifePinSheet`** (modal bottom sheet, opened from a
    new pin `IconButton` in the Life tab AppBar) hosts a
    `SwitchListTile.adaptive` toggle, a max-80-char custom
    message `TextField`, and Cancel/Save buttons. The
    AppBar icon switches between `push_pin_outlined` /
    `push_pin` via a `StreamProvider` on the prefs, so
    pin state is always reflected without a manual
    refresh.
  - **`PolarisHomeWidgetUpdater` rewritten** with explicit
    subject priority: life-pin → event-pin → empty. The
    widget renders the user's custom message in place of
    the auto subtitle when one is set (Event.widgetMessage
    for events, LifePinPreferences.customMessage for life).
    Now locale-aware: reads the user's `polaris.locale.v1`
    preference (falls back to `PlatformDispatcher.locale`)
    and formats hero/subtitle/recurrence strings through
    `AppL.delegate.load(locale)` — recurrence labels are
    handled via a local switch since `enum_labels.dart`
    requires a `BuildContext` we don't have in the
    headless refresh path. **Bootstrap now eagerly calls
    `initializeDateFormatting('en'/'id')`** so the first
    widget refresh after launch doesn't blow up on
    `LocaleDataException`.
  - **New tests** (+13 over the M6 baseline → **154** unit
    + 10 golden):
    - `life_pin_repository_test.dart` — round-trip,
      whitespace normalization, `clear()`, `watch()`
      emissions.
    - `life_pin_controller_test.dart` — pin/unpin/update
      side effects, widget refresh only when pinned,
      `EventsController.togglePin × LifePinRepository`
      mutual exclusivity in both directions.
    - `polaris_home_widget_updater_test.dart` rewritten
      end-to-end: event pin (EN), event `widgetMessage`
      overrides subtitle, life-pin priority over event,
      life custom message overrides subtitle, life pin
      with missing profile falls back to event, ID
      locale renders ID strings (`hari lagi`, `Sekitar`).
  - **L10n** keys added (EN + ID) for the sheet
    (`lifePinSheetTitle`, `lifePinToggleLabel`,
    `lifePinToggleHelper`, `lifePinCustomMessageLabel`,
    `lifePinCustomMessageHelper`, `lifePinAction`,
    `lifePinUnpinAction`, `lifePinTooltip`,
    `lifePinUnpinTooltip`) and the widget itself
    (`lifeWidgetDaysRemainingShort` plural,
    `lifeWidgetSubtitleDefault`,
    `widgetEventDays` plural,
    `widgetEventSubtitleDefault`,
    `eventsFieldWidgetMessage` + helper).
  - Verified end-to-end on the emulator: pinned life
    countdown with `"Satu napas pada satu waktu"` → home
    widget renders **Sisa Hariku / 10906 hari lagi /
    Satu napas pada satu waktu**, and the previously
    pinned `test` event was auto-unpinned by the
    exclusivity guard.

- **Multi-Pin Widget (v3)** shipped on top of Widget Pin
  v2 — the home-screen widget is no longer a single-card
  view of "whatever subject is pinned right now". It's a
  native `RemoteViews` collection widget that renders a
  **scrollable `ListView` of every pinned subject** (life
  pin + each event with `isPinnedToWidget = true`):
  - **Mutual exclusivity removed**. Life and event pins
    are now independent — pinning life does NOT unpin
    events and vice versa. `EventRepository.setPinned(id,
    bool)` is the new per-event entrypoint (the old
    `pinExclusive` is kept for backward compat).
    `EventsController.togglePin` routes through
    `setPinned`; `LifePinController` no longer touches the
    event repository at all. The `LifePinSheet` copy was
    updated to drop the "akan melepas event" warning.
  - **Wire contract rewritten**. `PolarisHomeWidgetUpdater`
    serializes a JSON array under a single SharedPreferences
    key (`polaris_widget_items_json`) plus header /
    empty-state strings (`polaris_widget_header_title`,
    `polaris_widget_empty_title`,
    `polaris_widget_empty_subtitle`). Each item is
    `{id, kind, title, hero, subtitle, accent}`. Ordering:
    life first (amber accent matching the brand pill),
    then events in repository order (target date ascending,
    each row uses `event.colorHex` as its accent strip).
  - **Native collection widget**. New files in
    `android/app/src/main/kotlin/com/phandarian/polaris/`:
    - `PolarisWidgetRemoteViewsService.kt` — thin
      `RemoteViewsService` shell.
    - `PolarisWidgetItemsFactory.kt` — `RemoteViewsFactory`
      that re-reads the JSON from `HomeWidgetPreferences`
      in `onDataSetChanged`, parses with `org.json.JSONArray`,
      and binds each row's title / hero / subtitle / accent
      color via `RemoteViews#setInt(..., "setBackgroundColor",
      ...)`. Empty / malformed JSON → empty list → empty
      view shows.
    - `PolarisWidgetProvider.kt` rewritten — binds the
      `ListView` via `setRemoteAdapter`, wires
      `setEmptyView`, sets a `PendingIntent` template for
      per-row taps, and crucially calls
      `notifyAppWidgetViewDataChanged` every update so the
      adapter actually re-reads the JSON (otherwise the
      first payload is cached forever).
    - `AndroidManifest.xml` registers the service with
      `android:permission="android.permission.BIND_REMOTEVIEWS"`
      and `android:exported="false"`.
  - **New layouts**:
    `res/layout/polaris_widget_layout.xml` is now a
    header + `ListView` + empty-state column;
    `res/layout/polaris_widget_item.xml` is the per-row
    card with a 4dp accent strip, title, hero, subtitle.
    Default size bumped from 2×2 to 4×3 (`minWidth=250dp`,
    `minHeight=180dp`, `resizeMode="horizontal|vertical"`)
    so multiple rows fit out of the box.
  - **Sharp edge — `<View>` is not allowed in RemoteViews**.
    Initial implementation used `<View>` for the accent
    strip; the launcher refused to inflate with
    "Class not allowed to be inflated android.view.View".
    Replaced with `<FrameLayout>` (allowed) — the comment
    in `polaris_widget_item.xml` documents this so the
    next change doesn't re-introduce the bug. (Same family
    as the previous `<Space>` regression we hit in v2.)
  - **Tests updated** (still **166** unit + golden):
    `polaris_home_widget_updater_test.dart` rewritten to
    assert the JSON array shape (multi-pin order,
    accent-color round-trip, custom messages, locale
    rendering, empty list on repo failure).
    `life_pin_controller_test.dart` rewritten to assert
    `LifePinController.pin` does NOT touch
    `EventRepository`, and `EventsController.togglePin`
    uses the new `setPinned` instead of `pinExclusive`
    and does NOT unpin the life countdown.
  - **Verified end-to-end on the emulator** (Pixel API 34):
    life pin + one event pinned simultaneously → widget
    shows two rows — **Sisa Hariku / 10906 hari lagi /
    Satu napas pada satu waktu** (amber strip) and
    **test / 6 hari / Sab, Jun 20 · Bulanan** (cyan strip
    matching the event's `#0EA5E9` color). No mutual
    exclusivity — both coexist. Native `ListView` scrolls
    automatically once items overflow.
  - **Deferred**: SVG / icon / background polish — the
    user mentioned wanting to source nice SVGs next; once
    those land they'll likely come in as Android vector
    drawables (`drawable/*.xml`) referenced from the
    widget layout, plus a possible `ImageView` row prefix
    in `polaris_widget_item.xml` for per-kind icons.

- **Auth & Cloud Sync strategy locked in** (decision only,
  no implementation):
  - Captured in [`docs/Auth-Strategy.md`](./Auth-Strategy.md).
    Decision: **Supabase free tier when Phase 2 (M9) begins**.
    BRD §6/§7.2 keeps auth + sync as Phase 2 — offline-first
    stays the MVP posture.
  - Rejected alternatives documented in the ADR: Neon
    alone (needs custom API on top — wrong shape for solo
    mobile dev), Firebase (Firestore is doc DB, doesn't
    fit Drift's relational schema, no exit ramp), Appwrite
    (less mature Flutter SDK). **PocketBase self-hosted is
    the strong runner-up** — revisit if Polaris graduates
    to a serious commercial product where UU PDP data
    residency + Indonesia latency become first-order wins.
  - **Schema v6 shipped today as sync insurance**
    (no behavior change): added nullable
    `events_table.deletedAtEpochMs`, and BOTH
    `lifestyle_logs_table.updatedAtEpochMs` +
    `deletedAtEpochMs`. Columns sit empty until the Phase 2
    sync engine starts writing them. Cheap reservation
    avoids a data-backfill migration later. Migration
    `from < 6` clause added to `app_database.dart`. All
    166 tests still green, `flutter analyze` clean.
  - **No code changes besides the schema bump** —
    `Remote*Repository` siblings, `AuthService`,
    `SyncCoordinator`, and the optional "Sign in to sync"
    onboarding CTA are all deferred to the M9 sitting
    (~1 week of focused work, day-by-day breakdown in
    Auth-Strategy.md §5).

### In Progress
- None — Multi-Pin Widget (v3) closed. M6 deferred items
  (Play Store track, insight l10n) still owner/scope-gated.
  Pending: SVG asset hunt (user-driven) + widget visual
  polish on top of those assets. Manual smoke tests below
  remain user-driven. Auth/sync work is deferred to Phase 2
  per `docs/Auth-Strategy.md`.

### Pending Manual Verification (user-driven)
- **Lifestyle end-to-end on device**:
  1. Open Polaris → Lifestyle tab.
  2. Tap a category card (e.g. Water) → quick-log sheet
     opens pre-selected to that category.
  3. Save a value → today summary card updates with the new
     total + entries count.
  4. Pull-to-refresh: streams already auto-refresh, the
     gesture is just an explicit affordance.
  5. Scroll down to **Last 7 days**, swipe a row right →
     confirm dialog → delete; row disappears from list and
     today summary recalculates.
- **Add the widget to the Android home screen** (carry-over
  from M2 — now exercises Widget Pin v2 too):
  1. On the running emulator, long-press the home screen →
     **Widgets** → scroll to **polaris** → drag the
     "Pinned event countdown" tile to the home screen.
  2. Widget should render the empty state
     ("Polaris · — · Pin an event in Polaris").
  3. Open Polaris → Events tab → create an event a few days
     out, optionally fill **Widget message (optional)** with
     e.g. `"Lunch with Mom"`, then tap **Pin** in the card's
     menu. Widget should update within a second to show the
     event title, days countdown, and your widget message
     (or the auto `date · recurrence` line if you left it
     blank).
  4. Open the **Life** tab → tap the pin icon in the AppBar
     → toggle **Show life countdown on widget** → optionally
     type a custom message → **Pin**. The previously pinned
     event should auto-unpin and the widget should show
     `Sisa Hariku / <N> hari lagi / <your message or "Sekitar
     <date>">`.
  5. Toggle the language picker in **Settings** between
     EN and ID — the widget should re-render with the
     new locale strings (plural rules, recurrence label,
     date format).
  6. Tap the widget — Polaris should launch.
- **Notification smoke test** is also still pending — same
  flow as before: create an event ~70 min out, accept
  `POST_NOTIFICATIONS`, lock screen, wait for T-1h reminder.

### Pending Manual Verification — M6 (user-driven)
- **Locale switch on device**:
  1. Open Polaris → **Settings** tab.
  2. Tap **Bahasa Indonesia** in the Language picker.
  3. Verify Life tab title becomes `Sisa Hariku` (unchanged
     since it's preserved as a brand phrase) and the
     "DAYS REMAINING" subtitle becomes `HARI TERSISA`,
     bottom nav becomes `Hidup / Acara / Gaya Hidup /
     Pengaturan`, and Insights header becomes
     `Saran untuk Anda`.
  4. Numbers should switch to ID grouping (`10.907` instead
     of `10,907`).
  5. Tap **Follow system** to revert.
- **TalkBack a11y sweep** (optional):
  1. Enable TalkBack on the emulator/device.
  2. Swipe through the Life tab — the big countdown number
     should be announced as one phrase ("10907 DAYS
     REMAINING").
  3. On Events, the pin indicator should be announced as
     "Pinned to widget" without re-reading the icon glyph.
  4. The popup-menu icon on event cards should announce
     "More actions" via the tooltip.
- **Text-scale at 2×** (Settings → Display & font size →
  Largest): Life-tab hero number should shrink-to-fit
  (single line) and other surfaces should remain
  readable without overflow.

### Not Started (next on deck)
- **M6 sub-deliverable D — Internal Play Store track**
  (owner-gated): generate upload keystore, add
  `android/key.properties` (gitignored), wire signing in
  `android/app/build.gradle.kts`, then add a
  `release.yml` workflow that builds a signed AAB on
  `v*` tag push and uploads via
  `r0adkll/upload-google-play`. Pre-req: Play Console
  app shell created + a service-account JSON committed
  as a GitHub Actions secret.
- **Recommendation Engine v2** (after M6): dismiss-a-card
  + cooldown (so the same `LifePhaseRule` insight doesn't
  re-show every open), per-rule analytics events, plus
  3–5 more rules drawn from real user data once we have
  testers (e.g. weekend vs weekday sleep delta, mood vs
  exercise correlation, water-on-low-sleep nudge).
  Optional: ship one rule as a *positive* streak
  (`encourage` after 7 consecutive exercise days) so the
  feed isn't only warnings.
- **Lifestyle polish (deferred from M4 scope)**: per-category
  charts (e.g. last-7-days water bars, sleep trendline) —
  fold into M6 or a dedicated minor milestone. HealthKit /
  Health Connect sync remains Phase 2 per BRD §5.3.
- Future widget polish: migrate the widget to **Glance
  Compose** for Android 12+ visuals, deep-link the widget
  tap to the pinned event's detail page (currently lands on
  root), add `workmanager` for background notification
  re-evaluation (catches recurring events the user never
  opens).

---

## 3. Environment Setup & Verification

A fresh contributor (or AI session in a new sandbox) should be able to verify
the toolchain with the steps below.

### 3.1 Required toolchain
| Tool | Version | Where |
|---|---|---|
| Flutter | 3.44.1 (stable channel) | `~/TurbidDev/flutter/` |
| Dart | 3.12.1 | Bundled with Flutter |
| Xcode | latest stable (for iOS) | App Store |
| Android Studio | Koala or newer (for Android SDK + emulators) | Standalone |
| CocoaPods | latest | `sudo gem install cocoapods` |
| Git | any recent | system |

### 3.2 PATH (`~/.zshrc` excerpt)
```sh
# Flutter
export PATH="$HOME/TurbidDev/flutter/bin:$PATH"
```
Reload with `source ~/.zshrc` (or open a new terminal).

### 3.3 Verify

```sh
cd ~/TurbidDev/project-polaris
flutter --version          # expect: Flutter 3.44.1 • channel stable
flutter doctor -v          # all checked categories should be green
flutter pub get            # resolve current pubspec
dart run build_runner build  # regenerate *.g.dart (Drift, Riverpod, …)
flutter analyze            # expect: No issues found!
flutter test               # expect: All tests passed! (141 unit/widget tests)
flutter test test/golden   # macOS only — 10 golden tests (font-sensitive)
```

> The `build_runner build` step is mandatory after a fresh checkout
> because we git-ignore generated files (Decision D1). Re-run it
> after editing any Drift table, Freezed class, or Riverpod
> annotation.

### 3.4 Run the app (sanity)
```sh
flutter devices            # list connected devices / simulators
flutter run                # picks the first available device
```

> Until the architecture work in §2 is done, `flutter run` boots the default
> Flutter counter template — that is expected.

---

## 4. Next Steps (for the next AI session)

Work in this order. Each item maps to milestones in `BRD §11`.
**Steps 1 & 2 are DONE** (see Current Status above); start at Step 3.

### Step 1 — Dependencies & Lints (M0) — DONE
1. Update `pubspec.yaml` to add (latest stable on pub.dev at the time of
   writing — let `flutter pub add` resolve versions):
   - Runtime: `flutter_riverpod`, `riverpod_annotation`, `go_router`,
     `drift`, `drift_flutter`, `sqlite3_flutter_libs`, `path_provider`,
     `shared_preferences`, `intl`, `logger`, `freezed_annotation`,
     `json_annotation`, `home_widget`, `flutter_local_notifications`,
     `workmanager`.
   - Dev: `build_runner`, `riverpod_generator`, `drift_dev`, `freezed`,
     `json_serializable`, `mocktail`, `custom_lint`, `riverpod_lint`.
2. Tighten `analysis_options.yaml`: enable Riverpod lints, add
   `avoid_relative_lib_imports`, document the cross-feature import ban as a
   review rule.
3. Run `dart run build_runner build --delete-conflicting-outputs` and commit
   the generated files (or add to `.gitignore` if the team prefers
   regeneration — decide in §5).

### Step 2 — Composition root & Architecture skeleton (M0) — DONE
4. Create folder structure per `BRD §9.1` (`app/`, `core/`, `shared/`,
   `data/`, `features/`).
5. Implement `app/bootstrap.dart`, `app/app.dart`, `app/router.dart`,
   `app/theme/` (color tokens, text styles, light + dark `ThemeData`).
6. Replace `lib/main.dart` with a thin entry that calls `bootstrap()`.
7. Add a placeholder home page that routes via `go_router` to confirm
   wiring.

### Step 3 — First vertical slice: Life Countdown (M1) — DONE

### Step 4 — CI (M0, can run in parallel) — DONE
See `.github/workflows/ci.yml`. Runs analyze + format check +
test --coverage on push to `main` and on every PR. Pinned to
Flutter 3.44.1 stable. Coverage uploaded as artifact.

### Step 5 — Subsequent milestones
Follow `BRD §11` for M2 → M9. Each milestone should ship as its own PR
series and update this Handoff document's `Current Status`.

**Pointer for the next session**: **M2 closed + CI live**.
Pick one:
1. **M4 — Lifestyle Logging** (BRD §11): daily-log entry
   sheet, history view, Drift schema bump for
   `lifestyle_logs`. Then **M5 — Recommendation Engine v1**
   builds on top.
2. **M6 — Polish & beta**: a11y pass, l10n (ID + EN —
   right now most copy is hard-coded English, with
   "Sisa Hariku" as the only Indonesian string), golden
   tests for the new event card and life countdown screen,
   internal Play Store track.
3. **CI hardening** (optional): Codecov/Coveralls upload,
   release.yml workflow that signs + uploads APK to Play
   Store internal track when a `v*` tag is pushed.
4. Keep `flutter analyze` clean; add tests alongside each item.

---

## 5. Decisions Pending

These need an explicit choice before the next milestone starts. Default
recommendation is in **bold**; revisit when a real constraint appears.

| # | Question | Options | Default |
|---|---|---|---|
| D1 | Commit generated files (`*.g.dart`, `*.freezed.dart`)? | (a) commit, (b) gitignore + regenerate | **(b) gitignore** — keep diffs clean, regenerate via build step |
| D2 | Lock Flutter version with `fvm`? | (a) yes now, (b) defer to Phase 2 | **(b) defer** — solo dev, single machine |
| D3 | Analytics provider? | (a) none, (b) PostHog self-hosted, (c) Firebase | **(a) none** for MVP; revisit at M7 |
| D4 | Crash reporting? | (a) Sentry, (b) Firebase Crashlytics, (c) none | **(c) none** for closed beta; add Sentry before public beta |
| D5 | Localization stack? | (a) `flutter_localizations` + ARB, (b) `slang`, (c) `easy_localization` | **(a) official ARB** — least surprise, good tooling |
| D6 | Min iOS for MVP? | (a) 14, (b) 16 | **(a) 14** for app; require 16 only for Lock Screen Widget |
| D7 | Bundled life-expectancy table — single source or merged? | (a) WHO only, (b) BPS only, (c) merged with `source` field | **(c) merged**, store source per row for transparency |
| D8 | Branching model? | (a) trunk-based on `main`, (b) GitFlow | **(a) trunk-based** with short-lived feature branches |
| D9 | Activate `riverpod_lint` analyzer plugin? | (a) yes (needs compatible `custom_lint`), (b) defer until ecosystem aligns | **(b) defer** — `riverpod_lint 3.1.4` requires `analyzer ^9.0.0` which conflicts with the latest published `custom_lint`; revisit at M3 |

---

## 6. Key Files & Locations

| Purpose | Path |
|---|---|
| Business requirements | `docs/BRD Polaris.md` |
| This handoff | `docs/Handoff.md` |
| Flutter manifest | `pubspec.yaml` |
| Lint profile | `analysis_options.yaml` |
| Android manifest | `android/app/src/main/AndroidManifest.xml` |
| Android Kotlin source | `android/app/src/main/kotlin/com/phandarian/polaris/` |
| iOS Runner | `ios/Runner/` |
| Entry point | `lib/main.dart` → calls `bootstrap()` |
| Composition root | `lib/app/bootstrap.dart` |
| Router (StatefulShellRoute) | `lib/app/router.dart` |
| HomeShell (bottom nav) | `lib/features/home/presentation/pages/home_shell_page.dart` |
| Drift database | `lib/data/database/app_database.dart` |
| Drift database provider | `lib/data/database/providers.dart` |
| Drift tables | `lib/data/database/tables/` |
| Drift DAOs | `lib/data/database/daos/` |
| Life Countdown feature | `lib/features/life_countdown/` |
| Event Countdown feature | `lib/features/event_countdown/` |
| LifeProfile SP→Drift migration | `lib/features/life_countdown/data/migrations/life_profile_sp_to_drift.dart` |
| Notification dispatcher (interface) | `lib/core/notifications/notification_dispatcher.dart` |
| Notification dispatcher (impl) | `lib/core/notifications/flutter_local_notifications_dispatcher.dart` |
| Notification scheduler (per-event) | `lib/features/event_countdown/application/notification_scheduler.dart` |
| Reminder offsets VO | `lib/features/event_countdown/domain/value_objects/reminder_offset.dart` |
| Home-widget updater (interface) | `lib/core/widgets/home_widget_updater.dart` |
| Home-widget updater (impl) | `lib/core/widgets/polaris_home_widget_updater.dart` |
| Home-widget provider (Kotlin) | `android/app/src/main/kotlin/com/phandarian/polaris/PolarisWidgetProvider.kt` |
| Home-widget metadata (XML) | `android/app/src/main/res/xml/polaris_widget_info.xml` |
| Home-widget layout (RemoteViews) | `android/app/src/main/res/layout/polaris_widget_layout.xml` |
| Seed assets | `assets/seed/` |
| Test root | `test/` |
| CI workflow (GitHub Actions) | `.github/workflows/ci.yml` |

### External links
- GitHub repo: <https://github.com/irwanphan/polaris>
- Flutter docs (3.44): <https://docs.flutter.dev/release/release-notes>
- Riverpod docs: <https://riverpod.dev>
- Drift docs: <https://drift.simonbinder.eu>
- Glance (Android widget): <https://developer.android.com/jetpack/androidx/releases/glance>
- WidgetKit (iOS): <https://developer.apple.com/documentation/widgetkit>
- WHO Global Health Observatory: <https://www.who.int/data/gho>
- BPS (Indonesia statistics): <https://www.bps.go.id>

---

## 7. Conventions for AI Sessions

When you (the next AI assistant) act on this project:

1. **Always read `BRD Polaris.md` first**, then this Handoff, before
   writing code. They are the source of truth.
2. **Honor the dependency rule** in `BRD §9.2` — never import `data` from
   `presentation`, never cross-import between `features/`.
3. **One Riverpod controller per feature**; place providers in
   `features/<x>/application/providers.dart`.
4. **No comments that narrate the obvious.** Comments should explain *why*,
   trade-offs, or non-obvious constraints — never *what* the code does.
5. **Reusable components follow SOLID** (user rule). Prefer composition over
   inheritance, accept dependencies through constructors / Riverpod
   overrides.
6. **Styling is Tailwind-flavored when possible** (user rule) — for Flutter
   that translates to: design tokens in `app/theme/color_tokens.dart`,
   spacing scale of 4, semantic text styles, no ad-hoc colors in widgets.
7. After substantive changes, run `flutter analyze` and `flutter test`
   before committing.
8. Update this Handoff's `Current Status` and `Next Steps` whenever a
   milestone advances.

---

## 8. Change Log

| Date | Author | Notes |
|---|---|---|
| 2026-06-12 | Cursor AI session | Initial handoff draft (§§1–2 partial) |
| 2026-06-12 | Cursor AI session | Completed §§2–8; aligned with BRD v0.2.0 |
| 2026-06-12 | Cursor AI session | Shipped **M0 — Foundation**: dependencies, lints, folder structure, theme, router, composition root, shared widgets, placeholder pages, 14/14 tests passing, `flutter analyze` clean. Added D9. |
| 2026-06-12 | Cursor AI session | Shipped **M1 — Life Countdown vertical slice**: domain (VOs + entities + use case), data (seed JSON + repositories), application (Riverpod AsyncNotifiers), presentation (onboarding + real countdown screen + reusable widgets), router redirect logic. 34/34 tests passing, `flutter analyze` clean. |
| 2026-06-12 | Cursor AI session | Shipped **M2 — Event Countdown CRUD slice**: Drift v1 + EventsDao, domain entities + recurrence math, repository with `Result`-wrapped failures, `EventsController` (create/update/delete/togglePin), real Event Countdown page + editor sheet. 57/57 tests passing, `flutter analyze` clean. |
| 2026-06-12 | Cursor AI session | Shipped **M2 — HomeShell + LifeProfile→Drift**: bottom-nav `StatefulShellRoute`, `LifeProfilesTable` (schema v2) + DAO + Drift repository, one-shot SP→Drift migration in `bootstrap()`. 68/68 tests passing, `flutter analyze` clean. |
| 2026-06-12 | Cursor AI session | Shipped **M2 — Notification scheduler**: `flutter_local_notifications` + TZ deps, Android manifest receivers + permissions, NDK pinned to 30.0.14904198, Drift v3 with `NotificationSchedulesTable`, `NotificationDispatcher` interface + Flutter Local Notifications impl in `core/`, per-event `NotificationScheduler` (T-7d/T-1d/T-1h) wired into `EventsController`, dispatcher init in bootstrap. 79/79 tests passing, `flutter analyze` clean. On-device smoke test deferred — local disk at 100%. |
| 2026-06-12 | Cursor AI session | **Android build fixes**: (a) NDK override applied to *all* `:plugin` subprojects via `android/build.gradle.kts` (transitive plugins like `jni` from `flutter_timezone` were re-asking for Flutter's default NDK); (b) core library desugaring enabled (`isCoreLibraryDesugaringEnabled = true` + `desugar_jdk_libs:2.1.4`) — required by `flutter_local_notifications` ≥ 18. `flutter build apk --debug` now succeeds. |
| 2026-06-13 | Cursor AI session | **Bootstrap zone fix**: moved `WidgetsFlutterBinding.ensureInitialized()` + all async init (SharedPreferences, AppDatabase, migration, notifications init) inside `runZonedGuarded` so binding zone matches `runApp`. Eliminates the "Zone mismatch" warning that fired on every cold boot. |
| 2026-06-13 | Cursor AI session | Shipped **M2 — Android home-screen widget**: `home_widget ^0.9.3` + `PolarisWidgetProvider` (Kotlin, RemoteViews) + indigo card layout with amber brand pill, abstract `HomeWidgetUpdater` in `core/widgets/` + concrete `PolarisHomeWidgetUpdater` (reads pinned event via new `EventRepository.getPinned()`, formats in Dart, pushes via `home_widget` plugin), wired into `EventsController` (create/update/delete/togglePin) and bootstrap initial refresh. 89/89 tests passing, `flutter analyze` clean. **M2 closed.** |
| 2026-06-13 | Cursor AI session | Shipped **CI (GitHub Actions)**: `.github/workflows/ci.yml` runs on push to `main` and every PR; pinned to Flutter 3.44.1 stable; pipeline = pub get → build_runner → format check → analyze → test --coverage; coverage uploaded as artifact. One-time `dart format .` cleanup applied (50 files re-formatted, 89/89 tests still pass). Handoff §4 Step 4 done. |
| 2026-06-14 | Cursor AI session | Shipped **Widget Pin v2**: Drift v5 adds `events_table.widget_message` (per-event widget override); new `LifePinPreferences` + `LifePinRepository` + `LifePinController` (life can be pinned with a custom mantra); mutual exclusivity between life pin and event pin (only one subject in the widget at a time). `PolarisHomeWidgetUpdater` rewritten with priority resolution + locale-aware date / recurrence formatting (loads `AppL` for the user's `polaris.locale.v1` pref, falls back to `PlatformDispatcher.locale`); `initializeDateFormatting('en'/'id')` added to `bootstrap()` so the headless refresh path doesn't hit `LocaleDataException`. New `LifePinSheet` modal + AppBar pin icon on the Life tab. 154 unit + 10 golden tests, `flutter analyze` clean. |
| 2026-06-14 | Cursor AI session | **Auth & Cloud Sync ADR captured** + schema v6 sync insurance shipped. Decision: Supabase free tier when Phase 2 (M9) begins. Rationale + Phase-2 day-by-day implementation plan + rejected alternatives (Neon-alone, Firebase, Appwrite) + runner-up (PocketBase) documented in [`docs/Auth-Strategy.md`](./Auth-Strategy.md). Schema v6 adds nullable `events_table.deletedAtEpochMs` + `lifestyle_logs_table.{updatedAtEpochMs, deletedAtEpochMs}` — pure column reservation, no app code changes. 166 tests green, `flutter analyze` clean. |
| 2026-06-14 | Cursor AI session | **Widget redesign: light "ticket frame" surface.** Surface drawable rewritten as a `layer-list` — thick black outer ring + cyan-50 `#ECFEFF` fill + thin black hairline (1.5dp) inset 10dp. Text colors flipped from white-on-indigo to slate-900/slate-500 on cyan-50. Per-row card background made transparent (outer frame is the only "card" affordance now); row separation via padding + accent strip. Verified on emulator: life pin (amber accent) + event pin (per-event accent) coexist in the new framed surface. Color spec source: `oklch(98.4% 0.019 200.873)` from the user — converted to `#ECFEFF` since Android XML doesn't speak OKLCH natively. |
| 2026-06-14 | Cursor AI session | Shipped **Multi-Pin Widget (v3)**: dropped mutual exclusivity — life and event pins are now independent. `EventRepository.setPinned(id, bool)` is the new per-event entrypoint (legacy `pinExclusive` kept for back-compat). Widget rewritten as a native `RemoteViews` **collection widget**: `PolarisHomeWidgetUpdater` serializes all pinned subjects (life first w/ amber accent, then events sorted by target date w/ per-event color accent) as a JSON array under `polaris_widget_items_json`; `PolarisWidgetRemoteViewsService` + `PolarisWidgetItemsFactory` parse it and feed a `ListView` inside the widget; `PolarisWidgetProvider` wires `setRemoteAdapter` + `notifyAppWidgetViewDataChanged` (critical for re-reads) + `setPendingIntentTemplate` for per-row taps; service registered in `AndroidManifest.xml` with `BIND_REMOTEVIEWS`. Default widget size bumped from 2×2 to 4×3 with `resizeMode="horizontal\|vertical"`. Sharp edge fix: `<View>` is not on the RemoteViews allow-list — accent strip now uses `<FrameLayout>` (commented in `polaris_widget_item.xml`). `LifePinSheet` copy de-warned. Tests updated to assert the JSON-array shape and the no-exclusivity invariant. 166 tests passing, `flutter analyze` clean. Verified on emulator: life + event coexist in the widget list, locale-aware (`Sisa Hariku / 10906 hari lagi / Satu napas pada satu waktu` + `test / 6 hari / Sab, Jun 20 · Bulanan`). Deferred: SVG/icon polish (user is sourcing assets). |
