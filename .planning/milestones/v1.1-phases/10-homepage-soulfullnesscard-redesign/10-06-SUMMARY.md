---
phase: 10-homepage-soulfullnesscard-redesign
plan: 06
subsystem: home-presentation
tags: [custom-painter, rings, tdd, mocktail-canvas]
requires: [10-03]
provides:
  - HappinessRingsPainter (CustomPainter subclass for 3 concentric gradient rings)
affects:
  - HomeHeroCard composition (Wave 4) — gains a render-only painter dependency
tech_stack:
  added:
    - mocktail-on-Canvas test pattern (registerFallbackValue + verify drawArc)
  patterns:
    - Canonical Flutter Canvas.drawArc + SweepGradient (RESEARCH §Pattern 3)
    - Mode-agnostic painter with `double?` ratios (null = Empty, value = Value)
key_files:
  created:
    - lib/features/home/presentation/widgets/painter/happiness_rings_painter.dart
  modified:
    - test/widget/features/home/presentation/widgets/painter/happiness_rings_painter_test.dart
decisions:
  - Painter is mode-agnostic; mode-specific sweep-ratio computation lives at the call site (HomeHeroCard, Wave 4) per Single Responsibility.
  - `0.0` (exact) is treated like Empty for fill rendering — the `> 0` guard skips zero-length arcs.
  - Sweep overflow clamps to 1.0 (full circle) so a ratio > 1 cannot draw past 360°.
metrics:
  duration: ~25m
  completed: 2026-05-02
  tasks: 2
  tests_added: 9
  files_added: 1
  files_modified: 1
---

# Phase 10 Plan 06: HappinessRingsPainter Summary

Implement `HappinessRingsPainter`, a pure-render `CustomPainter` that draws 3 concentric gradient rings for HomeHeroCard, and replace the Plan 10-03 skeleton tests with 9 mocktail-on-Canvas assertions covering Empty/Value semantics, sweep-angle math, overflow clamping, and `shouldRepaint` equality.

## Tasks Executed

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 6.1 | Implement HappinessRingsPainter | `e8b6537` | `lib/features/home/presentation/widgets/painter/happiness_rings_painter.dart` (created, 118 lines after `dart format`) |
| 6.2 | Populate painter unit tests (unskip + fill bodies) | `89253cd` | `test/widget/features/home/presentation/widgets/painter/happiness_rings_painter_test.dart` (modified; +191 / -32) |

## Implementation Notes

**Painter contract (mode-agnostic):**
- Const constructor; 3 `double?` sweep ratios + 3 `SweepGradient`s + `Color trackColor` + `double strokeWidth = 8` + `double ringGap = 4`.
- `paint()` always renders the gray track arc per ring; the gradient fill arc renders only when the ratio is non-null and `> 0`.
- Sweep overflow `> 1.0` clamps to `1.0` (full circle).
- `shouldRepaint` compares 3 ratios + `trackColor`; gradients are `const` (identity-stable per theme).
- No provider, locale, theme, or runtime state reads inside the painter — all inputs flow through the constructor.

**Reference:** RESEARCH §Pattern 3 (lines 379-447) — verbatim canonical Flutter `Canvas.drawArc` + `SweepGradient` pattern with [Context7-cited Flutter API docs fetched 2026-05-02].

## Test Suite (9 tests, all green)

| # | Test name | Key assertion |
| - | --------- | ------------- |
| 1 | Empty rings: 3 track arcs only, no fill arc | `verify(drawArc(any(), 0, 2π, false, any())).called(3)` + `verifyNever(drawArc(any(), -π/2, any(), false, any()))` |
| 2 | Mixed Empty/Value rings: 3 track arcs + 1 fill arc | 3 track arcs (sweep=2π) + `verify(drawArc(any(), -π/2, π, false, any())).called(1)` |
| 3 | All Value rings: 3 track arcs + 3 fill arcs | `verify(drawArc(any(), any(), any(), false, any())).called(6)` |
| 4 | Sweep ratio of 0.5 produces sweepAngle = π (half circle) | `verify(drawArc(any(), -π/2, π, false, any())).called(1)` |
| 5 | Sweep ratio overflow (1.5) clamps to full circle | `verify(drawArc(any(), -π/2, 2π, false, any())).called(1)` |
| 6 | Sweep ratio of 0.0 (exact zero) skips fill arc | 3 track arcs + `verifyNever(drawArc(any(), -π/2, any(), false, any()))` |
| 7 | shouldRepaint returns false when inputs equal | `expect(p1.shouldRepaint(p2), isFalse)` for two painters with identical fields |
| 8 | shouldRepaint returns true when outerSweepRatio differs | `expect(p1.shouldRepaint(p2), isTrue)` after changing `outerSweepRatio` 0.5 → 0.7 |
| 9 | shouldRepaint returns true when trackColor differs | `expect(p1.shouldRepaint(p2), isTrue)` after changing `trackColor` `0xFFEFEFEF` → `0xFF353845` (light → dark theme) |

