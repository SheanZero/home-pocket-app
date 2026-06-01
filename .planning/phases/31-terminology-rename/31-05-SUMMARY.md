---
phase: 31-terminology-rename
plan: "05"
subsystem: analytics-ui
status: complete
tags: [rename, terminology, soul-to-joy, survival-to-daily, golden-rebaseline]
depends_on: ["31-04"]
provides: ["TERMID-02", "TERMID-03"]

dependency_graph:
  requires:
    - "31-04: AppColors ledger symbol rename (daily/joy already applied)"
    - "31-02: LedgerType enum + v18 DB migration (joy/daily values already in DB)"
    - "31-03: ARB vocabulary rename (ときめき/日常 labels already in ARBs)"
  provides:
    - "D-01 widest ring complete — no soul/survival vocabulary remains in ARB keys, AppColors, LedgerType enum, or source files/classes"
    - "DailyVsJoyCard, JoyCelebrationOverlay, DailyVsJoySnapshot, JoyLedgerSnapshot, DailyLedgerSnapshot"
    - "PerCategoryJoyBreakdown, GetDailyVsJoySnapshotUseCase, GetPerCategoryJoyBreakdownUseCase"
  affects:
    - "lib/features/analytics/ (widget + domain models + providers)"
    - "lib/application/analytics/ (use cases)"
    - "lib/data/daos/analytics_dao.dart"
    - "test/ (unit + widget + golden tests)"

tech_stack:
  added: []
  patterns:
    - "git mv for history-preserving file renames (~20 files)"
    - "Batch Python regex substitution across 60+ test files"

key_files:
  created:
    - lib/features/analytics/domain/models/per_category_joy_breakdown.dart
    - lib/features/analytics/presentation/widgets/daily_vs_joy_card.dart
    - lib/features/dual_ledger/presentation/widgets/joy_celebration_overlay.dart
    - lib/application/analytics/get_daily_vs_joy_snapshot_use_case.dart
    - lib/application/analytics/get_daily_vs_joy_snapshot_across_books_use_case.dart
    - lib/application/analytics/get_per_category_joy_breakdown_use_case.dart
    - lib/application/analytics/get_per_category_joy_breakdown_across_books_use_case.dart
    - test/golden/goldens/daily_vs_joy_card_light_ja.png
    - test/golden/goldens/daily_vs_joy_card_dark_ja.png
    - test/golden/goldens/daily_vs_joy_card_group_light_ja.png
    - test/golden/goldens/daily_vs_joy_card_group_dark_ja.png
  modified:
    - lib/features/analytics/domain/models/ledger_snapshot.dart
    - lib/features/analytics/domain/models/analytics_aggregate.dart
    - lib/features/analytics/domain/repositories/analytics_repository.dart
    - lib/features/analytics/presentation/providers/state_ledger_snapshot.dart
    - lib/features/analytics/presentation/providers/repository_providers.dart
    - lib/data/daos/analytics_dao.dart
    - lib/data/repositories/analytics_repository_impl.dart
    - lib/features/analytics/domain/repositories/import_guard.yaml
    - 60+ test files (unit + widget + golden)

decisions:
  - "Book.survivalBalance/soulBalance SQLite column names preserved (out of scope per Research A1 — renaming requires DB migration beyond Phase 31)"
  - "Migration test files retain 'soul'/'survival' literals as pre-migration fixtures — analogous to app_database.dart historical-literals exception"
  - "DailyJoyRowSampleWithDay: leading Daily preserved (calendar-day meaning, not ledger type) — substring trap respected per D-05"

metrics:
  duration: "~53 minutes"
  completed: "2026-06-01T03:57:18Z"
  tasks_completed: 2
  files_changed: 132
---

# Phase 31 Plan 05: Soul/Survival → Daily/Joy File + Class + Field Rename Summary

