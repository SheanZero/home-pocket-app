# Phase 46: 卡片体系 (Cards) - Pattern Map

**Mapped:** 2026-06-17
**Files analyzed:** 18 (5 new cards/screen + 3 new widgets + 3 new app/provider paths + 3 rebuilds + 8 deletes)
**Analogs found:** 11 / 11 net-new files (every new file has a same-role, same-data-flow in-repo analog)

> This repo is Flutter / Riverpod 3 (codegen) / Drift Clean-Architecture 5-layer. There are NO controllers/middleware — roles map to: **card** (presentation `ConsumerWidget`), **chart-widget** (presentation `StatelessWidget`), **screen** (presentation `ConsumerWidget` route host), **use-case** (application), **provider** (`@riverpod` family), **domain-helper** (pure transform), **model** (`@freezed`).

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `widgets/cards/within_month_trend_card.dart` (NEW) | card | request-response (watch 1 family + `.when`) | `cards/satisfaction_histogram_card.dart` (pill-tab/multi-state) + `cards/category_donut_card.dart` | exact (role) / role-match (pill tabs + line are new) |
| `widgets/within_month_cumulative_line_chart.dart` (NEW) | chart-widget | transform→render | `widgets/category_spend_donut_chart.dart` (fl_chart wiring) + `widgets/satisfaction_distribution_histogram.dart` (BarChart) | role-match (no `LineChart` exists; closest fl_chart wiring) |
| `widgets/cards/joy_spend_card.dart` (NEW, 悦己花在哪) | card | request-response | `cards/category_donut_card.dart` | exact |
| `widgets/joy_spend_stacked_bar.dart` (NEW, R-1 custom Row) | chart-widget | transform→render (NOT fl_chart) | `widgets/category_spend_donut_chart.dart` `_LegendItem`/`Wrap` + `Color.lerp` ambient | role-match |
| `widgets/cards/joy_calendar_card.dart` (NEW, 小确幸日历) | card | request-response | `cards/category_donut_card.dart` | exact |
| `widgets/joy_calendar_heatmap.dart` (NEW, R-2 custom GridView) | chart-widget | transform→render (NOT fl_chart) | `widgets/satisfaction_distribution_histogram.dart` `_colorForScore` ambient `f(value)→color` | role-match (custom grid is new) |
| `screens/category_drill_down_screen.dart` (NEW) | screen (route host) | request-response, read-only list | `home_screen.dart:223,249,353` push pattern + drill provider | role-match |
| `cards/category_donut_card.dart` (REBUILD) | card | request-response + tap→push | itself + `home_screen.dart` Navigator.push | exact |
| `cards/satisfaction_histogram_card.dart` + `widgets/satisfaction_distribution_histogram.dart` (REBUILD) | card + chart-widget | request-response (REDES-02 native label) | itself (delete Stack hack) | exact |
| `analytics_card_registry.dart` (MODIFY) | provider/registry | spec-list re-order | itself | exact |
| `application/analytics/get_within_month_cumulative_use_case.dart` (NEW) | use-case | batch/transform over `findByBookIds` | `get_category_drill_down_use_case.dart` + `get_expense_trend_use_case.dart` (per-ledger split) | exact (role) |
| per-day-cumulative trend provider (NEW, in `state_analytics.dart`) | provider | request-response family | `monthlyReportProvider` / `categoryDrillDownProvider` in `state_analytics.dart` | exact |
| per-day-joy COUNT provider (NEW, in `state_analytics.dart`) | provider | request-response family | `satisfactionDistributionProvider` | exact |
| per-L1 joy AMOUNT rollup (NEW use-case/provider) | use-case + domain-helper | transform | `get_category_drill_down_use_case.dart` + `l1RollupFromTransactions` (`category_l1_rollup.dart`) | exact |
| 8 DELETEs (best_joy / kpi_hero / largest_expense / total_six_month cards; monthly_spend_trend_bar_chart; analytics_screen_section_header widgets; get_expense_trend_use_case; expense_trend model) | — | — | — | see § Deletions |

