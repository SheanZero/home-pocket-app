# BASIC-001: 加密基础设施 (Crypto Infrastructure)

**文档编号:** BASIC-001
**文档版本:** 1.0
**创建日期:** 2026-02-06
**最后更新:** 2026-02-06
**状态:** 已实施
**作者:** Claude Opus 4.6

---

## 1. 概述

本文档是 `lib/infrastructure/crypto/` 的**技术实现参考**，面向开发者提供加密基础设施的完整 API 说明、算法细节和使用示例。

### 文档定位

| 文档 | 定位 | 关注点 |
|------|------|--------|
| **本文档 (BASIC-001)** | 基础技术实现文档 | Infrastructure 层密码学原语的 API、算法、代码示例 |
| ARCH-003_Security_Architecture | 安全架构顶层设计 | 威胁模型、安全原则、4层加密策略 |
| MOD-005_Security (MOD-006) | 模块功能设计文档 | 安全模块业务需求、UI 组件、用户流程 |
| ADR-003 / ADR-006 | 架构决策记录 | 多层加密策略、密钥派生方案的决策依据 |

---

## 2. 目录结构

```
lib/infrastructure/crypto/
├── services/
│   ├── key_manager.dart              # 密钥管理器（Ed25519 密钥对管理）
│   ├── field_encryption_service.dart  # 字段加密服务（ChaCha20-Poly1305）
│   └── hash_chain_service.dart        # 哈希链服务（SHA-256 防篡改）
├── models/
│   ├── device_key_pair.dart           # 设备密钥对模型（唯一定义）
│   └── chain_verification_result.dart # 链验证结果模型（唯一定义）
├── repositories/
│   ├── key_repository.dart            # 密钥仓库接口
│   ├── key_repository_impl.dart       # 密钥仓库实现
│   ├── encryption_repository.dart     # 加密仓库接口
│   └── encryption_repository_impl.dart # 加密仓库实现
└── database/
    └── encrypted_database.dart        # SQLCipher 加密数据库配置
```

> **注意:** `photo_encryption_service.dart` 和 `recovery_kit_service.dart` 在架构设计中规划，
> 照片加密将在 Phase 2 实现，恢复套件服务目前位于 `lib/features/security/application/services/`。

---

## 3. 核心组件详解

### 3.1 KeyManager（密钥管理器）

**文件:** `lib/infrastructure/crypto/services/key_manager.dart`

**职责:**
- Ed25519 密钥对生成与存储
- 数字签名与验证
- 密钥恢复（从 BIP39 种子）
- 密钥清除

**技术栈:** `cryptography` + `flutter_secure_storage`

#### 类签名

```dart
class KeyManager {
  KeyManager({required KeyRepository repository});
  final KeyRepository _repository;
}
```

#### 核心方法

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `generateDeviceKeyPair()` | `Future<DeviceKeyPair>` | 首次启动时生成 Ed25519 密钥对 |
| `getPublicKey()` | `Future<String?>` | 获取 Base64 编码的公钥 |
| `getDeviceId()` | `Future<String?>` | 获取设备 ID（SHA-256 前 16 字符） |
| `hasKeyPair()` | `Future<bool>` | 检查密钥对是否存在 |
| `signData(List<int> data)` | `Future<Signature>` | Ed25519 数字签名 |
| `verifySignature(...)` | `Future<bool>` | 验证 Ed25519 签名 |
| `recoverFromSeed(List<int> seed)` | `Future<DeviceKeyPair>` | 从 BIP39 种子恢复密钥 |
| `clearKeys()` | `Future<void>` | 删除所有密钥（不可逆） |

#### 密钥层次结构

```
Master Key (Ed25519 Private Key)
    │
    ├── HKDF → Database Key (AES-256-CBC for SQLCipher)
    ├── HKDF → Field Encryption Key (ChaCha20-Poly1305)
    ├── HKDF → File Encryption Key (AES-256-GCM, Phase 2)
    └── HKDF → Sync Key (TLS 1.3 + E2EE, Phase 3)
```

