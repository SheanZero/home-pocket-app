// lib/application/voice/voice_fill_decision.dart
//
// quick-260707-kfb (KFB-2): the resolve-on-final GATING for a voice form fill,
// extracted from the scattered `if (fillCategory)` branches in
// `VoicePttSessionMixin._fillFormFromTextInner`
// (voice_ptt_session_fill_orchestration.dart) into a pure "fill plan".
//
// Placement rationale (CLAUDE.md placement rule): resolve-on-final ordering is
// business logic, not a domain model or repository interface — so it lives in
// `lib/application/{domain}/`, co-located with the pure `AmountArbiter`. It
// imports ONLY Dart core + the `VoiceParseResult` domain model
// (application -> domain is a legal dependency direction). It has ZERO Flutter,
// ZERO widget/State/BuildContext imports, and never touches a State: it only
// DECIDES. The State executes the plan — all async repo/rate IO, `mounted`
// guards, `pttFormState` null-guards, and the final `onPttCommitted` stay in
// the State part.

import '../../features/voice/domain/models/voice_parse_result.dart';

/// A pure "fill plan" for one voice form fill.
///
/// XVAL-03 / D-01..D-03 hysteresis: [runNotice]/[resolveCategory]/
/// [pushRecognition]/[attemptConversion] are all gated by the caller's
/// `fillCategory` (partial-driven fills pass `false` to hold the category and
/// the recognition surface until the first end-of-speech final). [writeAmount]
/// follows the arbitrated amount alone (partials fill amount LIVE).
class VoiceFillDecision {
  const VoiceFillDecision({
    required this.writeAmount,
    required this.resolveCategory,
    required this.pushRecognition,
    required this.attemptConversion,
    required this.runNotice,
  });

  /// Builds the plan from the fill inputs. [arbitratedAmount] is the already
  /// resolved display amount (via `AmountArbiter.resolveDisplayAmount`, `?? 0`).
  factory VoiceFillDecision.from({
    required bool fillCategory,
    required VoiceParseResult data,
    required int arbitratedAmount,
  }) {
    final hasCategory = data.categoryMatch?.categoryId != null;
    final detectedCurrency = data.detectedCurrency;
    final hasCurrency = detectedCurrency != null && detectedCurrency.isNotEmpty;
    return VoiceFillDecision(
      writeAmount: arbitratedAmount > 0,
      resolveCategory: fillCategory && hasCategory,
      pushRecognition: fillCategory,
      attemptConversion: fillCategory && arbitratedAmount > 0 && hasCurrency,
      runNotice: fillCategory,
    );
  }

  /// Write the arbitrated amount into the form (amount > 0).
  final bool writeAmount;

  /// Resolve (repo lookup) + write the floor-gated category. True only on a
  /// final fill AND when the parse carries a floor-gated `categoryMatch`.
  final bool resolveCategory;

  /// Push the recognition surface (confidence band + ranked alternates). Final
  /// fills only — partials never flicker the band/chips.
  final bool pushRecognition;

  /// Attempt a foreign-currency conversion (fetch rate + push the triple).
  /// Final fills only, when an amount and a detected currency are present.
  final bool attemptConversion;

  /// Run the post-final amount notice (conversion-undo / repair / large-amount).
  /// Final fills only.
  final bool runNotice;
}
