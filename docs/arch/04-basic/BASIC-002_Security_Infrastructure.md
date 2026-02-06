# BASIC-002: 安全基础设施 (Security Infrastructure)

**文档编号:** BASIC-002
**文档版本:** 1.0
**创建日期:** 2026-02-06
**最后更新:** 2026-02-06
**状态:** 待实施
**作者:** Claude Opus 4.6

---

## 1. 概述

本文档是 `lib/infrastructure/security/` 三个安全平台服务的**技术设计文档**，面向开发者提供完整的 API 设计、实现规范和集成指南。

### 目标服务

| 服务 | 文件 | 职责 |
|------|------|------|
| **BiometricService** | `biometric_service.dart` | Face ID / Touch ID / 指纹认证封装 |
| **SecureStorageService** | `secure_storage_service.dart` | iOS Keychain / Android Keystore 统一封装 |
| **AuditLogger** | `audit_logger.dart` | 安全事件审计日志记录与查询 |

### Crypto vs Security 的区别

| 领域 | Crypto (BASIC-001) | Security (本文档) |
|------|-------------------|------------------|
| 关注点 | 密码学原语（加密/解密/签名/哈希） | 平台安全 API 封装（认证/存储/审计） |
| 技术栈 | `cryptography`, `crypto`, SQLCipher | `local_auth`, `flutter_secure_storage`, Drift |
| 位置 | `lib/infrastructure/crypto/` | `lib/infrastructure/security/` |
| 用户交互 | 无（后台运行） | 有（生物识别弹窗、审计报告） |

### 文档定位

| 文档 | 定位 |
|------|------|
| **本文档 (BASIC-002)** | Security Infrastructure 层 API 设计与实现规范 |
| [BASIC-001](./BASIC-001_Crypto_Infrastructure.md) | Crypto Infrastructure 层实现参考 |
| [ARCH-003](../01-core-architecture/ARCH-003_Security_Architecture.md) | 安全架构顶层设计（威胁模型、原则） |
| [MOD-005](../02-module-specs/MOD-005_Security.md) (MOD-006) | 安全模块业务需求、UI、用户流程 |

### 设计来源

本文档的设计基于以下已有实现和架构文档：

- **BiometricService**: 重构自 `lib/features/security/application/services/biometric_lock.dart`
- **SecureStorageService**: 从 `KeyRepositoryImpl` 和 `PINManager` 中提取公共安全存储逻辑
- **AuditLogger**: 基于 ARCH-003 第 1695-1735 行的设计规范新建

---

## 2. 目录结构

```
lib/infrastructure/security/
├── biometric_service.dart         # 生物识别认证服务
├── secure_storage_service.dart    # 安全存储服务
└── audit_logger.dart              # 审计日志服务
```

### 与现有代码的关系

```
现有 (Feature 层, 待迁移)              → 目标 (Infrastructure 层)
─────────────────────────────────────────────────────────────────
features/security/application/          infrastructure/security/
  services/biometric_lock.dart     →     biometric_service.dart
  services/pin_manager.dart        →     (使用 SecureStorageService)
  services/recovery_kit_service.dart →   (使用 SecureStorageService)
                                   →     secure_storage_service.dart (新建)
                                   →     audit_logger.dart (新建)
```

---

## 3. 核心组件详解

### 3.1 BiometricService（生物识别服务）

**文件:** `lib/infrastructure/security/biometric_service.dart`

**职责:**
- Face ID / Touch ID / 指纹认证的平台 API 封装
- 生物识别可用性检查
- 认证执行与结果封装
- 失败计数与本地锁定策略
- 多语言认证消息

**技术栈:** `local_auth` + `local_auth_android` + `local_auth_darwin`

#### 枚举定义

```dart
/// 生物识别可用性状态
enum BiometricAvailability {
  /// Face ID 可用 (iOS)
  faceId,
  /// 指纹识别可用
  fingerprint,
  /// 通用生物识别可用
  generic,
  /// 设备支持但未注册生物信息
  notEnrolled,
  /// 设备硬件不支持
  notSupported,
}
```

#### 类设计

```dart
class BiometricService {
  BiometricService({
    LocalAuthentication? localAuth,
  }) : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;
  int _failedAttempts = 0;

  /// 最大允许连续失败次数
  static const int maxFailedAttempts = 3;
}
```

> **与 BiometricLock 的区别:** 重命名为 `BiometricService` 以符合 Infrastructure 层命名规范（Service 后缀），
> 并通过构造函数注入 `LocalAuthentication` 便于测试。

#### 核心方法

##### checkAvailability