**HKDF 参数:**
- 算法: HKDF-SHA256
- Salt: `homepocket-v1-2026`
- Info: 用途标识字符串
- Output: 32 字节 (256-bit)

#### 设备 ID 生成算法

```dart
String _generateDeviceId(List<int> publicKeyBytes) {
  final hash = sha256.convert(publicKeyBytes);
  return base64UrlEncode(hash.bytes).substring(0, 16);
}
```

格式: `Base64URL(SHA-256(publicKey))[0:16]`

#### Provider 定义

```dart
@riverpod
KeyRepository keyRepository(KeyRepositoryRef ref) {
  return KeyRepositoryImpl(
    secureStorage: const FlutterSecureStorage(),
  );
}

@riverpod
KeyManager keyManager(KeyManagerRef ref) {
  final repository = ref.watch(keyRepositoryProvider);
  return KeyManager(repository: repository);
}

@riverpod
Future<bool> hasKeyPair(HasKeyPairRef ref) async {
  final keyManager = ref.watch(keyManagerProvider);
  return keyManager.hasKeyPair();
}
```

#### 使用示例

```dart
// 初始化密钥（AppInitializer 中调用）
final keyManager = ref.read(keyManagerProvider);
if (!await keyManager.hasKeyPair()) {
  await keyManager.generateDeviceKeyPair();
}

// 获取设备信息
final deviceId = await keyManager.getDeviceId();
final publicKey = await keyManager.getPublicKey();

// 数字签名
final signature = await keyManager.signData(utf8.encode('data'));
final isValid = await keyManager.verifySignature(
  data: utf8.encode('data'),
  signature: signature,
  publicKeyBase64: publicKey!,
);
```

---

### 3.2 FieldEncryptionService（字段加密服务）

**文件:** `lib/infrastructure/crypto/services/field_encryption_service.dart`

**职责:**
- 敏感字段加密/解密（交易备注、商家名称）
- 金额加密/解密
- 加密密钥缓存管理

**算法:** ChaCha20-Poly1305 AEAD

#### 类签名

```dart
class FieldEncryptionService {
  FieldEncryptionService({required EncryptionRepository repository});
  final EncryptionRepository _repository;
}
```

#### 核心方法

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `encryptField(String plaintext)` | `Future<String>` | 加密字符串 → Base64 密文 |
| `decryptField(String ciphertext)` | `Future<String>` | 解密 Base64 密文 → 明文 |
| `encryptAmount(double amount)` | `Future<String>` | 加密数值金额 |
| `decryptAmount(String encrypted)` | `Future<double>` | 解密金额 |
| `clearCache()` | `Future<void>` | 清除内存中缓存的加密密钥 |

#### 加密格式

```
密文 = Base64( nonce[12B] + encrypted_data + mac[16B] )
```

| 组成部分 | 大小 | 说明 |
|----------|------|------|
| Nonce | 12 字节 (96-bit) | 每次加密随机生成 |
| Encrypted Data | 变长 | ChaCha20 加密的数据 |
| MAC | 16 字节 (128-bit) | Poly1305 认证标签 |

#### 密钥派生

```dart
Future<SecretKey> _deriveEncryptionKey() async {
  final publicKeyBase64 = await _keyRepository.getPublicKey();
  final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  final publicKeyBytes = base64Decode(publicKeyBase64);

  return await hkdf.deriveKey(
    secretKey: SecretKey(publicKeyBytes),
    info: utf8.encode('homepocket_field_encryption_v1'),
    nonce: const [],  // 确定性派生
  );
}
```

**性能优化:** 加密密钥首次派生后缓存在内存中，避免重复派生。

#### Provider 定义

