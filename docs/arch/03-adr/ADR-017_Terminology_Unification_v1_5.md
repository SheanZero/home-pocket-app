# ADR-017: Terminology Unification v1.5 (词汇统一 v1.5)

**文档编号:** ADR-017
**文档版本:** 1.0
**创建日期:** 2026-06-01
**最后更新:** 2026-06-01
**状态:** ✅ 已接受 (Accepted — 2026-06-01)
**决策者:** zxsheanjp@gmail.com (project owner) + Claude (planning agent)
**影响范围:** v1.5 ledger vocab (ARB keys+values+@description), AppColors survival/soul + derived symbols, LedgerType enum + v18 migration, soul*/survival* class/file names, soul_satisfaction→joy_fullness column (D-16)
**相关 ADR:** ADR-015 (词汇分层 v1.1 — extended by this ADR), ADR-014 (Soul Satisfaction Unipolar Positive Scale — display term relabeled to "fullness/充盈", record title preserved)

> **本 ADR 已 ratify 于 2026-06-01。** 本文进入 append-only 模式。后续修订以 `## Update YYYY-MM-DD: <topic>` 章节追加，不修改原决议正文。

---

## 📋 状态

**当前状态:** ✅ 已接受 (2026-06-01)
**触发来源:** Phase 31 计划阶段研究 + D-14 用户决策 (2026-06-01): 确立 v1.5 词汇锁定为正式 ADR，记录三项决策：(1) canonical locale vocab mapping, (2) identifier convention, (3) LedgerType enum-rename-with-v18-migration schema decision.
**Ratify 路径:** Phase 31 wave 5 — 本 ADR 是 ADR-015 的后继者，锁定 v1.5 完整词汇统一。

---

## 🎯 背景 (Context)

### 词汇半迁移状态

v1.4 milestone 结束时，双轨账本的词汇处于半迁移状态：

- **用户界面 (ARB values):** 多数已使用 日常/悦己/ときめき/Daily/Joy，但部分字面量（暮らし/Living Expenses 等）仍未统一
- **代码标识符 (Dart/ARB keys):** `LedgerType.survival/soul`、`AppColors.survivalLight/soulLight`、ARB key `soulLedger/survivalLedger` 等全部使用旧命名
- **数据库列名:** `soul_satisfaction` 列名与新词汇 joy/joyFullness 不一致

### v1.5 milestone 目标

v1.5 "文案与配色统一" milestone 目标是：将双轨账本词汇在三种语言的用户界面字符串、内部代码标识符、以及数据库 schema 层面全面统一，消除半迁移状态。

### 与 ADR-015 的关系

ADR-015 (词汇分层 v1.1) 建立了三层 lexical hierarchy 规则（文档层/产品 UI 层/KPI 数学密度层），并锁定了产品 UI 的日中英词汇配对。**本 ADR (ADR-017) 是其后继者**，在 ADR-015 确立的框架基础上，进一步锁定：

1. v1.5 canonical locale vocab mapping 的完整映射表（扩展 ADR-015 §4 决策表）
2. 内部代码 identifier 重命名规约
3. `LedgerType` enum rename + v17→v18 数据库迁移 schema 决策

---

## 🔍 考虑的方案 (Considered Options)

### 方案 A：仅迁移 ARB values，保留旧 identifier

**核心:** 修改用户可见字符串（ARB values），保持 `LedgerType.survival/soul`、`AppColors.survivalLight` 等 Dart 标识符不变。

**结论:** 拒绝。

**理由:** 半迁移状态延续。代码标识符与业务含义脱节（`soul` 在代码中，`joy` 在界面中），增加新开发者认知负担，且 ADR-015 已指出这是需要解决的一致性问题。

### 方案 B：迁移 identifier，但不做数据库列迁移

**核心:** 重命名 Dart 标识符（LedgerType enum、AppColors symbol、ARB key），但保留 `soul_satisfaction` 数据库列名。

**结论:** 拒绝。

**理由:**
- D-04: hash-chain 不覆盖 `ledger_type`（`hash_chain_service.dart:18` 的 SHA-256 载荷为 `id|amount|timestamp|prevHash`），DB 值迁移没有完整性风险。
- D-03: 项目处于 pre-release v0.1.0，无已部署对端，可做 clean upgrade，无需双字符串兼容路径。
- D-16: 将 `soul_satisfaction→joy_fullness` 列 rename 折叠到同一 v18 迁移，成本最低，避免未来单独迁移窗口。

