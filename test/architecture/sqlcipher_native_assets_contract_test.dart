import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _runtimeTest =
    'integration_test/sqlcipher_native_assets_lifecycle_test.dart';

void main() {
  test(
    'native safety lane owns current-schema SQLCipher lifecycle evidence',
    () {
      final runtime = File(_runtimeTest).readAsStringSync();
      final runner = File(
        'scripts/verify_ios_native_safety_lane.dart',
      ).readAsStringSync();
      final pubspec = File('pubspec.yaml').readAsStringSync();

      expect(runtime, contains('createDeviceTestEncryptedExecutor'));
      expect(runtime, contains('AppDatabase'));
      expect(runtime, contains('PRAGMA cipher_version'));
      expect(runtime, contains('PRAGMA cipher_status'));
      expect(runtime, contains('PRAGMA integrity_check'));
      expect(runtime, contains('await database.close()'));
      expect(runtime, isNot(contains('onUpgrade')));
      expect(runtime, isNot(contains('sqlcipher_4_10')));
      expect(runtime, isNot(contains('v23')));
      expect(runtime, isNot(contains('v35')));

      expect(runner, contains(_runtimeTest));
      expect(runner, isNot(contains('sqlcipher_native_assets_migration_test')));
      expect(pubspec, contains('source: sqlcipher'));
      expect(pubspec, isNot(contains('sqlcipher_flutter_libs')));
      expect(pubspec, isNot(contains('sqlite3_flutter_libs')));
    },
  );
}