---

## Pattern Assignments

### `widgets/cards/within_month_trend_card.dart` (card, request-response) — NEW

**Analogs:** `cards/satisfaction_histogram_card.dart` (multi-async `.when`, single-source `refreshTargets`), `cards/category_donut_card.dart` (minimal shape).

**Card skeleton + single-source refreshTargets** (copy structure from `category_donut_card.dart:25-89`):
- `ConsumerWidget` with `bookId/startDate/endDate/joyMetricVariant` fields.
- `build`: `final targets = <card>RefreshTargets(_ctx());` then `ref.watch(<newTrendProvider>(...))` → `.when(data/loading/error)`.
- `loading: () => const SizedBox(height: 280)`; `error: (_, _) => AnalyticsCardErrorState(onRetry: () => ref.invalidate(targets.single))`.
- Wrap chart in `AnalyticsDataCard(title:, caption:, child:)` with `S.of(context)` l10n keys.
- Provide a top-level `List<ProviderBase<Object?>> withinMonthTrendRefreshTargets(AnalyticsCardContext ctx)` returning the new provider keyed off `ctx` — exactly the `categoryDonutRefreshTargets` shape (`category_donut_card.dart:80-89`).

**Pill tabs (总支出/日常/悦己):** no exact analog in-repo. Planner: a local `StatefulWidget`/`StateProvider` selecting which ledger series the line chart renders. Joy tab = single line, NO `prevMonth` series (D-E1, Pitfall 2).

**Family-key normalization (D-12, mandatory):** the trend provider keys on a MONTH-anchored value, not raw instants — see `analytics_card_registry.dart:116-120` (`trendAnchor = DateTime(range.end.year, range.end.month)`) and the defensive `DateBoundaries.dayRange(...)` re-normalization in `state_analytics.dart:83-84`.

---

### `widgets/within_month_cumulative_line_chart.dart` (chart-widget) — NEW

**Analog:** `widgets/category_spend_donut_chart.dart` (fl_chart wiring + palette + legend) — there is NO `LineChart` anywhere in `lib/` (grep-confirmed), so copy the fl_chart import/`SizedBox(height:)`/palette pattern, swap `PieChart`→`LineChart`.

**fl_chart wiring pattern** (`category_spend_donut_chart.dart:1-52`):
```dart
import 'package:fl_chart/fl_chart.dart';
// ...
final palette = context.palette;
return SizedBox(
  height: 200,
  child: PieChart(PieChartData(sections: [...], centerSpaceRadius: 38)),
);
```
For `LineChart`: build `LineChartData(lineBarsData: [...])`, one `LineChartBarData` per series. Spend side = 2 series (本月 solid `isStrokeCapRound`, 上月 dashed via `dashArray: [4,4]`); joy side = 1 series. Color via `context.palette` (ADR-019): daily `palette.daily`, joy `palette.joy`. `[VERIFY field shapes against installed fl_chart 1.2.0 LineChartBarData API during planning — A3]`.

**Ambient color rule** (copy `_colorFor`, donut chart `:105-109`): `Color.lerp(palette.daily, palette.joy, t)`.

---

### `widgets/cards/joy_spend_card.dart` (card) + `widgets/joy_spend_stacked_bar.dart` (R-1 custom Row) — NEW

**Card analog:** `category_donut_card.dart` (identical skeleton).

**Widget analog:** `category_spend_donut_chart.dart` — reuse its single-column legend idiom and `Wrap`/`_LegendItem` (`:55-65,124-148`) but render the bar as `Row(children: [Flexible(flex: amount, child: ColoredBox(...))])` (R-1, NOT fl_chart — GATE-04). Segments largest→smallest. tap-segment → in-place highlight (local `StatefulWidget` selected-index; no drill — D-C2).

**Count-up anchor (D-D2):** the header "悦己 ¥…" total uses `TweenAnimationBuilder` ~400-600ms (Flutter built-in, ADR-012-safe). No in-repo count-up analog — Flutter built-in, see RESEARCH Don't-Hand-Roll.

