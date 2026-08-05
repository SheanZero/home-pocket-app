# PRD - 安全与隐私模块

**模块ID:** MOD-006
**模块名称:** 安全与隐私模块
**版本:** 1.0
**创建日期:** 2026年2月3日
**优先级:** P0（MVP必备）
**预估工时:** 10天

---

## 1. 模块概述

### 1.1 功能定义

安全与隐私模块是Happy Pocket的核心竞争力,实现完整的端到端加密（E2EE）和防篡改机制。包括:

- **密钥管理（E02）:** 设备密钥对生成、Recovery Kit备份、密钥恢复
- **生物识别锁（E03）:** Face ID/Touch ID/指纹识别启动认证
- **哈希链审计（D03）:** 区块链式防篡改记录,可导出审计报告
- **隐私宣言引导（E01）:** 首次启动三页隐私承诺展示
- **数据加密:** SQLCipher数据库加密、备注字段加密、照片加密

**核心价值主张:**
在隐私泄露频发的时代,Happy Pocket承诺"你的数据只属于你"。通过开源代码、E2EE架构、哈希链审计,建立用户信任。

### 1.2 用户场景与痛点

**用户画像:**
- 佐藤太郎（38岁,IT工程师）,隐私意识强
- 担心传统记账应用将数据上传服务器
- 曾经历某金融应用数据泄露事件,账单明细被曝光

**痛点:**
1. **隐私焦虑:** "我的收入、消费习惯会被公司看到吗?"
2. **数据泄露风险:** "如果服务器被黑,我的财务信息会被窃取吗?"
3. **篡改担忧:** "伴侣会偷偷删除TA的消费记录吗?"
4. **设备丢失恐慌:** "手机丢了,所有记账数据都没了怎么办?"

**Happy Pocket解决方案:**
- 本地优先架构,数据不上传服务器
- 端到端加密,即使同步也无法被中间人窃取
- 区块链式哈希链,任何篡改都会被检测
- Recovery Kit备份,支持从助记词恢复所有数据

### 1.3 与其他模块的依赖关系

**前置依赖:**
- 无（最基础模块,优先开发）

**被依赖:**
- MOD-001 基础记账（需要加密存储）
- MOD-004 家庭同步（需要密钥交换）
- MOD-005 OCR扫描（需要照片加密）
- 所有模块（依赖生物识别锁和数据库加密）

---

## 2. 详细功能规格

### 2.1 E02: 密钥管理

#### 2.1.1 设备密钥对生成

**密钥算法选择:**
- **非对称加密:** Ed25519（椭圆曲线签名）
- **对称加密:** ChaCha20-Poly1305（备注字段加密）
- **哈希算法:** SHA-256（哈希链）
- **密钥派生:** PBKDF2（从Recovery Kit派生）

**为什么选择Ed25519?**
1. 性能优秀（比RSA快10倍）
2. 密钥短（32字节公钥、64字节签名）
3. 安全性高（128位安全级别）
4. Flutter原生支持（`pointycastle`库）

**密钥生成流程:**

```dart
// lib/core/security/key_manager.dart

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bip39/bip39.dart' as bip39;

class KeyManager {
  final FlutterSecureStorage _secureStorage;
  final Ed25519 _ed25519 = Ed25519();

  /// 生成设备主密钥对（首次启动时调用）
  Future<DeviceKeyPair> generateDeviceKeyPair() async {
    // 1. 生成Ed25519密钥对
    final keyPair = await _ed25519.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

    // 2. 将私钥存储到安全存储（iOS Keychain / Android Keystore）
    await _secureStorage.write(
      key: 'device_private_key',
      value: base64Encode(privateKeyBytes),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.whenUnlockedThisDeviceOnly,
      ),
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    );

    // 3. 公钥可以明文存储
    final publicKeyHex = base64Encode(publicKey.bytes);
    await _secureStorage.write(
      key: 'device_public_key',
      value: publicKeyHex,
    );

    // 4. 生成设备ID（公钥的哈希）
    final deviceId = _generateDeviceId(publicKey.bytes);
    await _secureStorage.write(key: 'device_id', value: deviceId);

    return DeviceKeyPair(
      publicKey: publicKeyHex,
      deviceId: deviceId,
      createdAt: DateTime.now(),
    );
  }

  /// 从Recovery Kit恢复密钥对
  Future<DeviceKeyPair> recoverFromMnemonic(String mnemonic) async {
    // 1. 验证助记词
    if (!bip39.validateMnemonic(mnemonic)) {
      throw InvalidMnemonicException('助记词格式错误');
    }

    // 2. 从助记词派生种子（512位）
    final seed = bip39.mnemonicToSeed(mnemonic);

    // 3. 取前32字节作为Ed25519私钥种子
    final privateKeySeed = seed.sublist(0, 32);

    // 4. 生成密钥对
    final keyPair = await _ed25519.newKeyPairFromSeed(privateKeySeed);
    final publicKey = await keyPair.extractPublicKey();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

    // 5. 存储到安全存储
    await _secureStorage.write(
      key: 'device_private_key',
      value: base64Encode(privateKeyBytes),
    );

    await _secureStorage.write(
      key: 'device_public_key',
      value: base64Encode(publicKey.bytes),
    );

    final deviceId = _generateDeviceId(publicKey.bytes);
    await _secureStorage.write(key: 'device_id', value: deviceId);

    return DeviceKeyPair(
      publicKey: base64Encode(publicKey.bytes),
      deviceId: deviceId,
      createdAt: DateTime.now(),
    );
  }

  /// 生成设备ID（公钥哈希的前16字符）
  String _generateDeviceId(List<int> publicKeyBytes) {
    final hash = sha256.convert(publicKeyBytes);
    return base64UrlEncode(hash.bytes).substring(0, 16);
  }

  /// 获取当前设备的公钥
  Future<String?> getPublicKey() async {
    return await _secureStorage.read(key: 'device_public_key');
  }

  /// 获取当前设备ID
  Future<String?> getDeviceId() async {
    return await _secureStorage.read(key: 'device_id');
  }

  /// 检查是否已生成密钥对
  Future<bool> hasKeyPair() async {
    final privateKey = await _secureStorage.read(key: 'device_private_key');
    return privateKey != null;
  }

  /// 签名数据（用于哈希链）
  Future<Signature> signData(List<int> data) async {
    final privateKeyBase64 = await _secureStorage.read(key: 'device_private_key');
    if (privateKeyBase64 == null) {
      throw KeyNotFoundException('设备私钥未找到');
    }

    final privateKeyBytes = base64Decode(privateKeyBase64);
    final keyPair = await _ed25519.newKeyPairFromSeed(privateKeyBytes);

    return await _ed25519.sign(data, keyPair: keyPair);
  }

  /// 验证签名
  Future<bool> verifySignature({
    required List<int> data,
    required Signature signature,
    required String publicKeyBase64,
  }) async {
    final publicKeyBytes = base64Decode(publicKeyBase64);
    final publicKey = SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519);

    return await _ed25519.verify(data, signature: signature);
  }
}

class DeviceKeyPair {
  final String publicKey;
  final String deviceId;
  final DateTime createdAt;

  DeviceKeyPair({
    required this.publicKey,
    required this.deviceId,
    required this.createdAt,
  });
}
```

#### 2.1.2 Recovery Kit（24个助记词）

