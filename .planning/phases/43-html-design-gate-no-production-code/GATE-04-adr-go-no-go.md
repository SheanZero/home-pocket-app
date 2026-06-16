# GATE-04 (a) — ADR Go / No-Go 决策记录

**Phase:** 43-html-design-gate-no-production-code
**写于:** 2026-06-16
**Scope:** GATE-03 选定方向 round-5 B（M2 衍生），见 `GATE-03-direction-selection.md`
**性质:** 设计门决策记录。**无生产代码**。结论由 CONTEXT 与 GATE-03 选定 pre-lock —— 此处**记录并补充例外**，不重新 litigate。

---

## 概述

GATE-04 须就两件 ADR 相关事项给出 go/no-go：

1. **JOY-04 持久化是否需要新 ADR** → **NO-GO**（无需新 ADR）— 不变，承 D-06。
2. **选定设计的支出跨期趋势是否需要 ADR 动作** → **GO（须补一条记录在案的 ADR-012 amendment）** — 新增，承 GATE-03 / ROUND2-DECISION.md 的用户批准例外。

---

## 决策 1 — JOY-04 持久化 ADR = **NO-GO**

**结论:** **NO-GO —— 不需要新 ADR。**

**依据（D-06 / D-07）:**

| 链条 | 说明 |
|---|---|
| JOY-04 = 静态只读提示 | 一句温柔提问 + 示例引导，**不接受用户输入**（D-06） |
| → 不持久化用户自撰文本 | 无任何 user-authored text 落盘 |
| → 无加密 / 隐私含义 | 不触 4 层加密栈、不触 Drift、不触同步 |
| → **不需要新 ADR** | v1.8 保持**无 Drift 迁移、纯展示层** |

**声明:** v1.8 里程碑（Phases 43–47）保持 **no-Drift, presentation-only**。本里程碑不引入任何 schema 变更。

**未来留口（D-07，非本里程碑）:** 若未来里程碑要持久化用户自撰反思文本，存储机制留给**届时的新 ADR**（non-Drift 优先以避开迁移/同步）。本里程碑不涉及，此处仅记录以防丢失。

> 此结论已由 CONTEXT（D-06）锁定，GATE-04 **记录、不再讨论**。

---

## 决策 2 — 支出侧跨期趋势 = **GO（记录在案的 ADR-012 amendment）**

**结论:** **GO —— 选定设计的支出侧本月vs上月趋势需要一条记录在案的 ADR-012 carve-out（amendment）。**

### 背景
GATE-03 选定方向 round-5 B 在 `支出趋势` 的 **总支出 / 日常** 两个**支出侧** tab 含 **本月 vs 上月** 累计折线。这放宽了 ADR-012 §4「never surface previousMonthComparison / never draw cross-period delta」的 blanket 规则。用户在被**明确告知此冲突三次**后**刻意选择**保留（来源：`mocks/round2/ROUND2-DECISION.md` 三处岔口表 · 第 1 行）。

### Carve-out 精确措辞（须原样带入 ADR-012 amendment）

> **Cross-period（本月vs上月）comparison is permitted on the EXPENSE-side analytics trend（总支出 / 日常），matching the home 支出趋势; the cross-period prohibition remains ABSOLUTE for the 悦己/joy side and for all achievement / goal / streak framing.**
>
> 中文等义：跨期（本月vs上月）对比**仅**允许出现在**支出侧** analytics 趋势（总支出 / 日常），与首页 `支出趋势` 对齐；跨期禁止对**悦己/joy 侧**以及**所有成就 / 目标 / 连续打卡框定**保持**绝对**。

### 范围与红线
| 维度 | 决定 |
|---|---|
| 允许跨期的位置 | **仅** `支出趋势` 的 总支出 / 日常（支出侧）两个 tab |
| 语义 | 实用预算 parity（与首页支出趋势对齐，判断"这个月比上个月花得多/少"） |
| 标签 | 全程中性（本月 / 上月），**无**「超过/落后/目标/达标/+X%」等评判或 delta 措辞 |
| 悦己侧 | **zero 跨期 / zero 目标 / zero 进度环 / zero 排名 / zero 连续打卡 / zero 成就框定** —— 绝对清洁 |
| 悦己跨期 | **绝对禁止**（悦己跨期 = 成就压力，才是 ADR-012 真正守护的毒性红线） |

### 必需的后续动作（Phase 45 实施前）

- 本 carve-out 须作为 **`## Update YYYY-MM-DD` append** 补入 `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md`，**遵循项目 append-only ADR 规则**（ADR 在「已接受」后只能 append，不改原决策正文）。
- **本门不编辑 ADR-012 本体** —— 仅在此记录决定 + 必需 follow-up。
- amendment 须在 **Phase 45（外壳实施）之前**完成，否则支出趋势的跨期实现会与 ADR-012 §4 静默冲突。

### 来源链
1. `mocks/round2/ROUND2-DECISION.md` — 用户在被告知约束后选定该支出侧跨期例外，记为「须在 GATE-04 ADR go/no-go 中作为一条记录在案的决定纳入，而非静默违规」。
2. `mocks/selected/selected-adr012-audit.md` — 选定方向自审把该例外 carry-forward，判定 PASS（含此例外）。
3. **本文档** — GATE-04 正式 record + 指定 Phase 45 前的 ADR-012 amendment follow-up。

---

## 汇总

| 决策 | 结论 | 依据 | Follow-up |
|---|---|---|---|
| JOY-04 持久化新 ADR | **NO-GO** | D-06：静态只读 → 无持久化 → 无加密/隐私含义 | 无（v1.8 no-Drift, presentation-only） |
| 支出侧跨期趋势 | **GO**（记录在案的 ADR-012 amendment） | GATE-03 选定 + ROUND2-DECISION 用户批准例外 | Phase 45 前以 `## Update` append 补入 ADR-012；本门不改 ADR-012 本体 |

---

**示例数据声明:** 本门无真实数据；选定设计金额为虚构模拟（SIMULATED，威胁 T-43-01）。
