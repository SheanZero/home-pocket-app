---
phase: 24
slug: data-layer-extension
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-29
---

# Phase 24 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (Dart) |
| **Config file** | none — existing test infra covers this phase |
| **Quick run command** | `flutter test test/data/daos/transaction_dao_test.dart test/shared/utils/date_boundaries_test.dart` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~60 seconds (targeted), full suite longer |

---

## Sampling Rate

- **After every task commit:** Run quick run command (targeted DAO/utils tests)
- **After every plan wave:** Run `flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green + `flutter analyze` 0 issues
- **Max feedback latency:** ~60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| (filled by planner) | — | — | LIST-02 | — | — | unit | `flutter test` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

> The 5 Success Criteria map to these validation anchors (see RESEARCH.md §Validation Architecture):
> - SC#1 (multi-book single SQL) → unit test on `findByBookIds`: in-memory DB, multiple book_ids, assert single query spans all + excludes soft-deleted + respects ledgerType/categoryId + ORDER BY SortField
> - SC#2 (reactive watch within one rebuild cycle) → `ProviderContainer.test()` + `waitForFirstValue<T>`, assert emit after insert / soft-delete / sync-applied write WITHOUT `ref.invalidate`
> - SC#3 (DateBoundaries closed interval, local time) → unit tests asserting `00:00:00` and `23:59:59` boundary inclusion, local-time alignment with AnalyticsDao
> - SC#4 (hash chain after soft-delete) → unit test: soft-delete mid-chain row, assert hash fields unmutated and full chain `verifyChain()` valid (see RESEARCH open question — invariant restated)
> - SC#5 (note decrypt-failure → null) → unit test with fixture simulating decrypt failure, assert `note: null` + other fields intact

---

## Wave 0 Requirements

- [ ] `test/data/daos/transaction_dao_test.dart` — extend with `findByBookIds` + `watchByBookIds` cases (existing file)
- [ ] `test/shared/utils/date_boundaries_test.dart` — new test file for DateBoundaries
- [ ] Decrypt-failure fixture for `_toModel()` note path (SC#5)

*Existing flutter_test infrastructure covers all phase requirements — no framework install needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|

*All phase behaviors have automated verification — this is a pure data-layer phase, no UI.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
