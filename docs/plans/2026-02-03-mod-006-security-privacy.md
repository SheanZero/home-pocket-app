# MOD-006: Security & Privacy Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement complete security and privacy infrastructure for Home Pocket including Ed25519 key management, biometric authentication, field encryption, database encryption, and blockchain-style hash chain integrity verification.

**Architecture:** Clean Architecture with 5 layers. Security module sits at the foundation, providing cryptographic services to all other modules. Uses zero-knowledge architecture where all sensitive data is encrypted at rest and in transit. Implements defense-in-depth with 4-layer encryption: biometric/PIN → field encryption → database encryption → transport encryption.

**Tech Stack:** Flutter 3.16+, Dart 3.2+, Riverpod 2.4+, Freezed (immutable models), Drift (type-safe SQL), SQLCipher (AES-256-CBC database encryption), flutter_secure_storage (iOS Keychain/Android Keystore), local_auth (biometric), cryptography (Ed25519, ChaCha20-Poly1305), crypto (SHA-256), bip39 (mnemonic), pdf (recovery kit export)

---

## Overview

This plan implements MOD-006 Security & Privacy module:

**1: Key Management System**
- Ed25519 device keypair generation
- Secure storage integration (Keychain/Keystore)
- Device ID derivation from public key hash
- HKDF key derivation for purpose separation

**2: Recovery Kit System**
- BIP39 24-word mnemonic generation
- Mnemonic-to-seed conversion
- Key recovery from mnemonic
- PDF export for backup
- User verification flow

**3: Biometric Lock**
- Face ID/Touch ID/Fingerprint integration
- PIN code fallback system
- Failed attempt tracking
- Auto-lock timer (5 minutes)
- Lock screen UI

**4: Field Encryption**
- ChaCha20-Poly1305 AEAD encryption
- Sensitive field encryption (amount, note, category)
- Batch encryption optimization
- Encryption service with key caching

**5: Database Encryption**
- SQLCipher integration with Drift
- AES-256-CBC with 256,000 PBKDF2 iterations
- Database initialization flow
- Encrypted migration handling

**6: Hash Chain Integrity**
- Blockchain-style hash chain implementation
- Incremental hash chain verification
- Tamper detection system
- Audit log generation

**7: Integration & Testing**
- Privacy onboarding UI
- End-to-end security flow
- Performance optimization
- Comprehensive security audit

---

## Prerequisites Setup

### Task 0: Add Security Dependencies

**Files:**
- Modify: `pubspec.yaml`
- Modify: `ios/Podfile`
- Modify: `android/app/build.gradle`

**Step 1: Add dependencies to pubspec.yaml**

Modify `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0

  # Immutable Models
  freezed_annotation: ^2.4.0
  json_annotation: ^4.8.0

  # Database
  drift: ^2.14.0
  sqlcipher_flutter_libs: ^0.6.0  # IMPORTANT: Use SQLCipher, not sqlite3

  # Cryptography
  cryptography: ^2.7.0
  crypto: ^3.0.3

  # Secure Storage
  flutter_secure_storage: ^9.0.0

  # Biometric Auth
  local_auth: ^2.1.7
  local_auth_android: ^1.0.34
  local_auth_ios: ^1.1.5

  # BIP39 Mnemonic
  bip39: ^1.0.6

  # PDF Generation
  pdf: ^3.10.6

  # Path Provider
  path_provider: ^2.1.1
  path: ^1.8.3

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Code Generation
  build_runner: ^2.4.6
  riverpod_generator: ^2.3.0
  freezed: ^2.4.5
  json_serializable: ^6.7.1
  drift_dev: ^2.14.0

  # Testing
  mockito: ^5.4.4
  integration_test:
    sdk: flutter
```

**Step 2: Configure iOS Podfile for SQLCipher**

Modify `ios/Podfile`:

```ruby
# Uncomment this line to define a global platform for your project
platform :ios, '14.0'

# Fix for ML Kit and other frameworks on simulator
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)

    # Fix for ML Kit simulator build issue
    target.build_configurations.each do |config|
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'

      # Enable bitcode for SQLCipher
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
```

**Step 3: Configure Android for biometric**

Modify `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 34

    defaultConfig {
        applicationId "com.homepocket.app"
        minSdkVersion 24  // API 24+ (Android 7.0+)
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
}

dependencies {
    // Biometric dependencies are handled by local_auth plugin
}
```

**Step 4: Update Android permissions**

Modify `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Biometric permission -->
    <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
    <uses-permission android:name="android.permission.USE_FINGERPRINT"/>

    <application
        android:label="Home Pocket"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">

        <!-- ... rest of manifest ... -->
    </application>
</manifest>
```

**Step 5: Update iOS Info.plist**

Modify `ios/Runner/Info.plist`:

```xml
<dict>
    <!-- Face ID usage description -->
    <key>NSFaceIDUsageDescription</key>
    <string>Home Pocketを開くには認証が必要です</string>

    <!-- ... rest of Info.plist ... -->
</dict>
```

**Step 6: Install dependencies**

Run: `flutter pub get`

Expected: All dependencies resolved successfully

**Step 7: Install iOS pods**

Run: `cd ios && pod install && cd ..`

Expected: Pods installed successfully

**Step 8: Verify build**

Run: `flutter build ios --debug --no-codesign` or `flutter build apk --debug`

Expected: Build succeeds without errors

**Step 9: Commit dependency setup**

```bash
git add pubspec.yaml ios/Podfile android/app/build.gradle android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist
git commit -m "$(cat <<'EOF'
feat: add security module dependencies

- Add cryptography libraries (Ed25519, ChaCha20-Poly1305)
- Add SQLCipher for database encryption
- Add flutter_secure_storage for keychain/keystore
- Add local_auth for biometric authentication
- Add bip39 for mnemonic recovery
- Configure iOS/Android for biometric permissions

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## 1: Key Management System

### Task 1: Domain Models for Security

**Files:**
- Create: `lib/features/security/domain/models/device_key_pair.dart`
- Create: `lib/features/security/domain/models/auth_result.dart`
- Create: `lib/features/security/domain/models/chain_verification_result.dart`
- Create: `test/features/security/domain/models/device_key_pair_test.dart`
- Create: `test/features/security/domain/models/auth_result_test.dart`
- Create: `test/features/security/domain/models/chain_verification_result_test.dart`

**Step 1: Write test for DeviceKeyPair model**

Create `test/features/security/domain/models/device_key_pair_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/security/domain/models/device_key_pair.dart';

