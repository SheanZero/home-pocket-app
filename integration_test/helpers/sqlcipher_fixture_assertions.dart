import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

const plaintextSqliteHeader = <int>[
  0x53,
  0x51,
  0x4c,
  0x69,
  0x74,
  0x65,
  0x20,
  0x66,
  0x6f,
  0x72,
  0x6d,
  0x61,
  0x74,
  0x20,
  0x33,
  0x00,
];

/// Immutable metadata for a historical encrypted database witness.
///
/// This helper deliberately contains only metadata and assertion routines. The
/// integration entrypoint owns all production executor/database construction
/// and SQL, so no second migration path can accidentally be introduced here.
class SqlCipherFixtureMetadata {
  const SqlCipherFixtureMetadata({
    required this.label,
    required this.sha256,
    required this.sourceUserVersion,
    required this.sourceTables,
    required this.sourceIndexes,
    required this.sourceDefaults,
    required this.sentinelIds,
    this.historicalSettings = const <String, Object?>{},
  });

  final String label;
  final String sha256;
  final int sourceUserVersion;
  final Set<String> sourceTables;
  final Set<String> sourceIndexes;
  final Map<String, String> sourceDefaults;
  final Map<String, String> sentinelIds;
  final Map<String, Object?> historicalSettings;
}

void assertFixtureBytes(SqlCipherFixtureMetadata fixture, List<int> bytes) {
  expect(sha256.convert(bytes).toString(), fixture.sha256);
  expect(
    bytes.take(plaintextSqliteHeader.length),
    isNot(orderedEquals(plaintextSqliteHeader)),
  );
}

Future<void> assertEncryptedFileHeader(File file) async {
  final bytes = await file.openRead(0, plaintextSqliteHeader.length).first;
  expect(bytes, isNot(equals(plaintextSqliteHeader)));
}

void assertSqlCipherRuntime({
  required String version,
  required String status,
  required int sqliteMasterCount,
  required int userVersion,
  required String integrity,
}) {
  expect(version, matches(RegExp(r'^4\.17\.\d+(?:\s|$)')));
  expect(status, '1');
  expect(sqliteMasterCount, greaterThan(0));
  expect(userVersion, 36);
  expect(integrity, 'ok');
}

void assertSourceMetadata(
  SqlCipherFixtureMetadata fixture, {
  required int userVersion,
  required Set<String> tables,
  required Set<String> indexes,
  required Map<String, String?> defaults,
  required Map<String, bool> sentinelsPresent,
}) {
  expect(userVersion, fixture.sourceUserVersion);
  expect(tables, containsAll(fixture.sourceTables));
  expect(indexes, containsAll(fixture.sourceIndexes));
  for (final entry in fixture.sourceDefaults.entries) {
    expect(defaults[entry.key], entry.value, reason: '${entry.key} default');
  }
  for (final entry in fixture.sentinelIds.entries) {
    expect(sentinelsPresent[entry.key], isTrue, reason: entry.key);
  }
}

void assertPostMigrationSchema(
  SqlCipherFixtureMetadata fixture, {
  required Set<String> tables,
  required Set<String> indexes,
  required Map<String, String?> defaults,
}) {
  expect(tables, containsAll(fixture.sourceTables));
  expect(indexes, containsAll(fixture.sourceIndexes));
  expect(tables, containsAll(const {'family_sync_outbox', 'shopping_items'}));
  expect(defaults['shopping_items.sync_revision'], '0');
  expect(defaults['user_profiles.sync_revision'], '0');
}

void assertHistoricalSettings(
  SqlCipherFixtureMetadata fixture,
  Map<String, Object?> actual,
) {
  expect(actual, fixture.historicalSettings);
}
