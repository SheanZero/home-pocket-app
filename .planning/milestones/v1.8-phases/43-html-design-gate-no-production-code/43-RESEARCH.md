# Phase 43: HTML 设计探索关卡 (Design Gate — NO production code) - Research

**Researched:** 2026-06-15
**Domain:** 无代码设计关卡 — 决策文档 + 自包含 HTML 设计稿规划（不是功能实现研究）
**Confidence:** HIGH（直接读取 17 个 analytics widget、6 个 provider 文件、ADR-012/016/017/019、两个 anti-toxicity 测试、milestone 级 research 种子；fl_chart 1.2.0 版本经 `pubspec.lock` 实测确认）

> **本研究服务的是"如何 PLAN 这些设计/文档交付物"**，不是"如何实现分析页"。下游 planner 用本文件来规划：(1) GATE-01 现状深研图的章节与种子内容；(2) GATE-02 五套 HTML mock 的产出结构 + ADR-012 自审表模板；(3) GATE-04 的 fl_chart 1.2.0 逐图 affordance 校验清单 + 情感词表扩充锚点。本阶段**零生产代码**——validation 是"关卡出口证据"，不是单元测试。

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions（锁定决策 — planner 必须逐条遵守）

**方向探索结构:**
- **D-01:** 主差异轴 = **实用 ↔ 悦己 配比**。比较聚焦「天平往哪偏」+ 悦己端如何表达。
- **D-02:** 产出 **5 套 mock**（超过 GATE-02 的 ≥3 下限），阵容用户亲定：
  - **M1 实用主导** — 总览/趋势/分类下钻为骨架，悦己以最克制 ambient 呈现
  - **M2 均衡** — 实用与悦己并重
  - **M3 极简实用派** — 悦己主导，但克制、干净、近实用质感（悦己端最低"浓度"）
  - **M4 温暖反思派** — 悦己主导，kakeibo Q4 反思 +「值得」肯定为情感核心
  - **M5 故事画报派** — 悦己主导，记忆故事/画报式呈现已花悦己（悦己端最高"浓度"）
  - M3/M4/M5 = 悦己主导端三种"浓度"（克制→浓墨）；M1/M2 代表实用一侧。

**悦己情感基调:**
- **D-03:** JOY-01「值得」卡数字强度（已花悦己 / `Σ joy_contribution`）在 M3/M4/M5 **各取不同强度探索**。**硬约束:绝不成为 progress/target ring**——HomeHero 独占唯一 target ring（ADR-016 §3）。
- **D-04:** 情感措辞 register = **calm-warm 平静温暖**（像日记，克制、不外放、不打分）。直接定调 GATE-04 情感词表。
- **D-05:** kakeibo Q4 前瞻反思**框定为价值观肯定（非目标）**，ADR-012-safe 的核心抓手（kakeibo 原生非游戏化先例）。

**JOY-04 持久化（GATE-04 go/no-go）:**
- **D-06:** JOY-04 = **静态只读提示**（一句温柔提问 + 示例引导，不接受用户输入）→ 不持久化 → **GATE-04 的 ADR go/no-go = 不需要新 ADR**；v1.8 保持无 Drift 迁移、纯展示层。
- **D-07:** 未来若要持久化用户自撰反思文本，留给届时新 ADR（non-Drift 优先）。本里程碑不涉及。

**Mock 产出与评审:**
- **D-08:** 媒介 = **自包含 HTML 为主体**（单文件内联 CSS，浏览器直开，可版本控制可截图 UAT）；选定一案后再用 Pencil 精细化一两关键帧。⚠ **Pencil 步骤必须在主 session 由编排者手动完成**——executor 子代理访问不到 `mcp__pencil__*`（claude-code#13898），不可交给执行子代理。
- **D-09:** 数据 = **真实感示例数据**（模拟一个家庭一个月账目）。
- **D-10:** 评审覆盖 = **仅中文 + 浅+深色**（5 mock × 2 theme = 10 视图；深色用 ADR-019 桜餅×若葉暖调）。三语 ARB parity 留到 Phase 47。
- **D-11:** 选定唯一一案首要评判 = **悦己情感共鸣 / 实用性 / ADR-012 安全度**（复用度/低成本为次要上下文，不进首要标准）。

### Claude's Discretion（researcher/planner 自由裁量区）
- D-03 数字强度在 M3/M4/M5 之间的具体分配由设计阶段把握。
- mock 文件存放位置/命名（建议 `.planning/phases/43-html-design-gate-no-production-code/mocks/`）。
- GATE-04 fl_chart affordance 校验的逐图清单。
- GATE-01 现状深研图的章节粒度。

### Deferred Ideas（OUT OF SCOPE — 完全忽略，记录以防丢失）
- 收入录入 / 真实结余率 → INCOME-V2-01
- 预算 vs 实际（需 budgets 表 + 迁移）→ ANALYTICS-V2-03
- 可定制/可重排仪表盘 → ANALYTICS-V2-02
- Sankey 收入→支出→结余流向图（无收入侧数据 + 无 native fl_chart 支持；**不进 5-mock 阵容**）→ ANALYTICS-V2-01
- "about typical" 中性滚动带 → ANALYTICS-V2-04
- 分币种 analytics 小计 → CUR-V2-02
- JOY-04 用户自撰反思文本持久化 → 未来新 ADR
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| **GATE-01** | 书面「现状统计实现深研图」（以 `.planning/research/ARCHITECTURE.md` reuse 图为种子）：13/15 可复用用例、`MonthlyReport` 已算字段、HomeHero 隔离 + 反毒性结构锁点 | §1 现状深研图种子（17 widget 清单 + 已算字段表 + 锁点测试文件路径）。本研究把 ARCHITECTURE.md 的 reuse 图直接落到 widget 粒度。 |
| **GATE-02** | ≥3 套（本阶段 5 套）HTML 方向，每套自带 ADR-012 自审表，把每个情感元素映射为 *ambient/庆祝过去(OK)* vs *目标/跨期对比/成就(forbidden)* | §2 mock 产出指南（5 套结构 + 自审表模板 + 存储约定 + 示例数据 schema）。§4 反游戏化映射表（ambient OK vs forbidden 的可操作定义）。 |
| **GATE-03** | 充分讨论后用户选定恰好一套；出口 = 用户批准 且 仓库无新增 Dart/生产代码 | §6 Validation Architecture（关卡出口证据清单）+ §5 Pitfall 4（防止 build 提前/scope creep）。 |
| **GATE-04** | 选定方向：新 ADR go/no-go（D-06: 不需要）、锁定情感词表、每图表 affordance 对 fl_chart 1.2.0 逐项校验 | §3 fl_chart 1.2.0 affordance 事实表 + 逐图校验清单种子；§3 情感词表锚点（现有 anti-toxicity 词表 + 扩充建议）。 |
</phase_requirements>

