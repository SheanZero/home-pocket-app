# Phase 46: 卡片体系 (Cards) - Context

**Gathered:** 2026-06-17
**Status:** Ready for planning

<domain>
## Phase Boundary

在 Phase 45 的瘦外壳 + 卡片注册表契约就绪后，**逐卡构建/迁移已批准的 round-5 B 设计**——把现有内联卡阵容重排/增删为 GATE-03 选定方向，全程反游戏化（ADR-012）。这是 v1.8「45 立机制 → **46 填内容** → 47 验视觉」的填充阶段。

**元决策（贯穿全阶段，D-A1）：round-5 B（`selected/*.html`）为唯一真相。** 凡已批准 mock 与 ROADMAP/REQUIREMENTS 字面冲突，以 mock 为准，并补正需求台账（D-A2）。

**已批准的 round-5 B 最终阵容 = 恰好 5 张卡**（扁平叙事流，无分区头）：
1. **支出趋势**（top，pill tabs 总支出 / 日常 / 悦己）—— **当月内按天累计** LineChart，支出侧本月+上月双线、悦己侧本月单线
2. **支出分类圆环 hero（donut）**—— 中心「本月支出」，10 个 L1 金额降序图例，图例行 tap → 下钻
3. **悦己花在哪 横向堆叠分段条**—— 悦己金额在 L1 严格子集间构成，单列图例
4. **小确幸日历热力**—— 月历网格色深 = 当天悦己笔数，tap 某天 inline 展开
5. **悦己满足度分布直方图**—— 频次分布 + 中位

**不在本阶段：** 数据/用例的「应有」补全（Phase 44 已建大部，但趋势数据形态不符——见 D-E2，本阶段须补）；i18n ARB parity / 反毒性禁词扫描扩充 / macOS golden 从零撰写+重基线 / 全量门禁 / 真机 UAT（Phase 47）；JOY-03 记忆故事 / JOY-04 kakeibo Q4（随设计门 drop，D-A1）；收入/结余率/预算/Sankey/可定制仪表盘（里程碑外）。

</domain>

<decisions>
## Implementation Decisions

### A. 卡片阵容对账（核心交付边界）
- **D-A1:** **round-5 B 为唯一真相 —— 严格只建 5 卡。** JOY-01「已花悦己」+ JOY-02「满足度/分类悦己」视为**已由设计重新承载**（已花悦己金额在悦己 tab+悦己花在哪；满足度在直方图；分类悦己在悦己花在哪堆叠条），不另画独立「值得」headline 卡。JOY-03「记忆故事」+ JOY-04「kakeibo Q4 反思」**随 round-5 B drop，零加回**（与 round2→round5 取舍一致；最终选定 mock 经 grep 确认 0 命中此三者）。
- **D-A2:** **Phase 46 含需求台账补正 doc 任务**——把 `REQUIREMENTS.md` 的 JOY-03 / JOY-04 标为 **Descoped（superseded by GATE-03 round-5 B）**，并把 `ROADMAP.md` Phase 46 success criteria **#3 重写**为 round-5 B 实际 5 卡阵容。目的：使 gsd-verifier 的 goal-backward 与已批准设计一致，不误报未达成。
- **D-A3:** **彻底删除 round-5 B 不含的旧卡**——`best_joy_card.dart`（JOY-03）/ `kpi_hero_card.dart` / `largest_expense_card.dart` 及其**唯一专属** widget / provider / ARB key（用 `find_referencing_symbols` 逐个确认无他用后删）。死代码零残留（CLAUDE.md dead-code/immutability 规则）。golden 重基线入 Phase 47。**`family_insight_data_card` 不在删除名单**（见 D-F1）。`total_six_month_card.dart`（趋势）由新 within-month line card 替换（D-E1）。
- **D-A4:** **ADR-016 Joy 指标（Σ joy_contribution）保持 HomeHero 独占**，analytics 卡**零展示**。JOY-01 以「已花悦己金额」承载即满足；analytics 不复制 target ring / joy-index（ADR-016 §3）。