```dart
/// 检查当前设备的生物识别可用性
///
/// 返回具体的可用性状态，用于 UI 展示和认证策略判断。
/// - [faceId]: 设备支持并已注册 Face ID
/// - [fingerprint]: 设备支持并已注册指纹
/// - [generic]: 设备支持并已注册某种生物识别（无法确定具体类型）
/// - [notEnrolled]: 设备支持但用户未注册
/// - [notSupported]: 设备硬件不支持
Future<BiometricAvailability> checkAvailability() async {
  final canCheck = await _localAuth.canCheckBiometrics;
  final isSupported = await _localAuth.isDeviceSupported();

  if (!canCheck && !isSupported) {
    return BiometricAvailability.notSupported;
  }

  final availableBiometrics = await _localAuth.getAvailableBiometrics();

  if (availableBiometrics.isEmpty) {
    return BiometricAvailability.notEnrolled;
  }

  if (availableBiometrics.contains(BiometricType.face)) {
    return BiometricAvailability.faceId;
  }
  if (availableBiometrics.contains(BiometricType.fingerprint)) {
    return BiometricAvailability.fingerprint;
  }
  return BiometricAvailability.generic;
}
```

##### authenticate

```dart
/// 执行生物识别认证
///
/// [reason]: 认证原因（多语言），显示在系统认证弹窗中
/// [biometricOnly]: 是否仅允许生物识别（不允许设备 PIN 降级）
///
/// 返回 [AuthResult] 联合类型，调用方通过 `when` 穷举处理所有情况。
///
/// 失败策略:
/// - 连续失败 < 3 次: 返回 [AuthResult.failed]
/// - 连续失败 >= 3 次: 返回 [AuthResult.tooManyAttempts]
/// - 成功后自动重置失败计数
Future<AuthResult> authenticate({
  required String reason,
  bool biometricOnly = false,
}) async {
  // 1. 检查可用性
  final availability = await checkAvailability();
  if (availability == BiometricAvailability.notSupported ||
      availability == BiometricAvailability.notEnrolled) {
    return const AuthResult.fallbackToPIN();
  }

  // 2. 检查本地失败次数
  if (_failedAttempts >= maxFailedAttempts) {
    return const AuthResult.tooManyAttempts();
  }

  // 3. 执行认证
  try {
    final authenticated = await _localAuth.authenticate(
      localizedReason: reason,
      options: AuthenticationOptions(
        stickyAuth: true,
        biometricOnly: biometricOnly,
        sensitiveTransaction: true,
      ),
      authMessages: const [
        AndroidAuthMessages(
          signInTitle: '生体認証',
          cancelButton: 'キャンセル',
          biometricHint: '指紋を確認してください',
        ),
        IOSAuthMessages(
          cancelButton: 'キャンセル',
          goToSettingsButton: '設定へ',
          goToSettingsDescription: '生体認証を設定してください',
        ),
      ],
    );

    if (authenticated) {
      _failedAttempts = 0;
      return const AuthResult.success();
    } else {
      _failedAttempts++;
      return AuthResult.failed(failedAttempts: _failedAttempts);
    }
  } on PlatformException catch (e) {
    return _handlePlatformException(e);
  }
}
```

##### resetFailedAttempts

```dart
/// 手动重置失败计数器
///
/// 通常在 PIN 认证成功后调用，允许用户重新尝试生物识别。
void resetFailedAttempts() {
  _failedAttempts = 0;
}
```

#### PlatformException 处理

```dart
AuthResult _handlePlatformException(PlatformException e) {
  switch (e.code) {
    case auth_error.lockedOut:
    case auth_error.permanentlyLockedOut:
      return const AuthResult.lockedOut();
    case auth_error.notAvailable:
    case auth_error.notEnrolled:
      return const AuthResult.fallbackToPIN();
    default:
      return AuthResult.error(message: e.message ?? 'Unknown biometric error');
  }
}
```

#### 认证流程图

```
用户触发认证
    │
    ▼
checkAvailability()
    │
    ├── notSupported ──→ AuthResult.fallbackToPIN()
    ├── notEnrolled  ──→ AuthResult.fallbackToPIN()
    │
    ▼ (faceId / fingerprint / generic)
failedAttempts >= 3?
    │
    ├── YES ──→ AuthResult.tooManyAttempts()
    │
    ▼ NO
_localAuth.authenticate()
    │
    ├── true  ──→ resetFailedAttempts() → AuthResult.success()
    │
    ├── false ──→ failedAttempts++ → AuthResult.failed(N)
    │
    └── PlatformException
        ├── lockedOut         → AuthResult.lockedOut()
        ├── notAvailable      → AuthResult.fallbackToPIN()
        └── other             → AuthResult.error(message)
```

