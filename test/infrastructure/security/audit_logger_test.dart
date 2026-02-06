import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/infrastructure/security/audit_logger.dart';
import 'package:home_pocket/infrastructure/security/models/audit_log_entry.dart';
import 'package:home_pocket/infrastructure/security/secure_storage_service.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late AppDatabase db;
  late MockSecureStorageService mockStorage;
  late AuditLogger logger;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    mockStorage = MockSecureStorageService();
    when(() => mockStorage.getDeviceId())
        .thenAnswer((_) async => 'test_device_id');
    logger = AuditLogger(database: db, storageService: mockStorage);
  });

  tearDown(() async {
    await db.close();
  });

  group('log', () {
    test('creates entry with correct fields', () async {
      await logger.log(event: AuditEvent.biometricAuthSuccess);

      final logs = await logger.getLogs();

      expect(logs.length, 1);
      expect(logs.first.event, AuditEvent.biometricAuthSuccess);
      expect(logs.first.deviceId, 'test_device_id');
      expect(logs.first.id, isNotEmpty);
      expect(logs.first.timestamp, isNotNull);
    });

    test('creates entry with optional bookId and details', () async {
      await logger.log(
        event: AuditEvent.tamperDetected,
        bookId: 'book_001',
        transactionId: 'tx_42',
        details: '{"tamperedIds": ["tx_42"]}',
      );

      final logs = await logger.getLogs();

      expect(logs.first.bookId, 'book_001');
      expect(logs.first.transactionId, 'tx_42');
      expect(logs.first.details, '{"tamperedIds": ["tx_42"]}');
    });

    test('uses "unknown" deviceId when storage returns null', () async {
      when(() => mockStorage.getDeviceId()).thenAnswer((_) async => null);

      await logger.log(event: AuditEvent.appLaunched);

      final logs = await logger.getLogs();
      expect(logs.first.deviceId, 'unknown');
    });

    test('generates unique IDs for each entry', () async {
      await logger.log(event: AuditEvent.appLaunched);
      await logger.log(event: AuditEvent.databaseOpened);

      final logs = await logger.getLogs();

      expect(logs[0].id, isNot(logs[1].id));
    });
  });

  group('getLogs', () {
    test('returns logs in descending insertion order (ULID tiebreaker)',
        () async {
      // Drift stores DateTime as integer seconds, so sub-second entries
      // share the same timestamp. ULID secondary sort ensures correct order.
      await logger.log(event: AuditEvent.appLaunched);
      await logger.log(event: AuditEvent.databaseOpened);

      final logs = await logger.getLogs();

      expect(logs.length, 2);
      expect(logs.first.event, AuditEvent.databaseOpened); // newest ULID first
      expect(logs.last.event, AuditEvent.appLaunched);
    });

    test('filters by eventType', () async {
      await logger.log(event: AuditEvent.biometricAuthSuccess);
      await logger.log(event: AuditEvent.biometricAuthFailed);
      await logger.log(event: AuditEvent.pinAuthSuccess);

      final logs =
          await logger.getLogs(eventType: AuditEvent.biometricAuthFailed);

      expect(logs.length, 1);
      expect(logs.first.event, AuditEvent.biometricAuthFailed);
    });

    test('filters by bookId', () async {
      await logger.log(event: AuditEvent.chainVerified, bookId: 'book_A');
      await logger.log(event: AuditEvent.chainVerified, bookId: 'book_B');

      final logs = await logger.getLogs(bookId: 'book_A');

      expect(logs.length, 1);
      expect(logs.first.bookId, 'book_A');
    });

    test('filters by date range', () async {
      // Drift stores DateTime as integer seconds, so we need >1s gap
      // to get distinct timestamp values for filtering.
      await logger.log(event: AuditEvent.appLaunched);
      await Future.delayed(const Duration(seconds: 2));
      final afterFirst = DateTime.now();
      await logger.log(event: AuditEvent.databaseOpened);

      final logs = await logger.getLogs(startDate: afterFirst);

      expect(logs.length, 1);
      expect(logs.first.event, AuditEvent.databaseOpened);
    });

    test('respects limit parameter', () async {
      for (int i = 0; i < 5; i++) {
        await logger.log(event: AuditEvent.appLaunched);
      }

      final logs = await logger.getLogs(limit: 3);

      expect(logs.length, 3);
    });

    test('respects offset parameter', () async {
      for (int i = 0; i < 5; i++) {
        await logger.log(event: AuditEvent.appLaunched);
        await Future.delayed(const Duration(milliseconds: 5));
      }

      final allLogs = await logger.getLogs();
      final offsetLogs = await logger.getLogs(offset: 2, limit: 2);

      expect(offsetLogs.length, 2);
      expect(offsetLogs.first.id, allLogs[2].id);
    });
  });

  group('getLogCount', () {
    test('returns total count', () async {
      await logger.log(event: AuditEvent.appLaunched);
      await logger.log(event: AuditEvent.databaseOpened);
      await logger.log(event: AuditEvent.biometricAuthSuccess);

      final count = await logger.getLogCount();

      expect(count, 3);
    });

    test('returns filtered count', () async {
      await logger.log(event: AuditEvent.biometricAuthSuccess);
      await logger.log(event: AuditEvent.biometricAuthFailed);
      await logger.log(event: AuditEvent.biometricAuthFailed);

      final count = await logger.getLogCount(
        eventType: AuditEvent.biometricAuthFailed,
      );

      expect(count, 2);
    });
  });

  group('exportToCSV', () {
    test('generates valid CSV with headers', () async {
      await logger.log(
        event: AuditEvent.keyGenerated,
        details: '{"algorithm": "Ed25519"}',
      );

      final csv = await logger.exportToCSV();

      expect(
          csv,
          contains(
              'id,event,deviceId,bookId,transactionId,details,timestamp'));
      expect(csv, contains('keyGenerated'));
      expect(csv, contains('test_device_id'));
      expect(csv, contains('Ed25519'));
    });

    test('escapes commas and quotes in details', () async {
      await logger.log(
        event: AuditEvent.appLaunched,
        details: 'value,with,"quotes"',
      );

      final csv = await logger.exportToCSV();

      // CSV escaping: wrap in quotes, double-escape inner quotes
      expect(csv, contains('"value,with,""quotes"""'));
    });

    test('filters by bookId', () async {
      await logger.log(event: AuditEvent.chainVerified, bookId: 'book_A');
      await logger.log(event: AuditEvent.chainVerified, bookId: 'book_B');

      final csv = await logger.exportToCSV(bookId: 'book_A');

      expect(csv, contains('book_A'));
      expect(csv, isNot(contains('book_B')));
    });
  });
}
