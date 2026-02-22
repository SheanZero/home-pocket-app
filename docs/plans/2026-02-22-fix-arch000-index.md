# Fix ARCH-000_INDEX.md Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rewrite the severely outdated ARCH-000_INDEX.md to accurately index all architecture documents with correct file paths and links.

**Architecture:** The INDEX file is the master navigation hub for `docs/arch/`. It must link to all documents across 4 subdirectories (01-core-architecture, 02-module-specs, 03-adr, 04-basic) using correct relative paths. No code changes — this is purely a documentation fix.

**Tech Stack:** Markdown only.

---

## Context

The audit report (`docs/worklog/20260222_0946_review_arch000_index.md`) found 20+ broken links and 7 unindexed files. The INDEX was created on 2026-02-03 (v1.0) and never updated after the file renaming from `01_MVP_Architecture_Design.md` → `ARCH-001_Complete_Guide.md` scheme.

## Ground Truth (verified via filesystem)

**Core Architecture (01-core-architecture/):** 9 files
- `ARCH-000_INDEX.md` (this file)
- `ARCH-001_Complete_Guide.md`
- `ARCH-002_Data_Architecture.md`
- `ARCH-003_Security_Architecture.md`
- `ARCH-004_State_Management.md`
- `ARCH-005_Integration_Patterns.md`
- `ARCH-006_Error_Boundaries.md`
- `ARCH-007_Architecture_Diagram_I18N.md`
- `ARCH-008_Layer_Clarification.md`

**Module Specs (02-module-specs/):** 7 files
- `MOD-001_BasicAccounting.md`
- `MOD-002_DualLedger.md`
- `MOD-003_FamilySync.md`
- `MOD-004_OCR.md`
- `MOD-006_Analytics.md` (note: MOD-005 skipped — Security spec never created)
- `MOD-007_Settings.md`
- `MOD-008_Gamification.md`

**ADRs (03-adr/):** 11 files
- `ADR-000_INDEX.md`
- `ADR-001_State_Management.md`
- `ADR-002_Database_Solution.md`
- `ADR-003_Multi_Layer_Encryption.md`
- `ADR-004_CRDT_Sync.md`
- `ADR-005_OCR_ML_Tech.md`
- `ADR-006_Key_Derivation_Security.md`
- `ADR-007_Layer_Responsibilities.md`
- `ADR-008_Book_Balance_Update_Strategy.md`
- `ADR-009_Incremental_Hash_Chain_Verification.md`
- `ADR-010_CRDT_Conflict_Resolution_Strategy.md`

**Basic PRDs (04-basic/):** 4 files
- `BASIC-001_Crypto_Infrastructure.md`
- `BASIC-002_Security_Infrastructure.md`
- `BASIC-003_I18N_Infrastructure.md`
- `BASIC-004_Category_PRD.md`

**Known gaps:**
- MOD-005 (Security module spec) — never created, numbering jumps 004→006
- MOD-014 (i18n) — referenced in old INDEX but does NOT exist on disk

---

### Task 1: Rewrite ARCH-000_INDEX.md

**Files:**
- Modify: `docs/arch/01-core-architecture/ARCH-000_INDEX.md` (full rewrite, all 574 lines)

**Step 1: Replace ARCH-000_INDEX.md with corrected content**

The new file must fix ALL issues from the audit report:

1. **Core Architecture links** — use `./ARCH-NNN_Name.md` format (same directory), include ARCH-001 through ARCH-008 (the old INDEX only had 5, missing 006/007/008)
2. **Module Spec links** — use `../02-module-specs/MOD-NNN_Name.md` format (cross-directory), list all 7 actual files, note MOD-005 gap
3. **ADR links** — use `../03-adr/ADR-NNN_Name.md` format (cross-directory), include all 10 ADRs (old INDEX only had 6, missing 007-010)
4. **Basic PRD links** — keep `../04-basic/BASIC-NNN_Name.md` format (these were already correct)
5. **Remove MOD-014 reference** — file does not exist on disk
6. **Update statistics** — 8 core docs, 7 module docs, 10 ADRs, 4 basic PRDs = 29 total
7. **Update version** to 2.0, date to 2026-02-22
8. **Update layer diagram** — use "Application Layer" not "Business Logic Layer" (per ARCH-008)
9. **Keep all non-link sections intact** — architecture overview, reading guide, tech stack, etc. (only fix broken references within them)

Here is the complete replacement content for the core tables:

