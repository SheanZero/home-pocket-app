---
phase: 24
slug: data-layer-extension
status: final
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-29
updated: 2026-05-29
---

# Phase 24 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (Dart) |
| **Config file** | none — existing test infra covers this phase |
| **Quick run command** | `flutter test test/unit/shared/utils/date_boundaries_test.dart test/unit/data/daos/transaction_dao_multi_book_test.dart test/unit/data/repositories/transaction_repository_note_decrypt_test.dart` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~60 seconds (targeted), full suite longer |

---

## Sampling Rate

- **After every task commit:** Run the targeted quick-run command above
- **After every plan wave:** Run `flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green + `flutter analyze` 0 issues
- **Max feedback latency:** ~60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 24-01-T1 | 24-01 | 1 | LIST-02 (D-01 precondition) | T-24-01-02 | SortField enum values are compile-time constants — cannot be injected via user input | unit (pure Dart) | `flutter analyze lib/shared/constants/sort_config.dart` | ❌ W0 | ⬜ pending |
| 24-01-T2 | 24-01 | 1 | SC#3 | T-24-01-01 | DateBoundaries uses local time (no .utc()); boundaries include 00:00:00 and 23:59:59 | unit (pure Dart) | `flutter test test/unit/shared/utils/date_boundaries_test.dart` | ❌ W0 | ⬜ pending |
| 24-02-T1 | 24-02 | 2 | SC#1, SC#2, SC#4, LIST-02 | T-24-02-01, T-24-02-02, T-24-02-03, T-24-02-04 | IN(?) parameterized; ORDER BY from enum switch (no user string); bookIds trusted from caller; softDelete preserves hash fields | integration (in-memory DB) | `flutter test test/unit/data/daos/transaction_dao_multi_book_test.dart` | ❌ W0 | ⬜ pending |
| 24-03-T1 | 24-03 | 3 | SC#5, LIST-02 | T-24-03-01, T-24-03-02 | catch block silent — no logging of row.note/ciphertext; only decryptField call wrapped (not full _toModel) | unit (mock EncryptionService) | `flutter test test/unit/data/repositories/transaction_repository_note_decrypt_test.dart` | ❌ W0 | ⬜ pending |
| 24-03-T2 | 24-03 | 3 | LIST-02 | T-24-03-03, T-24-03-04 | asyncMap preserves stream error propagation; no hard-delete path introduced | integration + full suite | `flutter test` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## SC#4 Invariant Restatement (CRITICAL)

The ROADMAP SC#4 wording ("verifyChain() on the remaining non-deleted rows returns valid") is architecturally incorrect. After soft-deleting tx_002 from chain tx_001→tx_002→tx_003, calling `verifyChain([tx_001, tx_003])` (excluding tx_002) WILL fail the linkage check because tx_003.prevHash != tx_001.currentHash.

**Correct invariant (verified by RESEARCH.md + PATTERNS.md):** `softDelete()` writes ONLY `isDeleted=true` + `updatedAt` and does NOT touch `currentHash` or `prevHash`. Therefore `verifyChain(allThreeRows)` including the soft-deleted row returns `ChainVerificationResult.valid` because the full hash chain is cryptographically intact.

**Plan 02 Task 1 tests against the CORRECT invariant:**
1. Assert tx_002.isDeleted == true after softDelete
2. Assert tx_002.currentHash and tx_002.prevHash are unchanged
3. Assert verifyChain([tx_001_map, tx_002_map, tx_003_map]) == ChainVerificationResult.valid

---

## Wave 0 Requirements

All test files created in their respective plan tasks (TDD RED→GREEN cycle within each task):

- [x] `test/unit/shared/utils/date_boundaries_test.dart` — created in Plan 01 Task 2 (SC#3)
- [x] `test/unit/data/daos/transaction_dao_multi_book_test.dart` — created in Plan 02 Task 1 (SC#1, SC#2, SC#4)
- [x] `test/unit/data/repositories/transaction_repository_note_decrypt_test.dart` — created in Plan 03 Task 1 (SC#5)

*Existing flutter_test infrastructure covers all phase requirements — no framework install needed.*

---

## 5 Success Criteria → Validation Anchors

| SC | Wording | Validated By | Plan/Task | Test Command |
|----|---------|--------------|-----------|--------------|
| SC#1 | findByBookIds: single SQL, multi-book, excludes deleted, filters, SortField ORDER BY | Unit test: multi-book INSERT + findByBookIds + assert row count and order | 24-02 T1 | `flutter test test/unit/data/daos/transaction_dao_multi_book_test.dart` |
| SC#2 | watchByBookIds: emits within one rebuild cycle after insert/soft-delete/sync write, no ref.invalidate | Stream test: subscribe → write → await stream.first → assert emission | 24-02 T1 | `flutter test test/unit/data/daos/transaction_dao_multi_book_test.dart` |
| SC#3 | DateBoundaries: 00:00:00 and 23:59:59 inclusive, local time | 6 boundary tests including Feb non-leap + Dec year-boundary | 24-01 T2 | `flutter test test/unit/shared/utils/date_boundaries_test.dart` |
| SC#4 | Soft-delete: isDeleted=true only, hash fields unchanged, verifyChain(ALL rows)=valid | Insert 3-tx chain, softDelete middle, assert hash fields + verifyChain(all 3) valid | 24-02 T1 | `flutter test test/unit/data/daos/transaction_dao_multi_book_test.dart` |
| SC#5 | _toModel decrypt failure: note=null, all other fields intact, no ciphertext logging | Mock throwing EncryptionService, assert note=null + amount/categoryId intact | 24-03 T1 | `flutter test test/unit/data/repositories/transaction_repository_note_decrypt_test.dart` |

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|

*All phase behaviors have automated verification — this is a pure data-layer phase, no UI.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or are Wave 0 tasks creating the test files
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (test files created within plan tasks via TDD)
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** final
