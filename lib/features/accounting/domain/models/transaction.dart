import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

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

  /// Create new transaction with auto-generated ID
  /// Hash must be calculated externally using HashChainService
  factory Transaction.create({
    required String bookId,
    required String deviceId,
    required int amount,
    required TransactionType type,
    required String categoryId,
    required LedgerType ledgerType,
    required String currentHash,  // ✅ Hash provided externally
    DateTime? timestamp,
    String? note,
    String? photoHash,
    String? merchant,
    Map<String, dynamic>? metadata,
    String? prevHash,
    bool isPrivate = false,
  }) {
    final now = DateTime.now();
    return Transaction(
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
      currentHash: currentHash,  // ✅ Use externally calculated hash
      createdAt: now,
      isPrivate: isPrivate,
    );
  }
}
