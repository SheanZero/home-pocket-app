// quick-260707-kfb (KFB-2): pure unit tests for [VoiceFillDecision], the
// resolve-on-final gating object. No Flutter binding, no widget pump — the
// assertions are on the plan's boolean gates ONLY. This locks the XVAL-03 /
// D-01..D-03 hysteresis: partial-driven fills (fillCategory == false) hold the
// category, recognition surface, conversion, and notice; only the final fill
// resolves them.

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/voice_fill_decision.dart';
import 'package:home_pocket/features/voice/domain/models/voice_parse_result.dart';

VoiceParseResult _data({String? categoryId, String? detectedCurrency}) {
  return VoiceParseResult(
    rawText: 'ランチ 800円',
    categoryMatch: categoryId == null
        ? null
        : CategoryMatchResult(
            categoryId: categoryId,
            confidence: 0.95,
            source: MatchSource.keyword,
          ),
    detectedCurrency: detectedCurrency,
  );
}

void main() {
  group(
    'VoiceFillDecision.from — partial-driven fill (fillCategory: false)',
    () {
      test(
        'resolveCategory / pushRecognition / attemptConversion / runNotice are '
        'all false regardless of parse content',
        () {
          final plan = VoiceFillDecision.from(
            fillCategory: false,
            data: _data(categoryId: 'food', detectedCurrency: 'USD'),
            arbitratedAmount: 500,
          );

          expect(plan.resolveCategory, isFalse);
          expect(plan.pushRecognition, isFalse);
          expect(plan.attemptConversion, isFalse);
          expect(plan.runNotice, isFalse);
        },
      );

      test('writeAmount follows arbitratedAmount > 0', () {
        final positive = VoiceFillDecision.from(
          fillCategory: false,
          data: _data(),
          arbitratedAmount: 500,
        );
        expect(positive.writeAmount, isTrue);

        final zero = VoiceFillDecision.from(
          fillCategory: false,
          data: _data(),
          arbitratedAmount: 0,
        );
        expect(zero.writeAmount, isFalse);
      });
    },
  );

  group('VoiceFillDecision.from — final fill (fillCategory: true)', () {
    test(
      'with a categoryMatch categoryId → resolveCategory + pushRecognition',
      () {
        final plan = VoiceFillDecision.from(
          fillCategory: true,
          data: _data(categoryId: 'food'),
          arbitratedAmount: 800,
        );

        expect(plan.resolveCategory, isTrue);
        expect(plan.pushRecognition, isTrue);
        expect(plan.runNotice, isTrue);
      },
    );

    test('without a categoryMatch → resolveCategory false, pushRecognition '
        'still true (final always pushes the recognition surface)', () {
      final plan = VoiceFillDecision.from(
        fillCategory: true,
        data: _data(),
        arbitratedAmount: 800,
      );

      expect(plan.resolveCategory, isFalse);
      expect(plan.pushRecognition, isTrue);
      expect(plan.runNotice, isTrue);
    });

    test('with a detectedCurrency + amount > 0 → attemptConversion true', () {
      final plan = VoiceFillDecision.from(
        fillCategory: true,
        data: _data(detectedCurrency: 'USD'),
        arbitratedAmount: 50,
      );

      expect(plan.attemptConversion, isTrue);
    });

    test(
      'detectedCurrency present but amount == 0 → attemptConversion false',
      () {
        final plan = VoiceFillDecision.from(
          fillCategory: true,
          data: _data(detectedCurrency: 'USD'),
          arbitratedAmount: 0,
        );

        expect(plan.attemptConversion, isFalse);
        expect(plan.writeAmount, isFalse);
      },
    );

    test('no detectedCurrency → attemptConversion false even with amount', () {
      final plan = VoiceFillDecision.from(
        fillCategory: true,
        data: _data(),
        arbitratedAmount: 800,
      );

      expect(plan.attemptConversion, isFalse);
    });

    test('empty-string detectedCurrency is treated as absent', () {
      final plan = VoiceFillDecision.from(
        fillCategory: true,
        data: _data(detectedCurrency: ''),
        arbitratedAmount: 800,
      );

      expect(plan.attemptConversion, isFalse);
    });
  });

  group('VoiceFillDecision.from — writeAmount gating', () {
    test('arbitratedAmount == 0 → writeAmount false', () {
      final plan = VoiceFillDecision.from(
        fillCategory: true,
        data: _data(categoryId: 'food'),
        arbitratedAmount: 0,
      );

      expect(plan.writeAmount, isFalse);
    });
  });
}
