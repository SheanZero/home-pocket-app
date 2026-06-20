# Quick Task 260620-lfp: 按 round5/r5-drawer-joybar.html mock 重做统计页 - Context

**Gathered:** 2026-06-20
**Status:** Ready for research → planning
**Mode:** --full (discuss + research + plan-check + verify)

<domain>
## Task Boundary

按照 `.planning/phases/43-html-design-gate-no-production-code/mocks/round5/r5-drawer-joybar.html`
mock 重新实现**整个统计页面**（`AnalyticsScreen` + 各分类卡片），做到视觉与结构**和 mock 一致**。
唯一例外：**保留现有的支出趋势图**（`WithinMonthTrendCard` / `WithinMonthCumulativeLineChart`，
刚经过 round-3 打磨，不动其内部实现）——只让它落到新的「支出趋势 · 实用」节标题之下。

**Scope = 支出侧统计页（presentation only）。** 不动 domain models / repositories / providers 的
数据契约；现有 5 卡 lineup（trend → category_donut → joy_spend → joy_calendar →
satisfaction_histogram + group-only family_insight）的**数据来源保持不变**——本任务是
**视觉保真 + 结构重排**，不是重写数据层。
</domain>

<decisions>
## Implementation Decisions (LOCKED — do not revisit)

### D1. 严格度 = --full
用户选定 `--full`：discussion + research + plan-check (≤2) + post-exec verification。
理由：整页保真重做、逆转既有锁定决策、会打破大量 golden master，需要校验闸防止再次「差距太大」。

### D2. 结构 = 完全对齐 mock（逆转 D-F2 的「扁平无节标题」设计）
mock 有 **4 个节标题**（`.sect-h`），当前 `AnalyticsScreen` 在 Phase 46 D-F2 **刻意删除了**所有节标题。
本任务**重新加回**节标题，并把悦己堆叠条**内嵌**进分类支出卡：

1. **重新加回 4 个节标题**（带 实用/悦己 tag chip）：
   - `支出趋势` · tag「实用」（绿，`.sect-h.prac`）→ 趋势卡
   - `分类支出` · tag「实用」（绿）→ 分类环 hero（内含悦己抽屉）
   - `小确幸日历` · tag「悦己」（樱粉，`.sect-h.joy`）→ 日历热力卡
   - `悦己满足度分布` · tag「悦己」（樱粉）→ 满足度直方图卡
   节标题样式：3px 左竖条（prac=primary 绿 / joy=joy 樱粉）+ 12px 字重 600 letter-spacing 标题
   + 右侧 tag chip（prac=dailyText/dailyLight，joy=joyText/joyLight）。

2. **悦己堆叠条内嵌为分类支出卡的「抽屉」**：mock 把 `悦己花在哪` 横向堆叠分段条（joybar）
   放在分类环 hero **内部**，经一个连接器 chip「▾ 把悦己这一块放大看看」从环引出，
   下接 `.drawer`（樱粉边框卡）含 joybar + 单列图例 + 脚注。
   当前 `JoySpendCard` 是**独立卡片（#3）**——本任务把它**移入** `CategoryDonutCard` 的 hero 之内
   （作为 connector + drawer），不再作为顶层独立卡。lineup 从 5 顶层卡 → 4 节
   （趋势 / 分类支出[含悦己抽屉] / 小确幸日历 / 满足度分布）+ group-only family_insight。

### D3. 趋势图保持现状
`WithinMonthTrendCard` 内部（pill-tab 总支出/日常/悦己、本月实线+上月虚线、悦己单线零跨期、
X 轴、终点标注等）**逐字保留**，round-3 打磨成果不回退。只是外面包一层「支出趋势 · 实用」节标题。

### D4. 数据用真实 provider，不 hardcode mock 数字
mock 里的 ¥248,600 / ¥47,200 / 86 笔 / 各分类金额 / 日历热力 / 直方图计数 **全是 SIMULATED 示例**，
仅作版式参照。生产实现**继续从现有 provider 取真实聚合数据**（monthlyReport / happinessReport /
L1 rollup 等）。绝不把示例数字写死进 widget。

