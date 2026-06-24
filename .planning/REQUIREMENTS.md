# Requirements: Home Pocket v1.9 — 语音类目与商家识别系统重构

**Defined:** 2026-06-23
**Core Value:** 让用户用一句话（中/日/英）就能把一笔花费稳准地记成「正确的类目 + 正确的账本（日常/悦己）」——通过把类目识别与商家识别拆成两个独立、可相互验证的引擎，并以真实的日本商家库支撑。

## v1 Requirements

本里程碑提交范围。每条映射到一个 roadmap phase（延续编号，v1.9 从 Phase 49 起）。

### Japanese Merchant Database (MERCH)

- [x] **MERCH-01**: 商家目录从 13 条硬编码 in-memory 列表迁移到新的 Drift `merchants` 表（schema v21→v22），字段含 `region`、多语店名变体、aliases、种子期计算的归一化 match-key、L2 `categoryId`、非权威 ledger 提示。
- [x] **MERCH-02**: ~400 家日本商家（覆盖每个日常类目的全国连锁头部——便利店/超市/牛丼·拉面/咖啡/ファミレス/药妆/百元店/家电/服饰/交通IC/加油/外卖/订阅——加东京·大阪重点商家），每条手工映射到 L2 类目，随表 seed 装载。
- [x] **MERCH-03**: 商家匹配使用锚定/归一化匹配（NFKC + 片↔平假名折叠 + 全角/小写、按字种最小长度），返回带分数的排序候选；不再用双向子串（`query.contains||contains(query)`），600-800 规模下无误命中爆炸。
- [x] **MERCH-04**: Seed 幂等（稳定 id + upsert/`INSERT OR IGNORE`、单事务批量）；表显式建索引（onCreate 与 onUpgrade 都 `CREATE INDEX IF NOT EXISTS`，`PRAGMA index_list` 可验证）；完整迁移阶梯在加密 executor 下验证。
- [x] **MERCH-05**: 商家 schema 按 600-800 上限设计、带 `region` 标签与多语店名，可被未来中国/其他地区扩展与 MOD-005 OCR 复用。

### Decoupled Recognizers (DECOUP)

- [x] **DECOUP-01**: `CategoryRecognizer` 与 `MerchantRecognizer` 为互不调用的独立引擎；移除 `VoiceCategoryResolver` 的「商家优先短路关键词」逻辑。
- [x] **DECOUP-02**: `CategoryRecognizer` 无条件运行，即使无商家也能从活动/物品关键词解析出 L2 类目——「加油用了400块」→ 燃料/交通 L2（Case B，category-only 路径）。
- [x] **DECOUP-03**: `MerchantRecognizer` 独立于关键词信号识别商家（及其弱默认类目 + ledger 提示）——单说「スタバ」仍解析为星巴克 → 咖啡。

### Cross-Validation / Reconciliation (XVAL)

- [x] **XVAL-01**: 纯领域 `RecognitionReconciler` 经显式 none/weak/strong 3×3 真值表合并两路裁决：一致 → 升置信度；关键词-商家冲突 → 关键词胜；无关键词 → 商家兜底；双弱 → 询问用户。
- [x] **XVAL-02**: Case A「在星巴克买了个杯子」解析为 购物（关键词意图），而非商家默认的咖啡。
- [ ] **XVAL-03**: 识别在 STT 最终结果上裁定并加滞后（hysteresis），不随中间 partial 抖动。

### Daily/Joy Ledger Rework (LEDGER)

- [ ] **LEDGER-01**: 语音条目的 日常/悦己 账本归属是最终交叉验证类目的纯函数（`resolveLedgerType(finalCategoryId)`）；删除商家 `ledgerType` 短路（`parse_voice_input_use_case.dart:106`）；每条路径有 `ledgerType == resolveLedgerType(finalCategoryId)` 不变量测试。
- [ ] **LEDGER-02**: `category_ledger_configs` 重新 seed/扩展覆盖全部 19 L1 + 有意义的 L2；退役死的 `RuleEngine`/`ClassificationService` 桩（先 grep 确认无消费者，若有则折叠进 config 而非删除）。

### Recognition UX + Learning Loop (RECUX)

- [ ] **RECUX-01**: 语音识别后，录入表单展示选定类目 + 3 档定性置信度带（绝不显示数字 %/分数），ADR-012-safe。
- [ ] **RECUX-02**: 低置信度时，可点的备选 chips（备选类目 + 商家默认类目）让用户一键纠正。
- [ ] **RECUX-03**: 对关键词-商家冲突的内联纠错教 KEYWORD 表（`category_keyword_preferences`），绝不污染商家表；`resolvedKeyword` 写键 == 读键身份端到端成立（防 260526-pg6 orphan-key 回归）。
- [ ] **RECUX-04**: 识别 UX 不引入任何游戏化（无准确率分数/连胜/徽章/排行）；扩展反毒性扫描覆盖新界面 × ja/zh/en。
- [ ] **RECUX-05**: 商家名是数据（存于 Drift 多语列、不进 ARB），类目标签是 ARB；所有新增 UI 文案三语 ARB parity，`flutter gen-l10n` 干净（`git add -f lib/generated/`）。

### English Voice Parity (VEN)

- [ ] **VEN-01**: 英文语音从英文关键词识别类目、从英文别名/locale 名识别商家、识别英文货币词——达到与 zh/ja 的实用对齐（不做口述数字状态机）。
- [ ] **VEN-02**: 英文 STT 数字金额正确解析；~30 行有界英文数字词兜底处理 "fifty"/"a hundred" 而不进 CJK 数字路径；`localeId` 端到端贯通。

