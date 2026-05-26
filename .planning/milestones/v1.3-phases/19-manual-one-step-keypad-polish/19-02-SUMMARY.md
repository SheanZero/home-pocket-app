---
phase: 19-manual-one-step-keypad-polish
plan: 02
subsystem: ui
tags: [flutter, smart-keyboard, responsive-layout, golden-tests, tabular-figures, layout-builder, mediaquery]

# Dependency graph
requires:
  - phase: 19-01
    provides: "AmountEditBottomSheet calling the POST-rename SmartKeyboard(actionLabel:) API (P19-B2 binding) — so the rename in this plan completes the migration without breaking Plan 01's caller"
provides:
  - "Refactored SmartKeyboard widget with responsive per-key height + non-negotiable 48 dp floor"
  - "Renamed constructor parameter: nextLabel (default 'Next') -> actionLabel (required, no default) — closes RESEARCH §Pitfall 6 leak"
  - "6 dp TOTAL visible column gap between adjacent keys (3 dp horizontal padding per side — P19-B3 fix)"
  - "12 dp inter-row gap (8 -> 12 dp per D-07)"
  - "Uniform action-row height (D-08 — backspace, ¥JPY, Save match digit-key keyHeight)"
  - "Tabular-figure digit glyphs (FontFeature.tabularFigures() on _DigitKey text style)"
  - "Widget test suite enforcing 48 dp floor on iPhone SE / 14 / Pro Max + rendered-gap distance + tabular figures + uniform action-row height"
  - "Golden test scaffold with 6 baseline PNGs (smart_keyboard_{ja,zh,en}_{light,dark}.png) — SC-3 regression baseline"
affects:
  - 19-03-plan (ManualOneStepScreen consumes the new actionLabel: API and the responsive height)
  - 19-04-plan (TransactionEditScreen + OcrReviewScreen host adoption — does NOT touch SmartKeyboard, indirect dependency only via AmountEditBottomSheet)
  - 19-05-plan (TransactionEntryScreen/TransactionConfirmScreen deletion — depends on transaction_entry_screen.dart being removed because it currently calls the now-renamed nextLabel: parameter)

# Tech tracking
tech-stack:
  added: []  # Zero new pub.dev dependencies (D-12 binding preserved)
  patterns:
    - "LayoutBuilder + MediaQuery.size.height responsive computation with math.max(48.0, computed) clamp — first such primitive in the project"
    - "Vanilla flutter_test matchesGoldenFile 6-image matrix (locale × theme) — no alchemist or golden_toolkit"
    - "TDD RED -> GREEN cycle: failing widget test driven by API rename (actionLabel:) commit before refactor"

key-files:
  created:
    - "test/widget/features/accounting/presentation/widgets/smart_keyboard_test.dart (300 lines, 5 test bodies / 7 assertions)"
    - "test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart (golden matrix loop)"
    - "test/widget/features/accounting/presentation/widgets/goldens/smart_keyboard_ja_light.png"
    - "test/widget/features/accounting/presentation/widgets/goldens/smart_keyboard_ja_dark.png"
    - "test/widget/features/accounting/presentation/widgets/goldens/smart_keyboard_zh_light.png"
    - "test/widget/features/accounting/presentation/widgets/goldens/smart_keyboard_zh_dark.png"
    - "test/widget/features/accounting/presentation/widgets/goldens/smart_keyboard_en_light.png"
    - "test/widget/features/accounting/presentation/widgets/goldens/smart_keyboard_en_dark.png"
  modified:
    - "lib/features/accounting/presentation/widgets/smart_keyboard.dart (responsive refactor, in-place; ~88 insertions / 36 deletions)"

