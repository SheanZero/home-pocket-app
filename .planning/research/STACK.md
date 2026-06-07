# Stack Research

**Domain:** Flutter app — v1.6 购物清单 (Shopping List tab)
**Researched:** 2026-06-07
**Confidence:** HIGH — all conclusions drawn from direct source-code reads; no training-data assertions about package capabilities made without verification.

---

## TL;DR (read this first)

**Zero new packages required.** The shopping-list feature is fully buildable on the existing locked stack. Every capability — Drift table + DAO, Riverpod providers, list rendering, drag-sort, filter state, public/private segmented control, family-sync integration — already has a working primitive in the installed dependencies.

The existing family_sync pipeline generalizes naturally to a new `shopping_item` entity type with two targeted additions: a `ShoppingItemChangeTracker` (mirrors `TransactionChangeTracker`) and a `case 'shopping_item':` branch in `ApplySyncOperationsUseCase.execute()`. No relay-server protocol changes are needed because the pipeline is entity-agnostic at the wire level — it encrypts arbitrary JSON operation arrays. No new `SyncMode` is required because `incrementalPush` already flushes any tracker's ops and `incrementalPull` already applies whatever entity types are in the received operations.

The schema moves from v19 → v20 (the v19 slot was already consumed by the category sort-order reorder). The migration adds one table via `migrator.createTable(shoppingItems)` inside a new `if (from < 20)` block.

---

## What Is Already Installed (relevant to v1.6)

From `pubspec.yaml` (read 2026-06-07, schema version 19 confirmed):

| Locked Dependency | Version | v1.6 Use |
|---|---|---|
| `flutter_riverpod` | `^3.1.0` | `@riverpod` providers for list visibility (public/private), filter state, item list stream |
| `riverpod_annotation` | `^4.0.0` | `@riverpod` code-gen on new shopping-list providers |
| `freezed_annotation` | `^3.0.0` | Immutable models: `ShoppingItem`, `ShoppingListFilter`, `ShoppingItemParams` |
| `drift` | `^2.25.0` | New `ShoppingItems` table + `ShoppingItemDao`; typed queries, `.watch()` stream |
| `sqlcipher_flutter_libs` | `^0.6.7` | Encrypted DB — unchanged |
| `intl` | `0.20.2` (exact pin) | `NumberFormatter` for estimated-price display; `S.of(context)` for all UI strings |
| `flutter_localizations` | sdk | ARB keys: list name, item fields, filter labels, segment control, clear-completed |
| `collection` | `^1.19.1` | `sortedBy` / `groupBy` for completed-to-bottom reordering client-side if needed |
| `lucide_icons_flutter` | `^3.1.14` | Existing icon set — checkbox, trash, drag-handle icons |
| `uuid` | `^4.5.3` | `Uuid().v4()` for shopping item IDs (same as sync ops) |

Flutter SDK built-ins that cover remaining capabilities:

| Built-in | v1.6 Use |
|---|---|
| `ReorderableListView` / `SliverReorderableList` | Manual drag-sort (already used in `CategorySelectionScreen` and `state_category_reorder.dart`) |
| `Dismissible` | Swipe-to-delete on individual items (same pattern as transaction list rows) |
| `CupertinoSlidingSegmentedControl` or `SegmentedButton` | Public/Private top control (D1) |
| `Checkbox` / `ListTile` | Item rows with completion toggle |
| `showModalBottomSheet` | Add/edit item form |

No new dev-dependency additions required: `mocktail`, `build_runner`, `freezed`, `riverpod_generator`, `drift_dev`, `custom_lint`, `riverpod_lint`, `import_guard_custom_lint` are all current and cover v1.6's code-gen and test needs.

---

## Drift Schema Migration: v19 → v20

### The v19 slot is already used

`app_database.dart` line 45 shows `int get schemaVersion => 19`. The existing `if (from < 19)` block (lines 413–423) reorders `cat_food_dining_out` / `cat_food_groceries` sort orders — it is NOT the shopping list table. The shopping list table lands at **v20**.

### New Table: `ShoppingItems`

Convention follows `transactions_table.dart` and `categories_table.dart` verbatim — `@DataClassName`, `TextColumn`/`IntColumn`/`BoolColumn`/`DateTimeColumn`, `Set<Column> get primaryKey`, `List<TableIndex> get customIndices` with `{#columnSymbol}` syntax.

