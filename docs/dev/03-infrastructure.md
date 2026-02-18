# Infrastructure Layer (基础服务层)

> Crypto, Security, i18n, Category Service, Theme, Shared Utilities, App Initialization

---

## 目录

- [1. 架构概览](#1-架构概览)
- [2. 加密基础设施](#2-加密基础设施)
- [3. 安全基础设施](#3-安全基础设施)
- [4. 国际化基础设施](#4-国际化基础设施)
- [5. 分类基础设施](#5-分类基础设施)
- [6. 共享工具层](#6-共享工具层)
- [7. 应用初始化](#7-应用初始化)
- [8. 加密体系总览](#8-加密体系总览)
- [9. Provider 清单](#9-provider-清单)

---

## 1. 架构概览

```
lib/infrastructure/
├── crypto/              # 加密核心 (4 层加密)
│   ├── services/        # KeyManager, FieldEncryption, HashChain
│   ├── models/          # DeviceKeyPair, ChainVerificationResult
│   ├── repositories/    # 加密存储仓库 (接口 + 实现)
│   ├── database/        # SQLCipher 数据库加密
│   └── providers.dart   # Riverpod providers
├── security/            # 安全服务
│   ├── biometric_service.dart
│   ├── secure_storage_service.dart
│   ├── audit_logger.dart
│   ├── models/          # AuthResult, AuditLogEntry
│   └── providers.dart
├── i18n/                # 国际化
│   ├── formatters/      # DateFormatter, NumberFormatter
│   └── models/          # LocaleSettings
├── category/            # 分类名称解析
│   └── category_service.dart
└── (ml/, sync/, platform/)  # TODO 待实现
```

---

## 2. 加密基础设施

### 2.1 密钥管理 (KeyManager)

**文件**: `lib/infrastructure/crypto/services/key_manager.dart`

**职责**: 高层密钥操作门面，管理 Ed25519 设备密钥对

**公开 API**:
```dart
class KeyManager {
  Future<void> generateDeviceKeyPair()         // 生成新密钥对
  Future<String?> getPublicKey()               // 获取公钥 (Base64)
  Future<String?> getDeviceId()                // 获取设备 ID
  Future<bool> hasKeyPair()                    // 检查密钥是否存在
  Future<Signature> signData(List<int> data)   // 数据签名
  Future<bool> verifySignature({...})          // 签名验证
  Future<void> recoverFromSeed(List<int> seed) // BIP39 种子恢复
  Future<void> clearKeys()                     // 清除密钥
}
```

**设备 ID 生成**: `base64UrlEncode(SHA-256(publicKey))[0:16]`

### 2.2 主密钥管理 (MasterKeyRepository)

**接口**: `lib/infrastructure/crypto/repositories/master_key_repository.dart`
**实现**: `lib/infrastructure/crypto/repositories/master_key_repository_impl.dart`

**职责**: 256-bit AES 主密钥的生成、存储和派生

```dart
abstract class MasterKeyRepository {
  Future<void> initializeMasterKey()    // 生成 32 字节随机密钥
  Future<bool> hasMasterKey()           // 检查是否已初始化
  Future<List<int>> getMasterKey()      // 获取原始密钥
  Future<SecretKey> deriveKey(String purpose) // HKDF 派生子密钥
  Future<void> clearMasterKey()         // 清除密钥
}
```

**实现细节**:
- 存储: FlutterSecureStorage (Base64 编码)
- HKDF salt: `'homepocket-v1-2026'`
- 派生密钥缓存 (按 purpose 分)
- 自定义异常: `MasterKeyNotInitializedException`, `KeyDerivationException`

### 2.3 密钥对存储 (KeyRepository)

**接口**: `lib/infrastructure/crypto/repositories/key_repository.dart`
**实现**: `lib/infrastructure/crypto/repositories/key_repository_impl.dart`

**职责**: Ed25519 密钥对的安全存储

**实现细节**:
- 算法: Ed25519
- 存储位置: FlutterSecureStorage (iOS Keychain / Android Keystore)
- 存储项: 私钥、公钥、设备 ID
- 自定义异常: `KeyNotFoundException`, `InvalidSeedException`

### 2.4 字段加密 (FieldEncryptionService)

**文件**: `lib/infrastructure/crypto/services/field_encryption_service.dart`

**职责**: ChaCha20-Poly1305 AEAD 字段级加密

```dart
class FieldEncryptionService {
  Future<String> encryptField(String plaintext)     // 加密字符串
  Future<String> decryptField(String ciphertext)    // 解密字符串
  Future<String> encryptAmount(double amount)       // 加密金额
  Future<double> decryptAmount(String encrypted)    // 解密金额
  Future<void> clearCache()                         // 清除密钥缓存
}
```

**加密仓库实现** (`EncryptionRepositoryImpl`):
- 算法: ChaCha20-Poly1305 AEAD
- 密文格式: `Base64(nonce[12B] + ciphertext + mac[16B])`
- 密钥派生: HKDF-SHA256 从主密钥
- 每次加密使用随机 nonce
- 自定义异常: `MacValidationException`

### 2.5 哈希链 (HashChainService)

**文件**: `lib/infrastructure/crypto/services/hash_chain_service.dart`

**职责**: 区块链式交易完整性保护

```dart
class HashChainService {
  // 计算交易哈希
  String calculateTransactionHash({
    required String transactionId,
    required int amount,
    required DateTime timestamp,
    required String previousHash,
  })
  // 验证单条交易
  bool verifyTransactionIntegrity(...)
  // 完整链验证 (慢)
  ChainVerificationResult verifyChain(List<Transaction> chain)
  // 增量验证 (100-2000x 快)
  ChainVerificationResult verifyChainIncremental(...)
}
```

**哈希算法**: `SHA-256(transactionId|amount|timestamp|previousHash)`

### 2.6 数据库加密 (EncryptedDatabase)

**文件**: `lib/infrastructure/crypto/database/encrypted_database.dart`

**职责**: SQLCipher 加密数据库工厂

```dart
Future<QueryExecutor> createEncryptedExecutor(
  MasterKeyRepository masterKeyRepository, {
  bool inMemory = false,  // 测试用
})
```

**SQLCipher 配置**:
- 加密算法: AES-256-CBC
- 密钥导出: PBKDF2-HMAC-SHA512, 256,000 次迭代
- 数据库密钥: HKDF(masterKey, 'database_encryption') → 32 字节
- 数据库路径: `<documents>/databases/home_pocket.db`

### 2.7 加密模型

#### DeviceKeyPair (`models/device_key_pair.dart`)
```dart
@freezed
class DeviceKeyPair {
  final String publicKey;    // Base64 编码公钥 (32 字节)
  final String deviceId;     // Base64URL(SHA-256(publicKey))[0:16]
  final DateTime createdAt;
}
```

#### ChainVerificationResult (`models/chain_verification_result.dart`)
```dart
@freezed
class ChainVerificationResult {
  final bool isValid;
  final int totalTransactions;
  final List<String> tamperedTransactionIds;

  factory .valid(int total)
  factory .tampered(int total, List<String> tampered)
  factory .empty()
}
```

---

## 3. 安全基础设施

### 3.1 生物识别 (BiometricService)

**文件**: `lib/infrastructure/security/biometric_service.dart`

```dart
enum BiometricAvailability {
  faceId, fingerprint, strongBiometric, weakBiometric,
  generic, notEnrolled, notSupported
}

class BiometricService {
  Future<BiometricAvailability> checkAvailability()
  Future<AuthResult> authenticate({String? reason, bool biometricOnly = false})
  void resetFailedAttempts()
}
```

- 最大尝试次数: 3（超过后强制 PIN）
- 支持: Face ID / Touch ID / 指纹

### 3.2 安全存储 (SecureStorageService)

**文件**: `lib/infrastructure/security/secure_storage_service.dart`

**存储键常量** (`StorageKeys`):
```dart
static const devicePrivateKey = 'device_private_key';
static const devicePublicKey = 'device_public_key';
static const deviceId = 'device_id';
static const pinHash = 'pin_hash';
static const recoveryKitHash = 'recovery_kit_hash';
static const masterKey = 'master_key';
```

**公开 API**:
```dart
class SecureStorageService {
  Future<void> write(String key, String value)
  Future<String?> read(String key)
  Future<void> delete(String key)
  Future<bool> containsKey(String key)
  Future<void> clearAll()
  // 类型化便捷方法
  Future<String?> getDevicePrivateKey()
  Future<String?> getDeviceId()
  // ...
}
```

**平台配置**:
- iOS: `unlocked_this_device`, 禁止 iCloud 同步
- Android: 加密 SharedPreferences

### 3.3 审计日志 (AuditLogger)

**文件**: `lib/infrastructure/security/audit_logger.dart`

```dart
class AuditLogger {
  Future<void> log({
    required AuditEvent event,
    String? bookId, String? transactionId,
    Map<String, dynamic>? details,
  })
  Future<List<AuditLogEntry>> getLogs({...filters...})
  Future<int> getLogCount()
  Future<String> exportToCSV()
}
```

**审计事件** (`AuditEvent` 枚举):
| 类别 | 事件 |
|------|------|
| 生命周期 | appLaunched, databaseOpened |
| 认证 | biometricAuthSuccess, biometricAuthFailed, pinAuthSuccess, pinAuthFailed |
| 完整性 | chainVerified, tamperDetected |
| 密钥 | keyGenerated, keyRotated, recoveryKitGenerated, keyRecovered |
| 同步 | syncStarted, syncCompleted, syncFailed, devicePaired, deviceUnpaired |
| 数据 | backupExported, backupImported, securitySettingsChanged |

**安全规则 (details 字段)**:
- 允许: 算法名称、交易 ID、计数、错误类型
- 禁止: 加密密钥、明文金额、PIN

### 3.4 安全模型

#### AuthResult (`models/auth_result.dart`)
```dart
@freezed sealed class AuthResult {
  .success()
  .failed({int failedAttempts})
  .fallbackToPIN()
  .tooManyAttempts()
  .lockedOut()
  .error({String message})
}
```

#### AuditLogEntry (`models/audit_log_entry.dart`)
```dart
@freezed class AuditLogEntry {
  String id;          // ULID
  AuditEvent event;
  String deviceId;
  String? bookId, transactionId;
  String? details;    // JSON (无敏感信息)
  DateTime timestamp;
}
```

---

## 4. 国际化基础设施

### 4.1 日期格式化 (DateFormatter)

**文件**: `lib/infrastructure/i18n/formatters/date_formatter.dart`

全部为**静态方法**:

```dart
class DateFormatter {
  static String formatDate(DateTime date, Locale locale)
  static String formatDateTime(DateTime date, Locale locale)
  static String formatMonthYear(DateTime date, Locale locale)
  static String formatRelative(DateTime date, Locale locale)
}
```

**语言格式**:
| 方法 | 日语 | 中文 | 英语 |
|------|------|------|------|
| formatDate | `yyyy/MM/dd` | `yyyy年MM月dd日` | `MM/dd/yyyy` |
| formatDateTime | `yyyy/MM/dd HH:mm` | `yyyy年MM月dd日 HH:mm` | `MM/dd/yyyy h:mm a` |
| formatMonthYear | `yyyy年M月` | `yyyy年M月` | `MMMM yyyy` |
| formatRelative | 今日/昨日/N日前/日期 | 今天/昨天/N天前/日期 | Today/Yesterday/N days ago/date |

### 4.2 数字格式化 (NumberFormatter)

**文件**: `lib/infrastructure/i18n/formatters/number_formatter.dart`

全部为**静态方法**:

```dart
class NumberFormatter {
  static String formatNumber(double number, Locale locale, {int decimals = 0})
  static String formatCurrency(double amount, String currencyCode, Locale locale)
  static String formatPercentage(double value, Locale locale, {int decimals = 1})
  static String formatCompact(double number, Locale locale)
}
```

**货币格式规则**:
| 货币 | 小数位 | 示例 |
|------|--------|------|
| JPY | 0 | ¥1,235 |
| USD | 2 | $1,234.56 |
| CNY | 2 | ¥1,234.56 |
| EUR | 2 | €1,234.56 |
| GBP | 2 | £1,234.56 |

**紧凑数字**:
| 语言 | 示例 |
|------|------|
| 日语/中文 | 123万 (使用"万"单位) |
| 英语 | 1.23M (K/M/B) |

### 4.3 语言设置 (LocaleSettings)

**文件**: `lib/infrastructure/i18n/models/locale_settings.dart`

```dart
@freezed class LocaleSettings {
  final Locale locale;
  final bool isSystemDefault;

  factory .defaultSettings()       → Locale('ja'), system=false
  factory .fromSystem(Locale sys)  → 规范化至支持的语言 (ja/zh/en)
}
```

### 4.4 ARB 翻译文件

**位置**: `lib/l10n/`

| 文件 | 语言 |
|------|------|
| `app_ja.arb` | 日语 (默认) |
| `app_en.arb` | 英语 |
| `app_zh.arb` | 简体中文 |

**配置** (`l10n.yaml`):
```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: S
output-dir: lib/generated
```

**使用方式**: `S.of(context).keyName`

**关键分类**:
- 应用名/导航/交易/类型/账本/操作/状态
- 错误消息/成功消息
- 设置相关字符串
- 所有字符串含 `@` 元数据

---

## 5. 分类基础设施

### CategoryService

**文件**: `lib/infrastructure/category/category_service.dart`

**职责**: 分类 ID → 本地化显示名称的解析

```dart
abstract final class CategoryService {
  static String resolveFromId(String categoryId, Locale locale)
  static String resolve(String nameKey, Locale locale)
}
```

**数据**:
- 19 个 L1 支出分类 + 4 个 L1 收入分类
- 103 个 L2 子分类
- 三语全覆盖（日语、中文、英语）

**解析规则**:
- `categoryId` (如 `cat_food`) → `nameKey` (如 `category_food`) → 本地化名称
- 自定义分类: 找不到翻译则返回 `nameKey` 本身

---

## 6. 共享工具层

### 6.1 Result 类型

**文件**: `lib/shared/utils/result.dart`

```dart
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;
  bool get isError => !isSuccess;

  factory Result.success(T data)
  factory Result.error(String message)
}
```

Use Case 层统一返回类型。

### 6.2 默认分类常量

**文件**: `lib/shared/constants/default_categories.dart`

```dart
abstract final class DefaultCategories {
  static List<Category> get all          // 全部分类 (L1 + L2)
  static List<Category> get expenseL1    // 19 个支出 L1
  static List<Category> get incomeL1     // 4 个收入 L1
  static List<CategoryLedgerConfig> get defaultLedgerConfigs
}
```

**默认账本分类**:
| 生存 (Survival) | 灵魂 (Soul) |
|------------------|-------------|
| 食费, 日用品, 交通, 社交, 医疗, 水电, 通信, 住居, 车辆, 税金, 保险, 其他, 未分类 | 趣味, 服饰, 教育, 资产 |

### 6.3 主题常量

**`lib/core/theme/app_colors.dart`** — 50+ 静态颜色常量
**`lib/core/theme/app_text_styles.dart`** — 20+ 静态文本样式（含等宽数字金额样式）
**`lib/core/theme/app_theme.dart`** — Material 3 Light 主题

---

## 7. 应用初始化

### main.dart

**文件**: `lib/main.dart`

**初始化顺序**（在 `runApp()` 之前）:

```
1. WidgetsFlutterBinding.ensureInitialized()
2. 主密钥初始化
   ├── MasterKeyRepositoryImpl.hasMasterKey()
   └── MasterKeyRepositoryImpl.initializeMasterKey()  [首次]
3. 设备密钥对生成
   ├── KeyManager.hasKeyPair()
   └── KeyManager.generateDeviceKeyPair()  [首次]
4. 加密数据库创建
   └── createEncryptedExecutor(masterKeyRepository)
5. ProviderContainer 创建
   └── override: appDatabaseProvider → 已初始化数据库
6. runApp(UncontrolledProviderScope)
7. App 内初始化 (HomePocketApp)
   ├── SeedCategoriesUseCase.execute()    → 播种分类
   └── EnsureDefaultBookUseCase.execute() → 确保账本
```

**关键**:
- 必须在 `runApp()` 前完成密钥和数据库初始化
- 使用 `UncontrolledProviderScope` 传递已初始化的 container
- 支持 `inMemory` 模式用于测试

---

## 8. 加密体系总览

| 层级 | 算法 | 密钥来源 | 数据格式 | 保护对象 |
|------|------|----------|----------|----------|
| L1 数据库 | SQLCipher AES-256-CBC | HKDF(master_key, 'database_encryption') | 透明加密 | 全部数据库内容 |
| L2 字段 | ChaCha20-Poly1305 AEAD | HKDF(master_key, 'field_encryption') | Base64(nonce+cipher+mac) | 交易备注 |
| L3 完整性 | SHA-256 哈希链 | 无密钥（单向哈希） | Hex 字符串 | 交易完整性 |
| L4 设备密钥 | Ed25519 | Random.secure() | Base64 | 设备身份/签名 |
| 主密钥 | AES-256 | Random.secure() 32字节 | Base64 in SecureStorage | 所有子密钥的根 |
| 备份 | AES-256-GCM + PBKDF2 | 用户密码 | salt+nonce+cipher+mac | 备份文件 |

---

## 9. Provider 清单

### 加密 Providers (`crypto/providers.dart`)

| Provider | keepAlive | 返回类型 |
|----------|-----------|----------|
| `masterKeyRepositoryProvider` | — | MasterKeyRepository |
| `keyRepositoryProvider` | — | KeyRepository |
| `keyManagerProvider` | — | KeyManager |
| `hasKeyPairProvider` | — | Future\<bool\> |
| `encryptionRepositoryProvider` | — | EncryptionRepository |
| `fieldEncryptionServiceProvider` | — | FieldEncryptionService |
| `hashChainServiceProvider` | — | HashChainService |

### 安全 Providers (`security/providers.dart`)

| Provider | keepAlive | 返回类型 |
|----------|-----------|----------|
| `flutterSecureStorageProvider` | Yes | FlutterSecureStorage |
| `biometricServiceProvider` | Yes | BiometricService |
| `biometricAvailabilityProvider` | — | Future\<BiometricAvailability\> |
| `secureStorageServiceProvider` | — | SecureStorageService |
| `auditLoggerProvider` | — | AuditLogger |
| `appDatabaseProvider` | — | AppDatabase (placeholder, overridden) |

---

*最后更新: 2026-02-18*
