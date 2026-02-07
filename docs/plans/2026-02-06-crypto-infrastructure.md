# Crypto Infrastructure (BASIC-001) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the complete cryptographic infrastructure layer (`lib/infrastructure/crypto/`) providing Ed25519 key management, ChaCha20-Poly1305 field encryption, SHA-256 hash chain integrity, and SQLCipher database encryption.

**Architecture:** Clean Architecture with 5 layers. All crypto lives in `lib/infrastructure/crypto/`. Models use Freezed for immutability. Providers use Riverpod code generation. Repository pattern separates interfaces from implementations. Tests use mockito for platform dependencies (FlutterSecureStorage).

**Tech Stack:** Flutter/Dart, `cryptography` (Ed25519, ChaCha20-Poly1305, HKDF), `crypto` (SHA-256), `flutter_secure_storage`, `freezed`, `riverpod`, `drift` + `sqlcipher_flutter_libs`, `mockito`

---

## Current State

The project is a **blank Flutter scaffold** (default counter app). Only `lib/main.dart` exists with the template counter. No dependencies beyond flutter defaults. Everything must be built from scratch.

## Spec References

- **BASIC-001:** `docs/arch/04-basic/BASIC-001_Crypto_Infrastructure.md` - Primary implementation spec
- **ARCH-003:** `docs/arch/01-core-architecture/ARCH-003_Security_Architecture.md` - Security architecture
- **ADR-003:** `docs/arch/03-adr/ADR-003_Multi_Layer_Encryption.md` - Encryption decisions
- **ADR-006:** `docs/arch/03-adr/ADR-006_Key_Derivation_Security.md` - HKDF decisions
- **ADR-009:** `docs/arch/03-adr/ADR-009_Incremental_Hash_Chain_Verification.md` - Hash chain performance

## Target Directory Structure

```
lib/infrastructure/crypto/
├── services/
│   ├── key_manager.dart
│   ├── field_encryption_service.dart
│   └── hash_chain_service.dart
├── models/
│   ├── device_key_pair.dart
│   ├── device_key_pair.freezed.dart          (generated)
│   └── chain_verification_result.dart
│   └── chain_verification_result.freezed.dart (generated)
├── repositories/
│   ├── master_key_repository.dart             (interface) [NEW]
│   ├── master_key_repository_impl.dart        [NEW]
│   ├── key_repository.dart                    (interface)
│   ├── key_repository_impl.dart
│   ├── encryption_repository.dart             (interface)
│   └── encryption_repository_impl.dart
└── database/
    └── encrypted_database.dart
```

---

### Task 1: Add Dependencies to pubspec.yaml

**Files:**
- Modify: `pubspec.yaml`

**Step 1: Replace pubspec.yaml with all required dependencies**

```yaml
name: home_pocket
description: "Local-first, privacy-focused family accounting app."
publish_to: 'none'
version: 0.1.0+1

environment:
  sdk: ^3.10.8

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8

  # State Management
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1

  # Immutable Models
  freezed_annotation: ^3.0.0
  json_annotation: ^4.9.0

  # Cryptography
  cryptography: ^2.7.0
  crypto: ^3.0.6

  # Secure Storage
  flutter_secure_storage: ^9.2.4

  # Database
  drift: ^2.25.0
  sqlcipher_flutter_libs: ^0.6.7
  sqlite3: ^2.7.5
  path_provider: ^2.1.5
  path: ^1.9.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

  # Code Generation
  build_runner: ^2.4.14
  freezed: ^3.0.0
  json_serializable: ^6.9.4
  riverpod_generator: ^2.6.4
  custom_lint: ^0.7.5
  riverpod_lint: ^2.6.4
  drift_dev: ^2.25.0

  # Testing
  mockito: ^5.4.6
  mocktail: ^1.0.4

flutter:
  uses-material-design: true
```

**Step 2: Run flutter pub get**

Run: `flutter pub get`
Expected: Dependencies resolve successfully, `pubspec.lock` generated.

**Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add crypto infrastructure dependencies

Add cryptography, crypto, flutter_secure_storage, freezed, riverpod,
drift, sqlcipher_flutter_libs, mockito and related build tools."
```

---

### Task 2: Configure Build Tools

**Files:**
- Create: `build.yaml`
- Modify: `analysis_options.yaml`

**Step 1: Create build.yaml**

```yaml
targets:
  $default:
    builders:
      freezed:
        options:
          format: true
      json_serializable:
        options:
          explicit_to_json: true
```

**Step 2: Update analysis_options.yaml**

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  errors:
    invalid_annotation_target: ignore

linter:
  rules:
    prefer_single_quotes: true
    prefer_relative_imports: true
    avoid_print: false
```

**Step 3: Verify build_runner works**

Run: `cd /Users/xinz/Development/home-pocket-app && flutter pub run build_runner build --delete-conflicting-outputs`
Expected: Build succeeds (nothing to generate yet).

**Step 4: Commit**

```bash
git add build.yaml analysis_options.yaml
git commit -m "chore: configure build_runner and analysis options"
```

---

### Task 3: Create DeviceKeyPair Model

**Files:**
- Create: `lib/infrastructure/crypto/models/device_key_pair.dart`
- Test: `test/infrastructure/crypto/models/device_key_pair_test.dart`

**Step 1: Write the failing test**

```dart
// test/infrastructure/crypto/models/device_key_pair_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/crypto/models/device_key_pair.dart';

void main() {
  group('DeviceKeyPair', () {
    test('creates instance with required fields', () {
      final now = DateTime(2026, 2, 6);
      final keyPair = DeviceKeyPair(
        publicKey: 'dGVzdF9wdWJsaWNfa2V5',
        deviceId: 'abc123def456ghij',
        createdAt: now,
      );

      expect(keyPair.publicKey, 'dGVzdF9wdWJsaWNfa2V5');
      expect(keyPair.deviceId, 'abc123def456ghij');
      expect(keyPair.createdAt, now);
    });

    test('supports equality comparison', () {
      final now = DateTime(2026, 2, 6);
      final a = DeviceKeyPair(
        publicKey: 'key1',
        deviceId: 'device1',
        createdAt: now,
      );
      final b = DeviceKeyPair(
        publicKey: 'key1',
        deviceId: 'device1',
        createdAt: now,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('supports copyWith', () {
      final now = DateTime(2026, 2, 6);
      final original = DeviceKeyPair(
        publicKey: 'key1',
        deviceId: 'device1',
        createdAt: now,
      );
      final copied = original.copyWith(deviceId: 'device2');

      expect(copied.publicKey, 'key1');
      expect(copied.deviceId, 'device2');
      expect(copied.createdAt, now);
    });

    test('different instances are not equal', () {
      final a = DeviceKeyPair(
        publicKey: 'key1',
        deviceId: 'device1',
        createdAt: DateTime(2026, 2, 6),
      );
      final b = DeviceKeyPair(
        publicKey: 'key2',
        deviceId: 'device2',
        createdAt: DateTime(2026, 2, 7),
      );

      expect(a, isNot(equals(b)));
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/infrastructure/crypto/models/device_key_pair_test.dart`
Expected: FAIL - cannot find `device_key_pair.dart`

**Step 3: Write the model**

```dart
// lib/infrastructure/crypto/models/device_key_pair.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_key_pair.freezed.dart';

/// Device key pair model - UNIQUE definition.
///
/// Represents an Ed25519 key pair for this device.
/// All code that needs device key pair info MUST import from this file.
@freezed
class DeviceKeyPair with _$DeviceKeyPair {
  const factory DeviceKeyPair({
    /// Base64-encoded Ed25519 public key (32 bytes).
    required String publicKey,

    /// Device ID: Base64URL(SHA-256(publicKey))[0:16].
    required String deviceId,

    /// Timestamp when the key pair was generated.
    required DateTime createdAt,
  }) = _DeviceKeyPair;
}
```

**Step 4: Run code generation**

Run: `cd /Users/xinz/Development/home-pocket-app && flutter pub run build_runner build --delete-conflicting-outputs`
Expected: `device_key_pair.freezed.dart` generated.

**Step 5: Run test to verify it passes**

Run: `flutter test test/infrastructure/crypto/models/device_key_pair_test.dart`
Expected: ALL PASS

**Step 6: Commit**

```bash
git add lib/infrastructure/crypto/models/device_key_pair.dart test/infrastructure/crypto/models/device_key_pair_test.dart
git commit -m "feat: add DeviceKeyPair Freezed model

Ed25519 public key + device ID + creation timestamp.
Unique definition in lib/infrastructure/crypto/models/."
```

---

### Task 4: Create ChainVerificationResult Model

**Files:**
- Create: `lib/infrastructure/crypto/models/chain_verification_result.dart`
- Test: `test/infrastructure/crypto/models/chain_verification_result_test.dart`

