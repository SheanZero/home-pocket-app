# Phase 37: Application Use Cases + Sync Integration - Pattern Map

**Mapped:** 2026-06-08
**Files analyzed:** 18 (9 new, 9 modified/construction-site updates)
**Analogs found:** 18 / 18

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/application/shopping_list/create_shopping_item_use_case.dart` | use-case | request-response | `lib/application/accounting/create_transaction_use_case.dart` | role-match (simpler: no hash chain) |
| `lib/application/shopping_list/update_shopping_item_use_case.dart` | use-case | request-response | `lib/application/accounting/update_transaction_use_case.dart` | role-match + add D37-04 guard |
| `lib/application/shopping_list/delete_shopping_item_use_case.dart` | use-case | request-response | `lib/application/accounting/delete_transaction_use_case.dart` | exact |
| `lib/application/shopping_list/toggle_item_completed_use_case.dart` | use-case | request-response | `lib/application/accounting/update_transaction_use_case.dart` | partial (no direct analog) |
| `lib/application/shopping_list/reorder_shopping_items_use_case.dart` | use-case | request-response | `lib/application/accounting/delete_transaction_use_case.dart` | partial (no tracker call — D37-01) |
| `lib/application/shopping_list/clear_completed_items_use_case.dart` | use-case | batch | `lib/application/accounting/delete_transaction_use_case.dart` | partial (bulk + per-item loop) |
| `lib/application/family_sync/shopping_item_change_tracker.dart` | service | event-driven | `lib/application/family_sync/transaction_change_tracker.dart` | exact + add listType guard |
| `lib/features/accounting/domain/models/shopping_item_sync_mapper.dart` | utility | transform | `lib/features/accounting/domain/models/transaction_sync_mapper.dart` | exact structure, different fields |
| `test/integration/sync/shopping_sync_round_trip_test.dart` | test | CRUD+streaming | `test/integration/sync/bill_sync_round_trip_test.dart` | exact structure |
| `test/unit/application/shopping_list/create_shopping_item_use_case_test.dart` | test | request-response | `test/unit/application/family_sync/transaction_change_tracker_test.dart` | role-match |
| `test/unit/application/family_sync/shopping_item_change_tracker_test.dart` | test | event-driven | `test/unit/application/family_sync/transaction_change_tracker_test.dart` | exact |
| `lib/application/family_sync/apply_sync_operations_use_case.dart` (MODIFIED) | use-case | event-driven | self (add `case 'shopping_item':`) | — |
| `lib/application/family_sync/sync_orchestrator.dart` (MODIFIED) | service | event-driven | self (`_executeIncrementalPush` lines 151–160) | — |
| `lib/features/family_sync/presentation/providers/repository_providers.dart:130` (MODIFIED) | provider | — | self (line 129–136 block) | — |
| `lib/features/family_sync/presentation/providers/state_sync.dart:27` (MODIFIED) | provider | — | self (lines 27–39 block) | — |
| `test/integration/sync/bill_sync_round_trip_test.dart:81` (MODIFIED) | test | — | self (line 81 `ApplySyncOperationsUseCase(`) | — |
| `test/unit/application/family_sync/apply_sync_operations_use_case_test.dart:49` (MODIFIED) | test | — | self (line 49 `ApplySyncOperationsUseCase(`) | — |
| `test/unit/application/family_sync/phase6_sync_coverage_test.dart:168` (MODIFIED) | test | — | self (lines 168–180 `SyncOrchestrator(`) | — |
| `test/unit/features/family_sync/presentation/providers/sync_providers_characterization_test.dart:149` (MODIFIED) | test | — | self (lines 148–153) | — |

---

## Pattern Assignments

### `lib/application/shopping_list/create_shopping_item_use_case.dart` (use-case, request-response)

**Analog:** `lib/application/accounting/create_transaction_use_case.dart`

**Imports pattern** (analog lines 1–13):
```dart
import 'package:uuid/uuid.dart'; // use uuid (not ulid) — shopping items don't need sortable IDs

import '../../features/shopping_list/domain/models/shopping_item.dart';
import '../../features/shopping_list/domain/repositories/shopping_item_repository.dart';
import '../../shared/utils/result.dart';
import '../family_sync/shopping_item_change_tracker.dart';
import '../family_sync/sync_engine.dart';
import '../../features/accounting/domain/models/shopping_item_sync_mapper.dart';
```

**Constructor + field declaration pattern** (analog lines 48–70):
```dart
class CreateShoppingItemUseCase {
  CreateShoppingItemUseCase({
    required ShoppingItemRepository shoppingItemRepository,
    ShoppingItemChangeTracker? changeTracker,  // nullable — D37-06
    SyncEngine? syncEngine,                    // nullable — fire-and-forget
  }) : _repo = shoppingItemRepository,
       _changeTracker = changeTracker,
       _syncEngine = syncEngine;

  final ShoppingItemRepository _repo;
  final ShoppingItemChangeTracker? _changeTracker;
  final SyncEngine? _syncEngine;
```

**Core execute pattern** (analog lines 76–183, simplified — no hash chain):
```dart
  Future<Result<ShoppingItem>> execute(ShoppingItemParams params) async {
    // 1. Validate
    if (params.name.trim().isEmpty) {
      return Result.error('name must not be empty');
    }

    // 2. Build domain object (uuid v4, not ulid)
    final item = ShoppingItem(
      id: const Uuid().v4(),
      deviceId: params.deviceId,
      listType: params.listType,
      name: params.name.trim(),
      ledgerType: params.ledgerType,
      categoryId: params.categoryId,
      tags: params.tags ?? const [],
      note: params.note,
      quantity: params.quantity ?? 1,
      estimatedPrice: params.estimatedPrice,
      createdAt: DateTime.now(),
    );

    // 3. Persist (note encryption handled at repo boundary)
    await _repo.insert(item);

    // 4. Privacy gate (D37-06): ONLY public items enter the sync pipeline
    if (item.listType == 'public') {
      _changeTracker?.trackCreate(
        ShoppingItemSyncMapper.toCreateOperation(item),
      );
    }

    // 5. Fire-and-forget sync trigger (analog: line 180)
    _syncEngine?.onTransactionChanged();

    return Result.success(item);
  }
```

**Note:** No hash chain, no category verification, no classification service — shopping items are simpler than transactions. The `listType == 'public'` gate (step 4) is the critical addition absent in the transaction analog.

---

### `lib/application/shopping_list/update_shopping_item_use_case.dart` (use-case, request-response)

**Analog:** `lib/application/accounting/update_transaction_use_case.dart`

**D37-04 listType immutability guard** — insert before copyWith (analog lines 80–110):
```dart
  Future<Result<ShoppingItem>> execute(UpdateShoppingItemParams params) async {
    final existing = await _repo.findById(params.itemId);
    if (existing == null) return Result.error('ShoppingItem not found');

    // D37-04: listType is immutable after creation — fail-fast (not silent no-op)
    if (params.listType != null && params.listType != existing.listType) {
      return Result.error(
        'Invariant violation: listType cannot be changed after creation '
        '(D6/SYNC-03). Current: ${existing.listType}, attempted: ${params.listType}',
      );
    }

    // copyWith pattern (analog lines 94–105) — coalesce fields; pass-through for note
    final updated = existing.copyWith(
      name: params.name ?? existing.name,
      ledgerType: params.ledgerType ?? existing.ledgerType,
      categoryId: params.categoryId ?? existing.categoryId,
      tags: params.tags ?? existing.tags,
      note: params.note,              // pass-through: null clears (EDIT-02 convention)
      quantity: params.quantity ?? existing.quantity,
      estimatedPrice: params.estimatedPrice ?? existing.estimatedPrice,
      updatedAt: DateTime.now(),
      // isCompleted, completedAt, listType, sortOrder, id, deviceId: preserved
    );

    await _repo.update(updated);

    // Privacy gate (D37-06) — listType can't change so existing.listType is authoritative
    if (existing.listType == 'public') {
      _changeTracker?.trackUpdate(
        ShoppingItemSyncMapper.toUpdateOperation(updated),
      );
    }

    _syncEngine?.onTransactionChanged();
    return Result.success(updated);
  }
```

**Key difference from analog:** `UpdateTransactionParams` uses a `seed` Transaction object; `UpdateShoppingItemParams` should use `itemId String` (fetch from repo) to match the delete/toggle pattern. Confirm which style fits better — either works.

---

### `lib/application/shopping_list/delete_shopping_item_use_case.dart` (use-case, request-response)

**Analog:** `lib/application/accounting/delete_transaction_use_case.dart` (lines 1–38 — exact match, simplest use case)

**Full pattern** (analog, all 38 lines):
```dart
// Imports: mirror delete_transaction_use_case.dart but with shopping types
import '../../features/shopping_list/domain/repositories/shopping_item_repository.dart';
import '../../shared/utils/result.dart';
import '../family_sync/shopping_item_change_tracker.dart';
import '../family_sync/sync_engine.dart';

class DeleteShoppingItemUseCase {
  DeleteShoppingItemUseCase({
    required ShoppingItemRepository shoppingItemRepository,
    SyncEngine? syncEngine,
    ShoppingItemChangeTracker? changeTracker,
  }) : _repo = shoppingItemRepository,
       _syncEngine = syncEngine,
       _changeTracker = changeTracker;

  final ShoppingItemRepository _repo;
  final SyncEngine? _syncEngine;
  final ShoppingItemChangeTracker? _changeTracker;

  Future<Result<void>> execute(String itemId) async {
    if (itemId.isEmpty) {
      return Result.error('itemId must not be empty');
    }

    final existing = await _repo.findById(itemId);
    if (existing == null) {
      return Result.error('ShoppingItem not found');
    }

    await _repo.softDelete(itemId);  // analog line 30

    // Privacy gate (D37-06): analog has no gate; shopping adds it
    // existing.listType is the authoritative source (D37-04: immutable)
    if (existing.listType == 'public') {
      _changeTracker?.trackDelete(itemId: itemId);  // NOTE: different sig from txn tracker
    }

    _syncEngine?.onTransactionChanged();  // analog line 35
    return Result.success(null);
  }
}
```

**Key difference from analog:** `trackDelete` on `TransactionChangeTracker` takes `{required String transactionId, required String bookId}`. `ShoppingItemChangeTracker.trackDelete` should take `{required String itemId}` only — shopping items have no bookId concept.

---

### `lib/application/shopping_list/toggle_item_completed_use_case.dart` (use-case, request-response)

**No direct analog** — closest is `update_transaction_use_case.dart` for the constructor/tracker shape.

**Core pattern** (from RESEARCH.md Code Examples, D37-02):
```dart
  Future<Result<ShoppingItem>> execute(String itemId) async {
    final existing = await _repo.findById(itemId);
    if (existing == null) return Result.error('ShoppingItem not found');

    final now = DateTime.now();
    final ShoppingItem updated;

    if (existing.isCompleted) {
      // Deliberate un-complete (D37-02): clear completedAt so the sticky-complete
      // guard does NOT fire on remote devices (completedAt will be null → guard skips)
      updated = existing.copyWith(
        isCompleted: false,
        completedAt: null,   // Freezed copyWith with null: use explicit null
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

**Freezed nullable copyWith note:** `ShoppingItem` uses `@freezed`. To set a nullable field to null via `copyWith`, Freezed generates a sentinel pattern. Check `shopping_item.freezed.dart` — if `completedAt` uses the default Freezed nullable approach, `copyWith(completedAt: null)` may be a no-op. Use `copyWith(completedAt: const $CopyWithHelper())` or confirm the generated code handles it. Standard pattern for Freezed nullable fields: add `completedAt: Value(null)` or confirm the generated `copyWith` accepts explicit `null` reset.

---

### `lib/application/shopping_list/reorder_shopping_items_use_case.dart` (use-case, request-response)

**Analog:** `lib/application/accounting/delete_transaction_use_case.dart` (constructor shape only)

**D37-01: NO tracker call, NO privacy gate** — reorder is local-per-device only.

**Pattern:**
```dart
class ReorderShoppingItemsUseCase {
  ReorderShoppingItemsUseCase({
    required ShoppingItemRepository shoppingItemRepository,
  }) : _repo = shoppingItemRepository;
  // No changeTracker, no syncEngine — reorder is local-per-device (D37-01)

  final ShoppingItemRepository _repo;

  Future<Result<void>> execute(String itemId, int newSortOrder) async {
    if (itemId.isEmpty) return Result.error('itemId must not be empty');
    // D37-01: sortOrder is local-per-device — NOT synced; no tracker call
    await _repo.reorder(itemId, newSortOrder);
    return Result.success(null);
  }
}
```

---

### `lib/application/shopping_list/clear_completed_items_use_case.dart` (use-case, batch)

**Analog:** `lib/application/accounting/delete_transaction_use_case.dart` (constructor shape) + `ShoppingItemRepository.softDeleteAllCompleted` for the bulk call.

**Pattern** (from RESEARCH.md Code Examples):
```dart
  Future<Result<void>> execute(String listType) async {
    if (listType == 'public') {
      // Collect IDs of completed non-deleted items before bulk soft-delete
      // so we can emit individual tracker delete ops (D37-06)
      final items = await _repo.watchByListType(listType).first;
      final completed = items.where((i) => i.isCompleted && !i.isDeleted).toList();

      // Bulk soft-delete in one DB write (no N+1)
      await _repo.softDeleteAllCompleted(listType);

      // Emit per-item delete ops for sync (one op per item, consistent with single-delete)
      for (final item in completed) {
        _changeTracker?.trackDelete(itemId: item.id);
      }
    } else {
      // Private list: bulk soft-delete, no tracker (D37-06: private never enters sync)
      await _repo.softDeleteAllCompleted(listType);
    }

    _syncEngine?.onTransactionChanged();
    return Result.success(null);
  }
```

**Note:** `watchByListType(listType).first` reads the current stream snapshot synchronously. This is the established approach for one-shot reads from a Drift watch query without opening a persistent subscription.

---

### `lib/application/family_sync/shopping_item_change_tracker.dart` (service, event-driven)

**Analog:** `lib/application/family_sync/transaction_change_tracker.dart` (all 53 lines — copy verbatim then add listType guard)

**Full analog** (lines 1–53):
```dart
// transaction_change_tracker.dart — copy this structure exactly

import 'package:flutter/foundation.dart';

class TransactionChangeTracker {
  final _pendingOps = <Map<String, dynamic>>[];

  void trackCreate(Map<String, dynamic> operation) {
    _pendingOps.add(operation);
  }

  void trackUpdate(Map<String, dynamic> operation) {
    _pendingOps.add(operation);
  }

  void trackDelete({required String transactionId, required String bookId}) {
    _pendingOps.add({
      'op': 'delete',
      'entityType': 'bill',
      'entityId': transactionId,
      'data': {'bookId': bookId},
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  List<Map<String, dynamic>> flush() {
    final ops = List<Map<String, dynamic>>.of(_pendingOps);
    _pendingOps.clear();
    if (kDebugMode) {
      if (ops.isNotEmpty) {
        debugPrint('[ChangeTracker] pending changes flushed');
      }
    }
    return ops;
  }

  int get pendingCount => _pendingOps.length;
}
```

**Shopping version — changes from analog:**
1. `entityType: 'bill'` → `kShoppingItemEntityType` constant
2. `trackDelete` signature: remove `bookId` param (shopping items have no bookId); remove `'data': {'bookId': ...}` from op
3. Add `listType == 'public'` guard in `trackCreate` and `trackUpdate` (defense-in-depth per D37-06):

```dart
import 'package:flutter/foundation.dart';

const kShoppingItemEntityType = 'shopping_item'; // define ONCE here

class ShoppingItemChangeTracker {
  final _pendingOps = <Map<String, dynamic>>[];

  void trackCreate(Map<String, dynamic> operation) {
    // Second safety net (D37-06) — use-case gate is the primary enforcement
    final data = operation['data'] as Map<String, dynamic>?;
    if (data?['listType'] != 'public') return;
    _pendingOps.add(operation);
  }

  void trackUpdate(Map<String, dynamic> operation) {
    // Second safety net (D37-06)
    final data = operation['data'] as Map<String, dynamic>?;
    if (data?['listType'] != 'public') return;
    _pendingOps.add(operation);
  }

  // Delete ops have no listType in data; caller (use case) enforces D37-06
  void trackDelete({required String itemId}) {
    _pendingOps.add({
      'op': 'delete',
      'entityType': kShoppingItemEntityType,
      'entityId': itemId,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  List<Map<String, dynamic>> flush() {
    final ops = List<Map<String, dynamic>>.of(_pendingOps);
    _pendingOps.clear();
    if (kDebugMode) {
      if (ops.isNotEmpty) {
        debugPrint('[ShoppingChangeTracker] ${ops.length} ops flushed');
      }
    }
    return ops;
  }

  int get pendingCount => _pendingOps.length;
}
```

---

### `lib/features/accounting/domain/models/shopping_item_sync_mapper.dart` (utility, transform)

**Analog:** `lib/features/accounting/domain/models/transaction_sync_mapper.dart` (lines 66–111)

**Mapper op shape** (analog lines 66–110):
```dart
// transaction_sync_mapper.dart toCreateOperation (lines 66–84):
static Map<String, dynamic> toCreateOperation(Transaction t, {...}) {
  return {
    'op': 'create',
    'entityType': 'bill',       // → 'shopping_item' (kShoppingItemEntityType)
    'entityId': transaction.id,
    'data': toSyncMap(t, ...),
    'timestamp': transaction.createdAt.toUtc().toIso8601String(),
  };
}

// toUpdateOperation (lines 86–106):
static Map<String, dynamic> toUpdateOperation(Transaction t, {...}) {
  return {
    'op': 'update',
    'entityType': 'bill',       // → 'shopping_item'
    'entityId': transaction.id,
    'data': toSyncMap(t, ...),  // FULL snapshot (confirmed from source)
    'timestamp': (transaction.updatedAt ?? transaction.createdAt).toUtc().toIso8601String(),
  };
}
```

**Shopping mapper wire fields** (from RESEARCH.md Q3, D37-01):
```dart
// toSyncMap for ShoppingItem — full snapshot (consistent with bill convention)
// EXCLUDES: sortOrder (D37-01 local-per-device), isDeleted, isSynced (internal)
static Map<String, dynamic> toSyncMap(ShoppingItem item) {
  return {
    'id': item.id,
    'listType': item.listType,
    'name': item.name,
    'ledgerType': item.ledgerType?.name,      // nullable enum → string
    'categoryId': item.categoryId,
    'tags': jsonEncode(item.tags),             // JSON string (repo decodes on write)
    'note': item.note,                         // plaintext (repo encrypts on write)
    'quantity': item.quantity,
    'estimatedPrice': item.estimatedPrice,
    'isCompleted': item.isCompleted,
    'completedAt': item.completedAt?.toUtc().toIso8601String(),
    'createdAt': item.createdAt.toUtc().toIso8601String(),
    'updatedAt': item.updatedAt?.toUtc().toIso8601String(),
    'deviceId': item.deviceId,                 // only meaningful on create
    'addedByBookId': item.addedByBookId,       // only meaningful on create
    // sortOrder: EXCLUDED — D37-01
    // isDeleted: EXCLUDED — tombstone communicated by 'delete' op itself
    // isSynced: EXCLUDED — internal flag
  };
}

// fromSyncMap — inverse; used by apply handler
static ShoppingItem fromSyncMap(
  Map<String, dynamic> data, {
  String? fromDeviceId,
}) {
  return ShoppingItem(
    id: data['id'] as String,
    deviceId: fromDeviceId ?? data['deviceId'] as String? ?? '',
    listType: data['listType'] as String? ?? 'public',
    name: data['name'] as String? ?? '',
    ledgerType: _parseLedgerType(data['ledgerType'] as String?),
    categoryId: data['categoryId'] as String?,
    tags: data['tags'] != null
        ? List<String>.from(jsonDecode(data['tags'] as String) as List)
        : const [],
    note: data['note'] as String?,
    quantity: (data['quantity'] as int?) ?? 1,
    estimatedPrice: data['estimatedPrice'] as int?,
    isCompleted: (data['isCompleted'] as bool?) ?? false,
    completedAt: data['completedAt'] != null
        ? DateTime.parse(data['completedAt'] as String)
        : null,
    createdAt: data['createdAt'] != null
        ? DateTime.parse(data['createdAt'] as String)
        : DateTime.now(),
    updatedAt: data['updatedAt'] != null
        ? DateTime.parse(data['updatedAt'] as String)
        : null,
    addedByBookId: data['addedByBookId'] as String?,
    isSynced: true,  // always true when coming from sync pipeline
  );
}
```

**File placement note:** RESEARCH.md places this at `lib/features/accounting/domain/models/` (consistent with `transaction_sync_mapper.dart`). However, per CLAUDE.md placement rules, a shopping-item mapper is arguably better at `lib/features/shopping_list/domain/models/`. The analog's location (`features/accounting/domain/models/`) guides the executor; confirm with team if cross-feature placement is preferred.

---

### `lib/application/family_sync/apply_sync_operations_use_case.dart` (MODIFIED)

**Analog:** Self — lines 9–46 (`execute` method) + lines 48–66 (`_applyBillOperation` shape)

**Constructor change** (analog lines 10–20 — add `ShoppingItemRepository`):
```dart
// CURRENT constructor (lines 10–20):
ApplySyncOperationsUseCase({
  required TransactionRepository transactionRepository,
  required ShadowBookService shadowBookService,
  required GroupRepository groupRepository,
  SyncAvatarUseCase? syncAvatarUseCase,
  String? appDirectory,
}) : ...

// MODIFIED — add one required param (must update all 4 construction sites atomically):
ApplySyncOperationsUseCase({
  required TransactionRepository transactionRepository,
  required ShoppingItemRepository shoppingItemRepository,  // NEW
  required ShadowBookService shadowBookService,
  required GroupRepository groupRepository,
  SyncAvatarUseCase? syncAvatarUseCase,
  String? appDirectory,
}) : _transactionRepository = transactionRepository,
     _shoppingItemRepository = shoppingItemRepository,   // NEW
     ...
```

**`execute` switch — add `shopping_item` case** (analog lines 32–45):
```dart
// CURRENT switch (lines 35–44):
switch (entityType) {
  case 'bill':
    await _applyBillOperation(operation);
  case 'profile':
    await _applyProfileOperation(operation, groupId: groupId);
  case 'avatar':
    await _applyAvatarOperation(operation, groupId: groupId);
  default:
    continue;
}

// MODIFIED — add shopping_item with D37-05 fault isolation (ONLY this branch):
switch (entityType) {
  case 'bill':
    await _applyBillOperation(operation);        // UNCHANGED
  case 'profile':
    await _applyProfileOperation(operation, groupId: groupId);  // UNCHANGED
  case 'avatar':
    await _applyAvatarOperation(operation, groupId: groupId);   // UNCHANGED
  case 'shopping_item':
    // D37-05: fault isolation — bad shopping op must not abort bill ops
    try {
      await _applyShoppingItemOp(operation);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[ApplySyncOps] shopping_item op failed, skipping: $e\n$st');
      }
      continue; // skip-and-continue; next fullSync reconciles
    }
  default:
    continue;
}
```

**`_applyShoppingItemOp` + helpers** (modeled on `_applyBillOperation` lines 48–66 + `_handleCreate/Update` lines 106–152):
```dart
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
      // Soft-delete (tombstone) — never hard-delete (Pitfall 5)
      await _shoppingItemRepository.softDelete(entityId);
    case 'update':
      if (data == null) return;
      await _handleShoppingUpdate(entityId, data);
  }
}

Future<void> _handleShoppingCreate(
  String entityId,
  String? fromDeviceId,
  Map<String, dynamic> data,
) async {
  // Idempotent: skip if already exists (analog _handleCreate line 111–113)
  final existing = await _shoppingItemRepository.findById(entityId);
  if (existing != null) return;

  // No shadow-book concept for shopping items — they belong to the shared list
  final item = ShoppingItemSyncMapper.fromSyncMap(data, fromDeviceId: fromDeviceId);
  await _shoppingItemRepository.upsert(item);
}

Future<void> _handleShoppingUpdate(
  String entityId,
  Map<String, dynamic> data,
) async {
  final existing = await _shoppingItemRepository.findById(entityId);
  if (existing == null) {
    // Upsert: treat unknown-ID update as create (analog _handleUpdate line 137–140)
    final item = ShoppingItemSyncMapper.fromSyncMap(data, fromDeviceId: null);
    await _shoppingItemRepository.upsert(item.copyWith(id: entityId));
    return;
  }

  // SC4: tombstone wins — soft-deleted item never resurrected (Pitfall 3)
  // MUST be first check, before any field merging
  if (existing.isDeleted) return;

  // D-03/D37-02 sticky-complete merge
  final incomingUpdatedAt = data['updatedAt'] != null
      ? DateTime.parse(data['updatedAt'] as String)
      : DateTime.now();

  ShoppingItem updated = ShoppingItemSyncMapper.fromSyncMap(data, fromDeviceId: null)
      .copyWith(id: entityId);

  // Guard: only fire when completedAt exists AND is newer than incoming op
  // (D37-02: deliberate un-complete has completedAt=null → guard skips → applies)
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

---

### `lib/application/family_sync/sync_orchestrator.dart` (MODIFIED)

**Analog:** Self — `_executeIncrementalPush` lines 138–177

**Constructor change** (analog lines 43–64 — add `shoppingChangeTracker`):
```dart
// CURRENT (lines 43–64):
SyncOrchestrator({
  ...
  required TransactionChangeTracker changeTracker,
}) : ...
   _changeTracker = changeTracker;

// MODIFIED:
SyncOrchestrator({
  ...
  required TransactionChangeTracker changeTracker,
  required ShoppingItemChangeTracker shoppingChangeTracker,  // NEW
}) : ...
   _changeTracker = changeTracker,
   _shoppingChangeTracker = shoppingChangeTracker;           // NEW

final TransactionChangeTracker _changeTracker;
final ShoppingItemChangeTracker _shoppingChangeTracker;     // NEW
```

**`_executeIncrementalPush` shopping block** — insert AFTER txnOps block (line 160), BEFORE profileOps block (line 163):
```dart
// EXISTING txnOps block (lines 152–160 — DO NOT CHANGE):
final txnOps = _changeTracker.flush();
if (txnOps.isNotEmpty) {
  if (kDebugMode) {
    debugPrint('[SyncOrchestrator] incrementalPush: pushing ${txnOps.length} transaction ops');
  }
  await _pushSync.execute(operations: txnOps, vectorClock: const {});
}

// NEW shopping block — same shape as txnOps, separate _pushSync.execute call:
final shoppingOps = _shoppingChangeTracker.flush();
if (shoppingOps.isNotEmpty) {
  if (kDebugMode) {
    debugPrint('[SyncOrchestrator] incrementalPush: pushing ${shoppingOps.length} shopping ops');
  }
  await _pushSync.execute(operations: shoppingOps, vectorClock: const {});
}

// EXISTING profileOps block (lines 162–166 — DO NOT CHANGE):
final profileOps = await _buildProfileOperationsIfChanged();
if (profileOps.isNotEmpty) {
  await _pushSync.execute(operations: profileOps, vectorClock: const {});
}
```

---

### `lib/features/family_sync/presentation/providers/repository_providers.dart:130` (MODIFIED)

**Analog:** Self — lines 127–136

```dart
// CURRENT (lines 128–136):
@riverpod
ApplySyncOperationsUseCase applySyncOperationsUseCase(Ref ref) {
  return ApplySyncOperationsUseCase(
    transactionRepository: ref.watch(accounting.transactionRepositoryProvider),
    shadowBookService: ref.watch(shadowBookServiceProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
    syncAvatarUseCase: ref.watch(syncAvatarUseCaseProvider),
  );
}

// MODIFIED — add shoppingItemRepository:
@riverpod
ApplySyncOperationsUseCase applySyncOperationsUseCase(Ref ref) {
  return ApplySyncOperationsUseCase(
    transactionRepository: ref.watch(accounting.transactionRepositoryProvider),
    shoppingItemRepository: ref.watch(shoppingItemRepositoryProvider), // NEW
    shadowBookService: ref.watch(shadowBookServiceProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
    syncAvatarUseCase: ref.watch(syncAvatarUseCaseProvider),
  );
}
```

---

### `lib/features/family_sync/presentation/providers/state_sync.dart:27` (MODIFIED)

**Analog:** Self — lines 16–40

```dart
// CURRENT (lines 15–19): TransactionChangeTracker provider
@Riverpod(keepAlive: true)
TransactionChangeTracker transactionChangeTracker(Ref ref) {
  return TransactionChangeTracker();
}

// ADD: ShoppingItemChangeTracker provider (keepAlive mirrors transactionChangeTracker)
@Riverpod(keepAlive: true)
ShoppingItemChangeTracker shoppingItemChangeTracker(Ref ref) {
  return ShoppingItemChangeTracker();
}

// CURRENT SyncOrchestrator provider (lines 26–39):
@riverpod
SyncOrchestrator syncOrchestrator(Ref ref) {
  return SyncOrchestrator(
    ...
    changeTracker: ref.watch(transactionChangeTrackerProvider),
  );
}

// MODIFIED — add shoppingChangeTracker:
@riverpod
SyncOrchestrator syncOrchestrator(Ref ref) {
  return SyncOrchestrator(
    ...
    changeTracker: ref.watch(transactionChangeTrackerProvider),
    shoppingChangeTracker: ref.watch(shoppingItemChangeTrackerProvider), // NEW
  );
}
```

---

### `test/integration/sync/shopping_sync_round_trip_test.dart` (NEW)

**Analog:** `test/integration/sync/bill_sync_round_trip_test.dart` (all 371 lines)

**setUp structure** (analog lines 33–86):
```dart
setUp(() async {
  db = AppDatabase.forTesting();                        // analog line 35
  mockEncryption = _MockFieldEncryptionService();
  mockGroupRepository = _MockGroupRepository();

  when(() => mockEncryption.encryptField(any()))        // analog lines 40–44
      .thenAnswer((inv) async => inv.positionalArguments.first as String);
  when(() => mockEncryption.decryptField(any()))
      .thenAnswer((inv) async => inv.positionalArguments.first as String);

  // Shopping-specific: no ShadowBookService (shopping items go into shared table)
  shoppingItemDao = ShoppingItemDao(db);
  shoppingItemRepo = ShoppingItemRepositoryImpl(
    dao: shoppingItemDao,
    encryptionService: mockEncryption,
  );

  applyOps = ApplySyncOperationsUseCase(
    transactionRepository: ...,          // still needed for other entity types
    shoppingItemRepository: shoppingItemRepo,  // NEW param (atomic construction site)
    shadowBookService: ...,
    groupRepository: mockGroupRepository,
  );
});
```

**SC-5 test shape** (analog `group('Bill sync round trip', () {` → `group('Shopping sync round trip', () {`):
```dart
test('public item from member A appears in watchByListType stream', () async {
  final streamFuture = shoppingItemRepo.watchByListType('public').first;

  await applyOps.execute([{
    'op': 'create',
    'entityType': 'shopping_item',  // kShoppingItemEntityType
    'entityId': 'item-1',
    'fromDeviceId': 'partner-device',
    'data': {
      'id': 'item-1',
      'listType': 'public',
      'name': 'Milk',
      'quantity': 2,
      'isCompleted': false,
      'createdAt': '2026-06-08T10:00:00.000Z',
    },
  }]);

  final items = await streamFuture;
  expect(items.any((i) => i.id == 'item-1'), isTrue); // SYNC-06
});

test('private item NEVER appears in public watchByListType stream', () async {
  await applyOps.execute([{
    'op': 'create',
    'entityType': 'shopping_item',
    'entityId': 'private-item-1',
    'fromDeviceId': 'partner-device',
    'data': {
      'id': 'private-item-1',
      'listType': 'private',       // private — must not appear for remote members
      'name': 'Secret Gift',
      'quantity': 1,
      'isCompleted': false,
      'createdAt': '2026-06-08T10:00:00.000Z',
    },
  }]);

  final items = await shoppingItemRepo.watchByListType('public').first;
  expect(items.any((i) => i.id == 'private-item-1'), isFalse); // SYNC-02
});
```

---

### `test/unit/application/family_sync/shopping_item_change_tracker_test.dart` (NEW)

**Analog:** `test/unit/application/family_sync/transaction_change_tracker_test.dart` (all 73 lines)

**Key additions beyond the analog:**
```dart
group('ShoppingItemChangeTracker', () {
  late ShoppingItemChangeTracker tracker;
  setUp(() { tracker = ShoppingItemChangeTracker(); });

  // Copy all analog tests (trackUpdate, trackCreate, flush clears, etc.)

  // ADDITIONS unique to shopping tracker (D37-06 internal guard):
  group('privacy gate (D37-06 second safety net)', () {
    test('trackCreate ignores non-public listType', () {
      tracker.trackCreate({
        'op': 'create', 'entityType': 'shopping_item', 'entityId': 'item-1',
        'data': {'listType': 'private', 'name': 'Secret'},
      });
      expect(tracker.pendingCount, 0);  // private → NOT enqueued
    });

    test('trackCreate accepts public listType', () {
      tracker.trackCreate({
        'op': 'create', 'entityType': 'shopping_item', 'entityId': 'item-2',
        'data': {'listType': 'public', 'name': 'Milk'},
      });
      expect(tracker.pendingCount, 1);  // public → enqueued
    });

    test('trackUpdate ignores non-public listType', () {
      tracker.trackUpdate({'data': {'listType': 'private'}});
      expect(tracker.pendingCount, 0);
    });

    test('trackDelete always enqueues (caller is responsible for gate)', () {
      // Delete ops have no listType in data; use-case gate is primary
      tracker.trackDelete(itemId: 'item-3');
      expect(tracker.pendingCount, 1);
    });
  });
});
```

---

### Modified test construction sites

**`test/integration/sync/bill_sync_round_trip_test.dart:81`** — add `shoppingItemRepository:` param:
```dart
// CURRENT (line 81):
applyOps = ApplySyncOperationsUseCase(
  transactionRepository: txRepo,
  shadowBookService: shadowBookService,
  groupRepository: mockGroupRepository,
);

// MODIFIED:
applyOps = ApplySyncOperationsUseCase(
  transactionRepository: txRepo,
  shoppingItemRepository: _mockShoppingItemRepository,  // add mock
  shadowBookService: shadowBookService,
  groupRepository: mockGroupRepository,
);
```

**`test/unit/application/family_sync/apply_sync_operations_use_case_test.dart:49`** — same change at line 49.

**`test/unit/application/family_sync/phase6_sync_coverage_test.dart:168`** — add `shoppingChangeTracker:` to `SyncOrchestrator(` constructor at line 168:
```dart
// CURRENT (lines 168–180):
orchestrator = SyncOrchestrator(
  pullSync: pullSync,
  ...
  changeTracker: changeTracker,
);

// MODIFIED:
orchestrator = SyncOrchestrator(
  pullSync: pullSync,
  ...
  changeTracker: changeTracker,
  shoppingChangeTracker: ShoppingItemChangeTracker(),  // NEW (or a mock)
);
```

**`test/unit/features/family_sync/presentation/providers/sync_providers_characterization_test.dart:149`** — add `shoppingItemRepository` override to `ProviderContainer` overrides and add `shoppingItemChangeTrackerProvider` construction test.

---

## Shared Patterns

### Result Type
**Source:** `lib/shared/utils/result.dart`
**Apply to:** All use case files
```dart
// Result.success(value) — wraps a success
// Result.error('message') — wraps a failure string
// result.isSuccess / result.isError / result.data / result.error
factory Result.success(T? data) => Result._(data: data, isSuccess: true);
factory Result.error(String message) => Result._(error: message, isSuccess: false);
```

### Nullable Tracker Injection + Conditional Track Call
**Source:** `lib/application/accounting/delete_transaction_use_case.dart` lines 11–13, 31–34
**Apply to:** All shopping use cases except ReorderShoppingItemsUseCase
```dart
// Constructor: optional tracker
ShoppingItemChangeTracker? changeTracker,
// ...
final ShoppingItemChangeTracker? _changeTracker;

// Call site (AFTER privacy gate check):
if (existing.listType == 'public') {
  _changeTracker?.trackCreate/Update/Delete(...);
}
```

### SyncEngine Fire-and-Forget
**Source:** `lib/application/accounting/create_transaction_use_case.dart` line 180
**Apply to:** All shopping use cases except ReorderShoppingItemsUseCase
```dart
SyncEngine? syncEngine,  // constructor
// ...
_syncEngine?.onTransactionChanged(); // fire-and-forget after persist + track
```

### Privacy Gate Pattern (D37-06)
**Source:** CONTEXT.md D37-06 (no existing analog — new in Phase 37)
**Apply to:** Create, Update, Toggle, Delete, ClearCompleted use cases
```dart
// Gate: use-case boundary (primary enforcement)
if (item.listType == 'public') {
  _changeTracker?.track*(...);
}
// Gate: tracker internal (defense-in-depth, secondary)
// → in ShoppingItemChangeTracker.trackCreate/trackUpdate
```

### Soft Delete (tombstone)
**Source:** `lib/application/accounting/delete_transaction_use_case.dart` line 30
**Apply to:** DeleteShoppingItemUseCase, apply handler delete branch
```dart
await _repo.softDelete(id);  // NEVER hard-delete; tombstone survives full-sync
```

### Freezed copyWith Immutability
**Source:** `lib/application/accounting/update_transaction_use_case.dart` lines 94–105
**Apply to:** UpdateShoppingItemUseCase, ToggleItemCompletedUseCase, apply handler
```dart
final updated = existing.copyWith(
  field: override ?? existing.field,  // coalesce
  note: params.note,                  // pass-through (null clears)
  updatedAt: DateTime.now(),
);
```

### AppDatabase.forTesting() Pattern
**Source:** `test/integration/sync/bill_sync_round_trip_test.dart` line 35 + `test/unit/application/family_sync/apply_sync_operations_use_case_test.dart` line 29
**Apply to:** Integration test setUp
```dart
db = AppDatabase.forTesting();
// ...
tearDown(() async { await db.close(); });
```

### Mock FieldEncryptionService (pass-through)
**Source:** `test/integration/sync/bill_sync_round_trip_test.dart` lines 40–45
**Apply to:** Shopping integration test setUp
```dart
when(() => mockEncryption.encryptField(any()))
    .thenAnswer((inv) async => inv.positionalArguments.first as String);
when(() => mockEncryption.decryptField(any()))
    .thenAnswer((inv) async => inv.positionalArguments.first as String);
```

---

## No Analog Found

All files have close analogs. The following have only partial matches and require additional logic beyond copying:

| File | Role | Data Flow | Gap |
|------|------|-----------|-----|
| `toggle_item_completed_use_case.dart` | use-case | request-response | No "flip boolean + timestamp" use case in the codebase; closest is `update_transaction_use_case.dart` for structure only |
| `_applyShoppingItemOp` (inside apply_sync_ops) | handler | event-driven | `_applyBillOperation` is the model but lacks tombstone-first check AND sticky-complete merge — both are new logic |
| `shopping_item_sync_mapper.dart` | utility | transform | `transaction_sync_mapper.dart` is the shape but excludes `sortOrder` (D37-01) and adds `completedAt`/`listType` semantics |

---

## Metadata

**Analog search scope:** `lib/application/`, `lib/features/`, `test/unit/application/`, `test/integration/sync/`
**Files scanned:** 14 source files read directly
**Pattern extraction date:** 2026-06-08