```dart
// lib/data/tables/shopping_items_table.dart

import 'package:drift/drift.dart';

/// Shopping items table — public/private lists with optional metadata.
@DataClassName('ShoppingItemRow')
class ShoppingItems extends Table {
  // Identity
  TextColumn get id => text()();
  TextColumn get deviceId => text()();

  // List visibility: 'public' | 'private'
  TextColumn get listType => text().withDefault(const Constant('private'))();

  // Required
  TextColumn get name => text().withLength(min: 1, max: 200)();

  // Optional accounting hints (no transaction linkage — D3)
  TextColumn get ledgerType => text().nullable()();   // 'daily' | 'joy' | null
  TextColumn get categoryId => text().nullable()();
  TextColumn get tags => text().nullable()();          // JSON-encoded List<String>
  TextColumn get note => text().nullable()();

  // D4: quantity + estimated price
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  IntColumn get estimatedPrice => integer().nullable()();   // in sub-units (yen)

  // State
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  // Sync
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  // Timestamps
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK(list_type IN ('public', 'private'))",
    "CHECK(quantity >= 1)",
    "CHECK(ledger_type IN ('daily', 'joy') OR ledger_type IS NULL)",
  ];

  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_shopping_list_type', columns: {#listType}),
    TableIndex(name: 'idx_shopping_completed', columns: {#isCompleted}),
    TableIndex(name: 'idx_shopping_sort_order', columns: {#sortOrder}),
    TableIndex(name: 'idx_shopping_list_completed', columns: {#listType, #isCompleted}),
    TableIndex(name: 'idx_shopping_deleted', columns: {#isDeleted}),
  ];
}
```

Design notes:
- `tags` is stored as a JSON-encoded `List<String>` in a single TEXT column. This follows the existing `metadata` column convention in `transactions_table.dart` (JSON in TEXT). A separate tags junction table would be over-engineered for a list whose primary use is display + filter — client-side decode is trivial.
- `estimatedPrice` is in sub-units (integer yen), matching `Transaction.amount` convention (already integer, already yen).
- `sortOrder` is a client-managed integer. The DAO `reorder(id, newSortOrder)` method updates this column in a transaction; the UI calls it after `ReorderableListView.onReorder`. Completed items always sort to the bottom regardless of `sortOrder` — the DAO query applies `ORDER BY is_completed ASC, sort_order ASC`.
- `isDeleted` is a soft-delete flag matching the transaction table pattern, which the sync pipeline already understands for conflict resolution.

### Migration block in `app_database.dart`

Add to `onUpgrade`:

```dart
if (from < 20) {
  await migrator.createTable(shoppingItems);
}
```

Add `ShoppingItems` to the `@DriftDatabase(tables: [...])` annotation and bump `schemaVersion` to 20. No data backfill required. No existing table touched.

This is the simplest possible migration form — `migrator.createTable` is the established pattern for adding a net-new table (see `from < 6`, `from < 7`, `from < 12`).

### `@DriftDatabase` annotation change

```dart
@DriftDatabase(
  tables: [
    AuditLogs,
    Books,
    Categories,
    CategoryKeywordPreferences,
    CategoryLedgerConfigs,
    GroupMembers,
    Groups,
    MerchantCategoryPreferences,
    ShoppingItems,   // ADD
    SyncQueue,
    Transactions,
    UserProfiles,
  ],
)
class AppDatabase extends _$AppDatabase {
  // ...
  @override
  int get schemaVersion => 20;  // BUMP
```

---

## Family Sync Integration: Zero Protocol Changes

### How the pipeline works today

The sync pipeline is entity-agnostic at the wire level. `PushSyncUseCase.execute()` takes `List<Map<String, dynamic>> operations` and encrypts them as a JSON blob with `syncType`, `syncId`, `operations`, `vectorClock`. The server stores and relays this ciphertext without inspecting contents. `PullSyncUseCase` decrypts and passes the `operations` list to `ApplySyncOperationsUseCase.execute()`, which branches on `operation['entityType']`.

Currently recognized entity types: `'bill'` (transactions), `'profile'` (group member profiles), `'avatar'` (avatar images). Unknown entity types fall through the `default: continue` branch silently — they are ACK'd (line: `ackedMessageIds.add(messageId)` after `await _applyOperations(operations)`) and discarded.

### What v1.6 needs to add