### B. 分类下钻落地（结转 Phase 44 D-01..06 + Phase 45 D-C1/C2）
- **D-B1:** **入口 = donut 下方 10 行 level-1 图例「整行可点」** → push GoRouter route（形态 Phase 45 D-C1 已锁：独立页、传 `l1CategoryId`、时间窗走 keepAlive session state 无需穿线）。**不**点圆环扇区（扇区小/悦己弧窄/a11y 弱）。
- **D-B2:** **下钻页顶部小结 = 小计 + 笔数 + 日均**（三个中性描述量；日均 = 该窗口此分类总额/天数，纯描述非目标线/达标率）。严格 ADR-012-safe：无目标、无跨期、无排名、无评判措辞。
- **D-B3:** **下钻交易列表 = 只读**——复用 `ListTransactionTile` 视觉，但**禁用 swipe-删除 + tap-编辑**。analytics 下钻是描述性「看钱花哪了」；写操作回列表/录入 tab，避免误删 + 多 provider 失效复杂度。
- 数据层 **Phase 44 已建**：`CategoryDrillDown`（transactions + subtotal + count，可选 avgPerDay）+ `GetCategoryDrillDownUseCase`，走既有 `findByBookIds`，drill family `(bookIds, startDate, endDate, l1CategoryId)` auto-dispose；点 L1 → 平铺该 L1（含全部 L2）当前窗口全部交易（D-02，无 L1→L2 中间层）。

### C. 两张新自定义卡的交互
- **D-C1:** **小确幸日历热力**＝自定义 `GridView`/`Wrap` 月历网格色深网格（**R-2，非 fl_chart**），色深 = `f(当天悦己笔数)` ambient（显式非 streak，ADR-016 §5）。**可交互**：tap 某天 → **inline 就地展开**当天悦己一刻列表（**非** sheet/route；日历卡就地变高）。
- **D-C2:** **悦己花在哪 横向堆叠分段条**＝自定义 `Row` + `Flexible(flex)` 分段（**R-1，非 fl_chart**，largest→smallest）+ 单列图例（已含 ¥ + %）。**轻交互**：tap 某段 → **就地高亮**该段 + 同步高亮对应图例行（放大标签/¥+%）。**零新数据路径、ADR-012-safe 纯描述、不下钻**（悦己过滤下钻 = 第二条新只读路径，超 DRILL-01 上限 → 未来阶段）。

### D. 暖色动效（REDES-03）
- **D-D1:** **强度 = 克制微动**——仅入场一次性轻动效（卡片淡入），**无循环、无 glow 脉冲、无庆祝爆发**。贴 calm-warm 基调（Phase 43 D-04）+ ADR-012（ambient value-affirming，非 achievement-reward）。
- **D-D2:** **count-up 落点 = 仅两个锚点数字**——donut 中心「本月支出」总额 + 悦己花在哪 header「悦己 ¥…」总额，`TweenAnimationBuilder` ~400–600ms。其余主数字（趋势/满足度/图例）静态。

### E. 趋势卡形态（已批准设计 vs 已交付数据冲突 —— 重大）
- **D-E1:** **忠于 round-5 B 形态**——支出趋势 = 当月内「**按天累计**支出」`LineChart`：支出侧（总支出 / 日常 tab）本月（实线）+ 上月（虚线）**双线同尺度参照**；**悦己 tab = 本月单线、无上月线、无跨期**（D-09 + GATE-04 #4）。「本月 vs 上月」中性标签，仅支出侧（ADR-012 §4 记录在案例外，已 `## Update` 补正）。
- **D-E2:** ⚠ **Phase 44 趋势交付不匹配，Phase 46 须补。** Phase 44 D-08/D-09 建的是 **6 月滚动月总计**（`MonthlyTrend` per-month + dailyTotal/joyTotal）+ **BarChart**（`monthly_spend_trend_bar_chart.dart`），并把「本月vs上月」当作 6 月序列上的 framing。但 round-5 B 需的是 **per-DAY 累计**（本月 + 上月，per-ledger 总/日常/悦己）+ **新 LineChart widget**——现有 BarChart 不渲染此形态。**Phase 46 须新增 per-day-cumulative 数据路径 + 新 line widget。** Phase 44 的 6 月 MonthlyTrend 扩展本卡不用（去留交 researcher 核实，见 Research flags）。

### F. IA / 卡序 / 组模式
- **D-F1:** **`family_insight_data_card` 保留为 group-mode-only 条件卡**（Phase 45 D-B4 `isVisible(ctx)` 谓词），追在 5 卡之后。GUARD-02 要 `FamilyHappiness` 保持 aggregate-only → 该聚合面存续。**不在 D-A3 删除名单。**
- **D-F2:** **扁平 round-5 B 顺序** = 趋势(top) → donut hero → 悦己花在哪 → 小确幸日历 → 满足度直方图 → [family_insight 组模式条件卡]。**删 Phase 45 的 Time/Distribution/Stories 分区头**（及其 widget `analytics_screen_section_header.dart`，随 D-A3 彻底删除）。仅注册表 list 重排 + isVisible（机制 Phase 45 已立，不再触 shell 机制）。

