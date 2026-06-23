# Phase 43: HTML 设计探索关卡 (Design Gate — NO production code) - Context

**Gathered:** 2026-06-15
**Status:** Ready for planning

<domain>
## Phase Boundary

这是一个**硬性设计关卡**,只产出**决策文档与 HTML 设计稿**,不提交任何 Dart/生产代码。交付物:

1. **GATE-01** — 现状统计实现深研图(以 `.planning/research/ARCHITECTURE.md` 的 reuse 图为种子:13/15 可复用用例、`MonthlyReport` 已算字段、HomeHero 隔离与反毒性的结构性锁点)
2. **GATE-02** — ≥3 套 HTML 设计方向(本阶段定为 **5 套**),每套自带一张 ADR-012 自审表,把每个情感元素映射为 *ambient / 庆祝过去 (OK)* 还是 *目标 / 跨期对比 / 成就 (forbidden)*
3. **GATE-03** — 充分讨论后用户明确选定**恰好一套**;关卡出口 = 用户批准,且仓库无新增 Dart/生产代码
4. **GATE-04** — 针对选定方向:新 ADR 的 go/no-go、锁定供反毒性扫描使用的情感词表、每个图表 affordance 对 fl_chart 1.2.0 API 的逐项校验

**核心设计问题(本关卡要关闭):**「为自己花钱而开心」如何在 ADR-012 恒久反游戏化约束下表达。

**不在本阶段:** 任何生产代码、Drift 迁移、数据/用例补全(那是 Phase 44-47)。

</domain>

<decisions>
## Implementation Decisions

### 方向探索结构 (Direction Exploration Structure)
- **D-01:** 主差异轴 = **实用 ↔ 悦己 配比**。这次比较聚焦「天平往哪偏」以及悦己端如何表达。
- **D-02:** 产出 **5 套 mock**(超过 GATE-02 的 ≥3 下限),阵容由用户亲定:
  - **M1 实用主导** — 总览/趋势/分类下钻为骨架,悦己以最克制 ambient 呈现
  - **M2 均衡** — 实用与悦己并重
  - **M3 极简实用派** — 悦己主导,但克制、干净、近实用质感(悦己端最低"浓度")
  - **M4 温暖反思派** — 悦己主导,kakeibo Q4 反思 +「值得」肯定为情感核心
  - **M5 故事画报派** — 悦己主导,记忆故事/画报式呈现已花悦己(悦己端最高"浓度")
  - M3/M4/M5 是悦己主导端的三种"浓度"(从克制→浓墨);M1/M2 代表实用一侧。

### 悦己情感基调 (Joy Emotional Register)
- **D-03:** JOY-01「值得」肯定卡的**数字强度**(已花悦己金额 / `Σ joy_contribution`)在 M3/M4/M5 **各取不同强度探索**(用户:"各 mock 各试")。**硬约束:绝不成为 progress/target ring**——HomeHero 独占唯一 target ring(ADR-016 §3)。
- **D-04:** 情感措辞 register = **calm-warm 平静温暖**(像日记,克制、不外放、不打分)。这直接定调 GATE-04 要锁定的情感词表。
- **D-05:** kakeibo Q4 前瞻反思「下次如何让花钱更开心」**框定为价值观肯定(非目标)**,用户认可为 ADR-012-safe 的核心抓手(kakeibo 原生非游戏化先例)。

### JOY-04 持久化 (GATE-04 go/no-go)
- **D-06:** JOY-04 = **静态只读提示**(一句温柔提问 + 示例引导,不接受用户输入)。→ 不持久化 → **GATE-04 的 ADR go/no-go = 不需要新 ADR**;v1.8 保持**无 Drift 迁移、纯展示层**。
- **D-07:** 若未来里程碑要持久化用户自撰反思文本,存储机制留给届时的**新 ADR** 决定(non-Drift 优先以避开迁移/同步)。本里程碑不涉及。

