# Phase 5: MEDIUM Fixes - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `05-CONTEXT.md`; this log preserves the alternatives considered.

**Date:** 2026-04-27  
**Phase:** 05-medium-fixes  
**Areas discussed:** CategoryService split, Hardcoded CJK boundary, ARB key strategy, MOD-009 cleanup boundary, Money display enforcement

---

## CategoryService Split

| Question | Option | Description | Selected |
|---|---|---|---|
| Naming collision | A | Rename only infrastructure helper to `CategoryLocaleService`; keep application business `CategoryService`. | yes |
| Naming collision | B | Rename application business service too. | |
| Naming collision | C | Consolidate both services. | |
| File path | A | `git mv` infrastructure file to `category_locale_service.dart`; update imports; no compatibility layer. | yes |
| File path | B | Keep deprecated re-export compatibility layer. | |
| File path | C | Rename class only. | |
| Static category map | A | Do not refactor map. | |
| Static category map | B | Add map/ARB consistency test. | yes |
| Static category map | C | Convert category translation to ARB-driven implementation now. | |
| Regression lock | A | Assert old import path is gone and duplicate `CategoryService` classes no longer coexist. | |
| Regression lock | B | Rely on `flutter analyze`. | |
| Regression lock | C | Add stricter architecture test banning future cross-layer same-name services. | yes |

**User's choice:** 1A, 2A, 3B, 4C  
**Notes:** Full ARB-driven category localization remains deferred to `FUTURE-ARCH-01`.

---

## Hardcoded CJK Boundary

| Question | Option | Description | Selected |
|---|---|---|---|
| Extraction scope | A | Only user-visible UI copy. | yes |
| Extraction scope | B | Remove every CJK string from `lib/`. | |
| Extraction scope | C | Only presentation-layer strings. | |
| Allowed CJK | A | Whitelist NLP dictionaries, merchant seed data, formatter outputs, category map, and comment examples. | yes |
| Allowed CJK | B | Only comments and tests may keep CJK. | |
| Allowed CJK | C | Judge each file manually. | |
| Enforcement | A | Commit scanner/architecture test. | yes |
| Enforcement | B | Use `rg` manually and summarize. | |
| Enforcement | C | Enable CI blocking immediately. | |
| Chart labels | A | Localize chart labels and keep formatter-internal outputs. | yes |
| Chart labels | B | Keep chart short labels hardcoded for now. | |
| Chart labels | C | Convert chart labels to numeric/English-only. | |

**User's choice:** 1A, 2A, 3A, 4A  
**Notes:** Scanner must avoid false positives on intentional language data.

---

## ARB Key Strategy

| Question | Option | Description | Selected |
|---|---|---|---|
| Key naming | A | Reuse existing names and add narrow missing keys. | |
| Key naming | B | Normalize relevant key names in this phase. | yes |
| Key naming | C | Name keys by source file path. | |
| Unused keys | A | Audit first, then delete proven-unused non-stub keys. | yes |
| Unused keys | B | Do not delete any keys in this phase. | |
| Unused keys | C | Delete any unreferenced key immediately. | |
| OCR placeholders | A | Preserve OCR keys and add/verify metadata. | yes |
| OCR placeholders | B | Preserve keys without metadata. | |
| OCR placeholders | C | Delete if unused. | |
| ARB parity | A | Add parity test/script and run `flutter gen-l10n`. | yes |
| ARB parity | B | Rely only on `flutter gen-l10n`. | |
| ARB parity | C | Export CSV for manual review. | |

**User's choice:** 1B, 2A, 3A, 4A  
**Notes:** Planner should account for call-site churn caused by renamed ARB getters.

---

## MOD-009 Cleanup Boundary

| Question | Option | Description | Selected |
|---|---|---|---|
| Deprecated reference standard | A | Clean deprecated `lib/` references only and keep active voice code. | yes |
| Deprecated reference standard | B | Delete all MOD-009-related voice code. | |
| Deprecated reference standard | C | Clean imports only. | |
| Historical docs | A | Leave docs untouched until Phase 7. | |
| Historical docs | B | Clean all MOD-009 docs now. | yes |
| Historical docs | C | Only update `ARCH-000_INDEX.md`. | |
| Active shared-code comments | A | Rewrite old module-number comments as capability descriptions. | yes |
| Active shared-code comments | B | Delete those comments. | |
| Active shared-code comments | C | Keep comments unchanged. | |
| Verification | A | Add `lib/`-only scan assertion. | yes |
| Verification | B | Run `rg` manually once. | |
| Verification | C | Rely on Phase 8 re-audit. | |

**User's choice:** 1A, 2B, 3A, 4A  
**Notes:** Option 2B conflicts with fixed Phase 5 scope and `PROJECT.md` documentation-sweep deferral. Captured as a deferred idea for Phase 7; Phase 5 cleans live `lib/` references only.

---

## Money Display Enforcement

| Question | Option | Description | Selected |
|---|---|---|---|
| Monetary-display scope | A | Only real monetary values. | yes |
| Monetary-display scope | B | Every UI occurrence of yen/currency-looking text. | |
| Monetary-display scope | C | Only existing `AmountDisplay` users. | |
| Style rule | A | Use `AppTextStyles.amount*` or `copyWith`. | yes |
| Style rule | B | Any `TextStyle` is okay if `tabularFigures` is manually added. | |
| Style rule | C | Only check core widgets. | |
| Tests | A | Test touched money widget usage points. | yes |
| Tests | B | Only test `AppTextStyles` itself. | |
| Tests | C | Manual visual check only. | |
| Formatter/style relation | A | Use `FormatterService` for formatting and `AppTextStyles.amount*` for style. | yes |
| Formatter/style relation | B | `FormatterService` alone is enough. | |
| Formatter/style relation | C | `AppTextStyles` alone is enough. | |

**User's choice:** 1A, 2A, 3A, 4A  
**Notes:** Formatting and styling are separate requirements; neither satisfies the other.

---

## the agent's Discretion

- Exact plan sequencing and task split.
- Exact scanner/test implementation details.
- Exact normalized ARB key names, constrained by the decisions in `05-CONTEXT.md`.

## Deferred Ideas

- Drive `CategoryLocaleService` from ARB files and eliminate the static category map in `FUTURE-ARCH-01`.
- Clean historical MOD-009 documentation during Phase 7 Documentation Sweep.
