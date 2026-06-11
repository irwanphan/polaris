# Business Requirements Document — Polaris

> **Version:** 0.1.0 (Draft)
> **Last updated:** 2026-06-12
> **Author:** Irwan Phan (Phandarian Studio)
> **Status:** Pre-development / Scaffolding stage

---

## 1. Executive Summary

**Polaris** is a personal countdown companion mobile application that helps users
live more intentionally by visualizing the finiteness of time. The flagship
concept is **"Sisa Hariku di Dunia"** (My remaining days on earth) — a
life-expectancy-based countdown that motivates rather than alarms.

Beyond the life countdown, Polaris also tracks lifestyle data (sleep, exercise,
smoking, etc.) and provides personalized recommendations to help users improve
their habits — closing the loop between awareness and action.

The app is built mobile-first with home screen widgets and lock screen
integration so the message is **always visible** without opening the app.

### Vision Statement
> "Make every day count — by gently reminding people how precious time is, and
> giving them tools to spend it well."

### Tagline
**"Your countdown companion."**

---

## 2. Stakeholders

| Role | Name / Entity |
|---|---|
| Product Owner | Irwan Phan |
| Studio / Publisher | Phandarian |
| Initial Developer | Irwan Phan (solo) |
| Target Market (MVP) | Indonesia (Bahasa Indonesia + English) |
| Distribution (Phase 1) | Google Play Store |
| Distribution (Phase 2) | Apple App Store |

---

## 3. Product Identity

| Attribute | Value |
|---|---|
| Display Name | **Polaris** |
| Project Folder | `~/TurbidDev/project-polaris` |
| Pubspec Project Name | `polaris` |
| Application/Bundle ID | `com.phandarian.polaris` |
| Studio Domain | `phandarian` (under `com.` namespace) |
| Description | "Polaris — your countdown companion. Track meaningful days, lifestyle, and life moments." |
| Primary Languages | Bahasa Indonesia, English |
| Target SDK (Android) | API 34 (Android 14) |
| Min SDK (Android) | API 23 (Android 6.0) |
| Target iOS | iOS 16+ (for Lock Screen Widgets) |
| Min iOS | iOS 14 (without lock screen widget) |

---

## 4. Problem Statement & Opportunity

### Problem
- Most reminder/countdown apps focus on **events** but ignore the **bigger picture**: a person's finite lifetime.
- Existing life-countdown apps tend to be **morbid or gimmicky**, lacking actionable insights.
- Lifestyle tracking apps (Apple Health, Samsung Health) are **passive data viewers** without strong behavioral framing.

### Opportunity
Combine three angles into one cohesive product:
1. **Mortality awareness** as motivation (handled with care, not fear)
2. **Event countdowns** for everyday usefulness (deadlines, birthdays, trips)
3. **Lifestyle improvement loop** linking habits to estimated longevity

This positions Polaris uniquely vs. competitors:

| App | Life Countdown | Event Countdown | Lifestyle | Widget |
|---|---|---|---|---|
| WeCroak | ✓ (morbid) | ✗ | ✗ | ✗ |
| Final Countdown | ✗ | ✓ | ✗ | Basic |
| Apple Health | ✗ | ✗ | ✓ | ✓ |
| **Polaris** | ✓ (motivational) | ✓ | ✓ | ✓ |

---

## 5. Core Features (MVP — Phase 1)

### 5.1 Life Countdown ("Sisa Hariku")
- User enters: birth date, biological sex, country (default: Indonesia)
- App computes estimated remaining days using **public life expectancy tables**
  (WHO Global Health Observatory + BPS Indonesia)
- Modifier: lifestyle factors adjust the estimate (smoking +/-, exercise, sleep)
- Display modes:
  - Days remaining (default)
  - Weeks / months / years
  - Percentage of life lived (Sahil Bloom style)
- **Optional hide** for users who feel anxiety
- **Disclaimer**: "Estimation only, not medical prediction"
- **Tone**: motivational micro-copy, never morbid

### 5.2 Event Countdown
- CRUD multiple events (birthday, wedding, exam, trip, deadline)
- Custom: title, target date/time, color, icon, note
- Recurring: yearly / monthly / one-time
- Pinning: pin favorite event to widget
- Pre-event notifications: T-7d, T-1d, T-1h (configurable)

### 5.3 Home Screen Widget (Android first, iOS later)
- Small widget: 1 countdown (life or pinned event)
- Medium widget: 2-3 countdowns
- Large widget: countdown + today's lifestyle summary
- Tap to open relevant screen in app

