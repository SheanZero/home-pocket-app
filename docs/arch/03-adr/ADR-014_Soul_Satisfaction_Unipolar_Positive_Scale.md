# ADR-014: Soul Satisfaction Unipolar Positive Scale

**文档编号:** ADR-014
**文档版本:** 1.0
**创建日期:** 2026-05-01
**最后更新:** 2026-05-01
**状态:** 📝 草稿
**决策者:** Architecture Team / v1.1 Happiness Metric Working Group
**影响范围:** 数据库 schema v15→v16, 灵魂账本满足度语义, satisfaction picker, voice satisfaction estimator
**相关 ADR:** ADR-002 (Database Solution), ADR-012 (No Gamification v1.1), ADR-013 (Joy Density PTVF Scaling)

---

## 📋 状态

**当前状态:** 📝 草稿
**决策日期:** 2026-05-01
**实施状态:** Phase 9 起草；Phase 12 milestone close 标记为 `✅ 已接受`
**覆盖需求:** HAPPY-08

本 ADR 在 v1.1 期间锁定 `soul_satisfaction` 的语义迁移。代码、需求修订和 Phase 12 ARB rename pass 可以引用本文解释"为什么默认值是 2 而不是 5"。

---

## 🎯 背景 (Context)

`transactions.soul_satisfaction` 从项目早期开始就是 1-10 分。旧语义是围绕 5 的双向量表：5 表示 "neutral / baseline"，低于 5 表示不满意，高于 5 表示满意。这个模型看似直观，但它把悦己账本的每笔支出变成一次自我评分。

旧默认值 5 还造成了一个数据问题：未评分交易天然聚集在中位点，和用户主动选择 Neutral 的交易落在同一个点。Avg Satisfaction、分布图和未来的默认簇分析都无法区分"用户真的觉得中性"和"用户没有触碰 picker"。

Phase 9 讨论中形成的产品洞察是："让用户的每一笔灵魂支出都是幸福的"。Soul spending 是用户为了自己的精神需求主动选择的支出；量表应该庆祝快乐的程度，而不是给用户一个低分区间来否定自己的选择。

因此，v1.1 采用 Path B：单极正向量表。每笔 soul transaction 至少处于 neutral level；默认值移动到量表底部 2，而不是中位点 5。1-10 的数据库 CHECK 保持不变，但产品解释从"不开心到开心"迁移为"至少中性到最爱"。

---

## 🔍 考虑的方案 (Considered Options)

### 方案 A: 保持 1-10 双向量表，新增 `is_rated` boolean

**结论:** 拒绝。

**理由:** 该方案能区分 default-5 与 user-rated Neutral，但需要新增 schema 字段、迁移 repository/domain/UI 路径，并把一个二元状态永久写入数据库。更重要的是，它保留了"5 是中位，低分代表不开心"的产品困惑。

### 方案 B: Path B 单极正向量表（采用）

**结论:** 采用。

**核心:** 默认值 5 → 2；每笔 soul transaction 至少中性。Picker 继续写入 `{2, 4, 6, 8, 10}`，但 emoji 1 的语义从 Bad 改为 Neutral，作为最小正向档位展示。

### 方案 C: 使用 sentinel value 1 表示 "unrated"

**结论:** 拒绝。

**理由:** 现有 picker 最小写入 2，voice estimator 输出 ≥3，所以 1 目前确实空闲。但 sentinel 会让所有 aggregator、formatter、chart 和空态逻辑都增加 null-coalescing / sentinel 分支。这个复杂度只为区分一个当前产品不需要区分的状态。

### 方案 D: 保持默认值 5，在 UI 层补偿过滤

**结论:** 拒绝。

**理由:** D-01 明确要求 "no backdoor — keep DAO data clean"。在 DAO 或 UI 中偷偷过滤 default-5 会让不同 surface 对同一笔数据产生不同解释，也让未来统计扩展无法信任底层聚合。

---

## ✅ 决策 (Decision)

### Schema semantic migration

- `lib/data/tables/transactions_table.dart` 的 schema 已从 v15 迁移到 v16。
- `soul_satisfaction` 默认值从 `withDefault(const Constant(5))` 改为 `withDefault(const Constant(2))`。
- `CHECK(soul_satisfaction BETWEEN 1 AND 10)` 保持不变。
- 不做数据 backfill。Phase 9 CONTEXT.md 明确记录"现在没有用户使用"，项目处于 pre-launch 状态，真实用户数据风险为零。

### Picker emoji semantic remap

Picker 数值保持 `{2, 4, 6, 8, 10}`，语义从 bipolar 翻转为 unipolar positive：

| Emoji | Value | New label | Old label |
|-------|-------|-----------|-----------|
| emoji 1 | 2 | 中性 / Neutral / 中性 | Bad |
| emoji 2 | 4 | OK / OK / OK | Slightly Bad |
| emoji 3 | 6 | 不错 / Good / 不錯 | Normal |
| emoji 4 | 8 | 满足 / Great / 満足 | Good |
| emoji 5 | 10 | 最爱 / Amazing / 最愛 | Very Good |

Phase 9 只锁定 mapping 与 rationale。5 个 emoji ARB label rename 属于 Phase 12 UI Copy Rename Pass，并会在 `.planning/REQUIREMENTS.md` HAPPY-08 与 Phase 12 ROADMAP 中追踪。