### 方案 C：identifier + DB 迁移 + 折叠到 v18 migration（本决策）

**核心:** ARB values、ARB keys、Dart identifier、AppColors symbols、数据库 `ledger_type` 存储值、`soul_satisfaction` 列名全部一并迁移。`ledger_type` stored-value migration（`survival→daily, soul→joy`）+ `soul_satisfaction→joy_fullness` column rename 全部折叠到 schema v17→v18。

**结论:** 采用。

**理由见下文 §决策 + 迁移 schema 决策。**

---

## ✅ 决策 (Decision)

### 1. Canonical Locale Vocab Mapping (D-13/D-14)

以下为 v1.5 锁定的三语言词汇映射表，取代 ADR-015 §4 中的部分行：

| Concept | zh | ja | en | identifier |
|---------|----|----|-----|------------|
| Survival ledger | 日常 | 日常 (にちじょう) | Daily | `daily` |
| Soul ledger | 悦己 | ときめき | Joy | `joy` |

**注意 ja 语言的不对称性：** identifier 使用 `joy`，但 ja 产品 UI 值为 `ときめき`（非 `joy` 的音译）。这一不对称与既有 `ときめき指数`（joy-index 术语）一致，不是错误，是刻意保留的和風 register 选择（ADR-015 §5 rationale）。

**层级仍遵循 ADR-015:**

| Register tier | en | ja | zh |
|---------------|----|----|-----|
| 文档 / README | happiness | ハピネス | 幸福 |
| 产品 UI（默认）| Joy | ときめき | 悦己 |
| KPI 数学密度标题 | Joy per ¥ | ハピネス密度 | 幸福密度 |
| 家庭模式标签 | Family Joy | 家族の小確幸 | 家族的小确幸 |

ADR-015 §4 其余规则（Family Joy anti-collision、KPI math-density carve-out、JP picker wellbeing ladder）保持不变，本 ADR 不重新决议。

### 2. Identifier Convention (D-07/D-08)

v1.5 全面重命名所有 Dart 标识符：

| 旧标识符 | 新标识符 | 范围 |
|---------|---------|------|
| `LedgerType.survival` | `LedgerType.daily` | enum value |
| `LedgerType.soul` | `LedgerType.joy` | enum value |
| `AppColors.survivalLight` | `AppColors.dailyLight` | theme color |
| `AppColors.soulLight` | `AppColors.joyLight` | theme color |
| `AppColors.soulFullnessBg` | `AppColors.joyFullnessBg` | derived color |
| `AppColors.soulFullnessBorder` | `AppColors.joyFullnessBorder` | derived color |
| `AppColors.soulRoiBg` | `AppColors.joyRoiBg` | derived color |
| `AppColors.soulRoiBorder` | `AppColors.joyRoiBorder` | derived color |
| ARB key `soulLedger` | `joyLedger` | ARB key |
| ARB key `survivalLedger` | `dailyLedger` | ARB key |
| ARB key `soul*` | `joy*` | ARB key pattern |
| ARB key `survival*` | `daily*` | ARB key pattern |
| Dart field `soulSatisfaction` | `joyFullness` | Freezed model field |

**ja 语言不对称提醒：** `joy` identifier 对应 ja value `ときめき`（不是字面上的 joy 音译）。这一不对称是 ADR-015 确立的注册规则，downstream 维护者看到 identifier `joy` 应知晓 ja 端渲染为 `ときめき`。

### 3. LedgerType Enum Rename + v18 Migration Schema Decision (D-03/D-04/D-16)

#### 3.1 决策内容

**将以下变更全部折叠到 schema v17→v18 migration 中：**

1. **`category_ledger_configs` 表重建**（sub-step 1）: SQLite 无法 `ALTER` CHECK 约束，旧 CHECK `IN('survival','soul')` 会拒绝新值 `'daily'/'joy'`，因此需要 table rename → recreate with new CHECK `IN('daily','joy')` → data INSERT with CASE-WHEN 值转换 → DROP old table。

