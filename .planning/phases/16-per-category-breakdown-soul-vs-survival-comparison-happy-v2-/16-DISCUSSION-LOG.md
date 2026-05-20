# Phase 16: Per-Category Breakdown + Soul-vs-Survival Comparison (HAPPY-V2-01 + STATSUI-V2-01) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-20
**Phase:** 16-Per-Category Breakdown + Soul-vs-Survival Comparison
**Areas discussed:** Survival 满足度的语义陷阱, Per-Category 卡片形态与排序, Soul-vs-Survival surface 的视觉范式, Group/Family 模式行为

---

## Pre-Discussion — Gray Area Selection

| Option | Description | Selected |
|--------|-------------|----------|
| Survival 满足度的语义陷阱 | `soul_satisfaction` default=2, picker only on soul; raw AVG misleading | ✓ |
| Per-Category 卡片形态与排序 | list vs ranked pills vs table; sort axis; top-N; <3 entries handling | ✓ |
| Soul-vs-Survival surface 的视觉范式 | side-by-side vs stacked vs bar; insertion section; anti-toxicity copy | ✓ |
| Group/Family 模式行为 | aggregation strategy under `isGroupMode`; ADR-012 §6 compliance | ✓ |

**User's choice:** All four selected (multi-select).

---

## Area 1 — Survival 满足度的语义陷阱

### Q1.1 — Soul-vs-Survival 对比的本质度量

| Option | Description | Selected |
|--------|-------------|----------|
| 重新定义为 'engagement 轴' | count + total spend; avoid default=2 trap; consistent with ADR-014 unipolar | ✓ |
| 仅在"已评分"交易上计算 avg sat | Survival sat>2 filter; conflicts with ADR-014 D-10 Neutral collision | |
| 原始 AVG 直接对比，不过滤 | strict ROADMAP example; ships anti-toxicity reverse pattern | |
| 双轴：Soul 看 avg sat，Survival 看 spend share | mixed-semantic; users must parse why columns differ | |

**User's choice:** 重新定义为 'engagement 轴'.

### Q1.2 — engagement 轴里包含哪些指标

| Option | Description | Selected |
|--------|-------------|----------|
| entry count + total spend | minimal, descriptive | ✓ |
| entry count + total spend + avg/tx | adds per-tx amount; risks "single-tx cost = better" reading | |
| entry count + spend share % | % expressions whisper ranking ("60% on survival") | |
| 你决定 | planner discretion within guardrails | |

**User's choice:** entry count + total spend.

### Q1.3 — Soul 列是否带 avg satisfaction

| Option | Description | Selected |
|--------|-------------|----------|
| 带 (Soul 多一行 avg sat / N) | makes asymmetry explicit; honors ADR-014 product truth | ✓ |
| 不带 (两列完全对称) | cleaner; loses Soul-specific signal | |
| 仅以 avg sat 作 Soul 列顶部数字 | hero number is avg sat; expressive but visual cost | |

**User's choice:** 带 (asymmetric — Soul has avg sat row, Survival does not).

### Q1.4 — Empty state 怎么处理

| Option | Description | Selected |
|--------|-------------|----------|
| 任一账本=0 tx 时整个对比 surface Empty | consistent with SharedJoyInsight Empty | ✓ |
| 单账本=0 时仅该列缺席 | preserves info; readable as "incomplete" | |
| min-N 阈值：任一账本 <3 时整块 Empty | tighter threshold; arguable | |

**User's choice:** 任一账本=0 tx 时整个对比 surface Empty.

**Continue check:** 进入下一个 area.

---

## Area 2 — Per-Category 卡片形态与排序

### Q2.1 — 核心形态

| Option | Description | Selected |
|--------|-------------|----------|
| 纵向排名列表 (one row per category) | matches SharedJoyInsight one-liner; lightest in Variant ε density | ✓ |
| 水平 mini-bar + 数值叠加 | strong visual contrast; bar length reads as ranking | |
| 紧凑表格 (3 列) | most data-dense; conflicts with Variant ε card-section style | |
| Stories 卡片 ("最令心动的 3 类别") | "story" framing; crosses motive-language boundary | |

**User's choice:** 纵向排名列表.