**On push side:** A `ShoppingItemChangeTracker` (identical structure to `TransactionChangeTracker`) that accumulates `create`/`update`/`delete` operations with `entityType: 'shopping_item'`. The `SyncOrchestrator._executeIncrementalPush()` method flushes `TransactionChangeTracker` — extend it to also flush `ShoppingItemChangeTracker` and call `_pushSync.execute(operations: shoppingOps, vectorClock: const {})`.

Shopping items use the same `incrementalPush` debounce (10 seconds) already wired to `SyncEngine.onTransactionChanged()`. A parallel entry point `SyncEngine.onShoppingItemChanged()` calls `_scheduler.onTransactionChanged()` — or rename the callback to `onDataChanged()` to make it entity-agnostic. This is a small rename within `SyncEngine` and its call sites.

**On pull side:** Add a `case 'shopping_item':` branch in `ApplySyncOperationsUseCase.execute()`:

```dart
case 'shopping_item':
  await _applyShoppingItemOperation(operation);
```

`_applyShoppingItemOperation` receives `op` (create/update/delete), `entityId`, and `data` map, and calls `ShoppingItemRepository.insert/update/softDelete`.

**Private items never enter the push path.** The `ShoppingItemChangeTracker` only tracks items where `listType == 'public'`. Private items are written directly to Drift and never enqueued in the change tracker. No server-side filtering or flag-based suppression is needed.

**No relay server changes.** The server is a dumb encrypted-blob relay — it does not inspect `entityType`. The existing `/sync/push` and `/sync/pull` + `/sync/ack` endpoints handle shopping items without modification.

**No new `SyncMode`.** Shopping item sync flows through `incrementalPush` (local changes out) and `incrementalPull` (remote changes in) — the same modes transactions use.

### Sync payload shape for shopping items

```json
{
  "op": "create",
  "entityType": "shopping_item",
  "entityId": "<ulid>",
  "data": {
    "id": "<ulid>",
    "deviceId": "<device-id>",
    "listType": "public",
    "name": "牛奶",
    "ledgerType": "daily",
    "categoryId": "cat_food_groceries",
    "tags": "[\"breakfast\"]",
    "note": null,
    "quantity": 2,
    "estimatedPrice": 300,
    "isCompleted": false,
    "sortOrder": 0,
    "isDeleted": false,
    "createdAt": "2026-06-07T10:00:00.000Z",
    "updatedAt": null
  },
  "timestamp": "2026-06-07T10:00:00.000Z"
}
```

`delete` operations include only `entityId` (same as `TransactionSyncMapper.toDeleteOperation`). `update` includes the full `data` map (last-write-wins, consistent with the transaction CRDT pattern).

### CRDT conflict resolution

The existing pipeline uses last-write-wins on `updatedAt` timestamp, applied by `_handleUpdate` in `ApplySyncOperationsUseCase`. Shopping items use the same strategy: if a remote `update` arrives for an item that exists locally, overwrite with the remote data if `data['updatedAt'] > existing.updatedAt`. If the local item was deleted (`isDeleted = true`) and a remote update arrives, the delete wins (do not resurrect). This mirrors `_handleUpdate` / `_handleCreate` for transactions.

---

## Completed-to-Bottom Ordering: No New Package

This is purely a query-order concern. The DAO query uses:

```sql
ORDER BY is_completed ASC, sort_order ASC
```

Drift expression:

```dart
.orderBy([
  (t) => OrderingTerm.asc(t.isCompleted),
  (t) => OrderingTerm.asc(t.sortOrder),
])
```

Active items (is_completed = false = 0) sort before completed items (is_completed = true = 1). Within the active group, `sort_order` determines manual ordering. Within the completed group, `sort_order` is irrelevant — they all appear at the bottom in created-at order (or the last `sort_order` they held before completion).

This is a pure SQL ordering clause — no client-side grouping, no `collection.groupBy`, no new package. The `ReorderableListView.onReorder` callback updates `sort_order` for active items only (completed items are non-reorderable in the UI).

---

## Drag-Sort: Flutter Built-in, Already Used in This Codebase

`ReorderableListView.builder` is Flutter's built-in widget. The project already uses it in `CategorySelectionScreen` and has `state_category_reorder.dart` as the established notifier pattern for handling `onReorder` index arithmetic.

The shopping list will use the same pattern:
- Wrap the active (non-completed) items in `ReorderableListView.builder`
- Each item gets `key: ValueKey(item.id)` (required by `ReorderableListView`)
- `onReorder` callback updates `sort_order` in the DAO via a use case
- Completed items rendered below in a plain `ListView.builder` (non-reorderable)

