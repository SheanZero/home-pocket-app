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
            reason: 'legal asset $path must start with a top-level # heading, '
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
            reason: 'section-header count for $doc mismatch: '
                '${counts.toString()}',
          );
        }
      }
    });
  });
}