**为什么使用BIP39助记词?**
- 行业标准（加密货币钱包广泛采用）
- 易于抄写和记忆（相比随机hex字符串）
- 支持校验和（防止抄写错误）

**Recovery Kit生成流程:**

```dart
// lib/core/security/recovery_kit.dart

class RecoveryKitService {
  /// 生成Recovery Kit（24个助记词）
  Future<String> generateRecoveryKit() async {
    // 1. 生成256位随机熵
    final random = Random.secure();
    final entropy = List<int>.generate(32, (_) => random.nextInt(256));

    // 2. 转换为BIP39助记词（24个单词）
    final mnemonic = bip39.entropyToMnemonic(Uint8List.fromList(entropy));

    // 3. 存储到安全存储（用于后续验证）
    await _secureStorage.write(
      key: 'recovery_kit_hash',
      value: sha256.convert(utf8.encode(mnemonic)).toString(),
    );

    return mnemonic;
  }

  /// 验证用户输入的Recovery Kit
  Future<bool> verifyRecoveryKit(String userInput) async {
    // 1. 验证BIP39格式
    if (!bip39.validateMnemonic(userInput)) {
      return false;
    }

    // 2. 验证是否与存储的哈希匹配
    final storedHash = await _secureStorage.read(key: 'recovery_kit_hash');
    if (storedHash == null) {
      return false;
    }

    final inputHash = sha256.convert(utf8.encode(userInput)).toString();
    return inputHash == storedHash;
  }

  /// 导出Recovery Kit为PDF
  Future<File> exportToPDF(String mnemonic) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Happy Pocket Recovery Kit',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                '⚠️ 请安全保存此文件,丢失将无法恢复数据',
                style: pw.TextStyle(fontSize: 14, color: PdfColors.red),
              ),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text('您的24个助记词:', style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 12),
              _buildMnemonicGrid(mnemonic),
              pw.SizedBox(height: 40),
              pw.Text('生成日期: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
              pw.SizedBox(height: 12),
              pw.Text('设备ID: ${await _keyManager.getDeviceId()}'),
            ],
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/recovery_kit_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  pw.Widget _buildMnemonicGrid(String mnemonic) {
    final words = mnemonic.split(' ');
    return pw.GridView(
      crossAxisCount: 3,
      childAspectRatio: 3,
      children: List.generate(24, (index) {
        return pw.Container(
          padding: pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            '${index + 1}. ${words[index]}',
            style: pw.TextStyle(fontSize: 12),
          ),
        );
      }),
    );
  }
}
```

**UI设计（Recovery Kit备份页面）:**

```
┌─────────────────────────────────────┐
│  Recovery Kit 备份              [X] │
├─────────────────────────────────────┤
│                                     │
│  ⚠️ 请抄写以下24个单词               │
│     丢失此备份将无法恢复数据         │
│                                     │
│  ┌────────────────────────────┐    │
│  │ 1. abandon   9. castle     │    │
│  │ 2. ability  10. catalog    │    │
│  │ 3. able     11. catch      │    │
│  │ 4. about    12. category   │    │
│  │ 5. above    13. cattle     │    │
│  │ 6. absent   14. caught     │    │
│  │ 7. absorb   15. cause      │    │
│  │ 8. abstract 16. caution    │    │
│  │ 17. celery  21. change     │    │
│  │ 18. cement  22. chaos      │    │
│  │ 19. census  23. chapter    │    │
│  │ 20. century 24. charge     │    │
│  └────────────────────────────┘    │
│                                     │
│  导出选项：                         │
│  📋 [复制到剪贴板]                  │
│  💾 [保存为PDF]                     │
│  🖨️ [打印]                         │
│                                     │
│  确认事项：                         │
│  ☐ 我已安全保存这些单词             │
│  ☐ 我理解丢失后果                   │
│  ☐ 我不会向任何人泄露               │
│                                     │
│  [下一步]（需勾选全部）              │
└─────────────────────────────────────┘
```

**验证页面（确保用户真的抄写了）:**

```
┌─────────────────────────────────────┐
│  验证 Recovery Kit              ← │
├─────────────────────────────────────┤
│                                     │
│  请输入以下单词以验证您已抄写：      │
│                                     │
│  第3个单词：                        │
│  ┌────────────────────────────┐    │
│  │ able                        │    │  ← 用户输入
│  └────────────────────────────┘    │
│  ✓ 正确                             │
│                                     │
│  第12个单词：                       │
│  ┌────────────────────────────┐    │
│  │ category                    │    │
│  └────────────────────────────┘    │
│  ✓ 正确                             │
│                                     │
│  第24个单词：                       │
│  ┌────────────────────────────┐    │
│  │ charge                      │    │
│  └────────────────────────────┘    │
│  ✓ 正确                             │
│                                     │
│  [完成设置]                         │
└─────────────────────────────────────┘
```

---

### 2.2 E03: 生物识别锁

#### 2.2.1 支持的认证方式

| 平台 | 认证方式 | 备用方案 |
|------|---------|---------|
| iOS | Face ID | Touch ID → PIN码 |
| iOS | Touch ID | PIN码 |
| Android | 人脸识别 | 指纹识别 → PIN码 |
| Android | 指纹识别 | PIN码 |

**技术实现（使用local_auth插件）:**

