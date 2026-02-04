import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/key_repository_impl.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/encryption_repository_impl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Mock secure storage for performance tests
class MockSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _storage[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.remove(key);
  }

  @override
  Future<Map<String, String>> readAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return Map.from(_storage);
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.clear();
  }

  @override
  Future<bool> containsKey({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage.containsKey(key);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Security Performance Benchmarks', () {
    late KeyManager keyManager;
    late FieldEncryptionService encryptionService;
    late HashChainService hashChainService;

    setUp(() async {
      final secureStorage = MockSecureStorage();

      // Create repository instances
      final keyRepository = KeyRepositoryImpl(secureStorage: secureStorage);
      final encryptionRepository = EncryptionRepositoryImpl(keyRepository: keyRepository);

      // Create service instances
      keyManager = KeyManager(repository: keyRepository);

      // Generate device key for encryption
      await keyManager.generateDeviceKeyPair();

      encryptionService = FieldEncryptionService(repository: encryptionRepository);
      hashChainService = HashChainService();
    });

    test('field encryption should complete in <10ms per field', () async {
      // Arrange
      const testData = 'Test sensitive data';

      // Act & Measure
      final stopwatch = Stopwatch()..start();
      await encryptionService.encryptField(testData);
      stopwatch.stop();

      // Assert
      expect(stopwatch.elapsedMilliseconds, lessThan(10));
      print('✅ Field encryption time: ${stopwatch.elapsedMilliseconds}ms');
    });

    test('batch encryption of 100 fields should complete in <500ms', () async {
      // Arrange
      final testData = List.generate(100, (i) => 'Data item $i');
      final encrypted = <String>[];

      // Act & Measure
      final stopwatch = Stopwatch()..start();
      for (final data in testData) {
        encrypted.add(await encryptionService.encryptField(data));
      }
      stopwatch.stop();

      // Assert
      expect(encrypted.length, 100);
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
      print(
        '✅ Batch encryption (100 items): ${stopwatch.elapsedMilliseconds}ms',
      );
    });

    test('batch amount encryption of 100 items should complete in <500ms',
        () async {
      // Arrange
      final amounts = List.generate(100, (i) => (i + 1) * 100.0);
      final encrypted = <String>[];

      // Act & Measure
      final stopwatch = Stopwatch()..start();
      for (final amount in amounts) {
        encrypted.add(await encryptionService.encryptAmount(amount));
      }
      stopwatch.stop();

      // Assert
      expect(encrypted.length, 100);
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
      print(
        '✅ Batch amount encryption (100 items): ${stopwatch.elapsedMilliseconds}ms',
      );
    });

    test('hash chain verification of 1000 transactions should complete in <1s',
        () async {
      // Arrange: Create a chain of 1000 transactions
      final transactions = <Map<String, dynamic>>[];

      for (int i = 0; i < 1000; i++) {
        final transactionId = 'tx-${i.toString().padLeft(4, '0')}';
        final amount = (i + 1) * 10.0;
        final timestamp = 1704067200000 + (i * 1000);
        final previousHash = i == 0 ? '' : transactions[i - 1]['hash'] as String;

        final hash = hashChainService.calculateTransactionHash(
          transactionId: transactionId,
          amount: amount,
          timestamp: timestamp,
          previousHash: previousHash,
        );

        transactions.add({
          'id': transactionId,
          'amount': amount,
          'timestamp': timestamp,
          'previousHash': previousHash,
          'hash': hash,
        });
      }

      // Act & Measure
      final stopwatch = Stopwatch()..start();
      final result = hashChainService.verifyChain(transactions);
      stopwatch.stop();

      // Assert
      expect(result.isValid, true);
      expect(result.totalTransactions, 1000);
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      print(
        '✅ Hash chain verification (1000 nodes): ${stopwatch.elapsedMilliseconds}ms',
      );
    });

    test(
        'incremental hash chain verification of 1000 transactions should be significantly faster',
        () async {
      // Arrange: Create a chain of 1000 transactions
      final transactions = <Map<String, dynamic>>[];

      for (int i = 0; i < 1000; i++) {
        final transactionId = 'tx-${i.toString().padLeft(4, '0')}';
        final amount = (i + 1) * 10.0;
        final timestamp = 1704067200000 + (i * 1000);
        final previousHash = i == 0 ? '' : transactions[i - 1]['hash'] as String;

        final hash = hashChainService.calculateTransactionHash(
          transactionId: transactionId,
          amount: amount,
          timestamp: timestamp,
          previousHash: previousHash,
        );

        transactions.add({
          'id': transactionId,
          'amount': amount,
          'timestamp': timestamp,
          'previousHash': previousHash,
          'hash': hash,
        });
      }

      // Act & Measure: Full verification
      final stopwatch1 = Stopwatch()..start();
      hashChainService.verifyChain(transactions);
      stopwatch1.stop();

      // Act & Measure: Incremental verification (only last 100)
      final stopwatch2 = Stopwatch()..start();
      final incrementalResult = hashChainService.verifyChainIncremental(
        transactions,
        lastVerifiedIndex: 899,
      );
      stopwatch2.stop();

      // Assert
      expect(incrementalResult.isValid, true);
      expect(stopwatch2.elapsedMilliseconds, lessThan(stopwatch1.elapsedMilliseconds));

      final speedup = (stopwatch1.elapsedMilliseconds / stopwatch2.elapsedMilliseconds).toStringAsFixed(1);
      print(
        '✅ Incremental verification speedup: ${speedup}x faster (${stopwatch2.elapsedMilliseconds}ms vs ${stopwatch1.elapsedMilliseconds}ms)',
      );
    });

    test('encryption + decryption round-trip should complete in <20ms',
        () async {
      // Arrange
      const testData = 'Sensitive financial data';

      // Act & Measure
      final stopwatch = Stopwatch()..start();
      final encrypted = await encryptionService.encryptField(testData);
      final decrypted = await encryptionService.decryptField(encrypted);
      stopwatch.stop();

      // Assert
      expect(decrypted, equals(testData));
      expect(stopwatch.elapsedMilliseconds, lessThan(20));
      print(
        '✅ Encryption + decryption round-trip: ${stopwatch.elapsedMilliseconds}ms',
      );
    });
  });
}
