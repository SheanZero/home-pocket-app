# Phase 44: 数据与用例补全 (Data / Use-Case Additions — reuse-first) - Research

**Researched:** 2026-06-16
**Domain:** Flutter analytics data/use-case layer (Riverpod 3 + Freezed + Drift/SQLCipher). Reuse-first, NO schema migration (Drift stays v21).
**Confidence:** HIGH (all findings verified against committed source in this session)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** 下钻形态 = analytics 内轻量下钻视图（壳由 Phase 45/46 定）。尊重当前 analytics 时间窗（week/month/quarter/year/custom）；provider auto-dispose。**不**跳转既有「列表」tab。
- **D-02:** 下钻深度 = 点 **L1 分类** → 平铺该 L1（含全部 L2 子类）在当前窗口内的全部交易。不做 L1→L2 中间 breakdown 层。
- **D-03:** 下钻内容 = 顶部一个中性描述性小结（该分类小计 + 笔数；可选日均）+ 交易列表（复用 `ListTransactionTile`）。小结严格 ADR-012-safe：无目标、无跨期、无排名、无评判措辞。
- **D-04:** 数据路径 = 一条新 thin 只读路径：`CategoryDrillDown` Freezed 模型（`transactions` + `subtotal` + `count`，可选 `avgPerDay`）+ `GetCategoryDrillDownUseCase`，走既有 `TransactionRepository.findByBookIds(...)` 原语。**不**复用 v1.4 `GetListTransactionsUseCase`。**TDD 覆盖（先写 use case 测试）。**
- **D-05:** L1 过滤机制 = **Dart 侧按 category 的 L1 父类过滤**（取窗口内交易后 `.where`）。零新增 DAO/SQL 方法。小计/笔数复用 donut 卡已算的 L1 rollup（同一来源）。
- **D-06:** 索引结论 = `(book_id, category_id, timestamp)` 复合索引 **N/A / 不新增**。planner 须核查窗口取数路径已有合适索引（不是新增分类索引）。
- **D-07:** 三 tab 全上 = 总支出 / 日常 / 悦己。
- **D-08:** 实现 = 扩展 `MonthlyTrend` 增加 `dailyTotal` + `joyTotal` 字段；每月一次取齐三值（用 `getLedgerTotals` 原语，或 repo 层补一条 per-ledger 月度总计；**无 Drift 迁移**）。单一 trend provider family 驱动三 tab。
- **D-09:** 悦己趋势跨期约束 = 悦己 tab 为中性 6 月滚动线，无 delta callout。Phase 44 数据层**不计算、不暴露任何 joy 跨期 delta**。支出侧例外（总/日常 tab 的本月vs上月 highlight）属 Phase 46 framing，须在 Phase 45 前由 ADR-012 `## Update` 补正 —— **不在本阶段改 ADR-012 本体**。
- **D-10:** OVW-01 = 零新增数据工作。总支出 + 日常/悦己拆分 + Top 分类全来自 `MonthlyReport`。纯展示变换。
- **D-11:** donut 的「10 个 level-1 分类金额降序」需把 L2 粒度 `categoryBreakdowns` 按 L1 父类 rollup + 降序。纯展示变换。**L1 rollup 能力同时被 donut 卡与下钻小结复用** —— 放在一个共享 pure 函数/extension。
- **D-12:** 所有新 provider 的 family key 必须先经 `DateBoundaries`/`TimeWindow` 规范化再进 key tuple。
- **D-13:** Drift schema 保持 **v21** 不变；无迁移；无 budget 表；仅支出侧。
- **D-14:** analytics 总览/趋势/下钻 provider 保持 auto-dispose；不读取/不失效任何 `home/*` provider，不与 Home 共享任何 provider。

### Claude's Discretion
- 下钻壳的具体形态（bottom sheet vs pushed route）—— Phase 45/46 定。
- `CategoryDrillDown` 是否含 `avgPerDay`、交易排序（按金额 or 时间）—— planner 定。
- L1 rollup 的具体放置（pure 函数 / extension / provider）—— planner 定。
- per-ledger 月度数据补在 repo（如新 `getMonthlyLedgerTotals`）还是 use case 内循环 `getLedgerTotals` —— planner 定（两者均无迁移）。

