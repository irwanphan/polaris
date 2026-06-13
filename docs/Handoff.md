# Handoff Document — Polaris

> **Purpose:** Hand this file to a new AI chat session (or a new collaborator)
> to continue development without losing context.
> **Last updated:** 2026-06-12 by Cursor AI session — **M2 Notifications scheduler complete (Android home-widget pending)**

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

## 2. Current Status (As of 2026-06-12, M2 progress: HomeShell + LifeProfile→Drift + Notifications scheduler done)

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

### In Progress
- None — clean checkpoint after the notification scheduler.

### Not Started (next on deck)
- **Smoke test on emulator** — `flutter build apk --debug`
  now succeeds (debug APK at
  `build/app/outputs/flutter-apk/app-debug.apk`, ~11 min cold
  build because Gradle had to install CMake 3.22.1 and
  desugar tooling). Pending step: with the emulator running,
  `flutter install -d emulator-5554` (or `flutter run -d
  emulator-5554`) and then exercise:
  1. Boot into onboarding, complete it.
  2. Create an event one hour out.
  3. Accept the `POST_NOTIFICATIONS` prompt.
  4. Lock the screen and wait for the T-1h reminder.
  5. Reboot the emulator and confirm the schedule survives
     (`ScheduledNotificationBootReceiver`).
- **M2 (remainder)** before declaring the milestone fully
  shipped (see `BRD §11`):
  - **Pin to home-screen widget** (Android first, iOS Phase 2):
    bring in `home_widget`, register a Glance receiver in
    `android/`, and feed it the pinned event's countdown. The
    `togglePin` plumbing in `EventRepository` is already in
    place; only the platform-side renderer is missing. Wire
    `NotificationScheduler` to also re-render the widget when
    a reminder fires (or on every event mutation).
- **CI**: `.github/workflows/ci.yml` running `flutter analyze` +
  `flutter test --coverage` on push & PR (Handoff §4 Step 4).
  Must include a `dart run build_runner build` step before tests.
- Add `workmanager` for backgrounded notification re-evaluation
  at M3 (catches recurring events that the user never opens the
  app to refresh).

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
flutter test               # expect: All tests passed! (79+ tests)
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

### Step 4 — CI (M0, can run in parallel)
10. Add `.github/workflows/ci.yml`:
    - On `push` and `pull_request`: `flutter analyze`, `flutter test
      --coverage`, upload coverage as artifact.
    - Cache `~/.pub-cache` keyed on `pubspec.lock`.

### Step 5 — Subsequent milestones
Follow `BRD §11` for M2 → M9. Each milestone should ship as its own PR
series and update this Handoff document's `Current Status`.

**Pointer for the next session**: only one production task is
left in **M2 — Event Countdown** — the Android home-screen
widget. Notification scheduling is already wired end-to-end.
Recommended order:
1. **Smoke-test on the Android emulator**. Build now works:
   `flutter build apk --debug` produces
   `build/app/outputs/flutter-apk/app-debug.apk`. With the
   emulator running, `flutter install -d emulator-5554` (or
   just `flutter run -d emulator-5554`). Then create an event
   one hour out, accept the `POST_NOTIFICATIONS` prompt, lock
   the screen, and confirm the T-1h reminder fires. Also
   reboot the emulator to confirm
   `ScheduledNotificationBootReceiver` re-arms the schedule.
2. **Home-screen widget (Android)**: `home_widget` plugin +
   AndroidManifest `<receiver>` + a Glance composable. Widget
   reads the pinned event from Drift in a background isolate
   (use `home_widget`'s `registerBackgroundCallback`).
   Re-render on `togglePin`, on every event mutation, and on
   every notification firing so the day count stays fresh. Wire
   `NotificationScheduler` (or a new `WidgetUpdater` peer in
   `core/`) into the same composition root.
3. **`HomeShellPage` polish** (optional): consider adding a
   "Pinned event" hero card to the Life tab so the home screen
   feels coherent with the widget.
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
| Seed assets | `assets/seed/` |
| Test root | `test/` |

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
