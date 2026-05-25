---
phase: 18-shared-details-form-foundation
plan: "06"
subsystem: accounting/presentation/screens
tags:
  - thin-host-screens
  - transaction-edit
  - ocr-architectural-slot
  - riverpod
dependency_graph:
  requires:
    - 18-01  # TransactionDetailsFormConfig.$new/.edit + OcrParseDraft + TransactionDetailsFormResult
    - 18-03  # i18n keys: transactionEditTitle, ocrReviewTitle, ocrReviewEmptyDraftBanner, transactionUpdated
    - 18-04  # TransactionDetailsForm widget + TransactionDetailsFormState public class
  provides:
    - TransactionEditScreen (.edit thin host, EDIT-01)
    - OcrReviewScreen (.new thin host, INPUT-04 architectural slot)
  affects:
    - 18-07  # Wiring plan pushes TransactionEditScreen from home tile onTap
tech_stack:
  added: []
  patterns:
    - Thin host screen — Scaffold + AppBar + bottom CTA wrapping ConsumerStatefulWidget
    - GlobalKey<TransactionDetailsFormState> + submit() for CTA-to-form coupling (D-02)
    - OcrParseDraft.maybeWhen() to safely unpack sealed union fields into nullable config params
    - MaterialBanner gated by draft.isEmpty for empty-draft informational UX
key_files:
  created:
    - lib/features/accounting/presentation/screens/transaction_edit_screen.dart
    - lib/features/accounting/presentation/screens/ocr_review_screen.dart
  modified: []
decisions:
  - "OcrReviewScreen uses draft.maybeWhen() to extract nullable fields from OcrParseDraft sealed union — _OcrParseDraft variant exposes amount/merchant/date; _Empty variant falls through to orElse, producing a config with all initial values null (correct for Phase 18)"
  - "Both screens use l10n.save (not l10n.record) for the CTA label — save is the appropriate term for an edit operation; record is reserved for the initial-capture metaphor in TransactionConfirmScreen"
  - "Line count discipline: OcrReviewScreen at 149 lines (< 150 gate) achieved by inlining _config as a getter and collapsing the save button into the body build method"
metrics:
  duration_minutes: 45
  completed_date: "2026-05-22"
  tasks_completed: 2
  files_created: 2
  files_modified: 0
  lines_of_code: 288
requirements-completed: [INPUT-04]
---

# Phase 18 Plan 06: TransactionEditScreen + OcrReviewScreen — Summary

**One-liner:** Two thin Scaffold+AppBar+CTA host screens wiring TransactionDetailsForm into the edit-existing path (EDIT-01) and the OCR two-step architectural slot (INPUT-04), with EntrySource.manual+MOD-005 grep marker and empty-draft MaterialBanner.

## What Was Built

### `lib/features/accounting/presentation/screens/transaction_edit_screen.dart` (139 lines)

Thin host for the edit-existing path.

- **Class shape:** `TransactionEditScreen extends ConsumerStatefulWidget` + `_TransactionEditScreenState extends ConsumerState<TransactionEditScreen>`.
- **Constructor:** `const TransactionEditScreen({super.key, required this.transaction})`  — single required `Transaction` param. Plan 07 will pass the full `Transaction` from the home recent-tx tile closure.
- **GlobalKey pattern (D-02):** `final _formKey = GlobalKey<TransactionDetailsFormState>();` — CTA calls `_formKey.currentState!.submit()` which returns `Future<TransactionDetailsFormResult>`.
- **Config:** `TransactionDetailsFormConfig.edit(seed: widget.transaction)` — pre-populates all 7 editable fields from the seed.
- **Post-save navigation (D-18):** `Navigator.of(context).pop(true)` — pop-with-result to home; the home recent-tx stream (DB-backed) auto-refreshes.
- **Cancel (D-10/D-16):** `Navigator.pop(context)` — silent discard, no dirty-state dialog.
- **No delete affordance (D-11/D-17):** file contains no `Icons.delete`, no `'Delete'` label, no delete action.
- **No `showDialog` (D-10/D-16):** no dirty-confirm modal.
- **i18n:** `l10n.transactionEditTitle` (AppBar), `l10n.transactionUpdated` (success snackbar), `l10n.back` (leading button), `l10n.save` (CTA).
- **Riverpod 3:** imports only `flutter_riverpod/flutter_riverpod.dart` (no `legacy.dart`). `ref` available via `ConsumerState` but not actively used — form widget owns all `ref.read` calls.

