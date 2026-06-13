---
phase: quick-260613-n5c
plan: 01
subsystem: ui
tags: [flutter, riverpod, i18n, currency, edit-screen, date-formatter, golden]

requires:
  - phase: quick-260613-mgc
    provides: foreign-currency edit headline keypad + two-row CurrencyLinkedEditFields card
provides:
  - "Date-change trigger shows the transaction's ACTUAL date (DateFormatter), not the static 「日期/Date」 word"
  - "Edit-screen keypad 保存/record action key completes the WHOLE-entry save (submit + pop(true)) for both JPY and foreign paths"
affects: [transaction-edit, currency-linked-edit, ocr-review, voice-input]

tech-stack:
  added: []
  patterns:
    - "confirmed-flag-after-await: a host sets a local confirmed=true inside AmountEditBottomSheet.onConfirm, awaits show(), then runs follow-up work only if confirmed — cleanly separates 'pressed action key' from 'swipe-dismiss'"

key-files:
  created: []
  modified:
    - lib/features/accounting/presentation/widgets/currency_linked_edit_fields.dart
    - lib/features/accounting/presentation/widgets/transaction_details_form.dart
    - lib/features/accounting/presentation/widgets/currency_edit_strings.dart
    - lib/features/accounting/presentation/screens/transaction_edit_screen.dart
    - test/features/accounting/presentation/edit_currency_linked_test.dart
    - test/widget/features/accounting/presentation/screens/transaction_edit_screen_amount_test.dart
    - test/golden/currency_linked_edit_fields_golden_test.dart
    - test/golden/goldens/currency_linked_edit_fields_usd.png
    - test/golden/goldens/currency_linked_edit_fields_usd_dark.png

key-decisions:
  - "rateDate is a required prop on CurrencyLinkedEditFields; the trigger label is DateFormatter.formatDate(rateDate, locale) using the already-resolved Localizations.localeOf(context) — no currentLocaleProvider needed inside the card"
  - "Reuse the existing _save() for keypad-save-equals-entry-save; never write a second submit path. The synchronous onConfirm (display + form-state write) runs before show() resolves, so _save() submits the up-to-date form state"
  - "Only the two edit-screen headline entry points (_editAmount + _editForeignAmount) gained save-on-confirm; OCR review and Voice input sheets keep pure write-back (zero regression)"
  - "CurrencyEditStrings.dateLabel removed (dead after change 1); the 'date' ARB key retained (still used by the date-chip row)"

patterns-established:
  - "confirmed-flag-after-await for separating action-key confirm from swipe-dismiss on a fire-and-forget modal sheet"

requirements-completed: [QUICK-260613-n5c]

duration: ~22min
completed: 2026-06-13
---

# Quick 260613-n5c: 外币编辑微调 Summary

**The foreign-currency edit screen now shows the transaction's actual date on the rate-date trigger (ja `2026/06/13`, en `06/13/2026`) and treats the keypad 保存/record key as a real whole-entry save (submit → success → pop true) for both JPY and foreign paths — OCR/Voice sheets unchanged.**

## Performance

- **Duration:** ~22 min
- **Tasks:** 3 completed
- **Files modified:** 9 (4 lib + 3 test + 2 golden PNGs)

## Accomplishments
- 改动1: `edit_date_change_trigger` label now renders the actual `rateDate` via `DateFormatter` (no refresh icon); D-02 dialog / D-03 toast tap behavior unchanged.
- 改动2: pressing the keypad action key on the edit screen now commits the whole transaction (reuses `_save()` → `Navigator.pop(true)`) for both `_editAmount` (JPY) and `_editForeignAmount` (foreign); swipe-dismiss does NOT save.
- Proved zero regression for OCR review + Voice input amount sheets (their `onConfirm` stays pure write-back).
- `flutter analyze` 0 issues; full `flutter test` green (2821 passed); two goldens re-baselined on macOS.

## Task Commits

1. **Task 1: Date-change trigger shows the actual rate date (改动1)** - `3af79040` (feat)
2. **Task 2: Edit-screen keypad 保存 saves the whole entry (改动2)** - `ce64a4d8` (feat)
3. **Task 3: Re-baseline goldens + full suite + analyze** - `08c87829` (test)

_Plan metadata (SUMMARY.md, STATE.md) committed separately by the orchestrator._

## Files Created/Modified
- `currency_linked_edit_fields.dart` - Added required `rateDate` field; trigger label is `DateFormatter.formatDate(widget.rateDate, locale)`; imports `DateFormatter`.
- `transaction_details_form.dart` - Passes `rateDate: _date` (seed.timestamp) into the card.
- `currency_edit_strings.dart` - Removed dead `dateLabel` getter (only that getter).
- `transaction_edit_screen.dart` - `_editAmount` + `_editForeignAmount` set a local `confirmed` flag inside `onConfirm`, then `if (confirmed && mounted) await _save();` after `show()` resolves.
- `edit_currency_linked_test.dart` - `pumpHost` takes `rateDate`; D-01 group pins the formatted date label (`06/13/2026`) and asserts the word `Date` is gone.
- `transaction_edit_screen_amount_test.dart` - Reshaped TEST 5 (foreign Save → use case called once with recomputed triple USD 20000 minor / ¥32051 + pop true); added TEST 6 (JPY record key saves) and TEST 7 (swipe-dismiss does not save); added `_SeededCategoryRepository` + `_savableOverrides` + `_EditScreenLauncher` route harness.
- `currency_linked_edit_fields_golden_test.dart` - `_wrap` passes `rateDate`; contract test pins `06/13/2026`.
- `currency_linked_edit_fields_usd.png` / `..._usd_dark.png` - Regenerated on macOS for the new date label.

## Verification
- 改动1: trigger renders `DateFormatter.formatDate(rateDate, locale)`; D-02/D-03 re-fetch tap behavior intact; no refresh icon; ADR-022 single-direction invariant untouched.
- 改动2: edit-screen action key → `_save()` → `updateTransactionUseCase.execute` called once + `pop(true)` (verified for both JPY and foreign paths); swipe-dismiss → no use-case call + screen still mounted.
- OCR (`ocr_review_screen_amount_test.dart`) + Voice (`voice_input_screen_test.dart`, `voice_input_screen_foreign_save_test.dart`) sheet tests pass unchanged — their confirm does not trigger an entry save.
- No new ARB key; `CurrencyEditStrings.dateLabel` removed; `"date"` ARB key retained.
- `flutter analyze`: No issues found. Full `flutter test`: 2821 passed (includes `hardcoded_cjk_ui_scan` and coverage gates).

## Deviations from Plan
None - plan executed exactly as written.

## Known Stubs
None.

## Self-Check: PASSED
- All modified lib/test files present on disk.
- Regenerated golden PNGs present.
- All three task commits found in git history (3af79040, ce64a4d8, 08c87829).
