---
phase: 44
slug: data-use-case-additions-reuse-first
status: planned
nyquist_compliant: true
wave_0_complete: not_applicable
created: 2026-06-16
updated: 2026-06-16
---

# Phase 44 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Synced to the 3-plan / 2-wave structure (44-01, 44-02 in Wave 1; 44-03 in Wave 2). TDD for DRILL-01 (D-04) is a RED→GREEN sequence INSIDE Plan 03 (Task 1 RED, Task 2 GREEN) — there is no separate Wave 0 plan.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (Dart) + in-memory `AppDatabase.forTesting()` (NativeDatabase) for use-case tests |
| **Config file** | `test/flutter_test_config.dart` (golden comparator swap; not needed for these data-layer unit tests) |
| **Quick run command** | `flutter test test/unit/application/analytics/ test/unit/features/analytics/domain/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | quick ~10–30s · full suite ~several min |

---

## Sampling Rate

- **After every task commit:** Run the quick command scoped to the touched test file (paths below).
- **After every plan wave:** Run `flutter test` (full — architecture / anti-toxicity / HomeHero-isolation / CJK tests are global structural locks this data phase must not regress).
- **Before `/gsd-verify-work`:** Full suite green + `flutter analyze` 0 issues.
- **Max feedback latency:** ~30 seconds (quick) / a few minutes (full).

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 44-01-rollup | 44-01 | 1 | OVW-01 | T-44-01-01 | No tx-content logging in pure helper | unit (pure L1-rollup helper, locked API) | `flutter test test/unit/features/analytics/domain/category_l1_rollup_test.dart` | ❌ created by 44-01 | ⬜ pending |
| 44-02-trend-model | 44-02 | 1 | TREND-01 | — | N/A | unit (MonthlyTrend +dailyTotal/+joyTotal serialization) | `flutter test test/unit/features/analytics/domain/models/expense_trend_test.dart` | ✅ edit (exists) | ⬜ pending |
| 44-02-trend-usecase | 44-02 | 1 | TREND-01 | T-44-02-01 | No per-month amount logging | unit (per-ledger fetch + zero-default for zero-spend month) | `flutter test test/unit/application/analytics/get_expense_trend_use_case_test.dart` | ✅ edit (exists) | ⬜ pending |
| 44-03-drill-RED | 44-03 | 2 (Task 1) | DRILL-01 | — | N/A | unit (TDD RED — fails before impl, D-04) | `flutter test test/unit/application/analytics/get_category_drill_down_use_case_test.dart` | ❌ created by 44-03 Task 1 | ⬜ pending |
| 44-03-drill-GREEN | 44-03 | 2 (Task 2) | DRILL-01 | T-44-03-01, T-44-03-03 | No tx-content logging; no book-set widening | unit (TDD GREEN — same file passes after impl) | `flutter test test/unit/application/analytics/get_category_drill_down_use_case_test.dart` | ❌ same file, GREEN | ⬜ pending |
| 44-03-drill-wire | 44-03 | 2 (Task 3) | DRILL-01 / GUARD-01 | — | HomeHero isolation preserved | widget (structural lock) | `flutter test test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` | ✅ exists | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

**Path corrections vs the earlier draft:** all use-case/model tests live under `test/unit/...`; the drill test file is `get_category_drill_down_use_case_test.dart` (`drill_down`, not `drilldown`); the rollup test is `test/unit/features/analytics/domain/category_l1_rollup_test.dart`.

---

## TDD Sequence (DRILL-01, D-04) — inside Plan 03 (Wave 2)

No separate Wave 0 plan exists. The RED→GREEN cycle is contained in Plan 03:

- **RED:** 44-03 Task 1 writes `test/unit/application/analytics/get_category_drill_down_use_case_test.dart` BEFORE any `GetCategoryDrillDownUseCase`/`CategoryDrillDown` code → the run fails (use case absent). Verify command tolerates the expected non-zero via `|| echo RED-CONFIRMED`.
- **GREEN:** 44-03 Task 2 creates the model + use case → the SAME test file passes (exit 0).
- **WIRE:** 44-03 Task 3 adds the providers → `home_screen_isolation_test.dart` stays green.

---

## New / Edited Test Files (this phase)

- [ ] **NEW** `test/unit/features/analytics/domain/category_l1_rollup_test.dart` (44-01) — `l1AncestorOf` rule; `rollupCategoryBreakdownsToL1` (L2→L1 sum, amount-desc, top-10, L1-direct Pitfall 2, empty→empty); `l1RollupFromTransactions` (subtotal/count from raw txns, L1-direct + L2-child, missing L1→zero); single-source cross-check that both entrypoints agree (D-11).
- [ ] **NEW** `test/unit/application/analytics/get_category_drill_down_use_case_test.dart` (44-03 Task 1, TDD-first RED — D-04) — window+L1-filtered txns, subtotal/count == `l1RollupFromTransactions`, L1-direct + L2-child both included, sibling-L1 + out-of-window excluded, empty-window→empty.
- [ ] **EDIT** `test/unit/features/analytics/domain/models/expense_trend_test.dart` (44-02 Task 1) — construct `MonthlyTrend` with `dailyTotal`/`joyTotal`; assert serialization round-trip of the two new fields.
- [ ] **EDIT** `test/unit/application/analytics/get_expense_trend_use_case_test.dart` (44-02 Task 2) — per-ledger `dailyTotal`/`joyTotal` assertions + a joy-empty-month case asserting `joyTotal == 0` (RESEARCH Pitfall 1).
- [ ] Existing `flutter_test` infrastructure covers framework needs — no new framework install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| OVW-01 confirmed as pure-display-transform | OVW-01 | Negative assertion — proving "zero new use case/DAO/migration" is a code-review/grep check, not a runtime test | Confirm no new DAO method, no `schemaVersion` bump (stays v21), no migration in `app_database.dart`; OVW-01's only new code is the unit-tested L1-rollup helper. |
| OVW-01 donut consumer deferred to Phase 46 | OVW-01 | Phase boundary — Phase 44 delivers the data contract (helper + test), not a rendered donut | The verifier scopes OVW-01 to the helper + its unit test; the donut display lands in Phase 46. (Plan-checker Warning 1, intended.) |

*All other phase behaviors have automated unit verification.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or are part of the in-Plan-03 RED→GREEN sequence
- [x] Sampling continuity: no 3 consecutive tasks without automated verify (every task carries an `<automated>` command)
- [x] Wave 0 not applicable — TDD RED→GREEN is contained in Plan 03; all MISSING test references are created within their owning plan
- [x] No watch-mode flags
- [x] Feedback latency < 30s (quick) / minutes (full)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** synced to plans 44-01 / 44-02 / 44-03 (2026-06-16).
