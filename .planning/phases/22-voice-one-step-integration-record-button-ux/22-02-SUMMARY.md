---
phase: 22-voice-one-step-integration-record-button-ux
plan: 02
subsystem: ui
tags: [flutter, riverpod, widget-test, tdd, voice, transaction-form, public-mutator, satisfaction]

requires:
  - phase: 19-manual-one-step-keypad-polish
    provides: "TransactionDetailsFormState public surface (submit, updateAmount D-14 pattern) and ValueKey markers (merchant-textfield, note-textfield) on form fields"

provides:
  - "4 new public mutator methods on TransactionDetailsFormState — updateCategory(Category, Category?), updateMerchant(String), updateNote(String), updateSatisfaction(int)"
  - "Foundation for Wave 1 Plan 04 voice batch-fill: host VoiceInputScreen will call all 5 sibling setters (updateAmount + 4 new) via GlobalKey<TransactionDetailsFormState>.currentState on long-press release"
  - "RESEARCH §Open Q2 (BLOCKER B-1) resolved — updateSatisfaction(int) preserves the Phase 11 VoiceSatisfactionEstimator → soul-ledger satisfaction auto-fill pipeline through the Phase 22 single-screen rewrite (after Plan 04 deletes _navigateToConfirm)"

affects:
  - 22-04-voice-input-screen-single-screen (Wave 1: _stopRecordingAndCommit batch-fills via these setters)
  - 22-03 / 22-05 / 22-06 / 22-07 (any wave-1+ plan that touches TransactionDetailsForm host integration)

tech-stack:
  added: []
  patterns:
    - "Phase 19 D-14 updateAmount pattern extended to 4 sibling setters: !mounted guard + idempotency short-circuit on value equality + minimal state mutation (setState for build-driving fields, direct controller.text for TextField-backed fields)"
    - "Soul-ledger satisfaction wired through the public surface, bypassing the navigate-to-confirm screen handoff that Plan 04 will remove"

key-files:
  created: []
  modified:
    - "lib/features/accounting/presentation/widgets/transaction_details_form.dart (+63 LOC, 4 new public methods on TransactionDetailsFormState)"
    - "test/widget/features/accounting/presentation/widgets/transaction_details_form_test.dart (+712/-2 LOC, 10 new D-07 widget tests + 2 new fake repositories + extended _baseOverrides)"

key-decisions:
  - "Mirror Phase 19 D-14 updateAmount shape exactly (guards + idempotency + minimal state mutation) — zero behavior change for existing form users; the 4 new methods ride on existing internal state (no new fields)"
  - "updateNote is a v1.3 forward-compat no-op surface — voice parser does not emit a discrete note (RESEARCH §Assumptions A5); the method exists for parser-revision symmetry and to keep the 5-setter contract regular"
  - "updateSatisfaction added as the 4th sibling (Open Q2 resolution) — without it, Plan 04's deletion of _navigateToConfirm would orphan the Phase 11 audio-features → estimatedSatisfaction wiring"
  - "Test infrastructure extended in place (added _StubLedgerConfigRepository, _NoopMerchantCategoryPreferenceRepository, plus categoryServiceRepo / categoryServiceLedgerRepo / merchantCategoryLearningServiceProvider override knobs on _baseOverrides) — alternative would be a shared test helper extraction, but lightest touch is to grow the file in place since these fakes are local to the form-widget test surface"

patterns-established:
  - "5-method public-mutator surface for embedded form widgets driven by external orchestrators (host-owned UX, form-owned validation/persistence) — surface: submit + updateAmount + updateCategory + updateMerchant + updateNote + updateSatisfaction"
  - "Idempotency-via-listener-count test pattern for controller-backed setters: attach a ChangeNotifier listener, double-call the setter with the same value, assert listener fires exactly once"

requirements-completed: [INPUT-02]

duration: 12min
completed: 2026-05-25
---

# Phase 22 Plan 02: TransactionDetailsForm D-07 Public Setter Surface Summary

**4 new public mutator methods on TransactionDetailsFormState (updateCategory / updateMerchant / updateNote / updateSatisfaction) mirroring the Phase 19 D-14 updateAmount pattern, with 10 widget tests; lays the GlobalKey-driven batch-fill foundation for Wave 1 voice-screen integration and resolves RESEARCH Open Q2 (B-1).**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-05-25T04:46:00Z (approx)
- **Completed:** 2026-05-25T04:58:51Z
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments

