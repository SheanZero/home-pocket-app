---
phase: 51-cross-validation-daily-joy-ledger-rework
plan: 03
subsystem: voice
tags: [flutter, voice, ptt, stt, hysteresis, resolve-on-final, tdd]

# Dependency graph
requires:
  - phase: 51-01
    provides: voice/domain VoiceParseResult relocation (the DTO the fill path consumes)
provides:
  - "Resolve-on-final category hysteresis in voice_ptt_session_mixin: partials fill amount/text/merchant/date live, category resolves once on the first end-of-speech final (no category-chip flicker)"
  - "fillCategory gate threaded through _fillFormFromText / _fillFormFromTextInner (default true; partial path passes false)"
affects: [51 LEDGER wave (final-category-drives-ledger), Phase 52 alternate-category chips, single-page voice entry]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Resolve-on-final hysteresis: a per-write gate (fillCategory) holds the category guess until the first isFinal, decoupled from the merger's 2.5s numeric amount window — no new timer (the existing isFinal signal is the single trigger)"

key-files:
  created: []
  modified:
    - lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart
    - test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart

key-decisions:
  - "Gated path skips the category repo lookup ENTIRELY for partials (not just the state.updateCategory call) — saves a repo read per partial; category/parent stay null so the existing `if (category != null) state.updateCategory(...)` branch is naturally a no-op when gated."
  - "Test observes the gate via the rendered category chip (find.textContaining('Cafe')) — held findsNothing across 3 partials, findsOneWidget after the final — plus pttLastFilledAmount==1840 + merchant 星巴克 during partials to prove the gate is category-scoped, not a blanket partial freeze. This matches the harness's existing rendered-widget observation style (no production spy hook added)."

patterns-established:
  - "fillCategory bool gate (default true) is the minimal per-write hysteresis lever: only the final/hold-release fills resolve category; partial-driven fills pass false."

requirements-completed: [XVAL-03]

# Metrics
duration: ~20min
completed: 2026-06-24
status: complete
---

# Phase 51 Plan 03: Resolve-on-Final Category Hysteresis (XVAL-03) Summary

**Gated the voice category fill to the first end-of-speech final via a `fillCategory` parameter so partials keep filling amount/text/merchant/date live (260622-nhs sub-second feedback preserved) while the category chip stops jittering across partials — no new timer (D-03), full suite 3284/3284 green.**

## Performance

- **Duration:** ~20 min active
- **Started:** 2026-06-24
- **Completed:** 2026-06-24
- **Tasks:** 2
- **Files modified:** 2 (1 production mixin + 1 test)

## Accomplishments
- Threaded `bool fillCategory = true` through `_fillFormFromText` and `_fillFormFromTextInner` in `voice_ptt_session_mixin.dart`. The default keeps every existing final / hold-release call site byte-unchanged (category resolves once, as today).
- The partial-driven fill (`_parseVoiceInput`, continuous tap session) now calls `_fillFormFromText(text, data: data, fillCategory: false)` — partials fill amount/text/merchant/date LIVE but skip the category repo lookup AND `state.updateCategory`, so the category chip is held until the first end-of-speech `isFinal` (D-01/D-02).
- D-03 honored: **no new Timer** added (`grep -c Timer` stays at 2 — the field decl + the existing `_parseDebounce` instantiation). The single isFinal signal drives the one category fill; the merger's 2.5s numeric-only amount window (`_amountMerger.feedChunk`) is untouched.
- Added a deterministic resolve-on-final no-flicker test (XVAL-03 Success Criterion 3): 3 partials then 1 final with the same category-bearing utterance assert the category chip is absent across partials, present after the final, while amount (1840) + merchant (星巴克) DID fill from the partials.

## Task Commits

Each task was committed atomically (TDD order — RED test first, GREEN gate second):

1. **Task 2 (RED): resolve-on-final no-flicker test** — `7ee2a741` (test)
2. **Task 1 (GREEN): gate category fill to the final-result path** — `567b7d3a` (feat)

_The no-flicker test was authored first and confirmed RED against the pre-gate code (the category chip appeared during partials, failing the `findsNothing` assertion). The gate then turned it GREEN. This is the standard RED→GREEN cycle for the plan's single behavior; the two plan tasks (gate + test) map onto it directly._

## Files Created/Modified
- `lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart` — `fillCategory` gate added to `_fillFormFromText`/`_fillFormFromTextInner`; the category resolve block (repo lookup) wrapped in `if (fillCategory)`; the partial path passes `fillCategory: false`.
- `test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart` — new `'resolve-on-final: category fills exactly once on the final result, never from partials (XVAL-03)'` test.

## Decisions Made
- **Skip the repo lookup for partials, not just the write:** when `fillCategory` is false the whole category-resolution block (the two `repo.findById` reads) is skipped, leaving `category`/`parent` null so the downstream `if (category != null) state.updateCategory(...)` branch is a natural no-op. This saves a category repo read per partial and keeps the diff minimal. Either approach was plan-sanctioned; this is the cheaper one.
- **Rendered-chip observation for the no-flicker assertion:** rather than adding a production spy hook, the test reuses the harness's established rendered-widget style — the category chip (`find.textContaining('Cafe')`) is `findsNothing` across 3 debounced partials and `findsOneWidget` after the final. `pttLastFilledAmount == 1840` and the rendered merchant `星巴克` during partials prove the gate is category-scoped (not a blanket partial freeze). With the form's `updateCategory` idempotency short-circuit, chip presence is a faithful once-only proxy.

## Deviations from Plan

None - plan executed exactly as written. The `fillCategory` gate, the partial-path `false` call site, the no-new-timer constraint, and the no-flicker test all landed as specified. No Rule 1-4 deviations were needed.

## Issues Encountered
None. The change is behavior-additive only on the category timing axis; all pre-existing mixin tests (including R4 BUG D's live partial-fill test, which only asserts merchant fill) stayed green, and the full suite went 3284/3284.

## Known Stubs
None — no hardcoded/placeholder values introduced. The gate is a real per-write conditional on live data.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- The category now resolves once on the final, decoupled from the amount window — the 51 LEDGER wave (ledger-from-final-category) and Phase 52 (alternate-category correction chips) build on a stable, non-flickering category resolve.
- No blockers.

## Verification Evidence
- `grep -c 'Timer' lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart` → `2` (unchanged from HEAD baseline — no new category timer, D-03).
- `flutter test test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart` → 20/20 pass (incl. the new XVAL-03 case).
- `flutter analyze` → `No issues found!` (0 issues).
- `flutter test` (full suite) → **3284/3284 All tests passed**.

## Self-Check: PASSED

Both modified files exist on disk; both task commits (`567b7d3a` feat, `7ee2a741` test) present in git history.

---
*Phase: 51-cross-validation-daily-joy-ledger-rework*
*Completed: 2026-06-24*
