# Phase 51: Cross-Validation + Daily/Joy Ledger Rework - Context

**Gathered:** 2026-06-24
**Status:** Ready for planning

<domain>
## Phase Boundary

把 Phase 50 落地的「薄关键词优先合并规则」升级成真正的纯领域 `RecognitionReconciler`（显式 none/weak/strong 3×3 真值表 + resolve-on-final 滞后），**并在同一阶段消灭第二套发散的 日常/悦己 映射**（退役 `RuleEngine`/`ClassificationService`，统一到 config 化的 `CategoryService.resolveLedgerType`）。

**⚠ Phase 50 已提前完成的部分（D-02 re-slice，plan 必读，勿重做）：**
- `parse_voice_input_use_case.dart:106` 的 merchant-ledger 短路**已删**。
- 「关键词优先」薄合并规则 + `kMerchantAutoFillFloor = 0.85` **已在**。
- **XVAL-02**（「在星巴克买杯子」→购物）+ **LEDGER-01 主体**（voice 路径 ledger = `resolveLedgerType(finalCategoryId)`，非商家 hint）**已满足**。
- verdict 模型已产「原始分数 + 排序候选」；**none/weak/strong banding 显式留给本阶段**。

**本阶段实际剩余工作（两 wave，保留内部依赖：先 reconciler/XVAL，后读单一 ledger 站点的 LEDGER）：**
- **Wave-1 XVAL:** 纯领域 `RecognitionReconciler`（3×3 真值表，零 I/O）+ `RecognitionOutcome` 契约 + resolve-on-final 滞后 + `cross_validation_test.dart`（真值表逐 cell 作 spec）。
- **Wave-2 LEDGER:** `create_transaction` 改路由到 config 账本 + 退役整个 `lib/application/dual_ledger/`；`category_ledger_configs` 覆盖硬门禁 + L2 覆写复核；`ledgerType == resolveLedgerType(finalCategoryId)` 不变量测试。

**In scope:** `RecognitionReconciler`（pure，consume 两路 verdict → `RecognitionOutcome`）；3×3 真值表 + 置信度带计算；resolve-on-final（首个 end-of-speech `isFinal` 裁定，与 merger 2.5s 数字窗口解耦）；`create_transaction` 改注入 `CategoryService` + `?? daily` 兜底；退役 `RuleEngine`/`ClassificationService`/`ClassificationResult`/`ClassificationMethod` + 整 `dual_ledger/` 目录；`category_ledger_configs` 每个可达 L2 非 null 硬门禁 + L2 覆写按原则扩（research 产单 + 用户抽查）；recognition 域类型集中进 `features/voice/domain/`（含移 Phase 50 verdict 模型 + VPR）。

**Out of scope（属后续 phase）:** 备选 chips UI / 3 档置信度带**展示** / 内联纠错回流 KEYWORD 表 = **Phase 52 (RECUX)**；英文关键词/别名/货币词 + 英文数字词兜底 + `localeId` 端到端 = **Phase 52 (VEN)**；反毒性扫描 / ARB parity / golden 重基线（Phase 51 零新 UI 字符串，全留 52）；商家库凑 600-800 / 中国目录 / FTS5 = **MERCH-V2**。

</domain>

<decisions>
## Implementation Decisions

### XVAL-03 — 滞后 / 最终裁定（wave-1）
- **D-01 拆分填表。** STT partial 时：金额 + 原始转写文本**实时**更新（保留 260622-nhs R1–R8 已真机验收的亚秒级反馈）；**类目猜测 hold 到最终结果才填**（消除 chip 抖动）。
- **D-02 类目在首个 end-of-speech `isFinal` 裁定一次（~1–1.5s，<2s），与 merger 2.5s 数字窗口解耦。** 关键洞见：类目由口语**词**决定（首个 final 即完整）；merger 2.5s 窗口只等更多**数字续段**（`_bufferLooksOpen`/`_chunkStartsNumeric` 是 numeric-only 双门），与类目无关。故类目不等数字窗口 → 满足用户「<2s」要求。金额沿用 merger 2.5s 窗口**不动**（保护慢速数字口述「一千…八百」）。
- **D-03 不加类目专用计时器 / hysteresis margin。** 单一「utterance done」信号；resolve-once 已天然消除 intra-utterance 重排闪烁。
- **D-04 暂停后第二段才出现的改类目词不回溯翻转**（罕见；与现有 amount 路径丢弃暂停非数字续段一致；由 Phase 52 备选 chips 兜底）。
- **research/plan 验证：** ① 目标设备上首个 final 的 end-of-speech 时延确实 <2s；② 类目用的**完整 transcript 如何从 STT 取**（独立于 merger 的 amount 缓冲）；③ merger `restartListen()` re-arm 与 nhs R6 一次性聆听（不再 re-arm）的交互——若 R6 已在 end-of-speech 终止，2.5s 尾延几乎不出现。

