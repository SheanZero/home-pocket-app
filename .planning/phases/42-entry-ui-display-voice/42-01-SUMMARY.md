---
phase: 42-entry-ui-display-voice
plan: 01
subsystem: testing
tags: [flutter_test, mocktail, multi-currency, voice, tdd, wave-0, riverpod]

# Dependency graph
requires:
  - phase: 40-data-foundation-domain-sync
    provides: "CreateTransactionParams/Transaction foreign-currency triple (originalCurrency/originalAmount/appliedRate), convertToJpy() single conversion site"
  - phase: 41-exchange-rate-service
    provides: "RateResult sealed + GetExchangeRateUseCase (consumed by later edit/preview plans, not directly by these test scaffolds)"
provides:
  - "5 Wave 0 failing-test scaffolds locking Phase 42 acceptance criteria as executable contracts"
  - "SC-5 integration smoke (USD 50 @ 148.30 → amount=7415, full triple) as a GREEN regression guard"
  - "RED binding targets for plans 42-03 (update plumbing), 42-04 (voice currency), 42-05 (AmountInputController), 42-09 (edit-host)"
affects: [42-03, 42-04, 42-05, 42-09, currency, voice, edit-semantics]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Wave 0 RED scaffold: tests reference not-yet-existing symbols so later plans bind RED→GREEN"
    - "Top-of-file comment naming the producing plan for each scaffold"
    - "ParseVoiceInputUseCase + real VoiceTextParser + mocked resolver/merchantDB for voice corpus assertions"

key-files:
  created:
    - test/application/accounting/create_transaction_currency_test.dart
    - test/application/accounting/update_transaction_currency_test.dart
    - test/features/accounting/presentation/widgets/amount_input_controller_test.dart
    - test/infrastructure/voice/currency_detection_test.dart
    - test/features/accounting/presentation/edit_currency_linked_test.dart
  modified: []

key-decisions:
  - "create_transaction_currency_test is GREEN-on-arrival (Phase 40 shipped the create triple) — kept as a substantive SC-5 regression guard rather than fabricating a fake RED failure"
  - "Voice corpus asserts result.data!.detectedCurrency (non-existent getter) to drive compile-fail RED while exercising the real parse pipeline"
  - "AmountInputController surface (decimals/onDigit/onDot/onCurrencyChange/text) proposed in the test as the to-be-ratified contract for plan 42-05"

patterns-established:
  - "Each Wave 0 test file carries a header comment naming its producing plan and the locked decision it encodes"
  - "Truncation (D-08) asserted as a string op, not rounding (0.99→0, 50.50→50, 50.567→50.56)"

requirements-completed: []  # Wave 0 scaffolds — requirements CURR-05/DISP-04/VOICE-CUR-01/02/03 are turned GREEN by later plans, not satisfied here.

# Metrics
duration: ~18min
completed: 2026-06-13
---

# Phase 42 Plan 01: Wave 0 Test Scaffolding Summary

**Five failing-test scaffolds that lock Phase 42's multi-currency acceptance criteria (SC-5 7415 figure, D-07/D-08 decimal cap+truncation, zh/ja voice currency corpus, ADR-022 D-01/D-02/D-03 edit semantics) as executable RED contracts for plans 42-03/04/05/09.**

## Performance

- **Duration:** ~18 min
- **Started:** 2026-06-13
- **Completed:** 2026-06-13
- **Tasks:** 2
- **Files created:** 5

## Accomplishments
- SC-5 integration smoke locked as an executable assertion: USD 50 @ "148.30" → `amount=7415` with full foreign triple (GREEN regression guard; Phase 40 already implements the create path).
- UpdateTransaction foreign-row recompute + ADR-021 no-rehash invariant scaffolded RED (references not-yet-existing `UpdateTransactionParams` currency fields → compile-fail).
- D-07 decimal-cap + D-08 truncation boundaries (50.50→50, 0.99→0, 50.567→50.56) encoded against a proposed `AmountInputController` contract (RED).
- Voice currency detection corpus: ≥5 cases per currency per locale (zh USD/EUR/GBP/HKD/AUD/CAD; ja USD/EUR/GBP/HKD/AUD) + bare-token defaults + 元/円 ambiguity (D-08) + existing-corpus regression guard (RED via `VoiceParseResult.detectedCurrency`).
- ADR-022 edit semantics (D-01 two-input/one-derived, D-02 two-choice dialog, D-03 non-blocking undo toast) scaffolded RED against a proposed `CurrencyLinkedEditFields` widget.

## Task Commits

1. **Task 1: Application-layer currency smoke + update-plumbing tests** - `3f0ec3b5` (test)
2. **Task 2: AmountInputController + voice + edit-host scaffolds** - `a53353bd` (test)

_TDD plan: each task is a RED-only scaffold (no GREEN/REFACTOR here — those land in plans 42-03..42-09)._

