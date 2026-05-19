# Ratify ADR-016 Joy Metric Visualization Redesign + Supersede ADR-013

**日期:** 2026-05-19
**时间:** 11:20
**任务类型:** 架构决策 (ADR ratification + supersede)
**状态:** 已完成（决策层），实现层待新 phase
**相关模块:**
- HAPPY-02 (Joy metric pipeline)
- MOD-007 (Analytics)
- HomeHeroCard (lib/features/home/presentation/widgets/home_hero_card.dart)
- Settings (新增 monthly_joy_target field)

---

## 任务概述

用户 2026-05-18 首页 review 提出两件相关产品问题:
- item 3: 「重新设计 Joy 的计算方式，看是否用 sum 会更好一些，同时要考虑在同心环中的显示，要能不断累加，让用户有成就感」
- item 4: 「满意度均值是 5，但圆环是 1/4 深色、1/4 浅色，无法让用户理解」

2026-05-18 起草 ADR-016 作为 Proposed 状态，列出 4 个方案 + 5 个 Open Questions。本次任务在 2026-05-19 通过 Socratic discussion 完成 ratify，并 supersede ADR-013 的 density (Joy/¥) 主 metric 地位。

---

## 完成的工作

### 1. ADR-016 Ratify

`docs/arch/03-adr/ADR-016_Joy_Metric_Visualization_Redesign.md`:
- 文档版本 0.1 → 1.0
- 状态 📝 草稿 → ✅ 已接受 (2026-05-19)
- 决策者 TBD → xinz + Architecture Team
- 影响范围扩展为：HomeHeroCard + AnalyticsScreen + HAPPY-02 + ADR-013 supersede + 新增 user_settings.monthly_joy_target
- 文末 append `## ✅ Decision (2026-05-19)` 段落，含 8 节：
  1. 时机（接受打破 v1.1 baseline pure 状态的代价）
  2. Joy metric 处理 — supersede ADR-013，替换 density 为 Σ joy_contribution
  3. 累加视觉边界 — 单月内归零，禁 cross-period
  4. 目标值机制 — 用户可配置 + 默认值推荐算法（历史中位数 OR fallback baseline TBD in plan-phase）
  5. 100% 行为 — 纯环境变色（葵绿 → 金色平滑过渡），无文案 / 动画 / 提醒
  6. 双屏一致性 — HomeHero + Analytics 同 metric
  7. 后续工作 — 新建 v1.2 首个 phase, 1 天 spike 决定 fallback baseline 数字
  8. 显式被拒绝方案 — 方案 D、C、B+上月对比、文案 toast、产品拍定固定值等

### 2. ADR-013 Supersede（append-only）

`docs/arch/03-adr/ADR-013_Joy_Density_PTVF_Scaling.md`:
- 文末 append `## Update 2026-05-19: Superseded by ADR-016 §2` 段落
- 显式说明：
  - 仅 supersede density (聚合层)，PTVF per-tx scaling 公式被 ADR-016 继续引用
  - ADR-013 status 不翻为 已废弃 — 仍 ✅ 已接受 因公式仍在用
  - 未来 reader 顺序：先读 ADR-016 看当前 contract，再读 ADR-013 看 per-tx scaling rationale
- 列出实现 phase 将变更的代码点（use case fold、DAO query、formatter、tests）

### 3. 工作日志

本文件 `doc/worklog/20260519_1120_ratify_adr016_joy_metric_redesign.md`

### 4. 技术决策

**关键决策与理由:**

| 决策 | 选择 | 理由 |
|---|---|---|
| Q5 时机 | 现在 ratify，接受打破 v1.1 baseline | 用户反馈 item 4 是 deficit not preference，搁置不可接受 |
| Q2 公式 | 替换 ADR-013 主 metric | density 作为 ratio 不答「累加」诉求，sum 同样能利用现有 PTVF fold |
| Q1 边界 | 单月内累加，月底归零 | 守 ADR-012 #4 (no cross-period)；月度自然周期与 budget 周期对齐 |
| Q4 目标 | 用户可配置 + 推荐算法 | 平衡个人化与零配置 onboarding；推荐算法用历史中位数避免品味注入 |
| 100% 行为 | 纯环境变色 | ADR-012 #2 边界内最强表达；色变是 ambient state，非 discrete trigger |