### Deferred Ideas (OUT OF SCOPE)
- 收入录入 / 真实结余率 → INCOME-V2-01
- 预算 vs 实际（budgets 表 + 迁移）→ ANALYTICS-V2-03
- 可定制 / 可重排仪表盘 → ANALYTICS-V2-02
- Sankey 收入→支出→结余流向图 → ANALYTICS-V2-01
- "about typical" 中性滚动带 → ANALYTICS-V2-04
- 分币种 analytics 小计 → CUR-V2-02
- JOY-04 用户自撰反思文本持久化（GATE-04 no-go）
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OVW-01 | 支出总览面：总支出 + 日常/悦己拆分 + Top 分类，复用 `GetMonthlyReportUseCase`（零新数据工作） | **CONFIRMED pure-display-transform.** `MonthlyReport` already carries `totalExpenses`, `dailyTotal`, `joyTotal`, `categoryBreakdowns` (incl. amount/percentage/transactionCount/icon/color). The donut's "10 L1 categories desc" is the only new work — a pure L1 rollup over L2-grain `categoryBreakdowns` (D-11). Zero new use case/DAO/migration. |
| TREND-01 | 6 月滚动支出趋势，中性滚动上下文，无评判 framing（ADR-012 §4） | **CONFIRMED extend-in-place.** `GetExpenseTrendUseCase` already loops `monthCount` months calling `getMonthlyTotals`. D-08 adds two fields to `MonthlyTrend` + per-month per-ledger fetch (`getLedgerTotals` already exists and is migration-free). No joy cross-period delta computed (D-09). |
| DRILL-01 | 点分类下钻该窗口交易；至多一条新只读路径 | **CONFIRMED feasible with ZERO new DAO.** `TransactionRepository.findByBookIds(bookIds, {startDate, endDate, ...})` is the real window-fetch primitive; SQL is `book_id IN (...) AND is_deleted=0 AND timestamp BETWEEN ? AND ?`. L1 filtering is Dart-side (D-05). New `CategoryDrillDown` Freezed model + `GetCategoryDrillDownUseCase`, TDD-first (D-04). |
</phase_requirements>

## Summary

This is a **data/use-case-layer-only, reuse-first** phase. Every locked decision in CONTEXT.md is corroborated by the committed source: the heavy lifting (`MonthlyReport`, `getLedgerTotals`, `getCategoryTotals`, `findByBookIds`) already exists. The phase delivers exactly three things: (1) confirm OVW-01 is a pure display transform with one new shared pure L1-rollup helper; (2) extend `MonthlyTrend`/`GetExpenseTrendUseCase` for per-ledger 6-month series (no migration); (3) add one thin read-only drill-down path (`CategoryDrillDown` + `GetCategoryDrillDownUseCase`) over the existing `findByBookIds` primitive with TDD coverage.

The three research flags resolve cleanly. **(A) Per-day 悦己 attribution → Phase 46, not Phase 44.** No per-day joy-ledger query exists (`getDailyTotals` has no `ledger_type` filter), so the 小确幸日历 heatmap would need a net-new thin per-day-joy fetch — but that surface is a Phase 46 presentation card, NOT in this phase's three requirements (OVW/TREND/DRILL). Attribute that fetch to Phase 46. **(B) Window-fetch index — a real gap was found.** `findByBookIds` issues the `(book_id, timestamp)` range query D-06 cites, but the `idx_tx_book_timestamp` composite index declared in `transactions_table.dart customIndices` is **decorative and is NEVER emitted as an explicit `CREATE INDEX`** (the documented v1.6 CR-01 lesson). This is a planner-facing finding (details below); it does NOT contradict D-06 (no category index is needed), but the planner should record it. **(C) Per-ledger monthly primitive → confirmed migration-free** via existing `getLedgerTotals` per-month.

**Primary recommendation:** Build the three deliverables exactly as D-01..D-14 specify. The single shared L1-rollup pure helper (D-11) is the lynchpin — author it once, consume from both the donut display transform and the drill-down summary. Write the `GetCategoryDrillDownUseCase` test FIRST (D-04). Flag the decorative-index finding to the planner as a non-blocking note (no migration; surfacing it is the only correct action because D-13 forbids schema change).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Expense overview totals + splits + top-cat | Application (`GetMonthlyReportUseCase`, existing) | Domain (`MonthlyReport`) | Already computed; OVW-01 reuses verbatim |
| L1 rollup of L2-grain breakdowns (D-11) | Shared pure code (function/extension) | Domain (`CategoryBreakdown`) | Pure transform consumed by donut + drill summary; needs `Category.parentId` map |
| 6-month per-ledger trend | Application (`GetExpenseTrendUseCase`, extend) | Domain (`MonthlyTrend` +2 fields) | Loop-over-`getLedgerTotals`, no SQL change |
| Category drill-down read path | Application (`GetCategoryDrillDownUseCase`, NEW) | Data (`findByBookIds`, existing) | Window fetch + Dart-side L1 filter (D-05) |
| Per-day 悦己 heatmap data | **Phase 46** (out of scope here) | — | No existing query; net-new thin fetch belongs to the Phase 46 surface |
| Provider key normalization | Presentation (provider families) | Shared (`DateBoundaries`) | D-12 — normalize window before key tuple |

## Standard Stack

No new external packages. This phase is pure in-repo Dart against the existing stack.

