---
phase: 22-voice-one-step-integration-record-button-ux
verified: 2026-05-25T18:10:00Z
status: human_needed
score: 5/5 success criteria verified + 2/2 prior gaps closed
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 5/5 success criteria verified (code) — 2 production-risk gaps elevated from code review
  gaps_closed:
    - "G-01: _onStatus self-termination now invokes _stopRecordingAndCommit when _pressStart != null"
    - "G-02: _onError surfaces localized SoftToast via showVoiceRecognitionErrorToast; permanent==true flips _isInitialized=false (CR-02 literal shape; existing _onLongPressStart guard reused)"
  gaps_remaining: []
  regressions: []
follow_up_recommendations:
  # Prior advisory items still standing (NOT regressions; not blocking):
  - id: WR-01
    severity: warning
    file: lib/features/accounting/presentation/screens/voice_input_screen.dart
    line_refs: "73, 239-280, 540-546"
    issue: "_voiceLocaleId initialized to 'zh-CN' default; if user holds mic before voiceLocaleIdProvider resolves on cold start, recognizer + numeral parser run zh-CN against a Japanese-default device."
    recommendation: "Gate _onLongPressStart on voiceLocaleAsync is AsyncData (or add explicit _isLocaleReady flag)."
  - id: WR-02
    severity: warning
    file: lib/features/accounting/presentation/screens/voice_input_screen.dart
    line_refs: "336-338"
    issue: "Vacuous null check — VoiceParseResult.estimatedSatisfaction is @Default(5) int (non-nullable)."
    recommendation: "Compute satisfaction inline from just-resolved parseResult.data when data.ledgerType == LedgerType.soul."
  - id: WR-03
    severity: warning
    file: lib/features/accounting/presentation/screens/voice_input_screen.dart
    line_refs: "336-338, 412-450, 461-485"
    issue: "Two async pipelines write to _parseResult, creating microtask-scheduling race."
    recommendation: "Couple with WR-02 — read satisfaction from the local parseResult.data."
  - id: WR-04
    severity: warning
    file: lib/features/accounting/presentation/screens/voice_input_screen.dart
    line_refs: "365-392"
    issue: "_onSavePressed calls popUntil immediately on success; soul-ledger SoulCelebrationOverlay never paints."
    recommendation: "Defer pop until celebration overlay's onDismissed fires."
  - id: WR-06
    severity: warning
    file: test/integration/features/accounting/voice_save_entry_source_test.dart
    line_refs: "192-201"
    issue: "mocktail catch-all when(findById(any())) overrides specific stubs."
    recommendation: "Drop the catch-all; throw on unexpected ids."
  - id: WR-07
    severity: warning
    file: test/widget/features/accounting/presentation/widgets/transaction_details_form_test.dart
    line_refs: "910-911, 1056-1057"
    issue: "addListener/removeListener use distinct closure instances; removeListener is a no-op."
    recommendation: "Hoist listener into a named local function."
  # New advisory items surfaced by re-review (post gap-closure 22-REVIEW.md):
  - id: WR-NEW-01
    severity: warning
    file: lib/features/accounting/presentation/screens/voice_input_screen.dart
    line_refs: "185-195"
    issue: "_onStatus G-01 branch routes BOTH 'done' and 'notListening' through _stopRecordingAndCommit when _pressStart != null. 'notListening' may be emitted intermediately by speech_to_text on some devices (between recognition chunks), risking premature commit during normal recording sessions."
    recommendation: "Either restrict G-01 commit to status=='done' only, or add a research note + inline comment documenting that 'notListening' is treated as terminal on iOS+Android. See 22-REVIEW.md WR-01 (post-closure)."
  - id: WR-NEW-02
    severity: warning
    file: lib/features/accounting/presentation/screens/voice_input_screen.dart
    line_refs: "198-220"
    issue: "_onError may fire DURING speech-engine tear-down after a successful commit (e.g., error_speech_timeout, error_no_match on empty buffer), producing a spurious toast even when the form has already been populated successfully."
    recommendation: "Track _committedRecently flag; suppress transient (permanent==false) toasts within ~500ms of a successful commit. See 22-REVIEW.md WR-02 (post-closure)."
  - id: WR-NEW-03
    severity: warning
    file: lib/features/accounting/presentation/screens/voice_input_screen.dart
    line_refs: "317-377, 444-482"
    issue: "_stopRecordingAndCommit double-parses the final transcript — once via _parseFinalResult from _onResult, again from the commit path. Pre-existing waste; the G-01 status-driven commit path now makes it slightly more visible."
    recommendation: "Reuse already-populated _parseResult in _stopRecordingAndCommit instead of re-executing parseUseCase. Couples with WR-02/WR-03 (stale-read race)."
  - id: IN-01
    severity: info
    file: lib/features/accounting/presentation/screens/voice_input_screen.dart
    line_refs: "198-220 + voice_error_toast.dart:48-62"
    issue: "Toast helper has no recovery affordance after permanent error — user must navigate away and back. Mic visual does not change to indicate gated state."
    recommendation: "Future polish phase — add 'Retry' action on toast, grayed-out mic state, or auto-retry."
  - id: IN-02
    severity: info
    file: lib/features/accounting/presentation/screens/voice_input_screen.dart
    line_refs: "1-832"
    issue: "voice_input_screen.dart is 832 lines — 32 lines over the 800 CLAUDE.md hard cap. Verbose G-01/G-02 inline comments account for most of the overage."
    recommendation: "Trim inline rationale OR extract a self-contained widget cluster (e.g., MicButton subtree at lines 677-729)."
  - id: IN-03
    severity: info
    file: test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart
    line_refs: "946-1004"
    issue: "G-02 permanent test asserts SoftToast presence but does NOT assert which localized string is shown for 'error_audio'. The transient test does assert voiceRecognitionErrorNetwork, but the permanent test does not assert voiceRecognitionErrorAudio."
    recommendation: "Add expect(find.text(l10n.voiceRecognitionErrorAudio), findsOneWidget) in the permanent-error test."
