import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AND-04 keeps Android API 36 x86_64 and iOS gates executable', () {
    final workflow = File(
      '.github/workflows/device-e2e.yml',
    ).readAsStringSync();

    expect(workflow, contains('android-device-e2e:'));
    expect(workflow, contains('reactivecircus/android-emulator-runner@v2'));
    expect(
      workflow,
      contains('name: Android Emulator full suite (API 36 x86_64)'),
    );
    expect(workflow, contains('api-level: 36'));
    expect(workflow, contains('arch: x86_64'));
    expect(workflow, contains('java-version: "17"'));
    expect(workflow, contains('flutter pub get --enforce-lockfile'));
    expect(workflow, contains('ios-device-e2e:'));
    expect(workflow, contains('xcrun simctl bootstatus'));
    expect(
      RegExp(r'flutter test integration_test/').allMatches(workflow),
      hasLength(2),
    );
    expect(
      workflow,
      contains('bash scripts/release_preflight.sh --platform android'),
    );
  });

  test(
    'HP-05 keeps every device E2E Flutter pin aligned with the selected Stable baseline',
    () {
      final baseline =
          jsonDecode(
                File('docs/testing/STABLE_BASELINE.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final toolchains = baseline['toolchains'] as Map<String, dynamic>;
      final flutter = toolchains['flutter'] as Map<String, dynamic>;
      final selectedStable = flutter['selected_current'] as String;
      final workflow = File(
        '.github/workflows/device-e2e.yml',
      ).readAsStringSync();
      final flutterPins = RegExp(
        r'^\s*flutter-version:\s*([^\s#]+)\s*$',
        multiLine: true,
      ).allMatches(workflow).map((match) => match.group(1)).toList();

      expect(flutterPins, hasLength(2));
      expect(flutterPins, everyElement(selectedStable));
    },
  );

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

  test('AND-04 explicitly inventories every integration test file', () {
    const expected = <String>{
      'device_critical_journey_test.dart',
      'device_sync_delivery_test.dart',
      'merchant_migration_ladder_test.dart',
      'sqlcipher_backup_recovery_test.dart',
      'sqlcipher_native_assets_lifecycle_test.dart',
    };
    final actual = Directory('integration_test')
        .listSync()
        .whereType<File>()
        .map((file) => file.uri.pathSegments.last)
        .where((name) => name.endsWith('_test.dart'))
        .toSet();

    expect(actual, expected);
  });

  test('AND-04 workflow declaration remains NOT_RUN runtime evidence', () {
    final evidence = File(
      '.planning/phases/61-android-toolchain-emulator-lane/'
      '61-ANDROID-SAFETY-EVIDENCE.md',
    ).readAsStringSync();

    expect(evidence, contains('"emulator": "NOT_RUN"'));
    expect(
      evidence,
      contains(
        'Android physical-device validation was not performed or claimed.',
      ),
    );
  });
}
