---
phase: quick-260622-nhs
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart
  - lib/features/accounting/presentation/screens/voice_input_screen.dart
  - lib/features/accounting/presentation/screens/manual_one_step_screen.dart
  - lib/features/accounting/presentation/screens/ocr_scanner_screen.dart
  - lib/features/accounting/presentation/widgets/hold_to_talk_bar.dart
  - lib/features/accounting/presentation/widgets/voice_listening_overlay.dart
  - lib/features/accounting/presentation/widgets/entry_mode_switcher.dart
  - lib/features/accounting/presentation/widgets/input_mode_tabs.dart
  - lib/features/accounting/presentation/navigation/entry_mode_navigation_config.dart
  - lib/l10n/app_ja.arb
  - lib/l10n/app_zh.arb
  - lib/l10n/app_en.arb
  - lib/generated/*  (gen-l10n regenerated, git add -f)
autonomous: false
requirements: [D-1, D-2, D-3, D-4]
must_haves:
  truths:
    - "On the single 记账 entry screen the 手工/语音 mode Tab is gone (no EntryModeSwitcher / InputModeTabs rendered); manual keypad entry is the only resident state (D-3)"
    - "A full-width 樱粉 「按住说话」 bar sits below the SmartKeyboard; press-and-hold opens the listening overlay, release closes it (D-1)"
    - "On release the parsed amount/category/merchant/date/satisfaction are filled into the SAME form and the screen stays on the manual page — nothing auto-saves (D-2)"
    - "Foreign-currency triple push, JPY-native path, 悦己 satisfaction estimate, and 2.5s chunk-merger behavior are unchanged from the old voice screen (D-4)"
    - "voice_input_screen.dart still compiles and its characterization + Phase 22/23 behavior tests stay green after the recording logic is extracted into the shared mixin (D-3 reuse-not-rewrite)"
    - "OCR entry stays hidden behind kOcrEntryEnabled exactly as before; removing the Tab does not surface or break the OCR flow"
    - "flutter analyze = 0 issues; full flutter test green; ja/zh/en ARB parity holds and gen-l10n is regenerated"
  artifacts:
    - path: "lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart"
      provides: "Reusable hold-to-record session: speech lifecycle + transcript + chunk merger + parse + batch-fill + foreign triple, host-agnostic"
      min_lines: 120
    - path: "lib/features/accounting/presentation/widgets/hold_to_talk_bar.dart"
      provides: "Full-width push-to-talk bar (樱粉 light) below the keyboard"
      min_lines: 30
    - path: "lib/features/accounting/presentation/widgets/voice_listening_overlay.dart"
      provides: "Scrim + 正在聆听 pulse + transcript + 16-bar waveform + recording-red mic + 松开提示 overlay"
      min_lines: 40
  key_links:
    - from: "lib/features/accounting/presentation/screens/manual_one_step_screen.dart"
      to: "voice_ptt_session_mixin.dart"
      via: "with VoicePttSessionMixin; HoldToTalkBar.onHoldStart/onHoldEnd → mixin start/stopAndCommit"
      pattern: "VoicePttSessionMixin"
    - from: "voice_ptt_session_mixin.dart"
      to: "TransactionDetailsFormState"
      via: "host-supplied pttFormState getter → updateAmount/Category/Merchant/Date/Satisfaction/CurrencyTriple"
      pattern: "pttFormState"
    - from: "manual_one_step_screen.dart"
      to: "(removed) EntryModeSwitcher"
      via: "deletion — no mode tab on the entry screen"
      pattern: "EntryModeSwitcher"
---

<objective>
重构记账录入界面为单页 push-to-talk：取消「手工/语音」模式切换 Tab，合并为一页。手工键盘是唯一常驻状态；语音改为底部全宽「按住说话」长条 —— 按住录音、升起聆听浮层、松手把解析结果填入同一张表单并停在手工页等用户确认保存（不自动保存、不连续记账）。

复用而非重写现有语音能力：把 `voice_input_screen.dart` 已有的录音/转写/解析/合并/满意度/外币 triple/波形逻辑抽取为可复用单元（`VoicePttSessionMixin` + 两个 widget），供 PTT 长条调用。旧独立语音页底层逻辑保留、其路由入口移除。

Purpose: 缩短动线（手指停在底部键盘，说话入口也在底部），消灭「模式」心智，零功能回归。
Output: 1 个可复用 mixin、2 个 widget、单页 PTT 录入页、移除切换 Tab/语音路由入口、三语 ARB 同步、golden 重基线、analyze 0 + full test green。

锁定决策（CONTEXT，不可更改）：
- D-1 交互 = V2 底部全宽「按住说话」长条，按住录音、松手结束。
- D-2 松手 = 填入表单·停留确认（不自动保存、不连续记账）。
- D-3 架构 = 合并单页，以 `manual_one_step_screen.dart` 为唯一录入页；移除 `EntryModeSwitcher`/`InputModeTabs` 切换 Tab；抽取语音逻辑复用。
- D-4 复用：外币 triple、悦己满意度、JPY-native、chunk merger 2.5s 窗口、波形 —— 行为保持不变。
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
</execution_context>

<context>
@.planning/quick/260622-nhs-entry-voice-switch-redesign/260622-nhs-CONTEXT.md
@.planning/quick/260622-nhs-entry-voice-switch-redesign/260622-nhs-DESIGN.md
@.planning/quick/260622-nhs-entry-voice-switch-redesign/mocks/entry-ptt-designs.html
@CLAUDE.md

# Source-of-truth files this plan modifies (read once, in full, before editing)
@lib/features/accounting/presentation/screens/voice_input_screen.dart
@lib/features/accounting/presentation/screens/voice_recognition_event_handler_mixin.dart
@lib/features/accounting/presentation/screens/voice_locale_readiness_mixin.dart
@lib/features/accounting/presentation/screens/manual_one_step_screen.dart
@lib/features/accounting/presentation/widgets/entry_mode_switcher.dart
@lib/features/accounting/presentation/widgets/input_mode_tabs.dart
@lib/features/accounting/presentation/widgets/voice_waveform.dart
@lib/features/accounting/presentation/navigation/entry_mode_navigation_config.dart

# Provider + form contract (read the relevant ranges only)
@lib/features/accounting/presentation/providers/repository_providers.dart
@lib/core/constants/feature_flags.dart
</context>

<key_facts>
Discovered during planning — rely on these, do not re-derive:

- Voice recording logic in `_VoiceInputScreenState` is ALREADY well-factored: status/error callbacks live in `VoiceRecognitionEventHandlerMixin` (on `State`), locale cold-start gate in `VoiceLocaleReadinessMixin` (on `ConsumerState`). The screen owns the recording session state (`_isRecording`, `_partialText`, `_finalText`, `_soundLevel`, `_amountMerger`, `_mergedAmount`, `_parseResult`, `_displayCurrency`), the hold gesture (`_onLongPressStart/End/Cancel`), `_startRecording`, `_stopRecordingAndCommit` (the D-05 batch-fill into the form), `_pushVoiceForeignTriple`, `_parseFinalResult` (悦己 satisfaction estimation), `_onResult`, `_onSoundLevel`, and the speech-service lifecycle (init/cancel/dispose, app-lifecycle pause cancel).
- Batch-fill targets a `GlobalKey<TransactionDetailsFormState>` via public setters `updateAmount / updateCategory / updateMerchant / updateDate / updateSatisfaction / updateCurrencyTriple`. The manual screen ALSO holds a `GlobalKey<TransactionDetailsFormState> _formKey` with the SAME setters — so the extracted session can batch-fill the manual form unchanged.
- Providers `parseVoiceInputUseCaseProvider`, `voiceSatisfactionEstimatorProvider`, `appSpeechRecognitionServiceProvider`, `chineseNumeralStateMachineProvider`, `japaneseNumeralStateMachineProvider`, `voiceLocaleIdProvider`, `appGetExchangeRateUseCaseProvider` are feature/application-level — a host mixin reads them via `ref`. NO new providers needed.
- Palette tokens already exist (no new hex, color_literal_scan scans lib/features|application|shared): `fabGradientStart #E09DB4` / `fabGradientEnd #D98CA0` / `actionShadow`, `recordingGradientStart #E5484D` / `recordingGradientEnd #C93040`, `joy`, `joyLight #FBEAEF`, `joyText #A53D5E`, `daily` (waveform color). PTT 长条樱粉浅底 = `palette.joyLight` bg + `palette.joyText` text; recording mic = recordingGradient; waveform = `palette.daily`.
- `VoiceWaveform(soundLevel, isActive, color)` renders the 16 bars — reuse as-is in the overlay.
- Existing ARB keys to REUSE: `record` (记录/記録する/Record) for the manual save key, `holdToRecord` (按住说话), `recording` (录音中…). NEW keys this plan adds: `holdToTalkBar` (bar label, e.g. 「按住说话」), `listeningTitle` (「正在聆听…」), `releaseToFill` (「松开 → 自动填入表单」). Verify the exact final spelling, add to ALL THREE arb, run gen-l10n.
- Mode-switch removal blast radius (refs found): `EntryModeSwitcher` used by manual_one_step_screen / voice_input_screen / ocr_scanner_screen (+ entry_mode_switcher_test, manual_one_step_screen_test). `InputModeTabs`/`InputMode` additionally in entry_mode_navigation_config / entry_widgets_dark_mode_test. `navigateToEntryMode` only in entry_mode_navigation_config + entry_mode_switcher. `VoiceInputScreen` is routed ONLY from entry_mode_navigation_config (the FAB in main_shell_screen opens `ManualOneStepScreen` directly).
- OCR: `kOcrEntryEnabled=false` already hides the OCR tab inside InputModeTabs and short-circuits `navigateToEntryMode(InputMode.ocr)`. `ocr_review_screen` pushes `ManualOneStepScreen` directly (NOT via the switcher). `ocr_scanner_screen` renders `EntryModeSwitcher(selectedMode: InputMode.ocr)` — when the OCR tab is hidden the switcher shows only manual+voice, so the ocr_scanner header switcher must be handled in the removal task.
- `InputMode` enum (manual/ocr/voice) and `entrySource: EntrySource.voice` stamping are SEPARATE concerns from the Tab. `EntrySource.voice` must still be stamped on rows created via the PTT release on the manual screen (so voice provenance survives the merge — see Task 3).

CONSTRAINTS (project gates — every task honors):
- Strict TDD: write/adjust the test (RED) before the implementation (GREEN) in every task.
- `flutter analyze` = 0 issues; `flutter test` full suite green (run FULL suite at the gate, not a scoped subset — architecture tests like hardcoded_cjk_ui_scan only run in the full pass).
- All UI text via `S.of(context)`; update ja/zh/en together; `flutter gen-l10n`; `lib/generated/` is gitignored-yet-tracked → `git add -f` regenerated files.
- No raw hex in lib/features|application|shared (color_literal_scan) — use `context.palette.*` only.
- No `UnimplementedError` in providers; Riverpod 3 entry-points + naming + `ref.listen` for side-effects.
- Goldens are macOS-baselined (we are on macOS) — re-baseline ONLY affected goldens, scoped `--update-goldens`.
- File size < 800 LOC (CLAUDE.md). The session mixin keeps voice_input_screen.dart well under cap; the manual screen must also stay under cap after wiring (extract the bar/overlay into widgets, keep the host thin).
</key_facts>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Extract reusable VoicePttSessionMixin from VoiceInputScreen (no behavior change)</name>
  <files>
    lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart (new),
    lib/features/accounting/presentation/screens/voice_input_screen.dart (re-host the mixin),
    test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart (unchanged-behavior characterization stays green),
    test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart (new)
  </files>
  <behavior>
    - Mixin exposes recording-session state read by a host UI: isRecording, partialText, finalText, soundLevel, displayCurrency (and a way to read the live transcript for the overlay).
    - Host supplies, via abstract members: a `GlobalKey<TransactionDetailsFormState>` (or a `TransactionDetailsFormState? get pttFormState`) to batch-fill, and the active book context already present on the form.
    - startPttSession() begins recording exactly as `_startRecording` does today (locale-gated, merger rebuilt, speech started); stopPttSessionAndCommit() runs the verbatim `_stopRecordingAndCommit` batch-fill (amount via merger-or-parse, category lookup, merchant, date, satisfaction for joy, foreign triple via `_pushVoiceForeignTriple`); cancel path uses dispose+cancel (NOT stop+stop) — Pitfall 6.
    - The misfire threshold (300 ms), app-lifecycle pause cancel, text-field-focus auto-cancel, and the D-05 intra-session `notListening` heuristic are preserved (the existing two mixins remain the source of those; the new mixin composes with them or the host keeps wiring them).
    - VoiceInputScreen, re-hosting the mixin, renders byte-identically and ALL its existing tests pass with no assertion changes (this is a pure refactor — characterization test is the contract).
  </behavior>
  <action>
    Create `VoicePttSessionMixin` on `ConsumerState<W extends ConsumerStatefulWidget>` that OWNS the recording-session fields and methods currently inlined in `_VoiceInputScreenState`: `_isRecording`, `_partialText`, `_finalText`, `_soundLevel`, `_amountMerger`, `_mergedAmount`, `_parseResult`, `_displayCurrency`, plus `startRecording` (from `_startRecording`), `stopRecordingAndCommit` (from `_stopRecordingAndCommit`), `cancelRecordingAndDiscard`, `pushVoiceForeignTriple`, `extractRate`, `onResult`, `onSoundLevel`, `parseVoiceInput`, `parseFinalResult`, and the speech-service init/dispose lifecycle. The mixin reads all use cases via `ref` (parseVoiceInputUseCaseProvider, voiceSatisfactionEstimatorProvider, appSpeechRecognitionServiceProvider, the two numeral state machines, appGetExchangeRateUseCaseProvider). Declare abstract members the host must provide: the form-state accessor to batch-fill (return type `TransactionDetailsFormState?`), and an injectable `StartSpeechRecognitionUseCase?` for tests. Keep `VoiceRecognitionEventHandlerMixin` and `VoiceLocaleReadinessMixin` exactly as-is and compose them (the new mixin can satisfy their abstract contract, or the host keeps wiring all three `with` mixins — choose whichever keeps the diff smallest and both screens under the 800-LOC cap). Then refactor `_VoiceInputScreenState` to host `VoicePttSessionMixin` and delete the now-duplicated inlined logic, leaving only its UI (AppBar, AmountDisplay, embedded form, the voice card, save button) wired to the mixin's state/methods. This must be a NO-BEHAVIOR-CHANGE refactor — do NOT alter parse/merger/foreign/satisfaction semantics. Add a unit test that drives the mixin against a fake host + injected `StartSpeechRecognitionUseCase` mock and asserts a batch-fill produces the expected form setter calls (amount/category/merchant/date) and the foreign-triple path on a detected-currency utterance. Run `build_runner` only if you touched annotated files (this mixin is hand-written, no codegen).
  </action>
  <verify>
    <automated>flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart test/unit/features/accounting/presentation/screens/voice_input_screen_characterization_test.dart test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart test/widget/features/accounting/presentation/screens/voice_input_screen_foreign_save_test.dart test/integration/features/accounting/voice_save_entry_source_test.dart && flutter analyze lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart lib/features/accounting/presentation/screens/voice_input_screen.dart</automated>
  </verify>
  <done>VoicePttSessionMixin exists and owns the recording/parse/merger/foreign/satisfaction logic; voice_input_screen.dart re-hosts it and all its pre-existing tests pass with zero assertion changes; new mixin unit test green; analyze 0 on both files.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: HoldToTalkBar + VoiceListeningOverlay widgets (V2 visual, palette-only)</name>
  <files>
    lib/features/accounting/presentation/widgets/hold_to_talk_bar.dart (new),
    lib/features/accounting/presentation/widgets/voice_listening_overlay.dart (new),
    lib/l10n/app_ja.arb, lib/l10n/app_zh.arb, lib/l10n/app_en.arb,
    lib/generated/* (gen-l10n),
    test/widget/features/accounting/presentation/widgets/hold_to_talk_bar_test.dart (new),
    test/widget/features/accounting/presentation/widgets/voice_listening_overlay_test.dart (new)
  </files>
  <behavior>
    - HoldToTalkBar: full-width 48dp bar, 樱粉浅底 (palette.joyLight) + joyText label + a small joy dot + mic glyph, label from `S.of(context).holdToTalkBar`. Exposes onHoldStart / onHoldEnd / onHoldCancel callbacks via a press-and-hold gesture (LongPressGestureRecognizer with duration: Duration.zero, mirroring the voice mic button), hit area = whole bar. Stateless about recording — the host owns session state.
    - VoiceListeningOverlay: shown only while holding. Scrim (semi-transparent) + a rounded-top sheet containing: 「正在聆听…」 (S.listeningTitle) with a pulsing recording-red dot, the live transcript text (passed in), VoiceWaveform(soundLevel,isActive:true,color: palette.daily), a recording-red rounded mic (recordingGradient), and 「松开 → 自动填入表单」 (S.releaseToFill). All text via S.of(context); all colors via context.palette (zero hex).
    - Three new ARB keys added to ja/zh/en with @-metadata, parity holds, gen-l10n regenerated.
  </behavior>
  <action>
    Write `HoldToTalkBar` as a StatelessWidget taking `onHoldStart`/`onHoldEnd`/`onHoldCancel` callbacks; use a `RawGestureDetector` with a `LongPressGestureRecognizer(duration: Duration.zero)` (same recognizer wiring the current voice mic button uses) so press-down starts and release ends. Style per V2 mock: `Container` full width, height ~48, `color: palette.joyLight`, top border `palette.borderDefault` (or the existing divider token), centered Row of [dot (palette.joy), mic icon, Text(S.holdToTalkBar, style amount-agnostic labelMedium, color palette.joyText)]. Write `VoiceListeningOverlay` as a StatelessWidget taking `transcript`, `soundLevel`, and rendering the scrim + bottom sheet exactly as the mock's `.ptt` block: grab handle, listening row (pulsing red dot via a small AnimatedOpacity/TweenAnimationBuilder + Text S.listeningTitle, color palette.recordingGradientStart), transcript Text, `VoiceWaveform`, recording-red mic container (recordingGradient + actionShadow), Text S.releaseToFill. Add `holdToTalkBar`, `listeningTitle`, `releaseToFill` to all three ARB files (confirm final wording: zh 按住说话 / 正在聆听… / 松开后自动填入表单; ja/en accordingly) with @-descriptions; run `flutter gen-l10n`; `git add -f lib/generated/`. Write widget tests: HoldToTalkBar fires onHoldStart on press-down and onHoldEnd on release and renders the localized label; VoiceListeningOverlay renders the transcript, the localized listening title + release hint, and a VoiceWaveform. Keep both files small and palette-only.
  </action>
  <verify>
    <automated>flutter gen-l10n && flutter test test/widget/features/accounting/presentation/widgets/hold_to_talk_bar_test.dart test/widget/features/accounting/presentation/widgets/voice_listening_overlay_test.dart test/architecture/arb_key_parity_test.dart test/architecture/color_literal_scan_test.dart test/architecture/hardcoded_cjk_ui_scan_test.dart && flutter analyze lib/features/accounting/presentation/widgets/hold_to_talk_bar.dart lib/features/accounting/presentation/widgets/voice_listening_overlay.dart</automated>
  </verify>
  <done>Both widgets exist, palette-only (color_literal_scan green), localized (CJK scan + arb parity green); hold-gesture callbacks and overlay content verified by widget tests; gen-l10n regenerated and force-added.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: Wire PTT into ManualOneStepScreen (single-page push-to-talk, fill-and-stay)</name>
  <files>
    lib/features/accounting/presentation/screens/manual_one_step_screen.dart,
    test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart
  </files>
  <behavior>
    - ManualOneStepScreen hosts VoicePttSessionMixin (its `_formKey` is the batch-fill target). The HoldToTalkBar renders below the SmartKeyboard (V2: keypad on top, bar on bottom). The form's voice batch-fill uses the SAME `_formKey` already on the screen.
    - Pressing-and-holding the bar starts a recording session and shows VoiceListeningOverlay (in the existing body Stack); releasing runs stopPttSessionAndCommit → fills amount/category/merchant/date/satisfaction + foreign triple into the form, hides the overlay, and the screen STAYS on the manual page (D-2: no auto-save, no continuous mode side-effects). The amount headline (AmountDisplay) reflects the filled value/currency.
    - A row created after a PTT fill carries `EntrySource.voice` provenance; a row created by pure manual keypad stays `EntrySource.manual`. (Track a flag flipped on a successful PTT commit; thread it into the form config / submit so voice provenance survives the merge.)
    - The 300 ms misfire threshold, app-pause cancel, and text-field-focus auto-cancel behaviors carry over from the mixin. SmartKeyboard, foreign card, KeyboardToolbar, save guard, continuous-mode FAB path all keep working unchanged.
    - EntryModeSwitcher is removed from this screen (handled fully in Task 4; this task at minimum stops depending on it for layout).
  </behavior>
  <action>
    Add `VoicePttSessionMixin` to `_ManualOneStepScreenState`'s `with` clause and implement its abstract form-state accessor to return `_formKey.currentState`. Initialize/dispose the speech service via the mixin (mirror the voice screen's init/dispose) and compose `VoiceRecognitionEventHandlerMixin` + `VoiceLocaleReadinessMixin` as the voice screen does. In `build`, below the `AnimatedSlide(SmartKeyboard)` add the `HoldToTalkBar` (only when `_showSmartKeypad`, so it hides with the keypad when a TextField is focused) wired to `startPttSession`/`stopPttSessionAndCommit`/`cancelRecordingAndDiscard`. In the body `Stack`, conditionally render `VoiceListeningOverlay(transcript: <mixin partial-or-final>, soundLevel: <mixin soundLevel>)` while `isRecording`. On release, the mixin's commit batch-fills `_formKey` and the screen stays put — do NOT call `_save()` or pop. Set a `_lastFillWasVoice` flag on a successful PTT commit and thread `entrySource: _lastFillWasVoice ? EntrySource.voice : widget.entrySource` into the form config (or via a form setter) so the saved row's provenance is `voice` after a PTT fill — reset the flag if the user clears the amount or edits manually enough to count as manual (keep the rule simple and documented; minimum: voice provenance after a voice fill until the next manual clear). Keep the file under 800 LOC by relying on the widgets from Task 2 and the mixin from Task 1 (no inline recording logic here). RED first: extend manual_one_step_screen_test with: (a) HoldToTalkBar renders below SmartKeyboard; (b) hold → overlay shown, release → overlay gone and form fields filled (drive the mixin with an injected speech mock as voice_input_screen_test does); (c) a PTT-filled save stamps EntrySource.voice while a keypad-only save stays EntrySource.manual; (d) the screen does NOT pop on release (still on the manual page). Update the existing `expect(find.byType(EntryModeSwitcher), findsOneWidget)` assertion to `findsNothing` (the Tab is gone) — and remove EntryModeSwitcher from this screen's build.
  </action>
  <verify>
    <automated>flutter test test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart test/integration/features/accounting/manual_save_entry_source_test.dart test/integration/features/accounting/voice_save_entry_source_test.dart && flutter analyze lib/features/accounting/presentation/screens/manual_one_step_screen.dart</automated>
  </verify>
  <done>Single-page PTT works: hold the bottom bar → overlay → release fills the form and stays on the manual page (no auto-save); PTT-filled rows carry EntrySource.voice, keypad rows stay manual; EntryModeSwitcher no longer rendered on the screen; analyze 0; file under 800 LOC.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 4: Remove mode-switch surface + voice route entry; prune dead code & ARB</name>
  <files>
    lib/features/accounting/presentation/widgets/entry_mode_switcher.dart (delete),
    lib/features/accounting/presentation/widgets/input_mode_tabs.dart (delete or reduce to InputMode enum only),
    lib/features/accounting/presentation/navigation/entry_mode_navigation_config.dart (remove navigateToEntryMode/VoiceInputScreen route entry),
    lib/features/accounting/presentation/screens/ocr_scanner_screen.dart (drop EntryModeSwitcher header),
    lib/features/accounting/presentation/screens/voice_input_screen.dart (drop EntryModeSwitcher; keep screen file as retained-but-unrouted, OR delete if zero refs remain — decide per grep),
    lib/l10n/app_ja.arb, lib/l10n/app_zh.arb, lib/l10n/app_en.arb (remove orphaned manualInput/voiceInput/ocrScan keys ONLY if zero source refs),
    lib/generated/* (gen-l10n),
    test/widget/features/accounting/presentation/widgets/entry_mode_switcher_test.dart (delete),
    test/widget/features/accounting/presentation/widgets/entry_widgets_dark_mode_test.dart (drop InputModeTabs cases)
  </files>
  <behavior>
    - No screen renders EntryModeSwitcher / InputModeTabs as a 手工/语音 Tab. `navigateToEntryMode` and the VoiceInputScreen route entry are removed (the FAB already opens ManualOneStepScreen directly; the PTT bar is the only voice entry now).
    - OCR stays hidden behind kOcrEntryEnabled and its infrastructure/screens are untouched; the ocr_scanner_screen header no longer shows the switcher (it showed manual+voice tabs that no longer exist). The `InputMode` enum may be retained only if still referenced (entrySource is a SEPARATE enum and stays).
    - No dead code, no dangling imports/refs, no orphaned ARB keys. `manualInput`/`voiceInput`/`ocrScan` removed from all three ARB files ONLY after grep confirms zero source consumers (the Tab labels are their only users); otherwise leave them.
    - voice_input_screen.dart is retained as a non-routed file with its underlying logic intact (D-3: "保留底层逻辑"), UNLESS grep shows it is referenced by nothing reachable — in which case deletion is allowed but its mixin/helpers (reused by Task 1) must remain.
  </behavior>
  <action>
    Grep every reference: `EntryModeSwitcher`, `InputModeTabs`, `navigateToEntryMode`, `entry_mode_navigation_config`, `VoiceInputScreen`. Remove the EntryModeSwitcher widget from ocr_scanner_screen (and the now-unused import) and from voice_input_screen's build. Delete `entry_mode_switcher.dart` and its test. In `entry_mode_navigation_config.dart`, remove `navigateToEntryMode` and the manual/voice/ocr route map (the FAB and ocr_review push screens directly); if nothing else in the file is used, delete the file and its imports. Reduce `input_mode_tabs.dart` to just the `InputMode` enum IF the enum is still referenced anywhere (entrySource stamping, route configs) — otherwise delete the whole file; keep the OCR feature-flag path semantics intact (do not change `kOcrEntryEnabled` or the OCR screens). Decide voice_input_screen.dart's fate by grep: keep it (retained, unrouted, logic intact per D-3) if its mixins/helpers/tests still reference it; only delete if fully unreachable AND the shared mixin (Task 1) + voice helpers remain. Run `grep -nE "\"manualInput\"|\"voiceInput\"|\"ocrScan\"" lib/ -r` and source-side `grep -rn "\.manualInput\b|\.voiceInput\b|\.ocrScan\b" lib/` — if zero source consumers remain, delete those three keys symmetrically from ja/zh/en + gen-l10n + `git add -f`; if any consumer remains (e.g. ocrScanTitle is a different key — do NOT touch it), leave them. Update entry_widgets_dark_mode_test to drop the InputModeTabs cases (or delete the file if it only covered those). RED first: adjust/remove the affected tests to assert absence (no EntryModeSwitcher, no navigateToEntryMode) before deleting the production code, so the suite proves the removal rather than just compiling.
  </action>
  <verify>
    <automated>! grep -rn "EntryModeSwitcher\|navigateToEntryMode" lib/ && flutter test test/architecture/arb_key_parity_test.dart test/architecture/hardcoded_cjk_ui_scan_test.dart test/widget/features/accounting/ && flutter analyze lib/</automated>
  </verify>
  <done>Zero EntryModeSwitcher/navigateToEntryMode refs in lib/; OCR hidden-flag path untouched; no dangling imports or dead code; orphaned Tab ARB keys removed (or justified as retained); affected tests updated/removed; analyze 0.</done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <name>Task 5: Full gate — golden re-baseline (macOS) + analyze 0 + full suite + on-device PTT verify</name>
  <what-built>
    Single-page push-to-talk 记账 entry: 手工/语音 Tab removed; bottom full-width 「按住说话」 bar below the keypad; hold → listening overlay (transcript + waveform + recording-red mic) → release fills the same form and stays on the manual page (no auto-save). Voice logic reused via VoicePttSessionMixin; foreign triple / satisfaction / JPY-native / chunk-merger behavior unchanged; OCR hidden-flag path intact.
  </what-built>
  <action>
    Run `flutter analyze` (expect 0). Re-baseline ONLY the goldens affected by the layout change on macOS with a scoped `--update-goldens` (the manual screen now shows the PTT bar; any voice-screen goldens that survive Task 4 — e.g. voice_input_screen_mic_button_idle.png — only re-baseline if their widget actually changed; do NOT blanket-update). Then run the FULL suite: `flutter test` (the full pass is required so architecture tests — hardcoded_cjk_ui_scan, color_literal_scan, arb_key_parity, provider_graph_hygiene — actually execute). Ensure `lib/generated/` regenerated files are `git add -f`-ed. Confirm coverage did not regress materially.
  </action>
  <how-to-verify>
    On a physical device / simulator (locale ja, then switch zh):
    1. Open the 记账 entry screen via the FAB. Confirm there is NO 手工/语音 Tab at the top; the keypad is resident; a full-width 樱粉 「按住说话」 bar sits below the keypad.
    2. Press AND HOLD the bar. Confirm the listening overlay rises (正在聆听… pulse + live transcript + 16-bar waveform + recording-red mic + 松开提示). Speak e.g. "拿铁 一千二百八".
    3. Release. Confirm the overlay drops, the amount/category/merchant/date fill into the SAME form, AND the screen stays on the manual page (it does NOT save or pop). Manually tweak a field, then tap 记录 to save.
    4. Speak a foreign utterance (e.g. "拿铁 十美金") and confirm the foreign triple + headline pill currency behave exactly as the old voice screen did.
    5. Speak a 悦己 utterance and confirm the satisfaction estimate fills as before.
    6. Confirm a very short accidental tap on the bar does NOT record (300 ms misfire), and locking the screen mid-hold cancels cleanly.
  </how-to-verify>
  <resume-signal>Type "approved" if the single-page PTT flow works and nothing regressed, or describe issues (e.g. overlay glitch, wrong fill, OCR tab surfaced, provenance wrong).</resume-signal>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| microphone → speech recognizer → parser | untrusted spoken input parsed into amount/category/merchant/date before it touches the form |
| exchange-rate fetch (network) → foreign triple | a stale/failed rate must never persist a wrong JPY amount (ADR-021: triple excluded from hash chain) |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-nhs-01 | Tampering | foreign-triple push on PTT release | mitigate | Reuse the verbatim `_pushVoiceForeignTriple` staleness/RateUnavailable guards (Task 1 extracts them unchanged — no new push path) so a stale-rate JPY is never persisted (D-4) |
| T-nhs-02 | Denial of Service | mic stuck "live" after app pause / focus steal | mitigate | Preserve app-lifecycle pause-cancel + text-field-focus auto-cancel + 300 ms misfire discard in the extracted mixin (Task 1/3); release uses dispose+cancel on misfire (Pitfall 6) |
| T-nhs-03 | Repudiation | entry-source provenance lost in the merge | mitigate | PTT-filled rows stamp `EntrySource.voice`, keypad rows stay `EntrySource.manual` (Task 3) — provenance survives the single-page merge; verified by entry_source integration tests |
| T-nhs-SC | Tampering | npm/pip/cargo installs | accept | No package-manager installs in this plan — all deps (speech_to_text, fl_chart, etc.) already in pubspec; no new dependency added |
</threat_model>

<verification>
- `flutter analyze` = 0 issues across lib/.
- FULL `flutter test` green (architecture tests included: hardcoded_cjk_ui_scan, color_literal_scan, arb_key_parity, provider_graph_hygiene).
- `grep -rn "EntryModeSwitcher\|navigateToEntryMode" lib/` returns nothing.
- voice_input_screen behavior tests + characterization pass with zero assertion changes after the mixin extraction (proves no-behavior-change refactor).
- New mixin/widget unit+widget tests green; PTT fill-and-stay + EntrySource.voice provenance proven in manual screen tests.
- gen-l10n regenerated, ja/zh/en parity holds, `lib/generated/` force-added.
- Goldens re-baselined ONLY where layout changed (macOS), scoped update.
</verification>

<success_criteria>
- Single 记账 entry page with NO 手工/语音 Tab; manual keypad resident; full-width 「按住说话」 bar below the keypad (D-1, D-3).
- Hold → listening overlay; release → parsed fields fill the SAME form and the screen stays on the manual page with no auto-save and no continuous-record loop (D-2).
- Foreign triple, 悦己 satisfaction, JPY-native, 2.5s chunk merger, waveform all behave identically to the old voice screen (D-4) — proven by the unchanged voice behavior suite.
- Voice recording logic is reused via `VoicePttSessionMixin` (extracted, not rewritten); old voice screen's underlying logic retained (D-3).
- OCR hidden-flag path untouched; no dead code / dangling refs / orphaned ARB keys.
- `flutter analyze` 0; full `flutter test` green; goldens re-baselined on macOS where needed.
</success_criteria>

<output>
Worklog (project rule): after the gate passes, write `docs/worklog/YYYYMMDD_HHMM_entry_ptt_single_page.md` summarizing the change, decisions, problems/solutions, test results, and the commit hash.
Quick-task note: no SUMMARY frontmatter scaffolding required beyond the standard quick-task record; update the STATE.md Quick Tasks table entry for 260622-nhs on completion.
</output>