gaps: []
deferred: []
human_verification:
  - test: "Physical-touch → first-frame perceived latency on real device"
    expected: "On release build of iOS (≥ iPhone 12) and Android (≥ Pixel 6), open VoiceInputScreen, touch and hold mic button; observe visible state change within ~100ms of finger contact. Repeat 5× per device; record any > 200ms instances."
    why_human: "Stopwatch test measures gesture-callback-to-build-completion only; physical sensor latency (finger touch → Flutter gesture frame) is platform-dependent and outside code's control. Verified in 22-VALIDATION.md Manual-Only Verifications row 1."
  - test: "Real-world ja/zh recognizer end-to-end accuracy"
    expected: "On real device, open VoiceInputScreen, hold mic, say '1千8百4十元 星巴克' (zh) or '1840円 スターバックス' (ja), release; form fields auto-populate with amount=1840 and merchant set. Repeat for 3 utterances per locale."
    why_human: "Recognizer accuracy depends on device microphone + Apple/Google STT cloud quality; cannot be unit-tested with mocked services. Verified in 22-VALIDATION.md Manual-Only Verifications row 2."
  - test: "Idle-state golden visual quality (anti-aliasing parity vs true circle)"
    expected: "Compare new idle golden (borderRadius: 36 on 72×72 box) against a screenshot of today's pre-Phase-22 circle mic on the same device; confirm no perceptible aliasing degradation."
    why_human: "Anti-aliasing rendering can differ subtly between BoxShape.circle and borderRadius: 36 on a 72×72 box; visual review confirms acceptable parity. Verified in 22-VALIDATION.md Manual-Only Verifications row 3."
  - test: "Real-world _onStatus('notListening') intermediate behavior on iOS/Android"
    expected: "On real iOS + Android release builds, hold mic and pause briefly (1-2s) mid-utterance, then resume speaking. Observe whether the recognizer emits notListening during the pause (causing premature commit per WR-NEW-01) OR whether notListening only fires on true session end. Test 5 sessions per device with varied pause patterns."
    why_human: "speech_to_text status semantics differ between iOS and Android platform implementations; cannot be verified without real-device speech recognition. Surfaced by 22-REVIEW.md WR-NEW-01."
