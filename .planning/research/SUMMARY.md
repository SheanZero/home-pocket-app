# Project Research Summary

**Project:** Home Pocket v1.6 — 购物清单 (Shopping List)
**Domain:** Mobile shopping-list feature integrated into a local-first, E2EE family accounting app (Flutter + Riverpod 3 + Drift + SQLCipher)
**Researched:** 2026-06-07
**Confidence:** HIGH — all four research files draw exclusively from direct codebase reads; no training-data assertions made without file verification

---

## Executive Summary

The v1.6 shopping list is a net-new feature module built entirely on the existing locked stack — **zero new packages required**. Every capability (Drift table, Riverpod providers, drag-sort, public/private segmented control, family-sync integration, filter chips, swipe-delete, batch-select) already has a working primitive in the installed dependencies. The feature adds one Drift table (ShoppingItems), one DAO, one repository impl, six use cases, one ShoppingItemChangeTracker, and a presentation layer that mirrors the established lib/features/list/ thin-feature pattern. The Drift schema moves from **v19 to v20** — the v19 slot was already consumed by the v1.5 category sort-order reorder and must not be reused.

The family sync pipeline is entity-agnostic at the wire level: adding shopping items requires only three targeted changes — ShoppingItemChangeTracker (mirrors TransactionChangeTracker), a case shopping_item: branch in ApplySyncOperationsUseCase, and a 4-line extension to SyncOrchestrator._executeIncrementalPush. No relay-server changes are needed. The most important invariant: **private items must never enter the change tracker**. The listType == public guard lives at the use-case boundary (not in the tracker or orchestrator), and is the single highest-severity privacy risk in the feature. A private item that reaches the tracker is encrypted and relayed to every family member, which constitutes a fundamental breach of the app zero-knowledge design philosophy.

The competitive landscape (AnyList, Bring!, OurGroceries, Listonic) converges on a standard UX pattern: tap-to-complete, completed-to-bottom, clear-completed, swipe-to-delete, and a filter bar. Home Pocket differentiators are the **estimated running total** (the most-requested missing feature across all three top competitors), **dual-ledger item coloring** (unique to this app), and **privacy-first local-first sync** (no competitor is offline-first with E2EE). These are achievable without scope expansion. The locked decisions (D1-D4) are well-grounded: the public/private segmented model maps cleanly to the existing sync pipeline, the FAB context-awareness is a 4-line if (currentIndex == 3) guard, no transaction linkage keeps the feature scope clean, and quantity + estimated price are the enabling fields for the running-total differentiator.

---

## Key Findings

### Recommended Stack

**Zero new packages.** The entire feature is buildable on the installed stack. ReorderableListView (drag-sort, already used in CategorySelectionScreen) and Dismissible (swipe-to-delete, already used in the transaction list) cover all list interaction patterns. CupertinoSlidingSegmentedControl or SegmentedButton covers D1. FilterChip + Wrap covers the filter bar. showModalBottomSheet covers the add/edit form.

**Core technologies engaged by v1.6:**

- **Drift ^2.25.0** — new ShoppingItems table + ShoppingItemDao; schema bump v19->v20 via migrator.createTable; .watch() stream mandatory (not FutureProvider + ref.invalidate)
- **Riverpod 3 / riverpod_annotation ^4.0.0** — @riverpod providers: state_list_type (keepAlive), state_shopping_filter (keepAlive), state_shopping_items (StreamProvider); Riverpod 3 naming rules apply (ShoppingItemsNotifier -> shoppingItemsProvider)
- **Freezed ^3.0.0** — ShoppingItem, ShoppingListFilter, ShoppingItemParams models; always copyWith, never mutate
- **flutter_localizations / intl 0.20.2 (exact pin)** — rename homeTabTodo -> homeTabShoppingList in all three ARB files (ja/zh/en); all new string keys must be added atomically across all three locales
- **uuid ^4.5.3** — item IDs; same as sync ops
- **lucide_icons_flutter ^3.1.14** — checkbox, trash, drag-handle icons (existing icon set)
- **collection ^1.19.1** — available for sortedBy/groupBy if needed, though SQL ordering is preferred

