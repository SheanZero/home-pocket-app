---
status: resolved
phase: 38-presentation-shell-ui-widgets
depth: standard
reviewed: 2026-06-08T00:00:00Z
resolution: |
  Reviewed by orchestrator during code_review_gate.
  - CR-01 (category UUID shown to user): FIXED — capture selected.name on pick; resolve name async in edit mode via categoryRepository.findById. shopping_item_form_screen.dart.
  - CR-02 (Thin Feature: data/daos import in presentation): REJECTED (false positive) — 6 of 8 features (accounting/family_sync/analytics/profile/settings/shopping_list) wire repo impls this way in presentation/providers/repository_providers.dart; it is the established convention CLAUDE.md describes and the 38-03 import_guard allows. Not a phase-38 regression.
  - WR-03 (no negative qty/price validation): FIXED — sanitize quantity (>=1) and estimatedPrice (>=0, else null) in _save.
  - WR-04 (hardcoded English Semantics label): FIXED — use l10n.listClearAll. shopping_filter_bar.dart.
  - WR-01 (unawaited reorder Result), WR-02 (unused listType field), IN-01/02/03: ACKNOWLEDGED, non-blocking advisory — left as tracked follow-ups (optimistic-reorder is acceptable; dead-field cleanup is cosmetic).
  Full suite 2445/2445 green after fixes; analyze contributes zero phase-38 issues.
files_reviewed: 14
files_reviewed_list:
  - lib/features/home/presentation/screens/main_shell_screen.dart
  - lib/features/home/presentation/widgets/home_bottom_nav_bar.dart
  - lib/features/list/presentation/widgets/list_category_filter_sheet.dart
  - lib/features/shopping_list/domain/models/shopping_list_filter.dart
  - lib/features/shopping_list/presentation/providers/repository_providers.dart
  - lib/features/shopping_list/presentation/providers/state_shopping_batch.dart
  - lib/features/shopping_list/presentation/providers/state_shopping_filter.dart
  - lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart
  - lib/features/shopping_list/presentation/screens/shopping_list_screen.dart
  - lib/features/shopping_list/presentation/widgets/shopping_batch_action_bar.dart
  - lib/features/shopping_list/presentation/widgets/shopping_empty_state.dart
  - lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart
  - lib/features/shopping_list/presentation/widgets/shopping_item_tile.dart
  - lib/features/shopping_list/presentation/widgets/shopping_selection_header.dart
critical: 2
warning: 4
info: 3
---

# Phase 38: Code Review Report

**Reviewed:** 2026-06-08
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

## Summary

Phase 38 delivers the shopping-list presentation shell: navigation wiring, item tile, empty-state, filter bar, batch-select chrome, and the add/edit form. The architecture is sound overall — Riverpod 3 conventions are followed correctly (`.value` not `.valueOrNull`, `ref.listen` for side-effects), the SC1 invalidation invariant is preserved, and the critical feedback-before-use-case ordering rule is applied consistently.

Two blockers stand out: the form screen displays a raw UUID to the user as the selected category label, and the `repository_providers.dart` file in the feature's presentation layer directly imports `data/daos/` and `data/repositories/`, violating the Thin Feature rule. Four warnings cover unhandled async results, missing input guards, hardcoded semantic strings, and stale doc-comment copy.

---

## Critical Issues

### CR-01: Category field displays raw UUID instead of human-readable name

**File:** `lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart:164,230`

**Issue:** `_pickCategory()` stores only `selected.id` in `_categoryId` (line 164). Line 230 then renders `_categoryId ?? l.shoppingFormNoCategorySelected` as the visible label. After the user picks a category the display shows the raw UUID (e.g. `"e3b0c442-98fc..."`) — not the category name. The `Category` object returned by `CategorySelectionScreen` carries `.name` on it; it is silently discarded.

This is a UX correctness bug: the category picker round-trips but always renders garbage text. The form also pre-populates in edit mode from `item.categoryId` (a raw ID, line 75), so the user cannot see which category was originally saved.

**Fix:**
Add a `String? _categoryName` state field alongside `_categoryId`. Store both when a category is picked and when pre-populating from an existing item (edit mode requires an async name lookup or accepting the absence):

