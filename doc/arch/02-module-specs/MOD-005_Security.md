# MOD-006: 安全与隐私 - 技术设计文档

**模块编号:** MOD-006
**模块名称:** 安全与隐私
**文档版本:** 2.0
**创建日期:** 2026-02-03
**预估工时:** 10天
**优先级:** P0（MVP核心功能）
**依赖项:** 无(基础模块)

---

## 📋 目录

1. [模块概述](#模块概述)
2. [业务价值](#业务价值)
3. [核心功能](#核心功能)
4. [功能需求](#功能需求)
5. [技术设计](#技术设计)
6. [数据模型](#数据模型)
7. [核心实现流程](#核心实现流程)
8. [UI组件设计](#ui组件设计)
9. [测试策略](#测试策略)
10. [性能优化](#性能优化)

---

## 模块概述

### 业务价值

安全与隐私模块是Home Pocket的核心竞争优势,实现完整的端到端加密(E2EE)和防篡改机制:

- **密钥管理 (E02):** Ed25519密钥对生成、恢复套件备份、密钥恢复
- **生物识别锁 (E03):** Face ID/Touch ID/指纹认证
- **哈希链审计 (D03):** 区块链式防篡改检测、可导出审计报告
- **隐私引导 (E01):** 三页隐私承诺指南
- **数据加密:** SQLCipher数据库加密、备注字段加密、照片加密

**价值主张:**
在隐私泄露时代,Home Pocket通过开源代码、E2EE架构和哈希链审计,承诺"您的数据仅属于您"。

### 架构位置

```
┌─────────────────────────────────────────────────┐
│           表现层                                 │
│  ┌──────────────┐  ┌──────────────────────┐    │
│  │ 隐私引导     │  │  生物识别锁界面      │    │
│  └──────────────┘  └──────────────────────┘    │
│  ┌──────────────┐  ┌──────────────────────┐    │
│  │ 恢复套件     │  │  哈希链查看器        │    │
│  │ 界面         │  │                      │    │
│  └──────────────┘  └──────────────────────┘    │
└─────────────────────────────────────────────────┘
                     ↓↑
┌─────────────────────────────────────────────────┐
│           业务逻辑层                             │
│  ┌──────────────┐  ┌──────────────────────┐    │
│  │ 密钥管理器   │  │  生物识别锁服务      │    │
│  │ (Ed25519)    │  │                      │    │
│  └──────────────┘  └──────────────────────┘    │
│  ┌──────────────┐  ┌──────────────────────┐    │
│  │ 哈希链服务   │  │  加密服务            │    │
│  │              │  │  (ChaCha20-Poly1305) │    │
│  └──────────────┘  └──────────────────────┘    │
└─────────────────────────────────────────────────┘
                     ↓↑
┌─────────────────────────────────────────────────┐
│            数据层                                │
│  ┌──────────────┐  ┌──────────────────────┐    │
│  │ 安全存储     │  │  加密数据库          │    │
│  │ (Keychain)   │  │  (SQLCipher)         │    │
│  └──────────────┘  └──────────────────────┘    │
└─────────────────────────────────────────────────┘
```

---

## 业务价值

### 用户痛点

**目标用户:** 佐藤太郎(38岁,IT工程师),隐私意识强

**痛点:**
1. **隐私焦虑:** "我的收入和消费习惯会被公司看到吗?"
2. **数据泄露风险:** "如果服务器被黑,我的财务信息会被盗吗?"
3. **篡改担忧:** "我的伴侣能偷偷删除他们的消费记录吗?"
4. **设备丢失恐慌:** "如果我丢了手机,所有记账数据都没了?"

**解决方案:**
- 本地优先架构,无服务器上传
- 端到端加密,无法被截获
- 区块链式哈希链检测任何篡改
- 恢复套件备份支持助记词恢复

### 成功指标

| 指标 | 目标 | 测量方式 |
|------|------|----------|
| 密钥生成成功率 | 100% | 首次启动完成率 |
| 恢复套件验证成功 | 100% | 恢复测试通过率 |
| 生物识别认证成功率 | >98% | 支持设备上 |
| 哈希链验证时间 | <1s | 1000条交易 |
| 篡改检测灵敏度 | 100% | 检测到任何字段修改 |

---

## 核心功能

### 功能矩阵

| 功能ID | 功能名称 | 优先级 | 复杂度 |
|--------|----------|--------|--------|
| E02 | 密钥管理(Ed25519) | P0 | 高 |
| E02-RK | 恢复套件(24词) | P0 | 中 |
| E03 | 生物识别锁 | P0 | 中 |
| E03-PIN | PIN备选 | P0 | 低 |
| D03 | 哈希链审计 | P0 | 高 |
| D03-PDF | 审计报告导出 | P1 | 中 |
| E01 | 隐私引导 | P0 | 低 |
| ENC-01 | 数据库加密 | P0 | 高 |
| ENC-02 | 备注字段加密 | P0 | 中 |

---

## 功能需求

### 用户故事

**作为** 注重隐私的用户
**我希望** 在不上传到服务器的情况下生成设备密钥
**以便** 我的财务数据保持私密且在我的控制之下

**验收标准:**
- 首次启动时生成Ed25519密钥对
- 私钥存储在iOS Keychain / Android Keystore
- 公钥派生设备ID
- 密钥永不离开安全存储

---

## 技术设计

### 密钥管理架构

**为什么选择Ed25519?**
- 性能: 比RSA快10倍
- 紧凑: 32字节公钥 vs 2048位RSA
- 安全: 128位安全级别
- Flutter原生支持: `pointycastle`库

**密钥生成流程:**

```
首次启动
    ↓
生成Ed25519密钥对
    ↓
存储私钥 → iOS Keychain / Android Keystore
存储公钥 → 安全存储(可以是明文)
    ↓
生成设备ID ← SHA-256(public_key)[0:16]
    ↓
显示恢复套件(24词)
    ↓
用户验证(3个随机词)
    ↓
设置完成
```

---

## 数据模型

### Drift表定义

```dart
// lib/features/security/data/datasources/local/tables.dart

import 'package:drift/drift.dart';

@DataClassName('DeviceData')
class Devices extends Table {
  TextColumn get id => text()();  // 设备ID(公钥哈希)
  TextColumn get publicKey => text()();  // Ed25519公钥(Base64)
  TextColumn get name => text()();  // 设备昵称
  IntColumn get createdAt => integer()();
  IntColumn get lastSeenAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RecoveryKitData')
class RecoveryKits extends Table {
  TextColumn get id => text()();
  TextColumn get deviceId => text().references(Devices, #id)();
  TextColumn get mnemonicHash => text()();  // 仅哈希,绝不明文!
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
  TextColumn get details => text().nullable()();  // JSON详情
  IntColumn get timestamp => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
```

### 领域模型

```dart
// lib/features/security/domain/models/device_key_pair.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_key_pair.freezed.dart';

@freezed
class DeviceKeyPair with _$DeviceKeyPair {
  const factory DeviceKeyPair({
    required String publicKey,  // Base64编码
    required String deviceId,   // SHA-256哈希前16字符
    required DateTime createdAt,
  }) = _DeviceKeyPair;
}
```

```dart
// lib/features/security/domain/models/chain_verification_result.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'chain_verification_result.freezed.dart';

@freezed
class ChainVerificationResult with _$ChainVerificationResult {
  const factory ChainVerificationResult({
    required bool isValid,
    required int totalTransactions,
    required List<String> tamperedTransactionIds,
  }) = _ChainVerificationResult;

  factory ChainVerificationResult.valid({
    required int totalTransactions,
  }) = _ValidChainResult;

  factory ChainVerificationResult.tampered({
    required int totalTransactions,
    required List<String> tamperedTransactionIds,
  }) = _TamperedChainResult;

  factory ChainVerificationResult.empty() = _EmptyChainResult;
}
```

```dart
// lib/features/security/domain/models/auth_result.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_result.freezed.dart';

enum AuthStatus {
  success,
  failed,
  fallbackToPIN,
  tooManyAttempts,
  lockedOut,
  error,
}

@freezed
class AuthResult with _$AuthResult {
  const factory AuthResult({
    required AuthStatus status,
    String? message,
    int? failedAttempts,
  }) = _AuthResult;

  factory AuthResult.success() = _SuccessAuthResult;
  factory AuthResult.failed(int attempts) = _FailedAuthResult;
  factory AuthResult.fallbackToPIN() = _FallbackAuthResult;
  factory AuthResult.tooManyAttempts() = _TooManyAttemptsAuthResult;
  factory AuthResult.lockedOut() = _LockedOutAuthResult;
  factory AuthResult.error(String message) = _ErrorAuthResult;
}
```

---

## 核心实现流程

### 1. 密钥管理器实现

```dart
// lib/features/security/application/services/key_manager.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/device_key_pair.dart';

part 'key_manager.g.dart';

class KeyManager {
  final FlutterSecureStorage _secureStorage;
  final Ed25519 _ed25519 = Ed25519();

  KeyManager({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage;

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
      iOptions: const IOSOptions(
        accessibility: KeychainAccessibility.whenUnlockedThisDeviceOnly,
      ),
      aOptions: const AndroidOptions(
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
    if (!_validateMnemonic(mnemonic)) {
      throw InvalidMnemonicException('助记词格式错误');
    }

    // 2. 从助记词派生种子（512位）
    final seed = _mnemonicToSeed(mnemonic);

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

  /// 助记词验证（简化版BIP39）
  bool _validateMnemonic(String mnemonic) {
    final words = mnemonic.trim().split(' ');
    return words.length == 24;
  }

  /// 助记词转种子（简化版BIP39）
  Uint8List _mnemonicToSeed(String mnemonic) {
    // 实际实现应使用bip39包
    final bytes = utf8.encode(mnemonic);
    final hash = sha512.convert(bytes);
    return Uint8List.fromList(hash.bytes);
  }
}

// 异常类
class InvalidMnemonicException implements Exception {
  final String message;
  InvalidMnemonicException(this.message);
}

class KeyNotFoundException implements Exception {
  final String message;
  KeyNotFoundException(this.message);
}

// Provider
@riverpod
KeyManager keyManager(KeyManagerRef ref) {
  return KeyManager(
    secureStorage: const FlutterSecureStorage(),
  );
}

@riverpod
Future<bool> hasKeyPair(HasKeyPairRef ref) async {
  final keyManager = ref.watch(keyManagerProvider);
  return await keyManager.hasKeyPair();
}
```

### 2. 恢复套件服务实现

```dart
// lib/features/security/application/services/recovery_kit_service.dart

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'key_manager.dart';

part 'recovery_kit_service.g.dart';

class RecoveryKitService {
  final FlutterSecureStorage _secureStorage;
  final KeyManager _keyManager;

  // BIP39 词表（简化版，实际应使用完整的2048词）
  static const List<String> _wordList = [
    'abandon', 'ability', 'able', 'about', 'above', 'absent', 'absorb', 'abstract',
    'absurd', 'abuse', 'access', 'accident', 'account', 'accuse', 'achieve', 'acid',
    // ... 完整的BIP39词表应有2048个词
  ];

  RecoveryKitService({
    required FlutterSecureStorage secureStorage,
    required KeyManager keyManager,
  })  : _secureStorage = secureStorage,
        _keyManager = keyManager;

  /// 生成Recovery Kit（24个助记词）
  Future<String> generateRecoveryKit() async {
    // 1. 生成256位随机熵
    final random = Random.secure();
    final entropy = List<int>.generate(32, (_) => random.nextInt(256));

    // 2. 转换为助记词（24个单词）
    final mnemonic = _entropyToMnemonic(entropy);

    // 3. 存储到安全存储（用于后续验证）
    await _secureStorage.write(
      key: 'recovery_kit_hash',
      value: sha256.convert(utf8.encode(mnemonic)).toString(),
    );

    return mnemonic;
  }

  /// 验证用户输入的Recovery Kit
  Future<bool> verifyRecoveryKit(String userInput) async {
    // 1. 验证格式
    final words = userInput.trim().split(' ');
    if (words.length != 24) {
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
    final deviceId = await _keyManager.getDeviceId();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Home Pocket Recovery Kit',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                '⚠️ 请安全保存此文件,丢失将无法恢复数据',
                style: const pw.TextStyle(fontSize: 14, color: PdfColors.red),
              ),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text('您的24个助记词:', style: const pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 12),
              _buildMnemonicGrid(mnemonic),
              pw.SizedBox(height: 40),
              pw.Text('生成日期: ${DateTime.now().toString().substring(0, 19)}'),
              pw.SizedBox(height: 12),
              pw.Text('设备ID: $deviceId'),
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
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Text(
            '${index + 1}. ${words[index]}',
            style: const pw.TextStyle(fontSize: 12),
          ),
        );
      }),
    );
  }

  /// 熵转助记词（简化版BIP39）
  String _entropyToMnemonic(List<int> entropy) {
    // 实际实现应使用完整的BIP39算法
    final random = Random(entropy.reduce((a, b) => a ^ b));
    return List.generate(24, (_) => _wordList[random.nextInt(_wordList.length)])
        .join(' ');
  }
}

@riverpod
RecoveryKitService recoveryKitService(RecoveryKitServiceRef ref) {
  return RecoveryKitService(
    secureStorage: const FlutterSecureStorage(),
    keyManager: ref.watch(keyManagerProvider),
  );
}
```

### 3. 生物识别锁实现

```dart
// lib/features/security/application/services/biometric_lock.dart

import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_ios/local_auth_ios.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/auth_result.dart';

part 'biometric_lock.g.dart';

enum BiometricAvailability {
  faceId,
  fingerprint,
  generic,
  notEnrolled,
  notSupported,
}

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
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Home Pocket 認証',
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
          stickyAuth: true, // 防止应用切换到后台时取消认证
          biometricOnly: !allowPINFallback, // 是否允许PIN备用
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

@riverpod
BiometricLock biometricLock(BiometricLockRef ref) {
  return BiometricLock();
}

@riverpod
Future<BiometricAvailability> biometricAvailability(
  BiometricAvailabilityRef ref,
) async {
  final biometricLock = ref.watch(biometricLockProvider);
  return await biometricLock.checkAvailability();
}
```

### 4. 哈希链服务实现

```dart
// lib/features/security/application/services/hash_chain_service.dart

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../transaction/domain/models/transaction.dart';
import '../../../transaction/domain/repositories/transaction_repository.dart';
import '../../domain/models/chain_verification_result.dart';
import 'key_manager.dart';

part 'hash_chain_service.g.dart';

class HashChainService {
  final KeyManager _keyManager;
  final TransactionRepository _transactionRepo;

  HashChainService({
    required KeyManager keyManager,
    required TransactionRepository transactionRepo,
  })  : _keyManager = keyManager,
        _transactionRepo = transactionRepo;

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
    final transactions = await _transactionRepo.getTransactionsByBook(
      bookId: bookId,
      orderBy: 'timestamp ASC',
    );

    if (transactions.isEmpty) {
      return ChainVerificationResult.empty();
    }

    String prevHash = 'genesis';
    final tamperedTransactionIds = <String>[];

    for (var i = 0; i < transactions.length; i++) {
      final tx = transactions[i];

      // 1. 验证prevHash是否正确
      if (tx.prevHash != prevHash) {
        tamperedTransactionIds.add(tx.id);
        continue;
      }

      // 2. 重新计算哈希并比对
      final expectedHash = await calculateHash(
        tx.copyWith(prevHash: prevHash),
      );

      if (tx.currentHash != expectedHash) {
        tamperedTransactionIds.add(tx.id);
      }

      prevHash = tx.currentHash;
    }

    if (tamperedTransactionIds.isEmpty) {
      return ChainVerificationResult.valid(
        totalTransactions: transactions.length,
      );
    } else {
      return ChainVerificationResult.tampered(
        totalTransactions: transactions.length,
        tamperedTransactionIds: tamperedTransactionIds,
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

@riverpod
HashChainService hashChainService(HashChainServiceRef ref) {
  return HashChainService(
    keyManager: ref.watch(keyManagerProvider),
    transactionRepo: ref.watch(transactionRepositoryProvider),
  );
}

@riverpod
Future<ChainVerificationResult> chainVerification(
  ChainVerificationRef ref,
  String bookId,
) async {
  final hashChain = ref.watch(hashChainServiceProvider);
  return await hashChain.verifyChain(bookId);
}
```

### 5. 加密服务实现

```dart
// lib/features/security/application/services/encryption_service.dart

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'key_manager.dart';

part 'encryption_service.g.dart';

class EncryptionService {
  final KeyManager _keyManager;
  final ChaCha20 _chacha20 = ChaCha20.poly1305Aead();

  EncryptionService({required KeyManager keyManager})
      : _keyManager = keyManager;

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
    final publicKey = await _keyManager.getPublicKey();
    if (publicKey == null) {
      throw KeyNotFoundException('设备公钥未找到');
    }

    // 使用HKDF从公钥派生加密密钥
    final hkdf = Hkdf(
      hmac: Hmac.sha256(),
      outputLength: 32, // 256位
    );

    final derivedKey = await hkdf.deriveKey(
      secretKey: SecretKey(base64Decode(publicKey)),
      info: utf8.encode('homepocket_note_encryption'), // 上下文信息
      nonce: [],
    );

    return derivedKey;
  }

  List<int> _generateNonce() {
    final random = Random.secure();
    return List.generate(12, (_) => random.nextInt(256));
  }
}

@riverpod
EncryptionService encryptionService(EncryptionServiceRef ref) {
  return EncryptionService(
    keyManager: ref.watch(keyManagerProvider),
  );
}
```

---

## UI组件设计

### 1. 隐私引导界面

```dart
// lib/features/security/presentation/screens/privacy_onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyOnboardingScreen extends StatefulWidget {
  const PrivacyOnboardingScreen({super.key});

  @override
  State<PrivacyOnboardingScreen> createState() =>
      _PrivacyOnboardingScreenState();
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
            const SizedBox(height: 20),
            _buildNavigationButtons(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyPage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock, size: 100, color: Color(0xFF4A90D9)),
          const SizedBox(height: 40),
          const Text(
            'あなたのデータは\nあなただけのもの',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          _buildFeatureItem('サーバーに保存されません'),
          _buildFeatureItem('会社は見られません'),
          _buildFeatureItem('端到端加密で保護'),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('我们永不:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
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

  Widget _buildTamperproofPage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.link, size: 100, color: Color(0xFF4A90D9)),
          const SizedBox(height: 40),
          const Text(
            '改ざんできない記録',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          _buildFeatureItem('ブロックチェーン技術を使用'),
          _buildFeatureItem('すべての記録が暗号化'),
          _buildFeatureItem('誰も過去を変えられません'),
        ],
      ),
    );
  }

  Widget _buildOpenSourcePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.visibility, size: 100, color: Color(0xFF4A90D9)),
          const SizedBox(height: 40),
          const Text(
            '透明でオープンソース',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          _buildFeatureItem('コードは完全公開'),
          _buildFeatureItem('誰でも検証できます'),
          _buildFeatureItem('コミュニティと一緒に'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildNeverItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.close, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14)),
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
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? const Color(0xFF4A90D9)
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: () => _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              child: const Text('← 戻る'),
            )
          else
            const SizedBox(width: 80),
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
      duration: const Duration(milliseconds: 300),
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

### 2. 生物识别锁界面

```dart
// lib/features/security/presentation/screens/biometric_lock_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/services/biometric_lock.dart';
import '../../domain/models/auth_result.dart';

class BiometricLockScreen extends ConsumerStatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  ConsumerState<BiometricLockScreen> createState() =>
      _BiometricLockScreenState();
}

class _BiometricLockScreenState extends ConsumerState<BiometricLockScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    final biometricLock = ref.read(biometricLockProvider);

    final result = await biometricLock.authenticate(
      reason: 'Home Pocketを開くには認証が必要です',
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
    // TODO: 实现数据库解锁逻辑
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 80, color: Theme.of(context).primaryColor),
            const SizedBox(height: 24),
            const Text(
              'Home Pocket',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '認証してください',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _showPINDialog,
              child: const Text('PINコードを入力'),
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
        title: const Text('認証失敗'),
        content: Text('認証に失敗しました（$attempts/${BiometricLock.maxFailedAttempts}回）'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _authenticate();
            },
            child: const Text('再試行'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showPINDialog();
            },
            child: const Text('PINを入力'),
          ),
        ],
      ),
    );
  }

  void _showPINDialog() {
    // TODO: 实现PIN输入对话框
  }

  void _showLockedOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ロックアウト'),
        content: const Text('生体認証がロックされました。PINコードを入力してください。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showPINDialog();
            },
            child: const Text('PINを入力'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _authenticate();
            },
            child: const Text('再試行'),
          ),
        ],
      ),
    );
  }
}
```

---

## 测试策略

### 单元测试

```dart
// test/features/security/application/services/key_manager_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

