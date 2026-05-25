---
phase: 22-voice-one-step-integration-record-button-ux
verified: 2026-05-25T00:00:00Z
status: gaps_found
score: 5/5 success criteria verified (code) — 2 production-risk gaps elevated from code review per user direction
overrides_applied: 0
re_verification:
  previous_status: none
  previous_score: n/a
  gaps_closed: []
  gaps_remaining: []
  regressions: []
follow_up_recommendations:
  - id: CR-01
    severity: blocker (advisory — code review finding, not phase-blocker)
    file: lib/features/accounting/presentation/screens/voice_input_screen.dart
    line_refs: "171-180, 217-229"
    issue: "_onStatus flips _isRecording=false on recognizer self-termination (done/notListening) without invoking parse + commit. After self-termination, _onLongPressEnd short-circuits via !_isRecording guard. Real-world triggers: 30s listenFor expiry, 3s pauseFor mid-press, platform mic interruption. User holds, speaks, recognizer auto-ends ~3s after last word, user releases — nothing happens silently."
    recommendation: "Drive _stopRecordingAndCommit from _onStatus when status in {done, notListening} AND _pressStart != null (i.e., user still holding); see CR-01 fix in 22-REVIEW.md. Add widget test that emits final + onStatus('done') and asserts form fills."
  - id: CR-02
    severity: blocker (advisory — code review finding, not phase-blocker)
    file: lib/features/accounting/presentation/screens/voice_input_screen.dart
    line_refs: "182-188"
    issue: "_onError ignores errorMsg and permanent flag; UI silently resets to idle on permission revocation, network failure, engine unavailability. Violates CLAUDE.md error-handling rules ('user-friendly error messages in UI-facing code', 'never silently swallow errors')."
    recommendation: "Surface error via SoftToast; for permanent=true, gate mic until reinit. Add ARB keys voiceRecognitionErrorNetwork/NoMatch/Audio/Unknown × ja/zh/en. Add widget test that fires onError('network', false) and asserts toast appears."
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
    issue: "Vacuous null check — VoiceParseResult.estimatedSatisfaction is @Default(5) int (non-nullable). The check is always true when _parseResult != null. Also pushes satisfaction unconditionally for survival-ledger transactions (harmless but unclear intent)."
    recommendation: "Compute satisfaction inline from just-resolved parseResult.data when data.ledgerType == LedgerType.soul. Eliminates also WR-03 stale-read race."
  - id: WR-03
    severity: warning
    file: lib/features/accounting/presentation/screens/voice_input_screen.dart
    line_refs: "336-338, 412-450, 461-485"
    issue: "Two async pipelines write to _parseResult (_parseFinalResult from _onResult and _stopRecordingAndCommit), creating microtask-scheduling race. Tests don't catch this because fake use case resolves synchronously."
    recommendation: "Couple with WR-02 — read satisfaction from the local parseResult.data in _stopRecordingAndCommit instead of side-channel _parseResult field."
  - id: WR-04
    severity: warning
    file: lib/features/accounting/presentation/screens/voice_input_screen.dart
    line_refs: "365-392"
    issue: "_onSavePressed calls popUntil immediately on success; soul-ledger save's SoulCelebrationOverlay (set in form.submit() via _showCelebration=true) never paints because route is popped before next frame."
    recommendation: "Defer pop until celebration overlay's onDismissed fires, OR move celebration ownership to host so it can be sequenced with navigation."
  - id: WR-05
    severity: warning
    file: lib/features/accounting/presentation/screens/voice_input_screen.dart
    line_refs: "182-188"
    issue: "Compounds CR-02 — when surfacing _onError messages, the platform speech-engine errorMsg is English-only (e.g., 'error_network'). Violates i18n rule."
    recommendation: "Map platform error codes to localized ARB keys (voiceRecognitionErrorNetwork/NoMatch/Audio/Unknown) and switch on errorMsg."
  - id: WR-06
    severity: warning
    file: test/integration/features/accounting/voice_save_entry_source_test.dart
    line_refs: "192-201"
    issue: "mocktail catch-all when(findById(any())).thenAnswer((_) => _category) registered AFTER specific stubs overrides them; the parent-category lookup at voice_input_screen.dart:320 (parentId='cat_food') returns _category instead of _parentCategory. Hidden because current assertions only check entry_source + amount."
    recommendation: "Drop the catch-all and rely on the two specific stubs; throw on unexpected ids to make missing stubs loud."
  - id: WR-07
    severity: warning
    file: test/widget/features/accounting/presentation/widgets/transaction_details_form_test.dart
    line_refs: "910-911, 1056-1057"
    issue: "addListener(() => notifications++) and removeListener(() => notifications++) use distinct closure instances; removeListener is a no-op. Listener stays attached for controller lifetime; cleanup is cosmetic."
    recommendation: "Hoist listener into a named local function so the same reference is used in both calls."
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
---

