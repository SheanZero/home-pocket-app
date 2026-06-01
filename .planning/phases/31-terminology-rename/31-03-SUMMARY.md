---
phase: 31-terminology-rename
plan: "03"
subsystem: i18n/l10n
tags: [arb, flutter-gen-l10n, terminology-rename, i18n, zh, ja, en]

requires:
  - 31-02 (LedgerType enum renamed daily/joy — S getter call sites can now use new enum)

provides:
  - "All 25 ledger-vocab ARB key roots renamed survival→daily / soul→joy / soulSatisfaction→joyFullness"
  - "All user-facing zh/ja/en values rewritten to canonical 日常/悦己/ときめき/Daily/Joy vocabulary"
  - "@description metadata rewritten so naive ROADMAP grep #3 is zero-hit (D-18)"
  - "S localizations regenerated cleanly; all call sites updated (compiler-verified)"

affects:
  - 31-04 (color rename plans build on renamed S getters)
  - 31-05 (class rename plans — no ARB changes needed there)

tech-stack:
  added: []
  patterns:
    - "Perl mass-rename for 25 ARB key roots + sed for @metadata blocks (Perl interpolates @ as arrays)"
    - "sed targeted exact-match value rewrite per locale (zh/ja/en separate passes)"
    - "Golden re-baseline: copy failures/testImage.png over goldens/*.png"

key-files:
  created: []
  modified:
    - lib/l10n/app_zh.arb
    - lib/l10n/app_ja.arb
    - lib/l10n/app_en.arb
    - lib/generated/app_localizations.dart
    - lib/generated/app_localizations_en.dart
    - lib/generated/app_localizations_ja.dart
    - lib/generated/app_localizations_zh.dart
    - lib/features/accounting/presentation/widgets/transaction_details_form.dart
    - lib/features/analytics/presentation/widgets/per_category_breakdown_card.dart
    - lib/features/analytics/presentation/widgets/soul_vs_survival_card.dart
    - lib/features/home/presentation/widgets/home_hero_card.dart
    - lib/features/list/presentation/screens/list_screen.dart
    - lib/features/list/presentation/widgets/list_sort_filter_bar.dart
    - test/widget/features/analytics/presentation/widgets/joy_headline_kpi_tile_test.dart
    - test/widget/features/analytics/presentation/widgets/soul_vs_survival_card_test.dart
    - test/widget/features/list/list_sort_filter_bar_test.dart
    - test/golden/goldens/list_sort_filter_bar_en.png
    - test/golden/goldens/list_sort_filter_bar_ja.png
    - test/widget/features/accounting/presentation/screens/goldens/voice_input_screen_mic_button_idle.png

decisions:
  - "Use sed (not Perl) for @-key renames because Perl interpolates @symbol as array in double-quoted regex"
  - "D-17 normalization applied: ja 暮らし→日常 (homeDailyExpense), 生活→日常 (analyticsLedgerColumnDaily); en Living Expenses→Daily Expenses"
  - "Re-baseline 3 golden images (list_sort_filter_bar en/ja, voice_input_screen_mic_button_idle) — text chip labels changed from Survival/Soul/生存/魂 to Daily/Joy/日常/ときめき"
  - "homeBestJoyEmptyBig zh 記録第一笔魂账→记录第一笔悦己账 included (RESEARCH line 271 value rewrite)"

metrics:
  duration: ~19min
  started: "2026-06-01T01:46:33Z"
  completed: "2026-06-01T02:05:00Z"
  tasks: 3
  files_changed: 19
---

# Phase 31 Plan 03: ARB Terminology Rename Summary

**All 25 ledger-vocab ARB key roots renamed survival→daily / soul→joy across 3 locales; stale zh/ja/en values rewritten to canonical 日常/悦己/ときめき/Daily/Joy vocabulary; @description metadata D-18 updated; S localizations regenerated with 0 analyzer errors; 2244/2244 tests pass.**

## Performance

- **Duration:** ~19 min
- **Started:** 2026-06-01T01:46:33Z
- **Completed:** 2026-06-01T02:05:00Z
- **Tasks:** 3
- **Files changed:** 19