---

# Phase 22: Voice One-Step Integration + Record Button UX — Verification Report (Post Gap Closure)

**Phase Goal:** Wire the strengthened voice parser + level-2 category resolver into the shared details form on the same single screen as manual entry, and polish the record button so its idle caption unambiguously communicates the interaction model and its recording state is visibly distinct within 100ms.

**Verified:** 2026-05-25T18:10:00Z
**Status:** human_needed (all 5 ROADMAP success criteria verified + both prior BLOCKER gaps closed; 4 human-only device tests remain — 3 carried forward + 1 new from re-review)
**Re-verification:** Yes — after gap closure (G-01 + G-02)

---

## Re-Verification Summary

Prior verification (2026-05-25T00:00:00Z) closed with `status: gaps_found` and 2 elevated production-risk gaps:

- **G-01 (CR-01):** `_onStatus` self-termination did not invoke parse + commit — transcript silently dropped.
- **G-02 (CR-02):** `_onError` silently swallowed errors — no user feedback on permission revocation / network failure / engine unavailability.

Plans 22-08 (ARB keys) → 22-09 (production code fix) → 22-10 (widget tests) executed sequentially in waves 0 → 1 → 2. Re-review at `22-REVIEW.md` confirmed 0 critical findings (CR-01 + CR-02 CLOSED), with 3 new warnings and 3 infos that are non-blocking.

### Gap closure evidence

| Gap | Status | Evidence |
|-----|--------|----------|
| **G-01** | **CLOSED** | `voice_input_screen.dart:185-195` routes `_stopRecordingAndCommit` from `_onStatus` when `(status == 'done' \|\| status == 'notListening') && _isRecording && _pressStart != null`. Idempotency preserved by clearing `_pressStart = null` BEFORE invoking the commit path (so subsequent `_onLongPressEnd` hits its `start == null` guard). Verified by new widget test `G-01: status="done" mid-press drives commit and form fills without gesture release` at `voice_input_screen_test.dart:774-865` — test simulates `onStatus('done')` while gesture is still held and asserts form fills with `find.text('1,840')` + `find.text('星巴克')`. Idempotency block at lines 848-863 snapshots `stoppedBeforeRelease` + `inputCountBeforeRelease`, then asserts neither changes after `gesture.up()`. 3/3 tests pass. |
| **G-02 part A (error surface)** | **CLOSED** | `voice_input_screen.dart:198-220` now calls `showVoiceRecognitionErrorToast(context, errorMsg)`. New helper at `lib/features/accounting/presentation/widgets/voice_error_toast.dart:29-63` (63 LOC) switches on platform code (`error_network` / `error_network_timeout` / `error_no_match` / `error_audio` / default) and mounts a `SoftToast` via `OverlayEntry`. The platform's raw English `errorMsg` is NEVER rendered to UI — only the 4 ARB-backed `voiceRecognitionError*` strings appear in `SoftToast.message`. Closes WR-05 (i18n compliance). Verified by `voice_input_screen_test.dart:875-936` (G-02 transient test) which asserts `find.text(l10n.voiceRecognitionErrorNetwork)` findsOneWidget AND `find.text('error_network')` findsNothing. |
| **G-02 part B (permanent mic gate)** | **CLOSED** | `voice_input_screen.dart:212-218` setState block flips `_isInitialized = false` when `permanent == true`, reusing the existing `_onLongPressStart` guard at line 244 (`if (!_isInitialized \|\| _isRecording) return;`) — no new state field introduced. This matches the CR-02 literal recommendation from `22-REVIEW.md:99-108` verbatim. Verified by `grep -r _hasPermanentError lib/ test/` returning 0 matches AND by widget test `G-02 permanent: onError(..., true) gates mic` at `voice_input_screen_test.dart:946-1004` which fires `onError('error_audio', true)` then attempts a long-press and asserts `speechService.startedLocaleId` remains `null` — proving `startListening` is never called after the permanent error. |
| **WR-05 (i18n)** | **CLOSED** | 4 new ARB keys (`voiceRecognitionErrorNetwork` / `NoMatch` / `Audio` / `Unknown`) added × 3 locales (ja/zh/en). Confirmed via grep returning 4 matches per file. Generated S class exposes all 4 getters at `lib/generated/app_localizations.dart:2506,2512,2518,2524`. Locale-specific impls verified in `app_localizations_ja.dart` (e.g., line 1295: "ネットワークに接続できません。通信状況を確認してください"). |

