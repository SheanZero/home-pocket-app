---
phase: quick-260707-kfb
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/features/accounting/presentation/screens/manual_one_step_screen.dart
  - lib/features/accounting/presentation/screens/manual_one_step_keypad.dart
  - lib/features/accounting/presentation/screens/manual_one_step_currency.dart
  - lib/features/accounting/presentation/screens/manual_one_step_save.dart
  - lib/features/accounting/presentation/screens/voice_ptt_session_fill_orchestration.dart
  - lib/features/accounting/presentation/screens/voice_ptt_session_foreign_notice.dart
  - lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart
  - lib/application/voice/voice_amount_notice_policy.dart
  - lib/application/voice/voice_fill_decision.dart
  - lib/features/settings/domain/models/app_settings.dart
  - lib/features/settings/domain/repositories/settings_repository.dart
  - lib/data/repositories/settings_repository_impl.dart
  - lib/features/settings/presentation/widgets/voice_section.dart
  - lib/application/voice/start_speech_recognition_use_case.dart
  - lib/infrastructure/speech/speech_recognition_service.dart
  - lib/l10n/app_ja.arb
  - lib/l10n/app_zh.arb
  - lib/l10n/app_en.arb
autonomous: true
requirements:
  - KFB-1-HOST-SLIM
  - KFB-2-VOICE-POLICY-OBJECTS
  - KFB-3-PRIVACY-DEGRADATION-SETTING
  - KFB-4-RESET-MIRROR-TESTS
  - KFB-5-NOTICE-PRIORITY-TESTS

must_haves:
  truths:
    - "KFB-1: manual_one_step_screen.dart is under 800 lines; keypad/currency/save logic lives in same-library part files; every existing + new test stays green (no behavior drift from the move)."
    - "KFB-4: after a voice fill, a manual keypad edit keeps voice provenance and a reset restores _lastFillWasVoice from the snapshot; the keypad-mirror path is correct when the foreign-currency triple was already written before mirror runs."
    - "KFB-2: the voice fill ordering and the amount-notice precedence are decided by pure Dart objects (VoiceFillDecision, VoiceAmountNoticePolicy) with zero Flutter imports and no State access; the State calls into them and they never reach back into State."
    - "KFB-5: the notice precedence conversion-undo > repair-adopt > large-amount is locked by tests that assert on VoiceAmountNoticePolicy's decision independent of UI copy — a copy change cannot silently reorder business precedence."
    - "KFB-3: the settings page displays current on-device recognition status AND offers a switch to turn OFF auto-degradation; when disabled, an on-device failure is surfaced instead of a silent cloud retry; default behavior stays auto-degrade allowed (backward compatible, no Drift migration)."
  artifacts:
    - lib/features/accounting/presentation/screens/manual_one_step_keypad.dart
    - lib/features/accounting/presentation/screens/manual_one_step_currency.dart
    - lib/features/accounting/presentation/screens/manual_one_step_save.dart
    - lib/application/voice/voice_amount_notice_policy.dart
    - lib/application/voice/voice_fill_decision.dart
    - "AppSettings.voiceAllowOnDeviceFallback field (freezed, @Default(true))"
    - "SettingsRepository.setVoiceAllowOnDeviceFallback + SharedPreferences persistence"
    - "voice_section.dart on-device status indicator + auto-degradation SwitchListTile"
    - "3 new ARB keys x {ja,zh,en} + regenerated lib/generated l10n"
    - test/widget/features/accounting/presentation/screens/manual_one_step_reset_mirror_characterization_test.dart
    - test/unit/application/voice/voice_amount_notice_policy_test.dart
    - test/unit/application/voice/voice_fill_decision_test.dart
    - test/widget/features/settings/presentation/widgets/voice_section_test.dart
  key_links:
    - "Part files share the private _ManualOneStepScreenState via `part of 'manual_one_step_screen.dart'` + `extension on _ManualOneStepScreenState`; the sole sanctioned transformation is setState(...) -> _rebuild(...) (mirrors manual_one_step_voice_wiring.dart's onPttSessionChanged precedent)."
    - "voice_ptt_session_foreign_notice.dart calls VoiceAmountNoticePolicy.decide(...) then maps the returned notice variant to ARB copy + SnackBar; voice_ptt_session_fill_orchestration.dart consults VoiceFillDecision for the resolve-on-final gating/order."
    - "voice_ptt_session_mixin.dart's two startListening call sites read ref.read(appSettingsProvider).value?.voiceAllowOnDeviceFallback ?? true and thread it through StartSpeechRecognitionUseCase.startListening into SpeechRecognitionService's on-device->cloud fallback guard."
    - "voice_section.dart toggle calls settingsRepository.setVoiceAllowOnDeviceFallback(value) then ref.invalidate(appSettingsProvider) (mirrors the setVoiceLanguage pattern)."
