---
phase: 16-per-category-breakdown-soul-vs-survival-comparison-happy-v2-
verified: 2026-05-20T10:21:05Z
status: passed
score: 5/5 must-haves verified
overrides_applied: 0
---

# Phase 16: Per-Category Breakdown + Soul-vs-Survival Comparison Verification Report

**Phase Goal:** Extend AnalyticsScreen with two cooperative-framed surfaces — per-category satisfaction breakdown and Soul-vs-Survival happiness comparison — that deepen Joy insight without introducing value-judgment or competitive framing.
**Verified:** 2026-05-20T10:21:05Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (Roadmap Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| SC-1 | AnalyticsScreen renders a per-category satisfaction breakdown (category name + avg satisfaction + entry count) for soul-ledger transactions within the active Phase-15 time window. | ✓ VERIFIED | `PerCategoryBreakdownCard` (lib/features/analytics/presentation/widgets/per_category_breakdown_card.dart:40–261) integrated at `analytics_screen.dart:140`. Window-keyed via `perCategorySoulBreakdownProvider(bookId, startDate, endDate)`. Row format `{categoryName} · {avgSat} avg / {count} entries` (en) — see `app_en.arb:1957`, `app_ja.arb:1957`, `app_zh.arb:1957`. DAO `getPerCategorySoulBreakdown` (analytics_dao.dart:490–520) filters via `_soulExpenseFilter` and constrains by `timestamp >= ? AND timestamp <= ?`. |
| SC-2 | Per-category breakdown respects min-N filtering (categories with <3 entries grouped or suppressed) consistent with v1.1 SharedJoyInsight contract — single-data-point categories never crowned. | ✓ VERIFIED | `GetPerCategorySoulBreakdownUseCase._minN = 3` (get_per_category_soul_breakdown_use_case.dart:32). `aggregatePerCategoryBreakdown` partitions `items.where(totalCount >= minN)` into qualifying and folds `lowN` into `otherCount`/`otherCategoryCount` (lines 62–80). D-07 tie-break (`avg DESC, count DESC, categoryId ASC`) defensively re-applied at line 71–77. D-10 Other row carries no averaged satisfaction (model: `per_category_soul_breakdown.dart:48–53`). Widget `_renderResult` (per_category_breakdown_card.dart:157–209) defaults to top-5; `_buildOtherRow` shows count-only aggregate. |
| SC-3 | AnalyticsScreen renders Soul-vs-Survival "Ledger · This window" surface with engagement metrics (entry count + total spend), Soul column additionally showing average satisfaction; descriptive copy only — no value-judgment terms — verified by ARB review + widget assertion of forbidden-substring absence in all three locales. | ✓ VERIFIED | `SoulVsSurvivalCard` (soul_vs_survival_card.dart:28–119) integrated at `analytics_screen.dart:121`. Title `analyticsCardTitleLedgerThisWindow` = "Ledger · This window" / "今期の家計簿" / "本期账本描述" in all 3 ARB files (1986). Soul cell renders entries + spend + avgSat (lines 347–374); Survival cell renders entries + spend only (lines 418–433) — D-04 enforced. Anti-toxicity sweep `anti_toxicity_phase16_test.dart` runs 24 cases (2 cards × 3 locales × 4 states) and PASSES (verified by re-running `flutter test test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart`: `+24: All tests passed!`). |
| SC-4 | New AnalyticsScreen widgets follow v1.1 Variant ε / δ-derived layout conventions; goldens added for both surfaces in light + dark themes. | ✓ VERIFIED | Both cards use the `Card` + `BorderRadius.circular(14)` + 14px padding + `AppTextStyles.titleLarge` header convention used by `_CategoryDonutCard` and `_SatisfactionHistogramOrFallback` neighbors. Goldens present: `test/golden/goldens/per_category_breakdown_card_{light,dark,group_light}_ja.png` (3) and `test/golden/goldens/soul_vs_survival_card_{light,dark,group_light,group_dark}_ja.png` (4). Golden tests in `test/golden/per_category_breakdown_card_golden_test.dart` and `test/golden/soul_vs_survival_card_golden_test.dart` cover both light and dark themes for both surfaces (ja locale per project precedent; documented in plan headers). |
| SC-5 | ADR-012 §6 holds — no per-family-member breakdown introduced anywhere; only ledger-type aggregates shown. | ✓ VERIFIED | All 4 new DAO queries (`getPerCategorySoulBreakdown`, `getPerCategorySoulBreakdownAcrossBooks`, `getLedgerSnapshot`, `getLedgerSnapshotAcrossBooks`) at analytics_dao.dart:490–646 group ONLY by `category_id` or `ledger_type` — no `GROUP BY book_id`. Family-aggregate variants use `book_id IN (...)` to pool across member books (lines 525–561, 613–646). Comments at lines 525 and 610 explicitly cite "NEVER groups by book_id per ADR-012 §6". Domain models `PerCategorySoulBreakdownItem` (per_category_soul_breakdown.dart:26–33) and `SoulVsSurvivalSnapshot` (ledger_snapshot.dart:50–58) carry no `bookId` field — type-system gate. |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/features/analytics/domain/models/ledger_snapshot.dart` | Domain model with D-04 type-system gate (no avgSatisfaction on SurvivalLedgerSnapshot) | ✓ VERIFIED | 84 lines. `SurvivalLedgerSnapshot` (lines 37–42) has only `entryCount` + `totalSpend` — no avgSatisfaction field. `SoulLedgerSnapshot` (lines 22–28) carries the asymmetric `avgSatisfaction`. Composite `SoulVsSurvivalSnapshot` (lines 51–58) with optional `familySoul` / `familySurvival` for group mode. |
| `lib/features/analytics/domain/models/per_category_soul_breakdown.dart` | Domain model with item + aggregate + Other counts | ✓ VERIFIED | 55 lines. `PerCategorySoulBreakdownItem` (lines 26–33): `categoryId + avgSatisfaction + totalCount` mirroring SharedJoyInsight tuple. `PerCategorySoulBreakdown` (lines 47–54): `items + totalCount + otherCount + otherCategoryCount`. NO `bookId` field — ADR-012 §6 enforced. |
| `lib/features/analytics/presentation/widgets/per_category_breakdown_card.dart` | HAPPY-V2-01 widget with solo/you/family scope | ✓ VERIFIED | 261 lines. `PerCategoryScope { solo, you, family }` enum (line 22). Reads `perCategorySoulBreakdownProvider` (solo/you) or `perCategorySoulBreakdownFamilyProvider` (family) via `ref.watch`. State matrix covered: loading skeleton, error retry, Empty body, Value with top-5 + Other + expand toggle. |
| `lib/features/analytics/presentation/widgets/soul_vs_survival_card.dart` | STATSUI-V2-01 widget with solo two-column + group 2×2 grid | ✓ VERIFIED | 473 lines. Solo mode renders `_SoloTwoColumn` (Soul \| Survival via `IntrinsicHeight` + `VerticalDivider`, lines 133–171). Group mode renders `_GroupGrid` 2×2 (You row + Family row with `AsyncValue.when` branch for family loading/error/Empty/Value, lines 173–275). Cells `_SoulCell` (310–379) renders entries + spend + avg sat; `_SurvivalCell` (381–440) renders entries + spend only (D-04 compile-time gate). |
| `lib/features/analytics/presentation/providers/state_ledger_snapshot.dart` | 4 Riverpod providers (single + family for each surface) | ✓ VERIFIED | 110 lines, 4 `@riverpod` definitions: `perCategorySoulBreakdown`, `perCategorySoulBreakdownFamily`, `soulVsSurvivalSnapshot`, `soulVsSurvivalSnapshotFamily`. Family variants gate on `activeGroupProvider` non-null AND `shadowBooks.length >= 2` (D-20 defense in depth). |
| `lib/application/analytics/get_per_category_soul_breakdown_use_case.dart` | Use case with min-N filter + Other rollup | ✓ VERIFIED | 100 lines. `_minN = 3` constant. `aggregatePerCategoryBreakdown` shared function partitions, defensive sorts, computes Other counts. Returns `Empty` only when items=[] OR (qualifying=[] AND otherCount=0). Calls `TimeWindowValidation.assertValid` at entry. |
| `lib/application/analytics/get_soul_vs_survival_snapshot_use_case.dart` | Use case with D-05 either-ledger-zero gate | ✓ VERIFIED | 82 lines. Parallel-fetches `getLedgerSnapshot` + `getSoulSatisfactionOverview`. D-05 gate at lines 58–63: returns `Empty` if soul OR survival row missing/zero. Survival snapshot composed from ledger row only — never touches `soul_satisfaction` (D-04 type-system + provenance). Calls `TimeWindowValidation.assertValid` at entry. |
| `lib/data/daos/analytics_dao.dart` | 4 new DAO methods + `_survivalExpenseFilter` constant | ✓ VERIFIED | `_survivalExpenseFilter` at line 113. `getPerCategorySoulBreakdown` (490–520), `getPerCategorySoulBreakdownAcrossBooks` (528–561), `getLedgerSnapshot` (575–605), `getLedgerSnapshotAcrossBooks` (613–646). All `GROUP BY category_id` or `GROUP BY ledger_type` — no per-member projection. |
| `lib/features/analytics/presentation/screens/analytics_screen.dart` | Integration: cards in Distribution section + `_refresh()` invalidation | ✓ VERIFIED | `SoulVsSurvivalCard` at line 121 (between donut and histogram, per D-13 insertion order). `PerCategoryBreakdownCard` at line 140 (after histogram). Group mode adds second `PerCategoryBreakdownCard` with `scope: family` at line 154 (D-17 stacked cards). `_refresh()` invalidates all 4 new providers at lines 250–283 with matching `(bookId, startDate, endDate)` keys. Comments at lines 208, 247–249 reaffirm the D-12 HomeHero isolation invariant. |
| `lib/l10n/app_{en,ja,zh}.arb` | 22 new keys (incl. plural-/placeholder-bearing) in all three locales | ✓ VERIFIED | 22 matches per locale via grep — full ARB parity. Key headlines: `analyticsCardTitleLedgerThisWindow` ("Ledger · This window" / "今期の家計簿" / "本期账本描述"), `analyticsLedgerColumnSoul`, `analyticsLedgerColumnSurvival`, `analyticsLedgerRowYou`, `analyticsLedgerRowFamily`, `analyticsPerCategoryRow`, `analyticsPerCategoryOtherFold`, `analyticsPerCategoryShowAll/ShowLess`, `analyticsPerCategoryEmpty`, `analyticsLedgerEmpty/FamilyEmpty/FamilyError`, `analyticsCardTitlePerCategorySoul{,You,Family}`. |
| `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart` | Trilingual forbidden-substring sweep, 24 cases | ✓ VERIFIED | File exists. Locked forbidden lists per D-14: en (15 entries), zh (13), ja (10). Sweeps both cards × 3 locales × 4 states. `flutter test` re-run: **`+24: All tests passed!`** |
| `test/golden/per_category_breakdown_card_golden_test.dart` + 3 PNG goldens | Light + dark + group_light goldens for PerCategoryBreakdownCard | ✓ VERIFIED | Test file + `goldens/per_category_breakdown_card_{light,dark,group_light}_ja.png`. |
| `test/golden/soul_vs_survival_card_golden_test.dart` + 4 PNG goldens | Light + dark + group_light + group_dark goldens for SoulVsSurvivalCard | ✓ VERIFIED | Test file + `goldens/soul_vs_survival_card_{light,dark,group_light,group_dark}_ja.png`. |
| `test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` | Extended for Phase 16 providers (D-12 HomeHero isolation) | ✓ VERIFIED | Lines 98–103 declare mocks for all 4 Phase-16 use cases; lines 200–215 add provider overrides; lines 310+ assert HomeHero never invokes the Phase-16 providers. Test re-run: `+2: All tests passed!`. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `AnalyticsScreen` | `SoulVsSurvivalCard` | direct widget instantiation at line 121 with all required params (bookId, startDate, endDate, currencyCode, locale, isGroupMode) | ✓ WIRED | Pass-through from `selectedTimeWindowProvider` to card props. |
| `AnalyticsScreen` | `PerCategoryBreakdownCard` (solo/you) | direct widget instantiation at line 140 with scope = `solo` or `you` (based on `isGroupMode`) | ✓ WIRED | Window-keyed instantiation. |
| `AnalyticsScreen` | `PerCategoryBreakdownCard` (family) | conditional instantiation at line 154 wrapped in `if (isGroupMode)` | ✓ WIRED | Second stacked card per D-17. |
| `AnalyticsScreen._refresh` | `perCategorySoulBreakdownProvider`, `soulVsSurvivalSnapshotProvider`, family variants | `ref.invalidate(...)` at lines 250–283 | ✓ WIRED | Same `(bookId, startDate, endDate)` keys as build context — HomeHero providers untouched (D-12). |
| `SoulVsSurvivalCard` | `soulVsSurvivalSnapshotProvider` / `soulVsSurvivalSnapshotFamilyProvider` | `ref.watch` at lines 48–66 | ✓ WIRED | Solo/family branching by `isGroupMode` prop. |
| `PerCategoryBreakdownCard` | `perCategorySoulBreakdownProvider` / `perCategorySoulBreakdownFamilyProvider` | `ref.watch` at lines 84–97 | ✓ WIRED | Scope-driven selection in `_PerCategoryBreakdownCardState.build`. |
| Providers | Use cases | `ref.watch(get*UseCaseProvider)` at state_ledger_snapshot.dart:24, 52, 74, 101 | ✓ WIRED | Family providers additionally consume `activeGroupProvider` + `shadowBooksProvider` (D-20 gate). |
| Use cases | Repository methods | `_repo.getPerCategorySoulBreakdown(...)`, `_repo.getLedgerSnapshot(...)`, `_repo.getSoulSatisfactionOverview(...)`, `_repo.getPerCategorySoulBreakdownAcrossBooks(...)`, `_repo.getLedgerSnapshotAcrossBooks(...)` | ✓ WIRED | Interface methods exist at analytics_repository.dart:85, 95, 104, 112; impl wires DAO calls; DAO produces `List<LedgerSnapshotRow>` / `List<PerCategorySoulRowRaw>`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `PerCategoryBreakdownCard` | `asyncResult` → `MetricResult<PerCategorySoulBreakdown>` | `perCategorySoulBreakdownProvider` → `GetPerCategorySoulBreakdownUseCase.execute` → repo → DAO `AVG(soul_satisfaction), COUNT(*) GROUP BY category_id` | Yes — real SQL aggregation over `transactions` table (lines 497–502 of analytics_dao.dart). | ✓ FLOWING |
| `SoulVsSurvivalCard` | `asyncSnapshot` → `MetricResult<SoulVsSurvivalSnapshot>` | `soulVsSurvivalSnapshotProvider` → `GetSoulVsSurvivalSnapshotUseCase.execute` → repo → DAO `getLedgerSnapshot` (SUM + COUNT GROUP BY ledger_type) + `getSoulSatisfactionOverview` | Yes — real SQL aggregation, parallel fetch. | ✓ FLOWING |
| `_GroupGrid` (family row) | `familyAsync` → `MetricResult<SoulVsSurvivalSnapshot>` | `soulVsSurvivalSnapshotFamilyProvider` (gated on >=2 shadow books) → `GetSoulVsSurvivalSnapshotAcrossBooks` → DAO `getLedgerSnapshotAcrossBooks` | Yes — real SQL with `book_id IN (...)`. | ✓ FLOWING |
| `PerCategoryBreakdownCard` (family scope) | `asyncResult` → family provider | `perCategorySoulBreakdownFamilyProvider` (gated on >=2 shadow books) → `getPerCategorySoulBreakdownAcrossBooks` DAO | Yes — real SQL with `book_id IN (...)`. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Anti-toxicity sweep all 24 cases pass | `flutter test test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart` | `+24: All tests passed!` | ✓ PASS |
| PerCategoryBreakdownCard + SoulVsSurvivalCard widget tests pass | `flutter test test/widget/features/analytics/presentation/widgets/per_category_breakdown_card_test.dart test/widget/features/analytics/presentation/widgets/soul_vs_survival_card_test.dart` | `+18: All tests passed!` (includes Loading / Error / Empty / Value / D-04 invariant assertion / family row branching) | ✓ PASS |
| HomeHero isolation invariant holds with Phase-16 providers added | `flutter test test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` | `+2: All tests passed!` (HomeHero remains current-month keyed even when Analytics window is set to year 2020; HomeScreen does not import state_time_window) | ✓ PASS |
| Static analysis clean | `flutter analyze` | "No issues found! (ran in 2.4s)" | ✓ PASS |
| ARB key parity in en/ja/zh | `grep -c <22 keys> lib/l10n/app_{en,ja,zh}.arb` | 22 / 22 / 22 | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| HAPPY-V2-01 | Phase 16 (all 10 plans) | User can view a per-category satisfaction breakdown in AnalyticsScreen (e.g., "Coffee shops: 8.2 avg / 12 entries") | ✓ SATISFIED (code) — Pending → should be flipped to Complete in REQUIREMENTS.md traceability table | Card + provider + use case + DAO + tests all present; row format matches example wording. |
| STATSUI-V2-01 | Phase 16 (all 10 plans) | User can view a Soul-vs-Survival happiness comparison surface with anti-toxicity framing (no value judgment language) | ✓ SATISFIED (code) — Pending → should be flipped to Complete in REQUIREMENTS.md traceability table | Card + provider + use case + DAO + anti-toxicity widget sweep all present and passing. ROADMAP SC-3 wording correctly re-framed to engagement axis per D-15 (verified at ROADMAP.md:116). |

**Note:** `.planning/REQUIREMENTS.md` lines 25, 31 still show `[ ]` (unchecked) and lines 104, 107 of the traceability matrix still show "Pending". These reflect requirement-completion metadata that the orchestrator should flip to `[x]` / "Complete" as part of phase closure, but the underlying code work is fully satisfied. Not a blocker.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | — | — | No new TBD/FIXME/XXX/PLACEHOLDER markers detected in Phase-16-touched files. |

### Human Verification Required

No human verification items identified. All 5 success criteria verified programmatically via static inspection + test execution. Anti-toxicity copy review is automated by the trilingual forbidden-substring sweep. Golden images exist for both surfaces in light/dark variants. ARB parity is grep-verified.

### Pre-Existing Failures (Out of Scope for Phase 16)

`flutter test test/widget/features/analytics/` produces 6 failures, all in `test/widget/features/analytics/presentation/widgets/family_insight_card_test.dart`. Independent verification:

- The failing tests expect Japanese text `"今月、家族の小確幸 23回"` (with `今月、` prefix).
- The current ARB key `analyticsFamilyHighlightsSentence` resolves to `"家族の小確幸 {N}回"` (no `今月、` prefix) — see `lib/l10n/app_ja.arb:1923`.
- `git log -S "今月、家族の小確幸"` shows the prefix was dropped by commit `8d5f136` (Phase 15 fix-up "neutralize Analytics period copy"), which predates Phase 16's first commit `d2636e4`.
- The Phase 16 work modified `_refresh()` and `analytics_screen.dart` but did not touch `family_insight_card.dart` or its test.

These failures are stale Phase 15 tests, documented in `.planning/phases/16-per-category-breakdown-soul-vs-survival-comparison-happy-v2-/deferred-items.md` and acknowledged in 16-08-SUMMARY and 16-10-SUMMARY. They do NOT block Phase 16 verification.

### Goal Achievement Summary

All 5 ROADMAP Success Criteria are observably true in the codebase:

1. **SC-1 (Per-category breakdown rendering):** `PerCategoryBreakdownCard` integrated into `AnalyticsScreen.Distribution` group, reading the window-keyed `perCategorySoulBreakdownProvider` and rendering rows in the expected `{category} · {avg} avg / {count} entries` format. Soul-ledger filter (`_soulExpenseFilter`) and window range (`startDate`/`endDate`) enforced at DAO layer.

2. **SC-2 (Min-N filtering):** `GetPerCategorySoulBreakdownUseCase._minN = 3`. Sub-min-N rows fold into a count-only "Other" row (D-08, D-10). Defensive D-07 re-sort (`avg DESC, count DESC, categoryId ASC`) inside the use case.

3. **SC-3 (Soul-vs-Survival surface + anti-toxicity verification):** `SoulVsSurvivalCard` with title key `analyticsCardTitleLedgerThisWindow` = "Ledger · This window" / "今期の家計簿" / "本期账本描述". Soul cell renders entries + spend + avgSat. Survival cell renders entries + spend ONLY (D-04 enforced both at type-system and DAO-provenance levels). Anti-toxicity widget sweep (`anti_toxicity_phase16_test.dart`) runs 24 cases across 3 locales × 4 states for both cards — all pass.

4. **SC-4 (Variant-ε conventions + goldens):** Both cards adopt the `Card` + 14px radius + 14px padding + `AppTextStyles.titleLarge` header convention of their neighbors. Light + dark goldens exist for both surfaces (ja locale per project precedent); group-mode goldens additionally exist for completeness.

5. **SC-5 (ADR-012 §6 — no per-member breakdown):** All 4 new DAO queries group only by `category_id` or `ledger_type`. Family-aggregate variants use `book_id IN (...)` pooling — never `GROUP BY book_id`. Domain models carry no `bookId` field — type-system gate.

D-04 (SurvivalLedgerSnapshot has no avgSatisfaction) is enforced at the Freezed class level. D-12 (HomeHero isolation) is preserved by the extended `home_screen_isolation_test.dart`. D-14 (anti-toxicity) is enforced by the trilingual sweep test. `flutter analyze` is clean.

---

_Verified: 2026-05-20T10:21:05Z_
_Verifier: Claude (gsd-verifier)_