### D5. 颜色走 AppPalette / context.palette（ADR-019），不 hardcode hex
mock 的 chrome 色对应已有 palette token：bg `#FBF7F4` / primary·daily `#6FA36F`·`#5FAE72` /
dailyText `#2E6B3A` / joy 樱粉 `#D98CA0` / joyText `#A53D5E` / shared `#5B8AC4` / borders `#E6DDD8`。
**用 `context.palette.*` 解析，禁止裸 hex。** 例外：悦己 7 色暖调色板（joybar 分段 j1–j7：樱粉/琥珀金/
珊瑚赤陶/梅紫藕/桃沙/暖灰褐/藕灰玫）是 joybar 专属调色板——沿用现有 `JoySpendStackedBar` 已有的色板
（若已存在则不动；确认 7 色色相分离、避开绿/蓝语义色）。

### D6. Golden 重基线 + 全量测试
整页重排会打破大量 golden master。按既有流程在 **macOS** 上重新基线受影响的 golden
（CI 用 BaselineExistenceGoldenComparator，禁止在非 macOS 重基线）。
执行后跑**全量** `flutter test`（含 architecture 测试如 hardcoded_cjk_ui_scan / 节标题文案走 l10n）。

### D7. i18n：节标题 + tag 文案走 ARB（ja/zh/en 全更新）
4 个节标题文案 + 「实用」「悦己」tag 文案 = 新 UI 文本，**必须**经 `S.of(context)`，
三份 ARB（ja 默认 / zh / en）同步新增后 `flutter gen-l10n`。禁止硬编码中文/日文/英文串。

### Claude's Discretion
- 具体 widget 文件拆分（节标题做成共享 `AnalyticsSectionHeader` widget vs 内联）由 planner 定；
  倾向抽一个小的 `AnalyticsSectionHeader`（3px 竖条 + 标题 + tag）复用 4 处。
- joybar 内嵌后 `JoySpendCard` 文件是否保留/改造由 planner 定（保留其 provider 接线，外壳改为
  「在 CategoryDonutCard 内渲染 connector+drawer」）。
- ja/en 节标题与 tag 的具体译法由 executor 拟定合理值（ja 优先，遵守现有 ARB 风格）。
- ADR-012 反游戏化约束：悦己侧零跨期/零目标环/零排名/零连续打卡/零成就框定——沿用 mock 的中性框定语。
</decisions>

<specifics>
## Specific References

- **Mock（唯一保真基准）：** `.planning/phases/43-html-design-gate-no-production-code/mocks/round5/r5-drawer-joybar.html`
  - 节序：① 支出趋势(实用) ② 分类支出(实用，含悦己抽屉) ③ 小确幸日历(悦己) ④ 悦己满足度分布(悦己)
  - 分类环：level-1 扁平、按金额降序、10 项、中心只显示总计 + 中性标签「本月支出」，**无**日常/悦己拆分线
  - 悦己抽屉：joybar 7 段（flex-grow=金额）+ 单列图例（色块+类名+¥+%，largest→smallest）+ 中性脚注
  - 小确幸日历：7 列网格热力（heat0–3 深浅=当天悦己笔数，非连续天数），底部图例 + 中性说明
  - 满足度直方图：1–10 分柱状 + 中位满足度 pill + 文案
- **当前实现：**
  - `lib/features/analytics/presentation/screens/analytics_screen.dart`（thin shell，渲染 registry）
  - `lib/features/analytics/presentation/analytics_card_registry.dart`（render order 单源）
  - cards：`within_month_trend_card` / `category_donut_card` / `joy_spend_card` /
    `joy_calendar_card` / `satisfaction_histogram_card` / `family_insight_data_card`
  - 子 widget：`category_spend_donut_chart` / `joy_spend_stacked_bar` / `joy_calendar_heatmap` /
    `satisfaction_distribution_histogram` / `within_month_cumulative_line_chart`
</specifics>

<canonical_refs>
## Canonical References

- **ADR-019** 桜餅×若葉 v1.6 palette（节标题/卡 chrome 配色权威）：`docs/arch/03-adr/ADR-019_Palette_Selection_v1_6.md`
- **ADR-012** 反游戏化（悦己侧约束）
- **CLAUDE.md** i18n Rules（S.of / 三份 ARB / gen-l10n）、Amount Display Style（AppTextStyles.amount*）、
  App Color Scheme（context.palette）
- **Phase 43** mock 集（round5 为本任务基准；round4 是其派生源）
- **Memory:** golden-ci-platform-gate（仅 macOS 重基线）、analytics-transaction-type-reuse-trap（expense-only 过滤）
</canonical_refs>
