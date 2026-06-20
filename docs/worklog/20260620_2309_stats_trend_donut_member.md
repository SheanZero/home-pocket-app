# 统计页趋势图柔化/渐变/终点标签 + 圆环环上% + 成员维度/过滤

**日期:** 2026-06-20
**时间:** 23:09
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** [MOD-007] Analytics

---

## 任务概述

统计页两块改进：Part 1 把支出趋势折线柔化为曲线、加 below-line 渐变阴影、终点 date+amount 标签固定在终点 marker 正上方；Part 2 给分类圆环新增环上 % 标签（D3）、「分类/成员」维度切换、成员过滤下拉与成员切分渲染。全部用 ADR-019 自有配色与 i18n。quick 任务 260620-v2m，5 个任务原子提交。

---

## 完成的工作

### 1. 主要变更

- **Task1（趋势图，commit 80c1d987）**：`within_month_cumulative_line_chart.dart` 本月线 `isCurved:true`+`curveSmoothness:0.22`+`preventCurveOverShooting`，below-line `LinearGradient`（seriesColor α0.18→0）；终点标签强制锚定正上方，上月相反侧。
- **Task2（数据层 TDD，commit efdd2ec8）**：`MemberSpendBreakdown` 值模型 + `GetMemberSpendBreakdownUseCase`（findByBookIds 两账本 → expense + group-by deviceId）+ `memberSpendBreakdownProvider`/use-case provider。6 单测全绿。
- **Task3（状态层 TDD，commit f8b1f722）**：`DonutDimension` enum + `DonutDimensionState` Notifier（dimension+memberFilterDeviceId，全局收窄跨维度保留）。5 单测全绿。
- **Task4（UI，commit 0f18252a）**：donut_hero 环上 `<pct>%`（<5%/「其他」避让）+ 成员维度分支；`DonutDimensionMemberControls` 控件；`AnalyticsCategoryPalette.memberSequence/memberColorFor` 稳定成员色；`memberFilteredCategoryBreakdownProvider`（分类模式+过滤重算）；3 套 ARB 新 key+gen-l10n。
- **Task5（golden，commit eb74b990）**：趋势卡/圆环卡 golden macOS 重基线 + 3 个成员维度新 master；控件 en 溢出修复。

### 2. 技术决策

- **跨维度成员过滤语义（明确记录）**：全局收窄，两维度都 genuinely functional——成员模式过滤→该成员单片；分类模式过滤→`memberFilteredCategoryBreakdownProvider` 按 deviceId 重算分类占比。未走「分类下置灰」省事分支，因过滤在两维度都有真实意义且增量仅一个轻量 provider。
- **环上 % 避让阈值 5%**：小切片+长尾「其他」仅图例不上环，防 8–10 类标签重叠。
- **成员色**：`deviceId.hashCode.abs() % memberSequence.length` 稳定哈希，避 error 红、留樱粉给悦己。

### 3. 代码变更统计

- 新建 4 production + 2 test 文件；改 7 production + 2 test + 3 ARB；21 golden PNG（含 3 新成员 master）。

---

## 遇到的问题与解决方案

### 问题 1: 控件行 en locale 溢出 90px
**症状:** golden 重基线时 en value 报 RenderFlex overflowed by 90px。
**原因:** 顶层 Row 子项自然宽度超卡宽（en 标签较长）。
**解决方案:** 维度 Wrap 包 Flexible+runSpacing；过滤触发器 Flexible+ConstrainedBox(maxWidth:150) 省略。

### 问题 2: 注册表测试 3 失败
**症状:** memberSpendBreakdownProvider 折入 categoryDonutRefreshTargets 触发白名单 + 单源 key 断言失败。
**原因:** 新 provider 不在测试 analytics 家族白名单；(e) 期望旧 2 元目标。
**解决方案:** 白名单加 MemberSpendBreakdownProvider（确属 analytics 家族、零 home/*）；(e) 期望补第 3 元。未放宽语义。

### 问题 3: 趋势图本月强制 above 后上月撞车
**症状:** Part1② 新测失败（本月<上月时两标签都 above）。
**解决方案:** 上月改 `!currentLabelAbove`（相对强制侧），本月恒 above→上月恒 below。

---

## 测试验证

- [x] 单元测试通过（Task2 6/6、Task3 5/5）
- [x] full flutter test 3088/3088 全绿（含 anti_toxicity/cjk-scan/provider_graph_hygiene/home_isolation 架构测试）
- [x] flutter analyze 0 issues
- [x] analytics golden macOS 重基线
- [x] 代码审查（自审）完成

---

## Git 提交记录

```
80c1d987 feat: 趋势折线柔化曲线+below-line渐变+终点标签正上方 (Task1)
efdd2ec8 feat: 成员支出聚合 use case + 模型 + provider (Task2, TDD)
f8b1f722 feat: 圆环维度(分类/成员)+成员过滤 状态 Notifier (Task3, TDD)
0f18252a feat: 圆环环上%标签(D3)+成员维度/过滤+成员切分渲染+控件+稳定成员色+i18n (Task4)
eb74b990 test: analytics golden 重基线+控件溢出修复 (Task5)
```

---

## 后续工作

- 设备端视觉确认（趋势曲线/渐变/终点标签位置、环上 %、成员切换/过滤）待用户真机验收。

---

## 参考资源

- 计划/上下文: `.planning/quick/260620-v2m-stats-trend-donut-member/`
- 配色: ADR-019 桜餅×若葉

---

**创建时间:** 2026-06-20 23:09
**作者:** Claude Opus 4.8
