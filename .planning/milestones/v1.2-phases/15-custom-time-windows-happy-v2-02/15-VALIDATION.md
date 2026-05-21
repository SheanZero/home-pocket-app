---
phase: 15
slug: custom-time-windows-happy-v2-02
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-19
updated: 2026-05-19
---

# Phase 15 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (Flutter SDK) |
| **Config file** | none — uses default `test/` discovery |
| **Quick run command** | `flutter test test/unit/application/analytics/ test/unit/features/analytics/ test/widget/features/analytics/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | quick ~30s, full ~120s |

---

## Sampling Rate

- **After every task commit:** Run the task's `<automated>` command (each task declares a scoped `flutter test` invocation; runs in <30s).
- **After every plan wave:** Run `flutter analyze && flutter test` (full suite).
- **Before `/gsd:verify-work`:** Full suite must be green AND `flutter analyze` reports 0 issues.
- **Max feedback latency:** 30 seconds (quick) / 120 seconds (full).

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 15-01-T1 | 01 (ARB foundation) | 1 | HAPPY-V2-02 | T-15-01 (localized error copy) | ARB keys present in en/ja/zh; retired keys absent | static | `grep -c '"analyticsTimeWindowChipTooltip"' lib/l10n/app_en.arb lib/l10n/app_ja.arb lib/l10n/app_zh.arb` | ✅ (ARB files) | ⬜ pending |
| 15-01-T2 | 01 (ARB foundation) | 1 | HAPPY-V2-02 | T-15-02 (ARB parse) | Generated localizations clean | static | `flutter gen-l10n 2>&1 \| tee /tmp/gen-l10n.log && grep -q 'analyticsTimeWindowChipTooltip' lib/generated/app_localizations.dart` | ✅ (l10n.yaml + ARB) | ⬜ pending |
| 15-02-T1 | 02 (domain) | 1 | HAPPY-V2-02 | — (pure value object) | TimeWindow 5-variant range math correct (week-Monday, leap-year, quarter boundaries) | unit | `flutter test test/unit/features/analytics/domain/models/time_window_test.dart` | ❌ W0 → created in this task | ⬜ pending |
| 15-02-T2 | 02 (domain) | 1 | HAPPY-V2-02 | T-15-03 (input validation), T-15-04 (DoS), T-15-05 (info disclosure) | start>end, >12mo, future-end rejected with ArgumentError | unit | `flutter test test/unit/application/analytics/time_window_validation_test.dart` | ❌ W0 → created in this task | ⬜ pending |
| 15-03-T1 | 03 (use-case migration) | 2 | HAPPY-V2-02 (SC-2) | T-15-03, T-15-06 (display-anchor) | 5 use cases accept (startDate, endDate); assertValid gate; display-anchor for HappinessReport/FamilyHappiness | unit | `flutter test test/unit/application/analytics/get_satisfaction_distribution_use_case_test.dart test/unit/application/analytics/get_best_joy_moment_use_case_test.dart test/unit/application/analytics/get_largest_monthly_expense_use_case_test.dart test/unit/application/analytics/get_happiness_report_use_case_test.dart test/unit/application/analytics/get_family_happiness_use_case_test.dart` | ✅ (existing test files rewritten) | ⬜ pending |
| 15-03-T2 | 03 (use-case migration) | 2 | HAPPY-V2-02 (SC-2) | T-15-03, T-15-06 | get_monthly_report use case (startDate, endDate) + display-anchor on MonthlyReport.year/month; previousMonthComparison helper preserved | unit | `flutter test test/unit/application/analytics/get_monthly_report_use_case_test.dart test/unit/features/analytics/domain/models/monthly_report_test.dart` | ✅ (existing tests rewritten) | ⬜ pending |
| 15-03-T3 | 03 (use-case migration) | 2 | HAPPY-V2-02 (SC-5) | T-15-07 (ADR-012 §4 latent delta) | _MomDeltaSubLine + delta sub-line block deleted from total_spending_kpi_tile.dart | static | `flutter analyze lib/features/analytics/presentation/widgets/total_spending_kpi_tile.dart && grep -c '_MomDeltaSubLine\|analyticsKpiTotalDelta' lib/features/analytics/presentation/widgets/total_spending_kpi_tile.dart` | ✅ (file exists pre-phase) | ⬜ pending |
| 15-04-T1 | 04 (provider re-key) | 3 | HAPPY-V2-02 (SC-1, SC-2) | T-15-09 (provider key shape) | SelectedTimeWindow notifier default=current month; legacy SelectedMonth deleted; state_analytics family providers re-keyed | unit | `flutter pub run build_runner build --delete-conflicting-outputs && flutter test test/unit/features/analytics/presentation/providers/state_time_window_test.dart test/unit/features/analytics/presentation/providers/analytics_providers_characterization_test.dart` | ❌ W0 (state_time_window_test) + ✅ (characterization migrated) | ⬜ pending |
| 15-04-T2 | 04 (provider re-key) | 3 | HAPPY-V2-02 (SC-2) | T-15-09 | state_happiness 4 family providers re-keyed; _emptyFamilyHappiness uses display-anchor | static | `flutter pub run build_runner build --delete-conflicting-outputs && flutter analyze lib/features/analytics/presentation/providers/state_happiness.dart` | ✅ (file exists) | ⬜ pending |
| 15-04-T3 | 04 (provider re-key) | 3 | HAPPY-V2-02 (SC-3) | T-15-10 (HomeHero coupling drift) | HomeScreen reads DateTime.now(); shadowAggregate provider re-keyed; no state_time_window import in lib/features/home/ | static | `flutter pub run build_runner build --delete-conflicting-outputs && flutter analyze lib/features/home/ && ! grep -rn 'state_time_window\|selectedTimeWindowProvider' lib/features/home/` | ✅ (files exist) | ⬜ pending |
| 15-05-T1 | 05 (selector widgets) | 4 | HAPPY-V2-02 (SC-4) | — | DateFormatter / FormatterService verified stable; no new helpers (year/quarter labels composed via ARB substitution) | unit | `flutter test test/unit/infrastructure/i18n/formatters/date_formatter_test.dart` | ✅ (may need creation in-task) | ⬜ pending |
| 15-05-T2 | 05 (selector widgets) | 4 | HAPPY-V2-02 (SC-1, SC-4) | — | TimeWindowChip renders 5 TimeWindow variants in en/ja/zh; touch target ≥44pt; ARB-keyed copy | widget | `flutter test test/widget/features/analytics/presentation/widgets/time_window_chip_test.dart && flutter analyze lib/features/analytics/presentation/widgets/time_window_chip.dart` | ❌ W0 → created in this task | ⬜ pending |
| 15-05-T3 | 05 (selector widgets) | 4 | HAPPY-V2-02 (SC-1, SC-2, SC-4) | T-15-01 (localized errors), T-15-03 (UI gate), T-15-11 (picker bounds) | TimeWindowPickerSheet type-row + per-type chooser; showDateRangePicker bounded; localized SnackBar on invalid range | widget | `flutter test test/widget/features/analytics/presentation/widgets/time_window_picker_sheet_test.dart && flutter analyze lib/features/analytics/presentation/widgets/time_window_picker_sheet.dart` | ❌ W0 → created in this task | ⬜ pending |
| 15-06-T1 | 06 (integration + locks) | 5 | HAPPY-V2-02 (SC-1, SC-2) | T-15-09, T-15-13 (_refresh scope) | AnalyticsScreen reads selectedTimeWindowProvider; chip swapped; _refresh re-keyed; MonthChipPicker deleted | widget | `flutter pub run build_runner build --delete-conflicting-outputs && flutter analyze lib/ && flutter test test/widget/features/analytics/presentation/screens/analytics_screen_test.dart && ! grep -rn 'MonthChipPicker\|selectedMonthProvider\|month_chip_picker' lib/ test/` | ✅ (analytics_screen_test exists) | ⬜ pending |
| 15-06-T2 | 06 (integration + locks) | 5 | HAPPY-V2-02 (SC-3, SC-5) | T-15-10 (HomeHero isolation), T-15-12 (no-delta lock) | home_screen_isolation_test (year-2020 window vs current-month verify); analytics_no_delta_ui_test across 5 variants | widget | `flutter test test/widget/features/home/presentation/screens/home_screen_isolation_test.dart test/widget/features/analytics/presentation/screens/analytics_no_delta_ui_test.dart` | ❌ W0 → created in this task | ⬜ pending |
| 15-06-T3 | 06 (integration + locks) | 5 | HAPPY-V2-02 (all SCs) | T-15-10, T-15-12, T-15-13 | Full-suite green + analyzer 0 + grep gates exit-1 (legacy/retired symbols absent) | static + suite | `flutter analyze 2>&1 \| tail -20 && flutter test 2>&1 \| tail -30` | ✅ (verification scripts) | ⬜ pending |

*Each task's `<automated>` block in its PLAN.md is the source of truth for the command above. Status updates as tasks execute.*

*Status legend: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

> Test files that MUST exist before later waves can be verified. Derived from research §11 and locked in per-task verification map above.

- [x] `test/unit/features/analytics/domain/models/time_window_test.dart` — `TimeWindow` value object, range derivation (5 variants), leap-year edges, equality (Plan 02 Task 1 creates it; status flips green on plan execution)
- [x] `test/unit/application/analytics/time_window_validation_test.dart` — `assertValid` boundary tests (start>end, 12-month exact, 12-month+1day, 13-month, leap-year cross, future-end) (Plan 02 Task 2 creates it)
- [x] `test/unit/features/analytics/presentation/providers/state_time_window_test.dart` — Notifier state transitions (default current-month, setWindow Quarter/Custom, equality dedup) (Plan 04 Task 1 creates it)
- [x] `test/widget/features/analytics/presentation/widgets/time_window_chip_test.dart` — 5-variant rendering en + ja, touch target ≥44pt (Plan 05 Task 2 creates it)
- [x] `test/widget/features/analytics/presentation/widgets/time_window_picker_sheet_test.dart` — type-row navigation, immediate apply, custom-range invalid → localized SnackBar (Plan 05 Task 3 creates it)
- [x] `test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` — HomeHero locked to current-month regardless of selectedTimeWindowProvider state + static import-absence check (Plan 06 Task 2 creates it)
- [x] `test/widget/features/analytics/presentation/screens/analytics_no_delta_ui_test.dart` — No Delta/Comparison widget in tree across all 5 variants + retired-ARB-key absence check (Plan 06 Task 2 creates it)
- [x] Extensions to existing files: `test/unit/application/analytics/get_*_use_case_test.dart` (6 files, Plan 03) + `test/widget/features/analytics/presentation/screens/analytics_screen_test.dart` (Plan 06 Task 1) for new `(startDate, endDate)` signatures + ArgumentError cases

*Framework already installed — flutter_test ships with Flutter SDK; no install task needed.*

---

## Validation Architecture (Layer Map)

> Defense-in-depth: which layer validates what, what fails if it doesn't, and which test catches the regression.

| Layer | Must Validate | Failure Mode If Missed | Catching Test Type |
|-------|---------------|------------------------|-------------------|
| **UI (selector widget)** | User cannot submit `start > end`; >12-month range is blocked at picker level before being committed to provider state | Invalid state propagates to provider → use-case throws → snackbar/blank UI surfaces to user | widget test (pump picker, attempt invalid selection, assert dismiss/SnackBar) |
| **Provider (`SelectedTimeWindow` Notifier)** | Rejects malformed `TimeWindow` (variant with null/invalid bounds); emits last-valid state on rejected mutations | UI may render with a half-applied window; downstream rebuilds use stale data | notifier unit test (`ProviderContainer.test()`, dispatch invalid mutations, assert state unchanged + error logged) |
| **Domain (`TimeWindow` model)** | `start <= end`, range duration ≤ 12 months, week boundary correctness (Monday-start per D-05) | Logically impossible windows reach the use-case layer; produces empty result sets that look like "no data" rather than "invalid input" | model unit test (`TimeWindow.fromCustom(...)` factory rejects, throws structured error) |
| **Application (joy use-cases)** | `(startDate, endDate)` accepted and forwarded to repo; defensive re-check of `start <= end` (input-trust boundary); empty-result handling distinguishable from invalid input | False-positive empty KPI displayed; trend/distribution silently blank | use-case unit test (assert thrown on invalid, assert calls DAO with exact bounds on valid) |
| **Data (`AnalyticsDao`/`AnalyticsRepository`)** | Date-range queries use `idx_tx_book_timestamp` (year-wide query stays index-served, no full-table scan) | UI jank on year-window selection (>500ms render); battery drain | integration test with seeded book + EXPLAIN QUERY PLAN assertion OR perf test bounded to N transactions |
| **i18n (DateFormatter + ARB)** | All window labels (week / month / quarter / year / custom-range) localized for ja/zh/en; no hardcoded date strings introduced | English/Japanese mismatch in labels; ARB parity CI fails | ARB parity test (existing CI step) + widget test asserting `S.of(context).<key>` is consumed, not literal |
| **Cross-feature isolation (HomeHero)** | Selecting non-month window in AnalyticsScreen does NOT mutate any provider that HomeHero reads | ADR-016 §3 ring semantics violated; user sees ring jump when navigating between screens | locking widget test: pump HomeScreen with `selectedTimeWindowProvider` set to a 2020 yearly window, assert HomeHero use cases are invoked with current-month range only (mocktail `verifyNever` for 2020 key) |
| **No-cross-period-delta guard (ADR-012 §4)** | AnalyticsScreen widget tree contains zero delta/comparison widgets across all 5 variants | Accidental future PR adds a "vs last quarter" overlay; ADR violation slips through review | guard test: `expect(find.byWidgetPredicate((w) => w.runtimeType.toString().contains('Delta') || ...contains('Comparison')), findsNothing)` across all 5 TimeWindow variants |

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Custom date-range picker UX feels native on iOS + Android | HAPPY-V2-02 (acceptance criterion 1) | `showDateRangePicker` rendering is platform-themed; visual review only | Launch app in ja locale on iOS sim and Android emulator; open AnalyticsScreen → tap "Custom range"; verify picker styling matches platform Material 3 theme and respects ja date order |
| Performance on year-window with 10k+ transactions | HAPPY-V2-02 (acceptance criterion 2) | Realistic data volume is too expensive for CI seeding | Seed dev DB with 12-month worth of transactions (~10k rows); switch to "Year" window; measure frame time via DevTools timeline; expect <16ms median |
| Session-only persistence (not across restart) | HAPPY-V2-02 (acceptance criterion 1) | Process lifecycle behavior is hard to assert in widget tests | Select "Quarter" → background app → resume → window still Quarter; kill app → relaunch → window resets to default (Month) |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies — verified by Per-Task Verification Map above (every row references the task's `<automated>` block)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify — all 16 tasks have automated `<verify>` blocks
- [x] Wave 0 covers all MISSING references — 7 new test files listed in Wave 0 Requirements above
- [x] No watch-mode flags — all commands run once and exit
- [x] Feedback latency < 30s (quick) / 120s (full) — scoped per-task commands run in <30s; full suite <120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** ready — Phase 15 cleared for `/gsd:execute-phase`