**核心架构文档 table (replace lines 16-22):**

```markdown
| 文档 | 文件名 | 内容概要 | 状态 |
|------|--------|---------|------|
| ARCH-001 总体架构设计 | [ARCH-001_Complete_Guide.md](./ARCH-001_Complete_Guide.md) | MVP总体技术架构、技术栈选型、层次架构、核心设计决策 | ✅ 完成 |
| ARCH-002 数据架构设计 | [ARCH-002_Data_Architecture.md](./ARCH-002_Data_Architecture.md) | 完整数据模型、数据库设计、加密策略、数据流 | ✅ 完成 |
| ARCH-003 安全架构设计 | [ARCH-003_Security_Architecture.md](./ARCH-003_Security_Architecture.md) | E2EE实现、密钥管理、哈希链、生物识别 | ✅ 完成 |
| ARCH-004 状态管理架构 | [ARCH-004_State_Management.md](./ARCH-004_State_Management.md) | Riverpod架构、Provider模式、依赖注入 | ✅ 完成 |
| ARCH-005 集成模式设计 | [ARCH-005_Integration_Patterns.md](./ARCH-005_Integration_Patterns.md) | Repository模式、Use Case模式、CRDT同步 | ✅ 完成 |
| ARCH-006 错误边界 | [ARCH-006_Error_Boundaries.md](./ARCH-006_Error_Boundaries.md) | 错误处理模式、Result类型、错误边界 | ✅ 完成 |
| ARCH-007 I18N架构图 | [ARCH-007_Architecture_Diagram_I18N.md](./ARCH-007_Architecture_Diagram_I18N.md) | 国际化架构设计、多语言组件 | ✅ 完成 |
| ARCH-008 层级职责划分 | [ARCH-008_Layer_Clarification.md](./ARCH-008_Layer_Clarification.md) | 5层架构明确、Thin Feature规则、依赖方向 | ✅ 完成 |
```

**功能模块技术文档 table (replace lines 26-36):**

```markdown
| 模块 | 文件名 | 内容概要 | 工时 | 状态 |
|------|--------|---------|------|------|
| MOD-001 基础记账 | [MOD-001_BasicAccounting.md](../02-module-specs/MOD-001_BasicAccounting.md) | 基础记账+分类系统 | 13天 | ✅ 完成 |
| MOD-002 双轨账本 | [MOD-002_DualLedger.md](../02-module-specs/MOD-002_DualLedger.md) | 灵魂/生存双轨分类 | 8天 | ✅ 完成 |
| MOD-003 家庭同步 | [MOD-003_FamilySync.md](../02-module-specs/MOD-003_FamilySync.md) | P2P家庭同步 | 12天 | ✅ 完成 |
| MOD-004 OCR扫描 | [MOD-004_OCR.md](../02-module-specs/MOD-004_OCR.md) | OCR票据识别 | 7天 | ✅ 完成 |
| ~~MOD-005 安全隐私~~ | — | 安全模块规范 | 10天 | ❌ 未创建 |
| MOD-006 数据分析 | [MOD-006_Analytics.md](../02-module-specs/MOD-006_Analytics.md) | 报表与分析 | 5天 | ✅ 完成 |
| MOD-007 设置管理 | [MOD-007_Settings.md](../02-module-specs/MOD-007_Settings.md) | 应用设置 | 6天 | ✅ 完成 |
| MOD-008 趣味功能 | [MOD-008_Gamification.md](../02-module-specs/MOD-008_Gamification.md) | 游戏化功能 | 7天 | ✅ 完成 |
```

**ADR table (replace lines 49-57):**