#### Provider 定义

```dart
@riverpod
BiometricService biometricService(BiometricServiceRef ref) {
  return BiometricService();
}

@riverpod
Future<BiometricAvailability> biometricAvailability(
  BiometricAvailabilityRef ref,
) async {
  final service = ref.watch(biometricServiceProvider);
  return service.checkAvailability();
}
```

#### 使用示例

```dart
final biometric = ref.read(biometricServiceProvider);

// 检查可用性
final availability = await biometric.checkAvailability();
if (availability == BiometricAvailability.faceId) {
  showText('Face ID で認証します');
}

// 执行认证
final result = await biometric.authenticate(
  reason: '取引を確認するために認証してください',
);

result.when(
  success: () => proceedWithTransaction(),
  failed: (attempts) => showRetryDialog(remaining: 3 - attempts),
  fallbackToPIN: () => navigateToPINScreen(),
  tooManyAttempts: () => forcePINAuthentication(),
  lockedOut: () => showDeviceLockedMessage(),
  error: (message) => showErrorSnackbar(message),
);
```

#### 平台差异

| 特性 | iOS | Android |
|------|-----|---------|
| Face ID | `BiometricType.face` | N/A |
| 指纹 | `BiometricType.fingerprint` | `BiometricType.fingerprint` |
| 虹膜 | N/A | `BiometricType.iris`（少数设备） |
| 认证弹窗 | 系统级（不可自定义） | 可自定义样式 |
| 本地化 | `IOSAuthMessages` | `AndroidAuthMessages` |
| 锁定策略 | 5 次失败后 30s 冷却 | 设备策略决定 |

---

### 3.2 SecureStorageService（安全存储服务）

**文件:** `lib/infrastructure/security/secure_storage_service.dart`

**职责:**
- iOS Keychain / Android Keystore 的统一抽象
- 平台特定安全选项的集中管理
- 类型化的密钥读写操作
- 存储键常量集中管理

**技术栈:** `flutter_secure_storage`

#### 设计动机

当前 `KeyRepositoryImpl`、`PINManager`、`RecoveryKitService` 各自直接使用 `FlutterSecureStorage`，
存在以下问题：

1. **平台选项重复配置**: 每个使用方都需要单独设置 iOS/Android 选项
2. **存储键分散定义**: `'device_private_key'`、`'pin_hash'` 等键散落在多个文件中
3. **无统一的错误处理**: 平台异常各自处理，行为不一致
4. **难以测试**: 直接依赖 `FlutterSecureStorage`，Mock 困难

`SecureStorageService` 解决以上问题，提供单一入口。

#### 存储键常量

```dart
/// 安全存储键常量
///
/// 所有安全存储的键必须在此集中定义，
/// 禁止在其他文件中使用硬编码字符串。
abstract final class StorageKeys {
  /// Ed25519 私钥 (Base64)
  static const String devicePrivateKey = 'device_private_key';

  /// Ed25519 公钥 (Base64)
  static const String devicePublicKey = 'device_public_key';

  /// 设备 ID (SHA-256 前 16 字符)
  static const String deviceId = 'device_id';

  /// PIN 的 SHA-256 哈希
  static const String pinHash = 'pin_hash';

  /// 恢复助记词的 SHA-256 哈希
  static const String recoveryKitHash = 'recovery_kit_hash';

  /// 主加密密钥（预留，Phase 2）
  static const String masterKey = 'master_key';

  /// 所有已知的存储键列表（用于 clearAll）
  static const List<String> allKeys = [
    devicePrivateKey,
    devicePublicKey,
    deviceId,
    pinHash,
    recoveryKitHash,
    masterKey,
  ];
}
```

#### 类设计

```dart
class SecureStorageService {
  SecureStorageService({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// iOS Keychain 安全选项
  ///
  /// - whenUnlockedThisDeviceOnly: 仅设备解锁时可访问，不同步到 iCloud
  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.unlocked_this_device,
  );

  /// Android Keystore 安全选项
  ///
  /// - encryptedSharedPreferences: 使用 Android Keystore 支持的加密
  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );
}
```

#### 核心方法

##### write

```dart
/// 向安全存储写入键值对
///
/// [key]: 存储键（推荐使用 [StorageKeys] 常量）
/// [value]: 要存储的值
///
/// 如果键已存在，则覆盖旧值。
/// 自动应用平台特定的安全选项。
Future<void> write({
  required String key,
  required String value,
}) async {
  await _storage.write(
    key: key,
    value: value,
    iOptions: _iosOptions,
    aOptions: _androidOptions,
  );
}
```

