// lib/features/accounting/presentation/screens/voice_ptt_session_fill_orchestration.dart
//
// voice-consolidation P1-7: the fill-orchestration block of
// [VoicePttSessionMixin], moved out of `voice_ptt_session_mixin.dart` as a
// same-library `part` so every method keeps its private access to the mixin's
// session fields — no renames, no visibility promotion, a byte-faithful move.
// Covers the sound-level / result callbacks, the debounced partial parse, the
// final parse (satisfaction estimation delegated to
// `voice_ptt_session_foreign_notice.dart`), the shared batch-fill path, and
// the chunk-merger rebuild.

part of 'voice_ptt_session_mixin.dart';

extension _VoicePttFillOrchestration<W extends ConsumerStatefulWidget>
    on VoicePttSessionMixin<W> {
  // ── Sound-level / result callbacks (ported verbatim) ───────────────────────

  void _onSoundLevel(double level, int generation) {
    if (!_isPttSessionCurrent(generation)) return;
    final now = DateTime.now();
    if (_lastSampleTime != null &&
        now.difference(_lastSampleTime!).inMilliseconds <
            VoiceTuning.soundLevelThrottle.inMilliseconds) {
      onPttSessionChanged(() => _soundLevel = level);
      return;
    }
    _lastSampleTime = now;
    _soundLevels.add(level);
    _timestamps.add(now);
    onPttSessionChanged(() => _soundLevel = level);
  }

  void _onResult(SpeechRecognitionResult result, int generation) {
    if (!_isPttSessionCurrent(generation)) return;
    final resultRevision = ++_pttResultRevision;

    if (!result.finalResult) {
      _partialResultCount++;
      _lastWordCount = countVoiceWords(result.recognizedWords);
      onPttSessionChanged(() => _partialText = result.recognizedWords);

      _parseDebounce?.cancel();
      _parseDebounce = Timer(VoiceTuning.partialParseDebounce, () {
        if (_isPttResultCurrent(generation, resultRevision) &&
            result.recognizedWords.isNotEmpty) {
          _parseVoiceInput(result.recognizedWords, generation, resultRevision);
        }
      });
    } else {
      final text = result.recognizedWords;
      onPttSessionChanged(() {
        _finalText = text;
        _partialText = '';
        _soundLevel = 0.0;
      });

      _parseDebounce?.cancel();
      if (text.isNotEmpty) {
        _amountMerger?.feedChunk(text, isFinal: true);
        // 260703 BUG-1 (1D): the recognizer's alternate transcripts (the
        // transcription list minus its best entry) ride along so the parse
        // layer can cross-validate a suspected ITN-concat amount — an
        // alternate that independently reads the repaired value auto-adopts
        // the repair.
        final alternateTexts = <String>[
          for (final alt in result.alternates.skip(1))
            if (alt.recognizedWords.isNotEmpty) alt.recognizedWords,
        ];
        // R2/R4: in the continuous tap session, parse ONCE (with satisfaction)
        // and reuse that single result to auto-fill the form live (BUG D dedupe
        // — the prior code parsed `text` here AND again inside _fillFormFromText).
        // The legacy hold path only refreshes _parseResult here; the fill happens
        // on release (still one parse, via the release commit).
        if (_continuousActive) {
          unawaited(
            _parseAndFillContinuousFinal(
              text,
              generation: generation,
              resultRevision: resultRevision,
              alternateTexts: alternateTexts,
            ),
          );
        } else {
          _parseFinalResult(
            text,
            generation: generation,
            resultRevision: resultRevision,
            alternateTexts: alternateTexts,
          );
        }
      }
    }
  }

  /// 260622-nhs R4 (BUG D): the debounced PARTIAL parse now ALSO drives a live
  /// form-fill (continuous session only) so the user sees the entry update as
  /// they speak — sub-second, not after the 3s pauseFor final. Idempotent: the
  /// fill is overwritten by the final fill and revertible by reset (the snapshot
  /// baseline is unchanged). Parses ONCE and reuses the result for both the
  /// `_parseResult` mirror and the fill.
  Future<void> _parseVoiceInput(
    String text,
    int generation,
    int resultRevision,
  ) async {
    if (!_isPttResultCurrent(generation, resultRevision)) return;
    _beginPttParsing(generation);
    try {
      final useCase = ref.read(parseVoiceInputUseCaseProvider);
      final result = await useCase.execute(text, localeId: pttVoiceLocaleId);
      if (!_isPttResultCurrent(generation, resultRevision) ||
          !result.isSuccess) {
        return;
      }
      final data = result.data;
      onPttSessionChanged(() => _parseResult = data);
      if (_continuousActive && data != null) {
        // XVAL-03 / D-01: partial fills amount/text/merchant/date LIVE but holds
        // the category (fillCategory: false) until the first end-of-speech final.
        await _fillFormFromText(
          text,
          data: data,
          fillCategory: false,
          generation: generation,
          resultRevision: resultRevision,
        );
      }
    } finally {
      _endPttParsing(generation);
    }
  }

  /// Keeps the whole final parse→fill chain transient. Some recognizers emit
  /// `done` immediately after the final result; without this outer scope there
  /// was a gap before [_fillFormFromText] set `_parsing`, exposing a saveable
  /// review draft while parsing was still in flight.
  Future<void> _parseAndFillContinuousFinal(
    String text, {
    required int generation,
    required int resultRevision,
    required List<String> alternateTexts,
  }) async {
    if (!_isPttResultCurrent(generation, resultRevision)) return;
    _beginPttParsing(generation);
    try {
      final parsed = await _parseFinalResult(
        text,
        generation: generation,
        resultRevision: resultRevision,
        alternateTexts: alternateTexts,
      );
      if (_isPttResultCurrent(generation, resultRevision) &&
          _continuousActive) {
        await _fillFormFromText(
          text,
          data: parsed,
          generation: generation,
          resultRevision: resultRevision,
        );
      }
    } finally {
      _endPttParsing(generation);
    }
  }

  /// 260622-nhs R4 (BUG D): now RETURNS the resolved parse result so the caller
  /// can reuse it for the form-fill instead of parsing the same text a second
  /// time. Still mirrors `_parseResult` (drives the learning keyword hook /
  /// satisfaction read) as before.
  /// 260703 (1D): [alternateTexts] are threaded into the use case for the
  /// ITN-concat cross-validation.
  Future<VoiceParseResult?> _parseFinalResult(
    String text, {
    required int generation,
    required int resultRevision,
    List<String> alternateTexts = const [],
  }) async {
    if (!_isPttResultCurrent(generation, resultRevision)) return null;
    final useCase = ref.read(parseVoiceInputUseCaseProvider);
    final result = await useCase.execute(
      text,
      localeId: pttVoiceLocaleId,
      alternateTexts: alternateTexts,
    );

    if (!_isPttResultCurrent(generation, resultRevision) || !result.isSuccess) {
      return null;
    }

    var parseResult = result.data;
    if (parseResult == null) return null;

    parseResult = _applyEstimatedSatisfaction(parseResult, text);

    onPttSessionChanged(() => _parseResult = parseResult);
    return parseResult;
  }

  /// 260703 BUG-1 (1D): reuse the already-parsed result when it matches [text]
  /// verbatim — an alternate-confirmed amount repair lives ONLY on that
  /// instance; a re-parse here has no alternates and would resurrect the
  /// poisoned amount. Falls back to null (fresh parse) on any mismatch.
  VoiceParseResult? _cachedParseFor(String text) {
    final cached = _parseResult;
    return (cached != null && cached.rawText == text) ? cached : null;
  }

  /// 260622-nhs R2: parse [text] and batch-fill the embedded form (amount /
  /// category / merchant / date / satisfaction / foreign triple). Extracted
  /// VERBATIM from the prior `stopPttSessionAndCommit` body so BOTH the legacy
  /// hold-release commit AND the new continuous auto-fill (each speech-final)
  /// share one fill path — no parse/merger/foreign/satisfaction fork.
  /// 260622-nhs R4 (BUG D): accepts an optional already-parsed [data] so the
  /// final/partial paths parse ONCE and reuse the result here (the prior code
  /// parsed `text` again inside this method — a redundant second parse). When
  /// [data] is null this still parses [text] itself (legacy hold-release path).
  ///
  /// XVAL-03 / D-01..D-03 (resolve-on-final hysteresis): [fillCategory] gates
  /// ONLY the category write. The partial-driven fill passes `false` so partials
  /// keep filling amount/text/merchant/date LIVE (sub-second feedback, 260622-nhs
  /// R1-R8 unchanged) but hold the category guess until the first end-of-speech
  /// final — eliminating category-chip flicker across partials. The final-result
  /// fill keeps the default `true`, resolving the category exactly once. No new
  /// timer is introduced (D-03): the single isFinal signal drives the one fill.
  Future<void> _fillFormFromText(
    String text, {
    required int generation,
    VoiceParseResult? data,
    bool fillCategory = true,
    int? resultRevision,
  }) async {
    if (!_isPttWorkCurrent(generation, resultRevision) ||
        (text.isEmpty && data == null)) {
      return;
    }

    _beginPttParsing(generation);
    try {
      await _fillFormFromTextInner(
        text,
        generation: generation,
        preParsed: data,
        fillCategory: fillCategory,
        resultRevision: resultRevision,
      );
    } finally {
      _endPttParsing(generation);
    }
  }

  Future<void> _fillFormFromTextInner(
    String text, {
    required int generation,
    VoiceParseResult? preParsed,
    bool fillCategory = true,
    int? resultRevision,
  }) async {
    if (!_isPttWorkCurrent(generation, resultRevision)) return;
    var resolved = preParsed;
    if (resolved == null) {
      if (text.isEmpty) return;
      final parseUseCase = ref.read(parseVoiceInputUseCaseProvider);
      final parseResult = await parseUseCase.execute(
        text,
        localeId: pttVoiceLocaleId,
      );
      if (!_isPttWorkCurrent(generation, resultRevision) ||
          !parseResult.isSuccess) {
        return;
      }
      resolved = parseResult.data;
    }
    if (resolved == null) return;
    final data = resolved;

    // XVAL-03 / D-01..D-03: the category guess is held until the first
    // end-of-speech final. Partial-driven fills pass `fillCategory: false`, so
    // we skip the repo lookup entirely (saves a read) AND never call
    // state.updateCategory — the category chip resolves once, on the final.
    Category? category;
    Category? parent;
    if (fillCategory) {
      // CR-01: auto-stamp the category ONLY from the floor-gated `categoryMatch`
      // (keyword win, or merchant >= 0.85). Do NOT fall back to
      // `data.merchantCategoryId` — it carries the best candidate's category
      // unconditionally (even below the 0.85 floor), so auto-filling it would
      // silently defeat the floor (ADR-012: low-confidence guesses are
      // confirmed/corrected, never auto-committed). Below-floor candidates are
      // surfaced as Phase-52 confidence chips instead.
      final categoryId = data.categoryMatch?.categoryId;
      if (categoryId != null) {
        final repo = ref.read(categoryRepositoryProvider);
        category = await repo.findById(categoryId);
        if (!_isPttWorkCurrent(generation, resultRevision)) return;
        if (category?.parentId != null) {
          parent = await repo.findById(category!.parentId!);
          if (!_isPttWorkCurrent(generation, resultRevision)) return;
        }
      }
    }

    // 260706-saz: the 260703 concat exception and 260706-kzr magnitude
    // exception now live in [AmountArbiter.resolveDisplayAmount] (single
    // arbitration point, voice-consolidation P0-1) — semantics migrated verbatim.
    final amount =
        _amountArbiter.resolveDisplayAmount(
          parsed: data.amount,
          merged: _mergedAmount,
          rawText: data.rawText,
          localeId: pttVoiceLocaleId,
        ) ??
        0;
    if (!_isPttWorkCurrent(generation, resultRevision)) return;
    final state = pttFormState;
    if (state == null) return;

    // quick-260707-kfb (KFB-2): the resolve-on-final gating that used to be
    // scattered `if (fillCategory)` branches now comes from the pure
    // [VoiceFillDecision]. The State only EXECUTES the plan — all async
    // repo/rate IO, `mounted` guards, and `onPttCommitted` stay here. Built
    // after the arbitrated amount so `_mergedAmount`'s read timing is
    // byte-identical to the pre-extraction order.
    final plan = VoiceFillDecision.from(
      fillCategory: fillCategory,
      data: data,
      arbitratedAmount: amount,
    );
    final categoryNeedsSelection =
        plan.pushRecognition &&
        category == null &&
        data.categoryMatch == null &&
        (data.band == ConfidenceBand.weak || data.alternates.isNotEmpty);

    if (plan.writeAmount) {
      state.updateAmount(amount);
      _lastFilledAmount = amount;
    }
    // `category` is only ever non-null when the parse carried a floor-gated
    // categoryMatch on a final fill, so `plan.resolveCategory` is implied —
    // the guard keeps the actual write conditioned on the repo lookup result.
    if (categoryNeedsSelection) {
      state.restoreCategory(null, null);
      onPttCategoryNeedsSelection();
    } else if (plan.resolveCategory && category != null) {
      state.updateCategory(category, parent);
    }
    // Phase 52 (RECUX-01/02 / D-08): push the recognition surface (confidence
    // band + ranked alternates) at resolve-on-final ONLY — the same single
    // isFinal fill that resolves the category. Partial-driven fills pass
    // `fillCategory: false` and never reach here, so the band/chips resolve
    // exactly once (no flicker on partials). Null band on a manual/OCR VPR
    // leaves the form's no-affordance state intact (D-10).
    if (plan.pushRecognition) {
      state.updateRecognition(data.band, data.alternates);
    }
    if (data.merchantName != null && data.merchantName!.isNotEmpty) {
      state.updateMerchant(data.merchantName!);
    }
    if (data.parsedDate != null) state.updateDate(data.parsedDate!);
    if (_parseResult?.estimatedSatisfaction != null) {
      state.updateSatisfaction(_parseResult!.estimatedSatisfaction);
    }

    // 260703 BUG-2 (2C): the conversion — and every amount notice — runs ONLY
    // on the resolve-on-final fill, the same gate as the category (XVAL-03).
    // Partial-driven fills previously re-fetched the rate every ~300ms and
    // bounced the amount between raw and converted figures mid-utterance.
    if (plan.runNotice) {
      var nextCurrency = 'JPY';
      ({int jpy, String rate})? conversion;
      final detectedCurrency = data.detectedCurrency;
      if (plan.attemptConversion) {
        conversion = await pushVoiceForeignTriple(
          state: state,
          currency: detectedCurrency!,
          wholeUnitAmount: amount,
          date: data.parsedDate ?? DateTime.now(),
          generation: generation,
          resultRevision: resultRevision,
        );
        if (conversion != null) nextCurrency = detectedCurrency;
      }
      if (!_isPttWorkCurrent(generation, resultRevision)) return;
      onPttSessionChanged(() {
        _displayCurrency = nextCurrency;
      });
      _showVoiceAmountNotice(
        state: state,
        data: data,
        filledAmount: amount,
        conversion: conversion,
        currency: nextCurrency,
      );
    }
    // Provenance hook: a PTT fill happened — host stamps EntrySource.voice.
    if (_isPttWorkCurrent(generation, resultRevision)) onPttCommitted();
  }

  /// Rebuild the chunk merger (used by [resetPttSessionAndRestart]) so a reset
  /// re-accumulates the amount from a clean baseline. Mirrors the merger setup
  /// in [startPttSession] (same parser selection + onAmountResolved hook).
  void _rebuildAmountMerger(int generation) {
    _amountMerger?.dispose();
    final speechService = ref.read(appSpeechRecognitionServiceProvider);
    final parser = pttVoiceLocaleId.startsWith('ja')
        ? ref.read(japaneseNumeralStateMachineProvider)
        : ref.read(chineseNumeralStateMachineProvider);
    // 260703 BUG-1 (1E): commits go through the full parser routing (via
    // [AmountArbiter.extractAmount]) so a comma-grouped final (「2,546元」)
    // keeps its leading groups — the bare state machine would drop the comma
    // and read only the tail (546).
    _amountMerger = VoiceChunkMerger(
      parser: parser,
      speechService: speechService,
      amountExtractor: (text) =>
          _amountArbiter.extractAmount(text, localeId: pttVoiceLocaleId),
      onAmountResolved: (amount) {
        if (!_isPttSessionCurrent(generation)) return;
        onPttSessionChanged(() => _mergedAmount = amount);
      },
    );
  }
}