## v2 Requirements

已承认但延后，不在当前 roadmap。

### Merchant Coverage

- **MERCH-V2-01**: 区域/百货店尾部凑到 600-800 上限（全国主干验证后再装载；v1.9 承诺 ~400）。
- **MERCH-V2-02**: 中国/其他地区商家目录（schema 已就绪）。
- **MERCH-V2-03**: FTS5 商家索引（仅当目录增至数千、且核验 SQLCipher+fts5 构建兼容后）。

### Recognition

- **RECOG-V2-01**: 「为什么是这个类目」透明度 tooltip。
- **RECOG-V2-02**: 商家 / 类目双 facet 独立纠错。
- **RECOG-V2-03**: 设备端 embedding 相似度兜底（~40MB 资产，精度天花板；待纠错数据证明价值）。

### English

- **VEN-V2-01**: 完整英文口述数字状态机（仅当 STT 在某些设备/OS 返回数字词时）。

## Out of Scope

显式排除，防止范围蔓延。

| Feature | Reason |
|---------|--------|
| 任何识别相关的游戏化（准确率分/连胜/徽章/排行） | ADR-012 永久禁止 |
| 置信度显示为精确百分比 | 假精度，违反 ADR-012 反毒性 |
| 低置信度自动提交猜测 | 必须让用户确认/纠正（precision-over-recall） |
| 云端 NLU / 识别走网络 | 破坏零知识 + 离线优先 |
| 穷尽「日本每一家店」的商家库 | 维护成本高、收益递减；学习系统补尾 |
| TFLite / embeddings / on-device LLM 上识别路径 | v1.9 用 dict+rules+curated+learning；embedding 是 v2+ 天花板 |
| MOD-005 OCR writer 落地 | 独立模块；但新商家 schema 设计为 OCR-可复用 |
| `drift` ≥2.32.0 升级 | 丢失 SQLCipher easy-support（保持 2.31.0） |
| Levenshtein / fuzzy-match 库 | v1.3 已删 `FuzzyCategoryMatcher` 为净负 |

## Traceability

由 roadmap 创建时填充（gsd-roadmapper）。每条 v1 requirement 映射到恰好一个 phase。研究给出的依赖强制顺序经 roadmapper 确认后采纳，并按用户指示 **6→4 合并**：交叉验证 + 账本重做合并入 Phase 51（同一段代码手术——都删 `parse_voice_input_use_case.dart:106` 的商家短路），识别 UX + 英文语音合并入 Phase 52（同触 `TransactionDetailsForm` + 共享三语 ARB-parity/anti-toxicity/golden 收尾）。Phases 49/50 不变（**4 phases，49-52**）。

| Requirement | Phase | Status |
|-------------|-------|--------|
| MERCH-01 | Phase 49 — Merchant Data Foundation | Complete |
| MERCH-02 | Phase 49 — Merchant Data Foundation | Complete |
| MERCH-03 | Phase 49 — Merchant Data Foundation | Complete |
| MERCH-04 | Phase 49 — Merchant Data Foundation | Complete |
| MERCH-05 | Phase 49 — Merchant Data Foundation | Complete |
| DECOUP-01 | Phase 50 — Decoupled Recognizers | Complete |
| DECOUP-02 | Phase 50 — Decoupled Recognizers | Complete |
| DECOUP-03 | Phase 50 — Decoupled Recognizers | Complete |
| XVAL-01 | Phase 51 — Cross-Validation + Daily/Joy Ledger Rework | Complete |
| XVAL-02 | Phase 51 — Cross-Validation + Daily/Joy Ledger Rework | Complete |
| XVAL-03 | Phase 51 — Cross-Validation + Daily/Joy Ledger Rework | Pending |
| LEDGER-01 | Phase 51 — Cross-Validation + Daily/Joy Ledger Rework | Pending |
| LEDGER-02 | Phase 51 — Cross-Validation + Daily/Joy Ledger Rework | Pending |
| RECUX-01 | Phase 52 — Recognition UX + English Voice | Pending |
| RECUX-02 | Phase 52 — Recognition UX + English Voice | Pending |
| RECUX-03 | Phase 52 — Recognition UX + English Voice | Pending |
| RECUX-04 | Phase 52 — Recognition UX + English Voice | Pending |
| RECUX-05 | Phase 52 — Recognition UX + English Voice | Pending |
| VEN-01 | Phase 52 — Recognition UX + English Voice | Pending |
| VEN-02 | Phase 52 — Recognition UX + English Voice | Pending |

**Coverage:**

- v1 requirements: 20 total
- Mapped to phases: 20 ✓
- Unmapped: 0 ✓
- No requirement mapped to more than one phase (no duplicates) ✓

**Per-phase counts:**

| Phase | Requirements | Count |
|-------|--------------|-------|
| Phase 49 — Merchant Data Foundation | MERCH-01..05 | 5 |
| Phase 50 — Decoupled Recognizers | DECOUP-01..03 | 3 |
| Phase 51 — Cross-Validation + Daily/Joy Ledger Rework | XVAL-01..03, LEDGER-01..02 | 5 |
| Phase 52 — Recognition UX + English Voice | RECUX-01..05, VEN-01..02 | 7 |
| **Total** | | **20** |

---
*Requirements defined: 2026-06-23*
*Last updated: 2026-06-23 — roadmap revised (gsd-roadmapper): user-directed 6→4 merge (XVAL+LEDGER → Phase 51; RECUX+VEN → Phase 52); 20/20 v1 requirements mapped to Phases 49-52, 0 orphans, 0 duplicates*