### XVAL-01 — 3×3 仲裁器边界 + 契约（wave-1）
- **D-05 双弱 → 自动填 best-guess。** 用户决定：both-weak（无强关键词、商家 <0.85 floor）也把 best-guess 填进表单。**ADR-012 调和 + 切分：** Phase 51 只建**契约 + 域逻辑**（`RecognitionOutcome` 总带 best-guess 类目 + 定性置信度带 + ranked 备选；ledger 不变量在 best-guess 上仍成立）；**表单填充 + 置信度带渲染留 Phase 52**——自动填行为只在「tentative affordance（band+chips）」存在后才到达用户，故填表≠提交，ADR-012 安全。
- **D-06 agreement boost = 精确 L2 一致。** 仅当商家默认 L2 与关键词 L2 **完全相同**才升到 boosted-strong；L1 同但 L2 异**不** boost（走基础 keyword-wins/merchant-fallback，不膨胀置信度）。后果：strong 带很少触发、是真正挣来的；且 reconciler 只比 L2 id（纯函数，无需 ledger I/O）。
- **D-07 真值表骨架（carried + 本阶段形式化）：** 强关键词 + 任意商家 → 关键词胜，冲突时商家降为 alternate chip；无/弱关键词 + 商家 ≥floor → 商家填；both-weak → 填 best-guess + weak 带；精确-L2-一致 → boost。中间 cell + 每引擎 none/weak/strong 阈值 → 写成 `cross_validation_test.dart` 逐 cell spec **先于编码**（research flag）。
- **D-08 keyword 引擎强弱按 source 分：** learning（`category_keyword_preferences` 命中）> seed keyword > substring fallback；写进 cross_validation_test spec。

### XVAL — 契约形状 + 落位（wave-1）
- **D-09 `RecognitionReconciler` 纯领域、零 I/O：** `reconcile(CategoryVerdict, List<MerchantCandidate>) → RecognitionOutcome`。`RecognitionOutcome` 带 `selectedCategoryId` / `ConfidenceBand` / ranked 备选 / `resolvedKeyword` / 冲突标记——**不含 ledger**。ledger 由 use case 事后派生：`resolveLedgerType(selectedCategoryId) ?? daily`。
- **D-10 `ConfidenceBand{strong, medium, weak}` 定义在 voice domain，由 reconciler 在 Phase 51 计算**（精确-L2-agreement→strong / 单强信号→medium / 双弱→weak）；Phase 52 只 band→ARB 标签 + 视觉**渲染**，不重算仲裁。
- **D-11 落位 `features/voice/`（用户决定，非里程碑默认的 `features/accounting/domain/services/`）。** reconciler → `features/voice/domain/services/`；**recognition 域类型集中进 `features/voice/domain/`**：移 Phase 50 的 verdict 模型（`MerchantCandidate`/`CategoryVerdict`，现在 `features/accounting/domain/models/`）+ 新 `RecognitionOutcome`，避免跨特性 domain import。
- **D-12 VPR 移 voice + 清废弃字段。** `VoiceParseResult` 移到 `features/voice/domain/models/`（与 Outcome/verdict 同处）；**Outcome 纯领域、VPR 包裹**（VPR 是 use-case DTO，嵌 Outcome + amount/date/currency/satisfaction）；删废弃 `merchantLedgerType` 字段（LEDGER-01 后不再填）；`CategoryMatchResult` 作 keyword verdict 输入保留，结果侧由 Outcome 承载。**级联 import 更新（表单/语音屏/测试）交 plan 按引用面执行。**
- **D-13 `resolvedKeyword` 学习键 threading 经 reconciler 后仍 verbatim**（260526-pg6 orphan-key 契约，locked）；写键 == recognizer 读键端到端（纠错写路径是 Phase 52，本阶段只保住 outcome 透传）。