## Accomplishments

### Task 1 — Rename 25 ARB key roots + @metadata blocks + S call sites

- Renamed 25 key roots (D-07/D-08) across `app_zh.arb`, `app_ja.arb`, `app_en.arb`:
  - survivalLedger→dailyLedger, soulLedger→joyLedger, survival→daily, soul→joy
  - homeSurvival*→homeDaily*, homeSoul*→homeJoy*
  - survivalExpense→dailyExpense, soulExpense→joyExpense, soulSatisfaction→joyFullness (D-08)
  - analyticsSurvivalVsSoul→analyticsDailyVsJoy, analyticsCardTitlePerCategorySoul*→*Joy*
  - analyticsLedgerColumnSoul/Survival→Joy/Daily
  - listLedgerSurvival/Soul→Daily/Joy
- Renamed matching @metadata blocks using sed (Perl interpolates `@symbol` as arrays)
- Ran `flutter gen-l10n` → regenerated 4 `lib/generated/app_localizations*.dart` files
- Updated 15 S.xxx call sites across 6 Dart files (compiler-verified: flutter analyze 0 errors)
- D-09 boundary respected: key count per file unchanged at 587

### Task 2 — Rewrite stale value strings + @description metadata (D-17/D-18)

- **zh** (19 value rewrites): 生存→日常 (daily/dailyExpense/analyticsDailyVsJoy/etc.),
  灵魂/魂→悦己 (joy/joyExpense/homeJoyChargeStatus/analyticsKpiJoyIndexEmptyCaption/etc.)
- **ja** (14 value rewrites): 生存→日常, 魂→ときめき; D-17 normalizations:
  - 暮らし→日常 for `homeDailyExpense` (was "暮らしの支出" → "日常の支出")
  - 生活→日常 for `analyticsLedgerColumnDaily` (was "生活" → "日常")
- **en** (13 value rewrites): Survival→Daily, Soul→Joy; D-17:
  - Living Expenses→Daily Expenses for `homeDailyExpense`
- **@description metadata** rewritten in all 3 files (D-18): "Survival ledger label"→"Daily ledger label", "Soul ledger label"→"Joy ledger label", etc. across 26 description blocks
- Naive ROADMAP grep #3 (`grep -rn '生存\|灵魂\|魂\|ソウル\|Survival\|Soul' lib/l10n/*.arb`) → **0 hits**
- Updated 3 tests asserting stale value strings:
  - `joy_headline_kpi_tile_test.dart`: "魂の記録…" → "ときめきの記録…"
  - `soul_vs_survival_card_test.dart`: "生活" → "日常"
  - `list_sort_filter_bar_test.dart`: find.text('生存') → find.text('日常')
- Re-baselined 3 golden images affected by text chip label changes

### Task 3 — Build-green gate

- `flutter gen-l10n` + `git diff --exit-code lib/generated` → clean (AUDIT-10)
- `flutter pub run build_runner build --delete-conflicting-outputs` → clean (no ARB changes affect .g.dart/.freezed.dart)
- `flutter analyze` → 0 errors (4 pre-existing info-level items in build/ and deprecated API)
- `dart run custom_lint --no-fatal-infos` → 0 issues
- `flutter test` → 2244/2244 pass

## Task Commits

1. **Task 1: Rename 25 ARB ledger-vocab key roots + S call sites** — `3ae577d1` (feat)
2. **Task 2: Rewrite stale values + @description + test/golden fixes** — `7d139453` (feat)
3. **Task 3: Build-green gate** — no new commit (gate only, no file changes)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Perl interpolates `@symbol` as array in @-key renames**
- **Found during:** Task 1
- **Issue:** Perl substitution `s/"@survivalLedger"([\s]*:)/` silently produced no output because `@survivalLedger` inside a double-quoted Perl regex is interpolated as an empty array, making the pattern never match.
- **Fix:** Used `sed -i ''` with exact string matching instead of Perl for the @-metadata key renames. The main key renames (without `@` prefix) used Perl correctly; only the @-block renames required sed.
- **Files modified:** `lib/l10n/app_zh.arb`, `lib/l10n/app_ja.arb`, `lib/l10n/app_en.arb`
- **Commit:** `3ae577d1`

