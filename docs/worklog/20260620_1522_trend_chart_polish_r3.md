# 支出趋势图表 round-3 视觉打磨

**日期:** 2026-06-20
**时间:** 15:22
**任务类型:** 功能开发（UI 打磨）
**状态:** 已完成
**相关模块:** MOD-007 Analytics — 支出趋势 within-month 累计趋势图

---

## 任务概述

承接 quick 任务 260620-jx2（坐标轴/网格/上月线/标注）与 260620-kll（X轴整月 /
本月线到今日 / 上月线整月 / 终点锚定标注）。用户在真机复审后给出 5 条视觉打磨意见，
本轮全部实现。改动集中在单文件 `within_month_cumulative_line_chart.dart`（+ 其
widget 测试 + 8 个 golden 重基线），因体量小未走 GSD 子代理流水线，直接 inline 修改
并跑全量门禁。

---

## 完成的工作

### 1. 主要变更（5 条用户意见）

1. **「数字写到点上了」→ 标注自动翻转避免压线。** 端点靠近图顶/图底时，原先
   `above` 放置会被 clamp 到边界压在数据点上。`_positionedLabel` 改为：优先按对比
   规则（本月≥上月→上方）放置，若该侧会溢出卡片则**翻转到另一侧**，标注永不落在线/点上。
   widget 的 `above` 仍记录对比决策（Test 13 不受影响）。
2. **去掉右侧 28日/30日。** 底轴不再渲染贴近月末的刻度。
3. **X轴按 6/12/18/24 显示。** `bottomTitles.interval` 7→6；新增纯函数
   `showDayAxisLabel(day, daysInMonth) = day>=6 && day%6==0 && day<=daysInMonth-6`
   过滤 fl_chart 的 min/max 边缘标签与近月末刻度。
4. **整体高度降低。** 图表默认 `height` 244→200。
5. **金额字体调小。** 终点标注金额 `fontSize` 12→10；标注盒 `_labelW/_labelH`
   86/34→80/30、`_labelNudge` 28→14 同步收紧。

### 2. 技术决策

- **inline 而非 GSD 流水线：** 单文件视觉微调，按个人规则「小代码任务上 GSD 开销>收益」，
  直接改 + 全量门禁验证，避免 planner/executor/verifier 的 token 与时间开销。
- **自动翻转 vs 抬高 Y 轴留白：** 用户同时要求降低高度，若靠加大 Y 轴 headroom 给上方
  留空间会与「降低高度」冲突，故选自动翻转——既不压线又不浪费纵向空间。
- **过滤逻辑提取为纯静态函数** 以便单测锁定 6/12/18/24 行为（fl_chart 0-anchored
  interval 倍数 + 边缘标签，靠 `showDayAxisLabel` 收敛）。

### 3. 代码变更统计

- 修改文件：`lib/features/analytics/presentation/widgets/within_month_cumulative_line_chart.dart`
- 测试：`test/widget/.../within_month_cumulative_line_chart_test.dart`（+1 用例 13b）
- Golden：8 个 master 重基线（trend-card light/dark × ja/zh/en + empty_light_ja +
  analytics_screen_scroll_smoke_light_ja）

---

## 测试验证

- [x] chart widget 单测 14/14 通过（含新增 13b）
- [x] `flutter analyze` 0 issues
- [x] 全量 `flutter test` 3072/3072 通过
- [x] golden 在 macOS 重基线，ja master 目视确认（4 个底轴刻度、标注不压线、更紧凑、字体更小）
- [ ] 设备端最终视觉确认（待用户）

---

## 后续工作

- [ ] 用户真机复看：标注翻转后的位置、6/12/18/24 轴、整体高度与字体是否满意。

---

## 参考资源

- 前序：`.planning/quick/260620-jx2-trend-chart-axes/`、`.planning/quick/260620-kll-trend-chart-fix/`
- 调色板：ADR-019；悦己跨月约束：ADR-012/D-E1（本轮未触及）

---

**创建时间:** 2026-06-20 15:22
**作者:** Claude Opus 4.8