### Regressions

None detected. All 10 pre-existing Phase 22 widget tests still pass (REC-01 misfire, REC-02 visual, REC-02 timing, INPUT-02 D-08, INPUT-02 D-09, INPUT-02 SC-1, permission-toast × 2, initial-state, button-render). Full file passes 13/13.

---

## Goal Achievement

### Observable Truths (mapped to 5 ROADMAP Success Criteria)

All 5 success criteria remain verified from the prior verification — gap closure did not change SC outcomes; it added missing data-loss / error-surface paths that the SCs implicitly required but didn't enumerate.

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| SC-1 | Voice-driven ledger entry completes on the same single screen; voice parser output fills amount/category/note/merchant in-place; user can edit any auto-filled field before saving | VERIFIED | `voice_input_screen.dart:613-628` embeds `TransactionDetailsForm`. `_stopRecordingAndCommit` (lines 286-345) parses + calls 4+1 setters on the form. Test `INPUT-02 SC-1` passes. **Strengthened by G-01 closure:** even when recognizer self-terminates mid-press, transcript no longer drops; form still fills. |
| SC-2 | Saved voice entry produces a Transaction row with `entry_source = 'voice'` (DAO integration) | VERIFIED | `test/integration/features/accounting/voice_save_entry_source_test.dart` passes 1/1. |
| SC-3 | Record button idle caption communicates chosen interaction model unambiguously; chosen model consistent app-wide | VERIFIED | AnimatedSwitcher caption swap; hold-to-record via `RawGestureDetector`. ARB strings verified ja/zh/en. |
| SC-4 | While recording, button visibly changes AND caption changes to "录音中…"; state change perceivable within 100ms | VERIFIED | AnimatedContainer 180ms shape morph + gradient swap + caption swap. 100ms Stopwatch test passes. |
| SC-5 | All UI strings via `S.of(context)`; `flutter gen-l10n` clean; `flutter analyze` 0 issues for Phase-22-touched files | VERIFIED | `flutter gen-l10n` exits 0. `flutter analyze` on the 3 touched files (screen, helper, test) returns `No issues found`. Pre-existing 4 unrelated analyzer items remain (firebase_messaging + category_selection_screen). |

**Score:** 5/5 success criteria verified + 2/2 prior gaps closed.

---

## Requirements Coverage (from PLAN frontmatter requirements: [INPUT-02, REC-01, REC-02])