key-decisions:
  - "Implemented D-06 responsive height as `mq.size.height * 0.40 - mq.padding.bottom - (4 * 12.0)` divided by 5 with math.max(48.0, ...) clamp — protects iPhone SE 4.7\" (which yields ~36.96 dp without the clamp per RESEARCH §Pitfall 1)"
  - "Implemented D-07 column gap as `EdgeInsets.symmetric(horizontal: 3)` per key (P19-B3 fix) — 3 + 3 = 6 dp total visible gap between adjacent keys, matching D-07 intent; the earlier plan draft using `horizontal: 6` would have produced 12 dp total gap"
  - "Removed the `nextLabel = 'Next'` default and made `actionLabel` required — forces every callsite to supply an ARB-resolved string, closes RESEARCH §Pitfall 6"
  - "Used vanilla `AppTextStyles.labelMedium.copyWith(fontFeatures: const [FontFeature.tabularFigures()], ...)` on _DigitKey text style — kept FontFeature import from package:flutter/material.dart (no dart:ui import needed; analyzer flagged unnecessary_import)"
  - "Used `await tester.binding.setSurfaceSize(...)` in golden test — required because the call is guarded async; initial attempt without await produced 'Guarded function conflict' on every test"

patterns-established:
  - "LayoutBuilder + math.max(48.0, computed) responsive-height clamp for any future keypad / dense-grid widgets — first such primitive in the project"
  - "Per-key Padding wrapper `EdgeInsets.symmetric(horizontal: 3)` produces 6 dp total visible gap — pattern for any future row-of-flex-keys where total gap is the design spec"
  - "Required ARB-resolved label parameters with NO default (`required String actionLabel`) — closes the 'Next' / hardcoded string leak class for any future button widget that exposes a label"
  - "Vanilla matchesGoldenFile + double for-loop matrix (locale × themeMode) — pattern for any future widget that needs i18n + theme-mode regression baselines"

requirements-completed: [KEYPAD-01]

# Metrics
duration: 15min
completed: 2026-05-23
---

# Phase 19 Plan 02: SmartKeyboard Polish Summary

**Responsive 48 dp-floor SmartKeyboard with `math.max(48.0, computed)` clamp, renamed `actionLabel:` API (no 'Next' leak), 6 dp total column gap (3 dp per side via P19-B3 fix), uniform action-row height, tabular-figure digit glyphs, and a 6-image golden regression matrix (ja/zh/en × light/dark).**

## Performance

- **Duration:** 15 min
- **Started:** 2026-05-23T02:52:41Z
- **Completed:** 2026-05-23T03:08:12Z
- **Tasks:** 3 (1 TDD refactor, 1 golden-test scaffold, 1 human-verify checkpoint)
- **Files modified:** 1 production source (smart_keyboard.dart)
- **Files created:** 2 test files + 6 golden PNGs

## Accomplishments

- **48 dp floor enforced on all 3 target device surfaces** — widget test asserts every InkWell key has `height >= 48 dp` on iPhone SE (375×667), iPhone 14 (390×844), and Pro Max (428×926). Without `math.max(48.0, ...)` the SE case fails at ~36.96 dp (RESEARCH §Pitfall 1).
- **`nextLabel` -> `actionLabel` rename complete** — no default value, required parameter; Plan 01's `AmountEditBottomSheet` (which already uses `actionLabel: S.of(context).record`) compiles clean against this rename. RESEARCH §Pitfall 6 'Next' leak closed.
- **6 dp TOTAL visible column gap (P19-B3 fix)** — measured via rendered position assertion: `pos2.dx - (pos1.dx + box1.size.width)` closeTo 6.0 with ±0.5 dp tolerance. Each key Padding uses `EdgeInsets.symmetric(horizontal: 3)`; 3 + 3 = 6 dp matches D-07's "6 dp column gap" intent.
- **12 dp inter-row gap** — 4 × `SizedBox(height: 12)` between the 5 rows, replacing the previous 4 × `SizedBox(height: 8)`.
- **Action-row uniform height (D-08)** — backspace, ¥JPY currency, and Save (gradient) all use the same responsive `keyHeight` derived from `MediaQuery`. Test asserts `(backspaceHeight - currencyHeight).abs() <= 0.5` AND `(saveHeight - currencyHeight).abs() <= 0.5`.
- **Tabular-figure digit glyphs** — `_DigitKey` text style now uses `AppTextStyles.labelMedium.copyWith(fontFeatures: const [FontFeature.tabularFigures()], ...)`. Test verifies the style's `fontFeatures` includes a feature with `feature == 'tnum'`.
- **6 golden baselines committed and human-approved** — `test/widget/features/accounting/presentation/widgets/goldens/smart_keyboard_{ja,zh,en}_{light,dark}.png` are now the SC-3 regression baseline. Test passes against committed baselines without `--update-goldens`.