**Version pins to leave alone:** intl: 0.20.2 (exact), sqlcipher_flutter_libs: ^0.6.7 (not sqlite3_flutter_libs), file_picker/package_info_plus/share_plus win32 trio (do not bump individually).

---

### Expected Features

**Must have (table stakes) — all four agents agree these are non-negotiable for v1.6:**

- Tap to check off item (animate strikethrough + smooth move to completed section)
- Checked items sort to bottom + visual divider between active and completed sections
- One-tap clear all completed with confirmation dialog
- Add item: name (required) + optional ledger/category/tags/note/quantity/estimated price (D4)
- Edit item (same form sheet as add)
- Swipe-to-delete single item (confirm dialog; matches v1.4 pattern)
- Batch delete via long-press -> selection mode -> floating bottom bar -> confirmation
- Public / Private segmented control (D1)
- Public list syncs via existing family_sync pipeline
- Filter bar: ledger chips (All / daily / joy) + category + Active/All toggle + clear chip
- Empty states — 3 variants per list type (empty private, empty public solo, empty public family)
- Context-aware FAB (D2)
- Todo->Shopping List rename across zh/ja/en ARB
- Per-item family attribution chip on public list tile (who added)
- Dual-ledger color accent (left border on tile — near-zero complexity)
- Estimated total / running subtotal (sum of estimatedPrice x quantity for active items only)

**Should have (differentiators — include in v1.6 launch):**

- Estimated total display with priced-item count — highest unmet competitor need
- Dual-ledger item coloring with palette.daily/palette.joy — unique to this app, zero new infrastructure
- Per-item family attribution (addedByBookId) on public list — no competitor does this

**Defer to v1.x after validation:**

- Name autocomplete from item history (P2) — add when users report friction re-adding common items
- Sort by category with group headers (P2) — add when users have 15+ items
- Tag filter chip (P2) — add when tags see active use on shopping items
- Duplicate item detection / warn-on-same-name (P2)
- Collapsible completed section (P2)

**Explicitly skip (anti-features):**

- Completion creates transaction — locked out by D3; violates pure-list contract
- Gamification (streaks, badges, achievement unlocks) — hard-blocked by ADR-012
- Drag-to-reorder items — conflicts with swipe-delete gestures; category grouping covers 80% of the use case
- Voice-add shopping item, APNS push, barcode/QR scan, multiple lists beyond public/private, price history

---

### Architecture Approach

The shopping list slots cleanly into the existing 5-layer Clean Architecture following the Thin Feature pattern established by lib/features/list/. No new architectural layer is introduced. The file placement rule is strict: tables and DAOs go in lib/data/ (never inside lib/features/), use cases go in lib/application/shopping_list/, domain models and repository interfaces go in lib/features/shopping_list/domain/, and presentation code goes in lib/features/shopping_list/presentation/.

Two cross-feature widget resolution actions are required before any shopping list UI is written: LedgerTypeSelector must be moved to lib/shared/widgets/ (it has no accounting-specific state), and CategorySelectionScreen must be explicitly allow-listed in shopping_list/presentation/import_guard.yaml (it cannot be moved to shared because it depends on accounting-feature providers).

**Major components:**

1. **Data layer** (lib/data/) — ShoppingItems table, ShoppingItemDao, ShoppingItemRepositoryImpl; schema v19->v20 via migrator.createTable(shoppingItems)
2. **Domain layer** (lib/features/shopping_list/domain/) — ShoppingItem (Freezed), ShoppingListFilter (Freezed), ShoppingItemParams (Freezed), ShoppingItemRepository (interface); all import_guard.yaml files mirroring the list/domain/ pattern
3. **Application layer** (lib/application/shopping_list/) — 6 use cases: Create, Update, Delete, ToggleCompleted, Reorder, ClearCompleted; each guards listType == public before touching the change tracker
4. **Sync integration** (lib/application/family_sync/) — ShoppingItemChangeTracker (mirrors TransactionChangeTracker), SyncOrchestrator 4-line extension, ApplySyncOperationsUseCase case branch + handler, SyncEngine.onShoppingItemChanged()
5. **Presentation layer** (lib/features/shopping_list/presentation/) — ShoppingListScreen, 5 widgets, 4 providers; FAB context-awareness wired in MainShellScreen via if (currentIndex == 3) guard