---

<objective>
Continuation of the voice / manual-entry hardening line (most recently quick-260707-bwy). Five pre-decided deliverables, grouped so the orchestrator dispatches them to THREE sequential executor waves (A -> B -> C):

- GROUP A: slim `manual_one_step_screen.dart` (946 -> under 800 lines) by a mechanical, byte-faithful extraction of the keypad / currency / save segments into same-library `part` files, plus non-happy-path characterization tests (reset/snapshot, keypad-mirror, provenance).
- GROUP B: turn the voice fill/notice part-coupling into a pure OBJECT boundary — extract `VoiceFillDecision` and `VoiceAmountNoticePolicy` (zero Flutter, no State), then lock the notice precedence (conversion-undo > repair-adopt > large-amount) with copy-independent combination tests.
- GROUP C: add a privacy-degradation control — a settings switch (default on = auto-degrade allowed) to disable the silent on-device->cloud recognition fallback, wired end to end from `AppSettings` through `SpeechRecognitionService.startListening`.

Purpose: reduce a growing host file below the LOC cap, move business ordering out of stateful widgets into testable pure objects, and give the user control over a privacy-relevant silent degradation.
Output: three new `part` files, two pure `application/voice/` policy objects, one new `AppSettings` flag with full persistence + UI + service wiring, three ARB keys x 3 locales, and five new/extended test files.
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md

Execution environment (READ — differs from the worktree default):
- Runs DIRECTLY on branch `main`. NO worktree isolation. Do NOT create/switch branches.
- The executor commits CODE atomically per task (conventional-commit, no attribution footer). The executor MUST NOT commit docs artifacts (PLAN/SUMMARY/STATE) — the orchestrator handles those.
- Groups A/B/C run in three SEQUENTIAL waves (no parallelism) to avoid same-file collisions and the ARB-collision trap. Order within a group is by dependency (tests-that-pin before the mechanical move; the pure object before its priority tests; the model field before its consumers).
- Each task specifies a scoped `verify` command. The FULL gate (`flutter analyze` = 0 + FULL `flutter test`) is run EXTERNALLY by the orchestrator after all three waves — but each task must still leave its own scoped tests green + `flutter analyze` clean in the touched scope.
- After editing freezed `AppSettings` (C1): `flutter pub run build_runner build --delete-conflicting-outputs`.
- After editing ARB (C3): `flutter gen-l10n`, then `git add -f lib/generated` (that dir is gitignored-yet-tracked, so a normal `git add` skips the regenerated Dart and `flutter analyze` breaks from clean — see MEMORY: gsd-executor-l10n-generated-uncommitted).

Project rules (enforced): immutability via `copyWith` only (freezed); ALL UI text via `S.of(context)` with trilingual ARB parity; no hardcoded hex (use `context.palette` / `AppPalette`); amounts via `AppTextStyles.amount*`; zero analyzer warnings; do not hand-edit `.g.dart` / `.freezed.dart`; `dart run custom_lint` must stay green (add import_guard whitelist entries if a new legal cross-layer/cross-feature import trips a per-directory guard — mirror quick-260625-gwy).
</execution_context>

<context>
@.planning/STATE.md
@CLAUDE.md

# GROUP A — extraction pattern + host
@lib/features/accounting/presentation/screens/manual_one_step_voice_wiring.dart   # the EXACT pattern to mirror (part-of + extension + the sanctioned setState->hook substitution)
@lib/features/accounting/presentation/screens/manual_one_step_screen.dart          # 946-line host to slim
@lib/features/accounting/presentation/screens/manual_one_step_snapshot.dart        # ManualEntrySnapshot API used by reset (item 4b)
@test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart  # existing widget-test harness + fakes to reuse for A tests

# GROUP B — fill/notice source + pure-object home
@lib/features/accounting/presentation/screens/voice_ptt_session_fill_orchestration.dart  # source of VoiceFillDecision
@lib/features/accounting/presentation/screens/voice_ptt_session_foreign_notice.dart      # source of VoiceAmountNoticePolicy (the precedence lives in _showVoiceAmountNotice)
@lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart               # host mixin; AmountArbiter precedent for placement; the two startListening call sites (C2)
@test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart    # existing 1A/1E/2B + arbitration tests that must stay green; CapturingSpeechService harness

