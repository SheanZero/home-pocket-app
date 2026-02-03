# Home Pocket MVP - 安全架构设计

**文档版本:** 1.0
**创建日期:** 2026-02-03
**状态:** 完成
**作者:** Claude Sonnet 4.5 + senior-architect

---

## 📋 目录

1. [概述](#概述)
2. [威胁模型](#威胁模型)
3. [密钥管理](#密钥管理)
4. [多层加密](#多层加密)
5. [哈希链完整性](#哈希链完整性)
6. [生物识别认证](#生物识别认证)
7. [设备间同步安全](#设备间同步安全)
8. [Recovery Kit恢复机制](#recovery-kit恢复机制)
9. [隐私保护](#隐私保护)
10. [安全审计](#安全审计)

---

## 概述

### 安全目标

Home Pocket的安全架构遵循以下目标：

| 目标 | 说明 | 实现方式 |
|------|------|---------|
| **机密性（Confidentiality）** | 数据仅所有者可访问 | 端到端加密（E2EE） |
| **完整性（Integrity）** | 数据不可篡改 | 哈希链 + 数字签名 |
| **可用性（Availability）** | 数据始终可访问 | 本地优先 + Recovery Kit |
| **零知识（Zero Knowledge）** | 无第三方能解密数据 | 本地加密，密钥不离设备 |
| **防抵赖（Non-Repudiation）** | 交易可追溯到创建者 | Ed25519数字签名 |

### 安全原则

1. **Defense in Depth（纵深防御）**
   - 多层加密（数据库、字段、文件、传输）
   - 不依赖单一防护机制

2. **Least Privilege（最小权限）**
   - 每个模块仅访问必需的密钥
   - 细粒度权限控制

3. **Secure by Default（默认安全）**
   - 所有数据默认加密
   - 安全配置开箱即用

4. **Privacy by Design（隐私设计）**
   - 数据最小化收集
   - 用户完全控制数据

### 技术栈

| 组件 | 技术 | 用途 |
|------|------|------|
| 对称加密 | AES-256-CBC, ChaCha20-Poly1305 | 数据加密 |
| 非对称加密 | Ed25519 | 密钥交换、签名 |
| 哈希算法 | SHA-256 | 哈希链、完整性 |
| 密钥派生 | HKDF (HMAC-SHA256) | 派生专用密钥 |
| 随机数 | Platform Secure Random | Nonce生成 |
| 密钥存储 | iOS Keychain / Android KeyStore | 主密钥存储 |
| 生物识别 | local_auth + platform APIs | 身份验证 |

---

## 威胁模型

### 威胁场景

#### 1. 设备丢失/被盗

**威胁**: 攻击者获得物理访问权限

**防护**:
- 数据库全盘加密（SQLCipher）
- 生物识别锁定应用
- 远程数据擦除（未来）

**残余风险**: 低（需破解生物识别 + 数据库加密）

#### 2. 恶意软件

**威胁**: 设备感染恶意软件，窃取数据

**防护**:
- iOS沙盒隔离
- Android权限控制
- 密钥存储在安全区域（Keychain/KeyStore）

**残余风险**: 中（Root/Jailbreak设备）

#### 3. 网络窃听

**威胁**: 同步时数据被中间人攻击

**防护**:
- 端到端加密（E2EE）
- TLS 1.3传输加密
- 证书固定（Certificate Pinning，未来）

**残余风险**: 低

#### 4. 数据篡改

**威胁**: 攻击者修改交易数据

**防护**:
- 哈希链完整性验证
- Ed25519数字签名
- 定期完整性检查

**残余风险**: 极低

#### 5. 侧信道攻击

**威胁**: 通过缓存/时序攻击推断信息

**防护**:
- 常量时间算法
- 敏感数据清零
- 内存擦除

**残余风险**: 中（高级攻击）

---

## 密钥管理

### 密钥层次结构

```
主密钥（Master Key）
  ├─ 由设备安全存储生成（Keychain/KeyStore）
  └─ 256-bit随机密钥
      │
      ├─> 数据库密钥（Database Key）
      │   ├─ 通过HKDF派生
      │   └─ 用于SQLCipher AES-256加密
      │
      ├─> 字段加密密钥（Field Encryption Key）
      │   ├─ 通过HKDF派生
      │   └─ 用于ChaCha20-Poly1305加密交易备注
      │
      ├─> 文件加密密钥（File Encryption Key）
      │   ├─ 通过HKDF派生
      │   └─ 用于AES-256-GCM加密照片
      │
      └─> 同步加密密钥（Sync Encryption Key）
          ├─ 通过HKDF派生
          └─ 用于设备间E2EE

设备密钥对（Device Key Pair）
  ├─ Ed25519非对称密钥对
  ├─ 私钥存储在Keychain/KeyStore
  └─ 公钥共享给配对设备
```

### 密钥生成

```dart
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KeyManager {
  static final KeyManager instance = KeyManager._();
  KeyManager._();

  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// 初始化主密钥
  Future<void> initializeMasterKey() async {
    final existing = await _secureStorage.read(key: 'master_key');
    if (existing != null) {
      return;  // 主密钥已存在
    }

    // 生成256-bit随机主密钥
    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
    final masterKey = base64Encode(keyBytes);

    // 存储到安全存储
    await _secureStorage.write(key: 'master_key', value: masterKey);
  }

  /// 获取主密钥
  Future<List<int>> getMasterKey() async {
    final masterKey = await _secureStorage.read(key: 'master_key');
    if (masterKey == null) {
      throw Exception('主密钥不存在，请先初始化');
    }
    return base64Decode(masterKey);
  }

  /// 派生数据库密钥
  Future<String> getDatabaseKey() async {
    final masterKey = await getMasterKey();
    final derived = await _deriveKey(
      masterKey,
      info: 'database_encryption',
      length: 32,
    );
    return base64Encode(derived);
  }

  /// 派生字段加密密钥
  Future<SecretKey> getFieldEncryptionKey() async {
    final masterKey = await getMasterKey();
    final derived = await _deriveKey(
      masterKey,
      info: 'field_encryption',
      length: 32,
    );
    return SecretKey(derived);
  }

  /// 派生文件加密密钥
  Future<SecretKey> getFileEncryptionKey() async {
    final masterKey = await getMasterKey();
    final derived = await _deriveKey(
      masterKey,
      info: 'file_encryption',
      length: 32,
    );
    return SecretKey(derived);
  }

  /// 派生同步加密密钥
  Future<SecretKey> getSyncEncryptionKey() async {
    final masterKey = await getMasterKey();
    final derived = await _deriveKey(
      masterKey,
      info: 'sync_encryption',
      length: 32,
    );
    return SecretKey(derived);
  }

  /// HKDF密钥派生
  Future<List<int>> _deriveKey(
    List<int> masterKey, {
    required String info,
    required int length,
  }) async {
    final hkdf = Hkdf(
      hmac: Hmac.sha256(),
      outputLength: length,
    );

    final derivedKey = await hkdf.deriveKey(
      secretKey: SecretKey(masterKey),
      nonce: [],  // HKDF不需要nonce
      info: utf8.encode(info),
    );

    return await derivedKey.extractBytes();
  }

  /// 生成设备密钥对（Ed25519）
  Future<void> generateDeviceKeyPair() async {
    final existing = await _secureStorage.read(key: 'device_private_key');
    if (existing != null) {
      return;  // 密钥对已存在
    }

    // 生成Ed25519密钥对
    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPair();

    // 提取密钥
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();

    // 存储私钥到安全存储
    await _secureStorage.write(
      key: 'device_private_key',
      value: base64Encode(privateKeyBytes),
    );

    // 存储公钥（可以存储在普通位置）
    await _secureStorage.write(
      key: 'device_public_key',
      value: base64Encode(publicKey.bytes),
    );
  }

  /// 获取设备公钥
  Future<String> getDevicePublicKey() async {
    final publicKey = await _secureStorage.read(key: 'device_public_key');
    if (publicKey == null) {
      throw Exception('设备公钥不存在');
    }
    return publicKey;
  }

  /// 使用设备私钥签名
  Future<List<int>> sign(List<int> data) async {
    final privateKeyStr = await _secureStorage.read(key: 'device_private_key');
    if (privateKeyStr == null) {
      throw Exception('设备私钥不存在');
    }

    final privateKeyBytes = base64Decode(privateKeyStr);
    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPairFromSeed(privateKeyBytes);

    final signature = await algorithm.sign(data, keyPair: keyPair);
    return signature.bytes;
  }

  /// 验证签名
  Future<bool> verify({
    required List<int> data,
    required List<int> signature,
    required String publicKeyBase64,
  }) async {
    final publicKeyBytes = base64Decode(publicKeyBase64);
    final algorithm = Ed25519();
    final publicKey = SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519);

    final isValid = await algorithm.verify(
      data,
      signature: Signature(signature, publicKey: publicKey),
    );

    return isValid;
  }

  /// 清除所有密钥（用户卸载或重置）
  Future<void> clearAllKeys() async {
    await _secureStorage.deleteAll();
  }
}
```

### 密钥生命周期

```
生成 → 存储 → 使用 → 轮换 → 销毁
  ↓      ↓      ↓      ↓      ↓
应用    Keychain  加密   定期    卸载时
首次     /       /解密   更新    删除
启动  KeyStore
```

---

## 多层加密

### Layer 1: 数据库层加密（SQLCipher）

**算法**: AES-256-CBC
**密钥长度**: 256 bits
**KDF**: PBKDF2-HMAC-SHA512（256,000次迭代）
**范围**: 整个SQLite数据库文件

**配置**:

```dart
class DatabaseEncryption {
  static Future<void> setup(RawDatabase rawDb, String key) async {
    // SQLCipher 4.x配置
    await rawDb.execute("PRAGMA key = '$key'");
    await rawDb.execute("PRAGMA cipher_page_size = 4096");
    await rawDb.execute("PRAGMA kdf_iter = 256000");
    await rawDb.execute("PRAGMA cipher_hmac_algorithm = HMAC_SHA512");
    await rawDb.execute("PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA512");

    // 验证加密是否正确配置
    final result = await rawDb.select("PRAGMA cipher_version");
    print('SQLCipher version: $result');
  }

  /// 完整性检查
  static Future<bool> verifyIntegrity(RawDatabase rawDb) async {
    try {
      await rawDb.execute("PRAGMA cipher_integrity_check");
      return true;
    } catch (e) {
      print('数据库完整性检查失败: $e');
      return false;
    }
  }

  /// 更改数据库密钥（密钥轮换）
  static Future<void> rekeyDatabase(RawDatabase rawDb, String newKey) async {
    await rawDb.execute("PRAGMA rekey = '$newKey'");
  }
}
```

**优势**:
- 透明加密，应用层无感知
- 整个数据库文件加密，包括索引和元数据
- 行业标准，广泛审计

### Layer 2: 字段层加密（ChaCha20-Poly1305）

**算法**: ChaCha20-Poly1305（AEAD）
**密钥长度**: 256 bits
**Nonce**: 96 bits（随机生成）
**范围**: 敏感字段（交易备注、商家名称）

**实现**:

```dart
import 'package:cryptography/cryptography.dart';

class FieldEncryption {
  static final _algorithm = Chacha20.poly1305Aead();

  /// 加密字段
  static Future<String> encrypt(String plaintext) async {
    if (plaintext.isEmpty) return '';

    final keyManager = KeyManager.instance;
    final key = await keyManager.getFieldEncryptionKey();

    // 生成随机nonce（96-bit）
    final nonce = _algorithm.newNonce();

    // 加密
    final secretBox = await _algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
    );

    // 格式：nonce (12 bytes) + ciphertext (variable) + mac (16 bytes)
    final combined = <int>[
      ...nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ];

    return base64Encode(combined);
  }

  /// 解密字段
  static Future<String> decrypt(String encrypted) async {
    if (encrypted.isEmpty) return '';

    try {
      final keyManager = KeyManager.instance;
      final key = await keyManager.getFieldEncryptionKey();

      // 解析数据
      final data = base64Decode(encrypted);
      if (data.length < 28) {  // 12 (nonce) + 0 (min ciphertext) + 16 (mac)
        throw Exception('加密数据格式错误');
      }

      final nonce = data.sublist(0, 12);
      final macBytes = data.sublist(data.length - 16);
      final cipherText = data.sublist(12, data.length - 16);

      // 解密
      final secretBox = SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(macBytes),
      );

      final plaintext = await _algorithm.decrypt(
        secretBox,
        secretKey: key,
      );

      return utf8.decode(plaintext);
    } catch (e) {
      print('解密失败: $e');
      throw Exception('字段解密失败');
    }
  }
}
```

**优势**:
- AEAD提供认证加密，防篡改
- ChaCha20性能优于AES（移动设备）
- 每次加密使用新nonce

### Layer 3: 文件层加密（AES-256-GCM）

**算法**: AES-256-GCM
**密钥长度**: 256 bits
**Nonce**: 96 bits
**范围**: 交易照片文件

**实现**:

```dart
import 'package:cryptography/cryptography.dart';

class FileEncryption {
  static final _algorithm = AesGcm.with256bits();

  /// 加密文件
  static Future<File> encryptFile(File sourceFile) async {
    final keyManager = KeyManager.instance;
    final key = await keyManager.getFileEncryptionKey();

    // 读取源文件
    final plaintext = await sourceFile.readAsBytes();

    // 生成随机nonce
    final nonce = _algorithm.newNonce();

    // 加密
    final secretBox = await _algorithm.encrypt(
      plaintext,
      secretKey: key,
      nonce: nonce,
    );

    // 保存加密文件
    final encryptedPath = '${sourceFile.path}.enc';
    final encryptedFile = File(encryptedPath);

    // 写入：nonce + ciphertext + mac
    await encryptedFile.writeAsBytes([
      ...nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);

    // 删除明文文件
    await sourceFile.delete();

    return encryptedFile;
  }

  /// 解密文件到内存
  static Future<Uint8List> decryptFile(File encryptedFile) async {
    final keyManager = KeyManager.instance;
    final key = await keyManager.getFileEncryptionKey();

    // 读取加密文件
    final data = await encryptedFile.readAsBytes();

    // 解析
    final nonce = data.sublist(0, 12);
    final macBytes = data.sublist(data.length - 16);
    final cipherText = data.sublist(12, data.length - 16);

    // 解密
    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    final plaintext = await _algorithm.decrypt(
      secretBox,
      secretKey: key,
    );

    return Uint8List.fromList(plaintext);
  }

  /// 计算文件哈希（用于去重和验证）
  static Future<String> hashFile(File file) async {
    final data = await file.readAsBytes();
    final hash = await Sha256().hash(data);
    return hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
```

### Layer 4: 传输层加密（E2EE）

**协议**: TLS 1.3 + 自定义E2EE层
**密钥交换**: ECDH (Curve25519)
**传输加密**: ChaCha20-Poly1305
**范围**: 设备间同步数据

详见 [08_MOD_FamilySync.md](./08_MOD_FamilySync.md)。

---

## 哈希链完整性

### 哈希链设计

```
Genesis Block
    ↓
 Transaction 1 (prevHash: null)
    ↓ currentHash = SHA256(tx1 data)
 Transaction 2 (prevHash: tx1.currentHash)
    ↓ currentHash = SHA256(tx2 data + prevHash)
 Transaction 3 (prevHash: tx2.currentHash)
    ↓ currentHash = SHA256(tx3 data + prevHash)
  ...
```

**哈希输入**: `id|amount|type|categoryId|timestamp|prevHash`

### 实现

```dart
import 'package:crypto/crypto.dart';

class HashChainService {
  /// 计算哈希
  static String hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 计算交易哈希
  static String calculateTransactionHash(Transaction tx) {
    final input = [
      tx.id,
      tx.amount.toString(),
      tx.type.name,
      tx.categoryId,
      tx.timestamp.millisecondsSinceEpoch.toString(),
      tx.prevHash ?? 'genesis',
    ].join('|');

    return hash(input);
  }

  /// 获取账本最新哈希
  static Future<String?> getLatestHash(
    String bookId,
    TransactionRepository repo,
  ) async {
    final latestTx = await repo.getLatestTransaction(bookId);
    return latestTx?.currentHash;
  }

  /// 验证单笔交易完整性
  static bool verifyTransaction(Transaction tx) {
    final calculatedHash = calculateTransactionHash(tx);
    return calculatedHash == tx.currentHash;
  }

  /// 验证整个哈希链完整性
  static Future<HashChainVerificationResult> verifyHashChain({
    required String bookId,
    required TransactionRepository repo,
  }) async {
    // 获取所有交易，按时间排序
    final transactions = await repo.getTransactions(
      bookId: bookId,
      orderBy: 'timestamp ASC',
      includeDeleted: false,
    );

    if (transactions.isEmpty) {
      return HashChainVerificationResult(
        isValid: true,
        totalCount: 0,
        verifiedCount: 0,
      );
    }

    int verifiedCount = 0;
    String? expectedPrevHash;

    for (int i = 0; i < transactions.length; i++) {
      final tx = transactions[i];

      // 1. 验证当前交易哈希
      if (!verifyTransaction(tx)) {
        return HashChainVerificationResult(
          isValid: false,
          totalCount: transactions.length,
          verifiedCount: verifiedCount,
          brokenAt: i,
          brokenTransactionId: tx.id,
          error: '交易哈希验证失败',
        );
      }

      // 2. 验证prevHash链接
      if (i == 0) {
        // 第一笔交易
        if (tx.prevHash != null && tx.prevHash != 'genesis') {
          return HashChainVerificationResult(
            isValid: false,
            totalCount: transactions.length,
            verifiedCount: verifiedCount,
            brokenAt: i,
            brokenTransactionId: tx.id,
            error: '第一笔交易的prevHash应为null或genesis',
          );
        }
      } else {
        // 后续交易
        if (tx.prevHash != expectedPrevHash) {
          return HashChainVerificationResult(
            isValid: false,
            totalCount: transactions.length,
            verifiedCount: verifiedCount,
            brokenAt: i,
            brokenTransactionId: tx.id,
            error: '哈希链断裂：prevHash不匹配',
          );
        }
      }

      expectedPrevHash = tx.currentHash;
      verifiedCount++;
    }

    return HashChainVerificationResult(
      isValid: true,
      totalCount: transactions.length,
      verifiedCount: verifiedCount,
    );
  }
}

/// 验证结果
class HashChainVerificationResult {
  final bool isValid;
  final int totalCount;
  final int verifiedCount;
  final int? brokenAt;
  final String? brokenTransactionId;
  final String? error;

  HashChainVerificationResult({
    required this.isValid,
    required this.totalCount,
    required this.verifiedCount,
    this.brokenAt,
    this.brokenTransactionId,
    this.error,
  });
}
```

### 定期验证

```dart
@riverpod
class HashChainMonitor extends _$HashChainMonitor {
  Timer? _timer;

  @override
  void build() {
    // 每小时验证一次
    _timer = Timer.periodic(const Duration(hours: 1), (_) {
      _verifyAllBooks();
    });

    // 清理
    ref.onDispose(() {
      _timer?.cancel();
    });
  }

  Future<void> _verifyAllBooks() async {
    final bookRepo = ref.read(bookRepositoryProvider);
    final txRepo = ref.read(transactionRepositoryProvider);

    final books = await bookRepo.findAll();

    for (final book in books) {
      final result = await HashChainService.verifyHashChain(
        bookId: book.id,
        repo: txRepo,
      );

      if (!result.isValid) {
        // 记录警告
        await AuditLogger.log(
          event: AuditEvent.hashChainBroken,
          bookId: book.id,
          details: result.error,
        );

        // 通知用户
        ref.read(notificationServiceProvider).showError(
          '账本完整性验证失败：${book.name}',
        );
      }
    }
  }
}
```

---

## 生物识别认证

### 平台支持

| 平台 | 技术 | 支持类型 |
|------|------|---------|
| iOS | Face ID / Touch ID | 强生物识别 |
| Android | BiometricPrompt API | 指纹/人脸/虹膜 |

### 实现

```dart
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// 检查生物识别可用性
  Future<BiometricAvailability> checkAvailability() async {
    final canCheckBiometrics = await _auth.canCheckBiometrics;
    final isDeviceSupported = await _auth.isDeviceSupported();

    if (!canCheckBiometrics || !isDeviceSupported) {
      return BiometricAvailability.notAvailable;
    }

    final availableBiometrics = await _auth.getAvailableBiometrics();

    if (availableBiometrics.isEmpty) {
      return BiometricAvailability.notEnrolled;
    }

    if (Platform.isIOS) {
      if (availableBiometrics.contains(BiometricType.face)) {
        return BiometricAvailability.faceId;
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        return BiometricAvailability.touchId;
      }
    } else if (Platform.isAndroid) {
      if (availableBiometrics.contains(BiometricType.face)) {
        return BiometricAvailability.face;
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        return BiometricAvailability.fingerprint;
      }
    }

    return BiometricAvailability.unknown;
  }

  /// 进行生物识别认证
  Future<bool> authenticate({
    required String reason,
    bool biometricOnly = true,
  }) async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
          useErrorDialogs: true,
        ),
      );

      return authenticated;
    } on PlatformException catch (e) {
      print('生物识别认证错误: ${e.code} - ${e.message}');
      return false;
    }
  }

  /// 应用启动时认证
  Future<bool> authenticateOnLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('biometric_lock_enabled') ?? false;

    if (!enabled) {
      return true;  // 未启用生物识别锁
    }

    return await authenticate(
      reason: '验证您的身份以访问Home Pocket',
      biometricOnly: true,
    );
  }

  /// 敏感操作前认证
  Future<bool> authenticateForSensitiveOperation({
    required String operation,
  }) async {
    return await authenticate(
      reason: '验证您的身份以$operation',
      biometricOnly: false,  // 允许PIN码后备
    );
  }
}

enum BiometricAvailability {
  notAvailable,    // 设备不支持
  notEnrolled,     // 未注册生物识别
  faceId,          // iOS Face ID
  touchId,         // iOS Touch ID
  face,            // Android 人脸识别
  fingerprint,     // Android 指纹识别
  unknown,
}
```

### 集成示例

```dart
@riverpod
class AppLockManager extends _$AppLockManager {
  @override
  bool build() {
    return false;  // 初始未锁定
  }

  /// 应用进入后台
  void onAppPaused() {
    state = true;  // 锁定应用
  }

  /// 应用恢复前台
  Future<bool> onAppResumed() async {
    if (!state) return true;  // 未锁定

    final bioService = ref.read(biometricAuthServiceProvider);
    final authenticated = await bioService.authenticateOnLaunch();

    if (authenticated) {
      state = false;  // 解锁
    }

    return authenticated;
  }
}
```

---

## 设备间同步安全

### QR码配对

```dart
class PairingQRCodeService {
  /// 生成配对QR码
  Future<String> generatePairingQR() async {
    final keyManager = KeyManager.instance;
    final deviceManager = DeviceManager.instance;

    final deviceId = await deviceManager.getCurrentDeviceId();
    final publicKey = await keyManager.getDevicePublicKey();
    final deviceName = await deviceManager.getDeviceName();

    // 生成临时配对token（有效期5分钟）
    final token = _generateToken();
    final expiresAt = DateTime.now().add(const Duration(minutes: 5));

    // 构建配对数据
    final pairingData = {
      'version': '1.0',
      'deviceId': deviceId,
      'deviceName': deviceName,
      'publicKey': publicKey,
      'token': token,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
    };

    // 签名数据
    final dataString = jsonEncode(pairingData);
    final signature = await keyManager.sign(utf8.encode(dataString));

    // 最终QR码数据
    final qrData = {
      'data': pairingData,
      'signature': base64Encode(signature),
    };

    return jsonEncode(qrData);
  }

  /// 解析配对QR码
  Future<PairingInfo> parsePairingQR(String qrData) async {
    final json = jsonDecode(qrData) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>;
    final signatureBase64 = json['signature'] as String;

    // 1. 验证签名
    final dataString = jsonEncode(data);
    final publicKey = data['publicKey'] as String;
    final signature = base64Decode(signatureBase64);

    final keyManager = KeyManager.instance;
    final isValid = await keyManager.verify(
      data: utf8.encode(dataString),
      signature: signature,
      publicKeyBase64: publicKey,
    );

    if (!isValid) {
      throw Exception('配对QR码签名验证失败');
    }

    // 2. 验证有效期
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      data['expiresAt'] as int,
    );

    if (DateTime.now().isAfter(expiresAt)) {
      throw Exception('配对QR码已过期');
    }

    // 3. 返回配对信息
    return PairingInfo(
      deviceId: data['deviceId'] as String,
      deviceName: data['deviceName'] as String,
      publicKey: publicKey,
      token: data['token'] as String,
    );
  }

  String _generateToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
```

### E2EE同步加密

```dart
class SyncEncryption {
  /// 加密同步数据
  static Future<EncryptedSyncData> encrypt({
    required Transaction transaction,
    required String recipientPublicKey,
  }) async {
    // 1. 生成临时对称密钥
    final sessionKey = _generateSessionKey();

    // 2. 使用对称密钥加密交易数据
    final plaintext = jsonEncode(transaction.toJson());
    final encrypted = await _encryptWithSessionKey(plaintext, sessionKey);

    // 3. 使用接收方公钥加密对称密钥（ECDH）
    final keyManager = KeyManager.instance;
    final encryptedSessionKey = await _encryptSessionKey(
      sessionKey,
      recipientPublicKey,
    );

    // 4. 签名数据
    final signature = await keyManager.sign(utf8.encode(plaintext));

    return EncryptedSyncData(
      encryptedData: encrypted,
      encryptedSessionKey: encryptedSessionKey,
      signature: base64Encode(signature),
    );
  }

  /// 解密同步数据
  static Future<Transaction> decrypt({
    required EncryptedSyncData encryptedData,
    required String senderPublicKey,
  }) async {
    // 1. 解密对称密钥
    final sessionKey = await _decryptSessionKey(
      encryptedData.encryptedSessionKey,
    );

    // 2. 解密交易数据
    final plaintext = await _decryptWithSessionKey(
      encryptedData.encryptedData,
      sessionKey,
    );

    // 3. 验证签名
    final keyManager = KeyManager.instance;
    final isValid = await keyManager.verify(
      data: utf8.encode(plaintext),
      signature: base64Decode(encryptedData.signature),
      publicKeyBase64: senderPublicKey,
    );

    if (!isValid) {
      throw Exception('同步数据签名验证失败');
    }

    // 4. 解析交易
    final json = jsonDecode(plaintext) as Map<String, dynamic>;
    return Transaction.fromJson(json);
  }
}
```

---

## Recovery Kit恢复机制

### 24词助记词生成

```dart
import 'package:bip39/bip39.dart' as bip39;

class RecoveryKitService {
  /// 生成Recovery Kit
  Future<RecoveryKit> generateRecoveryKit() async {
    final keyManager = KeyManager.instance;

    // 1. 获取主密钥
    final masterKey = await keyManager.getMasterKey();

    // 2. 生成24词助记词
    final entropy = _convertKeyToEntropy(masterKey);
    final mnemonic = bip39.entropyToMnemonic(hex.encode(entropy));

    // 3. 获取设备密钥对
    final publicKey = await keyManager.getDevicePublicKey();

    // 4. 生成验证码（用于验证恢复）
    final verificationCode = _generateVerificationCode(masterKey);

    return RecoveryKit(
      mnemonic: mnemonic.split(' '),
      publicKey: publicKey,
      verificationCode: verificationCode,
      createdAt: DateTime.now(),
    );
  }

  /// 从Recovery Kit恢复
  Future<bool> recoverFromKit(RecoveryKit kit) async {
    try {
      // 1. 验证助记词
      final mnemonic = kit.mnemonic.join(' ');
      if (!bip39.validateMnemonic(mnemonic)) {
        throw Exception('助记词无效');
      }

      // 2. 恢复主密钥
      final entropy = hex.decode(bip39.mnemonicToEntropy(mnemonic));
      final masterKey = _convertEntropyToKey(entropy);

      // 3. 验证验证码
      final calculatedCode = _generateVerificationCode(masterKey);
      if (calculatedCode != kit.verificationCode) {
        throw Exception('验证码不匹配');
      }

      // 4. 存储主密钥
      final keyManager = KeyManager.instance;
      await keyManager._secureStorage.write(
        key: 'master_key',
        value: base64Encode(masterKey),
      );

      return true;
    } catch (e) {
      print('恢复失败: $e');
      return false;
    }
  }

  List<int> _convertKeyToEntropy(List<int> key) {
    // 主密钥32字节 = 256位熵 = 24词助记词
    return key;
  }

  List<int> _convertEntropyToKey(List<int> entropy) {
    return entropy;
  }

  String _generateVerificationCode(List<int> masterKey) {
    // 生成4位数字验证码
    final hash = sha256.convert(masterKey);
    final code = hash.bytes[0] << 24 |
                 hash.bytes[1] << 16 |
                 hash.bytes[2] << 8 |
                 hash.bytes[3];
    return (code.abs() % 10000).toString().padLeft(4, '0');
  }
}

class RecoveryKit {
  final List<String> mnemonic;  // 24个单词
  final String publicKey;
  final String verificationCode;  // 4位数字
  final DateTime createdAt;

  RecoveryKit({
    required this.mnemonic,
    required this.publicKey,
    required this.verificationCode,
    required this.createdAt,
  });
}
```

---

## 隐私保护

### 数据最小化

```dart
// ✅ 好的实践：仅收集必需数据
class Transaction {
  final int amount;
  final String categoryId;
  final DateTime timestamp;
  // 没有收集地理位置、设备指纹等
}

// ❌ 避免：过度收集
class Transaction {
  final int amount;
  final String categoryId;
  final DateTime timestamp;
  final Location location;  // ❌ 不必要
  final String deviceFingerprint;  // ❌ 隐私问题
}
```

### 私密交易

```dart
// 创建私密交易（仅创建者可见）
final transaction = Transaction.create(
  // ...
  isPrivate: true,  // 标记为私密
);

// 查询时过滤
class TransactionRepositoryImpl {
  Future<List<Transaction>> getTransactions({
    required String bookId,
    bool includePrivate = false,
  }) async {
    final currentDeviceId = await DeviceManager.instance.getCurrentDeviceId();

    var query = db.select(db.transactions)
      ..where((t) => t.bookId.equals(bookId));

    if (!includePrivate) {
      // 排除其他设备的私密交易
      query.where((t) =>
        t.isPrivate.equals(false) |
        t.deviceId.equals(currentDeviceId)
      );
    }

    return query.get();
  }
}
```

---

## 安全审计

### 审计日志

```dart
class AuditLogger {
  static Future<void> log({
    required AuditEvent event,
    String? bookId,
    String? transactionId,
    String? details,
  }) async {
    final entry = AuditLogEntry(
      id: Ulid().toString(),
      event: event,
      deviceId: await DeviceManager.instance.getCurrentDeviceId(),
      bookId: bookId,
      transactionId: transactionId,
      details: details,
      timestamp: DateTime.now(),
    );

    await _db.insert(_db.auditLogs, entry.toCompanion());
  }
}

enum AuditEvent {
  appLaunched,
  biometricAuthSuccess,
  biometricAuthFailed,
  databaseOpened,
  hashChainBroken,
  syncStarted,
  syncCompleted,
  syncFailed,
  devicePaired,
  deviceUnpaired,
  backupExported,
  backupImported,
  // ...
}
```

---

## 总结

Home Pocket安全架构的核心特点：

1. **多层防御**: 数据库、字段、文件、传输四层加密
2. **密钥管理**: HKDF派生专用密钥，安全存储
3. **完整性保证**: 哈希链 + 数字签名
4. **零知识架构**: 所有加密在本地，密钥不离设备
5. **生物识别**: 强认证机制
6. **恢复机制**: 24词助记词
7. **隐私优先**: 数据最小化，用户完全控制

**下一步阅读**:
- [04_State_Management.md](./04_State_Management.md) - 状态管理架构
- [05_Integration_Patterns.md](./05_Integration_Patterns.md) - 集成模式

---

**文档维护**:
- 最后更新: 2026-02-03
- 维护者: 安全团队
- 版本: 1.0