##### read

```dart
/// 从安全存储读取值
///
/// [key]: 存储键
/// 返回存储的值，如果不存在则返回 null。
Future<String?> read({required String key}) async {
  return await _storage.read(
    key: key,
    iOptions: _iosOptions,
    aOptions: _androidOptions,
  );
}
```

##### delete

```dart
/// 删除指定键
///
/// [key]: 要删除的存储键
/// 如果键不存在，静默忽略。
Future<void> delete({required String key}) async {
  await _storage.delete(
    key: key,
    iOptions: _iosOptions,
    aOptions: _androidOptions,
  );
}
```

##### containsKey

```dart
/// 检查存储中是否存在指定键
///
/// [key]: 要检查的存储键
/// 返回 true 如果键存在且值非 null。
Future<bool> containsKey({required String key}) async {
  return await _storage.containsKey(
    key: key,
    iOptions: _iosOptions,
    aOptions: _androidOptions,
  );
}
```

##### clearAll

```dart
/// 清除所有应用存储的安全数据
///
/// ⚠️ 危险操作: 将删除所有密钥、PIN、恢复哈希。
/// 仅在用户明确要求「重置应用」时调用。
///
/// 不使用 `_storage.deleteAll()` 以避免删除其他 SDK 写入的键，
/// 仅删除 [StorageKeys.allKeys] 中定义的键。
Future<void> clearAll() async {
  for (final key in StorageKeys.allKeys) {
    await delete(key: key);
  }
}
```

#### 便捷方法（类型化访问）

```dart
/// 读取设备私钥
Future<String?> getDevicePrivateKey() async {
  return read(key: StorageKeys.devicePrivateKey);
}

/// 写入设备私钥
Future<void> setDevicePrivateKey(String value) async {
  await write(key: StorageKeys.devicePrivateKey, value: value);
}

/// 读取设备公钥
Future<String?> getDevicePublicKey() async {
  return read(key: StorageKeys.devicePublicKey);
}

/// 写入设备公钥
Future<void> setDevicePublicKey(String value) async {
  await write(key: StorageKeys.devicePublicKey, value: value);
}

/// 读取设备 ID
Future<String?> getDeviceId() async {
  return read(key: StorageKeys.deviceId);
}

/// 写入设备 ID
Future<void> setDeviceId(String value) async {
  await write(key: StorageKeys.deviceId, value: value);
}

/// 读取 PIN 哈希
Future<String?> getPinHash() async {
  return read(key: StorageKeys.pinHash);
}

/// 写入 PIN 哈希
Future<void> setPinHash(String value) async {
  await write(key: StorageKeys.pinHash, value: value);
}

/// 删除 PIN 哈希
Future<void> deletePinHash() async {
  await delete(key: StorageKeys.pinHash);
}

/// 读取恢复套件哈希
Future<String?> getRecoveryKitHash() async {
  return read(key: StorageKeys.recoveryKitHash);
}

/// 写入恢复套件哈希
Future<void> setRecoveryKitHash(String value) async {
  await write(key: StorageKeys.recoveryKitHash, value: value);
}
```

#### Provider 定义

```dart
@riverpod
SecureStorageService secureStorageService(SecureStorageServiceRef ref) {
  return SecureStorageService();
}
```

#### 使用示例

```dart
final storage = ref.read(secureStorageServiceProvider);

// 写入
await storage.write(
  key: StorageKeys.devicePrivateKey,
  value: base64Encode(privateKeyBytes),
);

// 读取
final publicKey = await storage.getDevicePublicKey();

// 检查存在性
final hasPIN = await storage.containsKey(key: StorageKeys.pinHash);

// 类型化便捷方法
await storage.setPinHash(sha256Hash);
final hash = await storage.getPinHash();

// 清除所有（危险！仅用于应用重置）
await storage.clearAll();
```

#### 平台安全配置对比

| 特性 | iOS (Keychain) | Android (Keystore) |
|------|---------------|-------------------|
| 存储后端 | Secure Enclave (SEP) | TEE / StrongBox |
| 访问控制 | `whenUnlockedThisDeviceOnly` | `encryptedSharedPreferences` |
| iCloud 同步 | 禁用 (`thisDeviceOnly`) | N/A |
| 备份包含 | 排除 | 排除 |
| 生物识别绑定 | 可通过 `accessControl` 配置 | 可通过 `authenticationRequired` 配置 |
| 设备迁移 | 不迁移 | 不迁移 |

