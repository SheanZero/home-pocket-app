# Architecture Research

**Domain:** Shopping List feature integration — Flutter / Drift / Riverpod 3 / Clean Architecture
**Researched:** 2026-06-07
**Confidence:** HIGH — all conclusions drawn from direct source-code reads of the existing codebase

---

## Standard Architecture

### System Overview

The shopping_list feature slots into the existing 5-layer Clean Architecture. No new layer is introduced. The layer order and import-direction rules are unchanged.

```
+-----------------------------------------------------------------------+
|  PRESENTATION  lib/features/shopping_list/presentation/               |
|  ShoppingListScreen | ShoppingItemTile | ShoppingItemForm             |
|  ShoppingListSegmentControl | ShoppingFilterBar | ShoppingEmptyState  |
|  providers: repository_providers / state_list_type /                  |
|             state_shopping_filter / state_shopping_items              |
+-----------------------------------------------------------------------+
|  APPLICATION   lib/application/shopping_list/                         |
|  CreateShoppingItemUseCase | UpdateShoppingItemUseCase                |
|  DeleteShoppingItemUseCase | ToggleItemCompletedUseCase               |
|  ReorderShoppingItemsUseCase | ClearCompletedItemsUseCase            |
|                                                                       |
|  lib/application/family_sync/  (MODIFIED — minimal additions)         |
|  + ShoppingItemChangeTracker                                          |
|  + SyncOrchestrator._executeIncrementalPush (4-line extension)        |
|  + ApplySyncOperationsUseCase case 'shopping_item':                   |
+-----------------------------------------------------------------------+
|  DOMAIN   lib/features/shopping_list/domain/                          |
|  models: ShoppingItem | ShoppingListFilter | ShoppingItemParams       |
|  repositories: ShoppingItemRepository (interface only)                |
+-----------------------------------------------------------------------+
|  DATA   lib/data/  (SHARED per Thin Feature rule)                     |
|  tables/shopping_items_table.dart                                     |
|  daos/shopping_item_dao.dart                                          |
|  repositories/shopping_item_repository_impl.dart                     |
|  app_database.dart  (MODIFIED — table added, version 19 -> 20)        |
+-----------------------------------------------------------------------+
|  INFRASTRUCTURE   lib/infrastructure/  (unchanged)                    |
|  crypto/ | sync/ | security/ | i18n/ | platform/                     |
+-----------------------------------------------------------------------+
```

Dependency flow (no changes from existing rules):

```
Presentation -> Application -> Domain <- Data <- Infrastructure
```

---

## Complete File Manifest

### New files

**Domain layer** (`lib/features/shopping_list/domain/`):

```
lib/features/shopping_list/
  domain/
    import_guard.yaml                         (NEW — mirrors list/domain/import_guard.yaml)
    models/
      import_guard.yaml                       (NEW — per-subdirectory allow-list)
      shopping_item.dart                      (NEW — @freezed domain model)
      shopping_item.freezed.dart              (GENERATED)
      shopping_list_filter.dart               (NEW — @freezed filter state)
      shopping_list_filter.freezed.dart       (GENERATED)
      shopping_item_params.dart               (NEW — @freezed Create/UpdateParams)
      shopping_item_params.freezed.dart       (GENERATED)
    repositories/
      shopping_item_repository.dart           (NEW — abstract interface)
```

**Data layer** (`lib/data/`):

```
lib/data/
  tables/
    shopping_items_table.dart                 (NEW)
  daos/
    shopping_item_dao.dart                    (NEW)
  repositories/
    shopping_item_repository_impl.dart        (NEW)
```

**Application layer** (`lib/application/shopping_list/`):

```
lib/application/shopping_list/
  create_shopping_item_use_case.dart          (NEW)
  update_shopping_item_use_case.dart          (NEW)
  delete_shopping_item_use_case.dart          (NEW — soft-delete only)
  toggle_item_completed_use_case.dart         (NEW)
  reorder_shopping_items_use_case.dart        (NEW)
  clear_completed_items_use_case.dart         (NEW — batch soft-delete completed)

lib/application/family_sync/
  shopping_item_change_tracker.dart           (NEW — mirrors transaction_change_tracker.dart)
```

**Presentation layer** (`lib/features/shopping_list/presentation/`):

```
lib/features/shopping_list/
  presentation/
    import_guard.yaml                         (NEW — mirrors list/presentation/import_guard.yaml)
    providers/
      repository_providers.dart               (NEW — single source of truth for this feature)
      repository_providers.g.dart             (GENERATED)
      state_list_type.dart                    (NEW — public | private segmented control)
      state_list_type.g.dart                  (GENERATED)
      state_shopping_filter.dart              (NEW — filter notifier)
      state_shopping_filter.g.dart            (GENERATED)
      state_shopping_items.dart               (NEW — StreamProvider watching DAO)
      state_shopping_items.g.dart             (GENERATED)
    screens/
      shopping_list_screen.dart               (NEW)
    widgets/
      shopping_list_segment_control.dart      (NEW — public/private top control, D1)
      shopping_item_tile.dart                 (NEW — row with checkbox + swipe-delete)
      shopping_item_form.dart                 (NEW — add/edit bottom sheet)
      shopping_filter_bar.dart                (NEW)
      shopping_empty_state.dart               (NEW)
```

