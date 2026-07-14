---
quick: 260714-qit
status: complete
date: 2026-07-14
verification: human_needed
commits:
  # round 1 — 视觉高保真移植（presentation-only，零/极少新 ARB）
  - a5f602c6  # home r1
  - e2cb6b50  # list r1
  - 0014cc54  # analytics r1
  - 91616bc2  # shopping r1
  # round 2 — 完全按 mockup 实现（用户逐项决策，新 ARB 放开，含 1 处数据层改动）
  - 55bb7687  # home r2
  - 9764ec24  # list r2 (getDailyTotals ledgerType + D-06 revised)
  - 0b038694  # analytics r2 (month-only window)
  - 25fc68a4  # shopping r2
  - c1f98229  # golden rebaseline (cross-cutting)
  - ea1a627c  # arb metadata parity fix
---

# Quick Task 260714-qit — v15 A1/A3 四页面视觉高保真移植

**Goal:** 把 `whole-app-warm-japanese-v15.html` 中 A1（个人·浅色）/ A3（个人·深色）的**主页 / 明细 / 统计 / 购物**四页面视觉高保真移植到现有 Flutter 屏幕，替换现有 presentation 表面。

**Mode:** GSD quick-full（分屏分批 + 校验）。锁定决策 D-01（分屏分批：四个独立聚焦 executor，逐屏原子提交）+ D-02（视觉高保真移植：presentation-only，`context.palette` 派生浅/深，禁硬编码色，保留数据接线）。见 `260714-qit-CONTEXT.md`。

## Pipeline

planner(quick-full) → plan-checker（0 blocker / 2 verify-block warning 已直接修）→ 4× gsd-executor（顺序 main tree，逐屏原子提交）→ orchestrator 全量 `flutter analyze` + `flutter test` → gsd-verifier。

## 交付（四屏，各原子提交，文件不重叠）

| 屏 | Commit | 主要改动 | Golden 重基线(浅+深) | Provider | ARB |
|---|---|---|---|---|---|
| 主页 home | `a5f602c6` | hero_header 月份深绿标题+月历 icon；home_hero_card `.faithful-hero`（圆角22/accent 边/暖色叠底/软阴影/trend pill）；最近取引行 daily/joy 文字色；family_invite CTA 樱粉 | 10 | 无 | 无 |
| 明细 list | `e2cb6b50` | 新 `ListLedgerSegments` 全宽 toned pill（すべて/日常/ときめき）；filter-bar 重排为 v15 utilities row；calendar 卡化；day-header 静默；卡片圆角14+内分隔 | 18 | 无 | 无 |
| 统计 analytics | `0014cc54` | 新 `AnalyticsSegmentedControl<T>`；trend card + donut dimension controls 换 toned segmented + member-filter pill；registry 架构 + GUARD-01 保持 | 20 | 无 | 无 |
| 购物 shopping | `91616bc2` | 新 `ShoppingSegmentedControl`；filter card（scope + ledger 双 segment）；item tile check ring/ledger badge/drag glyph；empty-state 暖卡 | 48 | 无（复用既有 `ShoppingFilter.ledgerType` 客户端过滤） | **+1** `shoppingSectionToBuy`（ja/zh/en）+ gen-l10n |

四屏均：`context.palette` 全覆盖（133 处新增 palette 引用，0 处裸 `Color(0x..)`/`Colors.<name>`），金额 `AppTextStyles.amount*`，文案 `S.of(context)`。禁改的 `app_palette`/`app_theme`/`app_text_styles` 与 shell chrome 均未触碰。

## 验证（代码层 4/5 must-have，机器可验部分全绿）

- 全量 `flutter analyze` → **No issues found!**
- 全量 `flutter test` → **+3733 ~11: All tests passed!**（0 失败；含架构闸 color_literal_scan / hardcoded_cjk_ui_scan / theme_dark_mode_coverage）。
- verifier goal-backward：无硬编码色 ✓、数据接线保留（无 `lib/data`/repository/DAO/table 改动，唯一 additive 变更为 shopping 的 1 个 ARB key）✓、四屏文件不重叠 ✓、浅+深 golden 均重基线 ✓。
- 第 5 项「视觉与 mockup A1/A3 完全一致」**非机器可验** → `status: human_needed`，待设备端 UAT（浅+深逐屏比对 v15 mockup）。

## 待人工 UAT 权衡的保真取舍（executor 主动标注，多因零新增 ARB 约束）

- **home:** metrics 区保留现有三环 painter（未重建为 mockup 的 goal-ring/满足度 scale/小確幸）；family-invite 仅改色未改横向结构；hero 金额沿用 tabular（AppTextStyles 硬约束）；ときめき度 inline「今月の分析を見る›」链接省略。
- **list:** クリア 带标签、sort pill 分离方向箭头、日历 summary 沿用「今月の支出」（均为零新增 ARB）。
- **analytics:** trend card 顶部 insight 摘要条延后（需带占位符的新 ARB + 环比计算）。
- **shopping:** tile meta 显示估价而非「分类·数量」；drag 图标仅出现在正常模式活动行；scope 文案沿用 すべて。