```dart
@riverpod
EncryptionRepository encryptionRepository(EncryptionRepositoryRef ref) {
  final keyRepository = ref.watch(keyRepositoryProvider);
  return EncryptionRepositoryImpl(keyRepository: keyRepository);
}

@riverpod
FieldEncryptionService fieldEncryptionService(FieldEncryptionServiceRef ref) {
  final repository = ref.watch(encryptionRepositoryProvider);
  return FieldEncryptionService(repository: repository);
}
```

#### 使用示例

```dart
final encService = ref.read(fieldEncryptionServiceProvider);

// 加密交易备注
final encryptedNote = await encService.encryptField('午餐费用');
final decryptedNote = await encService.decryptField(encryptedNote);

// 加密金额
final encryptedAmount = await encService.encryptAmount(1234.56);
final decryptedAmount = await encService.decryptAmount(encryptedAmount);

// 登出时清除缓存
await encService.clearCache();
```

#### 异常处理

```dart
class MacValidationException implements Exception {
  MacValidationException(this.message);
  final String message;
}
```

当 MAC 验证失败时（数据被篡改或密钥不匹配）抛出 `MacValidationException`。

---

### 3.3 HashChainService（哈希链服务）

**文件:** `lib/infrastructure/crypto/services/hash_chain_service.dart`

**职责:**
- 区块链式交易哈希计算
- 单笔交易完整性验证
- 完整链验证
- 增量链验证（高性能）

**算法:** SHA-256

#### 类签名

```dart
class HashChainService {
  // 无依赖 - 无状态服务
}
```

#### 核心方法

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `calculateTransactionHash(...)` | `String` | 计算交易哈希 |
| `verifyTransactionIntegrity(...)` | `bool` | 验证单笔交易 |
| `verifyChain(List<Map<String, dynamic>>)` | `ChainVerificationResult` | 完整链验证 |
| `verifyChainIncremental(...)` | `ChainVerificationResult` | 增量验证（推荐） |

#### 哈希计算公式

```
Hash = SHA-256(transactionId + "|" + amount + "|" + timestamp + "|" + previousHash)
```

**输入字段:**
- `transactionId`: 交易唯一标识
- `amount`: 交易金额
- `timestamp`: Unix 时间戳（毫秒）
- `previousHash`: 前一笔交易的哈希值

> **注意:** 架构设计中规划的完整哈希输入为
> `id|bookId|deviceId|amount|type|categoryId|ledgerType|timestamp|prevHash`，
> 当前 MVP 实现使用简化版本，后续版本将扩展。

#### 验证策略

| 策略 | 适用场景 | 性能 |
|------|---------|------|
| **增量验证** (推荐) | 日常使用、新增交易后 | 100-2000x 优于全量 |
| **完整验证** | 后台定期审计、首次打开 | 基准性能 |

```dart
// 增量验证（仅验证新增部分）
final result = service.verifyChainIncremental(
  transactions,
  lastVerifiedIndex: 500,  // 从第 501 条开始验证
);

// 完整验证（验证全部）
final result = service.verifyChain(transactions);

// lastVerifiedIndex == -1 时等同于完整验证
final result = service.verifyChainIncremental(
  transactions,
  lastVerifiedIndex: -1,
);
```

#### 性能基准 (ADR-009)

| 交易数量 | 完整验证 | 增量验证 (最后 10 条) | 提升倍数 |
|----------|---------|---------------------|---------|
| 100 | ~5ms | ~0.5ms | 10x |
| 1,000 | ~50ms | ~0.5ms | 100x |
| 10,000 | ~500ms | ~0.5ms | 1,000x |
| 100,000 | ~5s | ~0.5ms | 10,000x |

#### Provider 定义

```dart
@riverpod
HashChainService hashChainService(HashChainServiceRef ref) {
  return HashChainService();
}
```

#### 使用示例

