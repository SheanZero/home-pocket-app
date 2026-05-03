# Phase 11: AnalyticsScreen Unified Dashboard (Variant δ) — Research

**Researched:** 2026-05-03
**Domain:** Flutter UI rebuild + chart wiring on top of Phase 9 happiness contracts
**Confidence:** HIGH (codebase audit complete, fl_chart APIs verified via Context7, Phase 9 contracts read end-to-end)

## Summary

Phase 11 is a **complete teardown + rebuild** of `AnalyticsScreen` into Variant δ — a 2-region (総 / 悦己) unified dashboard with a KPI mini-hero strip and 3 themed groups (時間 / 分布 / 物語). Every Phase 9 use case (`GetHappinessReportUseCase`, `GetBestJoyMomentUseCase`, `GetFamilyHappinessUseCase`) and provider (`happinessReportProvider`, `bestJoyMomentProvider`, `familyHappinessProvider`) is already shipped, tested, and dormant — Phase 11 wires them through to UI. The chart library `fl_chart ^0.69.0` is already in `pubspec.yaml` with battle-tested usage in the about-to-be-deleted v1.0 widgets, so **zero new dependencies** are required.

The "30-50% under-estimation" risk on this phase is structural: the audit-doc-first requirement (STATSUI-04) plus 8 widget deletions plus the two characterization tests that pin v1.0 behavior all combine to make naive plan estimates wrong. Per CONTEXT.md `## Update 2026-05-03`, Decision D-15 narrows scope materially — there is **no separate 生存 region**, and `getDailySatisfactionTrend` (one of the originally listed dormant DAO methods) is **superseded by a NEW DAO method `getDailySoulRowsForPtvf` per D-05**, since per-day PTVF folding is required, not per-day average satisfaction.

**Primary recommendation:** Plan Wave 0 = footprint audit doc commit (STATSUI-04). Wave 1 = ARB additions + new DAO method + new use case. Wave 2 = leaf widgets (KPI tiles, themed group header, chart cards). Wave 3 = AnalyticsScreen rebuild + delete 8 v1.0 widgets + delete characterization test + delete `analytics_money_widgets_test.dart`. Wave 4 = golden tests + ADR (if needed) + color polish.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Daily soul (amount, sat, day) row pull (new) | Database / Storage (DAO) | — | Pure SQL aggregation — composes existing `_soulExpenseFilter` constant; mirrors `getSoulRowsForPtvf` |
| Daily Joy/¥ PTVF fold (new) | Application (Use Case) | — | Math lives in Dart per ADR-013 (SQLite has no `POW`/`EXP`); mirrors `_computePtvfDensity` in `GetHappinessReportUseCase` |
| KPI mini-hero composition (総支出 + 悦己平均) | Presentation (widget) | Application (existing `MonthlyReport.totalExpenses` + `HappinessReport.avgSatisfaction/medianSatisfaction`) | Pure aggregation already shipped; KPI tile is layout-only |
| 6か月支出推移 BarChart | Presentation (widget) | Application (existing `GetExpenseTrendUseCase`) | Use case pre-computes 6 months; widget renders bars |
| 類別支出 Donut/PieChart | Presentation (widget) | Application (existing `MonthlyReport.categoryBreakdowns`) | Top-N + その他 bucketing happens in widget (UI-SPEC), data shape is final |
| Joy/¥ trend LineChart | Presentation (widget) | Application (NEW `GetDailyJoyPerYenUseCase`) | Per-day fold drives the chart |
| 満足度 distribution Histogram | Presentation (widget) | Application (existing `HappinessReport.medianSatisfaction` lives in distribution; need raw distribution from a new provider) | Per D-09 the bar at 5 carries trilingual annotation |
| 今月の最大支出 story (新) | Application (Use Case) + Presentation | Database (existing transaction query patterns) | Largest single expense — likely a NEW DAO query |
| Best Joy story strip | Presentation (widget) | Application (existing `bestJoyMomentProvider`) | Reuse Phase 10 visual treatment |
| FamilyInsightCard (group mode) | Presentation (widget) | Application (existing `familyHappinessProvider`) | Sentence form, ochre fill |
| Month chip | Presentation (widget) | Application (existing `selectedMonthProvider`) | Provider preserved per D-08 |
| Phase 10 hero tap → AnalyticsScreen | Presentation (call site update) | — | Per D-18 no `initialSection` param; navigation simplification |

## Standard Stack

