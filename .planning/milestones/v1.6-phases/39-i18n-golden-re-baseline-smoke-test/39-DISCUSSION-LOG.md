# Phase 39: i18n + Golden Re-baseline + Smoke Test - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-08
**Phase:** 39-i18n-golden-re-baseline-smoke-test
**Areas discussed:** Tab 文案, Golden 覆盖广度, 既有文案复审, Smoke test 范围

---

## Area selection

| Option | Description | Selected |
|--------|-------------|----------|
| Tab 标签文案 | 4th nav tab 缩短 + key rename | ✓ |
| Golden 覆盖广度 | SC3 最小集 vs 扩展变体 | ✓ |
| 既有文案复审 | 接受原样 vs 调整语气 | ✓ |
| Smoke test 范围 | 最小 SC4 vs 加 privacy 重申 | ✓ |

**User's choice:** all four areas.

---

## Tab 文案

| Option | Description | Selected |
|--------|-------------|----------|
| 缩短:買い物/购物/Shopping | 与兄弟 tab 等长,底部 nav 不换行/截断 | ✓ |
| 保留:買い物リスト/购物清单/Shopping List | 语义完整但偏长,可能换行/缩字 | |

**User's choice:** 缩短:買い物/购物/Shopping
**Notes:** 兄弟 tab 均为 2-3 字（ホーム/一覧/チャート）。key rename `homeTabTodo`→`homeTabShopping`、删除 stale `todoTab`（核实无代码引用）、改 `home_bottom_nav_bar.dart:45` 均为机械执行；图标已在 Phase 38 换为 `shopping_bag`，本 phase 不动。

---

## Golden 覆盖广度

### 粒度

| Option | Description | Selected |
|--------|-------------|----------|
| 整屏 screen 状态(贴合 SC3) | ShoppingListScreen 全屏 golden,需 seed+override,成本高 | |
| 组件级(延续现有约定) | tile/empty/filter/batch 各自 golden,稳定易维护 | ✓ |
| 混合:关键全屏+高风组件 | 列表全屏 + tile 变体组件级 | |

**User's choice:** 组件级(延续现有约定)
**Notes:** 现有 11 个 golden 均为组件级。需在 CONTEXT 注明"用组件级覆盖 SC3 各状态"以对齐验收口径，避免因缺整屏快照被判 fail。

### 变体集（multiSelect）

| Option | Description | Selected |
|--------|-------------|----------|
| Empty 3 变体 | private/public-solo/public-family | ✓ |
| Tile active + completed | 含 strikethrough(DONE-01) | ✓ |
| Tile 双轨账本边框(daily/joy) | SHOP-03/ADR-019 配色回归 | |
| Tile attribution chip + filter/batch bar | SYNC-04 chip + filter active + batch 栏 | ✓ |

**User's choice:** Empty 3 变体 + Tile active/completed + attribution chip + filter/batch bar（**未**单选双轨边框）
**Notes:** 双轨边框改为靠 active/completed tile 顺带各出现一次（建议 active=daily, completed=joy），不单独成对 golden。每变体默认 3 locales × 2 配色（遵 SC3）。

---

## 既有文案复审

| Option | Description | Selected |
|--------|-------------|----------|
| 接受原样 | 文案一致得体,本 phase 不动现值 | ✓ |
| 微调一致性 | 统一 ja 買うもの vs 買い物 等用词 | |

**User's choice:** 接受原样
**Notes:** Phase 38 已填全部 shopping 文案（实值），三语 key 数已对齐 1077。本 phase 仅做 tab key rename/delete，不改任何现有 ARB 值。

---

## Smoke test 范围

| Option | Description | Selected |
|--------|-------------|----------|
| 最小(只 SC4) | StreamProvider 自动 emit 不 invalidate | |
| SC4 + provider 层 privacy 再断言 | 加:远端 private 不出现在任何 watchByListType StreamProvider | ✓ |

**User's choice:** SC4 + provider 层 privacy 再断言
**Notes:** Phase 37 已在 application 层覆盖 reactive/privacy/tombstone；本 smoke test 聚焦 provider/presentation 层，不复制 application 层 tombstone 测试。

---

## Claude's Discretion

- 新 key 命名 `homeTabShopping`（与 `homeTab*` 约定一致）。
- golden 尺寸/seed/override 策略——沿用现有 harness（`list_sort_filter_bar_golden_test.dart` 模式），落点 `test/golden/` + `test/golden/goldens/`。
- D39-05 中 active/completed tile 各用哪个 ledger 颜色。
- coverage ≥70% 个别难覆盖文件的取舍（补真实测试优先，不降阈值）。

## Deferred Ideas

- 整屏 ShoppingListScreen golden（本 phase 用组件级）。
- 专门的 daily-vs-joy 双轨边框成对 golden（靠顺带覆盖）。
- v2 shopping enhancements（SUBTOTAL-01/AUTO-01/GROUP-01/TAGFILT-01/DUP-01/COLLAPSE-01/REORDER-01 cross-device）。