Plan called for "8 tests"; the enumerated bodies actually defined 9 distinct cases (3 shouldRepaint + 6 paint). All 9 implemented; the acceptance criterion `≥ 8` is satisfied.

**Test runner output:**
```
00:00 +0: HappinessRingsPainter Empty rings: 3 track arcs only, no fill arc
00:00 +1: HappinessRingsPainter Mixed Empty/Value rings: 3 track arcs + 1 fill arc...
00:00 +2: HappinessRingsPainter All Value rings: 3 track arcs + 3 fill arcs
00:00 +3: HappinessRingsPainter Sweep ratio of 0.5 produces sweepAngle = pi (half circle)
00:00 +4: HappinessRingsPainter Sweep ratio overflow (1.5) clamps to full circle...
00:00 +5: HappinessRingsPainter Sweep ratio of 0.0 (exact zero) skips fill arc
00:00 +6: HappinessRingsPainter shouldRepaint returns false when inputs equal
00:00 +7: HappinessRingsPainter shouldRepaint returns true when outerSweepRatio differs
00:00 +8: HappinessRingsPainter shouldRepaint returns true when trackColor differs
00:00 +9: All tests passed!
```

## Verification

| Check | Result |
| ----- | ------ |
| `flutter analyze lib/features/home/presentation/widgets/painter/` | No issues found |
| `flutter analyze test/widget/features/home/presentation/widgets/painter/happiness_rings_painter_test.dart` | No issues found |
| `flutter test test/widget/features/home/presentation/widgets/painter/happiness_rings_painter_test.dart` | All tests passed (9/9) |
| `grep -c "extends CustomPainter" lib/.../happiness_rings_painter.dart` | 1 |
| `grep -c "skip: 'pending"  test/.../happiness_rings_painter_test.dart` | 0 |
| painter file line count | 118 (auto-formatted; see Deviations) |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 — Format-budget conflict] Painter file is 118 lines after `dart format` (plan budget 60-110)**
- **Found during:** Task 6.1 verification.
- **Issue:** The plan acceptance criterion specifies `60-110 lines`, but `dart format` (mandated by `CLAUDE.md` "Quality checks ALL must pass before commit") expanded list literals onto separate lines, taking the file from 110 to 118 lines (+8 lines of pure formatting whitespace).
- **Decision:** `dart format` is a hard project mandate; the plan's line budget did not account for the formatter's collection-literal trailing-comma expansion. Content matches RESEARCH §Pattern 3 verbatim — the size delta is 100% formatting. Accepted the 118-line formatted file (8 lines over).
- **Files modified:** `lib/features/home/presentation/widgets/painter/happiness_rings_painter.dart`.
- **Commit:** `e8b6537`.

### Plan Counts vs. Implementation

- Plan said "8 tests total" but the enumerated test bodies in the plan actually defined 9 distinct cases (the third `shouldRepaint` case for `trackColor` was the 9th). Implemented 9 — matches the enumerated bodies and exceeds the `≥ 8` acceptance criterion.

## Authentication Gates

None.

## Self-Check: PASSED

| Claim | Verification | Result |
| ----- | ------------ | ------ |
| `lib/features/home/presentation/widgets/painter/happiness_rings_painter.dart` exists | `wc -l` reports 118 lines | FOUND |
| `test/widget/features/home/presentation/widgets/painter/happiness_rings_painter_test.dart` modified | `wc -l` reports 228 lines | FOUND |
| Commit `e8b6537` exists | `git log --oneline -3` shows it | FOUND |
| Commit `89253cd` exists | `git log --oneline -3` shows it | FOUND |
| All 9 painter tests pass | `flutter test ...painter_test.dart` reports "All tests passed!" | FOUND |
| `flutter analyze lib/.../painter/` clean | "No issues found" | FOUND |

## Threat Flags

None — the painter is a pure render utility with no I/O, no auth, no network, no schema.

## Known Stubs

None.

## Output

`HappinessRingsPainter` is ready for HomeHeroCard composition (Wave 4):
- Mode-agnostic — accepts `double?` ratios from either `HappinessReport` (single mode) or `FamilyHappiness` (group mode).
- Empty state renders as track-only (no NaN, no "0.0" fallback).
- Sweep overflow clamps to full circle.
- `shouldRepaint` honors all 4 mutable inputs (3 ratios + trackColor).
