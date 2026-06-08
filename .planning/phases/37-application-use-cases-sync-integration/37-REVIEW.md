---
phase: 37-application-use-cases-sync-integration
reviewed: 2026-06-08T00:00:00Z
depth: standard
files_reviewed: 26
files_reviewed_list:
  - lib/application/family_sync/apply_sync_operations_use_case.dart
  - lib/application/family_sync/shopping_item_change_tracker.dart
  - lib/application/family_sync/sync_orchestrator.dart
  - lib/application/shopping_list/clear_completed_items_use_case.dart
  - lib/application/shopping_list/create_shopping_item_use_case.dart
  - lib/application/shopping_list/delete_shopping_item_use_case.dart
  - lib/application/shopping_list/reorder_shopping_items_use_case.dart
  - lib/application/shopping_list/toggle_item_completed_use_case.dart
  - lib/application/shopping_list/update_shopping_item_use_case.dart
  - lib/features/family_sync/presentation/providers/repository_providers.dart
  - lib/features/family_sync/presentation/providers/state_sync.dart
  - lib/features/shopping_list/domain/models/shopping_item_sync_mapper.dart
  - lib/features/shopping_list/presentation/providers/repository_providers.dart
  - test/integration/sync/bill_sync_round_trip_test.dart
  - test/integration/sync/shopping_sync_round_trip_test.dart
  - test/unit/application/family_sync/apply_sync_operations_use_case_test.dart
  - test/unit/application/family_sync/phase6_sync_coverage_test.dart
  - test/unit/application/family_sync/shopping_item_change_tracker_test.dart
  - test/unit/application/shopping_list/clear_completed_items_use_case_test.dart
  - test/unit/application/shopping_list/create_shopping_item_use_case_test.dart
  - test/unit/application/shopping_list/delete_shopping_item_use_case_test.dart
  - test/unit/application/shopping_list/reorder_shopping_items_use_case_test.dart
  - test/unit/application/shopping_list/toggle_item_completed_use_case_test.dart
  - test/unit/application/shopping_list/update_shopping_item_use_case_test.dart
  - test/unit/features/family_sync/presentation/providers/sync_providers_characterization_test.dart
findings:
  critical: 1
  warning: 6
  info: 4
  total: 11
status: issues_found
---

# Phase 37: Code Review Report

**Reviewed:** 2026-06-08
**Depth:** standard
**Files Reviewed:** 26
**Status:** issues_found

## Summary

Phase 37 wires the shopping-list use cases into the family-sync pipeline:
`ShoppingItemChangeTracker`, the sync mapper, the apply-side merge in
`ApplySyncOperationsUseCase`, and orchestrator flushing. This re-review reflects
code **after** the committed `CR-01` fix (`4eb5d763 fix(37): preserve local
sortOrder on remote shopping update`). That fix is confirmed present at
`apply_sync_operations_use_case.dart:234-241` (`copyWith(..., sortOrder:
existing.sortOrder)`) and is covered by a regression test — the prior
"sortOrder clobbered to 0" BLOCKER is **resolved** and is not re-raised here.

The privacy gate (D37-06), listType immutability (D37-04), tombstone-wins for
existing rows (SC-4), deliberate-un-complete null-stamping (D37-02), and
local-sortOrder preservation (CR-01) are all implemented with tests.

The remaining dominant concern is the **conflict-resolution model in
`_handleShoppingUpdate`**: it is last-writer-*applies* (the incoming op always
overwrites local fields) with only a single completion-specific guard and no
general timestamp/staleness comparison. A stale remote op therefore silently
clobbers newer local edits for every field, and a stale remote *completion* can
revert a newer local *un-complete*. Combined with the still-present
unknown-ID-update resurrection gap, these are the data-correctness issues that
must be addressed for a multi-device feature.

No structural-findings block was provided, so the `## Structural Findings`
section is omitted and all findings below are narrative.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: `_handleShoppingUpdate` applies stale remote ops, clobbering newer local edits (no last-writer-wins guard)

**File:** `lib/application/family_sync/apply_sync_operations_use_case.dart:213-255`
**Issue:**
`_handleShoppingUpdate` rebuilds the item entirely from incoming wire data and
`upsert`s it. The ONLY staleness protection is the completion-specific guard at
lines 245-252:

```dart
if (existing.completedAt != null &&
    existing.completedAt!.isAfter(incomingUpdatedAt)) {
  updated = updated.copyWith(isCompleted: true, completedAt: existing.completedAt);
}
```

There is no comparison of `incomingUpdatedAt` against `existing.updatedAt` for
any other field. Two concrete failure modes follow:

1. **Stale edit overwrites a newer local edit (all non-completion fields).**
   Device A renames "Milk" → "Oat Milk" locally at T2. A stale remote update
   (name="Whole Milk", updatedAt=T1 < T2) then arrives and is applied
   unconditionally → the newer local "Oat Milk" is lost. `name`, `quantity`,
   `ledgerType`, `categoryId`, `tags`, `note`, and `estimatedPrice` all have the
   same exposure; the sticky-complete guard protects none of them.

