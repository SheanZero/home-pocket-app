# Phase 22: Voice One-Step Integration + Record Button UX — Research

**Researched:** 2026-05-25
**Domain:** Flutter UI integration (gestures + animations + state) + i18n ARB workflow + widget/integration test patterns
**Confidence:** HIGH — every load-bearing API claim verified against Flutter 3.44.0 SDK source on disk; every project-side pattern verified against the existing codebase.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

These are user-locked Phase 22 decisions; the planner MUST honor them verbatim and NOT explore alternatives.

- **D-01:** Keep `VoiceInputScreen` as a peer screen and refactor it to host `TransactionDetailsForm` directly (Option B). No `setState`-driven mode-aware screen; `EntryModeSwitcher` keeps `pushReplacement` semantics between three peer screens.
- **D-02:** Delete the `_navigateToConfirm` push to `ManualOneStepScreen` (voice_input_screen.dart:368-408). Voice becomes a single screen — no second-step push.
- **D-03:** Hold-to-record (push-to-talk) with 300 ms misfire threshold. Press starts instantly; release ≥ 300 ms commits, release < 300 ms discards. Save is a separate user action; release does NOT auto-save. App-wide hold-to-record is binding for any future voice surface.
- **D-04:** Recording-state visual: circle → rounded square (`borderRadius: 36 ↔ 16`) + green → red gradient swap. Mic icon stays `Icons.mic` in BOTH states. `AnimatedContainer(180ms, easeInOut)`. No pulse.
- **D-05:** Batch commit on release. Form is untouched during recording; all four values (amount, category, merchant, note) land at once after `onLongPressEnd` fires.
- **D-06:** 2 new ARB keys (`holdToRecord`, `recording`) × ja/zh/en; remove obsolete `tapToRecord` × 3 locales. Caption wraps in `AnimatedSwitcher(duration: 150ms)`.
- **D-07:** Add 3 new public methods on `TransactionDetailsFormState`: `updateCategory(Category, Category? parent)`, `updateMerchant(String)`, `updateNote(String)`. Mirrors Phase 19 D-14's `updateAmount(int)` pattern.
- **D-08:** Voice always overwrites — no skip-if-populated, no undo SoftToast.
- **D-09:** Text-field focus auto-stops recording. Restart is manual.
- **D-10:** Voice screen default bottom layer = mic + waveform + caption + full-width Save button. NO persistent `SmartKeyboard`.
- **D-11:** Save button = full-width gradient CTA (rename today's `Next` button to Save).
- **D-12:** 100 ms timing scope = `onLongPressStart` callback → `await tester.pump()` build completion. Golden ONLY for idle state; recording state is asserted via widget-test introspection.

### Claude's Discretion

The planner may decide each of these without re-asking the user.

- **Exact red color hex for recording state** (D-04). Pick from existing palette if it fits, otherwise add `AppColors.recording*` constants. (NOTE: verified — `lib/core/theme/app_colors.dart` does NOT currently expose an `error`/`warning`/`recording` color family; planner adds new constants in BOTH `app_colors.dart` and the dark variant.)
- **Animation duration tuning** (180 ms shape / 150 ms caption — D-04/D-06). Material baselines; ±50 ms tolerated.
- **Save button enable-predicate** (D-11). Either `_formKey.currentState?.canSubmit` (if added) OR `_resolvedCategory != null && amount > 0`.
- **`updateNote` source for v1.3** (D-07). Parser doesn't emit a discrete note today. Choose between (a) public no-op for forward-compat, (b) drop the method entirely, (c) populate from `voiceKeyword` leftover.
- **Where to dispose long-press state on cancel/end** (D-03). Field on `_VoiceInputScreenState` OR captured-in-closure.
- **Whether `_navigateToConfirm` and its helpers are deleted vs renamed** (D-02). Method body is replaced; wrapping name + the `_extractVoiceKeyword` helper may rename.

### Deferred Ideas (OUT OF SCOPE)

Beyond Phase 22 — DO NOT plan or implement.

- MOD-005 OCR writer landing → v1.4+.
- English (en) voice input quality → v1.4+ (Phase 22 wires en captions only).
- Cancel-mid-recording via swipe-up / off-target release gestures (beyond the misfire-discard and `onLongPressCancel` already covered).
- Visual pulse / breathing animation on the recording button.
- Haptic feedback on long-press start/end.
- Auto-resume recording after TextField blur.
- Voice "undo last batch fill" snapshot/undo.
- Adding a second voice surface in v1.3.
- Persist user's preferred voice locale per surface.
- Per-screen save-button shape unification (manual SmartKeyboard inline Save vs voice screen bottom CTA — divergence accepted).
- FAMILY-V2-01/02/03, FUTURE-QA-01, FUTURE-DOC-01..06, FUTURE-TOOL-03, TOOL-V2-01 (all v1.4+).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INPUT-02 | User can complete a voice-driven ledger entry from the same single screen — voice parser fills amount, category, note, merchant fields in-place; user can edit any field before saving. | `TransactionDetailsForm` (Phase 18) is the embeddable widget; Phase 19 D-14 established `updateAmount(int)`; Phase 22 adds `updateCategory`, `updateMerchant`, `updateNote` to complete the public mutator surface (Pattern 6). Voice → form batch commit (D-05) is wired by feeding the merger's `stop()` user-stop semantics (Pattern 7) into `ParseVoiceInputUseCase.execute(...)` then dispatching 4 setter calls. |
| REC-01 | Record button's idle-state caption unambiguously communicates the interaction model (tap-to-toggle vs hold-to-record); chosen model is consistent app-wide. | ARB key rename `tapToRecord` → `holdToRecord` (Pattern 4); single voice surface in v1.3 satisfies "app-wide consistent" by uniqueness; binding Decision Record for any future voice surface. |
| REC-02 | While recording, the record button visibly changes (color/shape/icon) AND the caption text changes to "录音中…" (i18n: ja/zh/en); state change perceivable within 100 ms of recording start. | `AnimatedContainer` shape morph (Pattern 2) + `AnimatedSwitcher` caption swap (Pattern 3); 100 ms guarantee enforced by `Stopwatch` around `setState → tester.pump()` (Pattern 9). Golden for idle state only. |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

The planner MUST treat each of these as a permanent guardrail.

- **Code generation:** Run `flutter pub run build_runner build --delete-conflicting-outputs` after modifying `@riverpod`, `@freezed`, Drift tables, or ARB files. Phase 22 has NO new `@freezed`/`@riverpod` annotations, but the ARB edit requires `flutter gen-l10n` (Pattern 8).
- **Quality gates (permanent):** `flutter analyze` 0 issues; `dart run custom_lint --no-fatal-infos` 0 errors; per-file coverage ≥ 70%; global coverage ≥ 70%; `build_runner` clean diff; `sqlite3_flutter_libs` REJECTED.
- **i18n parity:** All UI text via `S.of(context)`; ja/zh/en updated atomically; `flutter gen-l10n` clean. Pinned `intl: 0.20.2`.
- **5-layer Clean Architecture + Thin Feature rule:** `VoiceInputScreen` stays at `lib/features/accounting/presentation/screens/`. No `application/`, `infrastructure/`, `data/tables/`, `data/daos/` inside `lib/features/`.
- **Riverpod 3 imports:** Public surface (`Provider`, `FutureProvider`, `AsyncValue`, `ConsumerWidget`, `WidgetRef`) from `package:flutter_riverpod/flutter_riverpod.dart`; legacy `StateNotifier` from `flutter_riverpod/legacy.dart`. Provider name strips `Notifier` suffix.
- **Immutability:** `copyWith` on Freezed classes; never mutate.
- **Widget parameter pattern:** Nullable + provider fallback; never hardcode widget defaults.
- **iOS build pins (untouched in Phase 22 but enforced if pubspec is modified):** `sqlcipher_flutter_libs ^0.6.x`; `file_picker ^11.0.2` / `package_info_plus ^9.0.1` / `share_plus ^12.0.2` trio; Podfile `post_install` `-lsqlite3` strip + `EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64`.
- **Common Pitfalls #1, #4, #6, #8, #10 explicitly bind Phase 22:** don't hand-edit generated files; don't mutate (use `copyWith`); don't add `sqlite3_flutter_libs`; no analyzer warnings; no duplicate repository providers.

## Summary

Phase 22 is a UI + flow consolidation phase. It rewrites the body of one screen (`voice_input_screen.dart`, 813 lines), extends one widget (`transaction_details_form.dart`, 690 lines) with three new public mutator methods, and swaps one ARB key family across three locales. NO new pub dependencies. NO Drift schema migration. NO new ADR. NO new architectural boundaries.

The phase touches exactly four narrow areas, each backed by a battle-tested Flutter primitive or an established codebase pattern:

1. **Hold-to-record gesture** (D-03) — `GestureDetector` accepts `onLongPressStart` / `onLongPressEnd` / `onLongPressCancel` callbacks but constructs `LongPressGestureRecognizer` *without* passing a custom `duration`, so it uses `kLongPressTimeout = 500 ms`. To achieve "press fires instantly," Phase 22 MUST use `RawGestureDetector` with a hand-built `LongPressGestureRecognizer(duration: Duration.zero)` (Pattern 1). The 300 ms misfire threshold is applied on `onLongPressEnd`, not on `onLongPressStart`.
2. **Animated shape/color morph** (D-04) — `BoxDecoration` enforces a documented "if `shape: BoxShape.circle` then `borderRadius` is ignored" constraint. Phase 22 sidesteps it by ALWAYS using `BoxShape.rectangle` + `borderRadius: 36 ↔ 16` on a 72×72 box (idle visually circular to within ≤ 1 px anti-aliasing tolerance vs a true circle — see Pattern 2 trade-off note).
3. **Cross-fade caption swap** (D-06) — `AnimatedSwitcher` requires a unique `Key` per child to detect "this is a new widget"; the canonical pattern is `Text(captionText, key: ValueKey(captionText))` (Pattern 3).
4. **Cross-widget focus listener** (D-09) — codebase already uses the per-FocusNode listener pattern in `manual_one_step_screen.dart:171-179`. Phase 22 mirrors this verbatim (Pattern 5).

**Primary recommendation:** Plan Phase 22 as three sequential waves: (Wave 0) ARB key rename + form widget extension + golden harness scaffolding; (Wave 1) `VoiceInputScreen` body rewrite (gesture + animation + form embed + delete `_navigateToConfirm` push); (Wave 2) tests + verification. The form widget's three new mutator methods (D-07) can be implemented in parallel with the gesture rewrite because they have no internal dependency.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Long-press gesture detection | Presentation (`VoiceInputScreen`) | — | Pure UI input concern; no business logic. |
| AnimatedContainer / AnimatedSwitcher state morph | Presentation (`VoiceInputScreen`) | — | Visual state derived from `_isRecording` bool. |
| ARB caption strings | i18n (`lib/l10n/`) | Presentation (consumer) | Generated `S` class lives in `lib/generated/` per `l10n.yaml`; consumed by `voice_input_screen.dart`. |
| Voice transcript → form state push | Presentation (host) | Application (parser + resolver) | Host orchestrates; pipeline (merger → parse use case → resolver) lives in `application/voice/`. |
| Save persistence | Application (`CreateTransactionUseCase`) | Data (DAO, repository) | Flow unchanged from Phase 18; form widget's `submit()` calls the use case. |
| `entry_source = 'voice'` stamping | Application (`CreateTransactionParams.entrySource`) | Data (Drift v17 schema CHECK constraint) | Phase 17 D-06 contract; Phase 22 passes `EntrySource.voice` into the form config. |
| FocusScope/FocusNode listener | Presentation (`VoiceInputScreen`) | — | Same pattern as `manual_one_step_screen.dart:171`. |
| Speech recognition session lifecycle | Application (`StartSpeechRecognitionUseCase`) | Infrastructure (`SpeechRecognitionService`) | Existing layering; Phase 22 only calls `start/stop/cancel` from the new gesture callbacks. |

## Standard Stack

### Core (all already in the project — no new dependencies)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter` (Material) | 3.44.0 | `RawGestureDetector`, `LongPressGestureRecognizer`, `AnimatedContainer`, `AnimatedSwitcher`, `FocusNode` | Flutter SDK primitives — verified against `/Users/xinz/flutter/packages/flutter/lib/src/gestures/long_press.dart:281-290` and `widgets/gesture_detector.dart:1122-1133`. [VERIFIED: Flutter SDK source on disk] |
| `flutter_riverpod` | 3.1+ (project pin) | `ConsumerStatefulWidget`, `ref.watch`/`ref.read` | Existing project state-management library. [VERIFIED: pubspec.yaml + voice_input_screen.dart:4] |
| `flutter_test` | bundled | `tester.startGesture`, `tester.pump`, `tester.press`, `Stopwatch` | Bundled Flutter widget-test framework. [VERIFIED: Flutter SDK at `flutter_test/lib/src/controller.dart:1172-1218`] |
| `flutter_localizations` | bundled | ARB-driven `S.of(context)` | Existing i18n stack — already used pervasively. [VERIFIED: l10n.yaml `output-class: S`, `lib/l10n/app_{ja,zh,en}.arb`] |

### Supporting (existing project widgets)

| Library / Widget | Purpose | When to Use |
|------|---------|-------------|
| `TransactionDetailsForm` (Phase 18, 690 lines) | Embeddable form widget — handles non-amount fields + ledger toggle + soul satisfaction + save dispatch | Always — Phase 22 embeds it (D-01). Extended with 3 new public methods (D-07). |
| `AmountDisplay` (Phase 19 D-14 externalized) | Display-only amount surface; host renders independently | Host renders above the embedded form. Tap → `AmountEditBottomSheet`. |
| `AmountEditBottomSheet` (Phase 19 D-14 extracted) | Modal sheet for amount editing | Reused verbatim. Voice screen joins `TransactionEditScreen` + `OcrReviewScreen` in the modal-amount family (D-10). |
| `EntryModeSwitcher` (existing) | Top-of-screen tab strip; `pushReplacement` between three peer screens | Unchanged from current `VoiceInputScreen`. `selectedMode: InputMode.voice`. |
| `VoiceWaveform` (existing) | Audio-level waveform during recording | Unchanged. |
| `VoiceChunkMerger` (Phase 20) | Cross-final-result amount buffer with 2.5 s window | Already wired into `_VoiceInputScreenState` (lines 196-203). Phase 22 keeps the wiring; release fires `merger.stop()` which commits immediately per Phase 20 D-12 (Pattern 7). |
| `ParseVoiceInputUseCase` (Phase 21) | Orchestrator: text → amount + merchant + category + ledger type | Phase 22's `_stopRecordingAndCommit` calls `execute(finalText, localeId)` ONCE then batch-fills the form. |

### Alternatives Considered

| Instead of | Could Use | Why we don't |
|------------|-----------|--------------|
| `RawGestureDetector` + custom recognizer | `GestureDetector(onLongPress: ...)` with default 500 ms timer | GestureDetector does NOT expose `longPressDuration`; the 500 ms wait would break D-12's 100 ms perceived-state-change requirement because the `onLongPressStart` callback would not fire for half a second. [VERIFIED: gesture_detector.dart:1122-1124] |
| `BoxDecoration` with `BoxShape.rectangle` + radius | `ShapeDecoration` + `CircleBorder ↔ RoundedRectangleBorder` | `ShapeDecoration` interpolation would be more "correct" per Flutter docs, but the codebase uses `BoxDecoration` everywhere for the mic button family — staying with `BoxDecoration` keeps the diff focused and avoids dragging `ShapeDecoration` into the gradient + boxShadow combinations. The 72 × 72 + `borderRadius: 36` approach yields a circle within ≤ 1 px tolerance (verified via geometric reasoning: `borderRadius: 36` on a 72-pixel box rounds each corner with radius = half the side length = exact circle). [CITED: api.flutter.dev/flutter/painting/BoxDecoration/shape.html — "If this is BoxShape.circle then borderRadius is ignored"] |
| Per-widget `Focus` walker | Per-FocusNode listener attached in `initState` | The codebase already chose per-FocusNode listeners (`manual_one_step_screen.dart:100-101`) — for consistency and to avoid bringing a different focus-tracking model into the same feature. [VERIFIED: codebase grep] |
| Riverpod state for `_isRecording` | Widget-local `bool` | Voice screen state is local + ephemeral; no other widget needs to subscribe. Consistent with how `manual_one_step_screen.dart` keeps `_amountFocused` as a widget-local bool. [VERIFIED: codebase grep] |

**Installation:** None. Phase 22 adds zero new packages.

**Version verification:**
```bash
# No new packages — verification N/A. Confirm pubspec.lock hasn't drifted:
cd /Users/xinz/Development/home-pocket-app && git diff pubspec.lock 2>/dev/null | head -5
```

## Package Legitimacy Audit

> **Not applicable** — Phase 22 installs **zero** external packages. The phase is pure UI/flow consolidation using Flutter SDK primitives + existing project widgets/services. No slopcheck verification needed.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| *(none — no new dependencies)* | — | — | — | — | — | N/A |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
                          ┌─────────────────────────────────────────────┐
                          │            VoiceInputScreen                  │
                          │  (ConsumerStatefulWidget, body rewrite)      │
                          └─────────────────────────────────────────────┘
                                              │
        ┌─────────────────────────────────────┼─────────────────────────────────────────┐
        │                                     │                                         │
        ▼                                     ▼                                         ▼
┌──────────────────┐               ┌──────────────────────┐               ┌────────────────────────┐
│ EntryModeSwitcher │               │ Host-owned            │               │ Mic button area        │
│ (top tabs)        │               │ AmountDisplay         │               │  RawGestureDetector    │
│ pushReplacement   │               │  → tap →              │               │   ┌────────────────┐   │
│ between 3 peer    │               │  AmountEditBottomSheet│               │   │ AnimatedContnr │   │
│ screens — unchg.  │               │  (Phase 19 D-14)      │               │   │  shape morph   │   │
└──────────────────┘               └──────────────────────┘               │   └────────────────┘   │
                                              │                            │   ┌────────────────┐   │
                                              ▼                            │   │ AnimatedSwitchr│   │
                                  ┌────────────────────────────┐           │   │  caption swap  │   │
                                  │ TransactionDetailsForm     │           │   └────────────────┘   │
                                  │ (Phase 18 — EXTENDED in    │           │   ┌────────────────┐   │
                                  │  Phase 22 D-07 with 3 new  │           │   │ Save button    │   │
                                  │  public setter methods)    │           │   │  (full-width)  │   │
                                  └────────────────────────────┘           │   └────────────────┘   │
                                              │                            └────────────────────────┘
                                              │                                         │
                                              │  onLongPressEnd ≥ 300 ms                │
                                              ▼                                         ▼
                          ┌─────────────────────────────────────────────────────────────┐
                          │  _stopRecordingAndCommit():                                  │
                          │    1. _speechService.stop()   (cancels listen session)       │
                          │    2. _amountMerger.stop()    (commits buffer immediately)  │
                          │    3. parseVoiceInputUseCase.execute(finalText, localeId)    │
                          │    4. _formKey.currentState!.updateAmount(amount)            │
                          │       updateCategory(category, parent)                       │
                          │       updateMerchant(merchantName)                           │
                          │       updateNote(note)        ← may be no-op per discretion  │
                          └─────────────────────────────────────────────────────────────┘
                                              │
                                              ▼  Save button → _formKey.currentState!.submit()
                          ┌─────────────────────────────────────────────────────────────┐
                          │  CreateTransactionUseCase.execute(... entrySource: voice ...)│
                          │    → TransactionDao.insert(... entry_source = 'voice' ...)   │
                          │    → Navigator.popUntil((r) => r.isFirst)                    │
                          └─────────────────────────────────────────────────────────────┘
```

Data flow:
- User long-press (≥ 300 ms hold) → release → `_stopRecordingAndCommit` → parser → 4 form-state setter calls → form rebuilds.
- User taps Save → `submit()` → use case → DAO → entry_source = 'voice' row.
- User taps a `TextField` during recording → `FocusNode.addListener` callback fires → `_stopRecordingAndCommit` short-circuits without batch fill (D-09).

### Recommended Project Structure

```
lib/features/accounting/presentation/
├── screens/
│   ├── voice_input_screen.dart         # REWRITE: body rewrite, host TransactionDetailsForm, hold-to-record, animations
│   ├── manual_one_step_screen.dart     # unchanged (reference for FocusNode listener pattern)
│   ├── transaction_edit_screen.dart    # unchanged
│   └── ocr_review_screen.dart          # unchanged
└── widgets/
    ├── transaction_details_form.dart   # EXTEND: 3 new public setter methods on TransactionDetailsFormState (D-07)
    ├── amount_edit_bottom_sheet.dart   # reused verbatim
    ├── amount_display.dart             # reused verbatim
    ├── voice_waveform.dart             # reused verbatim
    ├── entry_mode_switcher.dart        # reused verbatim
    └── mic_button.dart                 # OPTIONAL extract (planner discretion, see file-size note below)

lib/l10n/
├── app_ja.arb                          # REMOVE tapToRecord; ADD holdToRecord + recording
├── app_zh.arb                          # REMOVE tapToRecord; ADD holdToRecord + recording
└── app_en.arb                          # REMOVE tapToRecord; ADD holdToRecord + recording

lib/generated/
└── app_localizations*.dart             # REGENERATED via flutter gen-l10n — do not hand-edit (CLAUDE.md Pitfall #1)
```

**File-size note:** `voice_input_screen.dart` is currently 813 lines. Phase 22 deletes `_navigateToConfirm` (lines 368-431, ~64 lines) + `VoiceRecognitionResultCard` + helpers (lines 643-813, ~170 lines) but adds the new gesture handlers + animated container + caption switcher + form embed + FocusNode listener. Net is likely +50 to +150 lines. If projected post-Phase-22 size exceeds ~900 lines, extract `MicButton` to `lib/features/accounting/presentation/widgets/mic_button.dart` per the `.claude/rules/coding-style.md` 800-line cap. Planner discretion.

### Pattern 1: RawGestureDetector with custom LongPressGestureRecognizer for zero-delay press

**What:** `GestureDetector(onLongPress: ...)` constructs `LongPressGestureRecognizer` with the default 500 ms deadline (`kLongPressTimeout`). It does NOT accept a `longPressDuration` constructor parameter. To get instant press fire, Phase 22 MUST use `RawGestureDetector` with a custom `LongPressGestureRecognizer(duration: Duration.zero)`.

**When to use:** Anywhere a developer needs to override the long-press deadline.

**Verified API:**
- `LongPressGestureRecognizer({Duration? duration, ...})` constructor accepts `duration` and forwards it as `deadline: duration ?? kLongPressTimeout`. [VERIFIED: `/Users/xinz/flutter/packages/flutter/lib/src/gestures/long_press.dart:281-290`]
- `GestureDetector` constructs `LongPressGestureRecognizer(debugOwner: this, supportedDevices: supportedDevices)` — NO `duration` argument. [VERIFIED: `/Users/xinz/flutter/packages/flutter/lib/src/widgets/gesture_detector.dart:1124`]
- Callback typedefs:
  - `typedef GestureLongPressCancelCallback = void Function();` (line 44)
  - `typedef GestureLongPressStartCallback = void Function(LongPressStartDetails details);` (line 79)
  - `typedef GestureLongPressEndCallback = void Function(LongPressEndDetails details);` (line 101)
- `LongPressStartDetails` / `LongPressEndDetails` carry `globalPosition` and `localPosition` (both `Offset`). [VERIFIED: long_press.dart:148-227]

**Example:**
```dart
// Source: /Users/xinz/flutter/packages/flutter/lib/src/widgets/gesture_detector.dart:1283-1338
// (RawGestureDetector class docstring shows this exact pattern)
RawGestureDetector(
  gestures: <Type, GestureRecognizerFactory>{
    LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
      () => LongPressGestureRecognizer(duration: Duration.zero, debugOwner: this),
      (LongPressGestureRecognizer instance) {
        instance
          ..onLongPressStart = (LongPressStartDetails details) {
            _pressStart = DateTime.now();
            _startRecording();
          }
          ..onLongPressEnd = (LongPressEndDetails details) {
            final held = DateTime.now().difference(_pressStart!);
            if (held < const Duration(milliseconds: 300)) {
              _cancelRecordingAndDiscard();
            } else {
              _stopRecordingAndCommit();
            }
          }
          ..onLongPressCancel = () {
            // Finger slid off target before release — treat same as misfire.
            _cancelRecordingAndDiscard();
          };
      },
    ),
  },
  child: Container(width: 72, height: 72, ...),
)
```

**Failure modes:**
- `onLongPressStart` fires only after the recognizer wins the gesture arena. With `duration: Duration.zero` and no competing recognizers on the same hit area, the recognizer wins immediately. Wrapping a button (e.g., Material `InkWell`) in a competing tap-recognizer ancestor could prevent that — Phase 22's mic button is a bare `Container` inside `RawGestureDetector`, so there's no contention.
- `onLongPressCancel` fires when the user slides their finger off the recognizer's hit area BEFORE end — wire it to the same discard path as the < 300 ms misfire branch.

### Pattern 2: AnimatedContainer with rectangular BoxDecoration + borderRadius interpolation

**What:** `BoxDecoration` documents an explicit constraint: "If this is `BoxShape.circle` then `borderRadius` is ignored." [CITED: api.flutter.dev/flutter/painting/BoxDecoration/shape.html]. AnimatedContainer interpolation between two `BoxDecoration`s where one has `shape: BoxShape.circle` and the other has `borderRadius` causes a rendering discontinuity. Phase 22 avoids the issue by ALWAYS using `BoxShape.rectangle` + `borderRadius: 36 (idle) ↔ 16 (recording)` on the 72×72 mic container.

**When to use:** When animating from "visually circular" to "rounded square" on a fixed-size box.

**Geometric note:** On a 72×72 box, `borderRadius: 36` produces a circle of radius 36 px touching each side at its midpoint — visually identical to `BoxShape.circle` within the sub-pixel anti-aliasing tolerance of any modern Flutter render backend (Skia or Impeller). No measurable difference in golden tests.

**Example:**
```dart
// Source: pattern derived from voice_input_screen.dart:544-566 (current) + Phase 22 D-04
AnimatedContainer(
  duration: const Duration(milliseconds: 180),
  curve: Curves.easeInOut,
  width: 72,
  height: 72,
  decoration: BoxDecoration(
    shape: BoxShape.rectangle,                                            // ALWAYS rectangle
    borderRadius: BorderRadius.circular(_isRecording ? 16 : 36),          // 36 ≈ circle on 72x72
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: _isRecording
          ? const [Color(0xFFE05050), Color(0xFFC03030)]                  // red — exact hex per planner discretion
          : const [AppColors.actionGradientStart, AppColors.actionGradientEnd],
    ),
    boxShadow: const [
      BoxShadow(color: AppColors.actionShadow, blurRadius: 16, offset: Offset(0, 4)),
    ],
  ),
  child: const Icon(Icons.mic, color: Colors.white, size: 32),
)
```

**Failure modes:**
- AnimatedContainer ONLY interpolates if BOTH the from-decoration and to-decoration are the SAME `BoxDecoration` class — mixing `BoxDecoration` and `ShapeDecoration` breaks interpolation. Phase 22 stays on `BoxDecoration` throughout.

### Pattern 3: AnimatedSwitcher with keyed Text child for cross-fade caption swap

**What:** AnimatedSwitcher's default `transitionBuilder` is a cross-fade (`FadeTransition`). The widget detects "child changed" by comparing widget type AND key. Without a key, two `Text` widgets with different `data:` look identical to the framework and no transition fires. Pattern: `Text(captionText, key: ValueKey(captionText))`. [VERIFIED: api.flutter.dev/flutter/widgets/AnimatedSwitcher-class.html, fetched 2026-05-25]

**When to use:** Any time two visually different strings should cross-fade.

**Example:**
```dart
// Source: standard Flutter pattern, verified at api.flutter.dev/flutter/widgets/AnimatedSwitcher-class.html
AnimatedSwitcher(
  duration: const Duration(milliseconds: 150),
  child: Text(
    _isRecording ? l10n.recording : l10n.holdToRecord,
    key: ValueKey(_isRecording),                                          // bool flip drives the key change
    style: AppTextStyles.bodySmall.copyWith(
      color: isDark ? AppColorsDark.textTertiary : AppColors.textTertiary,
    ),
  ),
)
```

**Note:** `ValueKey(_isRecording)` is shorter and more stable than `ValueKey(captionText)` — equivalent semantics, fewer string allocations per rebuild.

### Pattern 4: ARB file edit + flutter gen-l10n regeneration

**What:** ARB files are JSON-ish key-value translations. The `S` class is regenerated by `flutter gen-l10n` from `l10n.yaml` config. Pattern: edit ALL three locale files atomically, run `flutter gen-l10n`, never hand-edit `lib/generated/app_localizations*.dart`.

**Verified config:** [VERIFIED: `/Users/xinz/Development/home-pocket-app/l10n.yaml`]
```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: S
output-dir: lib/generated
nullable-getter: false
```

**Current state (verified by grep):**
- `app_ja.arb:1041-1042` — `"tapToRecord": "タップして録音"` + `"@tapToRecord": { ... }`
- `app_zh.arb:1041-1042` — `"tapToRecord": "点击录音"` + `"@tapToRecord": { ... }`
- `app_en.arb:1041-1044` — `"tapToRecord": "Tap to record"` + `"@tapToRecord": { "description": "Voice input hint" }`

**Phase 22 ARB changes:**
```jsonc
// app_ja.arb — REMOVE: "tapToRecord" + "@tapToRecord"; ADD:
"holdToRecord": "押して話す",
"@holdToRecord": { "description": "Voice idle caption: hold to speak (push-to-talk)" },
"recording": "録音中…",
"@recording": { "description": "Voice recording-state caption" },

