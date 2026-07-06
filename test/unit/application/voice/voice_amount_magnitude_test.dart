// Quick task 260706-kzr — magnitude-word ↔ digit-count arbitration in
// ParseVoiceInputUseCase (L2).
//
// A spoken magnitude word (千/万/thousand) pins the amount's expected digit
// count. When the resolved amount violates it, the use case adopts — in
// order — the 1a repair candidate, a state-machine re-read of the primary,
// or an alternate-transcript reading (only when the candidate's digit count
// matches). On adoption the ORIGINAL reading swaps into
// `amountRepairCandidate` so the form's existing 1A notice becomes a one-tap
// UNDO — zero new ARB keys, zero new fields. The 260703 1a exact-alternate
// silent adoption runs FIRST and is untouched; anchor-free utterances stay
// byte-identical to the 260703 behavior.

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
    required String localeId,
    List<String> alternateTexts = const [],
  }) async {
    final result = await useCase.execute(
      input,
      localeId: localeId,
      alternateTexts: alternateTexts,
    );
    expect(result.isSuccess, isTrue, reason: result.error);
    return result.data!;
  }

  group('magnitude arbitration (260706-kzr)', () {
    test('zh 53102元 + 五千三百一十二元 alternate → 5312 (user screenshot; '
        '1a exact path pinned)', () async {
      final r = await parse(
        '53102元',
        localeId: 'zh-CN',
        alternateTexts: ['五千三百一十二元'],
      );
      expect(r.amount, 5312);
    });

    test(
      'ja 5000300円 + 五千三百円 alternate → 5300 via magnitude source ③ '
      '(zero-led tail defeats the concat detector; candidate swaps to the '
      'original for one-tap undo)',
      () async {
        // Plan deviation note: the plan's 100002000円 vector exceeds the
        // parser's <10M clamp (primary extraction yields null, so the guard
        // precondition never holds). 5000300円 is the same ITN shape —
        // 「五千三百」 split "5000"+"300", tail starts with 0 so
        // detectConcatRepairCandidate returns null — inside the clamp.
        final r = await parse(
          '5000300円',
          localeId: 'ja-JP',
          alternateTexts: ['五千三百円'],
        );
        expect(r.amount, 5300);
        expect(
          r.amountRepairCandidate,
          5000300,
          reason: 'the original poisoned reading rides as the undo anchor',
        );
      },
    );

    test(r'en $350016 + word alternate → 3516', () async {
      final r = await parse(
        r'$350016',
        localeId: 'en-US',
        alternateTexts: ['three thousand five hundred sixteen dollars'],
      );
      expect(r.amount, 3516);
    });

    test(
      'regression: anchor-free 250046元 without alternates stays '
      'byte-identical to 260703 (amount kept, candidate rides)',
      () async {
        final r = await parse('250046元', localeId: 'zh-CN');
        expect(r.amount, 250046);
        expect(r.amountRepairCandidate, 2546);
      },
    );

    test(
      'regression: clean kanji 三千五百元 → 3500, no candidate, no arbitration',
      () async {
        final r = await parse('三千五百元', localeId: 'zh-CN');
        expect(r.amount, 3500);
        expect(r.amountRepairCandidate, isNull);
      },
    );
  });
}