```dart
final hashService = ref.read(hashChainServiceProvider);

// 计算新交易哈希
final hash = hashService.calculateTransactionHash(
  transactionId: 'tx_001',
  amount: 1500.0,
  timestamp: DateTime.now().millisecondsSinceEpoch,
  previousHash: prevHash,
);

// 验证单笔交易
final isValid = hashService.verifyTransactionIntegrity(
  transactionId: 'tx_001',
  amount: 1500.0,
  timestamp: 1706000000000,
  previousHash: prevHash,
  currentHash: hash,
);

// 增量验证（推荐）
final result = hashService.verifyChainIncremental(
  transactions,
  lastVerifiedIndex: lastVerified,
);

if (!result.isValid) {
  print('篡改检测: ${result.tamperedTransactionIds}');
}
```

---

### 3.4 PhotoEncryptionService（照片加密服务）- 规划中

> **状态:** Phase 2 实现，当前为架构设计阶段

**文件:** `lib/infrastructure/crypto/services/photo_encryption_service.dart`（待创建）

**职责:**
- 交易照片文件加密/解密
- 加密后删除明文文件
- 解密到内存（`Uint8List`），不写回磁盘

**规划算法:** AES-256-GCM

**规划格式:**
```
加密文件 (.enc) = nonce[12B] + ciphertext + mac[16B]
```

**安全原则:**
- 明文文件加密后立即删除
- 解密仅到内存，不持久化明文
- 使用独立的文件加密密钥（HKDF 派生）

---

### 3.5 RecoveryKitService（恢复套件服务）

> **注意:** 当前实现位于 `lib/features/security/application/services/recovery_kit_service.dart`，
> 架构规划将其迁移至 `lib/infrastructure/crypto/services/`。
> 详细 API 文档见 [BASIC-002_Security_Infrastructure.md](./BASIC-002_Security_Infrastructure.md) 第 3.3 节。

**职责:**
- BIP39 24 词助记词生成（256-bit 熵）
- 助记词验证（SHA-256 哈希比对）
- 密钥恢复（助记词 → 种子 → Ed25519 密钥对）
- 验证词选择（随机 3 个位置用于 UX 确认）

**安全规则:**
- 仅存储助记词的 SHA-256 哈希
- 绝不明文存储助记词
- 助记词仅在用户界面短暂显示

---

## 4. 数据模型

### 4.1 DeviceKeyPair（设备密钥对）

**唯一定义位置:** `lib/infrastructure/crypto/models/device_key_pair.dart`

```dart
@freezed
class DeviceKeyPair with _$DeviceKeyPair {
  const factory DeviceKeyPair({
    required String publicKey,    // Base64 编码的 Ed25519 公钥 (32 bytes)
    required String deviceId,     // Base64URL(SHA-256(publicKey))[0:16]
    required DateTime createdAt,  // 密钥生成时间戳
  }) = _DeviceKeyPair;
}
```

**字段说明:**

| 字段 | 类型 | 格式 | 说明 |
|------|------|------|------|
| `publicKey` | `String` | Base64 | Ed25519 公钥，32 字节 |
| `deviceId` | `String` | 16 字符 | SHA-256 哈希前 16 字符 |
| `createdAt` | `DateTime` | ISO 8601 | 密钥对生成时间 |

> **重要:** 此模型在整个项目中有且仅有一个定义，所有需要使用设备密钥对的地方必须引用此文件。

---

### 4.2 ChainVerificationResult（链验证结果）

**唯一定义位置:** `lib/infrastructure/crypto/models/chain_verification_result.dart`

```dart
@freezed
class ChainVerificationResult with _$ChainVerificationResult {
  const factory ChainVerificationResult({
    required bool isValid,
    required int totalTransactions,
    required List<String> tamperedTransactionIds,
  }) = _ChainVerificationResult;

  // 工厂构造函数
  factory ChainVerificationResult.valid({required int totalTransactions});
  factory ChainVerificationResult.tampered({
    required int totalTransactions,
    required List<String> tamperedTransactionIds,
  });
  factory ChainVerificationResult.empty();
}
```

**字段说明:**

