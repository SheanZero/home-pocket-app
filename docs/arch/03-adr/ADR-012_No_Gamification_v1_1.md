# ADR-012: No Gamification v1.1

**文档编号:** ADR-012
**文档版本:** 1.0
**创建日期:** 2026-05-01
**最后更新:** 2026-05-01
**状态:** 📝 草稿
**决策者:** Architecture Team
**影响范围:** v1.1 happiness metric surfaces (HomePage, AnalyticsScreen), product roadmap, future feature reviews
**相关 ADR:** ADR-007 (Layer Responsibilities), ADR-013 (Joy Density PTVF Scaling), ADR-014 (Soul Satisfaction Unipolar Positive Scale)

---

## 📋 状态

**当前状态:** 📝 草稿
**决策日期:** 2026-05-01
**实施状态:** Phase 9 起草；Phase 12 milestone close 标记为 `✅ 已接受`

---

## 🎯 背景 (Context)

v1.1 milestone 引入 4 个个人幸福度指标与 2 个家庭合作型聚合指标。个人侧包括 Avg Satisfaction、Joy per ¥、Highlights count、Best Joy per ¥；家庭侧包括 Family Highlights Sum 与 Shared Joy Insight。这些指标覆盖 HAPPY-01..04 与 FAMILY-01..02，目标是让 HomePage 与 AnalyticsScreen 能围绕悦己账本的真实满足感组织信息，而不是围绕金额大小或记账频率制造压力。

行业中的常见做法是把指标包装成 gamification surface：streaks、badges、daily targets、排行榜、跨周期涨跌提示。它们通常能抬高短期 engagement，却会损害长期指标有效性。Goodhart's Law 指出："When a measure becomes a target, it ceases to be a good measure." 如果 satisfaction score 变成徽章、连续打卡或每日目标的触发器，用户优化的对象会从"真实满足感"转向"保持指标漂亮"。

Home Pocket 的场景比普通单用户 habit app 更敏感。它处理的是家庭财务数据，而家庭成员之间的金钱、快乐和贡献感本就容易被误读。任何 per-member breakdown、leaderboard、公开分享或跨周期 delta surface 都可能把合作型洞察变成比较型压力，尤其是在家庭模式下。

用户约束来自 Phase 9 CONTEXT.md 的 specifics 部分："让用户的每一笔灵魂支出都是幸福的"。这句话定义了 v1.1 幸福指标的产品伦理：celebrating, not grading。悦己账本应该帮助用户看见哪些支出真正滋养自己，而不是要求用户每天达标、连续打卡或证明自己比上月更快乐。

因此，本 ADR 明确落实 `.planning/REQUIREMENTS.md` 中的 HAPPY-07，并复述 REQUIREMENTS.md "Out of Scope" 的 anti-feature 清单：streaks / badges / daily satisfaction targets、cross-period delta on home tile、public sharing of happiness metrics、per-member breakdown surfaces。这些禁令在 v1.1 milestone close 前具有约束力。

---

## 🔍 考虑的方案 (Considered Options)

### 方案 A：完全无游戏化（采用）

**核心：** 显式禁止 streaks / badges / daily targets / 跨周期对比 / 公开分享 / 按成员细分。

**优势：**
- 长期数据有效性保护（Goodhart's Law 防御）
- 家庭场景下的反比较伦理一致
- 减少未来 PR 审查负担：可直接引用本 ADR 拒绝相关请求

### 方案 B：温和游戏化（轻量徽章 / 周报）

**拒绝原因：** 一旦开门，徽章会蔓延为周徽 → 月徽 → leaderboard。"温和" 不是稳定平衡点。

### 方案 C：让用户自选（opt-in 设置）

**拒绝原因：** opt-in 同样会引入 UI surface 与代码路径，反而强化"游戏化是合理选项"的认知。零选项更便宜也更清晰。

---

## ✅ 决策 (Decision)

**v1.1 milestone 期间，禁止任何形式的游戏化激励机制。**

具体禁令见下文 `## 🚫 Forbidden Features (Permanent)` 章节。

