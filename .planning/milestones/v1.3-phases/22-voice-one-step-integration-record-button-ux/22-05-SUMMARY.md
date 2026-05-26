---
phase: 22
plan: 05
slug: voice-one-step-integration-record-button-ux
subsystem: testing
status: complete
wave: 2
tags: [flutter, voice, widget-test, golden-test, hold-to-record, regression-test]

requires:
  - phase: 22-voice-one-step-integration-record-button-ux
    plan: 04
    provides: "ValueKey('voice-mic-button') + ValueKey('voice-save-button') stable anchors; hold-to-record gesture surface; AnimatedSwitcher caption swap; AnimatedContainer mic morph 36 ↔ 16"

provides:
  - "test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart — major rewrite; 8 new Phase 22 behavior tests (REC-01 caption + misfire, REC-02 visual + timing, INPUT-02 SC-1 + D-08 + D-09) + 2 preserved permission tests = 10/10 green"
  - "test/widget/features/accounting/presentation/screens/voice_input_screen_mic_button_golden_test.dart — new D-12 / SC-4 golden harness (1×1 ja/light matrix, scoped via find.byKey('voice-mic-button'))"
  - "test/widget/features/accounting/presentation/screens/goldens/voice_input_screen_mic_button_idle.png — generated baseline (23,233 bytes, 390×844 surface)"
  - "FakeCategoryLedgerConfigRepository fixture (returns survival LedgerType for every id) — enables real CategoryService wiring during voice batch fill"

affects:
  - "test/widget/features/accounting/presentation/screens/voice_to_manual_one_step_screen_test.dart — DELETED (Phase 19 D-16 regression test for the push that Plan 04 removed via D-02)"

tech-stack:
  added: []
  patterns:
    - "tester.startGesture + pump(Duration(ms:1)) — advances test fake-clock past the LongPressGestureRecognizer(duration: Duration.zero) timer so onLongPressStart fires; second pump settles microtasks so onResult is wired before emitFinal"
    - "tester.binding.runAsync + Future.delayed(350ms) — elapses REAL wall-clock past the 300 ms misfire threshold; necessary because _onLongPressEnd reads DateTime.now() which doesn't respect the test fake-clock"
    - "AnimatedContainer decoration introspection (tester.widget<AnimatedContainer>(finder).decoration as BoxDecoration) — asserts the TARGET decoration values directly without waiting for the 180 ms interpolation"
    - "1×1 golden matrix per D-12 — collapses the SmartKeyboard 6-image template to a single ja/light asset since the mic button visual is i18n- and theme-insensitive"
    - "find.byKey(const ValueKey('voice-mic-button')) for gesture finders (H-6) — NOT find.byIcon(Icons.mic); the RawGestureDetector hit area lives on the AnimatedContainer, not on the child Icon"

key-files:
  created:
    - "test/widget/features/accounting/presentation/screens/voice_input_screen_mic_button_golden_test.dart (132 LOC)"
    - "test/widget/features/accounting/presentation/screens/goldens/voice_input_screen_mic_button_idle.png (23,233 bytes)"
    - ".planning/phases/22-voice-one-step-integration-record-button-ux/deferred-items.md (20 LOC)"
  modified:
    - "test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart (417 → 756 LOC; +471 / -132)"
  deleted:
    - "test/widget/features/accounting/presentation/screens/voice_to_manual_one_step_screen_test.dart (555 LOC; 4 tests obsolete after D-02 push removal)"

