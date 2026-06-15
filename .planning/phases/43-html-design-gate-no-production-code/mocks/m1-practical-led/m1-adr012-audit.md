# ADR-012 自审表 — Mock M1 实用主导（practical-led）

**Phase:** 43-html-design-gate-no-production-code（GATE-02）
**写于:** 2026-06-15
**判定标准:** RESEARCH §4 反游戏化映射表 + ADR-012《Forbidden Features》#1–#6 + ADR-016 §3/§5。
**判定口诀（RESEARCH §4）:** 动画/强调若由「view/data 出现」触发 = OK ✅；若由「跨过阈值/目标/连续」触发 = forbidden ❌。

> M1 是 5 套里**悦己浓度最低**的一案：实用骨架（支出总览 + donut + breakdown + 趋势柱）主导，悦己只以**一行最克制 ambient 小计**出现。因此情感元素少、越界面也小，本表应**安稳 PASS**——但仍逐元素填写，任何 ❌ 须在 GATE-03 选定前移除或降级。

---

## 一、本 mock 实际出现的情感元素逐项裁定

| 情感元素（M1 实际呈现） | ambient / 庆祝过去（OK） ✅ | 目标 / 跨期对比 / 成就（forbidden） ❌ | 判定 | 依据 |
|---|---|---|---|---|
| 已花悦己 ambient 小计（¥47,200 +「滋养了这个月的自己。值得。」） | 绝对累计 Σ joy_contribution，描述「已发生什么」，无基线、无 target、无百分比 | 若做成 progress / target ring，或「达成 X%」「超过上月」 | ✅ | ADR-016 §3（target ring 仅 HomeHero 独占）+ §5（ambient ≠ achievement）；D-03 |
| 值得（JOY-01）数字强度 | M1 取**最弱强度**——仅一行小计文字，weak/subordinate，附属于总览 | 若升格为进度环 / 满额脉冲 / 跨期涨跌 | ✅ | ADR-016 §3；D-03（JOY-01 绝不成 ring）|
| 分类支出 donut（占比环，含悦己合计 19%） | 占比构成的**静态分布**，view 出现即渲染，无阈值触发 | 若把环做成「目标达成填充环」或随阈值变色/庆祝 | ✅ | ADR-016 §5（f(state)→color 连续，非 discrete unlock）|
| 分类 breakdown 列表 + 下钻入口 chevron | 中性金额/笔数/占比清单 + 「轻点查看明细」affordance；min-N=3 + Other rollup | 若做「最大/最棒分类」排名榜或「第一名」高亮 | ✅ | ADR-012 #6（无排行）+ RESEARCH §4（排名 = forbidden）|
| 近 6 月趋势柱（日常/悦己分层） | **中性滚动上下文**，仅作节奏参照；当前月只用浅描边标识位置，无对比文案 | 若标「本月 vs 上月 ↑/↓」「比上月多/少」「连续 N 月下降」 | ✅ | ADR-012 #4（cross-period delta 禁止）；RESEARCH §1b（previousMonthComparison 已算但绝不 surface）|
| 日常/悦己配比条（81% / 19%） | 单月内构成占比的**事实陈述**，无好坏判断 | 若标「悦己占比目标 / 应达到 X%」「比上月更健康」 | ✅ | ADR-012 #3（daily target 禁止）+ #4 |
| 配色 / 动效（本 mock 为静态示意） | 暖色 ambient：桜粉悦己小计、若葉绿日常；如落地用 count-up / fade（value-affirming） | confetti / 徽章解锁 / 阈值触发的一次性发光·脉冲·haptic | ✅ | ADR-016 §5 + STACK.md（Flutter 内建 ambient 动效，非 achievement-reward）|
| 家庭模式 | M1 **未展示**家庭聚合视图（实用主导，个人单月视角）；若后续启用须 aggregate-only | per-member 排行 / 成员贡献条 / 谁花得多 | ✅（N/A，未呈现）| ADR-012 #6（FamilyHappiness aggregate-only 类型契约）|
| kakeibo Q4 反思 prompt | M1 **未采用**（D-02：Q4 反思核心展示在 M4，M1 不放）| —（未呈现，无越界面）| ✅（N/A，未呈现）| D-02 / D-05 |

---

## 二、关键红线复核（M1 专项）

- **无进度/目标环:** analytics 侧零 progress/target ring；唯一 target ring 归 HomeHero 独占（ADR-016 §3）。值得数字在 M1 是**一行文字**，绝非环。✅
- **仅支出侧:** 全页只画支出（总览 / donut / breakdown / 趋势）——无收入录入、无结余比率（范围勘误 INCOME-V2-01；GATE-01 deep-map「范围勘误」）。✅
- **无跨期对比:** 趋势柱是中性滚动上下文，当前月仅以浅描边定位，无任何「vs 上月」措辞或视觉箭头。✅
- **无排名/无 best-分类:** breakdown 按金额自然降序排列是**信息排序**，非「冠军/最棒」竞争框定；无「第一名」高亮、无奖杯/徽章。✅
- **calm-warm register（D-04）:** 悦己文案「滋养了这个月的自己。值得。」是平静肯定、像日记；无打分、无外放、无「最高/达成/连续」红线词（RESEARCH §3b）。✅
- **自包含 / 零网络:** 内联 `<style>`，无外部资源 / 无脚本 / 无网络字体——符合零知识 app 气质（威胁 T-43-03）。✅

---

## 三、整套裁定

**整套裁定: PASS**

M1 作为悦己浓度最低的实用主导方向，全部情感元素均落在 ambient / 庆祝过去（OK ✅）一侧，**零遗留 ❌**。无进度/目标环、无跨期对比、无排名、无成就/徽章/连续，仅支出侧，calm-warm 文案。可直接进入 GATE-03 评判，无需调整。

> 任何 ❌ 必须在选定前移除或降级为 ambient——本表无 ❌，无需处置。