### 5.4 Lock Screen Integration
- **iOS (16+)**: native Lock Screen Widget (circular, rectangular, inline)
- **Android**: always-on display via persistent notification (lock screen widgets deprecated on stock Android since 5.0)

### 5.5 Lifestyle Logging
- Daily inputs:
  - Sleep: bedtime, wake time (or manual hours)
  - Exercise: minutes, type (light/moderate/vigorous)
  - Smoking: yes/no + cigarettes count
  - Alcohol: drinks/day
  - Optional: mood, stress, water intake
- Quick log via widget tap (Phase 2)
- Optional sync with HealthKit / Health Connect

### 5.6 Recommendation Engine (Rule-based for MVP)
- Daily insight card on home screen
- Examples:
  - "You slept 5h average this week. Adults need 7-9h. Try going to bed 30 min earlier."
  - "Smoking 10/day reduces life expectancy ~10 years. Consider tapering."
  - "Great job! 5 days of exercise this week — keep it up."
- Rules engine in pure Dart (testable)
- Phase 2: on-device ML (Gemini Nano / Core ML)

---

## 6. Future Features (Phase 2+)

- Cloud sync (multi-device) — Supabase or Firebase
- Live Activities (iOS) — real-time countdown on lock screen
- Apple Watch / Wear OS companion
- Social: optional share milestones
- Streak gamification
- Export data (CSV, JSON)
- Themes / customization marketplace
- Premium tier (more widgets, custom themes, AI insights)

---

## 7. Non-Functional Requirements

### 7.1 Performance
- App cold start: < 2 seconds
- Widget refresh: < 500ms
- Countdown update: every minute on app, every 15 min on widget

### 7.2 Privacy & Data
- **Offline-first**: all data local by default (Drift SQLite)
- No data collection without explicit opt-in
- No third-party analytics in MVP (consider PostHog self-hosted later)
- Health data never leaves device unless cloud sync enabled (Phase 2)
- GDPR / UU PDP (Indonesia data protection law) compliant

### 7.3 Accessibility
- Min text size scaling support
- VoiceOver / TalkBack labels for all interactive elements
- Color contrast WCAG AA minimum
- Reduce motion option (disable animations)

### 7.4 Localization
- Bahasa Indonesia (primary)
- English (secondary)
- Date formats respect locale
- ARB files for translations

---

## 8. Tech Stack

### Application Layer
| Concern | Choice | Rationale |
|---|---|---|
| Framework | Flutter 3.44.1 stable | Single codebase, great widget plugin ecosystem |
| Language | Dart 3.x | Sound null safety, modern syntax |
| State Mgmt | Riverpod | Compile-safe, testable, scales well |
| Navigation | go_router | Declarative, deep-link friendly |
| Local DB | Drift | SQL + type-safe, reactive streams |
| Settings | shared_preferences | Lightweight key-value |
| HTTP | dio | Interceptors, cancellation |
| DI | Riverpod providers | No separate DI lib needed |
| Logging | logger | Pretty, level-based |

### Native Integration (mandatory native code)
| Need | iOS | Android |
|---|---|---|
| Home Widget | Swift + WidgetKit + SwiftUI | Kotlin + Jetpack Compose Glance |
| Lock Screen | WidgetKit Lock Screen Widget | Persistent Notification |
| Health Data | HealthKit (via `health` plugin) | Health Connect (via `health` plugin) |
| Background | BGTaskScheduler | WorkManager (via `workmanager`) |

### Key Flutter Packages
- `flutter_riverpod` — state management
- `go_router` — routing
- `drift` + `drift_flutter` — local DB
- `home_widget` — Flutter ↔ widget bridge
- `health` — HealthKit / Health Connect
- `flutter_local_notifications` — local notifications
- `workmanager` — background tasks (Android-focused)
- `intl` — i18n & date formatting
- `freezed` + `freezed_annotation` — immutable models
- `json_serializable` — JSON codegen
- `flutter_launcher_icons` — app icon gen
- `flutter_native_splash` — splash screen gen

### Tooling
- Build: `build_runner` (codegen)
- Lint: `flutter_lints` + custom rules
- Testing: built-in `flutter_test` + `mocktail`

---

## 9. Architecture

Polaris uses a **feature-based modular architecture** layered on top of Clean
Architecture principles. Each feature is self-contained and depends inward
(UI → Application → Domain ← Data). The folder layout is optimized for SOLID
adherence and for parallel work on multiple features without merge conflicts.

