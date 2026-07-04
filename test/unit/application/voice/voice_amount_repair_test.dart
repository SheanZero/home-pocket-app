// 260703 BUG-1 — amount repair candidate threading + alternate-transcript
// cross-validation (1A/1D).
//
// iOS zh ITN can concatenate 「两千五百四十六」 into the poisoned transcript
// "250046元". The use case:
//   - carries a positional-repair CANDIDATE (2546) on the result when the
//     Arabic-path amount matches the concat signature — the form surfaces it
//     as a one-tap confirm affordance, never a silent rewrite;
//   - EXCEPT when one of the recognizer's alternate transcripts independently
//     parses to the candidate — then the recognizer itself disagrees with the
//     primary reading and the repair is adopted directly into `amount`.

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/parse_voice_input_use_case.dart';
import 'package:home_pocket/application/voice/recognition/category_recognizer.dart';
import 'package:home_pocket/application/voice/recognition/merchant_recognizer.dart';
import 'package:home_pocket/application/voice/voice_text_parser.dart';
import 'package:home_pocket/features/voice/domain/models/merchant_candidate.dart';
import 'package:home_pocket/features/voice/domain/models/voice_parse_result.dart';
import 'package:mocktail/mocktail.dart';

class _MockCategoryRecognizer extends Mock implements CategoryRecognizer {}

class _MockMerchantRecognizer extends Mock implements MerchantRecognizer {}

void main() {
  late ParseVoiceInputUseCase useCase;

  setUp(() {
    final categoryRecognizer = _MockCategoryRecognizer();
    final merchantRecognizer = _MockMerchantRecognizer();
    useCase = ParseVoiceInputUseCase(
      textParser: VoiceTextParser(),
      categoryRecognizer: categoryRecognizer,
      merchantRecognizer: merchantRecognizer,
    );
    when(
      () => merchantRecognizer.recognize(any()),
    ).thenAnswer((_) async => const <MerchantCandidate>[]);
    when(() => categoryRecognizer.resolve(any())).thenAnswer((_) async => null);
  });

  Future<VoiceParseResult> parse(
    String input, {
    List<String> alternateTexts = const [],
  }) async {
    final result = await useCase.execute(
      input,
      localeId: 'zh-CN',
      alternateTexts: alternateTexts,
    );
    expect(result.isSuccess, isTrue, reason: result.error);
    return result.data!;
  }

  group('amountRepairCandidate (260703 BUG-1)', () {
    test('poisoned 250046元 → amount kept, candidate 2546 surfaced', () async {
      final r = await parse('250046元');
      expect(r.amount, 250046);
      expect(r.amountRepairCandidate, 2546);
    });

    test('clean kanji 两千五百四十六元 → no candidate', () async {
      final r = await parse('两千五百四十六元');
      expect(r.amount, 2546);
      expect(r.amountRepairCandidate, isNull);
    });

    test(
      'comma-grouped 2,546元 → no candidate (digits not verbatim in text)',
      () async {
        final r = await parse('2,546元');
        expect(r.amount, 2546);
        expect(r.amountRepairCandidate, isNull);
      },
    );

    test(
      'round clean amount 250000元 → no candidate (zero tail rejected)',
      () async {
        final r = await parse('250000元');
        expect(r.amount, 250000);
        expect(r.amountRepairCandidate, isNull);
      },
    );

    // 260704 on-device report: single-zero split 「五千三百一十二」 → "53102元".
    test('poisoned 53102元 → amount kept, candidate 5312 surfaced', () async {
      final r = await parse('53102元');
      expect(r.amount, 53102);
      expect(r.amountRepairCandidate, 5312);
    });

    test('53102元 with a 5312元 alternate auto-adopts the repair', () async {
      final r = await parse('53102元', alternateTexts: ['5312元']);
      expect(r.amount, 5312);
      expect(r.amountRepairCandidate, isNull);
    });

    test('alternate transcript confirming the repair auto-adopts it', () async {
      final r = await parse('250046元', alternateTexts: ['2546元']);
      expect(r.amount, 2546);
      expect(r.amountRepairCandidate, isNull);
    });

    test(
      'alternate transcript NOT confirming keeps amount + candidate',
      () async {
        final r = await parse('250046元', alternateTexts: ['250046元', '哈哈']);
        expect(r.amount, 250046);
        expect(r.amountRepairCandidate, 2546);
      },
    );
  });
}
