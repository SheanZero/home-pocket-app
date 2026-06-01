---
phase: 34-golden-re-baseline-verification
plan: "02"
subsystem: testing
tags: [flutter, golden-tests, dark-mode, ADR-018, teal-clarity, re-baseline]

requires:
  - phase: 34-golden-re-baseline-verification/34-01
    provides: ThemeMode-parameterized _wrap() + 27 dark golden stubs in 7 test files
  - phase: 33-color-token-system-consolidation
    provides: ThemeExtension<AppPalette> ADR-018 Teal Clarity token system + app-wide dark rollout

provides:
  - 50 failing golden masters re-baselined to ADR-018 Teal Clarity palette (coral/blue/green -> teal/gold)
  - 27 new dark golden PNG masters for the 7 light-only files from Plan 34-01
  - Full golden suite (12 test files, light + dark) exits 0 with 0 failures
  - All diffs classified as palette/D-04/D-05 (no layout regressions found)

affects:
  - 34-03 (final audit — depends on green golden suite)
  - any future plan touching golden test files or app color tokens

tech-stack:
  added: []
  patterns:
    - "Classification-before-update: run golden suite without --update-goldens first, inspect failures/ PNGs, classify each delta before updating"
    - "Per-file selective --update-goldens: never bulk-update all at once; preserves D-02 attribution discipline"
    - "D-04 halt protocol: non-palette deltas are never silently updated"

key-files:
  created:
    - test/golden/goldens/amount_display_cny_dark.png
    - test/golden/goldens/amount_display_jpy_dark.png
    - test/golden/goldens/amount_display_usd_dark.png
    - test/golden/goldens/list_calendar_header_dark_en.png
    - test/golden/goldens/list_calendar_header_dark_ja.png
    - test/golden/goldens/list_calendar_header_dark_zh.png
    - test/golden/goldens/list_category_filter_sheet_dark_en.png
    - test/golden/goldens/list_category_filter_sheet_dark_ja.png
    - test/golden/goldens/list_category_filter_sheet_dark_zh.png
    - test/golden/goldens/list_day_group_header_dark_en.png
    - test/golden/goldens/list_day_group_header_dark_ja.png
    - test/golden/goldens/list_day_group_header_dark_zh.png
    - test/golden/goldens/list_empty_state_dayEmpty_dark_en.png
    - test/golden/goldens/list_empty_state_dayEmpty_dark_ja.png
    - test/golden/goldens/list_empty_state_dayEmpty_dark_zh.png
    - test/golden/goldens/list_empty_state_filtered_dark_en.png
    - test/golden/goldens/list_empty_state_filtered_dark_ja.png
    - test/golden/goldens/list_empty_state_filtered_dark_zh.png
    - test/golden/goldens/list_empty_state_noData_dark_en.png
    - test/golden/goldens/list_empty_state_noData_dark_ja.png
    - test/golden/goldens/list_empty_state_noData_dark_zh.png
    - test/golden/goldens/list_sort_filter_bar_dark_en.png
    - test/golden/goldens/list_sort_filter_bar_dark_ja.png
    - test/golden/goldens/list_sort_filter_bar_dark_zh.png
    - test/golden/goldens/list_transaction_tile_dark_en.png
    - test/golden/goldens/list_transaction_tile_dark_ja.png
    - test/golden/goldens/list_transaction_tile_dark_zh.png
  modified:
    - test/golden/goldens/amount_display_cny.png (re-baselined to teal)
    - test/golden/goldens/amount_display_jpy.png (re-baselined to teal)
    - test/golden/goldens/amount_display_usd.png (re-baselined to teal)
    - test/golden/goldens/daily_vs_joy_card_dark_ja.png (re-baselined)
    - test/golden/goldens/daily_vs_joy_card_group_dark_ja.png (re-baselined)
    - test/golden/goldens/daily_vs_joy_card_group_light_ja.png (re-baselined)
    - test/golden/goldens/daily_vs_joy_card_light_ja.png (re-baselined)
    - test/golden/goldens/home_hero_card_*.png (8 files re-baselined)
    - test/golden/goldens/list_calendar_header_{en,ja,zh}.png (re-baselined)
    - test/golden/goldens/list_category_filter_sheet_{en,ja,zh}.png (re-baselined)
    - test/golden/goldens/list_day_group_header_{en,ja,zh}.png (re-baselined)
    - test/golden/goldens/list_empty_state_*_{en,ja,zh}.png (9 files re-baselined)
    - test/golden/goldens/list_sort_filter_bar_{en,ja,zh}.png (re-baselined)
    - test/golden/goldens/list_transaction_tile_{en,ja,zh}.png (re-baselined)
    - test/golden/goldens/per_category_breakdown_card_*.png (3 files re-baselined)
    - test/widget/features/accounting/presentation/screens/goldens/voice_input_screen_mic_button_idle.png (re-baselined)
    - test/widget/features/accounting/presentation/widgets/goldens/smart_keyboard_*.png (6 files re-baselined)

