import 'dart:convert';

import 'package:crypto/crypto.dart';
import '../models/chain_verification_result.dart';

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