## Summary

这是一个**硬性设计关卡**，唯一目的是在写任何生产代码前关闭核心设计问题——「为自己花钱而开心」如何在 ADR-012 恒久反游戏化约束下表达。交付物只有四类决策/设计产物（GATE-01..04），**没有 Dart/Drift/数据/用例工作**。所有真正的数据复用研究已在 milestone 级的 `.planning/research/ARCHITECTURE.md` 完成（13/15 用例可复用、`MonthlyReport` 已算全部实用字段、零新增数据工作）——本阶段不重做它，而是把它**落到 widget 粒度**作为 GATE-01 的种子，并以它为约束去**规划 5 套 HTML mock 的产出**。

研究确认了三件对 planner 最关键的事实：(1) **17 个现成 analytics widget** 已覆盖 mock 所需的全部视觉元素（donut/趋势柱/满足度直方图/各悦己卡/KPI tile），mock 应当是**重组这些既有元素的视觉结构**而非从零重画；(2) **fl_chart 实测锁定在 `1.2.0`**（`pubspec.lock` 确认，无 2.x 存在），其原生 `BarChartRodData.label` + `PieChartSectionData.cornerRadius` 已可用，直方图旧 `Stack`+`DecoratedBox` hack（`satisfaction_distribution_histogram.dart` 第 35-139 行）可由 1.2.0 `label` 取代——这是 GATE-04 逐图校验的核心事实；(3) **反游戏化的两层结构锁**（`home_screen_isolation_test.dart` 源串+verifyNever 双门 + `anti_toxicity_phase16/17_test.dart` 禁词扫描 + `FamilyHappiness` aggregate-only 类型契约）是 GATE-02 自审表和 GATE-04 词表的对照基准。

**Primary recommendation:** 把本阶段规划为「先深研（GATE-01 文档）→ 并行产 5 套自包含 HTML mock（每套自带 ADR-012 自审表，复用 17 widget 视觉结构 + 真实感家庭一月示例数据 + 浅/深双主题）→ 讨论选定一案（GATE-03，用户批准为出口）→ 对选定方向锁词表 + 逐图 fl_chart 1.2.0 affordance 校验（GATE-04，ADR go/no-go = 不需要）」。Pencil 关键帧精细化排在选定之后、由主 session 编排者手动完成，**绝不进 executor 子代理任务**。

## Architectural Responsibility Map

> 本关卡的"能力"是设计/文档交付物，不是运行时分层。下表把每个交付物映射到它的产出主体与产出方式。

| Capability（交付物） | Primary 产出主体 | Secondary | Rationale |
|------------|-------------|-----------|-----------|
| GATE-01 现状深研图 | researcher/planner 撰写 Markdown 文档 | — | 纯文档；种子已在 ARCHITECTURE.md，落到 widget 粒度即可 |
| GATE-02 五套 HTML mock | executor 子代理产出自包含 HTML | — | HTML+内联 CSS 是 executor 可产出/版本控制/截图的媒介（D-08） |
| GATE-02 每套 ADR-012 自审表 | executor 随 mock 产出 Markdown 表 | researcher 提供模板 | 每个情感元素 → ambient/forbidden 映射，对照 §4 |
| GATE-03 选定一案 | 用户决策（讨论后） | 主 session 记录 | 关卡出口 = 用户批准；无代码提交 |
| GATE-04 词表锁定 | planner 撰写词表文档 | 对照现有 anti-toxicity 词表 | 扩充 `anti_toxicity_*_test` 的禁词（calm-warm register） |
| GATE-04 fl_chart 逐图校验 | planner 撰写校验清单 | §3 affordance 事实表 | 每图 affordance → 1.2.0 API 是否原生支持 |
| GATE-04 ADR go/no-go | planner 记录决定（D-06 = no-go） | — | JOY-04 静态只读 → 无持久化 → 不需要新 ADR |
| Pencil 关键帧精细化 | **主 session 编排者手动**（选定后） | — | executor 无 `mcp__pencil__*`（claude-code#13898）；**不可交执行子代理** |

## Standard Stack

> 本关卡几乎不"安装"任何东西。Mock 是浏览器直开的自包含 HTML（D-08）。下表是 mock 制作与校验所需的"栈"。

### Core
| 工具/技术 | 版本 | 用途 | 为何标准 |
|---------|------|------|---------|
| 自包含 HTML + 内联 CSS | n/a（浏览器原生） | 5 套设计稿主体媒介 | D-08 锁定：单文件、可版本控制、可截图 UAT、executor 可产出。无构建步骤、无依赖 |
| `fl_chart` | **`1.2.0`**（`pubspec.lock` 实测） | GATE-04 affordance 校验对象（mock 不真的用它，但每个 chart affordance 必须能映射回 1.2.0 API） | 项目现 pin；**无 2.x**；原生 `label`/`cornerRadius` 已发布 [VERIFIED: pubspec.lock + STACK.md] |
| ADR-019 桜餅×若葉 palette | v1.6（light + dark hex 表见 §2） | mock 取色（浅+深双主题，D-10） | 项目 live 配色，深色 mock 必须用暖调 hex 验证 |

