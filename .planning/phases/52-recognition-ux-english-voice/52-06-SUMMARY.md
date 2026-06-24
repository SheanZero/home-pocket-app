---
phase: 52-recognition-ux-english-voice
plan: 06
subsystem: testing-i18n-gate
tags: [anti-toxicity, adr-012, recux, arb-parity, golden, i18n, merge-gate, recux-04, recux-05]

# Dependency graph
requires:
  - phase: 52-02
    provides: "ConfidenceBandIndicator + AlternateCategoryChips + 2 trilingual ARB keys (recognitionBandSuggestedCategory / recognitionAlternatesMore)"
  - phase: 52-03
    provides: "Deferred category-correction surface on TransactionDetailsForm (chip-tap + full-selector correction paths)"
  - phase: 52-04
    provides: "VEN-01 trilingual category/merchant seeds (no new UI surface — data only)"
  - phase: 52-05
    provides: "VEN-02 English number-word fallback + voice-locale decoupling (no new UI surface — parser only)"
provides:
  - "anti_toxicity_phase52_test.dart — new-UI anti-toxicity sweep (band-strong / band-weak+chips / correction-open / manual-no-affordance / voice-panel) × {en,ja,zh} with the COMPLETE banned-token list (fixes v1.8 WR-02 incompleteness)"
  - "Banned-list integrity guard — asserts the v1.8 WR-02 tokens can never be silently shrunk out of the locked list"
  - "Verified merge-blocking close-out gate: ARB parity green, gen-l10n clean, no merchant names in ARB, no golden delta, full suite + analyze green"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "New-UI anti-toxicity sweep as a compile-and-test merge gate: pump each new surface × {en,ja,zh}, assert no forbidden substring renders; banned list is the verbatim prior-phase vocabulary EXTENDED, never shrunk"
    - "Locked-list integrity test: a separate assertion proves the COMPLETE WR-02 vocabulary is present in every locale list so a future edit cannot regress the list back to the v1.8 gap"
    - "Trilingual-meaningful fixtures: cat_* category ids (not category_* keys) so CategoryLocalizationService resolves real per-locale labels — the sweep exercises actual rendered copy, not raw keys"

key-files:
  created:
    - test/widget/features/accounting/presentation/widgets/anti_toxicity_phase52_test.dart
  modified: []

key-decisions:
  - "The five swept surfaces map to the two genuinely-new painted-text widgets (ConfidenceBandIndicator + AlternateCategoryChips): band paints no text (a11y-only Semantics), chips paint category labels + the exit-chip ARB label. Plans 04/05 added NO new voice-panel UI widget (data/parser only), so the 'voice-panel' state is the band+chips as they render at resolve-on-final alongside the existing record panel."
  - "Used cat_* ids (cat_food/cat_transport/cat_hobbies) NOT category_* ids — CategoryLocalizationService.resolveFromId only translates ids starting with cat_ (strips prefix → looks up locale map); category_* ids pass through unchanged and would render the raw key identically in all three locales, making the trilingual sweep meaningless. Added a coverage guard asserting the localized food label (Food/食費/食费) actually renders."
  - "Task 2 + Task 3 are verification-only gates with no working-tree changes: gen-l10n was already clean (52-02 committed current generated Dart), the ARB parity test already auto-covers the 2 new keys via its matching-key-set assertion, no golden references the new surfaces (no rebaseline needed), and git add -f lib/generated/ staged nothing (no stale generated Dart). The only artifact this plan commits is the new test file."

requirements-completed: [RECUX-04, RECUX-05]

# Metrics
duration: ~10min
completed: 2026-06-24
status: complete
---

# Phase 52 Plan 06: Trilingual Close-Out Gate (Anti-Toxicity Sweep + ARB Parity + Golden) Summary

**Runs the merge-blocking inline close-out gate for the recognition UX: a new-UI anti-toxicity sweep across band-strong / band-weak+chips / correction-open / manual-no-affordance / voice-panel × {en,ja,zh} with the COMPLETE banned-token list (fixing the v1.8 WR-02 incompleteness), confirms trilingual ARB parity (equal counts, no orphans, the 2 new recognition keys present, gen-l10n clean, no merchant names in ARB), and verifies the full suite + analyze are green — proving zero gamification leaks before merge, not deferred to milestone close (RECUX-04 / RECUX-05 / D-17).**

## Performance

- **Duration:** ~10 min
- **Completed:** 2026-06-24
- **Tasks:** 3 (1 artifact-producing + 2 verification gates)
- **Files:** 1 created, 0 modified

## Accomplishments

