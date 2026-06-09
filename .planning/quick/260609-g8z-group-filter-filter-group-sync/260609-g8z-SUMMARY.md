---
phase: quick-260609-g8z
plan: "01"
type: execute
subsystem: shopping_list
tags: [filter, private, i18n, form, golden]
dependency_graph:
  requires: []
  provides: [shopping_private_filter_chip, shopping_form_listtype_selector]
  affects: [shopping_list_filter, shopping_filter_bar, shopping_item_form_screen]
tech_stack:
  added: []
  patterns: [riverpod_state_extension, freezed_field_addition, segmented_button_disabled]
key_files:
  created: []
  modified:
    - lib/features/shopping_list/domain/models/shopping_list_filter.dart
    - lib/features/shopping_list/domain/models/shopping_list_filter.freezed.dart
    - lib/features/shopping_list/presentation/providers/state_shopping_filter.dart
    - lib/features/shopping_list/presentation/providers/repository_providers.dart
    - lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart
    - lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/l10n/app_en.arb
    - lib/generated/app_localizations.dart
    - lib/generated/app_localizations_ja.dart
    - lib/generated/app_localizations_zh.dart
    - lib/generated/app_localizations_en.dart
    - test/unit/features/shopping_list/providers/state_shopping_filter_test.dart
    - test/widget/features/shopping_list/presentation/widgets/shopping_filter_bar_test.dart
    - test/widget/features/shopping_list/presentation/screens/shopping_item_form_screen_test.dart
    - test/golden/goldens/shopping_filter_bar_active_ja.png
    - test/golden/goldens/shopping_filter_bar_active_zh.png
    - test/golden/goldens/shopping_filter_bar_active_dark_ja.png
    - test/golden/goldens/shopping_filter_bar_active_dark_zh.png
decisions:
  - "Private filter chip uses palette.sharedLight/shared/sharedText (steel-blue identity) — neutral scope indicator, not confusable with daily/joy"
  - "IgnorePointer + Opacity(0.6) + onSelectionChanged=null for edit-mode read-only selector (belt and suspenders)"
  - "isGroupModeProvider fully removed from form screen; selector always rendered regardless of group membership"
metrics:
  duration: "~25 minutes"
  completed: "2026-06-09"
  tasks: 5
  files_modified: 18
---

# Phase quick-260609-g8z Plan 01: Group Filter / Private Chip Sync Summary

**One-liner:** Always-visible 私有 filter chip in ShoppingFilterBar + read-only list-type selector on edit form, with 個人/个人/Personal renamed to 私有/私有/Private across all 3 locales.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Extend ShoppingListFilter + ShoppingFilter with showPrivateOnly | 024748d6 | shopping_list_filter.dart, state_shopping_filter.dart, repository_providers.dart |
| 2 | ARB rename + new keys | 79a3e56b | app_ja/zh/en.arb, generated l10n files |
| 3 | ShoppingFilterBar — 私有 chip always visible | 5a587e30 | shopping_filter_bar.dart, shopping_filter_bar_test.dart |
| 4 | Form screen — create interactive / edit read-only selector | 669d6fef | shopping_item_form_screen.dart, form_screen_test.dart |
| 5 | Golden rebaseline + full suite check | 983399ec | 4 PNG golden baselines |

## Verification Results

- `flutter pub run build_runner build --delete-conflicting-outputs` — 0 conflicts, 1600 outputs
- `flutter gen-l10n` — 0 errors
- `flutter analyze --no-fatal-infos` — 0 issues
- `flutter test test/unit/.../state_shopping_filter_test.dart` — 9/9 pass
- `flutter test test/widget/.../shopping_filter_bar_test.dart` — 13/13 pass
- `flutter test test/widget/.../shopping_item_form_screen_test.dart` — 15/15 pass
- `flutter test --exclude-tags golden` — 2396/2396 pass
- Golden rebaseline — 6 PNGs updated (4 changed for ja/zh; en unchanged)

## Invariant Checks

