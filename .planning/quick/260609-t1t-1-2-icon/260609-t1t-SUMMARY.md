---
phase: quick-260609-t1t
plan: 01
subsystem: shopping_list
tags: [i18n, ui, shopping_list, l10n]
requires:
  - shoppingListTypeLockedHint (existing l10n key, reused)
  - context.palette.error (existing token)
  - AppTextStyles.headlineSmall (existing token)
provides:
  - shoppingListScreenTitle l10n key (ja/zh/en)
  - shopping list screen title heading (T1T-01)
  - always-on red right-aligned lock hint with icon (T1T-02)
affects:
  - lib/features/shopping_list/presentation/screens/shopping_list_screen.dart
  - lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart
tech-stack:
  added: []
  patterns:
    - "S.of(context) for all UI text (no hardcoded strings)"
    - "context.palette tokens for all colors (no hardcoded hex)"
key-files:
  created: []
  modified:
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/l10n/app_en.arb
    - lib/generated/app_localizations.dart
    - lib/generated/app_localizations_ja.dart
    - lib/generated/app_localizations_zh.dart
    - lib/generated/app_localizations_en.dart
    - lib/features/shopping_list/presentation/screens/shopping_list_screen.dart
    - lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart
    - test/widget/features/shopping_list/presentation/screens/shopping_item_form_screen_test.dart
decisions:
  - "Lock hint shows in BOTH add and edit modes (T1T-02) — FORM-SELECTOR-04 test updated to match"
metrics:
  duration: ~10m
  completed: 2026-06-09
requirements: [T1T-01, T1T-02]
---

# Phase quick-260609-t1t Plan 01: Shopping List Title + Type-Lock Hint Summary

Adds a localized title heading to the shopping list tab (T1T-01) and restyles the public/private
type-lock hint to be red, icon-prefixed, right-aligned, and visible in both add and edit modes (T1T-02).

## What Changed

### Task 1 — New title l10n key (commit 9560b1c8)
- Added `shoppingListScreenTitle` to all three ARB files, placed next to the existing
  `shoppingSegment*` group:
  - ja: `買い物リスト` (default)
  - zh: `购物清单`
  - en: `Shopping List`
- Each with an `@shoppingListScreenTitle` description object.
- Ran `flutter gen-l10n`; `lib/generated/app_localizations*.dart` regenerated with the
  `shoppingListScreenTitle` getter.

### Task 2 — List screen title heading (commit 52cc0c0b)
- Inserted a title row as the first child of the body `Column` in `ShoppingListScreen.build`.
- `Padding(EdgeInsets.fromLTRB(16, 12, 16, 4))` → `Align(centerLeft)` →
  `Text(S.of(context).shoppingListScreenTitle, style: AppTextStyles.headlineSmall.copyWith(color: palette.textPrimary))`.
- Always visible, above the segmented control / filter bar, independent of `isGroupMode`.
- SafeArea(top) behavior unchanged.

### Task 3 — Lock hint restyle + always-show (commit 077b6117)
- Removed the `if (isEditMode)` guard around the type-locked hint so it renders in both
  add (create) and edit modes.
- Restyled from a left-aligned `Text` (hintColor) to a right-aligned `Row`:
  `MainAxisAlignment.end` + `Icon(Icons.lock_outline, size: 14, color: palette.error)` +
  `SizedBox(width: 4)` + `Flexible(child: Text(l.shoppingListTypeLockedHint, textAlign: end, color: palette.error))`.
- `Flexible` prevents overflow of the long en string "Cannot be changed after creation".
- Reuses the existing `shoppingListTypeLockedHint` key (no new text key).
- The `ListTypeSelector enabled: !isEditMode` behavior was left untouched — only the hint text
  visibility/style changed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated FORM-SELECTOR-04 widget test to match new always-show behavior**
- **Found during:** Task 3
- **Issue:** `shopping_item_form_screen_test.dart` FORM-SELECTOR-04 asserted the lock hint is
  *absent* in create mode (`findsNothing`) — the exact behavior T1T-02 reverses. The test failed
  after the implementation change.
- **Fix:** Flipped the create-mode assertion to `findsOneWidget` and updated the test name/reason
  to reflect that the hint must appear in both edit and create modes (T1T-02).
- **Files modified:** test/widget/features/shopping_list/presentation/screens/shopping_item_form_screen_test.dart
- **Commit:** 077b6117

## Verification

- `flutter gen-l10n` succeeded; generated file contains `shoppingListScreenTitle`.
- `flutter analyze` on both changed screens: **No issues found** (0 issues).
- `shopping_item_form_screen_test.dart`: 24/24 passed (incl. updated FORM-SELECTOR-04).
- `shopping_list_screen_test.dart`: passed.
- No golden tests reference either screen (no re-baseline needed).
- No hardcoded UI strings (all via `S.of(context)`); no hardcoded color hex (all via `palette`).

## Note Line References

The PLAN's line citations (530-539 for the hint, etc.) were slightly shifted because the form was
restructured by the immediately-preceding quick task 260609-ruu. The actual current structure was
located and edited correctly; the hint block was at lines 530-539 of the worktree copy.

## Self-Check: PASSED

All 6 modified/created source files present; all 3 task commits (9560b1c8, 52cc0c0b, 077b6117) in git log.
