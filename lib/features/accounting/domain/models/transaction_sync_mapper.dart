import 'entry_source.dart';
import 'transaction.dart';

/// Maps [Transaction] to and from the sync protocol payload.
class TransactionSyncMapper {
  TransactionSyncMapper._();

  static Map<String, dynamic> toSyncMap(
    Transaction transaction, {
    required String sourceBookId,
    required String sourceBookName,
    required String sourceBookType,
  }) {
    return {
      'id': transaction.id,
      'amount': transaction.amount,
      'type': transaction.type.name,
      'categoryId': transaction.categoryId,
      'ledgerType': transaction.ledgerType.name,
      'timestamp': transaction.timestamp.toUtc().toIso8601String(),
      'createdAt': transaction.createdAt.toUtc().toIso8601String(),
      if (transaction.updatedAt != null)
        'updatedAt': transaction.updatedAt!.toUtc().toIso8601String(),
      if (transaction.note != null) 'note': transaction.note,
      if (transaction.merchant != null) 'merchant': transaction.merchant,
      if (transaction.photoHash != null) 'photoHash': transaction.photoHash,
      if (transaction.originalCurrency != null)
        'originalCurrency': transaction.originalCurrency,
      if (transaction.originalAmount != null)
        'originalAmount': transaction.originalAmount,
      if (transaction.appliedRate != null) 'appliedRate': transaction.appliedRate,
      'metadata': {
        'sourceBookId': sourceBookId,
        'sourceBookName': sourceBookName,
        'sourceBookType': sourceBookType,
      },
      'joyFullness': transaction.joyFullness,
      'entrySource': transaction.entrySource.name,
      'isPrivate': transaction.isPrivate,
    };
  }

  static Transaction fromSyncMap(
    Map<String, dynamic> data, {
    required String bookId,
    required String deviceId,
  }) {
    // CR-01 (Phase 40 review): the sync wire is untrusted input. ADR-021
    // designates the partial-triple invariant as the sole integrity mechanism
    // for the currency provenance fields (they are excluded from the hash
    // chain), so it must hold at the sync ingestion boundary too — not only
    // in CreateTransactionUseCase. Policy: a partial or invalid triple
    // degrades to JPY-native (all three null) instead of persisting invalid
    // domain state or dropping the whole operation — the hashed JPY `amount`
    // stays authoritative; only provenance metadata is discarded.
    // `is` checks (not `as` casts) so a peer sending wrong JSON types (e.g.
    // numeric appliedRate) cannot throw here.
    final rawCurrency = data['originalCurrency'];
    final rawOriginalAmount = data['originalAmount'];
    final rawAppliedRate = data['appliedRate'];
    final originalCurrency = rawCurrency is String ? rawCurrency : null;
    final originalAmount = rawOriginalAmount is int ? rawOriginalAmount : null;
    final appliedRate = rawAppliedRate is String ? rawAppliedRate : null;
    final tripleValid = originalCurrency != null &&
        originalAmount != null &&
        appliedRate != null &&
        originalAmount > 0 &&
        _iso4217.hasMatch(originalCurrency) &&
        _isValidRate(appliedRate);

    return Transaction(
      id: data['id'] as String,
      bookId: bookId,
      deviceId: deviceId,
      amount: data['amount'] as int,
      type: TransactionType.values.byName(data['type'] as String),
      categoryId: data['categoryId'] as String,
      ledgerType: LedgerType.values.byName(data['ledgerType'] as String),
      timestamp: DateTime.parse(data['timestamp'] as String),
      note: data['note'] as String?,
      photoHash: data['photoHash'] as String?,
      merchant: data['merchant'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
      originalCurrency: tripleValid ? originalCurrency : null,
      originalAmount: tripleValid ? originalAmount : null,
      appliedRate: tripleValid ? appliedRate : null,
      currentHash: '',
      createdAt: DateTime.parse(data['createdAt'] as String),
      isPrivate: data['isPrivate'] as bool? ?? false,
      isSynced: true,
      joyFullness: data['joyFullness'] as int? ?? 2,
      // D-09: absent field falls back to 'manual' (older v16 peers do not send entrySource).
      entrySource: EntrySource.values.byName((data['entrySource'] as String?) ?? 'manual'),
    );
  }

  /// ISO 4217 currency code shape: exactly 3 uppercase ASCII letters.
  static final _iso4217 = RegExp(r'^[A-Z]{3}$');

  /// Plain positive decimal literal (no sign, exponent, or whitespace —
  /// ADR-020 D-05). Mirrors `validateAppliedRate` in
  /// `lib/shared/utils/currency_conversion.dart`; the domain-models import
  /// guard (intra-domain-only allow list) prevents importing it here, so the
  /// shape rule is duplicated as a private wire-boundary check.
  static final _plainDecimal = RegExp(r'^\d+(\.\d+)?$');

  static bool _isValidRate(String raw) {
    if (!_plainDecimal.hasMatch(raw)) return false;
    final rate = double.tryParse(raw);
    return rate != null && rate.isFinite && rate > 0;
  }

  static Map<String, dynamic> toCreateOperation(
    Transaction transaction, {
    required String sourceBookId,
    required String sourceBookName,
    required String sourceBookType,
  }) {
    return {
      'op': 'create',
      'entityType': 'bill',
      'entityId': transaction.id,
      'data': toSyncMap(
        transaction,
        sourceBookId: sourceBookId,
        sourceBookName: sourceBookName,
        sourceBookType: sourceBookType,
      ),
      'timestamp': transaction.createdAt.toUtc().toIso8601String(),
    };
  }

  static Map<String, dynamic> toUpdateOperation(
    Transaction transaction, {
    required String sourceBookId,
    required String sourceBookName,
    required String sourceBookType,
  }) {
    return {
      'op': 'update',
      'entityType': 'bill',
      'entityId': transaction.id,
      'data': toSyncMap(
        transaction,
        sourceBookId: sourceBookId,
        sourceBookName: sourceBookName,
        sourceBookType: sourceBookType,
      ),
      'timestamp': (transaction.updatedAt ?? transaction.createdAt)
          .toUtc()
          .toIso8601String(),
    };
  }

  static Map<String, dynamic> toDeleteOperation(String transactionId) {
    return {'op': 'delete', 'entityType': 'bill', 'entityId': transactionId};
  }
}