**Step 1: Write the failing test**

```dart
// test/infrastructure/crypto/models/chain_verification_result_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/crypto/models/chain_verification_result.dart';

void main() {
  group('ChainVerificationResult', () {
    test('.valid() creates a valid result', () {
      final result = ChainVerificationResult.valid(totalTransactions: 100);

      expect(result.isValid, true);
      expect(result.totalTransactions, 100);
      expect(result.tamperedTransactionIds, isEmpty);
    });

    test('.tampered() creates an invalid result', () {
      final result = ChainVerificationResult.tampered(
        totalTransactions: 100,
        tamperedTransactionIds: ['tx_001', 'tx_005'],
      );

      expect(result.isValid, false);
      expect(result.totalTransactions, 100);
      expect(result.tamperedTransactionIds, ['tx_001', 'tx_005']);
    });

    test('.empty() creates a valid empty result', () {
      final result = ChainVerificationResult.empty();

      expect(result.isValid, true);
      expect(result.totalTransactions, 0);
      expect(result.tamperedTransactionIds, isEmpty);
    });

    test('supports equality comparison', () {
      final a = ChainVerificationResult.valid(totalTransactions: 50);
      final b = ChainVerificationResult.valid(totalTransactions: 50);

      expect(a, equals(b));
    });

    test('different results are not equal', () {
      final valid = ChainVerificationResult.valid(totalTransactions: 50);
      final tampered = ChainVerificationResult.tampered(
        totalTransactions: 50,
        tamperedTransactionIds: ['tx_001'],
      );

      expect(valid, isNot(equals(tampered)));
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/infrastructure/crypto/models/chain_verification_result_test.dart`
Expected: FAIL

**Step 3: Write the model**

```dart
// lib/infrastructure/crypto/models/chain_verification_result.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chain_verification_result.freezed.dart';

/// Hash chain verification result - UNIQUE definition.
///
/// All code that needs chain verification results MUST import from this file.
@freezed
class ChainVerificationResult with _$ChainVerificationResult {
  const factory ChainVerificationResult({
    required bool isValid,
    required int totalTransactions,
    required List<String> tamperedTransactionIds,
  }) = _ChainVerificationResult;

  /// Chain is valid with no tampered transactions.
  factory ChainVerificationResult.valid({required int totalTransactions}) =>
      ChainVerificationResult(
        isValid: true,
        totalTransactions: totalTransactions,
        tamperedTransactionIds: const [],
      );

  /// Chain has tampered transactions.
  factory ChainVerificationResult.tampered({
    required int totalTransactions,
    required List<String> tamperedTransactionIds,
  }) =>
      ChainVerificationResult(
        isValid: false,
        totalTransactions: totalTransactions,
        tamperedTransactionIds: tamperedTransactionIds,
      );

  /// No transactions to verify.
  factory ChainVerificationResult.empty() => const ChainVerificationResult(
        isValid: true,
        totalTransactions: 0,
        tamperedTransactionIds: [],
      );
}
```

**Step 4: Run code generation**

Run: `cd /Users/xinz/Development/home-pocket-app && flutter pub run build_runner build --delete-conflicting-outputs`
Expected: `chain_verification_result.freezed.dart` generated.

**Step 5: Run test to verify it passes**

Run: `flutter test test/infrastructure/crypto/models/chain_verification_result_test.dart`
Expected: ALL PASS

**Step 6: Commit**

```bash
git add lib/infrastructure/crypto/models/chain_verification_result.dart test/infrastructure/crypto/models/chain_verification_result_test.dart
git commit -m "feat: add ChainVerificationResult Freezed model

With .valid(), .tampered(), .empty() factory constructors.
Unique definition in lib/infrastructure/crypto/models/."
```

---

### Task 5: Create Repository Interfaces + Custom Exceptions

**Files:**
- Create: `lib/infrastructure/crypto/repositories/key_repository.dart`
- Create: `lib/infrastructure/crypto/repositories/encryption_repository.dart`
- Create: `lib/infrastructure/crypto/repositories/master_key_repository.dart`

**Step 1: Create MasterKeyRepository interface (NEW - 解决 Master Key 管理问题)**

```dart
// lib/infrastructure/crypto/repositories/master_key_repository.dart
import 'package:cryptography/cryptography.dart';

/// Master key not initialized.
class MasterKeyNotInitializedException implements Exception {
  MasterKeyNotInitializedException([this.message = 'Master key not initialized']);
  final String message;

  @override
  String toString() => 'MasterKeyNotInitializedException: $message';
}

/// Key derivation failed.
class KeyDerivationException implements Exception {
  KeyDerivationException(this.message);
  final String message;

  @override
  String toString() => 'KeyDerivationException: $message';
}

/// Abstract interface for master key management.
///
/// The master key is a 256-bit cryptographically secure random key
/// stored in platform secure storage (iOS Keychain / Android Keystore).
/// All derived keys (database, field, file, sync) are derived from this master key.
abstract class MasterKeyRepository {
  /// Initialize master key (first app launch only).
  /// Throws StateError if master key already exists.
  Future<void> initializeMasterKey();

  /// Check if master key exists.
  Future<bool> hasMasterKey();

  /// Get raw master key bytes (256-bit).
  /// Throws MasterKeyNotInitializedException if not initialized.
  Future<List<int>> getMasterKey();

  /// Derive a purpose-specific key using HKDF-SHA256.
  /// [purpose]: e.g., 'database_encryption', 'field_encryption', 'file_encryption'
  Future<SecretKey> deriveKey(String purpose);

  /// Clear master key (DANGEROUS - all data becomes unreadable).
  Future<void> clearMasterKey();
}
```

**Step 2: Create KeyRepository interface**

```dart
// lib/infrastructure/crypto/repositories/key_repository.dart
import 'package:cryptography/cryptography.dart';
import 'package:home_pocket/infrastructure/crypto/models/device_key_pair.dart';

/// Key not found in secure storage.
class KeyNotFoundException implements Exception {
  KeyNotFoundException(this.message);
  final String message;

  @override
  String toString() => 'KeyNotFoundException: $message';
}

/// Invalid seed for key recovery.
class InvalidSeedException implements Exception {
  InvalidSeedException(this.message);
  final String message;

  @override
  String toString() => 'InvalidSeedException: $message';
}

/// Abstract interface for device key pair management.
///
/// Implementations store keys in platform secure storage
/// (iOS Keychain / Android Keystore).
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

**Step 3: Create EncryptionRepository interface**

```dart
// lib/infrastructure/crypto/repositories/encryption_repository.dart

/// MAC validation failed during decryption (data tampered or wrong key).
class MacValidationException implements Exception {
  MacValidationException(this.message);
  final String message;

  @override
  String toString() => 'MacValidationException: $message';
}

/// Abstract interface for field-level encryption operations.
///
/// Uses ChaCha20-Poly1305 AEAD with HKDF-derived keys from MasterKeyRepository.
abstract class EncryptionRepository {
  Future<String> encryptField(String plaintext);
  Future<String> decryptField(String ciphertext);
  Future<String> encryptAmount(double amount);
  Future<double> decryptAmount(String encryptedAmount);
  Future<void> clearCache();
}
```

**Step 4: Verify compilation**

Run: `flutter analyze lib/infrastructure/crypto/repositories/`
Expected: No issues found.

**Step 5: Commit**

```bash
git add lib/infrastructure/crypto/repositories/master_key_repository.dart lib/infrastructure/crypto/repositories/key_repository.dart lib/infrastructure/crypto/repositories/encryption_repository.dart
git commit -m "feat: add MasterKeyRepository, KeyRepository and EncryptionRepository interfaces