### Claude's Discretion
- 下钻列表只读的实现（禁用 tile 回调 vs `ListTransactionTile` 只读变体）—— planner。
- 下钻交易排序（金额降序 vs 时间倒序）—— planner（D-B2 已定含日均）。
- per-day-cumulative 趋势取数位置（repo 新 thin method vs use case 内 `findByBookIds` 2-月窗 + Dart 侧 per-day cumulative）—— researcher/planner（无迁移、reuse-first）。
- 小确幸日历 inline-展开的高度/动画处理、悦己段高亮的视觉手法、count-up 曲线 —— planner。
- 自定义 widget（日历 GridView 色深 / 悦己 Row+Flexible / 趋势 LineChart）的文件拆分、命名（ADR-017 生存/灵魂 grep-ban）—— planner。
- 注册表条目增删形态（abstract base vs spec-list，Phase 45 已立机制）—— planner。

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 里程碑与需求（锁定范围 + 本阶段台账补正对象）
- `.planning/ROADMAP.md` — Phase 46 定义（OVW-02 / JOY-01..04 / REDES-02..03 / GUARD-02 success criteria）。**SC #3 须随 D-A2 重写**为 round-5 B 实际 5 卡阵容（drop JOY-03/04）
- `.planning/REQUIREMENTS.md` — OVW-02 / JOY-01..04 / REDES-02/03 / GUARD-02 全文 + Out of Scope。**JOY-03 / JOY-04 须随 D-A2 标 Descoped（superseded by GATE-03）**

### 已批准设计（本阶段视觉契约 = 唯一真相，D-A1）
- `.planning/phases/43-html-design-gate-no-production-code/mocks/selected/selected-light.html` / `selected-dark.html` — round-5 B 浅/深定稿（卡阵容/顺序/文案/配色的逐像素依据）
- `.planning/phases/43-html-design-gate-no-production-code/mocks/selected/README.md` — 5 卡阵容 + 悦己子类严格子集数据修正 + 跨期例外
- `.planning/phases/43-html-design-gate-no-production-code/mocks/selected/selected-adr012-audit.md` — 逐元素 ADR-012 自审 PASS + 跨期例外
- `.planning/phases/43-html-design-gate-no-production-code/GATE-03-direction-selection.md` — 选定 round-5 B（用户 approved）+ 一句话设计描述
- `.planning/phases/43-html-design-gate-no-production-code/GATE-04-flchart-affordance-verification.md` — 逐图 fl_chart 1.2.0 校验：donut/histogram/trend-line 原生 ✅；悦己横条 **R-1**（自定义 `Row`，非 fl_chart）；小确幸日历 **R-2**（自定义 `GridView`，非 fl_chart）
- `.planning/phases/43-html-design-gate-no-production-code/GATE-04-emotion-wordlist.md` — 锁定情感词表（反毒性扫描 + 新卡文案对照）
- `.planning/phases/43-html-design-gate-no-production-code/mocks/round2/ROUND2-DECISION.md` — 支出侧跨期例外的记录在案来源（三处岔口表 · 第 1 行）

