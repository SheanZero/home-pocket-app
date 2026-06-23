# Phase 50: Decoupled Recognizers - Context

**Gathered:** 2026-06-23
**Status:** Ready for planning

<domain>
## Phase Boundary

把语音管线里**嵌在一起**的「商家识别」与「类目识别」拆成两个**互不调用**的纯 Dart 引擎，并把所有消费者切到新引擎 + Phase 49 的 `MerchantRepository`，退役旧 `MerchantDatabase`：

- **`MerchantRecognizer`** — 锚定/归一化匹配(NFKC + 片↔平假名折叠 + 全角/小写)，查 Phase 49 的 `merchant_match_keys`，返回**带分数的排序候选**(召回优先)。替换旧 `merchant_database.dart` 的双向子串匹配(`:158` `contains||contains`)。
- **`CategoryRecognizer`** — 由 `VoiceCategoryResolver` 删掉 step-1 商家查找演化而来，keyword-only、**无条件运行**；本阶段把 category-only 关键词种子扩到**全覆盖可口语 L2**(zh+ja)。

**本阶段比纯解耦走得更远**(用户讨论决定)：除了拆引擎，还① 把「关键词优先」的**薄过渡合并规则**提前落地(本是 Phase 51 一部分)、② 用一个 Phase-49 规模的 authored-seed 把类目关键词扩到全 L2、③ 全删旧商家路径。

**In scope:** 两个独立引擎(构造上互不调用、各自可单测)；`MerchantRecognizer` 锚定匹配 + 反误命中护栏 + 排序召回候选；`MerchantRepository` 加 match-key 查找方法；`CategoryRecognizer` keyword-only + 全 L2 zh+ja 关键词种子 + `seed-keyword-categoryId-是真L2` 硬门禁；`ParseVoiceInputUseCase` 重写为「调两引擎 + 薄关键词优先规则 + 商家自动填地板」；删 `MerchantDatabase` + `VoiceTextParser` 内嵌商家匹配；切/退 OCR `LookupMerchantUseCase`。

**Out of scope（属后续 phase）:** 完整 3×3 `RecognitionReconciler`(agreement-boost / both-weak-询问 / STT-final-hysteresis) = **Phase 51**；`category_ledger_configs` 重 seed + `RuleEngine`/`ClassificationService` 退役 = **Phase 51**；备选 chips UI / 置信度带 / 内联纠错回流 = **Phase 52 (RECUX)**；英文关键词/别名/货币词 = **Phase 52 (VEN)**；商家库凑到 600-800 / 中国目录 / FTS5 = **MERCH-V2**。

</domain>

<decisions>
## Implementation Decisions

### 商家匹配：精度 vs 召回
- **D-01 召回优先(recall-first)。** `MerchantRecognizer` 返回**带分数的排序候选**(含弱项)，供 Phase 52 chips 消费。锚定/归一化匹配替换旧双向子串(`merchant_database.dart:158` `contains||contains`)。按字种最小别名长度仍是反误报护栏(供 research 按 ~40 条对抗语料 お米/杉並区/comment-words 调阈值)。
- **D-03 提交侧设「自动填充置信度地板」。** 召回是引擎的**输出**特性；**提交结果**(填进表单)另设地板：仅当最佳商家候选 ≥ 地板时才自动填商家默认类目，地板以下只挂在 verdict、不自动填。这样化解「召回优先 ↔ 不回归误报」的张力——备选 chips UI 在 Phase 52 才有，过渡期无 UI 可选时不能让弱召回商家误自动填。地板高度供 research 按对抗语料定。

### Phase 50 用户可见行为 + 50/51 边界
- **D-02 本阶段就翻成「关键词优先」，但只用薄规则、不建仲裁器。** Phase 50 用一条简单合并规则：关键词命中 → 关键词胜(`ledgerType` 由 `resolveLedgerType(finalCategoryId)` 派生)；关键词 null → 商家兜底(达 D-03 地板才填)。
  - 顺手删 `parse_voice_input_use_case.dart:106` 的 merchant-ledger 短路(`ledgerType = merchantMatch.ledgerType`)。
  - **不建** 3×3 真值表 / agreement-confidence-boost / both-weak-询问用户 / STT-final-hysteresis —— 整套留 **Phase 51**。「关键词优先」是 Phase 51 仲裁器的最小子集。
  - **⚠ Re-slice 提示(Phase 51 plan 必读):** 本决定把 Phase 51 的 **XVAL-02**(关键词胜冲突，例「在星巴克买杯子」→购物)+ **LEDGER-01**(ledger = `resolveLedgerType(finalCategoryId)` 纯函数 + 删 line 106) **提前到 Phase 50**。Phase 51 discuss/plan 需知：line 106 可能已删、关键词优先已在；Phase 51 余下 = 完整 3×3 真值表 + hysteresis + `category_ledger_configs` 重 seed + `RuleEngine`/`ClassificationService` 退役。**裸「スタバ」(关键词 null 不胜) 仍解析为星巴克→咖啡** —— 本阶段需有此回归用例。