### LEDGER-02 — 退役旧分类双写（wave-2）
- **D-14 改路由 + 删旧映射（单一真相源）。** `create_transaction` 改注入 `CategoryService`（或 `CategoryLedgerConfigRepository`），`ledgerType==null` 兑底改为 `resolveLedgerType(categoryId) ?? LedgerType.daily`；删 `RuleEngine` / `ClassificationService` / `ClassificationResult` / `ClassificationMethod`（证据：classification_result + rule_engine 无 dual_ledger 外消费者；classification_service 仅 create_transaction 消费）。单一真相源 = `category_ledger_configs`。
- **D-15 退役整个 `lib/application/dual_ledger/` 目录（5 文件）。** re-route 后 `repository_providers.dart`（仅 wire classification provider）+ `.g.dart` 也成死码 → 整目录退役。
- **D-16 `?? daily` 兜底。** unknown/无 config → daily（保守，不把支出误判为悦己）；配 D-18 硬门禁后此兜底仅为安全网。

### LEDGER-02 — 账本配置覆盖 + L2 覆写（wave-2）
- **D-17 现状：19 L1 全覆盖、L2 缺省继承 L1 → 已无 null 缺口。** 故 LEDGER-02 实质 ≠ 填大缺口，而是「加门禁 + 退役发散映射 + 复核覆写」。
- **D-18 L2 覆写按原则扩 + 用户抽查。** 原则：L2 默认继承 L1；**仅「明显享受/自我投资型」L2 才覆写为悦己**。research 产出完整提议清单，**commit 前用户抽查**（镜像 Phase 49/50 seed 模式，避免逐项走清单）。现有 9 条覆写（服饰子项→日常、社交酒水/礼物→悦己、特别支出婚礼/搬家/新年→悦己）为基线。
- **D-19 硬门禁：每个可达 L2 `resolveLedgerType` 非 null** 回归测试（镜像 Phase 49 D-08 / Phase 50 D-04 的 seed gate）。
- **D-20 `ledgerType == resolveLedgerType(finalCategoryId)` 不变量测试** 覆盖：新录入（voice/manual）+ edit **改类目**时；**排除** edit 加载时保留存储 ledger（W3 故意，可能含历史 override，见 D-23）。

### 商家 ledgerType 列 + 测试（wave-2）
- **D-21 商家 ledgerType 列保留 + 断言永不读。** 留作非权威提示（Phase 49 决定，为未来「商家专属账本」affordance 留口）；加不变量测试证明 ledger 派生从不读它。**不动 schema**（v1.9 约束：schema 仅 Phase 49 v21→v22 变更，删列会违反）。
- **D-22 测试：全删旧 dual_ledger-owned 测试 + 新建覆盖，但保非分类不变量。** `rule_engine_test` / `classification_service_test` / `dual_ledger/providers_characterization` → 删（测退役码）；`create_transaction_*_test` / entry-path 集成测试重建时，classification 耦合换 `CategoryService`，**但货币 triple 校验 / hash chain / 输入校验等非分类不变量用例必须保留/重断言**（不可随退役一起丢）。新增：`cross_validation_test.dart`（3×3 spec）、ledger 不变量、每个可达 L2 非 null 硬门禁、resolve-on-final 无闪烁。

### OCR / edit 路径（wave-2）
- **D-23 OCR review 自动继承 config 账本**（经 create_transaction re-route，dormant `kOcrEntryEnabled=false`，无需 UAT，correct-by-construction）；edit 加载保留存储 ledger（W3）不变，改类目时 form 已 re-derive（line 450）。

