---
phase: 37-application-use-cases-sync-integration
reviewed: 2026-06-08T00:00:00Z
depth: standard
files_reviewed: 13
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
findings:
  critical: 2
  warning: 5
  info: 3
  total: 10
status: issues_found
---

# Phase 37: Code Review Report

**Reviewed:** 2026-06-08
**Depth:** standard
**Files Reviewed:** 13
**Status:** issues_found

## Summary

Phase 37 wires shopping-list use cases into the P2P sync pipeline. The privacy gate
(D37-06), listType immutability (D37-04), and reorder-local-only (D37-01 at the
use-case layer) invariants are correctly enforced at the boundaries I traced. The
deliberate-un-complete null-stamping (D37-02) is implemented as documented.

However, the **apply side silently destroys the local-only `sortOrder` field every
time a remote update is applied**, defeating the same D37-01 invariant the mapper and
reorder use case worked to protect. There is also a tombstone-resurrection gap on the
"unknown-ID update" path. Both are correctness/data-integrity BLOCKERs. The remaining
findings are robustness and reporting-accuracy issues.

No structural-findings block was provided, so all findings below are narrative.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Applying a remote update clobbers the local-only `sortOrder` to 0 (breaks D37-01)

**File:** `lib/application/family_sync/apply_sync_operations_use_case.dart:213-250`
(root cause spans `lib/features/shopping_list/domain/models/shopping_item_sync_mapper.dart:70-106`
and `lib/data/daos/shopping_item_dao.dart:96-98`)

**Issue:**
D37-01 declares `sortOrder` local-per-device and the mapper deliberately *excludes* it
from the wire (`toSyncMap`, mapper:38). Consequently `fromSyncMap` never sets
`sortOrder`, so the reconstructed `ShoppingItem` carries the Freezed default
`sortOrder: 0` (shopping_item.dart:28).

`_handleShoppingUpdate` then persists that object via `_shoppingItemRepository.upsert`,
which calls `insertOnConflictUpdate` → `INSERT OR REPLACE` (dao:96-98). `INSERT OR
REPLACE` rewrites **every** column, so the existing row's locally-chosen `sortOrder` is
overwritten with `0`. Any remote edit (rename, quantity change, complete toggle) to an
item the local user has dragged into a custom position silently resets that item to the
top/`0` bucket. This is exactly the data loss D37-01 + the mapper exclusion were meant
to prevent.

The sticky-complete merge branch (lines 244-248) does not save this either — it
`copyWith`s only `isCompleted`/`completedAt` onto the same `sortOrder: 0` object.

The create path (`_handleShoppingCreate`) is fine for brand-new items (sortOrder 0 is a
correct default), but the *update* path must preserve the existing local value.

**Fix:** Read the existing row's `sortOrder` and re-apply it before upsert (the update
path already fetched `existing`):
```dart
ShoppingItem updated = ShoppingItemSyncMapper.fromSyncMap(
  data,
  fromDeviceId: null,
).copyWith(
  id: entityId,
  sortOrder: existing.sortOrder, // D37-01: never let sync clobber local order
);
```
Apply the same `sortOrder: existing.sortOrder` inside the sticky-complete branch.
Note the unknown-ID create-via-update branch (line 220-222) correctly keeps the default
0, so only the `existing != null` path needs the fix.

### CR-02: "Unknown-ID update" path resurrects deleted items / writes un-tombstoned ghosts

**File:** `lib/application/family_sync/apply_sync_operations_use_case.dart:217-223`

**Issue:**
When an `update` op arrives for an `entityId` not present locally, the handler treats it
as a create and upserts the item. But the SC-4 "tombstone wins" guard (line 227,
`if (existing.isDeleted) return;`) only runs on the `existing != null` branch — it is
*skipped entirely* on the unknown-ID branch.

This opens a resurrection window: if a delete op and a later (higher-clock but stale)
update op for the same item are delivered out of order, or if the delete op was dropped
by the D37-05 fault-isolation `catch/continue` (lines 52-61), the update will recreate a
"live" (`isDeleted = false`) row from `fromSyncMap`, which always sets
`isDeleted: false` (mapper never serializes/parses `isDeleted`). The deleted item comes
back. This directly undermines the tombstone-wins guarantee the `existing.isDeleted`
check is built to provide.

**Fix:** Do not synthesize a live row from an update op for an unknown ID. Either skip
(let the next fullSync reconcile a legitimately-missing create), or persist as a
tombstone-respecting create only when no tombstone could exist. Simplest safe option:
```dart
if (existing == null) {
  // An update for an ID we've never seen: defer to fullSync rather than
  // fabricate a live row that could resurrect a dropped/stale tombstone.
  return;
}
```
If create-on-update is genuinely required, route it through the same create handler
and ensure a prior delete can still win (e.g. consult a tombstone table) before writing
`isDeleted: false`.

## Warnings

### WR-01: Un-complete can be reverted by an arbitrarily stale remote `complete` op

**File:** `lib/application/family_sync/apply_sync_operations_use_case.dart:239-248`
and `lib/application/shopping_list/toggle_item_completed_use_case.dart:43-47`

**Issue:**
D37-02 clears `completedAt` to null on a deliberate un-complete so the sticky guard
skips. But because the guard *only* fires when `existing.completedAt != null`, once a
user un-completes (completedAt = null), **any** incoming op — including a `complete`
whose `updatedAt` is older than the un-complete — passes the guard and is applied
verbatim, re-completing the item. The guard has no last-writer-wins comparison on the
un-complete side; it relies entirely on `completedAt` presence. A late-arriving stale
"complete" silently reverts an intentional un-check. This matches the literal
documented behavior, but it is a real convergence hole worth flagging.

