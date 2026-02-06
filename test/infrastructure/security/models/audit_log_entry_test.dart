import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/security/models/audit_log_entry.dart';

void main() {
  group('AuditEvent', () {
    test('has all expected values', () {
      expect(AuditEvent.values, contains(AuditEvent.appLaunched));
      expect(AuditEvent.values, contains(AuditEvent.biometricAuthSuccess));
      expect(AuditEvent.values, contains(AuditEvent.biometricAuthFailed));
      expect(AuditEvent.values, contains(AuditEvent.pinAuthSuccess));
      expect(AuditEvent.values, contains(AuditEvent.pinAuthFailed));
      expect(AuditEvent.values, contains(AuditEvent.chainVerified));
      expect(AuditEvent.values, contains(AuditEvent.tamperDetected));
      expect(AuditEvent.values, contains(AuditEvent.keyGenerated));
      expect(AuditEvent.values, contains(AuditEvent.keyRotated));
      expect(AuditEvent.values, contains(AuditEvent.recoveryKitGenerated));
      expect(AuditEvent.values, contains(AuditEvent.keyRecovered));
    });

    test('enum name matches expected string', () {
      expect(AuditEvent.biometricAuthSuccess.name, 'biometricAuthSuccess');
      expect(AuditEvent.tamperDetected.name, 'tamperDetected');
    });
  });

  group('AuditLogEntry', () {
    test('creates instance with required fields', () {
      final now = DateTime(2026, 2, 6, 14, 30);
      final entry = AuditLogEntry(
        id: '01ARYZ6S41000000000000001',
        event: AuditEvent.biometricAuthSuccess,
        deviceId: 'test_device_id',
        timestamp: now,
      );

      expect(entry.id, '01ARYZ6S41000000000000001');
      expect(entry.event, AuditEvent.biometricAuthSuccess);
      expect(entry.deviceId, 'test_device_id');
      expect(entry.bookId, isNull);
      expect(entry.transactionId, isNull);
      expect(entry.details, isNull);
      expect(entry.timestamp, now);
    });

    test('creates instance with optional fields', () {
      final entry = AuditLogEntry(
        id: '01ARYZ6S41000000000000002',
        event: AuditEvent.tamperDetected,
        deviceId: 'test_device',
        bookId: 'book_001',
        transactionId: 'tx_42',
        details: '{"tamperedIds": ["tx_42"]}',
        timestamp: DateTime(2026, 2, 6),
      );

      expect(entry.bookId, 'book_001');
      expect(entry.transactionId, 'tx_42');
      expect(entry.details, '{"tamperedIds": ["tx_42"]}');
    });

    test('supports equality comparison', () {
      final now = DateTime(2026, 2, 6);
      final a = AuditLogEntry(
        id: 'id1',
        event: AuditEvent.appLaunched,
        deviceId: 'dev1',
        timestamp: now,
      );
      final b = AuditLogEntry(
        id: 'id1',
        event: AuditEvent.appLaunched,
        deviceId: 'dev1',
        timestamp: now,
      );

      expect(a, equals(b));
    });

    test('supports copyWith', () {
      final original = AuditLogEntry(
        id: 'id1',
        event: AuditEvent.appLaunched,
        deviceId: 'dev1',
        timestamp: DateTime(2026, 2, 6),
      );
      final copied = original.copyWith(event: AuditEvent.tamperDetected);

      expect(copied.id, 'id1');
      expect(copied.event, AuditEvent.tamperDetected);
    });
  });
}