// app_zh.arb — REMOVE same; ADD:
"holdToRecord": "按住说话",
"@holdToRecord": { "description": "Voice idle caption: hold to speak (push-to-talk)" },
"recording": "录音中…",
"@recording": { "description": "Voice recording-state caption" },

// app_en.arb — REMOVE same; ADD:
"holdToRecord": "Hold to speak",
"@holdToRecord": { "description": "Voice idle caption: hold to speak (push-to-talk)" },
"recording": "Recording…",
"@recording": { "description": "Voice recording-state caption" },
```

**Workflow sequence:**
```bash
# 1. Edit ARB files (atomic across 3 locales)
# 2. Regenerate:
flutter gen-l10n

# 3. (Optional) flutter pub get only if l10n.yaml itself changed:
flutter pub get

# 4. After ARB key removal — analyzer will flag remaining S.of(context).tapToRecord call sites.
# 5. NO build_runner step required for ARB edits.
```

**Failure modes:**
- `flutter gen-l10n` is silent on unused keys but FAILS LOUDLY on missing-key parity between locales. ARB parity is also structurally enforced by `test/architecture/arb_key_parity_test.dart` (verified pattern from Phase 18 D-04).
- If `S.of(context).tapToRecord` is referenced anywhere other than `voice_input_screen.dart:572`, the build will fail. Verified single call site by grep (Pattern 8 below).

### Pattern 5: Per-FocusNode listener for cross-widget focus changes

**What:** When a host widget needs to react to TextField focus changes inside an EMBEDDED child widget (e.g., `TransactionDetailsForm` hosting a merchant TextField), the canonical Flutter pattern is for the host to OWN the `FocusNode`(s), pass them via constructor parameters into the form widget's config, and attach `addListener(...)` callbacks in the host's `initState`. The form widget then assigns them to its `TextField(focusNode: ...)` props.

**Verified codebase precedent:** [VERIFIED: `/Users/xinz/Development/home-pocket-app/lib/features/accounting/presentation/screens/manual_one_step_screen.dart:71-101, 171-179`]
- `_merchantFocus = FocusNode()..addListener(_handleFocusChange);`
- `_handleFocusChange` reads `_merchantFocus.hasFocus || _noteFocus.hasFocus`, equality-guards, then `setState` to flip `_isTextFieldFocused`.

**Verified form widget plumbing:** [VERIFIED: `transaction_details_form.dart:450-466, 532-548`]
- `TransactionDetailsFormConfig.$new(... merchantFocusNode, noteFocusNode)` already accepts host-owned focus nodes.
- Form widget assigns them to `TextField(focusNode: widget.config.maybeWhen($new: (_, _, _, _, _, _, _, _, _, merchantFocusNode, noteFocusNode) => merchantFocusNode, orElse: () => null))`.

**Phase 22 application:**
```dart
class _VoiceInputScreenState extends ConsumerState<VoiceInputScreen> {
  late final FocusNode _merchantFocus;
  late final FocusNode _noteFocus;