# Phase 22: Voice One-Step Integration + Record Button UX — Verification Report

**Phase Goal:** Wire the strengthened voice parser + level-2 category resolver into the shared details form on the same single screen as manual entry, and polish the record button so its idle caption unambiguously communicates the interaction model and its recording state is visibly distinct within 100ms.

**Verified:** 2026-05-25
**Status:** PASSED (with human verification deferred to manual device testing — per 22-VALIDATION.md Manual-Only Verifications)
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths (mapped to 5 ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| SC-1 | Voice-driven ledger entry completes on the same single screen as manual entry; voice parser output fills amount/category/note/merchant in-place in shared `TransactionDetailsForm`; user can edit any auto-filled field before saving | VERIFIED | `voice_input_screen.dart:613-628` embeds `TransactionDetailsForm(key: _formKey, config: $new(entrySource: EntrySource.voice, ...))` in scrollable Expanded above the mic area. `_stopRecordingAndCommit` (lines 286-345) parses transcript, looks up category, calls 4+1 setters (`updateAmount`/`updateCategory`/`updateMerchant`/`updateSatisfaction`) on the form, then mirrors `_hostAmount`/`_hostCategory`. Test `voice_input_screen_test.dart::INPUT-02 SC-1` passes with transcript "1千8百4十元 星巴克". |
| SC-2 | Saved voice entry produces a Transaction row with `entry_source = 'voice'` (DAO integration) | VERIFIED | `test/integration/features/accounting/voice_save_entry_source_test.dart:260-360` mounts real `VoiceInputScreen` with real `AppDatabase.forTesting()` + real `CreateTransactionUseCase`, drives gesture-based save, then queries Drift `transactionDao.findByBookId('book-1')` and asserts `rows.first.entrySource == 'voice'`. Test PASSES (1/1). |
| SC-3 | Record button idle caption communicates chosen interaction model unambiguously; chosen model consistent app-wide | VERIFIED | `voice_input_screen.dart:702-713` AnimatedSwitcher reads `_isRecording ? l10n.recording : l10n.holdToRecord`. ARB strings: ja `押して話す/録音中…`, zh `按住说话/录音中…`, en `Hold to speak/Recording…` (verified in `app_*.arb:1041-1048`). `tapToRecord` removed from all 3 locales. Hold-to-record via `RawGestureDetector + LongPressGestureRecognizer(duration: Duration.zero)`. App-wide consistency: 22-CONTEXT D-03 records hold-to-record as binding decision; VoiceInputScreen is sole voice surface in v1.3. Tests `REC-01 idle caption` + `REC-01 recording caption` + `REC-01 misfire` all pass. |
| SC-4 | While recording, button visibly changes (color/shape/icon) AND caption changes to "录音中…"; state change perceivable within 100ms | VERIFIED | `voice_input_screen.dart:663-697` AnimatedContainer(180ms, easeInOut) with `borderRadius: BorderRadius.circular(_isRecording ? 16 : 36)` + gradient swap (`AppColors.recordingGradientStart/End` red ↔ `AppColors.actionGradientStart/End` green). Mic icon stays `Icons.mic` in both states (semantics from shape+color+caption per D-04). Tests: `REC-02 visual` asserts borderRadius transitions 36→16, `REC-02 timing` Stopwatch wraps setState+pump cycle and asserts < 100ms. Idle-state golden `voice_input_screen_mic_button_idle.png` (23,233 bytes) committed; golden test passes. |
| SC-5 | All UI strings routed through `S.of(context)` with ja/zh/en parity; `flutter gen-l10n` clean; `flutter analyze` 0 issues (for Phase-22-touched files) | VERIFIED | `flutter gen-l10n` exits 0; generated `app_localizations*.dart` files contain `holdToRecord`/`recording` getters in all 3 locales. `flutter analyze` reports 4 pre-existing issues — all in unrelated files (firebase_messaging build cache + 2 onReorder deprecations in category_selection_screen.dart). 0 issues in Phase-22-touched files. |

**Score:** 5/5 success criteria verified

---

## Requirements Coverage (from PLAN frontmatter requirements: [INPUT-02, REC-01, REC-02])

| Requirement | Source Plans | REQUIREMENTS.md Description | Status | Evidence |
|-------------|--------------|----------------------------|--------|----------|
| INPUT-02 | 22-02, 22-04, 22-05, 22-06 | "User can complete a voice-driven ledger entry from the same single screen — voice parser fills amount, category, note, merchant fields in-place; user can edit any field before saving" | SATISFIED | SC-1 + SC-2 verified above. D-07 setters (`updateCategory/Merchant/Note/Satisfaction`) added (transaction_details_form.dart:202-255). Voice batch-fill wired in `_stopRecordingAndCommit`. `entry_source='voice'` round-trip integration test passes. |
| REC-01 | 22-01, 22-04, 22-05 | "Record button's idle-state caption unambiguously communicates the interaction model (tap-to-toggle vs hold-to-record); chosen model is consistent app-wide" | SATISFIED | SC-3 verified above. Caption swap via AnimatedSwitcher; chosen model = hold-to-record (D-03 binding decision). |
| REC-02 | 22-01, 22-03, 22-04, 22-05 | "While recording, record button visibly changes (color/shape/icon) AND caption text changes to '录音中…'; state change perceivable within 100ms" | SATISFIED | SC-4 verified above. AnimatedContainer + 180ms shape morph + green→red gradient + AnimatedSwitcher caption swap. 100ms Stopwatch test passes. |

**Orphaned requirements check:** No additional requirement IDs mapped to Phase 22 in REQUIREMENTS.md beyond INPUT-02/REC-01/REC-02 — all accounted for.

---

## Required Artifacts (cross-referenced against 22-04-PLAN must_haves + behavior)

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/l10n/app_{ja,zh,en}.arb` | `holdToRecord` + `recording` keys added × 3 locales; `tapToRecord` removed | VERIFIED | grep confirms 0 `tapToRecord` references in any ARB; `holdToRecord` and `recording` present in all 3 with correct locale-specific strings. |
| `lib/generated/app_localizations*.dart` | Regenerated with `holdToRecord`/`recording` getters; no `tapToRecord` | VERIFIED | 4 files contain new getters (lines confirmed in app_localizations*.dart). Zero `tapToRecord` references. |
| `lib/core/theme/app_colors.dart` | `recordingGradientStart`/`recordingGradientEnd` constants (light + dark) | VERIFIED | Lines 36-37 (AppColors light: 0xFFE05050/0xFFC03030) + lines 115-116 (AppColorsDark: 0xFFE07070/0xFFB04040). |
| `lib/features/accounting/presentation/widgets/transaction_details_form.dart` | 4 new public setters on TransactionDetailsFormState | VERIFIED | `updateCategory` (202-214), `updateMerchant` (222-226), `updateNote` (232-236), `updateSatisfaction` (251-255). All include `!mounted` guard + idempotency check, mirroring D-14 `updateAmount` pattern. |
| `lib/features/accounting/presentation/screens/voice_input_screen.dart` | Rewritten body: embed form, hold-to-record gesture, animated mic morph, caption swap, full-width Save CTA, focus-auto-stop, WidgetsBindingObserver | VERIFIED | 800 LOC (under 900-line target). All locked decisions implemented (see Key Link table). Vestigial code (`_toggleRecording`/`_navigateToConfirm`/`VoiceRecognitionResultCard`/`_ParsedInfoRow`/`_ParsedDivider`/`tapToRecord`) fully deleted; 1 stale dartdoc comment reference at line 125 (cosmetic, not an actual code reference). |
| `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` | Major rewrite — REC-01/REC-02/INPUT-02/D-08/D-09 tests; old `VoiceRecognitionResultCard`/`タップして録音` assertions removed | VERIFIED | 9 Phase-22 `testWidgets` blocks + 2 preserved permission-toast tests; all 11 pass. Hold-to-record + caption swap + 100ms timing + batch fill + D-08 overwrite + D-09 focus-interrupts + INPUT-02 SC-1 happy path all asserted. |
| `test/widget/.../voice_input_screen_mic_button_golden_test.dart` | NEW idle-state golden harness | VERIFIED | File exists (3,932 bytes), test passes against `goldens/voice_input_screen_mic_button_idle.png` (23,233 bytes baseline). |
| `test/widget/.../goldens/voice_input_screen_mic_button_idle.png` | Golden baseline PNG | VERIFIED | File exists in correct location. |
| `test/integration/features/accounting/voice_save_entry_source_test.dart` | NEW SC-2 integration test | VERIFIED | File exists (15,215 bytes). Mounts real VoiceInputScreen + real AppDatabase. Test passes. |
| `test/widget/.../voice_to_manual_one_step_screen_test.dart` | DELETED (Phase 19 D-16 obsolete) | VERIFIED | File absent (search across test/ + lib/ returns 0 hits). |
| `test/widget/.../transaction_details_form_test.dart` | +10 D-07 setter tests | VERIFIED | 10 D-07 tests across 4 sub-groups (`updateCategory`/`updateMerchant`/`updateNote`/`updateSatisfaction`) all pass. |

---

## Key Link Verification (Wiring)

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `voice_input_screen.dart::_onLongPressEnd` (220) | `_stopRecordingAndCommit` OR `_cancelRecordingAndDiscard` | `held.inMilliseconds < 300` misfire threshold | WIRED | Line 224: `if (held < const Duration(milliseconds: 300))` branches into commit vs discard. |
| `_stopRecordingAndCommit` (286-345) | `TransactionDetailsFormState.{updateAmount,updateCategory,updateMerchant,updateSatisfaction}` | `_formKey.currentState` | WIRED | Lines 331-338: 4 setter calls + conditional `updateSatisfaction`. |
| voice_input_screen.dart Save button onTap (748) | `_formKey.currentState!.submit()` via `_onSavePressed` | `_canSave` predicate gate | WIRED | Line 748: `onTap: _canSave ? _onSavePressed : null`; line 369: `_formKey.currentState!.submit()`. |
| `_VoiceInputScreenState` host-cache fields | AmountDisplay render + `_canSave` predicate | `_hostAmount` + `_hostCategory` updated in setState | WIRED | Lines 549 (`amountStr = _hostAmount`), 106-107 (`_canSave => _hostCategory != null && _hostAmount > 0`), 342-343 (setState mirror in commit path), 604 (modal sheet path). |
| `_merchantFocus` / `_noteFocus` listeners | `_cancelRecordingAndDiscard` (D-09 focus auto-stop) | `_handleFocusChange` | WIRED | Lines 139-140 listeners, 780-785 handler body. FocusNodes passed into TransactionDetailsFormConfig (624-625). |
| `WidgetsBindingObserver.didChangeAppLifecycleState` | `_cancelRecordingAndDiscard` on AppLifecycleState.paused | observer pattern | WIRED | Lines 146 register, 770-776 handler, 794 unregister. |
| ARB keys → S class | flutter gen-l10n regen | locale-specific overrides | WIRED | All 4 generated files contain locale-specific implementations (verified above). |
| TransactionDetailsForm config | `entrySource: EntrySource.voice` | constructor parameter | WIRED | Line 623: hardcoded EntrySource.voice. Flows through Phase 17 D-06 / Phase 18 D-08 to DB write (verified by SC-2 integration test). |

---

## Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|-------------------|--------|
| `voice_input_screen.dart` AmountDisplay | `_hostAmount` (int) | Initially 0; updated in `_stopRecordingAndCommit` (342) AND modal sheet handler (604) | YES — both paths write real parsed/edited amount | FLOWING |
| Embedded `TransactionDetailsForm` | Form internal `_amount`, `_category`, `_storeController.text`, `_memoController.text`, `_soulSatisfaction` | Voice batch-fill via 4 public setters (`_formKey.currentState!.updateXxx`); user edits via chevron tap + TextField input | YES — real parser output + user input | FLOWING |
| Mic button visual state | `_isRecording` | Set true in `_startRecording` (line 244); set false in `_stopRecordingAndCommit` (293), `_cancelRecordingAndDiscard` (356), `_onStatus` (175), `_onError` (184) | YES — multiple write paths from real gesture + service events | FLOWING |
| Caption text | `_isRecording` → AnimatedSwitcher child | Same as above | YES | FLOWING |
| Save button enable | `_canSave` getter → `_hostCategory`/`_hostAmount`/`_isSubmitting` | All three fields actively populated | YES | FLOWING |

**No HOLLOW or DISCONNECTED artifacts detected.** Note: `updateNote` setter is called only as a no-op surface in v1.3 because parser doesn't emit a discrete note field (RESEARCH §A5); this is documented intentional behavior (forward-compat), not a hollow wire.

---

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Voice screen widget tests pass | `flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` | 10/10 tests pass | PASS |
| Golden test passes | `flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_mic_button_golden_test.dart` | 1/1 test passes | PASS |
| Integration test (SC-2) passes | `flutter test test/integration/features/accounting/voice_save_entry_source_test.dart` | 1/1 test passes | PASS |
| D-07 setter tests pass | `flutter test test/widget/features/accounting/presentation/widgets/transaction_details_form_test.dart --plain-name "D-07"` | 10/10 tests pass | PASS |
| `flutter analyze` (whole repo) | `flutter analyze` | 4 issues — all pre-existing, all in unrelated files (firebase_messaging + category_selection_screen.dart onReorder × 2); 0 in Phase-22-touched files | PASS (within scope) |
| Full test suite | `flutter test` | 2000 pass / 15 pre-existing fail (HomeHeroCard goldens + widgets + merchant_database — documented in `deferred-items.md`) | PASS (within scope) |

---

## Anti-Patterns Scan

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `voice_input_screen.dart` | 125 | Stale dartdoc comment references deleted `_navigateToConfirm` | ℹ Info | Cosmetic; not an actual code reference. Safe to ignore or clean up in follow-up. |
| `voice_input_screen.dart` | 182-188 | `_onError` swallows errorMsg + permanent flag (no user feedback) | ⚠ Warning (CR-02) | See follow-up recommendations. Advisory finding from 22-REVIEW.md, surfaced for next phase. |
| `voice_input_screen.dart` | 171-180 | `_onStatus` clears `_isRecording` on done/notListening without commit path | ⚠ Warning (CR-01) | See follow-up recommendations. Real-world transcript loss on recognizer self-termination. |
| `voice_input_screen.dart` | 73 | `_voiceLocaleId = 'zh-CN'` default before provider resolves | ⚠ Warning (WR-01) | First-tap race risk; see follow-up. |
| `voice_input_screen.dart` | 336-338 | Vacuous null check on non-nullable estimatedSatisfaction | ⚠ Warning (WR-02/03) | Stale-read race + unclear intent for survival ledger; see follow-up. |
| `voice_input_screen.dart` | 365-392 | Soul-celebration overlay never paints because popUntil fires first | ⚠ Warning (WR-04) | See follow-up. |
| `voice_save_entry_source_test.dart` | 192-201 | mocktail catch-all `when(findById(any()))` overrides specific stubs | ⚠ Warning (WR-06) | Latent mock issue; test still passes. See follow-up. |
| `transaction_details_form_test.dart` | 910-911, 1056-1057 | addListener/removeListener use distinct closure instances → listener leak | ⚠ Warning (WR-07) | Cosmetic cleanup; tests pass. See follow-up. |

No 🛑 BLOCKER anti-patterns detected within Phase 22 scope. Per phase task description, the 2 code-review BLOCKERS (CR-01, CR-02) are explicitly advisory and do not block phase verification.

**Debt markers in Phase-22-touched files:** none. No `TBD`/`FIXME`/`XXX` introduced.

---

## Human Verification Required

(From 22-VALIDATION.md Manual-Only Verifications section + phase task context.)

### 1. Physical-touch → first-frame perceived latency

**Test:** On a release build of iOS (≥ iPhone 12) and Android (≥ Pixel 6), open `VoiceInputScreen`, touch and hold the mic button. Observe the button visibly entering the recording state within ~100 ms of finger contact. Repeat 5× per device; record any > 200 ms instances.

**Expected:** State change perceivable within 100 ms (REC-02 SC-4 timing intent).

**Why human:** Stopwatch widget test measures gesture-callback-to-build-completion only; physical sensor latency (finger touch → Flutter gesture frame) is platform-dependent and outside the code's control.

### 2. Real-world ja/zh recognizer end-to-end accuracy

**Test:** On a real device, open `VoiceInputScreen`, hold mic, say "1千8百4十元 星巴克" (zh) or「1840円 スターバックス」(ja), release; verify form fields auto-populate with amount=1840 and merchant set. Repeat for 3 utterances per locale.

**Expected:** Form fields populate correctly across natural utterances.

**Why human:** Recognizer accuracy depends on device microphone + Apple/Google STT cloud quality; cannot be unit-tested with mocked services.

### 3. Idle-state golden visual quality

**Test:** Compare the new idle golden against a screenshot of today's pre-Phase-22 circle mic on the same device; confirm no perceptible aliasing degradation.

**Expected:** No visible quality regression at the 72×72 mic-button rendering.

**Why human:** Anti-aliasing rendering can differ subtly between `BoxShape.circle` and `borderRadius: 36` on a 72×72 box; visual review confirms acceptable parity.

---

## Follow-Up Recommendations (advisory — not blocking)

The code review at 22-REVIEW.md flagged 2 BLOCKER findings (CR-01, CR-02) and 7 warnings. Per the phase verification task, these are advisory recommendations for follow-up phases — they do not block Phase 22 completion. Summary:

**Code-review BLOCKERS (advisory):**
- **CR-01:** Self-terminated speech sessions silently drop transcript (lines 171-180, 217-229). Real-world impact on long voice notes (30s listenFor) and pauseFor timeouts in Japanese hesitation patterns. Fix: drive commit path from `_onStatus` when `_pressStart != null`.
- **CR-02:** `_onError` swallows all speech-recognition errors with zero user feedback (lines 182-188). Violates CLAUDE.md "never silently swallow errors" rule. Fix: surface via SoftToast + add localized error ARB keys.

**Warnings (7 total):** WR-01 first-tap locale race, WR-02/03 vacuous null check + stale-read race on `_parseResult.estimatedSatisfaction`, WR-04 soul-celebration overlay unreachable, WR-05 platform-error messages non-localized, WR-06 mocktail catch-all overrides specific stubs, WR-07 listener cleanup uses distinct closures.

Full details in frontmatter `follow_up_recommendations`. Recommend folding into a next-phase plan or a dedicated polish phase.

---

## Pre-Existing Out-of-Scope Items (documented per SCOPE BOUNDARY)

**Test failures (15 total) — NOT regressions caused by Phase 22:**
- `test/golden/home_hero_card_golden_test.dart` — 7 HomeHeroCard golden pixel diffs
- `test/widget/features/home/presentation/widgets/home_hero_card_test.dart` — 4 cumulative Joy assertion failures
- `test/unit/infrastructure/ml/merchant_database_test.dart` — 4 findMerchant case-insensitivity/substring failures

All documented in `deferred-items.md`. Phase 22 does not touch any of these files.

**Analyzer findings (4 total) — pre-existing:**
- 1 firebase_messaging build-cache `include_file_not_found` warning (third-party transitive cache; not actionable)
- 1 firebase_messaging `prefer_final_fields` info (third-party; not actionable)
- 2 `category_selection_screen.dart` onReorder deprecation infos (lines 386, 502 — post v3.41.0-0.0.pre)

---

## Gaps Summary

**Status updated to `gaps_found` per user direction at phase close (2026-05-25).** While the 5 ROADMAP success criteria are met by the code, the user elected to close the two BLOCKER production risks surfaced by code review before marking Phase 22 complete, rather than deferring them to a polish phase. Phase remains in-progress until these gaps are closed via `/gsd:plan-phase 22 --gaps`.

### Gap G-01 — Recognizer self-termination silently drops user's transcript

- **Severity:** blocker (production risk)
- **Source:** Code review CR-01 (see `22-REVIEW.md`)
- **File:** `lib/features/accounting/presentation/screens/voice_input_screen.dart` (lines 171–180, 217–229)
- **Failure mode:** When the speech recognizer self-terminates (`status: done` or `notListening`) — triggered by 30 s `listenFor` expiry, 3 s `pauseFor` mid-press, or platform mic interruption — `_onStatus` clears `_isRecording = false` but does NOT invoke the parse + commit path. The user releases the mic afterward, `_onLongPressEnd` short-circuits on `!_isRecording`, and the transcript is lost with no UI indication.
- **Why current tests miss it:** The fake recognizer in `voice_input_screen_test.dart` never auto-terminates, so the path is unexercised.
- **Expected fix shape:** Drive `_stopRecordingAndCommit` from `_onStatus` when status ∈ {done, notListening} AND `_pressStart != null` (user still holding). Add a widget test that emits a final transcript followed by `onStatus('done')` and asserts the form fills.

### Gap G-02 — Errors silently swallowed; user never notified

- **Severity:** blocker (production risk + project-rule violation)
- **Source:** Code review CR-02 (see `22-REVIEW.md`)
- **File:** `lib/features/accounting/presentation/screens/voice_input_screen.dart` (lines 182–188)
- **Failure mode:** `_onError` ignores both `errorMsg` and the `permanent` flag. UI silently resets to idle on permission revocation, network failure, or engine unavailability. Violates `CLAUDE.md` rules ("never silently swallow errors", "provide user-friendly error messages in UI-facing code").
- **Why current tests miss it:** Test fake never emits errors.
- **Expected fix shape:** Surface error via existing `SoftToast` pattern; for `permanent == true`, gate the mic until reinitialization. Add ARB keys `voiceRecognitionErrorNetwork` / `NoMatch` / `Audio` / `Unknown` × ja/zh/en. Add a widget test that fires `onError('network', false)` and asserts the toast appears.

### Out of scope for gap closure (deferred — surfaces in /gsd:progress as v1.3 debt)

- 3 device-only items (touch latency, real-world recognizer accuracy, idle-golden anti-aliasing parity) — see "Human Verification Required" section above. None are programmatically verifiable; defer to physical-device UAT alongside Phase 20's pending VOICE-02-DEVICE-VERIFY.
- 7 WARNING + 3 INFO findings in 22-REVIEW.md — kept as advisory follow-up; not elevated to gaps. The user opted to close only the two BLOCKERs now.

---

_Verified: 2026-05-25_
_Verifier: Claude (gsd-verifier)_
