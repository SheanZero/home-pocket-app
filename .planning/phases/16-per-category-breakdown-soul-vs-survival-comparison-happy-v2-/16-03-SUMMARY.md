---
phase: 16-per-category-breakdown-soul-vs-survival-comparison-happy-v2-
plan: 03
subsystem: analytics-domain
tags: [flutter, freezed, analytics, soul-survival, anti-toxicity, type-system-gate]
requires: []
provides:
  - Freezed PerCategorySoulBreakdownItem domain interchange shape
  - Freezed PerCategorySoulBreakdown aggregate with Other-fold counts
  - Freezed SoulLedgerSnapshot (entryCount + totalSpend + avgSatisfaction)
  - Freezed SurvivalLedgerSnapshot (entryCount + totalSpend ONLY — D-04 type-system gate)
  - Freezed SoulVsSurvivalSnapshot composite with optional family pair (group mode)
  - 14 unit tests covering equality, copyWith immutability, and the D-04 absence assertion
affects:
  - phase-16-04-analytics-dao
  - phase-16-05-use-cases
  - phase-16-06-providers
  - phase-16-07-widgets
  - phase-16-08-widgets
tech-stack:
  added: []
  patterns:
    - Freezed @freezed abstract class with _$Mixin
    - Domain interchange shape distinct from DAO transient row (CLAUDE.md Pitfall #2)
    - Absence-of-field as compile-time anti-toxicity gate (D-04)
key-files:
  created:
    - lib/features/analytics/domain/models/per_category_soul_breakdown.dart
    - lib/features/analytics/domain/models/per_category_soul_breakdown.freezed.dart
    - lib/features/analytics/domain/models/ledger_snapshot.dart
    - lib/features/analytics/domain/models/ledger_snapshot.freezed.dart
    - test/unit/features/analytics/domain/models/per_category_soul_breakdown_test.dart
    - test/unit/features/analytics/domain/models/ledger_snapshot_test.dart
  modified: []
key-decisions:
  - "Adopted canonical name PerCategorySoulBreakdownItem (D-06 wording 'one row per category' = each row is an item); DAO-tier transient row will use PerCategorySoulRowRaw in Plan 16-04 to keep names from colliding across layers."
  - "D-04 enforced structurally: SurvivalLedgerSnapshot literally cannot carry avgSatisfaction. The compile-time gate is the regression prevention against AVG(soul_satisfaction) over default-2 survival rows."
  - "Doc-comment on SurvivalLedgerSnapshot names ADR-014 D-10, the picker/default-2 collision, and the regression mode the gate prevents — so future readers don't reverse the decision."
  - "Composite SoulVsSurvivalSnapshot keeps family fields nullable; group-mode invariants live in the use case (D-18, D-20), not the model."
patterns-established:
  - "Domain models name their DAO counterparts descriptively in doc-comments without using the DAO symbol verbatim, so the cross-layer contract is documented but the file does not parametrize an import_guard violation grep."
  - "Anti-toxicity rules are enforceable as Freezed field absence, not just as ARB-key avoidance."
requirements-completed: [HAPPY-V2-01, STATSUI-V2-01]
duration: 6 min
completed: 2026-05-20
---

# Phase 16 Plan 03: Domain Models for Per-Category Breakdown + Soul-vs-Survival Comparison

**Two Freezed model files lock the HAPPY-V2-01 + STATSUI-V2-01 data contracts before any DAO/use-case/widget code is written; the SurvivalLedgerSnapshot field-absence is the structural enforcement of the engagement-axis reframe (D-04).**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-05-20T03:24:00Z
- **Completed:** 2026-05-20T03:30:00Z
- **Tasks:** 2
- **Files created:** 6 (2 source + 2 generated + 2 test)

## Accomplishments

- Created `PerCategorySoulBreakdownItem` Freezed model — `(categoryId, avgSatisfaction, totalCount)` triple that mirrors `SharedJoyInsight` field shape; this is the SOURCE OF TRUTH consumed by the `AnalyticsRepository` interface, use cases, providers, and widgets.
- Created `PerCategorySoulBreakdown` aggregate Freezed model — `(items, totalCount, otherCount, otherCategoryCount)` carrying the Other-fold counts per D-08/D-10 (no averaged avgSatisfaction on Other — heterogeneous low-N averages would be a false signal).
- Created `SoulLedgerSnapshot` Freezed model — `(entryCount, totalSpend, avgSatisfaction)` for the Soul column of the comparison surface; soul-only `avgSatisfaction` is intentional asymmetry per D-03.
- Created `SurvivalLedgerSnapshot` Freezed model — `(entryCount, totalSpend)` ONLY. The absence of `avgSatisfaction` is the compile-time D-04 type-system gate (ADR-014 D-10 default-2 collision regression prevention).
- Created `SoulVsSurvivalSnapshot` composite Freezed model — `(soul, survival, familySoul?, familySurvival?)` carrying solo + group-mode variants (group invariant enforcement deferred to use case per D-18, D-20).
- Added 14 unit tests covering equality, hashCode, copyWith immutability, list-element equality, empty construction, and — load-bearing — the structural assertion that `SurvivalLedgerSnapshot.toString()` does not contain the string `'avgSatisfaction'`.

## Task Commits

1. **Task 1 RED:** test for PerCategorySoulBreakdownItem + PerCategorySoulBreakdown — `b0576e5` (test)
2. **Task 1 GREEN:** implement PerCategorySoulBreakdownItem + PerCategorySoulBreakdown Freezed models + generated runtime — `91b7d51` (feat)
3. **Task 2 RED:** test for SoulLedgerSnapshot / SurvivalLedgerSnapshot / SoulVsSurvivalSnapshot + D-04 absence gate — `a9bfd44` (test)
4. **Task 2 GREEN:** implement ledger snapshots with D-04 structural enforcement + generated runtime — `bb1041f` (feat)

## Files Created/Modified

- `lib/features/analytics/domain/models/per_category_soul_breakdown.dart` — `PerCategorySoulBreakdownItem` (domain interchange shape) + `PerCategorySoulBreakdown` (aggregate); doc-comment names CLAUDE.md Pitfall #2 (Domain MUST NOT import the DAO row type).
- `lib/features/analytics/domain/models/per_category_soul_breakdown.freezed.dart` — generated Freezed equality/copyWith/toString runtime for both classes.
- `lib/features/analytics/domain/models/ledger_snapshot.dart` — `SoulLedgerSnapshot`, `SurvivalLedgerSnapshot` (D-04 NO avgSatisfaction), `SoulVsSurvivalSnapshot`; doc-comment above `SurvivalLedgerSnapshot` names ADR-014 D-10 + the regression mode the gate prevents.
- `lib/features/analytics/domain/models/ledger_snapshot.freezed.dart` — generated Freezed runtime; `_$SurvivalLedgerSnapshot` mixin has zero `avgSatisfaction` references (D-04 verified at the generated tier).
- `test/unit/features/analytics/domain/models/per_category_soul_breakdown_test.dart` — 7 tests across Item equality / copyWith / aggregate equality / empty construction.
- `test/unit/features/analytics/domain/models/ledger_snapshot_test.dart` — 7 tests across Soul equality / copyWith, Survival equality + D-04 absence assertion, composite solo/group construction + copyWith.

## Decisions Made

- **Canonical naming locked:** `PerCategorySoulBreakdownItem` (domain interchange shape) vs `PerCategorySoulRowRaw` (DAO-tier transient row, to be defined in Plan 16-04). The two names cannot collide; the domain layer NEVER imports the DAO row type.
- **D-04 enforced structurally, not socially:** `SurvivalLedgerSnapshot` literally has no `avgSatisfaction` field; the only way to add one is to edit the Freezed source — which then triggers the absence-assertion test failure. Future agents who would otherwise reach for `AVG(soul_satisfaction)` over survival rows must consciously break the gate, not stumble into it.
- **Doc-comments are load-bearing:** the comment block above `SurvivalLedgerSnapshot` names ADR-014 D-10, the default-2 collision, and the regression mode — so a reader who notices the asymmetry between Soul and Survival snapshots immediately understands WHY rather than reaching for symmetry as a "fix".
- **Group-mode invariants live in the use case, not the model:** `SoulVsSurvivalSnapshot.familySoul` and `familySurvival` are independently nullable. The "both-non-null in group mode" invariant (D-18) and "fall back to Empty when <2 books" (D-20) are use-case responsibilities — keeps the model layer pure and unaware of orchestration state.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Internal inconsistency in plan acceptance criteria vs action**
- **Found during:** Task 1 GREEN verification
- **Issue:** The plan's `<action>` block explicitly instructed adding a doc-comment containing the literal symbol `PerCategorySoulRowRaw` to document the DAO counterpart (the Domain→Data contract). The plan's `<acceptance_criteria>` block then specified `grep -E '\bPerCategorySoulRow\b|\bPerCategorySoulRowRaw\b' lib/.../per_category_soul_breakdown.dart` must return nothing — which is mutually contradictory with the action.
- **Fix:** Resolved by intent. The acceptance criterion's intent is to prevent the legacy symbol `PerCategorySoulRow` from leaking as a Dart identifier and to prevent the domain file from coupling itself to the DAO row symbol. I kept the architectural documentation in the doc-comment but rephrased the DAO counterpart description so it does not include the literal `PerCategorySoulRowRaw` token (now: "a Drift-row `(categoryId, avgSatisfaction, totalCount)` triple defined inside `lib/data/daos/analytics_dao.dart` — see Plan 16-04"). Verified: `grep -E '\bPerCategorySoulRow\b|\bPerCategorySoulRowRaw\b' lib/features/analytics/domain/models/per_category_soul_breakdown.dart` returns 0 matches; the cross-layer contract is still documented for any reader.
- **Files modified:** `lib/features/analytics/domain/models/per_category_soul_breakdown.dart` (doc-comment phrasing only — no code change).
- **Verification:** Symbol grep returns nothing; Task 1 acceptance criteria met; doc-comment still names CLAUDE.md Pitfall #2 and the architectural contract.
- **Committed in:** `91b7d51`

---

**Total deviations:** 1 auto-fixed (1 internal-plan-inconsistency reconciled).
**Impact on plan:** Both stated intents satisfied — file has no forbidden symbols AND the architectural contract is documented. Downstream plans (16-04 DAO definition) are unaffected; they can still introduce the `PerCategorySoulRowRaw` symbol on the DAO side without any cross-layer leakage.

## Issues Encountered

- `flutter pub run build_runner build --delete-conflicting-outputs` printed `W These options have been removed and were ignored: --delete-conflicting-outputs` (toolchain has dropped the flag) but generation completed successfully for both runs and the freezed runtime is clean.

## Verification

- **RED confirmed (Task 1):** `flutter test test/unit/features/analytics/domain/models/per_category_soul_breakdown_test.dart` failed with `Error: Method not found: 'PerCategorySoulBreakdownItem'` and `Error: Method not found: 'PerCategorySoulBreakdown'` before the source file existed.
- **RED confirmed (Task 2):** `flutter test test/unit/features/analytics/domain/models/ledger_snapshot_test.dart` failed with `Method not found: 'SurvivalLedgerSnapshot'`, etc., before the source file existed.
- **GREEN (Task 1):** 7 tests passed (`equality + hashCode`, `differing-field inequality`, `copyWith immutability`, aggregate equality across list members, aggregate inequality on differing `otherCount`, empty construction, mixed item+Other constructor accounting).
- **GREEN (Task 2):** 7 tests passed (`SoulLedgerSnapshot equality + hashCode`, `SoulLedgerSnapshot copyWith immutability`, `SurvivalLedgerSnapshot equality + hashCode`, `D-04 toString() does NOT contain avgSatisfaction`, composite solo construction, composite group construction, composite copyWith clears family fields).
- **D-04 structural gate verified at source tier:** `awk '/class.*SurvivalLedgerSnapshot/,/^}/' lib/features/analytics/domain/models/ledger_snapshot.dart | grep -c avgSatisfaction` returns `0`.
- **D-04 structural gate verified at generated tier:** `awk '/_\$SurvivalLedgerSnapshot/,/^}/' lib/features/analytics/domain/models/ledger_snapshot.freezed.dart | grep -c avgSatisfaction` returns `0`.
- **Domain → Data import gate verified:** `grep -E "import .*'\\.\\./\\.\\./\\.\\./data/" lib/features/analytics/domain/models/per_category_soul_breakdown.dart` returns nothing. Neither domain file imports anything outside `package:freezed_annotation/...`.
- **Forbidden-symbol gate verified:** `grep -E '\bPerCategorySoulRow\b|\bPerCategorySoulRowRaw\b' lib/features/analytics/domain/models/per_category_soul_breakdown.dart` returns nothing.
- **Generated runtime present:** `lib/features/analytics/domain/models/per_category_soul_breakdown.freezed.dart` contains 26 occurrences of `_$PerCategorySoulBreakdown`; `lib/features/analytics/domain/models/ledger_snapshot.freezed.dart` contains the `_$SurvivalLedgerSnapshot` mixin with `int get entryCount`, `int get totalSpend` and nothing else.
- **flutter analyze (full project):** "No issues found! (ran in 1.7s)" — zero issues across the entire codebase, not just the new files.
- **flutter analyze (new files):** `flutter analyze lib/features/analytics/domain/models/per_category_soul_breakdown.dart lib/features/analytics/domain/models/ledger_snapshot.dart test/unit/features/analytics/domain/models/per_category_soul_breakdown_test.dart test/unit/features/analytics/domain/models/ledger_snapshot_test.dart` reports `No issues found!`.
- **Combined test run:** 14/14 tests pass when both test files are executed together (7 + 7).

## User Setup Required

None — pure domain-layer additions with no external service configuration.

## Next Phase Readiness

Plan 16-04 (Analytics DAO method) can now:
- Return `List<PerCategorySoulBreakdownItem>` from the new repository method (the canonical interchange shape exists).
- Define `PerCategorySoulRowRaw` inside `lib/data/daos/analytics_dao.dart` as the Drift-row transient tuple; the repository impl converts `PerCategorySoulRowRaw → PerCategorySoulBreakdownItem` without coupling domain to data.
- Compose the `SoulVsSurvivalSnapshot` from `getLedgerTotals` + `getSoulSatisfactionOverview` results (D-04: never read `soul_satisfaction` for survival rows).

Plans 16-05/06/07/08 (use cases, providers, widgets) can rely on these models as a stable contract; the D-04 absence assertion will block any future code path that tries to compute `AVG(soul_satisfaction)` on the survival side at compile time.

## Self-Check: PASSED

- FOUND: lib/features/analytics/domain/models/per_category_soul_breakdown.dart
- FOUND: lib/features/analytics/domain/models/per_category_soul_breakdown.freezed.dart
- FOUND: lib/features/analytics/domain/models/ledger_snapshot.dart
- FOUND: lib/features/analytics/domain/models/ledger_snapshot.freezed.dart
- FOUND: test/unit/features/analytics/domain/models/per_category_soul_breakdown_test.dart
- FOUND: test/unit/features/analytics/domain/models/ledger_snapshot_test.dart
- FOUND commit b0576e5 (Task 1 RED)
- FOUND commit 91b7d51 (Task 1 GREEN)
- FOUND commit a9bfd44 (Task 2 RED)
- FOUND commit bb1041f (Task 2 GREEN)

---
*Phase: 16-per-category-breakdown-soul-vs-survival-comparison-happy-v2-*
*Completed: 2026-05-20*
