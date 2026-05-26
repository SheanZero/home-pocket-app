---
phase: 18-shared-details-form-foundation
plan: "07"
subsystem: accounting/presentation/screens, home/presentation/screens
tags:
  - entry-point-wiring
  - tap-to-edit
  - ocr-step2-route
  - navigation
dependency_graph:
  requires:
    - 18-06  # TransactionEditScreen + OcrReviewScreen (push targets)
    - 18-01  # OcrParseDraft.empty() (shutter payload)
  provides:
    - HomeTransactionTile.onTap → TransactionEditScreen (SC-2 reachable)
    - OcrScannerScreen shutter → OcrReviewScreen (SC-4 architectural slot behaviorally reachable)
  affects:
    - 18-08  # D-14 widget test (ocr_two_step_seam_test) can now assert the route appears
tech_stack:
  added: []
  patterns:
    - MaterialPageRoute<bool> for edit path (TransactionEditScreen pops with true per D-18)
    - MaterialPageRoute<void> for OCR step-2 path (OcrReviewScreen pops via popUntil)
    - Navigator.of(context).push() — consistent with existing push patterns in the codebase
key_files:
  created: []
  modified:
    - lib/features/home/presentation/screens/home_screen.dart
    - lib/features/accounting/presentation/screens/ocr_scanner_screen.dart
decisions:
  - "Used MaterialPageRoute<bool> (not void) for the tap-to-edit route — matches D-18 (TransactionEditScreen.pop(context, true)) so callers can detect saves; the home recent-tx stream already auto-refreshes from DB without needing the result, but the typed route keeps future flexibility"
  - "Worktree was branched from Phase 17 (bda7998) and was missing Plans 01-06 artifacts; merged main before proceeding — identical situation to Plan 06's known deviation (auto-fixed via git merge main)"
metrics:
  duration_minutes: 12
  completed_date: "2026-05-22"
  tasks_completed: 2
  files_created: 0
  files_modified: 2
  lines_of_code: 17
requirements-completed: [EDIT-01]
---

# Phase 18 Plan 07: Entry Point Wiring — Summary

**One-liner:** Two targeted single-file edits wiring HomeTransactionTile.onTap → TransactionEditScreen and OcrScannerScreen shutter → OcrReviewScreen, making SC-2 and SC-4 reachable at the behavioral level.

## What Was Built

### Task 1: `lib/features/home/presentation/screens/home_screen.dart` (+7 lines)

**What changed:**

- Added import at line 25: `import '../../../accounting/presentation/screens/transaction_edit_screen.dart';` (alphabetical placement among accounting imports, before the `'../widgets/'` block)
- Added `onTap:` argument as the last named parameter of the existing `HomeTransactionTile(...)` constructor call inside the `transactions.map((tx) { ... })` block (now around line 328):

  ```dart
  onTap: () => Navigator.of(context).push(
    MaterialPageRoute<bool>(
      builder: (_) => TransactionEditScreen(transaction: tx),
    ),
  ),
  ```

**Invariants preserved:**
- `HomeHeroCard` and `homeHero*Provider` untouched — zero diff outside the `transactions.map` block (ADR-016 §3 isolation invariant)
- No `onLongPress`, no `Dismissible`, no provider invalidation after pop added
- `tx` used directly from the map closure variable — no new provider lookup

**Route type:** `MaterialPageRoute<bool>` — matches `TransactionEditScreen`'s `Navigator.pop(context, true)` per D-18.

### Task 2: `lib/features/accounting/presentation/screens/ocr_scanner_screen.dart` (+10 lines, -1 line)

**What changed:**

- Added two imports after the existing import block:
  - `import '../../domain/models/ocr_parse_draft.dart';`
  - `import 'ocr_review_screen.dart';`
- Replaced shutter `GestureDetector.onTap` from `() => Navigator.pop(context)` to:

  ```dart
  onTap: () => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => OcrReviewScreen(
        bookId: bookId,
        draft: const OcrParseDraft.empty(),
      ),
    ),
  ),
  ```

