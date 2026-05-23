import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/voice_text_parser.dart';

import '../../fixtures/voice_corpus_zh.dart';

void main() {
  final parser = VoiceTextParser();
  int? parse(String input) => parser.extractAmount(input, localeId: 'zh-CN');

  // Suite-wide pass/fail counters for the aggregate reporter.
  var passCount = 0;
  var totalCount = 0;

  // ─── Anchor cases — strict, individual test() blocks ───
  group('zh anchor cases (VOICE-01 / VOICE-02 / VOICE-03)', () {
    final anchors =
        voiceCorpusZh.where((c) => c.note?.startsWith('anchor:') ?? false).toList();

    // Sanity: ensure all 5 expected anchors are present in the fixture.
    setUpAll(() {
      expect(
        anchors.length,
        greaterThanOrEqualTo(5),
        reason: 'Fixture must contain ≥5 anchor cases (Plan 20-01 contract)',
      );
    });

    for (final c in anchors) {
      test('${c.input} -> ${c.expected}  [${c.note}]', () {
        totalCount++;
        final actual = parse(c.input);
        if (actual == c.expected) {
          passCount++;
        } else {
          // Count before throwing so tearDownAll sees accurate passCount.
          // Rethrow because anchor failures are HARD failures.
          expect(
            actual,
            c.expected,
            reason:
                'anchor case must pass strictly: input="${c.input}" expected=${c.expected} actual=$actual',
          );
        }
      });
    }
  });

  // ─── Statistical bucket — non-anchor cases ───
  group('zh statistical corpus (≥95% accuracy gate)', () {
    final nonAnchors =
        voiceCorpusZh
            .where((c) => !(c.note?.startsWith('anchor:') ?? false))
            .toList();

    for (final c in nonAnchors) {
      test(c.input, () {
        totalCount++;
        final actual = parse(c.input);
        if (actual == c.expected) {
          passCount++;
        } else {
          // Soft per-case failure: log mismatch for inspection but do NOT
          // throw — the ≥95% aggregate gate in tearDownAll is the only gate.
          // ignore: avoid_print
          printOnFailure(
            'mismatch: input="${c.input}" expected=${c.expected} actual=$actual note=${c.note ?? ""}',
          );
        }
      });
    }
  });

  tearDownAll(() {
    final pct = totalCount == 0 ? 0.0 : (passCount / totalCount * 100);
    // Print is the deliberate test reporter output per RESEARCH §Validation Architecture
    // ignore: avoid_print
    print('═══════════════════════════════════════════');
    // ignore: avoid_print
    print('zh corpus: $passCount/$totalCount (${pct.toStringAsFixed(1)}%)');
    // ignore: avoid_print
    print('═══════════════════════════════════════════');
    expect(
      totalCount == 0 ? 0.0 : passCount / totalCount,
      greaterThanOrEqualTo(0.95),
      reason:
          'VOICE-03: zh corpus accuracy ${pct.toStringAsFixed(1)}% < 95%',
    );
  });
}