### 上游契约（数据 + 外壳）
- `.planning/phases/44-data-use-case-additions-reuse-first/44-CONTEXT.md` — 数据层契约：下钻 `CategoryDrillDown`(D-01..06, auto-dispose, 只读)、总览纯变换(D-10)、donut L1 rollup 共享 helper(D-11)；**趋势 D-08/D-09 = 6 月滚动（与 round-5 B 当月日累计形态不符，见 D-E2）**；Research flags §（小确幸日历 per-day 悦己数据归属、窗口取数索引核查）
- `.planning/phases/45-presentation-shell-rebuild/45-CONTEXT.md` — 卡片注册表契约（D-B1..B5：typed 注册表驱动渲染顺序+refresh 并集、`refreshTargets(ctx)`、结构断言 ⊆ analytics 零 home/*、`isVisible(ctx)` 条件卡）；下钻形态 D-C1（pushed route）/ D-C2（落地全在 46）；ADR-012 §4 支出侧跨期例外已 `## Update` 补正（D-D1）

### ADR 红线
- `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` — 反游戏化恒久契约（含已 append 的支出侧跨期 §4 例外）。悦己侧 **zero** 跨期/目标/进度环/排名/streak/成就。每张新卡须扫描-ready（反毒性禁词，GUARD-02；扫描扩充本体在 Phase 47）
- `docs/arch/03-adr/ADR-016_Joy_Metric_Visualization_Redesign.md` — §3 HomeHero 独占唯一 target ring（analytics 不复制，D-A4）；§5 ambient-vs-discrete 线（日历色深/悦己堆叠条自审依据）
- `docs/arch/03-adr/ADR-017_Terminology_Unification_v1_5.md` — 生存/灵魂 grep-ban（新卡 + widget + cards/ 文件命名）
- `docs/arch/03-adr/ADR-019_Palette_Selection_v1_6.md` — 桜餅×若葉 light+dark hex（新卡 + 悦己 6 色相 + 日历色深取色）

### 现状源码（重建 / 删除 / 复用对象）
- `lib/features/analytics/presentation/screens/analytics_screen.dart` — Phase 45 瘦外壳（176 LOC）；本阶段改注册表 list + 删分区头
- `lib/features/analytics/presentation/analytics_card_registry.dart` — Phase 45 新建；渲染顺序 + refresh 失效并集单一来源；本阶段重排 + 增删条目
- `lib/features/analytics/presentation/widgets/cards/` — 8 文件：**删** `best_joy_card`/`kpi_hero_card`/`largest_expense_card`；**重建** `category_donut_card`（hero + 图例行 tap drill）/ `satisfaction_histogram_card`（REDES-02 删 Stack hack 用原生 `BarChartRodData.label`）；趋势 `total_six_month_card` → 新 within-month line card 替换；**保留** `family_insight_data_card`（条件卡）/ `analytics_data_card`（共享壳）
- `lib/features/analytics/presentation/widgets/monthly_spend_trend_bar_chart.dart` — 现 6 月 BarChart（不渲染 round-5 B 当月日累计线 → **新 line widget**）
- `lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart` — 现 `Stack`+`Align`+`DecoratedBox` hack（REDES-02 删，用原生 label）
- `lib/features/analytics/presentation/widgets/analytics_screen_section_header.dart` — 随 D-F2 删
- `lib/application/analytics/get_expense_trend_use_case.dart` + `lib/features/analytics/domain/models/expense_trend.dart` — 6 月 `MonthlyTrend`（本卡形态不用，researcher 核实去留）
- `lib/features/list/presentation/widgets/list_transaction_tile.dart` — 下钻只读复用
- `lib/features/analytics/presentation/providers/` — `state_analytics` / `state_happiness` / `state_time_window` / `state_joy_metric_variant` / `state_ledger_snapshot` / `repository_providers`
- `lib/shared/utils/date_boundaries.dart` — 窗口规范化（family key 不漂移，D-12）

### 结构锁点（测试断言，不可破）
- `test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` — HomeHero 隔离（GUARD-01/02 延续）保绿
- `test/widget/features/analytics/presentation/analytics_card_registry_test.dart` — 注册表失效并集 ⊆ analytics、零 `home/*`（Phase 45）；重排后保绿
- `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart` + `anti_toxicity_phase17_test.dart` — 反毒性禁词扫描；新卡文案须扫描-ready（扫描扩充本体 Phase 47，GUARD-02）

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **注册表机制（Phase 45 D-B1..B5）已立** —— 本阶段是「重排 list + 换条目 + isVisible」非重写机制；HomeHero 隔离由构造保证。
- **fl_chart `^1.2.0` 原生**：`PieChartSectionData.cornerRadius`（donut 圆角）、`BarChartRodData.label`（直方图删 Stack hack）、`LineChart` 多系列（趋势本月+上月双线）。**不升级/不换库。**
- **`ListTransactionTile`（v1.4）** —— 下钻只读复用（禁回调）。
- **`TweenAnimationBuilder` / `AnimatedSwitcher`（Flutter 内建）** —— 暖色 count-up，ADR-012-safe（value-affirming 非 achievement-reward）。
- **L1 rollup 共享 pure helper（Phase 44 D-11）** —— donut 卡 + 下钻小结复用同源。

### Established Patterns
- 每卡 = `ConsumerWidget` watch 唯一 provider family；本地 `.when(data/loading/error)`；family key 先经 `DateBoundaries`/`TimeWindow` 规范化（避免 microsecond rebuild storm，D-12）。
- analytics provider 全 **auto-dispose**；零 `home/*` 共享（GUARD-01/02）。
- 自定义非-fl_chart widget（日历 `GridView` 色深、悦己 `Row`+`Flexible` 分段）—— ambient `f(value)→color`，ADR-012-safe（R-1/R-2 已预案，低风险无新依赖）。

### Integration Points
- 新 widgets 进 `widgets/`（趋势 line / 日历 calendar / 悦己 stacked-bar），卡进 `widgets/cards/`，注册表重排。
- donut 图例行 tap → **新 GoRouter route**（触 router config）→ drill page（新 screen）。
- 小确幸日历 tap-day inline 展开 → 需 **per-day 悦己交易数据**（Research flag）。
- 趋势 → 需 **per-day-cumulative 数据**（本月 + 上月，per-ledger）+ 新 line widget（D-E2，Research flag）。

### Research flags（给 gsd-phase-researcher）
1. **趋势 per-day-cumulative 数据（D-E2，高优先）：** round-5 B 需「当月内按天累计」本月+上月 per-ledger（总/日常/悦己）。核实能否由既有 `findByBookIds(bookIds, startDate, endDate)`（2-月窗）+ Dart 侧 per-day cumulative + per-ledger 拆分廉价得出（reuse-first、无迁移）；并裁定 Phase 44 的 6 月 `MonthlyTrend` 扩展（`dailyTotal`/`joyTotal`）是否仍有他用或清理。
2. **小确幸日历 per-day 悦己数据（D-C1）：** 热力 + tap-day inline 均需 per-day **悦己（joy-ledger）**交易/笔数；Phase 44 Research flag 已记现有 `getDailyTotals` 无 ledger 过滤。核实现有 joy 数据能否覆盖（呈现层过滤优先，无新 use case），还是需一条 thin per-day-joy 取数（若需，厘清是否触及 DRILL-01 的 scope 锁——category 路径是「那一条」允许，per-day-joy 是不同关注点，须明确裁定）。
3. **窗口取数索引（Phase 44 D-06）：** 确认 `findByBookIds` 的 `(book_id, timestamp)` 范围查询已有索引（下钻 + 趋势 + 日历均依赖）；**不**新增 `(book_id, category_id, timestamp)`。

</code_context>

<specifics>
## Specific Ideas

- **「round-5 B 为唯一真相」是本阶段元决策**：mock 与 ROADMAP/REQUIREMENTS 字面冲突时以 `selected/*.html` 为准 + 补正台账（D-A2）。最终 5 卡经 grep 确认无「值得卡/记忆故事/kakeibo」。
- **悦己侧 = calm-warm 描述性「庆祝过去」**：绝不打分/目标/排名/streak/跨期。已花悦己金额 + 去向（悦己花在哪）+ 满足度 + 日历纹理是「为自己花钱而开心」的 ADR-012-safe 表达。
- **趋势是唯一跨期面，且仅支出侧**（总/日常 本月vs上月，中性标签）；悦己 tab 单线无跨期 —— 严守红线。
- **用户主动选择两张新卡可交互**（日历 tap-day **inline 展开**、悦己段 tap **就地高亮**），覆盖我「纯 ambient 只读」的初始推荐；日历 tap-day 接受其新数据路径成本（已记 Research flag）。

</specifics>

<deferred>
## Deferred Ideas

- **JOY-03 记忆故事卡（best joy moment）/ JOY-04 kakeibo Q4 反思 prompt** —— 随 round-5 B drop，标 Descoped（superseded by GATE-03）。若未来里程碑要做，JOY-04 持久化用户自撰文本需新 ADR + non-Drift 存储（43 D-07）。
- **悦己过滤的分类下钻**（tap 悦己段 → 仅该子类悦己交易）—— 需第二条新只读路径，超 DRILL-01 上限；未来阶段。
- **小确幸日历 tap-day 若需新 per-day-joy 数据路径** —— 若 researcher 判定确需且触及 scope 锁，则该数据工作的归属（Phase 46 内补 vs 未来阶段）于 planning 复议。
- **Phase 44 的 6 月滚动 `MonthlyTrend` 扩展**（dailyTotal/joyTotal）若本卡不用 —— researcher 核实他用或清理（不在本 discuss 决定删）。
- **i18n ARB parity / 反毒性禁词扫描扩充 / macOS golden 从零撰写+重基线 / 全量门禁 / 真机 UAT** —— Phase 47（GUARD-03/04/05）。
- **收入/真实结余率**(INCOME-V2-01)、**预算 vs 实际**(ANALYTICS-V2-03)、**可定制仪表盘**(ANALYTICS-V2-02)、**Sankey**(ANALYTICS-V2-01)、**"about typical" 中性滚动带**(ANALYTICS-V2-04)、**分币种 analytics 小计**(CUR-V2-02)、**fl_chart 1.x→2.x**(TOOL-V2-01) —— 里程碑外。

None new beyond milestone-locked scope —— 以上均为设计门 drop 项 / 后续阶段项 / 里程碑外项，记录以防丢失。

</deferred>

---

*Phase: 46-cards*
*Context gathered: 2026-06-17*
