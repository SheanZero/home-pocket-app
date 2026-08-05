import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('P2-03 keeps Android and iOS device gates executable', () {
    final workflow = File(
      '.github/workflows/device-e2e.yml',
    ).readAsStringSync();

    expect(workflow, contains('android-device-e2e:'));
    expect(workflow, contains('reactivecircus/android-emulator-runner@v2'));
    expect(workflow, contains('api-level: 35'));
    expect(workflow, contains('ios-device-e2e:'));
    expect(workflow, contains('xcrun simctl bootstatus'));
    expect(
      RegExp(r'flutter test integration_test/').allMatches(workflow),
      hasLength(2),
    );
  });

  test(
    'P2-03 critical device matrix cannot collapse back to one migration',
    () {
      final criticalJourney = File(
        'integration_test/device_critical_journey_test.dart',
      ).readAsStringSync();
      final syncDelivery = File(
        'integration_test/device_sync_delivery_test.dart',
      ).readAsStringSync();
      final migration = File(
        'integration_test/merchant_migration_ladder_test.dart',
      );

      expect(migration.existsSync(), isTrue);
      for (final marker in const [
        'E2E-ONBOARDING',
        'E2E-LEDGER',
        'E2E-BACKUP',
        'E2E-APP-LOCK',
        'E2E-SQLCIPHER',
      ]) {
        expect(criticalJourney, contains(marker), reason: 'missing $marker');
      }
      for (final marker in const [
        'E2E-SYNC-PUSH',
        'E2E-SYNC-PULL',
        'E2E-SYNC-ACK',
        'E2E-OFFLINE-QUEUE',
      ]) {
        expect(syncDelivery, contains(marker), reason: 'missing $marker');
      }
    },
  );
}
