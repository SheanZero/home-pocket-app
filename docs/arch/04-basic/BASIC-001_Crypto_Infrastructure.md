# BASIC-001: 加密基础设施 (Crypto Infrastructure)

**文档编号:** BASIC-001  
**文档版本:** 1.1  
**创建日期:** 2026-02-06  
**最后更新:** 2026-02-21  
**状态:** 部分实施（v0.1.0）

---

## 1. 目标与边界

本文件定义 `lib/infrastructure/crypto/` 的技术能力边界，仅包含密码学基础能力，不包含业务流程 UI。

### 1.1 本文档覆盖

- 密钥管理（Ed25519）
- 敏感字段加密（ChaCha20-Poly1305）
- 交易哈希链完整性验证（SHA-256）
- SQLCipher 数据库密钥派生与初始化

### 1.2 不在本文档范围

- 生物识别认证、安全存储、审计日志（见 BASIC-002）
- i18n 与格式化（见 BASIC-003）
- 分类业务规则（见 BASIC-004）

---

## 2. 当前实现状态（与代码一致）

| 能力 | 状态 | 代码位置 |
|---|---|---|
| KeyManager | 已实施 | `lib/infrastructure/crypto/services/key_manager.dart` |
| FieldEncryptionService | 已实施 | `lib/infrastructure/crypto/services/field_encryption_service.dart` |
| HashChainService | 已实施 | `lib/infrastructure/crypto/services/hash_chain_service.dart` |
| MasterKeyRepository / HKDF 派生 | 已实施 | `lib/infrastructure/crypto/repositories/master_key_repository*.dart` |
| SQLCipher 初始化 | 已实施 | `lib/infrastructure/crypto/database/encrypted_database.dart` |
| Riverpod providers | 已实施 | `lib/infrastructure/crypto/providers.dart` |
| RecoveryKitService | 未实施（缺口） | 目标：`lib/infrastructure/crypto/services/recovery_kit_service.dart` |
| PhotoEncryptionService | 未实施（缺口） | 目标：`lib/infrastructure/crypto/services/photo_encryption_service.dart` |

---

## 3. 从功能模块迁移后的对齐结果

来源文档：`MOD-005_Security.md`（已废弃）。

| 原模块能力 | 当前归属 |
|---|---|
| E02 密钥管理 | BASIC-001（本文件） |
| ENC-02 备注字段加密 | BASIC-001（本文件） |
| D03 哈希链算法与验证 | BASIC-001（本文件） |
| E03 生物识别/PIN/安全存储/审计 | BASIC-002 |
| 恢复套件流程 | 仍有能力缺口，待补齐至 BASIC-001 + BASIC-002 |

---

## 4. 能力缺口与补齐建议

### 4.1 缺口 A：Recovery Kit 服务未基础化

- 当前现状：`KeyManager.recoverFromSeed()` 已存在，但缺少统一的 Recovery Kit 生成/校验/导出基础服务。
- 影响：安全恢复流程在架构文档中存在，但基础设施层未形成完整 API。
- 建议：新增 `RecoveryKitService`，职责包括助记词生成、哈希校验、导出接口。

### 4.2 缺口 B：照片文件加密未落地

- 当前现状：只有字段级加密，文件级加密能力缺失。
- 影响：OCR/票据图片加密路径不完整。
- 建议：新增 `PhotoEncryptionService`（AES-256-GCM）并配套文件存储读写规范。

### 4.3 缺口 C：传输层 E2EE 能力尚未文档化到实现层

- 当前现状：架构层有策略描述，但基础实现与接口规范尚未形成稳定文档契约。
- 建议：在后续 sync 基础文档中明确密钥协商、会话轮转、消息签名接口。

---

## 5. 初始化与依赖约束

### 5.1 初始化顺序（MUST）

1. 先初始化 `SecureStorageService`（BASIC-002）。
2. 初始化 `MasterKeyRepository`，确保主密钥可用。
3. 创建 SQLCipher executor（`createEncryptedExecutor`）。
4. 最后初始化依赖数据库的上层服务。

### 5.2 Provider 单一来源

- `lib/infrastructure/crypto/providers.dart` 为 Crypto Provider 单一来源。
- 禁止在 Feature 层重复定义同能力 provider。

---

## 6. 安全规则（强制）

- 禁止直接使用 `flutter_secure_storage` 存取业务密钥；必须经 `SecureStorageService`。
- 禁止在日志中输出密钥、明文金额、助记词。
- 加密参数与算法升级必须通过 ADR。

---

## 7. 关联文档

- 本地：`docs/arch/04-basic/BASIC-002_Security_Infrastructure.md`
- 本地：`docs/arch/03-adr/ADR-003_Multi_Layer_Encryption.md`
- 本地：`docs/arch/03-adr/ADR-006_Key_Derivation_Security.md`
- Notion: [BASIC-001_Crypto_Infrastructure](https://www.notion.so/30e0a19b391981a8a47be7b84c0a899c)
