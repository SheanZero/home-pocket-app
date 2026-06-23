# Phase 46: 卡片体系 (Cards) - Research

**Researched:** 2026-06-17
**Domain:** Flutter presentation-layer (analytics cards), fl_chart 1.2.0, reuse-first data wiring, custom widgets, anti-gamification (ADR-012)
**Confidence:** HIGH (all 3 research flags resolved against live source with file:line evidence)

<user_constraints>
## User Constraints (from 46-CONTEXT.md)

### Locked Decisions (verbatim from `<decisions>`)

**A. 卡片阵容对账 (核心交付边界)**
- **D-A1:** round-5 B 为唯一真相 — 严格只建 5 卡。JOY-01/JOY-02 视为已由设计重新承载（不另画独立"值得"headline 卡）。**JOY-03 记忆故事 + JOY-04 kakeibo Q4 随 round-5 B drop，零加回。**
- **D-A2:** Phase 46 含需求台账补正 doc 任务 — `REQUIREMENTS.md` JOY-03/JOY-04 标 Descoped (superseded by GATE-03 round-5 B)；`ROADMAP.md` Phase 46 SC #3 重写为实际 5 卡阵容。
- **D-A3:** 彻底删除 round-5 B 不含的旧卡 — `best_joy_card.dart` / `kpi_hero_card.dart` / `largest_expense_card.dart` 及其唯一专属 widget/provider/ARB key（`find_referencing_symbols` 逐个确认无他用后删）。`family_insight_data_card` 不删（D-F1）。`total_six_month_card.dart` 由新 within-month line card 替换。
- **D-A4:** ADR-016 Joy 指标 (Σ joy_contribution) 保持 HomeHero 独占；analytics 卡零展示。

**B. 分类下钻落地**
- **D-B1:** 入口 = donut 下方 10 行 L1 图例「整行可点」→ push route。不点扇区。
- **D-B2:** 下钻页顶部小结 = 小计 + 笔数 + 日均（中性描述量，ADR-012-safe）。
- **D-B3:** 下钻交易列表 = 只读（复用 `ListTransactionTile`，禁 swipe-删除 + tap-编辑）。

**C. 两张新自定义卡的交互**
- **D-C1:** 小确幸日历热力 = 自定义 `GridView`/`Wrap` 月历网格色深（R-2，非 fl_chart），色深 = `f(当天悦己笔数)` ambient。可交互：tap 某天 → inline 就地展开当天悦己列表。
- **D-C2:** 悦己花在哪 横向堆叠分段条 = 自定义 `Row` + `Flexible(flex)`（R-1，非 fl_chart）+ 单列图例。轻交互：tap 某段 → 就地高亮 + 同步高亮图例行。**零新数据路径、ADR-012-safe 纯描述、不下钻。**

**D. 暖色动效 (REDES-03)**
- **D-D1:** 强度 = 克制微动 — 仅入场一次性轻动效（卡片淡入），无循环、无 glow 脉冲、无庆祝爆发。
- **D-D2:** count-up 落点 = 仅两个锚点数字（donut 中心「本月支出」+ 悦己花在哪 header「悦己 ¥…」），`TweenAnimationBuilder` ~400–600ms。其余主数字静态。

**E. 趋势卡形态 (重大冲突)**
- **D-E1:** 忠于 round-5 B 形态 — 支出趋势 = 当月内「按天累计」`LineChart`：支出侧（总支出/日常 tab）本月（实线）+ 上月（虚线）双线；**悦己 tab = 本月单线、无上月线、无跨期。**
- **D-E2:** ⚠ Phase 44 趋势交付不匹配，Phase 46 须补 — Phase 44 建的是 6 月滚动月总计 + BarChart；round-5 B 需 per-DAY 累计 + 新 LineChart widget。

**F. IA / 卡序 / 组模式**
- **D-F1:** `family_insight_data_card` 保留为 group-mode-only 条件卡，追在 5 卡之后。不在删除名单。
- **D-F2:** 扁平 round-5 B 顺序 = 趋势(top) → donut hero → 悦己花在哪 → 小确幸日历 → 满足度直方图 → [family_insight 组模式条件卡]。删 Phase 45 的 Time/Distribution/Stories 分区头（含 `analytics_screen_section_header.dart`）。

### Claude's Discretion (verbatim)
- 下钻列表只读的实现（禁用 tile 回调 vs `ListTransactionTile` 只读变体）— planner。
- 下钻交易排序（金额降序 vs 时间倒序）— planner。
- per-day-cumulative 趋势取数位置（repo 新 thin method vs use case 内 `findByBookIds` 2-月窗 + Dart 侧 cumulative）— researcher/planner（无迁移、reuse-first）。【本研究给出推荐，见 Flag 1 verdict】
- 小确幸日历 inline-展开的高度/动画处理、悦己段高亮的视觉手法、count-up 曲线 — planner。
- 自定义 widget 的文件拆分、命名（ADR-017 生存/灵魂 grep-ban）— planner。
- 注册表条目增删形态（abstract base vs spec-list，Phase 45 已立）— planner。