**Key patterns:**

- **Reactive stream mandatory:** watchByListType(listType).watch() wrapped in a StreamProvider — the v1.4 GAP-2 lesson (dead watchByBookIds) must not be repeated; pull-sync writes from family members must appear automatically without ref.invalidate
- **keepAlive: true** for listTypeProvider (segment) and shoppingFilterProvider (filter) — state must survive IndexedStack tab switches
- **Completed-to-bottom via SQL ordering only:** ORDER BY is_completed ASC, sort_order ASC, created_at ASC — no client-side grouping
- **Two SliverList sections:** active items in SliverReorderableList, completed items in plain SliverList below a divider — never mix reorderable and non-reorderable items in one ReorderableListView
- **estimatedPrice as IntColumn (nullable integer yen)** — matches Transaction.amount convention; never REAL/double
- **Note field encrypted at repository boundary** — mirrors TransactionRepositoryImpl note encryption via FieldEncryptionService

---

### Critical Pitfalls

The four research agents reached full agreement on these top pitfalls — ordered by combined severity:

1. **Private item leaks into family sync (PRIVACY-CRITICAL)** — The listType == public guard must live at the use-case boundary (Create/Update/Toggle/Reorder/Delete), not in the tracker or orchestrator. A private item that reaches ShoppingItemChangeTracker is encrypted and relayed to every family member. Test: tracker.pendingCount == 0 after private insert; == 1 after public insert.

2. **Cross-feature widget import breaks the build immediately** — LedgerTypeSelector must be moved to lib/shared/widgets/ BEFORE any shopping list UI is written. CategorySelectionScreen must be explicitly allow-listed in shopping_list/presentation/import_guard.yaml. Run dart run custom_lint --no-fatal-infos after every new file.

3. **Drift migration number collision: v19 slot already taken** — The from < 19 block was added by a post-PROJECT.md quick task (category sort-order reorder). PROJECT.md says schema v18->v19 but the actual schemaVersion is 19. Shopping list migration MUST be if (from < 20) with schemaVersion => 20. Read app_database.dart directly — do not trust any cached schema-version claim.

4. **FutureProvider + ref.invalidate instead of StreamProvider** — The v1.4 GAP-2 dead-code debt (watchByBookIds never consumed) must not be repeated. Pull-sync writes from family members have no ref.invalidate call site. The shopping list MUST use watchByListType().watch() in a StreamProvider.

5. **ApplySyncOperationsUseCase constructor not updated atomically** — Adding ShoppingItemRepository as a new constructor parameter breaks every existing construction site. Run grep -rn ApplySyncOperationsUseCase lib/ before adding the parameter; update all sites in the same commit.

