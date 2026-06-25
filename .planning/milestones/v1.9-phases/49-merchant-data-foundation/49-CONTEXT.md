# Phase 49: Merchant Data Foundation - Context

**Gathered:** 2026-06-23
**Status:** Ready for planning

<domain>
## Phase Boundary

把商家目录从 `lib/infrastructure/ml/merchant_database.dart` 里 **12 条硬编码 in-memory 条目**迁移到一张持久、加索引、可幂等重 seed 的 Drift `merchants` 表（schema **v21→v22**），为所有读商家的组件提供数据底座。

**纯数据底座，无行为变化、安全先落地。** Phase 49 只新增 表 + DAO + repo interface/impl + 幂等 seed；**不切换任何消费者**——现有 `MerchantDatabase` in-memory 列表与其消费者（`LookupMerchantUseCase`、voice 管线）在 Phase 49 保持原样，消费者切换到新 `MerchantRepository` 留到 **Phase 50**（"data before logic"）。

**In scope:** `merchants` + `merchant_match_keys` 两表（v22 迁移 + 显式索引）、~400 家日本商家 Dart const seed、seed 期归一化 match-key 计算、`MerchantRepository` 接口+实现、count-guarded post-open 幂等 seed、完整迁移阶梯测试（加密 executor）。
**Out of scope（属后续 phase）:** 商家匹配算法（NFKC query、锚定/打分、反误命中语料）= Phase 50；商家短路删除 / ledger 重做 = Phase 51；UI/英文别名消费 = Phase 52；区域尾部凑到 600-800、中国目录、FTS5 = v2 (MERCH-V2-*)。

</domain>

<decisions>
## Implementation Decisions

### 表结构形状 (Schema shape)
- **D-01:** 采用 **surface-form 子表**结构（不是单表打包）：
  - `merchants` 主表：`id`(stable string)、`name_ja`(必填)、`name_zh`(nullable)、`name_en`(nullable)、`region`(默认 `'JP'`)、`category_id`(真实 L2)、`ledger_hint`。多语店名作 DATA 存多 locale 列（ROADMAP i18n 强制，不进 ARB）。
  - `merchant_match_keys` 子表：每个**可搜索表面形态**一行 — `merchant_id`(FK)、`surface`(原文)、`match_key`(seed 期归一化)、`kind`(`name`|`alias`|`locale`)。`match_key` 上建索引。
  - Phase 50 匹配 = 归一化 query → `merchant_match_keys.match_key` 单次索引查找 → `merchant_id` → join 主表。
- **D-02:** 两张表的索引都必须在 **onCreate 与 onUpgrade 两处**显式 `CREATE INDEX IF NOT EXISTS`（`customIndices` 是装饰性的 — MEMORY.md gotcha）。沿用现有 `_createShoppingItemIndexes` / `_createExchangeRateIndexes` 单点封装写法，防两路 drift。

### 归一化 (Normalization)
- **D-03:** **手写 NFKC + 片↔平假名折叠 + 全角/小写**，**不加 `kana_kit`**（milestone 保持 zero-new-deps）。
- **D-04:** romaji/英文表面形态作 `kind=alias` 行**手工录入**（延续现有 `_entries` 已手写 `'Starbucks'`/`'yoshinoya'`/`'マック'` 的做法）— 对外来词品牌比 `kana_kit` 自动 Hepburn 更准。

### Seed 策略 (Seed strategy)
- **D-05:** **post-open count-guarded** seed：新增 `SeedMerchantsUseCase` **镜像** `SeedCategoriesUseCase`（`findAll`→空才插；稳定 string id + `INSERT OR IGNORE`/upsert + **单事务** batch）。复用 `AppInitializer` Stage 3 的 `SeedRunner`（KeyManager→Database→seed 之后跑）。**不在 migrator 里读 rootBundle**（ROADMAP 明列为较差选项）。
- **D-06:** 顺便把 `lib/main.dart:65` 当前 no-op 的 `seedRunner: (_) async {}` 接上真实 seed 调用（categories + merchants）。
- **D-07:** seed 原始数据 = **Dart const `DefaultMerchants` 列表**（镜像 `DefaultCategories.all`，可拆多文件）。seed 代码把每个 merchant 展开成 N 条 match-key 行并算归一化。

