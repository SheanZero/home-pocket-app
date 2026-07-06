// Quick task 260706-saz (MOD-009 P0-1) — direct unit tests for AmountArbiter,
// the single arbitration point extracted from ParseVoiceInputUseCase (1a/1b)
// and VoicePttSessionMixin (display-time merged-vs-parsed arbitration).
//
// Vectors mirror the 260703 (ITN-concat repair) and 260706-kzr (magnitude
// arbitration) characterization suites so the migrated semantics are pinned
// at the arbiter surface too — not only through the two call sites.

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/amount_arbiter.dart';

void main() {
  final arbiter = AmountArbiter();

  group('resolveParsedAmount — 260703 1a concat repair', () {
    test('poisoned 250046 without alternates → kept, candidate 2546 rides',
        () {
      final r = arbiter.resolveParsedAmount(
        parsed: 250046,
        recognizedText: '250046元',
        alternateTexts: const [],
        localeId: 'zh-CN',
      );
      expect(r.amount, 250046);
      expect(r.repairCandidate, 2546);
    });

    test('alternate confirming the repair silently adopts it', () {
      final r = arbiter.resolveParsedAmount(
        parsed: 250046,
        recognizedText: '250046元',
        alternateTexts: const ['2546元'],
        localeId: 'zh-CN',
      );
      expect(r.amount, 2546);
      expect(r.repairCandidate, isNull);
    });

    test('non-confirming alternates keep amount + riding candidate', () {
      final r = arbiter.resolveParsedAmount(
        parsed: 250046,
        recognizedText: '250046元',
        alternateTexts: const ['250046元', '哈哈'],
        localeId: 'zh-CN',
      );
      expect(r.amount, 250046);
      expect(r.repairCandidate, 2546);
    });

    test('kanji-parsed amount is never second-guessed (signature gate)', () {
      // 2546 was parsed from kanji — "2546" does not appear verbatim in the
      // transcript, so the concat detector never runs.
      final r = arbiter.resolveParsedAmount(
        parsed: 2546,
        recognizedText: '两千五百四十六元',
        alternateTexts: const [],
        localeId: 'zh-CN',
      );
      expect(r.amount, 2546);
      expect(r.repairCandidate, isNull);
    });

    test('53102 + kanji alternate → 5312 via 1a exact path (silent adopt)',
        () {
      final r = arbiter.resolveParsedAmount(
        parsed: 53102,
        recognizedText: '53102元',
        alternateTexts: const ['五千三百一十二元'],
        localeId: 'zh-CN',
      );
      expect(r.amount, 5312);
      expect(r.repairCandidate, isNull);
    });
  });

  group('resolveParsedAmount — 260706-kzr magnitude arbitration', () {
    test(
      'ja 5000300 + 五千三百円 alternate → 5300 adopted, original swaps into '
      'the candidate (one-tap undo)',
      () {
        final r = arbiter.resolveParsedAmount(
          parsed: 5000300,
          recognizedText: '5000300円',
          alternateTexts: const ['五千三百円'],
          localeId: 'ja-JP',
        );
        expect(r.amount, 5300);
        expect(r.repairCandidate, 5000300);
      },
    );

    test(r'en $350016 + word alternate → 3516', () {
      final r = arbiter.resolveParsedAmount(
        parsed: 350016,
        recognizedText: r'$350016',
        alternateTexts: const ['three thousand five hundred sixteen dollars'],
        localeId: 'en-US',
      );
      expect(r.amount, 3516);
    });

    test('anchor-free utterance returns the parsed amount unchanged', () {
      final r = arbiter.resolveParsedAmount(
        parsed: 8000,
        recognizedText: '买东西8000元',
        alternateTexts: const [],
        localeId: 'zh-CN',
      );
      expect(r.amount, 8000);
      expect(r.repairCandidate, isNull);
    });

    test('null parsed amount passes through untouched', () {
      final r = arbiter.resolveParsedAmount(
        parsed: null,
        recognizedText: '午饭',
        alternateTexts: const [],
        localeId: 'zh-CN',
      );
      expect(r.amount, isNull);
      expect(r.repairCandidate, isNull);
    });
  });

  group('resolveDisplayAmount — merged-priority default', () {
    test('merged wins over parsed on plain divergence (anchor-free)', () {
      final amount = arbiter.resolveDisplayAmount(
        parsed: 300,
        merged: 2500,
        rawText: '买东西',
        localeId: 'zh-CN',
      );
      expect(amount, 2500);
    });

    test('merged null falls back to parsed', () {
      final amount = arbiter.resolveDisplayAmount(
        parsed: 450,
        merged: null,
        rawText: '450元',
        localeId: 'zh-CN',
      );
      expect(amount, 450);
    });

    test('both null → null (caller falls back to 0)', () {
      final amount = arbiter.resolveDisplayAmount(
        parsed: null,
        merged: null,
        rawText: '午饭',
        localeId: 'zh-CN',
      );
      expect(amount, isNull);
    });
  });

  group('resolveDisplayAmount — concat exception (260703)', () {
    test('merged 250046 vs parsed 2546 → parsed wins (poisoning detected)',
        () {
      final amount = arbiter.resolveDisplayAmount(
        parsed: 2546,
        merged: 250046,
        rawText: '两千五百四十六元',
        localeId: 'zh-CN',
      );
      expect(amount, 2546);
    });

    test('merged 53102 vs parsed 5312 → parsed wins (kzr vector A shape)',
        () {
      final amount = arbiter.resolveDisplayAmount(
        parsed: 5312,
        merged: 53102,
        rawText: '五千三百一十二元',
        localeId: 'zh-CN',
      );
      expect(amount, 5312);
    });
  });

  group('resolveDisplayAmount — magnitude exception (260706-kzr)', () {
    test(
      'merged 35016 violates the 三千五百一十六 anchor, parsed 3516 satisfies '
      '→ parsed wins (concat detector null for 35016 — pure magnitude branch)',
      () {
        final amount = arbiter.resolveDisplayAmount(
          parsed: 3516,
          merged: 35016,
          rawText: '三千五百一十六元',
          localeId: 'zh-CN',
        );
        expect(amount, 3516);
      },
    );

    test('both readings compliant → merged keeps priority', () {
      final amount = arbiter.resolveDisplayAmount(
        parsed: 3500,
        merged: 8000,
        rawText: '三千五百元',
        localeId: 'zh-CN',
      );
      expect(amount, 8000);
    });

    test('both readings violating → merged keeps priority', () {
      final amount = arbiter.resolveDisplayAmount(
        parsed: 350,
        merged: 35016,
        rawText: '三千五百元',
        localeId: 'zh-CN',
      );
      expect(amount, 35016);
    });

    test('anchor-free rawText → merged keeps priority', () {
      final amount = arbiter.resolveDisplayAmount(
        parsed: 3500,
        merged: 8000,
        rawText: '买东西8000',
        localeId: 'zh-CN',
      );
      expect(amount, 8000);
    });
  });

  group('extractAmount delegation', () {
    test('routes through the full parser (comma-grouped final preserved)', () {
      expect(arbiter.extractAmount('2,546元', localeId: 'zh-CN'), 2546);
    });

    test('kanji reading routes through the state machine', () {
      expect(arbiter.extractAmount('两千五百四十六元', localeId: 'zh-CN'), 2546);
    });
  });
}