MasterKeyRepository: Master key management with HKDF key derivation.
KeyRepository: Ed25519 key pair management.
EncryptionRepository: ChaCha20-Poly1305 field encryption.
Includes MasterKeyNotInitializedException, KeyDerivationException,
KeyNotFoundException, InvalidSeedException, and MacValidationException."
```

---

### Task 5.5: Implement MasterKeyRepositoryImpl (NEW - 解决 Master Key 管理问题)

**Files:**
- Create: `lib/infrastructure/crypto/repositories/master_key_repository_impl.dart`
- Test: `test/infrastructure/crypto/repositories/master_key_repository_impl_test.dart`

**Step 1: Write the failing tests**

```dart
// test/infrastructure/crypto/repositories/master_key_repository_impl_test.dart
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/master_key_repository.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/master_key_repository_impl.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late MasterKeyRepositoryImpl repository;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    repository = MasterKeyRepositoryImpl(secureStorage: mockStorage);
  });

  group('initializeMasterKey', () {
    test('creates and stores 256-bit master key on first call', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      await repository.initializeMasterKey();

      verify(() => mockStorage.write(
        key: 'master_key',
        value: any(named: 'value', that: hasLength(44)), // Base64(32 bytes)
      )).called(1);
    });

    test('throws StateError if master key already exists', () async {
      when(() => mockStorage.read(key: 'master_key'))
          .thenAnswer((_) async => 'existing_key');

      expect(
        () => repository.initializeMasterKey(),
        throwsStateError,
      );
    });
  });

  group('hasMasterKey', () {
    test('returns true when master key exists', () async {
      when(() => mockStorage.read(key: 'master_key'))
          .thenAnswer((_) async => 'some_base64_key');

      expect(await repository.hasMasterKey(), true);
    });

    test('returns false when master key does not exist', () async {
      when(() => mockStorage.read(key: 'master_key'))
          .thenAnswer((_) async => null);

      expect(await repository.hasMasterKey(), false);
    });
  });

  group('getMasterKey', () {
    test('returns master key bytes when initialized', () async {
      final testKey = List<int>.filled(32, 42);
      final testKeyBase64 = base64Encode(testKey);
      when(() => mockStorage.read(key: 'master_key'))
          .thenAnswer((_) async => testKeyBase64);

      final result = await repository.getMasterKey();

      expect(result, equals(testKey));
    });

    test('throws MasterKeyNotInitializedException when not initialized', () async {
      when(() => mockStorage.read(key: 'master_key'))
          .thenAnswer((_) async => null);

      expect(
        () => repository.getMasterKey(),
        throwsA(isA<MasterKeyNotInitializedException>()),
      );
    });
  });

  group('deriveKey', () {
    test('derives different keys for different purposes', () async {
      final testKey = List<int>.filled(32, 42);
      final testKeyBase64 = base64Encode(testKey);
      when(() => mockStorage.read(key: 'master_key'))
          .thenAnswer((_) async => testKeyBase64);

      final dbKey = await repository.deriveKey('database_encryption');
      final fieldKey = await repository.deriveKey('field_encryption');

      final dbBytes = await dbKey.extractBytes();
      final fieldBytes = await fieldKey.extractBytes();

      expect(dbBytes, isNot(equals(fieldBytes)));
      expect(dbBytes.length, 32);
      expect(fieldBytes.length, 32);
    });
  });
}
```

**Step 2: Implement MasterKeyRepositoryImpl**

```dart
// lib/infrastructure/crypto/repositories/master_key_repository_impl.dart
import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/master_key_repository.dart';

/// Implementation of [MasterKeyRepository] using FlutterSecureStorage.
///
/// The master key is a 256-bit (32-byte) cryptographically secure random key.
/// All encryption keys are derived from this master key using HKDF-SHA256.
class MasterKeyRepositoryImpl implements MasterKeyRepository {
  MasterKeyRepositoryImpl({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage;

  final FlutterSecureStorage _secureStorage;

  static const String _masterKeyStorageKey = 'master_key';
  static const String _hkdfSalt = 'homepocket-v1-2026';

  // Cache for derived keys to avoid repeated HKDF operations
  final Map<String, SecretKey> _derivedKeyCache = {};

  @override
  Future<void> initializeMasterKey() async {
    if (await hasMasterKey()) {
      throw StateError('Master key already exists. Cannot reinitialize.');
    }

    // Generate 256-bit cryptographically secure random key
    final random = Random.secure();
    final masterKeyBytes = List<int>.generate(32, (_) => random.nextInt(256));

    // Store in secure storage
    await _secureStorage.write(
      key: _masterKeyStorageKey,
      value: base64Encode(masterKeyBytes),
    );
  }

  @override
  Future<bool> hasMasterKey() async {
    final value = await _secureStorage.read(key: _masterKeyStorageKey);
    return value != null && value.isNotEmpty;
  }

  @override
  Future<List<int>> getMasterKey() async {
    final value = await _secureStorage.read(key: _masterKeyStorageKey);
    if (value == null || value.isEmpty) {
      throw MasterKeyNotInitializedException();
    }
    return base64Decode(value);
  }

  @override
  Future<SecretKey> deriveKey(String purpose) async {
    // Check cache first
    if (_derivedKeyCache.containsKey(purpose)) {
      return _derivedKeyCache[purpose]!;
    }

    final masterKeyBytes = await getMasterKey();

    // Use HKDF-SHA256 to derive purpose-specific key
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final derivedKey = await hkdf.deriveKey(
      secretKey: SecretKey(masterKeyBytes),
      info: utf8.encode(purpose),
      nonce: utf8.encode(_hkdfSalt),
    );

    // Cache the derived key
    _derivedKeyCache[purpose] = derivedKey;

    return derivedKey;
  }

  @override
  Future<void> clearMasterKey() async {
    _derivedKeyCache.clear();
    await _secureStorage.delete(key: _masterKeyStorageKey);
  }
}
```

**Step 3: Run tests**

Run: `flutter test test/infrastructure/crypto/repositories/master_key_repository_impl_test.dart`
Expected: All 6 tests pass.

**Step 4: Commit**

```bash
git add lib/infrastructure/crypto/repositories/master_key_repository_impl.dart test/infrastructure/crypto/repositories/master_key_repository_impl_test.dart
git commit -m "feat: implement MasterKeyRepositoryImpl with HKDF key derivation

256-bit master key with HKDF-SHA256 for purpose-specific key derivation.
Supports database, field, file, and sync encryption keys.
Uses FlutterSecureStorage for iOS Keychain / Android Keystore."
```

---

### Task 6: Implement HashChainService (TDD)


**Files:**
- Create: `lib/infrastructure/crypto/services/hash_chain_service.dart`
- Test: `test/infrastructure/crypto/services/hash_chain_service_test.dart`

**Step 1: Write the failing tests**

```dart
// test/infrastructure/crypto/services/hash_chain_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/crypto/models/chain_verification_result.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';

void main() {
  late HashChainService service;

  setUp(() {
    service = HashChainService();
  });

  group('calculateTransactionHash', () {
    test('produces a 64-character hex SHA-256 hash', () {
      final hash = service.calculateTransactionHash(
        transactionId: 'tx_001',
        amount: 1500.0,
        timestamp: 1706000000000,
        previousHash: 'genesis',
      );

      expect(hash.length, 64);
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hash), true);
    });

    test('same inputs produce same hash (deterministic)', () {
      final hash1 = service.calculateTransactionHash(
        transactionId: 'tx_001',
        amount: 1500.0,
        timestamp: 1706000000000,
        previousHash: 'genesis',
      );
      final hash2 = service.calculateTransactionHash(
        transactionId: 'tx_001',
        amount: 1500.0,
        timestamp: 1706000000000,
        previousHash: 'genesis',
      );

      expect(hash1, equals(hash2));
    });

    test('different inputs produce different hashes', () {
      final hash1 = service.calculateTransactionHash(
        transactionId: 'tx_001',
        amount: 1500.0,
        timestamp: 1706000000000,
        previousHash: 'genesis',
      );
      final hash2 = service.calculateTransactionHash(
        transactionId: 'tx_002',
        amount: 1500.0,
        timestamp: 1706000000000,
        previousHash: 'genesis',
      );

      expect(hash1, isNot(equals(hash2)));
    });

    test('changing amount changes hash', () {
      final hash1 = service.calculateTransactionHash(
        transactionId: 'tx_001',
        amount: 1500.0,
        timestamp: 1706000000000,
        previousHash: 'genesis',
      );
      final hash2 = service.calculateTransactionHash(
        transactionId: 'tx_001',
        amount: 1500.01,
        timestamp: 1706000000000,
        previousHash: 'genesis',
      );

      expect(hash1, isNot(equals(hash2)));
    });
  });

  group('verifyTransactionIntegrity', () {
    test('returns true for valid transaction', () {
      final hash = service.calculateTransactionHash(
        transactionId: 'tx_001',
        amount: 1500.0,
        timestamp: 1706000000000,
        previousHash: 'genesis',
      );

      final isValid = service.verifyTransactionIntegrity(
        transactionId: 'tx_001',
        amount: 1500.0,
        timestamp: 1706000000000,
        previousHash: 'genesis',
        currentHash: hash,
      );

      expect(isValid, true);
    });

    test('returns false for tampered amount', () {
      final hash = service.calculateTransactionHash(
        transactionId: 'tx_001',
        amount: 1500.0,
        timestamp: 1706000000000,
        previousHash: 'genesis',
      );

      final isValid = service.verifyTransactionIntegrity(
        transactionId: 'tx_001',
        amount: 9999.0, // tampered
        timestamp: 1706000000000,
        previousHash: 'genesis',
        currentHash: hash,
      );

      expect(isValid, false);
    });

    test('returns false for tampered previousHash', () {
      final hash = service.calculateTransactionHash(
        transactionId: 'tx_001',
        amount: 1500.0,
        timestamp: 1706000000000,
        previousHash: 'genesis',
      );

      final isValid = service.verifyTransactionIntegrity(
        transactionId: 'tx_001',
        amount: 1500.0,
        timestamp: 1706000000000,
        previousHash: 'tampered_hash',
        currentHash: hash,
      );

      expect(isValid, false);
    });
  });

