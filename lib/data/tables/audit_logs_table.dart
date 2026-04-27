import 'package:drift/drift.dart';

/// Audit log table — stores security event records.
///
/// See [AuditEvent] enum for valid event type values.
/// The `event` column stores enum `.name` strings.
class AuditLogs extends Table {
  // coverage:ignore-start
  // Drift column DSL is consumed by code generation and is not callable at
  // runtime. Generated table classes cover the executable behavior.
  /// ULID — time-sortable unique identifier.
  TextColumn get id => text()();

  /// Event type (AuditEvent.name string).
  TextColumn get event => text()();

  /// Device that produced this event.
  TextColumn get deviceId => text()();

  /// Associated book ID (optional).
  TextColumn get bookId => text().nullable()();

  /// Associated transaction ID (optional).
  TextColumn get transactionId => text().nullable()();

  /// Extra JSON details (optional). MUST NOT contain sensitive data.
  TextColumn get details => text().nullable()();

  /// When the event occurred.
  DateTimeColumn get timestamp => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
  // coverage:ignore-end

  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_audit_logs_event', columns: {#event}),
    TableIndex(name: 'idx_audit_logs_device_id', columns: {#deviceId}),
    TableIndex(name: 'idx_audit_logs_timestamp', columns: {#timestamp}),
  ];
}