### Deferred Ideas (OUT OF SCOPE — verbatim)
- JOY-03 记忆故事卡 / JOY-04 kakeibo Q4 反思 prompt — 随 round-5 B drop，标 Descoped。JOY-04 持久化未来需新 ADR + non-Drift 存储。
- 悦己过滤的分类下钻（tap 悦己段 → 仅该子类悦己交易）— 第二条新只读路径，超 DRILL-01 上限；未来阶段。
- 小确幸日历 tap-day 若需新 per-day-joy 数据路径 — 归属于 planning 复议。【本研究给出裁定，见 Flag 2 verdict】
- Phase 44 的 6 月滚动 `MonthlyTrend` 扩展若本卡不用 — researcher 核实他用或清理。【本研究给出裁定，见 Flag 1 verdict】
- i18n ARB parity / 反毒性禁词扫描扩充 / macOS golden 从零撰写+重基线 / 全量门禁 / 真机 UAT — Phase 47。
- 收入/真实结余率、预算 vs 实际、可定制仪表盘、Sankey、"about typical" 滚动带、分币种 analytics 小计、fl_chart 1.x→2.x — 里程碑外。
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OVW-02 | 总览遵守 ADR-012 — 中性当窗呈现，无跨期 delta、无评判 framing | donut hero (本月支出, 静态 count-up) + 日历/直方图/堆叠条均纯描述；唯一跨期 = 趋势支出侧 (ADR-012 §4 记录在案例外，已 Phase 45 `## Update` 补正) |
| JOY-01 | "值得" affirmation — 已花悦己 ambient (非 target ring) | 由「悦己 tab 趋势单线 + 悦己花在哪 header ¥总额」承载；ADR-016 §3 target ring 仍 HomeHero 独占 (D-A4) — analytics 零复制 |
| JOY-02 | "值不值" satisfaction surface — 复用 satisfaction histogram + per-category joy | `getSatisfactionDistribution` (analytics_dao.dart:342) + `PerCategoryJoyBreakdown` (满足度) 已存在；histogram 卡 REDES-02 删 Stack hack |
| JOY-03 | 记忆故事 surface | **DESCOPED (D-A1)** — 不建。Phase 46 含台账补正 doc 任务 (D-A2) |
| JOY-04 | kakeibo Q4 反思 prompt | **DESCOPED (D-A1)** — 不建。台账补正 (D-A2) |
| REDES-02 | fl_chart 1.2.0 native per-rod `label` (删 histogram Stack hack) + optional donut `cornerRadius`；保持 `^1.2.0` | **VERIFIED**: 1.2.0 含 `BarChartRodData.label` + `PieChartSectionData.cornerRadius` (changelog #2071/#1175)；当前 Stack hack 在 `satisfaction_distribution_histogram.dart:35-138` |
| REDES-03 | 暖色动效 (`TweenAnimationBuilder` count-up, ADR-012-safe) | Flutter 内建，无新依赖；落点 2 锚点数字 (D-D2) |
| GUARD-02 | 反游戏化 — 每张新卡入 `anti_toxicity_*_test` 禁词扫描；`FamilyHappiness` aggregate-only；single-Joy-expression | anti_toxicity test 结构在 `anti_toxicity_phase17_test.dart` (forbidden-substring × ja/zh/en × 状态)；扫描扩充本体 Phase 47，新卡文案须扫描-ready |
</phase_requirements>

## Summary

Phase 46 is a **presentation-layer fill** on top of a complete data contract (Phase 44) and a complete card-registry shell (Phase 45). The live registry (`analytics_card_registry.dart`) currently holds the OLD Variant-δ 10-spec lineup; Phase 46 re-orders it to the flat round-5 B 5-card lineup, deletes 3 dead cards, replaces the trend card, and adds 2 custom non-fl_chart widgets + a pushed drill route. The mechanism (typed `AnalyticsCardSpec` list, `refreshTargets`, `isVisible`, `buildAnalyticsCardContext`) is already in place and need not be rewritten — Phase 46 swaps entries.

**The three research flags resolve cleanly, but one carries a non-trivial correction:**

1. **Trend per-day-cumulative (Flag 1) — VERDICT: NEW use-case-internal 2-month-window path + new LineChart widget; DELETE the entire 6-month `MonthlyTrend` stack.** The cheapest reuse-first path uses the existing `findByBookIds` (2-month window) + Dart-side per-day cumulative + per-ledger split — no migration, no new DAO. The Phase 44 6-month `MonthlyTrend` / `GetExpenseTrendUseCase` / `monthly_spend_trend_bar_chart.dart` / `total_six_month_card.dart` / `expenseTrendProvider` are used by NOTHING except the trend card being replaced and their own tests — clean removal.

2. **小确幸日历 per-day joy (Flag 2) — VERDICT: needs a thin per-day-joy fetch; it does NOT cross the DRILL-01 scope lock; belongs in Phase 46.** No existing query gives per-day joy-ledger data (`getDailyTotals` has a `type` param but NO ledger filter — analytics_dao.dart:226-264). DRILL-01's "one new read path" is the category drill-down (already shipped in Phase 44); per-day-joy is a different concern and is permitted as ambient texture, not a second drill path. Cheapest path: Dart-side per-day grouping over `findByBookIds(ledgerType:'joy')` (zero new DAO), OR a `String? ledgerType` param added to `getDailyTotals` (thinnest SQL change, no migration).

3. **窗口取数索引 (Flag 3) — VERDICT: ⚠️ the assumed `(book_id, timestamp)` index DOES NOT EXIST.** The `Transactions.customIndices` getter declaring `idx_tx_book_timestamp` is **decorative** — Drift never emits it, and there is NO `CREATE INDEX ... ON transactions` statement anywhere in `app_database.dart` or the codebase. This is the same "customIndices is decorative" gotcha already documented in project memory (Phase 36 CR-01) and acknowledged in code comments for `shopping_items`/`exchange_rates`, but it was NEVER fixed for `transactions`. The advice "do NOT add `(book_id, category_id, timestamp)`" stands, but the planner should decide whether to ADD the missing `idx_tx_book_timestamp` (book_id, timestamp) index that drill-down + trend + calendar all rely on. This is a perf/correctness flag, not a blocker (current row volumes are small).

**Primary recommendation:** Build/re-order the 5 cards against the existing registry; route the new trend + per-day-joy data through `findByBookIds` Dart-side (no migration); delete the 6-month trend stack; flag the missing `(book_id, timestamp)` index to the planner as a discretionary perf task; navigate the drill page via `Navigator.push(MaterialPageRoute(...))` (the app uses imperative Navigator — there is NO GoRouter despite CLAUDE.md's claim).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Per-day cumulative trend data | Application (use case) | Data (existing `findByBookIds` primitive) | Pure transform over an existing repo read; no new DAO — D-E2 + Discretion |
| Per-day joy texture (calendar) | Application/Presentation | Data (`getDailyTotals` thin ledger param OR `findByBookIds` Dart-filter) | Ambient aggregation; not a drill path — Flag 2 |
| Per-L1-category joy AMOUNT (悦己花在哪) | Application (Dart transform) | Data (`findByBookIds(ledgerType:'joy')`) | No existing per-category joy-amount query; Dart rollup via existing helper |
| Card render order + refresh union | Presentation (registry) | — | `analytics_card_registry.dart` is the single source (Phase 45 D-B1) |
| Drill page navigation | Presentation (Navigator.push) | — | App uses imperative `Navigator.push(MaterialPageRoute)`; no GoRouter |
| Donut / histogram / trend-line charts | Presentation (fl_chart 1.2.0) | — | Native PieChart / BarChart / LineChart |
| 悦己横条 + 小确幸日历 | Presentation (custom Flutter) | — | NOT fl_chart (R-1/R-2, GATE-04) |
| Joy target ring (Σ joy_contribution) | **HomeHero only — NOT analytics** | — | ADR-016 §3 / D-A4 (zero analytics display) |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| fl_chart | 1.2.0 (locked) | donut (PieChart), histogram (BarChart), trend (LineChart) | Already the project pin; latest published; `cornerRadius` + per-rod `label` landed in 1.2.0 |
| flutter_riverpod | 3.1+ (gen 4.x) | `ConsumerWidget` cards, auto-dispose provider families | Project standard (CLAUDE.md Riverpod 3 conventions) |
| Flutter SDK (built-in) | — | `TweenAnimationBuilder` (count-up), `GridView`/`Wrap` (calendar), `Row`+`Flexible` (悦己横条), `Navigator.push`/`MaterialPageRoute` (drill route) | REDES-03 / R-1 / R-2 / drill nav — zero new deps |
| freezed | `@freezed` | new trend/per-day-joy domain models | Project immutability standard |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| drift | (existing) | only IF a thin `ledgerType` param is added to `getDailyTotals` | Flag 2 — no migration, just a SQL clause append |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| New use-case-internal 2-month window for trend | Extend the 6-month `MonthlyTrend` to carry per-day arrays | Rejected — wrong shape (per-month not per-day), and the 6-month stack has no other consumers (delete it) |
| `findByBookIds(ledgerType:'joy')` + Dart per-day group (calendar) | Add `String? ledgerType` to `getDailyTotals` (SQL-side) | Both valid, no migration. SQL-side is thinner output; Dart-side reuses an already-loaded fetch if the trend/heatmap share a window. Planner's call. |
| `Navigator.push(MaterialPageRoute)` for drill page | GoRouter named route | **GoRouter does not exist in this app** — CLAUDE.md is stale. Use imperative Navigator (the established pattern). |

**Installation:** No new packages. fl_chart `^1.2.0` already in `pubspec.yaml`; resolved `1.2.0` in `pubspec.lock`.

**Version verification:**
- `fl_chart` — `pubspec.lock` line: `version: "1.2.0"` `[VERIFIED: pubspec.lock]`. Latest published is 1.2.0; **no 2.x exists** `[VERIFIED: pub.dev changelog]` — confirms TOOL-V2-01 is N/A.
- `PieChartSectionData.cornerRadius` — added in 1.2.0 (changelog #1175) `[VERIFIED: pub.dev changelog]`.
- `BarChartRodData.label` (per-rod label above bar, not tooltip) — added in 1.2.0 (changelog #2071) `[CITED: pub.dev/packages/fl_chart/changelog]`.

## Package Legitimacy Audit

> No external packages are installed in this phase. All work uses already-pinned project dependencies (fl_chart 1.2.0, flutter_riverpod, freezed, drift) verified in `pubspec.lock`. **Package Legitimacy Gate: N/A (zero new installs).**

## Architecture Patterns

### System Architecture Diagram

```
[AnalyticsScreen shell (Phase 45, IndexedStack tab)]
        │  builds via
        ▼
[analyticsCardRegistry: List<AnalyticsCardSpec>]   ← Phase 46 RE-ORDERS to round-5 B 5-card flat list
        │  each spec.build(ctx)                        (delete section headers; delete 3 dead specs)
        ▼
 ┌──────────────────────────────────────────────────────────────────────┐
 │ 1. 趋势 LineChart card  ──watch──▶ NEW perDayCumulativeTrendProvider   │──▶ GetExpenseDailyCumulative
 │     (pill tabs 总/日常/悦己)                  (auto-dispose family)      │     UseCase ─▶ findByBookIds(2-mo window)
 │                                                                          │     ─▶ Dart per-day cumulative + per-ledger split
 │ 2. donut hero card  ──watch──▶ monthlyReportProvider (EXISTING)         │──▶ rollupCategoryBreakdownsToL1 (helper)
 │     legend row TAP ──Navigator.push──▶ [DrillPage (NEW screen)]         │──▶ getCategoryDrillDownProvider (Phase 44, auto-dispose)
 │                                                                          │     ─▶ ListTransactionTile (read-only)
 │ 3. 悦己花在哪 card (custom Row+Flexible) ──watch──▶ NEW perCategoryJoy   │──▶ findByBookIds(ledgerType:'joy') + L1 rollup amount
 │     Amount provider                                                      │
 │ 4. 小确幸日历 card (custom GridView) ──watch──▶ NEW perDayJoyProvider    │──▶ getDailyTotals(+ledger) OR findByBookIds(joy) Dart-group
 │     tap-day ──inline expand──▶ that day's joy tx list                   │
 │ 5. 满足度直方图 card ──watch──▶ satisfactionDistributionProvider (EXIST) │──▶ getSatisfactionDistribution (REDES-02: native label)
 │ [6. family_insight card] isVisible:(ctx)=>ctx.isGroupMode (D-F1, KEEP)  │
 └──────────────────────────────────────────────────────────────────────┘
        │  _refresh() = registry.where(isVisible).expand(refreshTargets) → invalidate
        ▼
[ALL analytics providers auto-dispose; ZERO home/* (GUARD-01/02, registry structurally enforces)]
```

### Recommended Project Structure (deltas only — existing tree)
```
lib/features/analytics/presentation/
├── analytics_card_registry.dart        # RE-ORDER specs; delete 3 dead + section-header refs
├── screens/
│   ├── analytics_screen.dart           # delete section-header interleave
│   └── category_drill_down_screen.dart # NEW — pushed route host (read-only drill list)
├── widgets/
│   ├── within_month_cumulative_line_chart.dart  # NEW (LineChart, replaces monthly_spend_trend_bar_chart)
│   ├── joy_spend_stacked_bar.dart       # NEW (R-1 custom Row+Flexible)
│   ├── joy_calendar_heatmap.dart        # NEW (R-2 custom GridView)
│   ├── satisfaction_distribution_histogram.dart  # EDIT — delete Stack hack, native label
│   ├── monthly_spend_trend_bar_chart.dart        # DELETE
│   └── analytics_screen_section_header.dart       # DELETE (D-F2)
│   └── cards/
│       ├── within_month_trend_card.dart # NEW (replaces total_six_month_card.dart)
│       ├── joy_spend_card.dart           # NEW (悦己花在哪)
│       ├── joy_calendar_card.dart        # NEW (小确幸日历)
│       ├── category_donut_card.dart      # EDIT — legend-row tap → drill push; optional cornerRadius
│       ├── satisfaction_histogram_card.dart  # KEEP (host of histogram widget)
│       ├── family_insight_data_card.dart # KEEP (D-F1)
│       ├── analytics_data_card.dart      # KEEP (shared shell)
│       ├── best_joy_card.dart            # DELETE (D-A3)
│       ├── kpi_hero_card.dart            # DELETE (D-A3)
│       └── largest_expense_card.dart     # DELETE (D-A3)
└── providers/
    └── state_analytics.dart              # add perDayCumulativeTrend / perDayJoy / perCategoryJoyAmount families; remove expenseTrendProvider
lib/application/analytics/
    ├── get_expense_trend_use_case.dart   # DELETE (6-month, no other consumer)
    └── get_within_month_cumulative_use_case.dart  # NEW (or fold into provider)
```

### Pattern 1: Card = single-source ConsumerWidget (Phase 45 contract)
**What:** Each card is a dumb `ConsumerWidget` watching exactly one provider family; the SAME provider list is its `refreshTargets(ctx)` and its error-retry target (`ref.invalidate(targets.single)`).
**When to use:** Every card in this phase.
**Example:**
```dart
// Source: lib/features/analytics/presentation/widgets/cards/category_donut_card.dart:39-62
final monthlyAsync = ref.watch(monthlyReportProvider(
  bookId: bookId, startDate: startDate, endDate: endDate,
  joyMetricVariant: joyMetricVariant));
return monthlyAsync.when(
  data: (monthly) => AnalyticsDataCard(/* ... */),
  loading: () => const SizedBox(height: 280),
  error: (_, _) => AnalyticsCardErrorState(onRetry: () => ref.invalidate(targets.single)),
);
```

### Pattern 2: family-key normalization (D-12, mandatory)
**What:** Provider family keys MUST be normalized through `DateBoundaries`/`TimeWindow` BEFORE entering the key tuple, or microsecond-exact rebuilds storm.
**Example:**
```dart
// Source: lib/features/analytics/presentation/analytics_card_registry.dart:116-120
final window = ref.watch(selectedTimeWindowProvider);
final range = window.range;       // already normalized
final trendAnchor = DateTime(range.end.year, range.end.month);  // month-anchored, not exact
```

### Pattern 3: pushed route via imperative Navigator (drill page)
**What:** The app navigates with `Navigator.push(MaterialPageRoute(...))`, NOT GoRouter. The drill page is a `ConsumerWidget` that watches `selectedTimeWindowProvider` directly (keepAlive session state — no route-param threading per Phase 45 D-C1); only `l1CategoryId` is passed in.
**Example:**
```dart
// Established pattern — lib/features/home/presentation/screens/home_screen.dart:223,249,353
Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => CategoryDrillDownScreen(bookId: bookId, l1CategoryId: l1Id),
  ),
);
// Inside CategoryDrillDownScreen.build: ref.watch(selectedTimeWindowProvider) → window range
// → ref.watch(categoryDrillDownProvider(bookIds, start, end, l1CategoryId))  // Phase 44, auto-dispose
```

### Pattern 4: Dart-side per-day / per-L1 aggregation over findByBookIds
**What:** When a card needs a shape no DAO query provides, fetch the window via `findByBookIds` and transform in Dart — the established reuse-first precedent (drill-down does exactly this; calendar does it over `getDailyTotals`).
**Example:**
```dart
// Source precedent: lib/application/analytics/get_category_drill_down_use_case.dart:43-86
final txns = await _txRepo.findByBookIds(bookIds, startDate: s, endDate: e, categoryId: null);
final expense = txns.where((t) => t.type == TransactionType.expense).toList();
// per-day cumulative / per-ledger split / per-L1-joy-amount all derive in Dart from this set.
```

### Anti-Patterns to Avoid
- **Joy target ring / progress ring / "hit 8+" in analytics:** Forbidden — ADR-016 §3 reserves the only target ring for HomeHero (D-A4). Analytics shows ambient `f(value)→color` only (ADR-016 §5).
- **Cross-period delta on the joy side:** The ONLY cross-period surface is the spend-side trend (总/日常 tabs). Joy tab = single line, zero cross-period (D-E1). This is the highest-risk ADR-012 line.
- **Adding a second new read path for joy-segment drill-down:** D-C2 forbids it (超 DRILL-01 上限). 悦己段 tap = in-place highlight only, no drill.
- **Aggregating `joy_fullness` over daily rows:** daily rows default `joy_fullness=2` and poison the aggregate (analytics_dao.dart:108-115 documents this — `_dailyExpenseFilter`). Joy satisfaction must use the joy-ledger filter only.
- **Trusting CLAUDE.md "Routing: GoRouter":** There is no GoRouter in the codebase — use `Navigator.push`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| L1 category rollup (donut + drill + 悦己横条) | A second rollup loop | `rollupCategoryBreakdownsToL1` / `l1RollupFromTransactions` / `l1AncestorOf` in `lib/features/analytics/domain/category_l1_rollup.dart` | Single source-of-truth (D-11) — donut slice and any L1 amount derive from the same rule, no drift |
| Window transaction fetch | New DAO / new SQL | `TransactionRepository.findByBookIds` (transaction_dao.dart:249) | Existing primitive; drill-down + trend + calendar all go through it |
| Per-day expense totals (calendar precedent) | New per-day loop | `getDailyTotals` (analytics_dao.dart:226) — add `ledgerType` param OR Dart-filter | Already does `DATE(...localtime)` grouping; precedent in `calendarDailyTotals` (state_calendar_totals.dart) |
| Read-only drill tile | New tile widget | `ListTransactionTile` with disabled callbacks (D-B3) | Visual reuse; just suppress swipe-delete + tap-edit |
| Count-up animation | Custom AnimationController | `TweenAnimationBuilder` (Flutter built-in) | REDES-03; ADR-012-safe; zero deps |
| Per-rod histogram label | `Stack`+`Align`+`DecoratedBox` (current hack) | `BarChartRodData.label` (fl_chart 1.2.0 native) | REDES-02 — delete `satisfaction_distribution_histogram.dart:35-138` Stack |

**Key insight:** The data layer is done (Phase 44) and the L1 rollup helper already unifies donut/drill math. Phase 46's only genuinely-new data work is (a) per-day-cumulative trend transform and (b) per-day/per-category JOY aggregation — both pure Dart transforms over the existing `findByBookIds` primitive, no migration.

## Runtime State Inventory

> Phase 46 has rename-adjacent surface (ADR-017 生存/灵魂 grep-ban on new file/widget names) but is NOT a data-migration phase. Drift schema stays v21 (no migration). Inventory:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — no new tables, no renamed keys/collections. Schema stays v21. | None — verified: zero `schemaVersion` change, zero new tables |
| Live service config | None — local-first app, no external service registrations touched | None |
| OS-registered state | None | None |
| Secrets/env vars | None | None |
| Build artifacts | `.g.dart` / `.freezed.dart` for new freezed models + new `@riverpod` providers MUST be regenerated (`flutter pub run build_runner build --delete-conflicting-outputs`). Deleting `expense_trend.dart` removes `expense_trend.g.dart`/`.freezed.dart`. | Run build_runner after model/provider changes AND after deleting the trend stack |

**Naming-rename note (ADR-017):** all NEW files/widgets (trend line, calendar, 悦己横条, drill screen) must pass the 生存/灵魂 grep-ban. Use 日常/悦己 terminology only. This is a naming convention, not runtime state.

## Common Pitfalls

### Pitfall 1: The `(book_id, timestamp)` index silently does not exist (Flag 3)
**What goes wrong:** `findByBookIds` does a `WHERE book_id IN (...) AND timestamp >= ? AND timestamp <= ?` range scan. The table declares `idx_tx_book_timestamp (book_id, timestamp)` on the `customIndices` getter — but Drift never emits that getter, and no `CREATE INDEX` statement exists. So the query is a **full table scan**.
**Why it happens:** "customIndices is decorative" — documented project gotcha (Phase 36 CR-01, project memory). It was fixed for `shopping_items` and `exchange_rates` (explicit `_create*Indexes()` helpers) but NEVER for `transactions`.
**How to avoid:** Planner decides — either (a) add a `_createTransactionIndexes()` helper emitting `CREATE INDEX IF NOT EXISTS idx_tx_book_timestamp ON transactions (book_id, timestamp)` in both `onCreate` and a new `onUpgrade` step (this WOULD be a schema-version bump to v22 — weigh against "no migration" lock), or (b) accept the full scan at current row volumes and defer. Do NOT add `(book_id, category_id, timestamp)` (D-06 — no SQL-side category filter).
**Warning signs:** Slow drill/trend/calendar at large transaction counts; `EXPLAIN QUERY PLAN` shows `SCAN transactions`.

### Pitfall 2: Joy-side cross-period creep
**What goes wrong:** Adding a "vs last month" line/label to the joy trend tab or any joy element violates ADR-012 (zero joy cross-period).
**How to avoid:** Joy tab = single current-month line (D-E1). Only 总/日常 tabs carry the本月+上月 dual line, and only because it is the ADR-012 §4 recorded exception (Phase 45 `## Update`).
**Warning signs:** A `prevMonth` series wired into the joy LineChart; "上月" string in any joy card.

### Pitfall 3: `getDailyTotals` returns ALL expense, not joy (Flag 2)
**What goes wrong:** Wiring the calendar heatmap to `getDailyTotals` as-is shows total daily spend, not joy笔数 — the heatmap would be wrong.
**Why it happens:** `getDailyTotals` (analytics_dao.dart:226-264) filters `type='expense'` with a `type` param but has NO `ledger_type` filter. The Phase 44 research flag noted this.
**How to avoid:** Either add `String? ledgerType` to `getDailyTotals` (thin SQL clause, no migration) and pass `'joy'`, OR fetch `findByBookIds(ledgerType:'joy')` and Dart-group by day. Heatmap color depth = `f(count)`, so you need COUNT per day, not just SUM — `findByBookIds` Dart-group gives count directly; a SQL `COUNT(*)` variant of `getDailyTotals` would too.

### Pitfall 4: Deleting cards without clearing registry + test references
**What goes wrong:** Deleting `best_joy_card.dart` etc. breaks the registry import and the registry test.
**How to avoid:** Each dead card (`best_joy_card`, `kpi_hero_card`, `largest_expense_card`, `total_six_month_card`, `analytics_screen_section_header`) is referenced ONLY by `analytics_card_registry.dart` + `analytics_card_registry_test.dart` (and `analytics_screen.dart`/`analytics_screen_test.dart` for the section header). Remove the spec, the import, AND update the test's expected registry shape together.
**Warning signs:** `flutter analyze` import errors; registry test failures on spec count.

### Pitfall 5: 悦己花在哪 needs AMOUNT, but `PerCategoryJoyBreakdown` is SATISFACTION
**What goes wrong:** Reusing `perCategoryJoyBreakdownProvider` for the stacked bar gives avg-satisfaction + counts, NOT the ¥ amounts the bar's `Flexible(flex)` segments need.
**Why it happens:** `PerCategoryJoyBreakdown` (per_category_joy_breakdown.dart:46-53) carries `avgSatisfaction`/`totalCount`/`otherCount` — no amount. `getCategoryTotals` has no ledger filter. There is NO existing per-category joy-AMOUNT query.
**How to avoid:** New thin transform: `findByBookIds(ledgerType:'joy')` → `l1RollupFromTransactions` per L1 → amounts. Zero new DAO (Dart-side rollup over existing helper). This is ADR-012-safe (pure description, no drill — D-C2).

## Code Examples

### fl_chart 1.2.0 native per-rod label (REDES-02 — replace Stack hack)
```dart
// Source: pub.dev/packages/fl_chart/changelog (1.2.0, #2071) — BarChartRodData.label
BarChartRodData(
  toY: bucket.count.toDouble(),
  color: _colorForScore(bucket.score, palette),
  width: 14,
  borderRadius: const BorderRadius.only(
    topLeft: Radius.circular(4), topRight: Radius.circular(4)),
  // NEW in 1.2.0 — renders a label ABOVE the rod natively; deletes the
  // Stack/Align/DecoratedBox annotation in satisfaction_distribution_histogram.dart:111-138
  // (consult the 1.2.0 BarChartRodData API for the exact label field shape during planning)
);
```

### fl_chart 1.2.0 donut cornerRadius (optional, REDES-02)
```dart
// Source: pub.dev/packages/fl_chart/changelog (1.2.0, #1175)
// Current donut: category_spend_donut_chart.dart:38 PieChartSectionData (NO cornerRadius today)
PieChartSectionData(
  value: amount, color: sliceColor, radius: 40,
  cornerRadius: 4, // NEW in 1.2.0 — optional rounded slice ends
);
```

### Per-ledger split precedent (trend per-ledger reuse)
```dart
// Source: lib/application/analytics/get_expense_trend_use_case.dart:38-56 (to be REPLACED, but the
// per-ledger zero-default pattern carries over to the new per-day path)
int dailyTotal = 0, joyTotal = 0;
for (final lt in ledgerTotals) {          // getLedgerTotals omits zero-spend ledgers
  if (lt.ledgerType == 'daily') dailyTotal = lt.totalAmount;
  else if (lt.ledgerType == 'joy') joyTotal = lt.totalAmount;
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| 6-month rolling `MonthlyTrend` + BarChart (TREND-01 / Phase 44) | within-month per-day cumulative LineChart (round-5 B / D-E1) | Phase 46 (design-driven) | Delete the entire 6-month stack; build a new LineChart widget |
| Histogram per-rod label via `Stack`+`Align`+`DecoratedBox` | `BarChartRodData.label` native | fl_chart 1.2.0 | REDES-02 — simpler, no overlay math |
| Donut square slice ends | optional `PieChartSectionData.cornerRadius` | fl_chart 1.2.0 | REDES-02 polish (optional) |
| Section-header IA (Time/Distribution/Stories) | flat round-5 B narrative (no headers) | Phase 46 (D-F2) | Delete `analytics_screen_section_header.dart` |

**Deprecated/outdated:**
- `fl_chart 1.x→2.x upgrade (TOOL-V2-01)`: **fl_chart 2.x does not exist** — 1.2.0 is latest. Backlog item rests on a false premise; N/A (already noted in REQUIREMENTS Out of Scope).
- `CLAUDE.md "Routing: GoRouter"`: stale — the app uses `Navigator.push(MaterialPageRoute)`. No GoRouter dependency.
- `CLAUDE.md / STATE / MEMORY "Drift schema v20"`: stale — live `schemaVersion => 21` (app_database.dart:49). A v20→v21 step exists (exchange_rates). Phase 44 context says "v21 unchanged" which is correct; the v20 references in CLAUDE.md/MEMORY are out of date.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The cheapest trend path is use-case-internal 2-month-window over `findByBookIds` (vs a repo thin method) — both are valid; planner picks. | Flag 1 | Low — both reuse-first, no migration; only affects file placement |
| A2 | Adding `(book_id, timestamp)` index would require a schema-version bump to v22, which tensions against the "no migration" milestone lock. | Pitfall 1 / Flag 3 | Medium — if planner adds the index, the "v21 unchanged / no migration" claim from Phase 44 is broken; needs explicit decision. Deferring (accept full scan) keeps v21 but leaves perf gap. |
| A3 | The exact field shape of `BarChartRodData.label` in 1.2.0 (it exists per changelog; precise constructor field confirmed during planning against the installed API). | Code Examples / REDES-02 | Low — existence verified via changelog; field details checkable at implementation |

**Note:** A1/A2 are explicitly left to the planner per CONTEXT Discretion + the milestone "no migration" lock. A2 in particular is a genuine decision point: the index is missing, but fixing it breaks the no-migration invariant.

## Open Questions

1. **Add the missing `(book_id, timestamp)` index or defer?**
   - What we know: the index declared on `customIndices` does NOT exist (decorative getter); drill/trend/calendar all range-scan `transactions`.
   - What's unclear: whether current row volumes justify a v22 migration that breaks the "v21 unchanged" lock.
   - Recommendation: Surface to the user/planner as a discretionary perf task. Default = defer (accept full scan, keep v21) unless profiling shows a problem; if added, do it via `_createTransactionIndexes()` in both `onCreate` and a v21→v22 `onUpgrade` step (mirror `_createShoppingItemIndexes` pattern) and bump `schemaVersion`.

2. **`getDailyTotals` ledger param vs Dart-group for the calendar (Flag 2)?**
   - What we know: both are no-migration; the heatmap needs per-day COUNT (not SUM).
   - Recommendation: If the calendar shares a window-fetch with another joy card, Dart-group `findByBookIds(joy)` to avoid a second query; otherwise add a `String? ledgerType` + `COUNT(*)` variant to `getDailyTotals`. Planner's call (Discretion).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| fl_chart | donut / histogram / trend line | ✓ | 1.2.0 (locked) | — |
| flutter_riverpod | all cards | ✓ | 3.1+ | — |
| Flutter SDK built-ins (TweenAnimationBuilder, GridView, Navigator) | animation / custom widgets / drill route | ✓ | — | — |
| build_runner | regen for new freezed/riverpod | ✓ | (project) | — |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None. (No GoRouter — use built-in Navigator; this is the established pattern, not a gap.)

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (+ golden via `test/flutter_test_config.dart` BaselineExistenceGoldenComparator off-macOS) |
| Config file | `test/flutter_test_config.dart` (golden platform gate) |
| Quick run command | `flutter test test/widget/features/analytics/` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REDES-02 | histogram uses native label (no Stack hack) | widget | `flutter test test/widget/features/analytics/presentation/widgets/` | ✅ (histogram tests exist; update) |
| GUARD-02 | new card copy passes forbidden-substring sweep ja/zh/en | widget | `flutter test test/widget/features/analytics/presentation/widgets/anti_toxicity_phase17_test.dart` | ✅ existing structure; **Wave 0: extend forbidden lists + new-card subjects (扫描扩充 body is Phase 47)** |
| GUARD-01 | HomeHero isolation preserved | widget | `flutter test test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` | ✅ stays green |
| REDES-01 (carry) | registry union ⊆ analytics, zero home/* | widget | `flutter test test/widget/features/analytics/presentation/analytics_card_registry_test.dart` | ✅ — **update expected registry shape after re-order/delete** |
| DRILL-01 (UI) | drill page read-only list | widget | new `category_drill_down_screen_test.dart` | ❌ Wave 0 |
| OVW-02 / JOY-01..02 | new cards render, ADR-012-safe | widget/unit | new per-card tests | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test test/widget/features/analytics/` + `flutter analyze` (MUST be 0 issues)
- **Per wave merge:** **FULL `flutter test`** — scoped runs miss architecture tests (e.g. `hardcoded_cjk_ui_scan`, 生存/灵魂 grep-ban, import_guard). This is a documented project gotcha (Phase 38 memory).
- **Phase gate:** Full suite green before `/gsd-verify-work`. Golden re-baseline is Phase 47 (macOS only).

### Wave 0 Gaps
- [ ] `within_month_trend_card` + `within_month_cumulative_line_chart` tests — covers D-E1/D-E2
- [ ] new trend use-case/provider unit test (per-day cumulative + per-ledger split)
- [ ] `joy_spend_card` (悦己花在哪) test — per-L1 joy amount rollup + tap-highlight
- [ ] `joy_calendar_card` test — per-day joy count + tap-day inline expand
- [ ] `category_drill_down_screen` test — read-only tile (no swipe/edit)
- [ ] update `analytics_card_registry_test.dart` expected shape (5 cards + conditional family)
- [ ] extend `anti_toxicity_phase17_test.dart` subjects to include new cards (�_GUARD-02 readiness; full扫描扩充 = Phase 47)
- [ ] delete tests for removed cards (`monthly_spend_trend_bar_chart_test`, dead-card tests)

*Goldens are NOT authored in Phase 46 (Phase 47, macOS-only). Per the golden CI platform gate, do not attempt pixel baselines off-macOS.*

## Security Domain

> `security_enforcement` is not set to `false` (treated as enabled). This is a local-first presentation-layer phase with no new network, auth, or crypto surface.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No auth change (biometric lock unchanged) |
| V3 Session Management | no | — |
| V4 Access Control | yes (data scoping) | Drill/trend/calendar pass ONLY caller-supplied `bookIds` to `findByBookIds` — never widen the book set (threat T-44-03-03, enforced in `get_category_drill_down_use_case.dart`); group mode pools aggregate-only (ADR-012 §6, FamilyHappiness no per-member fields) |
| V5 Input Validation | yes | `l1CategoryId` is an internal id, not free text; `findByBookIds` uses bound params (transaction_dao.dart:275 — `Variable.withString`, ORDER BY from compile-time enum switch, T-24-02 mitigated) |
| V6 Cryptography | no | No new crypto; DB encryption (SQLCipher) unchanged |

### Known Threat Patterns for Flutter/Drift analytics
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Transaction contents logged to console | Information Disclosure | Never log tx contents (T-44-03-01); no `print`/`debugPrint` of rows (project console.log audit hook) |
| Book-set widening (cross-family leak) | Elevation/Disclosure | Pass only caller `bookIds`; never re-derive a wider set in use cases |
| Per-member joy projection | Disclosure (ADR-012 §6) | FamilyHappiness aggregate-only; GROUP BY category/ledger only, never book_id |
| SQL injection via window/category params | Tampering | Bound parameters everywhere; no string interpolation of user values into SQL |

## Sources

### Primary (HIGH confidence — verified against live source)
- `lib/data/tables/transactions_table.dart:60-67` — decorative `customIndices` (Flag 3)
- `lib/data/app_database.dart:49,54-62,468-507` — `schemaVersion=21`, no transaction index creation, `customIndices` decorative comment (Flag 3)
- `lib/data/daos/transaction_dao.dart:249-286` — `findByBookIds` primitive (Flags 1/2)
- `lib/data/daos/analytics_dao.dart:226-264` — `getDailyTotals` (no ledger filter — Flag 2); :108-115 daily-default-2 trap
- `lib/application/analytics/get_category_drill_down_use_case.dart` — Phase 44 drill use case (DRILL-01 shipped)
- `lib/application/analytics/get_expense_trend_use_case.dart` + `lib/features/analytics/domain/models/expense_trend.dart` — 6-month stack to delete (Flag 1)
- `lib/features/analytics/presentation/analytics_card_registry.dart` — live registry (re-order target)
- `lib/features/analytics/domain/category_l1_rollup.dart` — shared L1 rollup helper
- `lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart:35-138` — Stack hack (REDES-02)
- `lib/features/analytics/domain/models/per_category_joy_breakdown.dart` — satisfaction-not-amount model (Pitfall 5)
- `lib/features/home/presentation/screens/home_screen.dart:223,249,353` + `main_shell_screen.dart:166,180` — Navigator.push pattern, IndexedStack tab (no GoRouter)
- `pubspec.lock` — `fl_chart version: "1.2.0"`
- grep: zero `LineChart` usage in `lib/`; dead-card references confined to registry+tests

### Secondary (MEDIUM confidence — official docs)
- pub.dev/packages/fl_chart/changelog — 1.2.0 added `PieChartSectionData.cornerRadius` (#1175) + `BarChartRodData.label` (#2071); no 2.x exists
- fl_chart bar_chart docs (GitHub) — `BarChart` renders rods vertically; no native horizontal (confirms R-1 custom Row)

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- 3 Research Flags: HIGH — each resolved with file:line evidence from live source
- Standard stack: HIGH — fl_chart 1.2.0 verified in pubspec.lock + changelog
- Architecture/patterns: HIGH — registry + helpers + Navigator pattern read directly
- Pitfalls: HIGH — index gotcha confirmed by grep (zero CREATE INDEX on transactions)

**Research date:** 2026-06-17
**Valid until:** 2026-07-17 (stable — local source + pinned deps; re-verify only if fl_chart pin changes)
