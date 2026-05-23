// Cross-machine normalize() invariant tests.
//
// Locks the contract surface that Plan 20-08's _bufferLooksOpen and
// _chunkStartsNumeric predicates depend on — last-token-is-Unit and
// first-token-is-Digit. If those invariants drift, the merger's gate
// falls apart.
//
// Also establishes the normalize(non-numeric) == [] contracts that Plan 20-08
// uses to reject "现金" / "現金" as non-numeric chunk leaders.
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/voice/numeral_state_machine.dart';
import 'package:home_pocket/infrastructure/voice/chinese_numeral_state_machine.dart';
import 'package:home_pocket/infrastructure/voice/japanese_numeral_state_machine.dart';

void main() {
  group('ChineseNumeralStateMachine.normalize', () {
    late ChineseNumeralStateMachine zh;

    setUp(() {
      zh = const ChineseNumeralStateMachine();
    });

    test(
      'normalize(1千8百) yields [Digit(1), Unit(1000), Digit(8), Unit(100)]',
      () {
        final tokens = zh.normalize('1千8百');
        expect(tokens.length, 4,
            reason: 'Mixed arabic+kanji must produce 4 tokens');
        expect(tokens[0], isA<Digit>());
        expect(tokens[1], isA<Unit>());
        expect(tokens[2], isA<Digit>());
        expect(tokens[3], isA<Unit>());
        expect((tokens[0] as Digit).value, 1);
        expect((tokens[1] as Unit).power, 1000);
        expect((tokens[2] as Digit).value, 8);
        expect((tokens[3] as Unit).power, 100);
      },
    );

    test(
      'normalize(4十元) first token is Digit(4), length 2 (元 dropped)',
      () {
        final tokens = zh.normalize('4十元');
        expect(tokens, hasLength(2));
        expect(tokens.first, isA<Digit>());
        expect((tokens.first as Digit).value, 4);
        expect(tokens[1], isA<Unit>());
        expect((tokens[1] as Unit).power, 10);
      },
    );

    test(
      'normalize(现金) yields [] (no recognized chars → empty, merger lexical gate rejects)',
      () {
        final tokens = zh.normalize('现金');
        expect(tokens, isEmpty,
            reason: '现金 has no digits or units; merger gate must reject as non-numeric leader');
      },
    );

    test(
      'normalize(零) yields [ZeroPlaceholder] (single-token check)',
      () {
        final tokens = zh.normalize('零');
        expect(tokens, hasLength(1));
        expect(tokens.first, isA<ZeroPlaceholder>());
      },
    );
  });

  group('JapaneseNumeralStateMachine.normalize', () {
    late JapaneseNumeralStateMachine ja;

    setUp(() {
      ja = JapaneseNumeralStateMachine();
    });

    test(
      'normalize はっぴゃく yields tokens that scan to 800 (longest-match anti-pattern guard)',
      () {
        final tokens = ja.normalize('はっぴゃく');
        expect(tokens, isNotEmpty,
            reason: 'longest-match MUST find はっぴゃく; empty list = single-char split bug');
        // Round-trip through scan to verify token semantics
        expect(ja.parse('はっぴゃく'), 800);
      },
    );

    test(
      'normalize(現金) yields [] (all chars unrecognised → Skip → dropped)',
      () {
        final tokens = ja.normalize('現金');
        expect(tokens, isEmpty,
            reason: '現金 chars not in dictionary or kanji digit/unit tables; merger gate must reject');
      },
    );

    test(
      'normalize(1千8百) yields [Digit(1), Unit(1000), Digit(8), Unit(100)] — same shape as zh for merger gate',
      () {
        final tokens = ja.normalize('1千8百');
        expect(tokens.length, 4,
            reason: 'Arabic+kanji fallback path must produce same 4-token shape as zh');
        expect(tokens[0], isA<Digit>());
        expect(tokens[1], isA<Unit>());
        expect(tokens[2], isA<Digit>());
        expect(tokens[3], isA<Unit>());
        expect((tokens[0] as Digit).value, 1);
        expect((tokens[1] as Unit).power, 1000);
        expect((tokens[2] as Digit).value, 8);
        expect((tokens[3] as Unit).power, 100);
      },
    );

    test(
      'normalize(せん) last token is Unit(1000) — used by _bufferLooksOpen Case A in Plan 20-08',
      () {
        final tokens = ja.normalize('せん');
        expect(tokens, isNotEmpty);
        expect(tokens.last, isA<Unit>());
        expect((tokens.last as Unit).power, 1000);
      },
    );

    test(
      'normalize(4十) first token is Digit(4) — used by _chunkStartsNumeric predicate',
      () {
        final tokens = ja.normalize('4十');
        expect(tokens, isNotEmpty);
        expect(tokens.first, isA<Digit>());
        expect((tokens.first as Digit).value, 4);
      },
    );
  });
}