key-decisions:
  - "All 50 diff PNGs classified as ADR-018 palette / D-04 decorative / D-05 hero gradient deltas (none classified as regression) — per D-02/D-04 protocol"
  - "D-04 halt protocol not triggered — zero suspected regressions across all 50 failing goldens"
  - "27 new dark masters generated via first-run --update-goldens on 7 files (not a diff path — PNG did not exist)"
  - "per_category_breakdown_card_dark_ja had high diff % (82%) due to ADR-018 palette being pervasive in that widget — classified as intended"

requirements-completed:
  - COLOR-04

duration: 6min
completed: 2026-06-01
---

# Phase 34 Plan 02: Golden Re-baseline Summary

**50 failing golden masters re-baselined to ADR-018 Teal Clarity palette + 27 new dark PNG masters created; full golden suite (70 tests across 12 files) exits 0 with 0 failures**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-06-01T13:34:55Z
- **Completed:** 2026-06-01T13:41:00Z
- **Tasks:** 2
- **Files modified:** 77 PNG files (50 updated + 27 new)

## Accomplishments

- Classification run confirmed all 50 failing goldens are ADR-018 palette deltas (no layout regressions, no missing elements, no wrong dark colors)
- All 50 failing golden masters updated via per-file selective `--update-goldens` (amount_display x3, daily_vs_joy_card x4, home_hero_card x8, list_calendar_header x3, list_category_filter_sheet x3, list_day_group_header x3, list_empty_state x9, list_sort_filter_bar x3, list_transaction_tile x3, per_category_breakdown_card x3, smart_keyboard x6, voice_input x1)
- 27 new dark golden PNG masters generated for 7 newly-dark files (first-run creation, not diff path)
- D-04 halt protocol: not triggered — zero deltas classified as suspected regressions

## Task Commits

1. **Task 1+2: Classification run + selective re-baseline + 27 new dark masters** - `616046ce` (chore)

## Files Created/Modified

**New dark masters (27 new files):**
- `test/golden/goldens/amount_display_{cny,jpy,usd}_dark.png` (3)
- `test/golden/goldens/list_calendar_header_dark_{en,ja,zh}.png` (3)
- `test/golden/goldens/list_category_filter_sheet_dark_{en,ja,zh}.png` (3)
- `test/golden/goldens/list_day_group_header_dark_{en,ja,zh}.png` (3)
- `test/golden/goldens/list_empty_state_{noData,dayEmpty,filtered}_dark_{en,ja,zh}.png` (9)
- `test/golden/goldens/list_sort_filter_bar_dark_{en,ja,zh}.png` (3)
- `test/golden/goldens/list_transaction_tile_dark_{en,ja,zh}.png` (3)

**Re-baselined masters (50 files updated):**
- All 12 golden test file master PNGs updated to ADR-018 Teal Clarity palette

## Decisions Made

- All 50 diff PNGs reviewed and classified as ADR-018 palette changes:
  - `amount_display_*`: old daily-blue `#5A9CC8` pill → new teal; layout unchanged
  - `daily_vs_joy_card_*`: joy panel green → gold `#F0A81E`, daily panel blue → teal `#0E9AA7` (D-05 hero gradient for card panels)
  - `home_hero_card_*`: coral outer ring → teal, green inner gradient → teal/gold (D-05 hero gradient), joy ledger bar green → gold
  - `list_*` widgets: old coral/blue active states → teal/gold; layout, dimensions, text all identical
  - `per_category_breakdown_card_dark_ja`: 82% diff due to pervasive palette change in dark card backgrounds — classified as intended (all element positions intact)
  - `smart_keyboard_*`: old coral "OK" button → teal; layout unchanged
  - `voice_input_screen_*`: old coral mic + buttons → teal; layout unchanged
- D-04 halt protocol not triggered: zero suspected regressions across all 50 goldens

## Deviations from Plan

None — plan executed exactly as written. Classification run populated failures/ with diff PNGs, all 50 classified as palette/D-04/D-05, all updated per-file without --update-goldens blanket. 27 new dark PNG masters created. Full suite 0 failures.

## Known Stubs

None — all golden PNGs now have valid masters. The 27 new dark goldens are fully rendered and passing.

## Threat Flags

None — this plan only updated golden PNG files (test artifacts). No production code, network, auth, or persistence changes.

## Issues Encountered

None.

## Next Phase Readiness

- Plan 34-02 complete: golden suite is fully green with ADR-018 Teal Clarity palette
- All 12 golden test files now cover both light and dark modes (28 dark golden masters total)
- Ready for Plan 34-03: comprehensive audit sweep (D-03a old-palette hex grep, ARB vocabulary audit, flutter analyze, coverage gate)

---

## Self-Check: PASSED

- `test/golden/goldens/list_day_group_header_dark_en.png`: FOUND
- `test/golden/goldens/list_transaction_tile_dark_en.png`: FOUND
- `test/golden/goldens/amount_display_jpy_dark.png`: FOUND
- Commit `616046ce`: FOUND
- `flutter test test/golden/` exits 0: VERIFIED
- `ls test/golden/goldens/ | grep '_dark_' | wc -l` = 28 (≥27): VERIFIED

---
*Phase: 34-golden-re-baseline-verification*
*Completed: 2026-06-01*
