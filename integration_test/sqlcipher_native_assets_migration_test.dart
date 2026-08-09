import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:integration_test/integration_test.dart';

import 'fixtures/sqlcipher_4_10_v23_fixture.dart';
import 'fixtures/sqlcipher_4_10_v35_fixture.dart';
import 'helpers/device_test_crypto.dart';
import 'helpers/sqlcipher_fixture_assertions.dart';

const _v35 = SqlCipherFixtureMetadata(
  label: 'v35',
  sha256: '58d6f6f1f40e636323e13d40cf013cd9e541a8eb892f60b507cd898e2328c004',
  sourceUserVersion: 35,
  sourceTables: {'shopping_items'},
  sourceIndexes: {},
  sourceDefaults: {'shopping_items.list_type': "'private'"},
  sentinelIds: {'shopping_items': 'fixture-item'},
);

const _v23 = SqlCipherFixtureMetadata(
  label: 'v23',
  sha256: '084b8b14637c1de304d1df55f477067a5403a3e555b74e61ac82e39f8db29588',
  sourceUserVersion: 23,
  sourceTables: {
    'audit_logs',
    'books',
    'categories',
    'category_keyword_preferences',
    'category_ledger_configs',
    'exchange_rates',
    'group_members',
    'groups',
    'merchant_category_preferences',
    'merchant_match_keys',
    'merchants',
    'shopping_items',
    'sync_queue',
    'transactions',
    'user_profiles',
  },
  sourceIndexes: {
    'idx_tx_book_id',
    'idx_shopping_list_type',
    'idx_exchange_rates_currency_date',
    'idx_group_members_group_id',
  },
  sourceDefaults: {
    'categories.is_archived': '0',
    'shopping_items.list_type': "'private'",
    'sync_queue.retry_count': '0',
  },
  sentinelIds: {
    'audit_logs': 'fixture-audit',
    'books': 'fixture-book',
    'categories': 'fixture-cat-l2',
    'category_keyword_preferences': 'fixture-keyword',
    'category_ledger_configs': 'fixture-cat-l2',
    'exchange_rates': 'XTS',
    'group_members': 'fixture-group',
    'groups': 'fixture-group',
    'merchant_category_preferences': 'fixture-merchant-preference',
    'merchant_match_keys': 'fixture-match-key',
    'merchants': 'fixture-merchant',
    'shopping_items': 'fixture-shopping',
    'sync_queue': 'fixture-sync',
    'transactions': 'fixture-transaction',
    'user_profiles': 'fixture-user',
  },
  historicalSettings: {
    'theme_mode': 'dark',
    'language': 'ja',
    'notifications_enabled': false,
    'biometric_lock_enabled': false,
    'app_lock_enabled': true,
    'biometric_unlock_enabled': true,
    'onboarding_complete': true,
    'voice_language': 'en',
    'monthly_joy_target': 7777,
    'week_start_day': 'sunday',
  },
);

/// Opens the production executor solely to record the immutable source shape.
///
/// It deliberately supplies no migration callback. The executor is then closed
/// and a fresh production executor is handed to [AppDatabase], which remains
/// the only code that executes the migration ladder.
class _SourceSchemaUser implements QueryExecutorUser {
  const _SourceSchemaUser(this.schemaVersion);

  @override
  final int schemaVersion;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}

Future<String> _scalar(QueryExecutor executor, String statement) async {
  final rows = await executor.runSelect(statement, const []);
  expect(rows, hasLength(1), reason: '$statement returned no scalar value');
  return rows.single.values.single.toString().toLowerCase();
}

Future<String> _databaseScalar(AppDatabase database, String statement) async {
  final rows = await database.customSelect(statement).get();
  expect(rows, hasLength(1), reason: '$statement returned no scalar value');
  return rows.single.data.values.single.toString().toLowerCase();
}

Future<Set<String>> _schemaNames(
  QueryExecutor executor, {
  required String type,
}) async {
  final rows = await executor.runSelect(
    "SELECT name FROM sqlite_master WHERE type = ? AND name NOT LIKE 'sqlite_%'",
    [type],
  );
  return rows.map((row) => row['name']! as String).toSet();
}

Future<Map<String, String?>> _defaults(
  QueryExecutor executor,
  Iterable<String> tableNames,
) async {
  final defaults = <String, String?>{};
  for (final table in tableNames) {
    final columns = await executor.runSelect(
      'PRAGMA table_info("$table")',
      const [],
    );
    for (final column in columns) {
      defaults['$table.${column['name']}'] = column['dflt_value']?.toString();
    }
  }
  return defaults;
}

