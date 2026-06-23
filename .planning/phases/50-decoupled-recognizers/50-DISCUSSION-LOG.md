# Phase 50: Decoupled Recognizers - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-23
**Phase:** 50-Decoupled Recognizers
**Areas discussed:** 商家匹配精度 vs 召回, Phase 50 用户可见行为范围, CategoryRecognizer 关键词覆盖, 旧商家路径退役范围

---

## 商家匹配精度 vs 召回 (Round 1)

| Option | Description | Selected |
|--------|-------------|----------|
| 精度优先 | 只在达到锚定阈值(字种最小别名长度)才命中，达不到→不报商家落回类目 | |
| 召回优先 | 弱匹配也作低分候选返回，靠后续置信度带/chips 让用户筛 | ✓ |
| 你决定 | 阈值留给 research 按对抗语料调 | |

**User's choice:** 召回优先
**Notes:** 用户偏向「引擎多召回、由下游筛」。引出 Round-2 的「自动填地板」澄清——因为 chips UI 在 Phase 52，过渡期需地板防误自动填(见下)。

---

## Phase 50 用户可见行为范围 (Round 1)

| Option | Description | Selected |
|--------|-------------|----------|
| 维持商家优先 | 保留今天 line 106 商家优先到 Phase 51 再翻，本阶段纯解耦 | |
| 本阶段就翻成关键词优先 | Phase 50 直接让关键词意图胜出，把部分仲裁提前 | ✓ |
| 你决定 | 由 research/plan 决定过渡合并 | |

**User's choice:** 本阶段就翻成关键词优先
**Notes:** 把 Phase 51 的 XVAL-02 + LEDGER-01 提前。引出 Round-2 的「50/51 边界」澄清(提多少)。

---

## CategoryRecognizer 关键词覆盖 (Round 1 → Round 2)

| Option | Description | Selected |
|--------|-------------|----------|
| 只补点名 case 的最小集 | 只补「加油」等 SC4 点名词让验收 case 过 | |
| 顺带扩一批活动词 | 借结构重构扩充常见 category-only 场景 | ✓ (R1) |
| 全覆盖 L2 category zh+ja | 为全部 L2 配 zh+ja 关键词种子 | ✓ (R2/R3) |

**User's choice:** 全覆盖 L2 category (zh+ja) — Round-1「顺带扩一批」→ Round-2 升级为「需要全覆盖 L2」→ Round-3 锁定「可口语 L2 配 zh+ja + 硬门禁」边界
**Notes:** 这把 Phase 50 加上一个 Phase-49 规模的 authored-seed 组件。边界锁定：可口语 L2 配 ≥1 zh + ≥1 ja，纯 `_other` 兜底桶不强配；`seed-keyword-categoryId-是真L2` 硬门禁(镜像 Phase 49 D-08)；zh+ja only(英文 Phase 52)；commit 前用户抽查。

---

## 旧商家路径退役范围 (Round 1)

| Option | Description | Selected |
|--------|-------------|----------|
| 全切新引擎+删旧DB | 语音全切+删 MerchantDatabase；OCR grep 后切/退；加 match-key 查找方法 | ✓ |
| 语音先切，OCR 留旧DB | 只语音切，MerchantDatabase 为 OCR 保活到 MOD-005 | |
| 留 shim 分批 | MerchantDatabase 降薄壳委托新引擎逐步迁 | |

**User's choice:** 全切新引擎 + 删旧 DB
**Notes:** 不留第二套发散匹配。OCR `LookupMerchantUseCase` 先 grep 消费者再决定切或随旧 DB 一起退。

---

## 50/51 边界 (Round 2 — follow-up on 可见行为)

| Option | Description | Selected |
|--------|-------------|----------|
| 薄规则，不建仲裁器 | 一条关键词优先简则 + 删 line 106 + ledger 派生；3×3/hysteresis 留 51 | ✓ |
| 整个仲裁器提到 Phase 50 | 本阶段建完整 3×3，Phase 51 只剩 ledger 重做 | |
| 你决定 | 由 research/plan 看代码手术量决定 | |

**User's choice:** 薄规则，不建仲裁器
**Notes:** 关键词优先 = Phase 51 仲裁器的最小子集。Phase 51 余下 = 完整 3×3 + hysteresis + category_ledger_configs 重 seed + RuleEngine 退役。

---

## 自动填阈 (Round 2 — follow-up on 召回 × 可见行为)

| Option | Description | Selected |
|--------|-------------|----------|
| 设自动填充置信度地板 | 召回所有候选(供 Phase 52 chips)，提交结果只在≥地板时自动填 | ✓ |
| 无地板，最高分即填 | 有候选就填最高分(即使很低)，无 chips 时可能回归误报 | |
| 你决定 | 由 research 按对抗语料定地板高度 | |

**User's choice:** 设自动填充置信度地板
**Notes:** 化解「召回优先 ↔ 不回归误报」张力。recall 是引擎输出特性、地板是提交侧护栏。

---

## Claude's Discretion

- 引擎/verdict 文件落位(application/voice/recognition + domain verdict)。
- verdict model 字段形状 + none/weak/strong banding 落 verdict 还是留 Phase 51。
- match-key 查找：repo 加方法 per-lookup 查 DB vs recognizer load-all in-memory。
- 字种最小别名长度阈值 + 提交置信度地板高度(按对抗语料调)。
- 是否复用 Phase 49 `MerchantNameNormalizer`(大概率复用)。
- 全 L2 关键词清单具体词条 + 是否拆多文件。

## Deferred Ideas

- 完整 3×3 `RecognitionReconciler` + agreement-boost + both-weak-询问 + STT-final-hysteresis → Phase 51。
- `category_ledger_configs` 重 seed + `RuleEngine`/`ClassificationService` 退役 → Phase 51。
- 备选 chips UI + 置信度带 + 内联纠错回流 → Phase 52 (RECUX)。
- 英文关键词/别名/货币词 + 英文数字词兜底 + `localeId` 端到端 → Phase 52 (VEN)。
- 商家库 600-800 / 中国目录 / FTS5 → MERCH-V2。
