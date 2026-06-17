# Phase 47: i18n + 反毒性扫描 + macOS golden 重基线 + 全量门禁 + UAT - Context

**Gathered:** 2026-06-17
**Status:** Ready for planning

<domain>
## Phase Boundary

v1.8 的**验证收尾阶段**——不新增功能，对 Phase 46 已上线的 round-5 B 五卡统计页做「验真」：

1. **GUARD-03 i18n** — 所有新文案 ja/zh/en 三语 ARB parity，`flutter gen-l10n` 干净，生存/灵魂 grep-ban green（ADR-017）
2. **GUARD-02 措辞层 + GUARD-03** — 每张新/改卡加入 `anti_toxicity_*_test` 禁词扫描，禁词在 3 语 × 全状态 `findsNothing`
3. **GUARD-04 golden + gate** — 在 **macOS** 上从零撰写/重基线 analytics chart golden（今天零覆盖），diff 归因清晰（无图表库变更混入），全量 `flutter test` 作逐波门禁（含 `home_screen_isolation_test` + 两个反毒性扫描 + 架构/CJK 扫描）
4. **GUARD-05 UAT** — 重设计后统计页通过真机视觉 UAT

**附带**（本阶段拍板纳入）：Phase 46 代码评审遗留的 4 个 warning（WR-01..04）在 UAT 前全部修复——因为 UAT 在本阶段进行，用户可见的边角缺陷必须先修。

**不在本阶段：** 任何新功能/新卡/新数据路径；schema 迁移（停 v21）；fl_chart 升级（停 `^1.2.0`）；性能优化超出 WR-03 单遍重构之外的部分；收入捕获（INCOME-V2-01）。
</domain>

<decisions>
## Implementation Decisions

### WR 修复取舍（Phase 46 评审遗留，全部 UAT 前修）
- **D-01:** 4 个 warning 全部折进 Phase 47，**在真机 UAT 之前修复**（不丢 backlog）。理由：UAT 在本阶段做，用户可见缺陷应先修，避免在 buggy-edge 卡上做视觉验收。
- **D-02 (WR-01 金额币种):** **删除** `AnalyticsCardContext.currencyCode` dead 字段（而非接线）。v1 唯一写入路径恒按日元入账、`amount` 列恒为 JPY、`Book.currency` 无非 JPY 设置入口——分类卡（donut/joy-spend/calendar/drill）显式 JPY-only，移除死接线以免暗示不存在的多币种 analytics 支持。
- **D-03 (WR-02 圆环对账):** 加一个中性「その他/其他/Other」rollup 切片，把 top-10 之外的长尾收进去。圆环**中心保留真·全类目总额**，slices + 图例 % 全部对账到真总额。当月 >10 个 L1 分类有支出时中心数与切片不再背离。「Other」措辞须中性、过反毒性扫描。
- **D-04 (WR-03 性能):** `GetJoyCategoryAmountsUseCase` **重构为单遍**按 L1 聚合，消除 O(n·k) 的 k-pass 重扫，并修正谎称「single pass」的 docstring。
- **D-05 (WR-04 刷新一致性):** `joyDayTransactionsProvider` 加入 `joyCalendarRefreshTargets`，下拉刷新时展开日的 inline 列表随热力 count 一并失效重算（消除残留已删行的状态不一致）。

### Golden 覆盖广度（GUARD-04）
- **D-06:** **全矩阵** ja/zh/en × light/dark per 新卡（≈ 5 卡 × 6 = 30+ master），延续 v1.5（77 master）/ v1.6（54 master）惯例。
- **D-07:** **per-card golden 为主**（与 46 的卡体系一致，diff 归因清晰、单卡改动不污染别卡）+ **1 张整页 `AnalyticsScreen` scroll smoke** golden 验证卡序。
- **D-08:** 除默认态外，额外覆盖：① 新 `CategoryDrillDownScreen` 只读列表；② 小确幸日历 inline 展开态（`_InlineDayPanel`，正是 WR-04 修复处）；③ group-mode `family_insight` 条件卡（GUARD-02 聚合面存续）；④ 各卡 empty/初始态。
- **D-09:** 所有 golden 仅在 **macOS** 基线（CI ubuntu 经 `test/flutter_test_config.dart` 走 `BaselineExistenceGoldenComparator`，非像素匹配）。count-up（`TweenAnimationBuilder`）golden 必须 pump 过动画到 settled 末态。固定样本数据复用 43-01 的 shared sample-data 以保 golden 确定性。

