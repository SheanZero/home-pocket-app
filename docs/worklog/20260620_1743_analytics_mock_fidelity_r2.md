# 统计页 分类支出卡 + 小确幸日历卡 像素级对齐 mock（260620-lfp R2）

**日期:** 2026-06-20
**时间:** 17:43
**任务类型:** Bug修复 / UI 保真
**状态:** 已完成
**相关模块:** MOD-007 Analytics

---

## 任务概述

quick 260620-lfp 整页重建后，用户在设备上发现「分类支出卡」与「小确幸日历卡」与 mock
`round5/r5-drawer-joybar.html`「差距太大」。根因：第一轮计划是**结构性**的（嵌套/节标题/调色板引入），
未规定**每卡像素级内部版式**；且 golden 是从实现重基线的，**无法**校验「是否对得上 mock」（只锁住了渲染结果）。
本轮按 mock 逐条像素对齐这两张卡，去掉卡内标题，颜色/字号/布局严格照 mock，不自我发挥。

---

## 完成的工作

### 1. 新增 `lib/core/theme/analytics_category_palette.dart`
mock 专属离散配色（裸 hex 仅允许 core/theme，过 `color_literal_scan`）：
- survivalSequence 绿/蓝系 5 色（环上生存系分类按金额降序轮转）
- joy 樱粉 `#D98CA0`（悦己系分类，账本暗示）
- other 藕灰 `#C4B6AD`（长尾「其他」）
- heat[0..3] 日历热力 4 档离散色

### 2. 分类支出卡（`category_donut_card.dart` + 新 `widgets/donut_hero.dart`）
- `AnalyticsDataCard(showHeader:false)` —— **去掉卡内「分类支出」标题**（外层 section header 已标注）。
- 顶部 hero-top：「这个月，钱花在哪」(13/w700) + 「N 笔 · M 月」pill（dailyLight 底 / dailyText / 圆角7）。
- 环配色：**弃 daily→joy 渐变 lerp**，改按分类离散——`joyCategoryAmountsProvider` 给的 L1 joy id 集合→樱粉；
  其余生存系按降序取 survivalSequence；长尾→藕灰。**环弧色 = 图例 dot 色**。
- 环几何：细环大孔（radius 22 / centerSpaceRadius 62 / sectionsSpace 0 / cornerRadius 0）。
- 环中心 3 行：本月支出 / ¥总额(28/w800 count-up) / **「N 笔」**（新增第三行）。
- 图例行：圆形 dot→**圆角方块 11×11 r4**、行间 1px 分隔线、**去掉 chevron**（行仍可点 drill）。
- 因新增内容超 REDES-01 400 LOC 闸 → 把 `DonutHero`/`LegendRow` 抽到 `widgets/donut_hero.dart`（逐字等价，卡 158 LOC）。

### 3. 小确幸日历卡（`joy_calendar_card.dart` + `joy_calendar_heatmap.dart`）
- `AnalyticsDataCard(showHeader:false)` —— 去掉卡内「小确幸·日历」标题。
- 顶部加**星期表头**「一二三四五六日」（周一起，10/w700/tertiary）。
- 网格：**正方格**（aspectRatio 1，原 1.3）、gap 6（原 4）、圆角 8（原 6）；leading 空白用透明 `SizedBox.expand()`（原 `shrink` 会塌陷错位）。
- 日号：**右上角**（原居中），8.5/w700；色随档位 0→tertiary / 1→joyText / ≥2→白。
- 热力：**离散 heat0–3**（原连续 lerp）；图例 4 色块同步改离散。
- 底部加 cal-cap「这个月有 N 天，为自己留下了一点小确幸 · 只看「哪些天发生过」」（原信息在被删的卡 caption 里）。

### 4. i18n
新增 11 个 ARB key（ja/zh/en 三份 + `flutter gen-l10n`）：hero-cap / hero-tag / center-count / cal-cap / 周一..周日。
全走 `S.of(context)`，过 `hardcoded_cjk_ui_scan`；cal-cap 已去掉 mock 原文「不数连续、不比多少」触发词，过 `anti_toxicity_phase47`。

---

## 遇到的问题与解决方案

### 问题 1: GridView leading 空白格 ValueKey 冲突
**症状:** inline 展开态触发 sliver child-element 断言。
**原因:** 多个 leading 空白格共享同一 ValueKey。
**解决:** 改无 key 的 `SizedBox.expand()` 透明占位。

### 问题 2: REDES-01 <400 LOC 架构闸
**症状:** 加 hero-top/center/legend 后 `category_donut_card.dart` 达 487 LOC。
**解决:** 抽 `DonutHero`/`LegendRow` 到 `widgets/donut_hero.dart`（cards/ 外，无 home/ 依赖），卡降至 158 LOC。

---

## 测试验证

- [x] `flutter analyze` → 0 issues（orchestrator 复跑确认）
- [x] `flutter test`（全量）→ 3072/3072（color_literal_scan / hardcoded_cjk_ui_scan / anti_toxicity_phase47 / arb_key_parity / donut+calendar widget 测试全绿）
- [x] 17 个 golden master macOS 重基线（donut 9 + calendar 7 + scroll-smoke 1），零删除
- [x] orchestrator 代码层复核 `donut_hero.dart` / `joy_calendar_heatmap.dart` 逐条对齐 spec
- [ ] **设备端视觉待用户最终确认**（golden 只锁渲染结果、无法校验"对不对得上 mock"，需人眼）

---

## Git 提交记录

```
53928fbc feat: analytics category palette + 11 round5-r5 ARB keys
774c2133 feat(analytics): pixel-align category donut card to round5-r5 mock
9640001f feat(analytics): pixel-align joy calendar card to round5-r5 mock
```

---

## 后续工作 / 保守保留（未在 spec 覆盖，按"勿发挥"保留现状）

- mock `.hero` 外层 radial-gradient 光晕 / shadowHero（spec 未给值）→ 保留标准 Card 外壳
- mock 环底灰圈 `#F1ECE8`（spec 标非必须）→ 未画
- joy-connector chip + 悦己抽屉（本轮范围外，第一轮已实现，未动）
- inline 日面板 tile 样式（非 mock 元素）
- 趋势图卡 / 满足度直方图卡：本轮零改动

---

**创建时间:** 2026-06-20 17:43
**作者:** Claude Opus 4.8