```dart
// State field
String? _categoryId;
String? _categoryName;    // <-- add this

// In _pickCategory():
if (selected != null && mounted) {
  setState(() {
    _categoryId   = selected.id;
    _categoryName = selected.name;   // store the human-readable name
  });
}

// In the display Text:
Text(
  _categoryName ?? l.shoppingFormNoCategorySelected,
  style: Theme.of(context).textTheme.bodyMedium,
),
```

For edit-mode pre-population, either fetch the category name via `categoryRepositoryProvider.findById(_categoryId)` in `initState`, or display a placeholder ("Category selected") until the picker is opened once. The former is preferable.

---

### CR-02: Thin Feature rule violated — feature's `repository_providers.dart` imports `data/daos` and `data/repositories`

**File:** `lib/features/shopping_list/presentation/providers/repository_providers.dart:11-12`

**Issue:** The file imports:
```dart
import '../../../../data/daos/shopping_item_dao.dart';
import '../../../../data/repositories/shopping_item_repository_impl.dart';
```

CLAUDE.md states: "Features NEVER contain `application/`, `infrastructure/`, `data/tables/`, or `data/daos/`." The `data/daos/` and `data/repositories/` imports break this boundary from within the presentation layer.

The existing `accounting` feature's `repository_providers.dart` contains the same pattern, suggesting it was used as a template rather than an architectural model. CLAUDE.md's Placement Decision Rule §3 says data-access belongs in `lib/data/`; a provider that constructs the repository impl belongs in `lib/application/shopping_list/` (or a dedicated `lib/data/repository_providers.dart`), not inside the feature's presentation layer.

**Fix:**
Move `shoppingItemRepositoryProvider` (and the DAO construction) into `lib/application/shopping_list/repository_providers.dart` (matching the convention used by `lib/application/accounting/repository_providers.dart` which is already imported here at line 3). The use-case providers that depend on it remain in the feature's presentation layer and simply switch their import. This keeps DAO/impl knowledge out of the feature tree.

---

## Warnings

### WR-01: Reorder use-case result is fire-and-forget — errors silently discarded

**File:** `lib/features/shopping_list/presentation/screens/shopping_list_screen.dart:160-164`

**Issue:** `onReorderItem` calls `execute(activeItems[oldIndex].id, newIndex)` without `await` and without handling the returned `Future<Result<void>>`. If the use case returns `Result.error(...)` or throws (e.g. DB unavailable), the drag appears successful to the user but the sort order is not persisted. The list will snap back to the old order on the next stream emission with no feedback.

```dart
onReorderItem: (oldIndex, newIndex) {
  ref
      .read(reorderShoppingItemsUseCaseProvider)
      .execute(activeItems[oldIndex].id, newIndex);  // unawaited, error ignored
},
```

**Fix:**
```dart
onReorderItem: (oldIndex, newIndex) async {
  final result = await ref
      .read(reorderShoppingItemsUseCaseProvider)
      .execute(activeItems[oldIndex].id, newIndex);
  if (result.isError && context.mounted) {
    // silent failure is acceptable here; alternatively show a brief toast
  }
},
```
At minimum the `Future` should be `unawaited()` with an explicit comment, or the result checked. The current code silently discards both the future and any error.

---

### WR-02: `ShoppingListFilter.listType` field is dead — creates false impression of filter-level segment control

**File:** `lib/features/shopping_list/domain/models/shopping_list_filter.dart:17`

**Issue:** `ShoppingListFilter` declares a `listType` field with a default of `'private'`. The `filteredShoppingItemsProvider` reads the active segment from `listTypeProvider` (a separate, authoritative provider) and does NOT read `filter.listType`. Neither `ShoppingFilter` notifier methods (`setLedgerFilter`, `setStatusFilter`, `setCategoryIds`, `clearAll`, `resetForNewSegment`) ever update `filter.listType`. The field has no read sites in production code.

This creates a correctness risk: a future developer seeing `filter.listType` might assume it gates queries (it does not), or might update it via `copyWith` without realising it has no effect on what the DAO returns. The CLAUDE.md doc comment on the `ShoppingListFilter` class also describes `listType` as part of the filter contract, reinforcing the false impression.

**Fix:**
Remove the `listType` field from `ShoppingListFilter` entirely, update the doc comment, and regenerate with build_runner. The segment is authoritative in `listTypeProvider`; the filter model should not duplicate it.

---

### WR-03: Negative and zero quantity/price are not validated — can create invalid items