> 若 UAT 判定 home metrics 区 / family-invite 结构 / 各 insight 摘要条为必须，可作为后续 quick 任务补做（多数需新增 ARB，故未在本轮零-ARB 约束内实现）。

## 未做

- 设备端浅色(A1)+深色(A3)四页面逐屏 UAT（本任务不含 device run）。
- shell chrome（底部浮动 pill 导航 + 中央 FAB）——四 tab 共享，明确排除在本轮范围外。
- 本任务未 push（GSD-quick inline 契约；提交停留在本地 `main`）。

---

## Round 2 — 完全按 mockup 实现（2026-07-14）

用户后续要求：「包括 home 在内，完全按 mockup 实现；不能实现的停下来提问。」放开 round-1 的「零新 ARB / 不重建」约束。

### 流程
4 屏并行 gap 分析（read-only，逐项分类 IMPL vs BLOCK）→ 批量 4 问决策（AskUserQuestion ×2 轮）→ 4 个全保真 executor（顺序 main tree）→ orchestrator 全量 analyze+test 门（修 2 处跨切漂移）。

### 用户锁定决策
- **功能取舍（逐项）：** 保留 满足度表情脸 / 成员归属 chip / 多态空态 / 周起始日设置；**移除** 统计多时间窗 → 月-only。
- **数据层：** ✅ 月历数字按账本过滤（改 `getDailyTotals` + 覆盖 D-06）；✗ 购物数量单位字段（不加 schema）。
- **满足度底部文案：** 保留中性事实（守 ADR-012），仅对齐「まんなか」措辞。
- **头部（明细/统计）：** 严格按 mockup —— 月份选择器 + 设置齿轮，去上/下月箭头。
- **全局文案：** 对齐 mockup 措辞（総支出 / カテゴリ別 / 全員 / 少·多 / ときめき支出·カレンダー·満足度 / 完了 / すべて削除 / 全部·個人 等）。

### 各屏 round-2 交付
| 屏 | Commit | 关键改动 | Golden(浅+深) |
|---|---|---|---|
| home | `55bb7687` | metrics 区重建 goal-ring+満足度 scale+小確幸 count（group 无家庭 joy 目标 → medianSatisfaction 环，不臆造）；family-invite 横向重构 + dismiss + 設定›家庭 path；今月の分析を見る link | 10 |
| list | `9764ec24` | 头部月份选择器+齿轮（去箭头）；**getDailyTotals +optional ledgerType、D-06 REVISED**、月历随账本过滤；合并 sort pill（方向进菜单）；CJK 日期头 yyyy年M月d日；icon-only clear；保留满足度脸/成员 chip/多态空态 | 32 |
| analytics | `0b038694` | 月-only 时间窗（删 TimeWindowChip/picker）；trend insight strip；可折叠 joy drawer；日历 summary + day-panel head；删冗余 donut caption；中性满足度文案（まんなか）；registry+GUARD-01 保持 | 26 |
| shopping | `25fc68a4` | tile meta = category(resolveFromId)·数量(裸数字)；inline 筛选空态；全部·個人 scope（消 私有 重复）；完了·すべて削除；完成行装饰 drag glyph | 24 |

### Orchestrator 全量门（两处跨切漂移，均已修）
1. **golden 漂移 8 张** → 重基线 `c1f98229`：category_drill_down ×4（list slash-date 传导到只读 tile 镜像）、family_insight_data_card ×2（家族ときめき 文案）、joy_spend_card ×2（drawer 默认折叠）。均预期视觉变更，非逻辑回归。
2. **arb_key_parity 失败** → `ea1a627c`：analytics 11 个占位符 key 的 @-metadata 仅加到 en 模板，镜像到 ja/zh（值零改动）。

> 二者都只有 orchestrator 的全量 `flutter test` 门能抓（executor scoped 门看不到跨屏 golden / 全局 ARB 一致性）——沿用「per-wave 门必须跑 FULL test」的既有教训。

### 最终门（全绿）
- `flutter analyze` → **No issues found!**
- 全量 `flutter test` → **+3712 ~11 All tests passed!**（0 fail；含 color_literal_scan / hardcoded_cjk_ui_scan / theme_dark_mode_coverage / arb_key_parity）。

### 仍待 / 轻量清理
- **设备端 UAT（human_needed）：** 浅(A1)+深(A3)四屏逐屏对比 mockup。
- 剩余小取舍：hero 金额保留 tabular（AppTextStyles 硬约束，mockup 金额本身也是 sans）；日历日格 compact 沿用「万」惯例；shopping 数量裸数字；满足度中性文案。
- `happiness_rings_painter.dart` 现无引用（未删，越范围，可后续清理）。
- round-2 仍未 push（GSD-quick 契约）。