### 9.1 Folder Structure (feature-based + SOLID)

```text
lib/
├── main.dart                         # Entry point (bootstrapping only)
├── app/                              # App-wide composition root
│   ├── app.dart                      # Root MaterialApp.router
│   ├── router.dart                   # go_router configuration
│   ├── theme/                        # ThemeData, color tokens, typography
│   │   ├── app_theme.dart
│   │   ├── color_tokens.dart
│   │   └── text_styles.dart
│   └── bootstrap.dart                # runZonedGuarded, error reporting, DI init
│
├── core/                             # Framework-agnostic shared kernel
│   ├── constants/                    # App-wide constants (no business logic)
│   ├── errors/                       # Failure, AppException sealed classes
│   ├── result/                       # Result<T,E> / Either equivalent
│   ├── utils/                        # date_x.dart, duration_x.dart, etc.
│   ├── extensions/                   # Dart extensions on built-in types
│   ├── logging/                      # Logger facade (wraps `logger` package)
│   └── platform/                     # Platform-channel wrappers
│
├── shared/                           # Cross-feature reusable widgets
│   ├── widgets/                      # Buttons, cards, sheets (atomic + molecules)
│   ├── animations/                   # Reusable animation builders
│   └── localization/                 # Generated l10n + helpers
│
├── data/                             # Cross-feature data infrastructure
│   ├── database/                     # Drift database, DAOs base
│   │   ├── app_database.dart
│   │   └── tables/
│   ├── preferences/                  # SharedPreferences facade
│   ├── network/                      # Dio client, interceptors
│   └── seed/                         # Bundled JSON (life expectancy tables)
│
└── features/                         # One folder per business capability
    ├── life_countdown/
    │   ├── domain/                   # Pure Dart, no Flutter imports
    │   │   ├── entities/             # LifeProfile, LifeEstimate
    │   │   ├── value_objects/        # Sex, CountryCode, DateOfBirth
    │   │   ├── repositories/         # Abstract LifeProfileRepository
    │   │   └── usecases/             # ComputeRemainingDays, AdjustForLifestyle
    │   ├── data/
    │   │   ├── models/               # DTOs + Drift rows
    │   │   ├── datasources/          # Local (Drift) / Remote (future)
    │   │   └── repositories/         # LifeProfileRepositoryImpl
    │   ├── application/              # Riverpod providers, state notifiers
    │   │   ├── life_countdown_controller.dart
    │   │   └── providers.dart
    │   └── presentation/
    │       ├── pages/                # LifeCountdownPage
    │       ├── widgets/              # CountdownDial, LifeProgressBar
    │       └── strings.dart          # Feature-scoped micro-copy keys
    │
    ├── event_countdown/              # Same internal shape
    ├── lifestyle/                    # Sleep, exercise, smoking, alcohol logging
    ├── recommendations/              # Rule-based insight engine
    ├── widgets_bridge/               # home_widget channel + payload builders
    ├── notifications/                # flutter_local_notifications wiring
    ├── settings/                     # User preferences, locale, theme
    └── onboarding/                   # First-run flow + birth date / sex capture

android/
├── app/                              # Standard Flutter Android module
│   └── src/main/kotlin/com/phandarian/polaris/
│       └── MainActivity.kt
└── polaris_widget/                   # Glance widget module (separate Gradle module)
    └── src/main/kotlin/com/phandarian/polaris/widget/
        ├── PolarisWidget.kt
        ├── PolarisWidgetReceiver.kt
        └── data/                     # Reads home_widget shared prefs

ios/
├── Runner/                           # Standard Flutter iOS app target
└── PolarisWidget/                    # WidgetKit extension target
    ├── PolarisWidget.swift
    ├── PolarisWidgetBundle.swift
    └── Lockscreen/                   # iOS 16+ lock-screen variants

test/
├── unit/
│   ├── core/
│   └── features/<feature>/{domain,application,data}/
├── widget/
│   └── features/<feature>/presentation/
└── integration/
    └── flows/                        # e.g. onboarding_flow_test.dart
```

### 9.2 Layering & Dependency Rule

```
presentation ──▶ application ──▶ domain ◀── data
        (widgets)    (Riverpod)    (pure)    (Drift/HTTP)
```

- **`domain`** is pure Dart. No `flutter`, no `drift`, no `dio` imports.
- **`data`** implements `domain` repository interfaces. Knows about Drift, Dio,
  shared_preferences, platform channels.
