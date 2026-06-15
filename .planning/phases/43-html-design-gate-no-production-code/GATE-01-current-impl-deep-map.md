# GATE-01 — 现状统计实现深研图（Current Analytics Implementation Deep-Map）

**Phase:** 43-html-design-gate-no-production-code
**写于:** 2026-06-15
**性质:** 决策/参照文档（无生产代码）。本图把 milestone 级 `.planning/research/ARCHITECTURE.md` 的 reuse 图落到 **widget 粒度**，作为 5 套 HTML mock（43-02 .. 43-06）共同的"重组种子"。
**种子来源:** `43-RESEARCH.md` §1（1a 17-widget 清单 / 1b MonthlyReport 已算字段 / 1c 结构锁点）+ `lib/features/analytics/presentation/widgets/` 实测目录。

> **一句话定位:** 统计页的所有视觉元素已由 17 个现成 widget 覆盖；实用侧数据已全部算好（零新增数据工作）；本里程碑的 5 套 mock 是**重新组织既有元素 + 探索悦己端表达**，不是绘制新图表类型。GATE-02 自审与 GATE-04 词表都以本图的"结构锁点"为对照基准。

---

## 17 现成 analytics widget 清单

来源：`lib/features/analytics/presentation/widgets/`（17 个文件全部实测存在，2026-06-15）。每个 widget 标注其角色与映射的 mock-side（实用 practical / 悦己 joy / 外壳 shell）。**这是 5 套 mock 重组的种子，不是从零重画。**

| Widget 文件 | LOC | 角色（mock 复刻参照） | mock-side |
|---|---|---|---|
| `total_spending_kpi_tile.dart` | 57 | 总支出 KPI tile（OVW 支出总览的核心数字） | 实用 |
| `category_spend_donut_chart.dart` | 148 | 分类支出环形图（donut）。GATE-04 可选 `cornerRadius` 校验对象 | 实用 |
| `monthly_spend_trend_bar_chart.dart` | 147 | 6 个月支出趋势柱状图（TREND） | 实用 |
| `per_category_breakdown_card.dart` | 260 | 分类 breakdown 列表（min-N=3 + Other rollup）。**已纳入 anti-toxicity 扫描** | 实用→悦己桥 |
| `kpi_mini_hero_strip.dart` | 47 | KPI mini-hero 横条（容纳多个 tile） | 外壳 |
| `time_window_chip.dart` | 99 | 时间窗 chip（外壳常驻） | 外壳 |
| `time_window_picker_sheet.dart` | 410 | 自定义时间窗选择 sheet（week/month/quarter/year/任意） | 外壳 |
| `analytics_screen_section_header.dart` | 27 | section 标题 | 外壳 |
| `analytics_card_error_state.dart` | 47 | 卡片 error 态（含 `onRetry`） | 外壳 |
| `joy_headline_kpi_tile.dart` | 96 | 悦己平均/累计 KPI tile（`formatJoyCumulative` → `Σ joy_contribution`；**JOY-01「值得」卡元素**） | 悦己 |
| `satisfaction_distribution_histogram.dart` | 181 | 满足度 1-10 直方图。**含 `Stack`+`DecoratedBox` hack（第 35-139 行）→ GATE-04 重点校验对象** | 悦己 |
| `best_joy_story_strip.dart` | 134 | 最佳悦己瞬间故事条（记忆故事；**M5 故事画报派核心元素**） | 悦己 |
| `largest_expense_story_card.dart` | 114 | 最大单笔支出故事卡 | 悦己/实用桥 |
| `daily_vs_joy_card.dart` | 471 | 日常 vs 悦己 对照卡（solo + family 模式）。**已纳入 anti-toxicity 扫描** | 悦己 |
| `joy_metric_variant_chip.dart` | 160 | Joy 指标 variant 切换 chip。**已纳入 anti_toxicity_phase17 扫描** | 悦己 |
| `joy_ledger_thin_sample_fallback.dart` | 48 | 悦己 thin-sample 低数据态 fallback | 悦己 |
| `family_insight_card.dart` | 83 | 家庭洞察卡（**aggregate-only**） | 悦己/家庭 |