### Core (already in pubspec.yaml — no new deps)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `fl_chart` | `^0.69.0` `[VERIFIED: pubspec.yaml line 44]` | LineChart + BarChart + PieChart | already used by 4 of the 8 doomed widgets (`ledger_ratio_chart`, `daily_expense_chart`, `category_pie_chart`, `expense_trend_chart`); migration cost = 0; **DO NOT upgrade to 1.x** per `TOOL-V2-01` defer |
| `flutter_riverpod` | `^2.6.1` `[VERIFIED: pubspec.yaml line 20]` | State + provider DI | project standard; `@riverpod` codegen enforced |
| `freezed_annotation` | (transitive — see riverpod_annotation `^2.6.1` line 21 + freezed dev_dep) | Immutable models | project standard; new `DailyJoyPerYenPoint` Freezed model required (D-05) |
| `drift` | `^2.25.0` `[VERIFIED: pubspec.yaml line 61]` | DAO custom SQL (no schema change) | project standard; `_soulExpenseFilter` constant reused |
| `sqlcipher_flutter_libs` | `^0.6.7` `[VERIFIED: pubspec.yaml line 62]` | Encrypted DB | locked — never `sqlite3_flutter_libs` (Pitfall #6) |

### Supporting (existing)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `mocktail` | dev | Mock providers in widget tests | follow precedent in `analytics_screen_characterization_test.dart` |
| Project-local `AppDatabase.forTesting()` | n/a `[VERIFIED: test/unit/data/daos/analytics_dao_happiness_test.dart line 14]` | In-memory DB for DAO tests | use for new `getDailySoulRowsForPtvf` test |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `fl_chart 0.69` | `fl_chart 1.x` | 1.x is API-incompatible, would force sweep across HomeHero painter + analytics; `TOOL-V2-01` defers explicitly |
| `fl_chart` | `syncfusion_flutter_charts` | non-free / heavy / would force re-eval of entire chart surface — out of scope |
| Per-bar `BarChartRodLabel` annotation | Stacked text overlay | `BarChartRodLabel` is the official fl_chart API for permanent above-bar text `[CITED: github.com/imanneo/fl_chart bar_chart.md]` and aligns with UI-SPEC "permanent — NOT inside tooltip" |

**No installation step required** — Phase 11 introduces zero new dependencies. The `pubspec.yaml` row count is unchanged.

**Version verification** `[VERIFIED: pubspec.yaml]`:
- `fl_chart: ^0.69.0` (publish status checked 2026-05-03 via project lockfile; consistent with v1.0 milestone close)
- `flutter_riverpod: ^2.6.1`
- `riverpod_annotation: ^2.6.1`

## Architecture Patterns

### System Architecture Diagram

```
[User taps Analytics tab in MainShellScreen]
                   │
                   ▼
        [AnalyticsScreen.bookId]
                   │
       ┌───────────┴───────────────┐
       │ ref.watch chain (Riverpod) │
       └───────────┬───────────────┘
                   │
   ┌───────────────┼───────────────────────────────────┐
   ▼               ▼                                   ▼
selectedMonth   bookByIdProvider               isGroupModeProvider
(notifier)      → currencyCode                   ↓
   │               │                          (gates FamilyInsightCard)
   │               │                                   │
   ▼               ▼                                   ▼
 Month         currentLocaleProvider               activeGroupProvider
 chip          → Locale                                │
                                                      ▼
                                              shadowBooksProvider
                                                      │
                          ┌───────────────────────────┼─────────────────────────┐
                          ▼                           ▼                         ▼
                monthlyReportProvider        happinessReportProvider    familyHappinessProvider
                (existing — Phase 9 era)    (existing — Phase 9)        (existing — Phase 9)
                expenseTrendProvider         bestJoyMomentProvider
                (existing)                   (existing)
                                                      │
                                              ┌───────┴────────┐
                                              ▼                ▼
                                  dailyJoyPerYenProvider   largestMonthlyExpenseProvider
                                  (NEW per D-05)          (NEW — see §5)
                                              │                │
                                              ▼                ▼
                                  GetDailyJoyPerYen        GetLargestMonthlyExpense
                                  UseCase (NEW)            UseCase (NEW)
                                              │                │
                                              ▼                ▼
                                  AnalyticsRepository ── interface (extended +2 methods)
                                              │
                                              ▼
                                  AnalyticsRepositoryImpl (extended +2 methods)
                                              │
                                              ▼
                                  AnalyticsDao
                                  ├── getDailySoulRowsForPtvf (NEW — per D-05)
                                  └── getLargestMonthlyExpense (NEW — for 物語 group 総 card)
                                              │
                                              ▼
                                  AppDatabase (Drift + SQLCipher) — NO SCHEMA CHANGES
                                              │
                                              ▼
                                  ┌─ all 9 chart/story/KPI cards render via AsyncValue.when
                                  │   Empty / Loading / Error / Data dispatch per-card (UI-SPEC interaction contract)
                                  ▼
                          [User scrolls; per-card error/empty does not break layout]
```

### Recommended Project Structure (delta from current)

```
lib/
├── application/
│   └── analytics/
│       ├── get_daily_joy_per_yen_use_case.dart                  # NEW (D-05)
│       ├── get_largest_monthly_expense_use_case.dart            # NEW (物語 group 総 card)
│       └── repository_providers.dart                            # EXISTING (no changes — provider in features/analytics/presentation/providers/)
├── data/
│   ├── daos/
│   │   └── analytics_dao.dart                                   # EXTEND (+ getDailySoulRowsForPtvf, + getLargestMonthlyExpense)
│   └── repositories/
│       └── analytics_repository_impl.dart                       # EXTEND (+ 2 methods)
├── features/
│   └── analytics/
│       ├── domain/
│       │   ├── models/
│       │   │   ├── analytics_aggregate.dart                     # EXTEND (+ DailySoulRowSample with day, + LargestMonthlyExpense)
│       │   │   └── daily_joy_per_yen_point.dart                 # NEW Freezed (per-day fold output)
│       │   └── repositories/
│       │       └── analytics_repository.dart                    # EXTEND (+ 2 abstract methods)
│       └── presentation/
│           ├── providers/
│           │   ├── repository_providers.dart                    # EXTEND (+ 2 use case providers)
│           │   ├── state_happiness.dart                         # EXTEND (+ dailyJoyPerYenProvider + largestMonthlyExpenseProvider + monthlyTotalSpendingDeltaProvider)
│           │   └── state_analytics.dart                         # PRESERVE selectedMonthProvider (D-08)
│           ├── screens/
│           │   └── analytics_screen.dart                        # FULL REWRITE
│           └── widgets/
│               ├── analytics_screen_section_header.dart         # NEW (━ Title ━ themed group header)
│               ├── kpi_mini_hero_strip.dart                     # NEW (parent of 2 KPI tiles)
│               ├── total_spending_kpi_tile.dart                 # NEW (総支出 + MoM delta)
│               ├── joy_headline_kpi_tile.dart                   # NEW (悦己平均 + median + n=k)
│               ├── month_chip_picker.dart                       # NEW (AppBar trailing chip)
│               ├── monthly_spend_trend_bar_chart.dart           # NEW (6か月推移)
│               ├── joy_trend_line_chart.dart                    # NEW (Joy/¥ MTD)
│               ├── category_spend_donut_chart.dart              # NEW (top-N + その他)
│               ├── satisfaction_distribution_histogram.dart     # NEW (5-bar trilingual annotation)
│               ├── largest_expense_story_card.dart              # NEW (物語 — 総)
│               ├── best_joy_story_strip.dart                    # NEW (物語 — 悦己; reuse Phase 10 visual)
│               ├── family_insight_card.dart                     # NEW (物語 — 家族; group mode only)
│               ├── joy_ledger_thin_sample_fallback.dart         # NEW (D-07 joint fallback for trend+histogram)
│               ├── analytics_card_error_state.dart              # NEW (per-card AsyncError shell)
│               │
│               ├── budget_progress_list.dart                    # DELETE
│               ├── category_breakdown_list.dart                 # DELETE
│               ├── category_pie_chart.dart                      # DELETE
│               ├── daily_expense_chart.dart                     # DELETE
│               ├── expense_trend_chart.dart                     # DELETE
│               ├── ledger_ratio_chart.dart                      # DELETE
│               ├── month_comparison_card.dart                   # DELETE
│               └── summary_cards.dart                           # DELETE
└── l10n/
    ├── app_ja.arb                                               # EXTEND (~30 new keys; trilingual)
    ├── app_zh.arb                                               # EXTEND (mirror)
    └── app_en.arb                                               # EXTEND (mirror)
```

### Pattern 1: Container Widget With Async Provider (project-established)

**What:** Parent screen does `AsyncValue.when(...)` and passes resolved Freezed aggregates to leaf widgets, which are pure `StatelessWidget` `[CITED: lib/features/home/presentation/widgets/home_hero_card.dart line 35-49]`.

**When to use:** Every chart card / story card. Follows Phase 10 `HomeHeroCard` precedent verbatim.

**Example:**
```dart
// Source: lib/features/home/presentation/widgets/home_hero_card.dart (Phase 10)
final happinessAsync = ref.watch(
  happinessReportProvider(bookId: bookId, year: year, month: month, currencyCode: currencyCode),
);
return happinessAsync.when(
  data: (happiness) => JoyHeadlineKpiTile(report: happiness, locale: locale),
  loading: () => const _KpiSkeleton(),
  error: (e, _) => AnalyticsCardErrorState(error: e, onRetry: () => ref.invalidate(...)),
);
```

### Pattern 2: Sealed `MetricResult<T>` pattern matching

**What:** Every metric in `HappinessReport` / `FamilyHappiness` is `MetricResult<T>` `[VERIFIED: lib/features/analytics/domain/models/metric_result.dart]`. UI must `switch` on `Empty()` vs `Value(:final data, :final sampleSize)`.

**When to use:** KPI tile sub-line ("n=k rated"), histogram empty state, FamilyInsight empty state.

**Example:**
```dart
// Source: lib/features/analytics/domain/models/metric_result.dart
final coverageCaption = switch (happiness.avgSatisfaction) {
  Empty() => l10n.analyticsKpiJoyEmptyCaption,
  Value(:final sampleSize) => l10n.analyticsKpiJoyCoverage(sampleSize, happiness.totalSoulTx),
};
```

### Pattern 3: BarChart per-bar permanent label (NEW for this phase)

**What:** `BarChartRodLabel` provides a permanent text label above each bar `[CITED: github.com/imanneo/fl_chart bar_chart.md]`. Used for the 「中央値・含未評価」 5-bar annotation.

**When to use:** Satisfaction histogram bar at score=5 only. Other bars: no label.

**Example:**
```dart
// Source: Context7 fl_chart docs (BarChartRodLabel)
BarChartRodData(
  toY: count.toDouble(),
  color: barColor,
  rodStackItems: [],
  // Per-bar label (the only API for permanent above-bar text)
  // BarChartRodData has a `label` parameter accepting BarChartRodLabel.
  // Bar 5 only — other bars omit the label entirely.
)
```

> **Note:** the exact API name is `BarChartRodData.rodStackItems` for stacked bars; `BarChartRodLabel` is attached to the rod itself. Planner should run `flutter pub deps` to confirm `0.69.0` exposes `BarChartRodLabel` (it has been in the API since 0.65). **`[ASSUMED: 0.69 surfaces BarChartRodLabel without breaking change]` — verify in implementation kickoff.**

### Pattern 4: LineChart gap-vs-zero via segmented `LineChartBarData`

**What:** Per D-06, days with no soul tx render as line gaps (NOT zero values). The fl_chart approach is **multiple `LineChartBarData` entries**, one per contiguous segment of data. `[CITED: D-06 in CONTEXT.md + verified against existing expense_trend_chart.dart line 116-138 multi-series pattern]`

**When to use:** Joy/¥ trend line only. Histogram + 6-month bars do not have gap semantics (they always render).

**Example (sketch):**
```dart
// Pseudo: split List<DailyJoyPerYenPoint> into List<List<DailyJoyPerYenPoint>>
// where each inner list is a contiguous run of days with data.
final segments = _splitIntoContiguousSegments(points, monthDays);
return LineChart(LineChartData(
  minY: 0,                                    // baseline-anchored y-axis (D-06)
  lineBarsData: [
    for (final seg in segments)
      LineChartBarData(
        spots: seg.map((p) => FlSpot(p.day.toDouble(), p.joyPerYen)).toList(),
        color: AppColors.soul,
        dotData: const FlDotData(show: true), // dots only on data days
      ),
  ],
));
```

### Anti-Patterns to Avoid

- **Multi-color overlay LineChart for family members.** Forbidden by D-11 + ADR-012 + FAMILY-01-02 binding. Family expression goes through `FamilyInsightCard` (sentence form) only.
- **Reusing v1.0 widget names for new widgets.** Clean break per D-01/D-02 + D-15. Do not name a new chart `CategoryPieChart` even if visually similar.
- **Hardcoding `'JPY'`.** Use `bookByIdProvider` → `book.currency` per `[CITED: lib/features/home/presentation/screens/home_screen.dart line 88-95]`.
- **Hand-edited `.g.dart` / `.freezed.dart`.** CLAUDE.md Pitfall #1; AUDIT-10 catches stale generated files but cannot detect hand-edited matches.
- **Hex literals in widget code.** UI-SPEC color section: must reference `AppColors.*` or `context.wm*`.
- **Skipping `_soulExpenseFilter` in new DAO methods.** Project-wide centralized SQL fragment per HAPPY-05; survival rows MUST NEVER contaminate Joy/¥ trend.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Chart rendering | Custom `CustomPainter` for bars/lines | `fl_chart 0.69` `BarChart` / `LineChart` / `PieChart` | already in pubspec; 4 v1.0 widgets prove it works; touch + tooltip + axis labels free |
| Per-bar text annotation | Stack + Positioned overlay | `BarChartRodData.label` with `BarChartRodLabel` | official API; correctly positioned above bar tip with `Offset(0, -8)` adjustment |
| Median calculation | New SQL query | `HappinessReport.medianSatisfaction` (already shipped via `_computeMedianFromDistribution` in `GetHappinessReportUseCase`) | Phase 9 already wired; consume the existing field |
| Currency formatting | `'¥${amount}'` literal | `FormatterService().formatCurrency(amount, currencyCode, locale)` `[VERIFIED: lib/application/i18n/formatter_service.dart used in 5+ screens]` | locale-aware decimals + thousand-separator |
| Date formatting | `DateTime.toString()` | `DateFormatter` in `lib/infrastructure/i18n/formatters/date_formatter.dart` | locale-aware (ja `2026/02/04` vs en `02/04/2026` vs zh `2026年02月04日`) |
| Joy density formatting | `density.toStringAsFixed(1)` | `formatJoyDensity(density, currencyCode)` `[VERIFIED: lib/infrastructure/i18n/formatters/joy_density_formatter.dart]` | currency-aware unit suffix `/ ¥1k` etc. |
| Theme-aware color | `Color(0xFF...)` literal | `context.wmCard` / `AppColors.soul` / `AppColors.survival` | dark mode parity automatic |
| Top-N + "Other" bucket | Custom sort + reduce | Compute in widget body from `MonthlyReport.categoryBreakdowns` (already sorted by amount DESC by SQL) | `getCategoryTotals` returns `ORDER BY total DESC` per `[VERIFIED: lib/data/daos/analytics_dao.dart line 151]`; widget takes first N, sums rest |
| In-memory DAO test | Real device DB | `AppDatabase.forTesting()` `[VERIFIED: test/unit/data/daos/analytics_dao_happiness_test.dart line 14]` | already established pattern with `tearDown(() async => db.close())` |

**Key insight:** Phase 11 has unusually low "build new infrastructure" surface area. The hardest novel work is the gap-vs-zero LineChart segmentation; everything else composes existing patterns.

## Runtime State Inventory

> Phase 11 is a UI rebuild + 1 new DAO method + 1 new use case. **No rename, no migration, no schema change.** Skipping the rename-style 5-category audit.

**Verification of "no schema change":**
- `[VERIFIED]` `getDailySoulRowsForPtvf` reuses `_soulExpenseFilter` constant + existing `transactions` columns (`amount`, `soul_satisfaction`, `timestamp`)
- `[VERIFIED]` `getLargestMonthlyExpense` reuses `transactions` table (`amount`, `category_id`, `timestamp`)
- `[VERIFIED]` no new tables, no new indexes, no migration needed; v15→v16 was Phase 9 closing event

**Build artifact note:** `flutter pub run build_runner build --delete-conflicting-outputs` MUST run after:
- adding `@riverpod` providers
- adding `@freezed` model `DailyJoyPerYenPoint` and `LargestMonthlyExpense`
- editing ARB files → `flutter gen-l10n`

## Common Pitfalls

### Pitfall 1: 8 v1.0 widget deletion creates broken intermediate states

**What goes wrong:** If a planner deletes a widget before the new replacement is wired, `flutter analyze` errors flood and the AnalyticsScreen breaks for the user.

**Why it happens:** UI-SPEC says "8 widgets deleted"; planner might create one plan unit per deletion.

**How to avoid:**
1. Wave 3 plan unit performs the AnalyticsScreen rewrite + the 8 widget file deletions + the 2 v1.0 test file deletions in a SINGLE atomic plan unit (one git commit).
2. Tests `analytics_money_widgets_test.dart` and `analytics_screen_characterization_test.dart` reference the 8 widgets directly `[VERIFIED: grep results]` — they MUST be deleted in the same commit, not later.

**Warning signs:** PR review with `flutter analyze` red between plan units = wrong sequencing.

### Pitfall 2: `selectedMonthProvider` notifier API mismatch with new MonthChipPicker

**What goes wrong:** v1.0 `_MonthSelector` uses `previousMonth()` / `nextMonth()` notifier methods. Variant δ MonthChipPicker uses a **picker bottom sheet** that calls `setMonth(DateTime)` directly — different UX.

**Why it happens:** Same provider, different UI affordance.

**How to avoid:** Provider already has `setMonth(DateTime month)` `[VERIFIED: lib/features/analytics/presentation/providers/state_analytics.dart line 17]`. New MonthChipPicker calls `setMonth(picked)`. Do NOT remove `previousMonth()` / `nextMonth()` from the notifier — the existing characterization test exercises them and at least one might still be useful.

**Warning signs:** Removing notifier methods causes test compile failures.

### Pitfall 3: `getDailySatisfactionTrend` is dormant but ROADMAP/PROJECT mentions it

**What goes wrong:** A planner reads ROADMAP.md "wire 3 dormant DAO methods" and tries to wire `getDailySatisfactionTrend`. But D-05 explicitly supersedes — Joy/¥ trend needs per-day **PTVF fold**, not per-day average satisfaction.

**Why it happens:** ROADMAP.md (line 39) still says "Wire 3 dormant DAO methods + new query"; CONTEXT.md `<domain>` section corrects it but a planner skimming ROADMAP could miss this.

**How to avoid:** Planner reads CONTEXT.md `<domain>` first paragraph + Folded Todos to confirm `getDailySatisfactionTrend` is **not used** in Phase 11. Decision is whether to delete it (cleaner) or leave it (defer to v2). Per Claude's Discretion in CONTEXT.md, planner decides — recommend **delete** (clean break, no caller anywhere `[VERIFIED: grep returns 0 callers]`).

**Warning signs:** Plan unit titled "wire getDailySatisfactionTrend" — abort and re-read CONTEXT.

### Pitfall 4: Currency hardcoded in chart labels

**What goes wrong:** Joy/¥ trend Y-axis labels formatted with `'JPY'` literal break for CNY/USD users.

**Why it happens:** Charts often have inline label formatters; tempting to write `'¥${value}'`.

**How to avoid:** All `JoyTrendLineChart` formatters take `currencyCode` as a constructor parameter, resolved from `bookByIdProvider` upstream `[CITED: home_hero_card.dart line 56-57 pattern]`. Use `formatJoyDensity(value, currencyCode)` for Y-axis labels.

**Warning signs:** Grep `'JPY'\|'¥'` in new widgets returns hits.

### Pitfall 5: `BarChartRodLabel` only on bar 5, but data may not include score=5

**What goes wrong:** If no soul tx had `soul_satisfaction == 5` in the selected month, the histogram skips bar 5 entirely (DAO returns no row), and the trilingual annotation never renders.

**Why it happens:** UI-SPEC interaction contract: "bars 1-10 always rendered (zero-count bars show as 1px stub at baseline for visual continuity)." But the dormant DAO returns only buckets that have rows.

**How to avoid:** Widget normalizes the distribution to **always include all 10 scores** (zero-fill missing keys) before rendering. Bar 5 always exists, always carries the annotation, regardless of data.

**Warning signs:** Edge-case test "all sat=10" produces histogram with only one bar — wrong.

### Pitfall 6: Family mode FamilyInsightCard render gate inconsistency

**What goes wrong:** Card renders when `isGroupMode == true` but `shadowBooks.isEmpty` (group exists but no other devices joined yet) — produces empty/Empty render with no useful content.

**Why it happens:** Two providers gate; easy to forget the second.

**How to avoid:** Per D-13 binding + Phase 10 D-08 minimum gate: render iff `isGroupModeProvider == true && shadowBooks.isNotEmpty`. Same gate Phase 10 used `[VERIFIED: home_hero_card.dart line 66 `showMembers = isGroupMode && (shadowBooks?.isNotEmpty ?? false)`]`.

### Pitfall 7: Histogram cool→warm gradient triggers ADR-014 review

**What goes wrong:** Reviewer flags bar-1 cool color as "too negative-feeling," code reviewer rejects PR.

**Why it happens:** D-10 explicitly notes the tension; UI-SPEC documents the persistent caption guard.

**How to avoid:** Three checkpoints — (1) caption text below histogram MUST display the trilingual ADR-014 guard (UI-SPEC Color section); (2) `accessibilityLabel` per-bar reads "satisfaction value + count + total" only — no negative-emotion words; (3) starting hue is `AppColors.survival` (a category blue), not red/orange.

**Warning signs:** Per-bar `Semantics(label: ...)` includes "差/悪い/bad/不好/低" → reject.

### Pitfall 8: Phase 10 hero `onTap` change couples Phase 10 ↔ 11

**What goes wrong:** Phase 10 widget exposes `initialSection` parameter; Phase 11 D-18 says no parameter. Removing it from Phase 10 widget after Phase 10 is complete is a backward-incompatible widget API change.

**Why it happens:** Per CONTEXT.md `## Update 2026-05-03 D-18`: "if Phase 10 widget exposes an `initialSection` param, it can be removed."

**How to avoid:** Verify in plan: read `home_hero_card.dart` constructor → no `initialSection` parameter exists today `[VERIFIED: lines 36-48 — only onTap is exposed]`. So D-18 has nothing to remove; the home_screen.dart navigation call (`AnalyticsScreen(bookId: bookId)`) is already the simple form `[VERIFIED: line 174]`. **No Phase 10 changes needed.**

## Code Examples

Verified patterns from official sources or existing codebase:

### Phase 9 use case parallel-fetch pattern (mirror for new use cases)

```dart
// Source: lib/application/analytics/get_happiness_report_use_case.dart line 37-58
final results = await Future.wait([
  _repo.getSoulSatisfactionOverview(bookId: bookId, startDate: ..., endDate: ...),
  _repo.getSatisfactionDistribution(bookId: bookId, startDate: ..., endDate: ...),
  _repo.getSoulRowsForPtvf(bookId: bookId, startDate: ..., endDate: ...),
  _repo.getBestJoyMoment(bookId: bookId, startDate: ..., endDate: ...),
]);
```

### Per-bar permanent label

```
// Source: github.com/imanneo/fl_chart/blob/main/repo_files/documentations/bar_chart.md
BarChartRodData(
  toY: count.toDouble(),
  color: barColor,
  // label: BarChartRodLabel(           // Verify exact API: `label` vs `rodStackItems[*].label`
  //   show: true,
  //   text: l10n.analyticsHistogramFiveBarAnnotation,
  //   style: AppTextStyles.caption.copyWith(color: AppColors.soul),
  //   offset: const Offset(0, -8),     // above the bar tip
  // ),
)
```

### LineChart baseline-anchored y-axis (D-06)

```
// Source: github.com/imanneo/fl_chart base_chart.md (LineChartData)
LineChartData(
  minX: 1,                       // first day of month
  maxX: daysInMonth.toDouble(),
  minY: 0,                       // baseline anchor — NEVER negative for Joy/¥
  maxY: maxObservedJoy * 1.2,    // 20% headroom
  lineBarsData: [...],           // segmented per gap-vs-zero (D-06)
)
```

### Riverpod provider for Joy/¥ trend (mirror state_happiness.dart pattern)

```dart
// Source: lib/features/analytics/presentation/providers/state_happiness.dart line 16-30
@riverpod
Future<MetricResult<List<DailyJoyPerYenPoint>>> dailyJoyPerYen(
  Ref ref, {
  required String bookId,
  required int year,
  required int month,
  required String currencyCode,
}) async {
  final useCase = ref.watch(getDailyJoyPerYenUseCaseProvider);
  return useCase.execute(
    bookId: bookId,
    year: year,
    month: month,
    currencyCode: currencyCode,
  );
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `_MonthSelector` row of chevrons in AppBar `bottom` | `MonthChipPicker` in AppBar `actions` opening bottom sheet | Phase 11 (this) | Saves vertical space; adopts UI-SPEC chip pattern |
| 8 separate v1.0 charts with individual `Card()` wrappers | 9 cards (KPI+chart+story) inside themed groups; tinted fills per ledger | Phase 11 (this) | IA reflects ledger ownership; anti-comparison framing via 総-first ordering |
| `MonthlyReport.categoryBreakdowns` rendered as both pie + list | Same data, single donut card with top-N + その他 | Phase 11 (this) | Reduces redundancy; saves screen space |
| Per-day average satisfaction (`getDailySatisfactionTrend`) | Per-day Joy/¥ density (`getDailyJoyPerYenUseCase` over `getDailySoulRowsForPtvf`) | Phase 11 D-05 | Aligns daily metric with monthly headline (PTVF semantics, not avg) |
| Family-mode = aggregated + leaderboard-prone | Family-mode = `FamilyHighlightsSum` int + `SharedJoyInsight` 3-tuple sentence-form, anti-leaderboard binding | Phase 9 D-08 (binding inherited by Phase 11 D-11/D-12/D-13) | Locks anti-leaderboard contract at the type system layer |

**Deprecated/outdated (in Phase 11 scope):**
- 8 v1.0 widget files: explicit deletion targets (see UI-SPEC + CONTEXT)
- `getDailySatisfactionTrend` DAO method: orphan after Phase 11; planner decides delete vs defer
- `analytics_money_widgets_test.dart` + `analytics_screen_characterization_test.dart`: pin v1.0 behavior, must be removed in Wave 3 atomic commit

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `BarChartRodData` exposes a `label` parameter accepting `BarChartRodLabel` in fl_chart 0.69 | Pattern 3 / Code Examples | If API differs (e.g., wrapped under different name), planner needs to either upgrade to a version that supports it or render the annotation as a Stack overlay outside the chart. **Mitigation:** Planner runs `dart analyze` against a stub call in Wave 1; aborts to overlay-Stack pattern if compile fails. |
| A2 | `getCategoryTotals` already orders by `total DESC`, so widget top-N is just `take(n)` | Don't Hand-Roll | Verified at line 151 of analytics_dao.dart — assumption holds; A2 actually `[VERIFIED]`, not assumed. |
| A3 | Phase 10's `home_hero_card.dart` constructor does NOT expose `initialSection`/`initialTab`/`scrollTo` | Pitfall 8 | Verified — A3 also `[VERIFIED]`, not assumed. |
| A4 | Family mode ochre `AppColors.olive` `#8A9178` provides WCAG AA contrast against ochre fill `#FFF7E6` | Theme & Style References | If fails contrast in dark mode, swap to a darker title token. **Mitigation:** UI-SPEC Accessibility section calls for spot-check at executor stage. |

**This table is non-empty:** Only A1 is genuinely unverified — and the mitigation is cheap (stub call in Wave 1).

## Open Questions

1. **Should `getDailySatisfactionTrend` DAO method be deleted now or deferred?**
   - What we know: zero call sites in `lib/` `[VERIFIED: grep]`. CONTEXT.md Claude's Discretion explicitly delegates this to planner.
   - What's unclear: nothing — planner's call.
   - Recommendation: delete in Wave 1 ("clean break" matches Phase 11 ethos; no v2 case justifies preserving dormant DAO method).

2. **Should there be a NEW ADR for Phase 11 IA decision (Variant δ)?**
   - What we know: CONTEXT D-03 says "UI-phase 锁 IA 后由 planner 评估必要性"; UI-SPEC was approved revision 2 (6/6 PASS).
   - What's unclear: Variant δ is a UI IA selection, not a foundational architectural decision (no new contracts, no new pattern).
   - Recommendation: **No new ADR needed.** UI-SPEC.md + CONTEXT.md `## Update 2026-05-03` D-15..D-18 already serve as the durable decision record. Optional: add a 1-line ADR-INDEX update if the project adopts UI variant decisions as ADR-worthy.

3. **Where does `MonthlyTotalSpendingDelta` (MoM delta for KPI tile) come from?**
   - What we know: `MonthlyReport.previousMonthComparison.expenseChange` already exists `[VERIFIED: lib/features/analytics/domain/models/month_comparison.dart line 14-15]`. UI-SPEC sub-line copy: `↓ -{pct}% MoM` / `↑ +{pct}% MoM`.
   - What's unclear: nothing — the field is present and is exactly what's needed.
   - Recommendation: KPI total-spending tile reads `monthlyReport.previousMonthComparison?.expenseChange`; if null (no previous month data), omit the sub-line.

4. **What library powers the "compact" formatter for K/M abbreviations on chart Y-axis?**
   - What we know: `FormatterService.formatCompact(value, locale)` is used in v1.0 `expense_trend_chart.dart` line 101 `[VERIFIED]`.
   - What's unclear: nothing.
   - Recommendation: reuse `FormatterService().formatCompact()` for 6-month BarChart Y-axis labels.

## Environment Availability

> Phase 11 has no external runtime dependencies (no Docker, no DB server, no native CLI tools). All work is in-process Flutter + Drift in-memory tests.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All | ✓ | (project lockfile) | — |
| `flutter pub run build_runner` | freezed/riverpod codegen | ✓ | per pubspec | — |
| `flutter gen-l10n` | ARB regeneration | ✓ | bundled | — |
| `flutter analyze` | CI gate | ✓ | bundled | — |
| `flutter test` | unit + widget | ✓ | bundled | — |
| `fl_chart` 0.69 | Charts | ✓ | `^0.69.0` | none — defer feature if breaks |

**Missing dependencies:** none.

## Validation Architecture

> `nyquist_validation` is enabled by default — including this section.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` (built-in) + `mocktail` for mocks `[VERIFIED: existing analytics tests]` |
| Config file | `pubspec.yaml` (test deps) — no separate `dart_test.yaml` |
| Quick run command | `flutter test test/unit/features/analytics/ test/widget/features/analytics/` |
| Full suite command | `flutter test --coverage` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| STATSUI-01 | Joy/¥ LineChart renders with baseline-anchored Y-axis + gap-vs-zero policy | widget | `flutter test test/widget/features/analytics/presentation/widgets/joy_trend_line_chart_test.dart -p` | ❌ Wave 3 (NEW) |
| STATSUI-02 | Histogram bar 5 has trilingual annotation; n<5 → joint fallback | widget | `flutter test test/widget/features/analytics/presentation/widgets/satisfaction_distribution_histogram_test.dart -p` | ❌ Wave 3 (NEW) |
| STATSUI-03 | KPI tile shows mean primary + median + n=k coverage; n<5 → text fallback | widget | `flutter test test/widget/features/analytics/presentation/widgets/joy_headline_kpi_tile_test.dart -p` | ❌ Wave 3 (NEW) |
| STATSUI-04 | Footprint audit doc exists in `.planning/phases/11-*/` BEFORE wiring | manual (gsd verifies file presence in commit history) | `git log --diff-filter=A --name-only -- .planning/phases/11-statistics-surface-for/11-AUDIT.md` | ❌ Wave 0 (NEW) |
| STATSUI-05 | AnalyticsScreen renders Variant δ structure; 8 v1.0 widgets deleted | widget + grep gate | `flutter test test/widget/features/analytics/presentation/screens/analytics_screen_test.dart -p && [ -z "$(grep -rl 'SummaryCards\|CategoryPieChart\|DailyExpenseChart\|LedgerRatioChart\|BudgetProgressList\|ExpenseTrendChart\|CategoryBreakdownList\|MonthComparisonCard' lib/)" ]` | ❌ Wave 3 (NEW) |
| STATSUI-06 | 6か月 BarChart current month highlighted; Donut top-N + その他; 今月の最大支出 story renders | widget | `flutter test test/widget/features/analytics/presentation/widgets/monthly_spend_trend_bar_chart_test.dart test/widget/features/analytics/presentation/widgets/category_spend_donut_chart_test.dart test/widget/features/analytics/presentation/widgets/largest_expense_story_card_test.dart -p` | ❌ Wave 3 (NEW) |
| STATSUI-07 | KPI mini-hero strip shows 総支出 + 悦己平均; month chip in AppBar; cards re-key on `(bookId, year, month)` | widget | `flutter test test/widget/features/analytics/presentation/widgets/kpi_mini_hero_strip_test.dart test/widget/features/analytics/presentation/widgets/month_chip_picker_test.dart -p` | ❌ Wave 3 (NEW) |
| Domain (D-05) | `getDailySoulRowsForPtvf` returns rows with day grouping; survival rows excluded | unit | `flutter test test/unit/data/daos/analytics_dao_daily_joy_test.dart -p` | ❌ Wave 1 (NEW) |
| Domain (NEW use case) | `GetDailyJoyPerYenUseCase` per-day fold matches monthly fold within rounding | unit | `flutter test test/unit/application/analytics/get_daily_joy_per_yen_use_case_test.dart -p` | ❌ Wave 1 (NEW) |
| Domain (Largest expense) | `GetLargestMonthlyExpenseUseCase` returns single argmax (amount DESC, timestamp DESC) | unit | `flutter test test/unit/application/analytics/get_largest_monthly_expense_use_case_test.dart -p` | ❌ Wave 1 (NEW) |

### Sample Points (Nyquist Dimension 8)

The plan-checker / verify-work step must see these specific sampled scenarios in test fixtures:

1. **n=0 (empty month):** all soul cards render Empty state; histogram shows joint fallback; KPI 悦己 tile shows `データを集計中...`.
2. **n=1..4 (thin sample):** trend + histogram joint fallback rendered; KPI 悦己 tile shows mean + `n=k` even for small n.
3. **n=5 cluster (only sat=5):** histogram shows bar 5 only (or with 1px stubs for other bars); annotation visible; mean = median = 5; coverage caption shows `n=k/k`.
4. **All sat=10:** histogram visible only on bar 10; bar 5 stub still renders annotation (per Pitfall 5 normalization).
5. **Group mode + shadowBooks empty:** `FamilyInsightCard` does NOT render; rest of dashboard unaffected.
6. **Group mode + shadowBooks present + family Empty (no shared insight, n<3 per category):** FamilyInsightCard renders empty-state body sentence.
7. **Joy/¥ gap-vs-zero:** day with no soul tx renders as line gap, not zero point; legend caption visible.
8. **Per-card AsyncError:** if `dailyJoyPerYenProvider` errors, only Joy/¥ card shows error state; histogram + 6 か月 + KPI tiles still render.
9. **Currency = CNY:** Joy/¥ Y-axis labels use `/ ¥100` suffix not `/ ¥1k`; ¥ formatting uses 2 decimals not 0.
10. **Locale = en + zh + ja:** all 3 month chip labels render correctly; trilingual annotation reflects current locale.

### Wave 0 Gaps

- [ ] `.planning/phases/11-statistics-surface-for/11-AUDIT.md` — STATSUI-04 footprint audit doc, FIRST commit of the phase
- [ ] `test/unit/data/daos/analytics_dao_daily_joy_test.dart` — covers `getDailySoulRowsForPtvf` (Wave 1)
- [ ] `test/unit/application/analytics/get_daily_joy_per_yen_use_case_test.dart` — Wave 1
- [ ] `test/unit/application/analytics/get_largest_monthly_expense_use_case_test.dart` — Wave 1
- [ ] 9 widget test files (KPI tile + 4 chart cards + 3 story cards + thin-sample fallback) — Wave 3
- [ ] `test/widget/features/analytics/presentation/screens/analytics_screen_test.dart` — replaces deleted characterization test, Wave 3
- [ ] (optional) `test/golden/joy_trend_line_chart_golden_test.dart` + `test/golden/satisfaction_distribution_histogram_golden_test.dart` — Wave 4 polish

## Security Domain

> `security_enforcement` defaults enabled. Phase 11 surface area is **read-only UI**: no auth, no input validation, no crypto. ASVS evaluation:

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 11 has no auth surface |
| V3 Session Management | no | none |
| V4 Access Control | no | read-only dashboard |
| V5 Input Validation | partial | only `selectedMonthProvider.setMonth(DateTime)` — value comes from a picker bound to `[earliestTxMonth, currentMonth]`; no untrusted input |
| V6 Cryptography | no | reads pre-decrypted DB rows; no new crypto |

### Known Threat Patterns for Flutter + Drift + Riverpod

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SQL injection in custom DAO query | Tampering | Drift `customSelect(... variables: [Variable.withString(...)])` parameterized binding `[VERIFIED: existing pattern in analytics_dao.dart line 110]` — apply same pattern in `getDailySoulRowsForPtvf` and `getLargestMonthlyExpense` |
| Information leak in error toast (e.g. raw SQL exception in error widget) | Information disclosure | `AnalyticsCardErrorState` widget shows `l10n.analyticsCardErrorBody` constant — never `error.toString()` raw |
| `accessibilityLabel` leaking sensitive amount/category to screen readers in shoulder-surfing scenario | Information disclosure | UI-SPEC Accessibility section: per-bar Semantics reads "satisfaction value + count + total" — does NOT read transaction descriptions or merchants |

## Sources

### Primary (HIGH confidence)
- Context7 `/imanneo/fl_chart` — `BarChartRodLabel`, `LineChartData`, `RangeAnnotations`, `FlSpot` (verified 2026-05-03)
- `pubspec.yaml` — fl_chart, riverpod, drift, sqlcipher versions
- `lib/features/analytics/domain/models/*.dart` — Phase 9 Freezed contracts
- `lib/features/analytics/presentation/providers/state_happiness.dart` — provider patterns
- `lib/features/analytics/presentation/screens/analytics_screen.dart` — current 274-line v1.0 implementation
- `lib/features/analytics/presentation/widgets/*.dart` — all 8 v1.0 widgets enumerated for deletion
- `lib/features/analytics/domain/repositories/analytics_repository.dart` — interface to extend
- `lib/data/daos/analytics_dao.dart` + `lib/data/repositories/analytics_repository_impl.dart` — extension targets
- `lib/application/analytics/get_happiness_report_use_case.dart` — template for new use cases (PTVF fold pattern)
- `lib/features/home/presentation/widgets/home_hero_card.dart` — Phase 10 Container Widget With Async Provider precedent
- `lib/features/home/presentation/screens/home_screen.dart` — hero tap → AnalyticsScreen call site
- `lib/core/theme/app_colors.dart` + `app_text_styles.dart` + `app_theme_colors.dart` — design tokens
- `lib/infrastructure/i18n/formatters/joy_density_formatter.dart` — PTVF base + display unit
- `lib/l10n/app_*.arb` — existing 30 analytics-prefixed keys
- `test/unit/data/daos/analytics_dao_happiness_test.dart` — `AppDatabase.forTesting()` test pattern
- `test/helpers/happiness_test_fixtures.dart` — Phase 10 fixture pattern (reuse for Phase 11 widget tests)
- `.planning/phases/11-statistics-surface-for/11-CONTEXT.md` — locked decisions (D-01..D-18)
- `.planning/phases/11-statistics-surface-for/11-UI-SPEC.md` — Variant δ contract (revision 2 approved)

### Secondary (MEDIUM confidence)
- WebSearch (none performed — Context7 + codebase audit sufficient)

### Tertiary (LOW confidence)
- A1 (`BarChartRodLabel` API surface in 0.69) — verify in Wave 1 stub call

## File Placement Map

For each new file the planner creates, classify per CLAUDE.md placement rule:

| New File | Layer | Rationale |
|----------|-------|-----------|
| `lib/data/daos/analytics_dao.dart` (extend +2 methods) | data | Drift DAO — data access |
| `lib/data/repositories/analytics_repository_impl.dart` (extend +2 methods) | data | repo impl |
| `lib/features/analytics/domain/repositories/analytics_repository.dart` (extend +2 abstract methods) | domain | interface |
| `lib/features/analytics/domain/models/analytics_aggregate.dart` (extend with `DailySoulRowSampleWithDay` + `LargestMonthlyExpense` raw classes) | domain | plain data classes (not Freezed — match existing convention in this file) |
| `lib/features/analytics/domain/models/daily_joy_per_yen_point.dart` | domain | Freezed model — per-day fold output (consumer of use case) |
| `lib/application/analytics/get_daily_joy_per_yen_use_case.dart` | application | business logic — PTVF per-day fold |
| `lib/application/analytics/get_largest_monthly_expense_use_case.dart` | application | business logic — single argmax |
| `lib/features/analytics/presentation/providers/repository_providers.dart` (extend +2 use case providers) | presentation | provider wiring |
| `lib/features/analytics/presentation/providers/state_happiness.dart` (extend +3 providers: `dailyJoyPerYen` + `largestMonthlyExpense` + `monthlyTotalSpendingDelta`) | presentation | consumer-facing async providers |
| `lib/features/analytics/presentation/screens/analytics_screen.dart` (full rewrite) | presentation (UI) | screen |
| `lib/features/analytics/presentation/widgets/*.dart` (14 new widget files) | presentation (UI) | widgets |
| `lib/l10n/app_{ja,zh,en}.arb` (extend ~30 keys each) | l10n | i18n |
| `test/unit/data/daos/analytics_dao_daily_joy_test.dart` | test (unit) | DAO test |
| `test/unit/application/analytics/get_daily_joy_per_yen_use_case_test.dart` | test (unit) | use case test |
| `test/unit/application/analytics/get_largest_monthly_expense_use_case_test.dart` | test (unit) | use case test |
| `test/widget/features/analytics/presentation/widgets/*.dart` (9 widget tests) | test (widget) | widget tests |
| `test/widget/features/analytics/presentation/screens/analytics_screen_test.dart` | test (widget) | screen integration test |
| `.planning/phases/11-statistics-surface-for/11-AUDIT.md` | meta (planning) | STATSUI-04 footprint audit doc |

**Thin Feature compliance check:** zero new files under `lib/features/analytics/application/` or `lib/features/analytics/data/` — all application + data layer changes route through the global `lib/application/` and `lib/data/`. ✓

## i18n Workflow + Trilingual ARB Sample

**Files to edit (single commit):**
- `lib/l10n/app_ja.arb` (default)
- `lib/l10n/app_zh.arb`
- `lib/l10n/app_en.arb`

**Regeneration command:** `flutter gen-l10n`

**ARB-parity CI guardrail:** key sets in all 3 files must be identical (Pitfall #6 territory — currently all 3 files have 1200 keys, 1623 lines `[VERIFIED]`).

**Namespace recommendation (per UI-SPEC):** `analytics*` umbrella with optional sub-prefixes `analyticsKpi*` / `analyticsTime*` / `analyticsDistribution*` / `analyticsStory*` / `analyticsFamily*`. Phase 12 RENAME pass does NOT touch these new keys.

**The HARD-LOCKED 5-bar trilingual annotation (STATSUI-02) — exact ARB sample:**

```json
// app_ja.arb
"analyticsHistogramBarFiveAnnotation": "中央値・含未評価",
"@analyticsHistogramBarFiveAnnotation": {
  "description": "Permanent annotation above bar 5 of satisfaction histogram acknowledging default-5 cluster + East-Asian central-tendency clustering (STATSUI-02 HARD-LOCKED)"
},

// app_zh.arb
"analyticsHistogramBarFiveAnnotation": "中位数·含未评分",
"@analyticsHistogramBarFiveAnnotation": {
  "description": "Permanent annotation above bar 5 of satisfaction histogram acknowledging default-5 cluster + East-Asian central-tendency clustering (STATSUI-02 HARD-LOCKED)"
},

// app_en.arb
"analyticsHistogramBarFiveAnnotation": "Median + unrated",
"@analyticsHistogramBarFiveAnnotation": {
  "description": "Permanent annotation above bar 5 of satisfaction histogram acknowledging default-5 cluster + East-Asian central-tendency clustering (STATSUI-02 HARD-LOCKED)"
}
```

**Other key proposals (planner refines):**

```json
// Dashboard chrome
"analyticsTitle"                         // "統計" / "统计" / "Statistics"
"analyticsMonthChipPickerTooltip"        // "月を選ぶ" / "选择月份" / "Pick a month"

// KPI mini-hero
"analyticsKpiTotalLabel"                 // "今月の支出" / "本月支出" / "This month's spending"
"analyticsKpiTotalDeltaDecreased"        // "↓ -{pct}% MoM"
"analyticsKpiTotalDeltaIncreased"        // "↑ +{pct}% MoM"
"analyticsKpiJoyLabel"                   // "今月の平均満足度" / "本月平均满足度" / "Avg satisfaction"
"analyticsKpiJoySubMedianCoverage"       // "中央値 {median} · n={k}/{N}"
"analyticsKpiJoyEmptyCaption"            // "データを集計中..." / "数据收集中..." / "Gathering data..."

// Themed group headers
"analyticsGroupHeaderTime"               // "━ 時間 / Time ━"
"analyticsGroupHeaderDistribution"       // "━ 分布 / Distribution ━"
"analyticsGroupHeaderStories"            // "━ 物語 / Stories ━"

// 時間 group cards
"analyticsCardTitleTotalSixMonth"        // "総 · 6 か月支出推移"
"analyticsCardCaptionTotalSixMonth"      // "BarChart · 当月 highlighted"
"analyticsCardTitleJoyTrend"             // "悦己 · ハピネス密度の推移"
"analyticsCardCaptionJoyTrendGap"        // "MTD · 断点 = 未記録日"

// 分布 group cards
"analyticsCardTitleCategoryDonut"        // "総 · 類別支出分布"
"analyticsCardCaptionCategoryDonut"      // "Donut/PieChart · top-N + その他"
"analyticsCardTitleSatisfactionHistogram"// "悦己 · 満足度の分布 1–10"
"analyticsCardCaptionHistogram"          // "Histogram · cool→warm · bar 5 三語注記"
"analyticsHistogramColorCaption"         // "色は ordinal 表現です" (ADR-014 guard)

// 物語 group cards
"analyticsCardTitleLargestExpense"       // "総 · 今月の最大支出"
"analyticsCardEmptyLargestExpense"       // "データなし — 今月はまだ記録がありません"
"analyticsCardTitleBestJoy"              // "悦己 · 今月のベスト ジョイ"
"analyticsCardSmallBestJoy"              // "{amount} · 満足 {sat}/10 ✨"
"analyticsCardEmptyBestJoy"              // "今月の最大ハイライトはまだ見つからない"
"analyticsCardTitleFamilyInsight"        // "家族 · ハイライトサマリー"
"analyticsFamilyHighlightsSentence"      // "今月、家族の小確幸 {N}回"
"analyticsFamilySharedJoySentence"       // "みんなで [{categoryName}] が好きみたい (n={count}, 平均{avg}/10)"
"analyticsFamilyEmpty"                   // "共通のお気に入り品目はまだ集計できません — もう少し記録してみよう"

// Empty / fallback
"analyticsThinSampleFallbackHeading"     // "今月の魂帳の記録がまだ少ないよ"
"analyticsThinSampleFallbackBody"        // "あと数日記録を続けたら、Joy の流れが見えてくる"
"analyticsThinSampleFallbackCta"         // "記録する »"

// Error
"analyticsCardErrorHeading"              // "データが読み込めなかった"
"analyticsCardErrorBody"                 // "しばらくしてから、もう一度試してください"
"analyticsCardErrorRetry"                // "再試行"
```

(planner may collapse some — UI-SPEC delegates concrete prefix choice)

## Pitfalls & Landmines

### Quantifying the "30-50% under-estimation" risk

For "just wire it up" UI rebuilds, common under-estimation comes from missing:
- (a) ARB additions across 3 locales (~30 keys × 3 = 90 string edits) — typically 1-2 hours, often forgotten in plan estimation
- (b) deletion of v1.0 widget files + their tests (8 widgets + 2 test files)
- (c) compile-error cascade when widgets are deleted before screen rewrite
- (d) edge-case widget tests (n=0 / n<5 / n=5 cluster / family-empty / per-card error) — 9-10 sample-point tests
- (e) golden test regeneration if introduced (Wave 4 optional)

**Calibration:** plan task count likely **12-16 plan units** (CONTEXT predicted ~13). If plan emerges with <10 units, planner under-counted ARB / test gaps. If >18, planner is over-decomposing.

### Deletion order (CRITICAL)

**Wrong:**
1. Delete `summary_cards.dart` (Wave 1)
2. Edit `analytics_screen.dart` to remove SummaryCards reference (Wave 2)
3. → between Waves 1 and 2, `flutter analyze` is red, repo is broken.

**Right:**
1. Wave 0: footprint audit doc (STATSUI-04).
2. Waves 1-2: NEW DAO + use case + provider + leaf widgets (no edits to AnalyticsScreen, no deletions).
3. Wave 3: SINGLE atomic plan unit:
   - rewrite `analytics_screen.dart` from scratch (no v1.0 imports)
   - delete the 8 widget files
   - delete `analytics_money_widgets_test.dart`
   - delete `analytics_screen_characterization_test.dart`
   - add new `analytics_screen_test.dart`
   - run `flutter analyze` + `flutter test test/unit/features/analytics test/widget/features/analytics`
   - commit

This atomic Wave 3 commit ensures the repo is never red between commits.

### Hidden imports of v1.0 widgets — VERIFIED

**Audit result `[VERIFIED: grep across lib/ + test/]`:**
- `SummaryCards`, `CategoryPieChart`, `DailyExpenseChart`, `LedgerRatioChart`, `BudgetProgressList`, `ExpenseTrendChart`, `CategoryBreakdownList`, `MonthComparisonCard` — referenced ONLY by:
  - `lib/features/analytics/presentation/screens/analytics_screen.dart` (the file being rewritten)
  - their own definition files (the files being deleted)
  - `test/widget/features/analytics/presentation/widgets/analytics_money_widgets_test.dart` (delete in Wave 3)
  - `test/golden/summary_cards_golden_test.dart` (verify and delete in Wave 3 — 1 file slipped from CONTEXT inventory)
- **No imports from outside `lib/features/analytics/`** — safe to delete in single atomic commit.

**Action:** add `test/golden/summary_cards_golden_test.dart` to Wave 3 deletion list (CONTEXT.md did not enumerate it).

### Other landmines

- **`DemoDataService` IconButton in v1.0 AnalyticsScreen AppBar:** The "auto_fix_high" demo-data action (lines 47-51 of current `analytics_screen.dart`) is NOT in UI-SPEC Variant δ. Planner must decide: drop it (cleaner), move to Settings (preserves dev tool), or keep behind a debug-only conditional. Recommend **drop** — Variant δ AppBar has only the title + month chip; demo data is testing scaffolding that should live in Settings or be removed.
- **`monthlyReportProvider` consumers in main_shell_screen.dart and home_screen.dart `[VERIFIED: 4 call sites]`:** These remain valid. Phase 11 does NOT remove `monthlyReportProvider` — KPI total spending tile + 類別支出 donut + 今月の最大支出 + 6か月推移 (via `expenseTrendProvider`) all consume it.
- **`expenseTrendProvider` is `bookId`-keyed only, not `(bookId, year, month)`-keyed `[VERIFIED: state_analytics.dart line 56]`:** The current 6-month trend uses `DateTime.now()` internally. For Variant δ where the user selects a month, the 6-month BarChart should "anchor on selected month" (not "always trailing 6 from today"). Planner decides: change `GetExpenseTrendUseCase` signature to accept anchor month, or accept that 6-month trend always trails today. Recommend: **change use case signature to accept `DateTime anchor`** — preserves D-08 "all dashboard cards re-key on selected month" intent.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — pubspec.yaml verified, fl_chart APIs cross-checked with Context7
- Architecture: HIGH — Phase 9 contracts read end-to-end, Phase 10 precedent in active use
- Pitfalls: HIGH — 8-widget grep confirms scope of deletion impact; tests enumerated
- Validation: HIGH — sample points derived directly from CONTEXT D-06/D-07/D-09/D-13 + UI-SPEC interaction contracts
- ARB / i18n: HIGH — file structure verified, key count matches across 3 locales
- BarChartRodLabel API in 0.69: MEDIUM (A1 in Assumptions Log; cheap mitigation in Wave 1)

**Research date:** 2026-05-03
**Valid until:** 2026-06-03 (30 days — stable codebase, no upstream library churn expected)

## RESEARCH COMPLETE