## Task Commits

Each task was committed atomically (TDD = 2 commits for Task 1):

1. **Task 1a (RED): Failing widget tests for SmartKeyboard** — `c5e77f7` (test)
   - 5 test bodies / 7 assertions in `smart_keyboard_test.dart`
   - Fails at compile time: no `actionLabel:` parameter exists yet on SmartKeyboard
2. **Task 1b (GREEN): SmartKeyboard responsive height refactor** — `3d3604c` (feat)
   - Adds `dart:math as math` import, renames `nextLabel` to required `actionLabel`, adds `math.max(48.0, ...)` clamp, changes 4 SizedBox(height:8) to 12, changes 7 EdgeInsets.symmetric(horizontal:4) to horizontal:3, removes hardcoded `height: 50` and `height: 48`, adds `FontFeature.tabularFigures()` to digit glyph
   - Also fixes test file: removed unnecessary `dart:ui` import (FontFeature is re-exported by flutter/material.dart)
3. **Task 2: Golden test file + 6 baseline PNGs** — `191a605` (feat)
   - Vanilla `matchesGoldenFile` + double for-loop over `{ja,zh,en} × {light,dark}`
   - 6 PNGs generated via `flutter test --update-goldens` and committed to `goldens/`
4. **Task 3: Human-verify checkpoint** — no commit (approval recorded in this summary)
   - User approved all 6 baselines visually
5. **Plan metadata (this summary)** — pending

_Note: The 6 baseline PNGs were committed in Task 2 (not in Task 3) per the plan's Task 2 acceptance criteria ("Six baseline PNGs are committed"). Task 3's human-verify checkpoint only required visual approval, not a separate commit._

## Files Created/Modified

- `lib/features/accounting/presentation/widgets/smart_keyboard.dart` — **MODIFIED.** Responsive height via `LayoutBuilder`-equivalent (direct `MediaQuery.of(context)` since the widget is the root of its layout slot); per-key `keyHeight` flowed into `_DigitKey`/`_ActionKey`/`_CurrencyKey`/`_GradientKey` via constructor param. ~88 insertions / 36 deletions.
- `test/widget/features/accounting/presentation/widgets/smart_keyboard_test.dart` — **NEW.** 300 lines, 5 test bodies (TEST 1 parameterized over 3 device sizes = 7 assertions total).
- `test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart` — **NEW.** Vanilla `matchesGoldenFile` golden test scaffold with double-loop matrix.
- `test/widget/features/accounting/presentation/widgets/goldens/smart_keyboard_{ja,zh,en}_{light,dark}.png` — **NEW.** 6 baseline PNGs (~8 KB each).

## Decisions Made