  group('verifyChain', () {
    test('returns valid for empty list', () {
      final result = service.verifyChain([]);

      expect(result.isValid, true);
      expect(result.totalTransactions, 0);
    });

    test('verifies a valid chain of 3 transactions', () {
      final hash1 = service.calculateTransactionHash(
        transactionId: 'tx_001',
        amount: 100.0,
        timestamp: 1000,
        previousHash: 'genesis',
      );
      final hash2 = service.calculateTransactionHash(
        transactionId: 'tx_002',
        amount: 200.0,
        timestamp: 2000,
        previousHash: hash1,
      );
      final hash3 = service.calculateTransactionHash(
        transactionId: 'tx_003',
        amount: 300.0,
        timestamp: 3000,
        previousHash: hash2,
      );

      final transactions = [
        {
          'transactionId': 'tx_001', 'amount': 100.0,
          'timestamp': 1000, 'previousHash': 'genesis', 'currentHash': hash1,
        },
        {
          'transactionId': 'tx_002', 'amount': 200.0,
          'timestamp': 2000, 'previousHash': hash1, 'currentHash': hash2,
        },
        {
          'transactionId': 'tx_003', 'amount': 300.0,
          'timestamp': 3000, 'previousHash': hash2, 'currentHash': hash3,
        },
      ];

      final result = service.verifyChain(transactions);

      expect(result.isValid, true);
      expect(result.totalTransactions, 3);
      expect(result.tamperedTransactionIds, isEmpty);
    });

    test('detects tampered transaction in chain', () {
      final hash1 = service.calculateTransactionHash(
        transactionId: 'tx_001',
        amount: 100.0,
        timestamp: 1000,
        previousHash: 'genesis',
      );
      final hash2 = service.calculateTransactionHash(
        transactionId: 'tx_002',
        amount: 200.0,
        timestamp: 2000,
        previousHash: hash1,
      );

      final transactions = [
        {
          'transactionId': 'tx_001', 'amount': 100.0,
          'timestamp': 1000, 'previousHash': 'genesis', 'currentHash': hash1,
        },
        {
          'transactionId': 'tx_002', 'amount': 999.0, // tampered
          'timestamp': 2000, 'previousHash': hash1, 'currentHash': hash2,
        },
      ];

      final result = service.verifyChain(transactions);

      expect(result.isValid, false);
      expect(result.tamperedTransactionIds, contains('tx_002'));
    });
  });

