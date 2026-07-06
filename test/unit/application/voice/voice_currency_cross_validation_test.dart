import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/parse_voice_input_use_case.dart';
import 'package:home_pocket/application/voice/recognition/category_recognizer.dart';
import 'package:home_pocket/application/voice/recognition/merchant_recognizer.dart';
import 'package:home_pocket/application/voice/voice_text_parser.dart';
import 'package:home_pocket/features/voice/domain/models/merchant_candidate.dart';
import 'package:mocktail/mocktail.dart';

// voice-consolidation P1-8 — alternates currency cross-validation.
//
// A currency conversion is a HIGH-RISK write (it rewrites the booked amount
// through a rate fetch), so when the recognizer's alternate transcripts
// disagree with the primary about WHICH foreign currency was spoken, the
// parse layer must conservatively suppress `detectedCurrency` to null — no
// conversion fires, the form stays JPY-native, and the user can change the
// currency manually. This mirrors the 260703 1D precedent where alternates
// cross-validate a suspected ITN-concat amount.
//
// Contract under test (three groups):
//   1. Contradiction → suppress: primary detects foreign ISO X and ANY
//      alternate explicitly detects a DIFFERENT foreign ISO Y (both non-null,
//      X != Y) → detectedCurrency == null.
//   2. No contradiction → pass through: alternates with the SAME ISO, with no
//      currency token at all, or with a native token (bare 元/円 → null) do
//      NOT suppress the primary detection.
//   3. Empty alternates → pass through unchanged. Plus the conservative
//      one-sided counter-case: a native primary is NEVER promoted to foreign
//      by an alternate (primary null stays null).
//
// Harness mirrors parse_voice_input_use_case_test.dart: mocked engines
// (no-hit — this suite only exercises detectedCurrency), REAL VoiceTextParser
// so the currency detection runs the real numeral-state-machine token scan.

class _MockCategoryRecognizer extends Mock implements CategoryRecognizer {}

class _MockMerchantRecognizer extends Mock implements MerchantRecognizer {}

void main() {
  late _MockCategoryRecognizer mockCategory;
  late _MockMerchantRecognizer mockMerchant;
  late ParseVoiceInputUseCase useCase;

  setUp(() {
    mockCategory = _MockCategoryRecognizer();
    mockMerchant = _MockMerchantRecognizer();
    useCase = ParseVoiceInputUseCase(
      textParser: VoiceTextParser(),
      categoryRecognizer: mockCategory,
      merchantRecognizer: mockMerchant,
    );

    // No-hit engine stubs — detectedCurrency is the only field under test.
    when(() => mockCategory.resolve(any())).thenAnswer((_) async => null);
    when(
      () => mockMerchant.recognize(any()),
    ).thenAnswer((_) async => const <MerchantCandidate>[]);
  });

  // ─── Group 1: contradiction → conservative suppression ───
  group('cross-validation suppresses contradictory foreign detections', () {
    test('zh: primary USD vs alternate CNY → detectedCurrency null', () async {
      final result = await useCase.execute(
        '五百美元的东西',
        localeId: 'zh-CN',
        alternateTexts: const ['五百人民币的东西'],
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      expect(
        result.data!.detectedCurrency,
        isNull,
        reason: 'primary 美元→USD contradicted by alternate 人民币→CNY '
            '→ conversion must be suppressed',
      );
    });

    test('ja: primary USD vs alternate CNY → detectedCurrency null', () async {
      final result = await useCase.execute(
        '五百ドルの品物',
        localeId: 'ja-JP',
        alternateTexts: const ['五百人民元の品物'],
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      expect(
        result.data!.detectedCurrency,
        isNull,
        reason: 'primary ドル→USD contradicted by alternate 人民元→CNY '
            '→ conversion must be suppressed',
      );
    });
  });

  // ─── Group 2: no contradiction → primary passes through ───
  group('cross-validation passes non-contradicting alternates through', () {
    test('alternate detects the SAME ISO → primary USD retained', () async {
      final result = await useCase.execute(
        '五百美元的东西',
        localeId: 'zh-CN',
        alternateTexts: const ['五百美元的东西啊'],
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      expect(result.data!.detectedCurrency, equals('USD'));
    });

    test('alternate has NO currency token → primary USD retained', () async {
      final result = await useCase.execute(
        '五百美元的东西',
        localeId: 'zh-CN',
        alternateTexts: const ['去超市买东西'],
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      expect(result.data!.detectedCurrency, equals('USD'));
    });

    test(
      'alternate has native token (bare 元 → null) → primary USD retained',
      () async {
        final result = await useCase.execute(
          '五百美元的东西',
          localeId: 'zh-CN',
          alternateTexts: const ['五百元的东西'],
        );

        expect(result.isSuccess, isTrue, reason: result.error);
        expect(result.data!.detectedCurrency, equals('USD'));
      },
    );
  });

  // ─── Group 3: empty alternates + one-sided conservative direction ───
  group('cross-validation edge cases', () {
    test('empty alternates → primary USD passes through unchanged', () async {
      final result = await useCase.execute(
        '五百美元的东西',
        localeId: 'zh-CN',
        alternateTexts: const [],
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      expect(result.data!.detectedCurrency, equals('USD'));
    });

    test(
      'native primary is never promoted to foreign by an alternate',
      () async {
        final result = await useCase.execute(
          '五百元的东西',
          localeId: 'zh-CN',
          alternateTexts: const ['五百美元的东西'],
        );

        expect(result.isSuccess, isTrue, reason: result.error);
        expect(
          result.data!.detectedCurrency,
          isNull,
          reason: 'suppression is one-sided/conservative: alternates can '
              'only VETO a foreign detection, never introduce one',
        );
      },
    );
  });
}
