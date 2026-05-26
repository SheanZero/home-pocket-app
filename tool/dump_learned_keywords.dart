// tool/dump_learned_keywords.dart
//
// Quick task 260526-pg6 (Option F — Task 4): dev/ops CLI tool that dumps the
// top-N learned keyword→category mappings from the encrypted
// category_keyword_preferences table.
//
// Usage:
//   dart run tool/dump_learned_keywords.dart \
//       --db <path-to-home_pocket.db> \
//       --key <64-char-hex-key> \
//       [--limit N]
//
//   dart run tool/dump_learned_keywords.dart --help
//
// Why the explicit --key argv (instead of reading from secure storage):
//   The production app derives the DB key via the in-app KeyManager +
//   flutter_secure_storage path. Both require WidgetsFlutterBinding to be
//   initialized, which standalone Dart scripts cannot do. Rather than pull
//   in the Flutter engine just for an ops tool, this script accepts the
//   raw 32-byte SQLCipher key as a hex string. Operators can grab it from
//   the running device once (e.g. via a debug log line gated behind a
//   developer flag) and pass it here.
//
// Where to find the DB:
//   On macOS dev (host):
//     ~/Library/Containers/<app-bundle-id>/Data/Documents/databases/home_pocket.db
//   On iOS simulator (host filesystem):
//     ~/Library/Developer/CoreSimulator/Devices/<UDID>/data/Containers/Data/Application/<APP-UUID>/Documents/databases/home_pocket.db
//   On Android (rooted): copy the file off-device first; the script does
//     not support direct Android execution (Flutter dependency conflicts).
//   The script reads only — it never writes back, never modifies the schema.
//
// Platform support:
//   macOS / Linux dev box only. Requires libsqlcipher to be resolvable via
//   the system dynamic-library loader (e.g. `brew install sqlcipher` on
//   macOS). Android is rejected at startup — the in-app SQLCipher path
//   uses sqlcipher_flutter_libs which is incompatible with standalone
//   Dart compilation.
//
// Output: an aligned plain-text table to stdout, English only (no ARB).
// Exits 0 on success, 1 on any error (with the error written to stderr).
//
// SECURITY NOTES:
//   - This script is shipped under tool/ only — it MUST NOT be bundled into
//     end-user app builds. tool/ is excluded from the iOS / Android app
//     bundles by default.
//   - The --key argument prints the user's own secrets to ps(1) on the
//     local box. Treat the operator's terminal session as trusted.
//   - The script never logs or re-prints the key.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/category_keyword_preference_dao.dart';

const _usage = '''
dump_learned_keywords — print top-N learned voice keywords from the
encrypted category_keyword_preferences table.

Usage:
  dart run tool/dump_learned_keywords.dart \\
      --db <path-to-home_pocket.db> \\
      --key <64-char-hex-key> \\
      [--limit N]

Options:
  --db <path>      Path to the encrypted SQLCipher database file.
  --key <hex>      64-char hex string — the 32-byte SQLCipher key. Get
                   this from a dev-mode debug log on the device.
  --limit N        Max rows to print. Default: 20.
  --help, -h       Show this message.

Output: hitCount | lastUsed (YYYY-MM-DD) | keyword -> categoryId
''';