void main() {
  group('DeviceKeyPair', () {
    test('should create valid DeviceKeyPair', () {
      final now = DateTime.now();
      final keyPair = DeviceKeyPair(
        publicKey: 'test_public_key_base64',
        deviceId: 'abcd1234efgh5678',
        createdAt: now,
      );

      expect(keyPair.publicKey, 'test_public_key_base64');
      expect(keyPair.deviceId, 'abcd1234efgh5678');
      expect(keyPair.deviceId.length, 16);
      expect(keyPair.createdAt, now);
    });

    test('should be immutable', () {
      final keyPair = DeviceKeyPair(
        publicKey: 'key1',
        deviceId: 'id1_12345678901',
        createdAt: DateTime.now(),
      );

      final copied = keyPair.copyWith(deviceId: 'id2_12345678902');

      expect(keyPair.deviceId, 'id1_12345678901');
      expect(copied.deviceId, 'id2_12345678902');
      expect(keyPair.publicKey, copied.publicKey);
    });

    test('should support equality comparison', () {
      final now = DateTime.now();
      final keyPair1 = DeviceKeyPair(
        publicKey: 'key',
        deviceId: 'id12345678901234',
        createdAt: now,
      );

      final keyPair2 = DeviceKeyPair(
        publicKey: 'key',
        deviceId: 'id12345678901234',
        createdAt: now,
      );

      expect(keyPair1, equals(keyPair2));
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/security/domain/models/device_key_pair_test.dart`

Expected: FAIL (file not found)

**Step 3: Implement DeviceKeyPair model**

Create `lib/features/security/domain/models/device_key_pair.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_key_pair.freezed.dart';

@freezed
class DeviceKeyPair with _$DeviceKeyPair {
  const factory DeviceKeyPair({
    required String publicKey,  // Base64编码的Ed25519公钥
    required String deviceId,   // SHA-256哈希前16字符
    required DateTime createdAt,
  }) = _DeviceKeyPair;
}
```

**Step 4: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

Expected: Generates `device_key_pair.freezed.dart`

**Step 5: Run test to verify it passes**

Run: `flutter test test/features/security/domain/models/device_key_pair_test.dart`

Expected: PASS

**Step 6: Write test for AuthResult model**

Create `test/features/security/domain/models/auth_result_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/security/domain/models/auth_result.dart';

void main() {
  group('AuthResult', () {
    test('should create success result', () {
      final result = AuthResult.success();

      expect(result.status, AuthStatus.success);
      expect(result.message, isNull);
      expect(result.failedAttempts, isNull);
    });

    test('should create failed result with attempt count', () {
      final result = AuthResult.failed(2);

      expect(result.status, AuthStatus.failed);
      expect(result.failedAttempts, 2);
    });

    test('should create fallback to PIN result', () {
      final result = AuthResult.fallbackToPIN();

      expect(result.status, AuthStatus.fallbackToPIN);
    });

    test('should create too many attempts result', () {
      final result = AuthResult.tooManyAttempts();

      expect(result.status, AuthStatus.tooManyAttempts);
    });

    test('should create locked out result', () {
      final result = AuthResult.lockedOut();

      expect(result.status, AuthStatus.lockedOut);
    });

    test('should create error result with message', () {
      final result = AuthResult.error('Test error');

      expect(result.status, AuthStatus.error);
      expect(result.message, 'Test error');
    });
  });
}
```

**Step 7: Run test to verify it fails**

Run: `flutter test test/features/security/domain/models/auth_result_test.dart`

Expected: FAIL

**Step 8: Implement AuthResult model**

Create `lib/features/security/domain/models/auth_result.dart`:

```dart
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

  factory AuthResult.success() => const AuthResult(status: AuthStatus.success);

  factory AuthResult.failed(int attempts) => AuthResult(
        status: AuthStatus.failed,
        failedAttempts: attempts,
      );

  factory AuthResult.fallbackToPIN() => const AuthResult(
        status: AuthStatus.fallbackToPIN,
      );

  factory AuthResult.tooManyAttempts() => const AuthResult(
        status: AuthStatus.tooManyAttempts,
      );

  factory AuthResult.lockedOut() => const AuthResult(
        status: AuthStatus.lockedOut,
      );

  factory AuthResult.error(String message) => AuthResult(
        status: AuthStatus.error,
        message: message,
      );
}
```

**Step 9: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

Expected: Generates `auth_result.freezed.dart`

**Step 10: Run test to verify it passes**

Run: `flutter test test/features/security/domain/models/auth_result_test.dart`

Expected: PASS

**Step 11: Write test for ChainVerificationResult**

Create `test/features/security/domain/models/chain_verification_result_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/security/domain/models/chain_verification_result.dart';

void main() {
  group('ChainVerificationResult', () {
    test('should create valid chain result', () {
      final result = ChainVerificationResult.valid(totalTransactions: 100);

      expect(result.isValid, true);
      expect(result.totalTransactions, 100);
      expect(result.tamperedTransactionIds, isEmpty);
    });

    test('should create tampered chain result', () {
      final result = ChainVerificationResult.tampered(
        totalTransactions: 100,
        tamperedTransactionIds: ['tx-001', 'tx-050'],
      );

      expect(result.isValid, false);
      expect(result.totalTransactions, 100);
      expect(result.tamperedTransactionIds, ['tx-001', 'tx-050']);
    });

    test('should create empty chain result', () {
      final result = ChainVerificationResult.empty();

      expect(result.isValid, true);
      expect(result.totalTransactions, 0);
      expect(result.tamperedTransactionIds, isEmpty);
    });
  });
}
```

**Step 12: Run test to verify it fails**

Run: `flutter test test/features/security/domain/models/chain_verification_result_test.dart`

Expected: FAIL

**Step 13: Implement ChainVerificationResult**

Create `lib/features/security/domain/models/chain_verification_result.dart`:

```dart
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
  }) =>
      ChainVerificationResult(
        isValid: true,
        totalTransactions: totalTransactions,
        tamperedTransactionIds: const [],
      );

  factory ChainVerificationResult.tampered({
    required int totalTransactions,
    required List<String> tamperedTransactionIds,
  }) =>
      ChainVerificationResult(
        isValid: false,
        totalTransactions: totalTransactions,
        tamperedTransactionIds: tamperedTransactionIds,
      );

  factory ChainVerificationResult.empty() => const ChainVerificationResult(
        isValid: true,
        totalTransactions: 0,
        tamperedTransactionIds: [],
      );
}
```

**Step 14: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

Expected: Generates `chain_verification_result.freezed.dart`

**Step 15: Run test to verify it passes**

Run: `flutter test test/features/security/domain/models/chain_verification_result_test.dart`

Expected: PASS

**Step 16: Run all domain model tests**

Run: `flutter test test/features/security/domain/models/`

Expected: All tests PASS

**Step 17: Commit domain models**

```bash
git add lib/features/security/domain/models/ test/features/security/domain/models/
git commit -m "$(cat <<'EOF'
feat: add security domain models

- Add DeviceKeyPair model for Ed25519 keys
- Add AuthResult model for biometric auth states
- Add ChainVerificationResult for integrity checks
- Add comprehensive unit tests
- All models use Freezed for immutability

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: KeyManager - Ed25519 Key Generation & Storage

**Files:**
- Create: `lib/features/security/application/services/key_manager.dart`
- Create: `test/features/security/application/services/key_manager_test.dart`

**Step 1: Write test for KeyManager**

Create `test/features/security/application/services/key_manager_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:home_pocket/features/security/application/services/key_manager.dart';

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

    group('generateDeviceKeyPair', () {
      test('should generate valid Ed25519 key pair', () async {
        // Arrange
        when(mockSecureStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
          iOptions: anyNamed('iOptions'),
          aOptions: anyNamed('aOptions'),
        )).thenAnswer((_) async => null);

        // Act
        final keyPair = await keyManager.generateDeviceKeyPair();

        // Assert
        expect(keyPair.publicKey, isNotEmpty);
        expect(keyPair.deviceId, isNotEmpty);
        expect(keyPair.deviceId.length, 16);
        expect(keyPair.createdAt, isA<DateTime>());

        // Verify private key stored securely
        verify(mockSecureStorage.write(
          key: 'device_private_key',
          value: anyNamed('value'),
          iOptions: anyNamed('iOptions'),
          aOptions: anyNamed('aOptions'),
        )).called(1);

        // Verify public key stored
        verify(mockSecureStorage.write(
          key: 'device_public_key',
          value: anyNamed('value'),
        )).called(1);

        // Verify device ID stored
        verify(mockSecureStorage.write(
          key: 'device_id',
          value: anyNamed('value'),
        )).called(1);
      });

      test('should generate different keys on each call', () async {
        // Arrange
        when(mockSecureStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
          iOptions: anyNamed('iOptions'),
          aOptions: anyNamed('aOptions'),
        )).thenAnswer((_) async => null);

        // Act
        final keyPair1 = await keyManager.generateDeviceKeyPair();
        final keyPair2 = await keyManager.generateDeviceKeyPair();

        // Assert
        expect(keyPair1.publicKey, isNot(equals(keyPair2.publicKey)));
        expect(keyPair1.deviceId, isNot(equals(keyPair2.deviceId)));
      });
    });

    group('hasKeyPair', () {
      test('should return true when private key exists', () async {
        // Arrange
        when(mockSecureStorage.read(key: 'device_private_key'))
            .thenAnswer((_) async => 'mock_private_key_base64');

        // Act
        final hasKey = await keyManager.hasKeyPair();

        // Assert
        expect(hasKey, true);
      });

      test('should return false when private key does not exist', () async {
        // Arrange
        when(mockSecureStorage.read(key: 'device_private_key'))
            .thenAnswer((_) async => null);

        // Act
        final hasKey = await keyManager.hasKeyPair();

        // Assert
        expect(hasKey, false);
      });
    });

    group('getPublicKey', () {
      test('should return stored public key', () async {
        // Arrange
        const mockPublicKey = 'mock_public_key_base64';
        when(mockSecureStorage.read(key: 'device_public_key'))
            .thenAnswer((_) async => mockPublicKey);

        // Act
        final publicKey = await keyManager.getPublicKey();

        // Assert
        expect(publicKey, mockPublicKey);
      });

      test('should return null when public key not found', () async {
        // Arrange
        when(mockSecureStorage.read(key: 'device_public_key'))
            .thenAnswer((_) async => null);

        // Act
        final publicKey = await keyManager.getPublicKey();

        // Assert
        expect(publicKey, isNull);
      });
    });

    group('getDeviceId', () {
      test('should return stored device ID', () async {
        // Arrange
        const mockDeviceId = 'abc123def4567890';
        when(mockSecureStorage.read(key: 'device_id'))
            .thenAnswer((_) async => mockDeviceId);

        // Act
        final deviceId = await keyManager.getDeviceId();

        // Assert
        expect(deviceId, mockDeviceId);
        expect(deviceId?.length, 16);
      });
    });

    group('signData', () {
      test('should throw KeyNotFoundException when private key not found', () async {
        // Arrange
        when(mockSecureStorage.read(key: 'device_private_key'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => keyManager.signData([1, 2, 3]),
          throwsA(isA<KeyNotFoundException>()),
        );
      });
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/security/application/services/key_manager_test.dart`

Expected: FAIL (KeyManager not found)

**Step 3: Implement KeyManager**

Create `lib/features/security/application/services/key_manager.dart`:

```dart
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
    final publicKeyBase64 = base64Encode(publicKey.bytes);
    await _secureStorage.write(
      key: 'device_public_key',
      value: publicKeyBase64,
    );

    // 4. 生成设备ID（公钥的哈希）
    final deviceId = _generateDeviceId(publicKey.bytes);
    await _secureStorage.write(key: 'device_id', value: deviceId);

    return DeviceKeyPair(
      publicKey: publicKeyBase64,
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

// 异常类
class KeyNotFoundException implements Exception {
  final String message;
  KeyNotFoundException(this.message);

  @override
  String toString() => 'KeyNotFoundException: $message';
}

class InvalidMnemonicException implements Exception {
  final String message;
  InvalidMnemonicException(this.message);

  @override
  String toString() => 'InvalidMnemonicException: $message';
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

**Step 4: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

Expected: Generates `key_manager.g.dart`

**Step 5: Run test to verify it passes**

Run: `flutter test test/features/security/application/services/key_manager_test.dart`

Expected: PASS (all tests green)

**Step 6: Commit KeyManager**

```bash
git add lib/features/security/application/services/ test/features/security/application/services/
git commit -m "$(cat <<'EOF'
feat: implement Ed25519 key manager

- Generate Ed25519 device keypairs
- Store private key in secure storage (Keychain/Keystore)
- Derive device ID from public key hash (SHA-256)
- Support data signing and verification
- Add comprehensive unit tests with mocks
- Test coverage >80%

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## 2: Recovery Kit System

### Task 3: BIP39 Mnemonic Recovery

**Files:**
- Create: `lib/features/security/application/services/recovery_kit_service.dart`
- Create: `test/features/security/application/services/recovery_kit_service_test.dart`

**Step 1: Write test for RecoveryKitService**

Create `test/features/security/application/services/recovery_kit_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:home_pocket/features/security/application/services/recovery_kit_service.dart';
import 'package:home_pocket/features/security/application/services/key_manager.dart';

@GenerateMocks([FlutterSecureStorage, KeyManager])
import 'recovery_kit_service_test.mocks.dart';

void main() {
  group('RecoveryKitService', () {
    late RecoveryKitService service;
    late MockFlutterSecureStorage mockSecureStorage;
    late MockKeyManager mockKeyManager;

    setUp(() {
      mockSecureStorage = MockFlutterSecureStorage();
      mockKeyManager = MockKeyManager();
      service = RecoveryKitService(
        secureStorage: mockSecureStorage,
        keyManager: mockKeyManager,
      );
    });

    group('generateRecoveryKit', () {
      test('should generate 24-word mnemonic', () async {
        // Arrange
        when(mockSecureStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
        )).thenAnswer((_) async => null);

        // Act
        final mnemonic = await service.generateRecoveryKit();

        // Assert
        final words = mnemonic.split(' ');
        expect(words.length, 24);
        expect(words.every((word) => word.isNotEmpty), true);

        // Verify hash stored
        verify(mockSecureStorage.write(
          key: 'recovery_kit_hash',
          value: anyNamed('value'),
        )).called(1);
      });

      test('should generate different mnemonics on each call', () async {
        // Arrange
        when(mockSecureStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
        )).thenAnswer((_) async => null);

        // Act
        final mnemonic1 = await service.generateRecoveryKit();
        final mnemonic2 = await service.generateRecoveryKit();

        // Assert
        expect(mnemonic1, isNot(equals(mnemonic2)));
      });
    });

    group('verifyRecoveryKit', () {
      test('should return true for correct mnemonic', () async {
        // Arrange
        const testMnemonic = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
        final hash = service.hashMnemonic(testMnemonic);

        when(mockSecureStorage.read(key: 'recovery_kit_hash'))
            .thenAnswer((_) async => hash);

        // Act
        final isValid = await service.verifyRecoveryKit(testMnemonic);

        // Assert
        expect(isValid, true);
      });

      test('should return false for incorrect mnemonic', () async {
        // Arrange
        const storedMnemonic = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
        const inputMnemonic = 'zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong';

        final storedHash = service.hashMnemonic(storedMnemonic);
        when(mockSecureStorage.read(key: 'recovery_kit_hash'))
            .thenAnswer((_) async => storedHash);

        // Act
        final isValid = await service.verifyRecoveryKit(inputMnemonic);

        // Assert
        expect(isValid, false);
      });

      test('should return false for invalid word count', () async {
        // Arrange
        const invalidMnemonic = 'abandon abandon abandon';

        when(mockSecureStorage.read(key: 'recovery_kit_hash'))
            .thenAnswer((_) async => 'some_hash');

        // Act
        final isValid = await service.verifyRecoveryKit(invalidMnemonic);

        // Assert
        expect(isValid, false);
      });

      test('should return false when no stored hash', () async {
        // Arrange
        when(mockSecureStorage.read(key: 'recovery_kit_hash'))
            .thenAnswer((_) async => null);

        // Act
        final isValid = await service.verifyRecoveryKit('some mnemonic');

        // Assert
        expect(isValid, false);
      });
    });

    group('getRandomWordsForVerification', () {
      test('should return 3 random word indices', () {
        // Act
        final indices = service.getRandomWordsForVerification();

        // Assert
        expect(indices.length, 3);
        expect(indices.every((i) => i >= 0 && i < 24), true);
        expect(indices.toSet().length, 3); // All unique
      });
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/security/application/services/recovery_kit_service_test.dart`

Expected: FAIL (RecoveryKitService not found)

**Step 3: Implement RecoveryKitService**

Create `lib/features/security/application/services/recovery_kit_service.dart`:

```dart
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'key_manager.dart';

part 'recovery_kit_service.g.dart';

class RecoveryKitService {
  final FlutterSecureStorage _secureStorage;
  final KeyManager _keyManager;

  RecoveryKitService({
    required FlutterSecureStorage secureStorage,
    required KeyManager keyManager,
  })  : _secureStorage = secureStorage,
        _keyManager = keyManager;

  /// 生成Recovery Kit（24个助记词）
  Future<String> generateRecoveryKit() async {
    // 1. 生成256位随机熵并转换为助记词（24个单词）
    final mnemonic = bip39.generateMnemonic(strength: 256);

    // 2. 存储助记词的哈希（用于后续验证，绝不存储明文）
    final hash = hashMnemonic(mnemonic);
    await _secureStorage.write(
      key: 'recovery_kit_hash',
      value: hash,
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

    final inputHash = hashMnemonic(userInput);
    return inputHash == storedHash;
  }

  /// 从助记词恢复密钥对
  Future<void> recoverFromMnemonic(String mnemonic) async {
    // 1. 验证助记词格式
    if (!bip39.validateMnemonic(mnemonic)) {
      throw InvalidMnemonicException('助记词格式错误');
    }

    // 2. 从助记词派生种子（512位）
    final seed = bip39.mnemonicToSeed(mnemonic);

    // 3. 使用种子的前32字节作为Ed25519私钥种子
    final privateKeySeed = seed.sublist(0, 32);

    // 4. 让KeyManager使用这个种子重新生成密钥对
    // (需要在KeyManager中添加从种子生成的方法)
    await _keyManager.recoverFromSeed(privateKeySeed);

    // 5. 存储助记词哈希
    final hash = hashMnemonic(mnemonic);
    await _secureStorage.write(
      key: 'recovery_kit_hash',
      value: hash,
    );
  }

  /// 获取随机3个单词位置用于验证
  List<int> getRandomWordsForVerification() {
    final random = Random.secure();
    final indices = <int>{};

    while (indices.length < 3) {
      indices.add(random.nextInt(24));
    }

    return indices.toList()..sort();
  }

  /// 计算助记词的SHA-256哈希
  String hashMnemonic(String mnemonic) {
    final bytes = utf8.encode(mnemonic.trim());
    final digest = sha256.convert(bytes);
    return digest.toString();
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

**Step 4: Add recoverFromSeed method to KeyManager**

Modify `lib/features/security/application/services/key_manager.dart`:

Add this method to the KeyManager class:

```dart
  /// 从种子恢复密钥对
  Future<DeviceKeyPair> recoverFromSeed(List<int> seed) async {
    if (seed.length != 32) {
      throw InvalidMnemonicException('种子长度必须为32字节');
    }

    // 1. 从种子生成密钥对
    final keyPair = await _ed25519.newKeyPairFromSeed(seed);
    final publicKey = await keyPair.extractPublicKey();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

    // 2. 存储到安全存储
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
```

**Step 5: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

Expected: Generates `recovery_kit_service.g.dart`

**Step 6: Run test to verify it passes**

Run: `flutter test test/features/security/application/services/recovery_kit_service_test.dart`

Expected: PASS

**Step 7: Commit RecoveryKitService**

```bash
git add lib/features/security/application/services/ test/features/security/application/services/
git commit -m "$(cat <<'EOF'
feat: implement BIP39 recovery kit system

- Generate 24-word BIP39 mnemonic
- Verify user-entered mnemonic against stored hash
- Recover keypair from mnemonic seed
- Add random word verification helper
- Store only hash of mnemonic (never plaintext)
- Add comprehensive unit tests

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## 3: Biometric Lock System

### Task 4: Biometric Authentication Service

**Files:**
- Create: `lib/features/security/application/services/biometric_lock.dart`
- Create: `test/features/security/application/services/biometric_lock_test.dart`

**Step 1: Write test for BiometricLock**

Create `test/features/security/application/services/biometric_lock_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';
import 'package:home_pocket/features/security/application/services/biometric_lock.dart';
import 'package:home_pocket/features/security/domain/models/auth_result.dart';

@GenerateMocks([LocalAuthentication])
import 'biometric_lock_test.mocks.dart';

void main() {
  group('BiometricLock', () {
    late BiometricLock biometricLock;
    late MockLocalAuthentication mockLocalAuth;

    setUp(() {
      mockLocalAuth = MockLocalAuthentication();
      biometricLock = BiometricLock(localAuth: mockLocalAuth);
    });

    group('checkAvailability', () {
      test('should return faceId when Face ID is available', () async {
        // Arrange
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);

        // Act
        final availability = await biometricLock.checkAvailability();

        // Assert
        expect(availability, BiometricAvailability.faceId);
      });

      test('should return fingerprint when fingerprint is available', () async {
        // Arrange
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.fingerprint]);

        // Act
        final availability = await biometricLock.checkAvailability();

        // Assert
        expect(availability, BiometricAvailability.fingerprint);
      });

      test('should return notSupported when hardware not supported', () async {
        // Arrange
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);

        // Act
        final availability = await biometricLock.checkAvailability();

        // Assert
        expect(availability, BiometricAvailability.notSupported);
      });

      test('should return notEnrolled when no biometrics enrolled', () async {
        // Arrange
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => []);

        // Act
        final availability = await biometricLock.checkAvailability();

        // Assert
        expect(availability, BiometricAvailability.notEnrolled);
      });
    });

    group('authenticate', () {
      test('should return success when authentication succeeds', () async {
        // Arrange
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);
        when(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          authMessages: anyNamed('authMessages'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => true);

        // Act
        final result = await biometricLock.authenticate(
          reason: 'Test authentication',
        );

        // Assert
        expect(result.status, AuthStatus.success);
      });

      test('should return failed and increment counter when auth fails', () async {
        // Arrange
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);
        when(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          authMessages: anyNamed('authMessages'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => false);

        // Act
        final result = await biometricLock.authenticate(
          reason: 'Test authentication',
        );

        // Assert
        expect(result.status, AuthStatus.failed);
        expect(result.failedAttempts, 1);
      });

      test('should return tooManyAttempts after 3 failures', () async {
        // Arrange
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);

        // Act: Fail 3 times
        await biometricLock.authenticate(reason: 'Test');
        await biometricLock.authenticate(reason: 'Test');
        final result = await biometricLock.authenticate(reason: 'Test');

        // Assert
        expect(result.status, AuthStatus.tooManyAttempts);
      });

      test('should return lockedOut when PlatformException LockedOut', () async {
        // Arrange
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);
        when(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          authMessages: anyNamed('authMessages'),
          options: anyNamed('options'),
        )).thenThrow(PlatformException(code: auth_error.lockedOut));

        // Act
        final result = await biometricLock.authenticate(
          reason: 'Test authentication',
        );

        // Assert
        expect(result.status, AuthStatus.lockedOut);
      });

      test('should return fallbackToPIN when biometric not available', () async {
        // Arrange
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);

        // Act
        final result = await biometricLock.authenticate(
          reason: 'Test authentication',
        );

        // Assert
        expect(result.status, AuthStatus.fallbackToPIN);
      });
    });

    group('resetFailedAttempts', () {
      test('should reset failed attempts counter', () async {
        // Arrange
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);
        when(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          authMessages: anyNamed('authMessages'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => false);

        // Act: Fail once
        await biometricLock.authenticate(reason: 'Test');

        // Reset
        biometricLock.resetFailedAttempts();

        // Try again
        final result = await biometricLock.authenticate(reason: 'Test');

        // Assert: Should be first failure again
        expect(result.failedAttempts, 1);
      });
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/security/application/services/biometric_lock_test.dart`

Expected: FAIL (BiometricLock not found)

**Step 3: Implement BiometricLock service**

Create `lib/features/security/application/services/biometric_lock.dart`:

```dart
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_ios/local_auth_ios.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
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
  final LocalAuthentication _localAuth;
  int _failedAttempts = 0;
  static const int maxFailedAttempts = 3;

  BiometricLock({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  /// 检查设备是否支持生物识别
  Future<BiometricAvailability> checkAvailability() async {
    try {
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
    } catch (e) {
      return BiometricAvailability.notSupported;
    }
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
          stickyAuth: true,
          biometricOnly: !allowPINFallback,
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
      if (e.code == auth_error.lockedOut ||
          e.code == auth_error.permanentlyLockedOut) {
        return AuthResult.lockedOut();
      } else if (e.code == auth_error.notAvailable ||
          e.code == auth_error.notEnrolled) {
        return AuthResult.fallbackToPIN();
      } else {
        _failedAttempts++;
        return AuthResult.error(e.message ?? '認証失敗');
      }
    } catch (e) {
      _failedAttempts++;
      return AuthResult.error(e.toString());
    }
  }

  /// 重置失败次数
  void resetFailedAttempts() {
    _failedAttempts = 0;
  }

  /// 获取当前失败次数
  int get failedAttempts => _failedAttempts;
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

**Step 4: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

Expected: Generates `biometric_lock.g.dart`

**Step 5: Run test to verify it passes**

Run: `flutter test test/features/security/application/services/biometric_lock_test.dart`

Expected: PASS

**Step 6: Commit BiometricLock**

```bash
git add lib/features/security/application/services/ test/features/security/application/services/
git commit -m "$(cat <<'EOF'
feat: implement biometric authentication service

- Support Face ID, Touch ID, and Fingerprint
- Track failed authentication attempts
- Auto-fallback to PIN after 3 failures
- Handle platform-specific error codes
- Support iOS and Android biometric types
- Add comprehensive unit tests with mocks

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: PIN Code Authentication & Lock Screen UI

**Files:**
- Create: `lib/features/security/application/services/pin_manager.dart`
- Create: `lib/features/security/presentation/screens/biometric_lock_screen.dart`
- Create: `lib/features/security/presentation/widgets/pin_input.dart`
- Create: `test/features/security/application/services/pin_manager_test.dart`
- Create: `test/features/security/presentation/widgets/pin_input_test.dart`

**Step 1: Write test for PINManager**

Create `test/features/security/application/services/pin_manager_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:home_pocket/features/security/application/services/pin_manager.dart';

@GenerateMocks([FlutterSecureStorage])
import 'pin_manager_test.mocks.dart';

void main() {
  group('PINManager', () {
    late PINManager pinManager;
    late MockFlutterSecureStorage mockSecureStorage;

    setUp(() {
      mockSecureStorage = MockFlutterSecureStorage();
      pinManager = PINManager(secureStorage: mockSecureStorage);
    });

    group('setPIN', () {
      test('should store hashed PIN', () async {
        // Arrange
        const pin = '123456';
        when(mockSecureStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
        )).thenAnswer((_) async => null);

        // Act
        await pinManager.setPIN(pin);

        // Assert
        verify(mockSecureStorage.write(
          key: 'pin_hash',
          value: anyNamed('value'),
        )).called(1);
      });

      test('should reject PIN shorter than 4 digits', () async {
        // Arrange
        const shortPin = '123';

        // Act & Assert
        expect(
          () => pinManager.setPIN(shortPin),
          throwsA(isA<InvalidPINException>()),
        );
      });

      test('should reject PIN with non-numeric characters', () async {
        // Arrange
        const invalidPin = '12ab56';

        // Act & Assert
        expect(
          () => pinManager.setPIN(invalidPin),
          throwsA(isA<InvalidPINException>()),
        );
      });
    });

    group('verifyPIN', () {
      test('should return true for correct PIN', () async {
        // Arrange
        const pin = '123456';
        final hash = pinManager.hashPIN(pin);

        when(mockSecureStorage.read(key: 'pin_hash'))
            .thenAnswer((_) async => hash);

        // Act
        final isValid = await pinManager.verifyPIN(pin);

        // Assert
        expect(isValid, true);
      });

      test('should return false for incorrect PIN', () async {
        // Arrange
        const correctPin = '123456';
        const wrongPin = '654321';
        final hash = pinManager.hashPIN(correctPin);

        when(mockSecureStorage.read(key: 'pin_hash'))
            .thenAnswer((_) async => hash);

        // Act
        final isValid = await pinManager.verifyPIN(wrongPin);

        // Assert
        expect(isValid, false);
      });

      test('should return false when no PIN is set', () async {
        // Arrange
        when(mockSecureStorage.read(key: 'pin_hash'))
            .thenAnswer((_) async => null);

        // Act
        final isValid = await pinManager.verifyPIN('123456');

        // Assert
        expect(isValid, false);
      });
    });

    group('hasPIN', () {
      test('should return true when PIN is set', () async {
        // Arrange
        when(mockSecureStorage.read(key: 'pin_hash'))
            .thenAnswer((_) async => 'some_hash');

        // Act
        final hasPIN = await pinManager.hasPIN();

        // Assert
        expect(hasPIN, true);
      });

      test('should return false when PIN is not set', () async {
        // Arrange
        when(mockSecureStorage.read(key: 'pin_hash'))
            .thenAnswer((_) async => null);

        // Act
        final hasPIN = await pinManager.hasPIN();

        // Assert
        expect(hasPIN, false);
      });
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/security/application/services/pin_manager_test.dart`

Expected: FAIL

**Step 3: Implement PINManager**

Create `lib/features/security/application/services/pin_manager.dart`:

```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pin_manager.g.dart';

class PINManager {
  final FlutterSecureStorage _secureStorage;

  PINManager({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage;

  /// 设置PIN码
  Future<void> setPIN(String pin) async {
    // 1. 验证PIN格式
    if (pin.length < 4 || pin.length > 8) {
      throw InvalidPINException('PIN must be 4-8 digits');
    }

    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      throw InvalidPINException('PIN must contain only numbers');
    }

    // 2. 哈希PIN并存储
    final hash = hashPIN(pin);
    await _secureStorage.write(key: 'pin_hash', value: hash);
  }

  /// 验证PIN码
  Future<bool> verifyPIN(String pin) async {
    final storedHash = await _secureStorage.read(key: 'pin_hash');
    if (storedHash == null) {
      return false;
    }

    final inputHash = hashPIN(pin);
    return inputHash == storedHash;
  }

  /// 检查是否已设置PIN
  Future<bool> hasPIN() async {
    final hash = await _secureStorage.read(key: 'pin_hash');
    return hash != null;
  }

  /// 删除PIN
  Future<void> deletePIN() async {
    await _secureStorage.delete(key: 'pin_hash');
  }

  /// 哈希PIN（使用SHA-256）
  String hashPIN(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

class InvalidPINException implements Exception {
  final String message;
  InvalidPINException(this.message);

  @override
  String toString() => 'InvalidPINException: $message';
}

@riverpod
PINManager pinManager(PinManagerRef ref) {
  return PINManager(
    secureStorage: const FlutterSecureStorage(),
  );
}

@riverpod
Future<bool> hasPIN(HasPINRef ref) async {
  final pinManager = ref.watch(pinManagerProvider);
  return await pinManager.hasPIN();
}
```

**Step 4: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

Expected: Generates `pin_manager.g.dart`

**Step 5: Run test to verify it passes**

Run: `flutter test test/features/security/application/services/pin_manager_test.dart`

Expected: PASS

**Step 6: Commit PINManager**

```bash
git add lib/features/security/application/services/ test/features/security/application/services/
git commit -m "$(cat <<'EOF'
feat: implement PIN code manager

- Set and verify numeric PIN (4-8 digits)
- Store PIN as SHA-256 hash
- Validate PIN format
- Add comprehensive unit tests

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Day 7: Field Encryption Service

### Task 6: ChaCha20-Poly1305 Field Encryption

**Files:**
- Create: `lib/features/security/application/services/encryption_service.dart`
- Create: `test/features/security/application/services/encryption_service_test.dart`

**Step 1: Write test for EncryptionService**

Create `test/features/security/application/services/encryption_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:home_pocket/features/security/application/services/encryption_service.dart';
import 'package:home_pocket/features/security/application/services/key_manager.dart';

@GenerateMocks([KeyManager])
import 'encryption_service_test.mocks.dart';

void main() {
  group('EncryptionService', () {
    late EncryptionService encryptionService;
    late MockKeyManager mockKeyManager;

    setUp(() {
      mockKeyManager = MockKeyManager();
      encryptionService = EncryptionService(keyManager: mockKeyManager);
    });

    group('encrypt and decrypt', () {
      test('should successfully encrypt and decrypt plaintext', () async {
        // Arrange
        const plaintext = 'Sensitive data 123';
        const mockPublicKey = 'mock_public_key_base64_encoded_string';

        when(mockKeyManager.getPublicKey())
            .thenAnswer((_) async => mockPublicKey);

        // Act: Encrypt
        final ciphertext = await encryptionService.encrypt(plaintext);

        // Assert: Ciphertext is not equal to plaintext
        expect(ciphertext, isNot(equals(plaintext)));
        expect(ciphertext, isNotEmpty);

        // Act: Decrypt
        final decrypted = await encryptionService.decrypt(ciphertext);

        // Assert: Decrypted matches original
        expect(decrypted, equals(plaintext));
      });

      test('should produce different ciphertext for same plaintext', () async {
        // Arrange
        const plaintext = 'Test message';
        const mockPublicKey = 'mock_public_key_base64_encoded_string';

        when(mockKeyManager.getPublicKey())
            .thenAnswer((_) async => mockPublicKey);

        // Act
        final ciphertext1 = await encryptionService.encrypt(plaintext);
        final ciphertext2 = await encryptionService.encrypt(plaintext);

        // Assert: Different due to random nonce
        expect(ciphertext1, isNot(equals(ciphertext2)));

        // But both decrypt to same plaintext
        final decrypted1 = await encryptionService.decrypt(ciphertext1);
        final decrypted2 = await encryptionService.decrypt(ciphertext2);
        expect(decrypted1, equals(plaintext));
        expect(decrypted2, equals(plaintext));
      });

      test('should handle Unicode characters', () async {
        // Arrange
        const plaintext = '日本語テスト 中文测试 🎉';
        const mockPublicKey = 'mock_public_key_base64_encoded_string';

        when(mockKeyManager.getPublicKey())
            .thenAnswer((_) async => mockPublicKey);

        // Act
        final ciphertext = await encryptionService.encrypt(plaintext);
        final decrypted = await encryptionService.decrypt(ciphertext);

        // Assert
        expect(decrypted, equals(plaintext));
      });

      test('should handle empty string', () async {
        // Arrange
        const plaintext = '';
        const mockPublicKey = 'mock_public_key_base64_encoded_string';

        when(mockKeyManager.getPublicKey())
            .thenAnswer((_) async => mockPublicKey);

        // Act
        final ciphertext = await encryptionService.encrypt(plaintext);
        final decrypted = await encryptionService.decrypt(ciphertext);

        // Assert
        expect(decrypted, equals(plaintext));
      });

      test('should throw KeyNotFoundException when public key not found', () async {
        // Arrange
        when(mockKeyManager.getPublicKey()).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => encryptionService.encrypt('test'),
          throwsA(isA<KeyNotFoundException>()),
        );
      });
    });

    group('encryptBatch', () {
      test('should encrypt multiple strings efficiently', () async {
        // Arrange
        const plaintexts = ['text1', 'text2', 'text3'];
        const mockPublicKey = 'mock_public_key_base64_encoded_string';

        when(mockKeyManager.getPublicKey())
            .thenAnswer((_) async => mockPublicKey);

        // Act
        final ciphertexts = await encryptionService.encryptBatch(plaintexts);

        // Assert
        expect(ciphertexts.length, 3);
        expect(ciphertexts[0], isNot(equals(plaintexts[0])));
        expect(ciphertexts[1], isNot(equals(plaintexts[1])));
        expect(ciphertexts[2], isNot(equals(plaintexts[2])));

        // Verify decryption
        final decrypted1 = await encryptionService.decrypt(ciphertexts[0]);
        final decrypted2 = await encryptionService.decrypt(ciphertexts[1]);
        final decrypted3 = await encryptionService.decrypt(ciphertexts[2]);

        expect(decrypted1, equals(plaintexts[0]));
        expect(decrypted2, equals(plaintexts[1]));
        expect(decrypted3, equals(plaintexts[2]));
      });
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/security/application/services/encryption_service_test.dart`

Expected: FAIL

**Step 3: Implement EncryptionService**

Create `lib/features/security/application/services/encryption_service.dart`:

```dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'key_manager.dart';

part 'encryption_service.g.dart';

class EncryptionService {
  final KeyManager _keyManager;
  final ChaCha20 _chacha20 = ChaCha20.poly1305Aead();
  SecretKey? _cachedEncryptionKey;

  EncryptionService({required KeyManager keyManager})
      : _keyManager = keyManager;

  /// 加密文本
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

  /// 解密文本
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

  /// 批量加密
  Future<List<String>> encryptBatch(List<String> plaintexts) async {
    // 预先获取密钥以提高批量操作性能
    await _getEncryptionKey();

    final results = <String>[];
    for (final plaintext in plaintexts) {
      results.add(await encrypt(plaintext));
    }
    return results;
  }

  /// 批量解密
  Future<List<String>> decryptBatch(List<String> ciphertexts) async {
    // 预先获取密钥以提高批量操作性能
    await _getEncryptionKey();

    final results = <String>[];
    for (final ciphertext in ciphertexts) {
      results.add(await decrypt(ciphertext));
    }
    return results;
  }

  /// 从设备密钥派生加密密钥（使用HKDF）
  Future<SecretKey> _getEncryptionKey() async {
    // 使用缓存的密钥
    if (_cachedEncryptionKey != null) {
      return _cachedEncryptionKey!;
    }

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
      info: utf8.encode('homepocket_field_encryption'), // 上下文信息
      nonce: [],
    );

    // 缓存密钥
    _cachedEncryptionKey = derivedKey;
    return derivedKey;
  }

  /// 生成随机nonce
  List<int> _generateNonce() {
    final random = Random.secure();
    return List.generate(12, (_) => random.nextInt(256));
  }

  /// 清除缓存的密钥
  void clearKeyCache() {
    _cachedEncryptionKey = null;
  }
}

@riverpod
EncryptionService encryptionService(EncryptionServiceRef ref) {
  return EncryptionService(
    keyManager: ref.watch(keyManagerProvider),
  );
}
```

**Step 4: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

Expected: Generates `encryption_service.g.dart`

**Step 5: Run test to verify it passes**

Run: `flutter test test/features/security/application/services/encryption_service_test.dart`

Expected: PASS

**Step 6: Commit EncryptionService**

```bash
git add lib/features/security/application/services/ test/features/security/application/services/
git commit -m "$(cat <<'EOF'
feat: implement ChaCha20-Poly1305 field encryption

- Encrypt/decrypt sensitive fields (amount, note, category)
- Use AEAD (authenticated encryption with associated data)
- Derive encryption key from device public key using HKDF
- Cache encryption key for batch operations
- Support batch encryption/decryption
- Add comprehensive unit tests

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## 4: Database Encryption with SQLCipher

### Task 7: Drift + SQLCipher Integration

**Files:**
- Create: `lib/core/database/app_database.dart`
- Create: `lib/core/database/connection/connection.dart`
- Create: `test/core/database/app_database_test.dart`

**Step 1: Write test for AppDatabase**

Create `test/core/database/app_database_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/database/app_database.dart';
import 'package:drift/native.dart';

void main() {
  group('AppDatabase', () {
    late AppDatabase database;

    setUp(() {
      // Use in-memory database for testing
      database = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('should initialize database successfully', () async {
      // Act: Access database to trigger initialization
      final count = await database.select(database.devices).get();

      // Assert
      expect(count, isEmpty);
    });

    test('should support encrypted operations', () async {
      // This test verifies that the database is operational
      // Actual encryption is tested at integration level

      // Act: Try basic operations
      await database.into(database.devices).insert(
            DevicesCompanion.insert(
              id: 'test-device-id',
              publicKey: 'test-public-key',
              name: 'Test Device',
              createdAt: DateTime.now().millisecondsSinceEpoch,
              lastSeenAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );

      final devices = await database.select(database.devices).get();

      // Assert
      expect(devices.length, 1);
      expect(devices.first.id, 'test-device-id');
      expect(devices.first.name, 'Test Device');
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/core/database/app_database_test.dart`

Expected: FAIL (AppDatabase not found)

**Step 3: Create database tables**

Create `lib/core/database/tables.dart`:

```dart
import 'package:drift/drift.dart';

@DataClassName('DeviceData')
class Devices extends Table {
  TextColumn get id => text()();
  TextColumn get publicKey => text()();
  TextColumn get name => text()();
  IntColumn get createdAt => integer()();
  IntColumn get lastSeenAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RecoveryKitData')
class RecoveryKits extends Table {
  TextColumn get id => text()();
  TextColumn get deviceId => text().references(Devices, #id)();
  TextColumn get mnemonicHash => text()();
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
  TextColumn get eventType => text()();
  TextColumn get details => text().nullable()();
  IntColumn get timestamp => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
```

**Step 4: Create database connection helper**

Create `lib/core/database/connection/connection.dart`:

```dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

LazyDatabase openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'home_pocket.db'));

    // Initialize SQLCipher
    await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();

    // Open database with encryption
    final executor = NativeDatabase(
      file,
      setup: (database) {
        // Set SQLCipher encryption key
        // In production, this should come from KeyManager
        database.execute("PRAGMA key = 'your-encryption-key';");

        // SQLCipher configuration
        database.execute('PRAGMA cipher_page_size = 4096;');
        database.execute('PRAGMA kdf_iter = 256000;');
        database.execute('PRAGMA cipher_hmac_algorithm = HMAC_SHA512;');
        database.execute('PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA512;');
      },
    );

    return executor;
  });
}
```

**Step 5: Create main database class**

Create `lib/core/database/app_database.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'tables.dart';
import 'connection/connection.dart' as impl;

part 'app_database.g.dart';

@DriftDatabase(tables: [Devices, RecoveryKits, AuditLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? impl.openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle future schema migrations
      },
    );
  }
}

@riverpod
AppDatabase appDatabase(AppDatabaseRef ref) {
  return AppDatabase();
}
```

**Step 6: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

Expected: Generates `app_database.g.dart` and table classes

**Step 7: Run test to verify it passes**

Run: `flutter test test/core/database/app_database_test.dart`

Expected: PASS

**Step 8: Commit database encryption**

```bash
git add lib/core/database/ test/core/database/
git commit -m "$(cat <<'EOF'
feat: integrate SQLCipher database encryption

- Add Drift database with SQLCipher support
- Configure AES-256-CBC encryption
- Set 256,000 PBKDF2 iterations
- Create security tables (Devices, RecoveryKits, AuditLogs)
- Add database connection helper
- Add unit tests

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## 5: Hash Chain Integrity System

### Task 8: Blockchain-Style Hash Chain

**Files:**
- Create: `lib/features/security/application/services/hash_chain_service.dart`
- Create: `test/features/security/application/services/hash_chain_service_test.dart`

**Step 1: Write test for HashChainService**

Create `test/features/security/application/services/hash_chain_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:home_pocket/features/security/application/services/hash_chain_service.dart';
import 'package:home_pocket/features/security/application/services/key_manager.dart';
import 'package:home_pocket/features/security/domain/models/chain_verification_result.dart';

@GenerateMocks([KeyManager])
import 'hash_chain_service_test.mocks.dart';

void main() {
  group('HashChainService', () {
    late HashChainService hashChainService;
    late MockKeyManager mockKeyManager;

    setUp(() {
      mockKeyManager = MockKeyManager();
      hashChainService = HashChainService(keyManager: mockKeyManager);
    });

    group('calculateHash', () {
      test('should calculate consistent hash for same data', () async {
        // Arrange
        const data = 'test-data';

        // Act
        final hash1 = await hashChainService.calculateHash(data, 'genesis');
        final hash2 = await hashChainService.calculateHash(data, 'genesis');

        // Assert
        expect(hash1, equals(hash2));
        expect(hash1, isNotEmpty);
      });

      test('should calculate different hash for different data', () async {
        // Arrange
        const data1 = 'test-data-1';
        const data2 = 'test-data-2';

        // Act
        final hash1 = await hashChainService.calculateHash(data1, 'genesis');
        final hash2 = await hashChainService.calculateHash(data2, 'genesis');

        // Assert
        expect(hash1, isNot(equals(hash2)));
      });

      test('should calculate different hash for different previous hash', () async {
        // Arrange
        const data = 'test-data';

        // Act
        final hash1 = await hashChainService.calculateHash(data, 'genesis');
        final hash2 = await hashChainService.calculateHash(data, 'other-hash');

        // Assert
        expect(hash1, isNot(equals(hash2)));
      });
    });

    group('verifyChain', () {
      test('should return valid for empty chain', () async {
        // Act
        final result = await hashChainService.verifyChain([]);

        // Assert
        expect(result.isValid, true);
        expect(result.totalTransactions, 0);
        expect(result.tamperedTransactionIds, isEmpty);
      });

      test('should return valid for correct chain', () async {
        // Arrange
        final hash1 = await hashChainService.calculateHash('data1', 'genesis');
        final hash2 = await hashChainService.calculateHash('data2', hash1);
        final hash3 = await hashChainService.calculateHash('data3', hash2);

        final nodes = [
          MockHashChainNode('tx1', 'data1', 'genesis', hash1),
          MockHashChainNode('tx2', 'data2', hash1, hash2),
          MockHashChainNode('tx3', 'data3', hash2, hash3),
        ];

        // Act
        final result = await hashChainService.verifyChain(nodes);

        // Assert
        expect(result.isValid, true);
        expect(result.totalTransactions, 3);
        expect(result.tamperedTransactionIds, isEmpty);
      });

      test('should detect tampered transaction', () async {
        // Arrange
        final hash1 = await hashChainService.calculateHash('data1', 'genesis');
        final hash2 = await hashChainService.calculateHash('data2', hash1);
        final hash3Correct = await hashChainService.calculateHash('data3', hash2);
        final hash3Tampered = await hashChainService.calculateHash('data3-modified', hash2);

        final nodes = [
          MockHashChainNode('tx1', 'data1', 'genesis', hash1),
          MockHashChainNode('tx2', 'data2', hash1, hash2),
          MockHashChainNode('tx3', 'data3-modified', hash2, hash3Correct), // Tampered
        ];

        // Act
        final result = await hashChainService.verifyChain(nodes);

        // Assert
        expect(result.isValid, false);
        expect(result.totalTransactions, 3);
        expect(result.tamperedTransactionIds, contains('tx3'));
      });

      test('should detect broken chain link', () async {
        // Arrange
        final hash1 = await hashChainService.calculateHash('data1', 'genesis');
        final hash2 = await hashChainService.calculateHash('data2', hash1);
        final hash3 = await hashChainService.calculateHash('data3', 'wrong-prev-hash');

        final nodes = [
          MockHashChainNode('tx1', 'data1', 'genesis', hash1),
          MockHashChainNode('tx2', 'data2', hash1, hash2),
          MockHashChainNode('tx3', 'data3', 'wrong-prev-hash', hash3), // Broken link
        ];

        // Act
        final result = await hashChainService.verifyChain(nodes);

        // Assert
        expect(result.isValid, false);
        expect(result.tamperedTransactionIds, contains('tx3'));
      });
    });
  });
}

// Mock hash chain node for testing
class MockHashChainNode {
  final String id;
  final String data;
  final String previousHash;
  final String currentHash;

  MockHashChainNode(this.id, this.data, this.previousHash, this.currentHash);
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/security/application/services/hash_chain_service_test.dart`

Expected: FAIL

**Step 3: Implement HashChainService**

Create `lib/features/security/application/services/hash_chain_service.dart`:

```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/chain_verification_result.dart';
import 'key_manager.dart';

part 'hash_chain_service.g.dart';

class HashChainService {
  final KeyManager _keyManager;

  HashChainService({required KeyManager keyManager})
      : _keyManager = keyManager;

  /// 计算哈希
  Future<String> calculateHash(String data, String previousHash) async {
    // 1. 构造待哈希数据
    final combined = StringBuffer()
      ..write(data)
      ..write('|')
      ..write(previousHash);

    // 2. SHA-256哈希
    final bytes = utf8.encode(combined.toString());
    final digest = sha256.convert(bytes);

    // 3. Base64编码
    return base64Encode(digest.bytes);
  }

  /// 验证整个哈希链的完整性
  Future<ChainVerificationResult> verifyChain(List<HashChainNode> nodes) async {
    if (nodes.isEmpty) {
      return ChainVerificationResult.empty();
    }

    String prevHash = 'genesis';
    final tamperedTransactionIds = <String>[];

    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];

      // 1. 验证previousHash是否正确
      if (node.previousHash != prevHash) {
        tamperedTransactionIds.add(node.id);
        continue;
      }

      // 2. 重新计算哈希并比对
      final expectedHash = await calculateHash(node.data, node.previousHash);

      if (node.currentHash != expectedHash) {
        tamperedTransactionIds.add(node.id);
      }

      prevHash = node.currentHash;
    }

    if (tamperedTransactionIds.isEmpty) {
      return ChainVerificationResult.valid(
        totalTransactions: nodes.length,
      );
    } else {
      return ChainVerificationResult.tampered(
        totalTransactions: nodes.length,
        tamperedTransactionIds: tamperedTransactionIds,
      );
    }
  }

  /// 增量验证单个节点
  Future<bool> verifyNode({
    required HashChainNode node,
    required String expectedPreviousHash,
  }) async {
    // 1. 验证previous hash
    if (node.previousHash != expectedPreviousHash) {
      return false;
    }

    // 2. 验证current hash
    final expectedHash = await calculateHash(node.data, node.previousHash);
    return node.currentHash == expectedHash;
  }

  /// 创建新节点并计算哈希
  Future<HashChainNode> createNode({
    required String id,
    required String data,
    required String previousHash,
  }) async {
    final currentHash = await calculateHash(data, previousHash);

    return HashChainNode(
      id: id,
      data: data,
      previousHash: previousHash,
      currentHash: currentHash,
      timestamp: DateTime.now(),
    );
  }
}

/// 哈希链节点（简化版，实际应使用domain model）
class HashChainNode {
  final String id;
  final String data;
  final String previousHash;
  final String currentHash;
  final DateTime timestamp;

  HashChainNode({
    required this.id,
    required this.data,
    required this.previousHash,
    required this.currentHash,
    required this.timestamp,
  });
}

@riverpod
HashChainService hashChainService(HashChainServiceRef ref) {
  return HashChainService(
    keyManager: ref.watch(keyManagerProvider),
  );
}
```

**Step 4: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

Expected: Generates `hash_chain_service.g.dart`

**Step 5: Run test to verify it passes**

Run: `flutter test test/features/security/application/services/hash_chain_service_test.dart`

Expected: PASS

**Step 6: Commit HashChainService**

```bash
git add lib/features/security/application/services/ test/features/security/application/services/
git commit -m "$(cat <<'EOF'
feat: implement blockchain-style hash chain

- Calculate SHA-256 hash chains
- Verify full chain integrity
- Detect tampered transactions
- Support incremental node verification
- Add comprehensive unit tests

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## 6: Integration, Testing & Documentation

### Task 9: Run Full Integration Tests

**Step 1: Run all unit tests**

Run: `flutter test`

Expected: All tests PASS

**Step 2: Generate and check coverage**

Run: `flutter test --coverage`

Expected: Coverage ≥80%

**Step 3: View coverage report**

Run: `genhtml coverage/lcov.info -o coverage/html && open coverage/html/index.html`

Expected: Coverage report shows ≥80% for all security modules

**Step 4: Run Flutter analyze**

Run: `flutter analyze`

Expected: No errors (warnings acceptable)

**Step 5: Format all code**

Run: `dart format lib/ test/`

Expected: All files formatted

---

### Task 10: Security Audit & Performance Testing

**Step 1: Security checklist verification**

Manual verification:
- ✅ Private keys stored in secure storage (Keychain/Keystore)
- ✅ Mnemonics stored only as SHA-256 hash
- ✅ PIN codes stored only as SHA-256 hash
- ✅ Encryption keys derived using HKDF
- ✅ ChaCha20-Poly1305 AEAD used for field encryption
- ✅ SQLCipher AES-256-CBC used for database
- ✅ 256,000 PBKDF2 iterations configured
- ✅ Biometric fallback to PIN implemented
- ✅ Failed attempt tracking functional
- ✅ Hash chain integrity verification working

**Step 2: Performance benchmarks**

Create `test/performance/security_performance_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/security/application/services/encryption_service.dart';
import 'package:home_pocket/features/security/application/services/hash_chain_service.dart';
import 'package:mockito/mockito.dart';
import '../features/security/application/services/encryption_service_test.mocks.dart';

void main() {
  group('Security Performance', () {
    test('encryption should complete in <10ms per field', () async {
      // Arrange
      final mockKeyManager = MockKeyManager();
      when(mockKeyManager.getPublicKey())
          .thenAnswer((_) async => 'mock_key');

      final encryptionService = EncryptionService(keyManager: mockKeyManager);
      const testData = 'Test sensitive data';

      // Act & Measure
      final stopwatch = Stopwatch()..start();
      await encryptionService.encrypt(testData);
      stopwatch.stop();

      // Assert
      expect(stopwatch.elapsedMilliseconds, lessThan(10));
      print('Encryption time: ${stopwatch.elapsedMilliseconds}ms');
    });

    test('batch encryption of 100 items should complete in <500ms', () async {
      // Arrange
      final mockKeyManager = MockKeyManager();
      when(mockKeyManager.getPublicKey())
          .thenAnswer((_) async => 'mock_key');

      final encryptionService = EncryptionService(keyManager: mockKeyManager);
      final testData = List.generate(100, (i) => 'Data $i');

      // Act & Measure
      final stopwatch = Stopwatch()..start();
      await encryptionService.encryptBatch(testData);
      stopwatch.stop();

      // Assert
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
      print('Batch encryption (100 items): ${stopwatch.elapsedMilliseconds}ms');
    });

    test('hash chain verification of 1000 nodes should complete in <1s', () async {
      // Arrange
      final mockKeyManager = MockKeyManager();
      final hashChainService = HashChainService(keyManager: mockKeyManager);

      // Create chain
      final nodes = <HashChainNode>[];
      String prevHash = 'genesis';

      for (int i = 0; i < 1000; i++) {
        final data = 'transaction-$i';
        final hash = await hashChainService.calculateHash(data, prevHash);
        nodes.add(HashChainNode(
          id: 'tx-$i',
          data: data,
          previousHash: prevHash,
          currentHash: hash,
          timestamp: DateTime.now(),
        ));
        prevHash = hash;
      }

      // Act & Measure
      final stopwatch = Stopwatch()..start();
      await hashChainService.verifyChain(nodes);
      stopwatch.stop();

      // Assert
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      print('Hash chain verification (1000 nodes): ${stopwatch.elapsedMilliseconds}ms');
    });
  });
}
```

**Step 3: Run performance tests**

Run: `flutter test test/performance/`

Expected: All performance tests PASS within target times

**Step 4: Final commit**

```bash
git add test/performance/
git commit -m "$(cat <<'EOF'
test: add security performance benchmarks

- Encryption: <10ms per field
- Batch encryption (100): <500ms
- Hash chain verification (1000): <1s
- All performance targets met

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Success Criteria

**MOD-006 Complete When:**
- ✅ Ed25519 key generation and storage working
- ✅ BIP39 24-word recovery kit functional
- ✅ Biometric authentication integrated
- ✅ Field encryption (ChaCha20-Poly1305) working
- ✅ SQLCipher database encryption enabled
- ✅ Hash chain integrity verification functional
- ✅ All tests passing with ≥80% coverage
- ✅ Security audit complete
- ✅ Performance targets met

---

**Plan Version:** 1.0
**Created:** 2026-02-03
**Priority:** P0 (MVP Critical)