### Modified files

| File | Change |
|---|---|
| `lib/data/app_database.dart` | Add `ShoppingItems` to `@DriftDatabase(tables:[...])` annotation; bump `schemaVersion` to 20; add `if (from < 20)` migration block |
| `lib/application/family_sync/sync_orchestrator.dart` | Add `ShoppingItemChangeTracker` field + constructor param; flush shopping ops in `_executeIncrementalPush` (4 lines total) |
| `lib/application/family_sync/apply_sync_operations_use_case.dart` | Add `ShoppingItemRepository` constructor param; add `case 'shopping_item':` branch in `execute()` switch + private handler method |
| `lib/application/family_sync/sync_engine.dart` | Add `onShoppingItemChanged()` public method (2 lines) |
| `lib/features/home/presentation/screens/main_shell_screen.dart` | Replace `Center(Text(S.of(context).todoTab))` with `ShoppingListScreen(bookId: bookId)`; make FAB context-aware (see FAB section) |
| `lib/features/home/presentation/widgets/home_bottom_nav_bar.dart` | Change tab 4 icon from `Icons.check_box_outlined` to `Icons.shopping_cart_outlined`; update ARB key reference |
| `lib/shared/widgets/ledger_type_selector.dart` | MOVED here from `lib/features/accounting/presentation/widgets/ledger_type_selector.dart` (see cross-feature resolution section) |
| `lib/features/accounting/presentation/widgets/transaction_details_form.dart` | Update import path for `ledger_type_selector.dart` after the move |
| `lib/l10n/app_ja.arb` / `app_zh.arb` / `app_en.arb` | Rename `homeTabTodo` -> `homeTabShoppingList`; add all shopping-list string keys |

---

## Drift Table Design: `ShoppingItems`

Convention follows `transactions_table.dart` exactly: `@DataClassName`, `{#symbolSyntax}` for indices, `customConstraints` for CHECK, no `@override` on `customIndices`.

```dart
// lib/data/tables/shopping_items_table.dart

import 'package:drift/drift.dart';

/// Shopping items table — public/private lists with optional metadata.
///
/// No transaction linkage (D3): completing an item only sets isCompleted.
/// Private items (listType='private') are NEVER enqueued in
/// ShoppingItemChangeTracker — guard enforced at use-case boundary.
@DataClassName('ShoppingItemRow')
class ShoppingItems extends Table {
  // Identity
  TextColumn get id => text()();
  TextColumn get deviceId => text()();

  // Visibility: 'public' syncs via family_sync; 'private' is local-only (D1)
  TextColumn get listType => text().withDefault(const Constant('private'))();

  // Required content
  TextColumn get name => text().withLength(min: 1, max: 200)();

  // Optional accounting hints (no FK constraint — D3 no linkage)
  TextColumn get ledgerType => text().nullable()();   // 'daily' | 'joy' | null
  TextColumn get categoryId => text().nullable()();

  // JSON-encoded List<String>. Convention: same as transactions.metadata TEXT column.
  // Decoded at DAO boundary: (jsonDecode(raw) as List).cast<String>()
  TextColumn get tags => text().nullable()();

  TextColumn get note => text().nullable()();

  // D4: quantity + estimated price
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  // Integer yen sub-units. Same convention as Transaction.amount. Nullable = not set.
  IntColumn get estimatedPrice => integer().nullable()();

  // State
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  // Client-managed ordering among active items. Completed items always sort to
  // the bottom via ORDER BY is_completed ASC, sort_order ASC regardless.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  // Sync control (mirrors transactions_table.dart pattern)
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  // Family attribution: book that originally created this public item.
  // Nullable TEXT (no FK) — shadow book may not exist locally when a pulled item arrives.
  TextColumn get addedByBookId => text().nullable()();

  // Timestamps
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK(list_type IN ('public', 'private'))",
    'CHECK(quantity >= 1)',
    "CHECK(ledger_type IN ('daily', 'joy') OR ledger_type IS NULL)",
    'CHECK(estimated_price IS NULL OR estimated_price >= 0)',
  ];

  // Convention: TableIndex with {#columnName} symbol syntax (CLAUDE.md).
  // Naming: idx_shopping_{columns}.
  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_shopping_list_type', columns: {#listType}),
    TableIndex(name: 'idx_shopping_completed', columns: {#isCompleted}),
    TableIndex(name: 'idx_shopping_sort_order', columns: {#sortOrder}),
    TableIndex(name: 'idx_shopping_list_completed', columns: {#listType, #isCompleted}),
    TableIndex(name: 'idx_shopping_deleted', columns: {#isDeleted}),
    TableIndex(name: 'idx_shopping_added_by_book', columns: {#addedByBookId}),
  ];
}
```

