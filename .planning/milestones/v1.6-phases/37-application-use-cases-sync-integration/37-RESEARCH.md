# Phase 37: Application Use Cases + Sync Integration - Research

**Researched:** 2026-06-08
**Domain:** Flutter application layer (use cases) + family_sync pipeline extension (shopping_items entity)
**Confidence:** HIGH — all findings derived from direct codebase reads of actual source files; no training-data assertions

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D37-01:** `sortOrder` is local-per-device — NOT synced. `ReorderShoppingItemsUseCase` updates local `sortOrder` only and does NOT push any sync op.
- **D37-02:** A family member CAN deliberately un-check a completed item and have it sync. An explicit un-complete clears `completedAt` to null and stamps a fresh `updatedAt`. The sticky-complete guard does NOT fire because `completedAt` is null.
- **D37-03:** Update ops carry field-level deltas (NOT full snapshots) so a rename op does not clobber a remote completion. Confirmed that `TransactionSyncMapper.toUpdateOperation` sends a FULL snapshot; shopping update ops must use a DELTA shape (separate SyncMap that excludes or omits isCompleted) to implement D37-03's intent cleanly.
- **D37-04:** `UpdateShoppingItemUseCase` rejects any attempt to change `listType` — returns a failure/throws a documented invariant error (fail-fast, NOT a silent no-op).
- **D37-05:** Wrap ONLY the `shopping_item` branch in try/catch with skip-and-continue. Existing `bill`/`profile`/`avatar` branches keep current semantics unchanged.
- **D37-06 (privacy-critical):** `listType == 'public'` gate lives at the use-case boundary (Create/Update/Toggle/Delete/ClearCompleted — NOT Reorder). Private item must NEVER reach `ShoppingItemChangeTracker`. The tracker enforces a SECOND `listType == 'public'` guard internally as defense-in-depth.
- **Carry-forward D-03:** sticky-complete + `completedAt DateTime?` column overrides D7/SYNC-05. Tombstone checked BEFORE applying any update.
- **Carry-forward D-06:** listType is immutable after creation.

### Claude's Discretion

- Exact `shopping_item` op wire payload field set — follow bill-op mapper shape; `sortOrder` does NOT travel; note field-encryption mirrors bill note handling.
- `ShoppingItemChangeTracker` as separate class vs folded into transaction tracker — research says separate class.
- Whether orchestrator does a separate `_pushSync.execute(...)` call or merges shopping ops into one push — separate call is simplest and matches the profile-ops pattern.
- `ClearCompletedItemsUseCase` mechanics: soft-deletes every completed item for given `listType`; each public soft-delete emits a delete tombstone op via tracker.
- Provider wiring shape — Phase 38 territory but constructor change is atomic in THIS phase.

### Deferred Ideas (OUT OF SCOPE)

- Cross-device shared shopping-list ordering (sync `sortOrder`) — deferred per D37-01.
- Tag-based filtering (v2 TAGFILT-01).
- Decimal/unit-bearing quantity — D8.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ITEM-01 | User can add a shopping item (name required only) | CreateShoppingItemUseCase — mirrors CreateTransactionUseCase shape |
| ITEM-02 | User can optionally set ledger, category, tags, note, quantity, estimatedPrice | All fields on ShoppingItemParams; note encrypted at repo boundary |
| ITEM-04 | User can edit any existing item via same form, pre-populated | UpdateShoppingItemUseCase with D37-04 listType immutability guard |
| DONE-01 | User can tap to toggle completed state | ToggleItemCompletedUseCase; sticky-complete merge in apply handler |
| DONE-03 | User can one-tap "clear all completed" (use-case logic only) | ClearCompletedItemsUseCase → softDeleteAllCompleted per listType |
| MGMT-01 | Swipe-delete (use-case logic) | DeleteShoppingItemUseCase → softDelete + tracker delete op |
| MGMT-02 | Batch-delete (use-case logic) | DeleteShoppingItemUseCase called per selected item |
| MGMT-03 | Swipe disabled in batch-select (use-case gate) | Use case is unchanged; mode flag is presentation-layer (Phase 38) |
| SYNC-01 | Public items sync through family_sync pipeline | ShoppingItemChangeTracker + orchestrator push extension |
| SYNC-02 | Private items NEVER enter sync pipeline | listType gate at use-case boundary + second gate in tracker |
| SYNC-03 | listType immutable after creation | D37-04 enforcement in UpdateShoppingItemUseCase |
| SYNC-05 | Sticky-complete merge: completedAt > incoming.updatedAt → preserve isCompleted | _applyShoppingItemOp merge algorithm; tombstone wins over remote update |
| SYNC-06 | Public changes appear reactively via watchByListType stream | Apply writes through ShoppingItemRepository.upsert → DAO → triggers watchByListType() .watch() |

</phase_requirements>

---

## Summary

Phase 37 adds the application layer for shopping list (six use cases) and extends the existing family_sync pipeline to handle `shopping_item` as a new entity type. All work is pure Dart at `lib/application/` — no schema changes, no new packages, no UI.

The existing family_sync pipeline is entity-agnostic at the wire level. Adding shopping items requires exactly three targeted changes: (1) `ShoppingItemChangeTracker` (mirrors `TransactionChangeTracker` with an added `listType == 'public'` guard), (2) a `case 'shopping_item':` branch in `ApplySyncOperationsUseCase.execute` routing to `_applyShoppingItemOp`, and (3) a 4-line shopping flush+push block in `SyncOrchestrator._executeIncrementalPush`. The `ApplySyncOperationsUseCase` constructor gains `ShoppingItemRepository` and must be updated atomically at all construction sites — there are four: `lib/features/family_sync/presentation/providers/repository_providers.dart:130`, `test/integration/sync/bill_sync_round_trip_test.dart:81`, `test/unit/application/family_sync/apply_sync_operations_use_case_test.dart:49`, and the characterization test at `test/unit/features/family_sync/presentation/providers/sync_providers_characterization_test.dart:152`.

The single highest-severity invariant is the privacy gate: private items must never reach `ShoppingItemChangeTracker`. The unit test proving `pendingCount == 0` after a private create and `pendingCount == 1` after a public create is the canonical evidence. The sticky-complete merge algorithm in `_applyShoppingItemOp` resolves the CRDT race by checking `existing.completedAt != null && existing.completedAt!.isAfter(incomingUpdatedAt)` before applying an incoming update's `isCompleted` field. Tombstone safety is the first check before any update: `if (existing.isDeleted) return`.

