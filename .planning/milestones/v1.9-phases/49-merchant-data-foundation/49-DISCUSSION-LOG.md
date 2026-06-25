# Phase 49: Merchant Data Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-23
**Phase:** 49-Merchant Data Foundation
**Areas discussed:** 表结构形状, 归一化依赖, Seed 策略, 清单产出

---

## 表结构形状 (Schema shape)

| Option | Description | Selected |
|--------|-------------|----------|
| surface-form 子表 | merchants 主表 + merchant_match_keys 子表(surface/match_key/kind)，match_key 索引；Phase 50 = 归一化 query→单次索引查找→join | ✓ |
| 单表打包 | 单 merchants 表，aliases 打包 TEXT，match_key 为列；符合 ROADMAP「match-key 列」字面但无法逐 alias 建索引 | |
| 你决定 | 交给 planner 在 plan 期定 | |

**User's choice:** surface-form 子表
**Notes:** 多语显示列 name_ja/name_zh/name_en 在主表（ROADMAP i18n 强制）；locale/romaji 变体作 kind=locale/alias 行。最稳于 600-800 规模 + 反误命中语料。

---

## 归一化依赖 (Normalization)

| Option | Description | Selected |
|--------|-------------|----------|
| 手写 + 手录 romaji | 手写 NFKC + 片↔平假名折叠 + 全角/小写；romaji/英文作 kind=alias 行手录。zero-new-deps | ✓ |
| 加 kana_kit ^2.1.1 | 唯一候选新依赖；seed 期 toRomaji 自动生成。对外来词品牌不如手写准 | |

**User's choice:** 手写 + 手录 romaji
**Notes:** milestone 保持 zero-new-deps；延续现有 _entries 已手写 romaji/英文 aliases 的做法。

---

## Seed 策略 (Seed strategy)

| Option | Description | Selected |
|--------|-------------|----------|
| post-open count-guarded (时机) | 复用 SeedRunner Stage 3，新增 SeedMerchantsUseCase 镜像 SeedCategoriesUseCase；接 main.dart:65 | ✓ |
| in-migrator (时机) | onCreate/onUpgrade 里直接 seed；要在 migrator 读 rootBundle，ROADMAP 列为较差 | |
| Dart const 列表 (来源) | 新增 DefaultMerchants const 列表镜像 DefaultCategories.all；与现有 seed 模式一致 | ✓ |
| bundled JSON/CSV asset (来源) | assets 下 JSON/CSV + rootBundle 读+解析+校验；可不重编辑但丢编译期检查 | |

**User's choice:** post-open count-guarded + Dart const 列表
**Notes:** categoryId 正确性由 seed-categoryId-is-real-L2 集成测试把关（两种来源都需此测试）。

---

## 清单产出 (List authorship)

| Option | Description | Selected |
|--------|-------------|----------|
| Claude 撰写 + 集成测试硬门禁 + 人工抽查 | 执行期 Claude 按 ROADMAP 枚举主干撰写 ~400，每行映射真实 L2，测试硬门禁 + 用户抽查 | ✓ |
| 分批：Claude 草案→用户审类目映射→定稿 | 更准但多一轮交互 | |
| 我提供来源清单 | 用户有现成 CSV/数据源 | |
| ledger_hint: seed 期从 categoryId 派生 | 保留列但派生填充，单一真相源，防 Phase 51 desync | ✓ |
| ledger_hint: 每商家手写 | 延续 _entries 现状，可能与类目不一致 | |
| ledger_hint: 不存，完全派生 | 不加列，偏离 ROADMAP「schema 含 ledger 提示」字面 | |

**User's choice:** Claude 撰写 + 硬门禁 + 抽查；ledger_hint seed 期从 categoryId 派生
**Notes:** 现有 12 条（categoryId 已 D-04 修过）作为已验证种子核心。

---

## Claude's Discretion

- stable string id 命名方案（如 `mer_seven_eleven`）。
- 跨商家 match_key 冲突处理（属 Phase 50 打分领域，seed/schema 需意识到）。
- 归一化是否复用 voice 管线已有 normalizer（先查 VoiceTextParser / voice_category_resolver）。
- DefaultMerchants 是否拆多文件、按类目分组。

## Deferred Ideas

- MERCH-V2-01 区域/百货店尾部凑 600-800；MERCH-V2-02 中国/其他地区目录；MERCH-V2-03 FTS5。
- 消费者切换（MerchantDatabase → MerchantRepository）= Phase 50 边界，非 v2。Phase 49 保持 additive、零行为变化。
