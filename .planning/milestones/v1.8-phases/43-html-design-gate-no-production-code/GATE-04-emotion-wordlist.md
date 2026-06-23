# GATE-04 (b) — 情感词表锁定（Calm-Warm Forbidden-Substring List）

**Phase:** 43-html-design-gate-no-production-code
**写于:** 2026-06-16
**Scope:** GATE-03 选定方向 round-5 B（M2 衍生）
**性质:** 设计门决策记录。**无生产代码**（本门不写测试）。锁定 calm-warm register 禁词，供 **Phase 47** 扩充 anti-toxicity 反毒性扫描。
**Register（D-04）:** calm-warm 平静温暖 —— 像日记，克制、不外放、不打分、不制造"分数感"。

---

## 1. 现有锁定禁词（restate — 不放宽）

来源实测：`test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart`（D-14 比较/评判词）+ `anti_toxicity_phase17_test.dart`（数据质量评判词）。**这些已锁定，GATE-04 不放宽。**

### Phase 16 — 比较 / 名次 / 评判词

| 语言 | 锁定禁词 |
|---|---|
| **EN** | `better` `worse` `winner` `loser` `vs` `versus` `compare` `comparison` `higher is good` `lower is bad` `score` `rank` `ranking` `wins` `loses` |
| **ZH** | `更好` `更差` `赢` `输` `胜` `败` `vs` `对比` `比较` `排名` `分数` `胜出` `落败` |
| **JA** | `勝ち` `負け` `より良い` `より悪い` `比較` `対決` `スコア` `ランキング` `勝つ` `負ける` |

### Phase 17 — 数据质量评判词（针对 variant chip）

| 语言 | 锁定禁词 |
|---|---|
| **EN** | `less accurate` `invalid` `unreliable` `less valid` `inaccurate` `wrong` |
| **ZH** | `不准` `不可靠` `不完整` `质量差` `估算不准` `错误` |
| **JA** | `不正確` `信頼できない` `不完全` `精度が低い` `誤り` |

---

## 2. Calm-Warm 新增禁词（GATE-04 锁定）

因选定方向引入新的悦己措辞（悦己花在哪 / 满足度分布 / 小确幸日历），以下 calm-warm 红线词作为**新增**禁词锁定，供 Phase 47 纳入 analytics 侧扫描。

| 语言 | 新增禁词 |
|---|---|
| **ZH** | `最棒` `最好` `超过` `达成` `目标`※ `连续` `成就` `排行` `第一` |
| **EN** | `best` `top` `beat` `most` `streak` `achievement` `goal` `target`※ `unlock` |
| **JA** | `最高` `達成` `連続` `目標`※ `ベスト` |

※ `目标 / target / 目標` —— **见 §3 的 analytics-only 边界。这是有条件锁定，不可无差别全局封禁。**

**红线对应（为何这些是 calm-warm 红线）:**

| 禁词族 | 触碰的 ADR-012 红线 |
|---|---|
| `最棒/最好/best/top/第一/排行/ranking` | §6 排名 / 名次框定（best=排名） |
| `超过/beat/达成/达标/achievement/成就` | §4 跨期"超过"评判 + 成就框定 |
| `连续/streak/連続` | §1 连续打卡 streak |
| `目标/goal/target/目標` | §3 daily target / 目标设定（**仅 analytics 侧**，§3 carve-out） |
| `unlock` | §2 离散解锁 / 徽章成就 |

---

## 3. ⚠ CRITICAL — `target / 目标 / 目標` 的 analytics-only 边界

**`target / 目标 / 目標` 的封禁严格 scope 到 ANALYTICS widgets ONLY。绝不可无差别全局封禁。**

| 上下文 | `target / 目标` 是否合法 | 依据 |
|---|---|---|
| **HomeHero** 的 `monthly_joy_target` ambient 填充环 | ✅ **合法 —— 不可封禁** | ADR-016 §3「HomeHero 同心环 = 单月内 Σ joy_contribution 累加进度环」+ §4「目标值机制 / `user_settings.monthly_joy_target`」。HomeHero 独占唯一合法 target ring |
| **Analytics 侧**（本里程碑全部选定方向元素） | ❌ **禁止引入 target 措辞** | JOY-01 硬约束（D-03）：analytics 侧绝不放进度环 / 目标。选定方向悦己侧已 zero target |

**操作约束（Phase 47 落地时必须遵守）:**

- `target / 目标 / 目標` 的扫描**只**加入 **analytics widget** 的 `_sweepForbiddenSubstrings` 范围（如 `category_spend_donut_chart` / `satisfaction_distribution_histogram` / 悦己堆叠条 / 小确幸日历等选定方向卡）。
- **绝不**把这三个词加入 HomeHero 的扫描范围 —— 否则会误伤 ADR-016 §3-§4 的合法 `monthly_joy_target` ambient ring copy，破坏既有合法功能。
- 本新增是**扩充 analytics 侧扫描**，**不**扩到 HomeHero scope。

> 这是 T-43-06（over-banning target/目标）的 mitigate：扫描范围隔离，使合法的 HomeHero 环不被下游误封。

---

## 4. 选定方向（round-5 B）措辞自检 —— 应全部干净

选定方向已设计为 calm-warm，对照本词表应无命中。逐元素抽检：

| 元素 | 用词倾向 | 命中禁词？ |
|---|---|---|
| 支出趋势 tabs（总支出/日常/悦己） | 中性「本月/上月」（支出侧）；悦己单月单线「不与过往比较」 | ❌ 无（中性，无超过/目标/达标） |
| 支出分类环 hero | 「钱花在哪」构成占比；降序仅为可读性排布 | ❌ 无（无"第一/最高/排行"名次词） |
| 悦己横向堆叠条「悦己花在哪」 | 「仅呈现去向，不分高下」 | ❌ 无（largest→smallest 是排布非名次） |
| 小确幸日历热力 | 「只看哪些天发生过，不数连续、不比多少」 | ❌ 无（显式非 streak） |
| 满足度分布直方图 | 「满足度落点的形状」+ 中位（calm 描述） | ❌ 无（无"目标 8+"/达成） |

---

## 5. Phase 47 接线说明（本门不写测试）

- **模板:** `anti_toxicity_phase16_test.dart` 的 `_sweepForbiddenSubstrings`（pump 整卡 → `find.textContaining(substring, findRichText: true)` → `findsNothing`）是新卡扫描范本。
- **Phase 47** 将以此模板把选定方向的每张新 analytics 卡纳入扫描，并把本文档 §2 的 calm-warm 新增禁词接入 analytics 侧扫描列表，**遵守 §3 的 `target/目标` analytics-only 边界**。
- **本阶段零测试代码** —— 本文档仅锁定词表与边界，供 Phase 47 落地。

---

**示例数据声明:** 本门无真实数据；词表锁定为设计决策记录。
