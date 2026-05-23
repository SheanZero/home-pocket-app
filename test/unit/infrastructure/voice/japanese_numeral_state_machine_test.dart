import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/voice/numeral_state_machine.dart';
import 'package:home_pocket/infrastructure/voice/japanese_numeral_state_machine.dart';

void main() {
  group('JapaneseNumeralStateMachine', () {
    late JapaneseNumeralStateMachine machine;

    setUp(() {
      machine = JapaneseNumeralStateMachine();
    });

    group('parse — anchor cases', () {
      test(
        'にせんにひゃくよん -> 2204 (pure hiragana VOICE-01 anchor)',
        () => expect(machine.parse('にせんにひゃくよん'), 2204),
      );

      test(
        'にせんにひゃくよん円 -> 2204 (currency suffix)',
        () => expect(machine.parse('にせんにひゃくよん円'), 2204),
      );

      test(
        'せんはっぴゃくよんじゅう -> 1840 (sokuon+voicing single-pass)',
        () => expect(
          machine.parse('せんはっぴゃくよんじゅう'),
          1840,
          reason: 'せん→1000, はっぴゃく→800 (sokuon dict entry), よんじゅう→40; total 1840',
        ),
      );

      test(
        'せんはっぴゃくよんじゅう円 -> 1840',
        () => expect(machine.parse('せんはっぴゃくよんじゅう円'), 1840),
      );

      test(
        '一万二千 -> 12000 (万-scale regression guard VOICE-03)',
        () => expect(
          machine.parse('一万二千'),
          12000,
          reason: 'kanji digit+unit fallback: 一→Digit(1), 万→Unit(10000), 二→Digit(2), 千→Unit(1000); total 12000',
        ),
      );
    });

    group('parse — multi-reading parity (Pitfall 2)', () {
      test('ななひゃく == しちひゃく == 700', () {
        expect(machine.parse('ななひゃく'), 700);
        expect(machine.parse('しちひゃく'), 700);
      });

      test('よんじゅう == しじゅう == 40', () {
        expect(machine.parse('よんじゅう'), 40);
        expect(machine.parse('しじゅう'), 40);
      });

      test('きゅうじゅう == くじゅう == 90', () {
        expect(machine.parse('きゅうじゅう'), 90);
        expect(machine.parse('くじゅう'), 90);
      });

      test('いちまん → 10000 (only one form for 10000 per D-05)', () {
        expect(machine.parse('いちまん'), 10000);
      });
    });

    group('parse — voicing & sokuon variants', () {
      test(
        'さんぜん -> 3000 (rendaku)',
        () => expect(machine.parse('さんぜん'), 3000),
      );

      test(
        'はっせん -> 8000 (sokuon)',
        () => expect(machine.parse('はっせん'), 8000),
      );

      test(
        'ろっぴゃく -> 600 (sokuon)',
        () => expect(machine.parse('ろっぴゃく'), 600),
      );

      test(
        'さんびゃく -> 300 (voicing)',
        () => expect(machine.parse('さんびゃく'), 300),
      );

      test(
        'はっぴゃく -> 800 (sokuon — longest-match must NOT split into は+っ+ぴ+ゃ+く)',
        () => expect(
          machine.parse('はっぴゃく'),
          800,
          reason: 'Greedy longest-match must find はっぴゃく (5 chars) in dict before は (1 char)',
        ),
      );
    });

    group('parse — negative cases', () {
      test(
        'empty -> null',
        () => expect(machine.parse(''), isNull),
      );

      test(
        'non-numeric (現金) -> null',
        () => expect(
          machine.parse('現金'),
          isNull,
          reason: 'No numeric tokens recognized; empty token list → scan returns null',
        ),
      );

      test(
        'only currency suffix (円) -> null',
        () => expect(machine.parse('円'), isNull),
      );
    });

    group('normalize — token structure', () {
      test('はっぴゃく yields non-empty token list (longest-match anti-pattern guard)', () {
        final tokens = machine.normalize('はっぴゃく');
        expect(tokens, isNotEmpty,
            reason: 'longest-match MUST find はっぴゃく; empty list = single-char split bug');
      });

      test('normalize(現金) yields empty list', () {
        final tokens = machine.normalize('現金');
        expect(tokens, isEmpty);
      });

      test('normalize(1千8百) yields [Digit(1), Unit(1000), Digit(8), Unit(100)]', () {
        final tokens = machine.normalize('1千8百');
        expect(tokens.length, 4);
        expect(tokens[0], isA<Digit>());
        expect(tokens[1], isA<Unit>());
        expect(tokens[2], isA<Digit>());
        expect(tokens[3], isA<Unit>());
        expect((tokens[0] as Digit).value, 1);
        expect((tokens[1] as Unit).power, 1000);
        expect((tokens[2] as Digit).value, 8);
        expect((tokens[3] as Unit).power, 100);
      });

      test('normalize(せん) last token is Unit(1000)', () {
        final tokens = machine.normalize('せん');
        expect(tokens, isNotEmpty);
        expect(tokens.last, isA<Unit>());
        expect((tokens.last as Unit).power, 1000);
      });

      test('normalize(4十) first token is Digit(4)', () {
        final tokens = machine.normalize('4十');
        expect(tokens, isNotEmpty);
        expect(tokens.first, isA<Digit>());
        expect((tokens.first as Digit).value, 4);
      });
    });
  });
}