#### 迁移影响

引入 `SecureStorageService` 后，以下服务需要重构依赖：

| 服务 | 当前依赖 | 迁移后依赖 |
|------|---------|-----------|
| `KeyRepositoryImpl` | `FlutterSecureStorage` 直接使用 | `SecureStorageService` |
| `PINManager` | `FlutterSecureStorage` 直接使用 | `SecureStorageService` |
| `RecoveryKitService` | `FlutterSecureStorage` 直接使用 | `SecureStorageService` |

重构后的构造函数示例：

```dart
// Before
class KeyRepositoryImpl implements KeyRepository {
  KeyRepositoryImpl({required FlutterSecureStorage secureStorage});
}

// After
class KeyRepositoryImpl implements KeyRepository {
  KeyRepositoryImpl({required SecureStorageService storageService});
}
```

---

### 3.3 AuditLogger（审计日志服务）

**文件:** `lib/infrastructure/security/audit_logger.dart`

**职责:**
- 安全事件的结构化记录
- 审计日志查询与过滤
- 日志导出（CSV 格式）
- 敏感信息过滤（绝不记录密钥/明文）

**技术栈:** Drift (数据库) + `ulid` (唯一 ID)

#### 事件类型枚举

```dart
/// 审计事件类型
///
/// 覆盖应用中所有需要审计跟踪的安全相关事件。
/// 新增事件类型时须同步更新本枚举。
enum AuditEvent {
  // ── 应用生命周期 ──
  /// 应用启动
  appLaunched,
  /// 数据库解锁成功
  databaseOpened,

  // ── 认证事件 ──
  /// 生物识别认证成功
  biometricAuthSuccess,
  /// 生物识别认证失败
  biometricAuthFailed,
  /// PIN 认证成功
  pinAuthSuccess,
  /// PIN 认证失败
  pinAuthFailed,

  // ── 完整性事件 ──
  /// 哈希链验证通过
  chainVerified,
  /// 哈希链检测到篡改
  tamperDetected,

  // ── 密钥管理事件 ──
  /// 密钥对生成
  keyGenerated,
  /// 密钥轮换
  keyRotated,
  /// 恢复套件生成
  recoveryKitGenerated,
  /// 密钥恢复成功
  keyRecovered,

  // ── 同步事件 (Phase 3) ──
  /// 同步开始
  syncStarted,
  /// 同步完成
  syncCompleted,
  /// 同步失败
  syncFailed,
  /// 设备配对
  devicePaired,
  /// 设备解除配对
  deviceUnpaired,

  // ── 数据管理事件 ──
  /// 备份导出
  backupExported,
  /// 备份导入
  backupImported,
  /// 安全设置变更
  securitySettingsChanged,
}
```

#### 审计日志条目模型

```dart
/// 审计日志条目
///
/// 对应数据库表 `audit_logs`。
@freezed
class AuditLogEntry with _$AuditLogEntry {
  const factory AuditLogEntry({
    /// 唯一标识 (ULID 格式，可按时间排序)
    required String id,

    /// 事件类型
    required AuditEvent event,

    /// 产生事件的设备 ID
    required String deviceId,

    /// 关联的账本 ID（可选）
    String? bookId,

    /// 关联的交易 ID（可选）
    String? transactionId,

    /// 附加详情 (JSON 格式，禁止包含敏感数据)
    String? details,

    /// 事件时间戳
    required DateTime timestamp,
  }) = _AuditLogEntry;
}
```

#### 数据库表定义

```dart
/// 审计日志表
///
/// 位置: lib/data/tables/audit_logs_table.dart
class AuditLogs extends Table {
  TextColumn get id => text()();
  TextColumn get event => text()();           // AuditEvent.name
  TextColumn get deviceId => text()();
  TextColumn get bookId => text().nullable()();
  TextColumn get transactionId => text().nullable()();
  TextColumn get details => text().nullable()();  // JSON string
  DateTimeColumn get timestamp => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  List<TableIndex> get customIndices => [
    TableIndex(
      name: 'idx_audit_logs_event',
      columns: {#event},
    ),
    TableIndex(
      name: 'idx_audit_logs_timestamp',
      columns: {#timestamp},
    ),
    TableIndex(
      name: 'idx_audit_logs_book_id',
      columns: {#bookId},
    ),
  ];
}
```

#### 类设计

```dart
class AuditLogger {
  AuditLogger({
    required AppDatabase database,
    required SecureStorageService storageService,
  })  : _database = database,
       _storageService = storageService;

  final AppDatabase _database;
  final SecureStorageService _storageService;
}
```

