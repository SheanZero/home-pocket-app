# Phase 51: Cross-Validation + Daily/Joy Ledger Rework - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-24
**Phase:** 51-Cross-Validation + Daily/Joy Ledger Rework
**Areas discussed:** 滞后/最终裁定 (XVAL-03), 3×3 仲裁器边界+契约 (XVAL-01), 退役旧分类双写 (LEDGER-02), 账本配置覆盖+L2 覆写 (LEDGER-02), 契约 Outcome vs VPR, Reconciler 落位+dual_ledger 命运, 模型归属, 商家 ledgerType 列+学习键, 旧测试迁移, VPR 级联清理, 置信度带枚举定义, OCR/edit 路径账本一致

---

## 滞后 / 最终裁定 (XVAL-03)

### Q1 — partial 时哪些字段实时填、哪些 hold？
| Option | Description | Selected |
|--------|-------------|----------|
| 拆分:金额实时/类目 hold | 金额+原始文本 partial 实时,类目 hold 到 final | ✓ |
| 全部 resolve-on-final | partial 只显示原始转写,金额+类目都等 final | |
| 沿用现状(都实时) | partial 实时填类目(会抖动,违 XVAL-03) | |

### Q2 — 类目在哪个时点裁定？
| Option | Description | Selected |
|--------|-------------|----------|
| 合并窗口关闭后裁定一次 | 复用 VoiceChunkMerger 2.5s 窗口 | (初选,后优化) |
| 每个 STT final 重裁+滞后 | 不等窗口,依滞后 margin 防抖 | |

### Q3 (free-text "分析一下滞后的时间" → "能否优化到2秒以内")
**User's choice:** 优化到 <2s。
**Notes:** 经分析——VoiceChunkMerger 2.5s 窗口是 numeric-only 双门（只等数字续段），与类目无关。**最终决策:** 类目在**首个 end-of-speech `isFinal`** 裁定（~1–1.5s，<2s），与 merger 2.5s 数字窗口**解耦**；金额沿用 2.5s（保护慢速数字口述）。不加类目专用计时器/margin。代价:真实 >1.5s 停顿后第二段才出现的改类目词不回溯翻转（与现有 amount 路径丢弃暂停非数字续段一致，Phase 52 chips 兜底）。

---

## 3×3 仲裁器边界 + 契约 (XVAL-01)

### Q1 — 双弱时输出什么、表单怎么表现？
| Option | Description | Selected |
|--------|-------------|----------|
| 统一契约、表单不自选 | outcome 带 best-guess+band+备选,但表单仅 strong/medium 自选 | |
| 类目 null + 只带备选 | both-weak → selectedCategory=null | |
| 自动填 best-guess | both-weak 也填 best-guess 到表单 | ✓ |

**Notes:** ADR-012 调和——填表≠提交;Phase 51 建契约+域逻辑(outcome 总带 best-guess+band+备选),Phase 52 接进表单并渲染可辨置信度带,自动填只在 tentative affordance 存在后到达用户。

### Q2 — agreement 一致粒度？
| Option | Description | Selected |
|--------|-------------|----------|
| L1 顶层类目一致 | 同 L1 → boost(推荐) | |
| 仅 ledger 一致 | 同账本 → boost(太粗) | |
| 精确 L2 一致 | 完全相同 L2 才 boost | ✓ |

**Notes:** 保守取向;boost 罕见、strong 真正挣得;reconciler 只比 L2 id 保持纯函数。

---

## 退役旧分类双写 (LEDGER-02)

### Q — 退役策略？
| Option | Description | Selected |
|--------|-------------|----------|
| 改路由+删旧映射 | create_transaction 改用 CategoryService.resolveLedgerType ?? daily;删 RuleEngine/ClassificationService/Result/Method | ✓ |
| 保 ClassificationService 薄 wrapper | classify() 委托 CategoryService | |
| 只补 RuleEngine 不删 | 改读 config/补全 | |

**Notes:** 证据——唯一生产消费者是 create_transaction 的 ledgerType==null 兑底;ClassificationResult/Method 无 dual_ledger 外消费者。整 `lib/application/dual_ledger/`(5 文件)按证据默认退役。`?? daily` 兜底。

---

## 账本配置覆盖 + L2 覆写 (LEDGER-02)

### Q — L2 覆写清单怎么定？
| Option | Description | Selected |
|--------|-------------|----------|
| research 按原则补+你抽查 | L2 默认继承 L1,仅明显享受型覆写悦己;research 产单,commit 前抽查 | ✓ |
| 现在一起过一遍 | 逐项决定 | |
| 保持现状 9 条 | 不增补 | |

**Notes:** 19 L1 已全覆盖、L2 缺省继承 → 已无 null 缺口;实质=加「每个可达 L2 非 null」硬门禁 + 复核覆写。daily 兜底 + 硬门禁为近显默认。

---

## 契约: Outcome vs VoiceParseResult