**对 5 套 mock 的含义（配比映射）:**

- **M1/M2 实用侧骨架** ← `total_spending_kpi_tile` + `category_spend_donut_chart` + `monthly_spend_trend_bar_chart` + `per_category_breakdown_card` + 下钻入口 affordance。
- **M3/M4/M5 悦己侧** ← `joy_headline_kpi_tile`（值得卡）+ `satisfaction_distribution_histogram`（值不值）+ `best_joy_story_strip`（记忆故事）+ kakeibo Q4 反思 prompt（**唯一新增视觉元素**，静态只读，不在 17 widget 中）。
- **家庭模式** ← `family_insight_card`（aggregate-only，**绝不画 per-member 排行**）。
- mock 的工作是 **IA 重排 + 实用↔悦己配比调整 + 悦己端措辞/浓度探索**，不是绘制新图表类型。

---

## MonthlyReport 已算字段（零新增数据工作）

来源：`43-RESEARCH.md` §1b + `ARCHITECTURE.md` §1a/§1b。实用侧是**纯展示变换**——`GetMonthlyReportUseCase` 已算出全部所需字段，mock 与未来 Phase 44-46 落地都**不新增任何数据工作**。

| 实用侧需求 | `MonthlyReport` 字段 | 状态 |
|---|---|---|
| 总支出 | `totalExpenses` (int, JPY) | **已算** |
| 日常/悦己拆分 | `dailyTotal` / `joyTotal` | **已算** |
| Top 分类（donut/list） | `categoryBreakdowns: List<CategoryBreakdown>`（amount / percentage / txCount / icon / color） | **已算** |
| 每日支出序列 | `dailyExpenses: List<DailyExpense>`（按天 zero-fill） | **已算** |
| 跨期对比 | `previousMonthComparison` | **已算但绝不 surface（ADR-012 §4）** — doc-comment 明示 *"AnalyticsScreen no longer surfaces this delta"*；仅 HomeHero 消费。**mock 也绝不画跨期 delta** |

**悦己侧（同样零新增数据）:**

- **`Σ joy_contribution`**（ADR-016）已由 `GetHappinessReportUseCase` 算出；`joy_headline_kpi_tile.dart` 经 `formatJoyCumulative` 展示。JOY-01「值得」卡是 **framing-only**（不新增计算）。
- **13/15 用例可复用**；2 个非输入：`_TimeWindowValidation`（内部 plumbing）+ `GetBudgetProgressUseCase`（stub 返回 `[]`，需 budgets 表 → **OUT OF SCOPE**，ANALYTICS-V2-03）。

---

## 结构锁点（不可破）

以下 4 个锁点是 ADR-012/016 反游戏化与 HomeHero 隔离的**结构性强制**。GATE-02 每套 mock 的 ADR-012 自审表、以及 GATE-04 情感词表，都以这些锁点为**对照基准**。任何 mock 元素若触碰锁点即判 forbidden。