  @override
  void initState() {
    super.initState();
    _merchantFocus = FocusNode()..addListener(_handleFocusChange);
    _noteFocus = FocusNode()..addListener(_handleFocusChange);
    // ... existing init ...
  }

  void _handleFocusChange() {
    final hasTextFocus = _merchantFocus.hasFocus || _noteFocus.hasFocus;
    if (hasTextFocus && _isRecording) {
      _stopRecordingAndCommit();                                          // D-09: auto-stop, no batch fill
    }
  }

  @override
  void dispose() {
    _merchantFocus.dispose();
    _noteFocus.dispose();
    // ... existing dispose ...
    super.dispose();
  }
}
```

**Pass focus nodes into the form config:**
```dart
TransactionDetailsForm(
  key: _formKey,
  config: TransactionDetailsFormConfig.$new(
    bookId: widget.bookId,
    entrySource: EntrySource.voice,
    merchantFocusNode: _merchantFocus,
    noteFocusNode: _noteFocus,
    // ... other initial values stay null; voice will batch-fill via _formKey.currentState!.updateXxx ...
  ),
)
```

### Pattern 6: GlobalKey + public mutator methods on form State

**What:** Phase 18 D-02 established `GlobalKey<TransactionDetailsFormState>().currentState!.submit()`. Phase 19 D-14 extended the pattern with the public method `void updateAmount(int amount)`. Phase 22 D-07 adds three more: `updateCategory`, `updateMerchant`, `updateNote`. Public methods live on the State class (`TransactionDetailsFormState`), accessed via the GlobalKey.

**Verified existing implementation:** [VERIFIED: `transaction_details_form.dart:188-192`]
```dart
void updateAmount(int amount) {
  if (!mounted) return;
  if (amount == _amount) return;                                          // S-1 idempotency guard
  setState(() => _amount = amount);
}
```

**Phase 22 new methods (canonical shape):**
```dart
// On TransactionDetailsFormState — symmetric with updateAmount (Phase 19 D-14):