2. **Asymmetric completion hole: a stale remote completion reverts a newer local
   un-complete.** Per `ToggleItemCompletedUseCase` (D37-02), a deliberate
   un-complete sets `completedAt = null`. A *stale* remote op
   (`isCompleted=true, completedAt=T1, updatedAt=T1`, T1 < local un-complete T2)
   then arrives. Because `existing.completedAt == null`, the guard at line 245 is
   skipped and the incoming `isCompleted=true` is applied — the older remote
   completion overrides the newer local un-check. This is the exact inverse of
   the case the guard protects and is **not covered by any test** (existing tests
   only exercise completed-local + stale-incomplete-remote).

The merge needs a symmetric, timestamp-based decision: drop the whole incoming
op when it is strictly older than the local row, rather than applying it and
patching one field.

**Fix:**
```dart
final existing = await _shoppingItemRepository.findById(entityId);
...
if (existing.isDeleted) return; // SC-4 unchanged

final incomingUpdatedAt = data['updatedAt'] != null
    ? DateTime.parse(data['updatedAt'] as String)
    : DateTime.now();

// Last-writer-wins: drop the entire stale op before merging any field.
final localUpdatedAt = existing.updatedAt ?? existing.createdAt;
if (incomingUpdatedAt.isBefore(localUpdatedAt)) {
  return; // local is newer — remote op is stale, ignore
}

final updated = ShoppingItemSyncMapper
    .fromSyncMap(data, fromDeviceId: null)
    .copyWith(id: entityId, sortOrder: existing.sortOrder);
await _shoppingItemRepository.upsert(updated);
```
(If a vector clock is the intended convergence mechanism, thread it through and
compare on it instead of `updatedAt` — the current code uses neither.)

## Warnings

### WR-01: "Unknown-ID update" path resurrects deleted items (tombstone guard skipped)

**File:** `lib/application/family_sync/apply_sync_operations_use_case.dart:217-223`
**Issue:**
When an `update` op arrives for an `entityId` not present locally, the handler
treats it as a create and upserts a live row. The SC-4 tombstone guard
(`if (existing.isDeleted) return;`, line 227) only runs on the
`existing != null` branch — it is skipped entirely on the unknown-ID branch.
`ShoppingItemSyncMapper.fromSyncMap` never parses `isDeleted` (defaults to
`false`), so the synthesized row is always live.

If a `delete` op is dropped (e.g. by the D37-05 fault-isolation `catch/continue`
at lines 52-61) or arrives after the `update` (out-of-order best-effort relay),
this path recreates a deleted item as a live row. The tombstone-wins guarantee
the `existing.isDeleted` check provides for known rows does not extend to rows
that were never created locally.

**Fix:** Do not fabricate a live row from an unknown-ID update; defer to fullSync:
```dart
if (existing == null) {
  return; // update for an ID we've never seen — let fullSync reconcile,
          // rather than fabricate a row that could resurrect a dropped tombstone
}
```
If create-on-update is genuinely required, gate it through a tombstone store that
survives row absence.

### WR-02: Delete / toggle / update operate on already-tombstoned rows (no `isDeleted` guard)

**File:** `lib/application/shopping_list/delete_shopping_item_use_case.dart:29-42`
(also `toggle_item_completed_use_case.dart:30-58`, `update_shopping_item_use_case.dart:70-111`)
**Issue:**
`findById` returns soft-deleted rows. None of these use cases check
`existing.isDeleted`. Deleting an already-deleted public item re-soft-deletes and
re-emits a `trackDelete` op; toggling/updating a tombstoned item logically
"revives" it (fresh `updatedAt`/`completedAt`/field values) and enqueues an
update op that the remote SC-4 guard will then reject — wasted sync traffic plus
a locally inconsistent row (`isDeleted=true` carrying a fresh `updatedAt`). The
fresh local `updatedAt` also interacts badly with CR-01's proposed LWW guard.
**Fix:** Treat a tombstoned row as not-actionable after fetch:
```dart
if (existing == null || existing.isDeleted) {
  return Result.error('ShoppingItem not found');
}
```

### WR-03: `incrementalPush` under-reports `pushedCount` (omits shopping + profile ops)

**File:** `lib/application/family_sync/sync_orchestrator.dart:167-191`
**Issue:**
`_executeIncrementalPush` flushes and pushes `txnOps`, `shoppingOps`, and
`profileOps`, but returns `SyncOrchestratorSuccess(pushedCount: txnOps.length)`
(line 191). When a push round contains shopping items and/or a profile change but
no transactions, `pushedCount` is `0` despite real work — any UI/telemetry
consuming it misreports "nothing synced."
**Fix:**
```dart
return SyncOrchestratorSuccess(
  pushedCount: txnOps.length + shoppingOps.length + profileOps.length,
);
```

### WR-04: Fault isolation applied to shopping ops only — bill/profile/avatar ops still abort the whole pull batch

