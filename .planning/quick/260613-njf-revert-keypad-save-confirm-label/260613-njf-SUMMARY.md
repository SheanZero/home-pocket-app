---
phase: quick-260613-njf
plan: 01
subsystem: accounting-presentation
tags: [revert, foreign-currency, edit-screen, keypad, i18n-label]
requires:
  - "260613-n5c 改动2 (commit ce64a4d8) — the behavior being reverted"
provides:
  - "编辑页头部金额键盘动作键 = 纯 write-back（不触发整条目保存、不 pop）"
  - "编辑页外币键盘动作键文案 = 确认 (S.of(context).confirm)"
affects:
  - lib/features/accounting/presentation/screens/transaction_edit_screen.dart
  - lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart
tech-stack:
  added: []
  patterns:
    - "Reuse existing 'confirm' ARB key (zh 确认 / ja 確認 / en Confirm); no gen-l10n needed"
key-files:
  created: []
  modified:
    - lib/features/accounting/presentation/screens/transaction_edit_screen.dart
    - lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart
    - test/widget/features/accounting/presentation/screens/transaction_edit_screen_amount_test.dart
    - test/widget/features/accounting/presentation/widgets/amount_edit_bottom_sheet_currency_test.dart
decisions:
  - "改动2 fully reverted; 改动1 (rate-date trigger 3af79040 + golden 08c87829) preserved untouched"
  - "Currency-aware keypad label save→confirm; JPY mode keeps record"
metrics:
  duration: ~6min
  completed: 2026-06-13
---

# Quick Task 260613-njf: 撤销改动2键盘整条目保存 + 外币键盘动作键文案 save→确认 Summary

Reverted 260613-n5c 改动2 (commit `ce64a4d8`): the edit-screen headline-amount keypad action key is back to pure write-back (writes display + form, does NOT trigger a whole-entry save or pop the screen); whole-entry save remains owned by the screen's bottom Save button. The foreign (currency-aware) keypad action-key label was changed from 「保存」(save) to 「确认」(confirm). 改动1 (rate-date trigger + currency_linked goldens) was left fully intact.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | 撤销改动2代码 + 外币键盘动作键 save→confirm | `2196304e` | transaction_edit_screen.dart, amount_edit_bottom_sheet.dart |
| 2 | 撤销改动2测试 + 更新 label 断言 + 全量验证 | `8b274e08` | transaction_edit_screen_amount_test.dart, amount_edit_bottom_sheet_currency_test.dart |

## What Changed

### Task 1 — source
- `transaction_edit_screen.dart`: `_editAmount` and `_editForeignAmount` restored to the 260613-mgc write-back form (参照 `git show ce64a4d8^`). Removed `var confirmed = false;`, the `confirmed = true;` line inside each `onConfirm`, and the post-`show()` `if (confirmed && mounted) await _save();` block. Restored the original (shorter) doc comments. `_save()` itself untouched — the bottom Save button still owns whole-entry save.
- `amount_edit_bottom_sheet.dart`: currency-aware `actionLabel` `S.of(context).save` → `S.of(context).confirm`; JPY branch keeps `S.of(context).record`. Updated the adjacent comment to reflect the 确认 (write-back) semantics.

### Task 2 — tests
- `transaction_edit_screen_amount_test.dart`: restored to `ce64a4d8^` content (TEST 5 back to the write-back contract: headline updates, in-card JPY re-derives, screen stays mounted, use case NOT invoked). Removed 改动2 scaffolding — TEST 6 (JPY record whole-entry save), TEST 7 (swipe no-save), `_EditScreenLauncher`, `_savableOverrides`, `_SeededCategoryRepository`, and the `result.dart` import. TEST 5 keypad action-key lookup `find.text('Save')` → `find.text('Confirm')`. TEST 1-4 and the `CurrencyLinkedEditValue` test untouched; the bottom-CTA `find.text('Save')` in the clear-amount test stays (it targets the screen's bottom button, not the keypad).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated `amount_edit_bottom_sheet_currency_test.dart` label lookups**
- **Found during:** Task 2 full-suite run (2 failures)
- **Issue:** This test file (not listed in the plan's `<files>`) located the currency-aware keypad action key via `find.text('Save')` at two sites. The Task 1 label change (save→confirm) made those lookups miss, failing both currency-aware round-trip tests.
- **Fix:** Changed both `find.text('Save')` → `find.text('Confirm')` (the renamed label is correct; tests must follow it). JPY-mode `find.text('Record')` lookup in the same file left unchanged.
- **Files modified:** test/widget/features/accounting/presentation/widgets/amount_edit_bottom_sheet_currency_test.dart
- **Commit:** `8b274e08`

## Verification

- `flutter analyze`: **No issues found** (0).
- `flutter test` (full suite incl. architecture tests / hardcoded_cjk_ui_scan, not skipped): **2819 passed, 0 failed**.
- No golden files changed (`git diff --name-only` over both njf commits shows only the 4 source/test files; zero golden paths). 改动1 goldens not affected — the label lives in the bottom sheet, not in the currency_linked golden.
- 改动1 preserved: `rateDate` references intact in `currency_linked_edit_fields.dart`, `transaction_details_form.dart`, `conversion_preview_panel.dart`; no rateDate/DateFormatter/golden changes in the njf commits.
- OCR / Voice `AmountEditBottomSheet` paths use JPY mode (`record`) and were not touched — zero regression (full suite green).

## Self-Check: PASSED

- FOUND: lib/features/accounting/presentation/screens/transaction_edit_screen.dart
- FOUND: lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart
- FOUND: test/widget/features/accounting/presentation/screens/transaction_edit_screen_amount_test.dart
- FOUND: test/widget/features/accounting/presentation/widgets/amount_edit_bottom_sheet_currency_test.dart
- FOUND commit: 2196304e
- FOUND commit: 8b274e08