void main(List<String> argv) async {
  try {
    final args = _parseArgs(argv);
    if (args == null) {
      // _parseArgs already printed usage on --help.
      exit(0);
    }

    // Platform limitations:
    //   - macOS / Linux dev: SQLCipher loaded via the system dyld lookup
    //     (e.g. Homebrew sqlcipher or libcrypto_sqlcipher). Run from a
    //     shell where `sqlcipher` is on the dynamic-library path.
    //   - Android: NOT supported standalone — the production app uses
    //     sqlcipher_flutter_libs which transitively pulls Flutter, defeating
    //     standalone Dart compilation. Run the script from a macOS/Linux
    //     dev box pointing at a sqlite-encrypted copy of the device DB.
    if (Platform.isAndroid) {
      stderr.writeln(
        'Error: this script is not supported on Android. Copy the DB file '
        'to a macOS/Linux dev box and run there.',
      );
      exit(1);
    }

    final dbFile = File(args.dbPath);
    if (!await dbFile.exists()) {
      stderr.writeln('Error: database file not found at ${args.dbPath}');
      exit(1);
    }

    final db = AppDatabase(
      NativeDatabase(dbFile, setup: (raw) => _applyKey(raw, args.keyHex)),
    );
    try {
      final dao = CategoryKeywordPreferenceDao(db);
      final rows = await dao.findTopLearned(limit: args.limit);

      if (rows.isEmpty) {
        stdout.writeln(
          'No learned keywords found (only seed rows present, or table empty).',
        );
        return;
      }

      // Pre-compute column widths for alignment.
      final hitCountWidth = rows
          .map((r) => r.hitCount.toString().length)
          .fold<int>(8, (acc, w) => w > acc ? w : acc);
      final keywordWidth = rows
          .map((r) => r.keyword.length)
          .fold<int>(7, (acc, w) => w > acc ? w : acc);

      // Header.
      stdout.writeln(
        '${'hitCount'.padRight(hitCountWidth)} | '
        '${'lastUsed'.padRight(10)} | '
        '${'keyword'.padRight(keywordWidth)} -> categoryId',
      );
      stdout.writeln(
        '${'-' * hitCountWidth}-+-${'-' * 10}-+-${'-' * keywordWidth}----------',
      );

      // Rows.
      for (final row in rows) {
        final dateStr = _formatDate(row.lastUsed);
        stdout.writeln(
          '${row.hitCount.toString().padRight(hitCountWidth)} | '
          '$dateStr | '
          '${row.keyword.padRight(keywordWidth)} -> ${row.categoryId}',
        );
      }
    } finally {
      await db.close();
    }
  } on _CliError catch (e) {
    stderr.writeln('Error: ${e.message}');
    stderr.writeln('');
    stderr.writeln(_usage);
    exit(1);
  } catch (e, st) {
    stderr.writeln('Error: $e');
    stderr.writeln(st);
    exit(1);
  }
}

class _CliArgs {
  _CliArgs({required this.dbPath, required this.keyHex, required this.limit});

  final String dbPath;
  final String keyHex;
  final int limit;
}

class _CliError implements Exception {
  _CliError(this.message);

  final String message;

  @override
  String toString() => message;
}

_CliArgs? _parseArgs(List<String> argv) {
  String? dbPath;
  String? keyHex;
  var limit = 20;

  for (var i = 0; i < argv.length; i++) {
    final arg = argv[i];
    switch (arg) {
      case '--help':
      case '-h':
        stdout.writeln(_usage);
        return null;
      case '--db':
        if (i + 1 >= argv.length) {
          throw _CliError('--db requires a path argument');
        }
        dbPath = argv[++i];
      case '--key':
        if (i + 1 >= argv.length) {
          throw _CliError('--key requires a hex-string argument');
        }
        keyHex = argv[++i];
      case '--limit':
        if (i + 1 >= argv.length) {
          throw _CliError('--limit requires an integer argument');
        }
        final parsed = int.tryParse(argv[++i]);
        if (parsed == null || parsed <= 0) {
          throw _CliError('--limit must be a positive integer');
        }
        limit = parsed;
      default:
        throw _CliError('Unknown argument: $arg');
    }
  }

  if (dbPath == null) {
    throw _CliError('--db is required');
  }
  if (keyHex == null) {
    throw _CliError('--key is required');
  }
  if (keyHex.length != 64 ||
      !RegExp(r'^[0-9a-fA-F]+$').hasMatch(keyHex)) {
    throw _CliError(
      '--key must be a 64-character hexadecimal string (32 bytes)',
    );
  }

  return _CliArgs(dbPath: dbPath, keyHex: keyHex, limit: limit);
}

void _applyKey(sqlite3.Database db, String keyHex) {
  // Mirrors lib/infrastructure/crypto/database/encrypted_database.dart so
  // the script opens the DB with byte-identical SQLCipher params.
  db.execute("PRAGMA key = \"x'$keyHex'\";");
  db.execute('PRAGMA cipher = "aes-256-cbc";');
  db.execute('PRAGMA kdf_iter = 256000;');
  final result = db.select('PRAGMA cipher_version;');
  if (result.isEmpty) {
    throw StateError('SQLCipher not loaded — encryption unavailable.');
  }
}

String _formatDate(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
