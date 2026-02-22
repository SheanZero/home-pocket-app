# MOD-005 与 BASIC-001/002 技术设计对齐 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将 `MOD-005_Security.md` 技术设计中尚未进入 BASIC 文档的能力补齐，并按“加密能力 vs 安全能力”归档到 `BASIC-001` 或 `BASIC-002`。

**Architecture:** 以 `MOD-005` 的“技术设计 + 数据模型 + 核心实现流程”为基准，先做缺失项矩阵，再分别更新 Crypto 基础设施文档与 Security 基础设施文档，最后做术语和链接一致性校验。

**Tech Stack:** Markdown (`.md`), `rg`, `sed`, `apply_patch`, `git diff`

---

## 缺失项基线（先确认再改文档）

| MOD-005 技术设计项 | BASIC 当前状态 | 能力归类 | 目标文档 |
|---|---|---|---|
| Ed25519 选型原因（性能/体积/安全） | 未成体系描述（仅有技术栈） | 加密能力 | `BASIC-001` |
| KeyManager 恢复路径 `recoverFromMnemonic(String)` + 助记词校验/种子转换 | 仅描述 `recoverFromSeed(List<int>)` | 加密能力 | `BASIC-001` |
| RecoveryKitService 详细 API（`generateRecoveryKit`/`verifyRecoveryKit`/`exportToPDF`） | 仅有简述，缺少方法级文档 | 加密能力 | `BASIC-001` |
| Recovery Kit 24 词 + 随机 3 词验证流程 | 仅有职责描述，缺流程细节 | 加密能力 | `BASIC-001` |
| Drift 表 `Devices`/`RecoveryKits` 结构 | BASIC 未给出表定义 | 加密能力 | `BASIC-001` |
| HashChain `appendToChain`（按 `bookId` 组链） | 未明确该方法/流程 | 加密能力 | `BASIC-001` |
| `chainVerification(bookId)` provider 入口 | BASIC 未定义参数化 provider 形态 | 加密能力 | `BASIC-001` |
| `AuthResult` / `AuthStatus` 模型定义位置与状态语义 | BASIC-002 仅引用，未给模型定义章节 | 安全能力 | `BASIC-002` |

---

### Task 1: 建立最终缺失项矩阵（冻结范围）

**Files:**
- Reference: `docs/arch/02-module-specs/MOD-005_Security.md`
- Reference: `docs/arch/04-basic/BASIC-001_Crypto_Infrastructure.md`
- Reference: `docs/arch/04-basic/BASIC-002_Security_Infrastructure.md`
- Create: `docs/arch/04-basic/_tmp_mod005_basic_gap_check.md` (临时，可选)

**Step 1: 提取 MOD-005 技术设计锚点**

Run: `rg -n '^## 技术设计|^## 数据模型|^## 核心实现流程|^### ' docs/arch/02-module-specs/MOD-005_Security.md`
Expected: 输出技术设计、数据模型、5 个核心实现流程小节行号。

**Step 2: 对 BASIC-001/002 做关键词覆盖检索**

Run: `rg -n "recoverFromMnemonic|exportToPDF|appendToChain|AuthStatus|AuthResult|RecoveryKits|Devices extends Table|chainVerification\\(" docs/arch/04-basic/BASIC-001_Crypto_Infrastructure.md docs/arch/04-basic/BASIC-002_Security_Infrastructure.md`
Expected: 能直接看到未命中的设计项（空缺）。

**Step 3: 冻结“缺失项 → 归类 → 目标文档”矩阵**

在临时文件或工作笔记中记录上表，冻结本次改动范围，防止扩散到 UI/测试策略章节。

**Step 4: 清理临时文件（如使用）**

Run: `rm -f docs/arch/04-basic/_tmp_mod005_basic_gap_check.md`
Expected: 工作区无临时分析文件残留。

**Step 5: Commit（范围冻结）**

```bash
git add docs/plans/2026-02-21-mod005-basic-alignment.md
git commit -m "docs(plan): define MOD-005 to BASIC alignment scope"
```

---

### Task 2: 补齐 BASIC-001 的加密能力缺口

**Files:**
- Modify: `docs/arch/04-basic/BASIC-001_Crypto_Infrastructure.md`
- Reference: `docs/arch/02-module-specs/MOD-005_Security.md:170`
- Reference: `docs/arch/02-module-specs/MOD-005_Security.md:516`
- Reference: `docs/arch/02-module-specs/MOD-005_Security.md:806`

**Step 1: 在 KeyManager 小节补充 Ed25519 选型依据**

在 `3.1 KeyManager` 下新增“选型原因”段落（性能/密钥长度/安全级别/Flutter 支持），避免只写“使用了 Ed25519”。