```dart
// lib/core/security/biometric_lock.dart

import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_ios/local_auth_ios.dart';

class BiometricLock {
  final LocalAuthentication _localAuth = LocalAuthentication();
  int _failedAttempts = 0;
  static const int maxFailedAttempts = 3;

  /// 检查设备是否支持生物识别
  Future<BiometricAvailability> checkAvailability() async {
    // 1. 检查设备硬件支持
    final canCheckBiometrics = await _localAuth.canCheckBiometrics;
    final isDeviceSupported = await _localAuth.isDeviceSupported();

    if (!canCheckBiometrics || !isDeviceSupported) {
      return BiometricAvailability.notSupported;
    }

    // 2. 获取可用的生物识别类型
    final availableBiometrics = await _localAuth.getAvailableBiometrics();

    if (availableBiometrics.isEmpty) {
      return BiometricAvailability.notEnrolled;
    }

    // 3. 确定具体类型
    if (availableBiometrics.contains(BiometricType.face)) {
      return BiometricAvailability.faceId;
    } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
      return BiometricAvailability.fingerprint;
    } else if (availableBiometrics.contains(BiometricType.strong) ||
               availableBiometrics.contains(BiometricType.weak)) {
      return BiometricAvailability.generic;
    }

    return BiometricAvailability.notSupported;
  }

  /// 执行生物识别认证
  Future<AuthResult> authenticate({
    required String reason,
    bool allowPINFallback = true,
  }) async {
    try {
      // 1. 检查可用性
      final availability = await checkAvailability();
      if (availability == BiometricAvailability.notSupported ||
          availability == BiometricAvailability.notEnrolled) {
        return AuthResult.fallbackToPIN();
      }

      // 2. 检查失败次数
      if (_failedAttempts >= maxFailedAttempts) {
        return AuthResult.tooManyAttempts();
      }

      // 3. 执行认证
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        authMessages: [
          AndroidAuthMessages(
            signInTitle: 'Happy Pocket 認証',
            cancelButton: 'キャンセル',
            biometricHint: '指紋または顔で認証',
          ),
          IOSAuthMessages(
            cancelButton: 'キャンセル',
            goToSettingsButton: '設定',
            goToSettingsDescription: '生体認証を設定してください',
            lockOut: '生体認証がロックされました',
          ),
        ],
        options: AuthenticationOptions(
          stickyAuth: true,  // 防止应用切换到后台时取消认证
          biometricOnly: !allowPINFallback,  // 是否允许PIN备用
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );

      if (didAuthenticate) {
        _failedAttempts = 0;
        return AuthResult.success();
      } else {
        _failedAttempts++;
        return AuthResult.failed(_failedAttempts);
      }
    } on PlatformException catch (e) {
      if (e.code == 'LockedOut') {
        return AuthResult.lockedOut();
      } else if (e.code == 'NotAvailable') {
        return AuthResult.fallbackToPIN();
      } else {
        _failedAttempts++;
        return AuthResult.error(e.message ?? '认证失败');
      }
    }
  }

  /// 重置失败次数
  void resetFailedAttempts() {
    _failedAttempts = 0;
  }
}

enum BiometricAvailability {
  faceId,
  fingerprint,
  generic,
  notEnrolled,
  notSupported,
}

class AuthResult {
  final AuthStatus status;
  final String? message;
  final int? failedAttempts;

  AuthResult.success()
      : status = AuthStatus.success,
        message = null,
        failedAttempts = null;

  AuthResult.failed(int attempts)
      : status = AuthStatus.failed,
        message = null,
        failedAttempts = attempts;

  AuthResult.fallbackToPIN()
      : status = AuthStatus.fallbackToPIN,
        message = null,
        failedAttempts = null;

  AuthResult.tooManyAttempts()
      : status = AuthStatus.tooManyAttempts,
        message = 'PINコードを入力してください',
        failedAttempts = null;

  AuthResult.lockedOut()
      : status = AuthStatus.lockedOut,
        message = '生体認証がロックされました',
        failedAttempts = null;

  AuthResult.error(String msg)
      : status = AuthStatus.error,
        message = msg,
        failedAttempts = null;
}

enum AuthStatus {
  success,
  failed,
  fallbackToPIN,
  tooManyAttempts,
  lockedOut,
  error,
}
```

#### 2.2.2 启动认证流程

```dart
// lib/features/auth/presentation/biometric_lock_screen.dart

class BiometricLockScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends ConsumerState<BiometricLockScreen> {
  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    final biometricLock = ref.read(biometricLockProvider);

    final result = await biometricLock.authenticate(
      reason: 'Happy Pocketを開くには認証が必要です',
    );

    if (!mounted) return;

    switch (result.status) {
      case AuthStatus.success:
        // 解密数据库密钥
        await _unlockDatabase();
        // 进入首页
        Navigator.of(context).pushReplacementNamed('/home');
        break;

      case AuthStatus.failed:
        _showFailedDialog(result.failedAttempts!);
        break;

      case AuthStatus.fallbackToPIN:
      case AuthStatus.tooManyAttempts:
        _showPINDialog();
        break;

      case AuthStatus.lockedOut:
        _showLockedOutDialog();
        break;

      case AuthStatus.error:
        _showErrorDialog(result.message!);
        break;
    }
  }

  Future<void> _unlockDatabase() async {
    final keyManager = ref.read(keyManagerProvider);
    final dbPassword = await keyManager.getDatabasePassword();

    // 初始化SQLCipher
    final db = ref.read(databaseProvider);
    await db.initialize(password: dbPassword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 80, color: Theme.of(context).primaryColor),
            SizedBox(height: 24),
            Text(
              'Happy Pocket',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              '認証してください',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(),
            SizedBox(height: 20),
            TextButton(
              onPressed: _showPINDialog,
              child: Text('PINコードを入力'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFailedDialog(int attempts) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('認証失敗'),
        content: Text('認証に失敗しました（${attempts}/${BiometricLock.maxFailedAttempts}回）'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _authenticate();
            },
            child: Text('再試行'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showPINDialog();
            },
            child: Text('PINを入力'),
          ),
        ],
      ),
    );
  }

  void _showPINDialog() {
    // TODO: 实现PIN输入对话框
    // 验证PIN后调用_unlockDatabase()
  }
}
```

---

### 2.3 D03: 哈希链审计

#### 2.3.1 哈希链原理

**区块链式防篡改:**
每笔交易包含前一笔交易的哈希值,形成链式结构。任何修改都会导致后续哈希值全部改变,从而被检测。

```
Genesis (创世记录)
    ↓
tx-001 [hash: abc123, prevHash: genesis]
    ↓
tx-002 [hash: def456, prevHash: abc123]
    ↓
tx-003 [hash: ghi789, prevHash: def456]
    ↓
...
```

**哈希计算:**

```dart
// lib/core/security/hash_chain_service.dart

class HashChainService {
  final KeyManager _keyManager;
  final TransactionRepository _transactionRepo;

  /// 计算交易哈希
  Future<String> calculateHash(Transaction tx) async {
    // 1. 获取前一笔交易的哈希
    final prevHash = tx.prevHash ?? 'genesis';

    // 2. 构造待哈希数据（包含关键字段）
    final data = StringBuffer()
      ..write(tx.id)
      ..write('|')
      ..write(tx.bookId)
      ..write('|')
      ..write(tx.deviceId)
      ..write('|')
      ..write(tx.amount)
      ..write('|')
      ..write(tx.type.name)
      ..write('|')
      ..write(tx.categoryId)
      ..write('|')
      ..write(tx.ledgerType.name)
      ..write('|')
      ..write(tx.timestamp.millisecondsSinceEpoch)
      ..write('|')
      ..write(prevHash);

    // 3. SHA-256哈希
    final bytes = utf8.encode(data.toString());
    final digest = sha256.convert(bytes);

    // 4. Base64编码（便于存储）
    return base64Encode(digest.bytes);
  }

  /// 验证整个哈希链的完整性
  Future<ChainVerificationResult> verifyChain(String bookId) async {
    final transactions = await _transactionRepo.getTransactions(
      bookId: bookId,
      orderBy: 'timestamp ASC',
    );

    if (transactions.isEmpty) {
      return ChainVerificationResult.empty();
    }

    String prevHash = 'genesis';
    final tamperedTransactions = <Transaction>[];

    for (var i = 0; i < transactions.length; i++) {
      final tx = transactions[i];

      // 1. 验证prevHash是否正确
      if (tx.prevHash != prevHash) {
        tamperedTransactions.add(tx);
        continue;
      }

      // 2. 重新计算哈希并比对
      final expectedHash = await calculateHash(
        tx.copyWith(prevHash: prevHash),
      );

      if (tx.currentHash != expectedHash) {
        tamperedTransactions.add(tx);
      }

      prevHash = tx.currentHash;
    }

    if (tamperedTransactions.isEmpty) {
      return ChainVerificationResult.valid(
        totalTransactions: transactions.length,
      );
    } else {
      return ChainVerificationResult.tampered(
        totalTransactions: transactions.length,
        tamperedTransactions: tamperedTransactions,
      );
    }
  }

  /// 添加新交易到链中
  Future<Transaction> appendToChain({
    required Transaction tx,
    required String bookId,
  }) async {
    // 1. 获取最后一笔交易
    final lastTx = await _transactionRepo.getLastTransaction(bookId);

    // 2. 设置prevHash
    final prevHash = lastTx?.currentHash ?? 'genesis';

    // 3. 计算当前哈希
    final currentHash = await calculateHash(
      tx.copyWith(prevHash: prevHash),
    );

    // 4. 返回完整的交易对象
    return tx.copyWith(
      prevHash: prevHash,
      currentHash: currentHash,
    );
  }
}

class ChainVerificationResult {
  final bool isValid;
  final int totalTransactions;
  final List<Transaction> tamperedTransactions;

  ChainVerificationResult.valid({
    required this.totalTransactions,
  })  : isValid = true,
        tamperedTransactions = [];

  ChainVerificationResult.tampered({
    required this.totalTransactions,
    required this.tamperedTransactions,
  }) : isValid = false;

  ChainVerificationResult.empty()
      : isValid = true,
        totalTransactions = 0,
        tamperedTransactions = [];
}
```