6. **Data layer files placed inside lib/features/** — Tables, DAOs, and repository impls inside lib/features/shopping_list/ trigger import_guard violations and prevent AppDatabase from importing them. Data layer lives at lib/data/tables/, lib/data/daos/, lib/data/repositories/.

7. **FAB context-awareness regression** — The accounting FAB invalidates listTransactionsProvider, calendarDailyTotalsProvider, and three other providers. These must not be dropped when adding the shopping branch. Extract _onAccountingFabTap and _onShoppingFabTap as named private methods.

8. **listTypeProvider auto-disposed on tab switch** — Without keepAlive: true, the segment selection (public/private) resets to default when the user switches tabs and returns. Apply keepAlive: true to listTypeProvider and shoppingFilterProvider.

---

## Implications for Roadmap

Based on research, the architecture dependency ordering maps to a 7-phase build sequence continuing from Phase 35 (v1.5 close). Phases 39 and 40 are independent and can be developed concurrently.

### Phase 36: Data Layer Foundation
**Rationale:** All other layers depend on table column names and DAO API. Must be complete first. The Wave-0 contract test is the migration correctness gate.
**Delivers:** shopping_items_table.dart (v20 schema), shopping_item_dao.dart, shopping_item_repository_impl.dart, app_database.dart v19->v20 migration, ARB rename homeTabTodo->homeTabShoppingList (ja/zh/en), DAO tests for watchByListType reactivity/softDelete/upsert/reorder
**Features addressed:** Schema foundation for all table-stakes features
**Pitfalls to avoid:** v19 migration collision (read actual schemaVersion first), data-layer files inside features/ directory, REAL column type for estimatedPrice (use IntColumn nullable)

### Phase 37: Domain Layer + Import Guard Setup
**Rationale:** Domain interfaces and import_guard files must exist before use cases or presentation can be written. The LedgerTypeSelector move to lib/shared/widgets/ is a prerequisite for any shopping list form widget.
**Delivers:** ShoppingItem Freezed, ShoppingListFilter Freezed, ShoppingItemParams Freezed, ShoppingItemRepository interface, all import_guard.yaml files, LedgerTypeSelector moved to lib/shared/widgets/ + accounting import updated, build_runner run
**Pitfalls to avoid:** Cross-feature widget import (resolve before any UI code), missing import_guard YAML files for new subdirectories

### Phase 38: Application Layer (Use Cases)
**Rationale:** Use cases are the privacy enforcement layer — the listType == public guard lives here. Must be complete and tested before sync wiring to verify the guard is correct.
**Delivers:** 6 use cases (Create, Update, Delete, ToggleCompleted, Reorder, ClearCompleted), repository_providers.dart, Mocktail tests for each use case, test verifying tracker.pendingCount == 0 for private items
**Pitfalls to avoid:** Private item leak (guard at every mutation use case), scope creep into D3 territory (no TransactionRepository calls)

### Phase 39: Sync Integration (can run parallel to Phase 40)
**Rationale:** Sync integration is independent of all presentation files. Must be complete before any public-list end-to-end test.
**Delivers:** ShoppingItemChangeTracker, SyncOrchestrator 4-line extension, ApplySyncOperationsUseCase case branch + handler, SyncEngine.onShoppingItemChanged(), integration tests (public->tracker, private->no tracker, soft-delete-wins-over-update)
**Pitfalls to avoid:** ApplySyncOperationsUseCase constructor not updated atomically, shopping delete using hard-delete instead of soft-delete, error in shopping handler aborting bill handler loop

### Phase 40: Presentation Shell + Providers (can run parallel to Phase 39)
**Rationale:** Shell wiring (FAB context-awareness, nav tab rename, placeholder replacement) and provider graph are independent of sync.
**Delivers:** repository_providers.dart, state_list_type (keepAlive), state_shopping_filter (keepAlive), state_shopping_items (StreamProvider), MainShellScreen FAB context-aware wiring (_onShoppingFabTap / _onAccountingFabTap named methods), tab icon + label update, ShoppingListScreen shell, golden baselines for empty states
**Pitfalls to avoid:** FAB invalidation regression, listTypeProvider without keepAlive, tab index hardcoded as literal 3 (use named constant), cross-segment filter contamination

### Phase 41: UI Widgets
**Rationale:** All dependent layers must exist before widget development. Gesture interaction design must be settled before goldens.
**Delivers:** ShoppingItemTile (checkbox, ValueKey(item.id), swipe-to-delete disabled in batch mode), ShoppingItemForm (all D4 fields, CategorySelectionScreen push, LedgerTypeSelector), ShoppingListSegmentControl (D1), ShoppingFilterBar, ShoppingEmptyState (3 variants per list type), RunningTotalRow (estimated total display), batch-select mode with floating bottom bar, human-approved render
**Pitfalls to avoid:** Completed items inside ReorderableListView (use separate SliverList section), Dismissible not disabled during batch-select mode, estimatedPrice displayed as float, wrong currency from hardcoded symbol (derive from bookProvider.value?.currency ?? JPY)

### Phase 42: i18n + Golden Re-baseline + Smoke Test
**Rationale:** Final polish phase after all UI is stable. Defer all goldens to this phase — baselines set during development require constant re-baselining.
**Delivers:** All shopping list ARB keys x ja/zh/en parity (verify with jq keys length), golden tests for all screen states x locale x light/dark, sync integration smoke test (public item from family member appears automatically via stream), vocabulary grep gate
**Pitfalls to avoid:** ARB key parity breakage (all three locales in same commit), stale homeTabTodo/todoTab call sites (grep before renaming), golden churn from premature baselines

---

### Phase Ordering Rationale

- Phase 36 must be first because column names from ShoppingItems table are referenced by mapper code in Phases 37-38.
- Phase 37 (domain + import_guard + LedgerTypeSelector move) must precede Phase 38 (use cases need the repository interface) and any UI work (import_guard files must exist to enforce layer rules from the first file).
- Phase 38 (use cases) must precede Phase 39 (sync wiring) because use cases are the call site for ShoppingItemChangeTracker.track*().
- Phases 39 and 40 are independent: sync integration has no dependency on any presentation file, and the presentation shell has no dependency on sync being wired.
- Phase 41 (widgets) depends on Phase 40 (providers and shell exist) and Phase 38 (use cases available for provider wiring).
- Phase 42 (golden re-baseline) must be last — goldens set before layout is stable are wasted work.

---

### Research Flags

**None of the 7 phases require a --research-phase flag.** All patterns are directly verified from source files with HIGH confidence:
- Phase 36: Drift table/DAO/migration pattern thoroughly documented from codebase; migrator.createTable is simplest form
- Phase 37: Domain model + import_guard pattern is a direct mirror of lib/features/list/domain/
- Phase 38: Use case pattern mirrors v1.4 Phase 25; Mocktail test patterns are established
- Phase 39: Sync integration pattern thoroughly documented in STACK.md and ARCHITECTURE.md from direct source reads
- Phase 40: Provider/shell patterns directly established by lib/features/list/presentation/
- Phase 41: Widget patterns (tile, filter bar, empty state, bottom sheet form) all have established analogs in the transaction list feature
- Phase 42: ARB + golden pattern established from v1.4 Phase 30 and v1.5 Phase 34

---

### Open Questions — Must Be Decided Before or During Planning

These three questions were raised by the Pitfalls researcher and left unresolved. They affect the data model and CRDT behavior. The discuss-phase or planner must close them before the relevant phase begins:

**OPEN-1: completedAt DateTime? column — merge-wins vs last-write-wins on completion state (decide by Phase 36)**

CRDT race: Member A marks item completed at T1. Member B edits the item name at T2 > T1 with isCompleted: false. Last-write-wins on updatedAt would un-check the item.
- Option A: Add completedAt DateTime? column to the v20 table. isCompleted: true is sticky if completedAt > incoming.updatedAt. Requires a new column in the v20 migration.
- Option B: Accept last-write-wins on isCompleted (simpler). Document the race as a known eventual-consistency limitation. This is how Bring! and AnyList handle it.
- Recommended: Option B (simpler; consistent with transaction CRDT; same behavior as all competitors).

**OPEN-2: Per-segment filter policy (decide by Phase 40)**

When the user switches from the public segment to the private segment, should the filter state persist or reset?
- Option A: Independent filter per segment — two shoppingFilterProvider instances parameterized by listType.
- Option B: Shared filter with explicit reset on ref.listen(listTypeProvider, (_, __) => clearFilters()).
- Recommended: Option A (per-segment) — prevents cross-segment contamination; cleaner provider design.

**OPEN-3: listType mutation from public -> private after creation (decide by Phase 38)**

If a user changes an existing public item to private, should UpdateShoppingItemUseCase emit a sync delete tombstone to remove it from family members devices?
- Option A: listType is immutable after creation — edit form prevents changing listType on an existing item. Simplest.
- Option B: listType is mutable — detect public->private transitions in UpdateShoppingItemUseCase and emit a tombstone.
- Recommended: Option A (immutable) — eliminates the edge case entirely; users who want a private item should delete the public one and re-add it privately.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All conclusions from direct pubspec.yaml, source file, and app_database.dart reads. Zero new packages confirmed. Schema version confirmed at v19 (not v18 as PROJECT.md states). |
| Features | HIGH | Dominant patterns verified across AnyList, OurGroceries, Bring!, Listonic. All locked decisions (D1-D4) are well-grounded. Differentiators (estimated total, dual-ledger accent) are achievable without scope expansion. |
| Architecture | HIGH | All file-placement decisions derive from direct reads of lib/features/list/, lib/application/family_sync/, main_shell_screen.dart, and all import_guard YAML files. Migration pattern confirmed from 6 prior from < N blocks. |
| Pitfalls | HIGH | All pitfalls derive from direct source inspection. Privacy pitfall (private item leak) verified against TransactionChangeTracker source — the risk is real and reproducible. GAP-2 lesson documented in PROJECT.md with exact symptom. |

**Overall confidence: HIGH**

### Gaps to Address

- **Schema version mismatch in PROJECT.md and CLAUDE.md:** Both say schema v18->v19 but actual schemaVersion is 19. The first action in Phase 36 must be a direct grep schemaVersion lib/data/app_database.dart read. CLAUDE.md stale reference should be updated in the same Phase 36 commit that bumps to v20.
- **OPEN-1 / OPEN-2 / OPEN-3:** Three open questions above must be resolved before their respective phase begins. All have a recommended resolution (Option B, Option A, Option A respectively).
- **addedByBookId shadow book availability:** Family attribution uses addedByBookId without a FK constraint. A pulled item may arrive before the shadow book is locally available. The repository impl attribution display must handle null gracefully (omit the member chip if book not found, rather than throwing).

---

## Sources

### Primary (HIGH confidence — direct codebase reads, 2026-06-07)

- lib/data/app_database.dart — schemaVersion => 19; from < 19 block is category sort-order; migrator.createTable pattern
- lib/data/tables/transactions_table.dart — canonical @DataClassName, customConstraints, List<TableIndex> get customIndices with {#symbol} syntax
- lib/data/daos/transaction_dao.dart — DAO method shapes, soft-delete pattern, readsFrom: reactivity requirement (GAP-2 source)
- lib/application/family_sync/apply_sync_operations_use_case.dart — switch structure confirmed; default: continue safe for unknown entity types
- lib/application/family_sync/transaction_change_tracker.dart — no listType guard; template for ShoppingItemChangeTracker
- lib/application/family_sync/sync_orchestrator.dart — _executeIncrementalPush shape; pushedCount = txnOps.length only
- lib/application/family_sync/sync_engine.dart — onTransactionChanged() scheduler reuse pattern
- lib/features/home/presentation/screens/main_shell_screen.dart — FAB hardcoded; sync listener invalidates accounting providers only; shopping tab at index 3
- lib/features/list/ — canonical thin-feature analog; all layer files mirrored directly
- lib/features/accounting/presentation/widgets/ledger_type_selector.dart — zero accounting-specific dependencies; safe to move to lib/shared/widgets/
- lib/features/accounting/presentation/screens/category_selection_screen.dart — full ConsumerStatefulWidget with categoryRepositoryProvider; cannot move to shared
- lib/features/*/import_guard.yaml files — global deny rules do NOT block cross-feature presentation imports
- lib/data/repositories/transaction_repository_impl.dart — note encryption via FieldEncryptionService at repository boundary
- lib/features/list/presentation/providers/state_list_filter.dart — keepAlive: true precedent confirmed
- lib/l10n/app_ja.arb, app_zh.arb, app_en.arb — homeTabTodo and todoTab keys confirmed in all three locales
- pubspec.yaml — full dependency list; no reorder/drag/list-management package; schemaVersion: 19 confirmed

### Secondary (MEDIUM confidence — competitor analysis)

- AnyList help docs — check-off UX, autocomplete (flagship feature), duplicate detection
- OurGroceries user guide — sorting, crossed-off behavior, batch delete
- Bring! feature docs — collaborative features, real-time sync patterns
- SmartCart comparison — Listonic/Bring!/AnyList/OurGroceries feature matrix
- Baymard Institute, Nielsen Norman Group, Eleken — autocomplete, checkboxes, bulk action UX guidelines

---

*Research completed: 2026-06-07*
*Ready for roadmap: yes*
