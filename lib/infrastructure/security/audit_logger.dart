import 'package:drift/drift.dart';
import 'package:ulid/ulid.dart';

import '../../data/app_database.dart';
import 'models/audit_log_entry.dart';
import 'secure_storage_service.dart';

/// Security event audit logger.
///
/// Records structured audit events to the `audit_logs` Drift table.
/// Provides query, filtering, and CSV export capabilities.
///
/// Security rules for the `details` field:
/// - ALLOWED: algorithm names, transaction IDs, counts, error types
/// - FORBIDDEN: encryption keys, plaintext amounts, PINs, mnemonics
class AuditLogger {
  AuditLogger({
    required AppDatabase database,
    required SecureStorageService storageService,
  }) : _database = database,
       _storageService = storageService;

  final AppDatabase _database;
  final SecureStorageService _storageService;

  /// Record an audit event.
  ///
  /// Automatically fills [id] (ULID), [deviceId], and [timestamp].
  Future<void> log({
    required AuditEvent event,
    String? bookId,
    String? transactionId,
    String? details,
  }) async {
    final deviceId = await _storageService.getDeviceId() ?? 'unknown';

    await _database
        .into(_database.auditLogs)
        .insert(
          AuditLogsCompanion.insert(
            id: Ulid().toString(),
            event: event.name,
            deviceId: deviceId,
            bookId: Value(bookId),
            transactionId: Value(transactionId),
            details: Value(details),
            timestamp: DateTime.now(),
          ),
        );
  }

  /// Query audit logs with optional filters.
  ///
  /// Results are ordered newest-first. All filter parameters
  /// are AND-combined.
  Future<List<AuditLogEntry>> getLogs({
    String? bookId,
    AuditEvent? eventType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    final query = _database.select(_database.auditLogs)
      ..orderBy([
        (t) => OrderingTerm.desc(t.timestamp),
        (t) =>
            OrderingTerm.desc(t.id), // ULID tiebreaker for same-second entries
      ])
      ..limit(limit, offset: offset);

    if (bookId != null) {
      query.where((t) => t.bookId.equals(bookId));
    }
    if (eventType != null) {
      query.where((t) => t.event.equals(eventType.name));
    }
    if (startDate != null) {
      query.where((t) => t.timestamp.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where((t) => t.timestamp.isSmallerOrEqualValue(endDate));
    }

    final rows = await query.get();
    return rows.map(_rowToEntry).toList();
  }

  /// Count logs matching the given filters.
  Future<int> getLogCount({
    String? bookId,
    AuditEvent? eventType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final countExp = _database.auditLogs.id.count();
    final query = _database.selectOnly(_database.auditLogs)
      ..addColumns([countExp]);

    if (bookId != null) {
      query.where(_database.auditLogs.bookId.equals(bookId));
    }
    if (eventType != null) {
      query.where(_database.auditLogs.event.equals(eventType.name));
    }
    if (startDate != null) {
      query.where(
        _database.auditLogs.timestamp.isBiggerOrEqualValue(startDate),
      );
    }
    if (endDate != null) {
      query.where(_database.auditLogs.timestamp.isSmallerOrEqualValue(endDate));
    }

    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }

  /// Export logs to CSV string.
  ///
  /// Returns the CSV content. The caller is responsible for writing
  /// to a file if needed.
  Future<String> exportToCSV({String? bookId}) async {
    final logs = await getLogs(bookId: bookId, limit: 999999);

    final buffer = StringBuffer();
    buffer.writeln('id,event,deviceId,bookId,transactionId,details,timestamp');

    for (final log in logs) {
      buffer.writeln(
        [
          log.id,
          log.event.name,
          log.deviceId,
          log.bookId ?? '',
          log.transactionId ?? '',
          _escapeCSV(log.details ?? ''),
          log.timestamp.toIso8601String(),
        ].join(','),
      );
    }

    return buffer.toString();
  }

  AuditLogEntry _rowToEntry(AuditLog row) {
    return AuditLogEntry(
      id: row.id,
      event: AuditEvent.values.firstWhere(
        (e) => e.name == row.event,
        orElse: () => AuditEvent.appLaunched,
      ),
      deviceId: row.deviceId,
      bookId: row.bookId,
      transactionId: row.transactionId,
      details: row.details,
      timestamp: row.timestamp,
    );
  }

  String _escapeCSV(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