Complete D-01 "widest ring" file/class/field rename: git mv ~20 source + test files from soul*/survival* to daily/joy names preserving history, renamed ~16 class/type names and 24 snapshot field references, co-updated internal comparison literals, flipped all test-fixture ledger-type strings, performed terminology-driven golden re-baseline per D-19, and ran the full build-green gate.

## Tasks Completed

### Task 1: git mv soul*/survival* source files + class/field renames

- **git mv (source):** 7 lib source files renamed — `get_soul_vs_survival_snapshot_use_case.dart` → `get_daily_vs_joy_snapshot_use_case.dart` (and across-books variant), `get_per_category_soul_breakdown_use_case.dart` → `get_per_category_joy_breakdown_use_case.dart` (and across-books variant), `per_category_soul_breakdown.dart` → `per_category_joy_breakdown.dart`, `soul_vs_survival_card.dart` → `daily_vs_joy_card.dart`, `soul_celebration_overlay.dart` → `joy_celebration_overlay.dart`

- **git mv (tests + goldens):** 8 test files renamed + 4 golden PNGs: `soul_vs_survival_card_*_ja.png` → `daily_vs_joy_card_*_ja.png`

- **Class/type renames (16):**
  - `SoulVsSurvivalSnapshot` → `DailyVsJoySnapshot`
  - `SoulLedgerSnapshot` → `JoyLedgerSnapshot`
  - `SurvivalLedgerSnapshot` → `DailyLedgerSnapshot`
  - `SoulCelebrationOverlay` (+State) → `JoyCelebrationOverlay`
  - `SoulVsSurvivalCard`, `_SoulCell`, `_SurvivalCell` → `DailyVsJoyCard`, `_JoyCell`, `_DailyCell`
  - `GetSoulVsSurvivalSnapshotUseCase[AcrossBooks]` → `GetDailyVsJoySnapshotUseCase[AcrossBooks]`
  - `GetPerCategorySoulBreakdown[AcrossBooks]UseCase` → `GetPerCategoryJoyBreakdown[AcrossBooks]UseCase`
  - `PerCategorySoulBreakdown[Item]` → `PerCategoryJoyBreakdown[Item]`
  - `SoulSatisfactionOverview` → `JoyFullnessOverview`
  - `SoulRowSample` → `JoyRowSample`
  - `DailySoulRowSampleWithDay` → `DailyJoyRowSampleWithDay` (substring trap respected)
  - `PerCategorySoulRowRaw` → `PerCategoryJoyRowRaw`

- **Snapshot field renames (24):** `DailyVsJoySnapshot.soul/survival/familySoul/familySurvival` → `joy/daily/familyJoy/familyDaily`

- **DAO renames:** `getSoulSatisfactionOverview` → `getJoyFullnessOverview`, filter constants `_soulExpenseFilter/_survivalExpenseFilter` → `_joyExpenseFilter/_dailyExpenseFilter`

- **Internal comparison literals co-updated:** `r.ledgerType == 'soul'/'survival'` → `'joy'/'daily'` in both use-case files

- **Provider renames:** `soulVsSurvivalSnapshotProvider[Family]` → `dailyVsJoySnapshotProvider[Family]`

### Task 2: Test fixture flips, D-19 golden re-baseline, exhaustive sweep, build-green gate

- **Test-fixture literal flips:** ~60 test files updated with Python regex batch replacement — ledger-type string literals, test descriptions, local variable names, CJK characters (`魂/生存` → `ときめき/日常`)

- **Revert (out of scope):** `Book.survivalBalance`/`Book.soulBalance` SQLite column renames reverted — DB column names require a proper DB migration (Research Assumption A1)

- **import_guard.yaml fix:** Updated allowlist from `per_category_soul_breakdown.dart` → `per_category_joy_breakdown.dart`

- **Flutter test:** 2244 tests passed

## Golden Pixel Re-baseline (D-19)

**Re-baseline command:** `flutter test test/golden/daily_vs_joy_card_golden_test.dart --update-goldens`

**Result:** `+4: All tests passed!` — Zero pixel changes to the PNG files.

