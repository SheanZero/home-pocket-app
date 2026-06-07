# Pitfalls Research — v1.6 購物清単 (Shopping List)

**Domain:** Flutter + Riverpod 3 + Drift + SQLCipher shopping-list feature added to an existing local-first family accounting app with import_guard-enforced Clean Architecture, E2EE family sync, and a dual-ledger system
**Researched:** 2026-06-07
**Confidence:** HIGH — all findings derived from direct codebase inspection of the actual implementation files

---

## Priority Order (read this first)

Two pitfalls will cause an immediate, hard-to-diagnose build failure or a silent privacy violation. Address these first, before writing any other code:

1. **CRITICAL — Privacy:** Private-item leak into sync pipeline (Pitfall 1). A private shopping item silently enters the family sync queue because the `listType` guard is missing from the `ShoppingItemChangeTracker`. Every family member receives the item. This is a privacy violation of the highest severity.

2. **CRITICAL — Build:** Cross-feature import of `CategorySelectionScreen` from `lib/features/accounting/` into `lib/features/shopping_list/` (Pitfall 2). `import_guard_custom_lint` enforces the Thin Feature rule automatically — the build will fail before any code runs. This is the single most likely first-day build-breaker.

---

## Critical Pitfalls

### Pitfall 1: Private Item Leaks Into Family Sync (Privacy-Critical)

**What goes wrong:**
A `ShoppingItemChangeTracker` (mirroring `TransactionChangeTracker`) accumulates `create`/`update`/`delete` operations for all shopping items. If the tracker does not gate on `listType == 'public'` before enqueueing, a private shopping item — personal in nature, intended to be local-only — is serialized into an encrypted sync payload and relayed to every family member's device. The relay server is a dumb blob store; it does not inspect entity types, and `PullSyncUseCase` will apply the operation on every family member's device through the `case 'shopping_item':` branch in `ApplySyncOperationsUseCase`.

The encryption layer (ChaCha20-Poly1305 in transit, AES-256-CBC at rest) protects the payload from the relay server, but not from other family members who share the group key. All family members in the same group can decrypt the payload.

**Why it happens:**
The `TransactionChangeTracker` does not gate on any field — every transaction that is tracked is assumed to be syncable (all transactions are book-scoped and family-visible). A developer copying `TransactionChangeTracker` to create `ShoppingItemChangeTracker` adds the same unconditional `_pendingOps.add(operation)` pattern, forgetting that private shopping items must never be tracked at all.

A second failure mode: the `CreateShoppingItemUseCase` is implemented correctly (checks `listType`), but the `UpdateShoppingItemUseCase` or the `ToggleItemCompletedUseCase` tracks every update without re-checking `listType`. An item that was created private and later modified would trigger a sync op.

A third failure mode: a `fullSync` path (analogous to `FullSyncUseCase` for transactions) is added for shopping items and fetches all items from the DAO without a `listType == 'public'` WHERE clause.

**Consequences:**
Family members see each other's private shopping lists. This is a fundamental breach of the feature's privacy contract and the app's zero-knowledge design philosophy. Discovery after release would require forced updates and possibly database tombstoning of leaked records on all devices.

**Prevention:**
- The `ShoppingItemChangeTracker` must only accept items at the point of enqueueing, not filter after the fact. Add a guard at the call site — the use case, not the tracker itself, is responsible for the `listType` check:
  ```dart
  // In CreateShoppingItemUseCase / UpdateShoppingItemUseCase:
  if (params.listType == ListType.public) {
    _changeTracker.trackCreate(operation);
  }
  // Private items: write to Drift, never touch the tracker.
  ```
- Repeat the same guard in `ToggleItemCompletedUseCase`, `ReorderShoppingItemsUseCase`, and `DeleteShoppingItemUseCase`. Each mutation site is an independent leak opportunity.
- The `ShoppingItemDao` query used by any full-sync path must include `WHERE list_type = 'public' AND is_deleted = 0`.
- **Test — unit:** `ShoppingItemChangeTracker.pendingCount` is 0 after creating a private item. `ShoppingItemChangeTracker.pendingCount` is 1 after creating a public item.
- **Test — integration:** Call `CreateShoppingItemUseCase(listType: private)`, then call `ShoppingItemChangeTracker.flush()` — assert the returned list is empty. Call with `listType: public` — assert the list has one operation with `entityType: 'shopping_item'` and `data.listType == 'public'`.
- **Test — data boundary:** If `listType` is somehow mutated from `public` to `private` after initial creation (a future update-list-type operation), the update use case must NOT enqueue a sync op for the now-private item, and must enqueue a `delete` tombstone to remove the item from family members' devices.

**Phase to address:** Phase 1 / data layer (before any sync wiring). The guard must be the first thing written in the change tracker integration, before any integration test is possible.

---

### Pitfall 2: Cross-Feature Widget Import Breaks the Build Immediately (import_guard)

**What goes wrong:**
The shopping list feature needs category selection (D4 adds optional category to items) and ledger selection (日常/悦己). The natural implementation reaches for `CategorySelectionScreen` in `lib/features/accounting/presentation/screens/category_selection_screen.dart` or `LedgerTypeSelector` widget from `lib/features/accounting/presentation/`. This import, from `lib/features/shopping_list/` into `lib/features/accounting/`, triggers the `import_guard_custom_lint` rule at `lib/features/import_guard.yaml`:

```yaml
deny:
  - package:home_pocket/features/*/use_cases/**
  - package:home_pocket/features/*/application/**
  - package:home_pocket/features/*/infrastructure/**
  - package:home_pocket/features/*/data/**
```

The features-to-features presentation cross-import is NOT blocked by this global rule (the deny list targets `use_cases/`, `application/`, `infrastructure/`, `data/` subdirectories of features). However, the accounting-presentation's own `import_guard.yaml` may deny outward cross-feature presentation imports, and `domain/import_guard.yaml` at the list level denies `features/**/presentation/**`. More critically: a `CategorySelectionScreen` import from `accounting/presentation/` into `shopping_list/presentation/` violates the domain-import rule at `lib/features/list/domain/import_guard.yaml` if the domain models attempt to reference accounting presentation types.

