# ADR-000: Architecture Decision Records Index

**文档编号:** ADR-000  
**文档版本:** 2.0  
**最后更新:** 2026-02-21  
**状态:** 生效中

---

## 1. 说明

本索引是 Home Pocket 的架构决策真相源，列出当前有效 ADR 及其本地与 Notion 对照链接。

---

## 2. ADR 列表（当前有效）

| ADR | 标题 | 本地文件 | Notion |
|---|---|---|---|
| ADR-001 | State Management | `docs/arch/03-adr/ADR-001_State_Management.md` | [Link](https://www.notion.so/30e0a19b391981aab35adf3d641a6bea) |
| ADR-002 | Database Solution | `docs/arch/03-adr/ADR-002_Database_Solution.md` | [Link](https://www.notion.so/30e0a19b391981c3b75beb6e2b37bb7a) |
| ADR-003 | Multi Layer Encryption | `docs/arch/03-adr/ADR-003_Multi_Layer_Encryption.md` | [Link](https://www.notion.so/30e0a19b391981c6bd95ef666071d5e1) |
| ADR-004 | CRDT Sync | `docs/arch/03-adr/ADR-004_CRDT_Sync.md` | [Link](https://www.notion.so/30e0a19b39198195a007e57a285a646d) |
| ADR-005 | OCR ML Tech | `docs/arch/03-adr/ADR-005_OCR_ML_Tech.md` | [Link](https://www.notion.so/30e0a19b391981b5bea9e3f840d6c23f) |
| ADR-006 | Key Derivation Security | `docs/arch/03-adr/ADR-006_Key_Derivation_Security.md` | [Link](https://www.notion.so/30e0a19b39198178a510f0311d4bc575) |
| ADR-007 | Layer Responsibilities | `docs/arch/03-adr/ADR-007_Layer_Responsibilities.md` | [Link](https://www.notion.so/30e0a19b391981c5afa9d14e4ed80cd3) |
| ADR-008 | Book Balance Update Strategy | `docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md` | [Link](https://www.notion.so/30e0a19b391981349aa4e379398a6f6a) |
| ADR-009 | Incremental Hash Chain Verification | `docs/arch/03-adr/ADR-009_Incremental_Hash_Chain_Verification.md` | [Link](https://www.notion.so/30e0a19b391981b6abf1f33090cf936d) |
| ADR-010 | CRDT Conflict Resolution Strategy | `docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md` | [Link](https://www.notion.so/30e0a19b3919819fa0f5dca14b54bd95) |

---

## 3. 决策分组

### 3.1 平台基础

- ADR-001（状态管理）
- ADR-002（数据库）
- ADR-007（层职责）

### 3.2 安全与完整性

- ADR-003（多层加密）
- ADR-006（密钥派生修复）
- ADR-009（增量哈希链验证）

### 3.3 同步与冲突处理

- ADR-004（CRDT 基础策略）
- ADR-010（冲突解决增强）

### 3.4 业务能力

- ADR-005（OCR/ML 选型）
- ADR-008（余额更新策略）

---

## 4. 维护规则

1. 新增 ADR 采用连续编号。  
2. 每次新增/废弃 ADR 必须更新本索引。  
3. 本地文件名与 Notion `文档名称` 必须一致。  
4. 禁止在本索引使用失效相对路径（例如历史 `14_ADR_*` 链接）。

---

## 5. Notion 索引页

- [ADR-000_INDEX](https://www.notion.so/30e0a19b3919811f9a6bde4315f3fd95)
