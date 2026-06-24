import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/english_number_words.dart';
import 'package:home_pocket/application/voice/voice_text_parser.dart';

/// VEN-02 / D-14: bounded English number-word fallback.
///
/// Task 1 covers the pure parser (`parseEnglishNumberWords`).
/// Task 2 covers the `extractAmount` hook + isolation.
void main() {
  group('parseEnglishNumberWords - token set (Task 1)', () {
    test('units: "fifty" -> 50', () {
      expect(parseEnglishNumberWords('fifty', moneyContext: true), equals(50));
    });

    test('teens: "nineteen" -> 19', () {
      expect(
        parseEnglishNumberWords('nineteen', moneyContext: true),
        equals(19),
      );
    });

    test('"a hundred" -> 100', () {
      expect(
        parseEnglishNumberWords('a hundred', moneyContext: true),
        equals(100),
      );
    });

    test('"one hundred" -> 100', () {
      expect(
        parseEnglishNumberWords('one hundred', moneyContext: true),
        equals(100),
      );
    });

    test('"two thousand" -> 2000', () {
      expect(
        parseEnglishNumberWords('two thousand', moneyContext: true),
        equals(2000),
      );
    });

    test('compound: "twenty five" -> 25', () {
      expect(
        parseEnglishNumberWords('twenty five', moneyContext: true),
        equals(25),
      );
    });

    test('case-insensitive: "Fifty Dollars" embedded -> 50', () {
      expect(
        parseEnglishNumberWords('Fifty Dollars', moneyContext: true),
        equals(50),
      );
    });
  });

  group('parseEnglishNumberWords - X.50 money idiom (Task 1)', () {
    test('"five fifty" in money context -> 550 (5.50 minor units)', () {
      expect(
        parseEnglishNumberWords('five fifty', moneyContext: true),
        equals(550),
      );
    });

    test('bare "five fifty" with NO money context -> null (550 ambiguity)', () {
      expect(
        parseEnglishNumberWords('five fifty', moneyContext: false),
        isNull,
      );
    });

    test('"twelve fifty" in money context -> 1250', () {
      expect(
        parseEnglishNumberWords('twelve fifty', moneyContext: true),
        equals(1250),
      );
    });
  });

  group('parseEnglishNumberWords - clamp / rejection (Task 1)', () {
    test('no number words -> null', () {
      expect(
        parseEnglishNumberWords('lunch at the cafe', moneyContext: true),
        isNull,
      );
    });

    test('zero is rejected (lower clamp: 0 < amount)', () {
      expect(parseEnglishNumberWords('zero', moneyContext: true), isNull);
    });

    test('clamp keeps in-range max: "nineteen hundred thousand" stays bounded', () {
      // 19 * 100 * 1000 = 1_900_000 — under the 10_000_000 ceiling, returned.
      expect(
        parseEnglishNumberWords('nineteen hundred thousand', moneyContext: true),
        equals(1900000),
      );
    });
  });

  group('english_number_words isolation (Task 1)', () {
    // The pure parser must never touch the CJK state machines. The source-level
    // guard lives in <verification> (grep); this asserts behaviour: a CJK-only
    // numeral string yields nothing from the en parser.
    test('CJK numeral string -> null (no CJK machine reuse)', () {
      expect(parseEnglishNumberWords('五百円', moneyContext: true), isNull);
    });
  });

  group('VoiceTextParser still parses Arabic (regression guard)', () {
    test('Arabic path unaffected by the new file import', () {
      final parser = VoiceTextParser();
      expect(parser.extractAmount('lunch 550 yen'), equals(550));
    });
  });
}