```markdown
| ADR | 文件名 | 决策内容 | 状态 |
|-----|--------|---------|------|
| ADR-000 | [ADR-000_INDEX.md](../03-adr/ADR-000_INDEX.md) | ADR 总索引 | ✅ 完成 |
| ADR-001 | [ADR-001_State_Management.md](../03-adr/ADR-001_State_Management.md) | 选择Riverpod作为状态管理方案 | ✅ 已接受 |
| ADR-002 | [ADR-002_Database_Solution.md](../03-adr/ADR-002_Database_Solution.md) | 选择Drift+SQLCipher作为数据库 | ✅ 已接受 |
| ADR-003 | [ADR-003_Multi_Layer_Encryption.md](../03-adr/ADR-003_Multi_Layer_Encryption.md) | 多层加密策略设计 | ✅ 已接受 |
| ADR-004 | [ADR-004_CRDT_Sync.md](../03-adr/ADR-004_CRDT_Sync.md) | CRDT同步协议选型 | ✅ 已接受 |
| ADR-005 | [ADR-005_OCR_ML_Tech.md](../03-adr/ADR-005_OCR_ML_Tech.md) | OCR和ML技术选型 | ✅ 已接受 |
| ADR-006 | [ADR-006_Key_Derivation_Security.md](../03-adr/ADR-006_Key_Derivation_Security.md) | 密钥派生安全修复 (HKDF+缓存) | ✅ 已实施 |
| ADR-007 | [ADR-007_Layer_Responsibilities.md](../03-adr/ADR-007_Layer_Responsibilities.md) | 层级职责与依赖方向 | ✅ 已接受 |
| ADR-008 | [ADR-008_Book_Balance_Update_Strategy.md](../03-adr/ADR-008_Book_Balance_Update_Strategy.md) | 账本余额更新策略 | ✅ 已接受 |
| ADR-009 | [ADR-009_Incremental_Hash_Chain_Verification.md](../03-adr/ADR-009_Incremental_Hash_Chain_Verification.md) | 增量哈希链验证 | ✅ 已接受 |
| ADR-010 | [ADR-010_CRDT_Conflict_Resolution_Strategy.md](../03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md) | CRDT冲突解决策略 | ✅ 已接受 |
```

**Statistics table (replace lines 556-561):**

```markdown
| 类别 | 数量 | 状态 |
|------|------|------|
| 核心架构文档 | 8 | ✅ 100% |
| 功能模块文档 | 7 (+1 未创建) | ⚠️ 87.5% |
| ADR决策记录 | 10 | ✅ 100% |
| 基础能力文档 | 4 | ✅ 100% |
| **总计** | **29 (+1 未创建)** | **⚠️ 96.7%** |
```

**Layer diagram (replace lines 162-178):**

```
┌─────────────────────────────────────────┐
│      Presentation Layer (展示层)        │
│  Screens, Widgets, Providers            │
├─────────────────────────────────────────┤
│     Application Layer (应用层)          │
│  Use Cases, Services                    │
├─────────────────────────────────────────┤
│        Domain Layer (领域层)            │
│  Models, Repository Interfaces          │
├─────────────────────────────────────────┤
│         Data Layer (数据层)             │
│  Repository Impl, DAOs, Tables          │
├─────────────────────────────────────────┤
│    Infrastructure Layer (基础设施层)     │
│  Crypto, ML, Sync, Security, I18N       │
└─────────────────────────────────────────┘
```

**Additional inline reference fixes:**
- Line 66-67: Reading guide refs `(01)` → link to `ARCH-001_Complete_Guide.md`
- Line 68: `(06-13)` → link to `../02-module-specs/`
- Line 69: `(02)` → link to `ARCH-002_Data_Architecture.md`
- Line 78-81: Engineer guide refs → same pattern
- Line 94-96: Architect guide `(14-18)` → link to `../03-adr/`
- Line 106-109: Security guide refs → correct links
- Line 250: `ADR文档（14-18）` → `../03-adr/`
- Line 310: `安全架构设计 (03)` → link to `ARCH-003_Security_Architecture.md`
- Line 515: Version `1.0.0` → `2.0.0`
- Line 571-574: Generation info → update date and version

**Step 2: Verify all links are valid**

Run from project root:
```bash
# Extract all markdown links and verify files exist
grep -oP '\]\(([^)]+\.md)\)' docs/arch/01-core-architecture/ARCH-000_INDEX.md | \
  sed 's/](\(.*\))/\1/' | \
  while read link; do
    # Resolve relative to ARCH-000's directory
    target="docs/arch/01-core-architecture/$link"
    if [ ! -f "$target" ]; then
      echo "BROKEN: $link -> $target"
    else
      echo "OK: $link"
    fi
  done
```

Expected: All links should print "OK".

**Step 3: Commit**

```bash
git add docs/arch/01-core-architecture/ARCH-000_INDEX.md
git commit -m "docs(arch): rewrite ARCH-000 INDEX with correct links and complete file listing

Fix 20+ broken links, add 7 missing file entries (ARCH-006/007/008,
ADR-007/008/009/010), correct all cross-directory paths, update
statistics, and bump to v2.0.

Ref: docs/worklog/20260222_0946_review_arch000_index.md"
```
