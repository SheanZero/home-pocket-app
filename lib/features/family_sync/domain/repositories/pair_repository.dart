import '../models/paired_device.dart';

/// Abstract repository interface for paired device management.
abstract class PairRepository {
  /// Save a pending pair (Device A initiated, status: pending).
  /// At this point there is no partner info, only pairCode and expiry.
  Future<void> savePendingPair({
    required String pairId,
    required String bookId,
    required String pairCode,
    required DateTime expiresAt,
  });

  /// Save a confirming pair (Device B joined, status: confirming).
  /// Partner info is available but not yet activated.
  /// getActivePair() will NOT return this state.
  Future<void> saveConfirmingPair({
    required String pairId,
    required String bookId,
    required String partnerDeviceId,
    required String partnerPublicKey,
    required String partnerDeviceName,
  });

  /// Activate pair: pending -> active (Device A confirms).
  /// Stores partner information and sets status to active.
  Future<void> activatePair({
    required String pairId,
    required String bookId,
    required String partnerDeviceId,
    required String partnerPublicKey,
    required String partnerDeviceName,
  });

  /// Device B: confirming -> active after receiving confirmation push.
  Future<void> confirmLocalPair(String pairId);

  /// Get the currently active pair (status == 'active' ONLY).
  /// Never returns pending or confirming pairs.
  Future<PairedDevice?> getActivePair();

  /// Get the current pending pair (status == 'pending' or 'confirming').
  Future<PairedDevice?> getPendingPair();

  /// Update last sync time using server-issued timestamp.
  Future<void> updateLastSyncTime(DateTime syncTime);

  /// Deactivate pair (set status to inactive).
  Future<void> deactivatePair(String pairId);
}
