import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/voice/chinese_numeral_state_machine.dart';
import 'package:home_pocket/infrastructure/voice/numeral_state_machine.dart';

void main() {
  group('ChineseNumeralStateMachine', () {
    late ChineseNumeralStateMachine machine;

    setUp(() {
      machine = const ChineseNumeralStateMachine();
    });

    group('parse — anchor cases', () {
      test(
        '2千2百零4元 -> 2204 (零-placeholder VOICE-01 anchor)',
        () => expect(
          machine.parse('2千2百零4元'),
          2204,
          reason:
              'ZeroPlaceholder must not coerce digit to implicit 1; next Digit(4) lands as bare-tail',
        ),
      );

      test(
        '1千8百4十元 -> 1840 (single-pass complete)',
        () => expect(
          machine.parse('1千8百4十元'),
          1840,
          reason:
              'section accumulates: 8*100=800 + 4*10=40 → 840; +1000 → 1840',
        ),
      );

      test(
        '一千二百 -> 1200',
        () => expect(
          machine.parse('一千二百'),
          1200,
          reason: 'bare digit prefix + units, no currency suffix',
        ),
      );

      test(
        '六百八十块 -> 680',
        () => expect(
          machine.parse('六百八十块'),
          680,
          reason:
              '块 currency suffix is dropped by normalize; 6*100 + 8*10 = 680',
        ),
      );

      test(
        '三千九百八十 -> 3980',
        () => expect(
          machine.parse('三千九百八十'),
          3980,
          reason: 'three-segment compound without 万',
        ),
      );

      test(
        '一万二千 -> 12000 (万-flush)',
        () => expect(
          machine.parse('一万二千'),
          12000,
          reason: '万-flush: 1*10000 + 2000 = 12000',
        ),
      );

      test(
        '九万九千九百九十九 -> 99999',
        () => expect(
          machine.parse('九万九千九百九十九'),
          99999,
          reason: 'max 4-digit-万 + sub-万 compound',
        ),
      );
    });

    group('parse — negative cases', () {
      test(
        'empty string -> null',
        () => expect(
          machine.parse(''),
          isNull,
          reason: 'empty input yields empty token stream; sawAny=false → null',
        ),
      );

      test(
        'non-numeric text -> null',
        () => expect(
          machine.parse('abc'),
          isNull,
          reason: 'no recognizable tokens → sawAny=false → null',
        ),
      );

      test(
        'only 零 -> null (total=0 gate)',
        () => expect(
          machine.parse('零'),
          isNull,
          reason: 'ZeroPlaceholder → total=0; total > 0 gate fails → null',
        ),
      );

      test(
        'only currency -> null',
        () => expect(
          machine.parse('元'),
          isNull,
          reason:
              'currency suffix dropped by normalize; empty effective tokens → null',
        ),
      );
    });

    group('normalize — token stream', () {
      test('normalize 2千2百零4元 yields expected 6-token sequence', () {
        final toks = machine.normalize('2千2百零4元');
        // 元 is dropped; ordering: Digit(2), Unit(1000), Digit(2), Unit(100), ZeroPlaceholder, Digit(4)
        expect(
          toks.length,
          6,
          reason: '元 is dropped; 6 meaningful tokens remain',
        );
        expect(toks[0], isA<Digit>());
        expect((toks[0] as Digit).value, 2, reason: 'first token is Digit(2)');
        expect(toks[1], isA<Unit>());
        expect(
          (toks[1] as Unit).power,
          1000,
          reason: 'second token is Unit(1000)',
        );
        expect(toks[2], isA<Digit>());
        expect((toks[2] as Digit).value, 2, reason: 'third token is Digit(2)');
        expect(toks[3], isA<Unit>());
        expect(
          (toks[3] as Unit).power,
          100,
          reason: 'fourth token is Unit(100)',
        );
        expect(
          toks[4],
          isA<ZeroPlaceholder>(),
          reason: 'fifth token is ZeroPlaceholder from 零',
        );
        expect(toks[5], isA<Digit>());
        expect((toks[5] as Digit).value, 4, reason: 'sixth token is Digit(4)');
      });

      test('normalize arabic 1千 yields [Digit(1), Unit(1000)]', () {
        final toks = machine.normalize('1千');
        expect(toks.length, 2, reason: 'arabic digit 1 + unit 千');
        expect(toks[0], isA<Digit>());
        expect(
          (toks[0] as Digit).value,
          1,
          reason: 'arabic 1 recognized as Digit(1)',
        );
        expect(toks[1], isA<Unit>());
        expect((toks[1] as Unit).power, 1000, reason: '千 maps to Unit(1000)');
      });

      test('normalize kanji 一千 yields [Digit(1), Unit(1000)]', () {
        final toks = machine.normalize('一千');
        expect(toks.length, 2, reason: 'kanji digit 一 + unit 千');
        expect(toks[0], isA<Digit>());
        expect(
          (toks[0] as Digit).value,
          1,
          reason: '一 maps via _kanjiDigits to Digit(1)',
        );
        expect(toks[1], isA<Unit>());
        expect((toks[1] as Unit).power, 1000);
      });

      test('normalize 零 alone yields [ZeroPlaceholder]', () {
        final toks = machine.normalize('零');
        expect(toks.length, 1, reason: 'only ZeroPlaceholder emitted');
        expect(toks[0], isA<ZeroPlaceholder>());
      });

      test('normalize drops currency suffix 元', () {
        final toks = machine.normalize('元');
        expect(toks, isEmpty, reason: '元 is in skip pattern, dropped silently');
      });
    });

    // 260703 BUG-1 (ITN-split positional merge): iOS zh ITN can normalize
    // 「两千五百四十六」 as two number segments "2500"+"46". When the segments
    // arrive separated (space in the transcript, or the separator the chunk
    // merger inserts between finals), consecutive Digit tokens must merge
    // positionally when the second fits inside the first's trailing zeros —
    // not overwrite (the old last-wins kept only "46").
    group('parse — ITN-split consecutive digit groups (260703 BUG-1)', () {
      test('2500 46元 -> 2546 (tail fits trailing zeros)', () {
        expect(machine.parse('2500 46元'), 2546);
      });

      test('1000 200 -> 1200', () {
        expect(machine.parse('1000 200'), 1200);
      });

      test('250 4 -> 254 (single trailing zero)', () {
        expect(machine.parse('250 4'), 254);
      });

      test('12 34 -> 34 (no fit, last-wins preserved)', () {
        expect(machine.parse('12 34'), 34);
      });

      test('3000 5000 -> 5000 (self-correction overwrite preserved)', () {
        expect(machine.parse('3000 5000'), 5000);
      });

      // 260704: single-trailing-zero heads (十-terminated groups) — the
      // 「五千三百一十二」→"5310"+"2" split reported on-device. scan()'s
      // positional merge accepts a 1-digit tail into one trailing zero.
      test('5310 2元 -> 5312 (single-zero head + 1-digit tail)', () {
        expect(machine.parse('5310 2元'), 5312);
      });

      test('3210 1元 -> 3211', () {
        expect(machine.parse('3210 1元'), 3211);
      });

      test('两千五百四十六元 -> 2546 (pure kanji regression)', () {
        expect(machine.parse('两千五百四十六元'), 2546);
      });
    });
  });
}