### `lib/features/accounting/presentation/screens/ocr_review_screen.dart` (149 lines)

Thin host for the OCR review architectural slot (INPUT-04). MOD-005's first commit fills in real OCR data here.

- **Class shape:** `OcrReviewScreen extends ConsumerStatefulWidget` + `_OcrReviewScreenState extends ConsumerState<OcrReviewScreen>`.
- **Constructor:** `const OcrReviewScreen({super.key, required this.bookId, required this.draft})` — `bookId: String` + `draft: OcrParseDraft`.
- **GlobalKey pattern (D-02):** same as edit screen — `GlobalKey<TransactionDetailsFormState>`.
- **Config assembly (sealed union handling):** `OcrParseDraft` is a sealed class with two variants (`_OcrParseDraft` with nullable fields, `_Empty`). Fields are only accessible via pattern match. Uses `draft.maybeWhen(...)` — populated variant extracts `amount`, `merchant`, `date`; `_Empty` variant falls through to `orElse`, producing a config with all initial values null.
- **entrySource (D-12):** `EntrySource.manual` — Phase 18 stamps manual for all OCR-slot saves. The **MOD-005 grep marker** appears on the `entrySource:` line:
  - File: `lib/features/accounting/presentation/screens/ocr_review_screen.dart`
  - Lines: 97 and 104 (two occurrences — one per maybeWhen branch)
  - Text: `// MOD-005: flip to EntrySource.ocr when OCR writer ships (D-12)`
  - `grep -c "MOD-005" ocr_review_screen.dart` returns 3 (includes the file-level docstring mention)
- **Empty-draft banner (D-11/D-13):** `if (widget.draft.isEmpty) MaterialBanner(content: Text(l10n.ocrReviewEmptyDraftBanner), actions: const [SizedBox.shrink()])` — gated by `OcrParseDraft.isEmpty` getter.
- **Post-save navigation (D-13/D-04):** `Navigator.of(context).popUntil((r) => r.isFirst)` — mirrors `TransactionConfirmScreen` (both are `.new` flow saves).
- **i18n:** `l10n.ocrReviewTitle` (AppBar), `l10n.ocrReviewEmptyDraftBanner` (banner), `l10n.transactionSaved` (success snackbar), `l10n.back` (leading), `l10n.save` (CTA).
- **No `EntrySource.ocr` live code:** grep confirms zero live (non-comment) usages.

## D-18 vs popUntil Distinction

| Screen | Post-save | Reason |
|--------|-----------|--------|
| `TransactionEditScreen` | `Navigator.of(context).pop(true)` | Edit path — pop-with-result so caller can detect change; home stream auto-refreshes (D-18) |
| `OcrReviewScreen` | `Navigator.of(context).popUntil((r) => r.isFirst)` | New-entry path — same UX as `TransactionConfirmScreen`; returns user to main shell after creating a new transaction (D-13/D-04) |

## Line Count Summary

| File | Lines | Gate |
|------|-------|------|
| `transaction_edit_screen.dart` | 139 | < 150 ✓ |
| `ocr_review_screen.dart` | 149 | < 150 ✓ |

## TransactionDetailsForm as Single Body Source

Both screens embed `TransactionDetailsForm` as the sole body content (D-01 host-owns-chrome contract):
- `TransactionEditScreen` body: `SingleChildScrollView > TransactionDetailsForm(key:, config: .edit(seed:))`
- `OcrReviewScreen` body: `SingleChildScrollView > TransactionDetailsForm(key:, config: .$new(...))`

No editable field logic exists in either host screen — all field rendering, validation, and use-case dispatch lives in Plan 04's `TransactionDetailsForm`.

## Deviations from Plan

### Auto-adjusted: OcrParseDraft sealed union field access