key-decisions:
  - "Real-time runAsync over fake-clock pump for the 300 ms misfire boundary. _onLongPressEnd computes held duration via DateTime.now() (wall-clock). `tester.pump(Duration(ms:400))` only advances fake time, so the held delta stays ~0 ms in tests → discard path fires unconditionally. tester.binding.runAsync(() => Future.delayed(350ms)) elapses real wall-clock, routing release to _stopRecordingAndCommit instead. Production unchanged."
  - "Reuse permission-toast tests verbatim from pre-Plan-22 file. Plan 04 SUMMARY confirms the 2 permission tests (Japanese + English) continued to pass after the rewrite — the denied-init path is orthogonal to the body rewrite. Keeping them preserves coverage parity."
  - "Real CategoryService over a Mock surface. The form widget's _resolveLedgerType reads categoryServiceProvider, then awaits service.resolveLedgerType(id). A mock-based override would require mocktail Fake + stub setup per category id — verbose and fragile across the D-08 and SC-1 tests. Constructing a real CategoryService with FakeCategoryRepository + FakeCategoryLedgerConfigRepository (the latter returns LedgerType.survival for every id) is cheaper and tighter."
  - "Golden test reuses fixtures via cross-file 'show' clause. voice_input_screen_mic_button_golden_test.dart imports FakeStartSpeechRecognitionUseCase + FakeCategoryRepository + FakeCategoryLedgerConfigRepository from voice_input_screen_test.dart. No fixture duplication; the golden file remains a thin harness scoped to the mic-button subtree."
  - "1×1 golden matrix (D-12) — single locale (ja) × single theme (light). The voice mic button gradient + shape + Icons.mic are i18n- and theme-insensitive; the locale-sensitive caption sits OUTSIDE the voice-mic-button subtree this golden scopes to. Expanding to 3×2 would inflate disk + CI without catching additional regressions."
  - "Cleanup-path release (after the in-hold assertion) uses fake-clock pump(400ms) intentionally. The cleanup release lands in the discard path (held real-time ~0 ms), which is harmless — it just tears down the gesture recognizer and returns the screen to idle. The assertion under test ran while the gesture was active, so the discard-vs-commit cleanup distinction is irrelevant."

metrics:
  duration: "~40 min"
  tasks_completed: 4
  files_created: 3
  files_modified: 1
  files_deleted: 1
  net_loc_delta: "+46 (+471 widget rewrite -132 old asserts +132 golden +20 deferred +0 PNG asset -555 deleted regression)"
  test_count_delta: "+5 (8 new widget + 1 new golden = 9 added; 4 deleted = 4 removed; net +5)"
  completed_at: "2026-05-25T06:00:00Z"

requirements-completed: [INPUT-02, REC-01, REC-02]
---

# Phase 22 Plan 05: Voice Screen Test Coverage Rewrite Summary

Closes the widget-test gap left by Wave 1. Rewrites the obsolete `voice_input_screen_test.dart` assertions against Plan 04's new hold-to-record + embedded-form behavior, adds 8 new behavior tests + 1 idle-state golden, deletes the Phase 19 D-16 regression test whose flow no longer exists. All voice-surface tests green; pre-existing HomeHeroCard failures logged as out-of-scope deferred items.

## Performance

- **Duration:** ~40 min
- **Started:** 2026-05-25T05:20:00Z
- **Completed:** 2026-05-25T06:00:00Z
- **Tasks:** 4/4
- **Files created:** 3 (golden test file + PNG baseline + deferred-items log)
- **Files modified:** 1 (`voice_input_screen_test.dart` major rewrite)
- **Files deleted:** 1 (`voice_to_manual_one_step_screen_test.dart`)
- **Test count delta:** +5 net (9 added — 8 widget + 1 golden — minus 4 deleted)

## Accomplishments