### CategoryRecognizer 关键词覆盖
- **D-04 全覆盖可口语 L2(zh+ja) + 硬门禁。** `CategoryRecognizer` 把 category-only 关键词种子从现 ~120 条扩到**全覆盖可口语 L2**：为每个用户可能口语说出活动/物品的 L2 配 ≥1 条 zh + ≥1 条 ja 种子。纯 `_other`/兜底桶**不强配**(L1→`_other` 约定 + `_ensureL2` 安全网已覆盖)。
  - 仍存 `lib/shared/constants/default_synonyms.dart` Dart 字面量(沿用 VOICE-06 扩展契约，可拆多文件)。
  - **只 zh+ja**(英文关键词属 Phase 52 VEN)。
  - **硬门禁:** `seed-keyword-categoryId-是真L2` 集成测试(**镜像 Phase 49 D-08** merchant gate)防孤儿 categoryId(防「不存在的 categoryId → 静默 null」类 bug)。
  - SC4 点名的「加油用了400块」→燃料/交通 当前**缺**(种子里只有 `ガス`→`cat_utilities_gas`)——全覆盖自然包含「加油/给油/給油」等。
  - research 产出全清单、**commit 前用户抽查**。
  - **这是一个 Phase-49 规模的 authored-seed 工作量**(≈103 L2 × zh+ja)，叠在引擎解耦之上。

### 旧商家路径退役
- **D-05 全切新引擎 + 删旧 DB(不留第二套发散匹配)。** 语音管线全切到 `MerchantRecognizer`/`MerchantRepository`；删 `MerchantDatabase`(13 条 in-memory)+ `VoiceTextParser.extractAndMatchMerchant` 里内嵌的商家匹配。
  - `MerchantRepository` 现仅 `findAll`/`hasAny`/`findById`/`insertBatch` —— 本阶段**加 match-key 查找方法**(供 `MerchantRecognizer` 按归一化 query 查 `merchant_match_keys`)。
  - OCR 的 `LookupMerchantUseCase`：先 **grep 消费者**——有活消费者 → 切到同一引擎(不留两套发散匹配)；无消费者 → 随 `MerchantDatabase` 一起退役。
  - `VoiceCategoryResolver` 演化为 `CategoryRecognizer`(删 step-1 merchant lookup；step-2 关键词 + step-2.5 子串保留并入新引擎)。

### Claude's Discretion（留 research/plan）
- 引擎/verdict 文件落位：里程碑约束 recognizers → `lib/application/voice/recognition/`，verdict 模型 → `domain/`(建议 `features/accounting/domain/`)——具体形状。
- verdict model 字段形状：候选列表结构、分数字段；**none/weak/strong banding 是否落在 verdict 还是留 Phase 51 仲裁器定义**(建议本阶段只给原始分数 + 排序，banding 留 51)。
- match-key 查找实现：repo 加方法每次查 DB，还是 recognizer 一次性 load-all in-memory 匹配(~400 商家 / ~1600 match-key 是小表，两者皆可)。
- 字种最小别名长度阈值 + 提交置信度地板高度(按 ~40 条对抗语料调)。
- 归一化是否复用 Phase 49 `MerchantNameNormalizer`(seed 期同款)——**大概率复用**以保证 query 与 match-key 同规范化。
- 全 L2 关键词清单的具体词条 + 是否按类目拆多文件。

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 需求 / 路线图（authoritative scope + 相邻阶段边界）
- `.planning/ROADMAP.md` §"Phase 50: Decoupled Recognizers" — Goal、4 条 Success Criteria、Depends on Phase 49。
- `.planning/ROADMAP.md` §"Phase 51"、§"Phase 52" — **边界参考**：本阶段把哪些 51 的活儿(XVAL-02 / LEDGER-01)提前了、哪些 chips/英文留 52。
- `.planning/ROADMAP.md` §"v1.9 Roadmap Constraints" — 零新重依赖、no FTS5、no Levenshtein/fuzzy、分层(recognizers→application/voice/recognition、verdict/reconciler→domain、merchant data→data)、ledger=纯函数、learning-key 身份契约、security(不 log 原文)。
- `.planning/REQUIREMENTS.md` — **DECOUP-01/02/03**(Phase 50 范围)；**XVAL-02 + LEDGER-01**(本阶段提前的部分)；XVAL-01/03 + LEDGER-02 + 3×3 truth table(留 Phase 51)。