**Found during:** Task 2 (OcrReviewScreen creation — first analyze run)

**Issue:** The plan's template assumed `widget.draft.amount`, `widget.draft.merchant`, `widget.draft.date` could be accessed directly on the `OcrParseDraft` base type. However `OcrParseDraft` is a `sealed class` with two variants — `_OcrParseDraft` (with nullable fields) and `_Empty` (no fields). Dart's sealed class semantics require exhaustive pattern matching to access variant-specific members.

**Fix:** Replaced direct field access with `widget.draft.maybeWhen((amount, merchant, date, rawOcrText, imagePath) => ..., orElse: () => ...)`. The populated branch extracts the fields; `orElse` produces a config with all initial values null (correct Phase 18 behavior since `OcrParseDraft.empty()` is the only caller in Phase 18). The config was extracted into a private getter `_config` to keep the `build()` method readable.

**Files modified:** `ocr_review_screen.dart` only.

**Commit:** c3c20b1

### Auto-adjusted: Worktree merge required before analysis

**Found during:** Task 1 verification

**Issue:** The agent worktree (`worktree-agent-a6e5065b1d56fe0aa`) was branched from Phase 17 (commit `bda7998`) and was missing Plans 01-05 outputs: `transaction_details_form_config.dart`, `ocr_parse_draft.dart`, `transaction_details_form.dart`, updated generated localizations. `flutter analyze` reported 17 errors on dependencies missing from the worktree.

**Fix:** `git merge main` from inside the worktree. The merge brought 39 commits (Phase 18 Plans 01-05 + prior work). A stale `pubspec.lock` minor version delta in the worktree was discarded (`git checkout -- pubspec.lock`) before the merge. No conflicts.

**Impact:** No plan file changes needed. The merge is standard worktree lifecycle — analysis could not proceed until the worktree had the dependency artifacts.

## Self-Check

- [x] `lib/features/accounting/presentation/screens/transaction_edit_screen.dart` exists (139 lines)
- [x] `lib/features/accounting/presentation/screens/ocr_review_screen.dart` exists (149 lines)
- [x] `class TransactionEditScreen extends ConsumerStatefulWidget` present
- [x] `class OcrReviewScreen extends ConsumerStatefulWidget` present
- [x] `required this.transaction` + `final Transaction transaction` in edit screen
- [x] `required this.bookId` + `required this.draft` + `final OcrParseDraft draft` in ocr screen
- [x] `GlobalKey<TransactionDetailsFormState>` in both files
- [x] `TransactionDetailsFormConfig.edit(seed: widget.transaction)` in edit screen
- [x] `TransactionDetailsFormConfig.$new(` in ocr screen (via maybeWhen branches)
- [x] `Navigator.of(context).pop(true)` in edit screen (D-18)
- [x] `popUntil((r) => r.isFirst)` in ocr screen (D-13/D-04)
- [x] `EntrySource.manual` in ocr screen (D-12 — not EntrySource.ocr)
- [x] `MOD-005` grep marker in ocr screen (3 occurrences, 2 in code comments on entrySource lines)
- [x] `widget.draft.isEmpty` gates MaterialBanner in ocr screen (D-11/D-13)
- [x] `MaterialBanner(` present in ocr screen
- [x] `S.of(context).transactionEditTitle` in edit screen
- [x] `S.of(context).transactionUpdated` in edit screen
- [x] `S.of(context).ocrReviewTitle` in ocr screen
- [x] `S.of(context).ocrReviewEmptyDraftBanner` in ocr screen
- [x] No `Navigator.popUntil` in edit screen (only `popUntil` in comments)
- [x] No delete affordance in edit screen
- [x] No `showDialog` in either file
- [x] No `import 'package:flutter_riverpod/legacy.dart'` in either file
- [x] No `EntrySource.ocr` as live code in ocr screen (comments only)
- [x] No camera/MediaCapture/ImagePicker imports in ocr screen
- [x] `flutter analyze` exits 0 on both files
- [x] wc -l edit screen: 139 < 150
- [x] wc -l ocr screen: 149 < 150

## Self-Check: PASSED