**Column design decisions:**

- `tags`: single TEXT column with `jsonEncode(List<String>)`. Mirrors `transactions.metadata` convention. A separate tags junction table is over-engineered for a list whose use is display + filter; client-side decode is trivial.
- `estimatedPrice`: integer yen, nullable. Matches `Transaction.amount` convention. `null` = user left blank; `0` is valid for free items.
- `sortOrder`: client-managed integer. `ReorderableListView.onReorder` calls `ReorderShoppingItemsUseCase` which updates this column in a Drift transaction. Completed items are non-reorderable (separate `SliverList` section rendered below).
- `isDeleted`: soft-delete flag. The sync pipeline CRDT (delete wins over update) works identically to transactions.
- `addedByBookId`: nullable TEXT without a SQLite FOREIGN KEY constraint. Shadow books may not exist locally when a public item arrives via pull sync. Used purely for per-item owner attribution display.

**Migration block** (add to `app_database.dart` `onUpgrade`):

```dart
if (from < 20) {
  await migrator.createTable(shoppingItems);
}
```

No backfill required. No existing table touched. `schemaVersion` bumped from 19 to 20.

---

## DAO Design: `ShoppingItemDao`

Mirrors `TransactionDao` structure. Key methods:

```dart
class ShoppingItemDao {
  ShoppingItemDao(this._db);
  final AppDatabase _db;

  Future<void> insert(ShoppingItemsCompanion item) async { ... }
  Future<void> update(ShoppingItemsCompanion item) async { ... }

  // Sets isDeleted=true + updatedAt=now (soft-delete, mirrors TransactionDao.softDelete)
  Future<void> softDelete(String id) async { ... }

  // Batch soft-delete all completed items in a given listType (for clear-completed feature)
  Future<void> softDeleteAllCompleted(String listType) async { ... }

  Future<ShoppingItemRow?> findById(String id) async { ... }

  /// Primary watch query for the screen.
  /// ORDER BY is_completed ASC, sort_order ASC, created_at ASC.
  /// Excludes soft-deleted rows (is_deleted = 0).
  /// readsFrom: {_db.shoppingItems} is MANDATORY for reactivity.
  Stream<List<ShoppingItemRow>> watchByListType(String listType) { ... }

  /// For sync pull-side: insert-or-replace on conflict by id.
  Future<void> upsert(ShoppingItemsCompanion item) async { ... }

  /// Update sort_order for one item (used by ReorderShoppingItemsUseCase).
  Future<void> reorder(String id, int newSortOrder) async { ... }
}
```

The `watchByListType` stream must use Drift's `.watch()` with `readsFrom: {_db.shoppingItems}`. This is the lesson from v1.4 GAP-2 (`watchByBookIds` was dead code because `readsFrom` was missing): without `readsFrom`, the stream never emits after writes. The shopping list MUST use `watchByListType().watch()` in the StreamProvider — do not fall back to `FutureProvider` + `ref.invalidate`.

---

## Domain Model: `ShoppingItem`

```dart
// lib/features/shopping_list/domain/models/shopping_item.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../accounting/domain/models/transaction.dart'; // for LedgerType

part 'shopping_item.freezed.dart';

@freezed
abstract class ShoppingItem with _$ShoppingItem {
  const factory ShoppingItem({
    required String id,
    required String deviceId,
    required String listType,        // 'public' | 'private'
    required String name,
    LedgerType? ledgerType,
    String? categoryId,
    @Default(<String>[]) List<String> tags,
    String? note,
    @Default(1) int quantity,
    int? estimatedPrice,
    @Default(false) bool isCompleted,
    @Default(0) int sortOrder,
    @Default(false) bool isSynced,
    @Default(false) bool isDeleted,
    String? addedByBookId,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _ShoppingItem;
}
```

`ShoppingItem` imports `LedgerType` from `accounting/domain/models/transaction.dart`. This is a same-layer cross-feature domain model import. The existing `ListFilterState` in `lib/features/list/domain/models/list_filter_state.dart` already does this — the pattern is established and the `import_guard.yaml` subdirectory allow-list is the documented mechanism for it.

---

## import_guard.yaml Files Required

**`lib/features/shopping_list/domain/import_guard.yaml`** (mirrors `list/domain/import_guard.yaml`):

```yaml
deny:
  - package:home_pocket/data/**
  - package:home_pocket/infrastructure/**
  - package:home_pocket/application/**
  - package:home_pocket/features/**/presentation/**
  - package:flutter/**

inherit: true
```

**`lib/features/shopping_list/domain/models/import_guard.yaml`** (per-subdirectory allow-list):

```yaml
allow:
  - dart:core
  - package:freezed_annotation/**
  - ../../../accounting/domain/models/transaction.dart   # for LedgerType enum

inherit: true
```

**`lib/features/shopping_list/presentation/import_guard.yaml`** (mirrors `list/presentation/import_guard.yaml`):

