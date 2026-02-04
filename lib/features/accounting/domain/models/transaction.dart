import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

enum TransactionType {
  expense,   // 支出
  income,    // 收入
  transfer;  // 转账（未来扩展）
}

enum LedgerType {
  survival,  // 生存账本
  soul;      // 灵魂账本
}

@freezed
class Transaction with _$Transaction {
  const Transaction._();

  const factory Transaction({
    required String id,
    required String bookId,
    required String deviceId,
    required int amount,       // 金额（分）
    required TransactionType type,
    required String categoryId,
    required LedgerType ledgerType,
    required DateTime timestamp,

    // Optional fields
    String? note,
    String? photoHash,
    String? merchant,
    Map<String, dynamic>? metadata,

    // Hash chain
    String? prevHash,
    required String currentHash,

    // Timestamps
    required DateTime createdAt,
    DateTime? updatedAt,

    // Flags
    @Default(false) bool isPrivate,
    @Default(false) bool isSynced,
    @Default(false) bool isDeleted,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);

  /// Calculate hash of current transaction
  /// Uses SHA-256 hash chain (compatible with HashChainService)
  String calculateHash() {
    final input = [
      id,
      bookId,
      amount.toString(),
      type.name,
      categoryId,
      ledgerType.name,
      timestamp.millisecondsSinceEpoch.toString(),
      prevHash ?? 'genesis',
    ].join('|');

    // SHA-256 hash calculation (same as HashChainService)
    final bytes = utf8.encode(input);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Verify hash integrity
  bool verifyHash() {
    return currentHash == calculateHash();
  }

  /// Create new transaction with auto-generated ID and hash
  factory Transaction.create({
    required String bookId,
    required String deviceId,
    required int amount,
    required TransactionType type,
    required String categoryId,
    required LedgerType ledgerType,
    DateTime? timestamp,
    String? note,
    String? photoHash,
    String? merchant,
    Map<String, dynamic>? metadata,
    String? prevHash,
    bool isPrivate = false,
  }) {
    final now = DateTime.now();
    final tx = Transaction(
      id: const Uuid().v4(),
      bookId: bookId,
      deviceId: deviceId,
      amount: amount,
      type: type,
      categoryId: categoryId,
      ledgerType: ledgerType,
      timestamp: timestamp ?? now,
      note: note,
      photoHash: photoHash,
      merchant: merchant,
      metadata: metadata,
      prevHash: prevHash,
      currentHash: '',  // Placeholder
      createdAt: now,
      isPrivate: isPrivate,
    );

    // Calculate and set hash
    return tx.copyWith(currentHash: tx.calculateHash());
  }
}