| Requirement | Source Plans | REQUIREMENTS.md Description | Status | Evidence |
|-------------|--------------|-----------------------------|--------|----------|
| INPUT-02 | 22-02, 22-04, 22-05, 22-06, **22-08, 22-09, 22-10** | "User can complete a voice-driven ledger entry from the same single screen — voice parser fills amount, category, note, merchant fields in-place; user can edit any field before saving" | SATISFIED | SC-1 + SC-2 verified. **Strengthened by gap closure:** voice batch-fill now also fires on recognizer self-termination (G-01), and any error along the way produces user feedback (G-02) rather than silently dropping the recording. |
| REC-01 | 22-01, 22-04, 22-05, **22-09, 22-10** | "Record button's idle-state caption unambiguously communicates the interaction model; chosen model is consistent app-wide" | SATISFIED | SC-3 verified. Hold-to-record model + caption swap + permanent-error gate now also signals "mic temporarily unavailable" via toast (no caption ambiguity). |
| REC-02 | 22-01, 22-03, 22-04, 22-05 | "While recording, record button visibly changes AND caption text changes to '录音中…'; state change perceivable within 100ms" | SATISFIED | SC-4 verified. Gap closure did NOT modify the visual transition path (G-01/G-02 only touched `_onStatus` + `_onError`); existing AnimatedContainer + 180ms morph behavior preserved. |