  group('verifyChainIncremental', () {
    test('with lastVerifiedIndex=-1, verifies entire chain', () {
      final hash1 = service.calculateTransactionHash(
        transactionId: 'tx_001',
        amount: 100.0,
        timestamp: 1000,
        previousHash: 'genesis',
      );

      final transactions = [
        {
          'transactionId': 'tx_001', 'amount': 100.0,
          'timestamp': 1000, 'previousHash': 'genesis', 'currentHash': hash1,
        },
      ];

      final result = service.verifyChainIncremental(
        transactions,
        lastVerifiedIndex: -1,
      );

      expect(result.isValid, true);
      expect(result.totalTransactions, 1);
    });

    test('skips already-verified transactions', () {
      final hash1 = service.calculateTransactionHash(
        transactionId: 'tx_001',
        amount: 100.0,
        timestamp: 1000,
        previousHash: 'genesis',
      );
      final hash2 = service.calculateTransactionHash(
        transactionId: 'tx_002',
        amount: 200.0,
        timestamp: 2000,
        previousHash: hash1,
      );
      final hash3 = service.calculateTransactionHash(
        transactionId: 'tx_003',
        amount: 300.0,
        timestamp: 3000,
        previousHash: hash2,
      );

      final transactions = [
        {
          'transactionId': 'tx_001', 'amount': 100.0,
          'timestamp': 1000, 'previousHash': 'genesis', 'currentHash': hash1,
        },
        {
          'transactionId': 'tx_002', 'amount': 200.0,
          'timestamp': 2000, 'previousHash': hash1, 'currentHash': hash2,
        },
        {
          'transactionId': 'tx_003', 'amount': 300.0,
          'timestamp': 3000, 'previousHash': hash2, 'currentHash': hash3,
        },
      ];

      // Verify only from index 1 onwards (skip tx_001)
      final result = service.verifyChainIncremental(
        transactions,
        lastVerifiedIndex: 0,
      );

      expect(result.isValid, true);
      expect(result.totalTransactions, 3);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/infrastructure/crypto/services/hash_chain_service_test.dart`
Expected: FAIL - cannot find `hash_chain_service.dart`

**Step 3: Implement HashChainService**

```dart
// lib/infrastructure/crypto/services/hash_chain_service.dart
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:home_pocket/infrastructure/crypto/models/chain_verification_result.dart';

/// Stateless service for blockchain-style transaction integrity.
///
/// Uses SHA-256 to compute and verify hash chains.
/// See ADR-009 for incremental verification design.
class HashChainService {
  /// Hash formula: SHA-256(transactionId|amount|timestamp|previousHash)
  String calculateTransactionHash({
    required String transactionId,
    required double amount,
    required int timestamp,
    required String previousHash,
  }) {
    final input = '$transactionId|$amount|$timestamp|$previousHash';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify a single transaction's hash matches its data.
  bool verifyTransactionIntegrity({
    required String transactionId,
    required double amount,
    required int timestamp,
    required String previousHash,
    required String currentHash,
  }) {
    final calculated = calculateTransactionHash(
      transactionId: transactionId,
      amount: amount,
      timestamp: timestamp,
      previousHash: previousHash,
    );
    return calculated == currentHash;
  }

  /// Verify an entire chain from genesis.
  ///
  /// Each entry in [transactions] must have keys:
  /// `transactionId`, `amount`, `timestamp`, `previousHash`, `currentHash`.
  ChainVerificationResult verifyChain(List<Map<String, dynamic>> transactions) {
    if (transactions.isEmpty) {
      return ChainVerificationResult.empty();
    }

    final tamperedIds = <String>[];

    for (int i = 0; i < transactions.length; i++) {
      final tx = transactions[i];
      final isValid = verifyTransactionIntegrity(
        transactionId: tx['transactionId'] as String,
        amount: (tx['amount'] as num).toDouble(),
        timestamp: tx['timestamp'] as int,
        previousHash: tx['previousHash'] as String,
        currentHash: tx['currentHash'] as String,
      );

      if (!isValid) {
        tamperedIds.add(tx['transactionId'] as String);
      }

      // Verify chain linkage (currentHash of tx[i] == previousHash of tx[i+1])
      if (i < transactions.length - 1) {
        final nextTx = transactions[i + 1];
        if (nextTx['previousHash'] != tx['currentHash']) {
          tamperedIds.add(nextTx['transactionId'] as String);
        }
      }
    }

    if (tamperedIds.isEmpty) {
      return ChainVerificationResult.valid(
        totalTransactions: transactions.length,
      );
    }

    return ChainVerificationResult.tampered(
      totalTransactions: transactions.length,
      tamperedTransactionIds: tamperedIds.toSet().toList(),
    );
  }

  /// Incremental verification starting after [lastVerifiedIndex].
  ///
  /// When [lastVerifiedIndex] is -1, equivalent to full verification.
  /// Performance: 100-2000x faster than full verification for large chains.
  ChainVerificationResult verifyChainIncremental(
    List<Map<String, dynamic>> transactions, {
    required int lastVerifiedIndex,
  }) {
    if (transactions.isEmpty) {
      return ChainVerificationResult.empty();
    }

    final startIndex = lastVerifiedIndex + 1;
    if (startIndex >= transactions.length) {
      return ChainVerificationResult.valid(
        totalTransactions: transactions.length,
      );
    }

    final tamperedIds = <String>[];

    for (int i = startIndex; i < transactions.length; i++) {
      final tx = transactions[i];
      final isValid = verifyTransactionIntegrity(
        transactionId: tx['transactionId'] as String,
        amount: (tx['amount'] as num).toDouble(),
        timestamp: tx['timestamp'] as int,
        previousHash: tx['previousHash'] as String,
        currentHash: tx['currentHash'] as String,
      );

      if (!isValid) {
        tamperedIds.add(tx['transactionId'] as String);
      }

      if (i < transactions.length - 1) {
        final nextTx = transactions[i + 1];
        if (nextTx['previousHash'] != tx['currentHash']) {
          tamperedIds.add(nextTx['transactionId'] as String);
        }
      }
    }

    if (tamperedIds.isEmpty) {
      return ChainVerificationResult.valid(
        totalTransactions: transactions.length,
      );
    }

    return ChainVerificationResult.tampered(
      totalTransactions: transactions.length,
      tamperedTransactionIds: tamperedIds.toSet().toList(),
    );
  }
}
```

**Step 4: Run tests to verify they pass**

Run: `flutter test test/infrastructure/crypto/services/hash_chain_service_test.dart`
Expected: ALL PASS

**Step 5: Commit**

```bash
git add lib/infrastructure/crypto/services/hash_chain_service.dart test/infrastructure/crypto/services/hash_chain_service_test.dart
git commit -m "feat: implement HashChainService with SHA-256 hash chain

Stateless service for transaction integrity verification.
Supports full chain and incremental verification (ADR-009)."
```

---

### Task 7: Implement KeyRepositoryImpl (TDD)

**Files:**
- Create: `lib/infrastructure/crypto/repositories/key_repository_impl.dart`
- Test: `test/infrastructure/crypto/repositories/key_repository_impl_test.dart`

**Step 1: Write the failing tests**

```dart
// test/infrastructure/crypto/repositories/key_repository_impl_test.dart
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/key_repository.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/key_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late KeyRepositoryImpl repository;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    repository = KeyRepositoryImpl(secureStorage: mockStorage);
  });

  group('hasKeyPair', () {
    test('returns false when no key exists', () async {
      when(() => mockStorage.read(key: 'device_private_key'))
          .thenAnswer((_) async => null);

      expect(await repository.hasKeyPair(), false);
    });

    test('returns true when key exists', () async {
      when(() => mockStorage.read(key: 'device_private_key'))
          .thenAnswer((_) async => 'some_key_data');

      expect(await repository.hasKeyPair(), true);
    });
  });

  group('generateKeyPair', () {
    test('generates and stores Ed25519 key pair', () async {
      when(() => mockStorage.read(key: 'device_private_key'))
          .thenAnswer((_) async => null);
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      final keyPair = await repository.generateKeyPair();

      expect(keyPair.publicKey, isNotEmpty);
      expect(keyPair.deviceId.length, 16);
      expect(keyPair.createdAt, isNotNull);

      verify(() => mockStorage.write(key: 'device_private_key', value: any(named: 'value'))).called(1);
      verify(() => mockStorage.write(key: 'device_public_key', value: any(named: 'value'))).called(1);
      verify(() => mockStorage.write(key: 'device_id', value: any(named: 'value'))).called(1);
    });

    test('throws StateError if key pair already exists', () async {
      when(() => mockStorage.read(key: 'device_private_key'))
          .thenAnswer((_) async => 'existing_key');

      expect(
        () => repository.generateKeyPair(),
        throwsStateError,
      );
    });
  });

  group('getPublicKey', () {
    test('returns stored public key', () async {
      when(() => mockStorage.read(key: 'device_public_key'))
          .thenAnswer((_) async => 'test_public_key');

      expect(await repository.getPublicKey(), 'test_public_key');
    });

    test('returns null when no key stored', () async {
      when(() => mockStorage.read(key: 'device_public_key'))
          .thenAnswer((_) async => null);

      expect(await repository.getPublicKey(), null);
    });
  });

  group('getDeviceId', () {
    test('returns stored device id', () async {
      when(() => mockStorage.read(key: 'device_id'))
          .thenAnswer((_) async => 'abc123def456ghij');

      expect(await repository.getDeviceId(), 'abc123def456ghij');
    });
  });

  group('signData and verifySignature', () {
    test('sign then verify round-trip succeeds', () async {
      // Generate a real key pair for sign/verify test
      final ed25519 = Ed25519();
      final realKeyPair = await ed25519.newKeyPair();
      final privateKeyBytes = await realKeyPair.extractPrivateKeyBytes();
      final publicKey = await realKeyPair.extractPublicKey();
      final publicKeyBase64 = base64Encode(publicKey.bytes);

      when(() => mockStorage.read(key: 'device_private_key'))
          .thenAnswer((_) async => base64Encode(privateKeyBytes));

      final data = utf8.encode('hello world');
      final signature = await repository.signData(data);

      final isValid = await repository.verifySignature(
        data: data,
        signature: signature,
        publicKeyBase64: publicKeyBase64,
      );

      expect(isValid, true);
    });

    test('verify fails with wrong data', () async {
      final ed25519 = Ed25519();
      final realKeyPair = await ed25519.newKeyPair();
      final privateKeyBytes = await realKeyPair.extractPrivateKeyBytes();
      final publicKey = await realKeyPair.extractPublicKey();
      final publicKeyBase64 = base64Encode(publicKey.bytes);

      when(() => mockStorage.read(key: 'device_private_key'))
          .thenAnswer((_) async => base64Encode(privateKeyBytes));

      final data = utf8.encode('hello world');
      final signature = await repository.signData(data);

      final isValid = await repository.verifySignature(
        data: utf8.encode('tampered data'),
        signature: signature,
        publicKeyBase64: publicKeyBase64,
      );

      expect(isValid, false);
    });

    test('signData throws KeyNotFoundException when no key', () async {
      when(() => mockStorage.read(key: 'device_private_key'))
          .thenAnswer((_) async => null);

      expect(
        () => repository.signData(utf8.encode('data')),
        throwsA(isA<KeyNotFoundException>()),
      );
    });
  });

  group('clearKeys', () {
    test('deletes all key entries', () async {
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      await repository.clearKeys();

      verify(() => mockStorage.delete(key: 'device_private_key')).called(1);
      verify(() => mockStorage.delete(key: 'device_public_key')).called(1);
      verify(() => mockStorage.delete(key: 'device_id')).called(1);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/infrastructure/crypto/repositories/key_repository_impl_test.dart`
Expected: FAIL

**Step 3: Implement KeyRepositoryImpl**

```dart
// lib/infrastructure/crypto/repositories/key_repository_impl.dart
import 'dart:convert';

import 'package:crypto/crypto.dart' as hash_lib;
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:home_pocket/infrastructure/crypto/models/device_key_pair.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/key_repository.dart';

class KeyRepositoryImpl implements KeyRepository {
  KeyRepositoryImpl({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage;

  final FlutterSecureStorage _secureStorage;
  final _ed25519 = Ed25519();

  static const _privateKeyKey = 'device_private_key';
  static const _publicKeyKey = 'device_public_key';
  static const _deviceIdKey = 'device_id';

  @override
  Future<bool> hasKeyPair() async {
    final key = await _secureStorage.read(key: _privateKeyKey);
    return key != null;
  }

  @override
  Future<DeviceKeyPair> generateKeyPair() async {
    if (await hasKeyPair()) {
      throw StateError('Key pair already exists. Call clearKeys() first.');
    }

    final keyPair = await _ed25519.newKeyPair();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();
    final publicKeyBase64 = base64Encode(publicKey.bytes);
    final deviceId = _generateDeviceId(publicKey.bytes);

    await _secureStorage.write(
      key: _privateKeyKey,
      value: base64Encode(privateKeyBytes),
    );
    await _secureStorage.write(key: _publicKeyKey, value: publicKeyBase64);
    await _secureStorage.write(key: _deviceIdKey, value: deviceId);

    return DeviceKeyPair(
      publicKey: publicKeyBase64,
      deviceId: deviceId,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<DeviceKeyPair> recoverFromSeed(List<int> seed) async {
    if (seed.length != 32) {
      throw InvalidSeedException(
        'Seed must be 32 bytes, got ${seed.length}',
      );
    }

    final keyPair = await _ed25519.newKeyPairFromSeed(seed);
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();
    final publicKeyBase64 = base64Encode(publicKey.bytes);
    final deviceId = _generateDeviceId(publicKey.bytes);

    await _secureStorage.write(
      key: _privateKeyKey,
      value: base64Encode(privateKeyBytes),
    );
    await _secureStorage.write(key: _publicKeyKey, value: publicKeyBase64);
    await _secureStorage.write(key: _deviceIdKey, value: deviceId);

    return DeviceKeyPair(
      publicKey: publicKeyBase64,
      deviceId: deviceId,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<String?> getPublicKey() async {
    return _secureStorage.read(key: _publicKeyKey);
  }

  @override
  Future<String?> getDeviceId() async {
    return _secureStorage.read(key: _deviceIdKey);
  }

  @override
  Future<Signature> signData(List<int> data) async {
    final privateKeyStr = await _secureStorage.read(key: _privateKeyKey);
    if (privateKeyStr == null) {
      throw KeyNotFoundException('Private key not found in secure storage');
    }

    final privateKeyBytes = base64Decode(privateKeyStr);
    final keyPair = await _ed25519.newKeyPairFromSeed(privateKeyBytes);
    final signature = await _ed25519.sign(data, keyPair: keyPair);
    return signature;
  }

  @override
  Future<bool> verifySignature({
    required List<int> data,
    required Signature signature,
    required String publicKeyBase64,
  }) async {
    final publicKeyBytes = base64Decode(publicKeyBase64);
    final publicKey = SimplePublicKey(
      publicKeyBytes,
      type: KeyPairType.ed25519,
    );

    return _ed25519.verify(
      data,
      signature: Signature(signature.bytes, publicKey: publicKey),
    );
  }

  @override
  Future<void> clearKeys() async {
    await _secureStorage.delete(key: _privateKeyKey);
    await _secureStorage.delete(key: _publicKeyKey);
    await _secureStorage.delete(key: _deviceIdKey);
  }

  /// Base64URL(SHA-256(publicKey))[0:16]
  String _generateDeviceId(List<int> publicKeyBytes) {
    final digest = hash_lib.sha256.convert(publicKeyBytes);
    return base64UrlEncode(digest.bytes).substring(0, 16);
  }
}
```

**Step 4: Run tests**

Run: `flutter test test/infrastructure/crypto/repositories/key_repository_impl_test.dart`
Expected: ALL PASS

**Step 5: Commit**

```bash
git add lib/infrastructure/crypto/repositories/key_repository_impl.dart test/infrastructure/crypto/repositories/key_repository_impl_test.dart
git commit -m "feat: implement KeyRepositoryImpl with Ed25519 key management

Ed25519 key generation, signing, verification. Keys stored in
FlutterSecureStorage. Device ID from SHA-256 of public key."
```

---

### Task 8: Implement KeyManager (TDD)

**Files:**
- Create: `lib/infrastructure/crypto/services/key_manager.dart`
- Test: `test/infrastructure/crypto/services/key_manager_test.dart`

**Step 1: Write the failing tests**

```dart
// test/infrastructure/crypto/services/key_manager_test.dart
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/crypto/models/device_key_pair.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/key_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:mocktail/mocktail.dart';

class MockKeyRepository extends Mock implements KeyRepository {}

void main() {
  late MockKeyRepository mockRepo;
  late KeyManager keyManager;

  setUp(() {
    mockRepo = MockKeyRepository();
    keyManager = KeyManager(repository: mockRepo);
  });

  group('hasKeyPair', () {
    test('delegates to repository', () async {
      when(() => mockRepo.hasKeyPair()).thenAnswer((_) async => true);

      expect(await keyManager.hasKeyPair(), true);
      verify(() => mockRepo.hasKeyPair()).called(1);
    });
  });

  group('generateDeviceKeyPair', () {
    test('delegates to repository', () async {
      final expected = DeviceKeyPair(
        publicKey: 'pk',
        deviceId: 'did',
        createdAt: DateTime(2026),
      );
      when(() => mockRepo.generateKeyPair())
          .thenAnswer((_) async => expected);

      final result = await keyManager.generateDeviceKeyPair();

      expect(result, expected);
      verify(() => mockRepo.generateKeyPair()).called(1);
    });
  });

  group('getPublicKey', () {
    test('delegates to repository', () async {
      when(() => mockRepo.getPublicKey())
          .thenAnswer((_) async => 'public_key_base64');

      expect(await keyManager.getPublicKey(), 'public_key_base64');
    });
  });

  group('getDeviceId', () {
    test('delegates to repository', () async {
      when(() => mockRepo.getDeviceId())
          .thenAnswer((_) async => 'device_id_16ch');

      expect(await keyManager.getDeviceId(), 'device_id_16ch');
    });
  });

  group('signData', () {
    test('delegates to repository', () async {
      final fakeSignature = Signature(
        [1, 2, 3],
        publicKey: SimplePublicKey([4, 5, 6], type: KeyPairType.ed25519),
      );
      when(() => mockRepo.signData(any()))
          .thenAnswer((_) async => fakeSignature);

      final result = await keyManager.signData(utf8.encode('data'));

      expect(result, fakeSignature);
    });
  });

  group('verifySignature', () {
    test('delegates to repository', () async {
      final fakeSignature = Signature(
        [1, 2, 3],
        publicKey: SimplePublicKey([4, 5, 6], type: KeyPairType.ed25519),
      );
      when(() => mockRepo.verifySignature(
            data: any(named: 'data'),
            signature: any(named: 'signature'),
            publicKeyBase64: any(named: 'publicKeyBase64'),
          )).thenAnswer((_) async => true);

      final result = await keyManager.verifySignature(
        data: utf8.encode('data'),
        signature: fakeSignature,
        publicKeyBase64: 'pk_base64',
      );

      expect(result, true);
    });
  });

  group('recoverFromSeed', () {
    test('delegates to repository', () async {
      final seed = List<int>.generate(32, (i) => i);
      final expected = DeviceKeyPair(
        publicKey: 'pk',
        deviceId: 'did',
        createdAt: DateTime(2026),
      );
      when(() => mockRepo.recoverFromSeed(any()))
          .thenAnswer((_) async => expected);

      final result = await keyManager.recoverFromSeed(seed);

      expect(result, expected);
      verify(() => mockRepo.recoverFromSeed(seed)).called(1);
    });
  });

  group('clearKeys', () {
    test('delegates to repository', () async {
      when(() => mockRepo.clearKeys()).thenAnswer((_) async {});

      await keyManager.clearKeys();

      verify(() => mockRepo.clearKeys()).called(1);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/infrastructure/crypto/services/key_manager_test.dart`
Expected: FAIL

**Step 3: Implement KeyManager**

```dart
// lib/infrastructure/crypto/services/key_manager.dart
import 'package:cryptography/cryptography.dart';
import 'package:home_pocket/infrastructure/crypto/models/device_key_pair.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/key_repository.dart';

/// High-level key management service.
///
/// Delegates to [KeyRepository] for storage operations.
/// This is the primary API for key operations throughout the app.
class KeyManager {
  KeyManager({required KeyRepository repository}) : _repository = repository;

  final KeyRepository _repository;

  Future<DeviceKeyPair> generateDeviceKeyPair() =>
      _repository.generateKeyPair();

  Future<String?> getPublicKey() => _repository.getPublicKey();

  Future<String?> getDeviceId() => _repository.getDeviceId();

  Future<bool> hasKeyPair() => _repository.hasKeyPair();

  Future<Signature> signData(List<int> data) => _repository.signData(data);

  Future<bool> verifySignature({
    required List<int> data,
    required Signature signature,
    required String publicKeyBase64,
  }) =>
      _repository.verifySignature(
        data: data,
        signature: signature,
        publicKeyBase64: publicKeyBase64,
      );

  Future<DeviceKeyPair> recoverFromSeed(List<int> seed) =>
      _repository.recoverFromSeed(seed);

  Future<void> clearKeys() => _repository.clearKeys();
}
```

**Step 4: Run tests**

Run: `flutter test test/infrastructure/crypto/services/key_manager_test.dart`
Expected: ALL PASS

**Step 5: Commit**

```bash
git add lib/infrastructure/crypto/services/key_manager.dart test/infrastructure/crypto/services/key_manager_test.dart
git commit -m "feat: implement KeyManager service

Thin delegation layer over KeyRepository. Primary API for all
key operations (generate, sign, verify, recover, clear)."
```

---

### Task 9: Implement EncryptionRepositoryImpl (TDD)

**Files:**
- Create: `lib/infrastructure/crypto/repositories/encryption_repository_impl.dart`
- Test: `test/infrastructure/crypto/repositories/encryption_repository_impl_test.dart`

**Step 1: Write the failing tests**

```dart
// test/infrastructure/crypto/repositories/encryption_repository_impl_test.dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/encryption_repository.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/encryption_repository_impl.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/key_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockKeyRepository extends Mock implements KeyRepository {}

void main() {
  late MockKeyRepository mockKeyRepo;
  late EncryptionRepositoryImpl repository;

  setUp(() {
    mockKeyRepo = MockKeyRepository();
    repository = EncryptionRepositoryImpl(keyRepository: mockKeyRepo);

    // Return a consistent fake public key for HKDF derivation
    when(() => mockKeyRepo.getPublicKey()).thenAnswer(
      (_) async => base64Encode(List<int>.generate(32, (i) => i + 1)),
    );
  });

  group('encryptField / decryptField', () {
    test('encrypt then decrypt round-trip returns original text', () async {
      const plaintext = 'lunch expense';
      final encrypted = await repository.encryptField(plaintext);
      final decrypted = await repository.decryptField(encrypted);

      expect(decrypted, plaintext);
    });

    test('encrypted output is Base64 and differs from plaintext', () async {
      const plaintext = 'secret note';
      final encrypted = await repository.encryptField(plaintext);

      expect(encrypted, isNot(equals(plaintext)));
      // Should be valid Base64
      expect(() => base64Decode(encrypted), returnsNormally);
    });

    test('same plaintext produces different ciphertexts (random nonce)', () async {
      const plaintext = 'same text';
      final encrypted1 = await repository.encryptField(plaintext);
      final encrypted2 = await repository.encryptField(plaintext);

      expect(encrypted1, isNot(equals(encrypted2)));
    });

    test('empty string round-trip', () async {
      final encrypted = await repository.encryptField('');
      final decrypted = await repository.decryptField(encrypted);

      expect(decrypted, '');
    });

    test('unicode text round-trip', () async {
      const plaintext = 'lunch 午餐 ランチ';
      final encrypted = await repository.encryptField(plaintext);
      final decrypted = await repository.decryptField(encrypted);

      expect(decrypted, plaintext);
    });

    test('decrypting tampered data throws MacValidationException', () async {
      final encrypted = await repository.encryptField('data');
      final bytes = base64Decode(encrypted);

      // Tamper with the last byte (part of MAC)
      bytes[bytes.length - 1] ^= 0xFF;
      final tampered = base64Encode(bytes);

      expect(
        () => repository.decryptField(tampered),
        throwsA(isA<MacValidationException>()),
      );
    });

    test('decrypting too-short data throws MacValidationException', () async {
      final tooShort = base64Encode(List<int>.filled(10, 0));

      expect(
        () => repository.decryptField(tooShort),
        throwsA(isA<MacValidationException>()),
      );
    });
  });

  group('encryptAmount / decryptAmount', () {
    test('round-trip preserves amount value', () async {
      const amount = 1234.56;
      final encrypted = await repository.encryptAmount(amount);
      final decrypted = await repository.decryptAmount(encrypted);

      expect(decrypted, amount);
    });

    test('zero amount round-trip', () async {
      final encrypted = await repository.encryptAmount(0.0);
      final decrypted = await repository.decryptAmount(encrypted);

      expect(decrypted, 0.0);
    });

    test('negative amount round-trip', () async {
      final encrypted = await repository.encryptAmount(-500.25);
      final decrypted = await repository.decryptAmount(encrypted);

      expect(decrypted, -500.25);
    });
  });

  group('clearCache', () {
    test('clears cached key and re-derives on next use', () async {
      // First encrypt to populate cache
      await repository.encryptField('test');

      // Clear cache
      await repository.clearCache();

      // Should still work (re-derives key)
      final encrypted = await repository.encryptField('after clear');
      final decrypted = await repository.decryptField(encrypted);

      expect(decrypted, 'after clear');
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/infrastructure/crypto/repositories/encryption_repository_impl_test.dart`
Expected: FAIL

**Step 3: Implement EncryptionRepositoryImpl**

```dart
// lib/infrastructure/crypto/repositories/encryption_repository_impl.dart
import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/encryption_repository.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/key_repository.dart';

/// ChaCha20-Poly1305 AEAD field encryption.
///
/// Cipher format: Base64(nonce[12B] + encrypted_data + mac[16B])
/// Key derived via HKDF-SHA256 from device public key.
class EncryptionRepositoryImpl implements EncryptionRepository {
  EncryptionRepositoryImpl({required KeyRepository keyRepository})
      : _keyRepository = keyRepository;

  final KeyRepository _keyRepository;
  final _algorithm = Chacha20.poly1305Aead();
  final _random = Random.secure();

  /// Cached derived encryption key (cleared on logout).
  SecretKey? _cachedKey;

  @override
  Future<String> encryptField(String plaintext) async {
    final key = await _getOrDeriveKey();
    final nonce = _generateNonce();

    final secretBox = await _algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
    );

    final combined = <int>[
      ...nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ];

    return base64Encode(combined);
  }

  @override
  Future<String> decryptField(String ciphertext) async {
    final data = base64Decode(ciphertext);

    // Minimum: 12 (nonce) + 0 (empty plaintext) + 16 (MAC) = 28 bytes
    if (data.length < 28) {
      throw MacValidationException(
        'Ciphertext too short: ${data.length} bytes (minimum 28)',
      );
    }

    final nonce = data.sublist(0, 12);
    final macBytes = data.sublist(data.length - 16);
    final cipherData = data.sublist(12, data.length - 16);

    final key = await _getOrDeriveKey();

    try {
      final secretBox = SecretBox(
        cipherData,
        nonce: nonce,
        mac: Mac(macBytes),
      );

      final plaintext = await _algorithm.decrypt(secretBox, secretKey: key);
      return utf8.decode(plaintext);
    } catch (e) {
      throw MacValidationException('Decryption failed: $e');
    }
  }

  @override
  Future<String> encryptAmount(double amount) async {
    return encryptField(amount.toString());
  }

  @override
  Future<double> decryptAmount(String encryptedAmount) async {
    final decrypted = await decryptField(encryptedAmount);
    return double.parse(decrypted);
  }

  @override
  Future<void> clearCache() async {
    _cachedKey = null;
  }

  Future<SecretKey> _getOrDeriveKey() async {
    if (_cachedKey != null) return _cachedKey!;
    _cachedKey = await _deriveEncryptionKey();
    return _cachedKey!;
  }

  Future<SecretKey> _deriveEncryptionKey() async {
    final publicKeyBase64 = await _keyRepository.getPublicKey();
    if (publicKeyBase64 == null) {
      throw StateError('No public key available for key derivation');
    }

    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final publicKeyBytes = base64Decode(publicKeyBase64);

    return hkdf.deriveKey(
      secretKey: SecretKey(publicKeyBytes),
      info: utf8.encode('homepocket_field_encryption_v1'),
      nonce: const [],
    );
  }

  List<int> _generateNonce() {
    return List<int>.generate(12, (_) => _random.nextInt(256));
  }
}
```

**Step 4: Run tests**

Run: `flutter test test/infrastructure/crypto/repositories/encryption_repository_impl_test.dart`
Expected: ALL PASS

**Step 5: Commit**

```bash
git add lib/infrastructure/crypto/repositories/encryption_repository_impl.dart test/infrastructure/crypto/repositories/encryption_repository_impl_test.dart
git commit -m "feat: implement EncryptionRepositoryImpl with ChaCha20-Poly1305

AEAD field encryption with HKDF-derived keys. Supports field and
amount encryption/decryption with key caching."
```

---

### Task 10: Implement FieldEncryptionService (TDD)

**Files:**
- Create: `lib/infrastructure/crypto/services/field_encryption_service.dart`
- Test: `test/infrastructure/crypto/services/field_encryption_service_test.dart`

**Step 1: Write the failing tests**

```dart
// test/infrastructure/crypto/services/field_encryption_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/encryption_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:mocktail/mocktail.dart';

class MockEncryptionRepository extends Mock implements EncryptionRepository {}

void main() {
  late MockEncryptionRepository mockRepo;
  late FieldEncryptionService service;

  setUp(() {
    mockRepo = MockEncryptionRepository();
    service = FieldEncryptionService(repository: mockRepo);
  });

  group('encryptField', () {
    test('delegates to repository', () async {
      when(() => mockRepo.encryptField('test'))
          .thenAnswer((_) async => 'encrypted_test');

      final result = await service.encryptField('test');

      expect(result, 'encrypted_test');
      verify(() => mockRepo.encryptField('test')).called(1);
    });
  });

  group('decryptField', () {
    test('delegates to repository', () async {
      when(() => mockRepo.decryptField('encrypted'))
          .thenAnswer((_) async => 'decrypted');

      final result = await service.decryptField('encrypted');

      expect(result, 'decrypted');
    });
  });

  group('encryptAmount', () {
    test('delegates to repository', () async {
      when(() => mockRepo.encryptAmount(1234.56))
          .thenAnswer((_) async => 'enc_amount');

      final result = await service.encryptAmount(1234.56);

      expect(result, 'enc_amount');
    });
  });

  group('decryptAmount', () {
    test('delegates to repository', () async {
      when(() => mockRepo.decryptAmount('enc'))
          .thenAnswer((_) async => 1234.56);

      final result = await service.decryptAmount('enc');

      expect(result, 1234.56);
    });
  });

  group('clearCache', () {
    test('delegates to repository', () async {
      when(() => mockRepo.clearCache()).thenAnswer((_) async {});

      await service.clearCache();

      verify(() => mockRepo.clearCache()).called(1);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/infrastructure/crypto/services/field_encryption_service_test.dart`
Expected: FAIL

**Step 3: Implement FieldEncryptionService**

```dart
// lib/infrastructure/crypto/services/field_encryption_service.dart
import 'package:home_pocket/infrastructure/crypto/repositories/encryption_repository.dart';

/// High-level field encryption API.
///
/// Encrypts sensitive transaction fields (notes, merchant names, amounts).
/// Delegates to [EncryptionRepository] for crypto operations.
class FieldEncryptionService {
  FieldEncryptionService({required EncryptionRepository repository})
      : _repository = repository;

  final EncryptionRepository _repository;

  Future<String> encryptField(String plaintext) =>
      _repository.encryptField(plaintext);

  Future<String> decryptField(String ciphertext) =>
      _repository.decryptField(ciphertext);

  Future<String> encryptAmount(double amount) =>
      _repository.encryptAmount(amount);

  Future<double> decryptAmount(String encrypted) =>
      _repository.decryptAmount(encrypted);

  Future<void> clearCache() => _repository.clearCache();
}
```

**Step 4: Run tests**

Run: `flutter test test/infrastructure/crypto/services/field_encryption_service_test.dart`
Expected: ALL PASS

**Step 5: Commit**

```bash
git add lib/infrastructure/crypto/services/field_encryption_service.dart test/infrastructure/crypto/services/field_encryption_service_test.dart
git commit -m "feat: implement FieldEncryptionService

Thin delegation layer over EncryptionRepository for field-level
encryption of notes, merchant names, and amounts."
```

---

### Task 11: Create Encrypted Database Setup

**Files:**
- Create: `lib/infrastructure/crypto/database/encrypted_database.dart`

**Note:** This file uses native SQLCipher and platform-specific code. Unit testing requires integration tests with a real device/emulator. We create the file without unit tests but verify it compiles.

**Step 1: Implement createEncryptedExecutor (UPDATED - 使用 HKDF 密钥派生)**

```dart
// lib/infrastructure/crypto/database/encrypted_database.dart
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/master_key_repository.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// Creates an encrypted SQLCipher database executor.
///
/// Must be called after MasterKeyRepository is initialized (has master key).
///
/// SQLCipher config:
/// - Cipher: AES-256-CBC
/// - KDF: PBKDF2-HMAC-SHA512, 256,000 iterations
/// - Key: 32 bytes derived from master key using HKDF
Future<QueryExecutor> createEncryptedExecutor(
  MasterKeyRepository masterKeyRepository, {
  bool inMemory = false,
}) async {
  if (!await masterKeyRepository.hasMasterKey()) {
    throw MasterKeyNotInitializedException();
  }

  final dbKey = await _deriveDatabaseKey(masterKeyRepository);

  return NativeDatabase.createInBackground(
    inMemory ? sqlite3.sqlite3.openInMemory() : await _openDatabase(),
    setup: (db) {
      // Apply SQLCipher encryption key
      db.execute("PRAGMA key = \"x'$dbKey'\";");
      db.execute('PRAGMA cipher = "aes-256-cbc";');
      db.execute('PRAGMA kdf_iter = 256000;');

      // Verify encryption is active
      final result = db.select('PRAGMA cipher_version;');
      if (result.isEmpty) {
        throw StateError('SQLCipher not loaded - encryption unavailable');
      }
    },
  );
}

/// Derive database encryption key using HKDF-SHA256.
///
/// This is cryptographically secure key derivation per ADR-006.
Future<String> _deriveDatabaseKey(MasterKeyRepository masterKeyRepository) async {
  final secretKey = await masterKeyRepository.deriveKey('database_encryption');
  final keyBytes = await secretKey.extractBytes();
  return keyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
}

Future<File> _getDatabaseFile() async {
  final dir = await getApplicationDocumentsDirectory();
  final dbDir = Directory(p.join(dir.path, 'databases'));
  if (!await dbDir.exists()) {
    await dbDir.create(recursive: true);
  }
  return File(p.join(dbDir.path, 'home_pocket.db'));
}

/// Open native SQLCipher database with platform-specific loading.
Future<sqlite3.Database> _openDatabase() async {
  // Load SQLCipher native library
  if (Platform.isAndroid) {
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  } else if (Platform.isIOS || Platform.isMacOS) {
    open.overrideForAll(() => DynamicLibrary.process());
  }

  final file = await _getDatabaseFile();
  return sqlite3.sqlite3.open(file.path);
}
```

**Step 2: Verify compilation**

Run: `flutter analyze lib/infrastructure/crypto/database/`
Expected: No errors (may have warnings about unused imports on non-mobile platforms, which is OK).

**Step 3: Commit**

```bash
git add lib/infrastructure/crypto/database/encrypted_database.dart
git commit -m "feat: add SQLCipher encrypted database setup with HKDF key derivation

AES-256-CBC with PBKDF2-HMAC-SHA512 (256k iterations).
Database key derived from master key using HKDF-SHA256.
Platform-specific SQLCipher library loading for Android/iOS."
```

---

### Task 12: Wire Up Riverpod Providers

**Files:**
- Create: `lib/infrastructure/crypto/providers.dart`

**Step 1: Create providers file (UPDATED - 使用 Ref 替代废弃的 XxxRef 类型)**

```dart
// lib/infrastructure/crypto/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:home_pocket/infrastructure/crypto/repositories/master_key_repository.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/master_key_repository_impl.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/key_repository.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/key_repository_impl.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/encryption_repository.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/encryption_repository_impl.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';

part 'providers.g.dart';

// FlutterSecureStorage configuration
const _secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.unlocked_this_device,
  ),
);

/// Master key repository - manages 256-bit master key and HKDF derivation
@riverpod
MasterKeyRepository masterKeyRepository(Ref ref) {
  return MasterKeyRepositoryImpl(secureStorage: _secureStorage);
}

/// Key repository - manages Ed25519 key pairs
@riverpod
KeyRepository keyRepository(Ref ref) {
  return KeyRepositoryImpl(secureStorage: _secureStorage);
}

/// Key manager - high-level key operations
@riverpod
KeyManager keyManager(Ref ref) {
  final repository = ref.watch(keyRepositoryProvider);
  return KeyManager(repository: repository);
}

/// Check if device has a key pair
@riverpod
Future<bool> hasKeyPair(Ref ref) async {
  final km = ref.watch(keyManagerProvider);
  return km.hasKeyPair();
}

/// Encryption repository - ChaCha20-Poly1305 field encryption
@riverpod
EncryptionRepository encryptionRepository(Ref ref) {
  final masterKeyRepo = ref.watch(masterKeyRepositoryProvider);
  return EncryptionRepositoryImpl(masterKeyRepository: masterKeyRepo);
}

/// Field encryption service - high-level encryption operations
@riverpod
FieldEncryptionService fieldEncryptionService(Ref ref) {
  final repository = ref.watch(encryptionRepositoryProvider);
  return FieldEncryptionService(repository: repository);
}

/// Hash chain service - SHA-256 transaction integrity
@riverpod
HashChainService hashChainService(Ref ref) {
  return HashChainService();
}
```


**Step 2: Run code generation**

Run: `cd /Users/xinz/Development/home-pocket-app && flutter pub run build_runner build --delete-conflicting-outputs`
Expected: `providers.g.dart` generated.

**Step 3: Verify compilation**

Run: `flutter analyze lib/infrastructure/crypto/`
Expected: No issues found.

**Step 4: Commit**

```bash
git add lib/infrastructure/crypto/providers.dart
git commit -m "feat: add Riverpod providers for crypto infrastructure

Provider wiring for KeyRepository, KeyManager, EncryptionRepository,
FieldEncryptionService, and HashChainService."
```

---

### Task 13: Run Full Test Suite + Static Analysis

**Files:** None (verification only)

**Step 1: Run all tests**

Run: `flutter test`
Expected: ALL PASS (all crypto tests green)

**Step 2: Run static analysis**

Run: `flutter analyze`
Expected: No issues found.

**Step 3: Format all code**

Run: `dart format lib/ test/`
Expected: All files formatted.

**Step 4: Final commit if any formatting changes**

```bash
git add -A
git commit -m "chore: format code and verify full test suite

All crypto infrastructure tests pass. Zero analyzer warnings."
```

---

## Summary

| Task | Component | Files Created | Tests |
|------|-----------|---------------|-------|
| 1 | Dependencies | `pubspec.yaml` | - |
| 2 | Build config | `build.yaml`, `analysis_options.yaml` | - |
| 3 | DeviceKeyPair model | 1 source + 1 test | 4 tests |
| 4 | ChainVerificationResult model | 1 source + 1 test | 5 tests |
| 5 | Repository interfaces | 2 source | - |
| 6 | HashChainService | 1 source + 1 test | 11 tests |
| 7 | KeyRepositoryImpl | 1 source + 1 test | 9 tests |
| 8 | KeyManager | 1 source + 1 test | 7 tests |
| 9 | EncryptionRepositoryImpl | 1 source + 1 test | 10 tests |
| 10 | FieldEncryptionService | 1 source + 1 test | 5 tests |
| 11 | Encrypted Database | 1 source | - (integration only) |
| 12 | Riverpod Providers | 1 source | - |
| 13 | Verification | - | Full suite |

**Total:** 11 source files, 7 test files, ~51 unit tests, 13 commits.

**Estimated time:** ~2-3 hours for experienced Flutter developer.