### Supporting
| 工具 | 用途 | 何时用 |
|------|------|--------|
| Pencil MCP（`mcp__pencil__*`） | 选定一案后精细化 1-2 关键帧 | **仅主 session 手动**，选定之后；executor 子代理不可用（claude-code#13898） |
| 现有 17 个 analytics widget 源码 | mock 视觉结构的复刻参照 | 产 mock 时对照每个 widget 的布局/配色/层级 |
| 现有 anti-toxicity 测试词表 | GATE-04 情感词表扩充的基准 | 锁定 calm-warm register 词表时 |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| 自包含 HTML | 直接 Pencil mock | Pencil 无法落盘 + executor 无 MCP 访问（claude-code#13898）→ 不可作为主产出媒介，只能选定后主 session 精细化 |
| 自包含 HTML | Flutter widget 原型 | 违反"零生产代码"硬约束；且改 Dart 即破关卡出口条件 |
| fl_chart 1.2.0 | 升级 2.x / 换 graphic/syncfusion | **2.x 不存在**；换库要重做全部 golden + 商业 license 风险（STACK.md 已否决） |

**Installation:** 无需安装。Mock 浏览器直开。`flutter pub get` 不需要（无依赖变更）。

**Version verification:**
```bash
awk '/^  fl_chart:/{f=1} f&&/version:/{print; exit}' pubspec.lock   # → version: "1.2.0" [VERIFIED 2026-06-15]
```

## Package Legitimacy Audit

> 本关卡**不安装任何外部包**（自包含 HTML，无依赖变更）。fl_chart `1.2.0` 已在树内且经 milestone 级 STACK.md 审计为 MIT、纯 Dart、无网络/telemetry、已集成。无新增包 → 无 SLOP/SUS 风险。

| Package | Registry | 状态 | Verdict | Disposition |
|---------|----------|------|---------|-------------|
| fl_chart | pub.dev | 已在树内 `1.2.0`，MIT，无 telemetry | OK | 不变（仅作 GATE-04 校验对象，本阶段不改 pubspec） |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## 1. GATE-01 现状深研图种子（落到 widget 粒度）

> GATE-01 文档以 `.planning/research/ARCHITECTURE.md` 的 reuse 图为种子。本节把那张 reuse 图**落到 17 个 widget 的名字+角色**，外加已算字段表与结构锁点的精确文件路径——这是 GATE-01 文档可直接消费的"种子内容"。

### 1a. 17 个现成 analytics widget 清单（按 LOC，role 标注）

来源：`lib/features/analytics/presentation/widgets/`（`ls` + `wc -l` 实测，2026-06-15）[VERIFIED: codebase]

| Widget 文件 | LOC | Role（mock 复刻参照） |
|---|---|---|
| `daily_vs_joy_card.dart` | 471 | 日常 vs 悦己 对照卡（solo + family 模式）。**已纳入 anti-toxicity 扫描** |
| `time_window_picker_sheet.dart` | 410 | 自定义时间窗选择 sheet（week/month/quarter/year/任意） |
| `per_category_breakdown_card.dart` | 260 | 分类悦己 breakdown（min-N=3 + Other rollup）。**已纳入 anti-toxicity 扫描** |
| `satisfaction_distribution_histogram.dart` | 181 | 满足度 1-10 直方图。**含 `Stack`+`DecoratedBox` hack（第 35-139 行）→ GATE-04 重点校验对象** |
| `joy_metric_variant_chip.dart` | 160 | Joy 指标 variant 切换 chip。**已纳入 anti_toxicity_phase17 扫描** |
| `category_spend_donut_chart.dart` | 148 | 分类支出环形图（donut）。GATE-04 可选 `cornerRadius` 校验对象 |
| `monthly_spend_trend_bar_chart.dart` | 147 | 6 个月支出趋势柱状图 |
| `best_joy_story_strip.dart` | 134 | 最佳悦己瞬间故事条（记忆故事；M5 故事画报派核心元素） |
| `largest_expense_story_card.dart` | 114 | 最大单笔支出故事卡 |
| `time_window_chip.dart` | 99 | 时间窗 chip（外壳常驻） |
| `joy_headline_kpi_tile.dart` | 96 | 悦己平均/累计 KPI tile（`formatJoyCumulative` → `Σ joy_contribution`；JOY-01 元素） |
| `family_insight_card.dart` | 83 | 家庭洞察卡（aggregate-only） |
| `total_spending_kpi_tile.dart` | 57 | 总支出 KPI tile（OVW 元素） |
| `joy_ledger_thin_sample_fallback.dart` | 48 | 悦己 thin-sample 低数据态 fallback |
| `kpi_mini_hero_strip.dart` | 47 | KPI mini-hero 横条（容纳多个 tile） |
| `analytics_card_error_state.dart` | 47 | 卡片 error 态（含 `onRetry`） |
| `analytics_screen_section_header.dart` | 27 | section 标题 |

**对 planner 的含义:** 5 套 mock 的视觉元素**几乎全部能从上表映射出来**。M1/M2 实用侧 = `total_spending_kpi_tile` + `category_spend_donut_chart` + `monthly_spend_trend_bar_chart` + drill-down 入口；M3/M4/M5 悦己侧 = `joy_headline_kpi_tile`（值得卡）+ `satisfaction_distribution_histogram`（值不值）+ `best_joy_story_strip`（记忆故事）+ kakeibo Q4 prompt（**唯一新增视觉元素**，静态只读）。mock 主要是 IA 重排 + 配比调整 + 悦己端措辞/浓度探索，**不是绘制新图表类型**。

### 1b. `MonthlyReport` / use-case 已算字段（零新增数据工作）

来源：ARCHITECTURE.md §1a + §1b（HIGH，直接读 use case 与 domain model）。GATE-01 文档应复述这张表以证明实用侧"纯展示变换"：

| 实用侧需求 | `MonthlyReport` 字段 | 状态 |
|---|---|---|
| 总支出 | `totalExpenses` (int, JPY) | **已算** |
| 日常/悦己拆分 | `dailyTotal` / `joyTotal` | **已算** |
| Top 分类（donut/list） | `categoryBreakdowns: List<CategoryBreakdown>`（amount/percentage/txCount/icon/color） | **已算** |
| 每日支出序列 | `dailyExpenses: List<DailyExpense>`（按天 zero-fill） | **已算** |
| 跨期对比 | `previousMonthComparison` | **已算但绝不 surface**——doc-comment 明示 *"AnalyticsScreen no longer surfaces this delta (ADR-012 §4)"*；仅 HomeHero 消费。**mock 也绝不能画跨期 delta** |