### Mock 产出与评审 (Mock Production & Review)
- **D-08:** 媒介 = **自包含 HTML 为主体**(单文件内联 CSS,浏览器直开;executor 可产出、可版本控制、可截图 UAT);**选定一案后**再用 Pencil 精细化一两关键帧。⚠ **Pencil 步骤必须在主 session 由编排者手动完成**——本环境 Pencil MCP 无法落盘且 executor 子代理访问不到 `mcp__pencil__*`(claude-code#13898),不可交给执行子代理。
- **D-09:** 数据 = **真实感示例数据**(模拟一个家庭一个月账目:日常/悦己拆分、Top 分类、满足度分布、最佳悦己瞬间),让情感与密度读感准确。
- **D-10:** 评审覆盖 = **仅中文 + 浅色与深色**(5 mock × 2 theme = 10 视图;深色用 ADR-019 桜餅×若葉暖调验证)。三语 ARB parity 留到 Phase 47。
- **D-11:** 选定唯一一案的**首要评判标准** = **悦己情感共鸣 / 实用性 / ADR-012 安全度**(复用度/低成本为次要上下文,不进首要标准)。

### Claude's Discretion
- D-03 数字强度在 M3/M4/M5 之间的具体分配由设计阶段把握(用户授权"各 mock 各试")。
- mock 文件存放位置/命名(建议 `.planning/phases/43-html-design-gate-no-production-code/mocks/`)、GATE-04 fl_chart affordance 校验的逐图清单、GATE-01 现状深研图的章节粒度 — 由 researcher/planner 决定。

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 里程碑与需求 (锁定范围)
- `.planning/ROADMAP.md` — Phase 43 定义(GATE-01..04 success criteria)+ v1.8 里程碑(Phases 43-47)
- `.planning/REQUIREMENTS.md` — GATE-01..04 + OVW/TREND/DRILL/JOY/REDES/GUARD;**Out of Scope** 锁定(无收入/无结余率、无预算迁移、固定布局、Sankey 仅方向探索、滚动带延后)

### 研究(GATE-01 现状图的种子)
- `.planning/research/SUMMARY.md` — 综合;central design tension + reuse landscape
- `.planning/research/ARCHITECTURE.md` — reuse 图(13/15 用例可复用、`MonthlyReport` 已算字段、HomeHero 隔离 + 反毒性结构锁点)— **GATE-01 主要种子**
- `.planning/research/FEATURES.md` — table stakes / 差异化 / anti-features;kakeibo Q4 非游戏化先例
- `.planning/research/STACK.md` — fl_chart `^1.2.0` stay verdict;1.2.0 `label`/`cornerRadius` 已发布;**无 2.x**
- `.planning/research/PITFALLS.md` — 6 关键陷阱(反游戏化陷阱、隔离破坏、provider rebuild storm、fl_chart churn)

### ADR 约束(关卡核心红线)
- `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` — 反游戏化恒久契约:ambient `f(progress)→color` OK / 离散解锁·阈值·庆祝·目标·跨期对比 **禁止**
- `docs/arch/03-adr/ADR-016_Joy_Metric_Visualization_Redesign.md` — §3 HomeHero 独占唯一 target ring;§5 ambient-vs-discrete 线(JOY-01 自审依据)
- `docs/arch/03-adr/ADR-017_Terminology_Unification_v1_5.md` — 生存/灵魂 grep-ban(GATE-04 词表锁定 + i18n)
- `docs/arch/03-adr/ADR-019_Palette_Selection_v1_6.md` — 桜餅×若葉 light+dark 配色(深色 mock 取色)

### 现状实现(GATE-01 深研对象)
- `lib/features/analytics/presentation/screens/analytics_screen.dart` — 739 LOC 单体(待瘦身,Phase 45)
- `lib/features/analytics/presentation/widgets/` — 17 个现成 widget(donut/趋势柱/满足度直方图/各悦己卡)
- `lib/features/analytics/presentation/providers/` — `state_time_window` / `state_joy_metric_variant` / `state_ledger_snapshot` / `state_analytics` / `state_happiness` / `repository_providers`

### 结构锁点(不可破,GATE-02 自审 + GATE-04 词表的对照)
- `test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` — HomeHero 隔离
- `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart` + `anti_toxicity_phase17_test.dart` — 反毒性禁词扫描(GATE-04 锁定词表将扩充此扫描)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **17 个 analytics widget**(`category_spend_donut_chart` / `monthly_spend_trend_bar_chart` / `satisfaction_distribution_histogram` / `best_joy_story_strip` / `largest_expense_story_card` / `daily_vs_joy_card` / `joy_headline_kpi_tile` / `per_category_breakdown_card` / `family_insight_card` / `kpi_mini_hero_strip` / `total_spending_kpi_tile` / `time_window_chip` / `time_window_picker_sheet` / `joy_metric_variant_chip` 等)— **mock 多为重组这些既有元素,而非从零重画**。
- `GetMonthlyReportUseCase` 已算 `totalExpenses` + 日常/悦己拆分 + Top 分类;`Σ joy_contribution`(ADR-016)。总览/趋势是纯展示变换,零新增数据工作。
- **fl_chart `^1.2.0`** 原生 `BarChartRodData.label` + `PieChartSectionData.cornerRadius` 已可用(**无需升级/更换**;直方图旧 `Stack` hack 可由 1.2.0 `label` 取代)。

### Established Patterns
- 每卡 = `ConsumerWidget`,watch 唯一 provider family `(bookId, startDate, endDate, joyMetricVariant)`,本地 `.when(data/loading/error)`。
- `DateBoundaries`/`TimeWindow` 规范化窗口边界(避免 microsecond-exact provider rebuild storm)。
- 暖色 ambient 动效用 Flutter 内建(`TweenAnimationBuilder` count-up / `AnimatedSwitcher` / glow)——ADR-012-safe(value-affirming, 非 achievement-reward)。

### Integration Points
- 本阶段**零生产代码**——mock 是设计探索,不接代码。选定方向在 Phase 44(数据)→ 45(外壳)→ 46(卡片)落地。

</code_context>

<specifics>
## Specific Ideas

- **5-mock 阵容(用户亲定,见 D-02):** M1 实用主导 / M2 均衡 / M3 极简实用派 / M4 温暖反思派 / M5 故事画报派。
- **气质参照:** 像日记的平静温暖(calm-warm),不外放、不打分、不制造"分数感"。
- **数字处理:** JOY-01「值得」卡的金额在 M3/M4/M5 各取不同强度,验证哪种读感最对;但任何 mock 都不得把它做成 progress/target ring。
- **Pencil 用法:** 仅用于**选定一案后**精细化关键帧,且必须主 session 手动完成(执行子代理无 Pencil MCP)。

</specifics>

<deferred>
## Deferred Ideas

- **收入录入 / 真实结余率** — 无录入路径(唯一写入硬编码 `expense`),overview 仅支出侧;→ INCOME-V2-01
- **预算 vs 实际** — 需 `budgets` 表 + v21→v22 迁移,扩大范围;→ ANALYTICS-V2-03
- **可定制/可重排仪表盘** — v1.8 用固定(重设计)布局;→ ANALYTICS-V2-02
- **Sankey 收入→支出→结余流向图** — 无收入侧数据 + 无 native fl_chart 支持;**不进 5-mock 阵容**;→ ANALYTICS-V2-01
- **"about typical" 中性滚动带** — 贴近 ADR-012 #4 边界,需新 ADR 验证非评判框定;→ ANALYTICS-V2-04
- **分币种 analytics 小计** — 携带自 v1.7,除非重设计自然吸收;→ CUR-V2-02
- **JOY-04 用户自撰反思文本持久化** — 本里程碑静态只读;未来若做需新 ADR(加密/隐私)+ non-Drift 存储(D-07)

None — discussion stayed within phase scope(以上均为里程碑级已锁定的范围外项,记录以防丢失,非本次新增范围蔓延)。

</deferred>

---

*Phase: 43-html-design-gate-no-production-code*
*Context gathered: 2026-06-15*