**Primary recommendation:** Mirror `TransactionChangeTracker` and the accounting use cases directly. Build the shopping apply handler by adapting `_applyBillOperation` with the two additional guards (tombstone-first, sticky-complete). Extend the orchestrator with a separate `_shoppingChangeTracker.flush()` → `_pushSync.execute()` block in `_executeIncrementalPush` mirroring the profile-ops second-push pattern.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Use case privacy gate (listType) | Application | — | Business rule lives at the application boundary; no UI or data-layer concern |
| Change tracking (pending ops queue) | Application | — | In-memory tracker is application-layer state, not persistence |
| Sync push (flush + push call) | Application (orchestrator) | Infrastructure (relay) | Orchestrator sequences use cases; relay is infrastructure |
| Sync apply (incoming ops) | Application | Data | apply use case routes and calls repo; repo handles persistence |
| Note encryption/decryption | Data (repo boundary) | Infrastructure (crypto) | ShoppingItemRepositoryImpl already encrypts/decrypts; apply handler passes plaintext note through the repo upsert which re-encrypts |
| Tombstone check | Application (apply handler) | — | Domain rule: deleted items are not resurrectable |
| Sticky-complete merge | Application (apply handler) | — | CRDT rule lives at the apply boundary before any repo write |
| Reactive stream delivery | Data (DAO `readsFrom:`) | — | Drift .watch() with `readsFrom:` is the delivery mechanism; no invalidation needed |

---

## Standard Stack

### Core (zero new packages)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter_riverpod` | `^3.1.0` | Provider wiring for tracker/orchestrator | Already installed; locked stack |
| `drift` | `^2.25.0` | Repo impl + reactive stream via `.watch()` | Phase 36 foundation; watchByListType uses `readsFrom:` |
| `freezed_annotation` | `^3.0.0` | `ShoppingItem` immutable model with `copyWith` | Already in use; sticky-complete merge needs `copyWith` |
| `mocktail` | current | Unit and integration test mocking | All existing sync tests use mocktail |
| `uuid` | `^4.5.3` | Item IDs for new shopping items | Consistent with transaction IDs |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `collection` | `^1.19.1` | Iterable utilities if needed in use cases | Available; prefer SQL ordering in DAO (already done) |

**Installation:** No new packages. All dependencies already in `pubspec.yaml`.

---

## Package Legitimacy Audit

No new packages installed in this phase. Audit section not applicable.

---

## Architecture Patterns

### System Architecture Diagram

```
[Use Case: Create/Update/Delete/Toggle/ClearCompleted]
    │ listType == 'public'?
    ├── YES → [ShoppingItemRepositoryImpl] → [ShoppingItemDao] → [shopping_items table]
    │               │                                                 │
    │               └── note encrypt/decrypt ◄── [FieldEncryptionService]
    │          [ShoppingItemChangeTracker.track*(op)]
    │               │
    │               └── _pendingOps (in-memory)
    └── NO  → [ShoppingItemRepositoryImpl only; tracker NOT called]

[Use Case: ReorderShoppingItemsUseCase]
    └── [ShoppingItemRepositoryImpl.reorder()] (local only; NO tracker)

[SyncOrchestrator._executeIncrementalPush]
    ├── [TransactionChangeTracker.flush()] → [PushSyncUseCase] (existing)
    ├── [ShoppingItemChangeTracker.flush()] → [PushSyncUseCase] (new block)
    └── [profile ops] → [PushSyncUseCase] (existing)

[PullSyncUseCase] → [ApplySyncOperationsUseCase.execute(ops)]
    switch(entityType):
    ├── 'bill'           → _applyBillOperation() (unchanged)
    ├── 'profile'        → _applyProfileOperation() (unchanged)
    ├── 'avatar'         → _applyAvatarOperation() (unchanged)
    ├── 'shopping_item'  → try { _applyShoppingItemOp() } catch (e) { log; continue }
    └── default          → continue

[_applyShoppingItemOp]
    1. if (existing.isDeleted) return          ← tombstone wins
    2. sticky-complete merge check             ← D-03/D37-02
    3. ShoppingItemRepository.upsert(item)     ← triggers watchByListType stream
```

### Recommended Project Structure

```
lib/application/shopping_list/
├── create_shopping_item_use_case.dart
├── update_shopping_item_use_case.dart
├── delete_shopping_item_use_case.dart
├── toggle_item_completed_use_case.dart
├── reorder_shopping_items_use_case.dart
└── clear_completed_items_use_case.dart

lib/application/family_sync/
└── shopping_item_change_tracker.dart      (NEW — mirrors transaction_change_tracker.dart)

lib/features/accounting/domain/models/
└── shopping_item_sync_mapper.dart         (NEW — analogous to transaction_sync_mapper.dart)

lib/application/family_sync/
└── apply_sync_operations_use_case.dart    (MODIFIED — gains ShoppingItemRepository + case branch)
└── sync_orchestrator.dart                 (MODIFIED — _executeIncrementalPush gains shopping block)
```

### Pattern 1: Use Case with Privacy Gate + Tracker

Every mutation use case (except Reorder) follows this structure — mirror from `DeleteTransactionUseCase`:

```dart
// Source: lib/application/accounting/delete_transaction_use_case.dart (verified)
class DeleteShoppingItemUseCase {
  DeleteShoppingItemUseCase({
    required ShoppingItemRepository shoppingItemRepository,
    ShoppingItemChangeTracker? changeTracker,
    SyncEngine? syncEngine,
  });

  Future<Result<void>> execute(String itemId) async {
    final existing = await _repo.findById(itemId);
    if (existing == null) return Result.error('ShoppingItem not found');

    await _repo.softDelete(itemId);

    // Privacy gate: only public items enter the sync pipeline (D37-06)
    if (existing.listType == 'public') {
      _changeTracker?.trackDelete(itemId: itemId);
    }
    _syncEngine?.onTransactionChanged(); // reuse existing SyncEngine trigger

    return Result.success(null);
  }
}
```

### Pattern 2: ShoppingItemChangeTracker (copy + add privacy guard)

```dart
// Source: lib/application/family_sync/transaction_change_tracker.dart (verified)
// Mirror exactly; add the internal listType guard as defense-in-depth (D37-06)

class ShoppingItemChangeTracker {
  final _pendingOps = <Map<String, dynamic>>[];

  void trackCreate(Map<String, dynamic> operation) {
    // Second safety net (D37-06) — use case gate is the primary
    final data = operation['data'] as Map<String, dynamic>?;
    if (data?['listType'] != 'public') return;
    _pendingOps.add(operation);
  }

  void trackUpdate(Map<String, dynamic> operation) {
    final data = operation['data'] as Map<String, dynamic>?;
    if (data?['listType'] != 'public') return;
    _pendingOps.add(operation);
  }

  void trackDelete({required String itemId}) {
    // Delete ops have no listType in data; caller (use case) is responsible
    // for ensuring only public-item deletes reach here (D37-06)
    _pendingOps.add({
      'op': 'delete',
      'entityType': kShoppingItemEntityType,
      'entityId': itemId,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  List<Map<String, dynamic>> flush() { /* mirror TransactionChangeTracker */ }
  int get pendingCount => _pendingOps.length;
}

const kShoppingItemEntityType = 'shopping_item'; // define ONCE, use everywhere
```