# GROUP C — settings privacy-degradation
@lib/infrastructure/speech/speech_recognition_service.dart          # the on-device->cloud fallback mechanism (wiring target)
@lib/application/voice/start_speech_recognition_use_case.dart        # thin wrapper to thread the flag through
@lib/features/settings/domain/models/app_settings.dart               # freezed settings model (new field)
@lib/features/settings/domain/repositories/settings_repository.dart  # interface (new setter)
@lib/data/repositories/settings_repository_impl.dart                 # SharedPreferences persistence pattern (mirror biometricLock/voiceLanguage)
@lib/features/settings/presentation/widgets/voice_section.dart        # settings UI to extend
@lib/features/settings/presentation/providers/state_settings.dart     # appSettingsProvider / voiceLocaleIdProvider
@test/unit/data/repositories/settings_repository_impl_voice_test.dart # repo test to extend
@test/unit/infrastructure/speech/speech_recognition_service_ondevice_test.dart  # service degradation test to extend
</context>

<tasks>

<!-- ================= GROUP A — Host slim + non-happy tests (items 1 & 4) ================= -->

<task type="auto">
  <name>A1: Pin current keypad/currency/save + reset/mirror behavior with characterization + non-happy-path tests (BEFORE the move)</name>
  <files>test/widget/features/accounting/presentation/screens/manual_one_step_reset_mirror_characterization_test.dart</files>
  <action>
Write a NEW widget-test file that pins the CURRENT behavior of `ManualOneStepScreen` so the GROUP-A extraction can be proven byte-faithful. Reuse the existing harness/fakes from `manual_one_step_screen_test.dart` (its `FakeCategoryRepository`, a capturing/fake `StartSpeechRecognitionUseCase`, `parseVoiceInputUseCaseProvider` override, `createLocalizedWidget`, and a tall test surface). Run this file against the CURRENT (pre-A2) host and confirm it is GREEN — it exists to catch drift, so it must pass before the move.

Cover these behaviors:
- Characterization (keypad): typing digits updates `AmountDisplay`; the clear affordance empties the amount AND drops voice provenance (a subsequent keypad-entered row saves as manual, per T-nhs-03).
- Characterization (currency): selecting a non-JPY currency truncates the amount to the new minor unit and re-syncs; selecting JPY clears the triple.
- Characterization (save guard): `_trySave` is short-circuited with an error toast when amount is empty/zero, and when category is null.
- Item 4a — manual edit AFTER a voice fill: drive a continuous tap-session final fill (voice), then perform a keypad edit; assert the amount reflects the edit and provenance stays `EntrySource.voice` (the saved row stamps voice) until the amount is cleared.
- Item 4b — reset restores `_lastFillWasVoice`: capture a pure-manual snapshot (tap 语音记录 with a manual slate), do a voice fill (flips provenance to voice), then trigger the reset/restore path (`_onVoiceReset`); assert the form + host provenance roll back to the pre-speech snapshot (manual), i.e. a later keypad save is manual again.
- Item 4c — keypad mirror with a foreign triple already written: arrange a state where the foreign-currency triple (originalCurrency/originalAmount/appliedRate) is ALREADY present on the form, then drive the PTT-commit mirror (`onPttCommitted` -> `_mirrorPttFillIntoKeypad`); assert the mirror writes the booked JPY figure into the keypad controller/`AmountDisplay` and flips provenance to voice, WITHOUT clobbering the form's foreign triple (headline shows booked JPY; save still carries the foreign triple, D-4).

Assert on OBSERVABLE surfaces (rendered `AmountDisplay` text, form getters like `currentAmount` / `currentOriginalCurrency`, saved `EntrySource`), never on private fields. These are the item-4 non-happy-path tests AND the behavior pins for item 1. Do NOT modify any production file in this task.
  </action>
  <verify>
    <automated>flutter test test/widget/features/accounting/presentation/screens/manual_one_step_reset_mirror_characterization_test.dart</automated>
  </verify>
  <done>New test file passes on the CURRENT host (pre-extraction). It exercises keypad/currency/save characterization plus items 4a/4b/4c via observable surfaces only. flutter analyze reports 0 issues for the new file.</done>
</task>

<task type="auto">
  <name>A2: Mechanically extract keypad / currency / save into three same-library part files (host under 800 lines)</name>
  <files>lib/features/accounting/presentation/screens/manual_one_step_screen.dart, lib/features/accounting/presentation/screens/manual_one_step_keypad.dart, lib/features/accounting/presentation/screens/manual_one_step_currency.dart, lib/features/accounting/presentation/screens/manual_one_step_save.dart</files>
  <action>