### 清单产出 (List authorship)
- **D-08:** **Claude 执行期撰写** ~400 家，按 ROADMAP 枚举的全国连锁主干（便利店/超市/牛丼·拉面/咖啡/ファミレス/药妆/百元店/家电/服饰/交通IC/加油/外卖/订阅 + 东京·大阪重点）。每行映射真实 L2 `categoryId`。**`seed-categoryId-is-real-L2` 集成测试为硬门禁**（防 D-04 "不存在 L1 → 静默 null" 类 bug）；commit 前用户抽查。现有 12 条（categoryId 已经 D-04 修过）作为已验证的种子核心。
- **D-09:** `ledger_hint` 列**保留**（ROADMAP 要 schema 含非权威 ledger 提示），但 **seed 期由 `category_id` 派生填充**（而非每商家手写）——单一真相源，预防 Phase 51 要消灭的 ledger desync（pitfall #2）。Phase 50/51 可把它当弱信号。

### Claude's Discretion（未问、留给 research/plan 定）
- stable string id 命名方案（如 `mer_seven_eleven`）。
- 跨商家 `match_key` 冲突处理（两商家归一化到同 key）——属 Phase 50 打分领域，但 seed/schema 需意识到。
- 归一化实现是否复用 voice 管线已有的 normalizer（先查 `VoiceTextParser` / `voice_category_resolver.dart` 有无可复用规范化）。
- `DefaultMerchants` 是否拆多文件、按类目分组。

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 需求 / 路线图 (authoritative scope)
- `.planning/ROADMAP.md` §"Phase 49: Merchant Data Foundation" — Goal、5 条 Success Criteria、Plans。
- `.planning/ROADMAP.md` §"v1.9 Cross-Cutting Constraints" — Drift 2.31.0 pin、schema v21→v22、显式 CREATE INDEX、no FTS5、~400/600-800、merchant-names-as-data、分层、security。
- `.planning/ROADMAP.md` §"v1.9 Pitfall → Phase → Regression-Test Map"（行 5/6/9 命中 Phase 49）。
- `.planning/ROADMAP.md` §"v1.9 Research Flags" → Phase 49 (seed-timing 已在本 CONTEXT 定为 post-open；migration-ladder-on-encrypted-executor)。
- `.planning/REQUIREMENTS.md` — MERCH-01..05（Phase 49 范围）；MERCH-V2-01..03（deferred）。

### 迁移代码 / 数据来源
- `lib/infrastructure/ml/merchant_database.dart` — 现有 12 条 `_MerchantEntry`（name/aliases/categoryId/ledgerType）= 迁移源 + seed 核心；含 D-04 categoryId 修复注释。Phase 49 **不删此文件**（消费者切换在 Phase 50）。
- `lib/data/app_database.dart` — `schemaVersion => 21`、`MigrationStrategy` onCreate/onUpgrade、`_createShoppingItemIndexes` / `_createExchangeRateIndexes` 显式建索引范式。**v22 step 加在这里。**
- `lib/data/tables/shopping_items_table.dart`、`lib/data/tables/exchange_rates_table.dart` — 最近的 Drift 表定义范例（列/约束/customIndices 写法）。
- `lib/application/accounting/seed_categories_use_case.dart` — **要镜像**的 count-guarded post-open seed 范式。
- `lib/core/initialization/app_initializer.dart` — `SeedRunner` typedef + Stage 3 seeding 钩子（KeyManager→DB→seed 顺序）。
- `lib/main.dart` (≈行 65) — 当前 no-op `seedRunner`，本阶段接线。
- `lib/shared/constants/default_categories.dart` — L2 `categoryId` 真相源（`seed-categoryId-is-real-L2` 测试比对对象）；L1/L2 结构（cat_food_*、cat_daily_* …）。

