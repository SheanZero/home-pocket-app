---
quick_id: 260526-i9a
plan: 01
status: complete
tasks_completed: 3
tasks_total: 3
files_modified:
  - lib/features/accounting/presentation/navigation/entry_mode_navigation_config.dart
commits:
  - 2a7d6ce: "fix(260526-i9a): swap MaterialPageRoute for zero-duration PageRouteBuilder in entry mode nav"
verification:
  flutter_analyze: pass (0 issues)
  widget_test: pass (2/2)
  human_visual: approved (2026-05-26)
requirements:
  - I9A-01
completed_date: 2026-05-26
---

# Quick 260526-i9a: Tab Switch Inner Content Only — Summary

One-liner: Replaced the `MaterialPageRoute` in `navigateToEntryMode()` with a zero-duration `PageRouteBuilder` so tab switches in the Add-Transaction flow swap only the body region, leaving the AppBar and tab strip visually stationary.

## Tasks Completed

| # | Task | Status | Commit |
|---|------|--------|--------|
| 1 | Swap `MaterialPageRoute` for zero-duration `PageRouteBuilder` | done | `2a7d6ce` |
| 2 | Re-run `entry_mode_switcher_test.dart` | done | n/a (verification only) |
| 3 | Visual verification in running app | **pending human** | — |

## What Changed

**File:** `lib/features/accounting/presentation/navigation/entry_mode_navigation_config.dart`

Inside `navigateToEntryMode()`, replaced:

```dart
final route = MaterialPageRoute<void>(builder: (_) => config.builder(bookId));
```

with:

```dart
final route = PageRouteBuilder<void>(
  pageBuilder: (_, _, _) => config.builder(bookId),
  transitionDuration: Duration.zero,
  reverseTransitionDuration: Duration.zero,
  transitionsBuilder: (_, _, _, child) => child,
);
```

No other lines changed. `_entryModeRouteConfigs`, `EntryModeRouteConfig`, the `if (fromMode == toMode) return;` guard, and the `pushReplacement` / `push` branching are all preserved. No new imports (PageRouteBuilder resolves from the existing `package:flutter/material.dart`).

## Verification Results

- **`flutter analyze` on the file:** `No issues found! (ran in 1.9s)` — 0 issues.
- **`dart format` check:** 0 changes needed; file already formatted.
- **`flutter test test/widget/features/accounting/presentation/widgets/entry_mode_switcher_test.dart`:**
  - `EntryModeSwitcher navigates to OCR screen when OCR tab is tapped` — pass
  - `EntryModeSwitcher navigates to Voice screen when Voice tab is tapped` — pass
  - Total: 2/2 pass.

## Deviations from Plan

None — plan executed exactly as written.

## Status

`status: incomplete` is correct and expected — Task 3 is a blocking `checkpoint:human-verify` gate that requires running the app on a simulator/device. The executor stopped after Task 2 per the plan's own checkpoint protocol.

## Next Step (Human Visual Verification)

Run the app and confirm tab switches no longer animate the AppBar or the tab strip:

1. From the project root: `flutter run`.
2. From the Home tab, tap the center FAB to open the Add-Transaction flow (lands on `ManualOneStepScreen`, 手动输入 selected).
3. Tap the **OCR** tab (camera icon, middle). Expected: body region instantly changes to the dark camera viewfinder. The AppBar (title "添加账目", close button) and the tab strip do NOT slide or flash. The selected-pill highlight smoothly slides from left to middle (intentional `AnimatedContainer` inside `InputModeTabs`). Note: AppBar background color cross-cuts from light to dark `#1A2530` instantly — if it slides, Task 1 did not take effect.
4. Tap the **语音** tab (mic icon, right). Expected: instant body swap to the voice screen; AppBar reverts to light theme instantly.
5. Tap the **手动输入** tab (keyboard icon, left). Expected: instant return to manual entry with a fresh empty form (pre-existing `pushReplacement` rebuild behavior, not a regression).
6. Tap the close (X) button in the AppBar from any tab. Expected: pops back to `MainShellScreen` (Home tab).

Reply `approved` to mark Task 3 done, or describe what still animates so the fix can be revisited.

## Self-Check: PASSED

- File `lib/features/accounting/presentation/navigation/entry_mode_navigation_config.dart`: FOUND, contains `PageRouteBuilder<void>`, `Duration.zero` (x2), identity `transitionsBuilder`.
- Commit `2a7d6ce`: FOUND on `main`.
