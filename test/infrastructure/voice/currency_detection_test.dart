// WAVE 0 RED SCAFFOLD — Phase 42, producing plan 42-04 (voice currency detection).
//
// This file references VoiceParseResult.detectedCurrency — a getter that DOES
// NOT EXIST yet. It is therefore EXPECTED to fail to compile (RED) until plan
// 42-04 adds currency detection to the voice pipeline.
//
// Locked behavior under test (VOICE-CUR-01/02/03, CONTEXT D-08):
//   - zh corpus: 美元/欧元/英镑/港币/澳元/加元 → USD/EUR/GBP/HKD/AUD/CAD (≥5 cases).
//   - ja corpus: ドル/ユーロ/ポンド/香港ドル/豪ドル → USD/EUR/GBP/HKD/AUD (≥5 cases).
//   - Bare-token defaults & 元/円 ambiguity:
//       bare 「元」 → native JPY (null) in EVERY locale; bare 「円」 → JPY;
//       bare 「ドル」 → USD. Explicit 人民币/人民元/RMB/yuan → CNY.
//   - Regression guard: existing non-currency amount extraction is unchanged.
//
// 260703 BUG-2 — D-08's zh branch SUPERSEDED: the original D-08 resolved bare
// 「元」 in zh locale to CNY. In this JPY-native household app a zh speaker
// saying 「两千五百四十六元」 means yen (元 is the generic local-currency word,
// exactly like 块/块钱 which were ALREADY treated as native), so the CNY
// default triggered a wrong CNY→JPY conversion on every zh utterance.
// User-directed change 2026-07-03: bare 元 is native in all locales; only the
// explicit words (人民币/中国元/RMB/chinese yuan/yuan) map to CNY.
//
// Do NOT weaken assertions to make them pass. RED is the intended state.
//
// See: .planning/phases/42-entry-ui-display-voice/42-CONTEXT.md (D-08),
//      lib/shared/constants/voice_currency_suffixes.dart,
//      lib/features/voice/domain/models/voice_parse_result.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/parse_voice_input_use_case.dart';
import 'package:home_pocket/application/voice/recognition/category_recognizer.dart';
import 'package:home_pocket/application/voice/recognition/merchant_recognizer.dart';
import 'package:home_pocket/application/voice/voice_text_parser.dart';
import 'package:home_pocket/features/voice/domain/models/merchant_candidate.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/voice/domain/models/voice_parse_result.dart';
import 'package:mocktail/mocktail.dart';

class _MockCategoryRecognizer extends Mock implements CategoryRecognizer {}

class _MockMerchantRecognizer extends Mock implements MerchantRecognizer {}

/// One voice corpus expectation: input → (amount, detectedCurrency).
class _CurrencyCase {
  const _CurrencyCase(this.input, this.amount, this.currency);
  final String input;
  final int amount;
  final String? currency;
}

