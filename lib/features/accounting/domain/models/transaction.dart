import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

enum TransactionType { expense, income, transfer }

enum LedgerType { survival, soul }

@freezed
abstract class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required String bookId,
    required String deviceId,
    required int amount,
    required TransactionType type,
    required String categoryId,
    required LedgerType ledgerType,
    required DateTime timestamp,

    // Optional fields
    String? note,
    String? photoHash,
    String? merchant,

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
}