- **`anti_toxicity_phase52_test.dart`** (Task 1): a 21-test sweep covering the two genuinely-new painted-text recognition surfaces (`ConfidenceBandIndicator` + `AlternateCategoryChips`) across the five required states — band-strong (× daily/joy ledger families), band-weak+chips, correction-open (selected chip + exit chip), manual-no-affordance (D-10: band null → no band/chips render), and voice-panel (band+chips at resolve-on-final) — in each of en/ja/zh. The forbidden list is the **verbatim phase16/phase47 vocabulary** EXTENDED with the COMPLETE v1.8-WR-02 tokens (`score`, `streak`, `accuracy`, `正确率`, `連続`, `ストリーク`, `達成`) plus the UI-SPEC §Copywriting tokens (`badge`/`leaderboard`/`achievement` / `达成`/`连胜`/`徽章`/`排行榜` / `正解率`/`連勝`/`バッジ`). A separate **banned-list integrity guard** asserts the WR-02 tokens are present in every locale list so the list can never be silently shrunk back to the v1.8 gap. Fixtures use `cat_*` ids so chips resolve real trilingual labels (coverage-guarded on the localized "Food"/"食費"/"食费" label + the always-built exit chip).
- **ARB parity gate** (Task 2): `flutter gen-l10n` clean (no working-tree change), `arb_key_parity_test.dart` green (equal normal+metadata key sets across en/ja/zh — auto-covers the 2 new recognition keys via its matching-key-set assertion), both `recognitionBandSuggestedCategory` + `recognitionAlternatesMore` confirmed present in all three ARB files, and **no merchant names in ARB** (RECUX-05 — merchant proper-nouns stay encrypted Drift DATA columns). No golden references the new band/chips/correction surfaces, so **no golden rebaseline was needed** (the 202-test golden suite passed unchanged) and `git add -f lib/generated/` staged nothing (no stale generated Dart).
- **Full-suite phase gate** (Task 3): `flutter analyze` → **0 issues**; the FULL `flutter test` suite → **3352 tests, all green** (including arb_key_parity, anti_toxicity_phase52, the synonyms coverage tests, the voice_text_parser isolation test, and stale_suppressions_scan).

## Task Commits

1. **Task 1: anti_toxicity_phase52_test.dart — new-UI sweep, COMPLETE banned list** — `35ac551a` (test)
   - 21 tests; banned-list integrity guard; cat_* trilingual fixtures + coverage guards
   - Includes the Rule-1 auto-fix below (removed an unnecessary `ignore_for_file` directive that tripped `stale_suppressions_scan`)

_Tasks 2 and 3 are verification-only gates and produced no working-tree changes (gen-l10n clean, parity test already covers the new keys, no golden delta, no stale generated Dart) — there is nothing to commit for them beyond the Task 1 artifact._

## Files Created/Modified

- `test/widget/features/accounting/presentation/widgets/anti_toxicity_phase52_test.dart` (created) — 21-test new-UI anti-toxicity sweep with the COMPLETE banned list + locked-list integrity guard + trilingual coverage guards.

## Decisions Made

- The five swept surfaces map onto the two genuinely-new painted-text widgets. The band paints zero text (a11y-only `Semantics`); the chips paint category labels + the exit-chip ARB label. Plans 04/05 added no new voice-panel UI widget (data seeds + number parser only), so the "voice-panel" state is exercised as the band+chips rendering alongside the existing (unchanged) record panel at resolve-on-final.
- Used `cat_*` category ids rather than `category_*` keys so `CategoryLocalizationService.resolveFromId` resolves real per-locale labels (it only translates ids prefixed `cat_`); `category_*` ids pass through unchanged and would render identical raw keys in all three locales, defeating the trilingual sweep. A coverage guard asserts the localized food label actually renders.
- Tasks 2/3 are pure gates: the existing `arb_key_parity_test` already enforces that any en key exists in ja/zh (auto-covering the 2 new keys), gen-l10n produced no diff (52-02 committed current generated Dart), and no golden pumps the new surfaces — so no parity edit, no gen-l10n commit, and no golden rebaseline were required.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Blocking issue] Removed an unapproved `ignore_for_file` directive**
- **Found during:** Task 3 (full-suite gate)
- **Issue:** The initial Task 1 test file carried `// ignore_for_file: lines_longer_than_80_chars`, which `test/architecture/stale_suppressions_scan_test.dart` flagged as an unapproved suppression (it is not on the explicit allow list). This was the only full-suite failure.
- **Fix:** Removed the directive. The suppressed lint was not actually configured in this repo (the reference phase16/phase47 tests carry 100-char import lines with no suppression and pass), so the directive was unnecessary. Re-ran analyze (0 issues), the stale-suppressions scan (green), and the sweep (21 green).
- **Files modified:** `anti_toxicity_phase52_test.dart`
- **Commit:** `35ac551a` (amended into the Task 1 commit, since the fix is to the same just-created file)

## Self-Check: PASSED

- `test/widget/features/accounting/presentation/widgets/anti_toxicity_phase52_test.dart` exists on disk.
- Task 1 commit `35ac551a` present in git history.
- `flutter analyze` → 0 issues; FULL `flutter test` → 3352/3352 green.
- `flutter gen-l10n` clean; `arb_key_parity_test` green; both new keys present in en/ja/zh; no merchant names in ARB; golden suite (202) green with no rebaseline; `git add -f lib/generated/` staged nothing (no stale generated Dart); `git status` clean.

---
*Phase: 52-recognition-ux-english-voice*
*Completed: 2026-06-24*