### Core (already in `pubspec.yaml`, verified in use this session)
| Library | Role in this phase | Notes |
|---------|--------------------|-------|
| `freezed` / `freezed_annotation` | `CategoryDrillDown` model + `MonthlyTrend` extension | Run `build_runner` after editing any `@freezed` class |
| `riverpod` (3.x) / `riverpod_annotation` | New `@riverpod` use-case + family providers | Provider naming strips `UseCase`/`Notifier` suffix (CLAUDE.md Riverpod-3 note) |
| `drift` + `sqlcipher_flutter_libs` | NO new queries needed (DRILL reuses `findByBookIds`) | **NO migration — `schemaVersion` stays 21 (D-13)** |

**Installation:** None. `flutter pub run build_runner build --delete-conflicting-outputs` after model edits; `flutter gen-l10n` only if ARB touched (not expected this phase — copy lands in Phase 46/47).

## Package Legitimacy Audit

N/A — this phase installs no external packages. All work is in-repo Dart against the existing, already-vetted dependency set.

## Architecture Patterns

### Data Flow (drill-down path — the only new path)

```
Tap L1 category (Phase 45/46 shell)
        │  (bookIds, startDate, endDate, l1CategoryId)  ← key normalized via DateBoundaries (D-12)
        ▼
drillDownProvider.family  [auto-dispose, D-14]
        │
        ▼
GetCategoryDrillDownUseCase.execute(...)              ← NEW (Application layer)
        │   1. txns = TransactionRepository.findByBookIds(bookIds, startDate, endDate)   [existing primitive, no category filter in SQL — D-05/D-06]
        │   2. categories = CategoryRepository.findAll()  → build {id → parentId} map
        │   3. Dart-side .where(tx → L1-ancestor(tx.categoryId) == l1CategoryId)         [D-05]
        │   4. subtotal/count from shared L1-rollup helper (same source as donut — D-11)
        ▼
CategoryDrillDown {transactions, subtotal, count, avgPerDay?}   ← NEW Freezed model
        ▼
List of ListTransactionTile (reused, D-03)  +  neutral descriptive summary (ADR-012-safe, D-03)
```

### Trend extension data flow (no new path)

```
GetExpenseTrendUseCase.execute(anchor, monthCount=6)
  for each of 6 months:
    getMonthlyTotals(...)   → totalExpenses        [existing]
    getLedgerTotals(...)    → daily + joy split     [existing primitive, D-08]
  → ExpenseTrendData{ months: [MonthlyTrend{year, month, totalExpenses, totalIncome, dailyTotal*, joyTotal*}] }
                                                          (* = D-08 new fields)
One trend provider family drives all three tabs (D-08) — no 3× query, no 3× family.
```

### Recommended placement (follows 5-layer Clean Architecture + Thin Feature rule)

```
lib/
├── application/analytics/
│   ├── get_expense_trend_use_case.dart          # EDIT — add per-ledger fetch
│   └── get_category_drill_down_use_case.dart     # NEW
├── features/analytics/
│   ├── domain/models/
│   │   ├── expense_trend.dart                     # EDIT — MonthlyTrend +dailyTotal +joyTotal
│   │   └── category_drill_down.dart               # NEW Freezed model
│   └── presentation/providers/
│       └── repository_providers.dart              # EDIT — add getCategoryDrillDownUseCase provider
│                                                  #        + new drill family provider (auto-dispose)
└── shared/ or features/analytics/domain/          # NEW shared L1-rollup pure helper (D-11; planner picks exact location)
```

### Pattern 1: Existing analytics use-case + provider wiring (mirror this)
```dart
// Source: lib/features/analytics/presentation/providers/repository_providers.dart (verified this session)
@riverpod
GetExpenseTrendUseCase getExpenseTrendUseCase(Ref ref) {
  return GetExpenseTrendUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  );
}
```
For the NEW drill-down use case, inject `TransactionRepository` (not `AnalyticsRepository`) — its provider is `transactionRepositoryProvider` in
`lib/features/accounting/presentation/providers/repository_providers.dart` [VERIFIED: codebase grep]. It also needs `CategoryRepository` (for the parentId map) — `categoryRepositoryProvider` in the same file, already consumed by `GetMonthlyReportUseCase`.

### Pattern 2: Dart-side category filter precedent (D-05)
```dart
// Source: lib/application/list/get_list_transactions_use_case.dart (verified — comments cite "filter.categoryIds.contains (D-01 / A3)")
// v1.4 list path filters categories Dart-side, never in SQL. D-05 reuses this precedent
// for the L1-parent filter: fetch window via findByBookIds, then .where on the L1 ancestor.
```

