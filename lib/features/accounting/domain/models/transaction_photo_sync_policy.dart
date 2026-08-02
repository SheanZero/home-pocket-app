import 'transaction.dart';

/// Family-sync and backup policy for receipt photos.
///
/// Transaction photo storage has not shipped yet: [Transaction.photoHash] is
/// only a local lookup key and is neither a blob nor a recoverable remote
/// reference. Until a bounded E2EE blob protocol exists, sync and backup must
/// carry availability only and must never copy that local key to another
/// device.
class TransactionPhotoSyncPolicy {
  TransactionPhotoSyncPolicy._();

  static const wireAvailabilityKey = 'photoAvailability';
  static const metadataAvailabilityKey = '_receiptPhotoAvailability';
  static const none = 'none';
  static const localOnly = 'local_only';

  static String availabilityFor(Transaction transaction) {
    if (transaction.isDeleted) return none;
    final localHash = transaction.photoHash;
    if (localHash != null && localHash.isNotEmpty) return localOnly;
    return transaction.metadata?[metadataAvailabilityKey] == localOnly
        ? localOnly
        : none;
  }

  /// Sanitizes untrusted sync/backup metadata while retaining the UX boundary.
  ///
  /// A legacy non-empty `photoHash` is evidence that the source device had a
  /// photo, but the value itself is deliberately ignored. Media-like fields
  /// (mime, size, bytes) are never parsed by this local-only protocol.
  static Map<String, dynamic>? sanitizedInboundMetadata(
    Map<String, dynamic> source, {
    required bool isDeleted,
  }) {
    final rawMetadata = source['metadata'];
    final metadata = rawMetadata is Map<String, dynamic>
        ? Map<String, dynamic>.of(rawMetadata)
        : <String, dynamic>{};
    metadata.remove(metadataAvailabilityKey);

    if (!isDeleted) {
      final availability = source[wireAvailabilityKey];
      final legacyHash = source['photoHash'];
      final hadLegacyHash = legacyHash is String && legacyHash.isNotEmpty;
      if (availability == localOnly || hadLegacyHash) {
        metadata[metadataAvailabilityKey] = localOnly;
      }
    }

    return metadata.isEmpty ? null : metadata;
  }

  static bool isUnavailableRemotePhoto(Transaction transaction) =>
      transaction.photoHash == null &&
      !transaction.isDeleted &&
      transaction.metadata?[metadataAvailabilityKey] == localOnly;

  static bool isAvailableOnlyOnThisDevice(Transaction transaction) =>
      !transaction.isDeleted &&
      transaction.photoHash != null &&
      transaction.photoHash!.isNotEmpty;

  /// Removes local-only media keys from a transaction backup record and emits
  /// the same explicit availability contract as family sync.
  static Map<String, dynamic> toBackupJson(Transaction transaction) {
    final json = Map<String, dynamic>.of(transaction.toJson())
      ..remove('photoHash')
      ..[wireAvailabilityKey] = availabilityFor(transaction);
    return json;
  }

  /// Old backups could contain a bare local `photoHash`. Preserve only the
  /// fact that a photo existed; never restore the unusable lookup key.
  static Map<String, dynamic> sanitizeBackupJson(Map<String, dynamic> source) {
    final json = Map<String, dynamic>.of(source);
    final isDeleted = json['isDeleted'] == true;
    final metadata = sanitizedInboundMetadata(json, isDeleted: isDeleted);
    json
      ..remove('photoHash')
      ..['metadata'] = metadata;
    return json;
  }
}
