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
  // Quick 260706-kzr — magnitude-word digit-count guard. CJK literals are the
  // NLP lexicon (magnitude tokens, digit char classes, kana numeral keys),
  // not UI text — same rationale as voice_text_parser.dart above.
  'lib/application/voice/amount_magnitude_guard.dart',
  // v16 shopping voice draft parser. Japanese and Chinese literals are the
  // recognition lexicon (counters, ledger keywords, and price markers), not
  // user-visible copy; localized presentation strings remain in ARB files.
  'lib/application/shopping_list/parse_shopping_voice_input_use_case.dart',
  'lib/infrastructure/i18n/formatters/date_formatter.dart',
  'lib/infrastructure/i18n/formatters/number_formatter.dart',
  'lib/infrastructure/category/category_locale_service.dart',
  // Phase 20 NLP lexicons (numeral state machines + JP dictionary). CJK
  // literals are the data itself, not UI text — they cannot be ARB-keyed.
  'lib/infrastructure/voice/chinese_numeral_state_machine.dart',
  'lib/infrastructure/voice/japanese_numeral_state_machine.dart',
  'lib/infrastructure/voice/japanese_numeral_dictionary.dart',
  // Phase 21 voice category resolver seed dictionary. CJK keywords are seed
  // data inserted into category_keyword_preferences, not UI text — they
  // cannot be ARB-keyed (resolver matches against speech tokens).
  'lib/shared/constants/default_synonyms.dart',
  // Phase 21 WR-07 — voice currency suffix tokens. CJK literals are the
  // speech-token data the voice pipeline strips during amount extraction,
  // not UI text. Centralized so VoiceTextParser and ParseVoiceInputUseCase
  // share one source of truth.
  'lib/shared/constants/voice_currency_suffixes.dart',
  // Phase 49 — merchant name normalizer. The sole CJK literal ('・' 中黒) is
  // the character stripped during match-key normalization, i.e. algorithm
  // data, not UI text. (Merchant seed data files themselves are excluded by
  // directory prefix in _shouldScan below.)
  'lib/infrastructure/ml/merchant_name_normalizer.dart',
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

        final source = _stripRegExpLiterals(
          _stripFullLineComments(entity.readAsStringSync()),
        );
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
  // Phase 49 — merchant seed data. Merchant proper-nouns are DATA (multi-locale
  // seed rows), not UI text, per the v1.9 roadmap constraint ("merchant
  // proper-nouns are DATA, category labels are ARB"). The directory grows toward
  // a 600–800 merchant ceiling + regional tail (MERCH-V2), so exclude by prefix.
  if (path.startsWith('lib/shared/constants/merchants/')) return false;
  // Phase 50 D-04 — voice synonym seed data, split from default_synonyms.dart
  // into per-family group files. CJK keywords are seed data inserted into
  // category_keyword_preferences (resolver matches against speech tokens),
  // not UI text — same rationale as the whitelisted default_synonyms.dart.
  // Excluded by prefix because the set grows per-L1-family (full L2 coverage).
  if (path.startsWith('lib/shared/constants/synonyms/')) return false;
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

String _stripRegExpLiterals(String source) {
  return source.replaceAll(
    RegExp(
      r'''RegExp\(\s*r?(?:"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')\s*\)''',
      multiLine: true,
    ),
    'RegExp()',
  );
}

String _normalizePath(String path) => path.replaceAll(r'\', '/');
