---
phase: quick-260613-ohz
plan: 01
subsystem: accounting / currency-picker / i18n
status: complete
tags: [currency-selector, i18n, arb, goldens, ui-cleanup]
requires:
  - "CurrencySelectorSheet (Phase 42-06) with _localizedCommonZoneName resolver"
  - "Common-zone currencyName* ARB keys (Phase 42-06)"
provides:
  - "Currency rows without the bold ISO-code column (flag -> grey symbol/code -> name)"
  - "currencyNameChf..currencyNamePln localized for all 19 long-tail currencies (ja/zh/en)"
affects:
  - "test/golden/goldens/currency_selector_sheet_*.png (6 baselines re-baselined)"
tech-stack:
  added: []
  patterns:
    - "ARB three-file sync + flutter gen-l10n for new localized strings"
    - "Symbol cell ISO-code fallback makes a separate code column redundant"
key-files:
  created: []
  modified:
    - lib/features/accounting/presentation/widgets/currency_selector_sheet.dart
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/l10n/app_en.arb
    - test/golden/goldens/currency_selector_sheet_ja.png
    - test/golden/goldens/currency_selector_sheet_zh.png
    - test/golden/goldens/currency_selector_sheet_en.png
    - test/golden/goldens/currency_selector_sheet_dark_ja.png
    - test/golden/goldens/currency_selector_sheet_dark_zh.png
    - test/golden/goldens/currency_selector_sheet_dark_en.png
decisions:
  - "lib/generated/* is gitignored — regenerated l10n NOT committed; gen-l10n run locally and verified, build re-generates"
  - "Re-baselined exactly the 6 currency-selector goldens after confirming diffs (en 8.12%, ja/zh 3.84-4.23%) match column removal + name localization; no unrelated goldens touched"
metrics:
  duration: ~9min
  completed: 2026-06-13
---

# Quick Task 260613-ohz: Currency Picker Dedup + Long-tail l10n Summary

Removed the redundant bold ISO-code column from `CurrencySelectorSheet` rows and localized all 19 long-tail currency names (CHF..PLN) for zh/ja/en via ARB, with English retained as the final fallback.

## What Changed

### Change 1 — Bold ISO-code column removed
- Deleted the `SizedBox(width: 44)` cell wrapping `Text(entry.code, FontWeight.w700)` and its preceding `const SizedBox(width: 8)` spacer in `_CurrencyRow.build`.
- Row layout is now `flag (28) → 4dp → grey symbol/code (40) → 4dp → name (Expanded) → check icon`. The grey symbol cell already falls back to the ISO code for symbol-less currencies (`NumberFormatter.formatCurrency(...).replaceAll(...)`), so long-tail codes are still visible.
- Untouched: `isSelected` accent logic, `showFlag`, the row `ValueKey('currency-row-<code>')`, symbol/name derivation. Doc comments at class level and on `_CurrencyRow` updated to the new `flag + symbol/code + name` format.

### Change 2 — 19 long-tail currency names localized
- Added 19 keys (`currencyNameChf` … `currencyNamePln`) to all three ARB files in sync, inserted right after `currencyNameCad` and before `conversionPreviewRateRow`, mirroring the existing key + `@`-metadata style, tagged `(quick 260613-ohz)`.
- Extended `_localizedCommonZoneName(S s, String code)` from 11 to 30 cases (11 common + 19 long-tail); `default: return null` preserved so any unmapped code still falls back to `entry.englishName` via `localizedName ?? entry.englishName`.
- Ran `flutter gen-l10n`; generated getters `currencyNameChf`..`currencyNamePln` confirmed present in `lib/generated/app_localizations.dart`.

### Change 3 — Goldens re-baselined
- The 6 `currency_selector_sheet_*` goldens regenerated on macOS via `flutter test --update-goldens`. Diffs inspected before updating (en 8.12% from full-list left-shift, ja/zh 3.84–4.23%) — consistent with column removal + localized names, not a regression. Only these 6 files changed.

## Verification

- `flutter analyze` — **0 issues** (full project).
- `flutter test` — **2819 tests passed**, 0 failures (architecture/CJK-scan tests and `manual_one_step_foreign_triple_test.dart` ran; the latter selects USD by row key, unaffected by the column removal).
- ARB: all three files parse as valid JSON; each contains exactly the 19 new keys (verified by the plan's automated check → `OK`).
- Generated getters present; `FontWeight.w700` count in the widget = 0; resolver covers Chf/Pln.

## Deviations from Plan

**lib/generated NOT committed (gitignored).** Task 2's plan implied committing regenerated l10n alongside the widget. `lib/generated` is in `.gitignore`, so `git add` rejected it. Committed the widget alone; generated files are produced by the build. No functional impact — getters verified present locally and the full suite (which uses them) is green.

Otherwise the plan executed as written.

## Commits

- `471da272` feat(260613-ohz): add 19 long-tail currency name keys to all ARB files
- `5eeaffd5` feat(260613-ohz): drop bold ISO-code column + extend currency name resolver
- `72b2d788` test(260613-ohz): re-baseline currency-selector goldens (column removal + zh/ja names)

## Self-Check: PASSED
