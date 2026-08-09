import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

const _approvedRevision = '2cb07b08e951db2fb142aff63e4465e2fb0d1740';
const _manifestPath =
    'integration_test/fixtures/sqlcipher_4_10_v23_manifest.json';
const _fixturePath =
    'integration_test/fixtures/sqlcipher_4_10_v23_fixture.dart';
const _readmePath = 'integration_test/fixtures/README.md';
const _plaintextSqliteHeader = 'SQLite format 3\u0000';

const _requiredTables = <String>{
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
};

Never _fail(String message) =>
    throw StateError('v23 provenance rejected: $message');

Map<String, String> _arguments(List<String> arguments) {
  final parsed = <String, String>{};
  for (final argument in arguments) {
    final separator = argument.indexOf('=');
    if (!argument.startsWith('--') || separator < 3) {
      _fail('invalid argument `$argument`');
    }
    parsed[argument.substring(2, separator)] = argument.substring(
      separator + 1,
    );
  }
  return parsed;
}

String _git(List<String> arguments, {String? workingDirectory}) {
  final result = Process.runSync(
    'git',
    arguments,
    workingDirectory: workingDirectory,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  if (result.exitCode != 0) {
    _fail('git ${arguments.join(' ')} failed: ${result.stderr}'.trim());
  }
  return (result.stdout as String).trim();
}

Uint8List _gitBytes(List<String> arguments, {String? workingDirectory}) {
  final result = Process.runSync(
    'git',
    arguments,
    workingDirectory: workingDirectory,
    stdoutEncoding: null,
    stderrEncoding: utf8,
  );
  if (result.exitCode != 0) {
    _fail('git ${arguments.join(' ')} failed: ${result.stderr}'.trim());
  }
  return Uint8List.fromList(result.stdout as List<int>);
}

Map<String, dynamic> _manifest() {
  final file = File(_manifestPath);
  if (!file.existsSync()) _fail('missing manifest');
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, dynamic>) _fail('manifest is not a JSON object');
  return decoded;
}

Map<String, dynamic> _object(Map<String, dynamic> parent, String key) {
  final value = parent[key];
  if (value is! Map<String, dynamic>) _fail('manifest `$key` is missing');
  return value;
}

String _string(Map<String, dynamic> parent, String key) {
  final value = parent[key];
  if (value is! String || value.isEmpty) _fail('manifest `$key` is missing');
  return value;
}

void _expect(bool condition, String message) {
  if (!condition) _fail(message);
}

void _verifySource(
  Map<String, dynamic> manifest, {
  required String revision,
  String? worktree,
}) {
  _expect(revision == _approvedRevision, 'revision is not owner-approved');
  _expect(
    _string(manifest, 'owner_approved_revision') == _approvedRevision,
    'manifest owner revision differs from approval',
  );
  _expect(
    _string(manifest, 'owner_decision') == 'confirm-2cb07b08',
    'manifest lacks the exact owner decision',
  );
  _git(['cat-file', '-e', '$revision^{commit}']);
  if (worktree != null) {
    _expect(
      _git(['rev-parse', 'HEAD'], workingDirectory: worktree) == revision,
      'detached worktree HEAD differs from approved revision',
    );
    _expect(
      _git([
        'status',
        '--porcelain',
        '--untracked-files=no',
      ], workingDirectory: worktree).isEmpty,
      'detached worktree has tracked changes',
    );
  }

  final inputs = _object(manifest, 'historical_inputs');
  for (final entry in inputs.entries) {
    final path = entry.key;
    final expectedDigest = entry.value;
    _expect(
      expectedDigest is String && expectedDigest.length == 64,
      'invalid digest for $path',
    );
    final source = _gitBytes(['show', '$revision:$path']);
    _expect(
      sha256.convert(source).toString() == expectedDigest,
      'git-object digest mismatch for $path',
    );
    if (worktree != null) {
      final checkout = File('$worktree/$path');
      _expect(checkout.existsSync(), 'historical checkout lacks $path');
      _expect(
        sha256.convert(checkout.readAsBytesSync()).toString() == expectedDigest,
        'detached-checkout digest mismatch for $path',
      );
    }
  }

  final appDatabase = utf8.decode(
    _gitBytes(['show', '$revision:lib/data/app_database.dart']),
  );
  final lock = utf8.decode(_gitBytes(['show', '$revision:pubspec.lock']));
  final podLock = utf8.decode(
    _gitBytes(['show', '$revision:ios/Podfile.lock']),
  );
  final encryption = utf8.decode(
    _gitBytes([
      'show',
      '$revision:lib/infrastructure/crypto/database/encrypted_database.dart',
    ]),
  );

  _expect(
    RegExp(r'int get schemaVersion => 23;').hasMatch(appDatabase),
    'historical AppDatabase is not schemaVersion 23',
  );
  _expect(
    lock.contains('sqlcipher_flutter_libs:') &&
        lock.contains('version: "0.6.8"'),
    'historical lock does not resolve sqlcipher_flutter_libs 0.6.8',
  );
  _expect(
    lock.contains('sqlite3:') && lock.contains('version: "2.9.4"'),
    'historical lock does not resolve sqlite3 2.9.4',
  );
  _expect(
    podLock.contains('SQLCipher (4.10.0)'),
    'historical Podfile.lock does not pin SQLCipher 4.10.0',
  );
  for (final marker in <String>[
    'PRAGMA cipher = "aes-256-cbc"',
    'PRAGMA kdf_iter = 256000',
    'PRAGMA cipher_version',
  ]) {
    _expect(
      encryption.contains(marker),
      'historical cipher config lacks `$marker`',
    );
  }
}

