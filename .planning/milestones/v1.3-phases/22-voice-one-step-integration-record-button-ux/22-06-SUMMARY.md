---
phase: 22
plan: 06
slug: voice-one-step-integration-record-button-ux
subsystem: testing
status: complete
wave: 2
tags: [flutter, integration-test, voice, entry-source, drift, sqlcipher, sc-2]

requires:
  - phase: 22-voice-one-step-integration-record-button-ux
    plan: 04
    provides: "VoiceInputScreen with TransactionDetailsFormConfig.$new(entrySource: EntrySource.voice) wiring + stable ValueKey('voice-mic-button') / ValueKey('voice-save-button') anchors"
  - phase: 17
    provides: "DB schema v17 CHECK constraint allowing entry_source='voice'"
  - phase: 18
    provides: "TransactionDetailsForm.submit() persistence pipeline → CreateTransactionUseCase → TransactionRepositoryImpl → TransactionDao"
  - phase: 19
    provides: "manual_save_entry_source_test.dart — analog test file that proved the SC-4 manual-entry round-trip pattern Plan 06 mirrors"

provides:
  - "test/integration/features/accounting/voice_save_entry_source_test.dart — SC-2 (INPUT-02) round-trip integration test proving the voice save path stamps entry_source='voice' through the real Drift schema CHECK constraint"
  - "_CapturingSpeechService fake — drives transcript emission via emitFinal() captured callback (mirrors voice_input_screen_test.dart pattern, lifted into the integration test file)"
  - "_FakeParseVoiceInputUseCase — pre-seeded VoiceParseResult fixture for amount=500 / merchant='スターバックス' / category=cat_food_cafe survival"
  - "tester.runAsync wall-clock-delay pattern for the 300 ms hold-to-record misfire threshold (D-03) — DateTime.now() ≠ fake-async pump time"

affects:
  - "Phase 22 SC-2 coverage row in 22-VALIDATION.md — now fully satisfied by an automated test."
  - "Plan 07 (verification) — the only remaining missing piece for SC-2 closure is now in place."

tech-stack:
  added: []
  patterns:
    - "Integration test setup: real AppDatabase.forTesting() + real CreateTransactionUseCase + mocked outer dependencies (categoryRepository, deviceIdentityRepository, encryptionService, learningService) — verbatim shape from manual_save_entry_source_test.dart:74-138"
    - "tester.runAsync(() async => Future.delayed(350ms)) to bridge real DateTime.now() with fake-async pump time — required because the misfire-threshold gate uses wall-clock time, not fake-async elapsed time"
    - "tester.widget<AmountDisplay>(find.byType(AmountDisplay)).amount type-safe widget read instead of find.text('500') — H-5 mitigation against JPY-rendering-chrome coupling"
    - "Direct DAO query (transactionDao.findByBookId('book-1')) post-save — bypasses the repo encryption wrapper so the assertion checks the actual stored CHECK-constrained value"

key-files:
  created:
    - "test/integration/features/accounting/voice_save_entry_source_test.dart (361 LOC) — single testWidgets case covering the full hold-to-record → batch-fill → save → DB assert flow"
  modified: []

key-decisions:
  - "Wall-clock delay via tester.runAsync (not Future.delayed inside the fake-async zone). The misfire-threshold gate at voice_input_screen.dart:224 uses `DateTime.now().difference(start)` which reads real wall-clock time even inside the flutter_test fake-async zone. tester.pump(Duration(...)) only advances fake-async time, so a 400 ms pump still produces a held duration of ~0 ms and routes _onLongPressEnd to _cancelRecordingAndDiscard. Production fix is a non-starter (would require dependency-injecting a Clock into the screen); test fix is tester.runAsync, which yields control to the actual VM event loop where DateTime.now() advances normally. ~250 ms of real wall-clock cost per test run."
  - "Constructor injection (speechService: speechService) over provider override for the speech service. VoiceInputScreen's constructor already accepts an optional StartSpeechRecognitionUseCase? speechService — the production code falls back to ref.read(appSpeechRecognitionServiceProvider) when null. Constructor injection is the simpler path (no provider override needed) and matches the pattern from voice_input_screen_test.dart."
  - "MatchSource.merchant on the CategoryMatchResult fixture (not .keyword). Plan body Example 4 implied .merchant via the 'スターバックス' merchant context. .keyword would also work mechanically since the screen consumes data.categoryMatch.categoryId regardless of source — the choice is rhetorical, matching the Phase-22 SC-2 narrative ('saying \"Starbucks\" implies a merchant match')."
  - "Sanity-check assertions on the commit path (parseUseCase.inputs contains text, speechService.stopped, !speechService.canceled) added BEFORE the amount/DB assertions. These give a precise failure signal: if the misfire gate trips and the test routes through _cancelRecordingAndDiscard, the sanity checks fail with 'speechService.canceled was true' instead of the more confusing 'AmountDisplay.amount was empty' (which is the symptom, not the cause). Pays off any future regression that breaks the wall-clock delay shim."

