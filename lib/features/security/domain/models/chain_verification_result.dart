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