**关键 reconciliation:**
Q5 选「不破坏 v1.1 baseline」与 Q2 选「替换 ADR-013」直接冲突。Surface 后用户选择重读 Q5，明确接受 v1.1 baseline 不再 pure 的代价。此 reconciliation 记录在 Decision §1。

### 5. 文件变更统计

- 修改文件 2 个：ADR-016、ADR-013
- 新增文件 1 个：本 worklog
- ADR-016 行数变化：+约 180 行 (主要为 Decision 段落 + 状态元数据更新)
- ADR-013 行数变化：+约 60 行 (Update 段落 append)
- 零代码变更（本次任务边界仅含决策层）

---

## 遇到的问题与解决方案

### 问题 1: 用户初始指令「开始处理 ADR-016」存在歧义

**症状:** 用户通过 `/gsd-quick 开始处理ADR-016` 触发 quick task workflow，但 ADR 当前为草稿态，5 个 Open Questions 未回答 — 直接进入 plan/execute 阶段会让 planner/executor agent 在缺产品决策的情况下写代码，必然产出错。

**原因:** ADR-016 本身的 Next Steps 明确写「需要用户 + Architecture Team 一轮 discuss-phase」，而 `/gsd-quick` 默认 mode 跳过 discuss/research/verify。即使加 `--discuss` flag，也仅讨论已知 task 的 gray areas，不适合用于回答 ADR 5 个 Open Questions 这种产品级决策。

**解决方案:** Surface ambiguity 给用户，offer 4 个 scope 选项（先 discuss、用户已有方案、仅 item 4、推到 v1.2）。用户选「先 discuss、答 Open Questions、append Decision」后，跳过 `/gsd-quick` 的 planner/executor spawn，直接在主会话内 Socratic 走完 5 个问题，最后产出文档变更。

### 问题 2: Q5 vs Q2 答案直接冲突

**症状:** 用户 Q5 选「不破坏 v1.1 baseline」，Q2 选「替换 ADR-013」— 但替换 ADR-013 必然要改 `get_happiness_report_use_case.dart` 等 v1.1 Phase 9/10 锁定的输出 contract，与 Q5 矛盾。

**原因:** 两个问题在原 ADR 中独立列出，未显式标注其相互依赖。用户回答时按各问题局部最优选，未察觉系统级冲突。

**解决方案:** Reconciliation 轮次显式 surface 冲突，给出 3 个 reconcile 选项（重读 Q5、重读 Q2、两阶段切分）。用户选「重读 Q5」明确接受 baseline 代价。Decision §1 记录此 reconciliation 过程以便未来追溯。

### 问题 3: ADR-013 状态翻转决策

**症状:** ADR-013 当前 ✅ 已接受。supersede 后该翻为「已废弃」还是「保留 ✅ 已接受 + append Update」？

**原因:** ADR-013 的 PTVF per-tx scaling 公式（含 0.88 指数）被 ADR-016 直接引用 — 仅聚合层 (Σ amount 分母) 被 supersede，per-tx contribution 计算法仍在用。

**解决方案:** 保留 ADR-013 ✅ 已接受，仅 append Update 段落。Update 段落明确写「supersede 范围限定在聚合层，per-tx scaling 仍 active」。同时遵守项目 `.claude/rules/arch.md` 的「ADR append-only after 已接受」规则。

---

## 测试验证

本次任务为纯文档/决策变更，无代码改动，跳过常规代码测试。验证项：

- [x] ADR-016 status 字段从 「📝 草稿」 翻为 「✅ 已接受 (2026-05-19)」（line 7、19、12 blockquote 三处一致）
- [x] ADR-016 文档版本 0.1 → 1.0
- [x] ADR-016 最后更新日期 2026-05-18 → 2026-05-19
- [x] ADR-016 Decision 段落 8 节齐备
- [x] ADR-016 footer review dates 已更新
- [x] ADR-013 Update 段落 append 至文末（未修改既有正文，符合 append-only 规则）
- [x] ADR-013 status 保持 ✅ 已接受（未翻为 已废弃，per 决策 §2）
- [x] worklog 文件名格式：`YYYYMMDD_HHMM_{snake_case_name}.md`（符合 `.claude/rules/worklog.md`）
- [x] worklog 包含所有标准章节
- [x] 引用 ADR-012 Forbidden Features 各项编号准确