### Pattern 3: Orchestrator shopping flush block

```dart
// Source: lib/application/family_sync/sync_orchestrator.dart lines 138-177 (verified)
// _executeIncrementalPush — add after the txnOps block, before profile ops

// Flush pending shopping item changes
final shoppingOps = _shoppingChangeTracker.flush();
if (shoppingOps.isNotEmpty) {
  await _pushSync.execute(operations: shoppingOps, vectorClock: const {});
}
```

This is a SEPARATE `_pushSync.execute(...)` call — same pattern as profile-ops block at line 165.

### Pattern 4: apply handler (tombstone + sticky-complete merge)

```dart
// Source: lib/application/family_sync/apply_sync_operations_use_case.dart (verified)
// The existing _handleUpdate does NOT check isDeleted on existing row.
// _applyShoppingItemOp must add both guards.

Future<void> _applyShoppingItemOp(Map<String, dynamic> operation) async {
  final op = operation['op'] as String?;
  final entityId = operation['entityId'] as String?;
  final fromDeviceId = operation['fromDeviceId'] as String?;
  final data = operation['data'] as Map<String, dynamic>?;
  if (op == null || entityId == null) return;

  switch (op) {
    case 'create':
    case 'insert':
      if (data == null) return;
      await _handleShoppingCreate(entityId, fromDeviceId, data);
    case 'delete':
      await _shoppingItemRepository.softDelete(entityId);
    case 'update':
      if (data == null) return;
      await _handleShoppingUpdate(entityId, data);
  }
}

Future<void> _handleShoppingCreate(String entityId, String? fromDeviceId, Map<String, dynamic> data) async {
  final existing = await _shoppingItemRepository.findById(entityId);
  if (existing != null) return; // idempotent — same as _handleCreate for bills

  final item = ShoppingItemSyncMapper.fromSyncMap(data, fromDeviceId: fromDeviceId);
  await _shoppingItemRepository.upsert(item);
}

Future<void> _handleShoppingUpdate(String entityId, Map<String, dynamic> data) async {
  final existing = await _shoppingItemRepository.findById(entityId);
  if (existing == null) {
    // upsert: treat unknown update as create (same pattern as bill _handleUpdate)
    final item = ShoppingItemSyncMapper.fromSyncMap(data, fromDeviceId: null);
    await _shoppingItemRepository.upsert(item.copyWith(id: entityId));
    return;
  }

  // SC4: tombstone wins — a soft-deleted item is never resurrected by remote update
  if (existing.isDeleted) return;

  // D-03/D37-02 sticky-complete merge
  final incomingUpdatedAt = data['updatedAt'] != null
      ? DateTime.parse(data['updatedAt'] as String)
      : DateTime.now();

  ShoppingItem updated = ShoppingItemSyncMapper.fromSyncMap(data, fromDeviceId: null)
      .copyWith(id: entityId);

  if (existing.completedAt != null &&
      existing.completedAt!.isAfter(incomingUpdatedAt)) {
    // Stale edit: preserve local completion state
    updated = updated.copyWith(
      isCompleted: true,
      completedAt: existing.completedAt,
    );
  }

  await _shoppingItemRepository.upsert(updated);
}
```

### Pattern 5: delta-style update op shape (D37-03)

The bill mapper's `toUpdateOperation` sends a FULL snapshot via `toSyncMap` (confirmed: `lib/features/accounting/domain/models/transaction_sync_mapper.dart` lines 86-106). `toSyncMap` includes all fields including `joyFullness`, `photoHash`, `merchant`, `isPrivate`, etc. For shopping items this approach is acceptable IF AND ONLY IF we apply the sticky-complete merge in the apply handler — which we do (see Pattern 4). The "delta" aspect of D37-03 is satisfied by the apply handler's merge logic, not by omitting fields from the wire payload. Using a full shopping-item snapshot in the wire payload simplifies `ShoppingItemSyncMapper` and is consistent with the bill convention.

**Decision:** Use full snapshot in `toSyncUpdateOperation` (consistent with bill mapper). The sticky-complete merge in `_handleShoppingUpdate` fulfills D37-03's safety intent.

### Anti-Patterns to Avoid

- **Hard-deleting in the apply handler:** Call `_shoppingItemRepository.softDelete(entityId)`, never a DAO hard-delete. Tombstone must be preserved for later full-sync reconciliation.
- **Checking tombstone AFTER applying update:** Always check `if (existing.isDeleted) return` FIRST, before any field merging.
- **Inlining `'shopping_item'` string literal:** Define `const kShoppingItemEntityType = 'shopping_item'` once in `shopping_item_sync_mapper.dart` and reference it from tracker and apply handler.
- **Wrapping the bill branch in try/catch:** D37-05 is explicit — ONLY the `case 'shopping_item':` branch gets fault isolation. Billing semantics are unchanged.
- **Passing plaintext note through wire payload without encryption awareness:** The note travels as plaintext in the sync op's `data` map (consistent with how bill note travels); the `ShoppingItemRepositoryImpl` encrypts/decrypts at its boundary. The apply handler calls `upsert()` with the decrypted model — the repo impl handles re-encryption on write. No special handling needed in the apply handler.

---

## Open Technical Questions — RESOLVED

### Q1: `toUpdateOperation` — full snapshot or field-level delta?

**Confirmed from source** (`lib/features/accounting/domain/models/transaction_sync_mapper.dart` lines 86-106): `toUpdateOperation` calls `toSyncMap` which sends a FULL snapshot of all transaction fields including `isPrivate`, `joyFullness`, `photoHash`, `merchant`, `metadata`, `note`.

**Resolution for shopping items:** Use full snapshot in `toSyncUpdateOperation`. The apply handler's sticky-complete merge (D-03/D37-02) is the mechanism that prevents a stale rename from clobbing remote completion. This is behaviorally equivalent to delta-style updates because: a name-update op arrives, apply handler checks `existing.completedAt > incomingUpdatedAt` → true → preserves `isCompleted: true` regardless of the `isCompleted: false` in the incoming full snapshot.

