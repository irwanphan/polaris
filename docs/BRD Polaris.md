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

### Folder Structure (feature-based + SOLID)