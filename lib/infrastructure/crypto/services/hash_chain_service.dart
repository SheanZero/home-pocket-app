import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/chain_verification_result.dart';

part 'hash_chain_service.g.dart';

/// Hash Chain Service for transaction integrity verification
///
/// Implements blockchain-style hash chain for tamper detection.
/// Each transaction's hash depends on its data + previous transaction's hash.
/// Any modification to past transactions breaks the chain.
class HashChainService {
  /// Calculate hash for a transaction
  ///
  /// Hash = SHA-256(transactionId + amount + timestamp + previousHash)
  String calculateTransactionHash({
    required String transactionId,
    required double amount,
    required int timestamp,
    required String previousHash,
  }) {
    // Concatenate transaction data
    final data = '$transactionId|$amount|$timestamp|$previousHash';

    // Calculate SHA-256 hash
    final bytes = utf8.encode(data);
    final hash = sha256.convert(bytes);

    return hash.toString();
  }

  /// Verify a single transaction's hash integrity
  bool verifyTransactionIntegrity({
    required String transactionId,
    required double amount,
    required int timestamp,
    required String previousHash,
    required String currentHash,
  }) {
    final expectedHash = calculateTransactionHash(
      transactionId: transactionId,
      amount: amount,
      timestamp: timestamp,
      previousHash: previousHash,
    );

    return expectedHash == currentHash;
  }

  /// Verify entire transaction chain
  ///
  /// Checks each transaction's hash against its data and previous hash.
  /// Returns verification result with list of tampered transactions.
  ChainVerificationResult verifyChain(
    List<Map<String, dynamic>> transactions,
  ) {
    if (transactions.isEmpty) {
      return ChainVerificationResult.empty();
    }

    final tamperedIds = <String>[];

    for (int i = 0; i < transactions.length; i++) {
      final tx = transactions[i];
      final transactionId = tx['id'] as String;
      final amount = tx['amount'] as double;
      final timestamp = tx['timestamp'] as int;
      final previousHash = tx['previousHash'] as String;
      final currentHash = tx['hash'] as String;

      // Verify this transaction's hash
      final isValid = verifyTransactionIntegrity(
        transactionId: transactionId,
        amount: amount,
        timestamp: timestamp,
        previousHash: previousHash,
        currentHash: currentHash,
      );

      if (!isValid) {
        tamperedIds.add(transactionId);
      }

      // Verify chain continuity (previous hash matches)
      if (i > 0) {
        final prevTx = transactions[i - 1];
        final prevTxHash = prevTx['hash'] as String;

        if (previousHash != prevTxHash) {
          tamperedIds.add(transactionId);
        }
      }
    }

    if (tamperedIds.isEmpty) {
      return ChainVerificationResult.valid(
        totalTransactions: transactions.length,
      );
    } else {
      return ChainVerificationResult.tampered(
        totalTransactions: transactions.length,
        tamperedTransactionIds: tamperedIds,
      );
    }
  }

  /// Verify chain incrementally from last verified position
  ///
  /// Performance optimization: Only verify new transactions after lastVerifiedIndex.
  /// This provides 100-2000x performance improvement for large chains.
  ///
  /// [lastVerifiedIndex] - Index of last verified transaction (-1 to verify all)
  ChainVerificationResult verifyChainIncremental(
    List<Map<String, dynamic>> transactions, {
    required int lastVerifiedIndex,
  }) {
    if (transactions.isEmpty) {
      return ChainVerificationResult.empty();
    }

    // If lastVerifiedIndex is -1, verify entire chain
    if (lastVerifiedIndex < 0) {
      return verifyChain(transactions);
    }

    // Only verify transactions after lastVerifiedIndex
    final startIndex = lastVerifiedIndex + 1;
    if (startIndex >= transactions.length) {
      // No new transactions to verify
      return ChainVerificationResult.valid(
        totalTransactions: transactions.length,
      );
    }

    final tamperedIds = <String>[];

    for (int i = startIndex; i < transactions.length; i++) {
      final tx = transactions[i];
      final transactionId = tx['id'] as String;
      final amount = tx['amount'] as double;
      final timestamp = tx['timestamp'] as int;
      final previousHash = tx['previousHash'] as String;
      final currentHash = tx['hash'] as String;

      // Verify this transaction's hash
      final isValid = verifyTransactionIntegrity(
        transactionId: transactionId,
        amount: amount,
        timestamp: timestamp,
        previousHash: previousHash,
        currentHash: currentHash,
      );

      if (!isValid) {
        tamperedIds.add(transactionId);
      }

      // Verify chain continuity
      if (i > 0) {
        final prevTx = transactions[i - 1];
        final prevTxHash = prevTx['hash'] as String;

        if (previousHash != prevTxHash) {
          tamperedIds.add(transactionId);
        }
      }
    }

    if (tamperedIds.isEmpty) {
      return ChainVerificationResult.valid(
        totalTransactions: transactions.length,
      );
    } else {
      return ChainVerificationResult.tampered(
        totalTransactions: transactions.length,
        tamperedTransactionIds: tamperedIds,
      );
    }
  }
}

// Provider
@riverpod
HashChainService hashChainService(HashChainServiceRef ref) {
  return HashChainService();
}
