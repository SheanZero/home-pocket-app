// quick-260707-kfb (KFB-5): pure unit tests that LOCK the post-final amount
// notice precedence on [VoiceAmountNoticePolicy]. No Flutter binding, no widget
// pump — the assertions are on the returned decision TYPE + numeric payload
// ONLY, never on any UI/ARB string. This is the guard that a future UI-copy
// change (or a reordering refactor) cannot silently flip the business
// precedence: conversion-undo > repair-adopt > large-amount > none.

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/voice_amount_notice_policy.dart';

void main() {
  const policy = VoiceAmountNoticePolicy();

  // An arbitrary threshold chosen for the test — the policy takes it as a
  // parameter, so the tests never depend on the production constant's value.
  const threshold = 1000000;
  const conversion = (jpy: 720, rate: '7.2');

  group('VoiceAmountNoticePolicy.decide — precedence', () {
    test('conversion + valid repair candidate + large amount → conversion-undo '
        '(highest precedence)', () {
      final notice = policy.decide(
        conversion: conversion,
        currency: 'USD',
        filledAmount: 100,
        dataAmount: 100,
        repairCandidate: 999,
        largeAmountThreshold: 50, // filledAmount 100 >= 50 would be "large"
      );

      expect(notice, isA<VoiceConversionUndoNotice>());
      final undo = notice as VoiceConversionUndoNotice;
      expect(undo.spokenAmount, 100);
      expect(undo.jpy, 720);
      expect(undo.rate, '7.2');
      expect(undo.currency, 'USD');
    });

    test('no conversion, valid repair candidate, large amount → repair-adopt '
        '(beats large-amount)', () {
      final notice = policy.decide(
        conversion: null,
        currency: 'JPY',
        filledAmount: threshold + 5,
        dataAmount: threshold + 5,
        repairCandidate: 2546,
        largeAmountThreshold: threshold,
      );

      expect(notice, isA<VoiceRepairAdoptNotice>());
      final adopt = notice as VoiceRepairAdoptNotice;
      expect(adopt.filledAmount, threshold + 5);
      expect(adopt.candidate, 2546);
    });

    test('no conversion, no valid repair, large amount → large-amount', () {
      final notice = policy.decide(
        conversion: null,
        currency: 'JPY',
        filledAmount: threshold + 1,
        dataAmount: threshold + 1,
        repairCandidate: null,
        largeAmountThreshold: threshold,
      );

      expect(notice, isA<VoiceLargeAmountNotice>());
      expect((notice as VoiceLargeAmountNotice).filledAmount, threshold + 1);
    });

    test('none of the conditions → none', () {
      final notice = policy.decide(
        conversion: null,
        currency: 'JPY',
        filledAmount: 500,
        dataAmount: 500,
        repairCandidate: null,
        largeAmountThreshold: threshold,
      );

      expect(notice, isA<VoiceNoNotice>());
    });
  });

  group('VoiceAmountNoticePolicy.decide — repair-candidate suppression', () {
    test('repair candidate SUPPRESSED when filledAmount != dataAmount '
        '(falls through to large-amount)', () {
      // The filled amount came from the merger, not data.amount → the
      // candidate is meaningless and must not surface.
      final notice = policy.decide(
        conversion: null,
        currency: 'JPY',
        filledAmount: threshold + 7,
        dataAmount: 42, // != filledAmount
        repairCandidate: 2546,
        largeAmountThreshold: threshold,
      );

      expect(notice, isA<VoiceLargeAmountNotice>());
      expect((notice as VoiceLargeAmountNotice).filledAmount, threshold + 7);
    });

    test(
      'repair candidate SUPPRESSED when filledAmount != dataAmount and amount '
      'is below threshold → none',
      () {
        final notice = policy.decide(
          conversion: null,
          currency: 'JPY',
          filledAmount: 500,
          dataAmount: 42,
          repairCandidate: 2546,
          largeAmountThreshold: threshold,
        );

        expect(notice, isA<VoiceNoNotice>());
      },
    );

    test('repair candidate SUPPRESSED when candidate == filledAmount', () {
      final notice = policy.decide(
        conversion: null,
        currency: 'JPY',
        filledAmount: 800,
        dataAmount: 800,
        repairCandidate: 800, // identical → no meaningful alternative reading
        largeAmountThreshold: threshold,
      );

      expect(notice, isA<VoiceNoNotice>());
    });
  });

  group('VoiceAmountNoticePolicy.decide — large-amount boundary', () {
    test('filledAmount exactly == threshold triggers large-amount', () {
      final notice = policy.decide(
        conversion: null,
        currency: 'JPY',
        filledAmount: threshold,
        dataAmount: threshold,
        repairCandidate: null,
        largeAmountThreshold: threshold,
      );

      expect(notice, isA<VoiceLargeAmountNotice>());
      expect((notice as VoiceLargeAmountNotice).filledAmount, threshold);
    });

    test('filledAmount == threshold - 1 does NOT trigger large-amount', () {
      final notice = policy.decide(
        conversion: null,
        currency: 'JPY',
        filledAmount: threshold - 1,
        dataAmount: threshold - 1,
        repairCandidate: null,
        largeAmountThreshold: threshold,
      );

      expect(notice, isA<VoiceNoNotice>());
    });
  });
}
