---
phase: 37-application-use-cases-sync-integration
plan: "02"
subsystem: application/family-sync + features/shopping-list/domain
tags: [tdd, wave-1, tracker, mapper, privacy-gate, sync]
dependency_graph:
  requires:
    - "37-01 (Wave-0 RED test scaffolds)"
  provides:
    - ShoppingItemChangeTracker with D37-06 privacy gate (second safety net)
    - kShoppingItemEntityType constant defined once
    - ShoppingItemSyncMapper with toCreateOperation/toUpdateOperation/toSyncMap/fromSyncMap
  affects:
    - lib/application/family_sync/ (1 new file)
    - lib/features/shopping_list/domain/models/ (1 new file)
tech_stack:
  added: []
  patterns:
    - TransactionChangeTracker mirror pattern (exact structure + listType guard extension)
    - TransactionSyncMapper mirror pattern (static methods only, different fields)
    - D37-06 defense-in-depth: primary gate at use-case + secondary gate inside tracker
    - D37-01 sortOrder exclusion: documented in both docstring and inline comment
key_files:
  created:
    - lib/application/family_sync/shopping_item_change_tracker.dart
    - lib/features/shopping_list/domain/models/shopping_item_sync_mapper.dart
  modified: []
decisions:
  - "kShoppingItemEntityType const defined once in shopping_item_change_tracker.dart; imported by mapper (T-37-02 mitigation)"
  - "sortOrder excluded from toSyncMap with D37-01 inline comment (T-37-04 mitigation)"
  - "trackDelete always enqueues (no listType check); use-case is the primary D37-06 gate for deletes"
  - "fromSyncMap sets isSynced=true always; tags decoded with jsonDecode; ledgerType via switch (not .byName to avoid throwing on null)"
metrics:
  duration_minutes: 2
  completed_date: "2026-06-08"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 0
---

# Phase 37 Plan 02: ShoppingItemChangeTracker + ShoppingItemSyncMapper Summary

Wave-1 foundational utilities implemented — ShoppingItemChangeTracker (in-memory ops queue with D37-06 privacy gate) and ShoppingItemSyncMapper (wire protocol serializer/deserializer) — turning the tracker RED tests GREEN and enabling Wave 2 use cases to proceed.

## What Was Built

### Task 1: ShoppingItemChangeTracker (GREEN)

`lib/application/family_sync/shopping_item_change_tracker.dart`

Mirrors `TransactionChangeTracker` with two critical additions:

1. **`kShoppingItemEntityType = 'shopping_item'`** — defined exactly once here; imported by mapper. Prevents the typo vulnerability described in T-37-02.

2. **D37-06 privacy gate (second safety net)** — `trackCreate` and `trackUpdate` read `operation['data']['listType']`; if it is not `'public'`, the op is dropped silently without adding to `_pendingOps`. The use-case boundary is the primary gate; the tracker provides defense-in-depth.

3. **`trackDelete({required String itemId})`** — simplified signature vs the transaction analog (no `bookId` — shopping items have no book concept); always enqueues since delete ops have no `listType` in their payload.

4. **`flush()`** — returns copy of `_pendingOps` then clears; `debugPrint` label: `'[ShoppingChangeTracker] N ops flushed'`.

All 9 unit tests pass GREEN, including the 4 D37-06 privacy gate tests:
- `trackCreate ignores non-public listType (SC-3, SYNC-02)` → pendingCount == 0
- `trackCreate accepts public listType (SC-3, SYNC-01)` → pendingCount == 1
- `trackUpdate ignores non-public listType` → pendingCount == 0
- `trackDelete always enqueues (caller is responsible for gate)` → pendingCount == 1

### Task 2: ShoppingItemSyncMapper (0 analyzer issues)

`lib/features/shopping_list/domain/models/shopping_item_sync_mapper.dart`

Static-methods-only class (no constructor, no state) mirroring `TransactionSyncMapper` structure:

- **`toSyncMap(ShoppingItem item)`** — 14 wire fields; `ledgerType` encoded as `item.ledgerType?.name` (nullable enum → string); `tags` always encoded as `jsonEncode(item.tags)` (even empty list → `'[]'`); `note` passes as plaintext (repo encrypts at write boundary). `sortOrder`, `isDeleted`, `isSynced` explicitly excluded per D37-01.

- **`toCreateOperation(ShoppingItem item)`** — wraps `toSyncMap` in `{op: 'create', entityType: kShoppingItemEntityType, entityId: item.id, data: ..., timestamp: item.createdAt}`.

- **`toUpdateOperation(ShoppingItem item)`** — same shape with `op: 'update'`, timestamp uses `updatedAt ?? createdAt`.

- **`fromSyncMap(Map data, {String? fromDeviceId})`** — reconstructs `ShoppingItem`; `isSynced: true` always; tags: `jsonDecode` if non-null non-empty string, else `const []`; `ledgerType` via `_parseLedgerType` switch (safe — no `.byName` throwing on null/unknown); `completedAt` parsed from ISO 8601 string.

- **`_parseLedgerType(String? raw)`** — private helper; returns `LedgerType.daily`, `LedgerType.joy`, or `null`.

## Deviations from Plan

None — plan executed exactly as written.

The PATTERNS.md note about file placement (`lib/features/accounting/domain/models/` vs `lib/features/shopping_list/domain/models/`) was resolved by the plan frontmatter which declares `lib/features/shopping_list/domain/models/shopping_item_sync_mapper.dart` as the target path. Used that path.

## Known Stubs

None. Both files are complete implementations with no placeholders.

## Threat Flags

None. Both files are within the trust boundary declared in the plan's threat model. No new network endpoints, auth paths, or file access patterns introduced.

- T-37-01 (private item leak via tracker): **mitigated** — `trackCreate`/`trackUpdate` drop non-public ops
- T-37-02 (entityType string typo): **mitigated** — `kShoppingItemEntityType` defined once, imported everywhere
- T-37-04 (sortOrder in wire op): **mitigated** — `toSyncMap` excludes `sortOrder` with D37-01 inline comment; verified by grep
- T-37-SC (package installs): **accepted** — zero new packages

## Self-Check

### Files created:
- [x] `lib/application/family_sync/shopping_item_change_tracker.dart` — FOUND
- [x] `lib/features/shopping_list/domain/models/shopping_item_sync_mapper.dart` — FOUND

### Commits:
- [x] 018a6094 — feat(37-02): implement ShoppingItemChangeTracker with D37-06 privacy gate
- [x] 7a546e3a — feat(37-02): implement ShoppingItemSyncMapper with sortOrder exclusion

### Verification criteria:
- [x] `flutter test shopping_item_change_tracker_test.dart` exits 0 (9/9 GREEN)
- [x] `flutter analyze` on both files: 0 issues
- [x] sortOrder absent from wire map (only in comments, not in map literal)
- [x] `grep -c "kShoppingItemEntityType = 'shopping_item'" tracker.dart` = 1
- [x] `grep -c "kShoppingItemEntityType = " mapper.dart` = 0 (imported, not re-defined)

## Self-Check: PASSED
