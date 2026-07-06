// Quick task 260706-saz (MOD-009 P0-2): locks the VoiceTuning consolidation.
//
// Three guarantees:
//   1. The dual-declared `kMerchantAutoFillFloor` (application vs domain)
//      stays equal — the domain layer must not import shared tuning, so the
//      value IS the contract and this test is the machine lock (ADR-012 /
//      T-saz-03).
//   2. The three preserved public aliases resolve to their VoiceTuning value.
//   3. Every VoiceTuning value equals the pre-consolidation literal — any
//      silent drift of a tuning constant turns this file red.

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/parse_voice_input_use_case.dart'
    as application;
import 'package:home_pocket/application/voice/recognition/category_recognizer.dart';
import 'package:home_pocket/features/accounting/presentation/screens/voice_ptt_session_mixin.dart';
import 'package:home_pocket/features/accounting/presentation/screens/voice_recognition_event_handler_mixin.dart';
import 'package:home_pocket/features/voice/domain/services/recognition_reconciler.dart'
    as domain;
import 'package:home_pocket/shared/constants/voice_tuning.dart';

void main() {
  group('kMerchantAutoFillFloor dual declaration (T-saz-03)', () {
    test('domain-side floor equals application-side floor', () {
      expect(
        domain.kMerchantAutoFillFloor,
        application.kMerchantAutoFillFloor,
        reason:
            'recognition_reconciler.dart (domain) and '
            'parse_voice_input_use_case.dart (application) each declare the '
            '0.85 auto-fill floor — a single-sided change silently breaks the '
            'ADR-012 floor contract.',
      );
    });
  });

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
      expect(
        kLearnedPromotionThreshold,
        VoiceTuning.learnedPromotionThreshold,
      );
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
      expect(
        VoiceTuning.soundLevelThrottle,
        const Duration(milliseconds: 100),
      );
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