### Claude's Discretion（留 research/plan）
- D-12 级联 import 更新的具体范围（表单 / 语音屏 / 测试的引用点）。
- 中间 cell 的精确语义 + 每引擎 none/weak/strong 阈值（写进 `cross_validation_test.dart` spec）。
- reconciler 调用点重构：use case 调 reconciler 替换内联薄合并的具体形状。
- 候选并列分数的确定性 tie-break。
- `CategoryMatchResult` 是否最终被 `CategoryVerdict` 取代（命名/形状）。

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 需求 / 路线图（authoritative scope）
- `.planning/ROADMAP.md` §"Phase 51: Cross-Validation + Daily/Joy Ledger Rework" — Goal、6 条 Success Criteria（wave 标注）、Depends on Phase 50。
- `.planning/ROADMAP.md` §"v1.9 Cross-Cutting Constraints" + §"Pitfall→Phase→Regression-Test Map"（pitfalls 2/3/10）+ §"Research Flags" — drift 2.31.0/schema 仅 Phase 49、no FTS5/fuzzy、分层、ledger=纯函数、learning-key 身份契约、security。
- `.planning/REQUIREMENTS.md` — **XVAL-01/02/03 + LEDGER-01/02**（注：矩阵标 Pending，但 XVAL-02 + LEDGER-01 主体已在 Phase 50 code）。

### Phase 50 产出（必读 — 已提前的活儿 + verdict 形状）
- `.planning/phases/50-decoupled-recognizers/50-CONTEXT.md` — **D-02 re-slice**（关键词优先 + line-106 已删 + XVAL-02/LEDGER-01 提前）、D-01/D-03 召回优先 + 0.85 floor、banding 留 51。
- `lib/application/voice/parse_voice_input_use_case.dart` — 现两引擎 + 薄合并 + `kMerchantAutoFillFloor=0.85`；本阶段把内联薄合并替换为调 `RecognitionReconciler`。
- `lib/application/voice/recognition/category_recognizer.dart`、`merchant_recognizer.dart` — 两路引擎（reconciler 的 verdict 来源）。
- `lib/features/accounting/domain/models/voice_parse_result.dart`（含 `CategoryMatchResult`/`MatchSource`）、`merchant_candidate.dart` — **本阶段移入 `features/voice/domain/`**。

### 滞后 / STT（XVAL-03）
- `lib/application/voice/voice_chunk_merger.dart` — 2.5s numeric-only 双门窗口、`_commitAndClear`（amount-only）；**类目裁定与之解耦**（D-02）。
- `lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart` — 一次性聆听路径（nhs R6）；`PttListenStatus`。
- `MEMORY.md` `voice-entry-ios-recognition-gotchas` — iOS final 裁定 / 错误码分类 / 一次性 listen。

### Ledger 重做（LEDGER-01/02）
- `lib/application/accounting/category_service.dart` — `resolveLedgerType`（DB-backed 权威路径：直接 config → L2 继承 L1）；本阶段 create_transaction 的新依赖。
- `lib/application/dual_ledger/{classification_service,rule_engine,classification_result,repository_providers}.dart` — **退役目标**（D-14/D-15）；`RuleEngine` 含已不存在的旧 ID（cat_entertainment/cat_shopping）= 发散映射反面教材。
- `lib/application/accounting/create_transaction_use_case.dart` — 唯一生产消费者（`ledgerType==null` 兑底分支，行 136–147）；改路由目标。
- `lib/shared/constants/default_categories.dart` `_defaultLedgerConfigs`（行 1192–1222）— 19 L1 + 9 L2 覆写 seed；L2 覆写复核 + 硬门禁比对对象。
- `lib/features/accounting/domain/repositories/category_ledger_config_repository.dart`、`lib/data/{daos/category_ledger_config_dao,repositories/category_ledger_config_repository_impl}.dart` — config 数据通路。
- `lib/application/accounting/ledger_hint_deriver.dart` — Phase 50 留的「byte-equal resolveLedgerType」镜像（pre-empt ledger desync）；本阶段统一后复核去留。
- `lib/features/accounting/presentation/widgets/transaction_details_form.dart` — `_resolveLedgerType`（行 277）、改类目 re-derive（行 450）、edit 加载保留 seed（行 269，W3）；唯一生产 `CreateTransactionParams` 构造点（行 722，总传 `ledgerType`）。