- D37-06 privacy gate: `if (item.listType == 'public')` in `create_shopping_item_use_case.dart` — untouched
- D37-04 listType immutability: `'Invariant violation: listType cannot be changed after creation'` in `update_shopping_item_use_case.dart` — untouched
- No `isGroupModeProvider` usage remaining in `shopping_item_form_screen.dart` (import removed)
- Old labels 個人/个人/Personal replaced in all 3 ARB files for `shoppingSegmentPrivate`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] ITEM-02 test broken by form height increase**
- **Found during:** Task 4 (implementing form changes)
- **Issue:** The form always renders the list-type selector now, making it taller. The ITEM-02 "quantity and estimated price fields are present" test could no longer find the price field without scrolling.
- **Fix:** Added `scrollUntilVisible` calls before the quantity and price field assertions.
- **Files modified:** `test/widget/features/shopping_list/presentation/screens/shopping_item_form_screen_test.dart`
- **Commit:** 669d6fef (included in Task 4 commit)

## Known Stubs

None — all changes are wired to real data (ShoppingListFilter.showPrivateOnly, filteredShoppingItems routing, item.listType reflected in form).

## Threat Flags

No new security-relevant surfaces introduced. D37-06 and D37-04 invariants verified unchanged.

## Self-Check: PASSED

---

# Plan 02 — follow-up fixes (3 bugs)

**Date:** 2026-06-09 · **Status:** complete

User-reported refinements to the plan-01 delivery. Three fixes:

## FIX 1 — defaults + tile cleanup
- New items default to **日常 (daily)** ledger in create mode (`_ledgerType = LedgerType.daily` in initState; toggle-off still allowed).
- Removed the 日常/悦己 ledger badge from list tiles (deleted `_buildLedgerBadge`).
- Restored the **悦己 (joy)** 4px left accent bar (`LedgerType.joy => palette.joy`, was `Colors.transparent`).

## FIX 2 — public/private selector restyle + default public
- New `ListTypeSelector` widget (`lib/shared/widgets/list_type_selector.dart`) mirroring `LedgerTypeSelector`'s pill-chip style; order **公共 → 私有**, single shared steel-blue accent, `enabled` flag for read-only edit mode.
- Form: replaced the SegmentedButton with `ListTypeSelector`, moved it to sit **after** the ledger selector. Default **public**; edit mode read-only (enabled:false) + locked hint — D37-04/SYNC-03 immutability untouched.
- Create entry points default to `'public'`: `main_shell_screen` FAB + `shopping_empty_state` CTA (was `'private'`).

## FIX 3 — private marker in tiles
- In the old badge position, tiles now show a **私有 marker** (lock + `shoppingSegmentPrivate`, `palette.sharedLight/sharedText`) only for `listType=='private'`. Public items show no marker.

## Decisions / notes
- No schema change, no new ARB keys, no codegen (reused `shoppingSegmentPublic/Private`, `shoppingListTypeLockedHint`, `shoppingFormListTypeLabel`).
- Tasks 1–2 ran via a worktree executor; Tasks 3–5 were completed inline after the executor connection dropped/stalled (infra, not logic).

## Verification
- `flutter analyze` — **0 issues**.
- Affected widget tests — **50/50 green** (tile, form, ListTypeSelector, empty-state).
- Re-baselined **18** `shopping_item_tile` goldens (3 variants × 3 locales × 2 modes); filter-bar/empty-state/batch-chrome goldens unaffected. Visually confirmed: private marker present, public none, joy accent restored.
- Full non-golden suite: 2398 passing; the only 3 reds were `test/scripts/{merge_findings,coverage_gate}_test.dart` — flaky subprocess tooling tests (zero shopping refs) that **pass green in isolation**.

## Commits (plan 02)
- `ded92073` ListTypeSelector widget
- `f843db07` form: daily default, selector after ledger, default public, edit read-only
- `fe3e18eb` tile: joy accent restored, ledger badge dropped, 私有 marker
- `2de7f9fa` create entries default to public
- `0fb224ad` re-baseline 18 tile goldens + warnIfMissed on disabled-tap test
