// lib/features/accounting/presentation/screens/voice_ptt_session_foreign_notice.dart
//
// voice-consolidation P1-7: the foreign-currency + amount-notice +
// satisfaction block of [VoicePttSessionMixin], moved out of
// `voice_ptt_session_mixin.dart` as a same-library `part` — no renames, no
// visibility promotion, a byte-faithful move. The extension is PUBLIC so
// [pushVoiceForeignTriple] keeps its public callable surface.

part of 'voice_ptt_session_mixin.dart';

/// Foreign-currency triple push, post-final amount notices, and the joy-branch
/// satisfaction estimation for [VoicePttSessionMixin] (voice-consolidation
/// P1-7 split; public so [pushVoiceForeignTriple] stays externally callable).
extension VoicePttForeignNotice<W extends ConsumerStatefulWidget>
    on VoicePttSessionMixin<W> {
  // ── Foreign triple (ported from _pushVoiceForeignTriple) ────────────────────

  /// Pushes the foreign-currency triple + converted JPY amount into [state].
  ///
  /// 260703 (2B): returns the conversion outcome — the converted JPY figure and
  /// the applied rate — so the caller can surface a visible, undoable notice.
  /// Null means the triple was NOT pushed (non-positive amount, rate
  /// unavailable, or any error): the JPY-native path stays untouched.
  Future<({int jpy, String rate})?> pushVoiceForeignTriple({
    required TransactionDetailsFormState state,
    required String currency,
    required int wholeUnitAmount,
    required DateTime date,
  }) async {
    final minorUnits = wholeUnitAmount * subunitToUnitFor(currency);
    if (minorUnits <= 0) return null;
    try {
      final useCase = ref.read(appGetExchangeRateUseCaseProvider);
      final withSignal = await useCase.execute(
        GetExchangeRateParams(currency: currency, date: date),
      );
      if (!mounted) return null;
      final rate = _extractRate(withSignal.result);
      if (rate == null) {
        return null;
      }
      final jpy = convertToJpy(
        originalMinorUnits: minorUnits,
        appliedRate: rate,
        subunitToUnit: subunitToUnitFor(currency),
      );
      state.updateAmount(jpy);
      _lastFilledAmount = jpy;
      state.updateCurrencyTriple(
        originalCurrency: currency,
        originalAmount: minorUnits,
        appliedRate: rate,
      );
      return (jpy: jpy, rate: rate);
    } catch (_) {
      return null;
    }
  }

  String? _extractRate(RateResult result) => switch (result) {
    RateFetched(:final rate) => rate,
    RateCached(:final rate) => rate,
    RateFallback(:final rate) => rate,
    RateManual(:final rate) => rate,
    RateUnavailable() => null,
  };

  // ── 260703 (2B/1A/1E): post-final amount notices ────────────────────────────

  /// Shows AT MOST ONE notice per final fill, by precedence:
  /// conversion-undo (2B) > repair-candidate adopt (1A) > large-amount (1E).
  ///
  /// quick-260707-kfb (KFB-2/KFB-5): the PRECEDENCE now lives in the pure
  /// [VoiceAmountNoticePolicy] — this part only maps the returned variant to
  /// ARB copy + SnackBar side effects. All copy comes from ARB; amounts go
  /// through [NumberFormatter] with the ambient locale. Notices are
  /// informational or one-tap — the fill itself never silently rewrites what
  /// was recognized.
  void _showVoiceAmountNotice({
    required TransactionDetailsFormState state,
    required VoiceParseResult data,
    required int filledAmount,
    required ({int jpy, String rate})? conversion,
    required String currency,
  }) {
    if (!mounted) return;
    final l10n = S.of(context);
    final locale = Localizations.localeOf(context);
    String jpy(int v) => NumberFormatter.formatCurrency(v, 'JPY', locale);

    final notice = const VoiceAmountNoticePolicy().decide(
      conversion: conversion,
      currency: currency,
      filledAmount: filledAmount,
      dataAmount: data.amount,
      repairCandidate: data.amountRepairCandidate,
      largeAmountThreshold: kVoiceLargeAmountNoticeThreshold,
    );

    switch (notice) {
      case VoiceConversionUndoNotice(
        :final spokenAmount,
        jpy: final convertedJpy,
        :final rate,
        currency: final noticeCurrency,
      ):
        // 2B: the conversion is visible and reversible. Undo restores the
        // spoken amount and clears the triple back to a JPY-native row.
        _showVoiceSnackBar(
          message: l10n.voiceCurrencyConverted(
            NumberFormatter.formatCurrency(
              spokenAmount,
              noticeCurrency,
              locale,
              trimWholeFraction: true,
            ),
            jpy(convertedJpy),
            rate,
          ),
          actionLabel: l10n.voiceCurrencyConvertedUndo,
          onAction: () {
            state.updateAmount(spokenAmount);
            state.updateCurrencyTriple(
              originalCurrency: null,
              originalAmount: null,
              appliedRate: null,
            );
            _lastFilledAmount = spokenAmount;
            if (mounted) {
              onPttSessionChanged(() => _displayCurrency = 'JPY');
            }
          },
        );
      case VoiceRepairAdoptNotice(
        filledAmount: final shownAmount,
        :final candidate,
      ):
        // 1A: suspected ITN-concat amount — one-tap adopt, never silent.
        _showVoiceSnackBar(
          message: l10n.voiceAmountRepairSuspect(
            jpy(shownAmount),
            jpy(candidate),
          ),
          actionLabel: l10n.voiceAmountRepairApply(jpy(candidate)),
          onAction: () {
            state.updateAmount(candidate);
            _lastFilledAmount = candidate;
            if (mounted) onPttSessionChanged(() {});
          },
        );
      case VoiceLargeAmountNotice(filledAmount: final shownAmount):
        // 1E: sanity guardrail — a very large voice-filled amount gets a
        // visible "please double-check" nudge (non-blocking; still editable).
        _showVoiceSnackBar(
          message: l10n.voiceLargeAmountNotice(jpy(shownAmount)),
        );
      case VoiceNoNotice():
        break;
    }
  }

  void _showVoiceSnackBar({
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          action: (actionLabel != null && onAction != null)
              ? SnackBarAction(label: actionLabel, onPressed: onAction)
              : null,
        ),
      );
  }

  /// voice-consolidation P1-7: the joy-branch satisfaction estimation, moved
  /// verbatim out of `_parseFinalResult` (fill-orchestration part). Non-joy
  /// results pass through untouched.
  VoiceParseResult _applyEstimatedSatisfaction(
    VoiceParseResult parseResult,
    String text,
  ) {
    if (parseResult.ledgerType == LedgerType.joy) {
      final features = buildVoiceAudioFeatures(
        soundLevels: _soundLevels,
        timestamps: _timestamps,
        startTime: _startTime,
        partialResultCount: _partialResultCount,
        wordCount: _lastWordCount,
      );
      final estimator = ref.read(voiceSatisfactionEstimatorProvider);
      final satisfaction = estimator.estimate(
        audioFeatures: features,
        recognizedText: text,
      );
      parseResult = parseResult.copyWith(estimatedSatisfaction: satisfaction);
    }
    return parseResult;
  }
}
