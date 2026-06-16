# GATE-04 (c) — fl_chart 1.2.0 逐图 Affordance 校验（选定方向）

**Phase:** 43-html-design-gate-no-production-code
**写于:** 2026-06-16
**Scope:** GATE-03 选定方向 round-5 B（M2 衍生）的全部图表
**性质:** 设计门决策记录。**无生产代码**。把选定方向的每张图 affordance 逐项映射回 `fl_chart 1.2.0` API（RESEARCH §3a），标 ✅ 原生 / ❌ 非原生；任何 ❌ 选定方向需要的 → **flag 为 Phase 46 风险**。
**版本基准:** `fl_chart 1.2.0`（`pubspec.lock` 实测，**无 2.x**）。`BarChartRodData.label` + `PieChartSectionData.cornerRadius` 已发布。

---

## 1. 选定方向图表清单

round-5 B 用到的可视化（来自 `selected/selected-light.html` / `selected-dark.html` / `README.md`）：

1. 支出分类 **donut**（hero，中心「本月支出 ¥248,600」）
2. 满足度 **histogram**（1–10 频次分布 + 中位）
3. 支出趋势 **累计折线**（总支出 / 日常 tab：本月 + 上月，多系列）
4. 悦己 **单线趋势**（悦己 tab：本月单月单线，无上月/无跨期）
5. **悦己横向堆叠分段条**（悦己 ¥47,200 在 6 个分类间构成）
6. **小确幸日历热力**（本月每天是否有悦己一刻，色深=当天笔数）

---

## 2. 逐图 Affordance 校验表

| # | 图表 | fl_chart 类型 | 关键 affordance | 1.2.0 原生？ | 映射回 RESEARCH §3a | 结论 |
|---|---|---|---|---|---|---|
| 1 | **支出分类 donut** | `PieChart` | 环形 + section 圆角 `PieChartSectionData.cornerRadius`；中心 hole 文本；触摸 tooltip `PieTouchData` | ✅ 原生 | donut 圆角原生（1.2.0 新增）；`PieTouchData` 已用 | ✅ **可行** |
| 2 | **满足度 histogram** | `BarChart` | 柱顶 per-rod 数值标签 `BarChartRodData.label`；中位参考 | ✅ 原生 | **§3a：柱顶 per-rod 标签 1.2.0 原生 → 可删 `satisfaction_distribution_histogram.dart` 第 35–139 行的 `Stack`+`Align`+`DecoratedBox` hack** | ✅ **可行（且移除 Stack hack）** |
| 3 | **支出趋势 累计折线（本月+上月）** | `LineChart`（多系列） | 两条 `LineChartBarData`（本月 / 上月），同尺度参照；隐藏多余网格 | ✅ 原生 | `LineChart` 多系列原生支持 | ✅ **可行** |
| 4 | **悦己 单线趋势** | `LineChart`（单系列） | 单条 `LineChartBarData`（本月单月，无上月线/无跨期） | ✅ 原生 | LineChart sparkline（隐藏轴/网格/点）§3a 可行 | ✅ **可行** |
| 5 | **悦己横向堆叠分段条** | `BarChart`（**横向 + stacked**） | **横向**单条多段堆叠（largest→smallest），单列图例 | ⚠️ **半原生** | **§3a 无"横向 stacked"专列：fl_chart `BarChart` 默认竖直；stacked rod 用 `BarChartRodStackItem` 原生，但"横向"需 rotation/坐标互换或自定义** | ⚠️ **flag Phase 46 风险（见 §3）** |
| 6 | **小确幸日历热力** | **非 fl_chart 类型** | 月历网格，每格色深 = 当天笔数 | ❌ **非原生** | **§3a 无日历热力类型 → 须自定义 `GridView`/`Wrap` + 色深映射，非 fl_chart** | ❌ **flag Phase 46 风险（见 §3）** |
| — | **Sankey 流向图** | — | （选定方向**未使用**） | ❌ 无 native 支持 | §3a：Sankey ❌ 无 native 支持；OUT OF SCOPE（ANALYTICS-V2-01） | ❌ **排除（选定方向未用，记录在案）** |

---

## 3. ❌ / ⚠️ 项 — Phase 46 风险 flag

选定方向需要而 fl_chart 1.2.0 **非纯原生**的 affordance，须在 **Phase 46（卡片实施）**前预案，避免撞库返工（Pitfall 3：fidelity vs scope creep）：

### 风险 R-1 — 悦己横向堆叠分段条（#5，⚠️ 半原生）
- **问题:** fl_chart `BarChart` 默认竖直；堆叠段（`BarChartRodStackItem`）原生，但「**横向**单条堆叠」需要坐标互换 / rotation，非一行配置。
- **Phase 46 预案（任选其一）:**
  1. **自定义 `Row` + `Flexible(flex)` 分段**（纯 Flutter，不走 fl_chart）—— 横向单条堆叠用 weighted `Row` 最直接，且 ADR-019 配色可控、无图表库约束。**推荐**（HTML mock 本就是 CSS flex 分段，落地等价）。
  2. 竖直 `BarChart` + 单 group 多 `BarChartRodStackItem`，再整体 `RotatedBox(quarterTurns)` 转横 —— 可行但标签/触摸方向需额外处理。
- **风险等级:** 低（方案 1 无依赖、与 mock 等价）。

### 风险 R-2 — 小确幸日历热力（#6，❌ 非原生）
- **问题:** 日历热力**不是** fl_chart 图表类型，无任何 native 支持。
- **Phase 46 预案:** 自定义 **`GridView`/`Wrap`** 月历网格（7 列 × N 行），每格 `Container` 色深 = `f(当天悦己笔数)`（ambient `f(count)→color`，ADR-012-safe，非 streak）。纯 Flutter，无图表库。
- **风险等级:** 低（标准 GridView，无库依赖；色深映射是连续函数，符合 ADR-016 §5 ambient）。

### Sankey — 排除（记录在案）
- 选定方向**未使用** Sankey。fl_chart 1.2.0 ❌ 无 native 支持，且 milestone 级 OUT OF SCOPE（ANALYTICS-V2-01）。无 Phase 46 动作。

---

## 4. 汇总

| 图表 | 1.2.0 原生 | Phase 46 风险 |
|---|---|---|
| 支出分类 donut | ✅ | — |
| 满足度 histogram | ✅（移除 Stack hack） | — |
| 支出趋势累计折线（本月+上月） | ✅ | — |
| 悦己单线趋势 | ✅ | — |
| 悦己横向堆叠分段条 | ⚠️ 半原生 | **R-1**（推荐自定义 `Row` flex 分段，非 fl_chart） |
| 小确幸日历热力 | ❌ 非原生 | **R-2**（自定义 `GridView` 色深网格，非 fl_chart） |
| Sankey | ❌（未使用） | 排除（OUT OF SCOPE） |

**判定:** 选定方向的 6 张图中 4 张 fl_chart 1.2.0 原生可行（其中满足度直方图额外受益于移除 Stack hack）；2 张（悦己横向堆叠条、小确幸日历热力）**非 fl_chart 原生**，已 flag 为 Phase 46 风险并给出纯 Flutter 自定义预案（均低风险、无新依赖、ADR-012-safe）。**无任何图表需要升级 fl_chart 或换库。**

---

**示例数据声明:** 本门无真实数据；校验对象为选定设计的图表 affordance。