No `flutter_reorderable_list`, `drag_and_drop_lists`, or any third-party reorder package needed.

---

## Recommended Architecture for `lib/features/shopping_list/`

Following the "Thin Feature" rule:

```
lib/features/shopping_list/
├── domain/
│   ├── models/
│   │   ├── shopping_item.dart              # @freezed: all fields
│   │   ├── shopping_list_filter.dart       # @freezed: ledgerType?, categoryId?, tags?
│   │   └── shopping_item_params.dart       # @freezed: CreateShoppingItemParams / UpdateShoppingItemParams
│   └── repositories/
│       └── shopping_item_repository.dart   # interface only
└── presentation/
    ├── providers/
    │   ├── repository_providers.dart       # single source of truth for this feature
    │   ├── state_list_type.dart            # public | private segmented control state
    │   ├── state_shopping_filter.dart      # filter notifier
    │   └── state_shopping_items.dart       # StreamProvider watching DAO
    ├── screens/
    │   └── shopping_list_screen.dart
    └── widgets/
        ├── shopping_list_segment_control.dart
        ├── shopping_item_tile.dart
        ├── shopping_item_form.dart         # add / edit bottom sheet
        ├── shopping_filter_bar.dart
        └── shopping_empty_state.dart
```

Data layer (in `lib/data/` per Thin Feature rule — never inside `lib/features/`):

```
lib/data/
├── tables/
│   └── shopping_items_table.dart           # new
├── daos/
│   └── shopping_item_dao.dart              # new
└── repositories/
    └── shopping_item_repository_impl.dart  # new
```

Application layer (use cases in `lib/application/shopping_list/`):

```
lib/application/shopping_list/
├── create_shopping_item_use_case.dart
├── update_shopping_item_use_case.dart
├── delete_shopping_item_use_case.dart
├── toggle_item_completed_use_case.dart
├── reorder_shopping_items_use_case.dart
├── clear_completed_items_use_case.dart
└── repository_providers.dart
```

`lib/application/family_sync/` additions:
- `shopping_item_change_tracker.dart` — mirrors `transaction_change_tracker.dart`
- Extend `sync_orchestrator.dart` to flush the shopping change tracker in `_executeIncrementalPush`
- Extend `apply_sync_operations_use_case.dart` with `case 'shopping_item':` branch

---

## Riverpod Provider Conventions

Follow Riverpod 3 conventions from CLAUDE.md:

- `class ShoppingItemsNotifier` (annotated `@riverpod`) generates `shoppingItemsProvider` (NOT `shoppingItemsNotifierProvider`)
- Use `ProviderContainer.test()` in tests
- `AsyncValue.value` (nullable) not `valueOrNull` (removed in Riverpod 3)
- ONE `repository_providers.dart` per feature
- Use `ref.watch` for derived state, `ref.listen` for side effects (navigation after save)

---

## What NOT to Add

| Avoid | Why Tempting | Why Wrong | Use Instead |
|---|---|---|---|
| Any reorder/drag package (`flutter_reorderable_list`, `drag_and_drop_lists`) | "Cleaner drag UX" | `ReorderableListView` is Flutter built-in, already used in `CategorySelectionScreen`; adding a package duplicates tested platform primitives | `ReorderableListView.builder` (built-in) |
| `hive` / `isar` / `sembast` | "Simpler for a list feature" | Project is fully Drift + SQLCipher; any secondary DB bypasses field encryption and violates layer rules | Drift — add one new table |
| `provider_for_tags: flutter_chips_input` etc. | Tag input chips | `Wrap` + `FilterChip` are Flutter built-ins; existing `CategorySelectionScreen` demonstrates multi-select chip pattern | `FilterChip` + `Wrap` (built-in) |
| A separate sync table for shopping items | "Decouple sync queue" | The existing `SyncQueue` table + `SyncQueueManager` is already entity-agnostic; shopping ops flow through the same queue | Extend `ShoppingItemChangeTracker` → same `SyncQueueManager` |
| New relay server endpoint for shopping | "Cleaner API surface" | The relay server is a dumb blob relay; entity type lives in the encrypted payload; no server-side routing by entity type | Existing `/sync/push` + `/sync/pull` + `/sync/ack` |
| `json_serializable` manual tags column | "Typed tags model" | Tags are a simple `List<String>`; `jsonEncode/jsonDecode` at the DAO boundary is sufficient; adding a generated model adds build-runner complexity for no gain | `jsonEncode(tags)` / `(jsonDecode(raw) as List).cast<String>()` |
| Server-side filtering of private items | "Extra security" | Private items never enter the change tracker; they are never serialized into a sync payload; the relay never sees them | Change tracker only tracks `listType == 'public'` items |