void updateCategory(Category category, Category? parentCategory) {
  if (!mounted) return;
  if (category.id == _category?.id) return;                               // idempotency
  setState(() {
    _categoryById[category.id] = category;
    if (parentCategory != null) _categoryById[parentCategory.id] = parentCategory;
    _category = category;
    _parentCategory = parentCategory;
  });
  // .new mode: resolve ledger type from new category (existing helper).
  _resolveLedgerType(category.id);
}

void updateMerchant(String merchant) {
  if (!mounted) return;
  if (merchant == _storeController.text) return;
  _storeController.text = merchant;                                       // setting .text triggers TextField rebuild
}

void updateNote(String note) {
  if (!mounted) return;
  if (note == _memoController.text) return;
  _memoController.text = note;
}
```

**Verified test-tractability:** [VERIFIED: codebase test pattern at `manual_one_step_screen.dart:202-204`]
- `_formKey.currentState?.updateAmount(parsed);` is called from outside the form widget in production code today and works in widget tests via `final formKey = GlobalKey<TransactionDetailsFormState>();` + pump + access. The same pattern applies to the new three methods.

### Pattern 7: VoiceChunkMerger user-stop semantics

**What:** `VoiceChunkMerger.stop()` is a synchronous commit-and-clear that bypasses the 2.5 s window timer. The merger's window is intended for "wait for the user to maybe-resume after a pause"; an explicit user-stop event (Phase 20 D-12) skips the wait and commits the buffer immediately.

**Verified implementation:** [VERIFIED: `/Users/xinz/Development/home-pocket-app/lib/application/voice/voice_chunk_merger.dart:101-103, 189-200`]
```dart
/// User-initiated commit — called when the screen's tap-to-stop fires.
void stop() {
  _commitAndClear();
}

