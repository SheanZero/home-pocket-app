import 'package:freezed_annotation/freezed_annotation.dart';

part 'chain_verification_result.freezed.dart';

/// Hash chain verification result - UNIQUE definition.
///
/// All code that needs chain verification results MUST import from this file.
@freezed
abstract class ChainVerificationResult with _$ChainVerificationResult {
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
  }) => ChainVerificationResult(
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