The more common actual failure: a developer who reads the accounting feature as "shared infrastructure" and imports accounting domain models (e.g., `LedgerType` from `lib/features/accounting/domain/models/transaction.dart`) directly into the shopping list domain. `LedgerType` is defined in `lib/features/accounting/domain/models/transaction.dart` — importing it into `lib/features/shopping_list/domain/` imports from another feature's domain, which violates the cross-feature domain isolation principle even if import_guard does not currently block it. When a new `deny` rule is added (and it will be, as part of hygiene), this import breaks.

**Why it happens:**
`CategorySelectionScreen` is a convenient, production-quality widget that already does everything needed. The developer reuses it to save time. The build failure happens at `dart run custom_lint` time, not at compilation time — it appears as a lint warning/error that blocks CI.

**Consequences:**
CI fails. The `import_guard` CI step (`dart run custom_lint --no-fatal-infos`) returns non-zero. The feature cannot merge.

**Prevention:**
- Move `LedgerType` enum to `lib/shared/` or `lib/core/` before building the shopping list feature, OR define a new `ShoppingLedgerType` enum in `lib/features/shopping_list/domain/models/` that is independent of `LedgerType`. The latter is simpler and avoids touching the accounting domain.
- Do NOT import `CategorySelectionScreen` from `lib/features/accounting/presentation/` into shopping list presentation. Instead, extract the category selection behavior into a shared widget at `lib/shared/widgets/category_selection_widget.dart` that can be consumed by both features. This extraction is a prerequisite and belongs in the data layer phase before shopping list UI begins.
- Alternatively, the shopping list can push category selection via a GoRouter route (navigating to an accounting route) rather than importing the widget directly — but this couples routing to feature internals, which is equally problematic.
- The recommended approach (matching CLAUDE.md Placement Rule): category selection capability is a shared UI concern. Move the reusable core to `lib/shared/widgets/` and leave `CategorySelectionScreen` in accounting as a thin wrapper.
- **Test — CI gate:** After adding the new feature directory, run `dart run custom_lint --no-fatal-infos` and confirm zero new import_guard violations before writing any inter-feature dependency.
- **Test — architectural:** The existing `domain_import_rules_test.dart` + `provider_graph_hygiene_test.dart` will catch violations at test runtime. Run them early.

**Phase to address:** Phase 0 / pre-implementation. Resolve the shared widget extraction before any shopping list UI code is written. This is a prerequisite, not a feature.

---

### Pitfall 3: Drift Migration v19 → v20: Stale CLAUDE.md Says v18

**What goes wrong:**
`CLAUDE.md` in the repository currently states "Drift schema at v18" (the v1.5 constraint text). The actual `schemaVersion` in `app_database.dart` is **v19** (confirmed: the `from < 19` block was added by quick task 260603-ti2 to reorder food category sort orders). A developer who reads CLAUDE.md first and writes `if (from < 19) { await migrator.createTable(shoppingItems); }` will collide with the existing v19 block, skipping the shopping table creation for all existing users at exactly v19. The shopping items table never gets created for any device that upgraded through the category reorder migration.

A second failure mode in the same migration: forgetting `migrator.createTable` in favor of a raw `CREATE TABLE` statement. The existing v18 migration used `customStatement` for its sub-steps, so a developer following that as the template for new table creation will write raw SQL instead of `migrator.createTable(shoppingItems)`. Raw SQL bypasses Drift's type-checking and does not include the `customConstraints` (`CHECK(list_type IN ('public', 'private'))`, `CHECK(quantity >= 1)`, etc.) automatically. The CHECK constraints must be re-stated manually in the raw SQL, and any mismatch between the raw SQL and the Drift table definition causes the app to open against a schema that does not match Drift's expected shape.

A third failure mode: adding `ShoppingItems` to the `@DriftDatabase(tables: [...])` annotation but forgetting to bump `schemaVersion` from 19 to 20. Drift will log a schema mismatch warning in debug mode but may not crash in release mode — the shopping items table does not exist, and all DAO queries throw `SqliteException: no such table: shopping_items`.

**Why it happens:**
CLAUDE.md is the primary reference developers read. Five milestones of schema changes have not been backported into CLAUDE.md. The mismatch between documented schema (v18) and actual schema (v19) creates a migration number collision trap.

**Consequences:**
Silent data loss on existing user devices: shopping items table is never created; all create operations throw at runtime; the user sees an error or a crash.

