# Phase 24: Data Layer Extension - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-29
**Phase:** 24-Data Layer Extension
**Areas discussed:** 排序依赖 (SortField enum 时序), 查询上限 (limit 策略), watch 流过滤粒度, DateBoundaries 时区基准

---

## 排序依赖 (SortField enum 时序)

| Option | Description | Selected |
|--------|-------------|----------|
| 把 enum 提前到 Phase 24 | 在 Phase 24 就创建 lib/shared/constants/sort_config.dart 的 SortField/SortDirection enum，DAO 直接用类型安全枚举。Phase 25 只引用。SC#1 在本 phase 完全可测。 | ✓ |
| Phase 24 用原始参数 | DAO 先收一个 String/primitive 排序参数，Phase 25 再引入类型化 enum 并替换。本 phase 不碰 shared/constants。 | |
| Phase 24 只 timestamp-desc | DAO 暂时硬编码 timestamp DESC 排序，排序参数留到 Phase 25 再加。SC#1 的 SortField 部分推迟。 | |

**User's choice:** 把 enum 提前到 Phase 24
**Notes:** Roadmap SC#1 要求 DAO 按 requested SortField 排序，若 enum 留 Phase 25 则本 phase SC#1 不可测。提前建到 shared/constants 不触发 import_guard。

---

## 查询上限 (limit 策略)

| Option | Description | Selected |
|--------|-------------|----------|
| 500 硬上限 | 沿用 research 提议 limit=500，超出只显示最近 500 条（分页留 v1.5）。 | |
| 月范围不设 limit | 对单月日期范围查询不加 limit，保证一个月内所有条目都显示。 | ✓ |
| 你来定 | 由实现时选合理默认值。 | |

**User's choice:** 月范围不设 limit
**Notes:** 分页明确推到 v1.5。极端大数据量一次性加载可接受。

---

## watch 流过滤粒度

| Option | Description | Selected |
|--------|-------------|----------|
| 全部过滤进 SQL watch | watch 查询绑定所有过滤条件 (bookIds+dateRange+ledger+category+ORDER BY)，任一变化触发新查询。provider 层薄。 | ✓ |
| 宽 watch + provider 内过滤 | watch 只绑 bookIds+月范围，ledger/category/sort 在 provider 层内存过滤。SQL 重查少但内存活多。 | |
| 你来定 | 由实现时按 watch 重建成本与 rebuild 行为权衡。 | |

**User's choice:** 全部过滤进 SQL watch
**Notes:** 与 SC#2 reactive-without-invalidate 契合，过滤逻辑集中 SQL 一处。

---

## DateBoundaries 时区基准

| Option | Description | Selected |
|--------|-------------|----------|
| 设备本地时间 | 月/日边界用 local time 计算，与 AnalyticsDao 的 DATE(...,'localtime') 分组一致。23:30 交易归当天。 | ✓ |
| UTC | 边界按 UTC 计算。与 AnalyticsDao localtime 分组不一致，可能日历/列表分组错位。 | |

**User's choice:** 设备本地时间
**Notes:** 一致性优先 —— 避免日历每日合计与列表分组落在不同日。

---

## Claude's Discretion

- `findByBookIds` 多值 book_id 的 SQL 实现方式（Drift `isIn()` vs `customSelect` IN(?) 展开），约束：必须单条 SQL。
- 软删除/hash chain 契约测试 (SC#4) 与 shadow-book 解密失败 fixture (SC#5) 的测试组织。
- watch 流 distinct/去重处理。

## Deferred Ideas

- 分页 / 无限滚动 → v1.5。
- family 模式日历 combined 合计 → v1.5（own-book only 已为 v1.4 默认）。
- undo-delete SnackBar / loading skeleton → post-v1.4。
