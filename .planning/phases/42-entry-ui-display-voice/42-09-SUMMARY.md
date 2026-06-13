---
phase: 42-entry-ui-display-voice
plan: 09
subsystem: ui
tags: [flutter, riverpod, currency, edit-semantics, adr-022, i18n, snackbar, dialog]

requires:
  - phase: 42-01
    provides: edit_currency_linked_test.dart RED scaffold (CurrencyLinkedEditFields contract)
  - phase: 42-03
    provides: UpdateTransactionParams currency triple + validateCurrencyTriple (coalesce semantics, ADR-021 no-rehash)
  - phase: 42-04
    provides: VoiceParseResult.detectedCurrency
  - phase: 42-06
    provides: CurrencySelectorSheet + recent-currency provider
  - phase: 42-07
    provides: convertToJpy single-site + validateAppliedRate
provides:
  - CurrencyLinkedEditFields widget (ADR-022 D-01 two-input/one-derived edit host)
  - ChangeRateConfirmationDialog (ADR-022 D-02 two-choice, no default)
  - D-03 non-blocking undo SnackBar (5s) restoring the old rate
  - TransactionDetailsForm.updateCurrency / updateRate + foreign edit-host rendering + onForeignJpyChanged
  - Voice detectedCurrency surfacing on the shared form (VOICE-CUR-02/03)
  - ARB ja/zh/en edit-row labels, rate-validation, dialog, undo copy
affects: [42-verifier, edit-flow, multi-currency, voice-entry]

tech-stack:
  added: []
  patterns:
    - "Two-input/one-derived edit host: JPY is read-only, recomputed one-directionally via convertToJpy() (ADR-022 D-01) — no bidirectional loop"
    - "Null-safe localization resolver (CurrencyEditStrings) so delegate-less unit harnesses render while production stays fully localized"
    - "Gmail-style undo: non-blocking SnackBar + 5s SnackBarAction restoring prior state"

key-files:
  created:
    - lib/features/accounting/presentation/widgets/currency_linked_edit_fields.dart
    - lib/features/accounting/presentation/widgets/change_rate_confirmation_dialog.dart
    - lib/features/accounting/presentation/widgets/currency_edit_strings.dart
  modified:
    - lib/features/accounting/presentation/widgets/transaction_details_form.dart
    - lib/features/accounting/presentation/screens/transaction_edit_screen.dart
    - lib/features/accounting/presentation/screens/voice_input_screen.dart
    - lib/l10n/app_en.arb
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb

key-decisions:
  - "JPY row is read-only derived (ADR-022 D-01) — never an input; original × rate → JPY is the only data-flow direction"
  - "D-02/D-03 date-change semantics live inside CurrencyLinkedEditFields (it owns the original amount needed for the JPY delta)"
  - "Editing the rate field by hand marks the row as a manual override (drives D-02 vs D-03 on the next date change)"
  - "CurrencyEditStrings null-safe resolver added to honor the Wave-0 RED test's delegate-less harness without sacrificing i18n"

patterns-established:
  - "Two-input/one-derived: read-only derived value recomputed at a single conversion site, never written back"
  - "Foreign-row top AmountDisplay made read-only; edits routed through the form's linked rows"

requirements-completed: [DISP-03, DISP-04, VOICE-CUR-02, VOICE-CUR-03]

duration: 13min
completed: 2026-06-13
---

# Phase 42 Plan 09: Currency-Linked Edit Host Summary

**Two-input/one-derived foreign-currency edit host (ADR-022 D-01): original amount + rate editable, JPY read-only derived via single-site convertToJpy() — plus D-02 two-choice no-default dialog, D-03 non-blocking undo toast, and voice detectedCurrency surfacing.**

## Performance

- **Duration:** ~13 min
- **Started:** 2026-06-13T03:50:17Z
- **Completed:** 2026-06-13T04:03:23Z
- **Tasks:** 2
- **Files modified:** 9 (3 created, 6 modified; +4 generated l10n)

## Accomplishments
- `CurrencyLinkedEditFields` — three always-visible rows (original amount editable, rate editable/never-collapsed, JPY read-only derived). Exactly ONE data-flow direction (original × rate → JPY); JPY is never an input. Turns `edit_currency_linked_test.dart` GREEN (D-01/D-02/D-03, 4 tests).
- `ChangeRateConfirmationDialog` — ADR-022 D-02 `AlertDialog` with two affirmative actions and NO default (keep manual rate / re-fetch for new date).
- D-03 — non-blocking `SnackBar` + 5s `Undo` (restores the OLD rate), gated on `|new-old|/old > 0.01`.
- `TransactionDetailsForm` extended: seeds the foreign triple in `.edit`, renders the linked host for foreign rows, adds idempotent `updateCurrency`/`updateRate`, persists the triple in `$edit` submit (ADR-021 no rehash), and exposes `onForeignJpyChanged` so the screen's top display tracks the derived JPY.
- `transaction_edit_screen` — foreign rows make the top `AmountDisplay` read-only (no tap-to-edit, no clear); JPY-native rows byte-identical (CURR-04).
- Voice `detectedCurrency` surfaced on the shared form via `updateCurrency` in the voice batch-fill (VOICE-CUR-02/03).
- ARB ja/zh/en: three row labels, mandatory-rate + validation error, dialog labels, undo.

## Task Commits

Each task was committed atomically (TDD: RED gate `a53353bd test(42-01)` from Wave 0; GREEN here):