### 已知陷阱 / 契约（project memory）
- `MEMORY.md` 学习键身份契约（260526-pg6）— `resolvedKeyword` 写键==读键；纠错教 KEYWORD 表不污染商家表。
- `MEMORY.md` `drift-customindices-is-decorative` — 若涉 config seed/索引，显式 CREATE INDEX（本阶段大概率不动 schema）。
- import_guard / arch test（domain 不 import application/data/infrastructure；feature→feature domain 是否禁 → D-11 集中进 voice 即为规避）。

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`CategoryService.resolveLedgerType`**（config-backed）：retire 后的单一账本真相源；create_transaction 改用它 + `?? daily`。
- **Phase 50 两引擎 + verdict 模型**：reconciler 的纯输入；本阶段只新增「合并裁决」层，不重写引擎。
- **`VoiceChunkMerger`**：金额多段合并照旧；类目裁定解耦不动它。
- **Phase 49 seed gate 范式（D-08）+ Phase 50 D-04 keyword gate**：D-19「每个可达 L2 非 null」硬门禁照此写。
- **`category_ledger_configs` 全套**（table/dao/repo/model/seed）：L2 覆写扩 = 改 `_defaultLedgerConfigs` Dart 字面量 + 重 seed，零新数据层。

### Established Patterns
- 分层：reconciler/verdict/outcome/VPR → `features/voice/domain/`（D-11/D-12）；recognizers/use case → `lib/application/voice/recognition/`（里程碑约束，不动）；config 数据 → `lib/data/`。Domain 不 import application/data/infrastructure。
- ledger = `resolveLedgerType(finalCategoryId)` 纯函数（LEDGER-01，Phase 50 voice 路径已落，本阶段扩到 manual 路径 + 不变量测试）。
- 无新重依赖：reconciler 纯 in-house Dart；无 FTS5/fuzzy/embeddings。

### Integration Points
- **`ParseVoiceInputUseCase`**：内联薄合并 → 调 `RecognitionReconciler` 产 `RecognitionOutcome`，再派生 ledger 装进 VPR。
- **`CreateTransactionUseCase`**：注入从 `ClassificationService` 换 `CategoryService`；provider wiring（`features/accounting/presentation/providers/repository_providers.dart`）同步改，删 `dual_ledger/repository_providers` 引用。
- **`RecognitionOutcome`**：Phase 52 RECUX（chips/置信度带/纠错）消费的契约；本阶段定形 + 计算 band，52 只渲染。
- 商家名仍写交易**已加密 merchant 字段**；不 log 原始 transcript/amount/merchant（security）。

</code_context>

<specifics>
## Specific Ideas

- 滞后核心洞见：**类目由词定、金额由数字定**——把「类目等数字续段窗口」改成「类目首个 final 即裁」是把延迟从 ≤2.5s 砍到 ≈1–1.5s 的关键，且不牺牲金额慢速口述的 2.5s 保护。
- both-weak 仍填 best-guess 是用户明确取向（永远给用户一个起点、少点一次）；安全性靠 Phase 52 的可辨置信度带 + chips，而非 Phase 51 留空。
- 精确-L2-agreement 是**保守**取向：boost 罕见 → strong 真正挣得；同时让 reconciler 保持纯函数（只比 L2 id）。
- LEDGER 退役的真正价值不是「填覆盖缺口」（已无 null 缺口），而是**消灭第二套含过时 ID 的发散硬编码映射** + 加回归门禁。
- 四象限回归（carried，本阶段在 3×3 真值表内）：「在星巴克买杯子」→购物；裸「スタバ」→咖啡（地板内自动填）；「加油用了400块」→燃料；both-weak→低置信度 best-guess。

</specifics>

<deferred>
## Deferred Ideas

- **备选 chips UI + 3 档置信度带展示 + 内联纠错回流 KEYWORD 表** → **Phase 52 (RECUX)**（本阶段定 `RecognitionOutcome` 契约 + 计算 band，但不建 UI）。
- **英文关键词/别名/货币词 + 英文数字词兜底 + `localeId` 端到端** → **Phase 52 (VEN)**。
- **反毒性扫描 / ARB parity / golden 重基线** → **Phase 52 收尾内联门禁**（Phase 51 零新 UI 字符串）。
- **商家专属账本 affordance**（用商家 ledgerType 列）→ 未来（本阶段保列但断言不读）。
- **商家库凑 600-800 / 中国及其他地区目录 / FTS5** → **MERCH-V2**。

None reviewed-but-deferred from todos（cross_reference_todos 无匹配，todo_count=0）。

</deferred>

---

*Phase: 51-Cross-Validation + Daily/Joy Ledger Rework*
*Context gathered: 2026-06-24*
