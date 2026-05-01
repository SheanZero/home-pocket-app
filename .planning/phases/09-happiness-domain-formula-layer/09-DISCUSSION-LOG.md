# Phase 9: Happiness Domain & Formula Layer - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `09-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-05-01
**Phase:** 9 — Happiness Domain & Formula Layer
**Areas discussed:** Formulas (Area 1), MetricResult contract (Area 2), Best Joy fallback (Area 3), HAPPY-09 voice-bias (Area 4), Headline & Joy/¥ unit (Area 5)

---

## Area 1 — Formulas (4 personal + 2 family)

### Sub-area 1.1: default-5 row treatment (initial framing)

| Option | Description | Selected |
|--------|-------------|----------|
| 全部计入（保持原提议）| DAO `_soulOnly()` 不加 satisfaction 过滤 · mean 被 default-5 拉向 5 · 与 PITFALLS "annotate, don't fix" 一致 | |
| 排除所有 5 | DAO 加 `AND soul_satisfaction != 5` · 过滤 99% 默认 · 误伤 voice 偶尔吐 5 | |
| 奇偶启发式 | DAO `AND soul_satisfaction % 2 = 0` · 仅保留 picker 主动评分 · 耦合 picker 实现 | |
| 全部计入 + highlights 仅 ≥8 | 同选项 1，highlights count 天然不受 default-5 影响 | |

**User's choice (initial):** "全部计入，不排除，为后续 UI 扩展做准备，不要留下后门"
**Notes:** 用户拒绝在 SQL 层埋后门，倾向于让 DAO 数据保持干净，UI 层用 caption / median 补偿。这成为 Area 1 后续讨论的基础原则。但用户随后转向"将 default 5→2 + emoji 语义重构"路径，本质是用产品哲学解决 default cluster 问题，而不是用 SQL 过滤。

### Sub-area 1.2: HAPPY-04 Best Joy 排序公式

