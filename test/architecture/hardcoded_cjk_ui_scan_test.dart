import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture test: user-visible hardcoded CJK strings must stay out of UI.
///
/// Intentional language data, NLP dictionaries, merchant seed data, and
/// formatter locale outputs are approved by Phase 5 D-06 and whitelisted below.
///
/// Run: flutter test test/architecture/hardcoded_cjk_ui_scan_test.dart

const approvedWhitelist = {
  'lib/application/voice/voice_text_parser.dart',
  'lib/application/voice/voice_satisfaction_estimator.dart',
  'lib/application/voice/fuzzy_category_matcher.dart',
  'lib/infrastructure/ml/merchant_database.dart',
  'lib/infrastructure/i18n/formatters/date_formatter.dart',
  'lib/infrastructure/i18n/formatters/number_formatter.dart',
  'lib/infrastructure/category/category_locale_service.dart',
};

void main() {
  group('Hardcoded CJK UI scanner', () {
    test('production UI files do not contain hardcoded CJK string literals', () {
      final hits = <String>[];
      final stringLiteralPattern = RegExp(
        r'''(?:"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')''',
        multiLine: true,
      );
      final cjkPattern = RegExp(r'[\u3040-\u30ff\u3400-\u9fff]');

      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !_shouldScan(entity)) continue;

        final source = _stripFullLineComments(entity.readAsStringSync());
        final offendingStrings = stringLiteralPattern
            .allMatches(source)
            .map((match) => match.group(0)!)
            .where(cjkPattern.hasMatch)
            .toList();

        if (offendingStrings.isNotEmpty) {
          hits.add('${_normalizePath(entity.path)}: $offendingStrings');
        }
      }

      expect(
        hits,
        isEmpty,
        reason:
            'User-visible hardcoded CJK string literals found outside approvedWhitelist:\n'
            '${hits.join("\n")}',
      );
    });
  });
}

bool _shouldScan(File file) {
  final path = _normalizePath(file.path);
  if (!path.endsWith('.dart')) return false;
  if (path.startsWith('lib/generated/')) return false;
  if (path.startsWith('lib/l10n/')) return false;
  if (path.endsWith('.g.dart')) return false;
  if (path.endsWith('.freezed.dart')) return false;
  if (approvedWhitelist.contains(path)) return false;
  return true;
}

String _stripFullLineComments(String source) {
  return source
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');
}

String _normalizePath(String path) => path.replaceAll(r'\', '/');
