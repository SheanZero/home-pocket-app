import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/voice/japanese_numeral_dictionary.dart';
import 'package:home_pocket/infrastructure/voice/numeral_state_machine.dart';

void main() {
  group('japaneseNumeralDictionary', () {
    group('digits', () {
      const expected = <String, int>{
        'いち': 1,
        'ひと': 1,
        'に': 2,
        'ふた': 2,
        'さん': 3,
        'よん': 4,
        'し': 4,
        'ご': 5,
        'ろく': 6,
        'なな': 7,
        'しち': 7,
        'はち': 8,
        'きゅう': 9,
        'く': 9,
      };
      expected.forEach((key, value) {
        test('$key -> Digit($value)', () {
          final tok = japaneseNumeralDictionary[key];
          expect(tok, isA<Digit>(), reason: 'key=$key returned $tok');
          expect((tok! as Digit).value, value);
        });
      });
    });

    group('zeroReadings', () {
      const keys = ['ゼロ', 'れい', 'まる'];
      for (final key in keys) {
        test('$key -> ZeroPlaceholder', () {
          final tok = japaneseNumeralDictionary[key];
          expect(tok, isA<ZeroPlaceholder>(), reason: 'key=$key returned $tok');
        });
      }
    });

    group('unitBaseForms', () {
      const expected = <String, int>{
        'せん': 1000,
        'ひゃく': 100,
        'じゅう': 10,
        'まん': 10000,
      };
      expected.forEach((key, power) {
        test('$key -> Unit($power)', () {
          final tok = japaneseNumeralDictionary[key];
          expect(tok, isA<Unit>(), reason: 'key=$key returned $tok');
          expect((tok! as Unit).power, power);
        });
      });
    });

    group('voicingVariants', () {
      test('いっせん -> PackedToken([Digit(1), Unit(1000)])', () {
        final tok = japaneseNumeralDictionary['いっせん'];
        expect(tok, isA<PackedToken>(), reason: 'key=いっせん returned $tok');
        final inner = (tok! as PackedToken).inner;
        expect(inner.length, 2);
        expect(inner[0], isA<Digit>());
        expect((inner[0] as Digit).value, 1);
        expect(inner[1], isA<Unit>());
        expect((inner[1] as Unit).power, 1000);
      });

      test('さんぜん -> PackedToken([Digit(3), Unit(1000)])', () {
        final tok = japaneseNumeralDictionary['さんぜん'];
        expect(tok, isA<PackedToken>(), reason: 'key=さんぜん returned $tok');
        final inner = (tok! as PackedToken).inner;
        expect(inner.length, 2);
        expect(inner[0], isA<Digit>());
        expect((inner[0] as Digit).value, 3);
        expect(inner[1], isA<Unit>());
        expect((inner[1] as Unit).power, 1000);
      });

      test('はっせん -> PackedToken([Digit(8), Unit(1000)])', () {
        final tok = japaneseNumeralDictionary['はっせん'];
        expect(tok, isA<PackedToken>(), reason: 'key=はっせん returned $tok');
        final inner = (tok! as PackedToken).inner;
        expect(inner.length, 2);
        expect(inner[0], isA<Digit>());
        expect((inner[0] as Digit).value, 8);
        expect(inner[1], isA<Unit>());
        expect((inner[1] as Unit).power, 1000);
      });

      test('さんびゃく -> PackedToken([Digit(3), Unit(100)])', () {
        final tok = japaneseNumeralDictionary['さんびゃく'];
        expect(tok, isA<PackedToken>(), reason: 'key=さんびゃく returned $tok');
        final inner = (tok! as PackedToken).inner;
        expect(inner.length, 2);
        expect(inner[0], isA<Digit>());
        expect((inner[0] as Digit).value, 3);
        expect(inner[1], isA<Unit>());
        expect((inner[1] as Unit).power, 100);
      });

      test('ろっぴゃく -> PackedToken([Digit(6), Unit(100)])', () {
        final tok = japaneseNumeralDictionary['ろっぴゃく'];
        expect(tok, isA<PackedToken>(), reason: 'key=ろっぴゃく returned $tok');
        final inner = (tok! as PackedToken).inner;
        expect(inner.length, 2);
        expect(inner[0], isA<Digit>());
        expect((inner[0] as Digit).value, 6);
        expect(inner[1], isA<Unit>());
        expect((inner[1] as Unit).power, 100);
      });

      test('はっぴゃく -> PackedToken([Digit(8), Unit(100)])', () {
        final tok = japaneseNumeralDictionary['はっぴゃく'];
        expect(tok, isA<PackedToken>(), reason: 'key=はっぴゃく returned $tok');
        final inner = (tok! as PackedToken).inner;
        expect(inner.length, 2);
        expect(inner[0], isA<Digit>());
        expect((inner[0] as Digit).value, 8);
        expect(inner[1], isA<Unit>());
        expect((inner[1] as Unit).power, 100);
      });

      test('いちまん -> PackedToken([Digit(1), Unit(10000)])', () {
        final tok = japaneseNumeralDictionary['いちまん'];
        expect(tok, isA<PackedToken>(), reason: 'key=いちまん returned $tok');
        final inner = (tok! as PackedToken).inner;
        expect(inner.length, 2);
        expect(inner[0], isA<Digit>());
        expect((inner[0] as Digit).value, 1);
        expect(inner[1], isA<Unit>());
        expect((inner[1] as Unit).power, 10000);
      });
    });

    test('missing key returns null', () {
      expect(japaneseNumeralDictionary['foo'], isNull);
    });
  });
}