#### 2.3.2 审计日志查看器

**UI设计:**

```
┌─────────────────────────────────────┐
│  哈希链完整性验证                ← │
├─────────────────────────────────────┤
│  账本：我们的小窝                    │
│  交易总数：1,234笔                   │
│  最后验证：2026/2/3 14:30           │
│                                     │
│  验证结果：✅ 完整                   │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━      │
│                                     │
│  哈希链可视化：                     │
│  ┌────────────────────────────┐    │
│  │ Genesis                     │    │
│  │   ↓                         │    │
│  │ tx-001 [✓]                  │    │
│  │ abc123def456789...          │    │
│  │   ↓                         │    │
│  │ tx-002 [✓]                  │    │
│  │ def456ghi789abc...          │    │
│  │   ↓                         │    │
│  │ tx-003 [✓]                  │    │
│  │ ghi789jkl012def...          │    │
│  │   ↓                         │    │
│  │ ...                         │    │
│  │   ↓                         │    │
│  │ tx-1234 [✓]                 │    │
│  │ xyz987uvw654pqr...          │    │
│  └────────────────────────────┘    │
│                                     │
│  [重新验证]                         │
│  [导出审计报告PDF]                  │
│                                     │
│  ⚠️ 如检测到篡改，哈希链会显示      │
│     红色警告，并标记受影响的记录     │
└─────────────────────────────────────┘
```

**篡改检测展示:**

```
┌─────────────────────────────────────┐
│  哈希链完整性验证                ← │
├─────────────────────────────────────┤
│  验证结果：❌ 检测到篡改             │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━      │
│                                     │
│  受影响的交易：                     │
│  ┌────────────────────────────┐    │
│  │ tx-042 [❌]                 │    │  ← 红色标记
│  │ 金额：¥5,000 → ¥500？      │    │
│  │ 哈希不匹配                  │    │
│  │ 预期：def456...             │    │
│  │ 实际：abc123...             │    │
│  │                             │    │
│  │ tx-043 [❌]                 │    │
│  │ 链式影响（后续全部失效）     │    │
│  └────────────────────────────┘    │
│                                     │
│  可能原因：                         │
│  • 数据库文件被直接修改             │
│  • 设备时间被调整                   │
│  • 恶意应用篡改                     │
│                                     │
│  建议操作：                         │
│  [查看详细日志]                     │
│  [恢复备份]                         │
│  [联系支持]                         │
└─────────────────────────────────────┘
```

#### 2.3.3 PDF审计报告

```dart
// lib/features/audit/use_cases/export_audit_report.dart

class ExportAuditReportUseCase {
  final HashChainService _hashChain;
  final TransactionRepository _transactionRepo;
  final KeyManager _keyManager;

  Future<File> execute(String bookId) async {
    // 1. 验证哈希链
    final verification = await _hashChain.verifyChain(bookId);

    // 2. 获取所有交易
    final transactions = await _transactionRepo.getTransactions(
      bookId: bookId,
      orderBy: 'timestamp ASC',
    );

    // 3. 生成PDF
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader(),
          pw.SizedBox(height: 20),
          _buildSummary(bookId, verification),
          pw.SizedBox(height: 20),
          _buildChainVisualization(transactions, verification),
          pw.SizedBox(height: 20),
          _buildSignature(),
        ],
      ),
    );

    // 4. 保存文件
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/audit_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  pw.Widget _buildHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Happy Pocket 審計報告',
          style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          '生成時間：${DateFormat('yyyy年MM月dd日 HH:mm').format(DateTime.now())}',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
        ),
      ],
    );
  }

  pw.Widget _buildSummary(String bookId, ChainVerificationResult verification) {
    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('帳簿情報', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('帳簿ID：'),
              pw.Text(bookId),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('総取引数：'),
              pw.Text('${verification.totalTransactions}筆'),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('検証状態：'),
              pw.Text(
                verification.isValid ? '✅ 完全' : '❌ 改ざん検出',
                style: pw.TextStyle(
                  color: verification.isValid ? PdfColors.green : PdfColors.red,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildChainVisualization(
    List<Transaction> transactions,
    ChainVerificationResult verification,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('完全ハッシュチェーン', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 12),
        ...transactions.take(50).map((tx) {
          final isTampered = verification.tamperedTransactions.contains(tx);
          return _buildTransactionRow(tx, isTampered);
        }),
        if (transactions.length > 50)
          pw.Text('... (${transactions.length - 50}筆省略)'),
      ],
    );
  }

  pw.Widget _buildTransactionRow(Transaction tx, bool isTampered) {
    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 8),
      padding: pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: isTampered ? PdfColors.red50 : PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '${DateFormat('yyyy/MM/dd HH:mm').format(tx.timestamp)}',
                style: pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                '¥${_formatAmount(tx.amount)}',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text('Hash: ${tx.currentHash.substring(0, 32)}...', style: pw.TextStyle(fontSize: 8)),
          pw.Text('PrevHash: ${tx.prevHash?.substring(0, 32) ?? 'genesis'}...', style: pw.TextStyle(fontSize: 8)),
          if (isTampered)
            pw.Text(
              '⚠️ 改ざん検出',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.red),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildSignature() async {
    final deviceId = await _keyManager.getDeviceId();
    final publicKey = await _keyManager.getPublicKey();

    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('署名情報', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.Divider(),
          pw.Text('本報告書は以下のデバイスにより生成されました：'),
          pw.SizedBox(height: 8),
          pw.Text('デバイスID: $deviceId', style: pw.TextStyle(fontSize: 10)),
          pw.Text('公開鍵指紋: ${_formatFingerprint(publicKey!)}', style: pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 8),
          pw.Text(
            '⚠️ このPDFは参照用です。改ざんの証明としてブロックチェーンエクスプローラーをご利用ください。',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          ),
        ],
      ),
    );
  }

  String _formatFingerprint(String publicKey) {
    final hash = sha256.convert(base64Decode(publicKey));
    final hex = hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
    return hex.toUpperCase().replaceAllMapped(
      RegExp(r'.{2}'),
      (match) => '${match.group(0)}:',
    ).substring(0, 59);  // AB:CD:EF:12:34:56:...
  }

  String _formatAmount(int amount) {
    final formatter = NumberFormat('#,###', 'ja_JP');
    return formatter.format(amount);
  }
}
```

---

### 2.4 E01: 隐私宣言引导

#### 2.4.1 三页引导设计