### 已知陷阱 (project memory)
- MEMORY.md `drift-customindices-is-decorative` — `customIndices` getter 不建索引，必须 onCreate+onUpgrade 显式 emit。

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `SeedCategoriesUseCase`：count-guarded 幂等 seed 的现成模板（`findAll`→空→`insertBatch`/`upsertBatch`）。`SeedMerchantsUseCase` 照此写。
- `_createShoppingItemIndexes()` / `_createExchangeRateIndexes()`：显式索引创建的单点封装范式 → 加 `_createMerchantIndexes()`。
- `migrator.createTable(xxx)` + `customStatement('ALTER TABLE …')`：v21 (exchange_rates) 迁移步骤模板。
- 现有 12 条 `_MerchantEntry`：seed 数据起点（categoryId 已 D-04 验证）。
- `DefaultCategories.all`：Dart const seed 列表的现成范式（`DefaultMerchants` 镜像它）。

### Established Patterns
- 幂等 seed = count 守卫 + 稳定 id + 单事务批量（重启/升级再 seed 收敛不翻倍）。
- 新表显式索引在 onCreate（fresh）与 onUpgrade（升级）两路同时建，封装单点防 drift。
- 分层：table→`lib/data/tables/`，DAO→`lib/data/daos/`，repo impl→`lib/data/repositories/`，repo interface→`lib/features/accounting/domain/repositories/`。Domain 不 import data/infrastructure。

### Integration Points
- `lib/main.dart` seedRunner：把 categories + 新 merchants seed 接上（现 no-op）。
- `MerchantRepository`（domain 接口）：Phase 50 的 `MerchantRecognizer` 消费 — Phase 49 定义接口形状但不接消费者。
- 识别命中的商家名最终写进交易的**已加密 merchant 字段**（security：seed 列表是公开非敏感数据，绝不 log 原文）。

</code_context>

<specifics>
## Specific Ideas

- surface-form 展开规模：~400 merchants × ~4 形态 ≈ **~1600 条 match-key 行**——对 600-800 商家上限仍是小表（no FTS5 合理）。
- 迁移阶梯测试必须在**带 SQLCipher key 的加密 executor 路径**跑（v3→v22、v17→v22、v21→v22、fresh v22），不只 `NativeDatabase.memory()`。
- 验证断言（来自 Success Criteria）：`PRAGMA index_list(merchants)` 与 `merchant_match_keys` 在 fresh + migrated 两路都非空；双启动/升级再 seed 行数不变；每行 `category_id` 解析为真实 L2。
- `ledger_hint` 由 `category_id` 派生（D-09）——seed 逻辑里调用类目→ledger 的映射（注意 Phase 51 会把权威 ledger 收敛为 `resolveLedgerType`；seed 期派生应与之一致，避免第二套硬编码映射）。

</specifics>

<deferred>
## Deferred Ideas

- **MERCH-V2-01**：区域/百货店（depachika）尾部凑到 600-800 上限 — 全国主干验证后的 v2 工作。
- **MERCH-V2-02**：中国/其他地区商家目录（schema 的 `region` 已就绪）。
- **MERCH-V2-03**：FTS5 商家索引（仅当目录增至数千且核验 SQLCipher+fts5 构建后）。
- **消费者切换**（不是 v2，是下一 phase 边界）：现有 `MerchantDatabase` 及其消费者（`LookupMerchantUseCase`、voice 管线）切到新 `MerchantRepository` → **Phase 50**。Phase 49 保持 additive、零行为变化。

None reviewed-but-deferred from todos（cross_reference_todos 无匹配）。

</deferred>

---

*Phase: 49-Merchant Data Foundation*
*Context gathered: 2026-06-23*