```yaml
deny:
  - package:home_pocket/infrastructure/**
  - package:home_pocket/data/daos/**
  - package:home_pocket/data/tables/**

inherit: true
```

---

## Cross-Feature Widget Import Resolution (CRITICAL)

### The problem

`CategorySelectionScreen` lives at `lib/features/accounting/presentation/screens/category_selection_screen.dart`.
`LedgerTypeSelector` lives at `lib/features/accounting/presentation/widgets/ledger_type_selector.dart`.

Currently both are only used by `transaction_details_form.dart` within the same accounting feature — no cross-feature violation today. `shopping_list/presentation/widgets/shopping_item_form.dart` will need both. If it imports them from `features/accounting/presentation/`, it creates a cross-feature presentation dependency.

### Resolution for LedgerTypeSelector: move to `lib/shared/widgets/`

`LedgerTypeSelector` is a genuinely generic component: it takes `LedgerType selected` and `ValueChanged<LedgerType> onChanged`. Its only non-generic dependency is `LedgerType` (a domain enum), `AppPalette`, and `AppTextStyles` — all of which are already accessible from `lib/shared/`. It has zero accounting-specific state, no Riverpod providers, and no ConsumerWidget.

Action: move `ledger_type_selector.dart` to `lib/shared/widgets/ledger_type_selector.dart`. Update the import in `transaction_details_form.dart`. Both `transaction_details_form.dart` and `shopping_item_form.dart` then import from `lib/shared/widgets/ledger_type_selector.dart` — no cross-feature dependency.

### Resolution for CategorySelectionScreen: direct cross-feature import, allow-listed

`CategorySelectionScreen` is a full ConsumerStatefulWidget (240+ lines) with:
- `categoryRepositoryProvider` (from accounting feature)
- `CategoryLocalizationService`
- `state_category_reorder.dart` (from accounting feature)
- `ReorderableListView.builder` with category reordering

Moving it to `lib/shared/` would drag accounting-specific providers into the shared layer — incorrect. It belongs in `lib/features/accounting/presentation/`.

The correct pattern is the same that `transaction_details_form.dart` uses: `Navigator.of(context).push<Category>(MaterialPageRoute(builder: (_) => CategorySelectionScreen(...)))`. For `shopping_item_form.dart` to do this without a cross-feature import violation, it must explicitly allow the import.

Inspection of the actual import_guard rules confirms:
- `lib/features/import_guard.yaml` (root) denies `features/*/use_cases/**`, `features/*/application/**`, `features/*/infrastructure/**`, `features/*/data/**` — does NOT deny cross-feature presentation imports.
- `lib/features/shopping_list/presentation/import_guard.yaml` denies `infrastructure/**`, `data/daos/**`, `data/tables/**` — does NOT deny `features/accounting/presentation/**` by default.