**2. [Rule 1 - Bug] 3 widget tests asserted stale ARB value strings**
- **Found during:** Task 2 (test run after value rewrites)
- **Tests affected:**
  - `joy_headline_kpi_tile_test.dart:58` — asserted "魂の記録に満足度をつけると…" (old ja value for `analyticsKpiJoyIndexEmptyCaption`)
  - `soul_vs_survival_card_test.dart:82` — asserted "生活" (old ja value for `analyticsLedgerColumnDaily`)
  - `list_sort_filter_bar_test.dart:75` — tapped chip labeled "生存" (old ja value for `listLedgerDaily`)
- **Fix:** Updated all 3 test assertions to the new canonical values (ときめきの記録…, 日常, 日常)
- **Commit:** `7d139453`

**3. [Rule 1 - Bug] 3 golden images had pixel differences from text chip label changes**
- **Found during:** Task 2 (test run after value rewrites)
- **Goldens affected:**
  - `test/golden/goldens/list_sort_filter_bar_en.png` — chips changed from "Survival"/"Soul" to "Daily"/"Joy"
  - `test/golden/goldens/list_sort_filter_bar_ja.png` — chips changed from "生存"/"魂" to "日常"/"ときめき"
  - `test/widget/.../goldens/voice_input_screen_mic_button_idle.png` — LedgerTypeSelector in form shows "日常支出"/"ときめき支出" instead of "生存支出"/"魂支出" (ja locale)
- **Fix:** Copied failures/testImage.png to goldens/*.png for each golden. These pixel changes are expected (text content changed) and correct.
- **Commit:** `7d139453`

---

**Total deviations:** 3 auto-fixed (all Rule 1 bugs)
**Impact on plan:** Minimal — Perl @-interpolation gotcha required switching to sed for @-block renames; test/golden fixes are standard value-change maintenance.

## Known Stubs

None — all ARB keys and values are fully wired to real localization infrastructure.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes introduced. Pure localization key/value rename.

## Self-Check

Files modified (key checks):
- `lib/l10n/app_zh.arb` — `grep -c '"joyLedger"'` ≥ 1 ✓; `grep -c '日常'` = 7 ✓; `grep -c '悦己'` = 33 ✓
- `lib/l10n/app_ja.arb` — `grep -c '"joyLedger"'` ≥ 1 ✓; `grep -c '日常'` = 6 ✓; `grep -c 'ときめき'` = 26 ✓
- `lib/l10n/app_en.arb` — `grep -c '"joyLedger"'` ≥ 1 ✓; `grep -c 'Daily'` = 18 ✓; `grep -c 'Joy'` = 156 ✓
- `lib/l10n/*.arb` — TERMID-01 grep → 0 ✓; TERM-04 naive grep → 0 ✓
- Key count per file: 587 (unchanged) ✓

Commits:
- `3ae577d1` — Task 1: key renames + S call sites ✓
- `7d139453` — Task 2: value rewrites + @description + test/golden fixes ✓

Acceptance criteria:
- No soul/survival ARB key names: `grep -rnE '"[^"]*(soul|survival|Soul|Survival)[^"]*" *:' lib/l10n/*.arb` → 0 ✓
- New keys present all 3 files: `grep -c '"joyLedger"'` ≥ 1 per file ✓
- No stale getter call sites: `flutter analyze` → 0 errors ✓
- Generated localizations regenerated: `git diff --exit-code lib/generated` clean ✓
- D-09 boundary respected: key count unchanged at 587 ✓
- Naive ROADMAP grep #3 zero-hit: ✓
- zh canonical 日常/悦己 present ✓
- ja canonical 日常/ときめき present; no 生活/暮らし in ledger labels ✓
- en canonical Daily/Joy present; no "Living Expenses" ✓
- `flutter gen-l10n` exits 0 ✓
- `dart run custom_lint --no-fatal-infos` → 0 issues ✓
- `flutter test` → 2244/2244 pass ✓

## Self-Check: PASSED
