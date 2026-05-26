import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/voice_text_parser.dart';

import '../../fixtures/voice_corpus_ja.dart';
import '../../fixtures/voice_corpus_zh.dart';

/// Quick task 260526-k92 (Item 4) — date-phrase corpus.
///
/// Verifies `VoiceTextParser.extractDate` against the new zh + ja phrases
/// added by Item 4 (明天/后天/大前天/明日/あした/あす/明後日/あさって) plus the
/// LAST-wins conflict rule. Each case computes `expectedToday` once at suite
/// startup; assertions compare whole-day offsets so a sub-second wall-clock
/// drift between setUp and parse-time does not flake the test.
void main() {
  final parser = VoiceTextParser();

  late DateTime expectedToday;

  setUpAll(() {
    final now = DateTime.now();
    expectedToday = DateTime(now.year, now.month, now.day);
  });

  group('zh date corpus (Item 4 of 260526-k92)', () {
    for (final c in voiceDateCorpusZh) {
      test('${c.input} → today ${c.offsetFromToday >= 0 ? "+" : ""}${c.offsetFromToday}d  [${c.note}]', () {
        final actual = parser.extractDate(c.input);
        expect(
          actual,
          isNotNull,
          reason: 'parser must extract a date for "${c.input}"',
        );
        final actualDay = DateTime(actual!.year, actual.month, actual.day);
        final deltaDays = actualDay.difference(expectedToday).inDays;
        expect(
          deltaDays,
          equals(c.offsetFromToday),
          reason:
              'offset mismatch: input="${c.input}" expected=${c.offsetFromToday}d actual=${deltaDays}d',
        );
      });
    }
  });

  group('ja date corpus (Item 4 of 260526-k92)', () {
    for (final c in voiceDateCorpusJa) {
      test('${c.input} → today ${c.offsetFromToday >= 0 ? "+" : ""}${c.offsetFromToday}d  [${c.note}]', () {
        final actual = parser.extractDate(c.input);
        expect(
          actual,
          isNotNull,
          reason: 'parser must extract a date for "${c.input}"',
        );
        final actualDay = DateTime(actual!.year, actual.month, actual.day);
        final deltaDays = actualDay.difference(expectedToday).inDays;
        expect(
          deltaDays,
          equals(c.offsetFromToday),
          reason:
              'offset mismatch: input="${c.input}" expected=${c.offsetFromToday}d actual=${deltaDays}d',
        );
      });
    }
  });
}
