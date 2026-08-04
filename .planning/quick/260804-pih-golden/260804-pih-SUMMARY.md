---
phase: quick-260804-pih-golden
plan: 01
subsystem: ui
tags: [flutter, home, widget-test, golden-test, dark-mode]

requires:
  - phase: quick-260804-tch
    provides: Home hero card surface and tear-notch visual correction
  - phase: quick-260804-tln
    provides: Tear-notch opening border mask
provides:
  - Continuous parent-painted HomeHeroCard surface for the no-Joy state
  - Widget regression coverage for sole-surface and single-shadow ownership
  - Updated light and dark no-Joy golden baselines
affects: [home, home-hero-card, golden-tests]

tech-stack:
  added: []
  patterns:
    - Parent card owns the shared surface while embedded empty-state content remains transparent

key-files:
  created: []
  modified:
    - lib/features/home/presentation/widgets/home_joy_empty_state.dart
    - test/widget/features/home/presentation/widgets/home_hero_card_test.dart
    - test/golden/goldens/home_hero_card_no_joy_c2_light_ja.png
    - test/golden/goldens/home_hero_card_no_joy_c2_dark_ja.png

key-decisions:
  - "Keep HomeHeroCard as the sole painted card surface; remove only the outer HomeJoyEmptyState decoration."
  - "Preserve HomeHeroCard decoration, tear-notch geometry, prompt styling, layout, copy, and callbacks unchanged."

patterns-established:
  - "Integrated surface ownership: a nested region that visually belongs to a card does not repaint the card background."

requirements-completed: [QUICK-PIH-01]

coverage:
  - id: D1
    description: "The no-Joy empty-state wrapper is transparent while its parent retains exactly one outer shadow."
    requirement: QUICK-PIH-01
    verification:
      - kind: automated_ui
        ref: "test/widget/features/home/presentation/widgets/home_hero_card_test.dart#parent is the sole card surface and retains one outer shadow"
        status: pass
    human_judgment: false
  - id: D2
    description: "Light and dark no-Joy cards render as continuous surfaces with their existing geometry and controls intact."
    requirement: QUICK-PIH-01
    verification:
      - kind: automated_ui
        ref: "test/golden/home_hero_card_golden_test.dart#no Joy C2"
        status: pass
      - kind: manual_procedural
        ref: "Visual inspection of both regenerated 350x420 PNG baselines"
        status: pass
    human_judgment: false

duration: 3min
completed: 2026-08-04
status: complete
---

# Quick Task 260804-pih: Integrated No-Joy Hero Surface Summary

**A transparent no-Joy empty-state wrapper now lets one HomeHeroCard decoration paint the entire light and dark card without a horizontal color seam.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-08-04T09:28:34Z
- **Completed:** 2026-08-04T09:31:32Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Removed the independently mixed empty-state background while preserving all nested prompt-card styling and behavior.
- Added a TDD regression assertion proving the parent owns one shadow and the child owns no surface paint.
- Regenerated and visually inspected exactly the light and dark no-Joy golden baselines.

## Task Commits

1. **Task 1 RED: Lock sole-surface behavior** - `92db23e3` (test)
2. **Task 1 GREEN: Remove the empty wrapper fill** - `d27c2395` (fix)
3. **Task 2: Re-baseline both no-Joy themes** - `c6c3fad1` (test)

## Files Created/Modified

- `lib/features/home/presentation/widgets/home_joy_empty_state.dart` - Removed only the outer wrapper decoration so the parent surface shows through.
- `test/widget/features/home/presentation/widgets/home_hero_card_test.dart` - Locks sole-surface ownership and the parent's single outer shadow.
- `test/golden/goldens/home_hero_card_no_joy_c2_light_ja.png` - Updated light-theme integrated-surface baseline.
- `test/golden/goldens/home_hero_card_no_joy_c2_dark_ja.png` - Updated dark-theme integrated-surface baseline.

## Verification

- RED gate: the new focused test failed before production changes because the child owned a `BoxDecoration`.
- `flutter test test/widget/features/home/presentation/widgets/home_hero_card_test.dart` — 41 passed.
- `flutter test test/golden/home_hero_card_golden_test.dart --plain-name 'no Joy C2'` — 2 passed.
- `flutter analyze lib/features/home/presentation/widgets` — no issues.
- `flutter analyze` — no issues.
- Visual inspection — both 350x420 baselines have continuous upper/lower surfaces; outer shadow, border/radius, tear notches, prompt cards, spacing, and dimensions remain intact.
- Diff scope — exactly four implementation/test artifacts changed; `home_hero_card.dart` and filled-state goldens are unchanged.

## Decisions Made

- The parent remains the only card-level painted surface; the child keeps its constraints, padding, content, and prompt-specific decorations.
- No divider, internal border, new abstraction, localization change, or interaction change was introduced.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

Flutter initially could not write its SDK cache under the workspace sandbox. The prescribed tests were rerun with approved SDK-cache access and then completed successfully.

## Known Stubs

None. The stub-pattern scan found only an existing test assertion message containing the word “placeholder”; it does not represent a runtime stub.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The integrated no-Joy hero surface is covered structurally and visually in both themes, with no blockers.

## TDD Gate Compliance

- RED commit precedes GREEN commit: `92db23e3` → `d27c2395`.
- The focused assertion failed for the intended child-decoration reason before implementation and passed afterward.

## Self-Check: PASSED

All four changed code/test artifacts and all three task commits were found. `home_hero_card.dart` is unchanged, and the committed diff contains no files outside the plan's four-artifact scope.

---
*Quick task: 260804-pih-golden*
*Completed: 2026-08-04*
