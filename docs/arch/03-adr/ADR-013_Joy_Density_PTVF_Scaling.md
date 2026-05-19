# ADR-013: Joy Density PTVF Scaling

**文档编号:** ADR-013
**文档版本:** 1.0
**创建日期:** 2026-05-01
**最后更新:** 2026-05-01
**状态:** 📝 草稿
**决策者:** Architecture Team / v1.1 Happiness Metric Working Group
**影响范围:** v1.1 happiness metric layer (HAPPY-02), AnalyticsDao 性能预算, Joy/¥ 展示格式
**相关 ADR:** ADR-002 (Database Solution), ADR-011 (Codebase Cleanup Initiative Outcome), ADR-012 (No Gamification v1.1)

---

## 📋 状态

**当前状态:** 📝 草稿
**决策日期:** 2026-05-01
**实施状态:** Phase 9 formula layer drafting; Phase 12 milestone close flips this ADR to `✅ 已接受`
**覆盖需求:** HAPPY-02

本 ADR 在 v1.1 期间作为公式实现的约束文档使用。代码可以引用本 ADR 的 α、base 表、Dart-layer fold 原因和性能例外；正式接受状态等 Phase 12 closeout 统一 ratify。

---

## 🎯 背景 (Context)

v1.1 的核心目标是把「花钱的幸福」从模糊感觉变成可计算、可展示的指标。最初的 `Σ satisfaction / Σ amount` 朴素密度容易让 ¥10 糖果稳定压过 ¥10000 旅行：小金额分母过小，导致中等满足度的小支出获得夸张分数。

HAPPY-02 需要同时满足两条产品直觉：

1. 小确幸应该被看见，金额不能简单等于快乐。
2. 用户明确说过：「虽然小东西会让人开心，但也要鼓励为了自己的开心花更多的钱」。

讨论中另一个锚点是用户的「10000 的 10 是 50」直觉：一笔 sat=10、amount=10000 的灵魂支出不应该因为金额大就被 sat=6、amount=500 的支出轻易压过。研究比较显示，要让 `sat=10 ¥10000` 击败 `sat=6 ¥500`，幂指数的 critical threshold 约为 `α ≈ 0.83`。

因此，公式需要是金额的次线性缩放，但不能像平方根那样压得过平。Kahneman-Tversky Prospect Theory Value Function 的 `α=0.88` 刚好越过临界值，并且它不是拍脑袋常数，而是 Kahneman & Tversky 1979 论文给出的经验拟合参数。

数据库层也带来实现约束：SQLite 标准函数没有 `POW` / `EXP`，所以 SQL 层直接计算 `(amount / base)^0.88` 不可移植。Phase 9 因此选择 DAO 返回行级 `(amount, soul_satisfaction)`，由 Dart use case 层 fold 成最终 Joy/¥ 密度。

---

## 🔍 考虑的方案 (Considered Options)

### 方案 A: 朴素 `Σsat / Σamount`

**结论:** 拒绝。

**原因:** 分母直接使用金额会让极小支出完全主导。¥10 糖果可以轻易超过 ¥10000 旅行，违背「也要鼓励为了自己的开心花更多的钱」的产品意图。

### 方案 B: sqrt scaling (`α=0.5`)

**结论:** 拒绝。

**原因:** Stevens 1957 psychophysical power law 支持幂律作为候选方向，但 `α=0.5` 对金额压缩太强，低于本讨论中的 `α ≈ 0.83` 临界值。它保留了「小金额过度占优」的问题。

### 方案 C: log Weber-Fechner

**结论:** 拒绝。

**原因:** log 方案表达「边际感知递减」很自然，但在 `amount → 0` 附近需要额外平移或 clamp；一旦加入人为 offset，就会产生新的 magic number，比 PTVF 更难解释和测试。

### 方案 D: Prospect Theory Value Function (`α=0.88`)

**结论:** 采用。

**原因:** `α=0.88` 满足临界约束，保留金额的正向影响，同时仍然是次线性缩放。该值来自 Kahneman & Tversky 1979 的经验拟合，未来如果调参，也有清晰的学术与产品基线可回看。

### 方案 E: SQL-layer PTVF

**结论:** 拒绝。

**原因:** SQLite 标准函数没有 `POW` / `EXP`。把 PTVF 放进 SQL 会引入平台差异、扩展函数依赖或手写近似。Dart-layer fold 更可测、更可维护。

---

## ✅ 决策 (Decision)

