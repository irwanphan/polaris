# Handoff Document — Polaris

> **Purpose:** Hand this file to a new AI chat session (or a new collaborator)
> to continue development without losing context.
> **Last updated:** 2026-06-12 by Cursor AI session — **M1 Life Countdown vertical slice complete**

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

## 2. Current Status (As of 2026-06-12, end of M1)

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

### In Progress
- None — clean checkpoint at the end of M1.

### Not Started (next on deck)
- **M2 — Event Countdown** (see `BRD §11`):
  - Drift schema v1: `LifeProfile` table (migrated from
    SharedPreferences) + `Event` + `NotificationSchedule` tables.
  - CRUD events; pin to widget flag; recurrence (none / yearly /
    monthly / weekly).
  - `flutter_local_notifications` integration + reminder scheduler
    (T-7d / T-1d / T-1h, configurable).
  - Replace `LauncherPage` with a `HomeShellPage` (bottom nav).
- **CI**: `.github/workflows/ci.yml` running `flutter analyze` +
  `flutter test --coverage` on push & PR (Handoff §4 Step 4).
- Add `home_widget`, `workmanager` at M3.

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
flutter pub get            # resolve current pubspec (passes with defaults)
flutter analyze            # expect: No issues found!
flutter test               # expect: All tests passed!
```

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

**Pointer for the next session**: start at **M2 — Event Countdown**.
Recommended order:
1. Introduce Drift schema v1 in `lib/data/database/` and migrate the
   existing `LifeProfile` from SharedPreferences into a typed row.
2. Add `Event` + `NotificationSchedule` tables; CRUD use cases.
3. Wire `flutter_local_notifications` with `permission_handler`
   prompts.
4. Replace `LauncherPage` with a `HomeShellPage` (bottom navigation:
   Life / Events / Lifestyle / Settings).
5. Update widget + integration tests; keep `flutter analyze` clean.

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
| Entry point | `lib/main.dart` (currently template) |
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