| Option | Description | Selected |
|--------|-------------|----------|
| Outcome 纯领域, VPR 包裹 | reconcile()→RecognitionOutcome(纯函数零I/O,不含 ledger);use case 事后派生 ledger 并嵌入 VPR | ✓ |
| 直接扩 VoiceParseResult | 不引独立 Outcome 类型 | |
| Outcome 完全替换 VPR | 改动最大,touches 所有消费者 | |

**Notes:** 符合 Clean Arch + XVAL-01 纯领域;exact-L2 agreement 使 reconciler 无需 ledger I/O。

---

## Reconciler 落位 + dual_ledger 命运

| Option | Description | Selected |
|--------|-------------|----------|
| features/accounting/domain/services/ | 与 Phase 50 verdict 模型同 feature(里程碑推荐) | |
| 新建 features/voice/ 模块 | 为语音识别开独立 feature | ✓ |

**Notes:** dual_ledger 整目录退役已按证据默认收下。

### 模型归属（features/voice/ 的级联）
| Option | Description | Selected |
|--------|-------------|----------|
| 集中进 features/voice/domain | verdict 模型 + Outcome 都移/放 features/voice/domain,避免跨特性 import | ✓ |
| verdict 留 accounting, 跨特性引 | 只新 Outcome+reconciler 进 voice | |
| 交 research/plan 定 | 查 import_guard 规则后定 | |

**Notes:** 代价:移 Phase 50 模型 + 改 import 路径。

---

## 商家 ledgerType 列 + 学习键

| Option | Description | Selected |
|--------|-------------|----------|
| 保留列 + 断言永不读 | 非权威提示,为未来 affordance 留口;不动 schema(v22-only-Phase49) | ✓ |
| 彻底删除该列 | 需额外迁移,违 v1.9 schema 约束 | |

**Notes:** resolvedKeyword 学习键 threading 经 reconciler 后 verbatim(260526-pg6,locked,非问题)。

---

## VPR 级联清理

| Option | Description | Selected |
|--------|-------------|----------|
| VPR 移 voice + 清废弃字段 | VPR 移 features/voice/domain/models/;删废弃 merchantLedgerType;CategoryMatchResult 留作 keyword verdict | ✓ |
| VPR 留 accounting | 跨特性引 voice domain | |
| 交 plan 定级联范围 | 按引用面决定 | |

---

## 置信度带枚举定义

| Option | Description | Selected |
|--------|-------------|----------|
| 51 定枚举+计算, 52 只渲染 | voice domain 定 ConfidenceBand{strong/medium/weak},reconciler 计算;keyword 强弱按 source(learning>seed>substring) | ✓ |
| 51 只定枚举, 映射留 52 | reconciler 出原始分数,52 算带 | |
| 交 research 定阈值 | 随 3×3 真值表一起 | |

---

## 旧测试迁移

| Option | Description | Selected |
|--------|-------------|----------|
| 删退役码测+迁消费者测 | 删 dual_ledger-owned 测,迁 create_transaction 系列 | |
| 全删旧 + 新建覆盖 | 删所有 dual_ledger 相关测,新建 CategoryService-based 覆盖 | ✓ |
| 交 plan 定 | 逐文件评估 | |

**Notes (caveat applied):** 全删仅限 dual_ledger-owned 测试;create_transaction/entry-path 测试重建时,货币 triple/hash chain/校验等**非分类不变量用例必须保留/重断言**(不可随退役丢)。新增 cross_validation_test/ledger 不变量/每可达 L2 非 null 硬门禁/resolve-on-final 无闪烁。

---

## OCR/edit 路径账本一致

| Option | Description | Selected |
|--------|-------------|----------|
| OCR 自动继承 + edit 不变量仅限改类目 | OCR review 经 re-route 自动继承(dormant 无 UAT);不变量覆盖新录入+edit 改类目;排除 edit 加载保留(W3) | ✓ |
| edit 也强制 re-derive(连加载) | 推翻 W3,翻转历史 override | |
| 交 plan 定边界 | 按实际决定 | |

---

## Claude's Discretion

- 级联 import 更新具体范围（表单/语音屏/测试引用点）。
- 中间 cell 语义 + 每引擎 none/weak/strong 阈值（cross_validation_test spec）。
- reconciler 调用点重构形状（use case 调 reconciler 替换内联薄合并）。
- 候选并列分数的确定性 tie-break。
- `CategoryMatchResult` 是否最终被 `CategoryVerdict` 取代。

## Deferred Ideas

- 备选 chips UI / 置信度带展示 / 内联纠错回流 → Phase 52 (RECUX)。
- 英文关键词/别名/货币词 + 英文数字词兜底 + localeId 端到端 → Phase 52 (VEN)。
- 反毒性扫描 / ARB parity / golden 重基线 → Phase 52 收尾内联门禁。
- 商家专属账本 affordance（用商家 ledgerType 列）→ 未来。
- 商家库凑 600-800 / 中国及其他地区目录 / FTS5 → MERCH-V2。
