# Phase 45: 展示外壳重建 (Presentation Shell Rebuild) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-17
**Phase:** 45-presentation-shell-rebuild
**Areas discussed:** 外壳范围边界, 卡片注册表契约, 下钻宿主落点, ADR-012 补正时机

---

## A. 外壳范围边界 (Shell scope)

| Option | Description | Selected |
|--------|-------------|----------|
| A1 纯结构重构（推荐）| 保持现 7 卡 + 现 IA 不变，仅抽卡到 widgets/cards/ + 建注册表 + refresh 派生；页面观感不变 → golden 保绿、isolation test 同断言过、diff 纯机械抽取；round-5 B 重排/增删全留 Phase 46 | ✓ |
| A2 现在落最终 IA | Phase 45 就采用 round-5 B 顺序/分区（趋势置顶 + donut hero），删被舍弃的卡、为两张新卡留空槽；Phase 46 只填槽 + 图表打磨；代价：45 就有可见变化 + golden 漂移 | |

**User's choice:** A1 纯结构重构
**Notes:** 把所有可见变化集中到 Phase 46、golden 重基线集中到 Phase 47。「shell-before-cards」的纯净读法：45 立机制、46 填内容、47 验视觉。scroll container 选型归 planner discretion。

---

## B. 卡片注册表契约 (Registry contract)

### B-i — 契约形态 + 「由构造保证 home 隔离」强度

| Option | Description | Selected |
|--------|-------------|----------|
| 强契约 + 新测试（推荐）| 一个 typed 注册表同驱动布局+refresh；每卡声明 refreshTargets(ctx)；_refresh = registry.expand(refreshTargets)；新单测断言并集 ⊆ analytics provider、0 个 home/*（abstract 基类 vs spec-list 由 planner 定）| ✓ |
| 轻量、只靠现有测试 | 注册表同样驱动，但不新增 registry-targets 测试，仅依赖现有 home_screen_isolation_test 间接断言 | |

**User's choice:** 强契约 + 新测试

### B-ii — 条件卡怎么进注册表

| Option | Description | Selected |
|--------|-------------|----------|
| 注册表 isVisible(ctx)（推荐）| 条目带 isVisible(ctx) 谓词（如 isGroupMode）；shell 只 build 可见卡，_refresh 也只失效可见卡 provider；min-N<5 异步自隐仍留卡内 | ✓ |
| 卡内部自隐 + 全量失效 | 所有卡进注册表，不可见时自返 SizedBox.shrink；_refresh 始终失效全量并集（含 group-mode family 变体）| |

**User's choice:** 注册表 isVisible(ctx)
**Notes:** async 依赖数据的自隐（satisfaction histogram min-N<5）ctx 拿不到，保持卡内 .when 判断，refreshTargets 照常含其 provider。

---

## C. 下钻宿主落点 (Drill-down host)

### C-i — 宿主形态（现在锁、Phase 46 实现）

| Option | Description | Selected |
|--------|-------------|----------|
| modal bottom sheet（我推荐）| 可拖拽/滚动底部 sheet；天然尊重当前时间窗、与 auto-dispose drill family 契合、无需 GoRouter 注册 | |
| pushed route (GoRouter) | 压入独立页；更多屏幕空间 + back 栈适合长交易列表，但需 route 注册 + 时间窗上下文传递 | ✓ |

**User's choice:** pushed route (GoRouter)
**Notes:** 用户覆盖了我对 sheet 的推荐——要独立页的屏幕空间 + back 栈。Phase 46 落地须知已记入 CONTEXT research flag（读 keepAlive session provider、仅传 l1CategoryId、family 保持 auto-dispose）。

### C-ii — 何时落地 / Phase 45 是否预留

| Option | Description | Selected |
|--------|-------------|----------|
| 全部入 Phase 46（推荐）| 下钻是新行为，与 A1 行为保持冲突；Phase 45 零预留，注册表契约天然容得下下一张会 push route 的卡；保持 45 diff 纯净 + golden 绿 | ✓ |
| Phase 45 预留宿主脚手架 | 先把 sheet/route 宿主壳 + 入口接点建好（不接数据/不触发），Phase 46 只填内容；略破坏 A1 纯机械抽取 | |

**User's choice:** 全部入 Phase 46

---

## D. ADR-012 补正时机 (ADR-012 amendment timing)

| Option | Description | Selected |
|--------|-------------|----------|
| 折进 Phase 45（推荐）| 把 ADR-012 ## Update（支出侧 本月vs上月 = §4 在案例外、悦己侧跨期仍绝对禁止）作为 Phase 45 一个小 doc 任务；append-only、兑现已记录的「Phase 45 前」义务、红线提前上档、零功能耦合 | ✓ |
| 正式改挂 Phase 46 | 重定为 Phase 46 前置（callout 真正渲染处），在 CONTEXT + STATE 记录改挂以免丢失；保持 45 纯结构但有「补正被遗忘」风险 | |

**User's choice:** 折进 Phase 45
**Notes:** 文档原定「Phase 45 前」（STATE.md 行 192 确认 Phase 43 punt），至今未做；A1 下 Phase 45 不渲染该 callout 故无功能依赖，但 append-only 近乎零成本、兑现义务。ADR 状态 append-only（.claude/rules/arch.md）。

---

## Claude's Discretion

- 注册表抽象具体形态（abstract `AnalyticsCard` 基类 vs `List<AnalyticsCardSpec>`）—— planner 定
- scroll container 选型（`SingleChildScrollView`+`Column` vs `ListView.builder`）—— planner 定
- 卡片文件拆分粒度/命名、`AnalyticsCardContext` 字段集精确形状、`_AnalyticsDataCard` 卡壳留 shell vs 抽 cards/ —— planner 定

## Deferred Ideas

- round-5 B IA 重排 + 卡片增删 + 图表打磨 + 暖色动效 → Phase 46
- 下钻宿主真实落地（pushed route + GoRouter 注册 + donut tap 入口）→ Phase 46
- i18n / 反毒性扫描 / macOS golden 重基线 / 全量门禁 / 真机 UAT → Phase 47
- 里程碑级锁定外项：收入/结余率、预算、可定制仪表盘、Sankey、中性滚动带、分币种小计、JOY-04 持久化、fl_chart 2.x 升级（详见 CONTEXT deferred）
