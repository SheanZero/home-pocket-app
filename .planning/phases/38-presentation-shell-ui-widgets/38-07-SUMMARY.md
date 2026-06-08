---
phase: 38-presentation-shell-ui-widgets
plan: "07"
subsystem: shopping-list-form
tags: [flutter, riverpod, shopping-list, form, validation, i18n]
status: complete

dependency_graph:
  requires:
    - "38-04"  # ShoppingItemTile (stub ShoppingItemFormScreen)
    - "38-05"  # ShoppingEmptyState (CTA pushes form)
  provides:
    - ShoppingItemFormScreen (create/edit, all D4 fields)
    - 12 ARB localization keys (shoppingForm* across ja/zh/en)
  affects:
    - lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart
    - test/widget/features/shopping_list/presentation/screens/shopping_item_form_screen_test.dart

tech_stack:
  added:
    - Category import from accounting domain (for typed Navigator.push<Category>)
    - deviceIdentityRepositoryProvider from accounting presentation (cross-feature, import_guard allows)
  patterns:
    - ConsumerStatefulWidget form pattern (mirrors ManualOneStepScreen)
    - LedgerTypeSelector reuse from lib/shared/widgets/ (confirmed constructor signature)
    - TextFormField validator with S.of(context) error message (ITEM-01)
    - Navigator.push<Category> typed return from CategorySelectionScreen
    - Result<T>.isError / .error pattern from shared/utils/result.dart

key_files:
  created:
    - lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart
    - test/widget/features/shopping_list/presentation/screens/shopping_item_form_screen_test.dart
  modified:
    - lib/l10n/app_en.arb
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb

decisions:
  - "deviceId obtained via deviceIdentityRepositoryProvider from accounting feature presentation layer — import_guard deny list does not block this (only infrastructure/daos/tables denied); cross-feature accounting import already pattern-established via CategorySelectionScreen allow-list"
  - "LedgerTypeSelector toggle behavior: tapping same ledger again sets _ledgerType to null (toggle off), allowing users to clear ledger selection — more flexible than one-way toggle"
  - "Navigator.push typed as <Category> instead of <dynamic> — eliminates unsafe .id cast; CategorySelectionScreen pops Category objects via onChildSelected callback"
  - "_tags field removed: tags parsed directly from _tagsController.text in _save() — avoids unused field warning and simplifies state"

metrics:
  duration: "~25 minutes"
  completed_date: "2026-06-08"
  tasks_completed: 2
  files_created: 2
  files_modified: 3
---

# Phase 38 Plan 07: ShoppingItemFormScreen — Create/Edit Form Summary

Full-screen add/edit form for shopping list items, implementing all D4 optional fields (ledger, category, tags, note, quantity, estimated price) plus required name validation. ConsumerStatefulWidget pattern mirrors ManualOneStepScreen. LedgerTypeSelector widget reused verbatim from shared/widgets. listType is never shown as a UI control (D6/SYNC-03 immutability enforced at T-38-07-01).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Implement ShoppingItemFormScreen — create/edit form | `3ad3da6e` | shopping_item_form_screen.dart + 3 ARB files |
| 2 | Fill in shopping_item_form_screen_test.dart | `4570e178` | shopping_item_form_screen_test.dart + form screen refinement |

## Verification

- `flutter test test/widget/features/shopping_list/presentation/screens/shopping_item_form_screen_test.dart` — 10/10 tests pass (ITEM-01, ITEM-02, ITEM-04)
- `flutter analyze lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart` — No issues found
- `flutter test test/widget/features/shopping_list/` — 41/41 tests pass (no regressions)
- `grep LedgerTypeSelector shopping_item_form_screen.dart` — 1 hit (line 208)
- `grep _formKey.currentState!.validate shopping_item_form_screen.dart` — 1 hit (line 97)
- `listType` appears only in: doc comment, constructor param, field declaration, CreateShoppingItemParams call — NOT in form UI rendering section

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Result type used errorMessage getter that does not exist**
- **Found during:** Task 1, `flutter analyze`
- **Issue:** Plan pattern used `result.errorMessage` but `Result<T>` only exposes `.error` (String?) and `.isError` (bool) — no `errorMessage` getter
- **Fix:** Changed to `result.isError` check + `throw Exception(result.error)` pattern
- **Files modified:** shopping_item_form_screen.dart
- **Commit:** `3ad3da6e`

**2. [Rule 1 - Bug] Unused `_tags` state field**
- **Found during:** Task 1, `flutter analyze`
- **Issue:** Plan specified a separate `_tags = []` state field but the implementation parses tags directly from `_tagsController.text` in `_save()`, making the field unused
- **Fix:** Removed `_tags` field; tags parsed from comma-separated `_tagsController` text inline in `_save()`
- **Files modified:** shopping_item_form_screen.dart
- **Commit:** `3ad3da6e`

**3. [Rule 2 - Missing critical functionality] _pickCategory typed as dynamic**
- **Found during:** Task 2, analyzing CategorySelectionScreen.pop behavior
- **Issue:** Initial implementation used `Navigator.push<dynamic>` with unsafe `.id` dynamic cast; CategorySelectionScreen.onChildSelected pops Category objects
- **Fix:** Changed to `Navigator.push<Category>` with typed `Category` import; removed unsafe dynamic cast
- **Files modified:** shopping_item_form_screen.dart (in Task 2 commit)
- **Commit:** `4570e178`

**4. [Rule 2 - i18n completeness] Added 12 ARB keys not in original plan scope**
- **Found during:** Task 1 (implementation requires l10n strings)
- **Reason:** Plan action referenced `S.of(context).shoppingFormAddTitle`, `shoppingFormSaveError`, etc. but these keys did not exist in ARBs
- **Fix:** Added 12 keys (shoppingFormAddTitle, shoppingFormEditTitle, shoppingFormSave, shoppingFormNameLabel, shoppingFormNameRequired, shoppingFormLedgerLabel, shoppingFormCategoryLabel, shoppingFormNoCategorySelected, shoppingFormChangeCategory, shoppingFormTagsLabel, shoppingFormNoteLabel, shoppingFormQuantityLabel, shoppingFormPrice, shoppingFormSaveError) to all 3 ARBs + ran flutter gen-l10n
- **Files modified:** app_en.arb, app_ja.arb, app_zh.arb
- **Commit:** `3ad3da6e`

## Known Stubs

None — ShoppingItemFormScreen is fully wired to CreateShoppingItemUseCase and UpdateShoppingItemUseCase. All D4 fields are rendered and functional.

## Threat Flags

No new threat surface beyond what the plan's threat model covers:
- listType immutability enforced (T-38-07-01): listType is only read from constructor param, never rendered as a form control
- Note plaintext to use case (T-38-07-02): no encryption in form; note passed as `_noteController.text.isEmpty ? null : _noteController.text`
- Estimated price non-integer (T-38-07-03): `int.tryParse` returns null for non-numeric → null treated as "no price set"

## Self-Check: PASSED

- [x] `lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart` — FOUND
- [x] `test/widget/features/shopping_list/presentation/screens/shopping_item_form_screen_test.dart` — FOUND
- [x] Commit `3ad3da6e` — FOUND
- [x] Commit `4570e178` — FOUND
- [x] 10/10 tests pass
- [x] analyze 0 issues
