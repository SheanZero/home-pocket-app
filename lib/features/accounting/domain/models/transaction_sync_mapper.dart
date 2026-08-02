import 'entry_source.dart';
import 'transaction.dart';
import 'transaction_family_sync_policy.dart';
import 'transaction_photo_sync_policy.dart';

/// Maps [Transaction] to and from the sync protocol payload.
class TransactionSyncMapper {
  TransactionSyncMapper._();

  static Map<String, dynamic> toSyncMap(
    Transaction transaction, {
    required String sourceBookId,
    required String sourceBookName,
    required String sourceBookType,
  }) {
    if (transaction.isPrivate || transaction.isDeleted) {
      throw StateError(
        'Private/deleted transactions cannot be serialized as live family bills',
      );
    }
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
      // A local photo hash is not a blob/reference. Only its availability may
      // cross devices until a bounded E2EE media protocol exists.
      TransactionPhotoSyncPolicy.wireAvailabilityKey:
          TransactionPhotoSyncPolicy.availabilityFor(transaction),
      if (transaction.originalCurrency != null)
        'originalCurrency': transaction.originalCurrency,
      if (transaction.originalAmount != null)
        'originalAmount': transaction.originalAmount,
      if (transaction.appliedRate != null)
        'appliedRate': transaction.appliedRate,
      'metadata': {
        'sourceBookId': sourceBookId,
        'sourceBookName': sourceBookName,
        'sourceBookType': sourceBookType,
      },
      'joyFullness': transaction.joyFullness,
      'entrySource': transaction.entrySource.name,
      'isDeleted': false,
      'syncRevision': _effectiveSyncRevision(transaction),
      'syncOriginDeviceId': _effectiveSyncOriginDeviceId(transaction),
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
    final tripleValid =
        originalCurrency != null &&
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
      // Never persist another device's local lookup key. Legacy payloads are
      // reduced to an explicit unavailable-photo marker in metadata.
      photoHash: null,
      merchant: data['merchant'] as String?,
      metadata: TransactionPhotoSyncPolicy.sanitizedInboundMetadata(
        data,
        isDeleted: data['isDeleted'] == true,
      ),
      originalCurrency: tripleValid ? originalCurrency : null,
      originalAmount: tripleValid ? originalAmount : null,
      appliedRate: tripleValid ? appliedRate : null,
      currentHash: '',
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: data['updatedAt'] is String
          ? DateTime.parse(data['updatedAt'] as String)
          : null,
      // Remote bills are always public shadow copies. Private/local-only wire
      // state is rejected before this mapper is called.
      isPrivate: false,
      isSynced: true,
      isDeleted: data['isDeleted'] as bool? ?? false,
      syncRevision: (data['syncRevision'] as num?)?.toInt() ?? 0,
      syncOriginDeviceId: data['syncOriginDeviceId'] as String? ?? deviceId,
      familySyncVisibility: FamilySyncVisibility.localOnly,
      familySharedRevision: 0,
      joyFullness: data['joyFullness'] as int? ?? 2,
      // D-09: absent field falls back to 'manual' (older v16 peers do not send entrySource).
      entrySource: EntrySource.values.byName(
        (data['entrySource'] as String?) ?? 'manual',
      ),
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
    return _toVersionedOperation(
      op: 'create',
      transaction: transaction,
      sourceBookId: sourceBookId,
      sourceBookName: sourceBookName,
      sourceBookType: sourceBookType,
    );
  }

  static Map<String, dynamic> _toVersionedOperation({
    required String op,
    required Transaction transaction,
    required String sourceBookId,
    required String sourceBookName,
    required String sourceBookType,
  }) {
    final revision = _effectiveSyncRevision(transaction);
    final originDeviceId = _effectiveSyncOriginDeviceId(transaction);
    return {
      'op': op,
      'entityType': 'bill',
      'entityId': transaction.id,
      'data': toSyncMap(
        transaction,
        sourceBookId: sourceBookId,
        sourceBookName: sourceBookName,
        sourceBookType: sourceBookType,
      ),
      'revision': revision,
      'originDeviceId': originDeviceId,
      'timestamp': (transaction.updatedAt ?? transaction.createdAt)
          .toUtc()
          .toIso8601String(),
    };
  }

  static Map<String, dynamic> toUpdateOperation(
    Transaction transaction, {
    required String sourceBookId,
    required String sourceBookName,
    required String sourceBookType,
  }) {
    return _toVersionedOperation(
      op: 'update',
      transaction: transaction,
      sourceBookId: sourceBookId,
      sourceBookName: sourceBookName,
      sourceBookType: sourceBookType,
    );
  }

  static Map<String, dynamic> toDeleteOperation(
    Transaction transaction, {
    required String sourceBookId,
    required String sourceBookName,
    required String sourceBookType,
  }) {
    assert(transaction.isDeleted, 'delete operation requires a tombstone');
    return toWithdrawalOperation(transaction);
  }

  /// Minimal, idempotent withdrawal/delete tombstone. No bill/category/photo
  /// content is serialized, even though it remains in the local row.
  static Map<String, dynamic> toWithdrawalOperation(Transaction transaction) {
    final revision = _effectiveSyncRevision(transaction);
    final originDeviceId = _effectiveSyncOriginDeviceId(transaction);
    return {
      'op': 'delete',
      'entityType': 'bill',
      'entityId': transaction.id,
      'data': {
        'isDeleted': true,
        'syncRevision': revision,
        'syncOriginDeviceId': originDeviceId,
      },
      'revision': revision,
      'originDeviceId': originDeviceId,
      'timestamp': (transaction.updatedAt ?? transaction.createdAt)
          .toUtc()
          .toIso8601String(),
    };
  }

  /// Complete state used by full sync to repair lost creates, updates, and
  /// deletes. Receivers version-compare and upsert rather than skipping rows.
  static Map<String, dynamic> toReconcileOperation(
    Transaction transaction, {
    required String sourceBookId,
    required String sourceBookName,
    required String sourceBookType,
  }) {
    return _toVersionedOperation(
      op: 'reconcile',
      transaction: transaction,
      sourceBookId: sourceBookId,
      sourceBookName: sourceBookName,
      sourceBookType: sourceBookType,
    );
  }

  /// Returns the only operation full sync is allowed to emit for this local
  /// row, or null when the row is local-only/already withdrawn.
  static Map<String, dynamic>? toFullSyncOperation(
    Transaction transaction, {
    required String sourceBookId,
    required String sourceBookName,
    required String sourceBookType,
  }) {
    if (TransactionFamilySyncPolicy.shouldSendWithdrawal(transaction)) {
      return toWithdrawalOperation(transaction);
    }
    if (TransactionFamilySyncPolicy.shouldSendLive(transaction)) {
      return toReconcileOperation(
        transaction,
        sourceBookId: sourceBookId,
        sourceBookName: sourceBookName,
        sourceBookType: sourceBookType,
      );
    }
    return null;
  }

  static int _effectiveSyncRevision(Transaction transaction) {
    if (transaction.syncRevision > 0) return transaction.syncRevision;
    return (transaction.updatedAt ?? transaction.createdAt)
        .toUtc()
        .microsecondsSinceEpoch;
  }

  static String _effectiveSyncOriginDeviceId(Transaction transaction) {
    return transaction.syncOriginDeviceId.isNotEmpty
        ? transaction.syncOriginDeviceId
        : transaction.deviceId;
  }
}
