import 'package:flutter_test/flutter_test.dart';
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
          'transactionId': 'tx_001',
          'amount': 100.0,
          'timestamp': 1000,
          'previousHash': 'genesis',
          'currentHash': hash1,
        },
        {
          'transactionId': 'tx_002',
          'amount': 200.0,
          'timestamp': 2000,
          'previousHash': hash1,
          'currentHash': hash2,
        },
        {
          'transactionId': 'tx_003',
          'amount': 300.0,
          'timestamp': 3000,
          'previousHash': hash2,
          'currentHash': hash3,
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
          'transactionId': 'tx_001',
          'amount': 100.0,
          'timestamp': 1000,
          'previousHash': 'genesis',
          'currentHash': hash1,
        },
        {
          'transactionId': 'tx_002',
          'amount': 999.0, // tampered
          'timestamp': 2000,
          'previousHash': hash1,
          'currentHash': hash2,
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
          'transactionId': 'tx_001',
          'amount': 100.0,
          'timestamp': 1000,
          'previousHash': 'genesis',
          'currentHash': hash1,
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
          'transactionId': 'tx_001',
          'amount': 100.0,
          'timestamp': 1000,
          'previousHash': 'genesis',
          'currentHash': hash1,
        },
        {
          'transactionId': 'tx_002',
          'amount': 200.0,
          'timestamp': 2000,
          'previousHash': hash1,
          'currentHash': hash2,
        },
        {
          'transactionId': 'tx_003',
          'amount': 300.0,
          'timestamp': 3000,
          'previousHash': hash2,
          'currentHash': hash3,
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
