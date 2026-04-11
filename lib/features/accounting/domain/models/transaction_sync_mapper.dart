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
      'metadata': {
        'sourceBookId': sourceBookId,
        'sourceBookName': sourceBookName,
        'sourceBookType': sourceBookType,
      },
      'soulSatisfaction': transaction.soulSatisfaction,
      'isPrivate': transaction.isPrivate,
    };
  }

  static Transaction fromSyncMap(
    Map<String, dynamic> data, {
    required String bookId,
    required String deviceId,
  }) {
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
      currentHash: '',
      createdAt: DateTime.parse(data['createdAt'] as String),
      isPrivate: data['isPrivate'] as bool? ?? false,
      isSynced: true,
      soulSatisfaction: data['soulSatisfaction'] as int? ?? 5,
    );
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