- Rewrote `voice_input_screen_test.dart` (417 → 756 LOC) with a top-level `Phase 22 — voice screen body rewrite` group containing 8 new `testWidgets` blocks: REC-01 idle caption + recording caption + misfire, REC-02 visual diff + 100 ms timing, INPUT-02 SC-1 happy path + D-08 overwrite + D-09 focus interrupts. All 10 tests in the file (8 new + 2 preserved permission) pass; analyzer clean.
- Preserved the 3 speech-service fakes (`FakeStartSpeechRecognitionUseCase`, `FakeDeniedStartSpeechRecognitionUseCase`, `CapturingStartSpeechRecognitionUseCase`) + `FakeParseVoiceInputUseCase` + `FakeVoiceSatisfactionEstimator` + `FakeCategoryRepository` verbatim — they remain the right fixtures. Extended `FakeCategoryRepository` with `cat_food` + `cat_food_cafe` entries for SC-1.
- Added `FakeCategoryLedgerConfigRepository` (returns `LedgerType.survival` config for every id) so a real `CategoryService` can be constructed and overridden into `categoryServiceProvider`. This satisfies `TransactionDetailsFormState._resolveLedgerType` (called inside `updateCategory`) during voice batch-fill.
- Created `voice_input_screen_mic_button_golden_test.dart` (132 LOC) — D-12 / SC-4 golden harness with a 1×1 ja/light matrix. Uses `find.byKey(const ValueKey('voice-mic-button'))` to scope the golden to the AnimatedContainer subtree. Generated baseline PNG (23,233 bytes, 390×844 surface) via `flutter test --update-goldens`; subsequent runs without the flag confirm zero pixel diff.
- Deleted `voice_to_manual_one_step_screen_test.dart` (555 LOC, 4 testWidgets blocks). All four tests asserted the `VoiceInputScreen → ManualOneStepScreen` push that Plan 04 D-02 removed; coverage is fully subsumed by Plan 05 Task 1 (single-screen batch fill) + Plan 06 (integration test for `entry_source='voice'`).
- Implemented the H-6 finder-consistency rule: every gesture finder uses `find.byKey(const ValueKey('voice-mic-button'))`, NOT `find.byIcon(Icons.mic)`. The Icon is a child of the AnimatedContainer; the RawGestureDetector wraps the AnimatedContainer.
- Implemented the H-3 visual-introspection rule: the REC-02 visual test reads `AnimatedContainer.decoration` directly (the widget's target value, not the painted interpolation). For painted-pixel verification, the golden test in Task 2 is the canonical assertion path.
- Logged 15 pre-existing test failures (HomeHeroCard goldens + widget tests) to `deferred-items.md` per the SCOPE BOUNDARY rule — they predate Phase 22 (last touched by feat 14-02/14-03) and have no voice surface dependency.

## Task Commits

| Task | Name                                                           | Commit  | LOC delta            |
| ---- | -------------------------------------------------------------- | ------- | -------------------- |
| 1    | Rewrite voice_input_screen_test for Phase 22 hold-to-record body | afdfb55 | +471 / -132          |
| 2    | Add idle mic button golden (D-12, SC-4 visual baseline)        | da3fe39 | +110 (test + PNG)    |
| 3    | Delete obsolete Phase 19 D-16 voice→manual regression test     | ee601ef | -555                 |
| 4    | Log Plan 22-05 quality-gate findings (deferred-items.md)       | 6a0f740 | +20                  |

## Files Created / Modified / Deleted

### Created
- `test/widget/features/accounting/presentation/screens/voice_input_screen_mic_button_golden_test.dart` — Phase 22 / D-12 / SC-4 golden harness (132 LOC).
- `test/widget/features/accounting/presentation/screens/goldens/voice_input_screen_mic_button_idle.png` — golden baseline asset (23,233 bytes, 390×844 surface, ja/light).
- `.planning/phases/22-voice-one-step-integration-record-button-ux/deferred-items.md` — out-of-scope failure log (20 LOC).

### Modified
- `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` — major rewrite (417 → 756 LOC). 8 new Phase 22 behavior tests added under a top-level group; 4 obsolete VoiceRecognitionResultCard assertions stripped; 2 permission tests preserved verbatim; 1 new fixture class (`FakeCategoryLedgerConfigRepository`) added; `FakeCategoryRepository` extended with 2 new category entries; `buildSubject` extended with `categoryServiceProvider` override.

### Deleted
- `test/widget/features/accounting/presentation/screens/voice_to_manual_one_step_screen_test.dart` (555 LOC) — Phase 19 D-16 regression test for the voice → manual push that Plan 04 D-02 removed.

## Decisions Made

- **Real-time `runAsync` over fake-clock `pump` for the 300 ms misfire boundary.** Production code computes `held = DateTime.now().difference(_pressStart!)` — that uses real wall-clock, not the Flutter test fake-clock. So `tester.pump(Duration(ms:400))` advances fake time but `held` stays ≈0 ms → release always routes to discard. The D-08 and SC-1 tests need the commit path; they use `tester.binding.runAsync(() => Future.delayed(350ms))` to elapse real wall-clock past the threshold. Production unchanged.
- **Real `CategoryService` over a Mock surface.** The form's `_resolveLedgerType` reads `categoryServiceProvider`. A mock-based override would require mocktail `Fake` + per-category-id stubs. Constructing a real `CategoryService` from `FakeCategoryRepository` + `FakeCategoryLedgerConfigRepository` (the latter returns survival for every id) is cheaper and matches the production resolution path.
- **Cleanup-path release intentionally uses fake-clock `pump`.** Tests that assert during the active hold (REC-01 recording caption, REC-02 visual, REC-02 timing) follow up with `pump(Duration(ms:400))` + `gesture.up()` for cleanup. The release lands in the discard path (held real-time ~0 ms), which is harmless because the assertion already happened. No need to use `runAsync` for cleanup.
- **1×1 golden matrix per D-12.** Voice mic button visual is i18n- and theme-insensitive; the only locale-sensitive element (caption) is OUTSIDE the `voice-mic-button` subtree the golden scopes to. Expanding to 3×2 (ja/zh/en × light/dark) would inflate the asset footprint without catching additional regressions.
- **`textContaining('Cafe')` instead of `text('Cafe')` for the SC-1 category assertion.** The form renders the L1>L2 path via `formatCategoryPath` — for our fake categories it produces `'Food > Cafe'`, not a bare `'Cafe'`. Using `textContaining` keeps the assertion robust to the exact path format while still verifying the L2 category landed.

## Deviations from Plan

**1. [Rule 3 — Blocker] Added `FakeCategoryLedgerConfigRepository` + `categoryServiceProvider` override**

- **Found during:** Task 1, first run of D-08 / SC-1 tests
- **Issue:** Plan body's `buildSubject` overrode only `categoryRepositoryProvider`. Voice batch-fill calls `_formKey.currentState!.updateCategory(...)`, which inside the form triggers `_resolveLedgerType` → `ref.read(categoryServiceProvider)` → throws `ProviderException` because the real provider tries to look up `categoryLedgerConfigRepositoryProvider` which has no override. The throw aborted the batch-fill before the host-cache mirror was updated.
- **Fix:** Added a `FakeCategoryLedgerConfigRepository` class that returns a survival-ledger `CategoryLedgerConfig` for every requested id. Constructed a real `CategoryService` from this + the existing `FakeCategoryRepository` and overrode `categoryServiceProvider` with the instance. Mirrors the pattern the deleted `voice_to_manual_one_step_screen_test.dart` used (`when(() => mockCategoryService.resolveLedgerType(any())).thenAnswer((_) async => LedgerType.soul)`).
- **Files modified:** `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart`
- **Commit:** afdfb55 (Task 1)

**2. [Rule 3 — Blocker] Real-time `runAsync` pump past the 300 ms misfire threshold**

- **Found during:** Task 1, second run of D-08 / SC-1 tests (after fix #1)
- **Issue:** Plan body used `tester.pump(Duration(ms:400))` between `emitFinal` and `gesture.up()`, expecting the held duration to exceed 300 ms so `_onLongPressEnd` routes to `_stopRecordingAndCommit`. But the production code reads `DateTime.now()` which doesn't honor the test fake-clock — `held` was ≈0 ms in tests → release routed to `_cancelRecordingAndDiscard` → no batch fill. Confirmed via debug print: `speech.stopped=false speech.canceled=true`.
- **Fix:** Used `await tester.binding.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 350)))` for the D-08 and SC-1 commit-path tests. This elapses real wall-clock past the threshold. Cleanup paths in other tests (where the assertion already happened during the hold) keep the fake-clock `pump(400ms)` since the discard cleanup is harmless.
- **Files modified:** `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart`
- **Commit:** afdfb55 (Task 1)

**3. [Rule 3 — Blocker] Pump `Duration(milliseconds: 1)` after `startGesture` instead of bare `pump()`**

- **Found during:** Task 1, REC-02 visual + D-08 + SC-1 tests
- **Issue:** Plan body used `await tester.pump()` (zero duration) after `tester.startGesture`. `LongPressGestureRecognizer(duration: Duration.zero)` schedules a `Timer(Duration.zero)` to fire `onLongPressStart`; the timer only fires when the test fake-clock advances past zero duration. A bare `pump()` doesn't advance the clock, so `_isRecording` stayed false. Verified via debug print: `speechService.startedLocaleId=null`.
- **Fix:** Replaced the bare `pump()` with `pump(Duration(milliseconds: 1))` then a second `pump()` to settle microtasks. The 1 ms is sufficient to advance past the `Timer(Duration.zero)` deadline. This matches the implicit pattern in the REC-01 recording caption test (which pumped `Duration(ms:200)` after `startGesture` and worked).
- **Files modified:** `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart`
- **Commit:** afdfb55 (Task 1)

**4. [Cosmetic] Asserted `textContaining('Cafe')` instead of `text('Cafe')` for SC-1**

- **Found during:** Task 1, after Tasks 1.1-1.3 fixes landed
- **Issue:** The form renders the category chip via `formatCategoryPath` which produces `'Food > Cafe'` (parent > child) when both exist. Bare `find.text('Cafe')` didn't match the composite string.
- **Fix:** Used `find.textContaining('Cafe')` — keeps the assertion robust to the exact path format while verifying the L2 category landed.
- **Files modified:** `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart`
- **Commit:** afdfb55 (Task 1)

## Issues Encountered

- **`flutter test` shows 15 pre-existing failures in HomeHeroCard widget + golden tests** — completely unrelated to the voice screen. Logged to `deferred-items.md`. Voice-surface tests (11/11) all pass.
- **`flutter analyze` reports 4 pre-existing issues** in Firebase Messaging build cache + `category_selection_screen.dart` deprecated `onReorder`. All pre-existing per Plan 04 SUMMARY. Zero issues in the voice surface or the new test files.
- **The `Iconography_idle.png` golden was generated on Apple Silicon (M1/M2)** at 390×844 surface. CI machines on other architectures may produce subtly different anti-aliased pixels; if CI golden diffs appear, regenerate with `--update-goldens` on the CI runner.

## Test Coverage Verification

**`flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart test/widget/features/accounting/presentation/screens/voice_input_screen_mic_button_golden_test.dart` — 11/11 pass:**

| File                                                | Group / Test                                                                                      | Status |
| --------------------------------------------------- | ------------------------------------------------------------------------------------------------- | ------ |
| voice_input_screen_test.dart                        | shows Japanese localized microphone permission toast                                              | PASS   |
| voice_input_screen_test.dart                        | shows English localized microphone permission toast                                               | PASS   |
| voice_input_screen_test.dart                        | Phase 22 — REC-01 idle caption: holdToRecord is visible before recording                          | PASS   |
| voice_input_screen_test.dart                        | Phase 22 — REC-01 recording caption: caption swaps to "録音中…" on long-press start              | PASS   |
| voice_input_screen_test.dart                        | Phase 22 — REC-01 misfire: hold < 300ms cancels recording without parser invocation               | PASS   |
| voice_input_screen_test.dart                        | Phase 22 — REC-02 visual: BoxDecoration borderRadius transitions 36 → 16 on recording             | PASS   |
| voice_input_screen_test.dart                        | Phase 22 — REC-02 timing: caption swap completes within 100 ms of onLongPressStart                | PASS   |
| voice_input_screen_test.dart                        | Phase 22 — INPUT-02 D-08: voice batch fill always overwrites pre-filled form values               | PASS   |
| voice_input_screen_test.dart                        | Phase 22 — INPUT-02 D-09: text-field focus during recording auto-stops without batch fill         | PASS   |
| voice_input_screen_test.dart                        | Phase 22 — INPUT-02 SC-1: voice transcript "1千8百4十元 星巴克" fills form fields                | PASS   |
| voice_input_screen_mic_button_golden_test.dart      | Phase 22 — idle mic button (ja, light) matches golden baseline                                    | PASS   |

## VALIDATION.md Cross-Link

| VALIDATION row                                            | Test that closes it                                                              |
| --------------------------------------------------------- | -------------------------------------------------------------------------------- |
| REC-01 SC-3 caption (idle text visible)                   | voice_input_screen_test.dart — `REC-01 idle caption`                             |
| REC-01 SC-3 caption (recording text on hold)              | voice_input_screen_test.dart — `REC-01 recording caption`                        |
| REC-01 SC-3 misfire (< 300 ms hold = cancel)              | voice_input_screen_test.dart — `REC-01 misfire`                                  |
| REC-02 SC-4 visual diff (borderRadius 36 → 16)            | voice_input_screen_test.dart — `REC-02 visual`                                   |
| REC-02 SC-4 visual baseline (idle pixel snapshot)         | voice_input_screen_mic_button_golden_test.dart — `idle mic button (ja, light)`   |
| REC-02 SC-4 timing (< 100 ms from press to caption swap)  | voice_input_screen_test.dart — `REC-02 timing`                                   |
| INPUT-02 D-08 overwrite (voice replaces pre-filled amount)| voice_input_screen_test.dart — `INPUT-02 D-08 overwrite`                         |
| INPUT-02 D-09 focus interrupts (TextField focus → cancel) | voice_input_screen_test.dart — `INPUT-02 D-09`                                   |
| INPUT-02 SC-1 happy path (batch fill amount + merchant + category) | voice_input_screen_test.dart — `INPUT-02 SC-1`                          |

SC-2 (DAO `entry_source = 'voice'`) is owned by Plan 06 — out of scope for Plan 05.

## User Setup Required

None — pure test code change. No environment variables, third-party services, or platform configuration touched. No new packages installed.

## Next Phase Readiness

- **Plan 06 (integration test) unblocked.** The `voice_save_entry_source_test.dart` Plan 06 will create can rely on the same stable test anchors: `ValueKey('voice-mic-button')` for the gesture trigger and `ValueKey('voice-save-button')` for the Save tap. The `runAsync` real-time pattern used here is the right model for Plan 06's full save flow.
- **Wave 2 complete on the unit/widget test side.** Only outstanding test work is Plan 06's integration test.
- **No carry-over concerns to Plan 06.** All voice-screen widget tests are green; the misfire / commit / discard paths all have asserted coverage; the golden baseline is committed.

## Known Stubs

None. All voice-screen tests assert real production behavior:
- The hold-to-record gesture is exercised through the real `RawGestureDetector` + `LongPressGestureRecognizer` surface.
- The batch fill exercises the real `_stopRecordingAndCommit` → `parseUseCase.execute` → `state.updateXxx` setter pipeline.
- The form widget runs `_resolveLedgerType` through a real `CategoryService` instance (built on fake repositories).
- The golden asserts the actual rendered mic button pixels.

No "coming soon" / placeholder text; no hardcoded empty data sources.

## Threat Flags

None. Implementation matches the plan's `<threat_model>` register:

- T-22-05-01 (Information disclosure, mocked transcript strings) — accepted; '1千8百4十元 星巴克' and '5千' are non-sensitive engineered fixtures.
- T-22-05-02 (n/a, golden PNG) — N/A; the mic button image contains no user data, only fixed-palette gradient + Mic icon.
- T-22-05-SC (Tampering, supply chain) — N/A; zero new packages.

No new threat surface introduced.

## Self-Check: PASSED

- FOUND: `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` (756 LOC, analyze-clean, 10/10 pass)
- FOUND: `test/widget/features/accounting/presentation/screens/voice_input_screen_mic_button_golden_test.dart` (132 LOC, analyze-clean, 1/1 pass)
- FOUND: `test/widget/features/accounting/presentation/screens/goldens/voice_input_screen_mic_button_idle.png` (23,233 bytes)
- FOUND: `.planning/phases/22-voice-one-step-integration-record-button-ux/deferred-items.md` (20 LOC)
- VERIFIED: `voice_to_manual_one_step_screen_test.dart` does NOT exist (`test ! -f` returns 0)
- VERIFIED: no other file references `voice_to_manual_one_step_screen_test` (recursive grep returns 0)
- FOUND: commit `afdfb55` (Task 1 — voice_input_screen_test rewrite)
- FOUND: commit `da3fe39` (Task 2 — golden test + baseline PNG)
- FOUND: commit `ee601ef` (Task 3 — voice_to_manual delete)
- FOUND: commit `6a0f740` (Task 4 — deferred-items.md log)
- FOUND: 5 REC-01 markers in voice_input_screen_test.dart (>= 2 required)
- FOUND: 4 REC-02 markers in voice_input_screen_test.dart (>= 2 required)
- FOUND: 6 INPUT-02 markers in voice_input_screen_test.dart (>= 3 required)
- FOUND: 1 `Stopwatch` reference in voice_input_screen_test.dart (>= 1 required)
- FOUND: 7 `tester.startGesture` references
- FOUND: 0 `tester.longPress` references (must be 0 per Pitfall 5)
- FOUND: 3 `voice-mic-button` references
- FOUND: 0 `認識結果` references (must be 0)
- FOUND: 0 `タップして録音` references (must be 0)
- FOUND: 1 `matchesGoldenFile('goldens/voice_input_screen_mic_button_idle.png')` reference in golden harness
- FOUND: 2 `voice-mic-button` references in golden harness
- VERIFIED: `flutter analyze test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` → No issues found
- VERIFIED: `flutter analyze test/widget/features/accounting/presentation/screens/voice_input_screen_mic_button_golden_test.dart` → No issues found
- VERIFIED: `flutter gen-l10n` → clean (no warnings or errors)
- VERIFIED: voice tests `11/11 pass` via dedicated invocation
- ACKNOWLEDGED: 15 pre-existing `HomeHeroCard` test failures in `flutter test` full-suite output are logged to `deferred-items.md` as out-of-scope per SCOPE BOUNDARY rule (predate Phase 22; no voice surface dependency)

---
*Phase: 22-voice-one-step-integration-record-button-ux*
*Plan: 05*
*Completed: 2026-05-25*
