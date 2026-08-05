import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture test: trilingual legal-asset parity gate (D-02 / LEGAL-06).
///
/// Asserts all 9 `assets/legal/{doc}_{lang}.md` drafts are present AND
/// structurally consistent so `rootBundle.loadString` resolves at runtime /
/// in widget tests, and so a locale cannot silently ship a stub or a draft
/// whose section structure diverges from its siblings.
///
/// Guarantees per file:
///   - non-empty (guards against blank/stub drafts),
///   - its first non-blank line is a top-level `#` heading (well-formed doc),
///   - the count of `##` section headers matches across all three locales of
///     the same doc (cross-locale structural parity).
///
/// Run: flutter test test/architecture/legal_asset_parity_test.dart

const _docs = ['privacy', 'terms', 'tokusho'];
const _langs = ['ja', 'zh', 'en'];

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
    '固定のログ保存期間を設定していません',
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
    '未设定固定的日志保留期限',
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
    'does not set a fixed log-retention period',
  ],
};

const _obsoletePrivacyClaims = <String, List<String>>{
  'ja': ['端末間で直接行われる', 'サーバーに保存されることはありません'],
  'zh': ['设备之间直接进行', '不会保存至开发者的服务器'],
  'en': [
    'takes place directly between devices',
    'never stored on the developer',
  ],
};

int _countSectionHeaders(List<String> lines) =>
    lines.where((l) => l.startsWith('## ')).length;

String? _firstNonBlankLine(List<String> lines) {
  for (final line in lines) {
    if (line.trim().isNotEmpty) return line;
  }
  return null;
}

void main() {
  group('legal asset parity', () {
    test('all doc × locale assets exist', () {
      for (final doc in _docs) {
        for (final lang in _langs) {
          final path = 'assets/legal/${doc}_$lang.md';
          expect(
            File(path).existsSync(),
            isTrue,
            reason: 'missing legal asset $path',
          );
        }
      }
    });

    test('each asset is non-empty and starts with a # heading', () {
      for (final doc in _docs) {
        for (final lang in _langs) {
          final path = 'assets/legal/${doc}_$lang.md';
          final content = File(path).readAsStringSync();
          expect(
            content.trim(),
            isNotEmpty,
            reason: 'legal asset $path is empty or blank',
          );
          final firstLine = _firstNonBlankLine(content.split('\n'));
          expect(
            firstLine != null && firstLine.startsWith('# '),
            isTrue,
            reason:
                'legal asset $path must start with a top-level # heading, '
                'got: ${firstLine ?? '<none>'}',
          );
        }
      }
    });

    test('## section-header count matches across locales of the same doc', () {
      for (final doc in _docs) {
        final counts = <String, int>{};
        for (final lang in _langs) {
          final path = 'assets/legal/${doc}_$lang.md';
          final lines = File(path).readAsLinesSync();
          counts[lang] = _countSectionHeaders(lines);
        }
        final reference = counts[_langs.first]!;
        expect(
          reference,
          greaterThan(0),
          reason: '$doc drafts have no ## section headers',
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
        final path = 'assets/legal/privacy_$lang.md';
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
  });
}