- **Removed the `nextLabel` default and made `actionLabel` required** — the plan offered "default REMOVED or changed to 'Save'", I chose REMOVED. Reasoning: any caller forgetting to pass a label produces a compile error (`The named parameter 'actionLabel' is required, but there's no corresponding argument`), which is the strongest possible enforcement of "no 'Next' leak". Plan 01's `AmountEditBottomSheet` and Plan 03's `ManualOneStepScreen` both supply ARB-resolved strings, so no default is needed in production.
- **Used `MediaQuery.of(context)` directly in `build()` rather than wrapping the existing Container in a `LayoutBuilder`** — the plan suggested LayoutBuilder, but the SmartKeyboard's `Container` is already the root widget being laid out in the slot the host gives it, and the height computation only needs MediaQuery (not the constraints from LayoutBuilder). This produces simpler code without compromising the responsive behavior. LayoutBuilder would have been needed only if `keyHeight` depended on `constraints.maxWidth`, which it does not.
- **Removed `dart:ui` import after analyzer flag** — `FontFeature` is re-exported by `package:flutter/material.dart`, so the explicit `dart:ui` import is `unnecessary_import`. Removed in commit 3d3604c.
- **Used `await tester.binding.setSurfaceSize(...)` in golden test** — initial implementation called the method without `await`, which produced "Guarded function conflict. You must use 'await' with all Future-returning test APIs" on every test. Adding `await` to both the set call and the teardown's reset call resolved it.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed unnecessary `dart:ui` import flagged by analyzer**
- **Found during:** Task 1 GREEN (after the refactor was written)
- **Issue:** `import 'dart:ui' show FontFeature;` triggers `unnecessary_import` because `FontFeature` is re-exported by `package:flutter/material.dart`
- **Fix:** Removed the `dart:ui` import line from both `smart_keyboard.dart` and `smart_keyboard_test.dart`
- **Files modified:** lib/features/accounting/presentation/widgets/smart_keyboard.dart, test/widget/features/accounting/presentation/widgets/smart_keyboard_test.dart
- **Verification:** `flutter analyze lib/.../smart_keyboard.dart` reports "No issues found"; tests still pass
- **Committed in:** 3d3604c (folded into Task 1 GREEN commit since the import was added in that same commit)
- **Note:** The plan's `<action>` explicitly says "ADD `import 'dart:ui' show FontFeature;`" — but the project analyzer (and CLAUDE.md "Zero analyzer warnings before commit" rule) takes precedence. CLAUDE.md takes precedence over plan instructions; this deviation aligns with the project rule.
- **Acceptance impact:** The plan's acceptance criterion `grep -F "import 'dart:ui' show FontFeature;" smart_keyboard.dart matches one line` now returns 0 instead of 1. This is intentionally diverged in favor of analyzer cleanliness.

**2. [Rule 3 - Blocking] Added `await` to `tester.binding.setSurfaceSize(...)` in golden test**
- **Found during:** Task 2 first run of `flutter test --update-goldens`
- **Issue:** Without `await`, `setSurfaceSize` is a guarded function and conflicts with the subsequent `pumpWidget` call ("Guarded function conflict. You must use 'await' with all Future-returning test APIs")
- **Fix:** Added `await` to the `setSurfaceSize` call and made the `addTearDown` callback async
- **Files modified:** test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart
- **Verification:** All 6 golden tests pass with and without `--update-goldens`
- **Committed in:** 191a605 (folded into Task 2 commit since this is the first commit that contains the file)

---

**Total deviations:** 2 auto-fixed (1 analyzer/style, 1 blocking)
**Impact on plan:** Both fixes essential for project rules (analyzer cleanliness) and Flutter test correctness (await semantics). No scope creep, no architectural changes.

## Issues Encountered

- **CWD drift between worktree and main repo on first Write call** — initial Write of `smart_keyboard_test.dart` landed in the main repo path (`/Users/xinz/Development/home-pocket-app/test/...`) instead of the worktree path (`/Users/xinz/Development/home-pocket-app/.claude/worktrees/agent-a5581061452ec9374/test/...`). Detected via `flutter test`'s "Does not exist" loading error. Resolved by re-writing the file to the worktree path. No commit was affected (the misplaced file was overwritten in the main repo by the worktree Write).
- **Golden image text rendering** — the `'Record'` label and digit glyphs appear as small placeholder boxes in the golden PNGs because the custom 'Outfit' font does not load in the headless test environment. This is expected behavior per RESEARCH §Pitfall 7 ("CI font baseline mismatch — acceptable rhythm: run on Mac, commit, observe CI"). Structural layout (key separation, gradient on Save, light/dark contrast, action row uniformity) IS visible and correct in the images. User approved on visual review.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- **Plan 03 (ManualOneStepScreen, wave 2):** consumes the new `actionLabel:` parameter and the responsive height. Both Plan 01's `AmountEditBottomSheet` and Plan 03's `ManualOneStepScreen` will pass `actionLabel: S.of(context).record`.
- **Plan 04 (host adoption, wave 3):** does NOT touch `SmartKeyboard` directly. Indirect dependency only via `AmountEditBottomSheet` which Plan 01 already wired to the new API.
- **P19-B1 follow-up:** `transaction_entry_screen.dart:338` still calls `nextLabel: l10n.next` — this file is broken between this wave's commit and Plan 03's wave-2 deletion commit. This is the accepted intra-wave window documented in the plan's `<interfaces>` block (P19-B1 fix). `flutter analyze` on the global tree will report errors against this file until Plan 03 lands; analyzer was only run scoped to `smart_keyboard.dart` for that reason.
- **D-12 binding preserved:** `git diff pubspec.yaml pubspec.lock` is empty. Zero new pub dependencies.