### 演化源 / 删除目标（现有代码）
- `lib/application/voice/parse_voice_input_use_case.dart` — 编排器，**本阶段重写**为调两引擎 + 薄关键词优先规则 + 地板；`:106` merchant-ledger 短路 = 删除目标(D-02)。
- `lib/application/voice/voice_category_resolver.dart` — **`CategoryRecognizer` 的演化源**：删 step-1 `MerchantDatabase` 查找，保留 step-2 关键词 + step-2.5 子串 + `_ensureL2` always-L2 安全网 + `normalizeToL2`。
- `lib/application/voice/voice_text_parser.dart` — `extractAndMatchMerchant` 内嵌商家匹配 = 删除目标(D-05)；amount/date/keyword 抽取保留。
- `lib/infrastructure/ml/merchant_database.dart` — 旧 13 条 in-memory + **双向子串 `:158-159`**(`MerchantRecognizer` 要替换的反面教材) = 删除目标；`MerchantMatch` 形状参考。

### Phase 49 产出（新引擎的数据底座 — 必读）
- `lib/features/accounting/domain/repositories/merchant_repository.dart` — 接口，**本阶段加 match-key 查找方法**。
- `lib/data/daos/merchant_dao.dart`、`lib/data/repositories/merchant_repository_impl.dart` — 加查找实现。
- `lib/data/tables/merchant_match_keys_table.dart`、`lib/data/tables/merchants_table.dart` — match-key 子表(seed 期已归一化 + 索引)。
- `lib/infrastructure/ml/merchant_name_normalizer.dart` — seed 期归一化器，**query 侧大概率复用**(同规范化保证命中)。
- `lib/features/accounting/domain/models/merchant.dart`、`lib/shared/constants/default_merchants.dart` — 商家模型 + 391 家 seed。
- `.planning/phases/49-merchant-data-foundation/49-CONTEXT.md` — Phase 49 决策(schema D-01、归一化 D-03/04、ledger_hint D-09)。

### 类目关键词扩库（D-04）
- `lib/shared/constants/default_synonyms.dart` — 现 ~120 条 zh/ja 种子 = **扩库源**(VOICE-06 Dart 字面量扩展契约；英文已注释为延后)。
- `lib/shared/constants/default_categories.dart` — L2 `categoryId` 真相源(`seed-keyword-categoryId-是真L2` 门禁比对对象)；`cat_car_fuel` 等。
- `lib/application/accounting/seed_voice_synonyms_use_case.dart` — synonym 种子写入路径(`category_keyword_preferences` 表)。

### 已知陷阱 (project memory)
- `MEMORY.md` `voice-entry-ios-recognition-gotchas` — iOS STT 在 final 结果裁定、错误码分类等(虽 hysteresis 留 51，引擎拆分要保住一次性裁定边界意识)。
- `MEMORY.md` 学习键身份契约(260526-pg6) — `resolvedKeyword` 写键 == recognizer 读键端到端；纠错教 KEYWORD 表不污染商家表。

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`MerchantNameNormalizer`**(Phase 49)：seed 期归一化器 → query 侧复用，保证 query 与 `merchant_match_keys.match_key` 同规范化。
- **`merchant_match_keys` 子表 + `MerchantDao`/`MerchantRepository`**(Phase 49)：每个表面形态一行、match_key 已建索引；加一个查找方法即成 `MerchantRecognizer` 的数据后端。
- **`VoiceCategoryResolver._ensureL2` / `normalizeToL2`**：always-L2 契约 + `_other` 约定 + first-child 安全网 → `CategoryRecognizer` 直接继承。
- **`DefaultVoiceSynonyms._seed` 范式 + `seed-categoryId-是真L2` 门禁(Phase 49 D-08)**：D-04 扩库 + 硬门禁照此写。
- **`VoiceTextParser`** amount/date/keyword 抽取：保留;只摘掉内嵌商家匹配。