本决策对 v1.1 milestone 内所有 PR 具有约束力。如果未来 milestone 希望放开某项禁令，必须通过新 ADR 显式废止本 ADR 中对应条目，不得通过 PR 隐式绕过。

---

## 💡 决策理由 (Rationale)

1. **Goodhart's Law (Goodhart 1975)：** "When a measure becomes a target, it ceases to be a good measure." 一旦 satisfaction score 成为 streak / 徽章触发条件，用户行为优化的对象会从 "真实满足感" 偏移到 "保持连续记账"。
2. **家庭场景的反比较伦理：** 家庭成员之间的快乐指标对比（leaderboard）具有比单用户场景更强的破坏潜力——"为什么我妈这个月的 Joy 分数比我高？" 是类型系统都无法挽救的关系问题。
3. **数据有效性保护：** v1.1 是收集第一批真实快乐数据的阶段，metric 必须未受激励扭曲；这数据将驱动 v1.2 的算法调整（α=0.88 是否仍合适）。
4. **审查成本节省：** 显式拉黑列表减少未来争论次数，让团队聚焦在真正有意义的产品问题。

引用：
- Goodhart, C.A.E. (1975). "Problems of Monetary Management: The U.K. Experience." *Papers in Monetary Economics*, Reserve Bank of Australia.
- Strathern, M. (1997). "Improving ratings: audit in the British University system." *European Review*, 5(3), 305-321. (Goodhart 在审计语境的扩展引用)
- Cabinet Office (UK) (2010). "Wellbeing and Policy." — 国家级幸福度量的政策研究背景；提供 cross-period delta 的反例参考

---

## ⚠️ 后果 (Consequences)

**正面：**
- v1.1 metric 数据未受激励扭曲，可作为 v1.2 算法调优的纯净基线
- 未来 PR 评审有明确依据
- 家庭场景下的比较风险消除

**负面：**
- 短期 DAU 提升的"easy win" 不被允许
- 部分用户可能反馈"too plain"——通过 UX 文案与 onboarding 缓解，而不是补回游戏化
- 团队在产品会议上需要主动反驳重新引入游戏化的提议

**中性：**
- v1.2 milestone 启动时必须重新评估本 ADR 是否仍适用；若届时仍坚持，append `## Update YYYY-MM-DD: v1.2 carryover` 段落

---

## 🚫 Forbidden Features (Permanent)

以下功能在 v1.1 milestone 期间禁止实现。任何 PR 引入这些功能时，可直接以 "ADR-012" 拒绝。

1. **Streaks（连续打卡）** — 例如"连续记账 7 天获得徽章"。Goodhart 的核心场景。
2. **Badges / 成就系统** — 包括首次记账徽章、满月徽章、节日徽章等任何成就感触发。
3. **Daily satisfaction targets（每日幸福目标）** — "今天目标 8 分以上"或类似。
4. **Cross-period delta on home tile** — 例如 "vs 上月 +3.2 Joy 分"。引发自我评判。
5. **Public sharing of happiness metrics** — 一切对外暴露快乐指标的功能（社交分享、链接生成等）。
6. **Per-member breakdown surfaces（家庭成员细分页面）** — leaderboard、贡献图、按成员排序的列表。已通过类型系统强制（FamilyHighlightsSum: int, SharedJoyInsight: 3-tuple）；本条 ADR 复述以防未来 PR 想绕过类型契约。
7. **"幸福度评级历史" / 历史趋势对比** — 跨月跨年的 Joy 指标对比图。

每条禁令的具体边界由 PR 评审人判断；当不确定时，向 ADR 起草人或 Architecture Team 求助。

---

## 📝 实施计划 (Implementation Plan)

| Step | Owner | Status |
|------|-------|--------|
| Phase 9: 起草本 ADR + ADR-013 + ADR-014 | Architecture Team | Phase 9 plan 09-10 |
| Phase 9: REQUIREMENTS.md / ROADMAP.md 加入"Out of Scope"复述 | Architecture Team | Phase 9 plan 09-13 |
| Phase 10: HomePage UI 设计审核——确认无 streak / target / cross-period copy | UI Team | Phase 10 |
| Phase 11: AnalyticsScreen 设计审核——确认无 leaderboard / 跨期对比 | UI Team | Phase 11 |
| Phase 12 close: 状态 `📝 草稿` → `✅ 已接受`，append `## Update YYYY-MM-DD: ratified at v1.1 close` | Architecture Team | Phase 12 close |

