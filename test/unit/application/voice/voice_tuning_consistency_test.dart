// Quick task 260706-saz (MOD-009 P0-2): locks the VoiceTuning consolidation.
//
// Two guarantees:
//   1. The three preserved public aliases resolve to their VoiceTuning value.
//   2. Every VoiceTuning value equals the pre-consolidation literal — any
//      silent drift of a tuning constant turns this file red.

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/recognition/category_recognizer.dart';
import 'package:home_pocket/features/accounting/presentation/screens/voice_ptt_session_mixin.dart';
import 'package:home_pocket/features/accounting/presentation/screens/voice_recognition_event_handler_mixin.dart';
import 'package:home_pocket/shared/constants/voice_tuning.dart';

void main() {
  group('preserved public aliases resolve to VoiceTuning', () {
    test('kVoiceLargeAmountNoticeThreshold aliases VoiceTuning', () {
      expect(
        kVoiceLargeAmountNoticeThreshold,
        VoiceTuning.largeAmountNoticeThresholdJpy,
      );
    });

    test('intraSessionThreshold aliases VoiceTuning', () {
      expect(
        VoiceRecognitionEventHandlerMixin.intraSessionThreshold,
        VoiceTuning.intraSessionThreshold,
      );
    });

    test('kLearnedPromotionThreshold aliases VoiceTuning', () {
      expect(kLearnedPromotionThreshold, VoiceTuning.learnedPromotionThreshold);
    });
  });

  group('VoiceTuning values are locked to pre-consolidation behavior', () {
    test('recognizer listen configuration', () {
      expect(VoiceTuning.listenFor, const Duration(seconds: 30));
      expect(VoiceTuning.pauseFor, const Duration(seconds: 3));
    });

    test('the two distinct 300ms constants stay separately declared', () {
      expect(
        VoiceTuning.partialParseDebounce,
        const Duration(milliseconds: 300),
      );
      expect(
        VoiceTuning.holdMisfireThreshold,
        const Duration(milliseconds: 300),
      );
    });

    test('merger window / intra-session heuristic / sound-level throttle', () {
      expect(VoiceTuning.mergerWindow, const Duration(milliseconds: 2500));
      expect(
        VoiceTuning.intraSessionThreshold,
        const Duration(milliseconds: 800),
      );
      expect(VoiceTuning.soundLevelThrottle, const Duration(milliseconds: 100));
    });

    test('amount thresholds', () {
      expect(VoiceTuning.largeAmountNoticeThresholdJpy, 1000000);
      expect(VoiceTuning.amountUpperBoundExclusive, 10000000);
    });

    test('learned promotion threshold', () {
      expect(VoiceTuning.learnedPromotionThreshold, 3);
    });
  });
}