**Step 2: 在 KeyManager 核心方法表加入助记词恢复路径**

新增 `recoverFromMnemonic(String mnemonic)`，并解释与 `recoverFromSeed(List<int>)` 的关系（一个面向 UX 输入，一个面向底层种子）。

**Step 3: 扩展 3.5 RecoveryKitService 为完整 API 章节**

最少补齐：类签名、核心方法表、恢复验证流程、Provider、PDF 导出约束（本地导出、风险提示）。

**Step 4: 新增 `Devices` / `RecoveryKits` Drift 表定义小节**

建议位置：`4. 数据模型` 后新增 `4.3/4.4`，标注与密钥恢复链路的关系，避免把表结构散落到 Security 文档。

**Step 5: 在 HashChainService 加入 `appendToChain` 与参数化验证入口**

在 `3.3` 小节补充：`appendToChain({tx, bookId})`、`chainVerification(bookId)` provider，并说明与增量验证的配合方式。

**Step 6: 校验 BASIC-001 内部交叉引用**

Run: `rg -n "BASIC-002_Security_Infrastructure|RecoveryKitService" docs/arch/04-basic/BASIC-001_Crypto_Infrastructure.md`
Expected: RecoveryKitService 不再是“仅引用外部文档”的空壳描述。

**Step 7: Commit（Crypto 文档）**

```bash
git add docs/arch/04-basic/BASIC-001_Crypto_Infrastructure.md
git commit -m "docs(basic-001): add missing MOD-005 crypto design details"
```

---

### Task 3: 补齐 BASIC-002 的安全能力缺口

**Files:**
- Modify: `docs/arch/04-basic/BASIC-002_Security_Infrastructure.md`
- Reference: `docs/arch/02-module-specs/MOD-005_Security.md:246`
- Reference: `docs/arch/02-module-specs/MOD-005_Security.md:668`

**Step 1: 新增 `AuthResult / AuthStatus` 专门小节**

建议位置：`3.1 BiometricService` 之后，新增 `3.x AuthResult（认证结果模型）`，写明定义位置 `lib/features/security/domain/models/auth_result.dart`。

**Step 2: 列出状态语义与调用约束**

明确 `success / failed / fallbackToPIN / tooManyAttempts / lockedOut / error` 的触发条件，保证与 BiometricService 返回语义一致。

**Step 3: 在 BiometricService 示例中引用统一模型来源**

补一句“AuthResult 为 Feature Domain 模型，基础设施仅消费不定义”，避免层次误解。

**Step 4: 校验 BASIC-002 术语一致性**

Run: `rg -n "BiometricLock|BiometricService|AuthResult|AuthStatus" docs/arch/04-basic/BASIC-002_Security_Infrastructure.md`
Expected: 仅保留 `BiometricService` 命名；Auth 模型描述完整且不冲突。

**Step 5: Commit（Security 文档）**

```bash
git add docs/arch/04-basic/BASIC-002_Security_Infrastructure.md
git commit -m "docs(basic-002): document auth result model and semantics"
```

---

### Task 4: 跨文档一致性校验与收尾

**Files:**
- Modify (optional): `docs/arch/02-module-specs/MOD-005_Security.md`
- Verify: `docs/arch/04-basic/BASIC-001_Crypto_Infrastructure.md`
- Verify: `docs/arch/04-basic/BASIC-002_Security_Infrastructure.md`

**Step 1: 统一 MOD/BASIC 的引用关系**

检查 `MOD-005` 技术设计段对 BASIC 的描述是否仍准确（尤其 RecoveryKit/AuthResult 归属），必要时最小化修正链接说明。

**Step 2: 做一次差异审阅**

Run: `git diff -- docs/arch/02-module-specs/MOD-005_Security.md docs/arch/04-basic/BASIC-001_Crypto_Infrastructure.md docs/arch/04-basic/BASIC-002_Security_Infrastructure.md`
Expected: 仅出现本次计划范围内的文档改动。

**Step 3: 最终验证（文档完整性）**

Run: `rg -n "recoverFromMnemonic|exportToPDF|appendToChain|AuthStatus|RecoveryKits|Devices extends Table" docs/arch/04-basic/BASIC-001_Crypto_Infrastructure.md docs/arch/04-basic/BASIC-002_Security_Infrastructure.md`
Expected: 缺失项关键词都可在对应 BASIC 文档命中。

**Step 4: Commit（一致性收尾）**

```bash
git add docs/arch/02-module-specs/MOD-005_Security.md docs/arch/04-basic/BASIC-001_Crypto_Infrastructure.md docs/arch/04-basic/BASIC-002_Security_Infrastructure.md
git commit -m "docs(security): align MOD-005 technical design with BASIC docs"
```