| 字段 | 类型 | 说明 |
|------|------|------|
| `isValid` | `bool` | 链完整性状态 |
| `totalTransactions` | `int` | 验证的交易总数 |
| `tamperedTransactionIds` | `List<String>` | 被篡改的交易 ID 列表 |

**工厂方法:**

| 方法 | 场景 | isValid | tamperedTransactionIds |
|------|------|---------|----------------------|
| `.valid()` | 链完整无篡改 | `true` | `[]` |
| `.tampered()` | 检测到篡改 | `false` | 非空列表 |
| `.empty()` | 无交易数据 | `true` | `[]` |

> **重要:** 此模型在整个项目中有且仅有一个定义。

---

## 5. Repository 层

### 5.1 KeyRepository（密钥仓库接口）

**文件:** `lib/infrastructure/crypto/repositories/key_repository.dart`

```dart
abstract class KeyRepository {
  Future<DeviceKeyPair> generateKeyPair();
  Future<DeviceKeyPair> recoverFromSeed(List<int> seed);
  Future<String?> getPublicKey();
  Future<String?> getDeviceId();
  Future<bool> hasKeyPair();
  Future<Signature> signData(List<int> data);
  Future<bool> verifySignature({
    required List<int> data,
    required Signature signature,
    required String publicKeyBase64,
  });
  Future<void> clearKeys();
}
```

**自定义异常:**

```dart
class KeyNotFoundException implements Exception {
  KeyNotFoundException(this.message);
  final String message;
}

class InvalidSeedException implements Exception {
  InvalidSeedException(this.message);
  final String message;
}
```

### 5.2 KeyRepositoryImpl（密钥仓库实现）

**文件:** `lib/infrastructure/crypto/repositories/key_repository_impl.dart`

**技术栈:** `cryptography` (Ed25519) + `crypto` (SHA-256) + `flutter_secure_storage`

**安全存储键:**

| 常量 | 存储键 | 内容 |
|------|--------|------|
| `_privateKeyKey` | `device_private_key` | Ed25519 私钥 |
| `_publicKeyKey` | `device_public_key` | Ed25519 公钥 (Base64) |
| `_deviceIdKey` | `device_id` | 设备 ID (16字符) |

**平台安全存储配置:**

| 平台 | 配置 |
|------|------|
| iOS | `KeychainAccessibility.unlocked_this_device` (Keychain) |
| Android | `encryptedSharedPreferences: true` (Android Keystore) |

**密钥生成流程:**

```
1. 检查密钥是否已存在 → 已存在则抛出 StateError
2. Ed25519.newKeyPair() → 生成密钥对
3. 提取私钥字节 → Base64 编码 → 存入 Secure Storage
4. 提取公钥字节 → Base64 编码 → 存入 Secure Storage
5. SHA-256(publicKey) → Base64URL → 取前16字符 → 存入 Secure Storage
6. 返回 DeviceKeyPair
```

### 5.3 EncryptionRepository（加密仓库接口）

**文件:** `lib/infrastructure/crypto/repositories/encryption_repository.dart`

```dart
abstract class EncryptionRepository {
  Future<String> encryptField(String plaintext);
  Future<String> decryptField(String ciphertext);
  Future<String> encryptAmount(double amount);
  Future<double> decryptAmount(String encryptedAmount);
  Future<void> clearCache();
}
```

**加密规格:**
- **算法:** ChaCha20-Poly1305 AEAD
- **密钥大小:** 256-bit (32 bytes)
- **密钥派生:** HKDF-SHA256
- **Nonce:** 96-bit (12 bytes, 每次加密随机生成)
- **MAC:** 128-bit (16 bytes)

**自定义异常:**

```dart
class MacValidationException implements Exception {
  MacValidationException(this.message);
  final String message;
}
```

### 5.4 EncryptionRepositoryImpl（加密仓库实现）

**文件:** `lib/infrastructure/crypto/repositories/encryption_repository_impl.dart`

**加密流程:**