HAPPY-02 Joy/¥ 密度采用 PTVF 幂律金额缩放：

```text
density = Σ (soul_satisfaction × (amount / base)^0.88) / Σ amount
```

币种 base 表固定如下：

| Currency | Base |
|----------|------|
| JPY | 500 |
| CNY | 25 |
| USD | 5 |
| fallback | 500 |

实现位置与边界：

- **Base + display unit co-located:** `lib/infrastructure/i18n/formatters/joy_density_formatter.dart` 同时维护 PTVF base 与展示单位（D-20）。
- **Math layer:** Dart use case layer。DAO 返回行级金额与满足度；`lib/application/analytics/get_happiness_report_use_case.dart` fold 出密度。
- **DAO contract:** `lib/data/daos/analytics_dao.dart` 暴露 row-wise PTVF input query，继续复用 soul-only 过滤约束。
- **Domain value:** `MetricResult<double> joyPerYen` 存 raw density，不在 domain model 中做展示单位归一化。

---

## 💡 决策理由 (Rationale)

1. **经验锚点清楚。** Kahneman, D. & Tversky, A. (1979). "Prospect Theory: An Analysis of Decision under Risk." *Econometrica*, 47(2), 263–292. 给出 `α=0.88` 作为 value function 的经验拟合值；本项目直接采用该常数，避免后续把 `0.88` 当作无法解释的 magic number。

2. **满足本产品的双约束。** `α ≈ 0.83` 是让 `sat=10 ¥10000` 击败 `sat=6 ¥500` 的临界附近；`α=0.88` 刚好越过它。它仍然允许小确幸有高密度，但不会让高满足度的大额悦己支出被系统性低估。

3. **保留 psychophysical power-law 解释。** Stevens, S. S. (1957). "On the psychophysical law." *Psychological Review*, 64(3), 153–181. 支持幂律感知作为备选理论来源；本 ADR 拒绝 `sqrt α=0.5`，不是拒绝幂律本身。

4. **与 Prospect Theory 后续文献一致。** Tversky, A. & Kahneman, D. (1992). "Advances in prospect theory: Cumulative representation of uncertainty." *Journal of Risk and Uncertainty*, 5(4), 297–323. 延续了累积前景理论中的价值函数思路，使本项目的金额缩放解释保持一致。

5. **Dart-layer fold 可测试。** `pow(amount / base, 0.88)` 在 Dart use case 中是普通数值代码，可以用 n=0 / n=1 / mixed amounts / multi-currency fixtures 精确测试；SQL 扩展函数路径会让测试与运行时环境耦合。

6. **币种 base 与展示单位同源。** `joy_density_formatter.dart` 同时放 base 和 display unit，避免 JPY/CNY/USD 未来扩展时出现公式层和展示层分叉。

---

## ⚠️ 后果 (Consequences)

### 正面

- Joy/¥ 不再被 ¥10 级别小金额系统性劫持。
- `α=0.88` 有明确引用来源，降低未来「0.5 更简单，换掉吧」的反复争论成本。
- `MetricResult<double> joyPerYen` 保持 raw value，Phase 10 / Phase 11 可以自由决定 tile hierarchy 与 chart formatting。
- 多币种支持从第一版就有 JPY / CNY / USD / fallback 的明确基线。

### 负面（接受的性能权衡）

- DAO 为 PTVF 增加 row-wise query，违反 v1.0 cleanup 后形成的「DAO uses SUM/GROUP BY for <2s performance」原则。
- 接受理由：月度 soul transaction 数通常是每 book 10-100 行；在这个数据量下，把 `(amount, soul_satisfaction)` 返回到 Dart 层 fold 的开销可以忽略。
- 如果未来月度 soul tx 中位数超过 1000，必须重新 review：可考虑 materialized aggregate、预计算字段或平台可控的数学函数策略。

### 中性

- 公式比 `Σsat/Σamount` 更难口头解释，UI 文案需要把它表达为「幸福密度 / Joy per ¥」而不是暴露数学细节。
- EUR / GBP / KRW 等 base 暂不纳入 v1.1；fallback=500 让系统有安全默认值，但未来新增币种仍需明确产品确认。
- ADR 数量增加一条；Phase 12 closeout 需要把本 ADR 状态从 `📝 草稿` 翻转为 `✅ 已接受`。

---

## 📝 实施计划 (Implementation Plan)