**Prevention:**
- The first action in the data layer phase: run `grep schemaVersion lib/data/app_database.dart` and confirm the actual version before writing any migration code. Do NOT trust CLAUDE.md's schema version claim.
- Shopping list migration block must be `if (from < 20)` with `schemaVersion => 20`.
- Use `migrator.createTable(shoppingItems)` — NOT `customStatement('CREATE TABLE ...')` — so Drift validates the definition against the annotated table class.
- After adding `ShoppingItems` to the `@DriftDatabase` annotation, run `flutter pub run build_runner build --delete-conflicting-outputs` immediately. The generated `app_database.g.dart` will fail to compile if `schemaVersion` was not bumped (Drift's generated schema validator catches version mismatches).
- **Test — Wave-0 (project convention):** Write a raw-sqlite3 contract test (following the v1.5 `soul_satisfaction` Wave-0 test pattern) that:
  1. Opens an in-memory DB at schema v19 (the pre-migration state) by running the v1–v19 migration sequence.
  2. Applies the v19→v20 migration.
  3. Asserts the `shopping_items` table exists with the correct columns, CHECK constraints, and indices.
  4. Inserts a row with `list_type = 'invalid'` and asserts it throws (CHECK constraint enforced).
- **Update CLAUDE.md** in the same commit that bumps the schema version — this is the only way to prevent the drift from widening further.

**Phase to address:** Phase 1 / data layer. Migration correctness test is a prerequisite for the DAO.

---

### Pitfall 4: Adding ShoppingItems Table/DAO Inside the Feature Directory

**What goes wrong:**
`lib/features/shopping_list/` is a Thin Feature. The Thin Feature Rule (CLAUDE.md, structurally enforced by `import_guard`) is: features NEVER contain `application/`, `infrastructure/`, `data/tables/`, or `data/daos/`. A developer who creates `lib/features/shopping_list/data/shopping_items_table.dart` or `lib/features/shopping_list/data/daos/shopping_item_dao.dart` triggers the global `deny` rule at `lib/features/import_guard.yaml` (`features/*/data/**` is denied). The `AppDatabase` class also lives in `lib/data/app_database.dart` and must reference the table class by import — a table inside `features/` cannot be referenced from `lib/data/` without creating a reverse-direction import violation.

**Why it happens:**
The developer who is only working on the shopping list feature naturally places all shopping list files inside `lib/features/shopping_list/`. This is correct for domain models, repository interfaces, screens, widgets, and providers — but NOT for table definitions, DAOs, or repository implementations.

**Consequences:**
Build failure from `import_guard`. Even if the developer suppresses the lint, the `AppDatabase` class cannot import from `lib/features/` (a layer inversion), so the application will not compile.

**Prevention:**
- The data layer for shopping list lives at:
  - `lib/data/tables/shopping_items_table.dart` — table definition
  - `lib/data/daos/shopping_item_dao.dart` — DAO
  - `lib/data/repositories/shopping_item_repository_impl.dart` — repository implementation
- The feature layer contains only:
  - `lib/features/shopping_list/domain/models/shopping_item.dart` — Freezed model
  - `lib/features/shopping_list/domain/repositories/shopping_item_repository.dart` — interface
  - `lib/features/shopping_list/presentation/` — screens, widgets, providers
- Application use cases live at `lib/application/shopping_list/` — NOT inside the feature.
- **Gate:** Run `dart run custom_lint --no-fatal-infos` after creating each new file. The lint failure is immediate and unambiguous.

**Phase to address:** Phase 1 / data layer setup — the directory structure must be correct from the first file.

---

### Pitfall 5: Sync Pipeline — Adding shopping_item Case Breaks Existing Transaction Sync

**What goes wrong:**
`ApplySyncOperationsUseCase.execute()` loops over all operations in a pulled payload and switches on `entityType`. The shopping item case is added as:
```dart
case 'shopping_item':
  await _applyShoppingItemOperation(operation);
```
This is correct in isolation. The failure modes are:

**Failure A — Constructor not updated.** `ApplySyncOperationsUseCase` receives `ShoppingItemRepository` as a new constructor parameter. Any existing construction site (repository providers, dependency injection in tests) that does not pass the new parameter throws a `TypeError` at app start. Every `ApplySyncOperationsUseCase` instantiation must be updated atomically with the new parameter.

**Failure B — Error propagation swallows transaction sync.** The current `_applyBillOperation` path has no try/catch — an error in `_applyShoppingItemOperation` (e.g., Drift exception on schema mismatch) will propagate and abort the entire `execute()` loop, including any remaining `bill` operations. The v1.4 GAP-1 fix (quick task 260531-u34) invalidated `calendarDailyTotalsProvider` after sync — if a shopping sync error interrupts the loop before bill operations are applied, the calendar staleness fix never gets triggered.

**Failure C — Delete semantics mismatch.** The `bill` delete operation calls `_transactionRepository.softDelete(entityId)`. Shopping items also use soft-delete (the `isDeleted` flag in `ShoppingItems` table). But the `_applyShoppingItemOperation` handler might call a hard-delete (e.g., `dao.deleteById(entityId)`) if the developer does not check the convention. Hard-deleting a synced item means a device that is offline when the delete arrives will never see the tombstone, and will re-create the item on next full sync.

**Failure D — Unknown entity type swallowed.** The `default: continue` branch in the switch silently drops unknown entity types. If a shopping_item operation arrives on a device running an older app version (before v1.6), it is silently ignored — correct behavior. But if a BUG causes a new `entityType` string (e.g., `'shopping-item'` with a hyphen, a typo in the tracker) to be serialized, the operation is silently dropped without any error. Add a debug-mode assertion: `assert(entityType != null, 'entityType must not be null in sync operations')`.

**Why it happens:**
The sync pipeline was designed for transactions, which are always syncable. The constructor and the apply use case have implicit assumptions about entity types that are never tested in isolation.

**Consequences:**
Existing transaction sync breaks (Failure A, B), or shopping deletes silently fail to propagate (Failure C), or shopping operations are silently dropped due to a typo (Failure D).

**Prevention:**
- Wrap `_applyShoppingItemOperation` in a try/catch that logs and continues, matching the error-isolation model for bill operations.
- Update all `ApplySyncOperationsUseCase` construction sites in the same commit as the new constructor parameter — use `grep -rn ApplySyncOperationsUseCase lib/` to find all sites.
- Shopping item delete on pull side: call `shoppingItemRepository.softDelete(entityId)`, not any hard-delete DAO method.
- Use the exact string `'shopping_item'` (underscore, not hyphen) as the `entityType` constant. Define it as a top-level constant in `shopping_item_sync_mapper.dart` and reference it from both `ShoppingItemChangeTracker` and `_applyShoppingItemOperation` — never inline the string literal twice.
- **Test:** Mock `ShoppingItemRepository`, mock `TransactionRepository`. Push a payload containing one bill operation and one shopping_item operation. Assert both repositories receive exactly one call. Then push a payload where the shopping_item operation throws — assert the bill operation still completes (Failure B regression test).

**Phase to address:** Phase 3 / sync wiring. Must be complete before any public-list feature is tested end-to-end.

---

### Pitfall 6: CRDT Conflict Resolution — Concurrent Edits and Completed-State Races

**What goes wrong:**
Two family members simultaneously interact with the same public shopping list item:
- **Scenario A (check-off race):** Member A marks item as completed at T1. Member B edits the item name at T2 > T1. Last-write-wins on `updatedAt` means the remote update from B (with `isCompleted: false` in `data`) would un-check the item, resetting A's completion.
- **Scenario B (clear-completed collision):** Member A taps "Clear all completed" which soft-deletes 5 items. Member B simultaneously un-checks one of those items on their device. If B's update arrives after A's delete tombstone, `_handleUpdate` in the apply use case calls `_handleCreate` (existing=null, per the current `_handleUpdate` implementation which calls `_handleCreate` when existing is null). The soft-deleted item is resurrected.
- **Scenario C (delete-wins inconsistency):** The comment in STACK.md says "if the local item was deleted and a remote update arrives, the delete wins." But the current `_handleUpdate` in `ApplySyncOperationsUseCase` unconditionally calls `_transactionRepository.update(updated)` — it does NOT check `isDeleted` on the existing row. A new `_applyShoppingItemOperation` that mirrors this behavior will resurrect deleted items.

**Why it happens:**
The transaction CRDT applies last-write-wins on `updatedAt` with the implicit assumption that `isDeleted` tombstones are permanent. Shopping items have a user-visible completion state that can be toggled, and the clear-completed operation creates a bulk-delete event that races with individual un-check events.

**Consequences:**
Users see items disappearing and reappearing. The clear-completed action is unreliable in family mode. Items deleted by one member reappear for another.

**Prevention:**
- In `_applyShoppingItemOperation._handleUpdate`: if `existing.isDeleted == true`, do NOT apply the update. The tombstone wins. Return early.
- For the completion-state field specifically: apply a merge strategy where `isCompleted: true` is sticky if the `completedAt` timestamp is later than the incoming update's `updatedAt`. This requires adding a `completedAt DateTime?` column to the table — if this column is added, it must be included in the v20 migration.
- Alternatively, accept last-write-wins on `isCompleted` (simpler) and document the race condition as a known limitation of eventually-consistent list state. This is the approach used by Bring! and AnyList — they accept occasional double-additions and rely on the "clear completed" affordance as the reconciliation mechanism.
- **Test:** Simulate two concurrent updates: create item, apply remote update with `isCompleted: true`, then apply another remote update with newer `updatedAt` and `isCompleted: false`. Verify the final state matches the intended CRDT policy (either last-write-wins or merge-sticky).
- **Test:** Create item, soft-delete it locally, receive a remote `update` operation for the same `entityId`. Verify the item remains soft-deleted (tombstone wins).

**Phase to address:** Phase 3 / sync wiring. Document the chosen conflict policy in a comment in `_applyShoppingItemOperation`.

---

### Pitfall 7: Context-Aware FAB — Wrong Action on Wrong Tab / Regression to Accounting FAB

**What goes wrong:**
The current FAB in `MainShellScreen` has a single `onFabTap` callback that unconditionally opens `ManualOneStepScreen`. Making it context-aware for the shopping tab requires reading `selectedTabIndexProvider` and branching on the value. Two failure modes:

**Failure A — Tab index hardcoded.** The shopping list is tab index 3 (`IndexedStack` child 3, per `MainShellScreen` at line 124). If the tab order is changed in a future refactor, the hardcoded `if (currentIndex == 3)` branch routes the FAB to the wrong action silently.

**Failure B — Accounting FAB regression.** The `onFabTap` callback currently invalidates `listTransactionsProvider`, `calendarDailyTotalsProvider`, `monthlyReportProvider`, `todayTransactionsProvider`, and `bestJoyMomentProvider` after returning from `ManualOneStepScreen` (confirmed in `main_shell_screen.dart` lines 136–188). When the FAB is made context-aware, the shopping tab path must NOT call these same invalidations (they are irrelevant for shopping items and add unnecessary re-fetches). But the accounting path MUST still call all of them. A developer who extracts the FAB action into a conditional block may accidentally omit the invalidations from the accounting path.

**Failure C — `shoppingItemsProvider` not invalidated after add.** After returning from the add-item screen on the shopping tab, the shopping list does not update because no invalidation is called. The user sees the item only after a manual pull-to-refresh.

**Why it happens:**
The FAB action is a multi-step callback with side effects (invalidations). Adding a conditional branch with different side effects is error-prone.

**Consequences:**
Accounting FAB stops refreshing home screen data after entry (Failure B). Shopping list does not reflect newly added items (Failure C). In future tab-reorders, FAB opens wrong screen (Failure A).

**Prevention:**
- Define a `_ShoppingTabIndex` constant at the top of `MainShellScreen` or in a `nav_constants.dart` file in `lib/core/config/`. Reference the constant in the FAB branch — never inline the literal `3`.
- Extract the accounting FAB action into a named `_onAccountingFabTap` private method, and the shopping FAB action into `_onShoppingFabTap`. The `onFabTap` callback dispatches to one of them based on `currentIndex`. This separation makes it impossible to accidentally share invalidation lists.
- After returning from `ShoppingItemFormScreen`, invalidate `shoppingItemsProvider` (and any filter-state-derived providers that depend on it).
- **Test:** Write a widget test for `MainShellScreen` that:
  1. Sets tab index to 3 (shopping), taps FAB, asserts that `ShoppingItemFormScreen` is pushed (not `ManualOneStepScreen`).
  2. Sets tab index to 0 (home), taps FAB, asserts that `ManualOneStepScreen` is pushed.
  3. Returns from `ManualOneStepScreen`, asserts that `listTransactionsProvider` and `calendarDailyTotalsProvider` are invalidated (or verify the side effects via `ProviderObserver`).

**Phase to address:** Phase 2 / shell wiring. FAB context-awareness is a shell-level change; get it right before building any shopping list screen UI.

---

### Pitfall 8: Riverpod 3 — keepAlive, Segmented Control State Survival, and Invalidation After Mutation

**What goes wrong:**
The shopping list feature has several Riverpod state providers that interact with `IndexedStack` semantics:

**Problem A — Segmented control state (public/private) not keepAlive.** The `listTypeProvider` (public/private segment) is annotated `@riverpod` without `keepAlive: true`. Under `IndexedStack`, the shopping list widget is always mounted — but if the provider is `autoDispose` and has no active listener while the tab is in the background, it may be disposed in Riverpod 3 when the last listener drops momentarily (e.g., during a hot reload or widget rebuild cycle). The user returns to the shopping tab and finds the segment reset to the default (e.g., public), even though they were on the private list.

**Problem B — Invalidation after batch operations.** After `ClearCompletedItemsUseCase.execute()` (deletes all completed items), the `shoppingItemsProvider` must be invalidated. After `batch-delete` (multi-select delete), the same invalidation is required. After a sync pull that applied shopping item updates, the shell's sync listener in `MainShellScreen` must invalidate `shoppingItemsProvider` — but the existing listener (confirmed in `main_shell_screen.dart` lines 38–103) only invalidates transaction-related providers. A shopping sync that arrives while the shopping tab is visible will not update the list.

**Problem C — Filter state staleness after segment switch.** If the filter state (ledger, category, tags) is shared between public and private lists and the user switches segments, the filter from the public list persists on the private list. Items appear filtered in the private list by the category the user last selected in the public list. The filter state should either be independent per segment or reset on segment switch.

**Problem D — `waitForFirstValue` pattern not used.** A new `FutureProvider` or `AsyncNotifier` for shopping items that uses `await container.read(shoppingItemsProvider.future)` in a test will hit the Riverpod 3 "Bad state: disposed during loading" trap documented in CLAUDE.md. All async provider tests must use `waitForFirstValue<T>(container, provider)` from `test/helpers/test_provider_scope.dart`.

**Why it happens:**
The v1.4 list feature set the `keepAlive: true` precedent for filter state (confirmed in `state_list_filter.dart` line 16). The shopping list developer may not replicate this for the segmented control provider or may over-apply it to providers that should reset.

**Consequences:**
Users experience the private/public segment resetting unexpectedly (Problem A). Shopping list does not update after sync (Problem B). Cross-segment filter contamination (Problem C). Tests have intermittent "disposed during loading" failures (Problem D).

**Prevention:**
- `listTypeProvider` (segment): `keepAlive: true` — user's last-viewed segment must survive tab switches.
- `shoppingFilterProvider` (filter state): define a filter per segment or reset on segment change. If shared: add a `ref.listen(listTypeProvider, (_, __) => clearFilters())` in the shopping screen.
- `shoppingItemsProvider` (the stream or future): does NOT need `keepAlive` if it is a `StreamProvider` wrapping a Drift watch query — the stream subscription is maintained by the always-mounted `IndexedStack` widget.
- Add shopping item invalidation to `MainShellScreen`'s sync listener: `ref.invalidate(shoppingItemsProvider)`.
- Use `ProviderContainer.test()` in all tests. Use `waitForFirstValue` for all async provider reads in tests.
- **Test:** On the shopping tab, select "Private" segment, navigate to analytics tab and back. Assert the segment is still "Private".
- **Test:** Add a shopping item while the shopping tab is visible (simulate via provider invalidation). Assert the list widget rebuilds without a manual pull-to-refresh.
- **Test — segment filter isolation:** Set ledger filter to "Joy" on public list. Switch to private segment. Assert filter is reset to "All" (if the chosen policy is per-segment reset).

**Phase to address:** Phase 2 / shell and state wiring. Decide and document `keepAlive` policy for every new provider before writing the first widget.

---

### Pitfall 9: Completed-to-Bottom vs Swipe-to-Delete vs Batch-Select Gesture Conflicts

**What goes wrong:**
Three interaction patterns compete for the same gesture space on a shopping item row:
- **Tap:** Completion toggle (check/uncheck)
- **Swipe:** Delete (from v1.4 `Dismissible` pattern)
- **Long-press:** Enter batch-select mode

On iOS, `Dismissible` captures horizontal swipe. If `ReorderableListView` is also present (for drag-sort), it captures the long-press (its reorder handle uses long-press). Batch-select also uses long-press. These two features conflict.

A second conflict: completed items sort to the bottom. If the user initiates a swipe on an item that is in the process of animating to the bottom (just checked off), the `Dismissible` gesture starts on one row index but the underlying data item is now at a different position. If the provider update races with the gesture completion, the wrong item may be deleted.

A third conflict: batch-select mode shows checkboxes on all items. The completion-toggle tap must be disabled during batch-select mode (the tap now means "add to selection", not "complete this item"). If this mode-switching is not handled, a tap in batch-select mode simultaneously completes and selects the item.

**Why it happens:**
The FEATURES.md research flagged this explicitly: "FEATURES.md flagged: drag-sort conflicts with swipe-delete" and "Completed-to-bottom + batch-select gesture conflicts with swipe-delete." The v1.6 scope deliberately excludes drag-sort (FEATURES.md Anti-Features: "Drag-to-reorder items") but includes swipe-delete + batch-select + completed-to-bottom simultaneously.

**Consequences:**
Accidental deletion of the wrong item. Tapping to complete an item during batch-select mode also removes it from the selected set or triggers unintended selection. Gesture ambiguity causes user frustration.

**Prevention:**
- Batch-select mode is an exclusive UI mode: when `isBatchSelectModeProvider.state == true`, disable `Dismissible` (set `direction: DismissDirection.none`) and replace the row tap handler with a select/deselect toggle.
- Completion toggle and `Dismissible` are compatible as long as the item list is not reordering during a gesture. Use `ValueKey(item.id)` on all list items so Flutter's `Dismissible` tracks items by ID, not by index. This prevents the index-mismatch race during completed-to-bottom animation.
- Use `AnimatedList` or `AnimatedSwitcher` for the completed-to-bottom transition rather than an immediate setState — give the animation time to complete before the provider state is updated. A 200ms delay after `isCompleted = true` before re-querying the sorted list prevents gesture-over-animating-item conflicts.
- Do NOT add drag-sort handles (they share the long-press gesture with batch-select). The FEATURES.md Anti-Features decision was correct — removing drag-sort eliminates the hardest gesture conflict.
- **Test (widget):** Enter batch-select mode. Attempt to swipe an item. Assert `Dismissible` does not trigger (no delete callback fires). Tap the row. Assert the item is added to the selection set (not completed).
- **Test (widget):** Tap an item to complete it. Assert the row moves to the bottom section within one animation frame. Assert that a concurrent swipe on the just-completed item deletes the correct item (by ID, not by index).

**Phase to address:** Phase 4 / list UI. These interactions must be designed and tested before golden baselines are set.

---

### Pitfall 10: i18n Rename — Stale 待办/Todo Strings and ARB Key Parity Breakage

**What goes wrong:**
The rename from 待办事项/Todo to 购物清单/買い物リスト/Shopping List touches existing ARB keys used in two confirmed locations:
- `homeTabTodo` — nav bar label (confirmed: `app_ja.arb: "やること"`, `app_zh.arb: "待办事项"`, `app_en.arb: "Todo"`)
- `todoTab` — used in `MainShellScreen` line 125 (`S.of(context).todoTab`)

Additional risk: the rename introduces new keys for all shopping list UI strings (item form labels, filter labels, segment labels, empty state messages, confirmation dialogs). If any new key is added to one ARB file but not all three, `flutter gen-l10n` fails and the entire generated `lib/generated/` directory is out of sync. The CI `flutter analyze` step then fails on `lib/generated/app_localizations.dart` (the generated file references undefined keys from the incomplete ARB).

A secondary risk: the v1.5 grep gate (`grep` for `生存/灵魂/魂/ソウル/Survival/Soul` in ARB values) is extended by ADR-017. The shopping list may introduce new strings that accidentally use old vocabulary (e.g., a tag label that says "Soul purchase" instead of "Joy purchase"). This would fail the grep gate if it is run post-v1.6.

**Why it happens:**
Renaming existing keys is a safe operation (the generated class is updated). But the rename touches two keys that currently have callers across the codebase. Using `grep -rn 'homeTabTodo\|todoTab'` before renaming is essential. Missing one call site leaves a hardcoded reference to the old ARB key, which becomes an undefined symbol in the generated class.

**Consequences:**
`flutter gen-l10n` fails (missing key in one locale), blocking CI. Or the rename is incomplete and the old key name remains in some dart files as a compile error. Or the nav bar still shows "やること" in Japanese while the tab content shows the new shopping list.

**Prevention:**
- Rename `homeTabTodo` and `todoTab` keys in all three ARB files atomically in the same commit. Run `grep -rn 'homeTabTodo\|todoTab' lib/` before renaming to find all Dart call sites; update them in the same commit.
- Prefer adding new keys (e.g., `shoppingListTab`, `shoppingListScreen`) over renaming the old keys, to avoid breaking any future reference that might exist in test fixtures. The old keys can be deleted once the new ones are in use.
- All new shopping list ARB keys must be added to `app_ja.arb`, `app_zh.arb`, and `app_en.arb` in the same commit. Run `flutter gen-l10n` after every ARB commit and verify it produces no warnings.
- Run the existing vocabulary grep gate after all ARB work: `grep -rn '生存\|灵魂\|Survival\|Soul' lib/l10n/` must return zero hits in the new keys.
- **Test — CI:** `flutter gen-l10n` returns exit 0. The ARB key count in `app_ja.arb`, `app_zh.arb`, and `app_en.arb` is identical after each commit touching ARB files. Verify: `jq 'keys | length' lib/l10n/app_*.arb` should produce the same integer for all three files.
- **Golden churn:** Any golden that renders `homeTabTodo` text in the nav bar will fail after the rename. Re-baseline intentionally — confirm the diff shows only the text change, no layout shift.

**Phase to address:** Phase 2 / rename + shell wiring. Do the rename before any shopping list UI is visible, so the nav bar shows the correct label from the start.

---

### Pitfall 11: Estimated Price as Float / Integer Sub-Unit Confusion

**What goes wrong:**
The shopping item form accepts estimated price as user input. If stored as a `double` (Dart `double`), floating-point arithmetic produces subtotals like `¥299.999999` instead of `¥300` when `quantity * estimatedPrice` is computed. The `Transactions.amount` column in the existing schema is `INTEGER` (yen, no sub-units for JPY), but a developer may use `REAL` for shopping item price thinking "prices can have decimals."

A second failure mode: the `estimatedTotalProvider` (sum of `estimatedPrice * quantity` across all active items) uses Dart's `int` arithmetic but the values arrive from Drift as nullable integers. Null-handling errors (`null * quantity` throws a null dereference) cause the subtotal widget to show an error state or crash.

A third failure mode: `NumberFormatter` is called with an integer sub-unit amount (e.g., `300` for ¥300) but with the wrong currency code, producing `$300.00` instead of `¥300`. The shopping list form does not have a `currencyCode` parameter — it must derive the currency from the same `bookProvider` that transactions use.

**Why it happens:**
`Transactions.amount` is already integer and the schema design doc establishes this convention, but the shopping list is a new entity and a new developer may not read the convention carefully. The STACK.md research specified `IntColumn get estimatedPrice => integer().nullable()()` correctly — the pitfall is deviating from this in implementation.

**Consequences:**
Subtotal display shows nonsensical fractional yen values. Null pointer crashes in the subtotal calculation. Wrong currency symbol in price display.

**Prevention:**
- `estimatedPrice` column: `IntColumn get estimatedPrice => integer().nullable()()`. No `RealColumn`. No `double` in the domain model.
- Subtotal formula: `items.where((i) => !i.isCompleted && i.estimatedPrice != null).fold<int>(0, (sum, i) => sum + (i.estimatedPrice! * i.quantity))`. The null guard is explicit; no implicit null-to-zero coercion.
- Currency code: derive from `ref.watch(bookByIdProvider(bookId: bookId)).value?.currency ?? 'JPY'` — the same pattern used in `MainShellScreen` at line 86.
- Use `AppTextStyles.amountSmall` for price display (includes `FontFeature.tabularFigures()` for alignment). Use `NumberFormatter` with the resolved currency code. Never use `Text('¥$price')`.
- **Test:** Insert item with `estimatedPrice = 100`, `quantity = 3`. Assert `estimatedTotalProvider` returns `300` (not `300.0`, not `299.999...`). Insert item with `estimatedPrice = null`. Assert it is excluded from the total (total remains `300`).
- **Test:** Insert item with `estimatedPrice = 0`. Verify the `CHECK(quantity >= 1)` constraint is enforced in the DB. Verify `estimatedPrice = 0` is NOT excluded from the display (a zero-price item is valid — it represents "I don't know the price yet but the item exists").

**Phase to address:** Phase 1 / table definition. Get the column type right before writing any DAO or use case. Verify the subtotal formula in the use case test before the subtotal widget is built.

---

### Pitfall 12: Scope Creep — Accidentally Building Transaction Linkage (D3) or Gamification (ADR-012)

**What goes wrong:**
Two adjacent temptations will surface during implementation:

**Temptation A — D3 violation:** After marking an item completed, the obvious next step is "record this as an expense." A developer adds a "Mark complete and record expense" action button alongside the simple completion checkbox. This violates D3 ("no transaction linkage") and requires opening `ManualOneStepScreen` or an inline amount-entry flow. The locked decision is firm: completing an item only checks it off.

**Temptation B — ADR-012 violation:** The shopping list is a natural surface for streaks ("You've cleared your shopping list 5 times this week!") or achievement badges ("First family shopping list created!"). ADR-012 prohibits all such mechanics cross-milestone. A developer who does not read ADR-012 may add a "Shopping streaks" section to the analytics screen or a completion count badge on the tab icon.

**Temptation C — Feature creep in estimated total:** The estimated total (`Σ estimatedPrice * quantity`) for active items is a differentiator (FEATURES.md). Extending it to compare against a monthly budget, or linking it to `JoyMetricVariant` (how much of my Joy budget am I about to spend?), pulls the shopping feature into the accounting domain and violates D3 semantically.

**Why it happens:**
The shopping list naturally bridges accounting and list management. The dual-ledger item metadata (日常/悦己) creates a suggestive link to the Joy metric. The team is familiar with the Joy metric and it is tempting to surface it on a new screen.

**Consequences:**
Scope expansion delays the milestone. D3 violations require partial rewrites. ADR-012 violations require ADR revision (a governance overhead).

**Prevention:**
- Add a D3 compliance check to the code review checklist: does any shopping list action (completion, edit, delete, batch-delete, clear-completed) call any method on `TransactionRepository`? If yes, it is a D3 violation.
- Add an ADR-012 check: does any shopping list widget display a count, streak, achievement, or comparative metric over time? If yes, it is an ADR-012 violation.
- The estimated total display must clearly be labeled "estimated budget" not "spending" or "planned expense" — the label frames it as a planning tool, not an accounting action.
- When the shopping tab is visible, the FAB opens add-item, not transaction entry. This is correct (D2). The design MUST NOT add a secondary "add transaction" action within the shopping list screen — the user must navigate to another tab for that.

**Phase to address:** Every phase. Include D3 and ADR-012 in the acceptance criteria for each shopping list phase.

---

## Moderate Pitfalls

### Pitfall 13: `build_runner` Not Re-Run After Schema and Model Changes

After adding `ShoppingItems` to `@DriftDatabase`, `ShoppingItem` Freezed model, and `@riverpod` providers, `build_runner` must be re-run. The generated files are:
- `app_database.g.dart` — updated by Drift when `@DriftDatabase(tables: [...])` changes
- `shopping_item.freezed.dart` + `shopping_item.g.dart` — generated by `freezed`/`json_serializable`
- `repository_providers.g.dart` — generated by `riverpod_generator` for each `@riverpod` annotation

Forgetting to re-run `build_runner` after any of these changes causes compile errors that are confusing because the source file looks correct but the generated code references the old schema. The CI `build_runner` clean-diff guardrail will catch this, but it wastes a CI cycle.

**Prevention:** Run `flutter pub run build_runner build --delete-conflicting-outputs` after every change to `@DriftDatabase`, `@freezed`, or `@riverpod` annotated files. Run it again after any `git merge` or `git rebase`. The project rule in CLAUDE.md is explicit on this.

**Phase to address:** Every phase. Add to the pre-commit checklist.

---

### Pitfall 14: `import_guard` YAML Missing for New Feature Directories

When `lib/features/shopping_list/` is created, import_guard rules from parent directories (`lib/features/import_guard.yaml`) apply via `inherit: true`. But the feature should also have its own `import_guard.yaml` files in `domain/`, `presentation/`, `domain/models/`, and `domain/repositories/` to match the pattern of every other feature (confirmed: `list/domain/import_guard.yaml`, `list/presentation/import_guard.yaml`, `list/domain/models/import_guard.yaml`). Missing per-subdirectory yamls means the fine-grained deny rules (e.g., domain must not import infrastructure, presentation must not import DAOs directly) are not enforced for the shopping list feature.

**Prevention:** Copy the import_guard YAML structure from `lib/features/list/` verbatim when creating the shopping list feature directory structure. Run `dart run custom_lint --no-fatal-infos` to verify zero violations.

**Phase to address:** Phase 1 / directory setup.

---

### Pitfall 15: Golden Test Churn from Shopping List Layout

The shopping list has two list sections (active + completed), a segmented control, and optional filter chips — a layout with more variable elements than the transaction list. Goldens set during active development (before the layout is stable) will require constant re-baselining. The project currently has 2297 tests (MEMORY.md: "full suite 2297/2297 green"); large golden additions must be intentional.

**Prevention:** Follow the v1.4 and v1.5 pattern — defer golden baselines to the final polish phase. Golden only isolated widgets (single item tile, empty state variant, segment control in each state) rather than full-screen composites. Plan for no more than 18 new PNG masters for this feature (ja/zh/en × light/dark × 2-3 widget variants). The golden re-baseline commit must be isolated from any functional change commit to maintain diff-attribution.

**Phase to address:** Final polish phase only.

---

## Minor Pitfalls

### Pitfall 16: Tags Stored as JSON vs Normalized Table

The STACK.md recommendation stores tags as a JSON-encoded `List<String>` in a single `TEXT` column. The risk: filtering by tag requires a `LIKE '%"tag_value"%'` query, which does not use an index and scans all rows. For a shopping list that typically has 20–50 items, this is not a performance problem. But if tags evolve into a more structured feature (tag autocomplete across lists, tag-based analytics), the JSON encoding becomes a bottleneck.

**Prevention:** Proceed with JSON encoding as designed (consistent with the `metadata` column convention in `transactions_table.dart`). Document the encoding in a comment in `shopping_items_table.dart`. If tag-based analytics are requested in a future milestone, migrate to a junction table then.

### Pitfall 17: `selectedTabIndexProvider` Hardcoded Index for Shopping Tab

The shopping tab is at index 3. The `selectedTabIndexProvider.notifier.select(3)` call exists in `HomeBottomNavBar`. If a new tab is inserted in the future, this index shifts. A `const _kShoppingTabIndex = 3` in a central location prevents silent misbehavior.

**Prevention:** Define the constant immediately when wiring the FAB context-awareness.

### Pitfall 18: `SyncOrchestratorResult.pushedCount` Only Counts Transaction Ops

`SyncOrchestratorSuccess.pushedCount` (confirmed in `sync_orchestrator.dart` line 176) returns `txnOps.length`. After adding shopping item ops to the incremental push, the `pushedCount` should reflect both transaction and shopping item ops, or a separate `shoppingPushedCount` should be added. If left as-is, the sync status display underreports the actual number of pushed operations.

**Prevention:** Either add `shoppingOps.length` to `pushedCount`, or leave it as-is and document the known limitation. This is a cosmetic issue only — sync correctness is not affected.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Directory setup | Tables/DAOs placed inside `features/` | Create `lib/data/tables/shopping_items_table.dart` first; run `custom_lint` immediately |
| Migration v19→v20 | Using `from < 19` (collision) or forgetting `schemaVersion` bump | Read actual schemaVersion from file, not CLAUDE.md; Wave-0 contract test |
| Shared category widget | Importing `CategorySelectionScreen` from accounting presentation | Extract to `lib/shared/widgets/` before writing any shopping list UI |
| ShoppingItemChangeTracker | Missing `listType == 'public'` guard | Unit test: private item → tracker.pendingCount == 0 |
| ApplySyncOperationsUseCase | New constructor param breaks all injection sites | `grep ApplySyncOperationsUseCase lib/` before adding the param |
| Shell FAB wiring | Accounting FAB invalidations dropped; shopping invalidation missing | Separate named methods; explicit test for each FAB path |
| Segmented control state | listTypeProvider auto-disposed on tab switch | `keepAlive: true`; widget test verifying state survival |
| Filter state after segment switch | Cross-segment filter contamination | Per-segment filter or explicit reset on `ref.listen(listTypeProvider)` |
| Item row interactions | Batch-select vs swipe-delete vs tap-to-complete conflicts | `Dismissible.direction = none` in batch-select mode; `ValueKey(item.id)` on all rows |
| ARB rename | `homeTabTodo`/`todoTab` call sites missed | `grep -rn 'homeTabTodo\|todoTab' lib/` before renaming |
| Estimated price | Using `REAL` column instead of `INT` | Column type set at table definition time; subtotal test verifies integer arithmetic |
| Transaction linkage | Completion action calling `TransactionRepository` | D3 compliance check in every phase's acceptance criteria |
| Gamification | Streak/badge UI on shopping surfaces | ADR-012 check in every phase's acceptance criteria |

---

## Sources

- `/Users/xinz/Development/home-pocket-app/lib/data/app_database.dart` (read 2026-06-07) — confirmed `schemaVersion => 19`; confirmed `from < 19` block is category reorder (NOT shopping list). HIGH confidence.
- `/Users/xinz/Development/home-pocket-app/lib/application/family_sync/apply_sync_operations_use_case.dart` (read 2026-06-07) — confirmed switch structure, `_handleUpdate` does NOT check `isDeleted` on existing row. HIGH confidence.
- `/Users/xinz/Development/home-pocket-app/lib/application/family_sync/transaction_change_tracker.dart` (read 2026-06-07) — confirmed no `listType` guard; `_pendingOps.add(operation)` is unconditional. HIGH confidence.
- `/Users/xinz/Development/home-pocket-app/lib/application/family_sync/sync_orchestrator.dart` (read 2026-06-07) — confirmed `_changeTracker.flush()` in `_executeIncrementalPush`; `pushedCount = txnOps.length` only. HIGH confidence.
- `/Users/xinz/Development/home-pocket-app/lib/features/home/presentation/screens/main_shell_screen.dart` (read 2026-06-07) — confirmed FAB hardcoded to `ManualOneStepScreen`; confirmed sync listener only invalidates accounting providers; confirmed `IndexedStack` with shopping tab at index 3. HIGH confidence.
- `/Users/xinz/Development/home-pocket-app/lib/features/list/presentation/providers/state_list_filter.dart` (read 2026-06-07) — confirmed `keepAlive: true` on `ListFilter` notifier; established the precedent. HIGH confidence.
- `/Users/xinz/Development/home-pocket-app/lib/features/list/presentation/providers/state_list_transactions.dart` (read 2026-06-07) — confirmed cross-feature imports from `accounting/`, `family_sync/`, `home/`, `settings/` features; these are not blocked by current import_guard rules (presentation-to-presentation cross-feature imports permitted); domain-to-domain would be blocked. HIGH confidence.
- `/Users/xinz/Development/home-pocket-app/lib/features/import_guard.yaml` (read 2026-06-07) — confirmed global deny: `features/*/use_cases/**`, `features/*/application/**`, `features/*/infrastructure/**`, `features/*/data/**`. HIGH confidence.
- `/Users/xinz/Development/home-pocket-app/lib/features/accounting/presentation/import_guard.yaml` (read 2026-06-07) — denies `infrastructure/**`, `data/daos/**`, `data/tables/**` for accounting presentation. HIGH confidence.
- `/Users/xinz/Development/home-pocket-app/lib/l10n/app_ja.arb` + `app_zh.arb` + `app_en.arb` (read via grep 2026-06-07) — confirmed `homeTabTodo` and `todoTab` keys present in all three locales. HIGH confidence.
- `/Users/xinz/Development/home-pocket-app/.planning/PROJECT.md` (read 2026-06-07) — confirmed GAP-1 fix (260531-u34) invalidated `calendarDailyTotalsProvider` at sync + FAB sites; confirmed v1.4 `keepAlive` decision; confirmed Riverpod 3 migration lessons. HIGH confidence.
- `/Users/xinz/Development/home-pocket-app/.planning/research/FEATURES.md` (read 2026-06-07) — confirmed drag-sort excluded (Anti-Features), confirmed gesture conflict flagged. HIGH confidence.
- `/Users/xinz/Development/home-pocket-app/.planning/research/STACK.md` (read 2026-06-07) — confirmed `estimatedPrice` as `IntColumn`, confirmed `listType == 'public'` guard design, confirmed sync entity type string. HIGH confidence.
- `CLAUDE.md` (read 2026-06-07) — Riverpod 3 conventions (ProviderException, keepAlive, ref.listen, waitForFirstValue, ProviderContainer.test()), Drift TableIndex syntax, i18n rules, common pitfalls list. HIGH confidence.

---

*Pitfalls research for: v1.6 Shopping List feature on Home Pocket (Flutter + Riverpod 3 + Drift + SQLCipher)*
*Researched: 2026-06-07*
