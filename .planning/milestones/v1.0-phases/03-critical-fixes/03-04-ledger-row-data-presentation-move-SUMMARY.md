---
phase: "03-critical-fixes"
plan: "04"
subsystem: "home-feature-presentation"
tags:
  - ledger_row_data
  - layer_violation
  - presentation_models_convention
  - LV-022
dependency_graph:
  requires: []
  provides:
    - "lib/features/home/presentation/models/ledger_row_data.dart (LV-022 closed)"
    - "D-12 convention established by example"
  affects:
    - "lib/features/home/presentation/screens/home_screen.dart"
    - "lib/features/home/presentation/widgets/ledger_comparison_section.dart"
    - "test/features/home/presentation/widgets/ledger_comparison_section_test.dart"
tech_stack:
  added: []
  patterns:
    - "dart:ui view-models belong in features/<f>/presentation/models/ (D-12)"
    - "Pre-move characterization test written at original path before git mv"
key_files:
  created:
    - "lib/features/home/presentation/models/ledger_row_data.dart"
    - "lib/features/home/presentation/models/ledger_row_data.freezed.dart"
    - "test/features/home/presentation/models/ledger_row_data_test.dart"
    - "doc/worklog/20260426_1609_phase3_plan04_ledger_row_data_presentation_move.md"
  modified:
    - "lib/features/home/presentation/screens/home_screen.dart"
    - "lib/features/home/presentation/widgets/ledger_comparison_section.dart"
    - "test/features/home/presentation/widgets/ledger_comparison_section_test.dart"
    - ".planning/audit/issues.json"
decisions:
  - "D-11: Move ledger_row_data.dart to presentation/models/ — it holds 10 Color fields and is a view-model by nature"
  - "D-12 established by example: dart:ui view-models belong in features/<f>/presentation/models/"
  - "Coverage gate false-positive for Freezed annotation-only files accepted as known Dart/lcov tool limitation"
metrics:
  duration: "~30 minutes"
  completed: "2026-04-26"
  tasks_completed: 2
  tasks_total: 2
  files_changed: 10
requirements:
  - CRIT-01
  - CRIT-04
  - CRIT-05
  - CRIT-06
---

# Phase 3 Plan 04: ledger_row_data 移至 presentation/models (LV-022) Summary

**One-liner:** LedgerRowData view-model (10 Color fields + formatted strings) relocated from domain/models/ to presentation/models/ via git mv with R100 rename score, characterization tests, and LV-022 closed in issues.json.

## What Was Built

Plan 03-04 closed LV-022 by moving `lib/features/home/domain/models/ledger_row_data.dart` to `lib/features/home/presentation/models/ledger_row_data.dart`. The file holds 10 `Color` fields and formatted display strings — a presentation view-model by nature, not a domain entity.

The move was executed in two atomic commits:

1. **Task 0 (pre-move characterization test):** A dedicated unit test was written at the CURRENT (domain/) path before any move occurred. The test asserts constructor byte-equivalence and 10 individual `copyWith` micro-cases (one per field), locking the model's observable shape against accidental edits during the move.

2. **Task 1 (atomic move):** `git mv` source + test together, `git rm` stale `.freezed.dart`, `build_runner` regen at new location, 4 import updates (3 callers + the moved test file), all in a single commit. Rename scores: R100 for source, R099 for test.

## Commits

| SHA | Message | Task |
|-----|---------|------|
| `d8b9144` | `test(03-04): add ledger_row_data characterization test (pre-move, LV-022)` | Task 0 |
| `c549794` | `refactor(03-04): move ledger_row_data to presentation/models (LV-022, D-11/D-12)` | Task 1 |
| `a423e7f` | `chore(03-04): close LV-022 in issues.json (ledger_row_data moved to presentation)` | Task 1 follow-up |
| `6c7f90f` | `docs(03-04): add worklog for ledger_row_data presentation move (LV-022)` | Worklog |

## Verification Results

| Gate | Result |
|------|--------|
| `flutter analyze --no-fatal-infos` | PASS (exit 0) |
| `dart run custom_lint` (LV-022 specific) | PASS (no dart:ui error for domain/; other LV issues are Plan 03-01 scope) |
| Characterization test at new path (13 tests) | PASS (all GREEN) |
| `ledger_comparison_section_test.dart` (5 tests) | PASS |
| Full test suite (987 tests) | PASS |
| AUDIT-10 (build_runner stale-diff) | PASS (exit 0) |
| Rename score — `ledger_row_data.dart` | R100 |
| Rename score — `ledger_row_data_test.dart` | R099 (≥95 requirement met) |
| LV-022 in `issues.json` | `closed` (closed_in_phase: 3, closed_commit: c549794) |

## Deviations from Plan

### Auto-handled: coverage_gate false-positive on Freezed annotation file

- **Found during:** Task 1 coverage gate check
- **Issue:** `coverage_gate.dart` reports `ledger_row_data.dart` as 0/0 lines and FAIL. The file contains only Freezed annotations, `import` statements, and a `part` directive — no executable Dart statements. Dart's LCOV tool does not generate coverage data for such files.
- **Impact:** False positive. All 13 characterization tests pass. All 987 tests pass. The class's actual implementation is in `.freezed.dart` (filtered by coverde). Real behavior coverage is provided by both the dedicated unit test and `ledger_comparison_section_test.dart`.
- **Fix:** Documented as known tool limitation. Plan 03-05 can supplement if coverage tooling improves or policy requires an explicit workaround.
- **Rule:** [Rule 2 - deviation documentation] — recorded, not blocking.

### Wave 1 parallel execution: custom_lint exits 1 (other LV issues)

- **Scope:** `dart run custom_lint` exits 1 because Plans 03-01 (19 other LV violations) have not yet merged.
- **Impact on this plan:** None. LV-022 specifically does NOT appear in custom_lint output — the `dart:ui` import violation in domain/ is resolved.
- **Fix:** Not needed. Will resolve when Plan 03-01 merges to main.

## Known Stubs

None — this plan is a pure file move. No data flow stubs introduced.

## Threat Flags

None — `LedgerRowData` is a UI-only view-model holding Color and String fields. No security-relevant surface area.

## Convention Established (D-12)

By relocating `ledger_row_data.dart` to `presentation/models/`, this plan establishes by example the project convention: **view-models that compose `dart:ui` types (Color, TextStyle, Size, etc.) belong in `features/<f>/presentation/models/`**. CLAUDE.md documentation of this convention is scheduled for the Phase 7 documentation sweep (not this plan).

## `lib/features/home/domain/` Directory Retention

Per RESEARCH.md A7 and plan frontmatter: `lib/features/home/domain/` directory + its `import_guard.yaml` are intentionally kept after the move. The empty models/ subdirectory is removed (only the moved file was there), but the domain/ directory itself remains so future home-domain models inherit the layer-rule enforcement without extra setup.

## Self-Check

**Files created/exist:**
- `lib/features/home/presentation/models/ledger_row_data.dart`: EXISTS
- `lib/features/home/presentation/models/ledger_row_data.freezed.dart`: EXISTS
- `test/features/home/presentation/models/ledger_row_data_test.dart`: EXISTS

**Files removed:**
- `lib/features/home/domain/models/ledger_row_data.dart`: REMOVED (correct)
- `lib/features/home/domain/models/ledger_row_data.freezed.dart`: REMOVED (correct)
- `test/features/home/domain/models/ledger_row_data_test.dart`: REMOVED (moved, correct)

**LV-022 status:** `closed`

## Self-Check: PASSED