**第1页：隐私承诺**

```
┌─────────────────────────────────────┐
│                                     │
│           🔒                        │
│                                     │
│       あなたのデータは                │
│       あなただけのもの                │
│                                     │
│  • サーバーに保存されません         │
│  • 会社は見られません               │
│  • 端到端加密で保護                 │
│                                     │
│       ━━━━━━━━━━━━━━━━          │
│       我们永不:                      │
│       ❌ 上传你的数据到服务器        │
│       ❌ 出售你的财务信息            │
│       ❌ 追踪你的消费习惯            │
│                                     │
│              ○ ○ ○                │
│                                     │
│                          [次へ] →  │
└─────────────────────────────────────┘
```

**第2页：防篡改承诺**

```
┌─────────────────────────────────────┐
│                                     │
│           ⛓️                        │
│                                     │
│       改ざんできない記録              │
│                                     │
│  • ブロックチェーン技術を使用       │
│  • すべての記録が暗号化              │
│  • 誰も過去を変えられません         │
│                                     │
│       ━━━━━━━━━━━━━━━━          │
│       区块链式防篡改:                │
│       ✓ 每笔交易都有哈希签名         │
│       ✓ 任何修改都会被检测           │
│       ✓ 完整审计日志可导出           │
│                                     │
│              ○ ○ ○                │
│                                     │
│  [戻る] ←                [次へ] →  │
└─────────────────────────────────────┘
```

**第3页：开源承诺**

```
┌─────────────────────────────────────┐
│                                     │
│           👁️                        │
│                                     │
│       透明でオープンソース            │
│                                     │
│  • コードは完全公開                 │
│  • 誰でも検証できます               │
│  • コミュニティと一緒に             │
│                                     │
│       ━━━━━━━━━━━━━━━━          │
│       开源透明:                      │
│       ✓ 源代码完全公开               │
│       ✓ 安全专家可审计               │
│       ✓ 社区驱动开发                 │
│                                     │
│  GitHub: github.com/homepocket     │
│                                     │
│              ○ ○ ○                │
│                                     │
│  [戻る] ←              [始める] →  │
└─────────────────────────────────────┘
```

**实现代码:**

```dart
// lib/features/onboarding/presentation/privacy_onboarding_screen.dart

class PrivacyOnboardingScreen extends StatefulWidget {
  @override
  State<PrivacyOnboardingScreen> createState() => _PrivacyOnboardingScreenState();
}

class _PrivacyOnboardingScreenState extends State<PrivacyOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildPrivacyPage(),
                  _buildTamperproofPage(),
                  _buildOpenSourcePage(),
                ],
              ),
            ),
            _buildPageIndicator(),
            SizedBox(height: 20),
            _buildNavigationButtons(),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyPage() {
    return Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 100, color: Color(0xFF4A90D9)),
          SizedBox(height: 40),
          Text(
            'あなたのデータは\nあなただけのもの',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 40),
          _buildFeatureItem('サーバーに保存されません'),
          _buildFeatureItem('会社は見られません'),
          _buildFeatureItem('端到端加密で保護'),
          SizedBox(height: 40),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('我们永不:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                _buildNeverItem('上传你的数据到服务器'),
                _buildNeverItem('出售你的财务信息'),
                _buildNeverItem('追踪你的消费习惯'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildNeverItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.close, color: Colors.red, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index ? Color(0xFF4A90D9) : Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: () => _pageController.previousPage(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              child: Text('← 戻る'),
            )
          else
            SizedBox(width: 80),
          ElevatedButton(
            onPressed: _currentPage == 2 ? _onComplete : _onNext,
            child: Text(_currentPage == 2 ? '始める' : '次へ →'),
          ),
        ],
      ),
    );
  }

  void _onNext() {
    _pageController.nextPage(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onComplete() async {
    // 标记引导已完成
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('privacy_onboarding_completed', true);

    // 进入密钥生成页面
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/setup_keys');
  }
}
```

---

### 2.5 数据加密

#### 2.5.1 SQLCipher数据库加密

```dart
// lib/core/database/encrypted_database.dart

class EncryptedDatabase {
  late Database _database;
  final KeyManager _keyManager;

  /// 初始化加密数据库
  Future<void> initialize({String? password}) async {
    final dbPassword = password ?? await _keyManager.getDatabasePassword();

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'homepocket.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onOpen: (db) async {
        // 设置SQLCipher密钥
        await db.rawQuery('PRAGMA key = "$dbPassword"');

        // 验证密钥是否正确
        try {
          await db.rawQuery('SELECT count(*) FROM sqlite_master');
        } catch (e) {
          throw DatabasePasswordException('数据库密码错误');
        }

        // 性能优化设置
        await db.rawQuery('PRAGMA cipher_page_size = 4096');
        await db.rawQuery('PRAGMA kdf_iter = 256000');  // PBKDF2迭代次数
        await db.rawQuery('PRAGMA cipher_hmac_algorithm = HMAC_SHA512');
        await db.rawQuery('PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA512');
      },
    );
  }

  /// 生成数据库密码（从设备密钥派生）
  Future<String> generateDatabasePassword() async {
    final privateKey = await _keyManager.getPrivateKey();
    if (privateKey == null) {
      throw KeyNotFoundException('设备私钥未找到');
    }

    // 使用PBKDF2从私钥派生数据库密码
    final salt = utf8.encode('homepocket_db_salt');  // 固定盐值
    final derivedKey = await Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    ).deriveKey(
      secretKey: SecretKey(base64Decode(privateKey)),
      nonce: salt,
    );

    final keyBytes = await derivedKey.extractBytes();
    return base64Encode(keyBytes);
  }
}
```

#### 2.5.2 备注字段加密（ChaCha20-Poly1305）

```dart
// lib/core/security/encryption_service.dart

class EncryptionService {
  final KeyManager _keyManager;
  final ChaCha20 _chacha20 = ChaCha20.poly1305Aead();

  /// 加密备注字段
  Future<String> encrypt(String plaintext) async {
    // 1. 获取加密密钥
    final encryptionKey = await _getEncryptionKey();

    // 2. 生成随机nonce（12字节）
    final nonce = _generateNonce();

    // 3. 加密
    final secretBox = await _chacha20.encrypt(
      utf8.encode(plaintext),
      secretKey: encryptionKey,
      nonce: nonce,
    );

    // 4. 组合nonce + ciphertext + mac
    final combined = <int>[]
      ..addAll(nonce)
      ..addAll(secretBox.cipherText)
      ..addAll(secretBox.mac.bytes);

    // 5. Base64编码
    return base64Encode(combined);
  }

  /// 解密备注字段
  Future<String> decrypt(String ciphertext) async {
    // 1. Base64解码
    final combined = base64Decode(ciphertext);

    // 2. 分离nonce, ciphertext, mac
    final nonce = combined.sublist(0, 12);
    final ciphertextBytes = combined.sublist(12, combined.length - 16);
    final mac = Mac(combined.sublist(combined.length - 16));

    // 3. 获取加密密钥
    final encryptionKey = await _getEncryptionKey();

    // 4. 解密
    final secretBox = SecretBox(ciphertextBytes, nonce: nonce, mac: mac);
    final plaintext = await _chacha20.decrypt(
      secretBox,
      secretKey: encryptionKey,
    );

    return utf8.decode(plaintext);
  }

  /// 从设备密钥派生加密密钥
  Future<SecretKey> _getEncryptionKey() async {
    final privateKey = await _keyManager.getPrivateKey();
    if (privateKey == null) {
      throw KeyNotFoundException('设备私钥未找到');
    }

    // 使用HKDF从私钥派生加密密钥
    final hkdf = Hkdf(
      hmac: Hmac(Sha256()),
      outputLength: 32,  // 256位
    );

    final derivedKey = await hkdf.deriveKey(
      secretKey: SecretKey(base64Decode(privateKey)),
      info: utf8.encode('homepocket_note_encryption'),  // 上下文信息
      nonce: [],
    );

    return derivedKey;
  }

  List<int> _generateNonce() {
    final random = Random.secure();
    return List.generate(12, (_) => random.nextInt(256));
  }
}
```

