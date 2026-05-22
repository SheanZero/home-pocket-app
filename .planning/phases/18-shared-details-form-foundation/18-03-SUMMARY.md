---
phase: 18-shared-details-form-foundation
plan: "03"
subsystem: i18n
tags: [i18n, arb, localizations, flutter-gen-l10n]
dependency_graph:
  requires: []
  provides:
    - S.of(context).transactionEditTitle
    - S.of(context).ocrReviewTitle
    - S.of(context).ocrReviewEmptyDraftBanner
    - S.of(context).transactionUpdated
    - S.of(context).failedToUpdate
  affects:
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/l10n/app_en.arb
    - lib/generated/app_localizations.dart
    - lib/generated/app_localizations_en.dart
    - lib/generated/app_localizations_ja.dart
    - lib/generated/app_localizations_zh.dart
tech_stack:
  added: []
  patterns:
    - ARB key + @metadata lockstep across 3 locales (ja/zh/en)
    - flutter gen-l10n regeneration after ARB edits
key_files:
  modified:
    - lib/l10n/app_en.arb
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/generated/app_localizations.dart
    - lib/generated/app_localizations_en.dart
    - lib/generated/app_localizations_ja.dart
    - lib/generated/app_localizations_zh.dart
decisions:
  - Inserted new keys immediately after failedToSave for logical grouping with sibling save/error strings
  - All @metadata description text in English per project convention (locale-specific text in value fields only)
  - Simplified Chinese characters confirmed (明细编辑, not Traditional 明細編輯)
metrics:
  duration_seconds: 240
  tasks_completed: 2
  tasks_total: 2
  files_modified: 7
  completed_date: "2026-05-22"
---

# Phase 18 Plan 03: i18n ARB Keys for Shared Details Form — Summary

**One-liner:** Added 5 new Phase 18 i18n keys (transactionEditTitle, ocrReviewTitle, ocrReviewEmptyDraftBanner, transactionUpdated, failedToUpdate) in trilingual lockstep across ja/zh/en ARBs and regenerated S-class getters via flutter gen-l10n.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add 5 keys to all three ARB files in lockstep | 0f89bd4 | app_en.arb, app_ja.arb, app_zh.arb |
| 2 | Regenerate app_localizations*.dart via flutter gen-l10n + verify parity | 9450dff | app_localizations.dart, app_localizations_en.dart, app_localizations_ja.dart, app_localizations_zh.dart |

## Key-String Table (5 keys × 3 locales)

| Key | Japanese (ja) | Simplified Chinese (zh) | English (en) |
|-----|--------------|------------------------|--------------|
| `transactionEditTitle` | 明細編集 | 明细编辑 | Edit Entry |
| `ocrReviewTitle` | レシート確認 | 票据复核 | Review Receipt |
| `ocrReviewEmptyDraftBanner` | OCRはまだ実装されていません。手動で入力してください。 | OCR 尚未实现，请手动填写各字段。 | OCR is not implemented yet — please fill in the fields manually. |
| `transactionUpdated` | 明細を更新しました | 明细已更新 | Transaction updated |
| `failedToUpdate` | 更新に失敗しました | 更新失败 | Failed to update |

## Verification Results

- **JSON validation:** All three ARB files parse as valid JSON (python3 json.load exits 0)
- **Key count:** 889 keys each in ja/zh/en (5 keys × 2 {value + @metadata} = 10 new entries per file; all three files remain identical in count)
- **flutter gen-l10n:** Exits 0, no warnings
- **S class getters:** `String get transactionEditTitle`, `String get ocrReviewTitle`, `String get ocrReviewEmptyDraftBanner`, `String get transactionUpdated`, `String get failedToUpdate` all present in lib/generated/app_localizations.dart
- **Parity test:** `flutter test test/architecture/arb_key_parity_test.dart` — 2/2 passed (both normal-key-sets match AND OCR stub keys preserved)
- **Analyzer:** 0 issues in modified files (lib/l10n/ + lib/generated/); 4 pre-existing info/warning in build/ artifacts and category_selection_screen.dart not touched by this plan

## Insertion Location

Keys inserted immediately after `failedToSave` / `@failedToSave` block in all three files, before `appearance`. This groups the new save/update/error strings with the existing sibling `transactionSaved` / `failedToSave` keys for logical cohesion.

## Deviations from Plan

None — plan executed exactly as written. All 5 keys added in all 3 locales with @metadata blocks; JSON validates; gen-l10n clean; parity test green.

## Downstream Impact

Plans 05, 06, and 08 (TransactionConfirmScreen refactor, TransactionEditScreen + OcrReviewScreen, and integration tests) can now call:
- `S.of(context).transactionEditTitle` — AppBar for edit screen
- `S.of(context).ocrReviewTitle` — AppBar for OCR review screen
- `S.of(context).ocrReviewEmptyDraftBanner` — empty-draft info banner
- `S.of(context).transactionUpdated` — success snackbar after edit save
- `S.of(context).failedToUpdate` — error snackbar on edit save failure

## Threat Surface Scan

No new security-relevant surface introduced. All added strings are static display text with no user input, no external data, no trust boundaries crossed. T-18-03-01/02/03 dispositions from the plan's threat model apply as documented.

## Known Stubs

None — all strings are final and wired to the localization system. `ocrReviewEmptyDraftBanner` is intentionally a placeholder string communicating the OCR-not-yet-implemented status to users (D-13 per 18-CONTEXT.md); it is not a stub — it is the designed behavior for Phase 18. MOD-005 will replace it with empty-state copy when the OCR writer ships.

## Self-Check: PASSED

- [x] lib/l10n/app_en.arb — FOUND (modified, 889 keys, valid JSON)
- [x] lib/l10n/app_ja.arb — FOUND (modified, 889 keys, valid JSON)
- [x] lib/l10n/app_zh.arb — FOUND (modified, 889 keys, valid JSON)
- [x] lib/generated/app_localizations.dart — FOUND (contains String get transactionEditTitle)
- [x] lib/generated/app_localizations_en.dart — FOUND (contains 5 English getters)
- [x] lib/generated/app_localizations_ja.dart — FOUND (contains 5 Japanese getters)
- [x] lib/generated/app_localizations_zh.dart — FOUND (contains 5 Chinese getters)
- [x] Commit 0f89bd4 — FOUND (feat(18-03): add 5 i18n keys)
- [x] Commit 9450dff — FOUND (chore(18-03): regenerate app_localizations*.dart)
- [x] ARB parity test — PASSED (2/2)
