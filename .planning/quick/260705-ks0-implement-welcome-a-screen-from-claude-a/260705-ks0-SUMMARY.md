---
phase: quick-260705-ks0
plan: 01
subsystem: onboarding
status: complete
tags: [onboarding, ui-reskin, welcome-a, l10n, pageview]
requirements: [WELA-01, WELA-02, WELA-03, WELA-04]
dependency-graph:
  requires:
    - "Welcome-A.dc.html design source (committed at c32abcf0)"
    - "SatisfactionFaceIcon (lib/shared/widgets/satisfaction_face_icon.dart)"
    - "AppPalette v1.6 tokens (ADR-019)"
  provides:
    - "3-page Welcome A onboarding intro (welcome/privacy/joy PageView)"
    - "Design-04 re-skinned onboarding settings screen"
    - "FloatyLoop/DriftPetal decor widgets with test kill-switch"
    - "NumberFormatter.currencySymbol public lookup"
  affects:
    - "test/flutter_test_config.dart (global animationsEnabled=false)"
tech-stack:
  added: []
  patterns:
    - "@visibleForTesting static kill-switch for repeating tickers (cf. showConfidenceBand)"
    - "inline SvgPicture.string glyphs with palette-interpolated stroke color (COLOR-01 compliant)"
key-files:
  created:
    - lib/features/onboarding/presentation/widgets/onboarding_float_decor.dart
    - test/widget/features/onboarding/onboarding_float_decor_test.dart
  modified:
    - lib/features/onboarding/presentation/screens/onboarding_intro_screen.dart
    - lib/features/onboarding/presentation/screens/onboarding_settings_screen.dart
    - lib/infrastructure/i18n/formatters/number_formatter.dart
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/l10n/app_en.arb
    - lib/generated/ (regenerated, force-added)
    - test/flutter_test_config.dart
    - test/widget/features/onboarding/onboarding_intro_test.dart
    - test/widget/features/onboarding/onboarding_settings_test.dart
    - test/widget/features/onboarding/onboarding_flow_test.dart
    - test/widget/features/onboarding/onboarding_completion_gate_refresh_test.dart
decisions:
  - "House/shield glyphs: inline SvgPicture.string with palette-fed hex (design fidelity) instead of Material icon fallback"
  - "Language segments carry ValueKeys (onboarding-lang-*) — text finders are ambiguous when host device locale makes the voice-row value collide with a segment label"
  - "en onboardingRowCurrency stays 'Currency' (natural English) while ja→通貨単位 / zh→货币单位"
metrics:
  duration: "143 min (across session-limit reset)"
  completed: "2026-07-05"
  tasks: 3
  tests: "3566 passed (full suite), analyze 0"
---

# Quick 260705-ks0: Implement Welcome A Screen Summary

3-page Welcome A onboarding intro (PageView: ようこそ/プライバシー/記録の悦び with dots + skip) plus design-04 settings re-skin (inline name field, 4-segment language selector, chip picker rows) — visuals only, all persistence/callback contracts byte-preserved.

## Task Commits

| Task | Name | Commit(s) |
| ---- | ---- | --------- |
| 1 | Float/petal decor widgets + test kill-switch | `fcd4b726` (feat) |
| 2 | 3-page Welcome A intro PageView + ARB + tests | `00f56de7` (test RED), `a017b9b3` (feat GREEN) |
| 3 | Design-04 settings re-skin + full-suite gates | `c25530e8` (test RED), `7e73b95b` (feat GREEN) |

## What Was Built

