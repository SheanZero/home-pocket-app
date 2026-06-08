---
phase: 38-presentation-shell-ui-widgets
verified: 2026-06-08T00:00:00Z
status: passed
score: 5/5 must-haves verified
overrides_applied: 0
---

# Phase 38: Presentation Shell + UI Widgets Verification Report

**Phase Goal:** Users can fully manage their shopping lists — adding, completing, filtering, and batch-deleting items — through a complete, gesture-safe, accessibility-respecting UI on a correctly renamed and icon-updated nav tab with a context-aware FAB.
**Verified:** 2026-06-08
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths (Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | 4th nav tab reads Shopping List in all 3 locales, shopping-bag icon, context-aware FAB, no stale Todo/待办 strings, widget test confirms FAB routing index 3 vs other, SC1 accounting invalidations intact | VERIFIED | See SC1 detail below |
| 2 | listTypeProvider + shoppingFilterProvider both keepAlive:true; filter resets on segment switch; ShoppingListScreen replaces placeholder with loading state during stream init | VERIFIED | See SC2 detail below |
| 3 | ShoppingItemTile renders name/secondary text/dual-ledger border/attribution chip on public tiles only/animated strikethrough+fade | VERIFIED | See SC3 detail below |
| 4 | Add/edit form has all D4 fields, name validated, completed items below divider, active items in SliverReorderableList, swipe-delete disabled in batch mode | VERIFIED | See SC4 detail below |
| 5 | Long-press → batch mode + floating action bar; Select-all; batch-delete fires DeleteShoppingItemUseCase per item; Clear-all-completed only when completed section non-empty, fires ClearCompletedItemsUseCase; all 3 empty-state variants render | VERIFIED | See SC5 detail below |

**Score:** 5/5 truths verified

---

### SC1: Nav Tab + FAB Routing + SC1 Accounting Regression

**4th tab label:** `lib/features/home/presentation/widgets/home_bottom_nav_bar.dart` line 45 reads `l10n.homeTabTodo`. The ARB values are:
- `app_ja.arb:709`: `"homeTabTodo": "買い物リスト"`
- `app_zh.arb:709`: `"homeTabTodo": "购物清单"`
- `app_en.arb:709`: `"homeTabTodo": "Shopping List"`

Generated files `app_localizations_ja.dart:572`, `_zh.dart:572`, `_en.dart:578` confirm correct resolved strings. No `待办` / `Todo` / `やること` appears in production widget code.

**Shopping bag icon:** `home_bottom_nav_bar.dart` lines 28 and 35 — `_icons[3] = Icons.shopping_bag_outlined`, `_activeIcons[3] = Icons.shopping_bag`. Test `home_bottom_nav_bar_shopping_test.dart` (5 tests) asserts all 3 locales and active/inactive icon states.

**Context-aware FAB:** `main_shell_screen.dart` lines 141–203: `if (currentIndex == 3)` pushes `ShoppingItemFormScreen`, `else` pushes `ManualOneStepScreen` with all 6 post-entry invalidations:
- `monthlyReportProvider` (line 169)
- `todayTransactionsProvider` (line 175)
- `bestJoyMomentProvider` (line 177)
- `happinessReportProvider` (line 186, conditional on bookAsync.hasValue)
- `listTransactionsProvider` (line 195)
- `calendarDailyTotalsProvider` (line 197)

**FAB routing widget test:** `main_shell_screen_fab_test.dart` (3 tests) verifies index 3 → `_ShoppingItemFormRoute`; index 0 → `_ManualEntryRoute`; index 1 → `_ManualEntryRoute`.

**Batch guard:** `main_shell_screen.dart` line 131: `if (!batchActive)` wraps the `Positioned` nav-bar+FAB so both are hidden during batch mode.

---

### SC2: keepAlive Providers + Loading State

**keepAlive:** `state_shopping_filter.dart` lines 15 and 35: `@Riverpod(keepAlive: true)` on both `ListType` and `ShoppingFilter` classes.

**Filter reset on segment switch:** `setListType()` at line 25 calls `ref.read(shoppingFilterProvider.notifier).resetForNewSegment()`. Unit test `state_shopping_filter_test.dart` test "setListType resets shoppingFilterProvider" verifies this with `ProviderContainer.test()`.

**keepAlive retention tests:** Two tests in `state_shopping_filter_test.dart` verify that after the last subscriber is closed, both providers retain state (keepAlive behavior confirmed).

**Loading state:** `shopping_list_screen.dart` line 110–115: `itemsAsync.when(loading: () => Center(child: CircularProgressIndicator(...)), ...)`. Test `shopping_list_screen_test.dart` "shows CircularProgressIndicator while stream is loading" verifies this using `Stream.empty()`.

**Placeholder replaced:** `main_shell_screen.dart` line 128: `const ShoppingListScreen()` replaces the old `Center(Text(todoTab))` placeholder — confirmed by code reading (no `todoTab` string remains in lib/ production code outside ARB keys and generated files).

---

### SC3: ShoppingItemTile

**Name (SHOP-02):** `shopping_item_tile.dart` line 136–137: `AnimatedDefaultTextStyle` wraps `Text(item.name)`. Test `shopping_item_tile_test.dart` has "SHOP-02: item.name as Text widget" assertion.

**Secondary text (SHOP-02):** Lines 140–171: quantity (`'${item.quantity}×'`) and estimated price (`NumberFormatter.formatCurrency`) rendered in a secondary Row when set.

**Dual-ledger left border (SHOP-03):** Lines 101–105: `borderColor = switch (item.ledgerType) { daily → palette.daily, joy → palette.joy, null → palette.borderList }`. 4px BorderSide at line 110. Three tests in `shopping_item_tile_test.dart` assert each color.

**Attribution chip — public tiles only (SYNC-04):** Line 177: `if (item.listType == 'public' && item.addedByBookId != null)`. Resolved via `shadowBooksProvider.value ?? const []`. Three tests assert: public+resolvable → chip visible; public+null → no chip; private → no chip (T-38-04-01 defense-in-depth).

**Animated strikethrough + fade (DONE-01):** Lines 124–137: `AnimatedDefaultTextStyle(duration: 200ms, Curves.easeInOut)` applies `TextDecoration.lineThrough` + `palette.textTertiary` when `item.isCompleted`. `AnimatedOpacity(opacity: 0.5)` wraps the text. Test asserts `mockToggle.execute(item.id)` called on tap.

**WCAG compliance:** Estimated price uses `palette.dailyText` / `palette.joyText` / `palette.textSecondary` (never raw `palette.joy` — line 163 comment confirms).

**Accessibility:** Edit chevron wrapped in `Semantics(label: shoppingEditItem, button: true)` with 44×44 hit target (lines 222–249). Drag handle has `Semantics(label: shoppingReorderItem, button: true)` (lines 264–285).

---

### SC4: Add/Edit Form + List Layout

**All D4 fields present (ITEM-01/02/04):**
- Name: `TextFormField` with validator at line 226 (`shoppingFormNameRequired` error on empty)
- Ledger: `LedgerTypeSelector` at line 237 (key `shopping_form_ledger_selector`)
- Category: `OutlinedButton` with `_pickCategory()` at line 173 (key `shopping_form_category_button`); `_categoryName` state stores human-readable name (CR-01 fix)
- Tags: `TextField` at line 273 (key `shopping_form_tags_field`)
- Note: `TextField` at line 284 (key `shopping_form_note_field`)
- Quantity: `TextField` at line 296 (key `shopping_form_quantity_field`)
- Estimated price: `TextField` at line 308 (key `shopping_form_price_field`)

**Name required validation:** Test `shopping_item_form_screen_test.dart` "tapping Save with empty name shows validation error" asserts `find.text('Name is required')` and `verifyNever(() => mockCreate.execute(any()))`.

**Edit mode pre-population (ITEM-04):** `initState()` at lines 66–89 pre-populates all controllers from `widget.item`. `_resolveCategoryName(item.categoryId)` called asynchronously (CR-01 fix). Test "name field pre-populated from item.name" asserts `find.text('Bread')`.

**WR-03 numeric sanitization:** Lines 117–123 sanitize quantity (min 1) and price (null if negative).

**Completed items below divider:** `shopping_list_screen.dart` lines 173–193: `completedItems.isNotEmpty` guard wraps `_CompletedSectionHeader` + `SliverList(completedItems)`. Active items in `SliverReorderableList` (lines 158–171).

**Swipe disabled in batch mode (MGMT-03):** `shopping_item_tile.dart` lines 56–58: `direction: batchActive ? DismissDirection.none : DismissDirection.endToStart`. Tests in `shopping_item_tile_test.dart` assert both states.

---

### SC5: Batch Mode + Empty States + Clear-all-completed

**Long-press → batch mode (MGMT-02):** `shopping_item_tile.dart` lines 80–85: `onLongPress` calls `batchSelectModeProvider.notifier.enter()` then `.toggle(item.id)` when not already in batch mode.

**Floating action bar (ShoppingBatchActionBar):** `shopping_batch_action_bar.dart` — FilledButton.tonal delete fires a confirm dialog then iterates `idsToDelete` calling `deleteShoppingItemUseCaseProvider.execute(id)` per item (line 81). `batchSelectModeProvider.notifier.exit()` fires after loop completes (line 84). Context validity maintained: `showSuccessFeedback` called before delete loop (lines 72–76).

**Select-all:** `shopping_selection_header.dart` line 65: `selectAll(allItemIds)`. `allItemIds` received from `_BatchHeaderWrapper` which reads `filteredShoppingItemsProvider.value?.where(!isCompleted)`.

**Batch chrome visibility tests:** `shopping_list_screen_test.dart` tests "batch selection header visible", "batch action bar visible", and "batch chrome hidden" cover all three cases.

**Clear-all-completed (DONE-03):** `shopping_list_screen.dart` line 173: `if (completedItems.isNotEmpty)` gate ensures `_CompletedSectionHeader` only renders when the section is non-empty. `ClearCompletedItemsUseCase.execute(listType)` called at line 296.

**Empty-state variants (SHOP-04):** `shopping_empty_state.dart` — `ShoppingEmptyVariant` enum with 3 cases. Branch logic: `listType == 'private'` → `privateEmpty`; public + `isGroupModeProvider` → `publicFamily`; public + !group → `publicSolo`. Five tests in `shopping_empty_state_test.dart` cover all variants, CTA navigation, and private-always-privateEmpty invariant.

---

### Required Artifacts

| Artifact | Status | Evidence |
|----------|--------|----------|
| `lib/features/shopping_list/domain/models/shopping_list_filter.dart` | VERIFIED | categoryIds Set<String> field present |
| `lib/features/shopping_list/domain/models/shopping_list_filter.freezed.dart` | VERIFIED | regenerated with categoryIds (31 occurrences) |
| `lib/features/shopping_list/presentation/providers/state_shopping_filter.dart` | VERIFIED | ListType (keepAlive:true) + ShoppingFilter (keepAlive:true) |
| `lib/features/shopping_list/presentation/providers/state_shopping_batch.dart` | VERIFIED | BatchSelectModeState Freezed + batchSelectModeProvider (transient) |
| `lib/features/shopping_list/presentation/providers/repository_providers.dart` | VERIFIED | 6 use-case providers + filteredShoppingItemsProvider StreamProvider |
| `lib/features/shopping_list/presentation/widgets/shopping_item_tile.dart` | VERIFIED | All D38 affordances implemented (SHOP-02/03, DONE-01, MGMT-01/02/03, SYNC-04) |
| `lib/features/shopping_list/presentation/widgets/shopping_empty_state.dart` | VERIFIED | 3-variant enum + CTA |
| `lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart` | VERIFIED | shoppingFilterProvider wired, L3 fix applied, l10n semantic label (WR-04 fixed) |
| `lib/features/shopping_list/presentation/widgets/shopping_batch_action_bar.dart` | VERIFIED | Delete loop per item + context validity ordering |
| `lib/features/shopping_list/presentation/widgets/shopping_selection_header.dart` | VERIFIED | Cancel + count + selectAll |
| `lib/features/shopping_list/presentation/screens/shopping_list_screen.dart` | VERIFIED | Full shell with streaming, divider, batch chrome, empty state |
| `lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart` | VERIFIED | All D4 fields, CR-01 fix (_categoryName), WR-03 sanitization |
| `lib/features/home/presentation/screens/main_shell_screen.dart` | VERIFIED | ShoppingListScreen wired; context-aware FAB; all 6 SC1 invalidations in else branch |
| `lib/features/home/presentation/widgets/home_bottom_nav_bar.dart` | VERIFIED | shopping_bag_outlined / shopping_bag icons; homeTabTodo ARB key |
| `lib/l10n/app_ja.arb` | VERIFIED | homeTabTodo = 買い物リスト |
| `lib/l10n/app_zh.arb` | VERIFIED | homeTabTodo = 购物清单 |
| `lib/l10n/app_en.arb` | VERIFIED | homeTabTodo = Shopping List |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `ShoppingFilterBar` | `shoppingFilterProvider` | `ref.watch(shoppingFilterProvider)` + `ref.read(…notifier)` | WIRED | shopping_filter_bar.dart lines 24, 67, 94, 129, 163, 195 |
| `ShoppingFilterBar` → `CategoryFilterSheet` | `shoppingFilterProvider` | `onApply: (ids) => ref.read(shoppingFilterProvider.notifier).setCategoryIds(ids)` | WIRED | L3 fix; shopping_filter_bar.dart line 162 |
| `ListType.setListType` | `ShoppingFilter.resetForNewSegment` | `ref.read(shoppingFilterProvider.notifier).resetForNewSegment()` | WIRED | state_shopping_filter.dart line 26 |
| `ShoppingListScreen` | `filteredShoppingItemsProvider` | `ref.watch(filteredShoppingItemsProvider)` | WIRED | shopping_list_screen.dart line 108 |
| `filteredShoppingItemsProvider` | `shoppingItemRepositoryProvider.watchByListType` | `ref.watch(shoppingItemRepositoryProvider).watchByListType(listType).map(filter)` | WIRED | repository_providers.dart lines 113–135 |
| `MainShellScreen` FAB (index 3) | `ShoppingItemFormScreen` | `Navigator.push(ShoppingItemFormScreen(listType: ref.read(listTypeProvider)))` | WIRED | main_shell_screen.dart lines 143–149 |
| `MainShellScreen` FAB (else) | `ManualOneStepScreen` + 6 invalidations | `Navigator.push(ManualOneStepScreen)` + `ref.invalidate(...)` × 6 | WIRED | main_shell_screen.dart lines 153–202 |
| `ShoppingItemTile` swipe | `deleteShoppingItemUseCaseProvider` | `onDismissed: ref.read(deleteShoppingItemUseCaseProvider).execute(item.id)` | WIRED | shopping_item_tile.dart line 75 |
| `ShoppingItemTile` tap | `toggleItemCompletedUseCaseProvider` | `onTap: ref.read(toggleItemCompletedUseCaseProvider).execute(item.id)` | WIRED | shopping_item_tile.dart line 79 |
| `ShoppingBatchActionBar` | `deleteShoppingItemUseCaseProvider` | loop: `ref.read(deleteShoppingItemUseCaseProvider).execute(id)` | WIRED | shopping_batch_action_bar.dart line 81 |
| `_CompletedSectionHeader` | `clearCompletedItemsUseCaseProvider` | `ref.read(clearCompletedItemsUseCaseProvider).execute(listType)` | WIRED | shopping_list_screen.dart line 296 |
| `batchSelectModeProvider` | `MainShellScreen` nav-bar hide | `final batchActive = ref.watch(batchSelectModeProvider).isActive; if (!batchActive) Positioned(...)` | WIRED | main_shell_screen.dart lines 107, 131 |

---

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|-------------------|--------|
| `ShoppingListScreen` | `itemsAsync` | `filteredShoppingItemsProvider` → `shoppingItemRepositoryProvider.watchByListType(listType)` Drift stream | Drift `.watch()` stream from SQLCipher DB (Phase 36 table) | FLOWING |
| `ShoppingItemTile` | `item.name`, `item.ledgerType`, etc. | `filteredShoppingItemsProvider.data` items | Same Drift stream | FLOWING |
| `ShoppingItemTile` attribution chip | `shadows` | `shadowBooksProvider.value ?? const []` | FutureProvider backed by DB (Phase 37) | FLOWING |
| `ShoppingEmptyState` | `isGroupMode` | `isGroupModeProvider` (sync bool) | Riverpod provider backed by family sync state | FLOWING |

---

### Behavioral Spot-Checks

Step 7b: Runtime checks were not run (no standalone server). All wiring verified via static analysis + test suite evidence.

The full test suite (2445/2445 per 38-08-SUMMARY.md) and `flutter analyze` contributing zero phase-38 issues (verified via `flutter analyze lib/features/shopping_list/ ...main_shell_screen.dart ...home_bottom_nav_bar.dart` returning "No issues found") confirm behavioral correctness.

---

### Probe Execution

Step 7c: No `scripts/*/tests/probe-*.sh` files declared in any phase-38 plan. Skipped.

---

### Requirements Coverage

| Requirement | Phase 38 Plan | Description | Status | Evidence |
|-------------|--------------|-------------|--------|----------|
| SHOP-02 | 38-04 | Item tile shows name/secondary text | SATISFIED | shopping_item_tile.dart lines 124–171; tile tests |
| SHOP-03 | 38-04 | Dual-ledger left border | SATISFIED | shopping_item_tile.dart lines 101–112; 3 tile tests |
| SHOP-04 | 38-05 | 3-variant empty state with CTA | SATISFIED | shopping_empty_state.dart; 5 empty-state tests |
| DONE-01 | 38-04 | Animated strikethrough+fade toggle | SATISFIED | shopping_item_tile.dart lines 124–137; tile tests |
| DONE-03 | 38-06 | Clear-all-completed with confirmation, non-empty guard | SATISFIED | shopping_list_screen.dart lines 173, 296 |
| ITEM-01 | 38-07 | Name required, all else optional | SATISFIED | shopping_item_form_screen.dart lines 219–228; form tests |
| ITEM-02 | 38-07 | All D4 optional fields present | SATISFIED | form screen lines 237–318; form tests |
| ITEM-04 | 38-07 | Edit mode pre-population | SATISFIED | initState() lines 66–89; CR-01 fix; form tests |
| FILT-01 | 38-05 | Chip filter bar (All/Daily/Joy/Category/Status) | SATISFIED | shopping_filter_bar.dart; 5 filter bar tests |
| FILT-02 | 38-02/05 | Filter resets on segment switch (D5) | SATISFIED | state_shopping_filter.dart line 26; unit test |
| FILT-03 | 38-05 | Clear-all filters chip | SATISFIED | shopping_filter_bar.dart lines 200–222 |
| MGMT-01 | 38-04 | Swipe-to-delete with confirmation | SATISFIED | shopping_item_tile.dart lines 65–76; 4 swipe tests |
| MGMT-02 | 38-06 | Long-press → batch select + select-all + batch-delete | SATISFIED | tile lines 80–85; batch_action_bar.dart; selection_header.dart |
| MGMT-03 | 38-04 | Swipe disabled in batch mode | SATISFIED | shopping_item_tile.dart lines 56–58; 2 tile tests |
| NAV-01 | 38-08 | FAB on index 3 → add-item; else → transaction+invalidations | SATISFIED | main_shell_screen.dart lines 141–202; 3 FAB tests |
| NAV-02 | 38-03 | Tab renamed Shopping List + shopping bag icon | SATISFIED | home_bottom_nav_bar.dart; ARB files; 5 nav tests |
| SYNC-04 | 38-04 | Attribution chip on public tiles, private shows none | SATISFIED | shopping_item_tile.dart line 177; 3 SYNC-04 tests |
| NAV-03 | Phase 39 | ARB parity + flutter gen-l10n | DEFERRED | Explicitly assigned to Phase 39 in REQUIREMENTS.md line 151 |

**Orphaned requirements check:** No requirements assigned to Phase 38 in REQUIREMENTS.md are unclaimed by any plan. NAV-03 is correctly assigned to Phase 39 — not a gap.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `home_bottom_nav_bar.dart` | 10–11 | Stale "coral" doc comment (ADR-018 palette, superseded by ADR-019) | Info (IN-01) | Cosmetic — code behavior uses `palette.accentPrimary` correctly |
| `shopping_list_filter.dart` | 17 | `listType` field declared but never read in production (WR-02) | Warning | No functional impact; dead field may confuse future developers; not a blocker |
| `shopping_list_filter.dart` | 20 | `searchQuery` field declared but never populated (IN-02) | Info | Placeholder for future search; no functional impact |
| `repository_providers.dart` (shopping) | 11–12 | data/daos + data/repositories imports in presentation layer (CR-02 rejected as established convention) | Info (IN-03) | Pre-existing pattern across 6 other features; import_guard.yaml allows it; not a phase-38 regression |
| `shopping_list_screen.dart` | 160–163 | `onReorderItem` result unawaited (WR-01) | Warning | Optimistic-reorder accepted; silent failure on DB error; non-blocking |

No `TBD`, `FIXME`, or `XXX` markers exist in any phase-38 modified files. The single `TBD` found (`home_screen.dart:374`) is a pre-existing marker in a file not modified by Phase 38.

**Debt marker gate:** PASSED — zero unresolved debt markers in phase-38 files.

---

### Human Verification Required

The on-device human verification checkpoint (38-08 Task 3, 10 manual steps) was approved by the user. This is documented in `38-08-SUMMARY.md` (`human_verification: "approved (10/10 manual steps)"`). No remaining human verification items are outstanding.

---

### Gaps Summary

No gaps found. All 5 success criteria are verified against the actual codebase:

- SC1: Nav tab, icons, ARB values, context-aware FAB, SC1 invalidations, batch guard — all wired and tested.
- SC2: Both providers keepAlive:true, filter reset on segment switch, loading state during stream init — all wired and tested.
- SC3: ShoppingItemTile with all required affordances (name, border, chip, strikethrough+fade) — fully implemented.
- SC4: Add/edit form with all D4 fields, validation, edit-mode pre-population, CR-01/WR-03 fixes applied — fully implemented.
- SC5: Batch mode chrome, select-all, per-item delete, clear-all-completed guard, all 3 empty-state variants — fully implemented.

Code review findings CR-01 (UUID display), WR-03 (numeric validation), WR-04 (hardcoded semantic label) were all fixed in commit `c4f8a226`. CR-02 was correctly rejected as a false positive. WR-01 and WR-02 are accepted advisory items that do not affect the phase goal.

NAV-03 (ARB parity + golden re-baseline) is explicitly deferred to Phase 39 per the roadmap contract.

---

_Verified: 2026-06-08_
_Verifier: Claude (gsd-verifier)_
