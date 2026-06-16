---
phase: 44
slug: data-use-case-additions-reuse-first
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-16
---

# Phase 44 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (Dart) |
| **Config file** | `test/flutter_test_config.dart` (golden comparator swap; not needed for data-layer unit tests) |
| **Quick run command** | `flutter test test/application/analytics/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | quick ~10–30s · full suite ~several min |

---

## Sampling Rate

- **After every task commit:** Run quick command scoped to the touched use-case test
- **After every plan wave:** Run `flutter test` (full — architecture/anti-toxicity/isolation tests are global)
- **Before `/gsd-verify-work`:** Full suite must be green + `flutter analyze` 0 issues
- **Max feedback latency:** ~30 seconds (quick) / a few minutes (full)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 44-DRILL-test | DRILL | 0 | DRILL-01 | — | N/A | unit (TDD-first, RED) | `flutter test test/application/analytics/get_category_drilldown_use_case_test.dart` | ❌ W0 | ⬜ pending |
| 44-DRILL-impl | DRILL | 1 | DRILL-01 | — | N/A | unit (GREEN) | `flutter test test/application/analytics/get_category_drilldown_use_case_test.dart` | ❌ W0 | ⬜ pending |
| 44-TREND | TREND | 1 | TREND-01 | — | N/A | unit | `flutter test test/application/analytics/get_expense_trend_use_case_test.dart` | ❌ W0 | ⬜ pending |
| 44-OVW-rollup | OVW | 1 | OVW-01 | — | N/A | unit (pure L1-rollup helper) | `flutter test test/features/analytics/` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/application/analytics/get_category_drilldown_use_case_test.dart` — TDD-first RED test for `GetCategoryDrillDownUseCase` (D-04 mandate)
- [ ] `test/application/analytics/get_expense_trend_use_case_test.dart` — extend for per-ledger `dailyTotal`/`joyTotal` (D-08); zero-spend-ledger-defaults-to-0 case (research pitfall)
- [ ] L1-rollup pure helper test — covers L2→L1 parent rollup + descending sort (D-11), shared by donut + drill summary
- [ ] Existing flutter_test infrastructure covers framework needs — no new framework install

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| OVW-01 confirmed as pure-display-transform | OVW-01 | Negative assertion — proving "zero new use case/DAO/migration" is a code-review/grep check, not a runtime test | Confirm no new DAO method, no `schemaVersion` bump (stays v21), no new migration in `app_database.dart` |

*All other phase behaviors have automated unit verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