### Q2.2 — 排序主轴

| Option | Description | Selected |
|--------|-------------|----------|
| avg sat 降序, count 二级键 | matches SharedJoyInsight tie-break (AVG DESC → COUNT DESC → id ASC) | ✓ |
| count 降序, avg sat 二级键 | "frequency = joy" semantic; arguable | |
| 混合得分：avg × log(count) | balances avg vs sample size; conflicts with ADR-016 "single Joy expression" feel | |

**User's choice:** avg sat 降序，count 为二级键.

### Q2.3 — <3 entries 类别怎么处理

| Option | Description | Selected |
|--------|-------------|----------|
| 隐藏，不计不显 | cleanest; matches SharedJoyInsight HAVING COUNT>=3 | |
| 归到 'Other' 折叠行 | preserves "how many low-N entries" info | ✓ |
| 全部显示，但不能出现在顶部 3 位 | low-N visible but not crowned | |

**User's choice:** 归到 'Other' 折叠行.

### Q2.4 — Top-N 默认呈现量

| Option | Description | Selected |
|--------|-------------|----------|
| Top 5, 'show all' 点击展示剩余 | matches Variant ε card density and CategoryDonut top-N+Other model | ✓ |
| Top 3 | tighter; may lose useful long-tail | |
| 一次性全列 (top N≥3 + Other) | no expand needed; tall surface | |

**User's choice:** Top 5，'展开全部' 点击展示剩余.

**Continue check:** 进入下一个 area.

---

## Area 3 — Soul-vs-Survival surface 的视觉范式

### Q3.1 — 核心形态

| Option | Description | Selected |
|--------|-------------|----------|
| 并排双列 mini-card | single Card with left/right split; descriptive; non-confrontational | ✓ |
| 上下两行描述句子卡 | high anti-toxicity; lower info density; static feel | |
| 水平堆叠条 (全宽一根) | strong visual; % share whispers ranking | |
| 表格呈现 | most neutral, data-grade; conflicts with Variant ε story-card style | |

**User's choice:** 并排双列 mini-card.

### Q3.2 — AnalyticsScreen 插入位置

| Option | Description | Selected |
|--------|-------------|----------|
| 都放在 Distribution group | reuses existing section header; lowest i18n cost | ✓ |
| Soul-vs-Survival 在 Distribution, Per-Category 在 Stories | mixed; Per-Category as table conflicts with Stories card-style | |
| 新建 Comparison group (4 section total) | clean separation; extra header ARB + length cost | |
| 都放在 Stories group | "narrative" framing; Per-Category list shape mismatch | |

**User's choice:** 都放在 Distribution group.

### Q3.3 — anti-toxicity 禁词覆盖策略

| Option | Description | Selected |
|--------|-------------|----------|
| 限定 substring 禁用表 (固化在 CONTEXT) | locks trilingual blacklist + widget assertion early | |
| 由 planner 根据 ADR-014/ADR-012 拟定 | flexible; planner ships forbidden list as part of plan | ✓ |
| 文案驱动，不制定禁词表 | risk of locale drift; no machine check | |

**User's choice:** 由 planner 根据 ADR-014/ADR-012 拟定.

**Notes:** CONTEXT D-14 specifies a recommended minimum trilingual list as scaffolding; planner expands per locale review.

### Q3.4 — section header 语言框架

| Option | Description | Selected |
|--------|-------------|----------|
| '两本账本的窗口' / 'Ledger · Side by side' | neutral parallel-list framing | |
| '本月账本描述' / 'Ledger · This window' | window-anchored; generalizes for week/quarter/year/custom | ✓ |
| '账本插画' / 'Ledger · Snapshot' | concept-flavored; least defensible language | |
| 交给 planner / UI-spec | defer all wording | |

**User's choice:** '本月账本描述' / 'Ledger · This window'.

**Continue check:** 进入下一个 area.

---

## Area 4 — Group/Family 模式行为

### Q4.1 — isGroupMode=true 时 Per-Category breakdown 行为

| Option | Description | Selected |
|--------|-------------|----------|
| 聚合群组类别 (single aggregate list) | mirrors SharedJoyInsight group-aggregate; ADR-012 §6 compliant | |
| group mode 下隐藏 | safest; loses family insight | |
| 个人 mode = current book; group mode = aggregate + family marker | merged surface | |