Mechanically move three cohesive segments of `_ManualOneStepScreenState` out of the host into same-library parts, mirroring `manual_one_step_voice_wiring.dart` EXACTLY: add `part 'manual_one_step_keypad.dart';` / `part 'manual_one_step_currency.dart';` / `part 'manual_one_step_save.dart';` in the host next to the existing voice-wiring part directive; each new file opens with `part of 'manual_one_step_screen.dart';` and hosts `extension _ManualOneStepKeypad on _ManualOneStepScreenState { ... }` (resp. `_ManualOneStepCurrency`, `_ManualOneStepSave`). Parts share the host's imports and private visibility — do NOT add import lines to the parts and do NOT touch the host import block.

Segment assignment (move the method BODIES verbatim):
- keypad part: `_onAmountTap`, `_onDigit`, `_onDoubleZero`, `_onDot`, `_onDelete`, `_onClear`, `_syncAmountToForm`.
- currency part: `_pushForeignTriple`, `_rateStringOf`, `_onRateSignal`, `_onFormDateChanged`, `_onForeignRateEdited`, `_onCurrencyTap`, `_onCurrencySelected`.
- save part: `_trySave`, `_save`, `_resetForContinuousEntry`.

Keep in the host: all fields, the mixin contract (`onPttSessionChanged`, `onPttCommitted` delegate, etc.), `initState`/`dispose`/`didChangeAppLifecycleState`, `_initializeDefaultCategory`, `_handleFocusChange`, `_restoreKeypadFocus` (both are referenced by tear-off in initState/build — leave them in the host if the analyzer rejects an unqualified extension tear-off), `build`, and the top-level `foreignPushIsStale`.

SOLE SANCTIONED TRANSFORMATION (identical to the voice_wiring precedent): `setState(...)` is `@protected` and cannot be called from an extension, so add ONE private repaint hook on the State class — `void _rebuild(VoidCallback apply) { if (mounted) setState(apply); }` — and rewrite every moved `setState(...)` call to `_rebuild(...)`. This is behavior-identical (the added mounted guard is always-true in the synchronous handlers and already-present in the async ones). You MAY instead reuse the existing `onPttSessionChanged` hook, but `_rebuild` keeps voice naming out of keypad/currency/save. NO OTHER edits: no renames, no visibility promotion, no signature changes, no logic tweaks, no "while I'm here" cleanups. The A1 characterization suite is the proof of no drift.

After the move, confirm `manual_one_step_screen.dart` is under 800 lines and `dart format .` leaves the moved bodies unchanged apart from the setState->_rebuild substitution.
  </action>
  <verify>
    <automated>test $(grep -vc '^$' lib/features/accounting/presentation/screens/manual_one_step_screen.dart) -lt 800 && wc -l lib/features/accounting/presentation/screens/manual_one_step_screen.dart && flutter analyze lib/features/accounting/presentation/screens/ && flutter test test/widget/features/accounting/presentation/screens/manual_one_step_reset_mirror_characterization_test.dart test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart test/widget/features/accounting/presentation/screens/manual_one_step_snapshot_test.dart test/unit/features/accounting/presentation/screens/manual_one_step_screen_foreign_push_stale_test.dart</automated>
  </verify>
  <done>Host is under 800 lines; keypad/currency/save bodies live in the three new part files as extensions on _ManualOneStepScreenState; `_rebuild` is the only sanctioned change; the A1 suite plus all pre-existing manual_one_step suites stay green; flutter analyze = 0 in the touched scope.</done>
</task>

<!-- ================= GROUP B — Voice policy objects + priority tests (items 2 & 5) ================= -->

<task type="auto">
  <name>B1: Extract pure VoiceAmountNoticePolicy + VoiceFillDecision (zero Flutter, no State) and route the mixin parts through them</name>
  <files>lib/application/voice/voice_amount_notice_policy.dart, lib/application/voice/voice_fill_decision.dart, lib/features/accounting/presentation/screens/voice_ptt_session_foreign_notice.dart, lib/features/accounting/presentation/screens/voice_ptt_session_fill_orchestration.dart</files>
  <action>
Move the notice-precedence and fill-ordering business logic out of the State (the two `part` extensions) into two PURE Dart objects. Placement: `lib/application/voice/` — the application layer, co-located with the existing pure `AmountArbiter` (`lib/application/voice/amount_arbiter.dart`). Justification (record in the SUMMARY): per CLAUDE.md's placement rule, business logic / policy belongs in `lib/application/{domain}/`; the domain layer (`features/*/domain/`) is reserved for models + repository interfaces, so it is NOT the right home for a decision object. These files import ONLY Dart core + domain models (`VoiceParseResult` from `features/voice/domain/models/`) — ZERO Flutter, ZERO widget/State imports, and they never receive or touch a `State`/`BuildContext`.

