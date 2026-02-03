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