- **`application`** orchestrates use cases via Riverpod providers, exposes
  immutable state to presentation. Never imports `data` directly — only
  through providers wired in the composition root.
- **`presentation`** consumes Riverpod providers, renders widgets. Never
  touches `data` directly.
- **`core`** and **`shared`** may be imported anywhere; they must never import
  from `features/`.
- **`features/<x>`** may not import from **`features/<y>`** — cross-feature
  communication goes through `core` events or `application`-level providers
  declared in the composition root.

This rule is enforced by lint configuration (`analysis_options.yaml`) and code
review.

### 9.3 SOLID Mapping

| Principle | How Polaris applies it |
|---|---|
| **S — Single Responsibility** | Each use case is one class (`ComputeRemainingDays`, `LogSleepEntry`). Widgets render, controllers orchestrate, repositories persist. No "manager" classes. |
| **O — Open/Closed** | `RecommendationRule` is an abstract base; new rules (e.g. `WaterIntakeRule`) are added without modifying the engine. Same for `LifeExpectancyDataSource` (WHO table now, BPS later, ML model in Phase 2). |
| **L — Liskov Substitution** | Repository implementations (`LocalLifeProfileRepository`, future `CloudLifeProfileRepository`) honor the same abstract contract — controllers depend on the abstraction, not the implementation. |
| **I — Interface Segregation** | Repositories are split per aggregate (`EventRepository`, `LifestyleRepository`) rather than one fat `AppRepository`. DAOs in Drift are likewise per-table. |
| **D — Dependency Inversion** | High-level controllers depend on `domain` abstractions. Concrete `data` implementations are bound via Riverpod `Override`s in `app/bootstrap.dart`, enabling test doubles without rewriting consumers. |

### 9.4 State Management Conventions (Riverpod)

- One `Notifier` (or `AsyncNotifier`) per feature controller.
- Providers live in `features/<x>/application/providers.dart`.
- All providers are **declared `final`**, top-level, and use code generation
  (`@riverpod`) once `riverpod_generator` is added — until then, manual
  declaration with explicit types.
- UI uses `ref.watch` for reactive reads, `ref.read` only inside callbacks.
- Background work (widget refresh, notification scheduling) runs in
  `workmanager` / `BGTaskScheduler` handlers, which read providers via a
  `ProviderContainer` instantiated in the entry point.

### 9.5 Native ↔ Flutter Bridge

- **`home_widget`** package writes shared key-value data the native widgets
  read on render. Polaris keys (namespaced under `polaris.`):
  - `polaris.life.remainingDays:int`
  - `polaris.life.percentLived:double`
  - `polaris.event.pinned.title:string`
  - `polaris.event.pinned.targetEpochMs:int`
  - `polaris.lifestyle.today.sleepHours:double`
- Background refresh cadence: every 15 minutes (Android `WorkManager`),
  every ~30 minutes (iOS `BGAppRefreshTask` — OS decides).
- Tap intents deep-link via `go_router` paths
  (e.g. `polaris://life`, `polaris://event/<id>`).

### 9.6 Error Handling Strategy

- Domain operations return `Result<T, Failure>` (sealed) instead of throwing.
- Infrastructure exceptions are caught at the `data` boundary and mapped to
  `Failure` subtypes (`NoLifeExpectancyDataFailure`, `InvalidBirthDateFailure`).
- UI renders failures via a shared `ErrorView` widget; non-recoverable errors
  are logged through the `core/logging` facade.

### 9.7 Testing Strategy

| Layer | Tooling | What to test |
|---|---|---|
| Domain | `flutter_test` (pure Dart) | Use cases, value-object invariants, recommendation rules |
| Application | `flutter_test` + `ProviderContainer` | Controller state transitions, provider overrides |
| Data | `flutter_test` + in-memory Drift | Repository round-trips, schema migrations |
| Presentation | `flutter_test` widget tests | Golden tests for countdown widget, sheet flows |
| Integration | `integration_test` | Onboarding → first widget render |

Target coverage MVP: **≥ 70 %** on `domain` + `application`, lower bar on
`presentation` (use goldens instead of % targets).

---

## 10. Data Model

### 10.1 Core Entities (domain-level)

