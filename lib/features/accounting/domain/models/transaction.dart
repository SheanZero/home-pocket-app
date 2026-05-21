import 'package:freezed_annotation/freezed_annotation.dart';

import 'entry_source.dart';

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

    // Soul ledger satisfaction score (1-10, default 2)
    @Default(2) int soulSatisfaction,

    // Entry-path provenance (D-01 / D-09). Default 'manual' applies for older
    // sync payloads / DB rows where the column DEFAULT triggered.
    // CreateTransactionParams enforces required-no-default (D-06, Plan 04).
    @Default(EntrySource.manual) EntrySource entrySource,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}