- **`Σ joy_contribution`**（ADR-016）已由 `GetHappinessReportUseCase` 算出（`joy_headline_kpi_tile` 经 `formatJoyCumulative` 展示）。JOY-01「值得」卡是 framing-only。
- **13/15 用例可复用**；2 个非输入：`_TimeWindowValidation`（内部 plumbing）+ `GetBudgetProgressUseCase`（stub 返回 `[]`，需 budgets 表，**OUT OF SCOPE**）。
- **重要勘误（vs ARCHITECTURE.md）:** ARCHITECTURE.md 写"savings-rate overview"含 `totalIncome`/`savings`/`savingsRate` 字段。但 **REQUIREMENTS.md 已把总览重构为"仅支出侧"**（无收入录入路径，`totalIncome` 恒为 0，结余率无意义 → INCOME-V2-01）。**GATE-01 文档与所有 mock 必须只画支出总览（OVW），不画结余率**。这是 milestone 级已锁定的范围收缩，planner 必须以 REQUIREMENTS.md 为准。

### 1c. 结构锁点（不可破；GATE-02 自审 + GATE-04 词表的对照基准）

| 锁点 | 文件路径 | 它强制什么 |
|---|---|---|
| HomeHero 隔离 | `test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` | (a) `home_screen.dart` 源码**不含** `state_time_window` / `selectedTimeWindowProvider` / `state_ledger_snapshot` 字符串；(b) AnalyticsScreen 时间窗/variant 切换**绝不**重新调用 HomeHero 当月 use case（verifyNever）。**mock 不得把 HomeHero target ring 复制到 analytics 侧** |
| 反毒性禁词（Phase 16） | `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart` | `PerCategoryBreakdownCard` + `DailyVsJoyCard` 在 en/ja/zh × 4 态扫描锁定禁词（见 §3 词表） |
| 反毒性禁词（Phase 17） | `test/widget/.../anti_toxicity_phase17_test.dart` | `JoyMetricVariantChip` 在 en/ja/zh × 每个 variant 扫描**数据质量评判词**（不准/不可靠/不完整等） |
| Family aggregate-only | `FamilyHappiness` 类型（domain） | 仅 `familyHighlightsSum: int` / `sharedJoyInsight` / `medianSatisfaction` / `totalGroupJoyTx`——**无 per-member 字段**。ADR-012 §6 类型系统强制。**mock 家庭模式不得画 per-member 排行/贡献** |
| 单一 Joy 表达 | `grep -rn 'density\|joyPerYen' lib/` == 0 | `Σ joy_contribution` 是唯一 Joy metric（ADR-016 §2）。**mock 不得引入"每元快乐/joy 效率/性价比"框定**（实用页很容易诱发此） |

## 2. GATE-02 五套 HTML mock 产出指南

### 2a. 存储约定（Claude's Discretion，推荐）

```
.planning/phases/43-html-design-gate-no-production-code/mocks/
├── README.md                    # 阵容索引 + 评判矩阵 + 示例数据说明
├── shared/
│   └── sample-data.md           # D-09 真实感家庭一月账目（5 套共用，保证可比性）
├── m1-practical-led/
│   ├── m1-light.html            # 自包含：单文件内联 CSS
│   ├── m1-dark.html
│   └── m1-adr012-audit.md       # 本套 ADR-012 自审表（§2c 模板）
├── m2-balanced/  …（同结构）
├── m3-minimal-joy/  …
├── m4-warm-reflective/  …
└── m5-story-magazine/  …
```

- 每套 = `{light}.html` + `{dark}.html` + `{audit}.md` = 3 文件 × 5 套 = 15 文件 + 2 个共享文件。共 **10 个 HTML 视图**（D-10：5 mock × 2 theme，仅中文）。
- HTML 必须**自包含**（内联 `<style>`，无外部 CSS/JS/字体 CDN——离线可开，符合零知识 app 气质）。

### 2b. 5 套 mock 的元素配比骨架（从 §1a widget 清单映射）

| | 实用侧元素 | 悦己侧元素 | 悦己浓度 | JOY-01 数字强度（D-03） |
|---|---|---|---|---|
| **M1 实用主导** | 支出总览 KPI + donut + 6月趋势柱 + 下钻入口（骨架） | 最克制 ambient（如一行暖色悦己小计） | 最低 | 弱（附属于总览） |
| **M2 均衡** | 总览 + donut + 趋势并重 | 值得卡 + 满足度 + 故事条 并重 | 中 | 中 |
| **M3 极简实用派** | 干净的总览/分类 | 值得卡为主，克制干净近实用质感 | 悦己端最低 | **探索"低强度"读感** |
| **M4 温暖反思派** | 总览退居次要 | 值得卡 + kakeibo Q4 反思 + 满足度为情感核心 | 悦己端中 | **探索"中强度"读感** |
| **M5 故事画报派** | 总览最简 | 记忆故事/画报式呈现已花悦己（`best_joy_story_strip` 升级版） | 悦己端最高 | **探索"高强度"读感** |

- **kakeibo Q4 反思 prompt** 是唯一**新增**视觉元素（不在 17 widget 中）：静态只读（D-06）、一句温柔提问 + 示例引导、价值观肯定框定（D-05）、不接受输入。M4 为核心展示，M3/M5 可酌情。
- **drill-down 入口**：mock 只需画"点分类→进入"的 affordance 暗示（chevron/tap target），真实下钻路径是 Phase 44 的事。

### 2c. 每套 ADR-012 自审表模板（GATE-02 硬性产物）

每套 mock 必带一张表，把**每个情感元素**映射为 OK / forbidden。模板（planner 直接给 executor）：