VoiceAmountNoticePolicy (`voice_amount_notice_policy.dart`):
- Define a sealed/`sealed class` result `VoiceAmountNotice` with variants carrying only numeric payload: a conversion-undo variant (spokenAmount, jpy, rate, currency), a repair-adopt variant (filledAmount, candidate), a large-amount variant (filledAmount), and a "none" variant.
- Define `VoiceAmountNoticePolicy` with a pure `decide({required ({int jpy, String rate})? conversion, required String currency, required int filledAmount, required int? dataAmount, required int? repairCandidate, required int largeAmountThreshold})` that encodes the EXACT current precedence from `_showVoiceAmountNotice`: (1) if `conversion != null` -> conversion-undo; else (2) if `repairCandidate != null && filledAmount == dataAmount && repairCandidate != filledAmount` -> repair-adopt; else (3) if `filledAmount >= largeAmountThreshold` -> large-amount; else none. No string/ARB, no locale.

VoiceFillDecision (`voice_fill_decision.dart`):
- Define a pure value object (a "fill plan") + a factory that, given `{required bool fillCategory, required VoiceParseResult data, required int arbitratedAmount}`, decides the resolve-on-final gating that currently lives as scattered `if (fillCategory)` branches in `_fillFormFromTextInner`: whether to write amount (arbitratedAmount > 0), whether to resolve+write category (fillCategory && data.categoryMatch?.categoryId != null), whether to push the recognition surface (fillCategory), whether to attempt currency conversion (fillCategory && arbitratedAmount > 0 && detectedCurrency present), and whether to run the amount notice (fillCategory) — exposing these as named booleans/values in a stable order. The State executes the plan (all async repo/rate IO stays in the State part); the object only DECIDES.

Then refactor the two parts to consult these objects (behavior-preserving):
- `voice_ptt_session_foreign_notice.dart`: `_showVoiceAmountNotice` calls `VoiceAmountNoticePolicy().decide(...)` (pass `kVoiceLargeAmountNoticeThreshold` as the threshold, `data.amount` as dataAmount, `data.amountRepairCandidate` as repairCandidate, the `conversion` record, `currency`, `filledAmount`) and switches on the returned variant to build the SnackBar with the SAME ARB copy + `NumberFormatter` formatting + undo/adopt `onAction` closures as today. The precedence branching itself now lives in the pure policy; the part only maps variant -> copy + side effects.
- `voice_ptt_session_fill_orchestration.dart`: `_fillFormFromTextInner` computes `arbitratedAmount` via the existing `_amountArbiter.resolveDisplayAmount(...)` (unchanged), builds a `VoiceFillDecision` from `{fillCategory, data, arbitratedAmount}`, and drives its existing writes/conversion/notice off the plan's booleans instead of inline `if (fillCategory)` chains. Preserve exact ordering and every guard (mounted checks, `pttFormState` null-guard, `onPttCommitted` at the end, XVAL-03 hysteresis).

The existing `voice_ptt_session_mixin_test.dart` (1A adopt / 1E large-amount / 2B conversion-undo / kzr / saz vectors) and `amount_arbiter_test.dart` must stay green — they are the behavior lock for this refactor. Run `dart run custom_lint`; the new `application/voice/` files import only domain models so they should pass, but add an import_guard whitelist entry if a per-directory guard flags the `voice_parse_result.dart` import.
  </action>
  <verify>
    <automated>flutter analyze lib/application/voice/ lib/features/accounting/presentation/screens/ && flutter test test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart test/unit/application/voice/amount_arbiter_test.dart</automated>
  </verify>
  <done>VoiceAmountNoticePolicy and VoiceFillDecision exist in lib/application/voice/ with zero Flutter/State imports; the notice part maps a pure policy decision to ARB copy; the fill part drives writes off a pure decision object; all existing voice mixin + arbiter tests stay green; analyze = 0 and custom_lint = 0 in scope.</done>
</task>

<task type="auto">
  <name>B2: Lock notice precedence (conversion-undo > repair-adopt > large-amount) + fill-gating with copy-independent unit tests</name>
  <files>test/unit/application/voice/voice_amount_notice_policy_test.dart, test/unit/application/voice/voice_fill_decision_test.dart</files>
  <action>
Write pure unit tests (no Flutter binding, no widget pump) that LOCK the business precedence and gating on the new objects, asserting on the returned decision TYPE + numeric payload only — never on any UI/ARB string. This is the guard that a future UI-copy change cannot silently reorder the precedence.