Therefore the import is not currently blocked. To make the dependency explicit and intentional (consistent with the project's import_guard philosophy: `allow:` as an opt-in declaration), add:

```yaml
# lib/features/shopping_list/presentation/import_guard.yaml
allow:
  - package:home_pocket/features/accounting/presentation/screens/category_selection_screen.dart

deny:
  - package:home_pocket/infrastructure/**
  - package:home_pocket/data/daos/**
  - package:home_pocket/data/tables/**

inherit: true
```

### Summary of import resolution actions

| Action | File | What changes |
|---|---|---|
| Move widget | `ledger_type_selector.dart` | `lib/features/accounting/presentation/widgets/` -> `lib/shared/widgets/` |
| Update import | `transaction_details_form.dart` | Import from `../../../../shared/widgets/ledger_type_selector.dart` |
| Allow cross-feature | `shopping_list/presentation/import_guard.yaml` | Add explicit `allow:` for `CategorySelectionScreen` path |
| No action | `CategorySelectionScreen` itself | Stays in `lib/features/accounting/presentation/screens/` |

---

## Family Sync Integration: Minimal Change Set

The pipeline is entity-agnostic at the wire level. These are the only changes required.

### New file: `ShoppingItemChangeTracker`

```dart
// lib/application/family_sync/shopping_item_change_tracker.dart

import 'package:flutter/foundation.dart';

/// Tracks shopping item operations (public items only) pending sync push.
///
/// Private items are NEVER passed to this tracker.
/// The listType guard is enforced at the use-case boundary, not here.
class ShoppingItemChangeTracker {
  final _pendingOps = <Map<String, dynamic>>[];

  void trackCreate(Map<String, dynamic> operation) {
    _pendingOps.add(operation);
  }

  void trackUpdate(Map<String, dynamic> operation) {
    _pendingOps.add(operation);
  }

  void trackDelete({required String itemId}) {
    _pendingOps.add({
      'op': 'delete',
      'entityType': 'shopping_item',
      'entityId': itemId,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  List<Map<String, dynamic>> flush() {
    final ops = List<Map<String, dynamic>>.of(_pendingOps);
    _pendingOps.clear();
    if (kDebugMode && ops.isNotEmpty) {
      debugPrint('[ShoppingChangeTracker] ${ops.length} ops flushed');
    }
    return ops;
  }

  int get pendingCount => _pendingOps.length;
}
```

### Modified: `SyncOrchestrator._executeIncrementalPush`

Add `ShoppingItemChangeTracker _shoppingChangeTracker` field (injected via constructor). In `_executeIncrementalPush`, after the existing transaction ops flush block, add:

```dart
// Flush pending shopping item changes (public items only — private guard at use-case boundary)
final shoppingOps = _shoppingChangeTracker.flush();
if (shoppingOps.isNotEmpty) {
  await _pushSync.execute(operations: shoppingOps, vectorClock: const {});
}
```

That is 4 lines total. No other changes to `SyncOrchestrator`.

### Modified: `ApplySyncOperationsUseCase`

Add `ShoppingItemRepository _shoppingItemRepository` constructor parameter. In `execute()`, add one switch case:

```dart
case 'shopping_item':
  await _applyShoppingItemOperation(operation);
```

Add private method:

```dart
Future<void> _applyShoppingItemOperation(Map<String, dynamic> operation) async {
  final op = operation['op'] as String?;
  final entityId = operation['entityId'] as String?;
  final data = operation['data'] as Map<String, dynamic>?;
  if (op == null || entityId == null) return;

  switch (op) {
    case 'create':
    case 'insert':
      if (data == null) return;
      await _handleShoppingCreate(entityId, data);
    case 'update':
      if (data == null) return;
      await _handleShoppingUpdate(entityId, data);
    case 'delete':
      await _shoppingItemRepository.softDelete(entityId);
  }
}
```

`_handleShoppingCreate` checks for an existing item (idempotent) then calls `_shoppingItemRepository.upsert(...)`. `_handleShoppingUpdate` applies last-write-wins on `updatedAt` (same CRDT strategy as `_handleUpdate` for transactions).

### Modified: `SyncEngine`

Add one public method:

```dart
/// Shopping item created/updated/deleted (public items only).
void onShoppingItemChanged() {
  _scheduler.onTransactionChanged(); // reuses the existing 10s debounce trigger
}
```

The scheduler's `onTransactionChanged` debounce is entity-agnostic — it triggers `incrementalPush`. Both use cases call their respective engine method; both flush through the same orchestrator.

### Private item guard: enforced at use-case boundary

`CreateShoppingItemUseCase` and `UpdateShoppingItemUseCase` check `params.listType`. If `listType == 'public'` AND a group is active: call `_changeTracker.trackCreate/Update(operation)` then `_syncEngine.onShoppingItemChanged()`. If `listType == 'private'`: write to DB only, tracker never called. This is simpler and more reliable than filtering at the tracker or orchestrator level — no parsing of operation maps required.

---

## FAB Context-Awareness (D2)

**Current state:** `onFabTap` in `main_shell_screen.dart` is a single unconditional `Navigator.push(ManualOneStepScreen)`. The `HomeBottomNavBar` is a stateless widget that accepts `VoidCallback onFabTap` — it has no knowledge of the current tab.

**Recommended wiring:**

`currentIndex` is already available in `MainShellScreen.build` via `ref.watch(selectedTabIndexProvider)`. The FAB callback becomes conditional on `currentIndex`:

```dart
onFabTap: () async {
  if (currentIndex == 3) {
    // Shopping list tab — D2: context-aware FAB opens add-item sheet
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ShoppingItemAddSheet(
        bookId: bookId,
        // Pre-fill list type from the active segment control state
        defaultListType: ref.read(selectedShoppingListTypeProvider).name,
      ),
    );
    // No ref.invalidate needed — watchByListType stream reacts automatically
  } else {
    // All other tabs — existing transaction entry FAB
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ManualOneStepScreen(bookId: bookId),
      ),
    );
    // ... existing ref.invalidate calls unchanged ...
  }
},
```

No changes to `HomeBottomNavBar` widget itself — the FAB callback logic stays in `MainShellScreen`, which already has `currentIndex`. The nav bar remains a pure UI component accepting `VoidCallback onFabTap`.

`selectedShoppingListTypeProvider` is the `state_list_type.dart` keepAlive notifier. Passing `defaultListType` to the form means the FAB opens a new item pre-set to whichever segment is active (public or private).

---

## Architectural Patterns

### Pattern 1: DAO `.watch()` -> StreamProvider (reactive list)

The lesson from v1.4 GAP-2 is clear: use Drift's `.watch()` directly, not `FutureProvider` + `ref.invalidate`. For shopping items this is especially important because pull-sync writes from family members must appear without user action.

```dart
// state_shopping_items.dart
@riverpod
Stream<List<ShoppingItem>> shoppingItems(Ref ref, {required String listType}) {
  final dao = ref.watch(shoppingItemDaoProvider);
  return dao
      .watchByListType(listType)
      .map((rows) => rows.map(ShoppingItemMapper.fromRow).toList());
}
```

Filter notifiers (`state_shopping_filter.dart`, `state_list_type.dart`) use `keepAlive: true` so public/private segment selection and filter settings persist across tab switches in the IndexedStack.

### Pattern 2: Completed-to-bottom via SQL ordering only

No client-side sorting. The DAO query uses:

```dart
.orderBy([
  (t) => OrderingTerm.asc(t.isCompleted),   // false=0 before true=1
  (t) => OrderingTerm.asc(t.sortOrder),
  (t) => OrderingTerm.asc(t.createdAt),     // tiebreaker within completed group
])
```

`ReorderableListView.onReorder` updates `sortOrder` for active items only. Completed items are rendered in a non-reorderable `SliverList` section below a "Completed" divider. Split at the first row where `item.isCompleted == true` after the DAO query returns the ordered list.

### Pattern 3: Public-item sync guard at use-case boundary

The `listType` guard runs in application use cases, not in the tracker or orchestrator:

```dart
// In CreateShoppingItemUseCase.execute():
await _repository.insert(item);
if (params.listType == 'public' && await _isGroupActive()) {
  _changeTracker.trackCreate(_toSyncOperation(item));
  _syncEngine.onShoppingItemChanged();
}
```

This keeps the tracker clean, avoids conditional logic in the orchestrator, and makes the privacy invariant directly testable: mock `_isGroupActive()` returning true/false and verify tracker is called/not called.

---

## Data Flow

### Add item (FAB on shopping tab)

```
User taps FAB (currentIndex == 3)
  -> showModalBottomSheet(ShoppingItemAddSheet)
     User fills name + optional D4 fields
     -> CreateShoppingItemUseCase.execute(CreateShoppingItemParams)
          -> ShoppingItemRepository.insert(item)
               -> ShoppingItemDao.insert(companion) -> Drift -> SQLCipher DB
          -> if public + group active:
               ShoppingItemChangeTracker.trackCreate(op)
               SyncEngine.onShoppingItemChanged()
                 -> SyncScheduler debounce 10s
                   -> SyncOrchestrator._executeIncrementalPush
                     -> shoppingChangeTracker.flush() -> PushSyncUseCase
          -> Navigator.pop (sheet dismissed)
  <- ShoppingItemDao.watchByListType stream emits (Drift detects table write)
  <- shoppingItemsProvider rebuilds
  <- ShoppingListScreen rerenders with new item at correct sort position
```

### Pull sync (public item from family member)

```
WebSocket/push: syncAvailable
  -> SyncEngine.onSyncAvailable -> SyncOrchestrator.incrementalPull
     -> PullSyncUseCase.execute -> RelayApiClient.pull -> decrypt
        -> ApplySyncOperationsUseCase.execute(operations)
           -> case 'shopping_item':
              -> _applyShoppingItemOperation(op)
                 -> ShoppingItemRepository.upsert(item)
                    -> ShoppingItemDao.upsert -> Drift -> SQLCipher DB
  <- ShoppingItemDao.watchByListType stream emits automatically
  <- shoppingItemsProvider rebuilds (public list shows new item from family)
```

---

## Phase Build Order

Dependencies determine sequencing. Each phase must be complete before the next begins; phases 39 and 40 can run in parallel.

| Phase | Content | Prerequisite |
|---|---|---|
| Phase 36 | **Data layer foundation.** `shopping_items_table.dart`, `shopping_item_dao.dart`, `shopping_item_repository_impl.dart`. `app_database.dart` v19->v20 migration. ARB rename `homeTabTodo->homeTabShoppingList` (ja/zh/en). DAO tests (watchByListType reactivity, softDelete, upsert, reorder). | None |
| Phase 37 | **Domain layer.** `ShoppingItem` Freezed, `ShoppingListFilter` Freezed, `ShoppingItemParams` Freezed, `ShoppingItemRepository` interface. All `import_guard.yaml` files. `LedgerTypeSelector` move to `lib/shared/widgets/` + update accounting import. Run `build_runner`. | Phase 36 (table column names needed for mapping) |
| Phase 38 | **Application layer.** 6 use cases in `lib/application/shopping_list/`. `repository_providers.dart` for use-case wiring. Mocktail tests for each use case (mirrors v1.4 Phase 25 approach). | Phase 37 (domain interfaces required) |
| Phase 39 | **Sync integration.** `ShoppingItemChangeTracker`, `SyncOrchestrator` extension (4 lines), `ApplySyncOperationsUseCase` extension (case + handler), `SyncEngine.onShoppingItemChanged()`. Integration test: mock SyncEngine, verify public items enter tracker, private items do not. | Phase 38 (use cases call tracker) |
| Phase 40 | **Presentation shell.** `repository_providers.dart`, `state_list_type`, `state_shopping_filter`, `state_shopping_items` providers. Replace placeholder in `main_shell_screen.dart` with `ShoppingListScreen`. Context-aware FAB wiring. Tab icon + label update. Golden baselines (empty state). | Phases 37-38 (domain models + use cases required) |
| Phase 41 | **UI widgets.** `ShoppingItemTile` (checkbox toggle + swipe-delete via `DeleteShoppingItemUseCase`), `ShoppingItemForm` (add/edit bottom sheet with all D4 fields + `CategorySelectionScreen` push + `LedgerTypeSelector`), `ShoppingListSegmentControl` (D1 public/private), `ShoppingFilterBar`, `ShoppingEmptyState`. Human-approved render. | Phase 40 (screen + providers exist) |
| Phase 42 | **i18n + golden re-baseline.** All ARB keys x ja/zh/en parity. Golden tests for all screen states x locale x light/dark. Final sync integration smoke test. | Phase 41 (all UI complete) |

Phases 39 and 40 are independent: sync integration does not depend on any presentation file, and the presentation shell does not depend on sync being wired. They can be developed concurrently if resources allow.

---

## Anti-Patterns

### Anti-Pattern 1: `FutureProvider` + `ref.invalidate` instead of `StreamProvider`

**What people do:** Use `FutureProvider.autoDispose` for the shopping item list and call `ref.invalidate` after each mutation.

**Why it's wrong:** Creates the same dead-code debt as `watchByBookIds` in v1.4 (GAP-2). Pull-sync writes from family members cannot trigger a `ref.invalidate` — they happen inside `ApplySyncOperationsUseCase`, which has no access to Riverpod. Items added by family members will not appear in the public list until the user manually navigates away and back.

**Do this instead:** `watchByListType(listType).watch()` wrapped in a `StreamProvider`. Drift table writes (from any source including sync) automatically trigger stream emission.

### Anti-Pattern 2: Private item entering the change tracker

**What people do:** Call `_changeTracker.trackCreate(op)` after every insert, relying on the orchestrator to filter by listType.

**Why it's wrong:** The orchestrator sees only `List<Map<String, dynamic>>` after flush — it has no access to listType without parsing the JSON payload. This violates separation of concerns and is fragile (operation map structure is an internal implementation detail of the tracker, not the orchestrator).

**Do this instead:** Guard at use-case boundary. Only call `_changeTracker.trackCreate` when `params.listType == 'public'`. Private items never reach the tracker, relay, or any other device.

### Anti-Pattern 3: Cross-feature presentation import without explicit allow-list entry

**What people do:** Import `CategorySelectionScreen` from `shopping_list/presentation/` and omit the `allow:` entry in `shopping_list/presentation/import_guard.yaml`.

**Why it's wrong:** While the current `lib/features/import_guard.yaml` does not block cross-feature presentation imports, leaving the dependency implicit means it can silently become a violation if future import_guard rules tighten. The project's philosophy is opt-in allow-listing for intentional cross-boundary dependencies.

**Do this instead:** Add the explicit `allow:` path. Make the dependency documented and intentional.

### Anti-Pattern 4: Completed items inside `ReorderableListView`

**What people do:** Include completed items in the same `ReorderableListView` as active items, with a different visual state, and filter drag handles away.

**Why it's wrong:** `ReorderableListView` requires all items to be draggable. Mixing drag-enabled and drag-disabled items is not supported without custom drag-handle suppression that breaks keyboard accessibility and is undocumented behavior.

**Do this instead:** Two separate sections: `SliverReorderableList` for active items (reorderable), then `SliverList` for completed items below a divider (non-reorderable). The DAO `ORDER BY is_completed ASC` returns them pre-sorted; split at the first `isCompleted == true` row.

### Anti-Pattern 5: Moving `CategorySelectionScreen` to `lib/shared/`

**What people do:** Attempt to move `CategorySelectionScreen` to `lib/shared/widgets/` or `lib/shared/screens/` to avoid cross-feature import.

**Why it's wrong:** `CategorySelectionScreen` depends on `categoryRepositoryProvider` (defined in accounting feature's `presentation/providers/repository_providers.dart`) and `state_category_reorder.dart` (accounting-specific notifier). Moving the screen would drag accounting-feature-specific providers into the shared layer, which is a worse violation than a documented cross-feature import.

