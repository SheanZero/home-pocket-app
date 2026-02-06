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