metrics:
  duration: "~26 min"
  tasks_completed: 2
  files_created: 1
  files_modified: 0
  loc_delta: "+361 (0 → 361, single test file)"
  completed_at: "2026-05-25T05:57:07Z"

requirements-completed: [INPUT-02]
---

# Phase 22 Plan 06: Voice Save Entry Source Integration Test Summary

Closes the SC-2 integration test gap. Plan 04 stamped `entry_source = 'voice'` via `TransactionDetailsFormConfig.$new(entrySource: EntrySource.voice)` flowing through `CreateTransactionParams` into a Drift insert; this plan proves the round-trip with a real database. A single 361-LOC integration test mirrors `manual_save_entry_source_test.dart` (Phase 19 SC-4 analog) and exercises the production save path end-to-end: hold-to-record gesture → fake-final transcript emission → batch-fill the embedded `TransactionDetailsForm` → tap Save → assert the inserted Drift row has `entry_source = 'voice'`.

## Performance

- **Duration:** ~26 min
- **Started:** 2026-05-25T05:31:40Z
- **Completed:** 2026-05-25T05:57:07Z
- **Tasks:** 2/2 (Task 1 = test file create + commit; Task 2 = full-suite gate, no commit needed)

## Accomplishments

- **Created `test/integration/features/accounting/voice_save_entry_source_test.dart` (361 LOC).** Single `testWidgets` case `SC-2 INPUT-02: VoiceInputScreen save stamps entry_source=voice in Drift row`. Mirrors the analog's setUp/tearDown structure verbatim: `AppDatabase.forTesting()`, real `CreateTransactionUseCase`, `TransactionRepositoryImpl`, `HashChainService`, `ClassificationService`, with `_MockCategoryRepository` / `_MockDeviceIdentityRepository` / `_MockFieldEncryptionService` / `_MockMerchantCategoryLearningService` at the outer edges.
- **Added two voice-path-specific fakes** lifted from `voice_input_screen_test.dart`:
  - `_CapturingSpeechService implements StartSpeechRecognitionUseCase` — captures the `onResult` callback so the test drives transcript emission via `emitFinal('スターバックスで500円')`. Tracks `stopped` / `canceled` booleans so the test can sanity-check the cancel-vs-commit branch selection.
  - `_FakeParseVoiceInputUseCase implements ParseVoiceInputUseCase` — returns a pre-seeded `VoiceParseResult(amount: 500, merchantName: 'スターバックス', categoryMatch: CategoryMatchResult(categoryId: 'cat_food_cafe', confidence: 0.95, source: MatchSource.merchant), ledgerType: LedgerType.survival)` for the test transcript.