voice_amount_notice_policy_test.dart — assert `VoiceAmountNoticePolicy.decide`:
- conversion present AND a valid repair candidate present AND filledAmount >= threshold -> conversion-undo variant (highest precedence).
- no conversion, valid repair candidate, filledAmount >= threshold -> repair-adopt variant (beats large-amount).
- no conversion, no valid repair, filledAmount >= threshold -> large-amount variant.
- none of the conditions -> the none variant.
- repair candidate SUPPRESSED when filledAmount != dataAmount (falls through to large-amount or none).
- repair candidate SUPPRESSED when candidate == filledAmount.
- boundary: filledAmount exactly == threshold triggers large-amount; threshold-1 does not.
Assert on `runtimeType`/`is` variant checks + the carried numeric fields (jpy/rate/spoken/candidate/filledAmount), explicitly asserting NO dependence on locale/copy.

voice_fill_decision_test.dart — assert the resolve-on-final gating:
- fillCategory == false (partial-driven): writeCategory / pushRecognition / attemptConversion / runNotice are all false; writeAmount follows arbitratedAmount > 0.
- fillCategory == true with a categoryMatch categoryId -> writeCategory true, pushRecognition true; with a detectedCurrency + amount>0 -> attemptConversion true; runNotice true.
- arbitratedAmount == 0 -> writeAmount false.
  </action>
  <verify>
    <automated>flutter test test/unit/application/voice/voice_amount_notice_policy_test.dart test/unit/application/voice/voice_fill_decision_test.dart</automated>
  </verify>
  <done>Both pure unit test files pass; the precedence order conversion-undo > repair-adopt > large-amount is asserted via VoiceAmountNoticePolicy decisions independent of UI text; the fill-gating booleans are locked. flutter analyze = 0 for the new files.</done>
</task>

<!-- ================= GROUP C — Settings privacy-degradation control (item 3) ================= -->

<task type="auto">
  <name>C1: Add AppSettings.voiceAllowOnDeviceFallback (freezed) + SettingsRepository setter + SharedPreferences persistence</name>
  <files>lib/features/settings/domain/models/app_settings.dart, lib/features/settings/domain/repositories/settings_repository.dart, lib/data/repositories/settings_repository_impl.dart, test/unit/data/repositories/settings_repository_impl_voice_test.dart, test/unit/features/settings/domain/models/app_settings_test.dart</files>
  <action>
Add a backward-compatible privacy-degradation flag, mirroring the existing plaintext-SharedPreferences pattern of `biometricLockEnabled` / `voiceLanguage` — NO Drift migration (settings persist via SharedPreferences; schemaVersion stays 23).

