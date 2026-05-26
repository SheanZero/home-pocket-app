---
phase: 22
plan: 03
slug: voice-one-step-integration-record-button-ux
subsystem: theme
tags: [theme, colors, foundation, wave-0]
requirements: [REC-02]
dependency-graph:
  requires: []
  provides:
    - "AppColors.recordingGradientStart"
    - "AppColors.recordingGradientEnd"
    - "AppColorsDark.recordingGradientStart"
    - "AppColorsDark.recordingGradientEnd"
  affects:
    - "lib/features/accounting/presentation/screens/voice_input_screen.dart (Wave 1 consumer)"
tech-stack:
  added: []
  patterns:
    - "Named theme color constants (additive to AppColors / AppColorsDark families)"
key-files:
  created: []
  modified:
    - "lib/core/theme/app_colors.dart"
decisions:
  - "Used planner-default hex values per CONTEXT.md D-04 (no closer existing constant found): light 0xFFE05050 / 0xFFC03030, dark 0xFFE07070 / 0xFFB04040"
  - "Added the dark-theme pair at the tail of AppColorsDark (no pre-existing action* family there to mirror) — preserves additive-only diff"
metrics:
  duration: "~5 min"
  tasks_completed: 1
  files_touched: 1
  lines_added: 8
  lines_removed: 0
  completed_date: "2026-05-25"
---

# Phase 22 Plan 03: Recording Gradient Color Constants Summary

Added 4 named color constants (`recordingGradientStart` + `recordingGradientEnd` in both `AppColors` and `AppColorsDark`) so the Wave 1 mic button's `AnimatedContainer` can reference stable theme constants instead of inline hex literals for the REC-02 recording state.

## What Was Built

- `lib/core/theme/app_colors.dart`:
  - In `AppColors` (light theme), after the `actionShadow` constant, added a `// ── Recording — Phase 22 D-04 (mic button recording state) ──` block with `recordingGradientStart = Color(0xFFE05050)` and `recordingGradientEnd = Color(0xFFC03030)`.
  - In `AppColorsDark`, after `navShadow`, added a `// ── Recording — Phase 22 D-04 (dark-theme variant) ──` block with `recordingGradientStart = Color(0xFFE07070)` and `recordingGradientEnd = Color(0xFFB04040)`.
- Diff is purely additive (+8 lines, 0 removals). No existing constants were renamed, reordered, or modified.

## Why These Values

- Per CONTEXT.md D-04, the planner has discretion when no closer existing constant matches the need. The current palette has no `error`/`warning`/red family — the closest neighbor (`accentPrimary = 0xFFE85A4F`, coral) is reserved for the idle/action gradient and would not read as distinctly red.
- Light values (`0xFFE05050` → `0xFFC03030`) form a bright-to-darker red gradient that is clearly distinguishable from the green/coral action gradient.
- Dark values (`0xFFE07070` → `0xFFB04040`) follow the existing `AppColorsDark` desaturation pattern — slightly lighter top, muted bottom — for legibility against `AppColorsDark.background = 0xFF1A1D27`.

## Verification

- `grep -c "recordingGradientStart" lib/core/theme/app_colors.dart` → 2 (one per class).
- `grep -c "recordingGradientEnd" lib/core/theme/app_colors.dart` → 2.
- `grep -E "recordingGradient(Start|End)\s*=" lib/core/theme/app_colors.dart | wc -l` → 4.
- `grep -rn "recordingGradient" lib/ --exclude-dir=core` → 0 matches (Wave 1 has not yet consumed them — expected).
- `flutter analyze lib/core/theme/app_colors.dart` → `No issues found! (ran in 0.5s)`.

## Deviations from Plan

None — plan executed exactly as written. Used the planner-default hex values (D-04 discretion path); no aliased existing constant was suitable.

## Commits

| Task | Name                                            | Commit  | Files                                  |
| ---- | ----------------------------------------------- | ------- | -------------------------------------- |
| 1    | Add recordingGradient* to AppColors / AppColorsDark | 45594d3 | lib/core/theme/app_colors.dart |

## Acceptance Criteria

- [x] `static const recordingGradientStart` declared in `AppColors` (light, `Color(0xFFE05050)`).
- [x] `static const recordingGradientEnd` declared in `AppColors` (light, `Color(0xFFC03030)`).
- [x] Both inside the `AppColors abstract final class` block.
- [x] Both typed as `Color` via `Color(0x...)` constructor.
- [x] `// ── Recording — Phase 22 D-04` comment header precedes new constants for code-search traceability.
- [x] Existing constants unchanged — diff purely additive.
- [x] `AppColorsDark` mirrored block with planner-tuned muted dark values.
- [x] `flutter analyze lib/core/theme/app_colors.dart` outputs 0 errors and 0 warnings.
- [x] No other file in `lib/` references `recordingGradient*` yet (Wave 1 will be the first consumer).

## Known Stubs

None.

## Threat Flags

None — this plan adds pure constants only (no inputs, no I/O, no state changes, no new dependencies).

## Self-Check: PASSED

- File `lib/core/theme/app_colors.dart` exists and contains both constant pairs (verified by grep).
- Commit `45594d3` exists in `git log` of `worktree-agent-a6de6219b30e24057`.
- Analyzer clean.
- No untracked or accidentally-deleted files.