| Area | File | Responsibility |
|------|------|----------------|
| DAO | `lib/data/daos/analytics_dao.dart` | Add row-wise PTVF input query; keep soul-only filter centralized; document SUM/GROUP BY exception in code comments only if needed. |
| Repository interface | `lib/features/analytics/domain/repositories/analytics_repository.dart` | Expose PTVF input rows through analytics domain contract. |
| Repository impl | `lib/data/repositories/analytics_repository_impl.dart` | Map DAO rows to domain/application-friendly values without adding formula logic. |
| Use case | `lib/application/analytics/get_happiness_report_use_case.dart` | Apply `density = Σ (soul_satisfaction × (amount / base)^0.88) / Σ amount`; emit `MetricResult<double> joyPerYen`. |
| Formatter | `lib/infrastructure/i18n/formatters/joy_density_formatter.dart` | Co-locate PTVF base lookup and display unit formatting. |
| Tests | `test/unit/application/analytics/get_happiness_report_use_case_test.dart` | Cover n=0, n=1, mixed values, all sat=10, and JPY/CNY/USD/fallback base behavior. |
| Tests | `test/unit/infrastructure/i18n/formatters/joy_density_formatter_test.dart` | Pin base lookup and display-unit labels. |
| Milestone close | `docs/arch/03-adr/ADR-013_Joy_Density_PTVF_Scaling.md` | Phase 12 status flip from `📝 草稿` to `✅ 已接受` after implementation and UI copy close. |

**Review timestamp:** 2026-05-01T00:00:00Z
**Next-review timestamp:** v1.2 milestone start or when monthly soul tx median exceeds 1000

---

## Update 2026-05-19: Superseded by ADR-016 §2

**Status:** density (Joy/¥) as principal Joy metric — **superseded**. Underlying PTVF scaling formula (single-tx contribution) — **retained and re-used** by ADR-016.

### What changed

ADR-016 (Joy Metric Visualization Redesign, 2026-05-19 ratify) replaces the **density** output of this ADR with a **cumulative sum** output:

- **This ADR (ADR-013) defined:** `density = Σ (soul_satisfaction × (amount / base)^0.88) / Σ amount` — a ratio
- **ADR-016 §2 redefines the principal Joy metric as:** `Σ joy_contribution = Σ (soul_satisfaction × (amount / base)^0.88)` — the same numerator, but **not divided by Σ amount**

The PTVF scaling — `soul_satisfaction × (amount / base)^0.88` — remains the per-transaction Joy contribution formula. Only the **aggregation step** changed: the global divisor (Σ amount) is removed.

### Trigger

User feedback on 2026-05-18 home review (item 3): "重新设计 Joy 的计算方式，看是否用 sum 会更好一些，同时要考虑在同心环中的显示，要能不断累加，让用户有成就感". The density metric, while mathematically defensible as a per-yen efficiency measure, did not surface "accumulation" — a UX property the user explicitly wanted for HomeHeroCard's concentric ring.

### What this means in code

The following components defined by ADR-013 §📝 实施计划 will change during the v1.2 "Joy metric migration" phase (see ADR-016 §7):

- `lib/application/analytics/get_happiness_report_use_case.dart` — fold logic changes (numerator only, no `/ Σ amount`); return type adjusts
- `lib/data/daos/analytics_dao.dart` — query may simplify (no longer requires `Σ amount` dimension)
- `lib/infrastructure/i18n/formatters/joy_density_formatter.dart` — to be replaced by a cumulative-sum formatter (integer + thousands separator)
- All tests that pin `joyPerYen: density` output need updating to `joyCumulative: int` semantics

### What is preserved

- The PTVF rationale (`amount^0.88` to dampen amount dominance) is preserved per-transaction
- Soul-only filtering (this ADR's filter conventions) is preserved
- The §🚫 已知局限 in this ADR remains valid for the per-transaction contribution function

### Why this ADR stays ✅ 已接受 (not 已废弃)

Per project ADR conventions (`.claude/rules/arch.md`):
- ADRs in ✅ 已接受 are append-only — status cannot be reverted
- The per-transaction PTVF scaling formula defined here is **actively re-used** by ADR-016, so this ADR is not废弃
- Supersede is **scoped to the aggregation step only** (density → cumulative sum), not the underlying math

Future readers: when implementing or auditing Joy metric, **read ADR-016 first** for the current contract, then ADR-013 for the per-transaction scaling rationale that ADR-016 inherits.

**Update author:** xinz + Architecture Team (Claude)
**Update review timestamp:** 2026-05-19
