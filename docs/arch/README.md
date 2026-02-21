# Home Pocket 架构文档目录

**最后更新:** 2026-02-21  
**状态:** 生效中

---

## 1. 目录结构

```text
docs/arch/
├── 01-core-architecture/
│   ├── ARCH-000_INDEX.md
│   ├── ARCH-001_Complete_Guide.md
│   ├── ARCH-002_Data_Architecture.md
│   ├── ARCH-003_Security_Architecture.md
│   ├── ARCH-004_State_Management.md
│   ├── ARCH-005_Integration_Patterns.md
│   ├── ARCH-006_Error_Boundaries.md
│   ├── ARCH-007_Architecture_Diagram_I18N.md
│   ├── ARCH-008_Layer_Clarification.md
│   └── ARCH-009_I18N_Update_Summary.md
├── 02-module-specs/
│   ├── MOD-001_BasicAccounting.md
│   ├── MOD-002_DualLedger.md
│   ├── MOD-003_FamilySync.md
│   ├── MOD-004_OCR.md
│   ├── MOD-006_Analytics.md
│   ├── MOD-007_Settings.md
│   └── MOD-008_Gamification.md
├── 03-adr/
│   ├── ADR-000_INDEX.md
│   ├── ADR-001_State_Management.md
│   ├── ADR-002_Database_Solution.md
│   ├── ADR-003_Multi_Layer_Encryption.md
│   ├── ADR-004_CRDT_Sync.md
│   ├── ADR-005_OCR_ML_Tech.md
│   ├── ADR-006_Key_Derivation_Security.md
│   ├── ADR-007_Layer_Responsibilities.md
│   ├── ADR-008_Book_Balance_Update_Strategy.md
│   ├── ADR-009_Incremental_Hash_Chain_Verification.md
│   └── ADR-010_CRDT_Conflict_Resolution_Strategy.md
├── 04-basic/
│   ├── BASIC-001_Crypto_Infrastructure.md
│   ├── BASIC-002_Security_Infrastructure.md
│   ├── BASIC-003_I18N_Infrastructure.md
│   └── BASIC-004_Category_PRD.md
└── 05-UI/
    └── UI-001_Page_Inventory.md
```

---

## 2. 迁移说明

以下模块文档已迁移并删除：

- `MOD-005_Security.md` → 能力迁移至 `BASIC-001` + `BASIC-002`
- `MOD-014_i18n.md` → 能力迁移至 `BASIC-003`

Notion 中已标记：

- `DEPRECATED_MOD-005_Security`
- `DEPRECATED_MOD-014_i18n`

---

## 3. 阅读入口

1. 从 `docs/arch/01-core-architecture/ARCH-000_INDEX.md` 开始。  
2. 需要总览时读 `docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md`。  
3. ADR 请看 `docs/arch/03-adr/ADR-000_INDEX.md`。

---

## 4. Notion 对照

Notion 数据库：  
[开发文档](https://www.notion.so/30e0a19b39198039b423c991dbb63200?v=30e0a19b39198015b07f000c7c3b77bd&source=copy_link)
