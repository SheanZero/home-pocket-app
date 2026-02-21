# Architecture Docs Restructure And Notion Alignment Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 对齐 Notion 与本地架构文档命名，补全基础能力文档，移除已迁移功能模块文档，并重构核心索引文档。

**Architecture:** 以 `docs/arch` 本地文件为主真相源（source of truth），通过 Notion 数据库“文档名称”进行对齐；将安全/i18n 的技术能力归并到 BASIC 文档体系并从 MOD 目录移除；重建 `ARCH-001`、`ADR-000_INDEX` 与核心索引导航。

**Tech Stack:** Markdown, Notion MCP tools (`notion-query-database-view`, `notion-update-page`)

---

### Task 1: 建立标准命名映射与迁移范围

**Files:**
- Modify: `docs/plans/2026-02-21-arch-doc-restructure-and-notion-alignment.md`

**Steps:**
1. 以 `docs/arch` 现有文件名建立标准命名清单（ARCH/MOD/BASIC/ADR/UI）。
2. 将 Notion 数据库文档映射到标准命名，并标记“删除模块”目标。
3. 确认迁移删除范围为 `MOD-005_Security.md`、`MOD-014_i18n.md`。

### Task 2: 更新 Notion 文档名称

**Files:**
- Update (Notion pages): 所有 ARCH/ADR/BASIC/UI 页面 + 现存 MOD 页面

**Steps:**
1. 批量将 Notion `文档名称` 统一为标准文件名（不含 `.md` 后缀）。
2. 对已迁移模块设置弃用命名（`DEPRECATED_MOD-005_Security`、`DEPRECATED_MOD-014_i18n`）。
3. 校验视图中命名与本地文档一致性。

### Task 3: 重构基础能力文档（BASIC）

**Files:**
- Modify: `docs/arch/04-basic/BASIC-001_Crypto_Infrastructure.md`
- Modify: `docs/arch/04-basic/BASIC-002_Security_Infrastructure.md`
- Modify: `docs/arch/04-basic/BASIC-003_I18N_Infrastructure.md`
- Modify: `docs/arch/04-basic/BASIC-004_Category_PRD.md`

**Steps:**
1. 补齐“迁移完成状态”、职责边界与与模块文档关系。
2. 修正已不准确的“待迁移/待实施”叙述为当前实际状态。
3. 明确与 `lib/infrastructure/*` 代码目录的一致关系。

### Task 4: 删除对应功能模块文档

**Files:**
- Delete: `docs/arch/02-module-specs/MOD-005_Security.md`
- Delete: `docs/arch/02-module-specs/MOD-014_i18n.md`
- Modify: `docs/arch/02-module-specs/*`（仅在索引引用处）

**Steps:**
1. 删除已迁移模块文档文件。
2. 清理索引中的对应引用与依赖说明。
3. 保留仍在业务模块层的文档（BasicAccounting、DualLedger、FamilySync、OCR、Analytics、Settings、Gamification）。

### Task 5: 重构 ARCH-001 与 ADR-000_INDEX 并重建索引

**Files:**
- Modify: `docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md`
- Modify: `docs/arch/03-adr/ADR-000_INDEX.md`
- Modify: `docs/arch/01-core-architecture/ARCH-000_INDEX.md`
- Modify: `docs/arch/README.md`

**Steps:**
1. 以“当前代码结构 + 迁移后边界”为核心重写 `ARCH-001`。
2. 重写 `ADR-000_INDEX`，修复错误链接并对齐现有 ADR 列表。
3. 重建 ARCH 总索引，增加本地路径与 Notion 页面双链接。
4. 更新 `docs/arch/README.md` 目录描述与模块列表。

### Task 6: 一致性验证

**Files:**
- Verify: `docs/arch/**/*`

**Steps:**
1. 运行命名与链接检查（`rg` 检索旧文件名、失效链接模式）。
2. 输出变更清单与残留风险。
3. 提交结果说明（如需后续提交由用户决定）。
