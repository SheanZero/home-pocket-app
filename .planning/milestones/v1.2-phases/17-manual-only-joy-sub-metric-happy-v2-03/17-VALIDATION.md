---
phase: 17
slug: manual-only-joy-sub-metric-happy-v2-03
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-20
---

# Phase 17 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (3.x) + drift_dev migration testing |
| **Config file** | `pubspec.yaml` (test deps), `dart_test.yaml` if present |
| **Quick run command** | `flutter test test/unit/<changed-path>_test.dart` |
| **Full suite command** | `flutter test --coverage` |
| **Estimated runtime** | ~120–180 seconds (full suite) |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/unit/<changed-path>_test.dart` (~3-10s per file)
- **After every plan wave:** Run `flutter test --coverage` (full suite)
- **Before `/gsd:verify-work`:** Full suite must be green, `flutter analyze` must be 0 issues, coverage ≥80% per `.claude/rules/testing.md`
- **Max feedback latency:** 180 seconds (full suite)

---

## Per-Task Verification Map

> Populated by gsd-planner. Each plan task in `*-PLAN.md` must reference one row.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 17-01-01 | 01 | 1 | HAPPY-V2-03 | — | ROADMAP SC-3 text reflects whole-screen audit lens (D-15/D-16) | doc-grep | `grep -F "every data card on AnalyticsScreen" .planning/ROADMAP.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Note: Remaining task rows populated by planner during plan creation. Each PLAN.md task with `<automated>` block contributes one row here.*

---

## Wave 0 Requirements

- [ ] Drift migration test scaffolding for v16 → v17 (`test/unit/data/migration_v16_to_v17_test.dart`) — extends `migration_v15_to_v16_test.dart` pattern
- [ ] Anti-toxicity widget test extension (`test/unit/features/analytics/anti_toxicity_phase17_test.dart` OR extend `anti_toxicity_phase16_test.dart`) — adds D-14 trilingual substring list
- [ ] HomeHero isolation test extension (`test/unit/features/home/home_screen_isolation_test.dart`) — toggle change MUST NOT invalidate HomeHero providers
- [ ] Sync mapper round-trip test (`test/unit/features/accounting/transaction_sync_mapper_test.dart` or equivalent) — `entry_source` carries across serialize/deserialize, fallback to `'manual'` when field absent

*If existing scaffolds cover one or more of the above, planner refines the list during plan creation.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Family-sync cross-device round-trip: device A creates `entry_source='voice'` row, device B receives it stamped `'voice'` after sync | HAPPY-V2-03 / D-03 | Two-device E2E; no in-tree harness for live BLE/Wi-Fi sync at v1.2 (existing sync tests use mapper-level fixtures) | 1. Build app on two physical devices A, B paired in same family group. 2. On A, create transaction via voice path. 3. Trigger sync. 4. On B, inspect DB row: `SELECT entry_source FROM transactions WHERE id = '<id>'`. 5. Expect `'voice'`. |
| Cold-start toggle reset: toggle resets to `all` on every app restart | HAPPY-V2-03 / D-10 | Session-only state contract; integration test infrastructure does not cover process restart | 1. Open AnalyticsScreen, toggle to "Manual only". 2. Force-quit app. 3. Re-open app, navigate to AnalyticsScreen. 4. Expect chip label = "All entries". |
| AppBar narrow-viewport overflow check: `JoyMetricVariantChip` placement does not overflow on 360 dp width devices | HAPPY-V2-03 / D-12 concern | Golden tests cover known viewport sizes but live device check confirms perceived crowding | 1. Run app on iPhone SE / Pixel 4a / smallest target device. 2. Open AnalyticsScreen. 3. Verify both `TimeWindowChip` and `JoyMetricVariantChip` visible in AppBar.actions without truncation or overflow. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
