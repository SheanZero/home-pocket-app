import 'transaction.dart';

/// Fail-closed policy for deciding whether a bill may cross the family-sync
/// boundary. The current `isPrivate` flag alone is deliberately insufficient:
/// an older public revision can leave a withdrawal obligation behind.
class TransactionFamilySyncPolicy {
  TransactionFamilySyncPolicy._();

  static const _localWireKeys = <String>{
    'familySyncVisibility',
    'familySharedRevision',
    'familyVisibility',
    'withdrawalPending',
    'privateData',
    'privateMetadata',
    'localOnly',
    'localOnlyData',
  };

  static FamilySyncVisibility visibilityForCreate({required bool isPrivate}) =>
      isPrivate ? FamilySyncVisibility.localOnly : FamilySyncVisibility.shared;

  static FamilySyncVisibility visibilityForUpdate({
    required Transaction before,
    required bool isPrivate,
  }) {
    if (isPrivate) {
      return switch (before.familySyncVisibility) {
        FamilySyncVisibility.shared => FamilySyncVisibility.withdrawalPending,
        FamilySyncVisibility.withdrawalPending =>
          FamilySyncVisibility.withdrawalPending,
        FamilySyncVisibility.withdrawn => FamilySyncVisibility.withdrawn,
        FamilySyncVisibility.localOnly => FamilySyncVisibility.localOnly,
      };
    }
    // Making a transaction public, or explicitly editing an already-public
    // local-only restore, creates a new shared live revision.
    return FamilySyncVisibility.shared;
  }

  static FamilySyncVisibility visibilityForDelete(Transaction before) {
    return switch (before.familySyncVisibility) {
      FamilySyncVisibility.shared => FamilySyncVisibility.withdrawalPending,
      FamilySyncVisibility.withdrawalPending =>
        FamilySyncVisibility.withdrawalPending,
      FamilySyncVisibility.withdrawn => FamilySyncVisibility.withdrawn,
      FamilySyncVisibility.localOnly => FamilySyncVisibility.localOnly,
    };
  }

  static bool shouldSendLive(Transaction transaction) =>
      !transaction.isPrivate &&
      !transaction.isDeleted &&
      transaction.familySyncVisibility == FamilySyncVisibility.shared;

  static bool shouldSendWithdrawal(Transaction transaction) =>
      (transaction.isPrivate || transaction.isDeleted) &&
      transaction.familySyncVisibility ==
          FamilySyncVisibility.withdrawalPending;

  /// Returns a stable safe error code, or null for legacy-compatible public
  /// payloads (`isPrivate: false` or field absent).
  static String? inboundViolation(Map<String, dynamic> data) {
    if ((data.containsKey('isPrivate') && data['isPrivate'] != false) ||
        data.keys.any(_localWireKeys.contains)) {
      return 'private_bill_payload';
    }
    return null;
  }

  /// Last-resort defense for tracker/full-sync callers that accidentally
  /// construct a bill operation outside the mapper.
  static bool isSafeOutboundOperation(Map<String, dynamic> operation) {
    if (operation['entityType'] != 'bill') return true;
    final data = operation['data'];
    if (data is! Map<String, dynamic>) return false;
    if (inboundViolation(data) != null) return false;

    final isTombstone =
        operation['op'] == 'delete' || data['isDeleted'] == true;
    if (!isTombstone) return true;

    // A family withdrawal/delete may reveal only version metadata. In
    // particular no amount, category, note, merchant, photo, metadata, custom
    // category snapshot, or digest is permitted.
    const tombstoneKeys = <String>{
      'isDeleted',
      'syncRevision',
      'syncOriginDeviceId',
    };
    return data.keys.every(tombstoneKeys.contains) && data['isDeleted'] == true;
  }
}
