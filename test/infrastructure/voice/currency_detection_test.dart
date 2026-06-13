// WAVE 0 RED SCAFFOLD — Phase 42, producing plan 42-04 (voice currency detection).
//
// This file references VoiceParseResult.detectedCurrency — a getter that DOES
// NOT EXIST yet. It is therefore EXPECTED to fail to compile (RED) until plan
// 42-04 adds currency detection to the voice pipeline.
//
// Locked behavior under test (VOICE-CUR-01/02/03, CONTEXT D-08):
//   - zh corpus: 美元/欧元/英镑/港币/澳元/加元 → USD/EUR/GBP/HKD/AUD/CAD (≥5 cases).
//   - ja corpus: ドル/ユーロ/ポンド/香港ドル/豪ドル → USD/EUR/GBP/HKD/AUD (≥5 cases).
//   - Bare-token defaults & 元/円 ambiguity (LOCKED, D-08):
//       bare 「元」 in zh locale → CNY; bare 「円」 → JPY; bare 「ドル」 → USD.
//   - Regression guard: existing non-currency amount extraction is unchanged.
//
// Do NOT weaken assertions to make them pass. RED is the intended state.
//
// See: .planning/phases/42-entry-ui-display-voice/42-CONTEXT.md (D-08),
//      lib/shared/constants/voice_currency_suffixes.dart,
//      lib/features/accounting/domain/models/voice_parse_result.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/parse_voice_input_use_case.dart';
import 'package:home_pocket/application/voice/voice_category_resolver.dart';
import 'package:home_pocket/application/voice/voice_text_parser.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/models/voice_parse_result.dart';
import 'package:home_pocket/infrastructure/ml/merchant_database.dart';
import 'package:mocktail/mocktail.dart';

class _MockVoiceCategoryResolver extends Mock
    implements VoiceCategoryResolver {}

class _MockMerchantDatabase extends Mock implements MerchantDatabase {}

class _FakeMerchantDatabase extends Fake implements MerchantDatabase {}

/// One voice corpus expectation: input → (amount, detectedCurrency).
class _CurrencyCase {
  const _CurrencyCase(this.input, this.amount, this.currency);
  final String input;
  final int amount;
  final String? currency;
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeMerchantDatabase());
  });

  late _MockVoiceCategoryResolver mockResolver;
  late _MockMerchantDatabase mockMerchantDatabase;
  late VoiceTextParser parser;
  late ParseVoiceInputUseCase useCase;

  setUp(() {
    mockResolver = _MockVoiceCategoryResolver();
    mockMerchantDatabase = _MockMerchantDatabase();
    parser = VoiceTextParser();
    useCase = ParseVoiceInputUseCase(
      textParser: parser,
      voiceCategoryResolver: mockResolver,
      merchantDatabase: mockMerchantDatabase,
    );

    when(() => mockMerchantDatabase.findMerchant(any())).thenReturn(null);
    when(() => mockResolver.resolve(any())).thenAnswer(
      (_) async => const CategoryMatchResult(
        categoryId: 'cat_food_dining_out',
        confidence: 0.5,
        source: MatchSource.fallback,
      ),
    );
    when(
      () => mockResolver.resolveLedgerType(any()),
    ).thenAnswer((_) async => LedgerType.daily);
  });

  Future<VoiceParseResult> parseWith(String input, String localeId) async {
    final result = await useCase.execute(input, localeId: localeId);
    expect(result.isSuccess, isTrue, reason: result.error);
    return result.data!;
  }

  // ─── zh per-currency corpus (VOICE-CUR-01/02) — ≥5 cases ───
  group('zh currency detection corpus (≥5 cases)', () {
    const cases = <_CurrencyCase>[
      _CurrencyCase('五十美元', 50, 'USD'),
      _CurrencyCase('一百欧元', 100, 'EUR'),
      _CurrencyCase('二十英镑', 20, 'GBP'),
      _CurrencyCase('三百港币', 300, 'HKD'),
      _CurrencyCase('五十澳元', 50, 'AUD'),
      _CurrencyCase('八十加元', 80, 'CAD'),
    ];

    for (final c in cases) {
      test('${c.input} -> ${c.amount} ${c.currency}', () async {
        final r = await parseWith(c.input, 'zh-CN');
        expect(r.amount, c.amount);
        // detectedCurrency does NOT exist yet → compile-fail RED.
        expect(r.detectedCurrency, c.currency);
      });
    }
  });

  // ─── ja per-currency corpus (VOICE-CUR-01/03) — ≥5 cases ───
  group('ja currency detection corpus (≥5 cases)', () {
    const cases = <_CurrencyCase>[
      _CurrencyCase('50ドル', 50, 'USD'),
      _CurrencyCase('100ユーロ', 100, 'EUR'),
      _CurrencyCase('20ポンド', 20, 'GBP'),
      _CurrencyCase('300香港ドル', 300, 'HKD'),
      _CurrencyCase('80豪ドル', 80, 'AUD'),
    ];

    for (final c in cases) {
      test('${c.input} -> ${c.amount} ${c.currency}', () async {
        final r = await parseWith(c.input, 'ja-JP');
        expect(r.amount, c.amount);
        expect(r.detectedCurrency, c.currency);
      });
    }
  });

  // ─── Bare-token defaults + 元/円 ambiguity (LOCKED, D-08) ───
  group('bare-token defaults & 元/円 ambiguity (D-08 locked)', () {
    test('bare 元 in zh locale → CNY', () async {
      final r = await parseWith('五十元', 'zh-CN');
      expect(r.amount, 50);
      expect(r.detectedCurrency, 'CNY');
    });

    test('bare 円 → JPY', () async {
      final r = await parseWith('50円', 'ja-JP');
      expect(r.amount, 50);
      // JPY native: detectedCurrency null (no foreign conversion) per D-08.
      expect(r.detectedCurrency, anyOf(isNull, 'JPY'));
    });

    test('bare ドル → USD (default)', () async {
      final r = await parseWith('50ドル', 'ja-JP');
      expect(r.amount, 50);
      expect(r.detectedCurrency, 'USD');
    });
  });

  // ─── Regression guard: existing non-currency extraction unchanged ───
  group('regression: existing non-currency corpus still parses', () {
    test('ja 昼ごはんに680円 → amount 680 (unchanged)', () async {
      final r = await parseWith('昼ごはんに680円', 'ja-JP');
      expect(r.amount, 680);
    });

    test('zh 午饭花了三十五块钱 → amount 35 (unchanged)', () async {
      final r = await parseWith('午饭花了三十五块钱', 'zh-CN');
      expect(r.amount, 35);
    });
  });
}
