# Phase 38: Presentation Shell + UI Widgets - Context

**Gathered:** 2026-06-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Build the **presentation layer** for the shopping list — the UI that wires Phase 37's six use cases + sync into a usable screen on the renamed 4th nav tab. This is the user-facing feature surface: nav rename + shopping-bag icon, context-aware FAB, `keepAlive` providers, the `ShoppingListScreen` shell, `ShoppingItemTile`, the add/edit form, the filter bar, swipe-delete, batch-select, and empty states.

Requirements: SHOP-02, SHOP-03, SHOP-04, DONE-01 (UI animation), DONE-03 (UI button), ITEM-01/02/04 (form UI), FILT-01/02/03, MGMT-01/02/03 (gesture UI), NAV-01, NAV-02, SYNC-04 (attribution chip).

The ROADMAP §"Phase 38" 5 success criteria are the acceptance bar — they prescribe most of the implementation. This discussion only resolved the **interaction decisions where the SC conflict with each other or with established conventions**.

**Out of scope:** ARB key parity / `flutter gen-l10n` / golden re-baseline / reactive-sync smoke test (all Phase 39, NAV-03). No new use cases or sync logic (Phase 37, done). No data/schema changes (Phase 36, done).

</domain>

<decisions>
## Implementation Decisions

### Edit entry point (resolves tap conflict: DONE-01 vs established tile convention)
- **D38-01:** **tap on the row body = toggle completed** (DONE-01 kept literal). Editing is reached via an **explicit trailing affordance** (chevron / info icon at the row end) that pushes the edit form. Rationale: the existing `list_transaction_tile.dart` uses `tap row = edit`, but DONE-01 mandates `tap row = toggle`, so edit needs its own affordance. This matches the dominant Bring!/AnyList shopping-app pattern (tap to check, detail button to edit) and is consistent with the trailing `chevron_right` affordance already present on the transaction tile (`list_transaction_tile.dart:233`).
  - **Implication for planner:** the trailing region of an active `ShoppingItemTile` will hold both the edit affordance AND the reorder drag handle (D38-02) — design the trailing cluster so the two targets are distinguishable and don't fight the `Dismissible` swipe. On completed items there is no drag handle.

### Reorder exposure (resolves SC4 `SliverReorderableList` vs REORDER-01 v2-deferred vs long-press taken by batch-select)
- **D38-02:** Drag-reorder **IS exposed** this phase, via an **explicit drag handle** (`ReorderableDragStartListener` wrapping a handle icon in the tile), NOT long-press (long-press is owned by batch-select, MGMT-02). Active items live in a `SliverReorderableList` (satisfies SC4); **completed items are fixed below the divider and are NOT reorderable**. This wires up Phase 37's already-built `ReorderShoppingItemsUseCase` (local-only per D37-01).
  - **Note on the REORDER-01 tension:** REQUIREMENTS lists "manual drag-to-reorder" as v2-deferred (REORDER-01), but ROADMAP SC4 explicitly mandates `SliverReorderableList` and Phase 37 built the reorder use case. User chose to honor SC4 + the existing use case. The v2 REORDER-01 entry is effectively superseded for the *local, active-items, handle-driven* case; cross-device synced ordering remains deferred (D37-01).
  - **Implication for planner:** reorder writes go through `ReorderShoppingItemsUseCase` → repo → `.watch()` stream (local only, no sync op). Reorder must be disabled / handles hidden while batch-select mode is active (consistent with MGMT-03 disabling swipe in batch mode).