| 锁点 | 文件路径 | 它强制什么 |
|---|---|---|
| HomeHero 隔离 | `test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` | (a) `home_screen.dart` 源码**不含** `state_time_window` / `selectedTimeWindowProvider` / `state_ledger_snapshot` 字符串；(b) AnalyticsScreen 时间窗/variant 切换**绝不**重新调用 HomeHero 当月 use case（verifyNever 双门）。**mock 不得把 HomeHero target ring 复制到 analytics 侧** |
| 反毒性禁词（Phase 16） | `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart` | `PerCategoryBreakdownCard` + `DailyVsJoyCard` 在 en/ja/zh × 4 态扫描锁定禁词（better/worse/winner/vs/compare/score/rank … 中日对应词），`_sweepForbiddenSubstrings` → `findsNothing` |
| 反毒性禁词（Phase 17） | `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase17_test.dart` | `JoyMetricVariantChip` 在 en/ja/zh × 每个 variant 扫描**数据质量评判词**（不准/不可靠/不完整/估算不准/错误 等） |
| Family aggregate-only | `FamilyHappiness` 类型契约（domain） | 仅 `familyHighlightsSum` / `sharedJoyInsight` / `medianSatisfaction` / `totalGroupJoyTx`——**无 per-member 字段**（ADR-012 §6 类型系统强制）。**mock 家庭模式不得画 per-member 排行/贡献** |
| 单一 Joy 表达 | `grep -rn 'density\|joyPerYen' lib/` == 0 | `Σ joy_contribution` 是唯一 Joy metric（ADR-016 §2）。**mock 不得引入"每元快乐 / joy 效率 / 性价比"框定**（实用页极易诱发此越界） |

**GATE-04 / 词表边界备注:** 扩充 anti-toxicity 禁词时须限定到 **analytics widget 扫描范围**——`target/目标` 在 **HomeHero 上下文是合法的**（ADR-016 §3-§4 允许 `monthly_joy_target` 作为 ambient 填充环），扩充禁词**不能误伤 HomeHero 的合法 target copy**。analytics 侧（本里程碑全部 mock）则绝不引入 target 措辞（JOY-01 硬约束，D-03）。

---

## 范围勘误：仅支出侧总览

**记录 RESEARCH §1b 勘误（vs ARCHITECTURE.md）：**

`ARCHITECTURE.md` 早期写"savings-rate overview"含 `totalIncome` / `savings` / `savingsRate` 字段。但 **REQUIREMENTS.md 已把总览重构为「仅支出侧」**——

- 应用唯一的交易写入路径**硬编码 `expense`**，没有收入录入入口；
- 因此 `totalIncome` 恒为 0，**结余率（savings rate）无意义**；
- 真实收入录入 / 结余率延后到 **INCOME-V2-01**（milestone 级锁定的范围收缩）。

**硬约束（GATE-01 文档 + 全部 5 套 mock）:** 支出总览（OVW）**只画支出侧**——总支出 + 日常/悦己拆分 + Top 分类。**绝不画 结余率 / 收入 / savings-rate / 收支对比**。planner 与 executor 一律以 REQUIREMENTS.md 为准。

### Out-of-Scope 边界（参照 REQUIREMENTS.md）

以下项**不进** 5-mock 阵容、不进任何 mock 视觉，记录以防 scope creep（循环 UI-SPEC）：

| Out-of-Scope 项 | 原因 | 去向 backlog |
|---|---|---|
| 收入录入 / 真实结余率 | 无录入路径，`totalIncome`==0 | INCOME-V2-01 |
| 预算 vs 实际（budget bar） | 需 budgets 表 + v21→v22 Drift 迁移 | ANALYTICS-V2-03 |
| 可定制 / 可重排仪表盘 | v1.8 用固定重设计布局 | ANALYTICS-V2-02 |
| Sankey 收入→支出→结余流向图 | 无收入侧数据 + fl_chart 1.2.0 无 native 支持 | ANALYTICS-V2-01 |
| "about typical" 中性滚动带 | 贴近 ADR-012 #4 边界，需新 ADR 验证非评判 | ANALYTICS-V2-04 |
| 分币种 analytics 小计 | 携带自 v1.7，除非重设计自然吸收 | CUR-V2-02 |
| JOY-04 用户自撰反思文本持久化 | 本里程碑静态只读（D-06）；持久化需新 ADR + non-Drift | 未来里程碑 |

**任何 mock 出现以上元素（收入输入 / 结余率数字 / 预算条 / 拖拽重排 / 币种 tab / Sankey 流向）即越界，须在 GATE-03 选定前移除。**