void main() {
  late _MockCategoryRecognizer mockCategoryRecognizer;
  late _MockMerchantRecognizer mockMerchantRecognizer;
  late VoiceTextParser parser;
  late ParseVoiceInputUseCase useCase;

  setUp(() {
    mockCategoryRecognizer = _MockCategoryRecognizer();
    mockMerchantRecognizer = _MockMerchantRecognizer();
    parser = VoiceTextParser();
    useCase = ParseVoiceInputUseCase(
      textParser: parser,
      categoryRecognizer: mockCategoryRecognizer,
      merchantRecognizer: mockMerchantRecognizer,
    );

    when(
      () => mockMerchantRecognizer.recognize(any()),
    ).thenAnswer((_) async => const <MerchantCandidate>[]);
    when(() => mockCategoryRecognizer.resolve(any())).thenAnswer(
      (_) async => const CategoryMatchResult(
        categoryId: 'cat_food_dining_out',
        confidence: 0.5,
        source: MatchSource.fallback,
      ),
    );
    when(
      () => mockCategoryRecognizer.resolveLedgerType(any()),
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

  // ─── Bare-token defaults + 元/円 ambiguity (D-08 zh branch superseded 260703) ───
  group('bare-token defaults & 元/円 ambiguity', () {
    // 260703 BUG-2: bare 元 in zh is the generic local-currency word — in this
    // JPY-native app it means yen (aligned with 块/块钱). CNY now requires the
    // explicit 人民币/RMB/yuan words. Supersedes the original D-08 zh→CNY rule.
    test('bare 元 in zh locale → native JPY (null), NOT CNY', () async {
      final r = await parseWith('五十元', 'zh-CN');
      expect(r.amount, 50);
      expect(r.detectedCurrency, isNull);
    });

    test('zh 人民币 still → CNY (explicit intent unaffected)', () async {
      final r = await parseWith('五十元人民币', 'zh-CN');
      expect(r.detectedCurrency, 'CNY');
    });

    // 260614-goh: in ja locale the bare 元 is JPY-native (D-08), NOT CNY — a
    // Japanese speaker must say 人民元 for Chinese yuan. Locks the asymmetry so
    // the zh→CNY rule above never leaks into the ja path.
    test('bare 元 in ja locale → JPY-native (null), NOT CNY', () async {
      final r = await parseWith('五十元', 'ja-JP');
      expect(r.amount, 50);
      expect(r.detectedCurrency, anyOf(isNull, 'JPY'));
    });

    test('ja 人民元 → CNY (explicit, unlike bare 元)', () async {
      final r = await parseWith('100人民元', 'ja-JP');
      expect(r.amount, 100);
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

  // ─── WR-03: bare-native token EARLIER than an explicit-foreign token ───
  // Pure leftmost-wins mis-classified these as the bare-native currency. The
  // explicit-foreign token must win regardless of position.
  group(
    'WR-03: bare-native-before-foreign prefers the explicit foreign token',
    () {
      test('zh 元宝店买了美元 → USD (not CNY)', () async {
        final r = await parseWith('元宝店买了美元', 'zh-CN');
        expect(r.detectedCurrency, 'USD');
      });

      test('zh 五十块花了美元 → USD (块@2 must not beat 美元)', () async {
        final r = await parseWith('五十块花了美元', 'zh-CN');
        expect(r.detectedCurrency, 'USD');
      });

      test('ja 円高でも100ドル → USD (円@0 must not beat ドル)', () async {
        final r = await parseWith('円高でも100ドル', 'ja-JP');
        expect(r.detectedCurrency, 'USD');
      });

      test('containment preserved: ja 香港ドル still wins over ドル', () async {
        final r = await parseWith('300香港ドル', 'ja-JP');
        expect(r.detectedCurrency, 'HKD');
      });
    },
  );

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

  // ─── Quick task 260614-goh: natural/colloquial + trilingual expansion ───
  // User report: 「语音输入说美元和人民币的时候没有切换货币」. Root cause: the
  // natural words users actually speak (人民币 / 美金) were never in the token
  // table, and English was deferred. Decision (--discuss): cover EVERY
  // supported currency (USD/EUR/CNY/HKD/GBP/KRW/TWD/AUD/CAD/SGD) in zh/ja/en.
  group('260614-goh: colloquial zh words', () {
    const cases = <_CurrencyCase>[
      _CurrencyCase('一百人民币', 100, 'CNY'),
      _CurrencyCase('一百人民幣', 100, 'CNY'),
      _CurrencyCase('五十美金', 50, 'USD'),
      _CurrencyCase('三百港元', 300, 'HKD'),
      _CurrencyCase('五十澳币', 50, 'AUD'),
      _CurrencyCase('八十加币', 80, 'CAD'),
      _CurrencyCase('一百韩元', 100, 'KRW'),
      _CurrencyCase('两百台币', 200, 'TWD'),
      _CurrencyCase('五十新加坡元', 50, 'SGD'),
    ];
    for (final c in cases) {
      test('${c.input} -> ${c.amount} ${c.currency}', () async {
        final r = await parseWith(c.input, 'zh-CN');
        expect(r.amount, c.amount);
        expect(r.detectedCurrency, c.currency);
      });
    }
  });

  group('260614-goh: ja currency words (full supported set)', () {
    const cases = <_CurrencyCase>[
      _CurrencyCase('100米ドル', 100, 'USD'),
      _CurrencyCase('100人民元', 100, 'CNY'),
      _CurrencyCase('300カナダドル', 300, 'CAD'),
      _CurrencyCase('80オーストラリアドル', 80, 'AUD'),
      _CurrencyCase('1000韓国ウォン', 1000, 'KRW'),
      _CurrencyCase('200台湾ドル', 200, 'TWD'),
      _CurrencyCase('50シンガポールドル', 50, 'SGD'),
    ];
    for (final c in cases) {
      test('${c.input} -> ${c.amount} ${c.currency}', () async {
        final r = await parseWith(c.input, 'ja-JP');
        expect(r.amount, c.amount);
        expect(r.detectedCurrency, c.currency);
      });
    }
  });

  group('260614-goh: en currency words (digits; STT-style)', () {
    const cases = <_CurrencyCase>[
      _CurrencyCase('100 dollars', 100, 'USD'),
      _CurrencyCase('100 US dollars', 100, 'USD'),
      _CurrencyCase('50 euros', 50, 'EUR'),
      _CurrencyCase('30 pounds', 30, 'GBP'),
      _CurrencyCase('200 yuan', 200, 'CNY'),
      _CurrencyCase('300 Hong Kong dollars', 300, 'HKD'),
      _CurrencyCase('80 Australian dollars', 80, 'AUD'),
      _CurrencyCase('80 Canadian dollars', 80, 'CAD'),
      _CurrencyCase('1000 Korean won', 1000, 'KRW'),
      _CurrencyCase('200 Taiwan dollars', 200, 'TWD'),
      _CurrencyCase('50 Singapore dollars', 50, 'SGD'),
    ];
    for (final c in cases) {
      test('${c.input} -> ${c.amount} ${c.currency}', () async {
        // null localeId → ja-then-zh fallback; detection is locale-independent.
        final r = await parseWith(c.input, 'en-US');
        expect(r.amount, c.amount);
        expect(r.detectedCurrency, c.currency);
      });
    }
  });

  group('260614-goh: en JPY-native stays null (no foreign conversion)', () {
    test('100 yen → JPY-native (null)', () async {
      final r = await parseWith('100 yen', 'en-US');
      expect(r.amount, 100);
      expect(r.detectedCurrency, anyOf(isNull, 'JPY'));
    });
  });

  group('260614-goh: containment + leftmost preserved with new tokens', () {
    test('zh 港元 wins over bare 元', () async {
      final r = await parseWith('三百港元', 'zh-CN');
      expect(r.detectedCurrency, 'HKD');
    });

    test('en Canadian dollar wins over bare dollar', () async {
      final r = await parseWith('80 Canadian dollars', 'en-US');
      expect(r.detectedCurrency, 'CAD');
    });

    test('en lowercase still detected (case-insensitive)', () async {
      final r = await parseWith('100 dollars', 'en-US');
      expect(r.detectedCurrency, 'USD');
    });
  });
}