**Do this instead:** Keep it in `lib/features/accounting/presentation/screens/` and allow-list the import explicitly.

---

## Integration Points

### Internal Boundaries

| Boundary | Communication | Notes |
|---|---|---|
| `shopping_list` presentation <-> `application/shopping_list` | Use cases via Riverpod providers in `repository_providers.dart` | ONE `repository_providers.dart` per feature — Riverpod hygiene rule |
| `application/shopping_list` <-> `data/repositories/shopping_item_repository_impl` | `ShoppingItemRepository` interface | Injected via feature `repository_providers.dart` |
| `shopping_list` presentation -> `accounting` presentation | `CategorySelectionScreen` Navigator.push + return `Category?` | Allow-listed in `shopping_list/presentation/import_guard.yaml` |
| `lib/shared/widgets/ledger_type_selector.dart` <-> both features | Direct import from `lib/shared/widgets/` | Generic widget, no feature-specific state; both accounting form and shopping form import it |
| `application/shopping_list` use cases <-> `ShoppingItemChangeTracker` | Direct method calls (injected via constructor) | Only called when `listType == 'public'` AND group active |
| `application/family_sync/sync_orchestrator` <-> shopping tracker | `_shoppingChangeTracker.flush()` in `_executeIncrementalPush` | 4-line addition after the existing transaction flush |
| `application/family_sync/apply_sync_operations_use_case` <-> `ShoppingItemRepository` | Direct call in `case 'shopping_item':` branch | Repository injected via constructor |
| `features/home/presentation` FAB <-> shopping list | `currentIndex == 3` guard in `MainShellScreen.onFabTap` | No changes to `HomeBottomNavBar` widget |

