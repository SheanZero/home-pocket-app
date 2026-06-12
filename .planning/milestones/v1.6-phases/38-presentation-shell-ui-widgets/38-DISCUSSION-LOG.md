# Phase 38: Presentation Shell + UI Widgets - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-08
**Phase:** 38-presentation-shell-ui-widgets
**Areas discussed:** Edit entry point, Reorder exposure, Batch-mode chrome, Filter bar

---

## Edit entry point (tap conflict: DONE-01 vs established tile convention)

| Option | Description | Selected |
|--------|-------------|----------|
| tap=切换, 尾部 chevron 进编辑 | 保留 DONE-01 (tap 整行切换完成态);行尾加显式 chevron/info affordance 进编辑。Bring!/AnyList 主流模式,与现有 tile 尾部 chevron 一致。 | ✓ |
| tap 行体=编辑, checkbox=切换 | leading checkbox 切换;tap 行体进编辑。与现有交易 tile 一致,但重新解释了 DONE-01。 | |
| tap=切换, 双向 swipe | tap 切换;一侧 swipe 删除、另一侧 swipe 编辑。发现性差,与 batch 禁用 swipe 纠缠。 | |

**User's choice:** tap=切换, 尾部 chevron 进编辑 (D38-01)
**Notes:** 保留 DONE-01 原义;trailing 区域将同时容纳编辑 affordance 与 reorder drag handle,需与 Dismissible swipe 区分。

---

## Reorder exposure (SC4 SliverReorderableList vs REORDER-01 v2-deferred vs long-press 被 batch 占用)

| Option | Description | Selected |
|--------|-------------|----------|
| 暴露, 显式 drag handle | SliverReorderableList + 行尾显式 drag handle (ReorderableDragStartListener),避开 long-press。接 Phase 37 ReorderShoppingItemsUseCase,满足 SC4。completed 固定在 divider 下不可拖。 | ✓ |
| 用 widget 但不暴露 handle | 用 SliverReorderableList 作容器满足字面,但本期不放 handle;为 v2 预留。 | |
| 不上拖拽, 普通 SliverList | 与 REORDER-01 v2-deferred 一致,但与 SC4 字面冲突,需改 ROADMAP。 | |

**User's choice:** 暴露, 显式 drag handle (D38-02)
**Notes:** 选择尊重 SC4 + Phase 37 已建 use case;REORDER-01 v2 条目对 local/handle 情形被取代,跨设备同步排序仍 deferred (D37-01)。reorder 在 batch 模式下需禁用。

---

## Batch-mode chrome (浮动 action bar vs 父级 nav bar + FAB)

| Option | Description | Selected |
|--------|-------------|----------|
| Material contextual mode | 共享 batchSelectMode provider;MainShellScreen 隐藏 nav bar + FAB,顶部 selection header(N selected + 全选/取消),底部浮动 action bar。最标准最干净,需跨父子协调。 | ✓ |
| 自包含, 浮在 nav bar 上方 | 不动父级;action bar 浮在现有 nav bar 上方。最简单无耦合,但视觉略挤。 | |
| 只隐 FAB, 保留 nav bar | 折中:provider 只隐 FAB,nav bar 保留,action bar 占 FAB 位置。 | |

**User's choice:** Material contextual mode (D38-03)
**Notes:** 架构关键点:nav bar/FAB 住父级 MainShellScreen,ShoppingListScreen 是 IndexedStack body,隐藏需共享 provider 协调。

---

## Filter bar (FILT-01 "与 v1.4 ListSortFilterBar 一致" — 复用 vs 新建)

| Option | Description | Selected |
|--------|-------------|----------|
| 新建购物专用, 复用样式 | 新建购物专用 chip bar(ledger/category/status + 一键清除),复用 ListSortFilterBar 视觉样式;sticky 在分段控件下方;category 复用 list_category_filter_sheet。 | ✓ |
| 泛化现有 widget 共用 | 重构 ListSortFilterBar 成可配置组件两处共用;更 DRY 但交易列表已有 golden,回归面大。 | |
| You decide | 交给 planner 决定。 | |

**User's choice:** 新建购物专用, 复用样式 (D38-04)
**Notes:** 维度不同(交易是排序模式,购物是 ledger/category/status);避免重构现有 widget 引入交易列表 golden 回归。

---

## Claude's Discretion

- 空状态 CTA 文案/布局(3 个 SHOP-04 变体;最终字符串 Phase 39 i18n)
- Family attribution chip(SYNC-04)— 镜像 list_transaction_tile.dart 的 memberTag 样式
- strikethrough + fade 动画时长/曲线(DONE-01)
- loading 状态样式(spinner vs skeleton)
- add/edit 表单呈现(D2 "screen" → 全屏 MaterialPageRoute 镜像 ManualOneStepScreen)
- estimated-price 输入控件形态(integer yen via NumberFormatter,ITEM-05 已锁)

## Deferred Ideas

- 跨设备同步排序 — 仍 deferred (D37-01)
- v2 购物增强:SUBTOTAL-01 / AUTO-01 / GROUP-01 / TAGFILT-01 / DUP-01 / COLLAPSE-01 — 全部 v2(D8 不变)
