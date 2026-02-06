import 'package:freezed_annotation/freezed_annotation.dart';

part 'audit_log_entry.freezed.dart';

/// Security audit event types.
///
/// Every auditable action in the app has an entry here.
/// Add new events as needed; keep sorted by category.
enum AuditEvent {
  // ── App lifecycle ──
  appLaunched,
  databaseOpened,

  // ── Authentication ──
  biometricAuthSuccess,
  biometricAuthFailed,
  pinAuthSuccess,
  pinAuthFailed,

  // ── Integrity ──
  chainVerified,
  tamperDetected,

  // ── Key management ──
  keyGenerated,
  keyRotated,
  recoveryKitGenerated,
  keyRecovered,

  // ── Sync (Phase 3) ──
  syncStarted,
  syncCompleted,
  syncFailed,
  devicePaired,
  deviceUnpaired,

  // ── Data management ──
  backupExported,
  backupImported,
  securitySettingsChanged,
}

/// A single audit log entry.
///
/// Immutable record of a security-relevant event.
/// Stored in the `audit_logs` Drift table.
@freezed
sealed class AuditLogEntry with _$AuditLogEntry {
  const factory AuditLogEntry({
    /// ULID — time-sortable unique identifier.
    required String id,

    /// The type of security event.
    required AuditEvent event,

    /// Device that produced this event.
    required String deviceId,

    /// Associated book ID (optional).
    String? bookId,

    /// Associated transaction ID (optional).
    String? transactionId,

    /// Extra JSON details. MUST NOT contain keys, PINs, or amounts.
    String? details,

    /// When the event occurred.
    required DateTime timestamp,
  }) = _AuditLogEntry;
}