### Established Patterns
- 分层：recognizers/use case → `lib/application/voice/recognition/`；verdict 模型/(将来的 reconciler) → `domain/`；merchant table/DAO/repo-impl → `lib/data/`。Domain 不 import application/data/infrastructure。
- 关键词种子 = Dart 字面量、无需改 resolver 代码即可扩(VOICE-06 扩展契约)；synonym 种子走既有 `category_keyword_preferences` seed 路径(hitCount=0 sentinel)。
- 零新重依赖：归一化手写(无 `kana_kit`)、匹配无 Levenshtein/fuzzy、无 FTS5。

### Integration Points
- **`ParseVoiceInputUseCase`**：本阶段从「merchant-priority 短路」重写为「两引擎并跑 → 薄关键词优先合并 → 商家自动填地板」。
- **`VoiceParseResult`**：承载两路 verdict + `resolvedKeyword`(学习键身份契约 260526-pg6 必须保住，纵然纠错 UI 在 Phase 52)。
- 识别出的商家名最终写入交易的**已加密 merchant 字段**(security：seed 列表是公开非敏感数据，绝不 log 原始 transcript/amount/merchant)。
- OCR `LookupMerchantUseCase`(MOD-005 dormant, `kOcrEntryEnabled=false`)：grep 消费者后切/退(D-05)。

</code_context>

<specifics>
## Specific Ideas

- 三个决定叠加形成一个**连贯设计**：召回优先引擎(D-01) + 关键词优先薄规则(D-02) + 全 L2 关键词覆盖(D-04) ⇒ **强关键词意图层 + 商家作补充/兜底**(达地板 D-03 才自动填)。这把语义重心从「商家定类目」明确移到「关键词意图定类目」——正是里程碑解耦的方向。
- Phase 50 现在含一个 **Phase-49 规模的 authored-seed 组件**(全 L2 zh+ja 关键词)，验收含 `seed-keyword-categoryId-是真L2` 硬门禁 + commit 前用户抽查。Plan 时应把它当独立 wave/plan(类似 Phase 49 的 `DefaultMerchants` 撰写 plan)。
- 四象限回归用例(DECOUP/XVAL 必备)：(merchant✓ keyword✓)「在星巴克买杯子」→购物(关键词胜)；(merchant✓ keyword✗)裸「スタバ」→星巴克→咖啡(地板内自动填)；(merchant✗ keyword✓)「加油用了400块」→燃料；(merchant✗ keyword✗)→低置信度/不自动填。
- 商家变体覆盖：スタバ / 半角假名 ｽﾀﾊﾞ / Kansai 缩写 マクド / romaji Starbucks 各 surface 形态独立命中(SC3)。
- 反误命中对抗语料 ~40 条(お米/杉並区/comment-words)：`merchant_false_positive_test.dart` 断言无误命中或低分(SC2)。

</specifics>

<deferred>
## Deferred Ideas

- **完整 3×3 `RecognitionReconciler`** + agreement-confidence-boost + both-weak-询问用户 + STT-final-hysteresis → **Phase 51**(本阶段只落「关键词优先」最小子集)。
- **`category_ledger_configs` 重 seed**(全 19 L1 + 有意义 L2 正确日常/悦己默认) + **`RuleEngine`/`ClassificationService` 退役**(grep 消费者后折叠或删) → **Phase 51**。
- **备选 chips UI + 3 档定性置信度带 + 内联纠错回流 KEYWORD 表** → **Phase 52 (RECUX)**(本阶段引擎产出排序候选 + 保住 `resolvedKeyword` 键身份，但不建 UI)。
- **英文关键词/别名/货币词覆盖 + 英文数字词兜底 + `localeId` 端到端** → **Phase 52 (VEN)**(本阶段类目关键词只 zh+ja)。
- **商家库凑到 600-800 / 中国及其他地区目录 / FTS5 索引** → **MERCH-V2**。

None reviewed-but-deferred from todos（cross_reference_todos 无匹配，todo_count=0）。

</deferred>

---

*Phase: 50-Decoupled Recognizers*
*Context gathered: 2026-06-23*
