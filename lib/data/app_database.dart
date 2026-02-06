import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'tables/audit_logs_table.dart';

part 'app_database.g.dart';

/// Main application database.
///
/// Currently contains only the audit_logs table.
/// Will be expanded with transaction, category, and book tables
/// in Phase 2 (MOD-001 Basic Accounting).
@DriftDatabase(tables: [AuditLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// In-memory database for testing.
  AppDatabase.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}