**Invariants preserved:**
- Gallery `_CircleButton(icon: Icons.photo_library_outlined, onTap: () {})` — unchanged
- Flash `_CircleButton(icon: Icons.flash_off_outlined, onTap: () {})` — unchanged
- Shutter Container styling (width: 72, height: 72, BoxDecoration with BoxShape.circle) — byte-identical
- Header's `IconButton.onPressed: () => Navigator.pop(context)` — unchanged (back button, not shutter)
- `class OcrScannerScreen` constructor signature unchanged (D-10)

**Route type:** `MaterialPageRoute<void>` — OcrReviewScreen uses `popUntil((r) => r.isFirst)` per Plan 06.

## Wiring Line Numbers

| File | Line | What |
|------|------|------|
| `home_screen.dart` | 25 | `import transaction_edit_screen.dart` added |
| `home_screen.dart` | 327–334 | `onTap:` argument with `MaterialPageRoute<bool>` push |
| `ocr_scanner_screen.dart` | 6 | `import ocr_parse_draft.dart` added |
| `ocr_scanner_screen.dart` | 9 | `import ocr_review_screen.dart` added |
| `ocr_scanner_screen.dart` | 128–138 | Shutter `onTap` swapped from `pop` to `push(OcrReviewScreen)` |

## Deviations from Plan

### Auto-fixed: Worktree merge required before execution

**Found during:** Pre-task setup (verifying Plan 06 artifacts present)

**Issue:** This worktree was branched from Phase 17 (`bda7998`) and was missing all Plans 01-06 outputs: `transaction_edit_screen.dart`, `ocr_review_screen.dart`, `ocr_parse_draft.dart`, `transaction_details_form_config.dart`, and generated localizations. The push targets didn't exist in the worktree filesystem.

**Fix:** `git merge main` (fast-forward, 81 files, no conflicts). Identical to Plan 06's documented deviation.

**Impact:** No plan file changes needed. The two code edits proceeded as planned once the merge completed.

**Commit:** The merge itself (fast-forward to 811abf3); no separate commit needed.

## Self-Check

- [x] `lib/features/home/presentation/screens/home_screen.dart` contains `import '../../../accounting/presentation/screens/transaction_edit_screen.dart';` exactly once
- [x] File contains `TransactionEditScreen(transaction: tx)` inside the HomeTransactionTile constructor call
- [x] File contains `MaterialPageRoute<bool>` (matches D-18 — pops with bool result)
- [x] File contains `onTap:` followed by `Navigator.of(context).push` inside `transactions.map`
- [x] File does NOT contain HomeHeroCard changes (diff confined to tile block only)
- [x] File does NOT contain `homeHero` provider invalidation calls (ADR-016 §3)
- [x] File does NOT contain `onLongPress:` or `Dismissible(` on HomeTransactionTile
- [x] `lib/features/accounting/presentation/screens/ocr_scanner_screen.dart` contains `import '../../domain/models/ocr_parse_draft.dart';`
- [x] File contains `import 'ocr_review_screen.dart';`
- [x] File contains `OcrReviewScreen(bookId: bookId, draft: const OcrParseDraft.empty(),)`
- [x] File contains `MaterialPageRoute<void>`
- [x] File does NOT contain `Navigator.pop(context)` as the shutter's onTap target (replaced)
- [x] File still contains `_CircleButton(icon: Icons.photo_library_outlined, onTap: () {})` (unchanged)
- [x] File still contains `_CircleButton(icon: Icons.flash_off_outlined, onTap: () {})` (unchanged)
- [x] File still contains shutter Container styling `width: 72, height: 72`
- [x] File still declares `class OcrScannerScreen` with `required this.bookId` (D-10 — no rename)
- [x] `flutter analyze lib/features/home/presentation/screens/home_screen.dart` → No issues found
- [x] `flutter analyze lib/features/accounting/presentation/screens/ocr_scanner_screen.dart` → No issues found
- [x] Full `flutter analyze` — 4 issues, all pre-existing (2 in external build artifact `build/ios/SourcePackages/firebase_messaging-16.2.2/`, 2 deprecation infos in `category_selection_screen.dart`) — none in modified files
- [x] Task 1 commit: 9df0513
- [x] Task 2 commit: 44404b0
- [x] No files deleted in either commit

## Self-Check: PASSED