@GenerateMocks([FlutterSecureStorage])
import 'key_manager_test.mocks.dart';

void main() {
  group('KeyManager', () {
    late KeyManager keyManager;
    late MockFlutterSecureStorage mockSecureStorage;

    setUp(() {
      mockSecureStorage = MockFlutterSecureStorage();
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
        value: anyNamed('value'),
      ));
    });

    test('should recover key pair from valid mnemonic', () async {
      // Given
      final mnemonic = List.generate(24, (i) => 'word$i').join(' ');

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
  });

  group('HashChainService', () {
    test('should calculate consistent hash for same transaction', () async {
      // Test implementation
    });

    test('should verify valid chain', () async {
      // Test implementation
    });

    test('should detect tampered transaction', () async {
      // Test implementation
    });
  });
}
```

---

## 性能优化

### 优化策略

**1. 密钥生成:**
- 在后台线程执行
- 在内存中缓存公钥
- 目标<2秒生成时间

**2. 哈希链验证:**
- 增量验证(仅新交易)
- 后台异步执行
- 缓存上次验证状态

**3. 数据库加密:**
- 优化SQLCipher KDF迭代次数(平衡安全性/性能)
- 使用连接池
- 目标<500ms解锁时间

---

## 验收标准

### 功能需求

- ✅ 密钥生成成功率100%
- ✅ 恢复套件24词正确显示
- ✅ 恢复套件验证成功100%
- ✅ 生物识别认证成功>98%(支持设备上)
- ✅ 1000条交易的哈希链验证<1秒
- ✅ 篡改检测100%灵敏
- ✅ 审计报告PDF导出成功

### 性能需求

| 指标 | 目标 | 实际 |
|------|------|------|
| 密钥生成时间 | <2s | 待定 |
| 生物识别响应时间 | <1s | 待定 |
| 哈希链验证 | <1s(1000条交易) | 待定 |
| 数据库解锁时间 | <500ms | 待定 |

---

## 开发时间线 (10天)

| 天数 | 任务 | 交付物 |
|------|------|--------|
| **第1天** | 密钥管理基础 | KeyManager、Ed25519生成 |
| **第2天** | 恢复套件 | BIP39助记词、PDF导出 |
| **第3天** | 生物识别锁 | BiometricLock、local_auth集成 |
| **第4天** | 数据库加密 | SQLCipher集成、密钥派生 |
| **第5天** | 备注加密 | EncryptionService、ChaCha20-Poly1305 |
| **第6天** | 哈希链基础 | HashChainService、计算、验证 |
| **第7天** | 哈希链UI | 审计查看器、PDF报告 |
| **第8天** | 隐私引导 | 三页指南、动画 |
| **第9天** | 集成测试 | 端到端测试、安全审计 |
| **第10天** | 文档 | API文档、用户手册 |

---

## 参考资料

- [Ed25519](https://ed25519.cr.yp.to/)
- [BIP39规范](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki)
- [SQLCipher](https://www.zetetic.net/sqlcipher/)
- [ChaCha20-Poly1305](https://tools.ietf.org/html/rfc8439)
- PRD_Module_Security.md (需求)
- 01_MVP_Complete_Architecture_Guide.md (架构)

---

**文档状态:** 完成
**审核状态:** 待审核
**变更日志:**
- 2026-02-03: 创建完整技术实现文档，包含所有代码示例