---

## Git 提交记录

```bash
# 待此 commit 创建后填入
Commit: TBD
Date: 2026-05-19
Type: docs(adr)
```

将以单次 commit 提交本次三个文档变更：
- `docs/arch/03-adr/ADR-016_Joy_Metric_Visualization_Redesign.md`
- `docs/arch/03-adr/ADR-013_Joy_Density_PTVF_Scaling.md`
- `doc/worklog/20260519_1120_ratify_adr016_joy_metric_redesign.md`

---

## 后续工作

### 立即（本 commit 内已完成）
- [x] ADR-016 ratify + Decision append
- [x] ADR-013 Update append
- [x] worklog 写入

### 短期（下一会话）
- [ ] 决定本次实现归属：v1.1.x patch 还是 v1.2 首个 phase？建议走 `/gsd:plan-phase` 或 `/gsd:new-milestone` 让 planner 评估 scope
- [ ] 启动 1 天 spike 决定 §4 fallback baseline 具体数字（候选区间 30-100，需基于早期种子数据测试）

### 中期（实现 phase）
- [ ] Schema migration: 新增 `user_settings.monthly_joy_target INTEGER NULLABLE`
- [ ] 重写 `lib/application/analytics/get_happiness_report_use_case.dart` fold 逻辑
- [ ] 重写 `lib/data/daos/analytics_dao.dart` query（如需）
- [ ] 重命名/重写 `lib/infrastructure/i18n/formatters/joy_density_formatter.dart` → `joy_cumulative_formatter.dart`
- [ ] 重写 `lib/features/home/presentation/widgets/home_hero_card.dart` 同心环 — Σ joy_contribution 累加 + 颜色状态机
- [ ] 重写 Analytics screen Variant δ 体系
- [ ] 新增 Settings UI（monthly_joy_target 配置 + 推荐值文案）
- [ ] golden 测试覆盖 0% / 50% / 100% / >100% 四态
- [ ] i18n key 增减（ja / zh / en 三语言同步）

### 长期（v1.1 retrospective + 文档）
- [ ] `.planning/RETROSPECTIVE.md` append v1.1 baseline migration note（Joy metric 已迁移、对比基线分水岭日期 2026-05-19）
- [ ] 实现完成后回顾 ADR-016 §7 must-haves 是否全部达成
- [ ] 决定是否需要 ADR-014（满意度量表）追加任何 Update（目前评估不需要 — Σ joy_contribution 公式仍使用 soul_satisfaction，单极正向语义未变）

---

## 参考资源

- ADR-016: `docs/arch/03-adr/ADR-016_Joy_Metric_Visualization_Redesign.md`
- ADR-013: `docs/arch/03-adr/ADR-013_Joy_Density_PTVF_Scaling.md`
- ADR-012 (No Gamification v1.1): `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` — 硬约束来源
- ADR-014 (Soul Satisfaction Unipolar Positive Scale): `docs/arch/03-adr/ADR-014_Soul_Satisfaction_Unipolar_Positive_Scale.md`
- 当前 HomeHeroCard 实现: `lib/features/home/presentation/widgets/home_hero_card.dart`
- 当前 Joy 公式 fold: `lib/application/analytics/get_happiness_report_use_case.dart`
- 关联 quick task 系列: `doc/worklog/quick/260518-*-home-polish` (item 3/4 之外的 7 项已在那里处理)
- v1.1 ROADMAP: `.planning/milestones/v1.1-ROADMAP.md`
- 用户首页 review 原始反馈: 2026-05-18 (item 3 + item 4 触发本 ADR)

---

**创建时间:** 2026-05-19 11:20
**作者:** xinz + Claude (Architecture Team)
