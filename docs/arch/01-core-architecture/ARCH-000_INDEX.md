# ARCH-000: 架构文档总索引

**文档编号:** ARCH-000  
**文档版本:** 2.0  
**最后更新:** 2026-02-21  
**状态:** 生效中（重建索引）

---

## 1. 使用说明

- 本地 `docs/arch` 是工程内真相源。  
- Notion `开发文档` 数据库用于协作浏览。  
- 两端名称采用统一命名（不含 `.md` 后缀）。

Notion 数据库入口：  
[开发文档](https://www.notion.so/30e0a19b39198039b423c991dbb63200?v=30e0a19b39198015b07f000c7c3b77bd&source=copy_link)

---

## 2. 核心架构（ARCH）

| 文档名称 | 本地文件 | Notion |
|---|---|---|
| ARCH-000_INDEX | `docs/arch/01-core-architecture/ARCH-000_INDEX.md` | [Link](https://www.notion.so/30e0a19b3919815aaae4ca847a5ebdad) |
| ARCH-001_Complete_Guide | `docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md` | [Link](https://www.notion.so/30e0a19b391981e29b7ee90c78058ebc) |
| ARCH-002_Data_Architecture | `docs/arch/01-core-architecture/ARCH-002_Data_Architecture.md` | [Link](https://www.notion.so/30e0a19b391981328f07e0d64a52373c) |
| ARCH-003_Security_Architecture | `docs/arch/01-core-architecture/ARCH-003_Security_Architecture.md` | [Link](https://www.notion.so/30e0a19b391981f0aa23ed72df52dcf8) |
| ARCH-004_State_Management | `docs/arch/01-core-architecture/ARCH-004_State_Management.md` | [Link](https://www.notion.so/30e0a19b391981aa96bbe6975e03623d) |
| ARCH-005_Integration_Patterns | `docs/arch/01-core-architecture/ARCH-005_Integration_Patterns.md` | [Link](https://www.notion.so/30e0a19b391981148b45fd5df5ef69b7) |
| ARCH-006_Error_Boundaries | `docs/arch/01-core-architecture/ARCH-006_Error_Boundaries.md` | [Link](https://www.notion.so/30e0a19b3919814b984efb8d4afa12ae) |
| ARCH-007_Architecture_Diagram_I18N | `docs/arch/01-core-architecture/ARCH-007_Architecture_Diagram_I18N.md` | [Link](https://www.notion.so/30e0a19b391981398258f50c7772900e) |
| ARCH-008_Layer_Clarification | `docs/arch/01-core-architecture/ARCH-008_Layer_Clarification.md` | [Link](https://www.notion.so/30e0a19b391981e0b4e7c8606c3a9518) |
| ARCH-009_I18N_Update_Summary | `docs/arch/01-core-architecture/ARCH-009_I18N_Update_Summary.md` | [Link](https://www.notion.so/30e0a19b391981a984e2f33fd9085a79) |

---

## 3. 功能模块（MOD）

### 3.1 当前有效模块

| 文档名称 | 本地文件 | Notion |
|---|---|---|
| MOD-001_BasicAccounting | `docs/arch/02-module-specs/MOD-001_BasicAccounting.md` | [Link](https://www.notion.so/30e0a19b391981ad80b2ffe2b2e75406) |
| MOD-002_DualLedger | `docs/arch/02-module-specs/MOD-002_DualLedger.md` | [Link](https://www.notion.so/30e0a19b39198169a541cfbd131c9805) |
| MOD-003_FamilySync | `docs/arch/02-module-specs/MOD-003_FamilySync.md` | [Link](https://www.notion.so/30e0a19b3919812ea5f7ed1d6db56aee) |
| MOD-004_OCR | `docs/arch/02-module-specs/MOD-004_OCR.md` | [Link](https://www.notion.so/30e0a19b391981c3bf7ece5208450b90) |
| MOD-006_Analytics | `docs/arch/02-module-specs/MOD-006_Analytics.md` | [Link](https://www.notion.so/30e0a19b39198167ac45dcb3179a89c7) |
| MOD-007_Settings | `docs/arch/02-module-specs/MOD-007_Settings.md` | [Link](https://www.notion.so/30e0a19b391981378d5bfbbd30732514) |
| MOD-008_Gamification | `docs/arch/02-module-specs/MOD-008_Gamification.md` | [Link](https://www.notion.so/30e0a19b391981cf8aa7fecdc90f0e8e) |

### 3.2 已迁移并废弃

| 文档名称 | 本地状态 | Notion |
|---|---|---|
| MOD-005_Security | 已删除（迁移到 BASIC-001/002） | [DEPRECATED_MOD-005_Security](https://www.notion.so/30e0a19b3919812c8941e84ae4a1aebc) |
| MOD-014_i18n | 已删除（迁移到 BASIC-003） | [DEPRECATED_MOD-014_i18n](https://www.notion.so/30e0a19b391981d9a1bacb4014b32b7e) |

---

## 4. 基础能力（BASIC）

| 文档名称 | 本地文件 | Notion |
|---|---|---|
| BASIC-001_Crypto_Infrastructure | `docs/arch/04-basic/BASIC-001_Crypto_Infrastructure.md` | [Link](https://www.notion.so/30e0a19b391981a8a47be7b84c0a899c) |
| BASIC-002_Security_Infrastructure | `docs/arch/04-basic/BASIC-002_Security_Infrastructure.md` | [Link](https://www.notion.so/30e0a19b391981db8528eeb4812833d5) |
| BASIC-003_I18N_Infrastructure | `docs/arch/04-basic/BASIC-003_I18N_Infrastructure.md` | [Link](https://www.notion.so/30e0a19b391981a9b66ccb5aff0c7f84) |
| BASIC-004_Category_PRD | `docs/arch/04-basic/BASIC-004_Category_PRD.md` | [Link](https://www.notion.so/30e0a19b391981139e98e4c486f9f35c) |

---

## 5. 架构决策（ADR）

- ADR 总索引：`docs/arch/03-adr/ADR-000_INDEX.md`
- Notion ADR 索引：[ADR-000_INDEX](https://www.notion.so/30e0a19b3919811f9a6bde4315f3fd95)

---

## 6. 其他文档

| 文档名称 | 本地文件 | Notion |
|---|---|---|
| UI-001_Page_Inventory | `docs/arch/05-UI/UI-001_Page_Inventory.md` | [Link](https://www.notion.so/30e0a19b391981ac8c1fde73f5767fb3) |

---

## 7. 维护规则

1. 新增文档时必须同时更新本索引与对应子索引。  
2. 本地文件名与 Notion `文档名称` 必须一致。  
3. 能力迁移到 BASIC 后，应删除对应 MOD 文档并在索引中标注“已迁移”。