**Legend `_LegendItem` excerpt to mirror** (`category_spend_donut_chart.dart:124-148`):
```dart
Row(mainAxisSize: MainAxisSize.min, children: [
  Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
  const SizedBox(width: 6),
  Text(label, style: AppTextStyles.caption.copyWith(color: context.palette.textSecondary)),
]);
```

---

### `widgets/cards/joy_calendar_card.dart` (card) + `widgets/joy_calendar_heatmap.dart` (R-2 custom GridView) — NEW

**Card analog:** `category_donut_card.dart`.

**Widget:** custom `GridView`/`Wrap` month grid (R-2, NOT fl_chart). Color-depth = `f(per-day joy COUNT)` ambient — copy the `f(value)→color` lerp idiom from `satisfaction_distribution_histogram.dart:162-171` (`_colorForScore` → `Color.lerp(palette.daily, palette.joy, t)`). tap-day → INLINE expand (local state; the card grows in place, NOT a sheet/route — D-C1).

**Day cell join precaution (Pitfall 3):** the heatmap needs per-day joy COUNT, not SUM, and `getDailyTotals` has NO ledger filter — see provider section below.

---

### `screens/category_drill_down_screen.dart` (screen, read-only) — NEW

**Navigation analog:** `lib/features/home/presentation/screens/home_screen.dart:223,249,353` — the app uses imperative `Navigator.push(MaterialPageRoute)`. **There is NO GoRouter** (CLAUDE.md is stale — RESEARCH confirmed). The donut legend-row tap pushes this screen.

