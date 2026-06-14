---
phase: quick-260614-iww
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/core/constants/feature_flags.dart
  - lib/features/accounting/presentation/widgets/input_mode_tabs.dart
  - lib/features/accounting/presentation/navigation/entry_mode_navigation_config.dart
  - lib/features/home/presentation/widgets/home_bottom_nav_bar.dart
  - lib/features/home/presentation/screens/main_shell_screen.dart
  - lib/features/accounting/presentation/screens/manual_one_step_screen.dart
  - lib/features/accounting/presentation/screens/voice_input_screen.dart
  - lib/features/accounting/presentation/widgets/entry_mode_switcher.dart
  - lib/l10n/app_ja.arb
  - lib/l10n/app_zh.arb
  - lib/l10n/app_en.arb
autonomous: true
requirements: [IWW-OCR-HIDE, IWW-TAP-LONGPRESS]
must_haves:
  truths:
    - "OCR/scan tab no longer visible in the add-transaction mode switcher (manual / voice only)"
    - "OCR infra (lib/infrastructure/ml, lib/application/ocr) and OcrScanner/OcrReview screens untouched; re-enable via one flag flip"
    - "FAB tap: save (manual OR voice) pops to previous page + warm 'recorded' toast"
    - "FAB long-press: continuous mode; save stays open, clears form, warm 'keep going' toast, visible exit affordance back to previous page"
    - "New copy in ja/zh/en ARB, warm non-robotic tone; ja (default) equal care"
  artifacts:
    - path: "lib/core/constants/feature_flags.dart"
      provides: "kOcrEntryEnabled compile-time flag (false) to reversibly hide OCR entry"
      contains: "kOcrEntryEnabled"
    - path: "lib/features/accounting/presentation/screens/manual_one_step_screen.dart"
      provides: "continuousMode-aware save: pop+done (tap) vs stay+keep-going+exit (long-press)"
    - path: "lib/features/accounting/presentation/screens/voice_input_screen.dart"
      provides: "continuousMode-aware save branch matching manual screen"
  key_links:
    - from: "lib/features/home/presentation/widgets/home_bottom_nav_bar.dart"
      to: "lib/features/home/presentation/screens/main_shell_screen.dart"
      via: "onFabLongPress callback"
      pattern: "onFabLongPress"
    - from: "lib/features/home/presentation/screens/main_shell_screen.dart"
      to: "lib/features/accounting/presentation/screens/manual_one_step_screen.dart"
      via: "continuousMode constructor arg"
      pattern: "continuousMode"
    - from: "lib/features/accounting/presentation/widgets/input_mode_tabs.dart"
      to: "lib/core/constants/feature_flags.dart"
      via: "kOcrEntryEnabled conditional render"
      pattern: "kOcrEntryEnabled"
---

<objective>
Two independent changes to the add-transaction flow, grounded in verified code paths.

1. Reversibly hide the OCR entry. The ONLY user-visible OCR entry is the middle tab
   (Icons.document_scanner_outlined, label l10n.ocrScan) in InputModeTabs (rendered by
   EntryModeSwitcher on manual/voice/ocr screens). OcrScannerScreen and OcrReviewScreen are
   reachable ONLY via that tab + the InputMode.ocr route in entry_mode_navigation_config.dart.
   Hide via a single compile-time flag, NOT deletion. OCR infra (lib/infrastructure/ml/,
   lib/application/ocr/) and OCR screen files stay byte-for-byte untouched — re-enable is a
   one-line flag flip.

2. Tap vs long-press the add-entry FAB. Tap (single): open add screen, save pops to the
   previous page + warm "recorded" toast. Long-press: open in continuous mode, save stays on
   page, clears the form, warm "keep going" toast + a visible exit affordance returning to the
   previous page.

   Current state: ManualOneStepScreen._save ALREADY stays-open + resets + shows successKeepGoing
   (always-on, quick 260603-nr1). VoiceInputScreen._onSavePressed ALWAYS popUntil(isFirst). This
   plan makes BOTH conditional on a new continuousMode flag threaded from the FAB gesture.

Output: feature flag + OCR tab hidden + FAB long-press wiring + conditional save + trilingual copy.
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@CLAUDE.md
@lib/features/accounting/presentation/widgets/input_mode_tabs.dart
@lib/features/accounting/presentation/widgets/entry_mode_switcher.dart
@lib/features/accounting/presentation/navigation/entry_mode_navigation_config.dart
@lib/features/home/presentation/widgets/home_bottom_nav_bar.dart
@lib/features/accounting/presentation/screens/manual_one_step_screen.dart
@lib/features/accounting/presentation/screens/voice_input_screen.dart
@lib/shared/widgets/feedback_toast.dart
</context>

<tasks>

