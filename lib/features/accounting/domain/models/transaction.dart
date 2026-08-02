import 'package:freezed_annotation/freezed_annotation.dart';

import 'entry_source.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

enum TransactionType { expense, income, transfer }

enum LedgerType { daily, joy }

/// Local-only ledger of a transaction's family-sync exposure.
///
/// This must never be inferred from the current [Transaction.isPrivate]
/// value: a private transaction may still need a withdrawal for an older
/// public revision.
enum FamilySyncVisibility {
  /// Never eligible for automatic family sync (new private / backup restore /
  /// inbound shadow copy).
  localOnly,

  /// A public revision has been staged or delivered and must be reconciled.
  shared,

  /// A minimal tombstone must be delivered (and retried) before settling.
  withdrawalPending,

  /// Relay accepted the withdrawal. Repeated full sync no longer needs it.
  withdrawn,
}

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

    // Foreign-currency provenance (all three null = JPY-native row per STORE-01)
    String? originalCurrency, // ISO 4217 code, e.g. 'USD'; null = native JPY
    int?
    originalAmount, // minor units (cents for USD: $12.50 → 1250); null = native JPY
    String?
    appliedRate, // JPY per 1 whole unit as string (D-04 / ADR-020); null = native JPY
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

    // Deterministic family-sync version. Local mutations advance this Lamport
    // value monotonically; remote peers compare it before applying state.
    @Default(0) int syncRevision,
    @Default('') String syncOriginDeviceId,

    // Local privacy ledger. These fields are persisted in the encrypted app
    // database, but are never serialized into the family wire payload.
    @Default(FamilySyncVisibility.localOnly)
    FamilySyncVisibility familySyncVisibility,
    @Default(0) int familySharedRevision,

    // Joy ledger fullness score (1-10, default 2)
    @Default(2) int joyFullness,

    // Entry-path provenance (D-01 / D-09). Default 'manual' applies for older
    // sync payloads / DB rows where the column DEFAULT triggered.
    // CreateTransactionParams enforces required-no-default (D-06, Plan 04).
    @Default(EntrySource.manual) EntrySource entrySource,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}