### Batch-select chrome (resolves floating action bar vs parent-owned nav bar + FAB)
- **D38-03:** **Material contextual-action-mode pattern.** Entering batch-select (long-press) flips a **shared `batchSelectMode` provider**; `MainShellScreen` (the parent that owns `HomeBottomNavBar` + center FAB) watches it and **hides both the nav bar and the FAB** while batch mode is active. The shopping screen shows a **top selection header** (N selected + Select-all + Cancel) and a **bottom floating batch action bar** (batch-delete). Exiting batch mode (Cancel / tap-outside / empty selection) restores the nav bar + FAB.
  - **Architecture note (critical for planner):** `HomeBottomNavBar` and the FAB live in `lib/features/home/presentation/screens/main_shell_screen.dart` (parent), while `ShoppingListScreen` is only body content inside the parent's `IndexedStack`. Hiding them from a child screen REQUIRES the shared provider — this is cross-widget coordination, not a self-contained screen change. The provider's `keepAlive` is not required (it's transient UI state), but it must be readable by both `MainShellScreen` and the shopping screen.
  - **Implication:** `MainShellScreen.build` adds a `ref.watch(batchSelectModeProvider)` guard around the `Positioned` nav-bar/FAB block. Batch-delete fires `DeleteShoppingItemUseCase` per selected item (soft-delete), per SC5.

### Filter bar (resolves FILT-01 "consistent with v1.4 ListSortFilterBar" — reuse vs new)
- **D38-04:** **Build a shopping-specific chip bar**, do NOT reuse or generalize the existing `list_sort_filter_bar.dart` (its dimensions are transaction sort-modes; the shopping dimensions are ledger All/日常/悦己 + category + status active/all). The new bar **reuses the visual style / chip components / spacing** of `ListSortFilterBar` for consistency, and includes a one-tap **clear-all-filters** control (FILT-03). It is **sticky** beneath the public/private segmented control. The **category filter reuses the existing `list_category_filter_sheet.dart`** rather than forking a picker.
  - Rationale: avoids refactoring `ListSortFilterBar` (the transaction list already has golden masters — refactor would widen the regression surface for zero functional gain). Filter state is shared across segments and resets on segment switch (D5, already locked) — see SC2.

### Claude's Discretion (research / planner)
- **Empty-state copy + layout** for the 3 SHOP-04 variants (empty private / empty public solo / empty public family) — final strings are Phase 39 (i18n); this phase wires the 3-way branch and CTA.
- **Family attribution chip** (SYNC-04) — mirror the `taggedTx.memberTag` chip already in `list_transaction_tile.dart:198-221` (avatar emoji + display name, `palette.sharedLight` / `palette.sharedText`); resolve member identity from shadow books. Public-list tiles only; private list shows none.
- **Strikethrough + fade animation** (DONE-01) timing/curve.
- **Loading-state** style while the stream initializes (spinner vs skeleton) — SC2 only requires *a* loading state.
- **Add/edit form presentation** — D2/NAV-01 says "screen", so a full-screen `MaterialPageRoute` mirroring `ManualOneStepScreen` is the expected shape; edit reuses the same form pre-populated (ITEM-04). Exact field layout is planner's call within the D4 field set.
- **Estimated-price input** — integer yen via `NumberFormatter` (ITEM-05 locked); input widget shape is discretion.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone scope & locked decisions
- `.planning/REQUIREMENTS.md` — D1–D8 locked decisions + all 27 requirements. Phase 38 requirements: SHOP-02, SHOP-03, SHOP-04, DONE-01, DONE-03, FILT-01/02/03, ITEM-01/02/04, MGMT-01/02/03, NAV-01, NAV-02, SYNC-04. Note D5 (filter shared + resets on segment switch), D6 (visibility immutable), D8 (attribution + dual-ledger accent IN; subtotal/autocomplete/grouping/tag-filter/dup deferred). **REORDER-01 is listed v2-deferred but superseded for the local/handle case — see D38-02.**
- `.planning/ROADMAP.md` §"Phase 38" — 5 success criteria (the acceptance bar). UI hint: yes.
- `.planning/phases/37-application-use-cases-sync-integration/37-CONTEXT.md` — the use-case + sync layer this phase wires to; D37-01 (reorder local-only, no sync), D37-06 (privacy gate). Provider-wiring shape was flagged there as "Phase 38 territory".
- `.planning/phases/36-data-layer-domain-import-guard/36-CONTEXT.md` — v20 schema, `completedAt` nullable, DAO `watchByListType` reactive stream, repo-boundary note encryption + JSON tags.

### v1.6 research (milestone-level, 2026-06-07)
- `.planning/research/SUMMARY.md` — §"PITFALLS" #7 (FAB providers — THIS phase), #8 (keepAlive providers — THIS phase). NAV-01 context-aware FAB and `keepAlive: true` on `listTypeProvider`/`shoppingFilterProvider` (SC1, SC2).
- `.planning/research/PITFALLS.md` — GAP-2 reactivity lesson (use `.watch()`, not manual invalidate) for SYNC-06-driven UI updates.
- `.planning/research/ARCHITECTURE.md` — presentation-layer file placement, provider patterns.

### Codebase patterns to mirror (READ before writing)
- `lib/features/home/presentation/screens/main_shell_screen.dart` — the nav shell: `IndexedStack` with the 4th tab currently `Center(child: Text(S.of(context).todoTab))` (the placeholder to replace, line ~125); `HomeBottomNavBar` + `onFabTap` block (lines ~128-189) — where the **context-aware FAB** branch (index 3 → add-shopping-item; else → `ManualOneStepScreen` with ALL existing post-entry invalidations preserved) and the **batch-mode nav-bar/FAB hide guard** (D38-03) go.
- `lib/features/home/presentation/widgets/home_bottom_nav_bar.dart` — the nav bar widget (tab labels + icons; NAV-02 rename + `check_box_outlined` → shopping icon).
- `lib/features/list/presentation/widgets/list_transaction_tile.dart` — the tile template: `Dismissible` swipe-delete + `showSoftConfirmDialog` + `showSuccessFeedback` order, trailing `chevron_right` affordance (D38-01 edit entry), and the `memberTag` attribution chip (lines 198-221, mirror for SYNC-04).
- `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` — visual style / chip components to reuse for the NEW shopping filter bar (D38-04).
- `lib/features/list/presentation/widgets/list_category_filter_sheet.dart` — reuse for the shopping filter's category dimension (D38-04).
- `lib/features/list/presentation/widgets/list_empty_state.dart` — empty-state pattern for SHOP-04's 3 variants.
- `lib/features/list/presentation/screens/list_screen.dart` + `lib/features/list/presentation/providers/state_list_filter.dart` — screen composition + filter-state provider patterns to mirror for `ShoppingListScreen` + `shoppingFilterProvider`/`listTypeProvider` (both `keepAlive: true`, SC2).
- `lib/shared/widgets/ledger_type_selector.dart` — reuse verbatim for the add/edit form ledger field (ITEM-02/D4).
- `lib/shared/widgets/soft_confirm_dialog.dart` + `feedback_toast.dart` — confirm dialogs (delete, batch-delete, clear-completed) + success toasts.
- `lib/features/shopping_list/domain/repositories/shopping_item_repository.dart` + `domain/models/shopping_item.dart` + `shopping_list_filter.dart` + `shopping_item_params.dart` (Phase 36) — the domain interface + models the UI binds to.
- `lib/features/shopping_list/presentation/providers/repository_providers.dart` (Phase 36/37) — existing provider entry point to extend with screen-state providers + the shopping tracker/use-case wiring.
- `lib/application/shopping_list/*` (Phase 37) — the six use cases the UI calls: Create/Update/Delete/ToggleItemCompleted/Reorder/ClearCompleted.
- The `CategorySelectionScreen` (push target for the form's optional category field, SC4) — locate in the accounting/category feature.

### Project rules
- `CLAUDE.md` — Riverpod 3 conventions (provider-name suffix stripping, `.value` nullable, `ref.listen` for side-effects), `AppPalette` via `context.palette` (`palette.daily`/`palette.joy` dual-ledger accent — SHOP-03), `AppTextStyles.amount*` for monetary values, thin-feature rule (presentation lives in `lib/features/shopping_list/presentation/`), all UI text via `S.of(context)`.
- ADR-019 palette (桜餅×若葉) — `palette.daily` `#5FAE72`, `palette.joy` sakura — for the dual-ledger left-border accent.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `list_transaction_tile.dart` — closest analog for `ShoppingItemTile`: `Dismissible` endToStart swipe-delete, confirm dialog, success toast, trailing chevron, `memberTag` attribution chip. Copy structure; adapt content (name primary; emoji+qty+price secondary; dual-ledger left border; drag handle on active; strikethrough+fade on complete).
- `ledger_type_selector.dart` — reuse verbatim in the form.
- `list_category_filter_sheet.dart` — reuse for filter category dimension.
- `list_empty_state.dart` — pattern for the 3 SHOP-04 empty variants.
- `soft_confirm_dialog.dart` / `feedback_toast.dart` — confirm + toast for delete / batch-delete / clear-completed.
- `ManualOneStepScreen` (`main_shell_screen.dart:139`) — the full-screen route shape the add/edit form should mirror.

### Established Patterns
- The nav shell is an `IndexedStack` in `MainShellScreen`; the 4th child is the placeholder `Center(Text(todoTab))` to replace with `ShoppingListScreen`. The FAB is a single `onFabTap` callback in the parent — making it context-aware means branching on `currentIndex == 3`.
- Swipe-delete uses `Dismissible` + `confirmDismiss: showSoftConfirmDialog` + `onDismissed: showSuccessFeedback BEFORE provider calls` (context-validity ordering — preserve this).
- Reactive UI = bind to Drift `.watch()` streams (`watchByListType`), never manual invalidate for synced changes (GAP-2 lesson, SYNC-06).
- Attribution chip = `taggedTx.memberTag` (emoji + name, `palette.sharedLight`/`sharedText`), shown only for shadow/shared rows — mirror for public-list tiles (SYNC-04).

### Integration Points
- **`MainShellScreen`** is the single biggest integration site: (1) replace 4th-tab placeholder with `ShoppingListScreen`; (2) make `onFabTap` context-aware (index 3 → add-shopping-item screen, else → existing `ManualOneStepScreen` with all current invalidations intact — SC1 "no accounting regression"); (3) add `batchSelectMode` guard hiding nav bar + FAB (D38-03).
- **`home_bottom_nav_bar.dart`** — NAV-02 rename + icon swap (4th tab).
- **`shopping_list/presentation/providers/`** — add `listTypeProvider` + `shoppingFilterProvider` (both `keepAlive: true`, filter resets on segment switch — SC2), screen-state providers, the `batchSelectMode` provider, and wire the Phase 37 use cases + tracker into the provider graph (37-CONTEXT flagged this as Phase 38 territory).
- **`watchByListType('public'|'private')`** (Phase 36 DAO) — the stream the list binds to; reactive family updates flow through it (SYNC-06).

</code_context>

<specifics>
## Specific Ideas

- Edit/toggle split should feel like Bring!/AnyList: tapping the row checks the item off (the high-frequency action), editing is a deliberate secondary action behind a trailing affordance (D38-01).
- Batch mode should feel like a standard Material contextual action mode — the whole bottom chrome transforms (nav bar + FAB out, selection header + action bar in) rather than stacking a bar on top of the existing nav (D38-03).
- The drag handle and the edit affordance both live in the tile's trailing region but must not fight the swipe gesture — keep them visually distinct and the swipe target on the row body (D38-01/D38-02).

</specifics>

<deferred>
## Deferred Ideas

- **Cross-device synced shopping-list ordering** — still deferred (D37-01); D38-02's reorder is local-only via handle.
- **v2 shopping enhancements** (SUBTOTAL-01 running total, AUTO-01 autocomplete, GROUP-01 category grouping, TAGFILT-01 tag filter, DUP-01 duplicate detection, COLLAPSE-01 collapsible completed section) — all v2, unchanged from D8.

None beyond the above — discussion stayed within phase scope.

</deferred>

---

*Phase: 38-presentation-shell-ui-widgets*
*Context gathered: 2026-06-08*
