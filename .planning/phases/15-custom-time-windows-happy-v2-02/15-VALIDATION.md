---
phase: 15
slug: custom-time-windows-happy-v2-02
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-19
---

# Phase 15 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (Flutter SDK) |
| **Config file** | none — uses default `test/` discovery |
| **Quick run command** | `flutter test test/features/analytics/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | quick ~30s, full ~120s |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/features/analytics/` (quick scope)
- **After every plan wave:** Run `flutter analyze && flutter test` (full suite)
- **Before `/gsd:verify-work`:** Full suite must be green AND `flutter analyze` reports 0 issues
- **Max feedback latency:** 30 seconds (quick) / 120 seconds (full)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 15-XX-XX | TBD | TBD | HAPPY-V2-02 | — | N/A (UI-only, no auth boundary) | unit/widget | `flutter test test/...` | ❌ W0 | ⬜ pending |

*Filled by planner — every task in each PLAN.md must add a row referencing its automated verify command and HAPPY-V2-02.*

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

> Test files that MUST exist before later waves can be verified. Derived from research §11.

- [ ] `test/features/analytics/domain/models/time_window_test.dart` — `TimeWindow` value object, range derivation, validation (`start <= end`, >12 month rejection)
- [ ] `test/features/analytics/presentation/providers/selected_time_window_provider_test.dart` — Notifier state transitions, session-scope behavior, default value
- [ ] `test/features/analytics/presentation/widgets/time_window_selector_test.dart` — selector renders all variants, locale-aware labels, custom-range picker integration
- [ ] `test/features/analytics/presentation/screens/analytics_screen_window_test.dart` — re-query on window change, all metrics update
- [ ] `test/features/home/presentation/screens/home_hero_isolation_test.dart` — HomeHero ring unchanged when AnalyticsScreen window changes (locking widget test)
- [ ] `test/features/analytics/presentation/screens/analytics_no_delta_ui_test.dart` — assert no `*Delta*`/`*Comparison*` widget in tree (ADR-012 §4)
- [ ] `test/application/analytics/joy_contribution_use_cases_window_test.dart` — extend existing use-case tests with arbitrary `(startDate, endDate)` cases (or add new file if none exists)

*Framework already installed — flutter_test ships with Flutter SDK; no install task needed.*

---

## Validation Architecture (Layer Map)

> Defense-in-depth: which layer validates what, what fails if it doesn't, and which test catches the regression.

| Layer | Must Validate | Failure Mode If Missed | Catching Test Type |
|-------|---------------|------------------------|-------------------|
| **UI (selector widget)** | User cannot submit `start > end`; >12-month range is blocked at picker level before being committed to provider state | Invalid state propagates to provider → use-case throws → snackbar/blank UI surfaces to user | widget test (pump picker, attempt invalid selection, assert dismiss/SnackBar) |
| **Provider (`SelectedTimeWindow` Notifier)** | Rejects malformed `TimeWindow` (variant with null/invalid bounds); emits last-valid state on rejected mutations | UI may render with a half-applied window; downstream rebuilds use stale data | notifier unit test (`ProviderContainer.test()`, dispatch invalid mutations, assert state unchanged + error logged) |
| **Domain (`TimeWindow` model)** | `start <= end`, range duration ≤ 12 months, week boundary correctness (locale-aware ISO week vs Sun-anchored — see CONTEXT.md §Decisions) | Logically impossible windows reach the use-case layer; produces empty result sets that look like "no data" rather than "invalid input" | model unit test (`TimeWindow.fromCustom(...)` factory rejects, throws structured error) |
| **Application (joy use-cases)** | `(startDate, endDate)` accepted and forwarded to repo; defensive re-check of `start <= end` (input-trust boundary); empty-result handling distinguishable from invalid input | False-positive empty KPI displayed; trend/distribution silently blank | use-case unit test (assert thrown on invalid, assert calls DAO with exact bounds on valid) |
| **Data (`AnalyticsDao`/`AnalyticsRepository`)** | Date-range queries use `idx_tx_book_timestamp` (year-wide query stays index-served, no full-table scan) | UI jank on year-window selection (>500ms render); battery drain | integration test with seeded book + EXPLAIN QUERY PLAN assertion OR perf test bounded to N transactions |
| **i18n (DateFormatter + ARB)** | All window labels (week / month / quarter / year / custom-range) localized for ja/zh/en; no hardcoded date strings introduced | English/Japanese mismatch in labels; ARB parity CI fails | ARB parity test (existing CI step) + widget test asserting `S.of(context).<key>` is consumed, not literal |
| **Cross-feature isolation (HomeHero)** | Selecting non-month window in AnalyticsScreen does NOT mutate any provider that HomeHero reads | ADR-016 §3 ring semantics violated; user sees ring jump when navigating between screens | locking widget test: build HomeHero + AnalyticsScreen, change window, assert HomeHero ring frame identical (golden or numeric assertion) |
| **No-cross-period-delta guard (ADR-012 §4)** | AnalyticsScreen widget tree contains zero delta/comparison widgets across all 5 variants | Accidental future PR adds a "vs last quarter" overlay; ADR violation slips through review | guard test: `expect(find.byWidgetPredicate((w) => w.runtimeType.toString().contains('Delta') || ...contains('Comparison')), findsNothing)` |

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Custom date-range picker UX feels native on iOS + Android | HAPPY-V2-02 (acceptance criterion 1) | `showDateRangePicker` rendering is platform-themed; visual review only | Launch app in ja locale on iOS sim and Android emulator; open AnalyticsScreen → tap "Custom range"; verify picker styling matches platform Material 3 theme and respects ja date order |
| Performance on year-window with 10k+ transactions | HAPPY-V2-02 (acceptance criterion 2) | Realistic data volume is too expensive for CI seeding | Seed dev DB with 12-month worth of transactions (~10k rows); switch to "Year" window; measure frame time via DevTools timeline; expect <16ms median |
| Session-only persistence (not across restart) | HAPPY-V2-02 (acceptance criterion 1) | Process lifecycle behavior is hard to assert in widget tests | Select "Quarter" → background app → resume → window still Quarter; kill app → relaunch → window resets to default (Month) |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s (quick) / 120s (full)
- [ ] `nyquist_compliant: true` set in frontmatter (planner flips this once map is filled)

**Approval:** pending