void _commitAndClear() {
  final pending = _buffer;
  _windowTimer?.cancel();
  _windowTimer = null;
  _buffer = '';
  _lastFinalAt = null;
  if (pending.isEmpty) return;
  final amount = _parser.parse(pending);
  if (amount != null) {
    _onAmountResolved(amount);                                            // fires the screen's onAmountResolved callback
  }
}
```

**Verified existing wiring:** [VERIFIED: `voice_input_screen.dart:214-223`]
```dart
Future<void> _stopRecording() async {
  _amountMerger?.stop();                                                  // commits the merger buffer immediately
  await _speechService.stop();                                            // cancels the recognizer listen session
  // ...
}
```

**Phase 22 application:** `_stopRecordingAndCommit()` is a renamed + extended version of today's `_stopRecording()` — same calls to `merger.stop()` + `speechService.stop()`, plus the new batch-fill of the form via `parseVoiceInputUseCase.execute(...)` and 4 setter calls.

**Failure modes:**
- If `merger.stop()` is called AFTER `_speechService.stop()`, any pending finals in flight may not reach the merger before commit. Safer order: `merger.stop()` first (synchronous), THEN `_speechService.stop()` (async, cancels). Verified — codebase already does this (line 217 before line 218).

### Pattern 8: Single-call-site verification for ARB key removal

**What:** Before removing an ARB key, grep production code for ALL call sites; replace each one in the same diff. `flutter analyze` is the final gate (compile error if any reference remains after `flutter gen-l10n` strips the getter).

**Verified single production call site for `tapToRecord`:** [VERIFIED: grep `tapToRecord` across `lib/`]
```bash
$ grep -rn "tapToRecord" /Users/xinz/Development/home-pocket-app/lib
# Sole hit: lib/features/accounting/presentation/screens/voice_input_screen.dart:572
#   text: l10n.tapToRecord
```

Sole production caller is `voice_input_screen.dart:572`, which Phase 22 rewrites in this phase. No other module references the key. Generated getters in `lib/generated/app_localizations*.dart` regenerate automatically; they're not direct call sites.

**Verified test call site:** `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart:384` asserts `find.text('タップして録音')` (the Japanese rendering). Phase 22 test rewrites switch the assertion to `find.text('押して話す')` for idle and `find.text('録音中…')` for recording.

### Anti-Patterns to Avoid

- **GestureDetector(onLongPress)** with the default 500 ms timer → blocks the 100 ms perceived-state-change requirement. Use `RawGestureDetector` + custom recognizer (Pattern 1).
- **Pulse / breathing animation on the recording button** → explicitly rejected by D-04. Don't add even if "it looks good in the prototype."
- **Mic icon swap (Mic → Stop)** → D-04 explicitly keeps `Icons.mic` in both states. State change is shape + color + caption only.
- **AnimationController + Tween** for the shape/color morph → unnecessary; `AnimatedContainer` is the implicit-animation idiom for "decorations smoothly track state." Use the lighter primitive.
- **`Focus.of(context)` walker** for cross-widget focus detection → inconsistent with the existing per-FocusNode listener pattern in `manual_one_step_screen.dart` (Pattern 5). Stay with the precedent.
- **Hand-editing `lib/generated/app_localizations*.dart`** → Pitfall #1 of CLAUDE.md. Regenerate via `flutter gen-l10n` only.
- **Adding a new pub package for keyboard handling / gesture helpers** (e.g., `gesture_x_detector`, `motion_sensor`) → Phase 22 needs nothing beyond Flutter SDK primitives.
- **Setting `controller.text = newValue` without an equality guard** → causes a TextField rebuild on every voice-fill even when the value didn't change. Pattern 6's `updateMerchant`/`updateNote` short-circuit on `newValue == controller.text`.
- **Awaiting `await tester.pumpAndSettle()` for the 100 ms test** → `pumpAndSettle` waits for ALL animations (including `AnimatedContainer`'s 180 ms morph). Use `tester.pump()` once to flush exactly the rebuild triggered by `setState`. Reference Pattern 9.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Long-press gesture with custom timeout | Manual `Listener` + Timer | `RawGestureDetector` + `LongPressGestureRecognizer(duration: Duration.zero)` (Pattern 1) | Flutter's recognizer already handles pointer arena negotiation (multi-touch slop, accept-after-deadline semantics). Hand-rolling means re-implementing `postAcceptSlopTolerance` and pointer event multiplexing. |
| Animated shape morph | Wrap `AnimationController` + `Tween<BorderRadius>` + `AnimatedBuilder` | `AnimatedContainer` (Pattern 2) | Implicit animations are the Flutter idiom for "decorations track state." Less wiring; the implicit AnimationController is internal. |
| Caption text cross-fade | `AnimationController` + opacity Tween + AnimatedBuilder | `AnimatedSwitcher` with keyed child (Pattern 3) | Same rationale; implicit primitive is one line vs ten. |
| Cross-widget focus listener | Wrap each TextField in a `Focus()` widget + `FocusScope` walker | Per-FocusNode `addListener` (Pattern 5) | Codebase precedent — `manual_one_step_screen.dart:171-179` already does this. Consistency. |
| ARB workflow | Hand-write `*.intl_*.dart` localized getters | `flutter gen-l10n` from `l10n.yaml` (Pattern 4) | Generated; ARB parity test enforces atomicity across locales. |
| Locale-aware number parsing | Re-parse voice transcript inside the host | `ParseVoiceInputUseCase.execute(text, localeId: ...)` | Phase 20/21 already wired the pipeline; Phase 22 invokes once on release. |
| Cross-final-result amount buffer | Re-implement window timer + lexical gate inside the host | `VoiceChunkMerger` (Phase 20) | Already exists; user-stop semantics already commit immediately (Pattern 7). |
| Form widget state mutation from outside | Bypass GlobalKey via Provider / EventBus / ChangeNotifier | `GlobalKey<TransactionDetailsFormState>` + public methods (Pattern 6) | Phase 18 D-02 + Phase 19 D-14 already established the contract. Phase 22 adds 3 sibling methods to the same surface. |
| `entry_source = 'voice'` save stamping | Manually inject after the use case returns | Pass `entrySource: EntrySource.voice` into `TransactionDetailsFormConfig.$new(...)` | Phase 17 D-06 + Phase 18 D-08 already wire this; the form's `submit()` reads `entrySource` from the config. |

**Key insight:** Phase 22 is value-add by composition, not by invention. Every load-bearing API was set up in Phase 18/19/20/21 specifically to make this phase a wiring task.

## Runtime State Inventory

> **N/A** — Phase 22 is NOT a rename / refactor / migration phase. It is a UI body rewrite + 3 widget method additions + ARB key swap. No stored data, no live service config, no OS-registered state, no secret/env-var renames, no build-artifact churn beyond `flutter gen-l10n` regenerating `app_localizations*.dart` (which is the standard workflow, not a migration concern).

**Verified by:**
- Phase 22 does NOT rename any class, method, file, table, column, route, or provider.
- The ARB key change (`tapToRecord` → `holdToRecord` + `recording`) is purely a string-resource change; no runtime state stores `tapToRecord` as data.
- The `entry_source = 'voice'` value already exists in the v17 schema CHECK constraint from Phase 17.

## Common Pitfalls

### Pitfall 1: GestureDetector tap competes with RawGestureDetector long-press

**What goes wrong:** Wrapping the `RawGestureDetector` mic button inside an ancestor `GestureDetector(onTap: ...)` (e.g., a "tap anywhere to dismiss keyboard" pattern) lets the tap recognizer claim the pointer arena before the long-press recognizer's `duration: Duration.zero` deadline fires, swallowing the gesture.

**Why it happens:** Flutter's gesture arena resolves competing recognizers per-pointer; the first to accept wins. With `Duration.zero`, the long-press recognizer fires immediately on pointer-down — but a wrapping tap recognizer with no delay also accepts immediately, and tap is usually higher-priority.

**How to avoid:** Keep the mic button area free of ancestor tap-recognizers. The mic button is the SOLE gesture target inside its 72 × 72 box. Verify by reading the current build hierarchy at `voice_input_screen.dart:498-630` — the `Column` parent has no `GestureDetector`.

**Warning signs:** Long-press events never fire; `setState(() => _isRecording = true)` is never called even though logs show the user touched the button.

### Pitfall 2: AnimatedContainer doesn't interpolate when wrapped in a child key change

**What goes wrong:** If the host rebuilds with a different `key:` on the AnimatedContainer (or its parent), Flutter creates a fresh widget with no "previous decoration" to interpolate from — the morph happens instantly with no animation.

**Why it happens:** AnimatedContainer relies on Element identity preservation across rebuilds.

**How to avoid:** Don't put a `key:` on the AnimatedContainer that changes during the gesture. The 72 × 72 box keeps the same position in the widget tree throughout the recording lifecycle.

**Warning signs:** Shape morph is instantaneous (no 180 ms transition) — feels glitchy.

### Pitfall 3: TextEditingController.text assignment loses cursor / selection

**What goes wrong:** `_storeController.text = "Starbucks"` resets the cursor to position 0, scrambling any in-progress user edit.

**Why it happens:** TextEditingController's `text =` setter clears selection.

**How to avoid:** Voice-fill on RELEASE only (D-05); user is not editing the merchant TextField when batch fill fires (D-09 prevents this — if the TextField has focus, recording is auto-stopped without batch fill). So in the only scenario where `updateMerchant` runs, the TextField is unfocused — cursor reset is invisible.

**Warning signs:** Real user reports "voice typed my merchant but it appended to the start." Mitigated by D-09's auto-stop.

### Pitfall 4: ARB key removal compiles green but golden test references stale string

**What goes wrong:** `flutter gen-l10n` succeeds (because no Dart code references `tapToRecord` after the widget rewrite), but a golden test at `test/widget/.../mic_button_idle.png` was baked with the old caption — golden mismatches.

**Why it happens:** Goldens are baselined PNG snapshots; ARB key text isn't re-derived from source on each test run.

**How to avoid:** Phase 22 creates a NEW golden `mic_button_idle.png` from scratch; the old `tapToRecord` rendering never had a golden, so no stale baseline exists. Verify by `find test -name "*tapToRecord*" -o -name "*mic_button*"` — both return empty.

**Warning signs:** `flutter test --update-goldens` succeeds locally but fails in CI on a fresh checkout. (Not expected for Phase 22 since the golden is new.)

### Pitfall 5: 100 ms Stopwatch test is flaky on CI under load

**What goes wrong:** `expect(stopwatch.elapsedMilliseconds, lessThan(100))` passes locally but fails in CI on a noisy shared runner where build + setState takes 110 ms.

**Why it happens:** CI VMs throttle; Dart VM JIT warmup adds first-frame latency.

**How to avoid:** Phase 22 D-12 scopes timing to `onLongPressStart callback → tester.pump() return`, NOT real wall-clock animation completion. The setState + pump cycle is a small handful of microseconds in a unit-test harness — well under 100 ms on any reasonable CI runner. If the test consistently flakes, raise the bound to 200 ms; this is still meaningfully tight (100 ms is the user-perception floor; 200 ms is conservatively safe).

**Warning signs:** Single-run flake rate > 1 in 50 over a week of CI runs. If observed, planner should widen the bound rather than chase the underlying cause (the bound is a budget, not a measurement).

### Pitfall 6: `_speechService.cancel()` vs `.stop()` confusion on misfire branch

**What goes wrong:** On the < 300 ms misfire branch, calling `_speechService.stop()` (which `stopListening()`) flushes a partial final to the merger, which then commits whatever fragment was captured during the brief held window. The form gets a garbage parse.

**Why it happens:** `stop()` is "graceful drain" semantics; `cancel()` is "drop pending state" semantics. [VERIFIED: `lib/application/voice/start_speech_recognition_use_case.dart:42-45`]
```dart
Future<void> stop() => _service.stopListening();      // drains
Future<void> cancel() => _service.cancelListening();  // discards
```

**How to avoid:** Misfire branch calls `_speechService.cancel()` AND `_amountMerger?.dispose()` (NOT `_amountMerger?.stop()`, which would commit). The commit branch calls `_amountMerger?.stop()` + `_speechService.stop()` (existing order at line 217-218).

**Warning signs:** Form shows nonsense amounts after a tap-and-release that should have been a misfire.

### Pitfall 7: App suspends mid-recording (background)

**What goes wrong:** User long-presses, app goes to background (incoming call, home button), `_isRecording` is stuck true, mic button is stuck red-square; on resume the user sees an inconsistent state.

**Why it happens:** The hold-to-record gesture is a stateful "user is still pressing" invariant; backgrounding breaks the invariant without firing `onLongPressEnd`.

**How to avoid:** Add `WidgetsBindingObserver` to `_VoiceInputScreenState`; on `AppLifecycleState.paused`, call `_cancelRecordingAndDiscard()`. (NOTE: this is a robustness ADD that Phase 22 SHOULD include even though CONTEXT.md doesn't explicitly call it out — without it, the screen has a known-bad state transition that any QA round will surface. Listed as Open Question 1 below for planner decision.)

**Warning signs:** User reports "the mic button stayed red after I took a phone call."

### Pitfall 8: Recognizer error during the held window

**What goes wrong:** `_speechService.startListening` invokes `onError` (e.g., permission revoked mid-session, recognizer crash); the current `_onError` callback at lines 132-138 sets `_isRecording = false`, but the held finger and the new gesture state machine don't know about it.

**Why it happens:** Two state machines (the gesture's "held" state and the screen's `_isRecording` bool) can diverge.

**How to avoid:** Treat `_onError` as another path that calls `_cancelRecordingAndDiscard()` (synonymous with misfire). The next `onLongPressEnd` becomes a no-op because `_isRecording` is already false.

**Warning signs:** Mic button visually flips to idle but a subsequent release fires a stale commit.

### Pitfall 9: Merger emits nothing on stop (silent recording)

**What goes wrong:** User holds for 2 seconds but says nothing or only "umm". Merger's `_buffer` is empty; `stop()` returns without firing `onAmountResolved`. Subsequent `parseVoiceInputUseCase.execute(finalText: '')` returns `VoiceParseResult(amount: null, categoryMatch: null, ...)`. The four form-setter calls become no-ops (each has an equality guard or null-check).

**Why it happens:** Empty utterance is a valid outcome.

**How to avoid:** Don't treat empty parse as an error. Show a `SoftToast` (e.g., l10n key `voiceNoSpeechDetected` — planner discretion whether to add; out of scope per CONTEXT.md if not flagged). Save button stays disabled because `_resolvedCategory == null`.

**Warning signs:** Save button never enables after release; user is confused.

### Pitfall 10: `parseVoiceInputUseCase.execute` returns null/empty (no amount detected)

**What goes wrong:** Recognizer captured "买了一些东西" (zh "bought some stuff") — no number, no merchant, no category synonym. `VoiceParseResult.amount == null`, `categoryMatch == null`. The four setter calls are no-ops; form is empty; Save button is disabled.

**Why it happens:** Voice input is ambiguous; the parser cannot infer what isn't there.

**How to avoid:** Inherent to voice UX — user must say SOMETHING parseable. The form stays empty; user can manually tap chevrons to fill fields. Categories fall back to the form's default behavior (chevron tap → `CategorySelectionScreen` — existing path).

**Warning signs:** Save button disabled after a successful-looking recording. Normal UX; not a bug.

## Code Examples

### Example 1: hold-to-record gesture wired to `_startRecording` / `_stopRecordingAndCommit` / `_cancelRecordingAndDiscard`

```dart
// Source: composition of Pattern 1 + voice_input_screen.dart:159-223 (existing helpers)
DateTime? _pressStart;

