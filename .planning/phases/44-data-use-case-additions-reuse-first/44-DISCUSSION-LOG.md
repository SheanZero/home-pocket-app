# Phase 44: 数据与用例补全 (Data / Use-Case Additions — reuse-first) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-16
**Phase:** 44-data-use-case-additions-reuse-first
**Areas discussed:** 下钻呈现与深度, 下钻数据路径 (DRILL-01), 支出趋势 tab 范围 (TREND-01)

---

## 下钻呈现与深度

### Q1 — 点 L1 分类后，下钻去哪里？
| Option | Description | Selected |
|--------|-------------|----------|
| analytics 内轻量下钻 | sheet/页，尊重当前 analytics 时间窗，auto-dispose；复用 findByBookIds + ListTransactionTile | ✓ |
| 跳转「列表」tab | 最大复用既有列表 UI，但 GetListTransactionsUseCase 年月/单日模型无法映射任意窗口 | |
| 你决定 | 交由 Claude 拍板 | |

### Q2 — 点 L1 分类，看到什么粒度？
| Option | Description | Selected |
|--------|-------------|----------|
| L1 平铺全部交易 | 列出该 L1（含 L2 子类）当前窗口全部交易，最简单、reuse-first | ✓ |
| 先 L1→L2 再进交易 | 多一层 breakdown，更细更重 | |
| 你决定 | — | |

### Q3 — 下钻视图顶部要不要中性小结？
| Option | Description | Selected |
|--------|-------------|----------|
| 要：小计+笔数 | 中性描述性 header（小计 + 笔数，可选日均），ADR-012-safe；需一个轻量聚合 | ✓ |
| 不要，纯列表 | 更轻，纯复用 ListTransactionTile | |
| 你决定 | — | |

**Notes:** 三选共同把下钻指向「analytics 内、任意窗口、带小结」→ 新 thin 只读路径，而非复用 v1.4 列表。

---

## 下钻数据路径 (DRILL-01)

### Q1 — 数据路径用哪个？
| Option | Description | Selected |
|--------|-------------|----------|
| 新 thin GetCategoryDrillDownUseCase | CategoryDrillDown Freezed（txs+小计+笔数）+ use case，走 findByBookIds，尊重任意窗口；符合「至多一条新只读路径」 | ✓ |
| 复用 v1.4 GetListTransactionsUseCase | 零新 use case 但需改造年月/单日模型 + 不带聚合，与「analytics 内下钻+小结」不契合 | |
| 你决定 | — | |

### Q2 — L1 过滤怎么做？
| Option | Description | Selected |
|--------|-------------|----------|
| Dart 侧按 L1 父类过滤 | 取窗口交易后 .where（同 v1.4 多分类）；零新 DAO/SQL；小计/笔数复用 donut L1 rollup | ✓ |
| 新 AnalyticsDao.getCategoryTransactions (SQL) | category_id IN (子类) SQL 过滤；需新 DAO + (book_id, category_id, timestamp) 索引核查 | |
| 你决定 | — | |

**Notes:** Dart-side 过滤 → `(book_id, category_id, timestamp)` 复合索引 N/A；窗口取数走既有 `(book_id, timestamp)`。

---

## 支出趋势 tab 范围 (TREND-01)

### Q1 — 三 tab（总/日常/悦己）是否全上？
| Option | Description | Selected |
|--------|-------------|----------|
| 三 tab 全上 | 给趋势补 per-ledger 月度数据（getLedgerTotals 原语，无迁移），与已批准设计一致 | ✓ |
| 先 total-only | 最小数据工作，日常/悦己延后；但与 Phase 43 已批准三-tab 设计不符 | |
| 你决定 | — | |

### Q2 — per-ledger 趋势怎么接入？
| Option | Description | Selected |
|--------|-------------|----------|
| 扩展 MonthlyTrend 带 daily/joy | 每月一次取齐三值，一个 trend provider family，避免 3× 查询/family | ✓ |
| 加 ledgerType 参数调 3 次 | 三条独立 trend；更简单但 3× 往返 + 3 family | |
| 你决定 | — | |

### Q3 — 确认悦己趋势的跨期约束？
| Option | Description | Selected |
|--------|-------------|----------|
| 确认：悦己中性滚动 | 悦己 tab = 中性 6 月滚动线，无本月vs上月 delta；数据层不算/不暴露 joy 跨期 delta | ✓ |
| 重新考虑悦己 tab | 悦己 tab 不画趋势线、改别的——会偏离已批准设计 | |

**Notes:** 本月vs上月（总/日常）是 Phase 46 呈现 framing，6 月序列已含，非新数据；ADR-012 §4 支出侧例外须 Phase 45 前以 `## Update` 补正。

---

## Claude's Discretion

- 下钻壳具体形态（bottom sheet vs pushed route）→ Phase 45/46 presentation。
- `CategoryDrillDown` 是否含 `avgPerDay`、交易排序 → planner。
- L1 rollup 放置（pure 函数/extension/provider）→ planner。
- per-ledger 月度数据补在 repo 还是 use case 内循环 → planner（均无迁移）。

## Deferred Ideas

- 里程碑级已锁定的范围外项（收入/结余率、预算迁移、可重排仪表盘、Sankey、滚动带、分币种小计、JOY-04 持久化）—— 全部记录于 CONTEXT.md `<deferred>`，非本次新增。
- **Research flag（非延后，是 researcher 待核查）:** 小确幸日历 per-day 悦己数据归属（`getDailyTotals` 无 ledger 过滤）—— 见 CONTEXT.md Research flags。