```markdown
## ADR-012 自审表 — Mock {Mx}

| 情感元素 | ambient/庆祝过去 (OK) ✅ | 目标/跨期对比/成就 (forbidden) ❌ | 判定 | 依据 |
|---|---|---|---|---|
| 值得卡数字 | 绝对累计 Σ joy_contribution，无基线对比 | 若做成 progress ring / "达成 X%" | ✅/❌ | ADR-016 §3 §5 |
| 满足度直方图 | 分布展示 + 描述性措辞 | 若标"超过上月"/"目标 8+" | ✅/❌ | ADR-012 #3 #4 |
| 记忆故事条 | 叙事回顾既有 best-joy | 若做"最棒悦己分类"排名 | ✅/❌ | ADR-012 #6 + §4 |
| kakeibo Q4 prompt | 开放、肯定、价值观（"什么让你觉得值得"） | 若做成评分/目标式提问 | ✅/❌ | D-05 + ADR-012 #3 |
| 趋势柱 | 中性滚动上下文 | 若强调当月相对前月（视觉对比） | ✅/❌ | ADR-012 #4 |
| 家庭模式 | aggregate-only 洞察 | per-member 排行/贡献 | ✅/❌ | ADR-012 #6 类型契约 |
| 配色/动效（mock 静态示意） | 暖色 ambient `f(progress)→color` | confetti/徽章/解锁动效 | ✅/❌ | ADR-016 §5 + STACK.md |

**整套裁定:** {PASS / 需调整 / REJECT}
**任何 ❌ 必须在选定前移除或降级为 ambient。**
```

### 2d. D-09 真实感示例数据（5 套共用，放 `shared/sample-data.md`）

为让情感与密度读感准确（D-09），5 套用**同一组**模拟一家庭一月账目，包含：总支出 + 日常/悦己拆分、Top 分类（含 icon/color）、满足度分布（覆盖 1-10，让直方图有形状）、最佳悦己瞬间（category + 金额 + 日期 + fullness）、`Σ joy_contribution` 累计值、家庭两成员的 aggregate 数。共用数据保证 5 套**可比**（评判时差异只来自设计，不来自数据）。金额用 JPY（¥1,235 无小数，ADR-019 amount style）。

## 3. GATE-04 fl_chart 1.2.0 affordance 校验 + 情感词表锚点

### 3a. fl_chart 1.2.0 affordance 事实（逐图校验清单种子）

`fl_chart` 实测锁定 `1.2.0`（`pubspec.lock`）[VERIFIED: pubspec.lock 2026-06-15]。**无 2.x 存在**（STACK.md 经 pub.dev 主源确认）。GATE-04 须对**选定方向的每张图**逐项核对 affordance 是否原生支持：

| Affordance | 1.2.0 原生支持？ | 现状 / mock 用途 | 校验结论种子 |
|---|---|---|---|
| 柱顶 per-rod 标签 `BarChartRodData.label` | ✅ 原生（1.2.0 新增） | **可删除 `satisfaction_distribution_histogram.dart` 第 35-139 行的 `Stack`+`Align(Alignment(-0.12,-1))`+`DecoratedBox` hack** | 任何"实用派"mock 想要柱顶常驻数值标签 = **原生可行**，不再需要 overlay hack |
| Donut section 圆角 `PieChartSectionData.cornerRadius` | ✅ 原生（1.2.0 新增） | `category_spend_donut_chart.dart` 可加一行变柔和暖调 | 悦己暖调 donut = 一参数搞定 |
| 标签方向 `LabelDirection`（horizontal/vertical Mirrored） | ✅ 原生 | 下钻柱标签灵活定位 | 可行 |
| 触摸 tooltip `BarTouchData`/`PieTouchData` | ✅ 已用 | donut/柱点击下钻 callback | 可行（现状已用） |
| 数据变化进场动画 `swapAnimationDuration`/`Curve` | ✅ 原生 | ambient 进场（非 achievement） | ADR-012-safe |
| LineChart 做 sparkline（隐藏轴/网格/点） | ✅ 可行 | 下钻行内迷你趋势 | 无新依赖 |
| **Sankey 流向图** | ❌ **无 native 支持** | — | **不进 5-mock 阵容**（OUT OF SCOPE，ANALYTICS-V2-01） |

**对 mock 的约束:** 任何 mock 画出的 chart affordance 都必须能映射回上表的 ✅ 行。若某 mock 想要 ❌ 行的能力（如 Sankey），GATE-04 须标记并退回——这正是"逐图校验"防止 Phase 46 撞到"图表库做不到"的作用。

### 3b. 情感词表锚点（calm-warm register，GATE-04 锁定 + 扩充 anti-toxicity 扫描）

D-04 定调 register = **calm-warm**。GATE-04 锁定的词表将**扩充**现有两个 anti-toxicity 测试。现有锁定禁词（`anti_toxicity_phase16_test.dart` 实测）[VERIFIED: codebase]：

- **EN:** `better` `worse` `winner` `loser` `vs` `versus` `compare` `comparison` `higher is good` `lower is bad` `score` `rank` `ranking` `wins` `loses`
- **ZH:** `更好` `更差` `赢` `输` `胜` `败` `vs` `对比` `比较` `排名` `分数` `胜出` `落败`
- **JA:** `勝ち` `負け` `より良い` `より悪い` `比較` `対決` `スコア` `ランキング` `勝つ` `負ける`
- **Phase 17 额外（数据质量评判，针对 variant chip）:** ZH `不准/不可靠/不完整/质量差/估算不准/错误`；JA `不正確/信頼できない/不完全/精度が低い/誤り`

**GATE-04 建议扩充（因 5 套 mock 引入新悦己措辞，calm-warm 的红线词）:**
- ZH 候选新增：`最棒` `最好` `超过` `达成` `目标` `连续` `成就` `排行` `第一`
- EN 候选新增：`best` `top` `beat` `most` `streak` `achievement` `goal` `target` `unlock`
- JA 候选新增：`最高` `達成` `連続` `目標` `ベスト`

