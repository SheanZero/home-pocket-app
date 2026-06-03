---
phase: 260603-lr5
plan: 01
subsystem: theme
tags: [palette, golden, adr]
dependency_graph:
  requires: []
  provides: [ADR-019, AppPalette-v1.6-tokens, golden-baseline-80]
  affects: [app_palette.dart, app_theme.dart, goldens-80]
tech_stack:
  added: []
  patterns: [ThemeExtension token re-value, golden re-baseline]
key_files:
  created:
    - docs/arch/03-adr/ADR-019_Palette_Selection_v1_6.md
  modified:
    - lib/core/theme/app_palette.dart
    - lib/core/theme/app_theme.dart
    - docs/arch/03-adr/ADR-000_INDEX.md
    - docs/arch/03-adr/ADR-018_Palette_Selection_v1_5.md
    - CLAUDE.md
    - test/core/theme/app_palette_test.dart
    - test/widget/theme_dark_mode_coverage_test.dart
    - test/golden/goldens/*.png (73 files)
    - test/widget/features/**/goldens/*.png (7 files)
decisions:
  - "ADR-019 桜餅×若葉 palette accepted; accentPrimary = leaf green #6FA36F"
  - "FAB stays sakura pink #D98CA0 — not spread to nav/daily"
  - "Joy = warm amber #C8841A / #A15C00 (Mauve fully reverted)"
  - "Background = warm cream #FBF7F4 family"
  - "Shared steel-blue #5B8AC4 and semantic colors unchanged"
  - "app_theme.dart hardcoded ADR-018 hex updated to AppPalette references (Rule 1 auto-fix)"
metrics:
  duration: ~20 minutes
  completed: 2026-06-03
  tasks_completed: 2
  files_changed: 87
---

# Phase 260603-lr5 Plan 01: 桜餅×若葉 Palette Re-value + Golden Re-baseline Summary

AppPalette ThemeExtension migrated from ADR-018 "Teal Clarity" to ADR-019 "Sakura Mochi × Wakaba" — leaf green primary, sakura pink FAB, warm amber joy, warm cream background — with all 80 golden masters re-baselined and full test suite green.

## Tasks Completed

| Task | Description | Commit | Status |
|------|-------------|--------|--------|
| 1 | Re-value AppPalette light+dark to 桜餅×若葉 + ADR-019 + docs | 0e37262e | Done |
| 2 | Re-baseline all 80 golden masters | d148f6e7 | Done |

## Deliverables

### lib/core/theme/app_palette.dart
- All ~60 light and ~60 dark tokens updated per ADR-019 mapping
- `accentPrimary`: `#0E9AA7` → `#6FA36F` (leaf green)
- `fabGradientEnd`: `#0E9AA7` → `#D98CA0` (sakura pink)
- `joy`/`joyText`: Mauve `#A586B0`/`#6B4877` → Amber `#C8841A`/`#A15C00`
- `background`: `#F8FCFD` → `#FBF7F4` (warm cream)
- `dark.background`: `#0C1719` → `#171210` (warm dark)
- `joyRoiBg`/`joyRoiBorder`: KEPT green (ROI semantic — per plan constraint)
- `happiness_ring_palette.dart`: NOT touched (out of scope)
- Docstrings updated: "ADR-018 Teal Clarity" → "ADR-019 Sakura Mochi × Wakaba"
- Comment "Accent primary (Teal)" → "(Leaf Green)"

### docs/arch/03-adr/ADR-019_Palette_Selection_v1_6.md
- New ADR recording v1.6 decision with full light+dark hex-per-role table
- Status: ✅ 已接受 (2026-06-03)
- Includes WCAG AA contrast verification notes

### docs/arch/03-adr/ADR-018_Palette_Selection_v1_5.md
- Append-only `## Update 2026-06-03` section noting supersession by ADR-019
- Original decision body untouched

### docs/arch/03-adr/ADR-000_INDEX.md
- ADR-019 entry added, statistics updated (17 → 18 ADRs, 12 → 13 accepted)
- ADR-018 review row updated to indicate superseded

### CLAUDE.md
- Added `## App Color Scheme (v1.6 — ADR-019 桜餅×若葉)` section after Amount Display Style
- Documents primary/FAB/joy/background/shared/semantics values and ADR-019 path

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] app_theme.dart had hardcoded ADR-018 hex values**
- **Found during:** Task 2 (full test suite run)
- **Issue:** `app_theme.dart` used hardcoded `const Color(0xFFF8FCFD)` etc. for `scaffoldBackgroundColor`, `appBarTheme.backgroundColor`, `cardTheme.color`, `borderDefault` — these did not update with the palette change. `app_theme_test.dart` caught the mismatch.
- **Fix:** Updated `AppTheme.light`/`AppTheme.dark` to reference `AppPalette.light.*` / `AppPalette.dark.*` tokens dynamically. Also updated `colorSchemeSeed` to leaf green `#6FA36F`.
- **Files modified:** `lib/core/theme/app_theme.dart`
- **Committed in:** Task 2 commit d148f6e7

**2. [Rule 1 - Bug] theme_dark_mode_coverage_test.dart had hardcoded ADR-018 dark background**
- **Found during:** Task 2 (full test suite run)
- **Issue:** Test asserted `const Color(0xFF0C1719)` (ADR-018 teal-dark background) but new dark background is `#171210`.
- **Fix:** Updated assertion to `Color(0xFF171210)` and updated test description from "ADR-018" to "ADR-019".
- **Files modified:** `test/widget/theme_dark_mode_coverage_test.dart`
- **Committed in:** Task 2 commit d148f6e7

**3. [Rule 1 - Bug] Widget golden tests in test/widget/ also needed re-baseline**
- **Found during:** Task 2 (full flutter test run)
- **Issue:** Plan said `flutter test test/golden/` but `test/widget/` also has golden tests (voice mic button, SmartKeyboard 6 variants) that fail due to color changes.
- **Fix:** Added `flutter test test/widget/...golden... --update-goldens` pass covering 7 additional PNGs.
- **Files modified:** 7 PNG goldens in `test/widget/features/`
- **Committed in:** Task 2 commit d148f6e7

## Verification Results

| Check | Result |
|-------|--------|
| `flutter analyze` | 4 pre-existing issues (2 in firebase build artifact, 2 `info` deprecations in unmodified `category_selection_screen.dart`). Zero issues in modified files. |
| `grep "A586B0" lib/core/theme/app_palette.dart` | 0 results — Mauve fully removed |
| `grep "0xFF6FA36F" lib/core/theme/app_palette.dart` | 2 results — leaf green present |
| `ls docs/arch/03-adr/ADR-019_*.md` | File exists |
| `grep "ADR-019" docs/arch/03-adr/ADR-000_INDEX.md` | 4 mentions |
| `flutter test test/golden/` | 73/73 passed |
| `flutter test` (full suite) | 2297/2297 passed |
| Golden master count (`test/golden/goldens/*.png`) | 73 masters |
| Golden master count (all, excl. failures/) | 80 masters (73 + 7 widget) |

## Known Stubs

None — all tokens are live values sourced from ADR-019 spec. No placeholder/empty values.

## Pre-existing Advisory (Not Fixed)

Phase 34 WR-01: dark `list_transaction_tile` golden zh/en variants render the tile's internal date in `ja` (locale param not threaded into `ListTransactionTile`). Cosmetic only. Accepted-deferred per plan constraint.

## Self-Check: PASSED

- lib/core/theme/app_palette.dart: FOUND
- docs/arch/03-adr/ADR-019_Palette_Selection_v1_6.md: FOUND
- docs/arch/03-adr/ADR-000_INDEX.md: FOUND (ADR-019 entry present)
- CLAUDE.md: FOUND (ADR-019 palette section present)
- Commits 0e37262e and d148f6e7: FOUND in git log
- flutter test 2297/2297: PASSED
