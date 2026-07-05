import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';

/// Migration tests for schema v22 → v23 (index backfill).
///
/// The `customIndices` getter on table classes is decorative — Drift's
/// migrator never consumes it (CR-01, Phase 36). The fix pattern (explicit
/// CREATE INDEX from BOTH onCreate and an onUpgrade step) was only applied to
/// tables added after Phase 36; every older table's declared indices were
/// physically missing on some or all devices. v23 backfills them all.
///
/// Two concerns:
///   (1) Fresh install — every index declared via `TableIndex(name: ...)` in
///       lib/data/tables/*.dart physically exists after onCreate. The
///       declaration list is PARSED FROM SOURCE so a future table whose
///       declared indices are never created fails this test instead of
///       silently repeating CR-01.
///   (2) v22→v23 onUpgrade — the REAL `from < 23` block is driven via the
///       file-backed rewind pattern (mirrors merchant_v22_migration_test):
///       stamp the file at v22 with all declared indices dropped, reopen as
///       AppDatabase, and assert the production migrator recreated them.

/// Parses every declared TableIndex name from the table definition sources.
Set<String> _declaredIndexNames() {
  final dir = Directory('lib/data/tables');
  final pattern = RegExp(r"TableIndex\(\s*name:\s*'([^']+)'");
  final names = <String>{};
  for (final file in dir.listSync().whereType<File>()) {
    if (!file.path.endsWith('.dart')) continue;
    for (final match in pattern.allMatches(file.readAsStringSync())) {
      names.add(match.group(1)!);
    }
  }
  return names;
}

Future<Set<String>> _physicalIndexNames(AppDatabase db) async {
  final rows = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'index' "
        "AND name NOT LIKE 'sqlite_autoindex%'",
      )
      .get();
  return rows.map((r) => r.read<String>('name')).toSet();
}

void main() {
  test('table sources declare the expected number of indices', () {
    // Sanity floor so a parser regression cannot make the suite pass vacuously.
    expect(_declaredIndexNames().length, greaterThanOrEqualTo(35));
  });

  group('v23 — fresh install (onCreate)', () {
    test('AppDatabase schemaVersion is 23', () {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      expect(db.schemaVersion, equals(23));
    });

    test('every declared TableIndex physically exists', () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      final physical = await _physicalIndexNames(db);
      final missing = _declaredIndexNames().difference(physical);
      expect(
        missing,
        isEmpty,
        reason:
            'customIndices is decorative — every declared index must be '
            'emitted explicitly from onCreate (CR-01). Missing: $missing',
      );
    });
  });

  group('v23 — onUpgrade (v22→v23) drives the REAL migrator', () {
    late Directory tempDir;
    late File dbFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('index_v23_migration');
      dbFile = File('${tempDir.path}/app.sqlite');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('real from<23 block backfills every declared index', () async {
      final declared = _declaredIndexNames();

      // STAGE A — stamp the file at v22: open at current version (onCreate
      // builds everything), drop every declared index so the file looks like
      // a worst-case pre-v23 DB (v15-era fresh installs missed audit/profile
      // indices too), and rewind user_version to 22.
      final staged = AppDatabase(NativeDatabase(dbFile));
      for (final name in declared) {
        await staged.customStatement('DROP INDEX IF EXISTS $name');
      }
      await staged.customStatement('PRAGMA user_version = 22');
      expect(await _physicalIndexNames(staged), isEmpty);
      await staged.close();

      // STAGE B — reopen the SAME file. Drift sees 22 < 23 and runs the
      // production `from < 23` backfill.
      final upgraded = AppDatabase(NativeDatabase(dbFile));
      addTearDown(upgraded.close);

      final physical = await _physicalIndexNames(upgraded);
      final missing = declared.difference(physical);
      expect(
        missing,
        isEmpty,
        reason: 'from<23 must backfill every declared index. Missing: $missing',
      );
    });
  });
}
