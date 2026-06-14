# Auth & Cloud Sync Strategy — Polaris

> **Status:** Decision captured 2026-06-14. **Implementation deferred to
> Phase 2 (M9 per BRD §6).** Polaris MVP remains offline-first; this
> document exists so the decision context is preserved and the eventual
> migration is mechanical, not exploratory.
>
> **Decision owner:** Irwan Phan (Phandarian)
> **Last updated:** 2026-06-14

---

## 1. Context

Polaris is **offline-first by design** (BRD §7.2). The MVP scope (M1–M6)
ships zero networked features — all user data lives in local Drift
SQLite + SharedPreferences. This is a deliberate posture, not a
short-cut: the BRD argues that for a "Sisa Hariku" app dealing with
deeply personal data (date of birth, lifestyle habits, mood logs), the
default should be "your phone, no server".

Cloud sync is listed in BRD §6 "Future Features (Phase 2+)" and called
out as **M9 — Cloud Sync** in the milestone plan. The future-state is
not "every user must sign in" but rather "**optional** sign-in unlocks
multi-device sync + backup". Local-only must remain a first-class mode
forever.

This ADR captures the chosen backend stack for that eventual Phase 2
migration so we stop re-litigating it every time the question comes up.

## 2. Options evaluated

Five candidates were considered in detail. Full comparison below; the
short version is in §3.

### 2.1 NeonDB + custom API (rejected as standalone)

Neon is excellent serverless Postgres. **But Neon alone cannot be the
backend for a mobile app** — Flutter clients should never connect
directly to a database over the public internet (credential leakage,
no business-logic gating, no auth surface).

To use Neon you must additionally build:
- Auth service (email/password, OAuth, password reset, session/JWT)
- REST or GraphQL API gateway hosted somewhere (Railway, Fly.io, …)
- Email provider integration (verification, reset) — SendGrid/Resend
- Sync orchestration (conflict resolution, retry, idempotency)
- Operational overhead in perpetuity (patches, monitoring)

Estimated effort: **2-3 weeks of focused work + ongoing maintenance**.
That is the wrong shape for a solo-dev mobile project.

**When Neon would make sense for Polaris:** if there were a sister web
app at Phandarian that already used Neon and we wanted one DB across
the portfolio, or if the recommendation engine moved server-side
(which the BRD explicitly says it should NOT — §5.6 keeps it in pure
Dart on-device).

### 2.2 Supabase (chosen)

Postgres + Auth + Storage + Realtime + Row-Level Security (RLS) +
Edge Functions in one BaaS. Singapore region is ~50ms from Indonesia.
Open source under the hood — exit ramp via `pg_dump` to bare Postgres
is straightforward.

- **Setup time:** ~1 day to working auth + DB.
- **Year 1 cost:** $0 (free tier covers 500MB DB / 50K MAU / 5GB
  storage — more than sufficient for beta).
- **Year 2 worst case:** $25/mo Pro plan + usage if we cross 50K MAU.
- **Flutter SDK:** `supabase_flutter` is the official, battle-tested
  package — widely used in production Flutter apps.
- **Schema mapping:** Drift is relational SQL; Supabase is Postgres.
  Direct 1:1 mirror. No impedance mismatch.

### 2.3 Firebase / Firestore (rejected)

Strong auth, mature FlutterFire ecosystem. **Rejected because Firestore
is a document database** and Polaris's Drift schema is heavily
relational (events have a recurrence enum + a notification fanout;
lifestyle logs join against category metadata; future features want
joins). Migrating Drift → Firestore would force a schema redesign and
permanent vendor lock-in — there is no clean exit ramp from Firestore
the way there is from Supabase.

### 2.4 PocketBase self-hosted (strong runner-up)

Single Go binary with auth + SQLite + admin UI + realtime + storage,
hosted on a $5-10/mo VPS. Best in class for:
- **Privacy story:** data on a Phandarian-owned server in Indonesia
  (Biznet JKT, IDCloudHost SBY) — UU PDP-friendly framing.
- **Latency:** ~10-15ms from Jakarta vs ~50ms for AWS SG (Supabase).
- **Cost predictability:** flat ~$60-120/year regardless of growth.
- **Full data ownership:** no third-party host has access.

**Trade-off:** ~3-5 hours/month of operational work (OS patches, cert
renewal, backup verification) — a perpetual time cost. For a solo dev
in MVP phase that adds up to 1-2 weeks of foregone feature work per
year. Setup time also longer (~3-5 days for VPS + Docker + Caddy +
DNS + cron backup + first deploy).

PocketBase is the right answer if Polaris graduates into a **serious
commercial product** where the privacy story matters as a marketing
differentiator and operational maturity is worth the investment. For
the current "side project / portfolio piece" framing it loses to
Supabase on time-to-launch.

### 2.5 Appwrite (rejected)

Middle ground between Supabase and PocketBase (open-source + cloud
option). Less mature Flutter SDK than either. Smaller community.
Skipping.

## 3. Decision

**Use Supabase free tier when Phase 2 (M9) begins.**

| Dimension | Choice |
|---|---|
| Backend | Supabase (managed, SG region) |
| Database | Postgres (managed by Supabase) |
| Auth | Supabase Auth — email + Google OAuth + Apple OAuth (iOS later) |
| Per-user isolation | Postgres Row-Level Security |
| Realtime | Postgres CDC over WebSocket (used selectively) |
| Backup | Supabase daily snapshot (included) |
| Cost target | $0 in Year 1 (beta + initial launch) |
| Exit ramp | `pg_dump` → bare Postgres on Neon/RDS/PocketBase if needed |