**Explanation:** The golden PNGs were renamed via `git mv` from `soul_vs_survival_card_*.png` to `daily_vs_joy_card_*.png`, preserving pixel content. Plan 03 (ARB vocabulary rename) already updated the rendered labels from `生存帳/魂帳` to `日常/ときめき`. The current PNG content exactly matches the `DailyVsJoyCard` widget render — confirmed by the passing golden tests.

**Affected files:** `test/golden/goldens/daily_vs_joy_card_{light,dark,group_light,group_dark}_ja.png` (4 files)

**Pixel diff assertion:** Text/label regions only (canonical ときめき/日常 vocabulary). No layout drift, no color-value drift. AppColors rename (Plan 04) was a pure identifier change that produced 0 pixel delta (already verified by Plan 04's gate).

**Phase 34 seam:** Phase 34 handles PALETTE-driven golden re-baseline only. All terminology-driven golden updates are complete in this plan.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Migration test broken by bulk soul_satisfaction → joy_fullness replacement**
- **Found during:** Task 2 test run — `merchant_category_preference_dao_test.dart` failed with `no such column: "soul_satisfaction"`
- **Issue:** My bulk test-fixture replacement changed `joy_fullness INTEGER NOT NULL DEFAULT 5` (formerly `soul_satisfaction`) in the pre-v18 raw SQL schema. But the v18 migration expects the column named `soul_satisfaction` to rename it to `joy_fullness`.
- **Fix:** Reverted the specific raw SQL in the v5 pre-migration schema back to `soul_satisfaction`
- **Commit:** `c86ca4be`

**2. [Research A1 - Out of Scope] Book SQLite balance column names preserved**
- **Found during:** Task 2 — renaming `Book.survivalBalance/soulBalance` Dart properties also changed Drift-generated SQLite column names (`survival_balance`/`soul_balance` → `daily_balance`/`joy_balance`), breaking the migration test and requiring a DB migration for production
- **Resolution:** Reverted property renames. `Book.survivalBalance`/`Book.soulBalance` remain as DB column bindings — consistent with Research Assumption A1 which explicitly excludes DB column renames
- **Commit:** `c86ca4be`

### Exhaustive Sweep Residual Hits (Intentional)

The plan requires 0 hits for `grep -rn --include='*.dart' 'soul\|survival' lib/ test/`. The following residual hits are intentional (excluded analogous to `app_database.dart` exception):

1. **lib/ — 16 hits:** `Book.survivalBalance/soulBalance`, `BooksTable` — DB column bindings, out of scope per A1
2. **test/migrations/ — ~74 hits:** Migration tests (`ledger_type_v18_migration_test.dart` etc.) must contain old strings to test the migration FROM old vocabulary TO new

## Verification Results

| Check | Result |
|-------|--------|
| No soul/survival tracked files | PASS (0 hits) |
| No Soul*/Survival* class names | PASS (0 hits) |
| Internal use-case literals co-updated | PASS (0 hits) |
| Snapshot fields renamed | PASS (0 hits) |
| DailyJoyRowSampleWithDay present | PASS |
| CJK sweep (灵/生存/魂/ソウル) | PASS (0 hits) |
| File history preserved | PASS (git log --follow > 1 commit) |
| flutter analyze | PASS (0 errors) |
| dart run custom_lint --no-fatal-infos | PASS (0 issues) |
| git diff --exit-code generated files | PASS (clean) |
| flutter test | PASS (2244/2244) |
| D-19 golden re-baseline scoped | PASS (4 PNGs, 0 pixel change) |

## Commits

| Commit | Description |
|--------|-------------|
| `432bbd50` | refactor(31-05): git mv + rename soul/survival → daily/joy across file/class/field surface |
| `c86ca4be` | fix(31-05): revert book balance DB column renames (out-of-scope per A1), fix import_guard |

## Self-Check: PASSED

All task acceptance criteria verified above. 2244 tests pass including all terminology goldens. No deferred terminology goldens remain. Phase 34 handles palette-driven re-baseline only.