1. **Task 1: Edit-host three rows + updateCurrency/updateRate + voice surfacing** - `511c7ffa` (feat)
2. **Task 2: D-02 dialog + D-03 undo toast wiring + edit-screen routing** - `1d47847b` (feat)

## Files Created/Modified
- `lib/features/accounting/presentation/widgets/currency_linked_edit_fields.dart` - The ADR-022 D-01 two-input/one-derived host; owns D-02 dialog + D-03 undo SnackBar.
- `lib/features/accounting/presentation/widgets/change_rate_confirmation_dialog.dart` - D-02 two-choice AlertDialog (no default).
- `lib/features/accounting/presentation/widgets/currency_edit_strings.dart` - Null-safe l10n resolver for the edit widgets (delegate-less harness support).
- `lib/features/accounting/presentation/widgets/transaction_details_form.dart` - Foreign triple seeding, linked-host rendering, updateCurrency/updateRate, $edit triple persist, onForeignJpyChanged.
- `lib/features/accounting/presentation/screens/transaction_edit_screen.dart` - Foreign-row read-only top display; wires onForeignJpyChanged.
- `lib/features/accounting/presentation/screens/voice_input_screen.dart` - Surfaces detectedCurrency on the form.
- `lib/l10n/app_{en,ja,zh}.arb` - New edit-row / dialog / toast / validation keys.

## Decisions Made
- **JPY stays read-only derived (ADR-022 D-01).** The ROADMAP "three-field bidirectional" wording is void (circular-dependency risk). Implemented strictly as original × rate → JPY.
- **D-02/D-03 logic colocated in `CurrencyLinkedEditFields`.** The widget owns the original amount needed to compute the >1% JPY delta, and the RED test exercises both signals via the widget's built-in date-change trigger (no provider plumbing required for the unit contract). Production hosts can supply a real re-fetch rate via `dateChangeRefetchRate`; the threshold itself is never recomputed in arithmetic that would diverge from `convertToJpy`.
- **Hand-editing the rate flips manualOverride true** so the next date change routes to D-02 (dialog) rather than D-03 (silent recalculation), matching the ADR-022 override semantics.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Null-safe localization resolver for the delegate-less RED harness**
- **Found during:** Task 1 (edit-host GREEN)
- **Issue:** The Wave-0 RED test (`edit_currency_linked_test.dart`, authored by 42-01) pumps the widget inside a bare `MaterialApp` with NO `S` localization delegate. `S.of(context)` null-asserts (`Localizations.of<S>(context, S)!`) and threw during build, blocking GREEN. The test contract asserts only on the derived JPY value, dialog buttons, and undo toast — never on a localized label — so the widget must render without a hard `S` dependency at build time.
- **Fix:** Added `CurrencyEditStrings` (a small null-safe resolver: returns localized ja/zh/en when the delegate is present, stable English fallbacks otherwise). All three new widgets resolve copy through it. Production hosts always register `S.delegate`, so users only ever see localized copy.
- **Files modified:** lib/features/accounting/presentation/widgets/currency_edit_strings.dart (new), currency_linked_edit_fields.dart, change_rate_confirmation_dialog.dart
- **Verification:** `edit_currency_linked_test` GREEN (4 tests); `flutter analyze lib/` clean.
- **Committed in:** 511c7ffa (Task 1 commit)

**2. [Scope cleanup] Removed pre-existing unused-param warning**
- **Found during:** Task 1 (per plan notes: clean up the adjacent trivial warning)
- **Issue:** `test/infrastructure/voice/currency_detection_test.dart:38` declared an unused `{this.note}` optional parameter → `unused_element_parameter` warning (CLAUDE.md zero-warning policy).
- **Fix:** Dropped the unused `note` field/parameter.
- **Files modified:** test/infrastructure/voice/currency_detection_test.dart
- **Verification:** `flutter analyze` on the file → No issues found.
- **Committed in:** 511c7ffa (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 in-scope cleanup per plan notes)
**Impact on plan:** Both necessary; the null-safe resolver is the only way to satisfy the immutable RED-test contract while keeping i18n. No scope creep.

## Issues Encountered
- **Pre-existing arch-test failure (OUT OF SCOPE, deferred).** `provider_graph_hygiene_test.dart` HIGH-04 flags `recent_currency_provider.dart` (introduced by plan 42-06, predates this plan's first commit at `511c7ffa~1`). Not caused by 42-09. Logged to `deferred-items.md`; left untouched per SCOPE BOUNDARY. All other accounting / architecture / voice / linked-edit tests pass (93 accounting tests green; arb_key_parity green).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Foreign-row edit semantics (DISP-03/04, ADR-022 D-01/D-02/D-03) are complete and test-locked.
- Production wiring of a real date-change re-fetch rate (via `CurrencyLinkedEditFields.dateChangeRefetchRate` reading the rate use case's `RateResultWithSignal`) can be layered on without changing the widget's contract — the threshold is pre-computed by the use case and only rendered here.
- Verifier should confirm the JPY-native edit path remains byte-identical (CURR-04) and that the deferred provider-hygiene item is routed to a 42-06 follow-up.

---
*Phase: 42-entry-ui-display-voice*
*Completed: 2026-06-13*

## Self-Check: PASSED
- All created files verified on disk (currency_linked_edit_fields.dart, change_rate_confirmation_dialog.dart, currency_edit_strings.dart, SUMMARY, deferred-items).
- Both task commits verified in git history (511c7ffa, 1d47847b).
- `flutter analyze lib/` clean (0 issues); edit_currency_linked_test 4/4 GREEN; 93 accounting tests green.
