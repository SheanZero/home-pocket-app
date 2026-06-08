---
phase: 38
slug: presentation-shell-ui-widgets
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-08
---

# Phase 38 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (built-in) + Mocktail mocks |
| **Config file** | none — `flutter test` |
| **Quick run command** | `flutter test test/widget/features/shopping_list/ test/unit/features/shopping_list/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~10s scoped / ~90s full suite |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/widget/features/shopping_list/ test/unit/features/shopping_list/`
- **After every plan wave:** Run `flutter test` (full suite)
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~90 seconds (full suite)

---

## Per-Requirement Verification Map

> Task IDs assigned by the planner; this map is requirement-keyed and reconciled against PLAN.md task list during plan-check.

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| NAV-01 | FAB routes to add-shopping-item at index 3; transaction FAB at other indices (all post-entry invalidations intact) | widget | `flutter test test/widget/features/shopping_list/presentation/screens/main_shell_screen_fab_test.dart` | ❌ W0 | ⬜ pending |
| NAV-02 | 4th tab label = 購入リスト/购物清单/Shopping List; icon = shopping_bag; zero 待办/Todo strings | widget | `flutter test test/widget/features/shopping_list/presentation/widgets/home_bottom_nav_bar_shopping_test.dart` | ❌ W0 | ⬜ pending |
| FILT-01 | Shopping filter bar renders ledger/category/status chips | widget | `flutter test test/widget/features/shopping_list/presentation/widgets/shopping_filter_bar_test.dart` | ❌ W0 | ⬜ pending |
| FILT-02 | Filter resets on segment switch; shoppingFilterProvider + listTypeProvider keepAlive | unit (ProviderContainer) | `flutter test test/unit/features/shopping_list/providers/state_shopping_filter_test.dart` | ❌ W0 | ⬜ pending |
| FILT-03 | Clear-all-filters control resets to no-filter | widget | `flutter test test/widget/features/shopping_list/presentation/widgets/shopping_filter_bar_test.dart` | ❌ W0 | ⬜ pending |
| DONE-01 | Tap tile body toggles completed; animated strikethrough + fade applied | widget | `flutter test test/widget/features/shopping_list/presentation/widgets/shopping_item_tile_test.dart` | ❌ W0 | ⬜ pending |
| DONE-03 | "Clear all completed" appears only when completed section non-empty; fires ClearCompletedItemsUseCase for current segment | widget | `flutter test test/widget/features/shopping_list/presentation/screens/shopping_list_screen_test.dart` | ❌ W0 | ⬜ pending |
| ITEM-01 | Form validates name required (empty name blocks save) | widget | `flutter test test/widget/features/shopping_list/presentation/screens/shopping_item_form_screen_test.dart` | ❌ W0 | ⬜ pending |
| ITEM-02 | Form ledger field reuses LedgerTypeSelector; optional | widget | `flutter test test/widget/features/shopping_list/presentation/screens/shopping_item_form_screen_test.dart` | ❌ W0 | ⬜ pending |
| ITEM-04 | Edit reuses form pre-populated from existing item | widget | `flutter test test/widget/features/shopping_list/presentation/screens/shopping_item_form_screen_test.dart` | ❌ W0 | ⬜ pending |
| SHOP-02 | Tile renders name (primary); emoji+qty+price (secondary); dual-ledger left-border accent | widget | `flutter test test/widget/features/shopping_list/presentation/widgets/shopping_item_tile_test.dart` (golden → Phase 39) | ❌ W0 | ⬜ pending |
| SHOP-03 | Dual-ledger color accent: palette.daily/palette.joy, neutral when no ledger | widget | included in `shopping_item_tile_test.dart` | ❌ W0 | ⬜ pending |
| SHOP-04 | 3 empty-state variants (empty private / empty public solo / empty public family) render | widget | `flutter test test/widget/features/shopping_list/presentation/widgets/shopping_empty_state_test.dart` | ❌ W0 | ⬜ pending |
| MGMT-01 | Swipe-to-delete fires DeleteShoppingItemUseCase (soft-delete) | widget | `flutter test test/widget/features/shopping_list/presentation/widgets/shopping_item_tile_swipe_test.dart` | ❌ W0 | ⬜ pending |
| MGMT-02 | Long-press enters batch-select mode; Select-all available; batch-delete fires Delete per selected item | widget | `flutter test test/widget/features/shopping_list/presentation/screens/shopping_list_screen_test.dart` | ❌ W0 | ⬜ pending |
| MGMT-03 | Swipe + reorder handles disabled while batch mode active | widget | included in `shopping_item_tile_test.dart` | ❌ W0 | ⬜ pending |
| SYNC-04 | Attribution chip on public tiles only, absent on private | widget | included in `shopping_item_tile_test.dart` | ❌ W0 | ⬜ pending |
| D38-03 | batchSelectMode hides nav bar + FAB in MainShellScreen; restored on exit | widget | `flutter test test/widget/features/home/presentation/screens/main_shell_screen_test.dart` (EXTEND existing) | extend | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `ShoppingListFilter.categoryIds: Set<String>` field addition + `build_runner` — **blocks all filter tests** (Phase 36 model lacks it)
- [ ] `test/widget/features/shopping_list/` — directory tree + all widget test files listed above
- [ ] `test/unit/features/shopping_list/providers/` — provider unit tests (keepAlive + reset-on-switch)
- [ ] `test/widget/features/shopping_list/helpers/` — Mocktail mock use cases (Create/Update/Delete/Toggle/Reorder/Clear) + provider overrides for `shoppingItemRepositoryProvider`, `batchSelectModeProvider`, `listTypeProvider`, `shoppingFilterProvider`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Gesture conflict: drag handle vs Dismissible swipe vs long-press batch-select don't fight | MGMT-02/MGMT-03/D38-02 | `SliverReorderableList` drag-gesture simulation is not reliably reproducible in `flutter_test` | On device: long-press an active item → batch mode (no accidental drag); drag the handle → reorders (no swipe-delete); horizontal swipe on body → delete confirm |
| Screen-reader announces edit chevron + drag handle labels | D38-01/D38-02 (a11y) | On-device VoiceOver/TalkBack announcement not assertable in widget test (code-grep verifies `Semantics(label:)` presence only) | On device: enable VoiceOver/TalkBack; focus trailing affordances; confirm localized labels announced |
| Strikethrough + fade animation timing/curve feels right | DONE-01 | Animation aesthetics are subjective; widget test asserts presence not feel | On device: tap item; observe strikethrough sweep + fade |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (esp. `categoryIds` field)
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
