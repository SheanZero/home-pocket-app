# Phase 43 — HTML 设计探索关卡（Design Gate, NO production code）

**日期:** 2026-06-16
**时间:** 21:54
**任务类型:** 架构决策 / 设计探索
**状态:** 已完成（关卡 CLOSED，验证 4/4 通过）
**相关模块:** v1.8 统计页面重设计 · GATE-01..04

---

## 任务概述

在写任何生产代码之前，关闭 v1.8 里程碑的核心设计问题——「为自己花钱而开心」如何在 ADR-012 恒久反游戏化约束下表达。通过深研现状、产出多套 HTML 方向、迭代讨论，选定唯一一案并获用户批准。**全程零 Dart/生产代码**（仅 `.planning/` 下 HTML/Markdown）。

GSD 执行方式：7 plans / 3 waves，因 worktree fork-base 与 `origin/HEAD` 偏离（#683）降级为**主树顺序执行**（每个 plan 一个 gsd-executor agent，直接提交主分支）。

---

## 完成的工作

### Wave 1 — 基座（43-01）
- `GATE-01-current-impl-deep-map.md`：17 个 analytics widget 清单（与 `lib/features/analytics/presentation/widgets/` 磁盘 1:1 核对）+ `MonthlyReport` 已算字段表 + 4 个结构锁点路径 + 仅支出侧勘误。
- `mocks/shared/sample-data.md`（D-09 单一虚构家庭月度数据，全 mock 共用以保证可比）+ `mocks/README.md`（M1..M5 阵容 + D-11 判定矩阵）。

### Wave 2 — 5 套 HTML 方向（43-02..06）
- M1 实用主导 / M2 均衡 / M3 极简实用派 / M4 温暖反思派 / M5 故事画报派，各含 light+dark+ADR-012 自审表，**5 套自审全 PASS**。自包含 HTML（内联 `<style>`、无 CDN）、中文、ADR-019 桜餅×若葉 调色板。

### Wave 3 — 选定 + 决策（43-07，人工 checkpoint）
- 用户未直接选原始 5 案，而是以 **M2 为底迭代 4 轮**（round2 浓度三版 → round3 合并分类三方案 → round4 悦己堆叠条+配色 → round5 单列图例/降序 1 级类目/去悦己合计），最终选定 **round-5 B**（主圆环 + 悦己抽屉）并批准。
- 定稿资产 `mocks/selected/`：reconciled light（悦己明细对齐为主分类真子集）+ dark + ADR-012 自审。
- GATE-03 选定记录 + GATE-04 三决策文档。

---

## 关键技术决策

1. **支出侧「本月vs上月」趋势 = ADR-012 §4 跨期约束的显式例外**——用户在被三次告知冲突后明确选择。范围严格限定支出侧（与首页 `支出趋势` 对齐的预算工具语义）；**悦己侧跨期对比仍绝对禁止**（悦己跨期=自我消费攀比，才是真正毒性）。需在 Phase 45 前以 `## Update` 追加进 ADR-012（append-only），本阶段不改 ADR-012 正文。记录于 `mocks/round2/ROUND2-DECISION.md` + `GATE-04-adr-go-no-go.md`。
2. **JOY-04 = no-go**：静态只读反思 prompt（无输入元素、不持久化用户文本）→ 无加密/隐私含义 → 不新增 ADR，v1.8 保持 no-Drift、presentation-only。
3. **悦己目标改用描述性图表**：HomeHero 目标环（ADR-016 §3）隔离不破，analytics 侧不复制目标/进度环，改用满足度分布 / 悦己分类堆叠条 / 小确幸日历等描述性形式。
4. **情感词表锁定**：`target/目标` 仅限 analytics widget，保留 HomeHero 合法 ambient 环。
5. **fl_chart 1.2.0 逐图 affordance**：donut / histogram（原生 per-rod label，去 Stack hack）/ trend 多线 = ✅ 原生；**悦己水平堆叠条 ⚠ + 小确幸日历热力 ❌** 需自定义 widget（Row-flex / GridView）→ **Phase 46 风险**；Sankey 排除。

---

## 遇到的问题与解决方案

### 问题 1: worktree fork-base 偏离（#683）
**症状:** `worktree.base-check` 返回 `shouldDegrade=true`（本地 main 领先 origin/main 12 个未推送 commit）。
**解决:** 尊重系统建议，降级为主树顺序执行（每 wave 内 plan 串行，避免主树并发 git 冲突）。曾试 `baseRef:head` 恢复并行，但考虑无状态 Bash 无法可靠维护 worktree manifest + 本项目 worktree 历史脆弱 + 本阶段纯文档（并行仅省墙钟、无正确性收益），回退为顺序。

### 问题 2: STATE.md 计数漂移
**症状:** executor 因 `gsd-tools` 不在 PATH 而手改 STATE，`completed_plans`/`percent` 偶有滞后。
**解决:** orchestrator 在 wave 边界对账（percent 86 等），phase.complete 最终重算。ROADMAP（验证依据）始终正确。

### 问题 3: 悦己明细与主分类不自洽
**症状:** 悦己堆叠条含 旅行/美食犒赏，不在主 10 类清单内。
**解决:** 定稿时把悦己 ¥47,200 重分配为主 1 级类目的真子集（每项 ≤ 该类总额），用户批准时已授权对齐。

---

## 测试验证

- [x] GATE-01..04 经 gsd-verifier 逐项对码核验 **4/4 通过**（`43-VERIFICATION.md`）
- [x] 关卡出口硬条件：`git diff 3f083f78~1..HEAD` 仅 20 .html + 29 .md，**零 .dart/pubspec/lib/test**
- [x] 5 套原始方向 + 选定方向 ADR-012 自审全 PASS
- [x] 所有 HTML 自包含、仅支出侧、家庭 aggregate-only
- N/A code-review / regression / schema-drift gate —— 零生产代码变更，无回归面

---

## 后续工作

- [ ] **Phase 44 前**：将「支出侧跨期趋势例外」以 `## Update 2026-06-xx` 追加进 ADR-012（append-only）
- [ ] **Phase 46 风险**：悦己水平堆叠条 + 小确幸日历需自定义 widget（fl_chart 无原生支持）
- [ ] Phase 47：把 GATE-04 情感词表接入 `anti_toxicity_*_test` 的 `_sweepForbiddenSubstrings`
- [ ] Pencil 关键帧细化（如需）为 orchestrator-only 手动步骤（executor 无 `mcp__pencil__*`，claude-code#13898）

---

## 参考资源

- 选定方向：`.planning/phases/43-html-design-gate-no-production-code/mocks/selected/`
- 决策留痕：`GATE-03-direction-selection.md` · `GATE-04-*.md` · `mocks/round2/ROUND2-DECISION.md`
- 验证：`43-VERIFICATION.md`（4/4 passed）

---

**创建时间:** 2026-06-16 21:54