- **`onboarding_float_decor.dart`** — `FloatyLoop` (smooth-loop translateY 0→-7→0, period/phase params) and `DriftPetal` (translateY 0→-9→0 + rotate 45°→60°→45°, asymmetric 62% corner radius). `OnboardingFloatDecor.animationsEnabled` (`@visibleForTesting`) is forced off in `test/flutter_test_config.dart` so every existing `pumpAndSettle` (incl. `main_characterization_smoke_test`) terminates; verified `transientCallbackCount > 0` when on-device default is restored.
- **Intro rebuild** — `OnboardingIntroScreen` is now a StatefulWidget owning a `PageController`; 次へ pages internally, page-3 はじめる and the always-visible top-right スキップ both fire the unchanged single `onContinue` callback (D-02 skip-collapses-to-continue). Dots: active pill 20×6 accentPrimary, inactive 6×6 borderDefault. House/shield glyphs are inline SVG strings with stroke/fill interpolated from `AppPalette` at build time (zero raw hex; `Color(0x…)` scan untouched). Dark mode raises petal opacities to .7/.55 per the dark frames. Each page is scroll-safe via `LayoutBuilder` + `SingleChildScrollView`.
- **Settings re-skin** — eyebrow (最後のステップ) + two-line title, 88×88 tappable avatar with a 30×30 camera badge (opens the existing `AvatarPickerScreen`), inline nickname `TextField` (replaces `_NicknameDialog`, deleted 0-ref), 4 language segments calling `_applyLanguageSelection('ja'|'zh'|'en'|'system')` directly (replaces the dialog picker), currency/voice 46px chip rows opening the existing sheet/dialog, flat accent この設定ではじめる button. `_confirm` pipeline, `_canStart` (D-14), locale write-through (D-07/D-08), voice resolver (D-09) and `onConfirmed` are semantically identical to the previous implementation.
- **ARB** — added 15 intro + 6 setup keys (ja verbatim from the design HTML, natural zh/en); deleted 14 orphaned keys symmetrically across all 3 files after grep-confirming 0 references (9 old selling-point keys + `onboardingSettingsTitle/Subtitle/Hint`, `onboardingChange`, `onboardingNicknameUnset`); updated `onboardingStart` ja → この設定ではじめる and `onboardingRowCurrency` ja → 通貨単位 / zh → 货币单位. Note: the 54-02 lock on `onboardingStart` was about key separation from `profileStart`, not copy freeze. `lib/generated/` re-added with `git add -f` after every gen-l10n run (Phase 46 lesson).

## Deviations from Plan

### Auto-fixed / executor-call items

**1. [Rule 3 - Blocking] Exposed `NumberFormatter.currencySymbol`**
- **Found during:** Task 3 (currency chip needs the bare symbol; `_getCurrencySymbol` was private and the plan forbids new data tables)
- **Fix:** added a 2-line public delegate on `NumberFormatter` (infrastructure file not in the plan's `files_modified` list)
- **Files modified:** `lib/infrastructure/i18n/formatters/number_formatter.dart`
- **Commit:** `7e73b95b`

**2. [Rule 1 - Bug] Language segments get ValueKeys**
- **Found during:** Task 3 GREEN (test host device locale is `en`, so the voice-row value "English" collided with the English segment text finder)
- **Fix:** `ValueKey('onboarding-lang-ja'|'zh'|'en'|'system')` on the segments; tests find/tap by key
- **Commit:** `7e73b95b`

**3. Executor call per plan latitude:** decorative glyphs use inline `SvgPicture.string` (design's exact paths) rather than the Material-icon fallback; privacy card icons use the plan's suggested Material equivalents.

## TDD Gate Compliance

Both `tdd="true"` tasks followed RED→GREEN with gate commits: `00f56de7`→`a017b9b3` (intro) and `c25530e8`→`7e73b95b` (settings). No unexpected-pass during RED (4/5 intro tests and 5/6 settings tests failed as expected; the passers exercised contracts intentionally shared with the old UI, e.g. スキップ firing `onContinue`).

## Verification Results

- `flutter analyze` → 0 issues
- FULL `flutter test` (not piped) → **3566 passed, exit 0** (includes arb_key_parity, hardcoded_cjk_ui_scan, color_literal_scan, layer_import_rules, main_characterization_smoke)
- `git diff c32abcf0 -- onboarding_flow_screen.dart onboarding_lock_entry_screen.dart` → 0 lines (WELA-03 byte-unchanged)
- `dart format` run only on plan-touched files
- No goldens affected (none exist for onboarding)
- Manual device pass of light/dark frames + live floaty/drift loops: **deferred to user UAT** (non-blocking per plan)

## Known Stubs

None — every element is wired to real data/logic; the decor widgets are intentionally presentational.

## Threat Flags

None. T-q260705-01 mitigation confirmed: the inline nickname TextField feeds the same `SaveUserProfileUseCase` validation (nameRequired/nameTooLong/invalidEmoji); no new persistence surface, no logging added (T-q260705-02 accepted as planned).

## Self-Check: PASSED

- lib/features/onboarding/presentation/widgets/onboarding_float_decor.dart — FOUND
- lib/features/onboarding/presentation/screens/onboarding_intro_screen.dart — FOUND (rebuilt)
- lib/features/onboarding/presentation/screens/onboarding_settings_screen.dart — FOUND (re-skinned)
- Commits fcd4b726 / 00f56de7 / a017b9b3 / c25530e8 / 7e73b95b — FOUND in git log
