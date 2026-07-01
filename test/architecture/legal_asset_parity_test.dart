import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture test: trilingual legal-asset existence gate (D-02 / LEGAL-06).
///
/// Asserts all 9 `assets/legal/{doc}_{lang}.md` drafts are present so
/// `rootBundle.loadString` resolves at runtime and in widget tests.
///
/// Run: flutter test test/architecture/legal_asset_parity_test.dart

const _docs = ['privacy', 'terms', 'tokusho'];
const _langs = ['ja', 'zh', 'en'];

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
  });
}