**Fix:** Compare `existing.updatedAt` against `incomingUpdatedAt` regardless of
completion state, and drop the incoming op when the local row is strictly newer:
```dart
if (existing.updatedAt != null &&
    existing.updatedAt!.isAfter(incomingUpdatedAt)) {
  return; // local edit (including un-complete) is newer — ignore stale remote
}
```

### WR-02: `incrementalPush` under-reports `pushedCount` (omits shopping + profile ops)

**File:** `lib/application/family_sync/sync_orchestrator.dart:167-191`

**Issue:**
`_executeIncrementalPush` flushes and pushes `shoppingOps` (line 167-175) and
`profileOps` (178-182), but the success result returns only
`SyncOrchestratorSuccess(pushedCount: txnOps.length)` (line 191). Callers/telemetry
relying on `pushedCount` will believe shopping-item pushes never happened, masking sync
activity and complicating diagnosis.

**Fix:**
```dart
return SyncOrchestratorSuccess(
  pushedCount: txnOps.length + shoppingOps.length + profileOps.length,
);
```

### WR-03: Delete / toggle / update operate on already-tombstoned rows (no `isDeleted` guard)

**File:** `lib/application/shopping_list/delete_shopping_item_use_case.dart:30-42`
(also `toggle_item_completed_use_case.dart:31-58`, `update_shopping_item_use_case.dart:71-111`)

**Issue:**
`findById` returns soft-deleted rows (dao:57-61, repo:99-103). None of these use cases
check `existing.isDeleted`. Deleting an already-deleted public item re-soft-deletes and
re-emits a tracker `trackDelete` op (delete:40-41); toggling/updating a tombstoned item
"revives" it logically (sets new `updatedAt`, new field values) and enqueues an update
op that the remote SC-4 guard will reject — wasted sync traffic and locally-inconsistent
state (a row that is `isDeleted=true` but just got a fresh `updatedAt`/`completedAt`).

**Fix:** After fetching `existing`, treat a tombstoned row as not-actionable:
```dart
if (existing == null || existing.isDeleted) {
  return Result.error('ShoppingItem not found');
}
```

### WR-04: `_handleShoppingUpdate` create-via-update branch trusts wire `id` from `data` then overrides — inconsistent source of truth

**File:** `lib/application/family_sync/apply_sync_operations_use_case.dart:219-222`

**Issue:**
`fromSyncMap(data)` reads `data['id']` (mapper:83) to build the item, then the handler
immediately `copyWith(id: entityId)` to override it. If `data['id']` and the envelope
`entityId` ever disagree (malformed/tampered op), the item is silently coerced to
`entityId` while every other field still comes from `data`. There is no validation that
the envelope and payload refer to the same entity. For a privacy/E2EE sync surface,
mismatched envelope-vs-payload identity should be rejected, not silently merged.

**Fix:** Validate consistency and reject on mismatch:
```dart
final payloadId = data['id'] as String?;
if (payloadId != null && payloadId != entityId) {
  return; // envelope/payload id mismatch — drop, let fullSync reconcile
}
```

### WR-05: `fromSyncMap` will throw on malformed `tags` JSON, defeating per-op fault isolation only partially

**File:** `lib/features/shopping_list/domain/models/shopping_item_sync_mapper.dart:74-80`

**Issue:**
`jsonDecode(rawTags as List)` runs without a try/catch. A malformed `tags` string (or a
JSON value that is not a list) throws `FormatException`/`TypeError`. For shopping ops
this is caught by the D37-05 `try/catch/continue` in `execute` (apply:52-61), so a
single bad op is skipped — acceptable. But the same `fromSyncMap` is also invoked from
`_handleShoppingCreate`/`_handleShoppingUpdate` and the result is that *valid* fields in
that op are discarded wholesale because of one bad sub-field, with only a debug print.
Input from the network boundary should be validated/coerced field-by-field rather than
letting one corrupt field nuke the whole record.

**Fix:** Wrap the tag decode defensively and fall back to empty:
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

## Info

### IN-01: `CreateShoppingItemParams.ledgerType` typed as `dynamic` defeats type safety

**File:** `lib/application/shopping_list/create_shopping_item_use_case.dart:15`
(also `update_shopping_item_use_case.dart:28`)

**Issue:** `final dynamic ledgerType; // LedgerType? — nullable enum`. The comment admits
the intended type is `LedgerType?`. Using `dynamic` silently accepts any value (e.g. a
`String`), which would only blow up later at `params.ledgerType?.name` deep in the
mapper. The domain model already imports `LedgerType` (shopping_item.dart:2).

**Fix:** Type it as `LedgerType? ledgerType;` and import the enum.

### IN-02: Misleading sync trigger name `onTransactionChanged()` used for shopping changes

**File:** all six shopping use cases (e.g. `create_shopping_item_use_case.dart:88`,
`clear_completed_items_use_case.dart:48`)

**Issue:** Shopping-item use cases call `_syncEngine?.onTransactionChanged()` to schedule
a debounced push. The name implies a *transaction* (financial ledger) change. It works
because the scheduler is entity-agnostic, but the name will mislead future maintainers
into thinking shopping changes are not wired. Consider a neutral `onLocalChanged()` /
`onSyncableChanged()` alias.

**Fix:** Add/rename to an entity-neutral method on `SyncEngine`, or document at the call
sites that it is intentionally shared.

### IN-03: `flush()` debug log nests two `if`s where one `&&` suffices

**File:** `lib/application/family_sync/shopping_item_change_tracker.dart:66-72`

**Issue:** Minor readability — `if (kDebugMode) { if (ops.isNotEmpty) { ... } }`. Flatten
to `if (kDebugMode && ops.isNotEmpty)`.

**Fix:** `if (kDebugMode && ops.isNotEmpty) debugPrint(...)`.

---

_Reviewed: 2026-06-08_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