## Self-Check: PASSED

**Files verified to exist:**
- `lib/features/accounting/presentation/widgets/smart_keyboard.dart` — FOUND
- `test/widget/features/accounting/presentation/widgets/smart_keyboard_test.dart` — FOUND
- `test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart` — FOUND
- `test/widget/features/accounting/presentation/widgets/goldens/smart_keyboard_ja_light.png` — FOUND
- `test/widget/features/accounting/presentation/widgets/goldens/smart_keyboard_ja_dark.png` — FOUND
- `test/widget/features/accounting/presentation/widgets/goldens/smart_keyboard_zh_light.png` — FOUND
- `test/widget/features/accounting/presentation/widgets/goldens/smart_keyboard_zh_dark.png` — FOUND
- `test/widget/features/accounting/presentation/widgets/goldens/smart_keyboard_en_light.png` — FOUND
- `test/widget/features/accounting/presentation/widgets/goldens/smart_keyboard_en_dark.png` — FOUND

**Commits verified to exist:**
- `c5e77f7` — FOUND (test: failing widget test)
- `3d3604c` — FOUND (feat: refactor)
- `191a605` — FOUND (feat: golden test + baselines)

**Tests passing:**
- `flutter test test/widget/features/accounting/presentation/widgets/smart_keyboard_test.dart` — 7/7 passed
- `flutter test test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart` — 6/6 passed against committed baselines (no `--update-goldens`)

**Acceptance criteria gates:**
- `grep -c 'nextLabel' smart_keyboard.dart` = 1 (comment-only — explains the rename; constructor + field references all use actionLabel)
- `grep -c 'actionLabel' smart_keyboard.dart` = 3 (constructor param, field declaration, usage in _GradientKey wiring)
- `grep -c "import 'dart:math' as math;" smart_keyboard.dart` = 1
- `grep -c 'math.max(48.0' smart_keyboard.dart` = 1
- `grep -cE '(const )?SizedBox\(height: 12\)' smart_keyboard.dart` = 4 (all 4 inter-row gaps)
- `grep -cE 'EdgeInsets\.symmetric\(horizontal: 3\)' smart_keyboard.dart` = 7 (every key Padding wrapper)
- `grep -cE 'EdgeInsets\.symmetric\(horizontal: 4\)' smart_keyboard.dart` = 0 (old padding fully replaced)
- `grep -cE 'EdgeInsets\.symmetric\(horizontal: 6\)' smart_keyboard.dart` = 0 (the rejected earlier-draft padding never landed)
- `grep -cE 'height: 50' smart_keyboard.dart` = 0 (D-08 — no special-cased action-row height)
- `grep -cE 'Container\(\s*height: 48' smart_keyboard.dart` = 0 (hardcoded 48 dp digit-key literal removed)
- `grep -c 'FontFeature.tabularFigures()' smart_keyboard.dart` = 1
- `flutter analyze lib/features/accounting/presentation/widgets/smart_keyboard.dart` — 0 issues
- `git diff pubspec.yaml pubspec.lock` — empty (D-12 preserved)

---
*Phase: 19-manual-one-step-keypad-polish*
*Plan: 02*
*Completed: 2026-05-23*