**User's initial choice:** 聚合群组类别.

### Q4.2 — isGroupMode=true 时 Soul-vs-Survival 对比行为

| Option | Description | Selected |
|--------|-------------|----------|
| 聚合群组 | mirrors Per-Category aggregation | |
| group mode 隐藏 | safest | |
| 个人 mode 显示当前 book; group mode 额外加一个"全家聚合"并列 | dual you/family slot | ✓ |

**User's choice:** 个人 mode 显示当前 book; group mode 额外加一个"全家聚合"并列.

### Q4.3 — group mode Soul-vs-Survival 加入全家聚合后的布局

| Option | Description | Selected |
|--------|-------------|----------|
| 2×2 网格 (上行 '我' / 下行 '全家'; 列 Soul \| Survival) | clean crossing-axis expression | ✓ |
| 4 列水平并列 | overflow risk on narrow viewports | |
| 个人卡 + 全家卡 上下两卡 | clearer separation; higher surface cost | |
| 你决定 | defer layout | |

**User's choice:** 2×2 网格.

### Q4.4 — 不对称 (Per-Category 单聚合 vs Soul-vs-Survival 2×2) 是否接受

| Option | Description | Selected |
|--------|-------------|----------|
| 可接受。两个 surface 语义不同 | accepted asymmetry | |
| 调整 Per-Category 为 'group mode 也显示个人+全家两个卡' | symmetrize at Per-Category cost | ✓ |
| 调整 Soul-vs-Survival 为 'group mode 也仅聚合' | symmetrize at Soul-vs-Survival cost | |

**User's choice:** 调整 Per-Category 为 'group mode 也显示个人+全家两个卡'.

### Q4.5 — group mode Per-Category 个人卡+全家卡布局

| Option | Description | Selected |
|--------|-------------|----------|
| 上下两卡, 同一 Distribution group 内连续 | list-shaped surface, vertical stack natural | ✓ |
| 个人在 Distribution, 全家在 Stories | semantic-split; two-location confusion | |
| 仅充实 FamilyInsightCard, 不独立 '全家 Per-Category' | tighter; loses parallel list affordance | |

**User's choice:** 上下两卡，同一 Distribution group 内连续.

**Final continue check:** 进入 write_context.

---

## Claude's Discretion (captured in CONTEXT.md `Planner / UI-Spec Discretion` block)

- Exact ARB key names for new strings (subject to ja/zh/en parity).
- Card padding, divider width, column dividers, exact icon/typography.
- Tap behavior on rows and cells (recommendation: noop in Phase 16).
- DAO query shape for per-category breakdown (single query + Dart filter vs separate HAVING + low-N count query).
- Group-aggregate DAO query shape (extend `getSharedJoyCategoryInsight` vs new method — recommended: new method).
- Use case + provider naming conventions.
- Localized category name pathway through `CategoryLocaleService`.
- Refresh / invalidation wiring (subject to Phase 15 D-12 HomeHero-isolation rule).
- Theme + golden coverage (light + dark per current project theme support).

---

## Deferred Ideas (captured in CONTEXT.md `<deferred>`)

- Per-category drill-in (tap row → filtered transaction list).
- Per-category trend over time (mini-sparklines, WoW movement) — also ADR-012 §4 concern.
- Survival ledger satisfaction picker — contradicts ADR-014; needs new ADR.
- Spend-share % representation in Soul-vs-Survival — rejected (whispers ranking).
- Per-family-member breakdown — permanently forbidden by ADR-012 §6.
- Goldens for additional viewport widths.
- Cross-phase audit for default-2 leak in other analytics surfaces.

---

## ROADMAP correction noted (D-15)

ROADMAP.md Phase 16 Success Criteria 3 currently reads:
> "AnalyticsScreen renders a Soul-vs-Survival comparison surface displaying both ledgers' average satisfaction (e.g., 'Soul ledger averages 7.4 satisfaction; survival ledger 5.1')..."

Plan-phase task list item #1 must rewrite this to engagement-axis language consistent with D-01..D-04, removing the misleading "Survival ledger 5.1" example.
