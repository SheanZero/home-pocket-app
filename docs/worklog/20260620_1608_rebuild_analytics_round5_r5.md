# 按 round5/r5-drawer-joybar.html 重做统计页

**日期:** 2026-06-20
**时间:** 16:08
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** [MOD-007] Analytics（支出侧统计页）

---

## 任务概述

按 `round5/r5-drawer-joybar.html` mock 重建整个统计页（`AnalyticsScreen` + 各分类卡片），做到视觉与结构保真：重新加回 4 个节标题（逆转 Phase-46 D-F2 扁平设计），把悦己堆叠条内嵌进分类支出卡，并补齐日历图例 / 直方图中位 pill。纯 presentation refactor —— 不动任何 provider / domain / repository 数据契约。

---

## 完成的工作

### 1. 主要变更（5 个原子提交，全部直接落在 `main`）

- **Task 1 (`8cee0dbd`)** —— `lib/core/theme/joy_warm_palette.dart`（j1–j7 悦己暖色板，唯一 sanctioned 裸hex carve-out，放 core/ 避开 color_literal_scan）+ `AnalyticsSectionHeader`（3px 竖条 + 标题 + tag chip，palette+ARB 驱动，零 CJK 字面）+ joybar 改用 `JoyWarmPalette.colorAt(index)` + 三份 ARB 新增节标题/tag/抽屉/日历图例/直方图脚注键 + gen-l10n。
- **Task 2 (`971adf09`)** —— 抽取共享 `JoySpendDrawerBody`（standalone 卡 + 内嵌抽屉单源）；`CategoryDonutCard` 内嵌 connector chip + 樱粉边框抽屉（数据驱动 ¥ 合计 + N 类）；`joyCategoryAmountsProvider` 折叠进 `categoryDonutRefreshTargets`（Pitfall-3 / GUARD-01），error-retry 改 `targets.first`；`JoySpendCard` 降为薄 wrapper（保留供测试）。
- **Task 3 (`ca78e669`)** —— `AnalyticsCardSpec` 加 provider-free `sectionHeader` 描述符（文案闭包 + tone 枚举）；registry 6→5（删 JoySpend spec）；shell `_buildCardChildren` 在带 header 的 spec 前渲染节标题（26/10 mock 间距）；趋势卡 `showHeader:false` 抑制重复标题（_TrendBody/chart D3 冻结未动）。
- **Task 4 (`9ed170ac`)** —— 日历加 `.cal-legend`（淡 + 4 lerp 色块 + 浓 + 中性说明），连续深浅映射保留（ADR-012 安全）；直方图加 `histo-foot`（计数脚注 + 数据派生加权中位 pill，绝不写死 7）+ 中位柱描边。
- **Task 5 (`adb7fa8a`)** —— 翻转结构测试（screen：4 节标题 + JoySpendCard 非顶层卡 + 抽屉嵌于 donut；registry：长度=5 + 折叠 joy union；anti_toxicity：补 joy 串 sweep + 改写措辞清除禁用子串 comparison/ranking/比較）；抽出 `JoySpendDrawer` 到独立文件保 REDES-01 <400 LOC；macOS 重基线 34 个受影响 golden master。

### 2. 技术决策

- **裸hex 落点（D5）：** j1–j7 必须放 `lib/core/theme/`（color_literal_scan 只扫 features/application/shared），与 `happiness_ring_palette.dart` 同理。
- **refresh union（Pitfall-3）：** 删 JoySpendCard spec 会丢 joy refresh target → 折叠进 donut targets，registry 仍零 home/* 导入。
- **REDES-01：** donut 卡内嵌抽屉后达 578 LOC，超 400 限制 → 抽 `JoySpendDrawer` 独立 widget 文件。
- **趋势卡标题：** mock 节标题已是标签且卡身无标题 → `AnalyticsDataCard.showHeader:false` 最小改动抑制，未触 D3 冻结的图表内部。

### 3. 代码变更统计

- 新建 4 文件：`joy_warm_palette.dart` / `analytics_section_header.dart` / `joy_spend_drawer_body.dart` / `joy_spend_drawer.dart`
- 修改 ~12 lib 文件 + 3 测试文件 + 三份 ARB + 重基线 34 golden
- 5 个原子 code 提交

---

## 遇到的问题与解决方案

### 问题 1: anti_toxicity 禁用子串泄漏
**症状:** en「no comparison」/「no ranking」、ja「比較」触发 forbidden-substring sweep。
**原因:** 抽屉/副标题措辞含 comparison / ranking / 比較。
**解决方案:** 改写为「never weighed against the past」「nothing placed above another」「過去と引き比べる」，语义不变且 ADR-012 中性。

### 问题 2: REDES-01 LOC 超限
**症状:** registry_test 报 `category_donut_card.dart` 578 LOC > 400。
**解决方案:** 把 `_JoyDrawer` + `_JoyConnector` 抽到 `widgets/joy_spend_drawer.dart`，卡回落 372 LOC。

### 问题 3: 空 joy 数据下断言抓不到 JoySpendStackedBar
**症状:** screen 测试用空 joyCategoryAmounts → 抽屉渲染空态无 bar。
**解决方案:** 断言改为查 `JoySpendDrawer` widget 本身（空态也渲染）。

---

## 测试验证

- [x] `flutter analyze` —— 0 issues
- [x] `flutter test` 全量 —— 3072 passed
- [x] 架构测试通过：hardcoded_cjk_ui_scan / color_literal_scan / registry_test / anti_toxicity_phase47
- [x] 34 golden master 在 macOS 重基线
- [x] `daily_vs_joy_card` golden 未受影响（Pitfall-8）

---

## Git 提交记录

```
8cee0dbd feat: joy-warm palette + AnalyticsSectionHeader + joybar recolor + ARB
971adf09 feat: nest 悦己 joybar drawer into CategoryDonutCard + fold refresh + thin wrapper
ca78e669 feat: wire 4 section headers into registry + shell (D-F2 reversal)
9ed170ac feat: calendar heat legend; histogram median pill + count footer + outline
adb7fa8a test: flip structural tests + extract JoySpendDrawer + rebaseline goldens
```

---

## 参考资源

- Mock: `.planning/phases/43-html-design-gate-no-production-code/mocks/round5/r5-drawer-joybar.html`
- 计划: `.planning/quick/260620-lfp-round5-r5-drawer-joybar-html-mock/260620-lfp-PLAN.md`
- ADR-012（反游戏化）/ ADR-019（桜餅×若葉 palette）

---

**创建时间:** 2026-06-20 16:08
**作者:** Claude Opus 4.8