## Files Created/Modified
- `test/application/accounting/create_transaction_currency_test.dart` - SC-5 integration smoke (7415) + partial-triple error. GREEN.
- `test/application/accounting/update_transaction_currency_test.dart` - foreign-row JPY recompute + ADR-021 no-rehash. RED (compile-fail on missing currency params).
- `test/features/accounting/presentation/widgets/amount_input_controller_test.dart` - D-07 cap + D-08 truncation. RED (missing `AmountInputController`).
- `test/infrastructure/voice/currency_detection_test.dart` - VOICE-CUR-01/02/03 corpus + bare-token/ambiguity + regression guard. RED (missing `detectedCurrency`).
- `test/features/accounting/presentation/edit_currency_linked_test.dart` - ADR-022 D-01/D-02/D-03. RED (missing `CurrencyLinkedEditFields`).

## Decisions Made
- **create_transaction_currency_test kept GREEN, not forced RED.** The plan's verify gate assumed this file would be RED, but Phase 40 already shipped the create-side foreign triple and the `convertToJpy()` conversion, so the SC-5 create path is already satisfiable. Fabricating a fake failure (asserting a non-existent symbol) would have been dishonest and would have weakened the file's value. Instead it stands as a substantive SC-5 regression guard locking the 7415 figure. The genuinely-RED half of the SC-5 plumbing — foreign-row *edit* recompute — lives in the companion `update_transaction_currency_test` (correctly RED).
- **Voice corpus uses the real `ParseVoiceInputUseCase` + real `VoiceTextParser`** (mocked resolver/merchant DB), so the corpus exercises the true amount-extraction pipeline; only `detectedCurrency` is the missing symbol that drives RED.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Faulty verify-gate premise] create_transaction_currency_test is GREEN-on-arrival**
- **Found during:** Task 1 (Application-layer currency smoke)
- **Issue:** The plan's `<automated>` verify gate for Task 1 asserts the create file must be RED ("UNEXPECTED GREEN/PASS — scaffold must be RED"). In reality the `CreateTransactionParams`/`Transaction` foreign triple and `convertToJpy()` already shipped in Phase 40, so the SC-5 create smoke passes. The RED premise was incorrect for this specific file.
- **Fix:** Did NOT weaken or fabricate the test (project rule + plan both forbid weakening assertions). Kept the substantive SC-5 assertions as a GREEN regression guard. The companion `update_transaction_currency_test` carries the genuinely-RED portion of SC-5 plumbing (foreign-row edit recompute), which compile-fails as intended.
- **Files modified:** test/application/accounting/create_transaction_currency_test.dart
- **Verification:** `flutter test` on the create file → `All tests passed!`; update file → `Compilation failed ... No named parameter 'originalCurrency'` (RED). Task 2 verify gate (voice detection RED) → RED-OK.
- **Committed in:** `3f0ec3b5` (Task 1 commit)

---

**Total deviations:** 1 (Rule 1 — faulty verify-gate premise handled without weakening assertions)
**Impact on plan:** No scope creep. All five files exist; four are RED (intended), one is GREEN-on-arrival as a legitimate SC-5 regression guard. The `must_haves` truth "Wave 0 failing tests exist for the SC-5 integration smoke" is met by the RED `update_transaction_currency_test` (the unimplemented half); the create half is locked GREEN.

## Issues Encountered
- The two Task 2 widget scaffolds (`amount_input_controller_test`, `edit_currency_linked_test`) reference library files that do not yet exist; Flutter reports `Error when reading 'lib/...': No such file or directory` plus `Method not found`. This is the intended compile-fail RED state, confirmed individually before commit.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- RED binding targets are in place for plans 42-03 (UpdateTransactionParams currency fields), 42-04 (`VoiceParseResult.detectedCurrency`), 42-05 (`AmountInputController`), 42-09 (`CurrencyLinkedEditFields`).
- Later plans MUST turn these RED files GREEN without weakening the locked figures (7415, truncation boundaries, ≥5-case voice corpus, ADR-022 D-01/D-02/D-03).
- Golden masters are intentionally NOT created here — they land alongside their producing plan (per plan objective and 42-VALIDATION.md Wave 0 list).
- The proposed `AmountInputController` and `CurrencyLinkedEditFields` surfaces are test-authored contracts; producing plans may rename symbols but must preserve the asserted behavior (or update these tests in the same plan that lands the implementation).

## Self-Check: PASSED

- Files: all 5 scaffolds FOUND on disk.
- Commits: `3f0ec3b5` and `a53353bd` FOUND in git history.
- RED state: 4 files compile-fail / fail as intended; `create_transaction_currency_test` GREEN as a documented regression guard.

---
*Phase: 42-entry-ui-display-voice*
*Completed: 2026-06-13*