- Added 4 sibling public mutators to `TransactionDetailsFormState`, growing the host-callable surface from 2 methods (`submit`, `updateAmount`) to 6. Each method matches the Phase 19 D-14 shape: `!mounted` guard, idempotency short-circuit on value equality, minimal state mutation (setState for build-driving fields, direct `controller.text` for TextField-backed fields).
- `updateCategory(Category, Category?)` mirrors the internal `_editCategory` write set (`_categoryById` cache warm for both category + parent, `_category` / `_parentCategory` assignment, `_resolveLedgerType` call) so behavior is identical regardless of whether the user taps the chevron or voice pushes a value.
- `updateSatisfaction(int)` resolves RESEARCH §Open Q2 (BLOCKER B-1): the Phase 11 `VoiceSatisfactionEstimator` → `_parseResult.estimatedSatisfaction` pipeline now has a public sink that survives Plan 04's deletion of `_navigateToConfirm` (the prior handoff was via the confirm-screen's `initialSatisfaction:` constructor arg).
- Added 10 widget tests in a new top-level `group('D-07 public setter surface (Phase 22)', ...)` block (3 each for updateCategory/updateMerchant/updateNote + 1 comprehensive test for updateSatisfaction covering mutation + picker rebuild + idempotency + submit round-trip).
- Extended existing test infrastructure with two small fakes (`_StubLedgerConfigRepository`, `_NoopMerchantCategoryPreferenceRepository`) and three new override knobs on `_baseOverrides`. Existing 8 widget tests in this file + 6 in `transaction_details_form_update_amount_test.dart` + 5 in `transaction_details_form_smoke_test.dart` continue to pass (29/29 across the three form-widget test files).

## Task Commits

Each task was committed atomically:

1. **Task 1: Add 4 D-07 public setters on TransactionDetailsFormState** — `6881ae2` (feat)
2. **Task 2: 10 widget tests for the new D-07 setters** — `7bedfc0` (test)

_Note: Plan 02 is `type: execute` (not `type: tdd` at the plan level), so the RED/GREEN gate sequence is not enforced. Task 2 (tests) was written after Task 1 (implementation) per the plan's explicit ordering — both tasks are marked `tdd="true"` at the task level but the plan deliberately splits implementation and tests into separate atomic commits._

## Files Created/Modified

- `lib/features/accounting/presentation/widgets/transaction_details_form.dart` — added 4 public mutator methods (`updateCategory`, `updateMerchant`, `updateNote`, `updateSatisfaction`) immediately after the existing `updateAmount` block. No existing method touched; surface is purely additive. (+63 LOC)
- `test/widget/features/accounting/presentation/widgets/transaction_details_form_test.dart` — added `D-07 public setter surface (Phase 22)` top-level group with 4 sub-groups and 10 tests; added `_StubLedgerConfigRepository` (for `_resolveLedgerType` coverage), `_NoopMerchantCategoryPreferenceRepository` (to absorb post-save merchant-learning hook), and 3 new override knobs (`categoryServiceRepo`, `categoryServiceLedgerRepo`, `merchantCategoryLearningServiceProvider`) on `_baseOverrides`. (+712/-2 LOC)

## Decisions Made

- **Idempotency strategy is value-equality, not deep-equality or identity.** `updateCategory` short-circuits on `category.id == _category?.id` (cheap O(1) string compare against the only field that drives the contract — the persisted FK). `updateMerchant`/`updateNote` short-circuit on `merchant == _<controller>.text`. `updateSatisfaction` short-circuits on integer equality. These guards prevent rebuild storms when the host fires repeatedly on the same value (e.g., voice batch-fill on a stable parse) AND preserve cursor position in the TextField cases (Pitfall 3).
- **`updateSatisfaction` is intentionally not gated by `_ledgerType == LedgerType.soul`.** Per the plan's spec: "Soul-ledger only — for survival-ledger categories the satisfaction field is not rendered; calling this method is harmless (state is still mutated but never read at submit() time)." This keeps the host-callable contract regular (host doesn't need to know which ledger is active when it dispatches the batch-fill) AND preserves the value across ledger toggles (so flipping back to soul restores the previously-pushed value).
- **`.clamp(1, 10)` matches the SatisfactionEmojiPicker's `_faceValues = [2, 4, 6, 8, 10]` and the initState's existing `initialSatisfaction.clamp(1, 10)` (form line 100).** Verified by reading the picker config in the build method — no duplicate or replacement satisfaction field was created.