**Why Supabase wins for the current stage:**

1. **All six requested use cases solved in one shot** — sync, backup,
   premium tier gating, social/sharing, analytics, future-proof
   infrastructure.
2. **Lowest time-to-launch.** Solo dev gets 1 day of work instead of
   2-3 weeks of building auth + API from scratch on Neon.
3. **$0 cash cost during beta.** No infrastructure budget needed
   until we cross product-market fit.
4. **Schema compatibility.** Drift's relational SQL maps 1:1 to
   Postgres without any redesign.
5. **Migration ramp is preserved.** Supabase is open source on
   Postgres. If we outgrow it or want to relocate to Indonesia for
   UU PDP reasons, the data exits cleanly to PocketBase or a custom
   Postgres host.

**When to reconsider:**

- If Polaris pivots from "side project" to "primary commercial
  product" → revisit PocketBase on Indo-local VPS for the privacy /
  latency / cost-at-scale wins.
- If we cross 50K MAU and the Pro plan ($25/mo) feels expensive
  relative to revenue → consider PocketBase.
- If UU PDP enforcement tightens and demands data residency in
  Indonesia → relocate to PocketBase on Biznet/IDCloudHost.

## 4. What ships during MVP (today, before Phase 2)

**Schema insurance** — already landed in **schema v6** (2026-06-14):

- `events_table.deletedAtEpochMs` (nullable). Reserved for soft
  deletes the sync engine will introduce.
- `lifestyle_logs_table.updatedAtEpochMs` (nullable). Populated by
  the repository on every write going forward; Phase 2 will use it
  for last-write-wins conflict resolution.
- `lifestyle_logs_table.deletedAtEpochMs` (nullable). Same role as on
  events.

These three columns cost nothing on existing rows (null) and avoid a
data-backfill migration when sync lands. **No application code touches
them yet** — they exist solely to reserve the column slot.

**No other code changes** are needed during MVP. Auth feature module,
remote repositories, sync coordinator — all deferred until M9.

## 5. Phase 2 implementation plan (~1 week focused)

When M9 begins, the work breakdown is:

| Day | Work |
|---|---|
| 1 | Provision Supabase project (SG region). Mirror Drift schema in Postgres (events, life_profiles, lifestyle_logs). Enable RLS policies: `user_id = auth.uid()` for every row. |
| 2 | New `feature/auth/` module. `AuthService` abstract interface + `SupabaseAuthService` impl. Email + Google OAuth. Auth state stream as a Riverpod provider. |
| 3 | Onboarding flow gains an **optional** "Sign in to sync (optional)" CTA — skippable, with copy that explicitly says "all data stays on this device unless you sign in." Settings page gets sign-in / sign-out. |
| 4-5 | `Remote*Repository` siblings for each existing repo: `RemoteEventRepository`, `RemoteLifestyleLogRepository`, `RemoteLifeProfileRepository`. Compose with their `Local*` counterparts in a "local is source of truth, remote is replica" pattern — the controller always reads/writes local first, then enqueues a sync. |
| 6 | `SyncCoordinator` — background worker that drains the sync queue, applies last-write-wins based on `updatedAtEpochMs`, retries with exponential backoff, logs conflicts to a debug table for inspection. |
| 7 | Test suite: mocked Supabase client, integration smoke against a real Supabase project, conflict-resolution edge cases. Update `docs/Handoff.md`. |

**Migration notes for that day:**

- Add `userId` (text, nullable) column to every synced table; default
  existing rows to `'local'`. Sync engine treats `'local'` as
  unmigrated and offers a one-time upload prompt the first time the
  user signs in.
- Switch lifestyle-logs delete from hard `DELETE` to soft delete
  (`deletedAtEpochMs = now`). Existing queries learn to
  `WHERE deletedAtEpochMs IS NULL`.
- Replace `EventsDao.deleteById` with a soft-delete equivalent;
  events delete already routes through `EventsController.delete` so
  the change is localized.

## 6. Open questions for Phase 2

- **Account portability.** When a user signs in for the first time on
  a fresh device with no local data → seamless "download my data".
  When a user signs in for the first time on a device that already
  has local data → conflict (merge vs replace vs prompt). Default
  proposal: prompt the user.
- **Premium gating.** Supabase custom claims via Edge Functions can
  attach `is_premium: true` to JWT. Implementation deferred until
  there's an actual premium tier to gate.
- **Anonymous → authenticated upgrade.** Supabase supports anonymous
  sign-in; might be useful if we want sync between two devices
  without forcing real account creation. Defer the decision until
  user research confirms demand.
- **Data export / GDPR / UU PDP "right to be forgotten."** Already
  supported in spirit by the offline-first design; Phase 2 needs an
  explicit "Delete my cloud copy" button in settings that wipes the
  remote rows + clears the auth session.

## 7. References

- [`BRD Polaris.md`](./BRD%20Polaris.md) — §6 "Future Features",
  §7.2 "Privacy & Data", §9 "Architecture", Milestone plan M9.
- [`Handoff.md`](./Handoff.md) — current state.
- [Supabase Flutter docs](https://supabase.com/docs/reference/dart/installing)
- [Supabase RLS guide](https://supabase.com/docs/guides/auth/row-level-security)
- [PocketBase docs](https://pocketbase.io/docs/) — kept here as the
  fallback option's reference.

## 8. Change log

| Date | Author | Notes |
|---|---|---|
| 2026-06-14 | Cursor AI session | Initial ADR captured. Decision: Supabase free tier at Phase 2. Schema v6 ships today as sync insurance (no behavior change). |