---

*最后审查日期: 2026-05-01*
*下次审查触发: v1.2 milestone start*

---

## Update 2026-06-17: 支出侧「本月vs上月」趋势 — §4 记录在案例外

**追加性质:** append-only（`.claude/rules/arch.md`）—— 本段仅追加，**不修改**原决策正文、§🚫 Forbidden Features 列表、或第 7 行 `状态:` 头。

### 例外原文（须原样记录）

> **Cross-period（本月vs上月）comparison is permitted on the EXPENSE-side analytics trend（总支出 / 日常），matching the home 支出趋势; the cross-period prohibition remains ABSOLUTE for the 悦己/joy side and for all achievement / goal / streak framing.**
>
> 中文等义：跨期（本月vs上月）对比**仅**允许出现在**支出侧** analytics 趋势（总支出 / 日常），与首页 `支出趋势` 对齐；跨期禁止对**悦己/joy 侧**以及**所有成就 / 目标 / 连续打卡框定**保持**绝对**。

### 该例外做了什么

- 把**支出侧**「本月vs上月」累计折线趋势（仅 `支出趋势` 的 **总支出 / 日常** 两个 tab，与首页 `支出趋势` 对齐，全程**中性非评判**标签：本月 / 上月，**无**「超过/落后/目标/达标/+X%」等 delta 措辞）**记录为 §4「Cross-period delta on home tile / 跨期对比」禁项的用户批准例外（user-approved carve-out）**。
- 语义为**实用预算 parity**（判断「这个月比上个月花得多/少」），与首页支出趋势同义，不引入任何成就 / 目标 / 进度 / 排名框定。

### 悦己侧红线不变（绝对禁止）

- **悦己（joy）侧跨期对比仍绝对禁止（joy-side cross-period stays absolutely forbidden）。** 本例外**仅限支出侧**，**不放宽**悦己侧红线。
- 悦己侧维持 **zero 跨期 / zero 目标 / zero 进度环 / zero 排名 / zero 连续打卡 / zero 成就框定**——悦己跨期才是 §4 真正守护的毒性红线（成就压力）。
- §🚫 Forbidden Features 第 4 / 第 7 条对悦己侧与所有成就-目标-连续打卡框定**继续全额生效**；本例外不触动该列表正文。

### 批准来源（Source of approval）

- **GATE-04**（`.planning/phases/43-html-design-gate-no-production-code/GATE-04-adr-go-no-go.md`，决策 2 = **GO**，记录在案的 ADR-012 amendment）。
- **STATE.md §4 carve-out record**（GATE-04 §4 carve-out + ADR-012 punt history，约 line 192/194）。
- 上游链：`mocks/round2/ROUND2-DECISION.md`（用户被明确告知冲突三次后刻意选择保留）→ `mocks/selected/selected-adr012-audit.md`（自审 carry-forward，PASS 含此例外）。

### 时机与零功能耦合

- 本补正在 **Phase 45（外壳重建）** 落地，**先于 Phase 46** 渲染任何支出侧跨期 UI——把红线提前上档，避免 Phase 46 实现与 §4 静默冲突（GATE-04 要求「Phase 45 实施前」完成）。
- **零功能耦合：** 在 D-A1（行为保持）下，Phase 45 本身**不渲染**该支出跨期 callout（落在 Phase 46）；本段为 doc-only 记录，无任何运行时 / 代码路径变更。

### 批准状态记录（不改头部）

- 本 ADR 自 **Phase 12 milestone close** 起实质上已为 `✅ 已接受`（见 `## 📋 状态` 实施状态行）。此处以 Update 备注记录该事实，**遵循 append-only 规则，不手改第 7 行 `状态:` 头**。

---

*本次更新: 2026-06-17 — 支出侧本月vs上月 §4 记录在案例外（悦己侧跨期仍绝对禁止）*