Future<bool> _hasSentinel(
  QueryExecutor executor,
  String table,
  String id,
) async {
  final where = switch (table) {
    'exchange_rates' => 'currency = ?',
    'group_members' => 'group_id = ? AND device_id = ?',
    'category_keyword_preferences' => 'keyword = ?',
    'category_ledger_configs' => 'category_id = ?',
    'merchant_category_preferences' => 'merchant_key = ?',
    _ => 'id = ?',
  };
  final variables = table == 'group_members'
      ? <Object?>[id, 'fixture-device']
      : <Object?>[id];
  final rows = await executor.runSelect(
    'SELECT 1 FROM "$table" WHERE $where LIMIT 1',
    variables,
  );
  return rows.isNotEmpty;
}

Future<void> _assertSourceWitness(
  QueryExecutor executor,
  SqlCipherFixtureMetadata fixture,
) async {
  final tables = await _schemaNames(executor, type: 'table');
  final indexes = await _schemaNames(executor, type: 'index');
  final sentinels = <String, bool>{
    for (final entry in fixture.sentinelIds.entries)
      entry.key: await _hasSentinel(executor, entry.key, entry.value),
  };
  assertSourceMetadata(
    fixture,
    userVersion: int.parse(await _scalar(executor, 'PRAGMA user_version')),
    tables: tables,
    indexes: indexes,
    defaults: await _defaults(executor, fixture.sourceTables),
    sentinelsPresent: sentinels,
  );
}

Future<void> _assertMigratedWitness(
  AppDatabase database,
  SqlCipherFixtureMetadata fixture,
) async {
  final executor = database.executor;
  final tables = await _schemaNames(executor, type: 'table');
  final indexes = await _schemaNames(executor, type: 'index');
  final sentinels = <String, bool>{
    for (final entry in fixture.sentinelIds.entries)
      entry.key: await _hasSentinel(executor, entry.key, entry.value),
  };
  expect(sentinels.values, everyElement(isTrue));
  assertPostMigrationSchema(
    fixture,
    tables: tables,
    indexes: indexes,
    defaults: await _defaults(executor, {'shopping_items', 'user_profiles'}),
  );
  final masterRows = await database
      .customSelect('SELECT count(*) AS count FROM sqlite_master')
      .get();
  assertSqlCipherRuntime(
    version: await _databaseScalar(database, 'PRAGMA cipher_version'),
    status: await _databaseScalar(database, 'PRAGMA cipher_status'),
    sqliteMasterCount: masterRows.single.read<int>('count'),
    userVersion: int.parse(
      await _databaseScalar(database, 'PRAGMA user_version'),
    ),
    integrity: await _databaseScalar(database, 'PRAGMA integrity_check'),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final fixtures = <(SqlCipherFixtureMetadata, String)>[
    (_v35, sqlCipher410V35FixtureBase64),
    (_v23, sqlCipher410V23FixtureBase64),
  ];

  for (final (fixture, base64) in fixtures) {
    testWidgets(
      'SQLCipher 4.17 migrates immutable ${fixture.label} witness through AppDatabase',
      (tester) async {
        if (fixture == _v23) {
          final settings = jsonDecode(sqlCipher410V23HistoricalSettingsJson);
          assertHistoricalSettings(fixture, settings as Map<String, Object?>);
        }
        final root = await Directory.systemTemp.createTemp(
          'sqlcipher-native-assets-',
        );
        final databaseFile = File(
          '${root.path}/sqlcipher-4.10-${fixture.label}.db',
        );
        final fixtureBytes = base64Decode(base64.replaceAll(RegExp(r'\s'), ''));
        assertFixtureBytes(fixture, fixtureBytes);
        await databaseFile.writeAsBytes(fixtureBytes, flush: true);
        await assertEncryptedFileHeader(databaseFile);

        AppDatabase? database;
        try {
          final keys = DeviceTestMasterKeyRepository();
          final sourceExecutor = await createDeviceTestEncryptedExecutor(
            keys,
            databaseFile,
          );
          try {
            await sourceExecutor.ensureOpen(
              _SourceSchemaUser(fixture.sourceUserVersion),
            );
            await _assertSourceWitness(sourceExecutor, fixture);
          } finally {
            await sourceExecutor.close();
          }
          database = AppDatabase(
            await createDeviceTestEncryptedExecutor(keys, databaseFile),
          );
          await _assertMigratedWitness(database, fixture);
          await assertEncryptedFileHeader(databaseFile);
        } finally {
          await database?.close();
          if (await root.exists()) await root.delete(recursive: true);
        }
      },
      timeout: const Timeout(Duration(minutes: 4)),
    );
  }
}