```text
LifeProfile
  - id: Uuid
  - birthDate: Date
  - sex: Sex (male | female | undisclosed)
  - countryCode: CountryCode (ISO-3166-1 alpha-2, default "ID")
  - hideLifeCountdown: bool
  - createdAt / updatedAt: DateTime

LifestyleProfile (1:1 with LifeProfile)
  - smokerStatus: SmokerStatus (never | former | current)
  - cigarettesPerDay: int?
  - alcoholDrinksPerWeek: int?
  - exerciseMinutesPerWeek: int?
  - averageSleepHours: double?

DailyLog
  - id: Uuid
  - date: Date (unique per profile)
  - sleepHours: double?
  - bedtime / wakeTime: TimeOfDay?
  - exerciseMinutes: int?
  - exerciseIntensity: Intensity?
  - cigarettesCount: int?
  - alcoholDrinks: int?
  - mood: int? (1–5)
  - waterMl: int?

Event
  - id: Uuid
  - title: String
  - targetAt: DateTime (with timezone)
  - colorHex: String
  - iconKey: String
  - note: String?
  - recurrence: Recurrence (none | yearly | monthly | weekly)
  - isPinnedToWidget: bool
  - createdAt / updatedAt: DateTime

NotificationSchedule
  - id: Uuid
  - eventId: Uuid (FK Event)
  - offsetMinutesBeforeTarget: int  // e.g. 7d = 10080
  - isEnabled: bool

RecommendationCard (derived, not persisted)
  - id: String (rule key + date)
  - severity: Severity (info | nudge | warning)
  - titleKey / bodyKey: l10n keys
  - actionRoute: String?
  - generatedAt: DateTime

LifeExpectancyEntry (seed data, read-only)
  - countryCode: CountryCode
  - sex: Sex
  - year: int (table publication year)
  - expectancyYears: double
  - source: String  // "WHO-GHO-2024" | "BPS-2024"
```

### 10.2 Storage Mapping (Drift)

- Each entity above maps to one Drift table (snake_case).
- Seed data (`LifeExpectancyEntry`) is bundled as a JSON asset under
  `data/seed/` and loaded on first run into a read-only table.
- All timestamps stored as UTC `INTEGER` (epoch ms); presentation layer
  converts to local timezone.
- Schema version starts at `1`; migrations live in
  `data/database/migrations/`.

---

## 11. Roadmap & Milestones

| Milestone | Target | Scope |
|---|---|---|
| **M0 — Foundation** | Week 1 | Scaffolding, lint, theme, routing, Drift bootstrap, CI workflow, BRD locked |
| **M1 — Life Countdown Vertical Slice** | Week 2 | Onboarding (birth date + sex + country), life expectancy lookup, daily-updating countdown screen, unit tests |
| **M2 — Event Countdown** | Week 3 | CRUD events, pin to widget, local notifications T-7d/T-1d/T-1h |
| **M3 — Android Home Widget** | Week 4 | Glance widget (small + medium), `home_widget` bridge, WorkManager refresh, deep links |
| **M4 — Lifestyle Logging** | Week 5 | Daily-log entry sheet, history view, Drift schema v2 |
| **M5 — Recommendation Engine v1** | Week 6 | Rule-based engine, home-screen insight card, ≥ 6 starter rules |
| **M6 — Polish & Beta** | Week 7 | a11y pass, l10n (ID + EN), reduce-motion, golden tests, internal Play Store track |
| **M7 — Public Beta (Android)** | Week 8 | Open beta on Play Store, telemetry opt-in, feedback intake |
| **M8 — iOS Parity** | Phase 2 | iOS Runner verification, WidgetKit Lock Screen Widget |
| **M9 — Cloud Sync** | Phase 2 | Supabase/Firebase backend, account opt-in, multi-device |

Velocity assumption: solo developer, ~10 focused hours per week.

---

## 12. Success Metrics

### 12.1 Product KPIs (post-launch)
- **D1 retention ≥ 50 %**, D7 ≥ 30 %, D30 ≥ 20 %
- ≥ **40 %** of active users add at least one custom event within 3 days
- ≥ **30 %** of active users install the home-screen widget
- ≥ **25 %** of active users log lifestyle data ≥ 3 days per week
- App Store / Play Store rating ≥ **4.4**

### 12.2 Technical KPIs
- Crash-free sessions ≥ **99.5 %**
- Cold start p95 < 2 s on mid-tier Android (e.g. Pixel 5a)
- Widget refresh failure rate < 1 %
- Test coverage on `domain` + `application` ≥ **70 %**

### 12.3 North-Star Metric
**Weekly Active Users who both viewed the life countdown AND logged lifestyle
data at least once that week.** Captures the awareness-to-action loop the
product is designed to create.

---