```
明文 → UTF-8 编码 → ChaCha20-Poly1305 加密 → nonce + 密文 + MAC → Base64 编码
```

**解密流程:**

```
Base64 解码 → 分离 nonce(12B) / 密文 / MAC(16B) → ChaCha20-Poly1305 解密 + MAC验证 → UTF-8 解码
```

**Nonce 生成:**

```dart
List<int> _generateNonce() {
  return List<int>.generate(12, (_) => _random.nextInt(256));
}
```

使用 `Random.secure()` 确保密码学安全的随机性。

**最小密文长度验证:** 28 字节 (12 nonce + 16 MAC)

---

## 6. 数据库加密配置

**文件:** `lib/infrastructure/crypto/database/encrypted_database.dart`

### createEncryptedExecutor 函数

```dart
Future<QueryExecutor> createEncryptedExecutor(
  KeyManager keyManager,
  {bool inMemory = false}
)
```

**参数:**
- `keyManager`: 用于获取数据库加密密钥
- `inMemory`: 是否使用内存数据库（测试用）

### SQLCipher 配置

| 参数 | 值 | 说明 |
|------|-----|------|
| Cipher | AES-256-CBC | 对称加密算法 |
| KDF Iterations | 256,000 | PBKDF2-HMAC-SHA512 迭代次数 |
| Key Size | 256-bit (32 bytes) | 数据库加密密钥大小 |

**PRAGMA 设置:**

```sql
PRAGMA key = "x'{hex_key}'";
PRAGMA cipher = "aes-256-cbc";
PRAGMA kdf_iter = 256000;
PRAGMA cipher_version;
```

### 数据库密钥派生（MVP 版本）

```dart
String _deriveDatabaseKey(String publicKeyBase64) {
  final publicKeyBytes = base64Decode(publicKeyBase64);
  final keyBytes = <int>[];
  for (int i = 0; i < 32; i++) {
    keyBytes.add(publicKeyBytes[i % publicKeyBytes.length]);
  }
  return keyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
}
```

> **注意:** 这是 MVP 简化版本，正式版将使用 HKDF 派生。

### 平台库加载

| 平台 | 加载方式 |
|------|---------|
| Android | `openCipherOnAndroid` from `sqlcipher_flutter_libs` |
| iOS/macOS | `DynamicLibrary.process()` |

### 数据库文件路径

```
{应用文档目录}/databases/home_pocket.db
```

---

## 7. 4 层加密架构总览

```
┌──────────────────────────────────────────────────────────────┐
│  Layer 4: Transport Encryption (Phase 3)                     │
│  TLS 1.3 + E2EE (P2P Sync)                                 │
│  → lib/infrastructure/sync/                                  │
├──────────────────────────────────────────────────────────────┤
│  Layer 3: File Encryption (Phase 2)                          │
│  AES-256-GCM (照片/附件)                                     │
│  → lib/infrastructure/crypto/services/photo_encryption_...   │
├──────────────────────────────────────────────────────────────┤
│  Layer 2: Field Encryption ✅ 已实现                          │
│  ChaCha20-Poly1305 AEAD (敏感字段)                           │
│  → lib/infrastructure/crypto/services/field_encryption_...   │
├──────────────────────────────────────────────────────────────┤
│  Layer 1: Database Encryption ✅ 已实现                       │
│  SQLCipher AES-256-CBC + PBKDF2 256k (全库加密)              │
│  → lib/infrastructure/crypto/database/encrypted_database.dart│
└──────────────────────────────────────────────────────────────┘
```

**密码算法清单:**