String _fixtureBase64() {
  final source = File(_fixturePath).readAsStringSync();
  final match = RegExp(
    r"const sqlCipher410V23FixtureBase64 = '''([\s\S]+?)''';",
  ).firstMatch(source);
  if (match == null) {
    _fail('fixture does not expose the immutable Base64 constant');
  }
  return match.group(1)!.replaceAll(RegExp(r'\s'), '');
}

void _verifyAcceptance(Map<String, dynamic> manifest) {
  _verifySource(
    manifest,
    revision: _string(manifest, 'owner_approved_revision'),
  );

  final generation = _object(manifest, 'generation');
  for (final key in <String>[
    'detached_head',
    'command',
    'environment',
    'sqlcipher_source_sha256',
    'compiled_library_sha256',
  ]) {
    _string(generation, key);
  }
  _expect(
    generation['detached_head'] == _approvedRevision,
    'generation record detached HEAD differs from approval',
  );

  final fixture = _object(manifest, 'fixture');
  final bytes = base64Decode(_fixtureBase64());
  _expect(
    sha256.convert(bytes).toString() == _string(fixture, 'sha256'),
    'fixture SHA-256 mismatch',
  );
  _expect(
    bytes.length == fixture['byte_length'],
    'fixture byte length mismatch',
  );
  _expect(
    !utf8
        .decode(bytes.take(16).toList(), allowMalformed: true)
        .startsWith(_plaintextSqliteHeader),
    'fixture has a plaintext SQLite header',
  );
  _expect(fixture['user_version'] == 23, 'fixture is not user_version 23');
  _expect(
    fixture['cipher_version'] == '4.10.0 community',
    'fixture cipher identity is not SQLCipher 4.10.0 community',
  );

  final sentinels = _object(manifest, 'sentinels');
  _expect(
    sentinels.keys.toSet().containsAll(_requiredTables),
    'sentinel manifest is missing a required v23 table',
  );
  final settings = _object(manifest, 'historical_settings');
  _expect(
    settings.keys.length == 10,
    'historical settings companion is incomplete',
  );
  final fixtureSource = File(_fixturePath).readAsStringSync();
  for (final setting in settings.keys) {
    _expect(
      fixtureSource.contains(setting),
      'fixture settings companion lacks `$setting`',
    );
  }

  final readme = File(_readmePath).readAsStringSync();
  for (final marker in <String>[
    _approvedRevision,
    _string(fixture, 'sha256'),
    'SQLCipher 4.10.0',
    'user_version = 23',
    'confirm-2cb07b08',
  ]) {
    _expect(readme.contains(marker), 'README lacks `$marker`');
  }

  final pubspec = File('pubspec.yaml').readAsStringSync();
  _expect(
    !pubspec.contains('integration_test/fixtures/'),
    'historical fixtures must not be Flutter production assets',
  );
}

void main(List<String> arguments) {
  try {
    final options = _arguments(arguments);
    final mode = options['mode'];
    final manifest = _manifest();
    switch (mode) {
      case 'source':
        final revision = options['revision'];
        final worktree = options['worktree'];
        if (revision == null || worktree == null) {
          _fail('source mode requires --revision and --worktree');
        }
        _verifySource(manifest, revision: revision, worktree: worktree);
        break;
      case 'acceptance':
        if (options.length != 1) {
          _fail('acceptance mode takes no other arguments');
        }
        _verifyAcceptance(manifest);
        break;
      default:
        _fail('use --mode=source or --mode=acceptance');
    }
    stdout.writeln('v23 provenance verification passed ($mode)');
  } on Object catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  }
}
