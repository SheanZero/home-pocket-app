/// Quick task 260706-tm6 (voice-consolidation P0-4): ja golden corpus,
/// two-tier scheme.
///
/// Tier 1 (GREEN): every [voiceCorpusJaGolden] vector is asserted strictly in
/// its own test() — a single miss fails the suite (no statistical gate here;
/// the existing voice_corpus_ja_test.dart owns the ≥95% aggregate gate over
/// its own separate list).
///
/// Tier 2 (known-gap): every [voiceCorpusJaKnownGaps] vector keeps its strict
/// assertion in the test body but is skipped via the `skip:` parameter with
/// the documented reason — removing the skip activates the vector unchanged.
///
/// Meta assertions guard archive quality: golden notes and known-gap reasons
/// must be non-empty.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/voice_text_parser.dart';

import '../../fixtures/voice_corpus_ja.dart';

void main() {
  final parser = VoiceTextParser();
  int? parse(String input) => parser.extractAmount(input, localeId: 'ja-JP');

  group('ja golden corpus (Kanjize/NeMo-ja-derived, strict per-case)', () {
    for (final c in voiceCorpusJaGolden) {
      test('${c.input} -> ${c.expected}  [${c.note}]', () {
        expect(
          parse(c.input),
          c.expected,
          reason:
              'golden vector must pass strictly: input="${c.input}" '
              'expected=${c.expected} source=${c.note}',
        );
      });
    }
  });

  group('ja known-gap corpus (skip-documented, strict body preserved)', () {
    for (final c in voiceCorpusJaKnownGaps) {
      test(
        '${c.input} -> ${c.expected}',
        () {
          expect(
            parse(c.input),
            c.expected,
            reason:
                'known-gap vector: input="${c.input}" expected=${c.expected}',
          );
        },
        skip: 'known-gap: ${c.reason}',
      );
    }
  });

  group('ja corpus archive meta', () {
    test('every golden vector carries a non-empty source note', () {
      for (final c in voiceCorpusJaGolden) {
        expect(
          c.note,
          isNotNull,
          reason: 'golden "${c.input}" must document its source',
        );
        expect(
          c.note!.trim(),
          isNotEmpty,
          reason: 'golden "${c.input}" note must be non-empty',
        );
      }
    });

    test('every known-gap vector carries a non-empty reason', () {
      for (final c in voiceCorpusJaKnownGaps) {
        expect(
          c.reason.trim(),
          isNotEmpty,
          reason: 'known-gap "${c.input}" must document why it is skipped',
        );
      }
    });
  });
}
