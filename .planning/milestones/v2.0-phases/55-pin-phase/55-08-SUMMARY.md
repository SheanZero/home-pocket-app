---
phase: 55-pin-phase
plan: 08
subsystem: applock-ui
tags: [flutter, presentational-widgets, app-lock, pin, face-id, tone-b]
requires:
  - "Plan 55-04: app-lock ARB keys (appLockFaceIdPrompt/Retry, appLockUsePasscode) generated into lib/generated"
provides:
  - "PinKeypad: reusable 9-grid numeric keypad (onDigit/onBackspace)"
  - "PinDots: 4-dot indicator with shake-and-clear error animation (errorTrigger)"
  - "FaceIdPanel: Face ID surface with retry + ghost passcode escape (onRetry/onUsePasscode)"
  - "PrivacyMask: full-bleed opaque brand cover (no blur)"
affects:
  - "Plan 55-09 (AppLockScreen) consumes PinKeypad/PinDots/FaceIdPanel"
  - "Plan 55-10 (set-PIN flow) consumes PinKeypad/PinDots"
  - "Plan 55-11 (main.dart host) hosts PrivacyMask via ValueNotifier"
tech_stack:
  added: []
  patterns:
    - "context.palette (ADR-019 v1.6) theming; no hardcoded theme colours"
    - "S.of(context) for all user-facing strings"
    - "Outfit display font for keys/labels"
    - "callback-only presentational widgets (no provider/service reads)"
key_files:
  created:
    - lib/features/applock/presentation/widgets/pin_keypad.dart
    - lib/features/applock/presentation/widgets/pin_dots.dart
    - lib/features/applock/presentation/widgets/face_id_panel.dart
    - lib/features/applock/presentation/widgets/privacy_mask.dart
    - test/widget/features/applock/widgets/pin_keypad_test.dart
    - test/widget/features/applock/widgets/pin_dots_test.dart
  modified: []
decisions:
  - "PinKeypad bottom-left is a blank cell (per plan behavior contract), not the sketch's Face ID key — the Face ID escape lives on FaceIdPanel / the consuming screen, keeping the keypad purely numeric and reusable by the set-PIN flow."
  - "PinDots error animation is driven by a declarative monotonic errorTrigger counter (didUpdateWidget detects the bump), not a GlobalKey imperative method — cleaner to test and to wire from a parent's state."
  - "Backspace Semantics label uses MaterialLocalizations.deleteButtonTooltip (no app ARB key needed, CJK-free) since Plan 04 added no keypad-semantic key."
metrics:
  tasks_completed: 2
  files_created: 6
  files_modified: 0
  commits: 3
  completed: 2026-06-30
status: complete
---

# Phase 55 Plan 08: Tone-B Lock Widgets Summary

Four presentational sketch-002 tone-B lock primitives — a 9-grid `PinKeypad`, an animated 4-dot `PinDots`, a `FaceIdPanel` with ghost passcode escape, and an opaque `PrivacyMask` — built as callback-only, theme-following (ADR-019), S-localized widgets with no lock business logic.

## What was built

### Task 1 (TDD): PinKeypad + PinDots
- **PinKeypad** (`StatelessWidget`): standard iOS-style pad — rows `1 2 3 / 4 5 6 / 7 8 9` and a final `(blank) 0 ⌫` row. Emits `onDigit(int)` / `onBackspace()`. `context.palette` surfaces, `Outfit` font, per-key `Semantics(button, label)` (digit value + platform delete tooltip). Flexible-width `Expanded` cells avoid the fixed-width placeholder-font overflow gotcha.
- **PinDots** (`StatefulWidget`): `filledCount`/`length=4` filled vs outlined dots, no text. A monotonic `errorTrigger` prop fires a decaying horizontal shake (`SingleTickerProviderStateMixin` + `AnimatedBuilder`/`Transform.translate`) and `HapticFeedback.mediumImpact()` on a wrong PIN (D-12). Dots carry stable keys (`pin-dot-filled-N` / `pin-dot-empty-N`).
- **Tests** (5, all green): digit/backspace presence, `onDigit(7)`, `onBackspace`, filled/empty rendering, and the error animation settling without throwing.

### Task 2: FaceIdPanel + PrivacyMask
- **FaceIdPanel** (`StatelessWidget`): centered brand glyph + `S.appLockFaceIdPrompt`, a primary retry gradient pill (`S.appLockFaceIdRetry` → `onRetry`), and a ghost `S.appLockUsePasscode` text button (`onUsePasscode`). Emits callbacks only — never calls `BiometricService`. The ghost escape is always present so Face ID is never a dead end (D-09 / T-55-19).
- **PrivacyMask** (`StatelessWidget`): full-bleed OPAQUE `palette.background` `Container` + centered brand mark. Explicitly NOT a blur filter (D-07 / T-55-18 — blur can leak ledger in snapshot timings). No text, no state.

## Verification evidence

| Gate | Result |
|------|--------|
| `flutter test` (2 applock widget suites) | 5/5 passed |
| `flutter analyze` (4 widget files) | No issues found |
| `grep -c context.palette pin_keypad.dart` | 2 (≥1) |
| `grep -c context.palette privacy_mask.dart` | 1 (≥1) |
| `grep -c appLockUsePasscode face_id_panel.dart` | 1 (≥1) |
| `grep -c BackdropFilter privacy_mask.dart` | 0 (opaque, not blur) |
| hardcoded-color hex scan (4 files) | 0 literals |
| `hardcoded_cjk_ui_scan_test.dart` | passed |

## TDD Gate Compliance

Task 1 (`tdd="true"`) followed RED → GREEN:
- RED `984da03a` — `test(55-08)`: 5 failing tests against `SizedBox.shrink()` stubs.
- GREEN `342cdcab` — `feat(55-08)`: real PinKeypad/PinDots, all 5 tests pass.

## Deviations from Plan

None affecting behavior. One contract clarification recorded as a decision: the keypad's bottom-left cell is blank (plan behavior contract: "renders 12 cells: 1-9, blank, 0, backspace") rather than the sketch's "Face ID" key — the Face ID escape is owned by `FaceIdPanel`/the consuming screen, which keeps `PinKeypad` purely numeric and reusable by both the lock screen (Plan 09) and the set-PIN flow (Plan 10).

## Threat surface

No new surface. Both threat-register mitigations are satisfied at the widget level:
- T-55-18 (snapshot leak): `PrivacyMask` is an opaque `Container`, no `BackdropFilter` (grep gate = 0).
- T-55-19 (Face ID dead end): `FaceIdPanel` always renders the ghost passcode escape (grep gate = 1).

## Notes for downstream plans

- `PinDots` holds no entry state — the consumer drives `filledCount` and bumps `errorTrigger` to shake+clear; clear the digits in the same frame.
- `FaceIdPanel`/`PinKeypad` read no providers; Plans 09/10 wire `BiometricService`/`AppLockService` behavior around them.
- Goldens were intentionally left out of scope here (Plan 09's orchestration screen test may baseline goldens on macOS).

## Self-Check: PASSED