---

## 3. 数据模型设计

### 3.1 安全相关表定义

```dart
// lib/core/database/tables.dart

@DataClassName('DeviceData')
class Devices extends Table {
  TextColumn get id => text()();  // 设备ID（公钥哈希）
  TextColumn get publicKey => text()();  // Ed25519公钥（Base64）
  TextColumn get name => text()();  // 设备昵称（如"我的iPhone"）
  IntColumn get createdAt => integer()();
  IntColumn get lastSeenAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RecoveryKitData')
class RecoveryKits extends Table {
  TextColumn get id => text()();
  TextColumn get deviceId => text()();
  TextColumn get mnemonicHash => text()();  // 助记词哈希（不存储明文！）
  BoolColumn get isVerified => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get verifiedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AuditLogData')
class AuditLogs extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text()();
  TextColumn get eventType => text()();  // 'chain_verified', 'tamper_detected', 'key_rotated'
  TextColumn get details => text().nullable()();  // JSON格式详细信息
  IntColumn get timestamp => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
```

### 3.2 实体关系图（ERD）

```
┌─────────────────┐
│   Devices       │
├─────────────────┤
│ id (PK)         │
│ publicKey       │──┐
│ name            │  │
└─────────────────┘  │
                     │  关联
                     ↓
          ┌──────────────────┐
          │ RecoveryKits     │
          ├──────────────────┤
          │ deviceId (FK)    │
          │ mnemonicHash     │
          └──────────────────┘

┌─────────────────┐
│ Transactions    │
├─────────────────┤
│ id (PK)         │
│ prevHash        │  ← 哈希链
│ currentHash     │
└─────────────────┘
         ↓
   ┌──────────────────┐
   │ AuditLogs        │
   ├──────────────────┤
   │ eventType        │
   │ details          │  ← 记录验证结果
   └──────────────────┘
```

---

## 4. UI/UX设计

### 4.1 设置页面（安全选项）

```
┌─────────────────────────────────────┐
│ ← 设置                              │
├─────────────────────────────────────┤
│  [用户头像]                         │
│  太郎                               │
│  taro@example.com                   │
│                                     │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━      │
│  安全与隐私                         │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━      │
│                                     │
│  🔒 生物识别锁                      │
│  [Face ID                     ✓]   │  ← 开关
│                                     │
│  🔑 Recovery Kit                   │
│  [查看备份] [验证备份]              │
│                                     │
│  ⛓️ 哈希链审计                      │
│  [验证完整性] [导出报告]            │
│                                     │
│  🔐 密钥管理                        │
│  设备ID: abc123def456               │
│  公钥指纹: AB:CD:EF:12:34:56       │
│  [查看详情]                         │
│                                     │
│  📄 隐私政策                        │
│  [查看完整政策]                     │
│                                     │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━      │
│  数据管理                           │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━      │
│                                     │
│  💾 本地数据                        │
│  数据库大小: 2.3 MB                 │
│  交易数量: 1,234笔                  │
│  [清除缓存]                         │
│                                     │
│  🗑️ 删除所有数据                   │
│  [永久删除（不可恢复）]             │
│                                     │
└─────────────────────────────────────┘
```

---

## 5. 技术实现方案

### 5.1 状态管理（Riverpod）

```dart
// lib/core/security/providers/security_providers.dart

final keyManagerProvider = Provider<KeyManager>((ref) {
  return KeyManager(
    secureStorage: ref.read(secureStorageProvider),
  );
});

final biometricLockProvider = Provider<BiometricLock>((ref) {
  return BiometricLock();
});

final hashChainServiceProvider = Provider<HashChainService>((ref) {
  return HashChainService(
    keyManager: ref.read(keyManagerProvider),
    transactionRepo: ref.read(transactionRepositoryProvider),
  );
});

final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService(
    keyManager: ref.read(keyManagerProvider),
  );
});

// 检查是否已设置密钥
final hasKeyPairProvider = FutureProvider<bool>((ref) async {
  final keyManager = ref.read(keyManagerProvider);
  return await keyManager.hasKeyPair();
});

// 哈希链验证结果
final chainVerificationProvider = FutureProvider.family<ChainVerificationResult, String>(
  (ref, bookId) async {
    final hashChain = ref.read(hashChainServiceProvider);
    return await hashChain.verifyChain(bookId);
  },
);
```

### 5.2 第三方库依赖

```yaml
# pubspec.yaml

dependencies:
  # 加密库
  cryptography: ^2.7.0
  pointycastle: ^3.9.1  # Ed25519等算法

  # 安全存储
  flutter_secure_storage: ^9.2.2

  # BIP39助记词
  bip39: ^1.0.6

  # 生物识别
  local_auth: ^2.3.0
  local_auth_android: ^1.0.47
  local_auth_ios: ^1.2.1

  # SQLCipher
  sqflite_sqlcipher: ^3.1.0

  # PDF生成
  pdf: ^3.11.1
  printing: ^5.13.2

  # 状态管理
  flutter_riverpod: ^2.5.1
```

---

## 6. 验收标准

### 6.1 功能完整性

- ✅ 密钥生成成功率100%
- ✅ Recovery Kit 24个单词正确显示
- ✅ Recovery Kit备份验证成功率100%
- ✅ Recovery Kit恢复功能正常
- ✅ 生物识别认证成功率>98%（在支持设备上）
- ✅ PIN码备用方案可用
- ✅ 哈希链验证时间<1秒（1000条记录）
- ✅ 篡改检测灵敏度100%（修改任何字段都能检测）
- ✅ 审计报告PDF导出成功
- ✅ 隐私宣言引导完成率>95%
- ✅ 数据库加密/解密功能正常
- ✅ 备注字段加密/解密功能正常

### 6.2 性能指标

| 指标 | 目标 | 测试方法 |
|------|------|---------|
| 密钥生成时间 | <2s | 首次启动计时 |
| 生物识别响应时间 | <1s | 从触发到结果 |
| 哈希链验证时间 | <1s | 1000条交易 |
| 数据库解密时间 | <500ms | 应用启动计时 |
| 备注加密时间 | <10ms | 单条备注 |
| PDF导出时间 | <5s | 1000条交易 |

### 6.3 安全指标

- ✅ 私钥永不离开安全存储
- ✅ 数据库密码永不明文存储
- ✅ 备注明文永不存储在数据库
- ✅ Recovery Kit助记词永不存储（仅存储哈希）
- ✅ 哈希算法使用SHA-256
- ✅ 加密算法使用ChaCha20-Poly1305或Ed25519
- ✅ 密钥派生使用PBKDF2（迭代次数≥100,000）