**File:** `lib/application/family_sync/apply_sync_operations_use_case.dart:43-65`
**Issue:**
Only the `shopping_item` case wraps its handler in try/catch + `continue` (D37-05).
The `bill`, `profile`, and `avatar` cases have no isolation. A single malformed
bill op — e.g. the un-guarded `DateTime.parse(data['updatedAt'])` at line 169, or
any repository throw — propagates out of `execute` and aborts every remaining
operation in the pulled batch, including later shopping ops. The fault-isolation
rationale ("bad op must not abort other ops; next fullSync reconciles") applies
equally to bills, yet only shopping is protected. One poison record drops the
whole batch.
**Fix:** Hoist a per-operation try/catch around the entire `switch` body so every
entity type gets the same skip-and-continue isolation.

### WR-05: `fromSyncMap` throws on malformed `tags` JSON, discarding the whole record

**File:** `lib/features/shopping_list/domain/models/shopping_item_sync_mapper.dart:74-80`
**Issue:**
`jsonDecode(rawTags as List)` runs without try/catch. A malformed `tags` string
(or a JSON value that is not a list) throws `FormatException`/`TypeError`. On the
shopping path this is caught by the D37-05 isolation in `execute`, but the effect
is that *all* valid fields in that op are discarded wholesale because of one bad
sub-field, with only a debug print. Network-boundary input should be
coerced field-by-field, not let one corrupt field nuke the record.
**Fix:**
```dart
List<String> tags = const [];
final rawTags = data['tags'];
if (rawTags is String && rawTags.isNotEmpty) {
  try {
    final decoded = jsonDecode(rawTags);
    if (decoded is List) tags = decoded.map((e) => e.toString()).toList();
  } catch (_) {
    tags = const []; // corrupt tag payload — keep the rest of the item
  }
}
```

### WR-06: Misleading "encrypts at write boundary" comment — `note` is plaintext on the sync wire

**File:** `lib/features/shopping_list/domain/models/shopping_item_sync_mapper.dart:29`
**Issue:**
`toSyncMap` emits `'note': item.note` with the inline comment
"plaintext; ShoppingItemRepositoryImpl encrypts at write boundary." That
encryption boundary is the *local DB* path (`ShoppingItemRepositoryImpl._encryptNote`,
repo impl lines ~146-152). The sync push path serializes the domain model
directly and never passes through that repository, so the field-level ChaCha20
encryption the comment alludes to is NOT applied here. Confidentiality on the
wire depends entirely on the E2EE transport wrapping the whole payload. The
comment asserts protection this code path does not provide — exactly the false
reassurance that leads a maintainer to assume the note is already encrypted.
**Fix:** Correct the comment to state that `note` confidentiality relies on
transport-layer E2EE, not field encryption, and add an integration assertion that
a pushed shopping op is E2EE-wrapped before leaving the device.

## Info

### IN-01: `CreateShoppingItemParams.ledgerType` / `UpdateShoppingItemParams.ledgerType` typed as `dynamic`

**File:** `lib/application/shopping_list/create_shopping_item_use_case.dart:15`, `lib/application/shopping_list/update_shopping_item_use_case.dart:28`
**Issue:** Both declare `final dynamic ledgerType; // LedgerType? — nullable enum`.
`dynamic` silently accepts any value (e.g. a `String`), which only blows up later
at `params.ledgerType?.name` deep in the mapper. The domain type is known and
already imported via `shopping_item.dart`.
**Fix:** Type both as `LedgerType? ledgerType;` and import the enum.

### IN-02: Misleading sync-trigger name `onTransactionChanged()` used for shopping changes

**File:** all six shopping use cases (e.g. `create_shopping_item_use_case.dart:88`, `clear_completed_items_use_case.dart:48`)
**Issue:** Shopping use cases call `_syncEngine?.onTransactionChanged()` to
schedule a debounced push. The name implies a *financial transaction* change. It
works because the scheduler is entity-agnostic, but the name misleads future
maintainers into thinking shopping changes are not wired.
**Fix:** Add an entity-neutral alias (`onLocalChanged()` / `onSyncableChanged()`)
on `SyncEngine`, or document at the call sites that the trigger is intentionally
shared.

### IN-03: Duplicated profile-operation map construction

**File:** `lib/application/family_sync/sync_orchestrator.dart:218-230` and `271-283`
**Issue:** `_executeProfileSync` and `_buildProfileOperationsIfChanged` build the
identical profile-op envelope (`op/entityType/entityId/data/fromDeviceId/timestamp`).
Divergence risk on a future schema change.
**Fix:** Extract a private `_buildProfileOp(deviceId, displayName, avatarEmoji)`
helper and call it from both sites.

### IN-04: `flush()` debug log nests two `if`s where one `&&` suffices

**File:** `lib/application/family_sync/shopping_item_change_tracker.dart:66-72`
**Issue:** Minor readability — `if (kDebugMode) { if (ops.isNotEmpty) { ... } }`.
**Fix:** `if (kDebugMode && ops.isNotEmpty) debugPrint(...)`.

---

_Reviewed: 2026-06-08_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
