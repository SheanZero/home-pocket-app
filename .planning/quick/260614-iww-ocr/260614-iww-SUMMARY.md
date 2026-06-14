---
phase: quick-260614-iww
plan: 01
subsystem: accounting-entry
tags: [feature-flag, ocr-hide, fab-gesture, continuous-entry, i18n]
requires:
  - InputModeTabs / EntryModeSwitcher (add-transaction mode switcher)
  - HomeBottomNavBar + MainShellScreen (FAB host)
  - ManualOneStepScreen / VoiceInputScreen (add screens)
  - showSuccessFeedback (lib/shared/widgets/feedback_toast.dart)
provides:
  - kOcrEntryEnabled compile-time flag (reversibly hides OCR add-entry tab)
  - onFabLongPress wiring → continuous add-entry mode
  - continuousMode-conditional save (pop+done vs stay+keep-going+exit)
  - entrySavedDone / continuousKeepGoing / continuousExitHint (ja/zh/en)
affects:
  - add-transaction flow (manual + voice)
  - OCR entry visibility (hidden, infra retained)
tech-stack:
  added: []
  patterns: [compile-time-feature-flag, gesture-threaded-mode, conditional-save-branch]
key-files:
  created:
    - lib/core/constants/feature_flags.dart
    - .planning/quick/260614-iww-ocr/deferred-items.md
  modified:
    - lib/features/accounting/presentation/widgets/input_mode_tabs.dart
    - lib/features/accounting/presentation/navigation/entry_mode_navigation_config.dart
    - lib/features/accounting/presentation/widgets/entry_mode_switcher.dart
    - lib/features/home/presentation/widgets/home_bottom_nav_bar.dart
    - lib/features/home/presentation/screens/main_shell_screen.dart
    - lib/features/accounting/presentation/screens/manual_one_step_screen.dart
    - lib/features/accounting/presentation/screens/voice_input_screen.dart
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/l10n/app_en.arb
    - test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart
    - test/widget/features/accounting/presentation/widgets/entry_mode_switcher_test.dart
decisions:
  - "OCR hidden via const kOcrEntryEnabled=false + `if (flag)` render + nav short-circuit; route-config map and OcrScannerScreen import retained so a one-line flip restores it"
  - "continuousMode threaded from FAB gesture → MainShellScreen.openAddEntry → ManualOneStepScreen; EntryModeRouteConfig.builder gains a continuousMode arg so manual↔voice switching preserves the mode"
  - "Single-tap save now pops ONCE (was always-keep-going on manual / popUntil(isFirst) on voice); continuous mode keeps the legacy stay-open + reset, gated behind the flag"
  - "Voice joy-ledger celebration deferral preserved in BOTH modes (pop / keep-going run after waitForCelebrationDismissed)"
metrics:
  duration: ~22min
  completed: 2026-06-14
---

# Quick Task 260614-iww: Hide OCR entry + tap/long-press continuous accounting Summary

Reversibly hid the user-visible OCR/scan add-entry tab behind a single compile-time flag (OCR infra and screens untouched), and split the add-entry FAB into tap (save → pop + warm "recorded" toast) vs long-press (continuous mode: save stays open, clears the form, warm "keep going" toast + a discoverable on-page exit affordance), with new warm trilingual copy.

## What was built

### Task 1 — Reversibly hide the OCR add-entry tab (commit `10236350`)
- New `lib/core/constants/feature_flags.dart` exporting `const bool kOcrEntryEnabled = false` with a doc comment explaining the OCR infra is intentionally retained and a flip to `true` restores everything.
- `InputModeTabs`: the OCR `_tab(...)` is now wrapped in `if (kOcrEntryEnabled)`; manual + voice always render. The `InputMode.ocr` enum value, `ocrLabel`, and `Icons.document_scanner_outlined` are all kept.
- `entry_mode_navigation_config.dart`: early `return` when `toMode == InputMode.ocr && !kOcrEntryEnabled`. The route-config map literal (and the `OcrScannerScreen` import) is left intact.
- OCR screens + `lib/infrastructure/ml/` + `lib/application/ocr/` byte-for-byte untouched.

