// lib/application/voice/voice_amount_notice_policy.dart
//
// quick-260707-kfb (KFB-2/KFB-5): the post-final amount-notice PRECEDENCE,
// extracted verbatim from `VoicePttSessionMixin._showVoiceAmountNotice`
// (voice_ptt_session_foreign_notice.dart) into a pure, stateless policy object.
//
// Placement rationale (CLAUDE.md placement rule): this is business ordering,
// not a domain model or repository interface — so it belongs in
// `lib/application/{domain}/`, co-located with the existing pure `AmountArbiter`
// (`amount_arbiter.dart`). It imports ONLY Dart core: zero Flutter, zero
// widget/State/BuildContext, and it never performs IO or reaches back into the
// State. The State DECIDES via [VoiceAmountNoticePolicy.decide] and then maps
// the returned variant to ARB copy + SnackBar side effects. Because the result
// carries only numeric payload (no locale, no copy), a future UI-copy change
// cannot silently reorder the precedence (KFB-5).

/// One notice decision for a single post-final voice fill.
///
/// At most ONE notice fires per final fill, by precedence:
/// conversion-undo (2B) > repair-candidate adopt (1A) > large-amount (1E) >
/// none. Variants carry ONLY numeric payload — the presentation layer maps a
/// variant to localized copy; the precedence itself is copy-independent.
sealed class VoiceAmountNotice {
  const VoiceAmountNotice();
}

/// 2B: a visible, reversible foreign-currency conversion. Undo restores the
/// spoken amount ([spokenAmount]) and clears the currency triple.
class VoiceConversionUndoNotice extends VoiceAmountNotice {
  const VoiceConversionUndoNotice({
    required this.spokenAmount,
    required this.jpy,
    required this.rate,
    required this.currency,
  });

  /// The amount the user spoke (pre-conversion), restored on undo.
  final int spokenAmount;

  /// The converted JPY figure written into the form.
  final int jpy;

  /// The applied exchange rate (as the raw rate string).
  final String rate;

  /// The detected foreign-currency ISO code.
  final String currency;
}

/// 1A: a suspected ITN-concat amount with a one-tap adopt affordance
/// (never silent). [candidate] is the OTHER plausible reading of the amount.
class VoiceRepairAdoptNotice extends VoiceAmountNotice {
  const VoiceRepairAdoptNotice({
    required this.filledAmount,
    required this.candidate,
  });

  /// The amount currently filled into the form.
  final int filledAmount;

  /// The one-tap alternative reading.
  final int candidate;
}

/// 1E: a sanity guardrail — a very large voice-filled amount gets a visible,
/// non-blocking "please double-check" nudge.
class VoiceLargeAmountNotice extends VoiceAmountNotice {
  const VoiceLargeAmountNotice({required this.filledAmount});

  /// The large amount filled into the form.
  final int filledAmount;
}

/// No notice fires for this fill.
class VoiceNoNotice extends VoiceAmountNotice {
  const VoiceNoNotice();
}

/// Pure decision policy for the post-final voice amount notice.
///
/// Encodes the EXACT precedence previously inlined in
/// `_showVoiceAmountNotice`. No string / ARB / locale — the caller maps the
/// returned [VoiceAmountNotice] variant to copy.
class VoiceAmountNoticePolicy {
  const VoiceAmountNoticePolicy();

  /// Returns the single notice (or [VoiceNoNotice]) for a final fill.
  ///
  /// Precedence:
  /// 1. [conversion] present -> [VoiceConversionUndoNotice].
  /// 2. else a valid repair candidate ([repairCandidate] non-null AND the
  ///    filled amount came from [dataAmount] AND the candidate differs) ->
  ///    [VoiceRepairAdoptNotice].
  /// 3. else [filledAmount] >= [largeAmountThreshold] ->
  ///    [VoiceLargeAmountNotice].
  /// 4. else [VoiceNoNotice].
  VoiceAmountNotice decide({
    required ({int jpy, String rate})? conversion,
    required String currency,
    required int filledAmount,
    required int? dataAmount,
    required int? repairCandidate,
    required int largeAmountThreshold,
  }) {
    if (conversion != null) {
      return VoiceConversionUndoNotice(
        spokenAmount: filledAmount,
        jpy: conversion.jpy,
        rate: conversion.rate,
        currency: currency,
      );
    }

    // 1A: suspected ITN-concat amount — suppressed when the filled amount did
    // not come from data.amount (a merger-committed multi-chunk amount makes
    // the candidate meaningless), or when the candidate equals the fill.
    if (repairCandidate != null &&
        filledAmount == dataAmount &&
        repairCandidate != filledAmount) {
      return VoiceRepairAdoptNotice(
        filledAmount: filledAmount,
        candidate: repairCandidate,
      );
    }

    if (filledAmount >= largeAmountThreshold) {
      return VoiceLargeAmountNotice(filledAmount: filledAmount);
    }

    return const VoiceNoNotice();
  }
}