| Option | Description | Selected |
|--------|-------------|----------|
| A. Pure sat 主排 + amount DESC tiebreak | sat 严格 trump · 公式最可解释 · 可去掉 ¥500 floor | ✓ |
| B. sat × √amount (Stevens' Power Law) | 均衡奖励 sat 和 amount · 违反 "10 严格 trump 8" | |
| C. sat × log10(amount) (Weber-Fechner 柔和) | 同 B 思路但更柔和 · 同样违反 "10 trump" | |
| D. 保留原方案 sat/amount + ¥500 floor | 接受 "¥500 emoji 3 胜 ¥3000 emoji 5" 的后果 | |

**User's choice:** "A. Pure sat 主排 + amount DESC tiebreak（推荐）"
**Notes:** 用户原话"虽然小东西会让人开心，但也要鼓励为了自己的开心花更多的钱"。Pure sat 排序 + amount-DESC tiebreak 同时满足"sat=10 严格 trump"和"鼓励大金额悦己"两个直觉。¥500 floor 因此移除。

### Sub-area 1.3: HAPPY-01 vs HAPPY-02 区别 + HAPPY-02 走向

| Option | Description | Selected |
|--------|-------------|----------|
| 保留两者，按原计划 4 个个人指标 | REQUIREMENTS.md 不变 · UI 设计 2×2 矩阵叙事 | |
| 仅保留 HAPPY-02，合并 -01 | 失去"独立情绪自检"角度 | |
| 保留两者但 HAPPY-01 加金额加权 | HAPPY-01 与 -02 高度重叠 | |
| 换个指标取代 -01/-02 | 超出 milestone scope | |

**User's choice:** "对比一下 prospect theory value function（Kahneman-Tversky）的计算结果"
**Notes:** 用户在选项之间没直接选，而是要求引入 PTVF 重新评估 HAPPY-02。这把讨论从"是否保留两个指标"推到"HAPPY-02 公式具体怎么写"。

### Sub-area 1.4: HAPPY-02 PTVF α 选择

| Option | Description | Selected |
|--------|-------------|----------|
| α = 0.88 (K-T 实证值) | Nobel 论文原始拟合 · 大金额 sat=10 胜过 ¥500 sat=6 · 临界 α≈0.83 刚好越过 | ✓ |
| α = 0.95 (更接近线性) | 大金额奖励更多 · 偏离 K-T 标准 | |
| α = 0.85 (保守，仍越过临界) | K-T 拟合下限 · ¥10k sat=10 仍能胜 ¥500 sat=6 | |
| 老板其他选项 (D / sqrt / log / tier / 不缩放) | 继续上一轮选项 · 数学不解决用户抱怨 | |

**User's choice:** "α = 0.88（K-T 实证值，推荐）"
**Notes:** 数学论证：用户原始直觉"¥10000 → 50"对应 α≈0.54（sqrt 附近），但这个 α 不解决"6/500 vs 10/3000"的排序问题。临界 α≈0.83，PTVF α=0.88 刚好越过。base=¥500（小確幸 baseline），随后追加 currency-aware 修正。

### Sub-area 1.5: HAPPY-03 highlights 阈值

| Option | Description | Selected |
|--------|-------------|----------|
| 保持 ≥8（小確幸严格）| Emoji 4 满足 + emoji 5 最爱；月度 3-10 次 | |
| 改 ≥6（正向时刻）| 含 emoji 3 中性 + 4 + 5；月度 12-25 次 | |
| 改 ≥7（仅主动正向）| 与 ≥8 几乎无差别 | |
| 双指标 ≥6 count + ≥8 highlight | UI 拥挤 | |

**User's choice (initial):** "现在是从很不满开始，是否可以调整为2为中性，4-10是满足度逐渐提升呢，默认值调整为2，让用户的每一笔灵魂支出都是幸福的。深度调研一下，这样是否合理。"
**Notes:** 用户提出更深层的问题——重新定义整个 emoji 量表为单极正向。我做了深度 research（McDonald's / Apple Health / Daylio / Self-Compassion / CBT 等），提出三条落地路径。

### Sub-area 1.6: 单极正向量表落地路径

| Option | Description | Selected |
|--------|-------------|----------|
| A. v1.1 全量改造（schema + ARB + icon + voice + 阈值）| 完整哲学落地，超出 v1.1 锁 | |
| B. 仅 ARB 重命名 + 阈值 ≥6（schema 不动）| 哲学部分落地，不破 schema 锁 | (Selected base, 用户在此基础上加码)|
| C. v1.1 维持现状，哲学转移推到 v1.2 | 保守，错失 milestone-level insight | |
| D. 仅 Phase 9 contract 文件预告 | 量火，UI 不实现 | |

**User's choice:** "采用路径B，因为现在没有用户使用，所以把Schema default 5 → 2，不需要历史 backfill。"
**Notes:** 用户基于"现在没有用户"这个 fact，把路径 B 升级为"路径 B + schema 改 default"。schema 锁本来是 prudent default，pre-launch 状态下可以放宽。HAPPY-03 → ≥6（与新 mapping "Good or better" 对齐）；FAMILY-01 同步调整。

### Sub-area 1.7: Family use case group books 枚举

| Option | Description | Selected |
|--------|-------------|----------|
| 复用 `shadowBooksProvider` | 现有架构复用，Phase 11 同路径 | ✓ |
| AnalyticsRepository 新开 `getBooksInGroup` | 多一个 repo 接口 | |
| 留作 open question 交 planner | 不在 discuss-phase 决定 | |

**User's choice:** "复用 `shadowBooksProvider`（推荐，锁定）"
**Notes:** 在用户先要求 review FAMILY-02 完整公式后才回到这个问题。Use case 接 `groupBookIds: List<String>` 作参，presentation 层从 `shadowBooksProvider.future` 解析。

---

## Area 2 — MetricResult 契约

### Sub-area 2.1: thinSample 阈值

| Option | Description | Selected |
|--------|-------------|----------|
| 统一 n<3 | 与 FAMILY-02 min-N=3 推重合 | |
| 统一 n<5 | 与 PROJECT.md "HAPPY-06 空状态 n<5 fallback" 一致 | |
| Per-metric 不同阈值 | 各指标脆弱性不同 | |
| 不设 thinSample，二态 empty / value | UI 用 caption 表达样本 size 信号 | ✓ |

**User's choice:** "不设 thinSample，只有 empty / value"
**Notes:** 与用户"不要后门，UI 层处理"哲学一致。MetricResult 简化为 sealed binary。UI 用 sampleSize / totalSoulTx 等数据字段判断"样本充分性"。

### Sub-area 2.2: Value 是否带 sampleSize

| Option | Description | Selected |
|--------|-------------|----------|
| 带 (Value<T> { data, sampleSize }) | UI caption 单一来源 · self-contained | ✓ |
| 不带，UI 另起 provider | 职责分离但 UI 多 watch 一个 provider | |

**User's choice:** "带（推荐）"
**Notes:** 简化 UI 调用面。

### Sub-area 2.3: Empty 是否拆子类

| Option | Description | Selected |
|--------|-------------|----------|
| 单一 Empty 不拆 | 简单 · UI 用 totalSoulTx 区分上下文 | ✓ |
| 多 Empty 子类 | 类型多但语义清晰 | |
| Empty 带 reason enum | 中间道 · 灵活性 vs over-engineering | |

**User's choice:** "单一 Empty 不拆（推荐）"
**Notes:** UI 处理 FAMILY-02 "min-N 不满足" vs "无 group soul tx" 的差异通过读取 `totalGroupSoulTx` 字段。

### Sub-area 2.4: HappinessReport 字段是否逐个 MetricResult 包装

| Option | Description | Selected |
|--------|-------------|----------|
| A. 逐个包装 | 安全 · model 重 | |
| B. 平铺 + Provider 整体 MetricResult<HappinessReport> | model 瘦但 UI 语义判断分散 | |
| C. 混合：主指标包装，aux 平铺 | 4 主指标 MetricResult，aux (year/month/totalSoulTx) 平铺 | ✓ |

**User's choice:** "C. 混合：主指标包装，aux 平铺"
**Notes:** 4 个个人指标 + 2 个家庭指标都 MetricResult-wrapped；元信息（year/month/bookId/totalSoulTx）平铺。

---

## Area 3 — Best Joy 无候选时的行为

### Sub-area 3.1: "全 default / 全 neutral" 场景的 UX 决定

| Option | Description | Selected |
|--------|-------------|----------|
| A. 直接渲染 (contract 简单，UI 显示 "Neutral 最大金额") | 信息诚实但可能让用户感觉空虚 | |
| B. Phase 10 UI 检测 sat≤2 加 CTA | Contract 不变，UI 自主判断 | ✓ |
| C. Contract 加 Empty 触发 (违 Area 2 决策) | 与"单一 Empty 不拆"冲突 | |
| D. HAPPY-04 加最低 sat 门槛 | 与 Area 1 "无 floor" 冲突 | |

**User's choice:** "B. Contract 简单，Phase 10 UI 加 CTA（推荐）"
**Notes:** Phase 9 contract 保持简单（Empty iff totalSoulTx=0；否则 Value）。UI 通过读 `topJoy.data.soulSatisfaction <= 2` + `totalSoulTx > 0` 判断"全 neutral"状态，渲染 CTA 引导用户回去评分。

---

## Area 4 — HAPPY-09 voice-bias 路径

### Sub-area 4.1: entry_source 列加不加

| Option | Description | Selected |
|--------|-------------|----------|
| a. 加列 + 实现 manual-only sub-metric | 完整但 Phase 9 工作量+1-2 plan | |
| b. 不加列，仅交付 +0.3 regression test | 最轻量 · sub-metric 推 v1.2 | |
| c. 加列但 v1.1 不实现 sub-metric | 中道 · 为 v1.2 探路 | |
| d. 完全 drop HAPPY-09 (REQUIREMENTS 减一) | REQ 26→25 · voice bias 仍是实际问题 | (Selected) |

**User's choice:** "移除，把voice bias作为上线后的迭代功能处理，正式上线前先不作为工作项"
**Notes:** 用户选择把整个 HAPPY-09 推到 post-launch / v1.2，理由是 pre-launch 阶段更应聚焦核心交付。HAPPY-09 → HAPPY-V2-03（v2 deferred）。v1.1 REQ 数 26 → 25。Voice estimator output 范围（[3, 10]）也不在 v1.1 调整。

---

## Area 5 — Headline 呈现 + Joy/¥ 单位归一化

### Sub-area 5.1: Joy/¥ 显示单位

| Option | Description | Selected |
|--------|-------------|----------|
| Per ¥1,000 | 1.0–20.0 · 与 milestone insight 对齐 | |
| Per ¥10,000 | 10–200 · 与"万"单位对齐 | |
| Raw + UI 自由处理 | 最灵活但需 Phase 10/11 一致约定 | |
| Raw + Phase 9 附 displayUnit helper | 集中处理单位转换 | ✓ |

**User's choice:** "Raw + Phase 9 附 displayUnit 说明，用这个方案，其中日元采用1000，人民币采用100，美元采用1"
**Notes:** Helper 同时维护 PTVF base 和 display multiplier 两个 currency-keyed map。后续追问"现在的数据库中有币种记录吗"，确认 `books_table.currency` 已有，给 use case 提供 currencyCode 参数路径。

### Sub-area 5.2: medianSatisfaction 是否在 HappinessReport

| Option | Description | Selected |
|--------|-------------|----------|
| 不加，Phase 11 自行计算 | model 瘦，职责清晰 | |
| 加，HappinessReport + FamilyHappiness 都带 | model 肥但 UI 任意可用 | ✓ |
| 仅 HappinessReport 加 | personal 需，family 不需 | |

**User's choice:** "加，FamilyHappiness/HappinessReport 都携带 median"
**Notes:** Phase 11 AnalyticsScreen 头条 row 用；Phase 10 不直接显示但已就位。Median 计算复用 `getSatisfactionDistribution` 数据，Dart 层 fold。

### Sub-area 5.3: Headline tile 选择

| Option | Description | Selected |
|--------|-------------|----------|
| Joy/¥（推荐）| milestone 差异化 insight | |
| Avg Satisfaction | 最直接 | |
| Highlights count | 最具体但信息密度低 | |
| 交 Phase 10 / UI 设计阶段决 | Phase 9 contract 不锁 | ✓ |

**User's choice:** "交 Phase 10 / UI 设计阶段決"
**Notes:** Phase 9 contract 上 4 个 personal tile 平等。

### Sub-area 5.4: PTVF base 是否 currency-aware（追加补充）

(无正式 AskUserQuestion 选项，是用户主动追问引出的修正)

**User's input:** "HAPPY-02计算公式中的base也应该和币种相关，日元是500，人民币是25，美元是5"
**Notes:** 这是一个关键 catch。原本 base=¥500 是 JPY-implicit 假设；用户把它升级为显式的 currency-keyed map：JPY=500 / CNY=25 / USD=5。代码扫描确认 `books_table.dart:8` 已有 `currency` 列（ISO 三字符），实现路径直接打通。

---

## Claude's Discretion

下列点用户没有显式选择，按以下原则交给 planner / executor：

- **DAO 方法命名、文件拆分、build_runner 顺序** — 沿用 `get_monthly_report_use_case.dart` template 模式。
- **新 ADR 的具体编号** — planner 读 `docs/arch/03-adr/ADR-*.md` 取下一个序号（当前最大 ADR-011，预期下三个为 ADR-012/013/014；Phase 12 起草的 Lexical Hierarchy ADR 可能是 ADR-015）。
- **Test fixture 策略** — planner 决定 hand-built / demo_data_service-derived / new test_doubles 哪种。需覆盖：n=0、n=1、n=N mixed、all-default sat=2、all sat=10、多币种 PTVF base、FAMILY-02 min-N edge cases。
- **Median computation 实现路径** — 推荐复用 `getSatisfactionDistribution` 在 Dart 层算；planner 可选择 DAO 端新方法。

---

## Deferred Ideas

已写入 `09-CONTEXT.md` `<deferred>` 章节，不在此重复。简要清单：

**Out-of-Phase-9（仍 v1.1）：** Phase 10 UI rebuild、Phase 11 chart wiring、Phase 12 emoji ARB + icon、ADR-XXX_Lexical_Hierarchy（Phase 12 起草）。

**Out-of-v1.1 / v2+：** HAPPY-V2-03 manual-only sub-metric（含 entry_source 列）、voice estimator output realignment、HAPPY-V2-01/-02、STATSUI-V2-01、FAMILY-V2-01/-02、TOOL-V2-01/-02、多币种 PTVF base 扩展、PTVF α 调优、unrated/Neutral 区分手段、median DAO-side 优化。

**永久 forbidden anti-features：** 成员粒度面板（leaderboard）、streaks/badges/daily targets、cross-period delta on home tile、public sharing。

---

## 讨论中的关键转折点（供 retrospective 参考）

1. **default-5 处理（Area 1 起点）** — 用户从"全部计入"出发，但坚决拒绝 SQL 后门。这个原则贯穿了后续所有 Area。

2. **Best Joy 公式重审（Area 1 中段）** — 用户对原 `sat/amount` 公式的"6/500 胜 10/3000"现象提出强烈反对。这次反对引出了 Pure sat sort + amount-DESC tiebreak 决策（D-06），并间接催生了后续对 HAPPY-02 公式的 PTVF 升级。

3. **PTVF 引入（Area 1 中后段）** — 用户主动要求"对比 prospect theory value function"。我做了完整 4 公式 vs 用户约束的数学分析，明确指出"只有 PTVF α≥0.83 真正解决用户抱怨"。这是一个 research-grade 决策点。

4. **Path B + schema 改 default（Area 1 后段）** — 用户基于"现在没有用户"事实把 schema 锁从硬约束放宽。这个判断打通了 D-02 / D-10 / D-11 / D-12 一系列依赖链。

5. **HAPPY-09 整体移除（Area 4）** — 用户决定把 voice bias 整体推到 post-launch，理由是 pre-launch 应聚焦核心。这个决策让 Phase 9 plan 减负、避免无谓 schema 变更。

6. **PTVF base currency-aware（Area 5 末尾）** — 用户在准备写 CONTEXT.md 前主动追问，发现并修正了 base 的 JPY-implicit 假设。代码扫描立即确认 `books_table.currency` 已存在，落地路径打通。这是一个"差点遗漏的关键细节"被用户主动发现并修复。