2. **`transactions.ledger_type` 值迁移**（sub-step 2）: `transactions` 表的 `ledger_type` 列无 CHECK 约束，直接 `UPDATE` 存储值即可（`survival→daily, soul→joy`）。

3. **`transactions.soul_satisfaction` 列 rename**（sub-step 3, D-16）: `ALTER TABLE transactions RENAME COLUMN soul_satisfaction TO joy_fullness`。SQLite RENAME COLUMN 保留数据，对该列的 CHECK `BETWEEN 1 AND 10` 自动跟随新列名。新列名在 Drift 表定义中也须更新为 `joy_fullness`（fresh-install path）。

#### 3.2 决策理由

**D-04 — hash-chain 不覆盖 ledger_type / soul_satisfaction:**

`hash_chain_service.dart:18` 的 SHA-256 载荷为：

```
SHA-256(transactionId | amount | timestamp | previousHash)
```

`ledger_type` 和 `soul_satisfaction` 均不在哈希链载荷中。因此，stored-value 迁移不会破坏现有 hash chain 完整性。

**D-03 — pre-release, no deployed peers, clean upgrade:**

项目处于 v0.1.0 pre-release 状态，无生产环境已部署对端。迁移无需双字符串向后兼容路径（transaction sync mapper 的 JSON key `soulSatisfaction→joyFullness` 同样无需 backward-compat）。

**D-16 — 折叠 soul_satisfaction→joy_fullness 到 v18:**

将 `soul_satisfaction` 列 rename 折叠到已有的 v18 migration 窗口，避免单独引入 v19 migration。代码影响范围：
- `lib/data/tables/transactions_table.dart` — `soul_satisfaction` TextColumn → `joy_fullness`，fresh-install CHECK `CHECK(joy_fullness BETWEEN 1 AND 10)`
- `lib/features/accounting/domain/models/transaction.dart` — Freezed field `soulSatisfaction` → `joyFullness`
- `lib/features/accounting/domain/models/transaction_sync_mapper.dart` — JSON key `'soulSatisfaction'` → `'joyFullness'`（D-03 clean-upgrade, no compat shim）
- ~50 个下游调用点（analytics use case, voice estimator, test fixtures 等）

#### 3.3 迁移原子性

全部三个 sub-step 包裹在 `await transaction(() async { ... })` 中，确保部分失败不会产生脏数据。

**相关 ADR 引用:** ADR-015 §8（不重新决议 schema / enum names）→ 本 ADR 在 ADR-015 显式排除的 enum-rename 上做出决策，是 ADR-015 范围的扩展而非覆盖。ADR-014 record title 保持不变（"Soul Satisfaction Unipolar Positive Scale"）；本 ADR 仅将其 display term 从 "satisfaction" 标注为 "fullness/充盈"，不修改 ADR-014 原文。

---

## 🔗 Phase 33 协调接缝 (D-12)

Phase 31 (Plan 04) 已完成 AppColors 派生符号的重命名（`soulLight→joyLight`, `soulFullnessBg/Border→joyFullnessBg/Border`, `soulRoiBg/Border→joyRoiBg/Border` 等）。**Phase 33 (Color Token System) 在着手语义 token 系统时，必须将这些符号视为已完成重命名的状态，只需整合重复常量、不可再次对这些符号执行重命名（already-renamed）。** 任何在 Phase 33 对上述符号发起的"重命名"都是错误操作，会制造 double-rename churn。Phase 33 的职责是在已重命名符号的基础上，将散落的硬编码色值整合到统一的 semantic token 系统（COLOR-01/COLOR-02/COLOR-03），并仅做 consolidate，不做 re-rename。

---

## 🖼️ Phase 34 Golden Re-baseline 接缝 (D-19)

**术语驱动的 golden pixel re-baseline 已在 Phase 31 (Plan 05) 完成。** 受影响的 golden 仅为文字/词汇变更导致的像素差（例如 `daily_vs_joy_card` ja golden、`joy_celebration_overlay` golden — zh/ja/en ARB value 重写在 Plan 03 引入了 ja card label 生存/魂 → 日常/ときめき 等文字标签变化）。颜色值在 Phase 31 未变，因此仅文字区域有像素 delta，且 Phase 31 Plan 05 已将这些 golden 完整 re-baseline 并留下全绿测试套件。