void _onLongPressStart(LongPressStartDetails details) {
  if (!_isInitialized || _isRecording) return;
  _pressStart = DateTime.now();
  _startRecording();                                                      // existing helper, lines 169-212
}

void _onLongPressEnd(LongPressEndDetails details) {
  final start = _pressStart;
  _pressStart = null;
  if (start == null || !_isRecording) return;
  final held = DateTime.now().difference(start);
  if (held < const Duration(milliseconds: 300)) {
    _cancelRecordingAndDiscard();
  } else {
    _stopRecordingAndCommit();
  }
}

void _onLongPressCancel() {
  // Finger slid off target — treat same as misfire.
  if (_pressStart == null || !_isRecording) return;
  _pressStart = null;
  _cancelRecordingAndDiscard();
}

Future<void> _cancelRecordingAndDiscard() async {
  _amountMerger?.dispose();                                               // DISPOSE, not stop (no commit)
  _amountMerger = null;
  await _speechService.cancel();                                          // DISCARD pending state
  if (!mounted) return;
  setState(() {
    _isRecording = false;
    _soundLevel = 0.0;
  });
}

Future<void> _stopRecordingAndCommit() async {
  _amountMerger?.stop();                                                  // COMMIT (existing Pattern 7)
  await _speechService.stop();
  if (!mounted) return;
  setState(() {
    _isRecording = false;
    _soundLevel = 0.0;
  });
  // Batch fill via parse + 4 setter calls (D-05):
  final text = _finalText.isNotEmpty ? _finalText : _partialText;
  if (text.isEmpty) return;
  final parseResult = await ref
      .read(parseVoiceInputUseCaseProvider)
      .execute(text, localeId: _voiceLocaleId);
  if (!mounted || !parseResult.isSuccess) return;
  final data = parseResult.data;
  if (data == null) return;

  final categoryId = data.categoryMatch?.categoryId ?? data.merchantCategoryId;
  Category? category;
  Category? parent;
  if (categoryId != null) {
    final repo = ref.read(categoryRepositoryProvider);
    category = await repo.findById(categoryId);
    parent = (category?.parentId != null)
        ? await repo.findById(category!.parentId!)
        : null;
  }

  // _mergedAmount may have committed via merger.stop() callback before this point.
  final amount = _mergedAmount ?? data.amount ?? 0;
  if (!mounted) return;
  final state = _formKey.currentState;
  if (state == null) return;
  if (amount > 0) state.updateAmount(amount);
  if (category != null) state.updateCategory(category, parent);
  if (data.merchantName != null) state.updateMerchant(data.merchantName!);
  // updateNote: planner discretion (see D-07 in CONTEXT.md).
}
```

### Example 2: AnimatedContainer + AnimatedSwitcher in the build method

```dart
// Source: Patterns 2 + 3 applied to voice_input_screen.dart:541-578 (existing build)
RawGestureDetector(
  gestures: <Type, GestureRecognizerFactory>{
    LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
      () => LongPressGestureRecognizer(duration: Duration.zero, debugOwner: this),
      (LongPressGestureRecognizer instance) {
        instance
          ..onLongPressStart = _onLongPressStart
          ..onLongPressEnd = _onLongPressEnd
          ..onLongPressCancel = _onLongPressCancel;
      },
    ),
  },
  child: AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeInOut,
    width: 72,
    height: 72,
    decoration: BoxDecoration(
      shape: BoxShape.rectangle,
      borderRadius: BorderRadius.circular(_isRecording ? 16 : 36),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: _isRecording
            ? const [AppColors.recordingGradientStart, AppColors.recordingGradientEnd]
            : const [AppColors.actionGradientStart, AppColors.actionGradientEnd],
      ),
      boxShadow: const [
        BoxShadow(color: AppColors.actionShadow, blurRadius: 16, offset: Offset(0, 4)),
      ],
    ),
    child: const Icon(Icons.mic, color: Colors.white, size: 32),
  ),
),

const SizedBox(height: 12),