## Deviations from Plan

None - plan executed exactly as written.

A few minor pre-existing test-infrastructure gaps surfaced during Task 2 (the existing `_baseOverrides` did not stub `merchantCategoryLearningServiceProvider`, which `submit()` invokes when the merchant text is non-empty). These were handled per the plan's explicit guidance to "reuse / extend test infrastructure" and are documented in the override-knob expansion. No scope creep.

## Issues Encountered

- **Initial test compile failure (Test 10 fixture builder):** the `Transaction.soulSatisfaction` field is non-null with `@Default(2)`, not nullable. The first version of my `fakeTx` helper used `int? soulSatisfaction` which failed type-checking. Fix: changed signature to `int soulSatisfaction = 2`. Resolved in the same Task 2 commit (no separate commit).
- **Initial Test 4 runtime failure (Riverpod ProviderException):** `submit()` calls `merchantCategoryLearningServiceProvider.recordSelection(...)` when the merchant text is non-empty, but the existing `_baseOverrides` only stubbed it implicitly via the orElse-throws pattern when not requested. Test 4 was the first test in the file to set a non-empty merchant AND submit, so the provider was actually exercised for the first time. Fix: added a no-op stub repo (`_NoopMerchantCategoryPreferenceRepository`) and overrode `merchantCategoryLearningServiceProvider` with a real `MerchantCategoryLearningService` instance wired to it. This is a forward-looking test-infrastructure improvement: any future widget test that exercises the merchant-fill submit path will now get the no-op behavior for free. Resolved in the same Task 2 commit.
- **Doc-comment lint info (`unintended_html_in_doc_comment`):** my header docstring used `<TransactionDetailsFormState>` (angle brackets), which dart lint flagged as info-level. Fix: wrapped the generic in backticks (`` `GlobalKey<TransactionDetailsFormState>` ``). Resolved in the same Task 2 commit.

## User Setup Required

None — pure code change; no environment variables, third-party services, or platform configuration touched.

## Next Phase Readiness

- **Wave 1 Plan 04 unblocked:** `_stopRecordingAndCommit()` on the rewritten voice screen can now call `_formKey.currentState!.updateAmount(...)`, `.updateCategory(...)`, `.updateMerchant(...)`, `.updateNote(...)`, `.updateSatisfaction(...)` in a single batch on long-press release. The form will absorb the batch-fill atomically (each setter has its own idempotency guard, so order does not matter and re-runs are cheap).
- **RESEARCH §Open Q2 (BLOCKER B-1) closed:** documented in the file-level `updateSatisfaction` docstring with explicit references to Phase 11 `VoiceSatisfactionEstimator` and the Plan 04 `_navigateToConfirm` deletion.
- **No carry-over concerns.** All 29 widget tests across the three form-widget test files green. `flutter analyze` clean on both touched files (the pre-existing voice_input_screen.dart:572 error noted in the plan's verification block is in a different file and out of scope for Plan 02).

## Self-Check: PASSED

- `lib/features/accounting/presentation/widgets/transaction_details_form.dart` — FOUND, contains all 4 new methods (`grep -c 'void updateCategory|Merchant|Note|Satisfaction'` returns 1 each)
- `test/widget/features/accounting/presentation/widgets/transaction_details_form_test.dart` — FOUND, contains `D-07 public setter surface (Phase 22)` group and 10 testWidgets entries
- Commit `6881ae2` (feat, Task 1) — FOUND in `git log --oneline`
- Commit `7bedfc0` (test, Task 2) — FOUND in `git log --oneline`
- `flutter analyze` (both touched files): 0 issues
- `flutter test ... --plain-name "D-07"`: 10/10 pass
- `flutter test` (all 3 form widget test files): 29/29 pass

---
*Phase: 22-voice-one-step-integration-record-button-ux*
*Plan: 02*
*Completed: 2026-05-25*
