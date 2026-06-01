---
phase: 34-golden-re-baseline-verification
plan: "03"
subsystem: color-audit
tags: [color-audit, d-03a, palette-migration, adr-018, test-fixtures, docs-superseded]
dependency_graph:
  requires: [34-02]
  provides: [d-03a-audit-closed]
  affects: [test/widget/features, test/features, docs/design]
tech_stack:
  added: []
  patterns: [AppPalette.light.daily, AppPalette.light.joy, AppPalette.light.error]
key_files:
  created: []
  modified:
    - test/widget/features/home/presentation/widgets/home_transaction_tile_test.dart
    - test/widget/features/list/list_transaction_tile_test.dart
    - test/features/home/presentation/widgets/home_transaction_tile_test.dart
    - docs/design/README.md
    - docs/design/design-tokens.json
    - docs/design/flutter_color_mapping.dart
    - docs/design/design-system.md
    - docs/design/screen-inventory.md
decisions:
  - "Category.color '#E85A4F' string fixtures are inert data (not Color() literals) — left unchanged"
  - "test/features/home/presentation/widgets/home_transaction_tile_test.dart was an additional stale hit not in RESEARCH.md; treated as actionable per D-03a Rule 3"
  - "docs/design/ files annotated as superseded (Approach A) rather than updated, preserving pre-v1.5 design history"
  - "4 pre-existing flutter analyze info issues (category_selection_screen.dart deprecated_member_use + build/iOS Firebase warning) are out-of-scope per Scope Boundary — not introduced by this plan"
metrics:
  duration: "~15 minutes"
  completed: "2026-06-01T13:49:58Z"
  tasks_completed: 2
  files_changed: 8
---

# Phase 34 Plan 03: D-03a Comprehensive Audit Summary

D-03a comprehensive audit closed. Stale `Color(0xFF5A9CC8)` / `Color(0xFF47B88A)` / `Color(0xFFE85A4F)` literals removed from 3 test files; docs/design/ pre-v1.5 coral-palette files annotated as superseded by ADR-018; both ROADMAP success-criteria greps return empty output.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | D-03a audit + stale Color literal remediation in test files | e83d10f5 | 3 test files |
| 2 | Annotate docs/design/ files as superseded by ADR-018 + final greps | cc846221 | 5 docs files |

## D-03a Full Audit Log

### Primary old-palette hex sweep results (outside lib/core/theme/)

**ACTIONABLE — Color() literal in Dart code (3 files, now fixed):**

| File | Hit | Action |
|------|-----|--------|
| `test/widget/features/home/presentation/widgets/home_transaction_tile_test.dart` | `Color(0xFF5A9CC8)` ×3, `Color(0xFF47B88A)` ×1 | Fixed → `AppPalette.light.daily` / `.joy` |
| `test/widget/features/list/list_transaction_tile_test.dart` | `Color(0xFF5A9CC8)` ×2 | Fixed → `AppPalette.light.daily` |
| `test/features/home/presentation/widgets/home_transaction_tile_test.dart` | `Color(0xFF5A9CC8)` ×2, `Color(0xFF47B88A)` ×3, `Color(0xFFE85A4F)` ×1 | Fixed → `.daily` / `.joy` / `.error` (extra file, not in RESEARCH.md — Rule 3 auto-fix) |

**INERT DATA — Category.color string field (verified, not Color() literal):**

| File | Hit | Classification |
|------|-----|----------------|
| `test/widget/features/accounting/presentation/screens/category_selection_screen_test.dart` | `color: '#E85A4F'` ×3 | Inert — string field in Category model constructor, not `Color()` |
| `test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart` | `color: '#E85A4F'` ×2 | Inert |
| `test/widget/features/accounting/presentation/widgets/transaction_details_form_update_amount_test.dart` | `color: '#E85A4F'` ×1 | Inert |
| `test/widget/features/accounting/presentation/widgets/transaction_details_form_test.dart` | `color: '#E85A4F'` ×3 | Inert |
| `test/widget/features/list/list_category_filter_sheet_test.dart` | `color: '#E85A4F'` ×3 | Inert |
| `test/golden/list_category_filter_sheet_golden_test.dart` | `color: '#E85A4F'` ×3 | Inert |
| `test/integration/entry_path_stamping_test.dart` | `color: '#47B88A'` ×1 | Inert |
| `test/integration/features/accounting/manual_save_entry_source_test.dart` | `color: '#47B88A'` ×2 | Inert |
| `test/integration/features/accounting/voice_save_entry_source_test.dart` | `color: '#47B88A'` ×2 | Inert |

Verification: `CategoryLocaleService` maps category IDs to icon/color through ARB-mapped category names, not through the `Category.color` stored hex string. The `D-03a ROADMAP grep (Color(0x)` does not catch these string literals — confirmed correct behavior.

**STALE DOCS — docs/design/ (annotated as superseded):**

| File | Old hex references | Action |
|------|-------------------|--------|
| `docs/design/flutter_color_mapping.dart` | E85A4F, 5A9CC8, 47B88A, 8A9178, D4845A, F08070, + dark set | Added file-level SUPERSEDED comment |
| `docs/design/design-tokens.json` | Full pre-v1.5 token set | Added `_superseded_note` top-level key |
| `docs/design/README.md` | E85A4F, 5A9CC8, 47B88A | Added superseded notice block at top |
| `docs/design/design-system.md` | E85A4F, 5A9CC8, 47B88A, 8A9178, dark set | Added superseded notice block at top |
| `docs/design/screen-inventory.md` | E85A4F, 5A9CC8, 47B88A, 8A9178 | Added superseded notice block at top |