**Phase 34 (Color Token System / Palette) 处理的 golden re-baseline 仅为 PALETTE 驱动的变更（调色板颜色值改动导致的像素差）。** Phase 34 不需要也不应当处理术语驱动的 golden re-baseline — 那些已在 Phase 31 完成。terminology-driven golden re-baseline was completed in Phase 31 (Plan 05); Phase 34 handles PALETTE-driven golden re-baseline ONLY. 若 Phase 34 再次对术语区域执行 re-baseline，将产生冗余操作并可能掩盖真实的调色板像素 delta。

---

## 📋 后果 (Consequences)

### 正面

- 三语言用户界面、代码标识符、数据库存储值在 v1.5 结束时达到完全一致，消除半迁移状态
- ADR-015 的 lexical hierarchy 规则扩展至 identifier 层，任何新开发者都能从 ADR-015/ADR-017 获得完整的命名规则参考
- v18 migration 原子性保证：partial failure 不会产生混合 `survival/daily` 状态
- hash-chain 完整性不受影响（D-04 证明 `ledger_type` 不在哈希载荷中）

### 负面

- v18 migration 代码（`app_database.dart`）增加了复杂度（table recreate + 2个 UPDATE + 1个 RENAME COLUMN）
- `soul_satisfaction` 列的 rename 影响约 50 个调用点，改动面较大

### 中立

- ADR-014 原文和文件名保持不变（title "Soul Satisfaction Unipolar Positive Scale"）；仅 display term 的语义注释变更为 fullness/充盈，历史记录完整保留
- sync mapper JSON key 迁移无 backward-compat 路径（D-03 pre-release clean upgrade），已部署前无对端数据风险

---

## 🗓️ 实施计划 (Implementation Plan)

**本 ADR 对应 Phase 31 实施（2026-06-01）：**

| 计划 | 内容 | 状态 |
|------|------|------|
| 31-01 | ARB key 重命名（soul/survival → joy/daily key 前缀）+ gen-l10n | ✅ 已完成 |
| 31-02 | AppColors symbol + LedgerType enum rename 及所有 Dart 引用 | ✅ 已完成 |
| 31-03 | ARB values 全面统一（zh/ja/en 字面量规范化） + D-17/D-18 @description 更新 | ✅ 已完成 |
| 31-04 | 派生 AppColors 符号重命名（D-12 seam）+ soul_satisfaction → joy_fullness Freezed/mapper/call-sites | ✅ 已完成 |
| 31-05 | v18 migration 实施（category_ledger_configs recreate + transactions UPDATE + soul_satisfaction RENAME）+ golden re-baseline（D-19） | ✅ 已完成 |
| 31-06 | 本 ADR 起草 + ADR-015 pointer + INDEX 更新 + REQUIREMENTS.md 修订 | ✅ 当前计划 |

---

## 🔗 引用 (References)

- `docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md` — 词汇分层 v1.1，本 ADR 扩展对象
- `docs/arch/03-adr/ADR-014_Soul_Satisfaction_Unipolar_Positive_Scale.md` — 满意度量表（record title preserved; display term → fullness/充盈）
- `lib/infrastructure/crypto/services/hash_chain_service.dart:18` — SHA-256 载荷定义，证明 `ledger_type` 不在 hash chain 中（D-04）
- `lib/data/app_database.dart` — v17→v18 migration 实施位置
- `lib/data/tables/transactions_table.dart` — `joy_fullness` 列定义
- `lib/features/accounting/domain/models/transaction.dart` — `LedgerType` enum + Freezed `joyFullness` field
- `lib/features/accounting/domain/models/transaction_sync_mapper.dart` — sync JSON key `'joyFullness'`
- `.planning/REQUIREMENTS.md` — TERMID-04 (本 ADR 满足该需求)
- `.planning/phases/31-terminology-rename/31-CONTEXT.md` — D-03/D-04/D-12/D-13/D-14/D-15/D-16/D-19 决策上下文

---

## 📝 变更历史 (Change Log)

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|---------|------|
| 2026-06-01 | 1.0 | 初版起草，状态直接为 ✅ 已接受 (born accepted — Phase 31 wave 5) | Claude planning agent |

---

**下次 Review:** v1.5 milestone close 或 Phase 33 (Color Token System) 开始时回顾 Phase 33 协调接缝（D-12）的执行情况
