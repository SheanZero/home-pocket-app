# GATE-03 — 方向选定（Direction Selection）

**Phase:** 43-html-design-gate-no-production-code
**写于:** 2026-06-16
**性质:** 设计门出口记录。GATE-03「选定恰好一案」的闭合凭证。一次性设计产物，**无生产代码**。
**关卡核心问题（本门要关闭）:**「为自己花钱而开心」如何在 ADR-012 恒久反游戏化约束下表达。

---

## 选定方向（恰好一案）

**选定 = round-5 B（M2 衍生）。**

用户 review 原始 5 案（M1 实用主导 / M2 均衡 / M3 极简实用派 / M4 温暖反思派 / M5 故事画报派）后，**未在原始 5 案里直接选定**，而是以 **M2 均衡**为底提出 5 条修改方向，经 round2→round5 迭代收敛到变体 B「主环 + 悦己横向堆叠分段条」。因此 GATE-03 的「恰好一案」闭合在 **round-5 B（M2 衍生）**上，而非任一原始 M1–M5 as-is。

| 项 | 值 |
|---|---|
| **选定来源轴** | M2 均衡（沿 M1–M5 强度轴的"适中悦己浓度"衍生） |
| **最终定稿目录** | `.planning/phases/43-html-design-gate-no-production-code/mocks/selected/` |
| **定稿三件套** | `selected-light.html` · `selected-dark.html` · `selected-adr012-audit.md`（+ `README.md`） |
| **迭代留痕** | `mocks/round2/ROUND2-DECISION.md`（5 条修改方向 + 三处岔口决定） |
| **ADR-012 自审判定** | **PASS**（见 `selected/selected-adr012-audit.md`，含一处记录在案的支出跨期例外） |

---

## 用户明确批准

> **用户明确批准语句:「approved（通过）」。**

用户在 review round-5 B 的浅色 + 深色定稿 + ADR-012 自审表后，给出显式批准「approved」/「通过」。门出口条件（用户批准 + 仓库零生产代码）满足。

---

## 选定设计一句话描述（round-5 B）

支出趋势置顶（纯 CSS pill tabs：总支出 / 日常 / 悦己）→ 加粗的支出分类圆环 hero（中心「本月支出 ¥248,600」，10 个 level-1 分类金额降序，无悦己合计拆分）→「悦己花在哪」横向堆叠分段条（悦己 ¥47,200 在主 level-1 分类的严格子集间构成，单列图例，可辨暖色相）→ 小确幸日历热力（在分类节之后）→ 满足度分布直方图。**无悦己占比 · 无「值得卡」· 无记忆故事。**

---

## D-11 首要标准 — 选定理由

D-11 锁定首要评判 = **悦己情感共鸣 / 实用性 / ADR-012 安全度**（复用度/低成本为次要上下文，不进首要标准）。

### 悦己情感共鸣
悦己以**描述性**方式表达——通过「悦己花在哪」横向堆叠条（去向）+ 满足度分布 + 小确幸日历纹理，**庆祝过去（celebrate-past）**，从不目标/成就驱动。不画「值得卡」headline 数字、不画记忆故事，避免把悦己做成"分数感/成就感"。这正是「为自己花钱而开心」的 ADR-012-safe 表达方式：呈现"已经发生的滋养"，不催促、不打分、不较劲。

### 实用性
趋势置顶 + level-1 分类金额降序 + 下钻 affordance（drill 暗示）。支出侧给到实用预算判断的骨架，与首页支出统计语义对齐，practical-first。

### ADR-012 安全度
悦己侧**全部 ambient / 描述性**：无目标环、无跨期对比、无排名、无连续打卡（streak）、无成就框定。**唯一**使用跨期的是支出趋势（总支出 / 日常 tab），这是一处**记录在案、用户批准的 ADR-012 §4 例外**（见下节），严格限于支出侧；悦己侧 zero 跨期。

---

## ⚠ ADR-012 §4 跨期例外（记录在案，非违规）

选定设计在 `支出趋势` 的 **总支出 / 日常** 两个支出侧 tab 含 **本月 vs 上月** 累计折线。这**放宽**了 ADR-012 §4「绝不 surface previousMonthComparison / 不画跨期 delta」的一条规则——但**仅限支出侧**（实用预算 parity，与首页支出趋势对齐）。**悦己 tab 与所有悦己元素保持 cross-period-free。**

- 用户在被**明确告知此冲突三次**后**刻意选择**保留该支出侧跨期。
- 决定来源：`mocks/round2/ROUND2-DECISION.md`（三处设计岔口表 · 第 1 行）。
- **此例外须在 GATE-04 ADR go/no-go 中作为一条记录在案的决定纳入**（见 `GATE-04-adr-go-no-go.md`），并在 Phase 45 实施前作为 ADR-012 的 `## Update` append 补正——不在本门改 ADR-012 本体。

---

## 门出口硬条件 — 无生产代码证据（EMPTY gate）

出口硬条件：**仓库无新增 `.dart`/`pubspec`/`lib`/`test` 改动**。验证命令与输出：

验证命令：
`git diff --name-only $(git log --oneline --grep="43-01" --format=%H | tail -1)~1 HEAD | grep -E '\.dart$|pubspec\.(yaml|lock)|/lib/|/test/'`

**输出 = （空）。** grep 无匹配（exit code 1），证明 Phase 43 从首个 43-01 commit 至 HEAD **零** `.dart`/`pubspec`/`lib`/`test` 改动。

phase 43 全部变更**仅** `.md` 与 `.html`，且全部落在 `.planning/` 下（实测文件类型分布：20 个 `.html` + 24 个 `.md`，非 `.planning/` 文件数 = 0）。门出口硬条件满足。

---

## Pencil 关键帧精细化 — 仅编排者手动（非 executor 任务）

选定方向若需 Pencil 关键帧精细化（D-08），**必须**在主 session 由编排者手动完成：

- executor 子代理**访问不到** `mcp__pencil__*`（claude-code#13898）；
- 本环境 Pencil MCP 无法落盘。

因此 Pencil 步骤**绝不**排为 executor task。HTML 定稿（`selected/*.html`）才是本门可交付、可版本控制、可截图 UAT 的主产物；Pencil 仅为选定后的可选增强，由编排者在主 session 处置。

---

## 下游影响

GATE-04 三份决策文档（`GATE-04-adr-go-no-go.md` / `GATE-04-emotion-wordlist.md` / `GATE-04-flchart-affordance-verification.md`）**scope 到本选定方向（round-5 B）的图表与情感元素**。Phase 44（数据）→ 45（外壳）→ 46（卡片）→ 47（i18n/反毒性扫描）以此选定方向落地。

---

**示例数据声明:** `selected/*` 全部金额为虚构模拟（SIMULATED），非任何真实用户财务数据（威胁 T-43-01 红线）。