**OUT-OF-SCOPE hits (historical/planning docs — not actionable):**

`docs/plans/`, `docs/superpowers/plans/`, `docs/worklog/`, `docs/arch/03-adr/ADR-018_Palette_Selection_v1_5.md`, `docs/dev/01-presentation.md`, `docs/thinking/teamwork.md` — all historical/planning documents or the ADR itself referencing old palette for context. Not actionable.

### Extended old-palette sweep (dark backgrounds: 1A1D27, 252836, etc.)

All hits are in `docs/design/` (covered by superseded annotation) or `test/widget/features/home/presentation/widgets/painter/happiness_rings_painter_test.dart:223` (`Color(0xFF353845)` as dark track color — this is in `test/` not `lib/features/lib/application/lib/shared/` and is a deliberate dark-theme color, not a stale pre-migration value. The SC2-b grep targets `lib/features/` only).

No actionable hits in `lib/features/`, `lib/application/`, or `lib/shared/`.

### Stale ARB vocabulary audit (test/ and docs/)

No `生存|灵魂|魂|ソウル|Survival|Soul` hits in `lib/l10n/*.arb` (ROADMAP SC2-a). Occurrences in `test/` files are internal fixture method names (`_makeSurvivalSeedTx`, `totalSoulTx`) — not ARB string keys and not user-facing i18n vocabulary.

## ROADMAP Success-Criteria Greps (Evidence)

```
# SC2-a: vocabulary audit
grep -rn '生存|灵魂|魂|ソウル|Survival|Soul' lib/l10n/*.arb
→ (EMPTY — PASS)

# SC2-b: color literal audit
grep -rn 'Color(0x|Color(0X' lib/features/ lib/application/ lib/shared/
→ (EMPTY — PASS)
```

## Verification

- `grep -rn "Color(0xFF5A9CC8)|Color(0xFF47B88A)" test/ --include="*.dart"` → 0 hits
- `flutter test test/widget/features/home/presentation/widgets/home_transaction_tile_test.dart test/widget/features/list/list_transaction_tile_test.dart test/features/home/presentation/widgets/home_transaction_tile_test.dart` → 14/14 passed
- `flutter analyze test/widget/features/home/presentation/widgets/home_transaction_tile_test.dart test/widget/features/list/list_transaction_tile_test.dart test/features/home/presentation/widgets/home_transaction_tile_test.dart` → 0 issues

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Remediation] Additional stale Color literal file not in RESEARCH.md**
- **Found during:** Task 1 audit grep
- **Issue:** `test/features/home/presentation/widgets/home_transaction_tile_test.dart` had `Color(0xFF5A9CC8)` ×2, `Color(0xFF47B88A)` ×3, `Color(0xFFE85A4F)` ×1 — not listed in RESEARCH.md's Known current stale hits table
- **Fix:** Replaced all 6 literals with `AppPalette.light.daily`, `.joy`, `.error` respectively; dropped `const` wrappers where needed (AppPalette fields are runtime final, not compile-time const)
- **Files modified:** `test/features/home/presentation/widgets/home_transaction_tile_test.dart`
- **Commit:** e83d10f5

**2. [Rule 1 - Bug] AppPalette.light.* cannot be used in `const` expressions**
- **Found during:** Task 1 test file editing
- **Issue:** `AppPalette.light.daily` is a `final Color` field on a `const`-constructed instance, but Dart's const evaluation does not allow property access on const objects when the property is `final` (not `const`). Using it in `const MaterialApp(...)` blocks caused `const_eval_property_access` analyzer errors.
- **Fix:** Changed `const MaterialApp(...)` to `MaterialApp(...)` and `const joyColor = ...` to `final joyColor = ...` in all affected test methods.
- **Files modified:** `test/widget/features/home/presentation/widgets/home_transaction_tile_test.dart`, `test/features/home/presentation/widgets/home_transaction_tile_test.dart`
- **Commit:** e83d10f5

## Known Stubs

None — this plan performs audit and annotation only. No production code stubs.

## Threat Flags

None — this plan modifies test fixture color parameters and design documentation. No new attack surface.

## Self-Check: PASSED

- [x] `test/widget/features/home/presentation/widgets/home_transaction_tile_test.dart` exists (Task 1)
- [x] `test/widget/features/list/list_transaction_tile_test.dart` exists (Task 1)
- [x] `test/features/home/presentation/widgets/home_transaction_tile_test.dart` exists (Task 1)
- [x] `docs/design/flutter_color_mapping.dart` exists with SUPERSEDED comment (Task 2)
- [x] `docs/design/design-tokens.json` exists with `_superseded_note` key (Task 2)
- [x] Commit e83d10f5 exists (Task 1)
- [x] Commit cc846221 exists (Task 2)
- [x] Both ROADMAP SC2 greps return empty output
- [x] `grep -rn "Color(0xFF5A9CC8)|Color(0xFF47B88A)" test/ --include="*.dart"` returns 0 hits