#### 核心方法

##### log

```dart
/// 记录一条审计日志
///
/// [event]: 事件类型
/// [bookId]: 关联账本 ID（可选）
/// [transactionId]: 关联交易 ID（可选）
/// [details]: 附加详情，JSON 格式（可选）
///
/// 自动填充:
/// - id: ULID（时间排序的唯一标识）
/// - deviceId: 从 SecureStorageService 获取
/// - timestamp: 当前时间
///
/// ⚠️ 安全规则: [details] 中禁止包含以下信息:
/// - 加密密钥或密钥材料
/// - 明文金额或交易备注
/// - PIN 码或其哈希
/// - 助记词或其哈希
Future<void> log({
  required AuditEvent event,
  String? bookId,
  String? transactionId,
  String? details,
}) async {
  final deviceId = await _storageService.getDeviceId() ?? 'unknown';

  final entry = AuditLogEntry(
    id: Ulid().toString(),
    event: event,
    deviceId: deviceId,
    bookId: bookId,
    transactionId: transactionId,
    details: details,
    timestamp: DateTime.now(),
  );

  await _database.into(_database.auditLogs).insert(
    AuditLogsCompanion.insert(
      id: entry.id,
      event: entry.event.name,
      deviceId: entry.deviceId,
      bookId: Value(entry.bookId),
      transactionId: Value(entry.transactionId),
      details: Value(entry.details),
      timestamp: entry.timestamp,
    ),
  );
}
```

##### getLogs

```dart
/// 查询审计日志
///
/// 所有参数均可选，多条件取交集（AND）。
/// 结果按时间倒序排列（最新的在前）。
///
/// [bookId]: 按账本过滤
/// [eventType]: 按事件类型过滤
/// [startDate]: 起始时间（包含）
/// [endDate]: 结束时间（包含）
/// [limit]: 最大返回条数（默认 100）
/// [offset]: 分页偏移量
Future<List<AuditLogEntry>> getLogs({
  String? bookId,
  AuditEvent? eventType,
  DateTime? startDate,
  DateTime? endDate,
  int limit = 100,
  int offset = 0,
}) async {
  final query = _database.select(_database.auditLogs)
    ..orderBy([
      (t) => OrderingTerm.desc(t.timestamp),
    ])
    ..limit(limit, offset: offset);

  if (bookId != null) {
    query.where((t) => t.bookId.equals(bookId));
  }
  if (eventType != null) {
    query.where((t) => t.event.equals(eventType.name));
  }
  if (startDate != null) {
    query.where((t) => t.timestamp.isBiggerOrEqualValue(startDate));
  }
  if (endDate != null) {
    query.where((t) => t.timestamp.isSmallerOrEqualValue(endDate));
  }

  final rows = await query.get();
  return rows.map(_rowToEntry).toList();
}
```

##### getLogCount

```dart
/// 获取符合条件的日志总数
///
/// 参数含义与 [getLogs] 相同。
/// 用于分页 UI 显示总数。
Future<int> getLogCount({
  String? bookId,
  AuditEvent? eventType,
  DateTime? startDate,
  DateTime? endDate,
}) async {
  final countExp = _database.auditLogs.id.count();
  final query = _database.selectOnly(_database.auditLogs)
    ..addColumns([countExp]);

  if (bookId != null) {
    query.where(_database.auditLogs.bookId.equals(bookId));
  }
  if (eventType != null) {
    query.where(_database.auditLogs.event.equals(eventType.name));
  }
  if (startDate != null) {
    query.where(
      _database.auditLogs.timestamp.isBiggerOrEqualValue(startDate),
    );
  }
  if (endDate != null) {
    query.where(
      _database.auditLogs.timestamp.isSmallerOrEqualValue(endDate),
    );
  }

  final result = await query.getSingle();
  return result.read(countExp) ?? 0;
}
```

##### exportToCSV

```dart
/// 导出审计日志为 CSV 文件
///
/// [filePath]: 输出文件路径
/// [bookId]: 可选，仅导出指定账本的日志
///
/// CSV 列: id, event, deviceId, bookId, transactionId, details, timestamp
///
/// ⚠️ 导出的 CSV 不包含加密，仅用于本地审计查看。
/// 不应通过网络传输。
Future<void> exportToCSV({
  required String filePath,
  String? bookId,
}) async {
  final logs = await getLogs(
    bookId: bookId,
    limit: 999999,  // 导出全部
  );

  final buffer = StringBuffer();
  buffer.writeln('id,event,deviceId,bookId,transactionId,details,timestamp');

  for (final log in logs) {
    buffer.writeln([
      log.id,
      log.event.name,
      log.deviceId,
      log.bookId ?? '',
      log.transactionId ?? '',
      _escapeCSV(log.details ?? ''),
      log.timestamp.toIso8601String(),
    ].join(','));
  }

  final file = File(filePath);
  await file.writeAsString(buffer.toString());
}
```