**Push pattern (from donut card's new legend tap → drill):**
```dart
Navigator.of(context).push(MaterialPageRoute<void>(
  builder: (_) => CategoryDrillDownScreen(bookId: bookId, l1CategoryId: l1Id),
));
```

**Inside the screen:** `ConsumerWidget`; `ref.watch(selectedTimeWindowProvider)` for the window (keepAlive session state — Phase 45 D-C1, only `l1CategoryId` passed in), then `ref.watch(categoryDrillDownProvider(bookId:, startDate:, endDate:, l1CategoryId:))` — provider already exists (`state_analytics.dart:72-91`, auto-dispose, D-12 normalized).

**Header (D-B2):** subtotal + count + avgPerDay — all three are fields on `CategoryDrillDown` (use case `get_category_drill_down_use_case.dart:88-97` already computes `avgPerDay`). Pure description, no targets.

**Read-only tile (D-B3):** reuse `ListTransactionTile` (`list_transaction_tile.dart:30-49`) with DISABLED `onTap` (edit) and DISABLED swipe-delete. The tile takes required `onTap`/`onDeleted` `VoidCallback`s — pass no-op closures, and the parent does NOT wrap in `Dismissible`. Planner picks: no-op callbacks vs a read-only variant (Discretion). All display values (`tagText`, `formattedAmount`, `l1Icon`, etc.) are pre-formatted by the parent (pure-UI contract — `:63-69`).

---

### `cards/category_donut_card.dart` (REBUILD) — donut hero + tappable 10-row legend

**Current state:** `category_donut_card.dart` already watches `monthlyReportProvider` (`:43-50`) and renders `CategorySpendDonutChart`. **Changes:** (1) legend → 10 L1-rollup rows via `rollupCategoryBreakdownsToL1` (`category_l1_rollup.dart:78-101`) instead of the donut chart's internal top-5 `_buildSlices`; (2) each legend ROW is fully tappable → `Navigator.push` drill (above); (3) optional `PieChartSectionData.cornerRadius: 4` (fl_chart 1.2.0, REDES-02); (4) center "本月支出" total = `TweenAnimationBuilder` count-up (D-D2).

**L1 rollup is the single source (D-11, Don't-Hand-Roll):** donut slice AND drill header BOTH derive from `rollupCategoryBreakdownsToL1` / `l1RollupFromTransactions` — never write a second rollup loop.

---

### `widgets/satisfaction_distribution_histogram.dart` + `cards/satisfaction_histogram_card.dart` (REBUILD) — REDES-02

**The card stays as-is** (`satisfaction_histogram_card.dart` — keep the `totalJoyTx < 5` self-hide and both `refreshTargets`). **Only the widget changes.**

**DELETE the Stack hack** at `satisfaction_distribution_histogram.dart:35-138` — the `Stack` wrapping `BarChart` + the `Align`/`DecoratedBox` "5" annotation overlay (`:111-138`). **Replace with native `BarChartRodData.label`** (fl_chart 1.2.0, changelog #2071). The existing `BarChartRodData` is at `:81-91`:
```dart
BarChartRodData(
  toY: bucket.count == 0 ? 1 : bucket.count.toDouble(),
  color: _colorForScore(bucket.score, palette),
  width: 14,
  borderRadius: const BorderRadius.only(
    topLeft: Radius.circular(4), topRight: Radius.circular(4)),
  // ADD: native label field (replaces the Align/DecoratedBox overlay) — verify exact field shape against 1.2.0 API
);
```
Keep `_colorForScore` (`:162-171`), `_normalize` (`:154-160`), `_semanticLabel` (`:173-180`) verbatim. The `analyticsHistogramBarFiveAnnotation` l10n key + its `ValueKey('analytics_histogram_bar_5_annotation')` move onto the native label.

---

### `analytics_card_registry.dart` (MODIFY) — re-order to round-5 B flat 5-card list

**This is a spec-list re-order, NOT a mechanism rewrite** (Phase 45 D-B1 mechanism stays). The `AnalyticsCardSpec` list at `:222-351` is the single source for render order AND `_refresh` union.

**New order (D-F2):** within_month_trend → category_donut → joy_spend → joy_calendar → satisfaction_histogram → [family_insight `isVisible:(ctx)=>ctx.isGroupMode`].

**Edits:**
- DELETE specs: KpiHero (`:224-234`), TotalSixMonth (`:236-245`), DailyVsJoy (`:259-270`), both PerCategoryBreakdown (`:283-306`), LargestExpense (`:308-319`), BestJoy (`:321-331`). Keep CategoryDonut, SatisfactionHistogram, FamilyInsight (`:339-350`).
- REMOVE all `sectionHeaderKey:` usages (`:237,248,309`) — D-F2 deletes section headers.
- REMOVE imports of deleted cards (`:15,18,19,21,22,23`).
- ADD new specs + their `refreshTargets` closures (mirror `categoryDonutRefreshTargets` shape) for the 3 new cards.
- KEEP `family_insight` spec exactly (D-F1) — including its `shadowBooksAsync` null-placeholder shell-injection note (`:332-350`).
- UPDATE `analytics_card_registry_test.dart` expected shape (5 cards + 1 conditional) in the same change (Pitfall 4).

---

### `application/analytics/get_within_month_cumulative_use_case.dart` (NEW use-case)

**Analogs:** `get_category_drill_down_use_case.dart` (reuse-first `findByBookIds` + Dart transform) + `get_expense_trend_use_case.dart` (per-ledger zero-default split).

**Reuse-first fetch** (copy `get_category_drill_down_use_case.dart:43-50`):
```dart
final txns = await _txRepo.findByBookIds(
  bookIds, startDate: s, endDate: e, categoryId: null,
  sortField: SortField.timestamp, sortDirection: SortDirection.asc);
```
2-month window (current + prev month). Then Dart-side: group by day, running cumulative sum, per-ledger split. **Per-ledger zero-default pattern** (copy `get_expense_trend_use_case.dart:48-56`):
```dart
int dailyTotal = 0, joyTotal = 0;
for (final lt in ledgerTotals) {
  if (lt.ledgerType == 'daily') dailyTotal = lt.totalAmount;
  else if (lt.ledgerType == 'joy') joyTotal = lt.totalAmount;
}
```
NO new DAO, NO migration (RESEARCH Flag 1). Security: pass ONLY caller `bookIds`, never widen (`get_category_drill_down_use_case.dart:42` comment, threat T-44-03-03); never log tx contents.

---

### New providers in `state_analytics.dart`

**Analog:** every existing provider here (`monthlyReportProvider :15-34`, `categoryDrillDownProvider :72-91`, `satisfactionDistributionProvider :110-129`).

**`@riverpod` family pattern** (copy `:15-34`):
```dart
@riverpod
Future<X> withinMonthCumulativeTrend(Ref ref, {
  required String bookId,
  required DateTime anchor,         // MONTH-anchored, NOT raw (D-12)
  JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
}) async {
  final useCase = ref.watch(getWithinMonthCumulativeUseCaseProvider);
  final entrySourceFilter = joyMetricVariant == JoyMetricVariant.manualOnly
      ? EntrySource.manual : null;
  return useCase.execute(...);
}
```
- All auto-dispose (`@riverpod` default — `:69` comment "never kept alive, D-14"), ZERO `home/*` reads (GUARD-01).
- D-12 defensive normalization via `DateBoundaries` before the key (copy `:83-84`).
- **Per-day-joy COUNT provider:** needs COUNT-per-day, not SUM. `getDailyTotals` has NO ledger filter (Pitfall 3) — either Dart-group `findByBookIds(ledgerType:'joy')` (zero new DAO) OR add `String? ledgerType` + COUNT variant to `getDailyTotals` (thin SQL, no migration). Planner's call (Discretion / Open Q2).
- **Per-L1 joy AMOUNT:** `PerCategoryJoyBreakdown` is SATISFACTION not amount (Pitfall 5) — new transform: `findByBookIds(ledgerType:'joy')` → `l1RollupFromTransactions` per L1 (reuse `category_l1_rollup.dart:111-131`).
- REMOVE `expenseTrendProvider` (`:36-54`) + the `expense_trend.dart` import (`:7`).

---

## Shared Patterns

### Card = single-source ConsumerWidget (Phase 45 contract — apply to ALL new/rebuilt cards)
**Source:** `cards/category_donut_card.dart:39-89`
- One `ConsumerWidget` watching exactly ONE provider family.
- A top-level `<card>RefreshTargets(AnalyticsCardContext ctx)` function is the SINGLE source for both the registry `_refresh` union AND the card's error-retry (`ref.invalidate(targets.single)` / `targets[i]`).
- Multi-async cards nest `.when` and index targets (`satisfaction_histogram_card.dart:48,81,87`).

### Family-key normalization (D-12, mandatory — apply to ALL new providers + trend/calendar keys)
**Source:** `analytics_card_registry.dart:116-120` (month-anchor) + `state_analytics.dart:83-84` (`DateBoundaries.dayRange`)
Normalize window bounds to whole-day/month BEFORE they enter a provider family key, or microsecond-exact rebuilds storm.

### Reuse-first Dart aggregation over `findByBookIds` (apply to trend + joy-amount + per-day-joy)
**Source:** `get_category_drill_down_use_case.dart:43-86`
When no DAO query gives the needed shape, fetch the window via `findByBookIds` and transform in Dart. No new DAO, no migration. Filter `tx.type == TransactionType.expense` where the surface is expense-only (`:61-63`).

### L1 rollup single source-of-truth (apply to donut + joy_spend + drill)
**Source:** `lib/features/analytics/domain/category_l1_rollup.dart`
`rollupCategoryBreakdownsToL1` (breakdowns→L1) and `l1RollupFromTransactions` (raw tx→L1) both route through `l1AncestorOf` — never write a second rollup loop (D-11, Don't-Hand-Roll).

### Imperative navigation (apply to drill route — NO GoRouter)
**Source:** `home_screen.dart:223,249,353`
`Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ...))`. CLAUDE.md "Routing: GoRouter" is stale.

### Ambient `f(value)→color` (apply to calendar heatmap + joy stacked bar)
**Source:** `satisfaction_distribution_histogram.dart:162-171` + `category_spend_donut_chart.dart:105-109`
`Color.lerp(palette.daily, palette.joy, t)` from `context.palette` (ADR-019). Ambient depth only — NO target ring / progress ring / streak (ADR-016 §5, D-A4; analytics shows zero Joy target ring — that is HomeHero-exclusive).

### Amount display + palette (apply everywhere)
**Source:** `category_spend_donut_chart.dart:43`, CLAUDE.md
Monetary values use `AppTextStyles.amountLarge/Medium/Small` (tabular figures). Colors via `context.palette` (ADR-019 桜餅×若葉). Captions `AppTextStyles.caption`. All UI text via `S.of(context)` — never hardcode.

---

## Deletions (verify zero external refs — already confirmed by grep)

All 8 deletion targets are referenced ONLY by `analytics_card_registry.dart` + the analytics screen + their own tests (grep-confirmed):

| Delete | Referenced by (all to be cleaned in same change) |
|--------|--------------------------------------------------|
| `cards/best_joy_card.dart` | registry, registry_test |
| `cards/kpi_hero_card.dart` | registry, registry_test |
| `cards/largest_expense_card.dart` | registry, registry_test |
| `cards/total_six_month_card.dart` | registry, registry_test |
| `widgets/monthly_spend_trend_bar_chart.dart` | total_six_month_card, monthly_spend_trend_bar_chart_test |
| `widgets/analytics_screen_section_header.dart` | analytics_screen, analytics_screen_test |
| `application/analytics/get_expense_trend_use_case.dart` | state_analytics (`expenseTrendProvider`), repository_providers, get_expense_trend_use_case_test |
| `domain/models/expense_trend.dart` (+ `.freezed.dart` + `.g.dart`) | get_expense_trend_use_case, state_analytics, analytics_providers_characterization_test, expense_trend_test |

**Also remove:** `expenseTrendProvider` (`state_analytics.dart:36-54`), its `expense_trend.dart` import (`:7`), and any UNIQUE-only ARB keys / `getExpenseTrendUseCaseProvider` wiring in `repository_providers.dart`. Run `build_runner` after deleting the freezed/riverpod-annotated files (removes `expense_trend.g.dart`/`.freezed.dart`, regenerates `state_analytics.g.dart`).

**Test files to delete/update together (Pitfall 4):** `get_expense_trend_use_case_test.dart`, `expense_trend_test.dart`, `monthly_spend_trend_bar_chart_test.dart` (delete); `analytics_card_registry_test.dart`, `analytics_screen_test.dart`, `analytics_no_delta_ui_test.dart`, `analytics_refresh_group_mode_test.dart`, `analytics_providers_characterization_test.dart` (update expected shape).

---

## No Analog Found

No net-new file is analog-less, but two sub-patterns have NO in-repo precedent (use RESEARCH / Flutter built-ins):

| Sub-pattern | Role | Reason | Source to use instead |
|-------------|------|--------|------------------------|
| `LineChart` (within-month trend) | chart-widget | grep: zero `LineChart` in `lib/` | fl_chart 1.2.0 `LineChart` API (mirror donut/histogram wiring; RESEARCH Code Examples) |
| pill tabs (总/日常/悦己) | card sub-control | no segmented tab control in analytics cards | local `StatefulWidget`/`StateProvider` (planner) |
| `TweenAnimationBuilder` count-up | animation | no count-up in repo | Flutter built-in (RESEARCH Don't-Hand-Roll; D-D2) |

---

## Metadata

**Analog search scope:** `lib/features/analytics/presentation/{widgets,widgets/cards,screens,providers}`, `lib/application/analytics/`, `lib/features/analytics/domain/`, `lib/features/list/presentation/widgets/`, `lib/features/home/presentation/screens/`.
**Files scanned (read in full):** category_donut_card, satisfaction_histogram_card, satisfaction_distribution_histogram, category_spend_donut_chart, category_l1_rollup, get_category_drill_down_use_case, get_expense_trend_use_case, analytics_card_registry, state_analytics, list_transaction_tile. **Grep-confirmed:** dead-code reference closure, zero `LineChart`.
**Pattern extraction date:** 2026-06-17