| 用途 | 算法 | 密钥大小 | 实现文件 |
|------|------|---------|---------|
| 数据库加密 | AES-256-CBC (SQLCipher) | 256-bit | `encrypted_database.dart` |
| 字段加密 | ChaCha20-Poly1305 AEAD | 256-bit | `field_encryption_service.dart` |
| 文件加密 | AES-256-GCM (Phase 2) | 256-bit | `photo_encryption_service.dart` |
| 数字签名 | Ed25519 | 256-bit | `key_manager.dart` |
| 哈希 | SHA-256 | 256-bit | `hash_chain_service.dart` |
| 密钥派生 | HKDF-SHA256 | 256-bit | `encryption_repository_impl.dart` |
| KDF (数据库) | PBKDF2-HMAC-SHA512 | 256-bit | `encrypted_database.dart` |

---

## 8. 依赖关系图

### Provider 依赖链

```
FlutterSecureStorage
    │
    ▼
KeyRepositoryImpl (implements KeyRepository)
    │
    ├──▶ KeyManager
    │       │
    │       ▼
    │    createEncryptedExecutor → AppDatabase
    │
    └──▶ EncryptionRepositoryImpl (implements EncryptionRepository)
            │
            ▼
         FieldEncryptionService

HashChainService (无依赖, 无状态)
```

### 初始化顺序

```
1. FlutterSecureStorage    ← 平台提供
2. KeyRepository           ← 依赖 SecureStorage
3. KeyManager              ← 依赖 KeyRepository
4. EncryptedDatabase       ← 依赖 KeyManager (获取加密密钥)
5. FieldEncryptionService  ← 依赖 EncryptionRepository
6. HashChainService        ← 无依赖 (可随时创建)
```

> **关键:** `AppInitializer` 必须在 `runApp()` 之前完成步骤 1-4。

---

## 9. 安全注意事项

### 必须遵守

- **绝不**在日志中输出密钥或明文数据
- **绝不**跳过加密（即使是测试环境也应使用内存数据库 + 加密）
- **绝不**在代码中硬编码密钥或盐值
- **绝不**将私钥传输到网络或其他设备
- **必须**在用户登出时调用 `clearCache()` 清除内存中的加密密钥
- **必须**使用 `Random.secure()` 生成 nonce
- **必须**验证 MAC 标签（ChaCha20-Poly1305 自动完成）

### 密钥存储安全

| 平台 | 存储位置 | 保护等级 |
|------|---------|---------|
| iOS | Keychain | `whenUnlockedThisDeviceOnly` |
| Android | Keystore + EncryptedSharedPreferences | 硬件支持的密钥管理 |

### 密码学包依赖

| 包名 | 用途 |
|------|------|
| `cryptography: ^2.7.0` | Ed25519, ChaCha20-Poly1305, HKDF |
| `crypto: ^3.0.3` | SHA-256 哈希 |
| `flutter_secure_storage: ^9.2.2` | 平台安全存储 |
| `sqlcipher_flutter_libs` | SQLCipher 原生库 |
| `drift: ^2.22.1` | 类型安全 SQL 查询 |

---

## 10. 参考文档

| 文档 | 编号 | 说明 |
|------|------|------|
| 安全架构 | [ARCH-003](../arch/01-core-architecture/ARCH-003_Security_Architecture.md) | 4 层加密架构顶层设计 |
| 多层加密决策 | [ADR-003](../arch/03-adr/ADR-003_Multi_Layer_Encryption.md) | ChaCha20-Poly1305 选型依据 |
| 密钥派生决策 | [ADR-006](../arch/03-adr/ADR-006_Key_Derivation_Security.md) | HKDF 方案与缓存策略 |
| 增量验证决策 | [ADR-009](../arch/03-adr/ADR-009_Incremental_Hash_Chain_Verification.md) | 哈希链增量验证设计 |
| 安全模块规格 | [MOD-005](../arch/02-module-specs/MOD-005_Security.md) | 安全模块业务需求与 UI 设计 |
| 安全基础设施 | [BASIC-002](./BASIC-002_Security_Infrastructure.md) | 安全平台服务（生物识别、PIN、审计） |

---

**文档状态:** 完成
**审核状态:** 待审核
**变更日志:**
- 2026-02-06: v1.0 创建完整加密基础设施技术文档
