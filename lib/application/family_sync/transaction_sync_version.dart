import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/models/transaction_photo_sync_policy.dart';

/// Comparable, deterministic version for a synchronized transaction state.
///
/// Ordering is Lamport revision, tombstone priority, writer id, then a digest
/// of the complete synced state. The final digest makes even a malformed pair
/// of same-writer/same-revision operations converge independently of arrival
/// order. Correct producers normally decide at the writer-id step.
class TransactionSyncVersion implements Comparable<TransactionSyncVersion> {
  const TransactionSyncVersion({
    required this.revision,
    required this.isDeleted,
    required this.originDeviceId,
    required this.contentTag,
  });

  final int revision;
  final bool isDeleted;
  final String originDeviceId;
  final String contentTag;

  factory TransactionSyncVersion.fromTransaction(Transaction transaction) {
    return TransactionSyncVersion(
      revision: effectiveSyncRevision(transaction),
      isDeleted: transaction.isDeleted,
      originDeviceId: effectiveSyncOriginDeviceId(transaction),
      contentTag: transactionSyncContentTag(transaction),
    );
  }

  @override
  int compareTo(TransactionSyncVersion other) {
    final revisionOrder = revision.compareTo(other.revision);
    if (revisionOrder != 0) return revisionOrder;
    final tombstoneOrder = (isDeleted ? 1 : 0).compareTo(
      other.isDeleted ? 1 : 0,
    );
    if (tombstoneOrder != 0) return tombstoneOrder;
    final originOrder = originDeviceId.compareTo(other.originDeviceId);
    if (originOrder != 0) return originOrder;
    return contentTag.compareTo(other.contentTag);
  }
}

int effectiveSyncRevision(Transaction transaction) {
  if (transaction.syncRevision > 0) return transaction.syncRevision;
  return (transaction.updatedAt ?? transaction.createdAt)
      .toUtc()
      .microsecondsSinceEpoch;
}

String effectiveSyncOriginDeviceId(Transaction transaction) {
  return transaction.syncOriginDeviceId.isNotEmpty
      ? transaction.syncOriginDeviceId
      : transaction.deviceId;
}

int nextSyncRevision(Transaction transaction, DateTime now) {
  final wallClock = now.toUtc().microsecondsSinceEpoch;
  final logicalNext = effectiveSyncRevision(transaction) + 1;
  return wallClock > logicalNext ? wallClock : logicalNext;
}

/// SHA-256 over a canonical JSON projection of every synchronized bill field.
String transactionSyncContentTag(Transaction transaction) {
  final canonical = <String, dynamic>{
    'id': transaction.id,
    'amount': transaction.amount,
    'type': transaction.type.name,
    'categoryId': transaction.categoryId,
    'ledgerType': transaction.ledgerType.name,
    'timestamp': transaction.timestamp.toUtc().toIso8601String(),
    'createdAt': transaction.createdAt.toUtc().toIso8601String(),
    'updatedAt': transaction.updatedAt?.toUtc().toIso8601String(),
    'note': transaction.note,
    'merchant': transaction.merchant,
    // Local-only receipt lookup keys are intentionally outside synchronized
    // bill state. Only the explicit availability boundary participates.
    'photoAvailability': TransactionPhotoSyncPolicy.availabilityFor(
      transaction,
    ),
    'originalCurrency': transaction.originalCurrency,
    'originalAmount': transaction.originalAmount,
    'appliedRate': transaction.appliedRate,
    'metadata': _canonicalize(transaction.metadata),
    'joyFullness': transaction.joyFullness,
    'entrySource': transaction.entrySource.name,
    'isPrivate': transaction.isPrivate,
    'isDeleted': transaction.isDeleted,
  };
  return sha256.convert(utf8.encode(jsonEncode(canonical))).toString();
}

dynamic _canonicalize(dynamic value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return <String, dynamic>{
      for (final key in keys) key: _canonicalize(value[key]),
    };
  }
  if (value is List) return value.map(_canonicalize).toList();
  return value;
}