- **Wired five Riverpod overrides** that survive the worktree-isolated DB stack: `appDatabaseProvider.overrideWithValue(db)`, `categoryRepositoryProvider`, `createTransactionUseCaseProvider`, `merchantCategoryLearningServiceProvider`, `parseVoiceInputUseCaseProvider`, `voiceLocaleIdProvider.overrideWith((ref) async => 'ja-JP')`. Speech service is constructor-injected via `VoiceInputScreen(speechService: _CapturingSpeechService())`.
- **Drove the production gesture pipeline** via `tester.startGesture(tester.getCenter(find.byKey(ValueKey('voice-mic-button'))))` → `speechService.emitFinal('スターバックスで500円')` → `tester.runAsync(() => Future.delayed(350ms))` → `gesture.up()` → `await tester.pumpAndSettle()`.
- **Asserted the form-fill state via H-5 type-safe widget read.** `tester.widget<AmountDisplay>(find.byType(AmountDisplay)).amount == '500'` replaces the originally-planned `find.text('500')` which would have been coupled to JPY-rendering chrome.
- **Asserted the DB round-trip** via direct DAO query: `final rows = await transactionDao.findByBookId('book-1'); expect(rows.first.entrySource, 'voice'); expect(rows.first.amount, 500);` — bypasses the repository encryption wrapper to confirm the v17 schema CHECK constraint accepted the literal string `'voice'`.
- **Sanity-check assertions** on commit-path selection: the test asserts `parseUseCase.inputs.contains('スターバックスで500円')`, `speechService.stopped == true`, and `speechService.canceled == false` BEFORE the form-fill assertion. These give a precise failure signal if the misfire gate ever regresses (cancel path's `speechService.canceled == true` would fail first, pointing directly at the gesture-routing bug instead of the downstream symptom).

## Task Commits

| Task | Name                                                | Commit  | LOC delta |
| ---- | --------------------------------------------------- | ------- | --------- |
| 1    | Create voice_save_entry_source_test.dart            | 1486d79 | +361      |
| 2    | Full test suite gate (no file changes — gate only)  | —       | 0         |

## Files Created/Modified

- **Created:** `test/integration/features/accounting/voice_save_entry_source_test.dart` (361 LOC)
- **Modified:** none

## Decisions Made

### D-1: Wall-clock delay via tester.runAsync (test-side workaround for production DateTime.now())

The misfire-threshold gate at `voice_input_screen.dart:224` reads:
```dart
if (held < const Duration(milliseconds: 300)) {
  _cancelRecordingAndDiscard();
}
```
where `held = DateTime.now().difference(start)` and `start = DateTime.now()` captured at press-down. `DateTime.now()` returns real wall-clock time even inside flutter_test's fake-async zone, so `tester.pump(const Duration(milliseconds: 400))` does NOT advance the held duration past the threshold — held remains ~0 ms and the gesture routes through `_cancelRecordingAndDiscard`.

Two paths considered:
- **Production code change**: inject a `Clock` abstraction (`tester` could override it for tests). REJECTED — invasive for a test-only concern, would require touching the screen's gesture handler, and Phase 22 Plan 04 is closed.
- **Test-side wall-clock delay via `tester.runAsync`**: yields control to the real VM event loop where `DateTime.now()` advances normally; await `Future.delayed(const Duration(milliseconds: 350))` inside the runAsync callback. CHOSEN — zero production-code impact, ~250 ms real wall-clock cost per test run (test completes in ~1 s end-to-end).

### D-2: Constructor injection (speechService:) over provider override

`VoiceInputScreen`'s constructor accepts an optional `StartSpeechRecognitionUseCase? speechService` argument with a production fallback to `ref.read(appSpeechRecognitionServiceProvider)`. Constructor injection skips the provider override declaration entirely. Matches the pattern from `voice_input_screen_test.dart` (referenced as the source for `_CapturingSpeechService`).

### D-3: Direct DAO query post-save (not repo query)

The assertion uses `transactionDao.findByBookId('book-1')` directly against the Drift database instead of querying through `TransactionRepositoryImpl`. Reason: the repo passes results through the (mocked) encryption service's `decryptField` method. Going through the repo would test the repo's decrypt-pass-through rather than the v17 schema CHECK constraint's acceptance of `'voice'`. Direct DAO query reads the raw stored value, proving the CHECK constraint accepted the literal string.

### D-4: Sanity-check assertions BEFORE the symptom assertion

When debugging the wall-clock issue (D-1), the failure mode was confusing: the symptom was `expect(amountDisplay.amount, '500')` failing with `'500'` vs `''`, but the cause was the misfire-threshold gate routing through `_cancelRecordingAndDiscard`. Added three sanity-check assertions immediately after `gesture.up()`:
```dart
expect(parseUseCase.inputs, contains('スターバックスで500円'));
expect(speechService.stopped, isTrue);
expect(speechService.canceled, isFalse);
```
These fail first if the misfire gate trips, with messages that point directly at the gesture-routing bug. Future regressions will be diagnosable in seconds.

## Deviations from Plan

**1. [Rule 3 - Blocker] Wall-clock delay via tester.runAsync — production DateTime.now() incompatible with tester.pump fake-async time**

- **Found during:** Task 1 first test run (red phase)
- **Issue:** Plan body Example 4 specified `await tester.pump(const Duration(milliseconds: 400))` between `speechService.emitFinal(...)` and `gesture.up()`. The misfire-threshold gate at `voice_input_screen.dart:224` uses `DateTime.now()` which reads wall-clock time, not fake-async time. After 400 ms of fake-async pump, `held = DateTime.now().difference(start)` was ~0 ms, falling below the 300 ms threshold and routing the gesture through `_cancelRecordingAndDiscard`. Debug-print confirmed `speechService.canceled: true / stopped: false`.
- **Fix:** Replaced `tester.pump(Duration(milliseconds: 400))` with `tester.runAsync(() async => await Future<void>.delayed(const Duration(milliseconds: 350)))`. `runAsync` yields control to the actual VM event loop where DateTime.now() advances. Test went green; commit path confirmed via `speechService.stopped: true`.
- **Files modified:** `test/integration/features/accounting/voice_save_entry_source_test.dart`
- **Commit:** 1486d79 (Task 1, same commit as the file creation since this was a red→green iteration)

**2. [Rule 2 - Critical] Added sanity-check assertions on the cancel-vs-commit branch selection**

- **Found during:** Task 1 debug iteration
- **Issue:** When the wall-clock issue caused the test to silently route through the cancel branch, the failure mode was the AmountDisplay assertion at the end — a confusing symptom several layers removed from the cause. Future regressions of the wall-clock workaround would produce the same opaque failure.
- **Fix:** Added 3 sanity-check assertions immediately after `gesture.up()` and `pumpAndSettle()`: `parseUseCase.inputs contains 'スターバックスで500円'`, `speechService.stopped == true`, `speechService.canceled == false`. These give a precise failure signal directly at the gesture-routing boundary.
- **Files modified:** `test/integration/features/accounting/voice_save_entry_source_test.dart`
- **Commit:** 1486d79 (Task 1)

## Issues Encountered

### Full test suite NOT fully green after Plan 06 (Task 2 acceptance criterion partially unsatisfied)

`flutter test` reports 23 failing tests against the worktree base. Categorized:

| Category | Count | File(s) | Disposition |
|----------|-------|---------|-------------|
| Plan 05 closes (Plan 04 SUMMARY documented as EXPECTED FAILURE) | 4 | `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` | DEFERRED — Plan 05 (parallel Wave 2 sibling) rewrites this file. Plan 04 SUMMARY explicitly enumerates these 4 failures as expected. |
| Plan 05 deletes (Plan 04 SUMMARY documented as EXPECTED FAILURE) | 4 | `test/widget/features/accounting/presentation/screens/voice_to_manual_one_step_screen_test.dart` | DEFERRED — Plan 05 deletes this file (D-16 flow no longer exists). Plan 04 SUMMARY explicitly enumerates these 4 failures. |
| Pre-existing on worktree base | 4 | `test/unit/infrastructure/ml/merchant_database_test.dart` | OUT OF SCOPE — not caused by Plan 06's changes; no production code modified in this plan. |
| Pre-existing on worktree base | 4 | `test/widget/features/home/presentation/widgets/home_hero_card_test.dart` | OUT OF SCOPE — not caused by Plan 06's changes. |
| Pre-existing on worktree base | 7 | `test/golden/home_hero_card_golden_test.dart` | OUT OF SCOPE — golden-image regressions, not caused by Plan 06's changes. |
| **Total** | **23** | | |

Per the deviation rules SCOPE BOUNDARY ("Only auto-fix issues DIRECTLY caused by the current task's changes"), all 23 failures are out of scope for Plan 06:
- 8 failures resolve when Plan 05 lands (parallel Wave 2 sibling; merging is the orchestrator's job).
- 15 failures pre-date our worktree base (`c0d64fc`) — Plan 06 added exactly one file and modified zero production files. None of these failures touch the integration path Plan 06 covers.

Plan 07 (verification) will see this state. The plan's gate language ("If ANY non-Phase-22 test regresses, STOP and diagnose") is satisfied: no Phase-22 test regressed BECAUSE OF Plan 06.

### `flutter analyze` whole-repo reports 4 pre-existing issues (unchanged from Plan 04 SUMMARY)

- 1 firebase_messaging build cache `include_file_not_found` warning (third-party transitively cached)
- 1 firebase_messaging `prefer_final_fields` info (third-party)
- 2 `deprecated_member_use` infos in `lib/features/accounting/presentation/screens/category_selection_screen.dart` (pre-existing)

`flutter analyze test/integration/features/accounting/voice_save_entry_source_test.dart` → `No issues found!` — Plan 06's new file is analyze-clean.

## Test Failure Tally (for Plan 05's reference)

Identical to Plan 04 SUMMARY's tally. Plan 06 does NOT change any of these counts:

| Test File | Failures | Status |
|-----------|----------|--------|
| `test/widget/.../screens/voice_input_screen_test.dart` | 4 of 6 | Plan 05 rewrites |
| `test/widget/.../screens/voice_to_manual_one_step_screen_test.dart` | 4 of 4 | Plan 05 deletes |
| `test/integration/.../voice_save_entry_source_test.dart` (NEW — Plan 06) | 0 of 1 | **GREEN — passes after Plan 06** |

## User Setup Required

None — pure test addition. No environment variables, third-party services, or platform configuration touched. No new packages installed.

## Next Phase Readiness

- **SC-2 (INPUT-02) coverage CLOSED.** The 22-VALIDATION.md row "Save path stamps `entry_source = 'voice'` (SC-2)" is now satisfied by an automated integration test.
- **Plan 07 (verification) unblocked.** The only remaining missing piece for SC-2 closure (the integration test) is now in place. Plan 07 should observe:
  - 1 passing integration test in `test/integration/features/accounting/voice_save_entry_source_test.dart`
  - 0 changes to production code from Plan 06
  - 0 regressions caused by Plan 06
- **Plan 06 + Plan 05 + Plan 04 collectively realize the Phase 22 test surface.** Phase 22 net new tests when Plan 05 lands: 10 D-07 widget tests (Plan 02) + 8 widget tests + 1 golden (Plan 05) + 1 integration test (Plan 06) = 20 net new tests. Plan 06 contributes the 1 integration test.

## Known Stubs

None. The integration test exercises real production code paths:
- Real `AppDatabase.forTesting()` (in-memory SQLite, no SQLCipher in tests by design — encryption mocked at the FieldEncryptionService boundary, which is the correct seam per the analog file).
- Real `CreateTransactionUseCase`, `TransactionRepositoryImpl`, `HashChainService`, `ClassificationService`, `RuleEngine`, `TransactionDao`.
- Real `VoiceInputScreen` widget tree (the entire screen renders, including `TransactionDetailsForm` embed, `AmountDisplay`, mic button RawGestureDetector, full-width Save CTA).
- Real `TransactionDetailsForm.submit()` pipeline through the use case to the DAO.

The mocks at the outer edges (categoryRepository, deviceIdentityRepository, encryptionService, learningService, speechService, parseVoiceInputUseCase) are at the same boundaries as the analog `manual_save_entry_source_test.dart` — these are the unauthenticated / non-encrypted / non-keyed dependencies. The mocked surface is identical (encryptionService pass-through, learningService no-op, deviceIdentityRepository returns 'device-local'); the only additions for the voice variant are the speechService and parseVoiceInputUseCase, both of which need fakes to drive deterministic transcript emission.

## Threat Flags

None. Plan 06 introduces zero new network endpoints, zero new auth paths, zero new file-access patterns, and zero schema changes. The integration test exercises the existing v17 schema CHECK constraint allowlist (which already includes `'voice'` per Phase 17 D-06 + Phase 18 D-08). The threat model entries in 22-06-PLAN.md `<threat_model>` are all satisfied:

- T-22-06-01 (Tampering, schema CHECK constraint) — `mitigate`: the test asserts the literal string `'voice'` is accepted by the v17 schema. If a future migration regresses, this test fails loudly with a Drift constraint-violation error.
- T-22-06-02 (Information disclosure, mocked encryption service) — `accept`: matches the analog file's threat disposition.
- T-22-06-SC (Tampering, npm/pip/cargo installs) — `N/A`: zero new packages.

## Self-Check: PASSED

- **FOUND:** `test/integration/features/accounting/voice_save_entry_source_test.dart` (361 LOC, analyze-clean)
- **FOUND:** commit `1486d79` — `test(22-06): add SC-2 integration test — voice save stamps entry_source='voice'`
- **VERIFIED:** `flutter test test/integration/features/accounting/voice_save_entry_source_test.dart` → 1/1 pass, "All tests passed!"
- **VERIFIED:** `flutter analyze test/integration/features/accounting/voice_save_entry_source_test.dart` → "No issues found!"
- **VERIFIED:** `grep -q "AppDatabase.forTesting"` → matches (line 209)
- **VERIFIED:** `grep -q "VoiceInputScreen"` → matches (multiple lines)
- **VERIFIED:** `grep -q "tester.startGesture"` → matches (line 277)
- **VERIFIED:** `grep -q "voice-save-button"` → matches (line 308)
- **VERIFIED:** `grep -q "voice-mic-button"` → matches (line 270)
- **VERIFIED:** `grep -q "transactionDao.findByBookId"` → matches (line 327)
- **VERIFIED:** `grep -q "entry_source must equal the literal string"` → matches (line 333)
- **VERIFIED:** `grep -q "tester.widget<AmountDisplay>"` → matches (line 301)
- **VERIFIED:** test asserts `rows.length == 1` (line 330)
- **VERIFIED:** test holds gesture > 300 ms via `tester.runAsync` + `Future.delayed(350ms)` (line 290)

---
*Phase: 22-voice-one-step-integration-record-button-ux*
*Plan: 06*
*Completed: 2026-05-25*
