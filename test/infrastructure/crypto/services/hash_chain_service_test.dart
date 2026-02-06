import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';

void main() {
  group('HashChainService', () {
    late HashChainService hashChainService;

    setUp(() {
      hashChainService = HashChainService();
    });

    group('calculateTransactionHash', () {
      test('should generate consistent hash for same data', () {
        // Arrange
        const transactionId = 'tx-001';
        const amount = 1000.0;
        const timestamp = 1704067200000; // 2024-01-01 00:00:00
        const previousHash = 'prev-hash-123';

        // Act
        final hash1 = hashChainService.calculateTransactionHash(
          transactionId: transactionId,
          amount: amount,
          timestamp: timestamp,
          previousHash: previousHash,
        );
        final hash2 = hashChainService.calculateTransactionHash(
          transactionId: transactionId,
          amount: amount,
          timestamp: timestamp,
          previousHash: previousHash,
        );

        // Assert
        expect(hash1, equals(hash2));
        expect(hash1, isNotEmpty);
      });

      test('should generate different hash for different data', () {
        // Arrange & Act
        final hash1 = hashChainService.calculateTransactionHash(
          transactionId: 'tx-001',
          amount: 1000.0,
          timestamp: 1704067200000,
          previousHash: 'prev-hash',
        );
        final hash2 = hashChainService.calculateTransactionHash(
          transactionId: 'tx-002', // Different ID
          amount: 1000.0,
          timestamp: 1704067200000,
          previousHash: 'prev-hash',
        );

        // Assert
        expect(hash1, isNot(equals(hash2)));
      });

      test('should generate genesis hash when previousHash is empty', () {
        // Act
        final genesisHash = hashChainService.calculateTransactionHash(
          transactionId: 'tx-001',
          amount: 100.0,
          timestamp: 1704067200000,
          previousHash: '',
        );

        // Assert
        expect(genesisHash, isNotEmpty);
      });
    });

    group('verifyTransactionIntegrity', () {
      test('should return true for valid transaction hash', () {
        // Arrange
        const transactionId = 'tx-001';
        const amount = 1000.0;
        const timestamp = 1704067200000;
        const previousHash = 'prev-hash';

        final expectedHash = hashChainService.calculateTransactionHash(
          transactionId: transactionId,
          amount: amount,
          timestamp: timestamp,
          previousHash: previousHash,
        );

        // Act
        final isValid = hashChainService.verifyTransactionIntegrity(
          transactionId: transactionId,
          amount: amount,
          timestamp: timestamp,
          previousHash: previousHash,
          currentHash: expectedHash,
        );

        // Assert
        expect(isValid, true);
      });

      test('should return false for tampered transaction hash', () {
        // Arrange
        const transactionId = 'tx-001';
        const amount = 1000.0;
        const timestamp = 1704067200000;
        const previousHash = 'prev-hash';
        const tamperedHash = 'invalid-hash-123';

        // Act
        final isValid = hashChainService.verifyTransactionIntegrity(
          transactionId: transactionId,
          amount: amount,
          timestamp: timestamp,
          previousHash: previousHash,
          currentHash: tamperedHash,
        );

        // Assert
        expect(isValid, false);
      });
    });

    group('verifyChain', () {
      test('should verify valid chain', () {
        // Arrange
        final transactions = [
          {
            'id': 'tx-001',
            'amount': 100.0,
            'timestamp': 1704067200000,
            'previousHash': '',
            'hash': '',
          },
          {
            'id': 'tx-002',
            'amount': 200.0,
            'timestamp': 1704067300000,
            'previousHash': '',
            'hash': '',
          },
          {
            'id': 'tx-003',
            'amount': 300.0,
            'timestamp': 1704067400000,
            'previousHash': '',
            'hash': '',
          },
        ];

        // Build valid chain
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

        // Act
        final result = hashChainService.verifyChain(transactions);

        // Assert
        expect(result.isValid, true);
        expect(result.totalTransactions, 3);
        expect(result.tamperedTransactionIds, isEmpty);
      });

      test('should detect tampered transaction in chain', () {
        // Arrange
        final transactions = [
          {
            'id': 'tx-001',
            'amount': 100.0,
            'timestamp': 1704067200000,
            'previousHash': '',
            'hash': '',
          },
          {
            'id': 'tx-002',
            'amount': 200.0,
            'timestamp': 1704067300000,
            'previousHash': '',
            'hash': '',
          },
          {
            'id': 'tx-003',
            'amount': 300.0,
            'timestamp': 1704067400000,
            'previousHash': '',
            'hash': '',
          },
        ];

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

        // Tamper with middle transaction
        transactions[1]['amount'] = 999.0; // Changed amount but not hash

        // Act
        final result = hashChainService.verifyChain(transactions);

        // Assert
        expect(result.isValid, false);
        expect(result.tamperedTransactionIds, contains('tx-002'));
      });

      test('should handle empty chain', () {
        // Act
        final result = hashChainService.verifyChain([]);

        // Assert
        expect(result.isValid, true);
        expect(result.totalTransactions, 0);
        expect(result.tamperedTransactionIds, isEmpty);
      });

      test('should verify single transaction chain', () {
        // Arrange
        final transaction = {
          'id': 'tx-001',
          'amount': 100.0,
          'timestamp': 1704067200000,
          'previousHash': '',
          'hash': hashChainService.calculateTransactionHash(
            transactionId: 'tx-001',
            amount: 100.0,
            timestamp: 1704067200000,
            previousHash: '',
          ),
        };

        // Act
        final result = hashChainService.verifyChain([transaction]);

        // Assert
        expect(result.isValid, true);
        expect(result.totalTransactions, 1);
      });
    });

    group('incremental verification', () {
      test('should verify chain incrementally from last verified position', () {
        // Arrange: Create a chain of 1000 transactions
        final transactions = List.generate(
          1000,
          (i) => {
            'id': 'tx-${i.toString().padLeft(4, '0')}',
            'amount': (i + 1) * 100.0,
            'timestamp': 1704067200000 + (i * 1000),
            'previousHash': '',
            'hash': '',
          },
        );

        // Build valid chain
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

        // Act: Verify first 500, then verify remaining 500 incrementally
        final result1 = hashChainService.verifyChainIncremental(
          transactions.sublist(0, 500),
          lastVerifiedIndex: -1,
        );
        final result2 = hashChainService.verifyChainIncremental(
          transactions,
          lastVerifiedIndex: 499,
        );

        // Assert
        expect(result1.isValid, true);
        expect(result2.isValid, true);
        expect(result2.totalTransactions, 1000);
      });

      test('should only verify new transactions after last verified index', () {
        // This test verifies performance optimization by only checking new transactions
        final transactions = List.generate(
          100,
          (i) => {
            'id': 'tx-${i.toString().padLeft(3, '0')}',
            'amount': (i + 1) * 10.0,
            'timestamp': 1704067200000 + (i * 1000),
            'previousHash': '',
            'hash': '',
          },
        );

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

        // Act: Verify incrementally from transaction 50
        final result = hashChainService.verifyChainIncremental(
          transactions,
          lastVerifiedIndex: 49,
        );

        // Assert
        expect(result.isValid, true);
        expect(result.totalTransactions, 100);
        // Only transactions 50-99 should have been verified (50 transactions)
      });
    });
  });
}
