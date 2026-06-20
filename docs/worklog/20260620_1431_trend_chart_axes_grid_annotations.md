# 支出趋势图表增加坐标轴/网格/上月对比线/起止点标注

**日期:** 2026-06-20
**时间:** 14:31
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** [MOD-007] Analytics（统计页面 · 支出趋势卡片）

---

## 任务概述

统计页（图表 tab）的「支出趋势」单月累计折线图原本是一条裸的彩色对角线（刻意的
"the line is the signal" 设计，无坐标轴/网格/标注）。本任务按用户提供的参考截图把它
升级为更易读的呈现：左侧金额刻度 + 横向网格（从 0 起）、底部本地化日期刻度、清晰可见的
灰色虚线「上月」参考线（仅支出侧）、以及「本月」线首尾点的日期+金额标注。三个 tab
（总支出/日常/悦己）统一应用，悦己侧仍保持单线无上月（ADR-012 / D-E1 结构性保证）。

---

## 完成的工作

### 1. 主要变更

- `lib/features/analytics/presentation/widgets/within_month_cumulative_line_chart.dart`
  - `FlGridData(show:true, drawVerticalLine:false)` 横向网格，"nice" 整步长
    （1/2/5×10ⁿ，约 4 条线），`minY` 保持 0（绝不出现负刻度）。
  - 左轴 `SideTitles`：`NumberFormatter.formatCompact`（ja/zh `1万`、en `10K`）。
  - 底轴 `SideTitles`：`interval:7`，标签走新增的
    `DateFormatter.formatDayOfMonthAxis`（ja/zh `7日`、en `7`）。
  - 上月线改用显式中性灰 `palette.textTertiary`（原为淡 lerp），`barWidth` 1.5→2，
    保持虚线、仅支出侧（`_hasReference` 门控）。
  - 本月线首尾点 `FlDotData.checkToShowDot` 端点圆点 + `Stack` 叠加两个
    `_EndpointAnnotation`（日期 `formatShortMonthDay` + 金额 `formatCurrency JPY`，
    `AppTextStyles.amountSmall` tabular figures，系列色）。
  - 新增必填 `anchor` `DateTime` 参数用于构造标注日期；图高 220→244；
    locale 经 `Localizations.localeOf(context)` 获取（未引入 WidgetRef）。
- `lib/.../cards/within_month_trend_card.dart`：把 `ctx.trendAnchor` 透传给
  `_TrendBody`→图表；legend 灰色色块改 `palette.textTertiary`（legend == line）。
  悦己分支仍 `previous = null`（D-E1 不变）。
- `lib/infrastructure/i18n/formatters/date_formatter.dart`：新增
  `formatDayOfMonthAxis`（`日` 词缀留在白名单 formatter 内，图表保持无字面量，
  hardcoded-CJK 扫描绿）。
- 图表单测 5→9（网格仅横向 / 左下轴开 + 上右轴关 / minY 0 / 端点圆点仅首尾）。
- 重生成 8 个受影响 macOS golden master（7 trend-card + analytics scroll smoke）。

### 2. 技术决策

- Y 轴标签用 `formatCompact` 而非 `formatCurrency`，在 44px 保留宽下更不拥挤。
- 标注用 `FlDotData` + `Stack` 叠加，而非 fl_chart 内建 tooltip，避免在卡片高度下溢出。
- `日` 词缀走 whitelisted DateFormatter，而非新增 ARB key——零新增 ARB key。

### 3. 代码变更统计

- 修改文件：4 个源/测试 + 8 个 golden PNG = 12。
- 2 次原子提交：`ec4d43e2`（代码+单测）、`c005e531`（golden）。

---

## 遇到的问题与解决方案

### 问题 1: `日` 轴词缀可能触发 hardcoded-CJK-UI 架构扫描
**症状:** 图表内任何含 CJK 的字符串字面量会被 `hardcoded_cjk_ui_scan_test` 命中。
**原因:** 扫描对所有非白名单 lib UI 文件的字符串字面量做 CJK 检测。
**解决方案:** 在已白名单的 `date_formatter.dart` 新增 `formatDayOfMonthAxis`，
图表只调用 formatter，自身保持无 CJK 字面量。全套测试绿。

---

## 测试验证

- [x] 单元测试通过（图表 9 + 卡片 5）
- [x] `flutter analyze` == 0 issues（全项目）
- [x] 全量 `flutter test` 通过 **3061/3061**（含 anti-toxicity + hardcoded-CJK 扫描）
- [x] golden ja/en value master + empty master 目视确认（坐标轴/网格/灰虚线上月/
      端点标注，无裁切；空态稳定占位不抛异常）
- [x] 代码审查（immutable、小部件、零硬编码 hex、零硬编码 UI 字符串）

---

## Git 提交记录

```bash
ec4d43e2  feat: add axes, grid, gray 上月 line, endpoint annotations to within-month trend chart
c005e531  test: re-baseline trend-card + analytics-smoke goldens for chart axes/grid/annotations
```

---

## 后续工作

- 无。文档侧（SUMMARY/STATE）提交由 orchestrator 负责。

---

## 参考资源

- `.planning/quick/260620-jx2-trend-chart-axes/260620-jx2-PLAN.md`
- `.planning/quick/260620-jx2-trend-chart-axes/260620-jx2-CONTEXT.md`
- `docs/arch/03-adr/ADR-019_Palette_Selection_v1_6.md`（palette tokens）
- ADR-012（悦己 tab 无跨期参考线，本任务保留）

---

**创建时间:** 2026-06-20 14:31
**作者:** Claude Opus 4.8 (1M context)
