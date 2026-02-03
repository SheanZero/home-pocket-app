import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:home_pocket/features/security/application/services/key_manager.dart';
import 'package:home_pocket/features/security/application/services/recovery_kit_service.dart';
import 'package:home_pocket/features/security/application/services/pin_manager.dart';
import 'package:home_pocket/features/security/application/services/field_encryption_service.dart';
import 'package:home_pocket/features/security/application/services/hash_chain_service.dart';
import 'package:bip39/bip39.dart' as bip39;

// Mock secure storage for integration tests
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
  group('Security Integration Tests', () {
    late FlutterSecureStorage secureStorage;
    late KeyManager keyManager;
    late RecoveryKitService recoveryKitService;
    late PINManager pinManager;
    late FieldEncryptionService fieldEncryptionService;
    late HashChainService hashChainService;

    setUp(() {
      // Use mock secure storage for tests
      secureStorage = MockSecureStorage();
      keyManager = KeyManager(secureStorage: secureStorage);
      recoveryKitService = RecoveryKitService(
        secureStorage: secureStorage,
        keyManager: keyManager,
      );
      pinManager = PINManager(secureStorage: secureStorage);
      fieldEncryptionService = FieldEncryptionService(keyManager: keyManager);
      hashChainService = HashChainService();
    });

    test('Full security workflow: KeyGen → Recovery → Encryption', () async {
      // Step 1: Generate device key pair
      final deviceKeyPair = await keyManager.generateDeviceKeyPair();
      expect(deviceKeyPair.publicKey, isNotEmpty);
      expect(deviceKeyPair.deviceId, isNotEmpty);

      // Step 2: Generate recovery kit
      final mnemonic = await recoveryKitService.generateRecoveryKit();
      expect(mnemonic.split(' ').length, 24);
      expect(bip39.validateMnemonic(mnemonic), true);

      // Step 3: Verify recovery kit
      final isValid = await recoveryKitService.verifyRecoveryKit(mnemonic);
      expect(isValid, true);

      // Step 4: Encrypt sensitive data
      const sensitiveAmount = 12345.67;
      final encryptedAmount = await fieldEncryptionService.encryptAmount(sensitiveAmount);
      expect(encryptedAmount, isNotEmpty);
      expect(encryptedAmount, isNot(contains('12345')));

      // Step 5: Decrypt and verify
      final decryptedAmount = await fieldEncryptionService.decryptAmount(encryptedAmount);
      expect(decryptedAmount, equals(sensitiveAmount));
    });

    test('Recovery workflow: Mnemonic → Seed → Key Recovery', () async {
      // Step 1: Generate recovery kit
      final mnemonic = await recoveryKitService.generateRecoveryKit();
      expect(bip39.validateMnemonic(mnemonic), true);

      // Step 2: Simulate device loss - create new KeyManager
      final newSecureStorage = MockSecureStorage();
      final newKeyManager = KeyManager(secureStorage: newSecureStorage);

      // Step 3: Recover device key from mnemonic
      final fullSeed = bip39.mnemonicToSeed(mnemonic);
      final seed = fullSeed.sublist(0, 32); // Use first 32 bytes for Ed25519
      final recoveredKeyPair = await newKeyManager.recoverFromSeed(seed);

      // Step 4: Verify recovery succeeded
      expect(recoveredKeyPair.publicKey, isNotEmpty);
      expect(recoveredKeyPair.deviceId, isNotEmpty);
      expect(recoveredKeyPair.deviceId.length, 16);

      // Step 5: Verify same seed produces same keys (deterministic)
      final newSecureStorage2 = MockSecureStorage();
      final newKeyManager2 = KeyManager(secureStorage: newSecureStorage2);
      final recoveredKeyPair2 = await newKeyManager2.recoverFromSeed(seed);

      expect(recoveredKeyPair2.deviceId, equals(recoveredKeyPair.deviceId));
      expect(recoveredKeyPair2.publicKey, equals(recoveredKeyPair.publicKey));
    });

    test('PIN authentication workflow', () async {
      // Step 1: Setup PIN
      const pin = '123456';
      await pinManager.setPIN(pin);

      // Step 2: Verify PIN is set
      final isSet = await pinManager.isPINSet();
      expect(isSet, true);

      // Step 3: Verify correct PIN
      final isCorrect = await pinManager.verifyPIN(pin);
      expect(isCorrect, true);

      // Step 4: Verify incorrect PIN fails
      final isWrong = await pinManager.verifyPIN('654321');
      expect(isWrong, false);

      // Step 5: Change PIN
      const newPin = '999999';
      final changed = await pinManager.changePIN(pin, newPin);
      expect(changed, true);

      // Step 6: Verify new PIN works
      final newPinWorks = await pinManager.verifyPIN(newPin);
      expect(newPinWorks, true);

      // Step 7: Old PIN should not work
      final oldPinFails = await pinManager.verifyPIN(pin);
      expect(oldPinFails, false);
    });

    test('Hash chain with encrypted transactions', () async {
      // Step 1: Generate device key for encryption
      await keyManager.generateDeviceKeyPair();

      // Step 2: Create encrypted transactions
      final transactions = <Map<String, dynamic>>[];

      for (int i = 0; i < 5; i++) {
        final transactionId = 'tx-${i.toString().padLeft(3, '0')}';
        final amount = (i + 1) * 100.0;
        final timestamp = DateTime.now().millisecondsSinceEpoch + (i * 1000);

        // Encrypt sensitive data
        final encryptedAmount = await fieldEncryptionService.encryptAmount(amount);

        // Calculate hash for integrity
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
          'encryptedAmount': encryptedAmount,
          'timestamp': timestamp,
          'previousHash': previousHash,
          'hash': hash,
        });
      }

      // Step 3: Verify chain integrity
      final verificationResult = hashChainService.verifyChain(transactions);
      expect(verificationResult.isValid, true);
      expect(verificationResult.totalTransactions, 5);

      // Step 4: Verify encrypted data can be decrypted
      for (final tx in transactions) {
        final encryptedAmount = tx['encryptedAmount'] as String;
        final originalAmount = tx['amount'] as double;
        final decryptedAmount = await fieldEncryptionService.decryptAmount(encryptedAmount);
        expect(decryptedAmount, equals(originalAmount));
      }

      // Step 5: Simulate tampering
      transactions[2]['amount'] = 999.0; // Change amount without updating hash

      // Step 6: Verify tamper detection
      final tamperedResult = hashChainService.verifyChain(transactions);
      expect(tamperedResult.isValid, false);
      expect(tamperedResult.tamperedTransactionIds, contains('tx-002'));
    });

    test('Multi-layer security: PIN + Encryption + Hash Chain', () async {
      // Step 1: Setup PIN authentication
      const userPin = '123456';
      await pinManager.setPIN(userPin);

      // Step 2: User authenticates with PIN
      final authenticated = await pinManager.verifyPIN(userPin);
      expect(authenticated, true);

      // Step 3: Generate encryption key (after authentication)
      await keyManager.generateDeviceKeyPair();

      // Step 4: Create encrypted transaction with hash chain
      const transactionId = 'tx-secure-001';
      const amount = 5000.0;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Encrypt amount
      final encryptedAmount = await fieldEncryptionService.encryptAmount(amount);

      // Calculate hash
      final hash = hashChainService.calculateTransactionHash(
        transactionId: transactionId,
        amount: amount,
        timestamp: timestamp,
        previousHash: '',
      );

      // Step 5: Verify all layers
      // Layer 1: PIN authentication
      expect(await pinManager.verifyPIN(userPin), true);

      // Layer 2: Encryption/Decryption
      final decryptedAmount = await fieldEncryptionService.decryptAmount(encryptedAmount);
      expect(decryptedAmount, equals(amount));

      // Layer 3: Hash integrity
      final isValid = hashChainService.verifyTransactionIntegrity(
        transactionId: transactionId,
        amount: amount,
        timestamp: timestamp,
        previousHash: '',
        currentHash: hash,
      );
      expect(isValid, true);
    });

    test('Recovery verification with random word selection', () async {
      // Step 1: Generate recovery kit
      final mnemonic = await recoveryKitService.generateRecoveryKit();
      final words = mnemonic.split(' ');
      expect(words.length, 24);

      // Step 2: Get random words for verification (simulates UI flow)
      final randomIndices = recoveryKitService.getRandomWordsForVerification();
      expect(randomIndices.length, 3);
      expect(randomIndices.every((i) => i >= 0 && i < 24), true);
      expect(randomIndices.toSet().length, 3); // All unique

      // Step 3: User would provide words at these indices
      final verificationWords = randomIndices.map((i) => words[i]).toList();
      expect(verificationWords.length, 3);

      // Step 4: Reconstruct and verify (simulating user re-entering all words)
      final isValid = await recoveryKitService.verifyRecoveryKit(mnemonic);
      expect(isValid, true);
    });

    test('Incremental hash chain verification performance', () async {
      // Create a large chain
      final transactions = List.generate(100, (i) => {
        'id': 'tx-${i.toString().padLeft(3, '0')}',
        'amount': (i + 1) * 10.0,
        'timestamp': 1704067200000 + (i * 1000),
        'previousHash': '',
        'hash': '',
      });

      // Build chain
      for (int i = 0; i < transactions.length; i++) {
        final prevHash = i == 0 ? '' : transactions[i - 1]['hash'] as String;
        transactions[i]['previousHash'] = prevHash;
        transactions[i]['hash'] = hashChainService.calculateTransactionHash(
          transactionId: transactions[i]['id'] as String,
          amount: transactions[i]['amount'] as double,
          timestamp: transactions[i]['timestamp'] as int,
          previousHash: prevHash,
        );
      }

      // Full verification
      final fullResult = hashChainService.verifyChain(transactions);
      expect(fullResult.isValid, true);

      // Incremental verification (only last 20 transactions)
      final incrementalResult = hashChainService.verifyChainIncremental(
        transactions,
        lastVerifiedIndex: 79,
      );
      expect(incrementalResult.isValid, true);
      expect(incrementalResult.totalTransactions, 100);
    });
  });
}