### Anti-Patterns to Avoid
- **Adding `AnalyticsDao.getCategoryTransactions` or a `(book_id, category_id, timestamp)` index.** ROADMAP success-criterion #3 lists these as *one possible* path, but CONTEXT.md D-04/D-05/D-06 (the locked authority) explicitly rule them OUT. Use `findByBookIds` + Dart-side filter. No new DAO method, no new index.
- **Computing any joy cross-period delta in the data layer (D-09).** The 6-month series already contains this-month/last-month values; the support side must NEVER emit a `delta`/`vsLastMonth` field for joy. The expense-side highlight is a Phase 46 framing concern only.
- **Re-aggregating subtotal/count separately for the drill summary.** D-11 mandates the drill summary reuse the SAME L1-rollup the donut uses (one shared pure helper) to avoid a second source-of-truth drift.
- **Using raw microsecond `DateTime` in a provider family key (D-12).** Normalize via `DateBoundaries`/`TimeWindow` first, or you get a rebuild storm.
- **`生存`/`灵魂` in new code identifiers (ADR-017 grep-ban).** Use `daily`/`joy` (note: `LedgerType.survival/soul` Dart enum values are intentionally retained per ADR-017 D-15-variant, but new ARB keys/class names/symbols must use the new vocabulary). The stored `ledger_type` values are `'daily'`/`'joy'` [VERIFIED: analytics_dao.dart `_joyExpenseFilter`].

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Window transaction fetch for drill-down | New `getCategoryTransactions` DAO/SQL | Existing `TransactionRepository.findByBookIds(...)` | D-04/D-05/D-06; primitive already issues the exact `(book_id, timestamp)` range query, handles `is_deleted=0` + sort + multi-book |
| Per-ledger month totals | New per-month SQL | Existing `AnalyticsDao.getLedgerTotals` per month | D-08; already returns `daily`/`joy` SUM for a window, migration-free |
| Expense overview totals/splits | Any new aggregate | Existing `MonthlyReport` fields | D-10; `totalExpenses`/`dailyTotal`/`joyTotal`/`categoryBreakdowns` all present |
| Transaction list row UI (later phase) | New tile | `ListTransactionTile` (v1.4) | D-03; reuse verbatim |
| L1 rollup (the ONE genuinely new pure bit) | Two separate rollups | ONE shared pure helper consumed by donut + drill | D-11; single source-of-truth |

**Key insight:** The only genuinely-new code is (1) two Freezed field additions, (2) one new thin use case, (3) one shared L1-rollup pure helper. Everything else is reuse. Resist the ROADMAP's looser "or a new DAO method" phrasing — CONTEXT.md tightened it.

## Resolved Research Flags

### Flag A — Per-day 悦己 (joy-ledger) attribution → **Phase 46, NOT Phase 44**
**Finding:** No existing query exposes per-day joy-ledger totals. `AnalyticsDao.getDailyTotals` filters `type = 'expense'` + optional `entry_source` only — **no `ledger_type` predicate** [VERIFIED: analytics_dao.dart:226-264]. Grep for any per-day-joy query returns nothing (`DATE(timestamp...)` appears exactly once, in `getDailyTotals`, with no ledger filter). The 小确幸日历 heatmap therefore needs a net-new thin per-day-joy fetch (e.g. `getDailyTotals` + a `ledgerType`/joy-filter param, or a sibling `getDailyJoyTotals`).
**Attribution decision:** That fetch is **Phase 46 data work, not Phase 44.** Rationale: (1) the 小确幸日历 is a Phase 46 presentation surface; (2) it maps to NONE of Phase 44's three requirements (OVW-01/TREND-01/DRILL-01); (3) the milestone scopes Phase 44 to "selected-direction data truly missing under OVW/TREND/DRILL." Pulling joy-per-day into Phase 44 would be scope creep against the phase boundary. **Planner action:** explicitly note in PLAN that per-day-joy is deferred to Phase 46 so it is not silently dropped. [Confidence: HIGH]

### Flag B — Window-fetch index check (D-06) → **a real but non-blocking gap found**
**Finding:** `findByBookIds` (both repo interface and DAO impl) issues:
`SELECT * FROM transactions WHERE book_id IN (...) AND is_deleted = 0 AND timestamp >= ? AND timestamp <= ? [order]` [VERIFIED: transaction_dao.dart:249-286].
`transactions_table.dart customIndices` declares `idx_tx_book_timestamp` on `{bookId, timestamp}` (the relevant composite) [VERIFIED: transactions_table.dart:60-67]. **HOWEVER** — per the documented v1.6 CR-01 lesson and confirmed by grep — `customIndices` is **decorative**: Drift's migrator does NOT consume it, and `app_database.dart` only emits explicit `CREATE INDEX` for `category_ledger_configs`, `shopping_items`, `exchange_rates`, `audit_logs`, and `user_profiles`. **There is NO explicit `CREATE INDEX` for ANY `transactions` index in onCreate or onUpgrade** [VERIFIED: grep `idx_tx`/`CREATE INDEX.*transactions` across lib/ returns zero hits in app_database.dart].
**Interpretation vs D-06:** D-06 is still correct — no `(book_id, category_id, timestamp)` index is needed (no SQL-side category filter). But the broader truth is: **none of the transactions indices physically exist in the running DB.** The window-fetch path is currently a table scan filtered by `book_id`/`timestamp`.
**Recommendation (respecting D-13 = no migration):** This is a **non-blocking note for the planner**, NOT a Phase 44 task. D-13 forbids any schema change, and adding a real `CREATE INDEX` for `idx_tx_book_timestamp` would be a (cheap, `IF NOT EXISTS`, additive) migration step — out of scope here. Performance is acceptable at current data volumes (a single book's window is small; the codebase's own joy queries accept full-table reads — see `getJoyRowsForJoyContribution` comment "typical monthly joy tx count 10-100 per book: negligible"). **Planner action:** record this as a tech-debt observation; do NOT add the index in Phase 44. If a future phase relaxes D-13, the fix is a one-line `CREATE INDEX IF NOT EXISTS idx_tx_book_timestamp ON transactions(book_id, timestamp)` in onCreate + an onUpgrade bump. [Confidence: HIGH]

