---
phase: 35
plan: "01"
subsystem: list-a11y
tags: [a11y, semantics, l10n, accessibility, vocab-fix]
dependency_graph:
  requires: []
  provides: [W1-semantics-labels-fixed]
  affects: [list_sort_filter_bar]
tech_stack:
  added: []
  patterns: [l10n-via-S.of(context)]
key_files:
  created: []
  modified:
    - lib/features/list/presentation/widgets/list_sort_filter_bar.dart
decisions:
  - "No new ARB keys needed — listLedgerDaily and listLedgerJoy already exist in all 3 locales (ja/zh/en)"
  - "dart format applied — 57 insertions / 54 deletions due to formatter normalizing existing whitespace unrelated to the 2-line fix"
metrics:
  duration: "~5 minutes"
  completed: "2026-06-02"
  tasks_completed: 1
  tasks_total: 1
  files_changed: 1
---

# Phase 35 Plan 01: Fix Stale a11y Semantics Labels (W1) Summary

**One-liner:** Replaced two hardcoded `Semantics(label: ...)` strings in ledger-filter chips — `'Survival ledger'` → `l10n.listLedgerDaily` and `'Soul ledger'` → `l10n.listLedgerJoy` — closing the last screen-reader vocab leak from the v1.5 audit.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Replace hardcoded Semantics labels with l10n values | 9d39076e | list_sort_filter_bar.dart |

## Verification Results

**Gate 1 — No hardcoded stale strings:**
```
grep -rn "'Survival ledger'\|'Soul ledger'" lib/
# Result: 0 results (exit 1) ✓
```

**Gate 2 — Semantics labels route through l10n:**
```
grep -n "listLedgerDaily\|listLedgerJoy" lib/features/list/presentation/widgets/list_sort_filter_bar.dart
# Line 233: label: l10n.listLedgerDaily,  ← new Semantics label
# Line 237: l10n.listLedgerDaily,          ← pre-existing Text child
# Line 266: label: l10n.listLedgerJoy,     ← new Semantics label
# Line 270: l10n.listLedgerJoy,            ← pre-existing Text child
# 4 hits total ✓
```

**Gate 3 — Analyzer clean:**
```
flutter analyze
# 4 issues found — all pre-existing infos in external files (firebase_messaging, category_selection_screen)
# 0 new issues in list_sort_filter_bar.dart ✓
```

## Deviations from Plan

None — plan executed exactly as written. `dart format` touched whitespace normalization beyond the 2-line logical change (formatter adjusted `_showSortMenu` signature and `anyFilterActive` expression layout), which is expected behavior.

## Known Stubs

None.

## Threat Flags

None — 2-line swap of hardcoded string literals for existing l10n references. No new trust boundaries, network endpoints, auth paths, or persistence changes introduced.

## Self-Check: PASSED

- [x] `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` — FOUND (modified)
- [x] Commit `9d39076e` — FOUND in git log
- [x] 0 `'Survival ledger'` or `'Soul ledger'` occurrences in `lib/` — CONFIRMED
- [x] 4 `listLedgerDaily`/`listLedgerJoy` hits in file — CONFIRMED
- [x] flutter analyze: 0 new issues — CONFIRMED
