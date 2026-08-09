import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

const _ownerApprovedRevision = '2cb07b08e951db2fb142aff63e4465e2fb0d1740';
const _pinnedFixtureSha256 =
    '084b8b14637c1de304d1df55f477067a5403a3e555b74e61ac82e39f8db29588';
const _fixturePath =
    'integration_test/fixtures/sqlcipher_4_10_v23_fixture.dart';
const _manifestPath =
    'integration_test/fixtures/sqlcipher_4_10_v23_manifest.json';
const _verifierPath = 'scripts/verify_sqlcipher_v23_fixture_provenance.dart';

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

const _requiredSettings = <String>{
  'app_lock_enabled',
  'biometric_lock_enabled',
  'biometric_unlock_enabled',
  'language',
  'monthly_joy_target',
  'notifications_enabled',
  'onboarding_complete',
  'theme_mode',
  'voice_language',
  'week_start_day',
};

Map<String, dynamic> _manifest() => Map<String, dynamic>.from(
  jsonDecode(File(_manifestPath).readAsStringSync()) as Map,
);

List<int> _fixtureBytes(String fixtureSource) {
  final match = RegExp(
    r"const sqlCipher410V23FixtureBase64 = '''([\s\S]+?)''';",
  ).firstMatch(fixtureSource);
  expect(
    match,
    isNotNull,
    reason: 'fixture must expose immutable Base64 bytes',
  );
  return base64Decode(match!.group(1)!.replaceAll(RegExp(r'\s'), ''));
}

String _fingerprint(String path) =>
    sha256.convert(File(path).readAsBytesSync()).toString();

void main() {
  test('v23 fixture is an immutable SQLCipher 4.10 historical witness', () {
    final fixtureSource = File(_fixturePath).readAsStringSync();
    final manifest = _manifest();
    final fixture = Map<String, dynamic>.from(manifest['fixture'] as Map);
    final generation = Map<String, dynamic>.from(manifest['generation'] as Map);
    final historicalInputs = Map<String, dynamic>.from(
      manifest['historical_inputs'] as Map,
    );
    final sentinels = Map<String, dynamic>.from(manifest['sentinels'] as Map);
    final settings = Map<String, dynamic>.from(
      manifest['historical_settings'] as Map,
    );
    final bytes = _fixtureBytes(fixtureSource);

    // This is deliberately independent from the manifest and verifier so a
    // coordinated edit cannot silently re-bless a different encrypted file.
    expect(manifest['owner_approved_revision'], _ownerApprovedRevision);
    expect(manifest['owner_decision'], 'confirm-2cb07b08');
    expect(generation['detached_head'], _ownerApprovedRevision);
    expect(fixture['sha256'], _pinnedFixtureSha256);
    expect(fixtureSource, contains(_pinnedFixtureSha256));
    expect(sha256.convert(bytes).toString(), _pinnedFixtureSha256);
    expect(bytes.length, fixture['byte_length']);
    expect(bytes.take(16), isNot(equals(utf8.encode('SQLite format 3\u0000'))));
    expect(fixture['user_version'], 23);
    expect(fixture['cipher_version'], '4.10.0 community');

    expect(
      historicalInputs.keys,
      containsAll(<String>[
        'lib/data/app_database.dart',
        'pubspec.yaml',
        'pubspec.lock',
        'ios/Podfile.lock',
        'lib/infrastructure/crypto/database/encrypted_database.dart',
        'lib/data/repositories/settings_repository_impl.dart',
        'lib/features/settings/domain/models/app_settings.dart',
      ]),
    );
    expect(sentinels.keys.toSet(), _requiredTables);
    expect(settings.keys.toSet(), _requiredSettings);
    expect(generation['sqlcipher_source_sha256'], hasLength(64));
    expect(generation['compiled_library_sha256'], hasLength(64));
  });

  test(
    'acceptance verifier is pure and rejects provenance-contract mutations',
    () {
      final watchedPaths = <String>[
        _fixturePath,
        _manifestPath,
        _verifierPath,
        'integration_test/fixtures/README.md',
      ];
      final before = <String, String>{
        for (final path in watchedPaths) path: _fingerprint(path),
      };
      final result = Process.runSync(
        Platform.resolvedExecutable,
        ['run', _verifierPath, '--mode=acceptance'],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      final after = <String, String>{
        for (final path in watchedPaths) path: _fingerprint(path),
      };

      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
      expect(
        after,
        before,
        reason: 'the acceptance verifier must never rewrite its witness',
      );

      final verifier = File(_verifierPath).readAsStringSync();
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(verifier, contains('revision is not owner-approved'));
      expect(verifier, contains('git-object digest mismatch'));
      expect(verifier, contains('fixture SHA-256 mismatch'));
      expect(verifier, contains('fixture has a plaintext SQLite header'));
      expect(
        verifier,
        contains('sentinel manifest is missing a required v23 table'),
      );
      expect(
        verifier,
        contains('historical fixtures must not be Flutter production assets'),
      );
      expect(pubspec, isNot(contains('integration_test/fixtures/')));
      expect(
        File(
          'integration_test/sqlcipher_native_assets_migration_test.dart',
        ).readAsStringSync(),
        isNot(contains('generate_v23_fixture')),
        reason:
            'migration tests must consume the committed witness, never generate it',
      );
    },
  );
}