### Task 2 — Trilingual copy + thread continuousMode (commit `9c9b6068`)
- ARB ja/zh/en: `entrySavedDone` (ja「記録できました！」zh「记好啦！」en "Got it — recorded!"), `continuousKeepGoing` (ja「記録しました。続けてどうぞ」zh「记好啦，继续记吧」en "Saved — keep going!"), `continuousExitHint` (ja「終了ボタンでいつでも戻れます」zh「点退出键可结束连续记账」en "Tap exit anytime to finish"), each with `@`-metadata. `flutter gen-l10n` regenerated the `S` getters.
- `HomeBottomNavBar`: added nullable `onFabLongPress`; the FAB `GestureDetector` now has `onLongPress: onFabLongPress`.
- `MainShellScreen`: factored the accounting onFabTap branch into a local `Future<void> openAddEntry({required bool continuousMode})` (preserving the full post-pop invalidate block); `onFabTap → openAddEntry(continuousMode:false)`, `onFabLongPress → openAddEntry(continuousMode:true)` gated to the accounting path (no-op/null on the shopping tab).
- `ManualOneStepScreen` + `VoiceInputScreen`: added `final bool continuousMode` (default false).
- `EntryModeSwitcher` + nav config: added `continuousMode` and extended `EntryModeRouteConfig.builder` from `Widget Function(String)` to `Widget Function(String, bool)` so manual↔voice switching preserves the mode; OCR builder ignores it. Manual/voice call sites forward `widget.continuousMode`; the OCR-scanner call site relies on the default `false` (its screen file left untouched per constraint).

### Task 3 — continuousMode-conditional save + exit affordance (commit `45ed4332`)
- `ManualOneStepScreen._save`: branches on `widget.continuousMode`.
  - false: `showSuccessFeedback(entrySavedDone)` then `Navigator.pop()` once; no form reset.
  - true: longer (5s) `continuousKeepGoing` toast with a `recordingExitLink` action that pops once, then `_resetForContinuousEntry()` (legacy stay-open behavior, now gated).
  - AppBar in continuous mode surfaces a labelled `Exit` action (`palette.accentPrimary`) + the `continuousExitHint` near the switcher.
- `VoiceInputScreen._onSavePressed`: mirrors manual. Single-tap shows `entrySavedDone` then pops ONCE (replacing `popUntil((r)=>r.isFirst)`); continuous mode shows the keep-going toast + new `_resetForContinuousEntry()` analog (clears amount/currency/merchant/note/date + transcript + parse state, reverts to JPY-native). The joy-ledger celebration deferral (`waitForCelebrationDismissed`) is preserved in BOTH modes.

## Deviations from Plan

### Test updates (expected by the plan's verification clause)
- **[Test fix] manual_one_step_screen_test**: the test asserting the screen STAYS OPEN after a default-mode save (legacy 260603-nr1 always-keep-going) was updated to the new spec — single-tap (continuousMode:false) now pops back to the previous page (`findsNothing` + home route visible). Added a NEW positive test asserting continuous-mode save stays open, surfaces the Exit control + hint, and shows the keep-going toast.
- **[Test fix] entry_mode_switcher_test**: the "navigates to OCR screen when OCR tab is tapped" test was updated to the new spec — OCR tab is hidden behind `kOcrEntryEnabled=false`, so it now asserts the OCR icon is absent while manual + voice tabs remain. Removed the now-unused `OcrScannerScreen` import.

No Rule 1–4 auto-fixes were required; the implementation followed the plan exactly.

## Known Stubs

None. The OCR tab is intentionally hidden (not stubbed) and fully reversible via the documented flag; OCR infra remains wired and untouched.

## Verification

- `flutter analyze` → **No issues found** (whole project).
- `flutter gen-l10n` → succeeds; `entrySavedDone` / `continuousKeepGoing` / `continuousExitHint` resolve as `S.of(context)` getters in all 3 locales.
- `flutter test test/widget/features/accounting/ test/widget/features/home/` → **217 passed, 1 failed**. The single failure is `voice_input_screen_mic_button_idle.png` golden (0.98% diff on an isolated mic button this task never renders/touches) — pre-existing macOS-baseline font/AA drift, logged to `deferred-items.md` as out-of-scope.
- `flutter test test/architecture/ test/main_characterization_smoke_test.dart` → all pass (ARB key parity, hardcoded-CJK scan, smoke).
- OCR tab absent from the switcher; flipping `kOcrEntryEnabled` to `true` re-shows it with no other edits (asserted by the updated entry_mode_switcher test).

## Deferred Issues

- `voice_input_screen_mic_button_idle.png` golden re-baseline — pre-existing drift, out of scope (see `deferred-items.md`). Re-baseline on macOS in a dedicated golden-refresh pass.

## Self-Check: PASSED

- Created files exist: `lib/core/constants/feature_flags.dart` FOUND.
- Commits exist: `10236350` FOUND, `9c9b6068` FOUND, `45ed4332` FOUND.