<task type="auto">
  <name>Task 1: Reversibly hide the OCR add-entry tab behind a feature flag</name>
  <files>lib/core/constants/feature_flags.dart, lib/features/accounting/presentation/widgets/input_mode_tabs.dart, lib/features/accounting/presentation/navigation/entry_mode_navigation_config.dart</files>
  <action>
    Create lib/core/constants/feature_flags.dart exporting top-level `const bool kOcrEntryEnabled = false;` with a doc comment: temporarily hides the user-visible OCR/scan add-entry tab while OCR is being completed; flipping to true fully restores it; OCR infra is intentionally retained.

    input_mode_tabs.dart: import the flag; build the Row children so the OCR _tab(...) is included only `if (kOcrEntryEnabled)`. Keep manual + voice always present. Do NOT remove the InputMode.ocr enum value, ocrLabel, or Icons.document_scanner_outlined — leave them so the flip needs no re-add.

    entry_mode_navigation_config.dart: keep the _entryModeRouteConfigs map literal intact (so OcrScannerScreen import stays referenced); inside navigateToEntryMode add an early return when `toMode == InputMode.ocr && !kOcrEntryEnabled`. Leave the OcrScannerScreen import untouched.

    Do NOT touch ocr_scanner_screen.dart, ocr_review_screen.dart, lib/infrastructure/ml/, lib/application/ocr/.
  </action>
  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app && grep -q "kOcrEntryEnabled" lib/core/constants/feature_flags.dart && grep -q "kOcrEntryEnabled" lib/features/accounting/presentation/widgets/input_mode_tabs.dart && flutter analyze lib/features/accounting/presentation/widgets/input_mode_tabs.dart lib/features/accounting/presentation/navigation/entry_mode_navigation_config.dart lib/core/constants/feature_flags.dart</automated>
  </verify>
  <done>kOcrEntryEnabled=false; OCR tab omitted from InputModeTabs; OCR navigation short-circuited; OCR screens + infra unmodified; analyze clean for touched files; flip to true restores the tab with no other edits.</done>
</task>

<task type="auto">
  <name>Task 2: Add trilingual copy + thread continuousMode through FAB and add screens</name>
  <files>lib/l10n/app_ja.arb, lib/l10n/app_zh.arb, lib/l10n/app_en.arb, lib/features/home/presentation/widgets/home_bottom_nav_bar.dart, lib/features/home/presentation/screens/main_shell_screen.dart, lib/features/accounting/presentation/widgets/entry_mode_switcher.dart, lib/features/accounting/presentation/navigation/entry_mode_navigation_config.dart, lib/features/accounting/presentation/screens/manual_one_step_screen.dart, lib/features/accounting/presentation/screens/voice_input_screen.dart</files>
  <action>
    ARB — add to ALL THREE files (matching keys + @-metadata, warm non-robotic tone; ja is DEFAULT, equal care). Reuse existing recordingExitLink for the exit action label. Add:
      entrySavedDone (single-tap pop toast): ja「記録できました！」 zh「记好啦！」 en "Got it — recorded!"
      continuousKeepGoing (long-press stay toast): ja「記録しました。続けてどうぞ」 zh「记好啦，继续记吧」 en "Saved — keep going!"
      continuousExitHint (exit hint): ja「終了ボタンでいつでも戻れます」 zh「点退出键可结束连续记账」 en "Tap exit anytime to finish"
    Then run flutter gen-l10n.

    home_bottom_nav_bar.dart: add `final VoidCallback? onFabLongPress;` (nullable, keep onFabTap); in _buildFab the FAB GestureDetector gains `onLongPress: onFabLongPress`.

    main_shell_screen.dart: factor the existing onFabTap accounting branch (the else opening ManualOneStepScreen + post-pop invalidate block) into a local `Future<void> openAddEntry({required bool continuousMode})` pushing `ManualOneStepScreen(bookId: bookId, continuousMode: continuousMode)` and keeping the invalidate block. Wire `onFabTap: () => openAddEntry(continuousMode: false)` and `onFabLongPress: () => openAddEntry(continuousMode: true)`. Keep the shopping-tab (currentIndex==3) branch unchanged; gate long-press to the accounting path only (no-op/normal on shopping).

    ManualOneStepScreen: add `final bool continuousMode;` (default false). VoiceInputScreen: add the same field (default false).

    EntryModeSwitcher + entry_mode_navigation_config: add optional `bool continuousMode` so manual↔voice switching preserves the mode. Add `this.continuousMode = false` to EntryModeSwitcher; pass it into navigateToEntryMode; extend EntryModeRouteConfig.builder from `Widget Function(String bookId)` to `Widget Function(String bookId, bool continuousMode)` so Manual/Voice screens get the same continuousMode. Update all 3 EntryModeSwitcher call sites (manual ~678, voice ~694, ocr scanner ~61) to forward their host's continuousMode (ocr scanner passes false).

    Follow immutability + Riverpod 3 conventions. Run build_runner + gen-l10n after @freezed/@riverpod/ARB edits.
  </action>
  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app && grep -q "entrySavedDone" lib/l10n/app_ja.arb && grep -q "entrySavedDone" lib/l10n/app_zh.arb && grep -q "entrySavedDone" lib/l10n/app_en.arb && grep -q "onFabLongPress" lib/features/home/presentation/widgets/home_bottom_nav_bar.dart && grep -q "continuousMode" lib/features/home/presentation/screens/main_shell_screen.dart && grep -q "continuousMode" lib/features/accounting/presentation/screens/voice_input_screen.dart && flutter gen-l10n</automated>
  </verify>
  <done>entrySavedDone / continuousKeepGoing / continuousExitHint in all 3 ARB; gen-l10n regenerates S getters; FAB exposes onFabLongPress; main_shell opens add screen with continuousMode false (tap) / true (long-press); Manual, Voice, EntryModeSwitcher all accept + forward continuousMode.</done>
