# Phase 60: SQLCipher & iOS Native Safety Lane - Pattern Map

> **Scope correction (owner, 2026-08-09):** Historical v23/v35 fixture, provenance, and `onUpgrade` patterns below are superseded and must not be implemented. The active pattern is the current-schema production executor create → write → close → fresh AppDatabase reopen journey; backup work accepts current `.hpb` v2 only.

**Mapped:** 2026-08-09  
**Files analyzed:** 14 anticipated created/modified files  
**Analogs found:** 13 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/ROADMAP.md` | config | transform | `.planning/REQUIREMENTS.md` | role-match |
| `.planning/REQUIREMENTS.md` | config | transform | `docs/testing/DEPENDENCY_COMPATIBILITY.md` | role-match |
| `docs/testing/DEPENDENCY_COMPATIBILITY.md` | config | transform | `docs/testing/STABLE_BASELINE.json` | role-match |
| `docs/testing/STABLE_BASELINE.json` | config | transform | `scripts/dependency_compatibility.dart` | partial |
| `scripts/dependency_compatibility.dart` | utility | batch | existing validator sections | exact |
| `test/architecture/dependency_compatibility_contract_test.dart` | test | transform | existing mutation tests | exact |
| `test/architecture/ios_minimum_version_contract_test.dart` | test | transform | existing iOS floor contract | exact |
| `scripts/verify_ios_native_safety_lane.dart` (new; name discretionary) | utility | batch | `scripts/dependency_compatibility.dart` | role-match |
| `integration_test/fixtures/sqlcipher_4_10_v23_fixture.dart` | test fixture | file-I/O | `integration_test/fixtures/sqlcipher_4_10_v35_fixture.dart` | exact |
| `integration_test/fixtures/README.md` | config | transform | existing v35 provenance record | exact |
| `integration_test/sqlcipher_native_assets_migration_test.dart` | test | file-I/O | existing v35 fixture journey | exact |
| `integration_test/helpers/sqlcipher_backup_sandbox.dart` (new) | utility | file-I/O | `integration_test/helpers/device_test_crypto.dart` | role-match |
| `integration_test/sqlcipher_backup_recovery_test.dart` (new) | test | request-response | `integration_test/device_critical_journey_test.dart` | role-match |
| `lib/core/initialization/app_initializer.dart` (only if evidence seam needs adjustment) | service | request-response | existing staged initialization | exact |

Do not change `lib/data/app_database.dart`, `lib/data/app_database_migrations.dart`, `lib/infrastructure/crypto/database/encrypted_database.dart`, or backup use cases just to create a parallel test path. They are the production behavior to invoke and verify.

## Pattern Assignments

### Native graph contract and mutation tests

**Apply to:** `scripts/dependency_compatibility.dart`, `test/architecture/dependency_compatibility_contract_test.dart`, `docs/testing/STABLE_BASELINE.json`, `docs/testing/DEPENDENCY_COMPATIBILITY.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`  
**Analog:** `scripts/dependency_compatibility.dart`

**Fail-closed source/lock/hook pattern** ([lines 342-369](../../../scripts/dependency_compatibility.dart:342)):

```dart
expectConstraint('drift', '2.34.0');
expectLocked('drift', '2.34.0');
expectConstraint('sqlite3', '^3.3.1');
expectLocked('sqlite3', '3.5.1');
if (dependencies.containsKey('sqlcipher_flutter_libs') ||
    packages.containsKey('sqlcipher_flutter_libs')) {
  issues.add('sqlcipher_flutter_libs is obsolete on the sqlite3 Native Assets path');
}
if (!RegExp(r'^hooks:\s*\n\s+user_defines:\s*\n\s+sqlite3:\s*\n\s+source:\s*sqlcipher\s*$', multiLine: true)
    .hasMatch(pubspecYaml)) {
  issues.add('pubspec must select SQLCipher through hooks.user_defines.sqlite3.source');
}
```

**iOS graph enforcement pattern** ([lines 466-487](../../../scripts/dependency_compatibility.dart:466)):

```dart
if (pubspecYaml.contains('enable-swift-package-manager: false')) {
  issues.add('Swift Package Manager must stay enabled for supported plugins');
}
expectText('Xcode project', xcodeProject, 'FlutterGeneratedPluginSwiftPackage');
if (podfileLock.contains('SQLCipher') || podfileLock.contains('sqlcipher_flutter_libs')) {
  issues.add('ios/Podfile.lock must not retain the legacy SQLCipher CocoaPod path');
}
if (_hasActiveSqlCipherLinkerStrip(podfile)) {
  issues.add('ios/Podfile must not retain the obsolete sqlite3 linker strip');
}
_validateIosDeploymentTargets(issues: issues, podfile: podfile, xcodeProject: xcodeProject);
```

Extend this one validator with a post-generation SwiftPM package-floor input only if it is deliberately passed in for inspection; never edit `ios/Flutter/ephemeral/**`. Synchronize ROADMAP/REQUIREMENTS, the compatibility contract, baseline, validator, and mutation test in one atomic plan. Preserve ADR-002 history and its existing append-only Native Assets update.

**Mutation pattern** ([lines 523-555](../../../test/architecture/dependency_compatibility_contract_test.dart:523)):

```dart
final input = currentInputs();
input['pubspec'] = input['pubspec']!.replaceFirst(
  '  sqlite3: ^3.3.1',
  '  sqlite3: ^3.3.1\n  sqlite3_flutter_libs: ^0.5.0',
);
expect(validate(input), contains('sqlite3_flutter_libs conflicts with SQLCipher and is forbidden'));
```

Add focused positive/negative mutation cases for the legacy packages, wrong resolved graph, missing hook, SQLCipher CocoaPod, active `-lsqlite3` strip, and generated Swift package target below iOS 15.

### iOS minimum floor and clean-build evidence

**Apply to:** `test/architecture/ios_minimum_version_contract_test.dart`, new `scripts/verify_ios_native_safety_lane.dart` (or equivalent narrowly scoped runner), and any evidence workflow.  
**Analog:** `test/architecture/ios_minimum_version_contract_test.dart`

**Static contract** ([lines 27-49](../../../test/architecture/ios_minimum_version_contract_test.dart:27)):

```dart
final project = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
final targets = RegExp(r'IPHONEOS_DEPLOYMENT_TARGET = ([0-9.]+);')
    .allMatches(project).map((match) => match.group(1)).toList();
expect(targets, isNotEmpty);
expect(targets.toSet(), {'15.0'});
```

The runner should use validator-style input/error reporting: clean-resolve in the main tree from committed locks; resolve again from zero in a disposable copy; compare the resolved graph and protect the main tree from tracked drift; regenerate Flutter's Swift package through supported tooling; inspect the generated 15.0 target; then run unsigned generic Simulator/device Debug/Profile/Release builds. Output a redacted structured record that marks every generic destination as **compile-only**, never runtime acceptance.

### Immutable v23 encrypted fixture and provenance

**Apply to:** `integration_test/fixtures/sqlcipher_4_10_v23_fixture.dart`, `integration_test/fixtures/README.md`  
**Analog:** existing v35 Dart embedding and [README provenance](../../../integration_test/fixtures/README.md:3).

Mirror the existing Dart-only Base64 constant; it must be integration-test source, not a Flutter asset. Extend the README in its existing bullet format ([lines 3-23](../../../integration_test/fixtures/README.md:3)) with source revision (`2cb07b08` unless the owner corrects A1), historical resolved SQLCipher lane, cipher settings, source `cipher_version`, `user_version`, journal mode, SHA-256, encrypted-header result, synthetic-only cross-domain sentinels, and reproducible isolated-checkout generation record. Acceptance tests only checksum/decode/copy the immutable witness; they never regenerate it.

### Dual immutable-fixture production migration test

**Apply to:** `integration_test/sqlcipher_native_assets_migration_test.dart`  
**Analog:** existing v35 journey [lines 58-132](../../../integration_test/sqlcipher_native_assets_migration_test.dart:58).

**Imports and integrity** ([lines 1-31](../../../integration_test/sqlcipher_native_assets_migration_test.dart:1)):

```dart
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:integration_test/integration_test.dart';
```

**Production open/migrate/cold-reopen** ([lines 64-128](../../../integration_test/sqlcipher_native_assets_migration_test.dart:64)):

```dart
final root = await Directory.systemTemp.createTemp('sqlcipher-native-assets-');
final fixtureBytes = base64Decode(fixtureBase64.replaceAll(RegExp(r'\s'), ''));
expect(sha256.convert(fixtureBytes).toString(), expectedSha256);
await databaseFile.writeAsBytes(fixtureBytes, flush: true);
database = AppDatabase(
  await createDeviceTestEncryptedExecutor(keys, databaseFile),
);
// assert old sentinels and v36; write one new sentinel; close.
database = AppDatabase(
  await createDeviceTestEncryptedExecutor(keys, databaseFile),
);
```

Reuse `_assertSqlCipher417` ([lines 39-51](../../../integration_test/sqlcipher_native_assets_migration_test.dart:39)) and `_assertEncryptedFileHeader` ([lines 53-56](../../../integration_test/sqlcipher_native_assets_migration_test.dart:53)) before/after cold reopen for both fixtures. The v23 branch must assert user version, expected tables/indices/defaults, cross-domain sentinel rows/hashes, `PRAGMA integrity_check`, then old and new values after a brand-new `AppDatabase` instance. Do not introduce a bespoke migration loop: production `onUpgrade` delegates to the ordered runner ([app_database.dart lines 164-182](../../../lib/data/app_database.dart:164)).

### Isolated master key and encrypted executor

**Apply to:** `integration_test/helpers/sqlcipher_backup_sandbox.dart` plus both integration tests.  
**Analog:** `integration_test/helpers/device_test_crypto.dart`.

**Injection boundary** ([lines 8-61](../../../integration_test/helpers/device_test_crypto.dart:8)):

```dart
class DeviceTestMasterKeyRepository implements MasterKeyRepository {
  @override
  Future<List<int>> getMasterKey() async => List<int>.unmodifiable(_key);
}

Future<QueryExecutor> createDeviceTestEncryptedExecutor(
  MasterKeyRepository masterKeyRepository,
  File databaseFile,
) => createEncryptedExecutor(masterKeyRepository, databaseFile: databaseFile);
```

Use a unique `Directory.systemTemp.createTemp` root, synthetic key/data, injected filesystem/secure-storage/journal/sync boundaries, and tear down only that root. Never resolve the normal app container or real Keychain.

### Real-use-case backup recovery sandbox

**Apply to:** new `integration_test/sqlcipher_backup_recovery_test.dart` and its helper.  
**Primary analogs:** injected wipe construction ([clear-all comprehensive test lines 31-105](../../../test/unit/application/settings/clear_all_data_comprehensive_test.dart:31)), production export/import/restore/clear use cases.

**Clear state machine** ([clear_all_data_use_case.dart lines 24-42](../../../lib/application/settings/clear_all_data_use_case.dart:24)):

```dart
final clear = ClearAllDataUseCase(
  journalStore: sandboxJournal,
  suspendSync: sandboxSync.suspend,
  wipeDatabase: database.wipeLocalUserData,
  wipeAppOwnedFiles: ownedFiles.clear,
  clearSecureUserData: secureStorage.clearUserData,
  resetSettings: sandboxSettings.reset,
  resetInMemoryState: sandboxState.reset,
);
```

**Export injection and atomic publication** ([export_backup_use_case.dart lines 51-57](../../../lib/application/settings/export_backup_use_case.dart:51), [149-215](../../../lib/application/settings/export_backup_use_case.dart:149)):

```dart
final exported = await exportUseCase.execute(
  bookId: bookId,
  password: password,
  outputDirectory: sandbox.backupDirectory,
);
```

Compose actual `ExportBackupUseCase`, `ClearAllDataUseCase`, `ImportBackupUseCase`, and `RestoreBackupUseCase`; direct DAO deletion is prohibited. For v2 and headerless legacy success, snapshot logical records/settings/owned files/secure state, export, clear, restore, compare, cold-reopen a new encrypted `AppDatabase`, then export again. The restore barrier must be real: it suspends sync before import and keeps it closed until cleanup succeeds ([restore_backup_use_case.dart lines 87-135](../../../lib/application/settings/restore_backup_use_case.dart:87)).

For each wrong password, truncation, hostile KDF/resource limit, corrupt payload, and interruption, snapshot database bytes and logical rows, settings, synthetic secure state, owned files, journal, and original backup bytes before the attempt. Assert every item unchanged after the failed result. Model injected settings/transaction failures after [import atomicity test lines 36-165](../../../test/unit/application/settings/import_backup_use_case_atomicity_test.dart:36), and exercise actual staging/compensation behavior ([import_backup_use_case.dart lines 50-115](../../../lib/application/settings/import_backup_use_case.dart:50), [152-275](../../../lib/application/settings/import_backup_use_case.dart:152)).

### Initialization ordering evidence

**Apply to:** `lib/core/initialization/app_initializer.dart` only if a testability seam is genuinely missing; otherwise its existing unit test.  
**Analog:** staged initializer [lines 49-105](../../../lib/core/initialization/app_initializer.dart:49).

```dart
if (!await masterKeyRepo.hasMasterKey()) {
  if (await _databaseExists()) {
    return InitResult.failure(type: InitFailureType.masterKeyMissingWithData, ...);
  }
  await masterKeyRepo.initializeMasterKey();
}
database = await _databaseFactory(masterKeyRepo);
final container = _containerFactory(
  overrides: [appDatabaseProvider.overrideWithValue(database)],
);
await resumePendingPrivacyWipe(container);
```

Maintain key/native readiness before encrypted DB construction. Error branches dispose the container and close the database ([lines 102-149](../../../lib/core/initialization/app_initializer.dart:102)); do not add a second simulator-only initialization route.

## Shared Patterns

### SQLCipher fail-closed runtime identity

**Source:** [encrypted_database.dart](../../../lib/infrastructure/crypto/database/encrypted_database.dart:40)  
**Apply to:** fixture tests and diagnostics.

```dart
db.execute("PRAGMA key = \"x'$dbKey'\";");
db.execute('PRAGMA cipher = "aes-256-cbc";');
db.execute('PRAGMA kdf_iter = 256000;');
if (!_requiredSqlCipherVersion.hasMatch(version)) {
  throw StateError('Required SQLCipher 4.17.x Native Asset is unavailable');
}
if (status?.toString() != '1') {
  throw StateError('SQLCipher database handle is not encrypted');
}
```

Also assert readable `sqlite_master` and reject a plaintext `SQLite format 3\\0` header ([lines 94-114](../../../lib/infrastructure/crypto/database/encrypted_database.dart:94)). A successful open alone is insufficient.

### Production migration and backup atomicity

**Source:** [app_database.dart](../../../lib/data/app_database.dart:164), [app_database_migrations.dart](../../../lib/data/app_database_migrations.dart:56), and [import_backup_use_case.dart](../../../lib/application/settings/import_backup_use_case.dart:152).  
**Apply to:** all migration and recovery tests.

```dart
await _DatabaseMigrationRunner(
  database: this,
  migrator: migrator,
  sourceVersion: from,
).run(from: from, to: to);

await _unitOfWork.run(() async {
  // delete + restore all relational data in one database transaction
});
```

Use production migration and import paths; test their transactional/compensation results instead of duplicating their logic.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `scripts/verify_ios_native_safety_lane.dart` (or selected equivalent) | utility | batch | No current script combines disposable-copy resolution, supported Flutter regeneration, generic unsigned build matrix, generated SwiftPM floor inspection, and redacted compile-only evidence. Reuse validator conventions, but design this orchestration explicitly. |

## Metadata

**Analog search scope:** `lib/`, `integration_test/`, `test/`, `scripts/`, `ios/`, `docs/testing/`, and planning contracts.  
**Files scanned:** 1,551 repository files indexed; 18 primary analog files inspected.  
**Pattern extraction date:** 2026-08-09