## 13. Risks & Mitigations

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| R1 | Life-countdown framing triggers anxiety / bad reviews | Medium | High | Optional hide setting; motivational micro-copy reviewed by editor; in-app disclaimer; opt-in onboarding |
| R2 | Life-expectancy estimation perceived as medical advice | Low | High | Clear disclaimer on every surface; cite sources (WHO, BPS); no health claims in store listing |
| R3 | Native widget complexity blocks MVP (Glance + WidgetKit) | Medium | Medium | Ship Android-only widget in M3, defer iOS widget to Phase 2; keep widget data layer thin |
| R4 | Solo-developer velocity slippage | High | Medium | Vertical slices per milestone; defer Phase 2 features ruthlessly |
| R5 | Drift schema migrations break user data in beta | Medium | High | Migration tests on every schema bump; backup-on-migrate; semantic version of schema in shared prefs |
| R6 | Privacy regulation drift (UU PDP) | Low | Medium | Offline-first default; review Privacy Policy quarterly; minimal data collection |
| R7 | Background refresh unreliable on aggressive OEM ROMs (Xiaomi/Oppo) | High | Medium | Document known limitations; rely on widget tap-to-refresh fallback; show "last updated" timestamp |
| R8 | Flutter major upgrade introduces breakages | Medium | Low | Pin Flutter version in `fvm` config (Phase 2); upgrade in a branch with full test pass |

---

## 14. Acceptance Criteria (MVP)

A build is considered MVP-complete when **all** of the following hold:

### 14.1 Functional
- [ ] User can complete onboarding (birth date, sex, country) in < 60 seconds.
- [ ] Life countdown screen displays remaining days, weeks, months, and
      percentage lived, all updated at least once per minute while visible.
- [ ] User can hide the life countdown via a settings toggle without data loss.
- [ ] User can create, edit, delete, and pin at least one event.
- [ ] Event reminders fire at the configured offsets (T-7d, T-1d, T-1h) on
      both fresh installs and after a device reboot.
- [ ] Android home-screen widget (small + medium) installs, renders the pinned
      countdown, and updates within 15 minutes of underlying data changes.
- [ ] User can log a daily lifestyle entry (sleep, exercise, smoking, alcohol)
      in < 30 seconds, and view at least the last 7 days.
- [ ] At least 6 recommendation rules fire correctly against fixture data and
      surface as cards on the home screen.

### 14.2 Non-Functional
- [ ] All user-facing strings exist in both `id` and `en` ARB files.
- [ ] All interactive elements have semantic labels for TalkBack.
- [ ] App passes WCAG AA contrast in both light and dark themes.
- [ ] No network calls are made unless the user opts into a Phase-2 feature.
- [ ] `flutter analyze` returns zero issues with the project lint profile.
- [ ] Cold start on a Pixel 5a (or equivalent) is < 2 s, p95.

### 14.3 Release-readiness
- [ ] Privacy Policy and Terms published and linked from Settings.
- [ ] Play Store listing assets (icon, feature graphic, screenshots) prepared.
- [ ] Internal testing track green for ≥ 7 days with no Severity-1 bugs.

---

## 15. Glossary

| Term | Definition |
|---|---|
| **BRD** | Business Requirements Document (this file) |
| **Polaris** | Product name; also the North Star, symbolizing direction & time |
| **Sisa Hariku** | "My remaining days" — the life-countdown feature |
| **Phandarian** | Studio / publisher of Polaris |
| **MVP** | Minimum Viable Product — see §14 for criteria |
| **Vertical slice** | A thin end-to-end feature spanning data → UI |
| **Glance** | Jetpack Compose for Android home-screen widgets |
| **WidgetKit** | Apple framework for iOS home & lock-screen widgets |
| **Health Connect** | Android system health data store (replaces Google Fit APIs) |
| **HealthKit** | Apple system health data store |
| **WHO GHO** | World Health Organization — Global Health Observatory data |
| **BPS** | Badan Pusat Statistik (Indonesia) — official statistics agency |
| **UU PDP** | Undang-Undang Pelindungan Data Pribadi (Indonesia data-protection law) |
| **SOLID** | Single-responsibility, Open/closed, Liskov, Interface-segregation, Dependency-inversion |

---

## 16. Change Log

| Version | Date | Author | Notes |
|---|---|---|---|
| 0.1.0 | 2026-06-12 | Irwan Phan | Initial draft (§§1–8) |
| 0.2.0 | 2026-06-12 | Cursor AI session | Completed §9 Architecture, added §§10–15 |