---

## 7. 测试用例

### 7.1 单元测试

```dart
// test/core/security/key_manager_test.dart

void main() {
  group('KeyManager', () {
    late KeyManager keyManager;
    late MockSecureStorage mockSecureStorage;

    setUp(() {
      mockSecureStorage = MockSecureStorage();
      keyManager = KeyManager(secureStorage: mockSecureStorage);
    });

    test('should generate valid Ed25519 key pair', () async {
      // When
      final keyPair = await keyManager.generateDeviceKeyPair();

      // Then
      expect(keyPair.publicKey, isNotEmpty);
      expect(keyPair.deviceId, isNotEmpty);
      expect(keyPair.deviceId.length, 16);

      // Verify stored in secure storage
      verify(mockSecureStorage.write(
        key: 'device_private_key',
        value: any,
      ));
    });

    test('should recover key pair from valid mnemonic', () async {
      // Given
      final mnemonic = 'abandon abandon abandon abandon abandon abandon '
                       'abandon abandon abandon abandon abandon about';

      // When
      final keyPair = await keyManager.recoverFromMnemonic(mnemonic);

      // Then
      expect(keyPair.publicKey, isNotEmpty);
      expect(keyPair.deviceId, isNotEmpty);
    });

    test('should throw exception for invalid mnemonic', () async {
      // Given
      final invalidMnemonic = 'invalid mnemonic words';

      // When & Then
      expect(
        () => keyManager.recoverFromMnemonic(invalidMnemonic),
        throwsA(isA<InvalidMnemonicException>()),
      );
    });

    test('should sign and verify data correctly', () async {
      // Given
      await keyManager.generateDeviceKeyPair();
      final data = utf8.encode('test transaction data');

      // When
      final signature = await keyManager.signData(data);
      final publicKey = await keyManager.getPublicKey();
      final isValid = await keyManager.verifySignature(
        data: data,
        signature: signature,
        publicKeyBase64: publicKey!,
      );

      // Then
      expect(isValid, isTrue);
    });

    test('should detect tampered data', () async {
      // Given
      await keyManager.generateDeviceKeyPair();
      final data = utf8.encode('original data');
      final tamperedData = utf8.encode('tampered data');
      final signature = await keyManager.signData(data);
      final publicKey = await keyManager.getPublicKey();

      // When
      final isValid = await keyManager.verifySignature(
        data: tamperedData,
        signature: signature,
        publicKeyBase64: publicKey!,
      );

      // Then
      expect(isValid, isFalse);
    });
  });

  group('RecoveryKitService', () {
    late RecoveryKitService service;

    setUp(() {
      service = RecoveryKitService();
    });

    test('should generate 24-word mnemonic', () async {
      // When
      final mnemonic = await service.generateRecoveryKit();

      // Then
      final words = mnemonic.split(' ');
      expect(words.length, 24);
      expect(bip39.validateMnemonic(mnemonic), isTrue);
    });

    test('should verify correct recovery kit', () async {
      // Given
      final mnemonic = await service.generateRecoveryKit();

      // When
      final isValid = await service.verifyRecoveryKit(mnemonic);

      // Then
      expect(isValid, isTrue);
    });

    test('should reject incorrect recovery kit', () async {
      // Given
      await service.generateRecoveryKit();
      final wrongMnemonic = 'abandon abandon abandon abandon abandon abandon '
                            'abandon abandon abandon abandon abandon about';

      // When
      final isValid = await service.verifyRecoveryKit(wrongMnemonic);

      // Then
      expect(isValid, isFalse);
    });
  });

  group('HashChainService', () {
    late HashChainService hashChain;
    late MockTransactionRepository mockRepo;

    setUp(() {
      mockRepo = MockTransactionRepository();
      hashChain = HashChainService(
        keyManager: KeyManager(secureStorage: MockSecureStorage()),
        transactionRepo: mockRepo,
      );
    });

    test('should calculate consistent hash for same transaction', () async {
      // Given
      final tx = Transaction(
        id: 'tx-001',
        bookId: 'book-001',
        deviceId: 'device-001',
        amount: 1280,
        type: TransactionType.expense,
        categoryId: 'food',
        ledgerType: LedgerType.soul,
        timestamp: DateTime(2026, 2, 3, 14, 30),
        prevHash: 'genesis',
        currentHash: '',
        createdAt: DateTime.now(),
      );

      // When
      final hash1 = await hashChain.calculateHash(tx);
      final hash2 = await hashChain.calculateHash(tx);

      // Then
      expect(hash1, hash2);
    });

    test('should verify valid chain', () async {
      // Given
      final transactions = [
        Transaction(
          id: 'tx-001',
          prevHash: 'genesis',
          currentHash: await hashChain.calculateHash(/* tx-001 */),
          // ... other fields
        ),
        Transaction(
          id: 'tx-002',
          prevHash: 'abc123',  // hash of tx-001
          currentHash: await hashChain.calculateHash(/* tx-002 */),
          // ... other fields
        ),
      ];
      when(mockRepo.getTransactions(any)).thenAnswer((_) async => transactions);

      // When
      final result = await hashChain.verifyChain('book-001');

      // Then
      expect(result.isValid, isTrue);
      expect(result.tamperedTransactions, isEmpty);
    });

    test('should detect tampered transaction', () async {
      // Given
      final validHash = 'abc123def456';
      final tamperedHash = 'xyz987uvw654';  // Wrong hash!

      final transactions = [
        Transaction(
          id: 'tx-001',
          amount: 1280,  // Original
          prevHash: 'genesis',
          currentHash: validHash,
          // ...
        ),
        Transaction(
          id: 'tx-002',
          amount: 500,  // Tampered! (was 5000)
          prevHash: validHash,
          currentHash: tamperedHash,  // Hash doesn't match!
          // ...
        ),
      ];
      when(mockRepo.getTransactions(any)).thenAnswer((_) async => transactions);

      // When
      final result = await hashChain.verifyChain('book-001');

      // Then
      expect(result.isValid, isFalse);
      expect(result.tamperedTransactions.length, 1);
      expect(result.tamperedTransactions.first.id, 'tx-002');
    });
  });
}
```

### 7.2 Widget测试

```dart
// test/features/auth/presentation/biometric_lock_screen_test.dart

void main() {
  testWidgets('should authenticate successfully', (tester) async {
    // Given
    final mockBiometricLock = MockBiometricLock();
    when(mockBiometricLock.authenticate(any))
        .thenAnswer((_) async => AuthResult.success());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          biometricLockProvider.overrideWithValue(mockBiometricLock),
        ],
        child: MaterialApp(home: BiometricLockScreen()),
      ),
    );

    // When
    await tester.pumpAndSettle();

    // Then
    verify(mockBiometricLock.authenticate(
      reason: 'Happy Pocketを開くには認証が必要です',
    ));
  });

  testWidgets('should show PIN dialog after failed attempts', (tester) async {
    // Given
    final mockBiometricLock = MockBiometricLock();
    when(mockBiometricLock.authenticate(any))
        .thenAnswer((_) async => AuthResult.tooManyAttempts());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          biometricLockProvider.overrideWithValue(mockBiometricLock),
        ],
        child: MaterialApp(home: BiometricLockScreen()),
      ),
    );

    // When
    await tester.pumpAndSettle();

    // Then
    expect(find.text('PINコードを入力'), findsOneWidget);
  });
}
```