### External Services

| Service | Integration Pattern | Notes |
|---|---|---|
| WebSocket relay server | Existing `/sync/push` + `/sync/pull` + `/sync/ack` endpoints | Zero server changes — relay is entity-agnostic; `entityType: 'shopping_item'` lives inside the encrypted payload |
| SQLCipher DB | Drift `ShoppingItems` table + `ShoppingItemDao` | Shopping item `note` field SHOULD be encrypted via `FieldEncryptionService` at the repository impl boundary, matching the transaction `note` encryption pattern |

---

## Sources

- `lib/features/list/` (read 2026-06-07) — canonical 5-layer analog for shopping_list; all layer files mirrored. HIGH confidence.
- `lib/data/tables/transactions_table.dart` (read 2026-06-07) — `@DataClassName`, `customConstraints`, `List<TableIndex> get customIndices` with `{#symbol}` syntax confirmed. HIGH confidence.
- `lib/data/daos/transaction_dao.dart` (read 2026-06-07) — DAO method shapes, soft-delete pattern, `watchByBookIds` reactivity lesson (`readsFrom:` required). HIGH confidence.
- `lib/data/app_database.dart` (read 2026-06-07) — `schemaVersion => 19` confirmed; `from < 19` block is category sort-order (NOT shopping list); `migrator.createTable` is the established v-bump pattern. HIGH confidence.
- `lib/application/family_sync/transaction_change_tracker.dart` (read 2026-06-07) — in-memory tracker shape; `flush()` returns-and-clears. `ShoppingItemChangeTracker` is a direct mirror. HIGH confidence.
- `lib/application/family_sync/sync_orchestrator.dart` (read 2026-06-07) — `_executeIncrementalPush` calls `_changeTracker.flush()` then `_pushSync.execute(operations:...)`. Shopping ops slot in after transaction ops in 4 lines. HIGH confidence.
- `lib/application/family_sync/apply_sync_operations_use_case.dart` (read 2026-06-07) — `switch (entityType)` with `'bill'`, `'profile'`, `'avatar'` cases; `default: continue` discards unknowns safely. HIGH confidence.
- `lib/application/family_sync/sync_engine.dart` (read 2026-06-07) — `onTransactionChanged()` calls `_scheduler.onTransactionChanged()`. `onShoppingItemChanged()` reuses the same scheduler call. HIGH confidence.
- `lib/features/accounting/presentation/widgets/ledger_type_selector.dart` (read 2026-06-07) — zero accounting-specific dependencies; safe to move to `lib/shared/widgets/`. HIGH confidence.
- `lib/features/accounting/presentation/screens/category_selection_screen.dart` (read 2026-06-07) — full ConsumerStatefulWidget with `categoryRepositoryProvider` dependency; cannot move to shared. Must be accessed via cross-feature import with explicit allow-list. HIGH confidence.
- `lib/features/home/presentation/screens/main_shell_screen.dart` (read 2026-06-07) — `currentIndex = ref.watch(selectedTabIndexProvider)` already available; FAB is `VoidCallback onFabTap`. Context-aware dispatch is a 4-line `if (currentIndex == 3)` guard. HIGH confidence.
- `lib/features/home/presentation/providers/state_home.dart` (read 2026-06-07) — `SelectedTabIndex` notifier; `selectedTabIndexProvider` is `keepAlive: true`. Shopping list tab is index 3. HIGH confidence.
- `lib/features/home/presentation/widgets/home_bottom_nav_bar.dart` (read 2026-06-07) — stateless widget with `VoidCallback onFabTap`; no changes to widget itself for FAB context-awareness. HIGH confidence.
- `lib/features/list/domain/models/list_filter_state.dart` (read 2026-06-07) — confirmed precedent for cross-feature domain import (`LedgerType` from accounting); subdirectory allow-list is the established mechanism. HIGH confidence.
- `lib/features/*/import_guard.yaml` files (read 2026-06-07) — confirmed features-root deny rules do NOT block cross-feature presentation imports; only `use_cases/`, `application/`, `infrastructure/`, `data/` inside features are denied. HIGH confidence.
- `lib/data/repositories/transaction_repository_impl.dart` (read 2026-06-07) — `note` encryption pattern via `FieldEncryptionService` at repository boundary; shopping item `note` should mirror this. HIGH confidence.

---

*Architecture research for: v1.6 购物清单 Shopping List integration into Home Pocket*
*Researched: 2026-06-07*