### Picker icon defer

Emoji 1 的 Material icon 应从 `sentiment_very_dissatisfied_outlined` 改为 `sentiment_neutral_outlined`，与新 "Neutral as least-positive" 语义一致。该 icon 变更按 D-11 推迟到 Phase 12，和 ARB label rename 同批处理。

### Default-2 vs picker-Neutral collision

项目接受 default-2 与 picker emoji 1 Neutral 的碰撞（D-10）。v1.1 不需要区分"用户点击了 Neutral"和"用户未点击 picker 直接提交"。产品解释是：每笔悦己支出至少中性，默认状态就是最小正向档。

### Voice estimator realignment defer

`lib/application/voice/voice_satisfaction_estimator.dart` 当前把 voice score 映射到 [3, 10]。在新 picker mapping 下，3/5/7/9 会落在 `{2, 4, 6, 8, 10}` 桶之间。v1.1 接受这个跨模态不一致；voice output range realignment 推迟到 v1.2（D-12）。

---

## 💡 决策理由 (Rationale)

1. **产品哲学一致。** 悦己账本不是考试；它记录用户愿意为自己开心投入的瞬间。单极正向量表表达 celebrating, not grading。
2. **消除默认簇污染。** 默认值不再落在旧中位点 5，Avg Satisfaction 和 distribution 不再把大量 unrated rows 伪装成主动 Neutral。
3. **迁移风险最低。** 项目 pre-launch 且"现在没有用户使用"；schema v15→v16 是单行默认值迁移，无 backfill 风险。
4. **保留数据库约束简单性。** `BETWEEN 1 AND 10` 不变，避免引入 sentinel/null 语义到 every aggregator。
5. **跨模态不一致可接受。** Voice [3,10] 与 picker `{2,4,6,8,10}` 暂时不完全一致，但 picker 的 `_selectedIndex` 会把中间值稳定映射到最近 bucket，UI 渲染确定。

---

## ⚠️ 后果 (Consequences)

### 正面

- 未来 review 可以直接引用 ADR-014 回答"为什么默认值不是 5"。
- Avg Satisfaction 的 v1.1 baseline 更可解释；默认行不会集中在旧 neutral median。
- Phase 12 的 ARB rename 和 icon update 有明确语义来源。
- ADR-012 no-gamification 与 ADR-013 PTVF scaling 共享同一价值观：指标服务于自我理解，而不是压力或排名。

### 负面

- v1.1 接受 picker Neutral 与 default-2 的碰撞，无法区分用户主动点选与未点选。
- Voice estimator 暂时输出 [3,10]，会在 picker bucket 之间产生跨模态不一致。
- 旧字段名 `soul_satisfaction` 仍是 satisfaction，而产品语言迁移为 Joy / 悦己；Phase 12 仅改 ARB values，不改 schema 字段名。

### 中性

- `CHECK 1..10` 仍允许 value=1，但 v1.1 UI 不写入 1；它不是 sentinel，也不具有产品语义。
- 如果未来需要区分 rated/unrated，必须新建 ADR 评估 `is_rated` 或 sentinel，不得隐式复用 1。
- ADR 数量增加一条；Phase 12 closeout 需要把本 ADR 状态从 `📝 草稿` 翻转为 `✅ 已接受`。

---

## 📝 实施计划 (Implementation Plan)

| Milestone / Plan | Work | Status |
|------------------|------|--------|
| Phase 9 plan 09-01 | Schema migration v15→v16; `Constant(5)` → `Constant(2)`; update 5 code-side defaults; add Drift migration test | Completed in Phase 9 |
| Phase 9 plan 09-13 | Amend REQUIREMENTS.md HAPPY-08 with emoji ↔ value mapping table and unipolar positive wording | Planned |
| Phase 12 | Rename 5 satisfaction emoji ARB labels across ja/zh/en per table above | Planned |
| Phase 12 | Change picker emoji 1 icon from `sentiment_very_dissatisfied_outlined` to `sentiment_neutral_outlined` | Planned |
| v1.2 | Realign voice estimator output range with picker buckets if post-launch data shows friction | Deferred |
| Phase 12 close | Flip ADR-014 status from `📝 草稿` to `✅ 已接受` after ARB/icon closeout | Planned |

---

## 🔗 相关实现与需求引用

- `lib/data/tables/transactions_table.dart` — `soulSatisfaction` default is `Constant(2)` and CHECK remains `BETWEEN 1 AND 10`.
- `lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart` — picker writes `{2, 4, 6, 8, 10}` and `_selectedIndex` buckets in nearest-even ranges.
- `lib/application/voice/voice_satisfaction_estimator.dart` — voice maps score to [3,10], deferred to v1.2 for realignment.
- `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` — same v1.1 milestone philosophy: no pressure, no grading, no Goodhart target.
- `docs/arch/03-adr/ADR-013_Joy_Density_PTVF_Scaling.md` — same Phase 9 formula layer; Joy/¥ math assumes the new satisfaction semantics.
- `.planning/REQUIREMENTS.md` HAPPY-08 — mapping table amendment target.
- `.planning/ROADMAP.md` Phase 12 — ARB rename pass and picker icon change target.

---

*最后审查日期: 2026-05-01*
*下次审查触发: Phase 12 closeout 或 v1.2 milestone start*
