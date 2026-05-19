# ADR-016: Joy Metric Visualization Redesign

**文档编号:** ADR-016
**文档版本:** 1.0
**创建日期:** 2026-05-18
**最后更新:** 2026-05-19
**状态:** ✅ 已接受 (Accepted — 2026-05-19)
**决策者:** xinz (用户产品决策) + Architecture Team
**影响范围:** HomeHeroCard 同心环视觉、AnalyticsScreen 悦己 KPI、HAPPY-02 公式层、ADR-013 supersede、新增 user_settings.monthly_joy_target
**相关 ADR:** ADR-012 (No Gamification v1.1)、ADR-013 (Joy Density PTVF Scaling — superseded by 本 ADR §2)、ADR-014 (Soul Satisfaction Unipolar Positive Scale)

> **本 ADR 已 ratify 于 2026-05-19。** 决策见下文 [✅ Decision (2026-05-19)](#-decision-2026-05-19) 段落。
> 原文 Context + Considered Options 保留作为历史决策依据。Status 翻为 ✅ 已接受 后本文进入 append-only 模式（后续仅以 `## Update YYYY-MM-DD: <topic>` 追加，不修改既有正文）。

---

## 📋 状态

**当前状态:** ✅ 已接受 (2026-05-19) — Context + Options + Decision 三段齐备
**触发来源:** 用户首页样式 review 2026-05-18，原文：「重新设计 Joy 的计算方式，看是否用 sum 会更好一些，同时要考虑在同心环中的显示，要能不断累加，让用户有成就感」+「满意度均值是 5，但圆环是 1/4 深色、1/4 浅色，无法让用户理解，需要调整」
**Ratify 路径:** 2026-05-19 用户 + Claude Architecture Team Socratic discussion，5 个 Open Questions 逐题确认

**关联 quick task:** 2026-05-18 用户首页 review，其中 7 项纯视觉/bug 改动已拆为 `quick/260518-*-home-polish`；本 ADR 覆盖剩余的产品决策项（item 3 + item 4）。

---

## 🎯 背景 (Context)

### 用户反馈

用户在 2026-05-18 review HomeHeroCard 时提出两件相关的事：

1. **满意度圆环不直观（item 4）。** 当前同心环把满意度均值 `5/10` 渲染成 1/4 深色 + 1/4 浅色，普通用户无法把"半亮的环"对应到"中性满意度"。
2. **想要"累加"+"成就感"（item 3）。** 用户希望 Joy 指标"用 sum 会不会更好"，圆环能"不断累加"，让记录悦己开支这件事本身带来满足感。

### 当前实现 (2026-05-18 baseline)

- **Joy/¥ 密度公式（ADR-013 锁定）：** `density = Σ (soul_satisfaction × (amount / base)^0.88) / Σ amount`
- **满意度 schema 语义（ADR-014 锁定）：** `soul_satisfaction` 默认值 = 2（单极正向量表），CHECK 1..10 保留
- **HomeHeroCard 同心环** 在 `lib/features/home/presentation/widgets/home_hero_card.dart` 的 `_ringSection()`；当前可视化以"满意度均值 / 10"作为环的填充比例（待 design audit 二次确认）
- **AnalyticsScreen** 已经按 Variant δ 落地（v1.1 Phase 11 close）

### v1.1 已锁定的相邻决策

| ADR | 锁定内容 | 与用户新请求的关系 |
|---|---|---|
| ADR-012 | **禁止 streaks / badges / 跨周期对比 / 成就触发** | 「累加 + 成就感」语言直接撞 ADR-012 的 Forbidden Features 第 2 条 (Badges)、第 4 条 (cross-period delta)、第 7 条 (历史趋势对比)。如果"累加"仅限单月内、无 milestone 触发、无 streak 提示，仍可能落在边界内 — 取决于具体可视化 |
| ADR-013 | **Joy/¥ = PTVF 密度（除以 Σamount）** | 用户问"sum 是否更好"。Sum 不是 ratio，它是另一种 metric（`Σ joy_contribution`），不替换 ADR-013，但可能作为**新增的** ring layer 或新增 KPI。如果作为替换会触发 ADR-013 review |
| ADR-014 | **满意度默认 2（不是 5）** | 用户看到的"均值 5"是数据加权结果，不是默认簇污染。圆环本身的可读性问题与公式无关 — 可以独立于 item 3 修复 item 4 |

---

## 🔍 考虑的方案 (Considered Options — open, not exhaustive)

### 方案 A：仅修视觉，公式不动

**核心：** 不动 ADR-013 Joy/¥ 密度，不动 ADR-014 满意度量表。圆环视觉重设计为"5/10 看得懂"的形式，例如：
- 把"环填充比例 = 均值/10"改成"按 1-10 分梯度变色 + 数值居中"
- 或者把环从"满意度均值"换成"本月 soul 笔数 / 5 笔目标"等更直觉的进度

**优势：**
- 不动 ADR-013/014 任何 contract；零回归风险
- 单 phase 内完成（UI-only）

**劣势 / 风险：**
- 不解决用户「希望累加 + 成就感」的诉求
- 如果新视觉仍以"均值"为底，用户可能再次反馈"还是不直观"

**ADR-012 冲突：** 无（无 cross-period、无 badge）

### 方案 B：圆环改用 PTVF "Joy 累计量" (Σ joy contribution)，公式新增 sum 输出

**核心：**
- 保留 ADR-013 的 Joy/¥ 密度作为 analytics 端 KPI
- 新增 `Σ joy_contribution = Σ (soul_satisfaction × (amount/base)^0.88)`（**分子部分**），不除以 Σamount
- HomeHeroCard 环展示"本月已累计的 Joy 量"，相对一个软目标（例如上月同期、季节均值、或固定显示无目标）逐渐填充
- AnalyticsScreen 保留密度，HomeHeroCard 用累计量

**优势：**
- 答用户"sum"诉求：分子 sum 是 ADR-013 已经在 fold 的中间量，不增加 DB 查询成本
- "累加"在视觉上自然（环从 0 涨到当月总量）
- 不替换 ADR-013，扩展它

**劣势 / 风险：**
- "软目标"如何定义是关键。用"上月累计"作底就是 cross-period delta（撞 ADR-012 #4）；用"无目标"则圆环没有比较基线、视觉不强；用"季节均值"需要后端预计算
- 多了一个 metric 概念，UX 文案需要讲清楚"密度 vs 累计量"的关系
- 累计量本身没有"过高即不健康"的内置警告，可能鼓励无脑增加 soul 支出

**ADR-012 冲突：**
- 单月内累加：边界内
- 与上月对比：明确撞 #4
- 累计触发的 milestone 提示（"你已经超过上月！"）：明确撞 #2 / #7

### 方案 C：环改为"Joy 分布直方图"型视觉（替代圆环）

**核心：** 抛弃单值同心环，用一个圆形堆叠 / 弧形分布展示本月所有 soul 交易的满意度分布（例如：emoji 1 占 10%、emoji 5 占 30%）。

**优势：**
- 完全绕开"均值如何映射到圆环"的问题
- 视觉信息密度高，符合 v1.1 "celebrating not grading" 哲学
- 不增加新公式

**劣势 / 风险：**
- 改动比 A 大，需要新 widget
- 一旦交易少（n<3）分布无意义，需要空态/低密度态设计
- 不答用户"累加"诉求

**ADR-012 冲突：** 无

### 方案 D：保持现状

**核心：** 用户反馈是个人偏好，定性问题需更多用户反馈数据再决策。Phase 9 锁定刚落地（v1.1 close 2026-05-05，距今 13 天），过早改动会破坏数据基线。

**优势：**
- ADR-013 引用的"数据有效性保护"理由当前仍然适用
- 改动成本零

**劣势：**
- 用户当前体验问题被搁置
- "1/4 深 + 1/4 浅"问题是真的可读性缺陷，不全是品味问题

---

## ⚖️ 关键 Open Questions（讨论时必须先回答）

1. **"成就感"具体边界在哪？** 用户原话"让用户有成就感"。如果允许任何"累加视觉"，那 streak 也满足这个描述。需要用户/产品确认：可接受"单月内进度环"，但拒绝"跨月对比"、"milestone 提示"、"连续天数"？
2. **替换 vs 新增？** Joy/¥ 密度是 ADR-013 的锁定输出。用户问"sum 更好"是问替换还是增加一个 metric？
3. **HomeHeroCard 与 AnalyticsScreen 是否要不同？** AnalyticsScreen Variant δ 已经把密度+趋势+分布作了体系化呈现。HomeHeroCard 是 "glance"，可以承载与 Analytics 不同的视觉（更瞬时、更感性）。如果两边用不同 metric，是否会让用户困惑？
4. **目标设定的来源？** 如果选 B（累计环），底是什么？固定目标 vs 上月 vs 季节均值 vs 无目标？前三个里有两个直接撞 ADR-012。
5. **是否需要 v1.2 milestone？** v1.1 刚 close 13 天，立刻改 Phase 9/10 contract 会让 v1.1 retrospective 失去基线。是否应该把本 ADR 决定推迟到 v1.2 milestone 启动时再 ratify？

---

## 🚫 已经知道的硬约束（任何方案必须满足）

来自 ADR-012 Forbidden Features，不论选哪个方案都不能引入：

- 跨月 / 跨年 Joy 对比可视化
- "本月超过上月 +N" 类 delta 提示
- 任何形式的徽章 / 成就解锁
- 连续记账天数 streak
- 公开分享按钮
- 按家庭成员 leaderboard

如果选 B 并采用"上月累计"作软目标，必须重新 review ADR-012 #4 — 不可绕过。

---

## 📝 下一步 (Next Steps)

本 ADR 当前为 Proposed。决策路径：

1. **用户产品方向澄清** — 上面的 5 个 Open Questions
2. **/gsd:discuss-phase 或 /gsd:new-milestone** — 视范围决定走 phase-level discuss 还是 milestone-level
3. **必要时新增 spike** — 例如方案 B 的"软目标"选择需要少量用户测试
4. **决策后 append `## Decision (YYYY-MM-DD)`** 段落到本 ADR，状态从 `📝 草稿` 翻为 `✅ 已接受`
5. **若决策走方案 B/C：** 起新 phase 实现 + 可能修订 ADR-013（追加 update 段落，不改原文）

> **2026-05-19 update:** Steps 1-4 已完成（见下文 Decision）。Step 5 进入新 phase 规划，归属 v1.2 milestone。

---

## ✅ Decision (2026-05-19)

**Status:** ✅ 已接受
**决策者:** xinz (用户产品决策) + Architecture Team Socratic discussion
**讨论方法:** 本 ADR Open Questions §⚖️ 5 项逐题确认（Q5 → Q1 → Q2 → 冲突 reconcile → Q4 子任务 → ADR-012 边界）

### 1. 时机 (Q5)

现在 ratify，**显式接受打破 v1.1 baseline pure 状态** 的代价。v1.1 close 至今 13 天，本决定意味着：

- v1.1 retrospective 里追加一条「HomeHero + Analytics Joy metric 从密度 (Joy/¥) 迁移到累计量 (Σ joy_contribution)」的迁移点
- 未来 baseline 对比时以本 ADR 接受日 (2026-05-19) 为分水岭
- v1.1.x patch 与 v1.2 都可能承载实现，不强制锁定到单一 milestone

### 2. Joy metric 处理 (Q2) — supersede ADR-013

**替换 ADR-013。** Σ joy_contribution 成为全局唯一 Joy 表达。

**新公式:**
```
Σ joy_contribution = Σ (soul_satisfaction × (amount / base)^0.88)
```

**关键差异 vs ADR-013:**
- ADR-013: `density = Σ (soul_satisfaction × (amount / base)^0.88) / Σ amount` — 除以 Σamount，是 ratio
- ADR-016: 同样的分子，**不除以 Σamount**，是 cumulative sum

**ADR-013 处置:**
- ADR-013 保留 ✅ 已接受状态（append-only 规则不允许翻转回退）
- ADR-013 文末追加 `## Update 2026-05-19: Superseded by ADR-016 §2` 段落，记录 supersede 事实
- ADR-013 §🎯 背景 的 PTVF 标度数学定义作为 **单项贡献的算法** 继续保留并被 ADR-016 引用
- 密度 (Joy/¥) 作为 metric 退役，HomeHero 和 Analytics 都不再展示

**代码影响范围（实现 phase 列出）:**
- `lib/application/analytics/get_happiness_report_use_case.dart` — fold 逻辑改 (不再 / Σamount)，return type 调整为 `MetricResult<int>` 或类似
- `lib/data/daos/analytics_dao.dart` — query 可能简化 (不再需要 Σamount 维度)
- `lib/infrastructure/i18n/formatters/joy_density_formatter.dart` — 改名或删除，新增 `joy_cumulative_formatter` (整数 + 千分位)
- `lib/features/home/presentation/widgets/home_hero_card.dart` — 同心环数据源改 + 视觉重设计
- AnalyticsScreen 的 Variant δ 体系需重画 (密度 KPI 退役)

### 3. 累加视觉边界 (Q1)

**HomeHero 同心环 = 单月内 Σ joy_contribution 累加进度环。**

允许的视觉行为:
- ✅ 月初归零，环空
- ✅ 每笔 soul 交易提交后环递增（可有 micro-feedback 填充动画，单次时长 < 0.6s）
- ✅ 月底归零（下月 1 日重新从 0 开始）
- ✅ 与当月「软目标」对比的填充百分比（见 §4）

**禁止的视觉行为（仍守 ADR-012）:**
- ❌ 与上月、上周、季度均值、家庭成员均值对比 (ADR-012 #4)
- ❌ 累计天数 streak 显示 (ADR-012 #5)
- ❌ 「本月超过上月 +N」delta 提示 (ADR-012 #4)
- ❌ Joy 达成相关的 badge / 成就解锁 (ADR-012 #2)

### 4. 目标值机制 (Q1 子任务 + 原 Q4 重定向)

**用户可配置 + 默认值推荐：**

新增 schema field:
```
user_settings.monthly_joy_target  INTEGER NULLABLE
```

设置页 UI 提供数字输入框 + 默认值推荐文案。

**默认值推荐算法（用户未配置时，圆环按此填充比例计算）:**

| 用户历史 | 推荐值 |
|---|---|
| ≥3 个完整自然月 soul 交易数据 | `ceil(median(过去 3 个月每月 Σ joy_contribution))` |
| <3 个完整自然月 | fallback hardcoded baseline（**具体数字 TBD in plan-phase**） |

**TBD in 实现 phase（建议 1 天 spike 决定）:**
- fallback baseline 具体数字（候选区间 30-100，需基于早期种子数据测试）
- 中位数是否需要 outlier 截断（例如剔除 single-tx > 3× p75 的月份）
- 推荐值是否在用户配置后仍持续显示（"基于你过去 3 个月，建议 X"）

### 5. 100% 行为 (ADR-012 #2 边界) (Q3)

**纯环境变化。无 discrete event，避免触发 ADR-012 #2 (milestone/achievement)。**

允许:
- ✅ 环颜色从葵绿 (#47B88A, 灵魂账本绿) 平滑过渡到金色（具体色值实现期定）
- ✅ 颜色过渡曲线可以是 0%-100% 全程渐变，或 90%+ 才开始变金（实现期 UI 决策）
- ✅ 超过 100% 后环视觉冻结在金色饱和态（不再变化）

禁止:
- ❌ 文案提示（"本月你送了 X 份愉悦给自己"）
- ❌ 任何 toast / snackbar / push notification
- ❌ 一次性 celebration 动画（如发光、闪烁、放大脉冲）
- ❌ Haptic feedback 触发
- ❌ 显示 >100% 的数字（如 120%、150%）— 数字部分仅显示绝对值 Σ joy_contribution，不显示百分比

**ADR-012 兼容性声明:**
环颜色变化是 ambient state 渲染（连续函数 f(progress) → color），不是 achievement trigger（无 discrete unlock event）。此区分被显式记录以备未来 review 追溯。

### 6. 双屏一致性 (原 Q3 隐含)

- **HomeHero**: 累加环 + 数字 (Σ joy_contribution 绝对值) + 颜色状态（如 §5）
- **Analytics**: 改用 Σ joy_contribution 作为主 KPI；可视化形式（趋势线 / 月度分布块 / per-tx 散点）在实现 phase 重新设计 — 当前 Variant δ 的「密度 + 趋势 + 分布」体系需要重画
- **不允许:** 两屏使用不同 metric（避免用户认知割裂）

### 7. 后续工作

**本 ADR 落地后立即（同 commit 内）:**
- ADR-013 append `## Update 2026-05-19: Superseded by ADR-016 §2` 段落
- doc/worklog/ 写本次决策日志

**新建 phase（建议归属 v1.2 milestone 首个 phase）:** "Joy metric migration to Σ joy_contribution"
- Scope: schema 变更 + use case 重写 + HomeHero 重写 + Analytics 重写 + settings UI + golden 重生 + i18n key 增减
- 1 天 spike 决定 §4 fallback baseline 数字
- 验收 must-haves:
  - density 公式从代码 + UI 完全移除
  - Σ joy_contribution 在 HomeHero 单月内递增展示
  - 月度目标可配置 + 默认值推荐算法正确
  - 100% 行为符合 §5（颜色平滑、无文案、无动画、无提醒）
  - golden 测试覆盖 0%, 50%, 100%, >100% 四态

**v1.1 RETROSPECTIVE.md:** 追加一条 baseline migration note（Joy metric 已迁移、对比基线分水岭日期 2026-05-19）

### 8. 显式被拒绝的方案

- **方案 D (保持现状)** — 用户视觉可读性诉求是 deficit not preference，不可搁置
- **方案 C (圆环改分布直方图)** — 不答用户「累加」诉求；信息密度高但与「成就感」无关联
- **方案 B + 「上月累计」作软目标** — 撞 ADR-012 #4 (cross-period delta)，明确拒绝
- **100% 行为之 ②金色 + 一次性发光动画** — 在 ADR-012 #2 边界灰色地带，保守拒绝
- **100% 行为之 ③文案 toast** — 直接撞 ADR-012 #2 (achievement trigger)，明确拒绝
- **Q4 目标值之 ②产品拍固定 baseline** — 缺个人化，约 40% 用户会落在两端无意义区间
- **Q4 目标值之 ③v1.1 当窗口加 settings field** — v1.1 close 后窗口太重，但被并入新 phase

---

## 🔗 引用

- `lib/features/home/presentation/widgets/home_hero_card.dart` — 当前圆环实现
- `lib/application/analytics/get_happiness_report_use_case.dart` — Joy/¥ 密度 fold
- `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` — 硬约束来源
- `docs/arch/03-adr/ADR-013_Joy_Density_PTVF_Scaling.md` — 当前 Joy/¥ 公式
- `docs/arch/03-adr/ADR-014_Soul_Satisfaction_Unipolar_Positive_Scale.md` — 满意度量表
- `.planning/milestones/v1.1-ROADMAP.md` — v1.1 phase scope
- 用户首页 review 2026-05-18 — 触发本 ADR 的原始反馈（item 3 + item 4）

---

*最后审查日期: 2026-05-19 (ratify + Decision append)*
*下次审查触发: Joy metric migration phase 实现完成后回顾 (验证 §7 must-haves 达成情况)*