#### 行转换辅助方法

```dart
AuditLogEntry _rowToEntry(AuditLog row) {
  return AuditLogEntry(
    id: row.id,
    event: AuditEvent.values.firstWhere(
      (e) => e.name == row.event,
      orElse: () => AuditEvent.appLaunched,  // fallback
    ),
    deviceId: row.deviceId,
    bookId: row.bookId,
    transactionId: row.transactionId,
    details: row.details,
    timestamp: row.timestamp,
  );
}

String _escapeCSV(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
```

#### Provider 定义

```dart
@riverpod
AuditLogger auditLogger(AuditLoggerRef ref) {
  final database = ref.watch(appDatabaseProvider);
  final storageService = ref.watch(secureStorageServiceProvider);
  return AuditLogger(
    database: database,
    storageService: storageService,
  );
}
```

#### 使用示例

```dart
final logger = ref.read(auditLoggerProvider);

// 记录认证成功
await logger.log(event: AuditEvent.biometricAuthSuccess);

// 记录哈希链篡改检测
await logger.log(
  event: AuditEvent.tamperDetected,
  bookId: 'book_001',
  details: '{"tamperedIds": ["tx_42", "tx_43"]}',
);

// 记录密钥生成
await logger.log(
  event: AuditEvent.keyGenerated,
  details: '{"algorithm": "Ed25519"}',  // 不记录密钥内容!
);

// 查询最近的认证事件
final authLogs = await logger.getLogs(
  eventType: AuditEvent.biometricAuthFailed,
  startDate: DateTime.now().subtract(const Duration(days: 7)),
  limit: 50,
);

// 导出审计报告
await logger.exportToCSV(
  filePath: '${appDocDir.path}/audit_report.csv',
  bookId: 'book_001',
);
```

#### 安全规则

**details 字段允许记录的信息:**

| 允许 | 示例 |
|------|------|
| 算法名称 | `{"algorithm": "Ed25519"}` |
| 篡改的交易 ID | `{"tamperedIds": ["tx_42"]}` |
| 验证的交易数量 | `{"totalVerified": 500}` |
| 同步的设备数 | `{"deviceCount": 2}` |
| 错误类型 | `{"error": "timeout"}` |

**details 字段禁止记录的信息:**

| 禁止 | 原因 |
|------|------|
| 加密密钥 / 密钥材料 | 密钥泄露风险 |
| 明文金额 / 交易备注 | 隐私数据 |
| PIN 码 / PIN 哈希 | 认证凭据 |
| 助记词 / 助记词哈希 | 恢复凭据 |
| 用户个人信息 | 隐私保护 |

---

## 4. 依赖关系图

### Provider 依赖链

```
FlutterSecureStorage (平台提供)
    │
    ▼
SecureStorageService ─────────────────────────────┐
    │                                              │
    ├──▶ KeyRepositoryImpl (使用存储读写密钥)       │
    │       │                                      │
    │       ▼                                      │
    │    KeyManager                                 │
    │                                              │
    ├──▶ PINManager (使用存储读写 PIN 哈希)         │
    │                                              │
    ├──▶ RecoveryKitService (使用存储读写恢复哈希)  │
    │                                              │
    └──▶ AuditLogger (读取 deviceId) ◄─────────────┘
            │
            ▼
         AppDatabase (写入 audit_logs 表)

LocalAuthentication (平台提供)
    │
    ▼
BiometricService (独立，无 storage 依赖)
```

### 初始化顺序

```
1. SecureStorageService    ← 无依赖，最先创建
2. BiometricService        ← 无依赖，可与 1 并行
3. KeyRepository           ← 依赖 SecureStorageService
4. KeyManager              ← 依赖 KeyRepository
5. AppDatabase             ← 依赖 KeyManager (获取加密密钥)
6. AuditLogger             ← 依赖 AppDatabase + SecureStorageService
```

---

## 5. 测试策略

### 5.1 BiometricService 测试