- `app_settings.dart`: add `@Default(true) bool voiceAllowOnDeviceFallback` to the `AppSettings` freezed factory (true = current behavior, auto-degrade allowed). Run `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate `.freezed.dart` / `.g.dart`.
- `settings_repository.dart` (interface): add `Future<void> setVoiceAllowOnDeviceFallback(bool enabled);` with a doc comment noting plaintext SharedPreferences, no Drift migration (mirror `setVoiceLanguage`).
- `settings_repository_impl.dart`: add `static const String _voiceAllowOnDeviceFallbackKey = 'voice_allow_on_device_fallback';`; in `getSettings()` read `voiceAllowOnDeviceFallback: _prefs.getBool(_voiceAllowOnDeviceFallbackKey) ?? true`; in `updateSettings(...)` write `await _prefs.setBool(_voiceAllowOnDeviceFallbackKey, settings.voiceAllowOnDeviceFallback);`; implement `setVoiceAllowOnDeviceFallback` mirroring `setVoiceLanguage`.
- Tests: extend `settings_repository_impl_voice_test.dart` with a group asserting default `true`, `setVoiceAllowOnDeviceFallback(false)` round-trips via `getSettings`, and `updateSettings` persists it. Extend `app_settings_test.dart` with default-`true` + `copyWith` immutability round-trip (mirror the appLockEnabled test).
  </action>
  <verify>
    <automated>flutter analyze lib/features/settings/ lib/data/repositories/settings_repository_impl.dart && flutter test test/unit/data/repositories/settings_repository_impl_voice_test.dart test/unit/features/settings/domain/models/app_settings_test.dart</automated>
  </verify>
  <done>AppSettings carries voiceAllowOnDeviceFallback (default true); SettingsRepository + impl persist it via a plaintext SharedPreferences key with no Drift migration; repo + model tests pass; build_runner regen is committed (force-add generated freezed if needed); analyze = 0 in scope.</done>
</task>

<task type="auto">
  <name>C2: Thread allowOnDeviceFallback through SpeechRecognitionService -> use case -> the two mixin startListening call sites</name>
  <files>lib/infrastructure/speech/speech_recognition_service.dart, lib/application/voice/start_speech_recognition_use_case.dart, lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart, test/unit/infrastructure/speech/speech_recognition_service_ondevice_test.dart, test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart</files>
  <action>
Wire the flag so that disabling it surfaces an on-device failure instead of silently retrying with cloud recognition; the default preserves today's behavior.

- `speech_recognition_service.dart` `startListening`: add a named param `bool allowOnDeviceFallback = true`. Add `allowOnDeviceFallback` to the `_lastConfig` record so `restartListen` replays it (mirror how localeId/listenFor/pauseFor are cached and replayed). Change the fallback guard from `if (!wantOnDevice) rethrow;` to `if (!wantOnDevice || !allowOnDeviceFallback) rethrow;` — i.e. when the user has disallowed the fallback, an on-device `Exception` propagates (surfaced) instead of being caught and retried with `onDevice:false`. Keep the `wantOnDevice = VoiceTuning.preferOnDeviceRecognition && !_onDeviceFallbackActive` line and the on-device attempt itself unchanged; the flag only governs the cloud RETRY.
- `start_speech_recognition_use_case.dart` `startListening`: add `bool allowOnDeviceFallback = true` and pass it through to `_service.startListening(..., allowOnDeviceFallback: allowOnDeviceFallback)`.
- `voice_ptt_session_mixin.dart`: at BOTH `pttSpeechService.startListening(...)` call sites (in `startPttSession` and in `resetPttSessionAndRestart`), read the setting via `ref` and pass it: `allowOnDeviceFallback: ref.read(appSettingsProvider).value?.voiceAllowOnDeviceFallback ?? true`. Import `appSettingsProvider` from `../../../settings/presentation/providers/state_settings.dart`. The `?? true` keeps behavior identical before settings resolve (async provider) and in tests that do not override it. Run `dart run custom_lint`; if the new settings-provider import trips a per-directory import_guard, add the whitelist entry (mirror quick-260625-gwy).
- Test helper: update `CapturingSpeechService.startListening` in `voice_ptt_session_mixin_test.dart` to accept `bool allowOnDeviceFallback = true` (default preserves every existing call) and capture the last value for assertion.
- Tests:
  - Extend `speech_recognition_service_ondevice_test.dart` with a case: with `allowOnDeviceFallback: false` and the on-device `listen` throwing, `startListening` rethrows `ListenFailedException`, issues exactly ONE listen call (no cloud retry), and `onDeviceFallbackActive` stays false. Keep Tests 1-5 green (default true).
  - Add a mixin-level test: override `appSettingsProvider` to a settings value with `voiceAllowOnDeviceFallback: false`, start a tap-session, and assert the captured `allowOnDeviceFallback` passed into `CapturingSpeechService.startListening` is false; with the default (true) it is true.
  </action>
  <verify>
    <automated>flutter analyze lib/infrastructure/speech/ lib/application/voice/start_speech_recognition_use_case.dart lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart && flutter test test/unit/infrastructure/speech/ test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart</automated>
  </verify>
  <done>allowOnDeviceFallback threads from the two mixin startListening call sites (reading appSettingsProvider) through the use case into the service; when false an on-device failure is rethrown with no cloud retry; when true (default) the existing degrade behavior is byte-identical; restartListen replays the flag; service + mixin tests pass; analyze + custom_lint = 0 in scope.</done>
</task>

<task type="auto">
  <name>C3: Settings UI — on-device status indicator + auto-degradation SwitchListTile + 3 ARB keys x 3 locales</name>
  <files>lib/features/settings/presentation/widgets/voice_section.dart, lib/l10n/app_ja.arb, lib/l10n/app_zh.arb, lib/l10n/app_en.arb, test/widget/features/settings/presentation/widgets/voice_section_test.dart</files>
  <action>
Extend `VoiceSection` with a product surface for the privacy-degradation control, below the existing voice-language row:
- An on-device recognition STATUS indicator (a `ListTile` or a leading Icon + label) that reflects the effective on-device recognition policy derived from `settings.voiceAllowOnDeviceFallback`: when true, "auto (may fall back to cloud recognition)"; when false, "on-device only (no cloud fallback)". NOTE for the record: a true hardware-capability probe is out of scope — `speech_to_text` 7.x exposes no synchronous "on-device supported" query — so the indicator surfaces the effective POLICY, not a device hardware capability. State this in the SUMMARY.
- A `SwitchListTile` bound to `settings.voiceAllowOnDeviceFallback`; on toggle, `await ref.read(settingsRepositoryProvider).setVoiceAllowOnDeviceFallback(value)` then `ref.invalidate(appSettingsProvider)` (mirror the exact `setVoiceLanguage` flow already in this file). Switch ON = auto-degradation allowed (default).

i18n: add exactly 3 new ARB keys x {ja, zh, en} with `@`-metadata in `app_en.arb`, all rendered via `S.of(context)` (no hardcoded strings, no hardcoded hex — use `context.palette`/theme; leading icon may use `Icons.*`). Suggested key names (finalize copy trilingually): `voiceOnDeviceRecognitionTitle` (row/section heading), `voiceAllowCloudFallbackTitle` (switch title), `voiceAllowCloudFallbackSubtitle` (switch subtitle explaining that turning it off keeps recognition on-device and surfaces failures instead of using cloud). Then run `flutter gen-l10n` and `git add -f lib/generated` so the regenerated `S` getters are committed.

Test: new `voice_section_test.dart` — pump `VoiceSection` with an overridden `settingsRepositoryProvider` (fake/mock capturing the setter) + localized harness; assert the SwitchListTile renders, toggling it calls `setVoiceAllowOnDeviceFallback` with the new value and invalidates settings, and the status indicator text reflects both states. Assert the new strings resolve via `S` (not hardcoded).
  </action>
  <verify>
    <automated>flutter gen-l10n && flutter analyze lib/features/settings/presentation/widgets/voice_section.dart lib/generated && flutter test test/widget/features/settings/presentation/widgets/voice_section_test.dart test/architecture/arb_key_parity_test.dart test/architecture/hardcoded_cjk_ui_scan_test.dart</automated>
  </verify>
  <done>VoiceSection shows an on-device status indicator + an auto-degradation SwitchListTile wired to setVoiceAllowOnDeviceFallback + appSettings invalidation; 3 new ARB keys exist in all three locales with parity; gen-l10n regenerated and force-added; widget + ARB-parity tests pass; analyze = 0; no hardcoded hex/strings.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| device microphone -> speech recognizer | on-device vs cloud recognition; the cloud path sends audio off-device (privacy-relevant) |
| user -> settings persistence | user toggles the degradation policy; persisted plaintext in SharedPreferences (non-secret preference) |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-kfb-01 | Information Disclosure | SpeechRecognitionService on-device->cloud auto-degradation | medium | mitigate | C2/C3 give the user an explicit control to disable the silent cloud fallback; when disabled an on-device failure is surfaced (rethrown) rather than silently sending audio to cloud recognition. Default preserves current behavior (informed backward-compat). |
| T-kfb-02 | Tampering | GROUP A mechanical extraction | low | mitigate | A1 characterization + non-happy-path tests pin behavior BEFORE the move; A2 forbids any edit beyond the sanctioned setState->_rebuild substitution; the pinned suite proves no drift. |
| T-kfb-03 | Tampering | package/dependency surface | low | accept | No new packages (npm/pip/cargo/pub) are added by this task — no legitimacy gate required. |
</threat_model>

<verification>
Per-task scoped `verify` commands above are authoritative for each executor. The ORCHESTRATOR runs the external full gate after all three waves:
- `flutter analyze` = 0 issues.
- FULL `flutter test` green (run the whole suite, not a scoped subset — architecture tests like hardcoded_cjk_ui_scan, color_literal_scan, arb_key_parity, layer_import_rules, and main-characterization only trip on a full run; never pipe `flutter test` through `tail`, which masks the exit code).
- `dart run custom_lint` = 0 (confirms no layer/import_guard regression from the new application/voice files + the mixin's settings-provider import).
- Spot-check: `grep -vc '^$' manual_one_step_screen.dart` < 800.
</verification>

<success_criteria>
- KFB-1: manual_one_step_screen.dart under 800 lines; keypad/currency/save extracted into three same-library part files; only the sanctioned setState->_rebuild change; A1 + all pre-existing manual_one_step suites green.
- KFB-4: items 4a (manual edit after voice fill), 4b (reset restores _lastFillWasVoice), 4c (keypad mirror with pre-written foreign triple) covered by passing tests on observable surfaces.
- KFB-2: VoiceFillDecision + VoiceAmountNoticePolicy are pure Dart in lib/application/voice/ (zero Flutter, no State); the mixin parts call into them; existing voice tests stay green.
- KFB-5: precedence conversion-undo > repair-adopt > large-amount locked by VoiceAmountNoticePolicy unit tests asserting variant + payload, independent of UI copy.
- KFB-3: settings shows on-device status + a switch to disable auto-degradation; disabling surfaces on-device failure instead of silent cloud retry; default stays auto-degrade allowed; no Drift migration; 3 ARB keys x 3 locales with gen-l10n regenerated + force-added.
- Full external gate: flutter analyze = 0, full flutter test green, custom_lint = 0.
</success_criteria>

<output>
Create `.planning/quick/260707-kfb-host-voice-reset-mirror-policy/260707-kfb-SUMMARY.md` when done, recording: final host line count; the sanctioned setState->_rebuild note; the placement justification for the two pure objects; the on-device-status "policy not hardware-probe" note; the exact 3 ARB keys added; and any import_guard whitelist edits.
</output>