### Flag C — Per-ledger monthly trend primitive (D-08) → **confirmed migration-free**
**Finding:** `AnalyticsDao.getLedgerTotals(bookId, startDate, endDate, entrySourceFilter)` returns `List<LedgerTotalResult>` with `(ledgerType, totalAmount)` per ledger for any window, filtered `type='expense'` [VERIFIED: analytics_dao.dart:266-301]. `GetMonthlyReportUseCase` already extracts `daily`/`joy` from exactly this call [VERIFIED: get_monthly_report_use_case.dart:96-105]. The repo interface `getLedgerTotals` is wired through `AnalyticsRepository`/`AnalyticsRepositoryImpl` [VERIFIED].
**Cleaner-path note (planner's discretion per CONTEXT.md):** Two migration-free options —
1. **In-use-case loop:** `GetExpenseTrendUseCase` calls both `getMonthlyTotals` (for `totalExpenses`/`totalIncome`) AND `getLedgerTotals` (for `daily`/`joy`) per month. Simplest; mirrors the existing per-month loop; 2 queries × 6 months.
2. **Repo helper `getMonthlyLedgerTotals`:** fold both into one repo method. Fewer use-case round-trips but new repo surface.
**Correctness pitfall to flag:** `getLedgerTotals` only returns rows for ledger types that have expenses in the window — a month with zero joy spend yields NO `joy` row. The use case MUST default `dailyTotal`/`joyTotal` to `0` when the row is absent (the existing `GetMonthlyReportUseCase` does this correctly via its `for` loop with pre-initialized `0`s — copy that defensive pattern, do NOT assume both rows are always present). Also: `totalExpenses` from `getMonthlyTotals` should equal `daily + joy` for a consistent window, but DO NOT derive one from the other across query boundaries (entry-source filter and edge timestamps must match — use the SAME `(startDate, endDate, entrySourceFilter)` for both calls). [Confidence: HIGH]

## Model Shapes (current, verified) — for the planner

### `MonthlyTrend` / `ExpenseTrendData` (D-08 target)
```dart
// Source: lib/features/analytics/domain/models/expense_trend.dart (VERIFIED current)
@freezed
abstract class MonthlyTrend with _$MonthlyTrend {
  const factory MonthlyTrend({
    required int year,
    required int month,
    required int totalExpenses,
    required int totalIncome,
    // D-08 ADDS: required int dailyTotal,
    // D-08 ADDS: required int joyTotal,
  }) = _MonthlyTrend;
  factory MonthlyTrend.fromJson(...) => ...;
}
@freezed
abstract class ExpenseTrendData with _$ExpenseTrendData {
  const factory ExpenseTrendData({required List<MonthlyTrend> months}) = _ExpenseTrendData;
}
```
**Pitfall:** `MonthlyTrend` has `fromJson`/`toJson` (JSON-serializable). Adding `required` fields is a breaking change to any persisted/serialized `MonthlyTrend` — verify nothing persists it (grep showed it's only computed in-memory by the use case; HIGH confidence it's transient). Re-run `build_runner` after the edit (regenerates `.freezed.dart` + `.g.dart`). Update `expense_trend_test.dart` (86 LOC) for the new fields.

### `findByBookIds` real signature (DRILL primitive — D-04)
```dart
// Source: lib/features/accounting/domain/repositories/transaction_repository.dart (VERIFIED)
Future<List<Transaction>> findByBookIds(
  List<String> bookIds, {
  LedgerType? ledgerType,
  String? categoryId,            // single L2 leaf — NOT used for L1 drill (D-05 filters Dart-side)
  required DateTime startDate,   // inclusive
  required DateTime endDate,     // inclusive
  SortField sortField,           // {timestamp, amount}
  SortDirection sortDirection,   // {asc, desc}
});
```
**Note vs upstream docs:** CONTEXT.md code_context wrote the param list as `findByBookIds(bookIds, ledgerType, categoryId, startDate, endDate, sort…)` and ROADMAP cited a slightly different shape — the VERIFIED truth is the named-param signature above. `bookIds` is positional; everything else is named; `startDate`/`endDate` are `required`. `SortField`/`SortDirection` from `lib/shared/constants/sort_config.dart` (allow-listed for domain import).

### `CategoryDrillDown` (NEW, D-04) — recommended shape
```dart
@freezed
abstract class CategoryDrillDown with _$CategoryDrillDown {
  const factory CategoryDrillDown({
    required List<Transaction> transactions,   // window+L1-filtered, sorted (planner picks amount vs time)
    required int subtotal,                      // from shared L1-rollup helper (D-11 — same source as donut)
    required int count,
    int? avgPerDay,                             // optional (D-03 / Claude's discretion)
  }) = _CategoryDrillDown;
}
```
`Transaction` domain model is import-safe in domain. Whether `CategoryDrillDown` needs `fromJson` depends on persistence — it's transient (auto-dispose provider), so JSON is likely unnecessary; planner decides.

### L1 rollup inputs (D-11) — the one shared pure helper
- Input: `List<CategoryBreakdown>` (L2-grain, from `MonthlyReport.categoryBreakdowns`) + a `{categoryId → Category}` map for `parentId` lookup.
- `Category` has `parentId` (nullable) + `level` (L1 `level==1`, `parentId==null`; L2 `level==2`, `parentId==<L1 id>`) [VERIFIED: category.dart, app_database migration `WHERE level = 1`/`level = 2`].
- Output: L1-grain list, summed by L1 ancestor, sorted amount-desc, top-10 for donut.
- **No existing helper found** — grep for `rollup`/`parentId`/`level1` in analytics returns only the per-category-joy "Other rollup" (a different concept: folds low-N rows into "Other", NOT L1-parent aggregation). The L1 rollup is **genuinely new shared pure code** [Confidence: HIGH]. The drill summary's subtotal/count for a tapped L1 == that L1's rollup entry.

## Common Pitfalls

### Pitfall 1: `getLedgerTotals` omits zero-spend ledgers
**What goes wrong:** A month with no joy spend returns no `joy` row → null/missing → crash or wrong total. **Avoid:** pre-initialize `dailyTotal=0`/`joyTotal=0`, fill from rows (copy `GetMonthlyReportUseCase` lines 96-105). **Warning sign:** test with a joy-empty month.

### Pitfall 2: Dart-side L1 filter misses L1's own direct transactions
**What goes wrong:** Transactions can be filed directly on an L1 category (not only L2 leaves). The filter must match BOTH `tx.categoryId == l1Id` AND `category(tx.categoryId).parentId == l1Id`. **Avoid:** compute "L1 ancestor of tx.categoryId" = `if level==1 → id; if level==2 → parentId`. **Warning sign:** drill subtotal < donut L1 rollup amount for the same category.

### Pitfall 3: Subtotal drift between donut and drill (D-11 violation)
**What goes wrong:** Drill recomputes subtotal from `findByBookIds` rows while donut uses `categoryBreakdowns` rollup → the two disagree (different query, different rounding/filter). **Avoid:** both consume the ONE shared L1-rollup helper. The drill list shows individual transactions, but its SUMMARY number comes from the rollup, same as donut. **Warning sign:** UI shows donut slice ¥X but drill header ¥Y.

### Pitfall 4: Provider family rebuild storm (D-12)
**What goes wrong:** Raw `DateTime.now()`-derived microsecond bounds in the family key → every frame rebuilds. **Avoid:** normalize via `DateBoundaries`/`TimeWindow` before the key tuple. **Warning sign:** provider rebuilds on idle.

### Pitfall 5: Forgetting `build_runner` after Freezed/Riverpod edits
**What goes wrong:** Stale `.freezed.dart`/`.g.dart` → analyzer errors or AUDIT-10 CI block. **Avoid:** `flutter pub run build_runner build --delete-conflicting-outputs` after any `@freezed`/`@riverpod` edit. **Warning sign:** "method not found" on a freshly-added field.

## Runtime State Inventory

> Greenfield-additive within an existing app; NO rename/migration. Included for completeness.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — Drift stays v21, no new tables/columns/keys (D-13) | None |
| Live service config | None — no external service touched | None |
| OS-registered state | None | None |
| Secrets/env vars | None — no crypto/secret surface in this phase | None |
| Build artifacts | `.freezed.dart`/`.g.dart` for `expense_trend.dart` + new `category_drill_down.dart` + `repository_providers.g.dart` regenerate on `build_runner` | Run build_runner after model/provider edits |

**Nothing requiring data migration** — verified: D-13 locks schema at v21; no stored-string rename; the only "state" is regenerated codegen.

## Validation Architecture

> `nyquist_validation: true` in `.planning/config.json` [VERIFIED] — section REQUIRED. Gates VALIDATION.md downstream.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (+ `drift` `AppDatabase.forTesting()` in-memory NativeDatabase) |
| Config file | `flutter_test_config.dart` (golden comparator gate — not relevant to this data phase) |
| Quick run command | `flutter test test/unit/application/analytics/ test/unit/features/analytics/domain/models/` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TREND-01 | `MonthlyTrend` carries dailyTotal+joyTotal; 6-month series fills zero-spend months with 0 | unit | `flutter test test/unit/application/analytics/get_expense_trend_use_case_test.dart` | ✅ EDIT (171 LOC, exists) |
| TREND-01 | `MonthlyTrend`/`ExpenseTrendData` model shape + (de)serialization | unit | `flutter test test/unit/features/analytics/domain/models/expense_trend_test.dart` | ✅ EDIT (86 LOC, exists) |
| DRILL-01 | `GetCategoryDrillDownUseCase` returns window+L1-filtered txns, correct subtotal/count, L1-direct + L2-child both included, empty-window → empty | unit | `flutter test test/unit/application/analytics/get_category_drill_down_use_case_test.dart` | ❌ Wave 0 — **TDD: write FIRST (D-04)** |
| DRILL-01 / OVW-01 | Shared L1-rollup helper: L2→L1 sum, amount-desc, top-10, L1-direct handling | unit | `flutter test <new rollup test file>` | ❌ Wave 0 |
| OVW-01 | (pure display transform — no new use case) covered by L1-rollup helper test + existing `get_monthly_report_use_case_test.dart` | unit | `flutter test test/unit/application/analytics/get_monthly_report_use_case_test.dart` | ✅ exists (regression only) |

### Sampling Rate
- **Per task commit:** quick run (analytics unit dir) — <30s
- **Per wave merge:** `flutter test` full suite (MUST include `home_screen_isolation_test.dart` + both `anti_toxicity_phase16/17_test.dart` + architecture/CJK scans — these are structural locks the data phase must not regress)
- **Phase gate:** full suite green + `flutter analyze` 0 issues before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/unit/application/analytics/get_category_drill_down_use_case_test.dart` — covers DRILL-01 (write BEFORE the use case, D-04). Seed pattern: mirror `get_expense_trend_use_case_test.dart` (in-memory `AppDatabase.forTesting()` + real DAOs + `categoryDao.insertCategory` for L1/L2 + `transactionDao` inserts).
- [ ] Shared L1-rollup helper test (covers OVW-01 donut rollup + DRILL summary — D-11).
- [ ] Edit `get_expense_trend_use_case_test.dart` + `expense_trend_test.dart` for the two new fields.
- [ ] (No framework install needed — `flutter_test` present.)

*Note: TDD ordering for DRILL-01 is a LOCKED decision (D-04), not a suggestion. The use-case test is RED before any `GetCategoryDrillDownUseCase` code.*

## Security Domain

> `security_enforcement` not set to `false` in config → nominally enabled. This phase is read-only aggregation over already-encrypted data; minimal surface.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No auth surface touched |
| V3 Session Management | no | — |
| V4 Access Control | no | Reads only the active book(s) already scoped by caller |
| V5 Input Validation | partial | `findByBookIds` uses parameterized Drift `Variable.with*` (no SQL injection); window bounds validated upstream by `TimeWindowValidation.assertValid` |
| V6 Cryptography | no (inherited) | Data already at-rest encrypted via SQLCipher; NO new crypto, NO direct `flutter_secure_storage` access (CLAUDE.md crypto rule) |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SQL injection via category/book id | Tampering | Already mitigated — all DAO queries use bound `Variable.with*` placeholders, never string interpolation of user data [VERIFIED: transaction_dao.dart / analytics_dao.dart] |
| Sensitive data in logs | Info disclosure | CLAUDE.md "NEVER log sensitive data" — drill-down handles raw amounts/notes; do NOT add debug logging of transaction contents |
| Cross-book data leak | Info disclosure | `findByBookIds` scopes by `book_id IN (...)` from caller; the new use case must pass ONLY the active book(s), never widen |

**No new attack surface** — no network, no new persistence, no new secret. The drill-down summary copy must additionally be ADR-012-safe (D-03) — but that is a values/anti-gamification constraint enforced by `anti_toxicity_*_test`, surfaced at Phase 46/47, not a security control.

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| ROADMAP SC#3: "new `AnalyticsDao.getCategoryTransactions` + `(book_id, category_id, timestamp)` index" | CONTEXT.md D-04/05/06: reuse `findByBookIds` + Dart-side L1 filter, NO new DAO, index N/A | CONTEXT.md is the locked authority; tightens the looser ROADMAP "or" clause |
| `MonthlyTrend{totalExpenses, totalIncome}` | + `dailyTotal` + `joyTotal` (D-08) | Single trend family drives 3 tabs |
| Per-day joy assumed available | Confirmed NOT available; deferred to Phase 46 (Flag A) | Prevents silent Phase 44 scope creep |

**Deprecated/irrelevant here:** `GetBudgetProgressUseCase` is a stub (no-arg provider) — DO NOT wire it; budgets are ANALYTICS-V2-03. `totalIncome` is always 0 (no income path) — overview is expense-side only; do not surface savings-rate.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `MonthlyTrend` is transient (not persisted), so adding `required` fields is safe | Model Shapes | LOW — grep shows it's only built in-memory by the use case; if some cache serializes it, the codegen change would need a migration. Planner can confirm with a 10s grep for `MonthlyTrend.fromJson` call sites. |
| A2 | Current data volumes make the missing `idx_tx_book_timestamp` index non-blocking for window fetch | Flag B | LOW — consistent with the codebase's own accepted full-read joy queries; if a book has 10k+ txns in a window, perf could degrade, but D-13 forbids the fix this phase anyway. |
| A3 | Per-day-joy belongs to Phase 46 | Flag A | LOW — backed by phase boundary + requirement mapping; if the user later wants it in 44, it's a one-param addition to `getDailyTotals`. |

**All structural/data-contract claims (model shapes, signatures, index absence, query SQL) are [VERIFIED] against committed source this session — not assumed.**

## Open Questions

1. **Does `CategoryDrillDown` need JSON serialization?**
   - Known: it feeds an auto-dispose provider (transient).
   - Unclear: whether any caching/restore wants it serialized.
   - Recommendation: omit `fromJson`/`toJson` unless a consumer needs it (planner decides; default = transient, no JSON).

2. **Transaction sort in drill-down (amount vs time) and `avgPerDay` inclusion.**
   - Explicitly Claude's-discretion per CONTEXT.md — planner decides. Recommendation: time-desc (matches `ListTransactionTile` list mental model) + include `avgPerDay` only if the summary copy stays ADR-012-neutral (a plain daily average is descriptive, not a target — safe).

3. **L1-rollup helper location** (Claude's discretion). Recommendation: a pure top-level function or extension in `lib/features/analytics/domain/` (domain-pure, no Flutter import) so both the donut display transform and the drill use case import it without a layer violation. Avoid `lib/shared/` only if it would pull a domain type up; `CategoryBreakdown`/`Category` are domain types, so domain placement is cleanest.

## Sources

### Primary (HIGH confidence — verified against committed source this session)
- `lib/data/daos/analytics_dao.dart` — `getDailyTotals` (no ledger filter), `getLedgerTotals`, `getCategoryTotals`, `_joyExpenseFilter`/`_dailyExpenseFilter`
- `lib/data/daos/transaction_dao.dart` — `findByBookIds` SQL (`book_id IN (...) AND is_deleted=0 AND timestamp BETWEEN`)
- `lib/features/accounting/domain/repositories/transaction_repository.dart` — `findByBookIds` named-param signature
- `lib/features/analytics/domain/models/expense_trend.dart` — `MonthlyTrend`/`ExpenseTrendData` current shape
- `lib/features/analytics/domain/models/monthly_report.dart` + `analytics_aggregate.dart` — `MonthlyReport`/`CategoryBreakdown`/`LedgerTotal`
- `lib/application/analytics/get_expense_trend_use_case.dart` + `get_monthly_report_use_case.dart` — loop pattern + ledger-split extraction
- `lib/data/tables/transactions_table.dart` + `lib/data/app_database.dart` — decorative `customIndices`, no explicit transactions `CREATE INDEX`, `schemaVersion => 21`
- `lib/features/accounting/domain/models/category.dart` — `parentId`/`level`
- `lib/features/analytics/presentation/providers/repository_providers.dart` + `lib/features/accounting/presentation/providers/repository_providers.dart` — provider wiring (`transactionRepositoryProvider`, `categoryRepositoryProvider`)
- `lib/shared/constants/sort_config.dart` — `SortField`/`SortDirection`
- `test/unit/application/analytics/get_expense_trend_use_case_test.dart` — TDD seed pattern
- `.planning/phases/44-.../44-CONTEXT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md` — locked scope

### Secondary (MEDIUM)
- `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` (§4 cross-period), `ADR-017` (生存/灵魂 grep-ban) — constraint context

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages; all primitives verified in-use
- Architecture/data contracts: HIGH — every signature/model/SQL read from committed source
- Pitfalls: HIGH — derived from observed query behavior (zero-spend rows, decorative index, Dart-side filter precedent)
- Flag resolutions: HIGH — A/B/C each grounded in grep + source reads

**Research date:** 2026-06-16
**Valid until:** ~2026-07-16 (stable; only invalidated by a schema change or a refactor of `findByBookIds`/`getLedgerTotals`/`MonthlyReport`)
