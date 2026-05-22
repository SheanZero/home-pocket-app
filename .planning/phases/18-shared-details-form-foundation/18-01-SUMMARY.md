---
phase: 18-shared-details-form-foundation
plan: "01"
subsystem: accounting-domain
tags:
  - freezed
  - sealed-union
  - domain-model
  - ocr
  - transaction-form
dependency_graph:
  requires: []
  provides:
    - OcrParseDraft (sealed Freezed model, .empty() factory, isEmpty getter)
    - TransactionDetailsFormConfig (sealed union $new/edit)
    - NewEntryConfig (typedef for $new variant)
    - EditEntryConfig (typedef for edit variant)
    - TransactionDetailsFormResult (sealed union success/validationError/persistError)
    - _Success, _ValidationError, _PersistError (typedef discriminators)
  affects:
    - lib/features/accounting/domain/models/
tech_stack:
  added: []
  patterns:
    - "@freezed sealed class with private const constructor and isEmpty switch-based getter"
    - "Two sealed unions in one file (Config + Result)"
    - "$new factory name ($ prefix to escape Dart keyword)"
key_files:
  created:
    - lib/features/accounting/domain/models/ocr_parse_draft.dart
    - lib/features/accounting/domain/models/ocr_parse_draft.freezed.dart
    - lib/features/accounting/domain/models/transaction_details_form_config.dart
    - lib/features/accounting/domain/models/transaction_details_form_config.freezed.dart
  modified: []
decisions:
  - "OcrParseDraft.isEmpty uses switch-based pattern matching (not direct field access) because sealed variant _Empty has no fields — accessing fields from the base class body is undefined in sealed Freezed classes"
  - "Both sealed unions declared in a single file (transaction_details_form_config.dart) per plan spec — Config + Result are tightly coupled and small"
  - "$new factory name with $ prefix escapes the Dart 'new' keyword at call site: TransactionDetailsFormConfig.$new(...)"
  - "Variant typedef class names are: NewEntryConfig, EditEntryConfig, _Success, _ValidationError, _PersistError — these are the discriminator types in switch/when in downstream plans"
metrics:
  duration_minutes: 3
  tasks_completed: 3
  tasks_total: 3
  files_changed: 4
  completed_date: "2026-05-22"
---

# Phase 18 Plan 01: OcrParseDraft + TransactionDetailsFormConfig Domain Models Summary

**One-liner:** Two sealed Freezed unions (`OcrParseDraft` with `.empty()` + `isEmpty`, and `TransactionDetailsFormConfig.$new`/`.edit` + `TransactionDetailsFormResult`) establishing the type contracts that Plans 02–08 depend on.

## Tasks Completed

| Task | Description | Status | Commit |
|------|-------------|--------|--------|
| 1 | Create OcrParseDraft Freezed model | Done | 1faf988 |
| 2 | Create TransactionDetailsFormConfig + TransactionDetailsFormResult sealed unions | Done | 1faf988 |
| 3 | Run build_runner, generate Freezed boilerplate | Done | 2a36045 |

## What Was Built

### OcrParseDraft (`lib/features/accounting/domain/models/ocr_parse_draft.dart`)

Sealed Freezed model with two variants:
- `OcrParseDraft({int? amount, String? merchant, DateTime? date, String? rawOcrText, String? imagePath})` — default variant with five nullable fields
- `OcrParseDraft.empty()` — const-constructible empty variant, used at OCR step 1 → step 2 boundary

The `isEmpty` getter (drives the `OcrReviewScreen` banner gate per D-11) uses switch-based pattern matching over the sealed variants rather than direct field access.

### TransactionDetailsFormConfig (`lib/features/accounting/domain/models/transaction_details_form_config.dart`)

Two sealed unions in one file:

**TransactionDetailsFormConfig** — configures `TransactionDetailsForm`:
- `.$new({required String bookId, required EntrySource entrySource, int? initialAmount, Category? initialCategory, Category? initialParentCategory, String? initialMerchant, int? initialSatisfaction, DateTime? initialDate, String? voiceKeyword})` → `NewEntryConfig`
- `.edit({required Transaction seed})` → `EditEntryConfig`
- `voiceKeyword` is structurally absent from `.edit` (D-09)

**TransactionDetailsFormResult** — return type for `TransactionDetailsForm.submit()`:
- `.success(Transaction transaction)` → `_Success`
- `.validationError(String message)` → `_ValidationError`
- `.persistError(String message)` → `_PersistError`

### Generated Boilerplate

- `ocr_parse_draft.freezed.dart` (9,706 bytes)
- `transaction_details_form_config.freezed.dart` (28,288 bytes)

`flutter analyze` exits clean (0 issues on new files; 4 pre-existing info/warning entries in Firebase and category_selection_screen unrelated to this plan).

## Verification Results

- `flutter pub run build_runner build --delete-conflicting-outputs` exits 0
- Both `.freezed.dart` files exist and are non-empty
- `flutter analyze lib/features/accounting/domain/models/ocr_parse_draft.dart lib/features/accounting/domain/models/transaction_details_form_config.dart` — No issues found
- All 7 acceptance criteria for Task 1 passed
- All 8 acceptance criteria for Task 2 passed (voiceKeyword confirmed only in `$new` factory, not in `.edit`)
- Task 3 generated files confirmed in `git status`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed OcrParseDraft.isEmpty using switch-based pattern matching**

- **Found during:** Task 1 verification (flutter analyze)
- **Issue:** Initial implementation used direct field access (`amount == null && merchant == null && ...`) in the sealed class private constructor body. In Freezed-generated sealed classes, field names from one variant (`_OcrParseDraft`) are not visible from the base class body — `flutter analyze` reported `undefined_identifier` for all five field references.
- **Fix:** Replaced direct field access with `switch (this) { _OcrParseDraft(:final amount, ...) => ..., _Empty() => true }` using Dart 3 pattern matching.
- **Files modified:** `lib/features/accounting/domain/models/ocr_parse_draft.dart`
- **Commit:** 1faf988

## Known Stubs

None — these are pure Freezed data-carrier domain models. No UI rendering, no hardcoded values, no placeholder text.

## Threat Flags

None beyond what is documented in the plan's threat register (T-18-01-01/02/03 — all accepted or mitigated per plan).

## Self-Check: PASSED

- `lib/features/accounting/domain/models/ocr_parse_draft.dart` — FOUND
- `lib/features/accounting/domain/models/ocr_parse_draft.freezed.dart` — FOUND
- `lib/features/accounting/domain/models/transaction_details_form_config.dart` — FOUND
- `lib/features/accounting/domain/models/transaction_details_form_config.freezed.dart` — FOUND
- Commit `1faf988` — FOUND (feat: source models)
- Commit `2a36045` — FOUND (chore: generated boilerplate)