> ⚠ **关于 `target`/`目标`:** ADR-016 §3-§4 允许 HomeHero 的 `monthly_joy_target` 作为 ambient 填充环——所以"target/目标"在 **HomeHero 上下文是合法的**。但 analytics 侧（本里程碑全部 mock）**绝不引入 target 措辞**（JOY-01 硬约束，D-03）。扩充禁词时须限定到 analytics widget 扫描范围，**不能误伤 HomeHero 的合法 target copy**。这是 planner 锁词表时的精细边界，GATE-04 文档须显式记录。
- **测试模板:** `anti_toxicity_phase16_test.dart` 的 `_sweepForbiddenSubstrings`（pump 整卡 → `find.textContaining(substring, findRichText: true)` → `findsNothing`）是新卡扫描的范本。本阶段**不写测试**（无代码），但 GATE-04 词表文档应指明 Phase 47 将以此模板把每张新卡纳入扫描。

### 3c. ADR go/no-go（GATE-04 决定 = no-go）

D-06 锁定 JOY-04 = 静态只读提示 → 不持久化用户文本 → **不触发加密/隐私含义 → 不需要新 ADR**。GATE-04 文档须显式记录此 go/no-go 结论 + 依据（D-06/D-07），并声明 v1.8 保持无 Drift 迁移、纯展示层。这是 GATE-04 四项产物之一，**结论已由 CONTEXT 锁定，planner 只需记录不需再讨论**。

## 4. 反游戏化映射表（ambient OK vs forbidden 的可操作定义）

> 这是 GATE-02 自审表填写时的"判定标准"。继承 ADR-016 §3/§5 的精确区分：**ambient 状态渲染 `f(progress)→color` OK；离散 unlock/threshold/庆祝事件 forbidden**。

| 情感意图 | ✅ ambient/庆祝过去（OK） | ❌ 目标/跨期对比/成就（forbidden） | ADR 依据 |
|---|---|---|---|
| 让悦己花费"感觉好" | 展示**已发生什么**（"这月你用 X 滋养了自己"）；绝对累计 `Σ joy_contribution` 无基线 | "你比上月做得更好/更多/更高" | ADR-012 #4 / FEATURES |
| 满足感 | 满足度**分布** + 描述性反思（"最让你满足的悦己"） | "超过上月满足度" / "目标 8+" | ADR-012 #3 |
| 记忆/故事 | 抬升既有 `best_joy_story_strip`（叙事天然非竞争） | "你最棒的悦己分类"（best=排名） | ADR-012 #6 + Pitfall 1 |
| kakeibo Q4 反思 | 开放、肯定、价值观（"下次什么会让你更开心"= 多花在真正享受的事上） | 评分式/目标式/打分提问 | D-05 + kakeibo 原生先例 |
| 进度感 | **无**（analytics 侧不放进度环）；HomeHero 独占 target ring | 任何 analytics 侧 progress/target ring | ADR-016 §3 |
| 100% / 满额行为 | 颜色平滑过渡（连续函数） | toast/snackbar/一次性发光/脉冲/haptic/显示 >100% 数字 | ADR-016 §5 |
| 家庭模式 | aggregate-only 洞察 | per-member 排行/贡献/排序列表 | ADR-012 #6 类型契约 |
| 动效 | 暖色 count-up / glow / fade（value-affirming） | confetti / 徽章解锁 / 阈值触发动画 | STACK.md + ADR-012 #2 |

**判定口诀:** 动画/强调若由"**view/data 出现**"触发 = OK；若由"**跨过阈值/目标/连续**"触发 = forbidden。

## 5. Common Pitfalls（本关卡特有）

### Pitfall 1: 反游戏化陷阱在 mock 情感元素里悄悄越界（最高优先级）
**What goes wrong:** "让用户为自己花钱开心"与"庆祝进度"是 gamification app 的同款词汇。HTML 探索会本能地伸手去拿 streak/徽章/带 confetti 的环/"你超过上月了"/排名框定，因为那是该领域默认。
**Why:** Goodhart's Law（ADR-012 §💡）——一旦悦己数字成目标，用户优化"保持数字好看"而非诚实自我花费，毁掉 v1.1/v1.2 诚实收集的数据。家庭模式让任何对比关系性有毒。
**How to avoid:** (1) 每套 mock **必带** §2c ADR-012 自审表，逐元素映射 ambient/forbidden；(2) 用 §4 映射表作判定标准；(3) 任何 ❌ 元素在 GATE-03 选定前移除或降级；(4) 这正是关卡存在的理由——把陷阱变成**显式中心问题**。
**Warning signs:** mock 出现进度环带"100%!"态、score 样数字、"vs 上月"、"连续"、奖杯/勋章/confetti、per-member 排序、`更好/最棒/赢/best/top/rank` 字样。

### Pitfall 2: 循环 UI-SPEC（mock 反向定义需求，而非设计在需求内）
**What goes wrong:** mock 制作时"顺手"加入超出 REQUIREMENTS.md 锁定范围的功能（结余率、收入、预算、可定制仪表盘、Sankey、分币种小计），然后这些 mock 成为后续 phase 的事实需求，绕过了 Out-of-Scope 锁。
**Why:** "全面大改"名字无界；mock 是视觉的，容易塞东西。
**How to avoid:** mock **只画** REQUIREMENTS.md 的 4 实用（OVW 支出总览/TREND 趋势/DRILL 下钻入口）+ 4 悦己（JOY-01..04）。**支出总览仅支出侧，不画结余率/收入**（§1b 勘误）。Sankey/可定制/分币种 = OUT OF SCOPE，不进阵容。GATE-01 文档以 REQUIREMENTS.md 的 Out-of-Scope 表为边界声明。
**Warning signs:** 任何 mock 含收入输入、结余率数字、预算条、拖拽重排、币种 tab、Sankey 流向。