**File:** `lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart:122-123,137-138`

**Issue:** `keyboardType: TextInputType.number` allows the user to type `-1` or `0` for quantity and any negative integer for estimated price. `int.tryParse` happily parses these and passes them to the use case. A quantity of `0` or `-5` is semantically invalid for a shopping item; a negative estimated price is equally nonsensical and could affect analytics calculations.

There is a validator on the name field (line 197-198) but none on quantity or price.

**Fix:**
Add validators to the quantity and price `TextField`s (promote to `TextFormField`), or add `inputFormatters` to restrict input:

```dart
// In the quantity field:
TextFormField(
  controller: _quantityController,
  keyboardType: TextInputType.number,
  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
  validator: (v) {
    final n = int.tryParse(v ?? '');
    if (n == null || n < 1) return l.shoppingFormQuantityInvalid; // add ARB key
    return null;
  },
  ...
),

// In the price field — negative sign not needed for currency:
inputFormatters: [FilteringTextInputFormatter.digitsOnly],
```

---

### WR-04: Hardcoded English semantic label in `shopping_filter_bar.dart`

**File:** `lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart:204`

**Issue:**
```dart
Semantics(
  label: 'Clear all filters',   // <-- hardcoded English
  child: ActionChip(...),
),
```

This violates the i18n rule ("All UI text via `S.of(context)` — NEVER hardcode strings"). Screen-reader users running in Japanese or Chinese will hear "Clear all filters" in English. The same pattern exists in `list_sort_filter_bar.dart:496` (pre-existing), but the new shopping-list widget should not propagate it.

**Fix:**
```dart
Semantics(
  label: l10n.listClearAll,   // l10n already imported; listClearAll is already the chip label
  child: ActionChip(
    label: Text(l10n.listClearAll, ...),
    ...
  ),
),
```
Or remove the redundant `Semantics` wrapper entirely — an `ActionChip` with a text label is already accessible without an extra semantics node.

---

## Info

### IN-01: Stale "coral" doc comment in `home_bottom_nav_bar.dart`

**File:** `lib/features/home/presentation/widgets/home_bottom_nav_bar.dart:10-11`

**Issue:**
```
/// The pill has rounded corners (32px radius), a subtle shadow, and the active
/// tab is highlighted with a coral-coloured pill (14px radius). The FAB sits
/// to the right of the pill with a coral gradient.
```

ADR-019 (v1.6 palette) replaced coral with leaf green (`#6FA36F`) for nav/tab active states and sakura pink (`#D98CA0`) for the FAB gradient. The comment describes the pre-ADR-018 Coral palette. Code behavior is correct (uses `palette.accentPrimary`); the doc comment misleads contributors.

**Fix:** Update the class doc comment to reflect ADR-019: leaf-green active pill, sakura-pink FAB gradient.

---

### IN-02: `ShoppingListFilter.searchQuery` field is declared but never populated or applied

**File:** `lib/features/shopping_list/domain/models/shopping_list_filter.dart:20`

**Issue:** `searchQuery` is declared on the filter model and mentioned in the doc comment, but:
- `ShoppingFilter` notifier has no `setSearchQuery` method
- `filteredShoppingItemsProvider` does not apply a search filter
- No widget sets this field

The field is inert. Unlike `listType` (WR-02), it may legitimately be placeholder for a future search feature. It should be either removed (if truly out-of-scope) or annotated with a TODO to prevent confusion.

**Fix:** Either remove the field and regenerate, or add a `// TODO(Phase-NN): search not yet wired` comment and ensure `setSearchQuery` / filter application are tracked as known gaps.

---

### IN-03: `data/daos` and `data/repositories` imports in a feature's presentation layer (precedent from accounting)

**File:** `lib/features/shopping_list/presentation/providers/repository_providers.dart:11-12`

**Issue:** Noted in CR-02 above. The `accounting` feature's `repository_providers.dart` carries the identical pattern (already identified as a pre-existing architectural smell). Phase 38 replicates it rather than establishing a better pattern. A single `lib/data/shopping_item_repository_providers.dart` (parallel to `lib/application/accounting/repository_providers.dart` which handles other cross-cutting wiring) would be cleaner.

This is informational because it is a pre-existing pattern; the impact is limited until import_guard rules are extended to enforce the boundary in presentation layers.

---

_Reviewed: 2026-06-08_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
