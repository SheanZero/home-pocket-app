# BASIC-002: 安全基础设施 (Security Infrastructure)

**文档编号:** BASIC-002  
**文档版本:** 1.1  
**创建日期:** 2026-02-06  
**最后更新:** 2026-02-21  
**状态:** 已实施（v0.1.0）

---

## 1. 目标与边界

本文件定义 `lib/infrastructure/security/` 的平台安全能力：认证、密钥容器访问、审计记录。

### 1.1 本文档覆盖

- `BiometricService`（生物识别认证）
- `SecureStorageService`（Keychain/Keystore 封装）
- `AuditLogger`（安全审计日志）
- 安全 Provider 组织与依赖约束

### 1.2 不在本文档范围

- 密码学算法与数据库加密（见 BASIC-001）
- i18n/本地化（见 BASIC-003）
- 分类业务规则（见 BASIC-004）

---

## 2. 当前实现状态（与代码一致）

| 能力 | 状态 | 代码位置 |
|---|---|---|
| BiometricService | 已实施 | `lib/infrastructure/security/biometric_service.dart` |
| SecureStorageService | 已实施 | `lib/infrastructure/security/secure_storage_service.dart` |
| AuditLogger | 已实施 | `lib/infrastructure/security/audit_logger.dart` |
| AuthResult / AuditLogEntry models | 已实施 | `lib/infrastructure/security/models/*.dart` |
| Security Providers | 已实施 | `lib/infrastructure/security/providers.dart` |

---

## 3. 从功能模块迁移后的对齐结果

来源文档：`MOD-005_Security.md`（已废弃）。

| 原模块能力 | 当前归属 |
|---|---|
| 生物识别认证（E03） | BASIC-002 |
| 安全存储（密钥/PIN/恢复哈希） | BASIC-002 |
| 审计日志记录与导出 | BASIC-002 |
| 密钥管理/字段加密/哈希链算法 | BASIC-001 |

结论：`MOD-005` 中技术能力已拆分归并到 BASIC-001 与 BASIC-002，模块文档应删除。

---

## 4. 关键设计约束

### 4.1 SecureStorage 的唯一入口

- 所有安全键名集中定义在 `StorageKeys`。
- 禁止在其他层硬编码键名。
- 禁止直接实例化 `FlutterSecureStorage` 绕过 provider。

### 4.2 Biometric 失败策略

- 连续失败计数由 `BiometricService` 管理。
- 达到阈值后返回 `fallbackToPIN` / `tooManyAttempts`，由上层 UI/流程处理。

### 4.3 审计日志敏感信息约束

- `details` 字段禁止写入：密钥、助记词、明文金额、PIN。
- 允许记录：算法名、事务 ID、错误类型、数量统计。

---

## 5. 当前缺口与注意事项

### 5.1 AppDatabase Provider 需要启动期覆盖

`appDatabaseProvider` 在 `providers.dart` 中为占位实现，必须在应用初始化时 override。否则 `AuditLogger` 无法工作。

### 5.2 PIN/恢复流程是业务流程，不是基础设施流程

BASIC-002 只提供平台能力，不承担“设置 PIN / 恢复引导”等 feature 级流程编排。该流程应在 application/features 层实现并消费本层 API。

---

## 6. 关联文档

- 本地：`docs/arch/04-basic/BASIC-001_Crypto_Infrastructure.md`
- 本地：`docs/arch/03-adr/ADR-003_Multi_Layer_Encryption.md`
- Notion: [BASIC-002_Security_Infrastructure](https://www.notion.so/30e0a19b391981db8528eeb4812833d5)