### Pitfall 3: fidelity vs scope creep（mock 想要 fl_chart 做不到的图）
**What goes wrong:** "实用派"mock 假设图表库能做任意标签/图型（如柱顶常驻标签曾被认为是限制，或 Sankey），到 Phase 46 才发现 fl_chart 1.2.0 做不到 → 返工。
**Why:** 设计者假设"图表库能显示的任何标注都可用"。
**How to avoid:** GATE-04 **逐图** affordance 校验（§3a 事实表）。好消息：柱顶 per-rod 标签在 1.2.0 **原生可行**（直方图 Stack hack 可删）；donut 圆角原生；Sankey **不行**（已排除）。任何 mock 的 chart affordance 必须映射回 §3a 的 ✅ 行。
**Warning signs:** mock 出现 Sankey、或假设需要 1.2.0 没有的图型/标注。

### Pitfall 4: Pencil-MCP executor 限制（把 Pencil 交给执行子代理 → 卡死）
**What goes wrong:** 把"用 Pencil 精细化关键帧"写成 executor 子代理任务。但 executor 子代理**访问不到** `mcp__pencil__*`（claude-code#13898），且本环境 Pencil 无法落盘 → 任务无法完成。
**Why:** D-08 的媒介分工容易被忽略——HTML 给 executor，Pencil 只给主 session。
**How to avoid:** planner 把 Pencil 步骤排为**选定一案之后、主 session 编排者手动**的独立动作，**绝不进任何 executor wave**。HTML mock（GATE-02 主产物）才是 executor 可做的。
**Warning signs:** plan 里出现"executor: 用 Pencil 产出/精细化 mock"。

### Pitfall 5: 关卡出口被短路（在选定前提交 Dart/生产代码 → 破关卡条件）
**What goes wrong:** 在 GATE-03 用户批准前就开始写 Phase 44+ 的 Dart 代码。但 GATE-03 出口条件 = **用户批准 且 仓库无新增 Dart/生产代码**。任何 `.dart`/pubspec/Drift 改动都破坏出口条件。
**How to avoid:** 本阶段所有交付物是 `.md` + `.html`。planner 的每个 plan task 的产物路径必须落在 `.planning/` 或 `mocks/`（HTML/MD），**绝无 `lib/` 写入**。验证见 §6。
**Warning signs:** plan task 产物路径含 `lib/`、`test/`、`pubspec.yaml`、`*.dart`、`*.g.dart`、Drift schema。

## 6. Validation Architecture（关卡出口证据，非单元测试）

> **本关卡 nyquist_validation 解读:** 这是无代码设计关卡，没有可跑的单元测试。validation = **gate-exit 证据**：每个 GATE 交付物存在 + ADR-012 自审通过 + 用户批准 + 仓库无新增 Dart/生产代码。VALIDATION.md 应据此派生为"证据清单"而非"测试矩阵"。

### Gate-Exit 证据矩阵
| Req | 出口证据（可验证） | 验证方式（无代码） |
|-----|------|------|
| GATE-01 | `mocks/`（或 phase 目录）存在 GATE-01 现状深研图 `.md`，含 17 widget 清单 + `MonthlyReport` 已算字段表 + 4 个结构锁点文件路径 | 文件存在 + 章节核对（§1 种子） |
| GATE-02 | 5 套 mock 各有 `{light}.html` + `{dark}.html` + `adr012-audit.md`；每张自审表无遗留 ❌（或 ❌ 已标注待移除） | `ls mocks/m*/` 计数 = 15 文件 + 浏览器打开 10 视图截图 + 自审表逐表过 |
| GATE-03 | 主 session 记录"用户选定 Mx + 批准"；`git status` 显示无 `lib/`/`*.dart`/`pubspec`/Drift 改动 | 用户显式批准语句 + `git diff --name-only` 仅含 `.planning/`+`.md`+`.html` |
| GATE-04 | 选定方向的：(a) ADR go/no-go 记录（= no-go，依据 D-06）；(b) 锁定情感词表 `.md`（扩充建议 + analytics-only 边界）；(c) 逐图 fl_chart 1.2.0 affordance 校验表（每图 ✅/❌ 映射回 §3a） | 三项文档存在 + 内容核对 |

### 关键验证命令（出口前手动跑）
```bash
# 出口硬条件：仓库无新增 Dart/生产代码
git diff --name-only | grep -E '\.dart$|pubspec\.(yaml|lock)|/lib/|/test/' && echo "❌ 破坏出口条件" || echo "✅ 无生产代码改动"
# mock 文件完整性（5 套 × 3 文件）
ls .planning/phases/43-html-design-gate-no-production-code/mocks/m*/ | wc -l   # 期望 ≥ 15
```

### Wave 0 Gaps
- 无测试框架缺口（本阶段不写测试）。
- 需先建 `mocks/shared/sample-data.md`（D-09 共用示例数据），再产 5 套 mock——这是 mock 可比性的前置依赖，应排在 mock 产出 wave 之前。

## 7. Security Domain

> `security_enforcement` 默认启用。但本阶段**零生产代码、零数据、零网络**——mock 是自包含离线 HTML，不处理真实财务数据（D-09 用模拟数据）。

| ASVS Category | Applies | 说明 |
|---------------|---------|------|
| V5 Input Validation | no | mock 不接受输入（JOY-04 静态只读，D-06） |
| V6 Cryptography | no | 本阶段不触加密；JOY-04 不持久化 → 无加密/隐私含义（GATE-04 go/no-go = no-go） |
| 其它 | no | 无认证/会话/访问控制/数据存储 |

**唯一安全相关红线:** mock 的示例数据必须是**模拟数据**（D-09），**绝不嵌入真实用户财务数据**。自包含 HTML 不得引用外部资源（CDN 字体/JS/CSS）——保持离线、零网络，符合零知识 app 气质。

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `mocks/` 目录命名/结构按推荐布局 | §2a | 低——Claude's Discretion 显式授权 researcher/planner 定 |
| A2 | GATE-04 禁词扩充候选（最棒/best/streak 等）是合理的 calm-warm 红线 | §3b | 中——具体词表由 GATE-04 用户讨论锁定；此处仅候选锚点。`target/目标` 的 analytics-only 边界是真实约束（ADR-016 允许 HomeHero target），须避免误伤 |
| A3 | 5 套 mock 的元素配比骨架（§2b 表）是对 D-02 阵容的合理细化 | §2b | 低——D-03 浓度分配是 Claude's Discretion；骨架可在设计阶段调整 |

