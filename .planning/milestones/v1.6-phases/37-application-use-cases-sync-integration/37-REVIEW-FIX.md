---
phase: 37-application-use-cases-sync-integration
fixed_at: 2026-06-08T00:00:00Z
review_path: .planning/phases/37-application-use-cases-sync-integration/37-REVIEW.md
iteration: 1
findings_in_scope: 7
fixed: 7
skipped: 0
status: all_fixed
---

# Phase 37: Code Review Fix Report

**Fixed at:** 2026-06-08
**Source review:** .planning/phases/37-application-use-cases-sync-integration/37-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 7 (1 Critical + 6 Warning; Info findings out of scope)
- Fixed: 7
- Skipped: 0

## Fixed Issues

### CR-01: `_handleShoppingUpdate` applies stale remote ops, clobbering newer local edits

**Files modified:** `lib/application/family_sync/apply_sync_operations_use_case.dart`
**Commit:** 2f2d5754 (shared with WR-01)
**Applied fix:** Added a symmetric last-writer-wins guard in `_handleShoppingUpdate`.
After the SC-4 tombstone check, the handler now computes
`localUpdatedAt = existing.updatedAt ?? existing.createdAt` and, when
`incomingUpdatedAt.isBefore(localUpdatedAt)`, drops the ENTIRE incoming op
(`return`) instead of applying it and patching a single field. This removes the
old completion-only guard (which protected only `completedAt`) and closes both
failure modes: stale remote edits can no longer clobber newer local
name/quantity/note/etc., and a stale remote completion can no longer revert a
newer local un-complete. sortOrder preservation (prior CR-01 fix) is retained.

**Note:** This is a logic/conflict-resolution change — requires human verification
that the LWW direction and equality boundary (`isBefore`, exclusive) match the
intended convergence semantics, and that existing sticky-complete unit tests are
updated for the new symmetric behavior.

### WR-01: "Unknown-ID update" path resurrects deleted items (tombstone guard skipped)

**Files modified:** `lib/application/family_sync/apply_sync_operations_use_case.dart`
**Commit:** 2f2d5754 (shared with CR-01)
**Applied fix:** The unknown-ID branch in `_handleShoppingUpdate` no longer
fabricates a live row via `fromSyncMap`/`upsert`. When `existing == null` it now
returns early, deferring reconciliation to the next fullSync. This prevents an
out-of-order or dropped `delete` op from being undone by a later `update` op that
would synthesize a live (non-tombstoned) row. The now-unused
`shopping_item.dart` import was removed (the bare `ShoppingItem` type
declaration was eliminated by the CR-01 restructure).

### WR-02: Delete / toggle / update operate on already-tombstoned rows

**Files modified:** `lib/application/shopping_list/delete_shopping_item_use_case.dart`, `lib/application/shopping_list/toggle_item_completed_use_case.dart`, `lib/application/shopping_list/update_shopping_item_use_case.dart`
**Commit:** fea9c41e
**Applied fix:** Changed the existence guard in all three use cases from
`existing == null` to `existing == null || existing.isDeleted`, so a
soft-deleted row returned by `findById` is treated as not-actionable. This stops
redundant re-soft-deletes / re-emitted tombstone ops and prevents tombstoned
rows from being "revived" with a fresh `updatedAt` (which would also interact
badly with the CR-01 LWW guard).

### WR-03: `incrementalPush` under-reports `pushedCount`

**Files modified:** `lib/application/family_sync/sync_orchestrator.dart`
**Commit:** 8d4a634b
**Applied fix:** `_executeIncrementalPush` now returns
`SyncOrchestratorSuccess(pushedCount: txnOps.length + shoppingOps.length + profileOps.length)`
so a push round containing shopping and/or profile ops but no transactions
reports the real count instead of 0.

### WR-04: Fault isolation applied to shopping ops only

**Files modified:** `lib/application/family_sync/apply_sync_operations_use_case.dart`
**Commit:** 8d06d025
**Applied fix:** Hoisted the per-operation `try/catch + continue` from the
`shopping_item`-only case to wrap the entire `switch` body in the `execute`
loop. Now bill, profile, avatar, and shopping ops all get the same
skip-and-continue isolation, so one poison record (e.g. an unguarded
`DateTime.parse` in a bill op) can no longer abort the remaining ops in the
pulled batch. The redundant inner shopping-only try/catch was removed; debug
logging now reports the failing `entityType`.

### WR-05: `fromSyncMap` throws on malformed `tags` JSON

**Files modified:** `lib/features/shopping_list/domain/models/shopping_item_sync_mapper.dart`
**Commit:** 862c5d7e (shared with WR-06)
**Applied fix:** Wrapped the `tags` decode in `fromSyncMap` in a try/catch and a
`decoded is List` type check. A malformed or non-list `tags` payload now falls
back to an empty list instead of throwing `FormatException`/`TypeError` and
discarding the entire valid record. Uses `.map((e) => e.toString())` for safer
element coercion.

### WR-06: Misleading "encrypts at write boundary" comment on `note`

**Files modified:** `lib/features/shopping_list/domain/models/shopping_item_sync_mapper.dart`
**Commit:** 862c5d7e (shared with WR-05)
**Applied fix:** Replaced the misleading inline comment with an accurate one:
`note` is emitted as plaintext on the sync wire; the field-level ChaCha20
encryption in `ShoppingItemRepositoryImpl._encryptNote` applies only on the
local DB write path, so wire confidentiality of `note` depends entirely on
transport-layer E2EE wrapping the whole payload, not on field encryption.

**Advisory (not applied):** The review's secondary suggestion to "add an
integration assertion that a pushed shopping op is E2EE-wrapped before leaving
the device" is test scaffolding beyond the comment correction and was not added
in this fix pass. Recommend adding it as a follow-up test task to make the
transport-E2EE guarantee explicit and regression-protected.

---

_Fixed: 2026-06-08_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