AnimatedSwitcher(
  duration: const Duration(milliseconds: 150),
  child: Text(
    _isRecording ? l10n.recording : l10n.holdToRecord,
    key: ValueKey(_isRecording),
    style: AppTextStyles.bodySmall.copyWith(
      color: isDark ? AppColorsDark.textTertiary : AppColors.textTertiary,
    ),
  ),
),
```

### Example 3: Stopwatch test for 100 ms perceived state change

```dart
// Source: Pattern 9 + flutter_test API verified at /Users/xinz/flutter/packages/flutter_test/lib/src/controller.dart:1172
testWidgets('REC-02 D-12: caption swaps within 100 ms of onLongPressStart', (tester) async {
  await tester.pumpWidget(buildSubject(speechService: speechService));
  await tester.pumpAndSettle();

  final micFinder = find.byIcon(Icons.mic);
  expect(micFinder, findsOneWidget);

  // Use startGesture (not longPress, which has built-in kLongPressTimeout + kPressTimeout delays).
  final stopwatch = Stopwatch()..start();
  final gesture = await tester.startGesture(tester.getCenter(micFinder));
  // RawGestureDetector + LongPressGestureRecognizer(duration: Duration.zero) accepts
  // immediately on pointer-down — onLongPressStart fires within the same microtask.
  await tester.pump();                                                    // flush the setState(() => _isRecording = true)
  stopwatch.stop();

  expect(stopwatch.elapsedMilliseconds, lessThan(100),
    reason: 'Recording-state visual must be perceivable within 100 ms');
  expect(find.text('録音中…'), findsOneWidget);                            // recording caption visible

  // Cleanup — hold long enough to commit, then release.
  await tester.pump(const Duration(milliseconds: 400));                   // > 300 ms threshold
  await gesture.up();
  await tester.pumpAndSettle();
});
```

### Example 4: Integration test for `entry_source = 'voice'` save round-trip (SC-2)

```dart
// Source: pattern from /Users/xinz/Development/home-pocket-app/test/integration/features/accounting/manual_save_entry_source_test.dart:218-242
// Adapt for VoiceInputScreen save path (Phase 22):
testWidgets(
  'SC-2: VoiceInputScreen save stamps entry_source=voice in DB',
  (tester) async {
    // Setup: real AppDatabase.forTesting() + real CreateTransactionUseCase + mocks for
    // categoryRepository, deviceIdentityRepository, encryptionService, learningService.

    await tester.pumpWidget(
      createLocalizedWidget(
        VoiceInputScreen(bookId: 'book-1', speechService: speechService),
        locale: const Locale('ja'),
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          categoryRepositoryProvider.overrideWithValue(categoryRepository),
          createTransactionUseCaseProvider.overrideWithValue(useCase),
          merchantCategoryLearningServiceProvider.overrideWithValue(learningService),
          parseVoiceInputUseCaseProvider.overrideWithValue(parseUseCase),
          voiceLocaleIdProvider.overrideWith((ref) async => 'ja-JP'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // 1. Long-press hold ≥ 300 ms; recognizer emits a fake final.
    final micFinder = find.byIcon(Icons.mic);
    final gesture = await tester.startGesture(tester.getCenter(micFinder));
    await tester.pump(const Duration(milliseconds: 50));
    speechService.emitFinal('スターバックスで500円');                          // mock emits transcript
    await tester.pump(const Duration(milliseconds: 400));                  // hold > 300ms
    await gesture.up();
    await tester.pumpAndSettle();

    // 2. Assert form filled.
    expect(find.text('500'), findsOneWidget);

    // 3. Tap Save (full-width gradient CTA below mic+caption).
    final saveFinder = find.byKey(const ValueKey('voice-save-button'));   // planner-assigned key
    await tester.tap(saveFinder);
    await tester.pumpAndSettle();

    // 4. Verify DB row.
    final rows = await transactionDao.findByBookId('book-1');
    expect(rows.length, 1);
    expect(rows.first.entrySource, 'voice', reason: 'entry_source must be "voice"');
    expect(rows.first.amount, 500);
  },
);
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `GestureDetector(onTap: _toggleRecording)` (tap-to-toggle) | `RawGestureDetector` + `LongPressGestureRecognizer(duration: Duration.zero)` (hold-to-record) | Phase 22 | Eliminates "forgot to stop" failure mode; physical contact = recording semantics. |
| Two-step voice flow (`VoiceInputScreen` → `ManualOneStepScreen`) | Single-screen voice flow (voice fills `TransactionDetailsForm` embedded in voice screen) | Phase 22 | Realizes INPUT-02 promise; halves the click-to-save count. |
| `VoiceRecognitionResultCard` (read-only display) | `TransactionDetailsForm` embedded (editable) | Phase 22 | User can correct any field before save. |
| `BoxShape.circle` (static) | `BoxShape.rectangle` + `borderRadius: 36↔16` (animated via AnimatedContainer) | Phase 22 | Enables shape morph; preserves visual circular idle state. |
| Static caption `l10n.tapToRecord` | `AnimatedSwitcher` with `_isRecording ? l10n.recording : l10n.holdToRecord` | Phase 22 | Caption is the second channel of state signaling. |

**Deprecated/outdated:**
- `_toggleRecording` (lines 159-167) — replaced by `_startRecording` / `_stopRecordingAndCommit` / `_cancelRecordingAndDiscard` triad.
- `_navigateToConfirm` (lines 368-408) — deleted. Voice flow ends on the same screen.
- `_extractVoiceKeyword` (lines 410-431) — KEPT; output flows into `TransactionDetailsFormConfig.$new(voiceKeyword: ...)` for the form's correction-learning hook (Phase 18 D-09). Planner discretion whether to rename to a clearer name like `_keywordForCategoryLearning`.
- `VoiceRecognitionResultCard` class (lines 643-740) — DELETED; replaced by the embedded `TransactionDetailsForm`.
- `_ParsedInfoRow` + `_ParsedDivider` (lines 742-813) — DELETED with their parent card.
- ARB key `tapToRecord` (× 3 locales) — DELETED.

## Assumptions Log

> Claims tagged `[ASSUMED]` in this research. The planner and discuss-phase should resolve these before execution.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The 100 ms test bound is reliable in CI under typical load (Pattern 9 + Pitfall 5). | Pitfall 5 | If flaky in practice, planner widens the bound to 200 ms — still meets D-12 spirit (sub-perceptual). |
| A2 | `borderRadius: 36` on a 72×72 box is visually indistinguishable from `BoxShape.circle` in golden tests (Pattern 2). | Pattern 2 trade-off note | If golden anti-aliasing differs by 1+ px (rare), use `ClipOval` for idle and skip the AnimatedContainer's edge interpolation — but this loses the smooth morph. Planner verifies with a quick golden-update spike. |
| A3 | `RawGestureDetector + LongPressGestureRecognizer(duration: Duration.zero)` does NOT trigger a hover/touch-and-hold accessibility tooltip on iOS/Android. | Pattern 1 | If it does, a future a11y review surfaces. Out of scope per CONTEXT.md (no haptic, no a11y polish in Phase 22). |
| A4 | Backgrounding the app mid-recording is currently buggy and Phase 22 SHOULD add `WidgetsBindingObserver` handling (Pitfall 7) — but CONTEXT.md doesn't explicitly require it. | Pitfall 7 / Open Q1 | Planner decides; without the observer, a known-bad state transition exists in v1.3 release. Flagging for discuss-phase. |
| A5 | `updateNote` in v1.3 is a public no-op (the recommended discretion choice from D-07). Parser doesn't emit a separate note today. | Pattern 6 | If planner chooses option (c) "populate from `voiceKeyword` leftover", the form's note field will display extraction debris like "用了" or "买了" — undesirable. Recommend option (a) public no-op. |
| A6 | The `voice_to_manual_one_step_screen_test.dart` (Phase 19 D-16) is delete-or-rename; the planner re-targets coverage to the new SC-2 integration test on the voice screen save path. | Standard Stack alternatives + Existing tests section | If kept as-is, the test asserts a flow that no longer exists post-Phase-22; CI failure. Planner deletes or rewrites in Phase 22 scope. |

**If empty (it isn't):** all claims were verified or cited.

## Open Questions

1. **Backgrounding the app mid-recording — does Phase 22 ship a `WidgetsBindingObserver` to auto-cancel on `paused`?**
   - **What we know:** Pitfall 7 documents the failure mode. CONTEXT.md doesn't explicitly include or exclude this.
   - **What's unclear:** Whether the planner accepts adding a small robustness item not explicitly covered in CONTEXT.md.
   - **Recommendation:** Add it. ~10 lines of code (`WidgetsBindingObserver` mixin + `didChangeAppLifecycleState` override calling `_cancelRecordingAndDiscard()`). Without it, the screen has a known-bad state. Flag in discuss-phase if planner is uncertain.

2. **Soul satisfaction estimator continuation:** Phase 22's CONTEXT.md mentions "soul ledger branch continues to compute satisfaction" (voice_input_screen.dart:306-314). Does the satisfaction value still get passed through to the form widget when D-05 batch-fills?
   - **What we know:** Current code `parseResult.copyWith(estimatedSatisfaction: satisfaction)` then sets `_parseResult` (line 316). `_navigateToConfirm` reads `_parseResult.estimatedSatisfaction` and passes via `initialSatisfaction:`. Phase 22 deletes `_navigateToConfirm`.
   - **What's unclear:** The form widget's `TransactionDetailsFormConfig.$new(...)` accepts `initialSatisfaction:` — but the form is mounted ONCE at screen mount time with `initialSatisfaction: null` (host can't know the value yet). After voice fills the form, the satisfaction picker would need a `updateSatisfaction(int)` method too OR the form's `_soulSatisfaction` stays at default 2 unless the user manually adjusts.
   - **Recommendation:** Pass `estimatedSatisfaction` via the form widget's existing `initialSatisfaction:` config field at the moment the form is built — but the form has already been built. Two options: (a) add a public `updateSatisfaction(int)` method to mirror D-07's pattern (4th sibling); (b) accept that satisfaction defaults to 2 in v1.3 voice flow and Phase 23+ adds the wiring. Planner decision — flag at discuss-phase. **Recommend (a)** — symmetry with D-07's three other setters; the audio-features→satisfaction pipeline is already wired, would be a shame to lose it on the same-screen rewrite.

3. **Save button enable predicate (D-11):** CONTEXT.md leaves this to planner discretion. Choice between (i) `_formKey.currentState?.canSubmit` (if added as a new getter) vs (ii) `_resolvedCategory != null && _amount > 0` (host-side check).
   - **What we know:** Manual screen uses `_canSave` (line 89 in `manual_one_step_screen.dart`): `_selectedCategory != null && !_isSubmitting`. Form doesn't currently expose a public `canSubmit` getter.
   - **What's unclear:** Whether the planner wants to add a getter to the form widget (consistent with the public-API expansion theme of Phase 22) or keep the predicate host-side (consistent with manual screen).
   - **Recommendation:** Host-side predicate, mirroring manual screen's `_canSave` pattern. Add a tiny `get _canSave => _resolvedCategory != null && _mergedAmount != null && _mergedAmount! > 0 && !_isSubmitting;` to `_VoiceInputScreenState`. No form-widget API change needed for the Save button.

## Environment Availability

> Phase 22 has zero new external CLI / runtime / service dependencies. Everything needed is already provisioned in the project's standard toolchain.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All Dart compilation | ✓ | 3.44.0 (verified above) | — |
| Dart SDK | Bundled | ✓ | Bundled with Flutter 3.44.0 | — |
| `flutter gen-l10n` | ARB regeneration | ✓ | Bundled with Flutter | — |
| `flutter test` | Widget + integration tests | ✓ | Bundled | — |
| `flutter analyze` | Static analysis gate | ✓ | Bundled | — |
| `build_runner` | NOT REQUIRED in Phase 22 | ✓ (project already has it) | n/a — no annotated changes | — |

**Missing dependencies with no fallback:** none
**Missing dependencies with fallback:** none

## Validation Architecture

> `nyquist_validation: true` per `.planning/config.json` — section included.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` (bundled with Flutter 3.44.0) + `mocktail ^1.x` (existing project dep) |
| Config file | `pubspec.yaml` `dev_dependencies` + `analysis_options.yaml` (existing) |
| Quick run command | `flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INPUT-02 (SC-1) | Voice transcript fills form fields in-place; user can edit before saving. | widget | `flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart -p "INPUT-02"` | ✅ Extend |
| INPUT-02 (SC-2) | Save path stamps `entry_source = 'voice'`. | integration | `flutter test test/integration/features/accounting/voice_save_entry_source_test.dart` | ❌ NEW — Wave 2 |
| REC-01 (SC-3 caption) | Idle caption = `l10n.holdToRecord`; recording caption = `l10n.recording`. | widget | `flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart -p "REC-01"` | ✅ Extend |
| REC-01 (SC-3 misfire) | Hold < 300 ms → no parse, no fill, `speechService.cancel()` called. | widget | `flutter test test/widget/.../voice_input_screen_test.dart -p "misfire"` | ✅ Extend |
| REC-02 (SC-4 visual) | Idle vs recording golden + decoration introspection (`borderRadius ≈ 16` vs `≈ 36`, red gradient on recording). | golden + widget | `flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_mic_button_golden_test.dart` | ❌ NEW — Wave 0 |
| REC-02 (SC-4 timing) | `Stopwatch` around `setState → pump` < 100 ms. | widget | `flutter test test/widget/.../voice_input_screen_test.dart -p "100ms"` | ✅ Extend |
| D-08 overwrite | Pre-filled amount=100; voice fills 5000 → form amount=5000 post-release. | widget | `flutter test test/widget/.../voice_input_screen_test.dart -p "D-08"` | ✅ Extend |
| D-09 focus interrupts | Long-press start → tap merchant TextField → recording stops, no batch fill. | widget | `flutter test test/widget/.../voice_input_screen_test.dart -p "D-09"` | ✅ Extend |
| D-07 form widget | `updateCategory`, `updateMerchant`, `updateNote` mutate state correctly. | widget | `flutter test test/widget/features/accounting/presentation/widgets/transaction_details_form_test.dart -p "D-07"` | ❌ Extend existing |

### Sampling Rate

- **Per task commit:** `flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` (< 10 s)
- **Per wave merge:** `flutter test` (full suite, ~60 s)
- **Phase gate:** Full suite green + `flutter analyze` 0 issues before `/gsd:verify-work`.

### Wave 0 Gaps

- [ ] `test/widget/features/accounting/presentation/screens/voice_input_screen_mic_button_golden_test.dart` — NEW golden harness for SC-4 (idle state only, single locale × single theme matrix per D-12).
- [ ] `test/widget/features/accounting/presentation/screens/voice_input_screen_mic_button_golden.png` — idle golden baseline (generated via `flutter test --update-goldens` on first run).
- [ ] `test/integration/features/accounting/voice_save_entry_source_test.dart` — NEW integration test for SC-2 (mirror `manual_save_entry_source_test.dart` structure).
- [ ] DELETE or rename `test/widget/features/accounting/presentation/screens/voice_to_manual_one_step_screen_test.dart` (Phase 19 D-16 regression test) — voice→manual push no longer exists; coverage subsumed by new SC-2 integration test.
- [ ] Existing `voice_input_screen_test.dart` requires major rewrite — strip assertions on `VoiceRecognitionResultCard`/`認識結果`/`タップして録音` and replace with hold-to-record + caption-swap + 100ms + batch-fill + focus-interrupts assertions.

*(All other test files for Phase 22 are extensions of existing files, not new wave-0 scaffolding.)*

## Security Domain

> `security_enforcement` is not explicitly set in `.planning/config.json` — treated as enabled. Phase 22 is a UI-only change with no new auth, persistence, or crypto surfaces, so ASVS exposure is minimal but still documented.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Voice screen does not introduce auth surface. Existing biometric/secure-storage flows untouched. |
| V3 Session Management | no | No new sessions; only ephemeral in-memory recording state. |
| V4 Access Control | no | No new access boundaries; transaction save still flows through `CreateTransactionUseCase` with existing checks. |
| V5 Input Validation | partial | Voice transcript → `ParseVoiceInputUseCase` is the validation point. Phase 21 already enforces always-L2 category contract; Phase 20 already constrains amount parsing. Phase 22 adds no new validation surface — it consumes outputs of phases that already validated. |
| V6 Cryptography | no | No crypto changes. Field encryption + DB encryption (SQLCipher) flow remains controlled by existing `infrastructure/crypto/` paths. |
| V7 Error Handling & Logging | partial | Phase 22's `_cancelRecordingAndDiscard` should NOT log the partial transcript (it may contain accidental sensitive utterance like "card number"). Current logging in `_onError` (lines 132-138) does not log transcript text — preserved. |
| V8 Data Protection | no | Voice transcript is in-memory only; never persisted unless saved as a transaction note. Note field already routes through `_encryptionService.encryptField` in `TransactionRepositoryImpl` (Phase 18 verified). |

### Known Threat Patterns for Flutter UI + voice

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Voice transcript leakage via crash logs | Information disclosure | Don't log raw `_finalText` / `_partialText` in production. Existing `_onError` callback already does not log transcript. |
| Stuck recording state (mic stays "live" without user awareness) | (UX, not STRIDE) | Pitfall 7 — `WidgetsBindingObserver` recommended (Open Q1). |
| Hostile ARB injection (e.g., `holdToRecord` overridden by a malicious locale) | Tampering (low) | ARB files are checked into git; project does not load locales from untrusted sources. Standard threat — not a Phase 22 regression. |
| Sensitive data spoken into mic and saved to note field | Information disclosure | User-controlled; out of scope. The note field encrypts at rest (Phase 18 verified). |

## Sources

### Primary (HIGH confidence — codebase + Flutter SDK source on disk)

- **Flutter SDK 3.44.0 source on disk:**
  - `/Users/xinz/flutter/packages/flutter/lib/src/gestures/long_press.dart:281-290` — `LongPressGestureRecognizer` constructor with `duration` parameter.
  - `/Users/xinz/flutter/packages/flutter/lib/src/widgets/gesture_detector.dart:1122-1140` — proof that `GestureDetector` does NOT pass `duration` to the recognizer.
  - `/Users/xinz/flutter/packages/flutter/lib/src/gestures/long_press.dart:44, 79, 101, 148, 221` — callback typedefs + `LongPressStartDetails`/`LongPressEndDetails` classes.
  - `/Users/xinz/flutter/packages/flutter_test/lib/src/controller.dart:1172-1218` — `tester.press`, `tester.longPress`, `tester.startGesture`.
- **Project codebase verified by Read/grep:**
  - `lib/features/accounting/presentation/screens/voice_input_screen.dart` (813 lines, current state).
  - `lib/features/accounting/presentation/widgets/transaction_details_form.dart` (lines 188-192, public setter pattern).
  - `lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart` (Phase 19 D-14 extracted artifact, reused as-is).
  - `lib/features/accounting/presentation/screens/manual_one_step_screen.dart:71-101, 171-179` (per-FocusNode listener precedent).
  - `lib/application/voice/voice_chunk_merger.dart:101-103, 189-200` (merger user-stop semantics).
  - `lib/application/voice/parse_voice_input_use_case.dart` (use case signature + return shape).
  - `lib/application/voice/start_speech_recognition_use_case.dart:42-45` (`stop()` vs `cancel()`).
  - `lib/l10n/app_{ja,zh,en}.arb:1041-1044` (current `tapToRecord` location).
  - `lib/core/theme/app_colors.dart` (no `error`/`recording*` constants exist today).
  - `l10n.yaml` (ARB → S class config).
  - `test/integration/features/accounting/manual_save_entry_source_test.dart:218-242` (entry_source integration test pattern).
  - `test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart:1-80` (golden test setup pattern).
  - `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` (current widget tests).
  - `.planning/config.json` (workflow flags).
- **Phase 18/19/20/21 CONTEXT.md** — all four prior phase decisions verified by Read.

### Secondary (MEDIUM confidence — official Flutter docs fetched live)

- [api.flutter.dev/flutter/widgets/AnimatedSwitcher-class.html](https://api.flutter.dev/flutter/widgets/AnimatedSwitcher-class.html) — default cross-fade transition, keyed-child detection (fetched 2026-05-25).
- [api.flutter.dev/flutter/painting/BoxDecoration/shape.html](https://api.flutter.dev/flutter/painting/BoxDecoration/shape.html) — "If this is BoxShape.circle then borderRadius is ignored"; ShapeDecoration recommendation for circle ↔ rounded square morph (fetched 2026-05-25).
- [api.flutter.dev/flutter/widgets/GestureDetector-class.html](https://api.flutter.dev/flutter/widgets/GestureDetector-class.html) — callback enumeration (fetched 2026-05-25).
- [docs.flutter.dev/cookbook/testing/widget/tap-drag](https://docs.flutter.dev/cookbook/testing/widget/tap-drag) — `tester.tap` / `tester.longPress` / `tester.pump` vs `pumpAndSettle` distinction (fetched 2026-05-25).
- [github.com/flutter/flutter/issues/96275](https://github.com/flutter/flutter/issues/96275) — proposal for `GestureDetector.longPressDuration` (still open in 2026; workaround is RawGestureDetector + custom recognizer).

### Tertiary (LOW confidence — web search synthesis)

- WebSearch synthesis: "Flutter GestureDetector LongPressGestureRecognizer customize duration Duration.zero instant press" — confirmed (verified against SDK source).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every primitive verified against Flutter 3.44.0 SDK source on disk.
- Architecture: HIGH — every codebase pattern verified by Read/grep on actual project files.
- Pitfalls: MEDIUM-HIGH — Pitfalls 1, 5, 6 verified against codebase; Pitfalls 7, 8, 9, 10 derived from established Flutter/codebase patterns.
- 100 ms timing test reliability: MEDIUM — A1 documents flake risk.
- `borderRadius: 36` ≈ circle equivalence: HIGH — geometric, but A2 documents the golden anti-aliasing edge case.

**Research date:** 2026-05-25
**Valid until:** 2026-06-24 (30 days — stable area: well-known Flutter primitives + frozen codebase patterns from Phase 18/19/20/21).