### 7.3 集成测试

```dart
// integration_test/security_flow_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('complete security setup flow', (tester) async {
    // Given - first launch
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();

    // Then - should show privacy onboarding
    expect(find.text('あなたのデータは\nあなただけのもの'), findsOneWidget);

    // When - navigate through onboarding
    await tester.tap(find.text('次へ →'));
    await tester.pumpAndSettle();

    expect(find.text('改ざんできない記録'), findsOneWidget);

    await tester.tap(find.text('次へ →'));
    await tester.pumpAndSettle();

    expect(find.text('透明でオープンソース'), findsOneWidget);

    // When - complete onboarding
    await tester.tap(find.text('始める'));
    await tester.pumpAndSettle();

    // Then - should show recovery kit backup screen
    expect(find.text('Recovery Kit 備份'), findsOneWidget);
    expect(find.textContaining('1.'), findsWidgets);  // Mnemonic words

    // When - export to PDF
    await tester.tap(find.text('保存為PDF'));
    await tester.pumpAndSettle();

    // TODO: verify PDF file created

    // When - check all confirmations
    await tester.tap(find.byType(Checkbox).at(0));
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.tap(find.byType(Checkbox).at(2));
    await tester.pumpAndSettle();

    // When - proceed to verification
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();

    // Then - should show verification screen
    expect(find.text('驗證 Recovery Kit'), findsOneWidget);

    // TODO: input correct words and verify
  });

  testWidgets('hash chain verification', (tester) async {
    // Given - app with transactions
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();

    // Navigate to settings
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // When - tap on hash chain audit
    await tester.tap(find.text('驗證完整性'));
    await tester.pumpAndSettle();

    // Then - should show verification result
    expect(find.text('✅ 完整'), findsOneWidget);

    // When - export audit report
    await tester.tap(find.text('導出審計報告PDF'));
    await tester.pumpAndSettle();

    // TODO: verify PDF file created
  });
}
```

---

## 8. 开发里程碑

### 8.1 详细任务拆解（10天）

| Day | 任务 | 产出 | 风险 |
|-----|------|------|------|
| **Day 1** | 密钥管理基础 | - KeyManager实现<br>- Ed25519密钥生成<br>- 安全存储集成 | 中（加密库兼容性）|
| **Day 2** | Recovery Kit | - BIP39助记词生成<br>- 验证机制<br>- PDF导出 | 低 |
| **Day 3** | 生物识别锁 | - BiometricLock实现<br>- local_auth集成<br>- PIN备用方案 | 中（平台差异）|
| **Day 4** | 数据库加密 | - SQLCipher集成<br>- 密钥派生<br>- 性能测试 | 高（性能问题）|
| **Day 5** | 备注字段加密 | - EncryptionService<br>- ChaCha20-Poly1305<br>- 加解密测试 | 低 |
| **Day 6** | 哈希链基础 | - HashChainService<br>- 哈希计算<br>- 链式验证 | 中（算法正确性）|
| **Day 7** | 哈希链UI | - 审计查看器<br>- PDF报告生成<br>- 篡改检测展示 | 低 |
| **Day 8** | 隐私引导UI | - 三页引导页面<br>- 动画效果<br>- 流程集成 | 低 |
| **Day 9** | 集成测试 | - 端到端测试<br>- 安全审计<br>- 性能优化 | 高（集成问题）|
| **Day 10** | 文档与优化 | - API文档<br>- 用户手册<br>- Bug修复 | 低 |

### 8.2 关键路径识别

```
Day 1 (密钥管理)
    ↓
Day 2 (Recovery Kit) ──┐
                       ├──► Day 4 (数据库加密)
Day 3 (生物识别) ──────┘         ↓
                               Day 5 (备注加密)
                                 ↓
Day 6 (哈希链基础) ──────────────┤
    ↓                            ↓
Day 7 (哈希链UI)                 │
    ↓                            ↓
Day 8 (隐私引导) ────────────────┤
    ↓                            ↓
Day 9-10 (测试与优化)
```

**关键路径:** Day 1 → Day 4 → Day 5 → Day 9
**最大风险:** SQLCipher性能问题可能导致应用启动缓慢

### 8.3 风险与缓解措施

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|---------|
| SQLCipher性能差 | 中 | 高 | 提前性能测试,准备降级方案（仅加密敏感字段）|
| 平台生物识别差异 | 中 | 中 | 完善的PIN备用方案,充分测试 |
| 密钥恢复失败率高 | 低 | 高 | 多重验证机制,提供社交恢复选项（V1.0）|
| 哈希链验证慢 | 低 | 中 | 增量验证,后台异步执行 |

---

## 9. 附录

### 9.1 相关文档链接

- [PRD_Module_BasicAccounting.md](/Users/xinz/Development/ThinkCenter/claudedocs/PRD_Module_BasicAccounting.md)
- [research_home_pocket_feasibility_strategy_20260202_CN.md](/Users/xinz/Development/ThinkCenter/claudedocs/research_home_pocket_feasibility_strategy_20260202_CN.md)

### 9.2 技术参考资料

**加密库:**
- [cryptography (Dart)](https://pub.dev/packages/cryptography)
- [Ed25519签名算法](https://ed25519.cr.yp.to/)
- [ChaCha20-Poly1305规范](https://tools.ietf.org/html/rfc8439)

**SQLCipher:**
- [SQLCipher文档](https://www.zetetic.net/sqlcipher/documentation/)
- [sqflite_sqlcipher](https://pub.dev/packages/sqflite_sqlcipher)

**BIP39:**
- [BIP39规范](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki)
- [bip39 (Dart)](https://pub.dev/packages/bip39)

**生物识别:**
- [local_auth](https://pub.dev/packages/local_auth)
- [iOS Local Authentication](https://developer.apple.com/documentation/localauthentication)
- [Android BiometricPrompt](https://developer.android.com/training/sign-in/biometric-auth)

### 9.3 设计决策记录

**决策001: 为什么选择Ed25519而非RSA?**
- 日期: 2026-02-03
- 原因: 性能更好（签名验证快10倍）,密钥更短（32字节公钥 vs 2048位RSA）
- 参考: [Ed25519性能对比](https://ed25519.cr.yp.to/)

**决策002: 为什么不使用云备份Recovery Kit?**
- 日期: 2026-02-03
- 原因: 隐私承诺（不上传数据到服务器）,用户可选择自己的备份方式（PDF/打印）
- 替代方案: V1.0提供加密云备份选项（需用户额外密码）

**决策003: 为什么使用BIP39而非自定义助记词?**
- 日期: 2026-02-03
- 原因: 行业标准,用户熟悉度高（加密货币用户）,校验和防错
- 影响: 需要依赖bip39库

**决策004: 为什么哈希链不使用数字签名?**
- 日期: 2026-02-03
- 原因: MVP阶段简化实现,SHA-256已足够防篡改
- V1.0优化: 添加Ed25519签名增强安全性

---

**文档状态:** 完成
**审核状态:** 待评审
**需要评审:** 产品经理、安全工程师、技术负责人

**变更日志:**
- 2026-02-03: 初版完成（基于框架文档和可行性研究）