### 真机 UAT（GUARD-05）
- **D-10:** **全面核验清单**（逐项勾选）：5 卡渲染 + count-up 动效（donut 中心 + 悦己 header 两处锚点）+ 圆环整行下钻 + 日历 inline 展开 + WR-02/WR-04 修复可见 + 暗色 + 三语切换 + 组模式家庭卡。
- **D-11:** 主验证环境 = **真机 iOS + locale=ja**（app 默认 locale，真实字体/渲染/手势），zh/en 抽检。
- **D-12:** **UAT 失败项阻断 v1.8 里程碑收尾**——v1.8 是视觉重设计，UAT 是核心验收而非边角，失败项必须修复/重验才能关里程碑，**不走** acknowledged-deferred（区别于 v1.1/v1.5 的 human_needed 历史模式）。

### 反毒性扫描覆盖（GUARD-02 措辞层 + GUARD-03）
- **D-13:** 新卡**复用 GATE-04 已锁定的 forbidden substring 列表**（phase16/17 范式里的 `forbiddenEn/Zh/...`，已覆盖 ranking/streak/cross-period/comparison/目标）；不为新文案新增禁词（已锁表足够）。⚠ 已锁表「relax 需 ADR 签署」，本决策是复用而非放松。
- **D-14:** 单个 **`anti_toxicity_phase47_test.dart`** 覆盖 5 张新卡 × 3 语 × 全状态（延续 phase16/17 per-phase 文件惯例），非 per-card 拆文件。
- **D-15:** **本阶段删除**孤儿 section-header ARB 键 `analyticsGroupHeaderTime/Distribution/Stories`（46-07 扁平化后零消费者）。删除 → `flutter gen-l10n` → **`git add -f`** 被 gitignore-yet-tracked 的 `lib/generated/` 生成 Dart（已知坑：executor 会漏 commit 生成文件，orchestrator 需复查）。GUARD-03 ARB 洁净度优先。

### Claude's Discretion
- 逐波（wave）拆分与门禁顺序由 planner 定（goal 要求「逐波门禁」用全量 `flutter test`）。
- WR 修复与验证工作的先后编排（建议 WR 修复 → ARB/反毒性 → golden 撰写 → 全量门禁 → 真机 UAT）由 planner 细化。
- 「Other」rollup 切片的具体配色/排序细节遵循既有 donut 调色与 ADR-019 调色板。
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### WR 修复来源（最重要）
- `.planning/phases/46-cards/46-REVIEW.md` — WR-01..04 的完整问题描述 + 推荐修法（§WR-01 JPY / §WR-02 圆环对账 / §WR-03 O(n·k) / §WR-04 刷新一致性）

### 反毒性 / ADR 恒久约束
- `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` — 反游戏化恒久约束 + 末尾 `## Update` 记录的「支出侧本月vs上月」§4 显式例外（悦己侧跨期绝对禁止）
- `docs/arch/03-adr/ADR-016_Joy_Metric_Visualization_Redesign.md` §3/§4 — HomeHero 隔离不变量（analytics 不读/不失效任何 `home/*`；JOY-01 ambient 不得变成 target ring）
- `docs/arch/03-adr/ADR-017_Terminology_Unification_v1_5.md` — 日常/悦己 词表 + 生存/灵魂 grep-ban（GUARD-03）
- `.planning/phases/43-html-design-gate-no-production-code/GATE-04-emotion-wordlist.md` — GATE-04 锁定情感词表（反毒性禁词的权威来源，`target/目标` 限 analytics-only）
- `.planning/phases/43-html-design-gate-no-production-code/GATE-04-flchart-affordance-verification.md` — fl_chart 1.2.0 逐图 affordance 校验结论

### 现成测试范式 / golden 基础设施
- `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart` — 反毒性 per-phase 扫描范式 + 已锁 `forbidden*` 列表
- `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase17_test.dart` — 同上（entry-source 变体）
- `test/flutter_test_config.dart` — golden 平台门：macOS 基线，off-macOS 用 `BaselineExistenceGoldenComparator`（CI ubuntu 永不像素匹配）