```dart
// Mock LocalAuthentication
class MockLocalAuth extends Mock implements LocalAuthentication {}

test('authenticate returns success when biometric passes', () async {
  final mockAuth = MockLocalAuth();
  when(mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
  when(mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
  when(mockAuth.getAvailableBiometrics())
      .thenAnswer((_) async => [BiometricType.fingerprint]);
  when(mockAuth.authenticate(
    localizedReason: any(named: 'localizedReason'),
    options: any(named: 'options'),
    authMessages: any(named: 'authMessages'),
  )).thenAnswer((_) async => true);

  final service = BiometricService(localAuth: mockAuth);
  final result = await service.authenticate(reason: 'test');

  expect(result, const AuthResult.success());
});

test('authenticate returns tooManyAttempts after 3 failures', () async {
  // ... 模拟 3 次失败 ...
  expect(result, const AuthResult.tooManyAttempts());
});
```

### 5.2 SecureStorageService 测试

```dart
// Mock FlutterSecureStorage
class MockSecureStorage extends Mock implements FlutterSecureStorage {}

test('write and read round-trip', () async {
  final mockStorage = MockSecureStorage();
  when(mockStorage.write(
    key: 'test_key',
    value: 'test_value',
    iOptions: any(named: 'iOptions'),
    aOptions: any(named: 'aOptions'),
  )).thenAnswer((_) async {});
  when(mockStorage.read(
    key: 'test_key',
    iOptions: any(named: 'iOptions'),
    aOptions: any(named: 'aOptions'),
  )).thenAnswer((_) async => 'test_value');

  final service = SecureStorageService(storage: mockStorage);
  await service.write(key: 'test_key', value: 'test_value');
  final result = await service.read(key: 'test_key');

  expect(result, 'test_value');
});

test('clearAll deletes only known keys', () async {
  // ... 验证仅删除 StorageKeys.allKeys 中的键 ...
});
```

### 5.3 AuditLogger 测试

```dart
test('log creates entry with correct fields', () async {
  // 使用内存数据库
  final db = AppDatabase.forTesting();
  final mockStorage = MockSecureStorageService();
  when(mockStorage.getDeviceId()).thenAnswer((_) async => 'test_device_id');

  final logger = AuditLogger(database: db, storageService: mockStorage);

  await logger.log(
    event: AuditEvent.biometricAuthSuccess,
    bookId: 'book_001',
  );

  final logs = await logger.getLogs();
  expect(logs.length, 1);
  expect(logs.first.event, AuditEvent.biometricAuthSuccess);
  expect(logs.first.deviceId, 'test_device_id');
  expect(logs.first.bookId, 'book_001');
});

test('getLogs filters by event type and date range', () async {
  // ... 插入多条不同类型的日志，验证过滤 ...
});

test('exportToCSV generates valid format', () async {
  // ... 写入日志，导出 CSV，验证格式 ...
});
```

---

## 6. 安全注意事项

### 生物识别

- **绝不**缓存认证结果（每次操作重新认证）
- **绝不**在日志中记录认证的具体生物特征数据
- **必须**处理所有 `PlatformException` 分支
- **必须**在失败 3 次后强制切换到 PIN 认证

### 安全存储

- **绝不**使用 `_storage.deleteAll()`（可能删除其他 SDK 的数据）
- **绝不**在存储键中包含用户可见信息
- **必须**使用 `StorageKeys` 常量，禁止硬编码字符串
- **必须**配置平台特定安全选项（iOS: `thisDeviceOnly`, Android: `encrypted`）

### 审计日志

- **绝不**在 `details` 中记录密钥、明文金额、PIN、助记词
- **绝不**通过网络传输未加密的审计日志
- **必须**使用 ULID 确保日志按时间可排序
- **必须**自动填充 `deviceId` 和 `timestamp`

---

## 7. 参考文档

| 文档 | 编号 | 说明 |
|------|------|------|
| 加密基础设施 | [BASIC-001](./BASIC-001_Crypto_Infrastructure.md) | Crypto Infrastructure 层实现参考 |
| 安全架构 | [ARCH-003](../01-core-architecture/ARCH-003_Security_Architecture.md) | 安全架构顶层设计 |
| 安全模块规格 | [MOD-005](../02-module-specs/MOD-005_Security.md) (MOD-006) | 安全模块业务需求与 UI |
| 多层加密决策 | [ADR-003](../03-adr/ADR-003_Multi_Layer_Encryption.md) | 加密方案决策 |
| 密钥派生决策 | [ADR-006](../03-adr/ADR-006_Key_Derivation_Security.md) | HKDF 方案设计 |

---

**文档状态:** 完成
**审核状态:** 待审核
**变更日志:**
- 2026-02-06: v1.0 创建安全基础设施技术设计文档（BiometricService、SecureStorageService、AuditLogger）
