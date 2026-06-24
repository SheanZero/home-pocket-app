import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/voice/domain/models/voice_parse_result.dart';
import 'package:home_pocket/features/accounting/presentation/screens/voice_input_screen_helpers.dart';

// Quick task 260526-pg6 (Option F — Task 2): pin the new resolvedKeyword
// preference path + the legacy regex fallback. The preferred path closes the
// silent-orphan bug where two divergent extractors wrote learned rows under
// keys the resolver later never looked up. The fallback exists ONLY to keep
// older callers / test fakes that don't populate resolvedKeyword working.

void main() {
  group('extractVoiceKeyword — Task 2 resolvedKeyword preference', () {
    test(
      'Test 2.A.1: returns resolvedKeyword verbatim when non-null/non-empty '
      '(NOT the legacy stripped variant)',
      () {
        // Mimics the post-pg6 production shape: the use case computed `去外食`
        // via _extractKeyword, the resolver consumed `去外食`. The helper MUST
        // return that exact string so recordCorrection writes the same key.
        const result = VoiceParseResult(
          rawText: '去外食12,450日元',
          resolvedKeyword: '去外食',
        );

        // Pre-pg6 legacy behavior produced '去外食日元' because the helper's
        // regex `(円|元|ドル)?` stripped `元` only when terminal to digits, and
        // the bare `日` before it survived → `日元` left over. Asserting that
        // the helper now bypasses that path proves the bug is closed.
        expect(extractVoiceKeyword(result), equals('去外食'));
      },
    );

    test(
      'Test 2.A.2: resolvedKeyword == null falls back to the legacy regex '
      'path (1 regression pin on the safety-net behavior)',
      () {
        // Legacy behavior: regex strips `12,450円`, then the JP particle
        // pass strips に + は (both listed in `[のにでをはがもへとや]`),
        // leaving `昼ごん`. Pinning the buggy-but-historic output ensures
        // the safety-net is byte-identical to pre-Task-2 — fixing the
        // over-strip is out of scope for pg6 (would require gating the
        // helper on localeId, which is the broader unification the plan
        // explicitly deferred in favor of surfacing resolvedKeyword).
        const result = VoiceParseResult(rawText: '昼ごはんに12,450円');

        expect(extractVoiceKeyword(result), equals('昼ごん'));
      },
    );

    test(
      'Test 2.A.3: resolvedKeyword == empty-string also falls back to legacy '
      '(treated identically to null per the helper contract)',
      () {
        const result = VoiceParseResult(
          rawText: '昼ごはんに12,450円',
          resolvedKeyword: '',
        );

        // Empty-string is treated as "missing" — fall back to legacy regex.
        // Output mirrors Test 2.A.2 (same buggy-but-historic JP particle
        // over-strip).
        expect(extractVoiceKeyword(result), equals('昼ごん'));
      },
    );
  });
}
