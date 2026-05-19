# Phase 11 — Integration Footprint Audit (STATSUI-04)

**Audited:** 2026-05-03
**Purpose:** Pre-wiring footprint reality-check. Counters 30-50% under-estimation on "just wire it up" tasks (ROADMAP pitfall #1; RESEARCH § Pitfalls & Landmines, `.planning/phases/11-statistics-surface-for/11-RESEARCH.md:738`).
**Scope:** AnalyticsScreen Variant δ unified dashboard rebuild — 2-region (総 + 悦己) per D-15 (`.planning/phases/11-statistics-surface-for/11-CONTEXT.md:302`).

## Fact correction up front

ROADMAP.md and PROJECT.md describe Phase 11 as "wire 3 dormant DAO methods." This is OUT OF DATE post-Phase 9. Reality:

| DAO method | Status post-Phase-9 | Phase 11 use |
|------------|---------------------|--------------|
| `getSoulSatisfactionOverview` (`lib/data/daos/analytics_dao.dart:237`) | wired via `GetHappinessReportUseCase` | consumed indirectly via `happinessReportProvider` |
| `getSatisfactionDistribution` (`lib/data/daos/analytics_dao.dart:268`) | wired via `GetHappinessReportUseCase` | consumed indirectly (histogram render) |
| `getDailySatisfactionTrend` (`lib/data/daos/analytics_dao.dart:300`) | TRULY DORMANT (zero callers; `rg -n "getDailySatisfactionTrend" lib test` finds only the DAO definition) | **SUPERSEDED by NEW `getDailySoulRowsForPtvf` per D-05** — per-day PTVF fold, not per-day average |
| `getBestJoyMoment` (`lib/data/daos/analytics_dao.dart:335`) | wired via `GetBestJoyMomentUseCase` | consumed via `bestJoyMomentProvider` |

Phase 11 does NOT "wire 3 dormant DAOs" — it adds 2 NEW DAO methods (`getDailySoulRowsForPtvf` per D-05; `getLargestMonthlyExpense` for 物語 group 総 card) and rebuilds the screen around all wired use cases. Planner decision per CONTEXT.md Claude's Discretion (`.planning/phases/11-statistics-surface-for/11-CONTEXT.md:95`): DELETE the orphan `getDailySatisfactionTrend` in Wave 1 (clean break).

## Provider graph

Source: RESEARCH System Architecture Diagram (`.planning/phases/11-statistics-surface-for/11-RESEARCH.md:68`) and CONTEXT reusable assets (`.planning/phases/11-statistics-surface-for/11-CONTEXT.md:191`).

### Existing (consumed, no changes)

- `selectedMonthProvider` (`lib/features/analytics/presentation/providers/state_analytics.dart:12`) — D-08 preserved; chart re-keys on change
- `monthlyReportProvider` (`lib/features/analytics/presentation/providers/state_analytics.dart:32`) — feeds 総 KPI tile + 6か月推移 + 類別支出 donut + 今月の最大支出 anchor
- `expenseTrendProvider` (`lib/features/analytics/presentation/providers/state_analytics.dart:56`) — feeds 6か月推移 BarChart. **NOTE:** currently keyed by `bookId` only (not month). Per RESEARCH §Other landmines (`.planning/phases/11-statistics-surface-for/11-RESEARCH.md:784`): planner should change `GetExpenseTrendUseCase.execute` signature to accept `DateTime anchor` so 6-month window trails the SELECTED month, not `DateTime.now()`. **See Plan 03 task on use case + provider re-keying.**
- `happinessReportProvider` (`lib/features/analytics/presentation/providers/state_happiness.dart:16`) — feeds 悦己 KPI tile (mean + median + n=k)
- `bestJoyMomentProvider` (`lib/features/analytics/presentation/providers/state_happiness.dart:34`) — feeds 悦己 ベスト ジョイ story strip
- `familyHappinessProvider` (`lib/features/analytics/presentation/providers/state_happiness.dart:50`) — feeds FamilyInsightCard (group mode only)
- `bookByIdProvider` — currency resolution per CLAUDE.md Pitfall #9
- `currentLocaleProvider` — locale-aware formatters
- `isGroupModeProvider` (`lib/features/family_sync/presentation/providers/state_active_group.dart`) — FamilyInsightCard gate
- `shadowBooksProvider` (`lib/features/home/presentation/providers/state_shadow_books.dart`) — FamilyInsightCard gate (Phase 10 D-08 minimum)

### Removed (orphaned by Wave 3 deletion)

- `budgetProgressProvider` (`lib/features/analytics/presentation/providers/state_analytics.dart:44`) — REMOVE in Plan 07 (sole consumer = `BudgetProgressList` widget being deleted; Phase 11 has no budget surface; budget redesign deferred to v1.2 per CONTEXT Deferred Ideas)

### NEW (Plan 03 adds these to state_happiness.dart)

- `dailyJoyPerYenProvider({bookId, year, month, currencyCode})` -> `Future<MetricResult<List<DailyJoyPerYenPoint>>>` — Joy/¥ trend (STATSUI-01, D-05)
- `largestMonthlyExpenseProvider({bookId, year, month})` -> `Future<LargestMonthlyExpense?>` — 今月の最大支出 (STATSUI-06)
- (no new provider for MoM delta — KPI tile reads `monthlyReport.previousMonthComparison?.expenseChange` directly per RESEARCH Open Q3)

## Widget tree (target — Variant δ)

Source: 11-UI-SPEC.md `## Layout Rhythm` (`.planning/phases/11-statistics-surface-for/11-UI-SPEC.md:378`) and `## Component Inventory` (`.planning/phases/11-statistics-surface-for/11-UI-SPEC.md:291`). Current `AnalyticsScreen` imports all 8 v1.0 widgets at `lib/features/analytics/presentation/screens/analytics_screen.dart:14` through `:21`.

```
AnalyticsScreen (rewritten — Plan 07)
├── AppBar
│   ├── title: S.of(context).analyticsTitle
│   └── actions: [MonthChipPicker]
└── RefreshIndicator
    └── SingleChildScrollView
        └── Column
            ├── KpiMiniHeroStrip
            │   ├── TotalSpendingKpiTile      ← 総 (left) — Plan 04
            │   └── JoyHeadlineKpiTile        ← 悦己 (right) — Plan 04
            ├── AnalyticsScreenSectionHeader("時間")  ← Plan 04
            ├── MonthlySpendTrendBarChart    ← 総 — Plan 05
            ├── JoyTrendLineChart  OR  JoyLedgerThinSampleFallback  ← 悦己 — Plan 05/06
            ├── AnalyticsScreenSectionHeader("分布")
            ├── CategorySpendDonutChart      ← 総 — Plan 05
            ├── SatisfactionDistributionHistogram OR (joint fallback continues)  ← 悦己 — Plan 05
            ├── AnalyticsScreenSectionHeader("物語")
            ├── LargestExpenseStoryCard      ← 総 — Plan 06
            ├── BestJoyStoryStrip            ← 悦己 — Plan 06
            └── FamilyInsightCard            ← 家族 (group mode only) — Plan 06
```

Per-card error/empty: each card wraps its provider with its own `AsyncValue.when` so a single failure does not break adjacent cards (UI-SPEC Interaction Contracts, `.planning/phases/11-statistics-surface-for/11-UI-SPEC.md:335`).

## ARB namespace (Plan 03 adds these)

Trilingual (ja/zh/en) — all 3 files updated in same commit per ARB-parity CI guardrail. Source-of-truth strings live in 11-UI-SPEC.md `## Copywriting Contract` (`.planning/phases/11-statistics-surface-for/11-UI-SPEC.md:174`) including concrete trilingual values.

Approximate count: ~30 keys under `analytics*` umbrella with sub-prefixes:

- `analyticsTitle`, `analyticsMonthChipPickerTooltip` — chrome
- `analyticsKpiTotalLabel`, `analyticsKpiTotalDeltaIncreased`, `analyticsKpiTotalDeltaDecreased`, `analyticsKpiJoyLabel`, `analyticsKpiJoySubMedianCoverage`, `analyticsKpiJoyEmptyCaption` — KPI
- `analyticsGroupHeaderTime`, `analyticsGroupHeaderDistribution`, `analyticsGroupHeaderStories` — themed-group H3
- `analyticsCardTitleTotalSixMonth`, `analyticsCardCaptionTotalSixMonth`, `analyticsCardTitleJoyTrend`, `analyticsCardCaptionJoyTrendGap` — 時間
- `analyticsCardTitleCategoryDonut`, `analyticsCardCaptionCategoryDonut`, `analyticsCardTitleSatisfactionHistogram`, `analyticsCardCaptionHistogram`, `analyticsHistogramBarFiveAnnotation` (HARD-LOCKED), `analyticsHistogramColorCaption` — 分布
- `analyticsCardTitleLargestExpense`, `analyticsCardEmptyLargestExpense`, `analyticsCardTitleBestJoy`, `analyticsCardSmallBestJoy`, `analyticsCardEmptyBestJoy`, `analyticsCardTitleFamilyInsight`, `analyticsFamilyHighlightsSentence`, `analyticsFamilySharedJoySentence`, `analyticsFamilyEmpty` — 物語
- `analyticsThinSampleFallbackHeading`, `analyticsThinSampleFallbackBody`, `analyticsThinSampleFallbackCta` — D-07
- `analyticsCardErrorHeading`, `analyticsCardErrorBody`, `analyticsCardErrorRetry` — error
- `analyticsCategoryDonutOther` — "その他" / "其他" / "Other" bucket label

Phase 12 RENAME-01..06 does **NOT** touch any `analytics*` key (namespace isolation — verified against REQUIREMENTS.md RENAME-01..04 which target only `soulLedger`/`survivalLedger`/`homeHappinessROI`/`homeSoulFullness`).

## DAO call sites

### Existing (analytics_dao.dart) — kept

- `getMonthlyTotals` (`lib/data/daos/analytics_dao.dart:99`) — feeds `MonthlyReport` via existing use cases
- `getCategoryTotals` (`lib/data/daos/analytics_dao.dart:138`) — feeds 類別支出 donut (already ORDER BY total DESC; widget takes top-N + bucket rest into "その他")
- `getDailyTotals` (`lib/data/daos/analytics_dao.dart:173`) — feeds 6か月推移 anchor logic
- `getLedgerTotals` (`lib/data/daos/analytics_dao.dart:207`) — feeds `MonthlyReport.ledgerSplit`
- `getSoulSatisfactionOverview` (`lib/data/daos/analytics_dao.dart:237`) — Phase 9 wired
- `getSatisfactionDistribution` (`lib/data/daos/analytics_dao.dart:268`) — Phase 9 wired
- `getBestJoyMoment` (`lib/data/daos/analytics_dao.dart:335`) — Phase 9 wired
- `getSoulRowsForPtvf` (`lib/data/daos/analytics_dao.dart:371`) — Phase 9 wired (monthly fold)
- `getSharedJoyCategoryInsight` (`lib/data/daos/analytics_dao.dart:403`) — Phase 9 wired

### NEW (Plan 02 adds these)

- `getDailySoulRowsForPtvf({bookId, startDate, endDate})` -> `List<DailySoulRowSampleWithDay>` — D-05 STATSUI-01. Mirror `getSoulRowsForPtvf` (`lib/data/daos/analytics_dao.dart:371`) shape; SELECT `DATE(timestamp,'unixepoch','localtime') AS day, amount, soul_satisfaction` with `_soulExpenseFilter` interpolation.
- `getLargestMonthlyExpense({bookId, startDate, endDate})` -> `LargestMonthlyExpense?` — STATSUI-06 物語 group 総 card. Mirror `getBestJoyMoment` (`lib/data/daos/analytics_dao.dart:335`) shape; SELECT `id, amount, category_id, timestamp` with `is_deleted = 0 AND type = 'expense'` filter (NOT `_soulExpenseFilter` — total ledger per D-15) ORDER BY `amount DESC, timestamp DESC` LIMIT 1.

### REMOVED (Plan 02 deletes this)

- `getDailySatisfactionTrend` (`lib/data/daos/analytics_dao.dart:300`) — orphan after Phase 9 wiring; superseded by `getDailySoulRowsForPtvf` per D-05. Verify zero callers before deletion (`rg -n "getDailySatisfactionTrend" lib test` returns only `lib/data/daos/analytics_dao.dart:300`).

## Deletions (Plan 07 atomic)

### Widgets (8 files)

- `lib/features/analytics/presentation/widgets/summary_cards.dart`
- `lib/features/analytics/presentation/widgets/category_pie_chart.dart`
- `lib/features/analytics/presentation/widgets/daily_expense_chart.dart`
- `lib/features/analytics/presentation/widgets/ledger_ratio_chart.dart`
- `lib/features/analytics/presentation/widgets/budget_progress_list.dart`
- `lib/features/analytics/presentation/widgets/expense_trend_chart.dart`
- `lib/features/analytics/presentation/widgets/category_breakdown_list.dart`
- `lib/features/analytics/presentation/widgets/month_comparison_card.dart`

### Tests (3 files — RESEARCH § Hidden imports of v1.0 widgets)

- `test/widget/features/analytics/presentation/widgets/analytics_money_widgets_test.dart`
- `test/widget/features/analytics/presentation/screens/analytics_screen_characterization_test.dart` — verify existence; currently absent in this worktree, so omit from actual delete list if still absent in Plan 07
- `test/golden/summary_cards_golden_test.dart`

Hidden-import audit confirmed via grep (RESEARCH § Hidden imports, `.planning/phases/11-statistics-surface-for/11-RESEARCH.md:772`): the 8 widget class names appear ONLY in (a) their own definition files, (b) `analytics_screen.dart`, (c) `analytics_money_widgets_test.dart`, and (d) `summary_cards_golden_test.dart`. No external `lib/` consumer.

## Atomicity rule (Plan 07 — Wave 3)

Plan 07 is a SINGLE atomic git commit containing ALL of:
1. Rewrite `lib/features/analytics/presentation/screens/analytics_screen.dart` (no v1.0 imports)
2. Delete the 8 widget files above
3. Delete the 3 test files above, subject to the absent-characterization-test check
4. Add `test/widget/features/analytics/presentation/screens/analytics_screen_test.dart` (replaces deleted characterization test)
5. Run `flutter analyze` -> must report 0 issues
6. Run `flutter test test/unit/features/analytics test/widget/features/analytics` -> must pass

Splitting Plan 07 into multiple commits causes intermediate `flutter analyze` red and breaks bisect. RESEARCH deletion order marks this CRITICAL (`.planning/phases/11-statistics-surface-for/11-RESEARCH.md:751`).

## Test additions (12 new tests across waves)

Wave 1 (Plan 02 + Plan 03):
- `test/unit/data/daos/analytics_dao_daily_joy_test.dart`
- `test/unit/data/daos/analytics_dao_largest_expense_test.dart`
- `test/unit/application/analytics/get_daily_joy_per_yen_use_case_test.dart`
- `test/unit/application/analytics/get_largest_monthly_expense_use_case_test.dart`

Wave 2 (Plans 04/05/06): 9 widget tests
- `joy_headline_kpi_tile_test.dart`
- `total_spending_kpi_tile_test.dart`
- `kpi_mini_hero_strip_test.dart`
- `month_chip_picker_test.dart`
- `monthly_spend_trend_bar_chart_test.dart`
- `joy_trend_line_chart_test.dart`
- `category_spend_donut_chart_test.dart`
- `satisfaction_distribution_histogram_test.dart`
- `largest_expense_story_card_test.dart`
- `best_joy_story_strip_test.dart` (or include with histogram test grouping per Plan 06)
- `family_insight_card_test.dart`
- `joy_ledger_thin_sample_fallback_test.dart`

Wave 3 (Plan 07): 1 screen test
- `test/widget/features/analytics/presentation/screens/analytics_screen_test.dart`

Wave 4 (Plan 08, optional): 2 golden tests
- `test/golden/joy_trend_line_chart_golden_test.dart`
- `test/golden/satisfaction_distribution_histogram_golden_test.dart`

## Wave structure

| Wave | Plan | Concern | Tasks (target) | Atomicity |
|------|------|---------|----------------|-----------|
| 0 | 11-01 | This audit doc | 1 | n/a |
| 1 | 11-02 | DAO + repo + domain models | 3 | per-task commits |
| 1 | 11-03 | Use cases + ARB + providers + use case anchor change | 3 | per-task commits |
| 2 | 11-04 | KPI strip + chrome widgets (4 files + tests) | 3 | per-widget commits |
| 2 | 11-05 | Chart widgets (4 files + tests) | 3 | per-widget commits |
| 2 | 11-06 | Story + family + thin-sample fallback (4 files + tests) | 3 | per-widget commits |
| 3 | 11-07 | AnalyticsScreen rewrite + 8 deletes + 3 test deletes (ATOMIC) | 1 | SINGLE commit |
| 4 | 11-08 | Goldens + ROADMAP/REQUIREMENTS/STATE update + worklog | 2-3 | per-task commits |

Plans 04/05/06 have no `files_modified` overlap with each other (each owns disjoint widget files), so they can run parallel. Plan 07 depends on 04+05+06 all being green.