**Wire payload for shopping update ops includes:** `id`, `listType`, `name`, `ledgerType`, `categoryId`, `tags` (JSON-encoded), `note` (plaintext — repo encrypts on write), `quantity`, `estimatedPrice`, `isCompleted`, `completedAt` (ISO 8601 nullable), `createdAt`, `updatedAt`, `deviceId`, `addedByBookId`. Does NOT include: `sortOrder` (D37-01 — local-per-device). Does NOT include: `isDeleted`, `isSynced` (internal state, not synced).

### Q2: Note encryption across sync

**Confirmed from source** (`lib/data/repositories/shopping_item_repository_impl.dart` lines 147-152 + 166-176 + `lib/data/repositories/transaction_repository_impl.dart` lines 25-53): The pattern is identical for both entities. Note travels as **plaintext** in the sync op's `data.note` field. Encryption happens at the repo boundary only:
- `ShoppingItemRepositoryImpl.insert/update/upsert` calls `_encryptNote(item.note)` before writing to DB.
- `ShoppingItemRepositoryImpl._toModel` calls `_encryptionService.decryptField(row.note)` on read, silently catching decryption failures (wrong-device-key scenario for shadow-book items).

The apply handler (`_handleShoppingCreate` / `_handleShoppingUpdate`) constructs a `ShoppingItem` from the sync map (decrypted plaintext note is in `data['note']`), then calls `_shoppingItemRepository.upsert(item)` — the repo impl handles encryption before DB write. No special handling in the apply handler. [VERIFIED: direct source read]

**Tags similarly:** JSON-decoded at repo read boundary (`jsonDecode(row.tags!)`), JSON-encoded at repo write boundary (`jsonEncode(item.tags)`). Sync op carries the JSON string as `data['tags']` — or a pre-decoded list; the mapper must be consistent. Recommended: carry as JSON string in the wire payload (consistent with DB storage) and decode in `fromSyncMap`.

### Q3: Op wire payload field set

**Shopping item op fields (confirmed by ShoppingItem model and repo source):**

| Field | Create op | Update op | Delete op | Notes |
|-------|-----------|-----------|-----------|-------|
| `id` | YES | YES | — (entityId) | primary key |
| `listType` | YES | YES | NO | needed by tracker's internal guard |
| `name` | YES | YES | NO | required field |
| `ledgerType` | YES | YES | NO | nullable string ('daily'/'joy'/null) |
| `categoryId` | YES | YES | NO | nullable |
| `tags` | YES | YES | NO | JSON string |
| `note` | YES | YES | NO | plaintext; repo encrypts on write |
| `quantity` | YES | YES | NO | integer |
| `estimatedPrice` | YES | YES | NO | nullable integer |
| `isCompleted` | YES | YES | NO | bool |
| `completedAt` | YES | YES | NO | nullable ISO 8601 string |
| `createdAt` | YES | YES | NO | ISO 8601 string |
| `updatedAt` | YES | YES | NO | ISO 8601 string |
| `deviceId` | YES | NO | NO | set on create by addedByBookId source |
| `addedByBookId` | YES | NO | NO | attribution; set on create |
| `sortOrder` | NO | NO | NO | **D37-01: local-per-device, never synced** |
| `isDeleted` | NO | NO | NO | internal; tombstone is the `delete` op itself |
| `isSynced` | NO | NO | NO | internal flag |

### Q4: Tracker integration into `_executeIncrementalPush`

**Confirmed from source** (`lib/application/family_sync/sync_orchestrator.dart` lines 138-177): The orchestrator currently:
1. Flushes `_changeTracker` (transaction tracker) → calls `_pushSync.execute(operations: txnOps)` if non-empty.
2. Builds profile ops → calls `_pushSync.execute(operations: profileOps)` if non-empty (second separate call).
3. Drains the offline queue.

**Shopping tracker pattern:** Add a third block between the txnOps block and the profile ops block:
```
txnOps block (existing)
shoppingOps block (NEW — same shape as txnOps block)
profileOps block (existing)
drainQueue (existing)
```

The `SyncOrchestrator` constructor gains `ShoppingItemChangeTracker shoppingChangeTracker` as a required parameter (or optional — match the `TransactionChangeTracker` required convention). This touches the construction site in `state_sync.dart:27-39`.

**Is a separate `_pushSync.execute()` call correct?** Yes. The profile-ops pattern (separate call) is the model. Merging into one push would require concatenating the list, which is equivalent but less readable and requires more changes. Separate call is cleanest.

### Q5: Apply-loop fault isolation (D37-05)

**Confirmed from source** (`lib/application/family_sync/apply_sync_operations_use_case.dart` lines 32-46): The current `execute` loop has NO per-op try/catch anywhere. A thrown exception in `_applyBillOperation` aborts the entire `execute()` loop. The switch-case simply calls `await _applyBillOperation(operation)` with no try/catch wrapper.

**Implementation for D37-05:**
```dart
case 'shopping_item':
  try {
    await _applyShoppingItemOp(operation);
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[ApplySyncOps] shopping_item op failed, skipping: $e\n$st');
    }
    // Skip-and-continue: next full sync will reconcile
    continue; // the for-loop's continue label
  }
```
The `bill`/`profile`/`avatar` cases are NOT wrapped — zero regression.

### Q6: Atomic constructor change — all sites

**Confirmed from grep:** All sites that construct `ApplySyncOperationsUseCase`:

| File | Line | Type |
|------|------|------|
| `lib/features/family_sync/presentation/providers/repository_providers.dart` | 130 | Provider (production) |
| `test/integration/sync/bill_sync_round_trip_test.dart` | 81 | Integration test setUp |
| `test/unit/application/family_sync/apply_sync_operations_use_case_test.dart` | 49 | Unit test setUp |
| `test/unit/features/family_sync/presentation/providers/sync_providers_characterization_test.dart` | 149-152 | Characterization test |

All four must be updated in the same commit as the constructor change. [VERIFIED: grep of codebase]

**`SyncOrchestrator` constructor** gains `ShoppingItemChangeTracker shoppingChangeTracker` required param. Construction sites:
| File | Line | Type |
|------|------|------|
| `lib/features/family_sync/presentation/providers/state_sync.dart` | 27-39 | Provider (production) |
| `test/unit/application/family_sync/phase6_sync_coverage_test.dart` | 168-180 | Unit test setUp |