### 需求 / 路线
- `.planning/REQUIREMENTS.md` — GUARD-03 / GUARD-04 / GUARD-05 验收定义
- `.planning/ROADMAP.md` §Phase 47 — 目标 + 4 条 Success Criteria

### 受影响源码（修复 / 测试 / golden 落点）
- `lib/features/analytics/presentation/widgets/cards/` — 5 新卡：`within_month_trend_card.dart` / `category_donut_card.dart`（WR-01/02 落点）/ `joy_spend_card.dart`（WR-01）/ `joy_calendar_card.dart`（WR-01/04）/ `satisfaction_histogram_card.dart` + `family_insight_data_card.dart`
- `lib/features/analytics/presentation/screens/category_drill_down_screen.dart` — 只读下钻屏（golden 覆盖 + WR-01 币种）
- `lib/features/analytics/.../analytics_card_registry.dart` — `buildAnalyticsCardContext` 解析 `currencyCode`（WR-01 删除点）+ `joyCalendarRefreshTargets`（WR-04）
- `lib/features/analytics/domain/models/joy_category_amount.dart` + `GetJoyCategoryAmountsUseCase` — WR-03 单遍重构落点

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **反毒性范式：** `anti_toxicity_phase16/17_test.dart` 直接套用——pump 整卡 × 3 语 × 全状态，断言 `forbidden*` 列表 `findsNothing`。新 `phase47` 文件 import 5 张新卡即可。
- **golden 平台门：** `test/flutter_test_config.dart` 已处理 macOS/off-macOS 分流，新 golden 测试无需重复该逻辑。
- **shared sample-data（43-01）：** 确定性样本数据，golden + 反毒性扫描可复用以保稳定。
- **`ListTransactionTile(readOnly: true)`：** drill 列表已复用此变体（46-06），golden 直接覆盖。
- **rollup 单一来源：** `rollupCategoryBreakdownsToL1(topN:10)` / `l1RollupFromTransactions` / `l1AncestorOf`——WR-02「Other」rollup 与 WR-03 单遍重构都在这条链上，donut==drill 单一来源（D-11/46-02）不可破。

### Established Patterns
- **macOS-only golden 基线**：更新基线只在 macOS；CI ubuntu 必然非像素匹配（字体-AA 差），勿在 CI 重基线。
- **per-phase anti_toxicity 文件命名**：`anti_toxicity_phase{NN}_test.dart`。
- **LOCKED forbidden lists**：GATE-04 锁定；放松需 ADR 签署，收紧（加词）可，但本阶段复用不加。
- **全量 `flutter test` 作逐波门禁**（非子集）；必须含 `home_screen_isolation_test` + 两个反毒性扫描 + 架构/CJK/density grep。
- **gitignored-yet-tracked `lib/generated/`**：改 ARB 后 `flutter gen-l10n` → **`git add -f`** 生成 Dart，否则 analyze 从干净树会挂（已知坑，orchestrator 复查）。

### Integration Points
- WR 修复触及：registry（删 currencyCode）、`category_donut_card`（Other rollup + 中心总额）、`GetJoyCategoryAmountsUseCase`（单遍）、`joyCalendarRefreshTargets`（WR-04）。
- 反毒性：`anti_toxicity_phase47_test.dart` import 5 新卡。
- golden：5 卡 + drill 屏 + 4 类状态的新 golden 测试。
- ARB：删 3 个孤儿 section-header 键 → gen-l10n → force-add 生成文件。

</code_context>

<specifics>
## Specific Ideas

- WR-02 的「Other」rollup 在视觉上须是中性长尾聚合，措辞过反毒性扫描（不可暗示「剩下的不重要」之类评判）。
- UAT 主跑真机 iOS、locale=ja；这是 app 默认语言，最贴近真实用户首屏。
- count-up 动效的 golden 取 settled 末态——验证落点正确（donut 中心 + 悦己 header），不验证动画中间帧。
</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope. （性能优化超出 WR-03 单遍重构的部分仍属 v1 out-of-scope；多币种 analytics 子总额 = CUR-V2-02；收入/真实结余率 = INCOME-V2-01；fl_chart 2.x = TOOL-V2-01 已 N/A——均不在本阶段。）

</deferred>

---

*Phase: 47-i18n-macos-golden-uat*
*Context gathered: 2026-06-17*