---

## Version Compatibility (locked stack — do not touch)

| Package | v1.6 Constraint | Notes |
|---|---|---|
| `intl: 0.20.2` | Exact pin — do not touch | No new package needs a different `intl` version |
| `sqlcipher_flutter_libs: ^0.6.7` | Do not touch | CI guardrail rejects `sqlite3_flutter_libs`; v20 migration only adds a table |
| `flutter_riverpod: ^3.1.0` + `riverpod_annotation: ^4.0.0` + `riverpod_generator: ^4.0.0+1` | Keep together | Already on Riverpod 3; do not mix 2.x idioms |
| `file_picker: ^11.0.2` + `package_info_plus: ^9.0.1` + `share_plus: ^12.0.2` | Do not bump any alone | win32 ^5.x transitive constraint; shopping list does not touch this graph |
| `drift: ^2.25.0` + `drift_dev: ^2.25.0` | Keep in sync | New table added; no version change needed |
| `table_calendar: ^3.2.0` | Unchanged | Shopping list has no calendar component |

---

## Sources

- `lib/data/app_database.dart` (read 2026-06-07) — confirmed `schemaVersion => 19`; `from < 19` block is category sort-order reorder (NOT shopping list); migration pattern for new tables is `migrator.createTable` inside `if (from < N)`. HIGH confidence.
- `lib/data/tables/transactions_table.dart` (read 2026-06-07) — canonical `@DataClassName`, `customConstraints`, `List<TableIndex> get customIndices` with `{#symbol}` syntax. HIGH confidence.
- `lib/application/family_sync/apply_sync_operations_use_case.dart` (read 2026-06-07) — confirmed `switch (entityType)` with `'bill'`, `'profile'`, `'avatar'` branches; `default: continue` discards unknown types safely. Adding `'shopping_item'` case is the only pull-side change. HIGH confidence.
- `lib/application/family_sync/transaction_change_tracker.dart` (read 2026-06-07) — confirmed in-memory tracker pattern; `flush()` returns and clears pending ops. `ShoppingItemChangeTracker` is a direct mirror. HIGH confidence.
- `lib/application/family_sync/sync_orchestrator.dart` (read 2026-06-07) — confirmed `_executeIncrementalPush` calls `_changeTracker.flush()` then `_pushSync.execute(operations: txnOps)`; shopping ops slot in the same flow. HIGH confidence.
- `lib/application/family_sync/push_sync_use_case.dart` (read 2026-06-07) — confirmed `execute(operations: List<Map<String, dynamic>>)` is entity-agnostic; no entity-type filtering at this layer. HIGH confidence.
- `lib/application/family_sync/pull_sync_use_case.dart` (read 2026-06-07) — confirmed pipeline: pull → decrypt → `_applyOperations(operations)` → ack. Entity routing is entirely in `ApplySyncOperationsUseCase`. HIGH confidence.
- `lib/infrastructure/sync/relay_api_client.dart` (read 2026-06-07) — confirmed `/sync/push` accepts arbitrary `payload` (base64 encrypted blob); no entity-type awareness at the HTTP layer. HIGH confidence.
- `lib/features/accounting/presentation/screens/category_selection_screen.dart` + `state_category_reorder.dart` (filename confirmed 2026-06-07) — confirmed `ReorderableListView.builder` and `SliverReorderableList` already in use; no third-party reorder package present. HIGH confidence.
- `pubspec.yaml` (read 2026-06-07) — confirmed full dependency list; no reorder/drag/list-management package present. HIGH confidence.
- `CLAUDE.md` (read 2026-06-07) — Drift `TableIndex` `{#symbol}` syntax, Riverpod 3 naming conventions, iOS build pins, `sqlcipher_flutter_libs` rule. HIGH confidence.

---

*Stack research for: v1.6 购物清单 (Shopping List tab) — Flutter / Dart / Riverpod 3 / Drift+SQLCipher*
*Researched: 2026-06-07*
