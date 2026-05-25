# Phase 22: Voice One-Step Integration + Record Button UX - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 22 wires Phase 20's strengthened `VoiceChunkMerger` + Phase 21's `VoiceCategoryResolver` into the shared `TransactionDetailsForm` (Phase 18) on the voice screen itself, so the voice flow becomes a single-screen experience that fills amount, category, note, and merchant fields in-place rather than navigating to `ManualOneStepScreen` for review. Phase 22 also re-architects the record button: switches the interaction model from today's `tap-to-toggle` to `hold-to-record` (push-to-talk), redesigns the recording-state visual (circle → rounded square + red fill, Mic icon unchanged), swaps the idle/recording captions through `S.of(context)`, and enforces a 100 ms perceived state-change deadline via a stopwatch widget test.

The existing `VoiceInputScreen` file is preserved and refactored — NOT deleted (parallel to how Phase 18's `OcrReviewScreen` co-exists with `ManualOneStepScreen`); `EntryModeSwitcher` continues to `pushReplacement` between three peer screens. The voice screen's default bottom layer becomes `mic + waveform + caption + full-width Save button` (no persistent `SmartKeyboard`); the user taps `AmountDisplay` to summon an `AmountEditBottomSheet` modal for amount correction (Phase 18 pattern, mirroring `TransactionEditScreen`/`OcrReviewScreen`).

**In scope:**

- **`VoiceInputScreen` refactor — host `TransactionDetailsForm` in-place (D-01):**
  - Add `_formKey: GlobalKey<TransactionDetailsFormState>` to `_VoiceInputScreenState`.
  - Replace `VoiceRecognitionResultCard` (today's read-only result display, lines 643+) with a `TransactionDetailsForm(config: TransactionDetailsFormConfig.$new(...))` mounted in the scrollable `Expanded` region above the waveform/mic area.
  - Layout (top-to-bottom): AppBar → `EntryModeSwitcher(selectedMode: InputMode.voice)` → `AmountDisplay` (host-owned, follows Phase 19 D-14 externalized-amount pattern) → scrollable `TransactionDetailsForm` body → waveform → mic button → caption Text → full-width Save button.
  - `AmountDisplay` tap → `showModalBottomSheet` with `AmountEditBottomSheet` (the same sheet Phase 19 extracted for `TransactionEditScreen`/`OcrReviewScreen` — D-14 spillover artifact). NOT a persistent `SmartKeyboard` like `ManualOneStepScreen`.
  - Pass `entrySource: EntrySource.voice` into `TransactionDetailsFormConfig.$new(entrySource: ...)` (form already routes to `CreateTransactionUseCase` with this stamp per Phase 17 D-06).
  - Save button (full-width gradient, Phase 19 D-14 host-CTA shape) calls `_formKey.currentState!.submit()`; current `Next` button (lines 582-627) renamed to Save and rewired.
  - Post-save navigation matches manual: `Navigator.of(context).popUntil((r) => r.isFirst)`.

- **Delete the `_navigateToConfirm` push to `ManualOneStepScreen` (D-02):**
  - Current voice flow at `voice_input_screen.dart:368-408` pushes `ManualOneStepScreen` after the user taps `Next`; this becomes vestigial.
  - Phase 22 voice flow: voice fills the in-screen form → user taps Save → `submit()` → done. No second screen.
  - The `_extractVoiceKeyword` helper (lines 410-431) stays — its output goes into `TransactionDetailsFormConfig.$new(voiceKeyword: ...)` for the form widget's correction-learning hook.

- **Record button rebuild — hold-to-record + 300 ms misfire threshold (D-03):**
  - Replace `GestureDetector(onTap: _toggleRecording)` (voice_input_screen.dart:542) with `GestureDetector(onLongPressStart, onLongPressEnd, onLongPressCancel)`.
  - `onLongPressStart`: record `_pressStart = DateTime.now()`, call `_startRecording()` (existing helper).
  - `onLongPressEnd` / `onLongPressCancel`: compute `held = DateTime.now().difference(_pressStart!)`; if `held < Duration(milliseconds: 300)` → `_cancelRecordingAndDiscard()` (call `_speechService.cancel()` + clear merger buffer + DO NOT batch-fill form). If `held >= 300 ms` → `_stopRecordingAndCommit()` (call `_speechService.stop()` → drain final results → batch-fill form via D-05).
  - Long-press recognizer's `duration: Duration.zero` so `onLongPressStart` fires on first touch (no built-in delay) — the 300 ms threshold is applied on END, not START. This matches walkie-talkie UX (mic activates instantly; release determines whether to commit).
  - `_toggleRecording` is deleted along with its tap-toggle semantics.

- **Recording-state visual: circle → rounded square + red (D-04):**
  - Wrap current 72×72 `Container` in `AnimatedContainer(duration: 180ms, curve: Curves.easeInOut)` so `borderRadius` + `gradient` transition smoothly.
  - `borderRadius`: idle = `BoxShape.circle`; recording = `BorderRadius.circular(16)` (use a single `decoration: BoxDecoration(shape: ..., borderRadius: ...)` pattern — Flutter caveat: `shape: BoxShape.circle` and `borderRadius` are mutually exclusive in `BoxDecoration`, so the implementation MUST switch to `BoxShape.rectangle` + `borderRadius: 36` (≈ circle) when idle and `borderRadius: 16` when recording, OR use `ClipRRect` + always-rectangular `Container` — planner picks).
  - `gradient`: idle = current `[actionGradientStart, actionGradientEnd]` (green); recording = `[Color(0xFFE05050), Color(0xFFC03030)]` (red tones — planner finalizes exact hex from app color palette, prefer existing `AppColors.error` family if it matches the design intent).
  - Mic icon stays `Icons.mic` in BOTH states (no Mic→Stop swap — semantics clear from the shape/color change + caption swap).
  - No pulse animation (rejected — kept lighter per "hold-to-record" semantics, the user is actively holding so they already know it's recording).

- **Caption swap + 2 new ARB keys (D-06):**
  - Remove `lib/l10n/app_{ja,zh,en}.arb` key `tapToRecord` (and its 3 generated getters) — tap-toggle is gone. Replace with two new keys:
    - `holdToRecord`: ja `押して話す` / zh `按住说话` / en `Hold to speak`
    - `recording`: ja `録音中…` / zh `录音中…` / en `Recording…`
  - Caption Text widget (today voice_input_screen.dart:571) wraps in `AnimatedSwitcher(duration: 150ms)` + reads `_isRecording ? l10n.recording : l10n.holdToRecord`.
  - Run `flutter gen-l10n` after ARB edits; ARB parity locked at v1.3 baseline (Phase 19 baseline + new keys; key count rises by 1 net — `tapToRecord` removed, `holdToRecord` + `recording` added).

- **Voice → form batch fill on release (D-05 / D-07):**
  - On `_stopRecordingAndCommit()`: drain merger buffer → run `parseVoiceInputUseCase.execute(finalText, locale)` ONCE → batch-fill form via `_formKey.currentState!`:
    - `updateAmount(amount)` — uses Phase 19 D-14 public method
    - `updateCategory(category, parentCategory)` — NEW public method on `TransactionDetailsFormState` (mirrors `updateAmount` pattern; takes `Category` + nullable parent and calls `setState` internally)
    - `updateMerchant(merchantName)` — NEW public method (sets `_merchantController.text`)
    - `updateNote(noteText)` — NEW public method, optional; current parser doesn't extract a separate note, so this may be a no-op in v1.3 unless planner finds a sensible note source (e.g., voiceKeyword leftover)
  - **No incremental rewrite during recording.** Form is untouched while waveform animates; values only land on release. UX rationale: matches hold-to-record's "speak, release, see result" mental model.
  - **Voice always overwrites (D-08).** If user manually typed in the form before holding the mic, voice batch-fill overwrites all four fields unconditionally. No "skip if user already entered" check, no SoftToast undo. Trade-off accepted: rule is dead simple; user can always re-tap a field and retype.
  - **Text field focus auto-stops recording (D-09).** Add a global `FocusManager`/`FocusScope` listener on `VoiceInputScreen`: if any `TextField` (merchant/note inside form) gains focus while `_isRecording == true`, call `_stopRecordingAndCommit()` automatically and clear the long-press state. Mic stays in idle (red square reverts to green circle) waiting for the next user-initiated long-press. Restart is manual.

- **Tests:**
  - Widget test `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` — extend with:
    - **REC-01 (SC-3):** assert `S.of(context).holdToRecord` text is present in idle state; long-press hold ≥ 300 ms → caption flips to `S.of(context).recording`.
    - **REC-02 (SC-4 visual):** golden `mic_button_idle.png` (idle only, single locale × single theme — keypad button isn't i18n-sensitive); widget test assertions on recording-state `BoxDecoration` (color = red family, borderRadius ≈ 16 vs ≈ 36). **No recording-state golden** (animation frame).
    - **REC-02 (SC-4 timing):** `Stopwatch` test — `onLongPressStart` callback fires → record `Stopwatch.start()` → call `setState(() => _isRecording = true)` → `await tester.pump()` → `Stopwatch.stop()` → `expect(stopwatch.elapsedMilliseconds, lessThan(100))`. Stopwatch wraps the `setState → pump → build` cycle; physical-sensor latency excluded.
    - **REC-01 (SC-3 misfire):** simulate long-press start + end within 200 ms → verify `parseVoiceInputUseCase.execute` was NOT called, form fields unchanged, `_speechService.cancel()` was called.
    - **INPUT-02 (SC-1):** mock `VoiceChunkMerger` + `VoiceCategoryResolver` to emit a known transcript ("1千8百4十元 星巴克") → simulate `onLongPressStart` + 1 s wait + `onLongPressEnd` → assert form's amount = 1840, category = `cat_food_cafe` (resolver result), merchant = `スターバックス` (or `星巴克` per locale). Then simulate user typing in note field → tap Save → assert `transactionRepository.create` called with `entrySource = EntrySource.voice` and note = user-typed value.
    - **SC-2 (DAO):** integration test confirming Phase 22 save path produces a row with `entry_source = 'voice'` (mirrors Phase 19 SC-4 manual test).
    - **D-09 focus-interrupts test:** simulate `onLongPressStart` → in-recording, tap merchant `TextField` → assert recording stops, `_isRecording = false`, mic button returns to idle visual.
    - **D-08 overwrite test:** pump form, manually fill amount=100, then simulate voice recording emitting amount=5000 → assert form amount = 5000 after release.

- **i18n:** as noted in D-06 — 2 new keys added × ja/zh/en, 1 obsolete key removed; `flutter gen-l10n` clean.

- **No Drift schema migration.** Existing v17 schema (`entry_source` column) sufficient. Voice already stamps `EntrySource.voice` today via Phase 17 D-06.

- **No new ADR.** Phase 22 is UI + flow consolidation; doesn't establish new architectural boundaries. Hold-to-record as the chosen interaction model is recorded as a Phase 22 Decision (D-03) and noted as "voice screen is the single voice surface in v1.3" — REC-01's "consistent app-wide" is satisfied by uniqueness, not by cross-surface design.

**Out of scope:**

- **OCR writer (MOD-005)** — `OcrReviewScreen` stays Phase 18 design; v1.4+.
- **OCR scanner screen redesign** — not touched.
- **TransactionEditScreen redesign** — keeps Phase 18's tap-amount-to-open-sheet UX.
- **Long-press shortcuts** (e.g., long-press to cancel mid-recording — would conflict with hold-to-record gesture) — out of scope; misfire-discard < 300 ms is the only short-press behavior.
- **Visual pulse / breathing animation** on recording button — explicitly rejected (D-04 keeps it lighter; user is actively holding).
- **Haptic feedback** on long-press start/end — out of scope (would need ADR for haptic semantics).
- **Voice satisfaction estimator changes** — `voice_satisfaction_estimator.dart` keeps Phase 11 behavior; the form's satisfaction field is filled per the existing soul-ledger branch when `result.ledgerType == LedgerType.soul`.
- **English (en) voice input quality** — Phase 22 wires whatever the recognizer + parser + resolver produce for `en-US` but doesn't add en synonyms/corpus (per REQUIREMENTS.md milestone Out of scope; en voice deferred to v1.4+). Caption strings ARE localized to en for parity, but real-world en accuracy is not gated.
- **HomeHero / Analytics impact** — ADR-016 §3 isolation unchanged.
- **`category_keyword_preferences` learning loop on voice** — Phase 21 D-09 already covers `RecordCategoryCorrectionUseCase` from inside the form widget; Phase 22 just keeps the wiring intact via `voiceKeyword` in the config.
- **Multi-voice-surface coordination** — REC-01 "app-wide consistent" is satisfied by `VoiceInputScreen` being the sole voice surface in v1.3; if a second surface is ever added, it MUST also use hold-to-record per this Decision Record (D-03).
- **Cancel-mid-recording via swipe-up / off-target release gestures** — out of scope; user controls "abort" via the < 300 ms misfire threshold or by sliding finger off the mic (which fires `onLongPressCancel`, same effect as misfire).

</domain>

<decisions>
## Implementation Decisions

### Single-screen integration shape (Area 1)

- **D-01: Keep `VoiceInputScreen` as a peer screen and refactor it to host `TransactionDetailsForm` directly (Option B).**
  - **Why:** Voice and manual stay as siblings under `EntryModeSwitcher`'s `pushReplacement` model. Mode switch is still a route change (matches today's behavior; no `setState`-driven mode-aware screen logic). Diff stays focused on `VoiceInputScreen` body + the deletion of the second-step push. `ManualOneStepScreen` is untouched (other than possible test re-targeting for the voice→manual handoff that no longer exists).
  - **Trade-off:** `VoiceInputScreen` and `ManualOneStepScreen` look almost identical post-Phase-22 (both host `TransactionDetailsForm`); the difference is the bottom layer (mic+waveform vs persistent SmartKeyboard) + the save button location. Risk: drift between the two screens over time. Mitigated by both hosting the SAME `TransactionDetailsForm` widget — form behavior cannot drift, only chrome can.

- **D-02: Delete the `_navigateToConfirm` → `ManualOneStepScreen` push in `VoiceInputScreen`. Voice flow becomes a single screen (no second step).**
  - **Why:** This IS the INPUT-02 promise. Phase 19's voice→manual push was a temporary bridge; Phase 22 retires it.
  - **Impact:** Phase 19's `voice_to_manual_one_step_screen_test.dart` (D-16 regression test) loses its meaning — either delete or re-target to "voice screen save produces `entry_source = 'voice'`" (SC-2). Planner decides whether to rename + repoint or delete + replace with new test.

### Voice-screen bottom layer (Area 1 sub-decision)

- **D-10: Voice screen default bottom layer = mic button + waveform + caption + full-width Save button. NO persistent `SmartKeyboard`.**
  - **Why:** Voice is the primary interaction here; keyboard is the secondary path. Mirrors today's `VoiceInputScreen` layout, preserved.
  - **Amount editing path:** tap `AmountDisplay` → `showModalBottomSheet` with `AmountEditBottomSheet` (the modal extracted in Phase 19 D-14 for `TransactionEditScreen`/`OcrReviewScreen`). This is the established "edit-flow uses modal sheet" pattern; voice screen joins that family rather than `ManualOneStepScreen`'s persistent-keypad family.

- **D-11: Save button = full-width gradient CTA below mic+caption area (rename today's `Next` button to Save).**
  - **Why:** Voice screen has no `SmartKeyboard` row 5 to host Save inline. Bottom CTA is the natural pattern; today's `Next` button already lives in this exact slot — just renames and rewires.
  - **State:** disabled (greyed) until `_formKey.currentState?.canSubmit == true` (or until `_resolvedCategory != null && amount > 0` — same gates as Phase 19's manual Save). Planner picks the predicate.

### Text-input ↔ recording interaction (Area 1 sub-decision)

- **D-09: Text-field focus auto-stops recording.**
  - **Why:** Prevents spoken text from being clobbered by user typing AND prevents misalignment between what user is typing and what the recognizer thinks is happening. User explicitly switches modalities by focusing a TextField; voice yields.
  - **Implementation:** `FocusScope.of(context)` listener on `VoiceInputScreen` build subtree; when focus changes to a `TextField` (merchant/note inside the form), check `_isRecording` and call `_stopRecordingAndCommit()` if true.
  - **Restart UX:** user manually long-presses mic again to resume. No auto-resume on TextField blur (avoid surprise).

### Record button interaction model (Area 2)

- **D-03: Hold-to-record (push-to-talk) with 300 ms misfire threshold.**
  - **Idle caption:** `S.of(context).holdToRecord` → ja `押して話す` / zh `按住说话` / en `Hold to speak`.
  - **Recording caption:** `S.of(context).recording` → ja `録音中…` / zh `录音中…` / en `Recording…`.
  - **Press semantics:** `onLongPressStart` (with `duration: Duration.zero` so press fires instantly) → `_startRecording()`. `onLongPressEnd` / `onLongPressCancel` → compute held duration → if < 300 ms, discard recording (`_cancelRecordingAndDiscard`); if ≥ 300 ms, commit (`_stopRecordingAndCommit`).
  - **Why hold:** PROJECT.md explicitly asked for "tap-vs-long-press" clarity; user chose hold. Walkie-talkie metaphor is physical and unambiguous (finger on button = recording; finger off = stop). No "forgot to stop" failure mode that tap-toggle has.
  - **Why 300 ms misfire:** finger brush / accidental contact shouldn't accidentally start a 0.2 s recording that then fires a garbage `parse` against an empty buffer. 300 ms is the standard touch-vs-hold threshold from Material long-press recognizer.
  - **Save semantics:** Release does NOT auto-save. After release, user can review/edit any form field, then tap the dedicated Save button to commit. This is option-3 of "release semantics" — preserves user review opportunity.
  - **REC-01 "consistent app-wide":** v1.3 has exactly one voice surface (`VoiceInputScreen`); the uniqueness satisfies the app-wide consistency requirement. Recorded here as a binding decision for any future voice surface (any new voice surface added in v1.4+ MUST use hold-to-record per Phase 22 Decision Record).

### Voice → form commit timing & conflict rule (Area 3)

- **D-05: Batch commit on release (Option B). Form is untouched during recording; values land all at once after `onLongPressEnd` fires `_stopRecordingAndCommit()`.**
  - **Why:** Pairs naturally with hold-to-record: hold-speak-release is one logical unit. Form jumping mid-recording would be visually noisy and racy against the merger's window-close logic. Batch keeps state machine simple (one commit per session).
  - **Implementation flow:** `onLongPressEnd` → settle merger window (≤ 2.5 s per Phase 20 D-11; in practice the merger fires immediately on user-stop per Phase 20 D-12) → `parseVoiceInputUseCase.execute(finalText, locale)` → batch-fill the form via `_formKey.currentState!`'s 4 update methods.

- **D-07: Add 3 new public methods on `TransactionDetailsFormState`: `updateCategory(Category, Category? parent)`, `updateMerchant(String)`, `updateNote(String)`. Mirrors Phase 19 D-14's `updateAmount(int)` pattern.**
  - **Why:** Form widget remains the canonical save-side state container (Phase 18 D-01); host pushes voice-fill values in via explicit methods rather than reaching into form internals. Public surface stays narrow but expressive.
  - **Note method:** parser doesn't currently emit a discrete note field; the method exists for forward-compat and may be a no-op call in v1.3 unless planner identifies a sensible source (e.g., `voiceKeyword` leftover). Planner discretion.

- **D-08: Voice always overwrites — no skip-if-already-populated, no undo toast.**
  - **Why:** Simplest rule the user can model mentally ("last action wins"). No state machine for "user-touched vs voice-touched" fields. No transient SoftToast UI.
  - **Trade-off accepted:** User who pre-typed amount=100 then long-presses mic and says "5千" sees form change to 5000. If unintended, user can re-tap amount and retype. Snapshot/undo capability deemed not worth the implementation cost.

### Recording-state visual + 100 ms timing (Area 4)

- **D-04: Circle → rounded square (borderRadius 16) + green→red gradient swap. Mic icon unchanged.**
  - **Why:** Shape + color change is unambiguous and renders well in both themes. Pulse/breathing animation rejected because hold-to-record's continuous physical contact already signals "still recording."
  - **Implementation:** `AnimatedContainer(duration: 180ms, curve: Curves.easeInOut)` so borderRadius + gradient transition smoothly. Use rectangular `BoxDecoration` with `borderRadius` value: idle = 36 (≈ circle on 72×72 box), recording = 16. (Avoids the `BoxShape.circle` ↔ `borderRadius` mutual exclusivity issue.)
  - **Color values:** idle = existing `actionGradientStart`/`actionGradientEnd` (green); recording = red. Planner finalizes exact red hex; prefer existing `AppColors.error` family if it matches the design intent, otherwise add new `AppColors.recordingStart`/`recordingEnd` to `app_colors.dart` + dark variant.

- **D-06: 2 new ARB keys (`holdToRecord`, `recording`) × ja/zh/en; remove obsolete `tapToRecord` key + 3 generated getters. Caption Text widget wraps in `AnimatedSwitcher(duration: 150ms)`.**
  - **Why:** Caption is the second channel of state signaling (parallel to shape+color). Cross-fade transition matches Material motion baseline.
  - **i18n parity:** all 3 locales updated atomically; ARB key count rises by +1 net (Phase 19 baseline + 2 new − 1 removed).

- **D-12: 100 ms timing scope: from `onLongPressStart` callback to `await tester.pump()` build completion. Golden only for idle state.**
  - **Why timing scope:** physical-sensor latency (finger touch → Flutter gesture frame) is platform-dependent and outside our code's control; what we CAN control is "once the gesture callback fires, how long until the UI reflects the new state." That's the meaningful guarantee.
  - **Why idle-only golden:** recording state is mid-animation (`AnimatedContainer` interpolating); golden frames of in-progress animations are flaky. Idle state is stable and proves the "circle + green + Mic icon + holdToRecord caption" baseline. Recording state's visual difference is asserted via widget test inspection (`expect(decoration.color, ...)`, `expect(decoration.borderRadius, ...)`, `expect(find.text(l10n.recording), findsOneWidget)`).
  - **Test shape:** wrap the body of `_startRecording` (or whatever method `onLongPressStart` invokes) in a `Stopwatch.start()/stop()` pair AROUND the `setState` + `await tester.pump()` cycle; assert `< 100 ms`.

### Claude's Discretion

- **Exact red color hex for recording state** — D-04. Pick from existing `AppColors.error` family if it fits, otherwise add `AppColors.recording*` constants (light + dark). User reviews at PR.
- **Animation duration tuning** (180ms for shape, 150ms for caption) — D-04/D-06. Material baselines; planner may tune ±50ms.
- **Save button enable-predicate** — D-11. `_formKey.currentState?.canSubmit` (if such a getter exists) OR `_resolvedCategory != null && _amount > 0`. Planner picks.
- **`updateNote` source for v1.3** — D-07. Parser doesn't emit a discrete note field today. Planner decides whether to: (a) make `updateNote` a public no-op in v1.3 for forward-compat, (b) drop the method entirely and re-add when needed, (c) populate from `voiceKeyword` leftover after merchant/category extraction.
- **Where to dispose long-press state on cancel/end** — D-03. Planner picks whether `_pressStart` lives as a `_VoiceInputScreenState` field or is captured in a closure inside `onLongPressStart`.
- **Whether `_navigateToConfirm` and its helpers are deleted vs renamed** — D-02. The method body is replaced (no second screen push), but the wrapping function name + the `_extractVoiceKeyword` helper may rename to clearer names. Planner picks.

### Folded Todos

No todos folded (cross_reference_todos returned 0 matches for Phase 22).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` §Phase 22 — phase goal + 5 Success Criteria (voice fills shared form in-place; entry_source='voice'; record button idle caption unambiguous interaction model; recording-state visual + caption + 100ms timing; ja/zh/en i18n + flutter analyze clean)
- `.planning/REQUIREMENTS.md` — INPUT-02 (voice fills form on same screen, editable before save), REC-01 (idle caption unambiguous + chosen model consistent app-wide), REC-02 (recording-state visible diff + caption change + 100ms timing); §Out of Scope (English voice deferred); §Cross-cutting (no schema migration unless EDIT-01/02 needs it)
- `.planning/PROJECT.md` — milestone constraint "录音按钮交互优化：静态状态明确"点按 vs 长按"；录音中状态按钮形态 + 提示文案变化（"录音中…"）"

### Project state and adjacent phases
- `.planning/STATE.md` — Phase 18-21 complete; Phase 22 is the v1.3 milestone closer
- `.planning/phases/18-shared-details-form-foundation/18-CONTEXT.md` — `TransactionDetailsForm` contract (`.new` / `.edit` config, `GlobalKey + submit()`, voice-correction in `.new` mode via `voiceKeyword` config), `entry_source` preservation rules
- `.planning/phases/19-manual-one-step-keypad-polish/19-CONTEXT.md` — D-14 externalized-amount pattern (`updateAmount(int)` public method on `TransactionDetailsFormState`); `AmountEditBottomSheet` extracted as the modal amount editor for `TransactionEditScreen`/`OcrReviewScreen`; voice→manual push at `voice_input_screen.dart:351-407` (Phase 22 deletes this push per D-02)
- `.planning/phases/20-voice-number-parser-zh-ja/20-CONTEXT.md` — `VoiceChunkMerger` commits cross-final amount; `VoiceParseResult.amount` is the merger-committed value; merger window default 2.5 s (Phase 20 D-11) but user-stop fires commit immediately (Phase 20 D-12). Phase 22's `_stopRecordingAndCommit` is a user-stop event.
- `.planning/phases/21-voice-category-resolver-level-2-enforcement/21-CONTEXT.md` — `VoiceCategoryResolver` guarantees level-2 `categoryId` on every match; resolver is consumed by `ParseVoiceInputUseCase` which Phase 22 invokes from `_stopRecordingAndCommit`. Phase 22 inherits resolver's `null` semantics (no match) — voice screen falls back to user manual category selection via existing chevron tap.

### Architecture
- `docs/arch/02-module-specs/MOD-009_VoiceInput.md` — canonical voice-input module spec; Phase 22 closes the "single-screen voice" gap relative to MOD-009's flow narrative
- `docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md` — Clean Architecture layering; `VoiceInputScreen` stays in `lib/features/accounting/presentation/screens/`
- `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` — Phase 22 saves use existing snackbar; no streaks/achievement toasts
- `docs/arch/03-adr/ADR-014_Soul_Satisfaction_Unipolar_Positive_Scale.md` — `SatisfactionEmojiPicker` only when ledger == soul (form widget handles)
- `docs/arch/03-adr/ADR-016_Joy_Metric_Visualization_Redesign.md` §3 — HomeHero isolation invariant; Phase 22 doesn't touch HomeHero
- `CLAUDE.md` — Thin Feature rule (`VoiceInputScreen` stays in `presentation/`); Riverpod 3 conventions; intl 0.20.2 pin; `sqlcipher_flutter_libs` pin; immutability via `copyWith`; widget parameter pattern (nullable + provider fallback)

### Code touchpoints (Phase 22 will modify)
- `lib/features/accounting/presentation/screens/voice_input_screen.dart` (813 lines) — body rewrite:
  - Add `_formKey: GlobalKey<TransactionDetailsFormState>` to state
  - Replace `VoiceRecognitionResultCard` mount with `TransactionDetailsForm(config: ...)`
  - Replace `GestureDetector(onTap: _toggleRecording)` (line 542) with `GestureDetector(onLongPressStart/End/Cancel)`
  - Replace caption `l10n.tapToRecord` (line 572) with `AnimatedSwitcher` + `_isRecording ? l10n.recording : l10n.holdToRecord`
  - Wrap mic Container (lines 544-566) in `AnimatedContainer` for shape/color transition
  - Delete `_toggleRecording`; add `_startRecording` (or repurpose existing), `_stopRecordingAndCommit`, `_cancelRecordingAndDiscard`
  - Delete the `_navigateToConfirm` push to `ManualOneStepScreen` (lines 368-408); replace with in-screen submit via `_formKey.currentState!.submit()`
  - Rename `Next` button (lines 582-627) → Save button; rewire `onTap` from `_navigateToConfirm` to `_formKey.currentState!.submit()`
  - Add FocusScope listener for TextField-focus auto-stop (D-09)
- `lib/features/accounting/presentation/widgets/transaction_details_form.dart` (690 lines) — extend:
  - Add 3 new public methods on `TransactionDetailsFormState`: `updateCategory(Category, Category? parent)`, `updateMerchant(String)`, `updateNote(String)` (D-07)
- `lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart` — REUSED as-is (Phase 19 D-14 extracted artifact)
- `lib/l10n/app_ja.arb`, `app_zh.arb`, `app_en.arb` — remove `tapToRecord` + 1 description block × 3; add `holdToRecord` + `recording` × 3 locales (with `@<key>` description blocks)
- `lib/generated/app_localizations*.dart` — regenerate via `flutter gen-l10n` after ARB edits
- `lib/core/theme/app_colors.dart` (+ `app_colors_dark.dart` if separate) — possibly add `recordingGradientStart`/`recordingGradientEnd` constants if `AppColors.error` family doesn't fit (D-04, planner discretion)

### Existing tests to retire / re-target / extend
- `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` (if exists) — extend with REC-01/REC-02/INPUT-02 widget tests + D-09 focus interrupts test
- `test/widget/features/accounting/presentation/screens/voice_to_manual_one_step_screen_test.dart` (Phase 19 D-16) — DELETE or rename + re-target to "voice screen save persists `entry_source = 'voice'`" (SC-2 coverage)
- `test/widget/features/accounting/presentation/widgets/transaction_details_form_test.dart` — extend with 3 new updateXxx method tests
- New golden: `test/widget/features/accounting/presentation/screens/voice_input_screen_mic_button_idle.png` (single locale × single theme; mic button isolated subtree)

### Project rules
- `.claude/rules/coding-style.md` — file size targets; voice_input_screen.dart already at 813 lines, refactor target ≤ 900 (post-Phase-22). If approaching limit, extract `MicButton` widget to `lib/features/accounting/presentation/widgets/mic_button.dart` (planner discretion).
- `.claude/rules/testing.md` — TDD; per-file ≥ 70% coverage; widget tests assert behavior
- `.claude/rules/arch.md` — no new ADR for Phase 22; honors existing ADR-012/014/016
- `.claude/rules/worklog.md` — Phase 22 close requires `doc/worklog/YYYYMMDD_HHMM_*.md` entry

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`TransactionDetailsForm`** (Phase 18) — load-bearing reusable; Phase 22 embeds it for all non-amount, non-mic-area fields. Extended with 3 new public update methods (D-07).
- **`AmountDisplay`** — host-rendered above form (Phase 19 D-14 externalized pattern); voice screen renders it the same way.
- **`AmountEditBottomSheet`** (Phase 19 D-14 extracted artifact) — modal sheet for amount editing; voice screen reuses verbatim. Tap `AmountDisplay` → `showModalBottomSheet(... AmountEditBottomSheet)`.
- **`EntryModeSwitcher`** + `InputMode.voice` — already plumbed at top of `VoiceInputScreen`; unchanged.
- **`VoiceWaveform`** — existing widget at `lib/features/accounting/presentation/widgets/voice_waveform.dart`; unchanged.
- **`SoftToast`** — reusable for save-result feedback; voice screen reuses (already imported).
- **`StartSpeechRecognitionUseCase`** + `SpeechRecognitionService` — Phase 20 already strengthened; Phase 22 keeps usage shape (start/stop/cancel).
- **`VoiceChunkMerger`** (Phase 20) — already wires into `VoiceInputScreen`; Phase 22's `_stopRecordingAndCommit` triggers merger commit on user release.
- **`ParseVoiceInputUseCase`** (Phase 21 wired with `VoiceCategoryResolver`) — Phase 22 invokes from `_stopRecordingAndCommit` to produce a `VoiceParseResult` with guaranteed L2 categoryId.
- **`recordCategoryCorrectionUseCaseProvider`** — wired through form widget via `voiceKeyword` config (Phase 18 D-09 hook); Phase 22 keeps this wiring intact.
- **`VoiceSatisfactionEstimator`** — kept untouched; voice screen continues to compute satisfaction for soul-ledger branch (`voice_input_screen.dart:306-314`) and passes through `VoiceParseResult.estimatedSatisfaction`, which the form widget consumes.
- **`GestureDetector` long-press API** (`onLongPressStart`/`onLongPressEnd`/`onLongPressCancel`) — standard Flutter; supports custom `duration` to make press fire instantly (D-03).
- **`AnimatedContainer`** + **`AnimatedSwitcher`** — standard Flutter motion primitives for D-04/D-06.

### Established Patterns
- **Embeddable form widget + host-owned chrome** (Phase 18 D-01) — voice screen joins this family (host = voice screen owns waveform/mic/Save; form = handles fields, validation, save logic).
- **Externalized amount via `updateAmount(int)` public method on `TransactionDetailsFormState`** (Phase 19 D-14) — Phase 22 extends pattern with 3 sibling update methods (D-07).
- **Modal amount sheet (`AmountEditBottomSheet`) for edit-flow hosts** (Phase 19 D-14 spillover artifact) — voice screen adopts this pattern; only `ManualOneStepScreen` uses persistent SmartKeyboard.
- **`Scaffold.body` = Column of header + Expanded(scrollable) + bottom CTA** — current `VoiceInputScreen` shape; preserved.
- **`AnimatedSlide` for off-screen panel transitions** (Phase 19) — not directly used; D-04 uses `AnimatedContainer` instead (different transition semantics: shape morph, not slide).
- **`FocusScope.of(context)` listener for cross-widget focus changes** (Phase 19 manual screen) — Phase 22 reuses for D-09 TextField-focus auto-stop.
- **`Stopwatch` in widget tests for timing assertions** — standard `flutter_test` pattern, used for Phase 22's 100 ms gate (D-12).

### Integration Points
- **`voice_input_screen.dart:368-408`** — `_navigateToConfirm` push to `ManualOneStepScreen`: DELETED. Replaced with `_formKey.currentState!.submit()` invoked from the Save button.
- **`voice_input_screen.dart:542-567`** — mic `GestureDetector` + Container: rewritten per D-03 (long-press) and D-04 (animated shape/color).
- **`voice_input_screen.dart:569-578`** — caption Text: rewritten per D-06 (AnimatedSwitcher + holdToRecord/recording).
- **`voice_input_screen.dart:582-627`** — Next button: renamed Save + rewired to `submit()`.
- **`voice_input_screen.dart:286-320`** — `_onResult` callback (handles partial + final SpeechRecognitionResult): unchanged in shape, but the `setState(() => _parseResult = ...)` continues to populate `_parseResult` for the existing satisfaction estimator branch. The new commit path (D-05) consumes the merger-committed amount on release, not the per-final-result `_parseResult`.
- **`transaction_details_form.dart`** — new public methods `updateCategory`, `updateMerchant`, `updateNote` on `TransactionDetailsFormState` (D-07).
- **`EntryModeSwitcher`** at `voice_input_screen.dart:503-506` — unchanged; `selectedMode: InputMode.voice` continues to drive 3-mode swap via `pushReplacement`.
- **Save destination (`CreateTransactionUseCase`)** — already wired through form widget per Phase 18; voice path's `entry_source = 'voice'` enforcement comes from `TransactionDetailsFormConfig.$new(entrySource: EntrySource.voice)` (Phase 17 D-06 + Phase 18 D-08).

</code_context>

<specifics>
## Specific Ideas

Downstream agents MUST honor these specifics verbatim:

- **Hold-to-record is the chosen interaction model app-wide.** Any future voice surface added in v1.4+ MUST use the same model. Recorded as binding Phase 22 Decision (D-03).
- **300 ms misfire threshold.** Anything shorter than 300 ms is treated as a tap miss; recording is cancelled and no parser invocation runs. Decided to prevent finger-brush-triggered garbage parses.
- **2 new ARB keys exactly:** `holdToRecord` (ja `押して話す` / zh `按住说话` / en `Hold to speak`) + `recording` (ja `録音中…` / zh `录音中…` / en `Recording…`). `tapToRecord` is removed from all 3 locales + the 3 generated getters (sole production caller is `voice_input_screen.dart:572` which is rewritten in this phase).
- **Mic button shape transition: rectangular Container with `borderRadius` 36↔16 + `AnimatedContainer(180ms, easeInOut)`.** Avoids `BoxShape.circle ↔ borderRadius` mutual exclusivity quirk.
- **Mic icon stays `Icons.mic` in BOTH idle and recording states.** State change is communicated by shape + color + caption, not by icon swap.
- **No pulse / breathing animation on recording state.** Explicitly out of scope (D-04 rationale: hold-to-record's physical contact already signals "still recording").
- **No haptic feedback on press start/end.** Out of scope.
- **Voice always overwrites form fields on batch fill** — no smart skip-if-populated check, no undo SoftToast (D-08).
- **TextField focus auto-stops recording** (D-09).
- **Save is a separate user action after release** — release does NOT auto-save; gives user a window to review/edit (D-03 release semantics).
- **100 ms timing test wraps `setState → tester.pump()` in `Stopwatch`** — measures gesture-callback-to-build-completion, not physical-sensor latency (D-12).
- **Golden for idle state only** — recording state is animating, not amenable to golden (D-12).
- **Voice surface uniqueness** — `VoiceInputScreen` is the sole voice surface in v1.3, which satisfies REC-01's "consistent app-wide" automatically.

Anchor scenarios that downstream agents MUST encode as named `test()` blocks:

- **Hold ≥ 300 ms → commit:** simulate `onLongPressStart` + 1 s wait + `onLongPressEnd` → assert `parseVoiceInputUseCase.execute` called once + form fields updated.
- **Hold < 300 ms → discard:** simulate `onLongPressStart` + 200 ms wait + `onLongPressEnd` → assert `parseVoiceInputUseCase.execute` NOT called + form fields unchanged + `_speechService.cancel()` called.
- **Caption swaps within 100 ms of `onLongPressStart`:** Stopwatch around setState; assert `< 100 ms` AND `find.text(l10n.recording)` finds exactly one widget post-pump.
- **Mic button shape changes on recording:** widget test asserts `BoxDecoration.borderRadius` of `AnimatedContainer` final value transitions from ≈ 36 to ≈ 16.
- **Voice overwrite (D-08):** pump form with amount = 100 manually typed; simulate voice with parsed amount = 5000; assert form amount post-commit = 5000.
- **TextField focus stops recording (D-09):** simulate `onLongPressStart`; in-recording, simulate merchant TextField focus; assert `_isRecording = false`, mic returns to idle visual, recorder cancelled (no commit fired).
- **DAO `entry_source = 'voice'` round-trip (SC-2):** save via voice path; assert Drift row has `entry_source = 'voice'`.
- **Full INPUT-02 happy path (SC-1):** mock merger + resolver to emit transcript "1千8百4十元 星巴克咖啡 100元" (or simpler equivalent); long-press hold 1 s release; assert form has amount = 1840, category = `cat_food_cafe`, merchant matches.

</specifics>

<deferred>
## Deferred Ideas

### Beyond Phase 22 (v1.4+)

- **MOD-005 OCR writer landing** — `OcrReviewScreen` (Phase 18) gets its real OCR pipeline; v1.4+.
- **English voice input quality** — Phase 22 wires en captions but doesn't gate en accuracy. v1.4+ adds en synonyms, en corpus tests, en parser cases.
- **Cancel-mid-recording via swipe-up or off-target release gestures** — current model: release with `onLongPressCancel` (finger off button) discards the same as misfire. Future enhancement: explicit "slide up to cancel" gesture like WhatsApp voice messages.
- **Visual pulse / breathing animation on recording button** — explicitly rejected for Phase 22 (D-04 keeps it lighter). If v1.4+ user testing surfaces "user not sure if recording is still on," revisit.
- **Haptic feedback on long-press start/end** — would need ADR for haptic semantics; v1.4+.
- **Auto-resume recording after TextField blur** — D-09 requires manual restart; if v1.4+ feedback says users find this jarring, add auto-resume gate.
- **Voice "undo last batch fill"** — D-08 chose strict overwrite; if v1.4+ user feedback flags this, add SoftToast snapshot/undo or a "voice respect existing user input" toggle.
- **Add a second voice surface** (e.g., voice-driven quick-edit on home recent-tx tile) — would MUST use hold-to-record per Phase 22 Decision (D-03 "consistent app-wide" record).
- **Persist user's preferred voice locale per surface** — out of scope; settings-level `voiceLocaleIdProvider` already covers app-wide preference.
- **Per-screen save-button shape unification** (manual SmartKeyboard inline Save vs voice screen bottom CTA) — accepted divergence in v1.3 (one host uses persistent keypad, the other uses bottom CTA); revisit if user feedback says it's confusing.

### Beyond v1.3 — carried-forward themes (per PROJECT.md)

- **FAMILY-V2-01/02/03 family privacy hardening** — v1.4+ candidate.
- **FUTURE-QA-01 release-readiness smoke tests** — v1 release gate.
- **FUTURE-DOC-01..06 doc drift cleanup** — v1.4+.
- **FUTURE-TOOL-03 coverage threshold review** — v1.4+ (currently 70% post-v1.0; review whether to raise).
- **TOOL-V2-01 fl_chart 1.x upgrade** — bundle with future analytics chart work.

### Reviewed Todos (not folded)

`cross_reference_todos` returned 0 matches for Phase 22.

</deferred>

---

*Phase: 22-voice-one-step-integration-record-button-ux*
*Context gathered: 2026-05-25*
