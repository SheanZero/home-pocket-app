/// Fail-closed limits for decrypted inbound family-sync operations.
///
/// A normal full-sync chunk contains 50 operations. The 500-operation ceiling
/// leaves a 10x compatibility margin while preventing a single authenticated
/// peer message from causing unbounded decode/apply work. Quarantine storage is
/// separately capped by row count and stored UTF-8 payload bytes.
abstract final class InboundSyncResourcePolicy {
  static const int maxOperationsPerMessage = 500;
  static const int maxOperationJsonBytes = 64 * 1024;
  static const int maxSafeSummaryJsonBytes = 1024;
  static const int maxQuarantineEntriesPerGroup = 200;
  static const int maxQuarantinePayloadBytesPerGroup = 1 << 20;
  static const Duration quarantineTtl = Duration(days: 30);
  static const int quarantinePageSize = 50;

  static const int maxOperationIdBytes = 256;
  static const int maxGroupIdBytes = 256;
  static const int maxMessageIdBytes = 256;
  static const int maxEntityTypeBytes = 64;
  static const int maxEntityIdBytes = 256;
  static const int maxOriginDeviceIdBytes = 256;
  static const int maxOperationNameBytes = 32;
  static const int maxErrorCodeBytes = 128;
}