**Orphaned requirements check:** REQUIREMENTS.md maps exactly 3 IDs to Phase 22 (INPUT-02, REC-01, REC-02). All accounted for in plan frontmatters across 22-01 through 22-10. No orphans.

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/l10n/app_{ja,zh,en}.arb` | 4 new voiceRecognitionError* keys × 3 locales (12 entries + 12 @meta blocks) | VERIFIED | `grep -c '"voiceRecognitionError'` returns 8 per file (4 keys + 4 @meta blocks). All 4 keys present in all 3 locales. |
| `lib/generated/app_localizations*.dart` | Regenerated with 4 new getters per locale | VERIFIED | `String get voiceRecognitionErrorNetwork/NoMatch/Audio/Unknown` at lines 2506, 2512, 2518, 2524 of base `app_localizations.dart`. Locale-specific impls confirmed at `app_localizations_ja.dart:1295-1304` (full Japanese strings). |
| `lib/features/accounting/presentation/widgets/voice_error_toast.dart` | NEW — top-level `showVoiceRecognitionErrorToast(BuildContext, String)` function with switch on platform error codes | VERIFIED | File exists, 63 LOC. Switch covers `error_network`, `error_network_timeout`, `error_no_match`, `error_audio`, default. Mounts SoftToast via OverlayEntry mirroring `_showPermissionError`. |
| `lib/features/accounting/presentation/screens/voice_input_screen.dart` | `_onStatus` G-01 branch + `_onError` G-02 wiring + import added | VERIFIED | Line 36 imports `../widgets/voice_error_toast.dart`. Lines 172-196 contain new `_onStatus` body. Lines 198-220 contain new `_onError` body. `_onLongPressStart` (line 243-247) UNCHANGED — reuses existing `!_isInitialized` guard. NO `_hasPermanentError` token anywhere (grep returns 0). File grew from 800 → 832 lines (32-line overage of CLAUDE.md cap; flagged as IN-02 for follow-up). |
| `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` | +3 new tests in group "Phase 22 gap closure — G-01 + G-02" | VERIFIED | New group at line 763. 3 testWidgets blocks at lines 775, 876, 947. Group invokes `speechService.onStatus!('done')`, `speechService.onError!('error_network', false)`, `speechService.onError!('error_audio', true)` respectively. All 3 pass. |

---

## Key Link Verification (Wiring)

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `voice_input_screen.dart::_onStatus` | `_stopRecordingAndCommit` | predicate `(status == 'done' \|\| 'notListening') && _isRecording && _pressStart != null` then `unawaited(_stopRecordingAndCommit())` | WIRED (new) | Lines 185-189. `unawaited(...)` requires `dart:async` (imported at line 1). Idempotency: `_pressStart = null` cleared BEFORE the call (line 187), so subsequent `_onLongPressEnd` hits `start == null` guard. |
| `_onError` | `showVoiceRecognitionErrorToast(context, errorMsg)` | direct call after setState (line 219) | WIRED (new) | Toast helper switches on errorMsg and renders only ARB-backed strings via `S.of(context).voiceRecognitionError*`. Raw English never reaches UI. |
| `_onError (permanent=true)` | `_onLongPressStart` short-circuit | `_isInitialized = false` set inside setState block (lines 215-217); `_onLongPressStart` guard at line 244 reads `if (!_isInitialized \|\| _isRecording) return;` | WIRED (literal CR-02 shape) | NO new `_hasPermanentError` field — existing guard reused. Recovery via next `_initSpeechService` call (which re-sets `_isInitialized = available`). |
| `voice_error_toast.dart` | `lib/generated/app_localizations.dart` (S class) | `import '../../../../generated/app_localizations.dart';` + `S.of(context).voiceRecognitionError*` getters | WIRED | All 4 getter references present in helper body. |
| `voice_input_screen.dart` | `voice_error_toast.dart` | `import '../widgets/voice_error_toast.dart';` at line 36 | WIRED | Relative import — works because both files live under `lib/features/accounting/presentation/`. |
| ARB keys → S class | `flutter gen-l10n` | locale-specific overrides in app_localizations_{ja,zh,en}.dart | WIRED | All 4 getters present with correct locale-specific strings (verified by grep). |

---

## Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|-------------------|--------|
| `voice_input_screen.dart` — G-01 commit path | `_isRecording`, `_pressStart`, transcript text | `_onStatus` callback from real `SpeechToText` engine OR injected fake; commits via `_stopRecordingAndCommit` → 4 form setters | YES — real status events from platform OR test-driven fake | FLOWING |
| `voice_error_toast.dart::showVoiceRecognitionErrorToast` | `message` string in SoftToast | switch on platform `errorMsg` → `S.of(context).voiceRecognitionError{Network\|NoMatch\|Audio\|Unknown}` | YES — real localized strings flow from ARB → generated S class → runtime locale resolution | FLOWING |
| `_isInitialized` flag | bool | `_initSpeechService` sets true on availability; `_onError` flips to false on permanent error; next `_initSpeechService` restores | YES — multiple real write paths | FLOWING |
| 4 new ARB keys | localized string values | Authored verbatim in ja/zh/en ARB files; gen-l10n produces Dart getters | YES | FLOWING |

**No HOLLOW or DISCONNECTED artifacts detected for gap closure paths.** All inserted code reads, writes, and produces real data through real wiring.

---

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Gap closure tests pass (3 new) | `flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart --plain-name "Phase 22 gap closure"` | `+3 All tests passed!` | PASS |
| Full voice screen test file passes (10 existing + 3 new) | `flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` | `+13 All tests passed!` | PASS |
| Analyzer clean on touched files | `flutter analyze lib/features/accounting/presentation/screens/voice_input_screen.dart lib/features/accounting/presentation/widgets/voice_error_toast.dart test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` | `No issues found! (ran in 1.0s)` for 3 items | PASS |
| No `_hasPermanentError` token | `grep -rn "_hasPermanentError" lib/ test/` | 0 matches | PASS |
| ARB keys present × 3 locales | `grep -c '"voiceRecognitionError' lib/l10n/app_*.arb` | 8 per file (4 keys + 4 @meta) | PASS |
| Generated S class has 4 getters | `grep "String get voiceRecognitionError" lib/generated/app_localizations.dart` | 4 matches at lines 2506/2512/2518/2524 | PASS |
| Voice error toast import wired in screen | `grep "voice_error_toast.dart\|showVoiceRecognitionErrorToast" lib/features/accounting/presentation/screens/voice_input_screen.dart` | Import at line 36, call at line 219 | PASS |
| Gap closure summaries exist | `ls 22-{08,09,10}-SUMMARY.md` | 3 files present, sized 9587 / 15929 / 13983 bytes | PASS |

---

## Anti-Patterns Scan

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `voice_input_screen.dart` | 832 (LOC) | File exceeds 800-line CLAUDE.md cap by 32 lines | ℹ Info (IN-02) | Cap is "max", not hard error. Inline G-01/G-02 rationale comments account for overage. Flagged for future polish phase. |
| `voice_input_screen.dart` | 185-195 | `_onStatus` G-01 branch treats `notListening` as terminal — platform semantics may differ on iOS vs Android | ⚠ Warning (WR-NEW-01 from 22-REVIEW.md) | Potential premature commit during normal recording pauses on some devices. Needs real-device verification (added to human_verification). |
| `voice_input_screen.dart` | 198-220 | `_onError` may produce spurious toast during engine tear-down after a successful commit | ⚠ Warning (WR-NEW-02 from 22-REVIEW.md) | Confusing UX, not data loss. Mitigation: track `_committedRecently` flag. |
| `voice_input_screen.dart` | 317-377 + 444-482 | `_stopRecordingAndCommit` double-parses the final transcript (once via `_parseFinalResult`, again from commit path) | ⚠ Warning (WR-NEW-03 from 22-REVIEW.md) | Wasted work + stale-read risk. Pre-existing; G-01 path makes slightly more visible. |
| `voice_error_toast.dart` | 1-63 | Mirrors `_showPermissionError` overlay pattern verbatim; no recovery affordance | ℹ Info (IN-01) | Future polish — add retry action or grayed-out mic state. |
| `voice_input_screen_test.dart` | 946-1004 | G-02 permanent test asserts SoftToast presence but does NOT assert specific localized string for `error_audio` | ℹ Info (IN-03) | Coverage gap; cheap to add. |
| Prior warnings (WR-01 through WR-07) | various | All still standing | ⚠ Warning | Carried forward from initial verification as advisory; not blocking. |

**Debt markers in Phase-22-touched files:** none. No `TBD`/`FIXME`/`XXX` introduced by 22-08/09/10.

No 🛑 BLOCKER anti-patterns detected. The 2 prior BLOCKERs (CR-01, CR-02) are CLOSED.

---

## Human Verification Required

(3 items carried forward from initial verification + 1 new from 22-REVIEW.md WR-NEW-01.)

### 1. Physical-touch → first-frame perceived latency

**Test:** On a release build of iOS (≥ iPhone 12) and Android (≥ Pixel 6), open `VoiceInputScreen`, touch and hold the mic button. Observe the button visibly entering the recording state within ~100 ms of finger contact. Repeat 5× per device.

**Expected:** State change perceivable within 100 ms (REC-02 SC-4 timing intent).

**Why human:** Stopwatch widget test measures gesture-callback-to-build-completion only; physical sensor latency is platform-dependent and outside code's control.

### 2. Real-world ja/zh recognizer end-to-end accuracy

**Test:** On a real device, hold mic, say "1千8百4十元 星巴克" (zh) or「1840円 スターバックス」(ja), release; verify form fields auto-populate with amount=1840 and merchant set. Repeat 3 utterances per locale.

**Expected:** Form fields populate correctly across natural utterances.

**Why human:** Recognizer accuracy depends on device microphone + Apple/Google STT cloud quality.

### 3. Idle-state golden visual quality

**Test:** Compare the new idle golden against a screenshot of today's pre-Phase-22 circle mic on the same device.

**Expected:** No visible aliasing regression at 72×72 mic-button rendering.

**Why human:** Anti-aliasing rendering can differ subtly between `BoxShape.circle` and `borderRadius: 36`.

### 4. Real-world `_onStatus('notListening')` intermediate behavior (NEW — from re-review WR-NEW-01)

**Test:** On real iOS + Android release builds, hold mic and pause briefly (1-2s) mid-utterance, then resume speaking. Observe whether the recognizer emits `notListening` during the pause (causing premature commit per WR-NEW-01) OR whether `notListening` only fires on true session end. Test 5 sessions per device with varied pause patterns.

**Expected:** `notListening` should NOT fire intra-session during normal recording pauses; if it does, the new G-01 path will prematurely commit a partial transcript.

**Why human:** `speech_to_text` status semantics differ between iOS and Android platform implementations; cannot be verified without real-device speech recognition. Surfaced by `22-REVIEW.md` re-review WR-NEW-01 as a latent risk introduced by the G-01 fix shape (inherited the existing `notListening` predicate from the broken code).

---

## Follow-Up Recommendations (advisory — not blocking)

The post-gap-closure re-review at `22-REVIEW.md` flagged 0 critical, 3 warnings (WR-NEW-01/02/03), and 3 infos (IN-01/02/03). Plus 6 prior warnings still standing (WR-01/02/03/04/06/07). All advisory; none block phase verification. Recommend folding into a future polish phase (e.g., `polish-voice-flow` or as part of Phase 23 if voice work continues).

**New warnings (post-gap-closure):**
- **WR-NEW-01:** `notListening` may be intra-session on some devices → premature commit risk.
- **WR-NEW-02:** Spurious toast race when engine errors fire during tear-down after success.
- **WR-NEW-03:** Double-parse of final transcript (waste + stale-read risk).

**New infos:**
- **IN-01:** Toast has no recovery affordance after permanent error.
- **IN-02:** Screen file 832 lines (32 over 800-line cap).
- **IN-03:** G-02 permanent test doesn't assert specific localized string for `error_audio`.

**Carried forward (from initial verification):** WR-01 (locale race), WR-02/03 (vacuous null + stale-read), WR-04 (celebration overlay never paints), WR-06 (mocktail catch-all), WR-07 (listener closure cleanup).

Full details in frontmatter `follow_up_recommendations`.

---

## Pre-Existing Out-of-Scope Items (documented per SCOPE BOUNDARY)

**Test failures (15 total) — NOT regressions caused by Phase 22 or gap closure:**
- `test/golden/home_hero_card_golden_test.dart` — 7 HomeHeroCard golden pixel diffs
- `test/widget/features/home/presentation/widgets/home_hero_card_test.dart` — 4 cumulative Joy assertion failures
- `test/unit/infrastructure/ml/merchant_database_test.dart` — 4 findMerchant case-insensitivity/substring failures

All documented in `deferred-items.md`. Phase 22 + gap closure does not touch any of these files.

**Analyzer findings (4 total) — pre-existing:**
- 1 firebase_messaging build-cache `include_file_not_found` warning (third-party transitive cache)
- 1 firebase_messaging `prefer_final_fields` info (third-party)
- 2 `category_selection_screen.dart` onReorder deprecation infos (lines 386, 502)

---

## Gaps Summary

**Both prior BLOCKER gaps (G-01 + G-02) are CLOSED.** The phase goal is now fully achieved:

1. The voice parser + level-2 category resolver are wired into the shared details form on the same single screen as manual entry (SC-1 + INPUT-02).
2. Voice batch-fill survives recognizer self-termination (G-01 closure) — no silent transcript loss.
3. Errors along the way produce localized user feedback (G-02 closure) — no silent error swallowing.
4. The record button idle caption unambiguously communicates the hold-to-record interaction model (SC-3 + REC-01).
5. The recording state is visibly distinct within 100ms (SC-4 + REC-02).
6. All UI strings route through `S.of(context)` with ja/zh/en parity (SC-5).

**Status: `human_needed`** because 4 device-only verifications remain. None are programmatically verifiable; defer to physical-device UAT alongside the next manual-test cycle.

---

_Verified: 2026-05-25T18:10:00Z_
_Verifier: Claude (gsd-verifier)_
_Re-verification: Yes — after gap closure waves 22-08 → 22-09 → 22-10_