**表非空说明:** 上述 3 项均为 mock 产出的**结构性建议**（命名/配比/词表候选），落在 CONTEXT 显式授权的 Discretion 区。无任何**事实性**假设——所有技术事实（fl_chart 1.2.0、17 widget、已算字段、锁点文件、禁词列表、palette hex）均 VERIFIED via 实测或 CITED via 项目文档。

## Open Questions

1. **5 套 mock 的产出并行度**
   - 已知:每套自包含、共用示例数据、互不依赖（除共享 sample-data）。
   - 不清楚:planner 是否一波并行产 5 套 vs 分批。
   - 建议:sample-data + GATE-01 先行（wave 0）；5 套 mock 可一波并行（executor 各产一套，注意 §5 Pitfall 4——Pencil 不进 executor）。GATE-04 在 GATE-03 选定后做。

2. **kakeibo Q4 prompt 的具体文案在 mock 阶段定到多细**
   - 已知:静态只读、价值观肯定框定（D-05/D-06）、calm-warm register（D-04）。
   - 不清楚:mock 用占位文案 vs 接近最终文案。
   - 建议:mock 用接近最终的中文 calm-warm 文案（便于 D-11 情感共鸣评判），但正式三语 ARB parity 留 Phase 47。

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| 浏览器（产 mock 截图） | GATE-02 视觉 UAT | ✓（任意现代浏览器） | — | — |
| `pubspec.lock`（读 fl_chart 版本） | GATE-04 校验 | ✓ | fl_chart 1.2.0 | — |
| Pencil MCP（`mcp__pencil__*`） | 选定后关键帧精细化 | ✓ **仅主 session** | — | HTML 已是主产物；Pencil 是可选增强，executor 无访问（claude-code#13898） |
| 17 widget 源码 | mock 复刻参照 | ✓ | — | — |

**Missing dependencies with no fallback:** 无。
**Missing dependencies with fallback:** Pencil 对 executor 不可用——fallback = 主 session 手动 / 或仅用 HTML（HTML 是 D-08 锁定的主产物，Pencil 仅选定后增强）。

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| 直方图柱标用 `Stack`+`DecoratedBox` 手工像素对齐 hack | fl_chart 1.2.0 原生 `BarChartRodData.label` | fl_chart 1.2.0（已在树内） | mock 可放心画柱顶标签；Phase 46 删 hack |
| Joy/¥ 密度（ADR-013） | `Σ joy_contribution` 累计（ADR-016 §2，supersede ADR-013） | 2026-05-19 | `joy_density_formatter` 已改为 `joy_cumulative_formatter`；mock 用累计值，**不得引入密度/每元快乐** |
| "收支总览/结余率" | "支出总览"（仅支出侧） | v1.8 REQUIREMENTS.md | 无收入录入路径；mock 不画结余率/收入（§1b 勘误 vs ARCHITECTURE.md） |

**Deprecated/outdated:**
- fl_chart "2.x 升级"（TOOL-V2-01）:**2.x 不存在**，1.2.0 是最新。backlog 项基于错误前提，已 retire as N/A。
- 密度/joyPerYen metric:已退役（ADR-016）；`grep density|joyPerYen lib/` == 0 是守护。

## Sources

### Primary (HIGH confidence)
- `pubspec.lock` — fl_chart **`1.2.0`** 实测 [VERIFIED 2026-06-15]
- `lib/features/analytics/presentation/widgets/` — 17 widget 实测清单 + LOC [VERIFIED]
- `lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart` — `Stack`+`DecoratedBox` hack 第 35-139 行 [VERIFIED]
- `lib/features/analytics/presentation/widgets/joy_headline_kpi_tile.dart` — `formatJoyCumulative`/`Σ joy_contribution` [VERIFIED]
- `test/widget/.../anti_toxicity_phase16_test.dart` — 锁定禁词列表 + `_sweepForbiddenSubstrings` 模板 [VERIFIED]
- `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` — 7 条 Forbidden Features [CITED]
- `docs/arch/03-adr/ADR-016_Joy_Metric_Visualization_Redesign.md` — §3 HomeHero 独占 target ring、§5 ambient vs discrete [CITED]
- `docs/arch/03-adr/ADR-019_Palette_Selection_v1_6.md` — light+dark hex 表 [CITED]
- `docs/arch/03-adr/ADR-017_Terminology_Unification_v1_5.md` — 生存/灵魂 grep-ban [CITED]
- `.planning/REQUIREMENTS.md` — GATE-01..04 + Out-of-Scope + 总览仅支出侧重构 [CITED]
- `.planning/phases/43-.../43-CONTEXT.md` — D-01..D-11 锁定决策 [CITED]

### Secondary (MEDIUM confidence)
- `.planning/research/ARCHITECTURE.md` — reuse 图种子（GATE-01 主种子）；其"结余率"字段被 REQUIREMENTS.md 范围收缩覆盖（§1b 勘误）
- `.planning/research/STACK.md` — fl_chart stay verdict、1.2.0 label/cornerRadius
- `.planning/research/PITFALLS.md` — 6 关键陷阱
- `.planning/research/FEATURES.md` — kakeibo Q4 非游戏化先例

## Metadata

**Confidence breakdown:**
- GATE-01 现状种子: **HIGH** — 17 widget + 已算字段 + 锁点文件全部实测
- GATE-02 mock 指南: **HIGH**（结构）/ MEDIUM（具体配比，Discretion 区）— 视觉元素映射自实测 widget
- GATE-04 fl_chart 事实: **HIGH** — `pubspec.lock` 实测 1.2.0 + STACK.md 主源确认
- 情感词表锚点: **HIGH**（现有禁词实测）/ MEDIUM（扩充候选，待 GATE-04 讨论锁定）
- 反游戏化映射: **HIGH** — 直接继承 ADR-012/016 条文

**Research date:** 2026-06-15
**Valid until:** 2026-07-15（稳定——ADR 契约恒久，fl_chart 无 2.x 在途；30 天）