</task>

<task type="auto">
  <name>Task 3: Branch save on continuousMode in both screens + exit affordance</name>
  <files>lib/features/accounting/presentation/screens/manual_one_step_screen.dart, lib/features/accounting/presentation/screens/voice_input_screen.dart</files>
  <action>
    ManualOneStepScreen._save success branch (currently ALWAYS stays open + resets + successKeepGoing): make conditional on widget.continuousMode.
      continuousMode == false: showSuccessFeedback(context, S.of(context).entrySavedDone) (default duration, no action), then Navigator.of(context).pop() to the previous page. Do NOT call _resetForContinuousEntry.
      continuousMode == true: keep stay-open — show continuousKeepGoing (longer duration ~5s) with actionLabel S.of(context).recordingExitLink whose onAction does Navigator.of(context).pop() (single pop returns to the page before the add screen — NOT popUntil(isFirst)), then call _resetForContinuousEntry().

    Exit affordance for continuous mode (req: 页面上明确的退出按钮): when widget.continuousMode is true, surface an exit control + the continuousExitHint near the AppBar — e.g. an AppBar actions TextButton labeled recordingExitLink that pops once, plus the hint. Any colored exit control uses context.palette.accentPrimary (NEVER hardcode hex). The existing AppBar close (Icons.close ~655) already pops once and serves as exit; keep single-tap mode's close behavior intact.

    VoiceInputScreen._onSavePressed (currently ALWAYS popUntil(isFirst), with joy-ledger celebration deferral): mirror manual.
      continuousMode == false: show entrySavedDone, then pop ONCE to previous page (replace popUntil((route)=>route.isFirst) with Navigator.of(context).pop() on the survival path; on the joy path, after waitForCelebrationDismissed() also pop() once).
      continuousMode == true: show continuousKeepGoing (longer duration + recordingExitLink action popping once), reset the voice form in place for the next entry (mirror manual's _resetForContinuousEntry — clear amount/category/merchant/note, re-seed default, restore mic-ready state; add a _resetForContinuousEntry() analog). Do NOT pop.

    PRESERVE the joy-ledger celebration overlay deferral in BOTH branches: celebration must still play before any pop; in continuous mode (no pop) run keep-going toast + reset after celebration where applicable.

    Keep copyWith immutability, Riverpod 3 conventions, `if (!mounted) return;` on every async-gap context use. flutter analyze 0 issues; existing tests stay green.
  </action>
  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app && grep -q "continuousMode" lib/features/accounting/presentation/screens/manual_one_step_screen.dart && grep -q "entrySavedDone" lib/features/accounting/presentation/screens/manual_one_step_screen.dart && grep -q "entrySavedDone" lib/features/accounting/presentation/screens/voice_input_screen.dart && flutter analyze lib/features/accounting/presentation/screens/manual_one_step_screen.dart lib/features/accounting/presentation/screens/voice_input_screen.dart lib/features/home/presentation/screens/main_shell_screen.dart lib/features/home/presentation/widgets/home_bottom_nav_bar.dart</automated>
  </verify>
  <done>Single-tap save pops once + entrySavedDone (manual AND voice); long-press continuous save stays open, resets form, continuousKeepGoing with exit action that pops once, plus a discoverable on-page exit control; voice joy-ledger celebration still plays in both modes; analyze 0 issues on all touched screens.</done>
</task>

</tasks>

<verification>
- flutter analyze → 0 issues across the whole project before declaring done.
- flutter gen-l10n succeeds; entrySavedDone / continuousKeepGoing / continuousExitHint resolve as S.of(context) getters.
- OCR tab absent from the mode switcher; flipping kOcrEntryEnabled to true would re-show it with no other edits.
- flutter test → existing suite stays green (run accounting + home widget tests). If a test asserted the old always-pop or always-keep-going behavior, update it to the new continuousMode-conditional spec (fix the test to match, do not weaken it).
</verification>

<success_criteria>
- OCR add-entry tab hidden behind kOcrEntryEnabled=false; OCR infra + screens untouched; reversible via one flag flip.
- FAB tap → save → pop to previous page + warm entrySavedDone toast (manual AND voice).
- FAB long-press → continuous mode → save → stay + clear form + warm continuousKeepGoing toast + visible/actionable exit affordance returning to previous page.
- All copy warm and present in ja/zh/en; flutter analyze 0 issues; existing tests green.
</success_criteria>

<output>
Create `.planning/quick/260614-iww-ocr/260614-iww-SUMMARY.md` when done.
</output>
