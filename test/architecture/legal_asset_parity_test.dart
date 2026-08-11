import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture test: trilingual legal-asset parity gate (D-02 / LEGAL-06).
///
/// Asserts all 9 `assets/legal/{doc}_{lang}.html` final documents are present AND
/// structurally consistent so `rootBundle.loadString` resolves at runtime /
/// in widget tests, and so a locale cannot silently ship a stub or a document
/// whose section structure diverges from its siblings.
///
/// Guarantees per file:
///   - non-empty (guards against blank/stub drafts),
///   - it contains one top-level `<h1>` heading (well-formed HTML document),
///   - the count of `<h2>` section headers matches across all three locales of
///     the same doc (cross-locale structural parity),
///   - contains no launch placeholders or draft markers.
///
/// Run: flutter test test/architecture/legal_asset_parity_test.dart

const _docs = ['privacy', 'terms', 'tokusho'];
const _langs = ['ja', 'zh', 'en'];

const _ageContract = <String, List<String>>{
  'ja': ['一律の年齢制限は設けません', '子ども向け専用サービス'],
  'zh': ['不设置统一的年龄限制', '并非专门面向儿童'],
  'en': [
    'no general age restriction',
    'not offered specifically as a service for children',
  ],
};

const _privacyRelayContract = <String, List<String>>{
  'ja': [
    '中継サーバーに一時的に保存・転送',
    '復号鍵を保持しない',
    '7日間',
    '受信確認',
    '1時間ごと',
    '90日間',
    '14日間',
    'PostgreSQL',
    '30日間',
    'Tencent Cloud',
    '日本（東京）',
  ],
  'zh': [
    '由中继服务器临时存储和转发',
    '不持有解密密钥',
    '7天',
    '接收确认',
    '每小时',
    '90天',
    '14天',
    'PostgreSQL',
    '30天',
    'Tencent Cloud',
    '日本（东京）',
  ],
  'en': [
    'temporarily stored and forwarded by the relay server',
    'does not hold decryption keys',
    '7 days',
    'receipt acknowledgement',
    'every hour',
    '90 days',
    '14 days',
    'PostgreSQL',
    '30 days',
    'Tencent Cloud',
    'Japan (Tokyo)',
  ],
};

const _forbiddenReleaseMarkers = [
  'support@example.com',
  '[上线前填真实值]',
  'DRAFT MARKER',
  '草案マーカー',
  '草案标记',
  'IMPORTANT / DRAFT',
  '重要・草案',
  '重要·草案',
  '（草案）',
  '(Draft)',
];

const _obsoletePrivacyClaims = <String, List<String>>{
  'ja': ['端末間で直接行われる', 'サーバーに保存されることはありません'],
  'zh': ['设备之间直接进行', '不会保存至开发者的服务器'],
  'en': [
    'takes place directly between devices',
    'never stored on the developer',
  ],
};

int _countSectionHeaders(String content) =>
    RegExp(r'<h2(?:\s[^>]*)?>').allMatches(content).length;

void main() {
  group('legal asset parity', () {
    test('all doc × locale assets exist', () {
      for (final doc in _docs) {
        for (final lang in _langs) {
          final path = 'assets/legal/${doc}_$lang.html';
          expect(
            File(path).existsSync(),
            isTrue,
            reason: 'missing legal asset $path',
          );
        }
      }
    });

    test('each asset is non-empty HTML with one h1 heading', () {
      for (final doc in _docs) {
        for (final lang in _langs) {
          final path = 'assets/legal/${doc}_$lang.html';
          final content = File(path).readAsStringSync();
          expect(
            content.trim(),
            isNotEmpty,
            reason: 'legal asset $path is empty or blank',
          );
          expect(
            RegExp(r'<h1(?:\s[^>]*)?>').allMatches(content).length,
            1,
            reason: 'legal asset $path must contain exactly one h1 heading',
          );
          expect(
            content,
            isNot(contains(RegExp(r'^#{1,6}\s', multiLine: true))),
          );
          expect(content, isNot(contains('**')));
        }
      }
    });

    test('h2 section-header count matches across locales of the same doc', () {
      for (final doc in _docs) {
        final counts = <String, int>{};
        for (final lang in _langs) {
          final path = 'assets/legal/${doc}_$lang.html';
          final content = File(path).readAsStringSync();
          counts[lang] = _countSectionHeaders(content);
        }
        final reference = counts[_langs.first]!;
        expect(
          reference,
          greaterThan(0),
          reason: '$doc documents have no h2 section headers',
        );
        for (final lang in _langs) {
          expect(
            counts[lang],
            reference,
            reason:
                'section-header count for $doc mismatch: '
                '${counts.toString()}',
          );
        }
      }
    });

    test('privacy policies match the encrypted relay retention contract', () {
      for (final lang in _langs) {
        final path = 'assets/legal/privacy_$lang.html';
        final content = File(path).readAsStringSync();

        for (final requiredText in _privacyRelayContract[lang]!) {
          expect(
            content,
            contains(requiredText),
            reason: '$path must disclose relay behavior: $requiredText',
          );
        }
        for (final obsoleteText in _obsoletePrivacyClaims[lang]!) {
          expect(
            content,
            isNot(contains(obsoleteText)),
            reason:
                '$path still contains obsolete direct-sync claim: '
                '$obsoleteText',
          );
        }
      }
    });

    test('shipping documents contain final operator information', () {
      for (final doc in _docs) {
        for (final lang in _langs) {
          final path = 'assets/legal/${doc}_$lang.html';
          final content = File(path).readAsStringSync();

          expect(content, contains('ナープ株式会社'), reason: path);
          expect(content, contains('support@napu.co.jp'), reason: path);
          for (final marker in _forbiddenReleaseMarkers) {
            expect(
              content,
              isNot(contains(marker)),
              reason: '$path contains release-blocking marker: $marker',
            );
          }
        }
      }

      final tokushoJa = File('assets/legal/tokusho_ja.html').readAsStringSync();
      expect(tokushoJa, contains('代表取締役 張欣'));
      expect(tokushoJa, contains('03-6859-7235'));
      expect(tokushoJa, contains('〒101-0041'));
    });

    test('terms disclose the no-age-restriction product decision', () {
      for (final lang in _langs) {
        final path = 'assets/legal/terms_$lang.html';
        final content = File(path).readAsStringSync();
        for (final requiredText in _ageContract[lang]!) {
          expect(content, contains(requiredText), reason: path);
        }
      }
    });

    test('release snapshots exactly match app legal assets', () {
      for (final doc in _docs) {
        for (final lang in _langs) {
          final name = '${doc}_$lang.html';
          final asset = File('assets/legal/$name').readAsStringSync();
          final snapshot = File(
            'publish/ios/legal/current/$name',
          ).readAsStringSync();
          expect(snapshot, asset, reason: 'release snapshot drift: $name');
        }
      }
    });
  });
}
