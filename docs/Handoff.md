# Handoff Document — Polaris

> **Purpose:** Hand this file to a new AI chat session (or a new collaborator)
> to continue development without losing context.
> **Last updated:** 2026-06-12 by Cursor AI session

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

## 2. Current Status (As of 2026-06-12)

### Completed
- Flutter 3.44.1 stable installed at `~/TurbidDev/flutter/`.
  - Verified: `Flutter 3.44.1 • channel stable` / `Dart 3.12.1` /
    `DevTools 2.57.0` / Framework revision `924134a44c`.
- PATH configured in `~/.zshrc` so `flutter` resolves to
  `/Users/irwanphan/TurbidDev/flutter/bin/flutter`.
- Flutter project scaffolded at `~/TurbidDev/project-polaris/` via
  `flutter create` with:
  - `name: polaris`
  - bundle / application ID: `com.phandarian.polaris`
  - default Android + iOS runners
- Git repository initialized and pushed to GitHub:
  - Remote: `https://github.com/irwanphan/polaris.git`
  - Branch: `main`
  - Commits so far: `c487325 first commit`, `d72edcb project setup`
- `pubspec.yaml` minimally configured (description, version `1.0.0+1`,
  Dart SDK `^3.12.1`).
- BRD `docs/BRD Polaris.md` drafted to **v0.2.0** (sections 1–16 complete,
  including Architecture, Data Model, Roadmap, Risks, Acceptance Criteria,
  Glossary).
- This handoff document.

### In Progress
- None — at a clean checkpoint, working tree is clean.

### Not Started (next on deck)
- Dependency wiring in `pubspec.yaml` (Riverpod, go_router, Drift, etc.).
- Replace template `lib/main.dart` with the architecture described in
  `BRD §9.1` (composition root + `core` + `shared` + first feature shell).
- Lint hardening in `analysis_options.yaml` (enforce
  `avoid_relative_lib_imports`, `prefer_const_constructors`,
  custom rule against cross-feature imports).
- Theme tokens + `MaterialApp.router` bootstrap.
- CI workflow (`.github/workflows/ci.yml`) running `flutter analyze` +
  `flutter test`.
- First vertical slice: **Life Countdown** (M1 in `BRD §11`).

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

### Step 1 — Dependencies & Lints (M0)
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

### Step 2 — Composition root & Architecture skeleton (M0)
4. Create folder structure per `BRD §9.1` (`app/`, `core/`, `shared/`,
   `data/`, `features/`).
5. Implement `app/bootstrap.dart`, `app/app.dart`, `app/router.dart`,
   `app/theme/` (color tokens, text styles, light + dark `ThemeData`).
6. Replace `lib/main.dart` with a thin entry that calls `bootstrap()`.
7. Add a placeholder home page that routes via `go_router` to confirm
   wiring.

### Step 3 — First vertical slice: Life Countdown (M1)
8. Build the `features/life_countdown/` slice end-to-end:
   - `domain`: `LifeProfile`, `LifeEstimate`, `ComputeRemainingDays` use
     case (pure functions, fully unit-tested).
   - `data`: seed `life_expectancy.json` (start with WHO 2024 + BPS 2024
     headline numbers for `ID`, fallback to a global average), Drift schema
     v1, repository implementation.
   - `application`: `LifeCountdownController` exposing `AsyncValue` state.
   - `presentation`: onboarding page (birth date + sex + country),
     countdown page with day / week / month / percent toggles.
9. Add golden + widget tests for the countdown page.

### Step 4 — CI (M0, can run in parallel)
10. Add `.github/workflows/ci.yml`:
    - On `push` and `pull_request`: `flutter analyze`, `flutter test
      --coverage`, upload coverage as artifact.
    - Cache `~/.pub-cache` keyed on `pubspec.lock`.

### Step 5 — Subsequent milestones
Follow `BRD §11` for M2 → M9. Each milestone should ship as its own PR
series and update this Handoff document's `Current Status`.

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