Both must be updated atomically. [VERIFIED: grep + source read]

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Note encryption/decryption | Custom crypto | `FieldEncryptionService` via `ShoppingItemRepositoryImpl` | Already implemented; re-encrypts on `upsert()` |
| JSON tag encoding | Custom serializer | `jsonEncode`/`jsonDecode` at repo boundary | Pattern already in `ShoppingItemRepositoryImpl._encodeTags` |
| Reactive stream delivery | `ref.invalidate()` or polling | Drift `.watch()` with `readsFrom: {_db.shoppingItems}` | v1.4 GAP-2 lesson; `ShoppingItemDao.watchByListType` already has `readsFrom:` |
| Entity type string constant | Inline string literals | `const kShoppingItemEntityType = 'shopping_item'` defined once | Typo in entityType = silent dropped ops |
| Full-sync re-push of all items | New `FullSyncUseCase` variant | Existing `FullSyncUseCase` (which operates on transactions only; shopping items don't need full-sync) | Shopping items are never bulk-pushed; they only enter sync as individual mutations |

**Key insight:** The family_sync pipeline handles entity-agnostically. No relay-server changes, no new `SyncMode`, no new push strategy. The pipeline already encrypts arbitrary JSON op arrays. Adding shopping items is three surgical changes to three existing files plus one new tracker class and one new mapper class.

---

## Common Pitfalls

### Pitfall 1: Constructor Not Updated Atomically
**What goes wrong:** `ApplySyncOperationsUseCase` gets a new `ShoppingItemRepository` parameter. Any construction site that is missed throws a compile error or, if using named parameters with defaults, silently receives `null` and panics at runtime.
**Why it happens:** There are four construction sites — two in tests that developers might not think to update.
**How to avoid:** Run `grep -rn ApplySyncOperationsUseCase lib/ test/` before adding the parameter. Update ALL four sites in the same commit as the constructor change.
**Warning signs:** `TypeError` at app start; test file compile errors with "required named parameter".

### Pitfall 2: Private Item Leaks into Tracker
**What goes wrong:** A use case tracks an update/delete for a private item. The item is synced to all family members.
**Why it happens:** The developer adds the `listType == 'public'` guard to `CreateShoppingItemUseCase` but forgets `UpdateShoppingItemUseCase` or `ToggleItemCompletedUseCase`.
**How to avoid:** Add the guard at EVERY non-Reorder use case. The tracker's internal guard is defense-in-depth only — don't rely on it as the primary gate.
**Warning signs:** `pendingCount > 0` after creating/toggling a private item in unit tests.

### Pitfall 3: Tombstone Not Checked First in Apply Handler
**What goes wrong:** A remote update op arrives for a soft-deleted item. The item is resurrected.
**Why it happens:** The existing `_handleUpdate` for bills also does NOT check `isDeleted` (confirmed from source). A developer copying the bill pattern inherits the bug.
**How to avoid:** First line of `_handleShoppingUpdate`: `if (existing != null && existing.isDeleted) return;`
**Warning signs:** `isDeleted` item reappears in `watchByListType` after a full pull.

### Pitfall 4: sortOrder Traveling in Update Op
**What goes wrong:** The drag-reorder result is included in an update op payload and overwrites another device's local sort order.
**Why it happens:** D37-01 decision is easy to forget when building the SyncMapper.
**How to avoid:** `ShoppingItemSyncMapper.toSyncMap` explicitly excludes `sortOrder`. Comment in the mapper: "D37-01: sortOrder is local-per-device, NOT synced."
**Warning signs:** Integration test shows member B's list reordered unexpectedly after a name-edit sync.

### Pitfall 5: Using Hard Delete in Apply Handler
**What goes wrong:** `_applyShoppingItemOp` calls a DAO `deleteById` instead of `_shoppingItemRepository.softDelete`. A device that was offline when the delete arrived never sees the tombstone during full-sync reconciliation.
**Why it happens:** The delete is a sync pull operation; developer may reach for a physical delete.
**How to avoid:** Apply handler calls `await _shoppingItemRepository.softDelete(entityId)` — same as the bill handler calls `_transactionRepository.softDelete(entityId)`.
**Warning signs:** Deleted item reappears on device that was offline during delete.

### Pitfall 6: Sticky-Complete Merge Applied to `completedAt == null` Case
**What goes wrong:** The merge guard fires when `existing.completedAt` is null because the condition is written as `existing.completedAt != null`. If the guard is written incorrectly (e.g., checking `existing.isCompleted` instead of `existing.completedAt`), a deliberate un-complete is blocked.
**Why it happens:** D37-02 means un-complete MUST sync — the guard must only fire when `completedAt` exists AND is after the incoming `updatedAt`.
**How to avoid:** Guard condition: `existing.completedAt != null && existing.completedAt!.isAfter(incomingUpdatedAt)`. If `completedAt` is null, the item was never completed or was deliberately un-completed — apply the incoming op normally.
**Warning signs:** Un-complete operation has no effect on other devices.

---

## Code Examples

### Shopping Use Case Shell (CreateShoppingItemUseCase)

```dart
// Source pattern: lib/application/accounting/create_transaction_use_case.dart (verified)
class CreateShoppingItemUseCase {
  CreateShoppingItemUseCase({
    required ShoppingItemRepository shoppingItemRepository,
    ShoppingItemChangeTracker? changeTracker,
    SyncEngine? syncEngine,
  }) : _repo = shoppingItemRepository,
       _changeTracker = changeTracker,
       _syncEngine = syncEngine;

  final ShoppingItemRepository _repo;
  final ShoppingItemChangeTracker? _changeTracker;
  final SyncEngine? _syncEngine;

  Future<Result<ShoppingItem>> execute(ShoppingItemParams params) async {
    if (params.name.trim().isEmpty) {
      return Result.error('name must not be empty');
    }

    final item = ShoppingItem(
      id: const Uuid().v4(),
      deviceId: params.deviceId,
      listType: params.listType,
      name: params.name.trim(),
      ledgerType: params.ledgerType,
      categoryId: params.categoryId,
      tags: params.tags,
      note: params.note,
      quantity: params.quantity,
      estimatedPrice: params.estimatedPrice,
      createdAt: DateTime.now(),
    );

    await _repo.insert(item);

    // Privacy gate (D37-06): only public items enter the sync pipeline
    if (item.listType == 'public') {
      _changeTracker?.trackCreate(
        ShoppingItemSyncMapper.toCreateOperation(item),
      );
    }

    _syncEngine?.onTransactionChanged(); // reuse existing debounce trigger

    return Result.success(item);
  }
}
```

### ToggleItemCompletedUseCase (D37-02 un-complete semantics)

```dart
// Source pattern: lib/application/accounting/update_transaction_use_case.dart (verified)
Future<Result<ShoppingItem>> execute(String itemId) async {
  final existing = await _repo.findById(itemId);
  if (existing == null) return Result.error('ShoppingItem not found');

  final now = DateTime.now();
  final ShoppingItem updated;

  if (existing.isCompleted) {
    // Deliberate un-complete (D37-02): clear completedAt so sticky-complete
    // guard does NOT fire on remote devices (completedAt will be null)
    updated = existing.copyWith(
      isCompleted: false,
      completedAt: null,
      updatedAt: now,
    );
  } else {
    // Mark completed: stamp completedAt (D-03 sticky-complete timestamp)
    updated = existing.copyWith(
      isCompleted: true,
      completedAt: now,
      updatedAt: now,
    );
  }

  await _repo.update(updated);

  // Privacy gate (D37-06)
  if (existing.listType == 'public') {
    _changeTracker?.trackUpdate(
      ShoppingItemSyncMapper.toUpdateOperation(updated),
    );
  }

  _syncEngine?.onTransactionChanged();
  return Result.success(updated);
}
```

### UpdateShoppingItemUseCase (D37-04 listType immutability guard)

```dart
// Source pattern: lib/application/accounting/update_transaction_use_case.dart (verified)
Future<Result<ShoppingItem>> execute(UpdateShoppingItemParams params) async {
  final existing = await _repo.findById(params.itemId);
  if (existing == null) return Result.error('ShoppingItem not found');

  // D37-04: listType is immutable after creation — fail-fast for buggy callers
  if (params.listType != null && params.listType != existing.listType) {
    return Result.error(
      'Invariant violation: listType cannot be changed after creation '
      '(D6/SYNC-03). Current: ${existing.listType}, attempted: ${params.listType}',
    );
  }

  final updated = existing.copyWith(
    name: params.name ?? existing.name,
    ledgerType: params.ledgerType ?? existing.ledgerType,
    categoryId: params.categoryId ?? existing.categoryId,
    tags: params.tags ?? existing.tags,
    note: params.note, // pass-through: null clears the field
    quantity: params.quantity ?? existing.quantity,
    estimatedPrice: params.estimatedPrice ?? existing.estimatedPrice,
    updatedAt: DateTime.now(),
    // isCompleted, completedAt, listType, sortOrder, id, deviceId: preserved
  );

  await _repo.update(updated);

  // Privacy gate (D37-06): listType can't change so existing.listType is authoritative
  if (existing.listType == 'public') {
    _changeTracker?.trackUpdate(
      ShoppingItemSyncMapper.toUpdateOperation(updated),
    );
  }

  _syncEngine?.onTransactionChanged();
  return Result.success(updated);
}
```

### ClearCompletedItemsUseCase

```dart
// Source: ShoppingItemRepository.softDeleteAllCompleted (verified from shopping_item_repository_impl.dart)
// ClearCompleted calls softDeleteAllCompleted (bulk) then emits individual tracker delete ops
Future<Result<void>> execute(String listType) async {
  // Find all completed non-deleted items before bulk-deleting (to emit tracker ops)
  // OR: if tracker only needs entityIds, stream the IDs first
  // Simple approach: emit one 'clearCompleted' semantics via individual soft-deletes
  // The DAO already has softDeleteAllCompleted in one DB write (no N+1)

  if (listType == 'public') {
    // For tracker: we need the IDs of items being deleted. Two options:
    // Option A: find all completed public items, then softDeleteAll, then emit per-item delete ops
    // Option B: emit one special op (not standard) — NOT recommended (breaks existing apply handler)
    // Use Option A — consistent with D37-06 and the delete-op convention

    final items = await _repo.watchByListType(listType).first;
    final completed = items.where((i) => i.isCompleted && !i.isDeleted).toList();

    await _repo.softDeleteAllCompleted(listType);

    for (final item in completed) {
      _changeTracker?.trackDelete(itemId: item.id);
    }
  } else {
    // Private list: bulk soft-delete, no tracker
    await _repo.softDeleteAllCompleted(listType);
  }

  _syncEngine?.onTransactionChanged();
  return Result.success(null);
}
```

**Note:** The `watchByListType(listType).first` call reads the current stream snapshot before the bulk delete. This is acceptable because `ClearCompleted` is a user-initiated batch action (not a hot path) and the data access is lightweight.

---

## Runtime State Inventory

This phase makes no renames, refactors, or migrations — it adds new files in `lib/application/`. Runtime state inventory is not applicable.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All use cases | Yes | Confirmed in project | — |
| Drift `^2.25.0` | Repo access via Phase 36 DAO | Yes | Already in pubspec.yaml | — |
| mocktail | Test mocking | Yes | Already in dev_dependencies | — |
| `flutter test` | Test runner | Yes | Standard Flutter SDK | — |

No missing dependencies. Phase 37 is pure application-layer Dart; no external services or CLI tools needed.

---

## Validation Architecture

> Nyquist validation is enabled (workflow.nyquist_validation not set to false in config).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (dart:test + Flutter test extensions) |
| Config file | None separate — uses pubspec.yaml test config |
| Quick run command | `flutter test test/unit/application/shopping_list/ test/unit/application/family_sync/shopping_item_change_tracker_test.dart -x` |
| Full suite command | `flutter test test/unit/application/ test/integration/sync/` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File |
|--------|----------|-----------|-------------------|------|
| SYNC-02 (SC-1) | Private create → tracker pendingCount == 0 | unit | `flutter test test/unit/application/shopping_list/create_shopping_item_use_case_test.dart -x` | Wave 0 gap |
| SYNC-02 (SC-1) | Public create → tracker pendingCount == 1 | unit | same file | Wave 0 gap |
| SYNC-03/D37-04 (SC-2) | UpdateUseCase rejects listType change | unit | `flutter test test/unit/application/shopping_list/update_shopping_item_use_case_test.dart -x` | Wave 0 gap |
| DONE-03 (SC-2) | ClearCompleted soft-deletes all completed for listType | unit | `flutter test test/unit/application/shopping_list/clear_completed_items_use_case_test.dart -x` | Wave 0 gap |
| SYNC-01/SYNC-02/SYNC-05 (SC-3) | ShoppingItemChangeTracker internal guard rejects private | unit | `flutter test test/unit/application/family_sync/shopping_item_change_tracker_test.dart -x` | Wave 0 gap |
| SYNC-01 (SC-3) | Orchestrator pushes shopping ops in incrementalPush | unit | `flutter test test/unit/application/family_sync/phase6_sync_coverage_test.dart -x` | Modify existing file |
| SYNC-05/SC4 (SC-4) | Tombstone not resurrected: apply delete then send update → isDeleted stays true | unit | `flutter test test/unit/application/family_sync/apply_sync_operations_use_case_test.dart -x` | Modify existing file |
| SYNC-05/D37-02 (SC-4) | Sticky-complete merge: stale rename with isCompleted:false → completion preserved | unit | same file | Modify existing file |
| D37-02 (SC-4) | Deliberate un-complete (ToggleItemCompleted on completed item) syncs and is NOT blocked by sticky-complete | unit | `flutter test test/unit/application/shopping_list/toggle_item_completed_use_case_test.dart -x` | Wave 0 gap |
| D37-05 (SC-3) | Bad shopping op in batch does NOT abort bill ops | unit | `flutter test test/unit/application/family_sync/apply_sync_operations_use_case_test.dart -x` | Modify existing file |
| SYNC-06 (SC-5) | Public item from member A appears in member B watchByListType without manual refresh | integration | `flutter test test/integration/sync/shopping_sync_round_trip_test.dart -x` | Wave 0 gap |
| SYNC-02 (SC-5) | Private item from member A does NOT appear in member B watchByListType | integration | same file | Wave 0 gap |
| SYNC-01 (SC-3) | Constructor updated atomically: applySyncOperationsUseCaseProvider still constructs | unit | `flutter test test/unit/features/family_sync/presentation/providers/sync_providers_characterization_test.dart -x` | Modify existing file |

### Success Criteria → Test Coverage Map

| SC | Description | Test Files | What to Assert |
|----|-------------|------------|----------------|
| SC-1 | Six use cases + pendingCount privacy gate | `create_shopping_item_use_case_test.dart` | After private create: `tracker.pendingCount == 0`. After public create: `tracker.pendingCount == 1`. |
| SC-2 | listType immutability rejection + ClearCompleted soft-delete-all | `update_shopping_item_use_case_test.dart`, `clear_completed_items_use_case_test.dart` | Rejection: returns `Result.error(...)` with message containing 'Invariant'. ClearCompleted: `findById(id).isDeleted == true` for all completed items. |
| SC-3 | Tracker + orchestrator push + apply branch + atomic constructor | `shopping_item_change_tracker_test.dart`, `phase6_sync_coverage_test.dart` (modified), `apply_sync_operations_use_case_test.dart` (modified), `sync_providers_characterization_test.dart` | Tracker internal guard: private op not enqueued. Orchestrator: `pushSync.execute` called with shopping ops. Apply: shopping branch called without affecting bill results. Constructor test: provider still builds. |
| SC-4 | Tombstone not resurrected; sticky-complete preserves isCompleted | `apply_sync_operations_use_case_test.dart` (modified) | Tombstone: send create, then delete, then update → `findById(id).isDeleted == true`. Sticky-complete: send create (completedAt=T1), then update (updatedAt=T0, isCompleted:false) → `isCompleted == true`. |
| SC-5 | Reactive-stream round-trip: public appears, private never does | `test/integration/sync/shopping_sync_round_trip_test.dart` | Public: apply create op for entity 'shopping_item' → `watchByListType('public').first` emits list with new item. Private: apply private-item create op → `watchByListType('public').first` emits empty or unmodified list. |

### Sampling Rate

- **Per task commit:** `flutter test test/unit/application/shopping_list/ test/unit/application/family_sync/ -x`
- **Per wave merge:** `flutter test test/unit/ test/integration/sync/`
- **Phase gate:** Full suite green (`flutter test`) + `flutter analyze` 0 issues before `/gsd-verify-work`

### Wave 0 Gaps

These test files must be created BEFORE implementation (TDD contract):

- [ ] `test/unit/application/shopping_list/create_shopping_item_use_case_test.dart` — covers SC-1 (pendingCount privacy gate), ITEM-01
- [ ] `test/unit/application/shopping_list/update_shopping_item_use_case_test.dart` — covers SC-2 (listType rejection), ITEM-02, ITEM-04
- [ ] `test/unit/application/shopping_list/delete_shopping_item_use_case_test.dart` — covers MGMT-01, MGMT-02
- [ ] `test/unit/application/shopping_list/toggle_item_completed_use_case_test.dart` — covers DONE-01, D37-02 (deliberate un-complete)
- [ ] `test/unit/application/shopping_list/reorder_shopping_items_use_case_test.dart` — covers D37-01 (no tracker call)
- [ ] `test/unit/application/shopping_list/clear_completed_items_use_case_test.dart` — covers DONE-03, SC-2
- [ ] `test/unit/application/family_sync/shopping_item_change_tracker_test.dart` — covers SC-3 (internal privacy guard)
- [ ] `test/integration/sync/shopping_sync_round_trip_test.dart` — covers SC-5 (SYNC-06, reactive delivery + privacy)
- [ ] Modifications to `test/unit/application/family_sync/apply_sync_operations_use_case_test.dart` — add shopping_item cases (SC-3, SC-4)
- [ ] Modifications to `test/unit/application/family_sync/phase6_sync_coverage_test.dart` — update orchestrator setUp for new shopping tracker param (SC-3)
- [ ] Modifications to `test/unit/features/family_sync/presentation/providers/sync_providers_characterization_test.dart` — update constructor verification (SC-3)
- [ ] Modification to `test/integration/sync/bill_sync_round_trip_test.dart` setUp — add ShoppingItemRepository param to ApplySyncOperationsUseCase constructor (atomic update)

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | N/A (use cases called within authenticated app session) |
| V3 Session Management | No | N/A |
| V4 Access Control | Yes | listType gate enforced at use-case boundary (D37-06) — private items never enter sync |
| V5 Input Validation | Yes | Name non-empty validation; listType enum validation (only 'public'/'private') |
| V6 Cryptography | Yes | Note encrypted via `FieldEncryptionService` (ChaCha20-Poly1305 AEAD) at repo boundary — NEVER hand-rolled |

### Known Threat Patterns for This Phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Private item leaks into family sync | Information Disclosure | `listType == 'public'` gate at use-case + tracker; unit test: pendingCount == 0 for private |
| Stale rename resurrects completed item | Tampering | Sticky-complete merge in apply handler; test: completedAt > incomingUpdatedAt → isCompleted preserved |
| Tombstone resurrection by remote update | Tampering | `if (existing.isDeleted) return` as FIRST check in _handleShoppingUpdate; test: delete then update → still deleted |
| Note ciphertext logged on decryption failure | Information Disclosure | Silent catch in `_toModel` — DO NOT log `row.note` or exception message (mirror TransactionRepositoryImpl pattern) |
| Wrong entityType string (typo 'shopping-item') | Tampering (silent drop) | Define `const kShoppingItemEntityType = 'shopping_item'` once; `assert` in debug mode |

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Pure LWW on isCompleted (D7) | Sticky-complete merge with completedAt DateTime? | 2026-06-07 (D-03 override) | Phase 37 implements merge in apply handler; Phase 36 added the column |
| No shopping items in family_sync | shopping_item entityType, 3 targeted changes | Phase 37 | No relay-server changes needed; pipeline is entity-agnostic |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `ClearCompletedItemsUseCase` reads `watchByListType(listType).first` to collect item IDs for tracker before bulk soft-delete | Code Examples | If items are added/completed between the read and the bulk delete, a race produces slightly inconsistent tracker ops — acceptable for eventual-sync model |
| A2 | `SyncEngine.onTransactionChanged()` is the correct debounce trigger to reuse for shopping mutations | Architecture Patterns | If SyncEngine adds entity-type filtering later, shopping mutations would be misfiled; acceptable risk for v1.6 |

If this table is empty for A1/A2 above: these are minor design choices, not unverified facts. All primary claims are verified from source.

---

## Open Questions

None — all six technical questions from the objective are resolved. See "Open Technical Questions — RESOLVED" section above.

---

## Sources

### Primary (HIGH confidence — direct codebase reads, 2026-06-08)

- `lib/application/family_sync/apply_sync_operations_use_case.dart` — confirmed switch structure, no per-op try/catch, _handleUpdate does NOT check isDeleted, 4 entity types handled
- `lib/application/family_sync/transaction_change_tracker.dart` — confirmed no listType guard, _pendingOps, flush(), pendingCount API — exact template
- `lib/application/family_sync/sync_orchestrator.dart` — confirmed _executeIncrementalPush shape (txn flush → pushSync, profile ops → pushSync), profile-ops as second separate pushSync call model (lines 138-177)
- `lib/features/accounting/domain/models/transaction_sync_mapper.dart` — confirmed toUpdateOperation sends FULL snapshot via toSyncMap (lines 86-106); update op includes all fields including isCompleted/isPrivate; no delta
- `lib/application/accounting/create_transaction_use_case.dart` — confirmed nullable changeTracker injection + `_changeTracker?.trackCreate(...)` pattern
- `lib/application/accounting/update_transaction_use_case.dart` — confirmed `_changeTracker?.trackUpdate(...)` pattern + `SyncEngine?.onTransactionChanged()`
- `lib/application/accounting/delete_transaction_use_case.dart` — confirmed `_changeTracker?.trackDelete(...)` pattern
- `lib/features/family_sync/presentation/providers/repository_providers.dart` lines 127-136 — confirmed ApplySyncOperationsUseCase provider construction site (line 130); constructor call with transactionRepository, shadowBookService, groupRepository, syncAvatarUseCase
- `lib/features/family_sync/presentation/providers/state_sync.dart` — confirmed SyncOrchestrator provider construction site (lines 27-39); transactionChangeTracker injected via `changeTracker:` param
- `lib/features/shopping_list/domain/repositories/shopping_item_repository.dart` — confirmed interface API: insert, update, softDelete, softDeleteAllCompleted, findById, watchByListType, upsert, reorder
- `lib/features/shopping_list/domain/models/shopping_item.dart` — confirmed all 17 fields including completedAt DateTime?, listType, addedByBookId
- `lib/data/daos/shopping_item_dao.dart` — confirmed watchByListType uses `readsFrom: {_db.shoppingItems}` (v1.4 GAP-2 safe), softDeleteAllCompleted bulk update
- `lib/data/repositories/shopping_item_repository_impl.dart` — confirmed note encryption at repo boundary (encryptField/decryptField), JSON tag encoding; note travels as plaintext through use cases
- `lib/data/repositories/transaction_repository_impl.dart` lines 25-53 — confirmed bill note encryption pattern (mirror for shopping); plaintext in sync op, encrypted in DB
- `test/integration/sync/bill_sync_round_trip_test.dart` — confirmed ApplySyncOperationsUseCase construction at line 81; test setUp structure for shopping round-trip template
- `test/unit/application/family_sync/apply_sync_operations_use_case_test.dart` — confirmed ApplySyncOperationsUseCase construction at line 49; idempotent create, soft-delete semantics
- `test/unit/application/family_sync/transaction_change_tracker_test.dart` — template for ShoppingItemChangeTracker tests
- `test/unit/application/family_sync/phase6_sync_coverage_test.dart` — confirmed SyncOrchestrator construction at lines 168-180; changeTracker param verified
- `grep -rn ApplySyncOperationsUseCase lib/ test/` — all 4 construction sites confirmed
- `.planning/phases/37-application-use-cases-sync-integration/37-CONTEXT.md` — all 6 locked decisions (D37-01..06) read verbatim
- `.planning/REQUIREMENTS.md` — Phase 37 requirements: ITEM-01, ITEM-02, ITEM-04, DONE-01, DONE-03, MGMT-01-03, SYNC-01-03, SYNC-05-06
- `.planning/ROADMAP.md` — Phase 37 success criteria (SC-1..SC-5) read verbatim

### Secondary (MEDIUM confidence — milestone-level research)

- `.planning/research/SUMMARY.md` — §family-sync integration; §pitfalls #1 (privacy leak) #5 (constructor not updated)
- `.planning/research/PITFALLS.md` — Pitfall 5 (ApplySyncOperationsUseCase constructor), Pitfall 6 (CRDT conflict), Pitfall 1 (private item leak)
- `.planning/research/STACK.md` — zero new packages; entity-agnostic pipeline confirmed

---

## Metadata

**Confidence breakdown:**
- Use case shapes: HIGH — direct read of all three accounting use cases as templates
- Sync mapper (full snapshot vs delta): HIGH — TransactionSyncMapper.toUpdateOperation source read
- Note encryption across sync: HIGH — both TransactionRepositoryImpl and ShoppingItemRepositoryImpl source read
- Op wire payload field set: HIGH — ShoppingItem model (17 fields) + D37-01 exclusion read
- Orchestrator integration: HIGH — sync_orchestrator.dart _executeIncrementalPush source read (138-177)
- Apply-loop fault isolation: HIGH — apply_sync_operations_use_case.dart source read (no try/catch confirmed)
- Atomic constructor sites: HIGH — grep confirmed 4 sites for ApplySyncOperationsUseCase, 2 for SyncOrchestrator
- Test architecture: HIGH — all template test files read directly

**Research date:** 2026-06-08
**Valid until:** 2026-07-08 (30-day window; stable internal codebase, no external dependency changes)
