// lib/features/accounting/presentation/screens/manual_one_step_voice_wiring.dart
//
// voice-consolidation P1-7 (R2): the voice wiring segment of
// `_ManualOneStepScreenState`, moved out of `manual_one_step_screen.dart` as a
// same-library `part` (the host State class is private, so a part is the only
// split that keeps zero renames and zero visibility promotion). Covers the
// hold-to-record voice lifecycle, the PTT-commit keypad mirror, and the
// inline voice panel builder — verbatim moves. The keypad / currency / save /
// foreign-triple segments stay in the main file untouched.
//
// ONE sanctioned rewrite: the moved `setState(...)` calls became
// `onPttSessionChanged(...)` — `setState` is `@protected`, and an extension
// member is not a subclass instance member, so the analyzer rejects the
// verbatim call. `onPttSessionChanged` is the class's OWN public repaint hook
// (its body is exactly `if (mounted) setState(apply)`), so the substitution
// is behavior-identical; every call site here runs from a tap handler or
// behind an explicit `mounted` guard.

part of 'manual_one_step_screen.dart';

extension _ManualOneStepVoiceWiring on _ManualOneStepScreenState {
  // ── 260622-nhs R2: hold-to-record voice lifecycle ────────────────────

  /// Tap 「语音记录」: snapshot the form (D-2 reset-restore) and open the voice
  /// dock in its explicit idle state. Recognition starts only when the user
  /// holds the dock's central microphone.
  void _onVoiceRecordTap() {
    if (_voiceModalOpen || _isSubmitting) return;
    // speech_to_text requests iOS microphone / speech-recognition permissions
    // during initialize(). Keep that request attached to this explicit user
    // action instead of presenting it as soon as manual entry opens.
    if (!pttServiceInitialized) {
      unawaited(initPttSpeechService());
    }
    _voiceCoreHeld = false;
    final form = _formKey.currentState;
    if (form != null) {
      _voiceSnapshot = ManualEntrySnapshot.capture(
        amountText: _amount,
        currency: _currency,
        manualForeignRate: _manualForeignRate,
        lastFillWasVoice: _lastFillWasVoice,
        form: form,
      );
    }
    // Panel visibility stays independent of the recognizer lifecycle. Entering
    // voice mode never opens the microphone by itself.
    onPttSessionChanged(() {
      _voiceModalOpen = true;
      _voiceIdleForNext = true;
    });
  }

  Future<void> _onVoiceKeyboard() async {
    if (_isSubmitting) return;
    _voiceCoreHeld = false;
    final shouldRestore =
        _voiceDockState == UnifiedVoiceEntryState.listening ||
        _voiceDockState == UnifiedVoiceEntryState.processing;
    // Always invalidate/cancel, including review: a review→re-record reset may
    // still be awaiting its first cancel and must not reopen the microphone
    // after this dock closes.
    await cancelPttSessionAndDiscard();
    if (shouldRestore) _restoreVoiceSnapshot();
    if (!mounted) return;
    onPttSessionChanged(() {
      _voiceModalOpen = false;
      _voiceIdleForNext = false;
    });
    _voiceSnapshot = null;
  }

  void _onVoiceCore() {
    if (_isSubmitting) return;
    switch (_voiceDockState) {
      case UnifiedVoiceEntryState.idle:
      case UnifiedVoiceEntryState.review:
        _onVoiceCoreHoldStart();
      case UnifiedVoiceEntryState.listening:
        _onVoiceCoreHoldEnd();
      case UnifiedVoiceEntryState.processing:
      case UnifiedVoiceEntryState.unavailable:
        return;
    }
  }

  void _onVoiceCoreHoldStart() {
    if (_isSubmitting || _voiceCoreHeld) return;
    final state = _voiceDockState;
    if (state != UnifiedVoiceEntryState.idle &&
        state != UnifiedVoiceEntryState.review) {
      return;
    }
    _voiceCoreHeld = true;
    if (state == UnifiedVoiceEntryState.review) {
      unawaited(_prepareVoiceRerecordHold());
      return;
    }
    _beginVoiceReleaseControlledHold();
  }

  Future<void> _prepareVoiceRerecordHold() async {
    onPttSessionChanged(() => _voiceRerecordPreparing = true);
    try {
      _restoreVoiceSnapshot();
      // A full cancel clears the platform recognizer's previous utterance buffer
      // before the next hold starts, preventing old words from resurfacing.
      await cancelPttSessionAndDiscard();
      if (!mounted || !_voiceModalOpen || !_voiceCoreHeld) return;
      _beginVoiceReleaseControlledHold();
    } finally {
      if (mounted) {
        onPttSessionChanged(() => _voiceRerecordPreparing = false);
      }
    }
  }

  void _beginVoiceReleaseControlledHold() {
    if (!_voiceCoreHeld || !_voiceModalOpen) return;
    onPttSessionChanged(() => _voiceIdleForNext = false);
    onPttReleaseHoldStart();
  }

  void _onVoiceCoreHoldEnd() {
    if (!_voiceCoreHeld) return;
    _voiceCoreHeld = false;
    onPttReleaseHoldEnd();
  }

  void _onVoiceCoreHoldCancel() {
    if (!_voiceCoreHeld) return;
    _voiceCoreHeld = false;
    onPttReleaseHoldCancel();
  }

  void _restoreVoiceSnapshot() {
    final snapshot = _voiceSnapshot;
    final form = _formKey.currentState;
    if (snapshot == null || form == null) return;
    snapshot.restoreForm(form);
    form.discardPendingCorrection();
    onPttSessionChanged(() {
      _currency = snapshot.currency;
      _amount = snapshot.restoreHostAmount(_controller);
      _manualForeignRate = snapshot.manualForeignRate;
      _lastFillWasVoice = snapshot.lastFillWasVoice;
      _selectedCategory = snapshot.category;
      _selectedParentCategory = snapshot.parentCategory;
    });
  }

  /// 260622-nhs (T-nhs-03) / voice-consolidation P1-7 (R2): the PTT-commit
  /// keypad mirror — the body of the host's [onPttCommitted] override, moved
  /// verbatim (the `@override` itself stays in the class as a one-line
  /// delegate; overrides cannot live in an extension).
  void _mirrorPttFillIntoKeypad() {
    if (!mounted) return;
    // A PTT fill happened — the session mixin already pushed amount / category /
    // merchant / date / satisfaction (+ foreign triple) into _formKey's state.
    // For an explicit foreign utterance, mirror the ORIGINAL currency + amount
    // into the headline/keypad so the normal foreign-rate card mounts and shows
    // the already-resolved conversion. The form keeps the booked JPY amount and
    // foreign triple written by the mixin; do not re-drive _syncAmountToForm.
    final form = _formKey.currentState;
    final displayCurrency = pttDisplayCurrency.toUpperCase();
    final originalCurrency = form?.currentOriginalCurrency?.toUpperCase();
    final originalMinorUnits = form?.currentOriginalAmount;
    final hasForeignTriple =
        displayCurrency != 'JPY' &&
        originalCurrency == displayCurrency &&
        originalMinorUnits != null &&
        originalMinorUnits > 0;
    final nextCurrency = hasForeignTriple ? displayCurrency : 'JPY';
    final nextAmount = hasForeignTriple
        ? formatMinorAsMajor(originalMinorUnits, displayCurrency)
        : pttLastFilledAmount > 0
        ? pttLastFilledAmount.toString()
        : '';

    if (hasForeignTriple) {
      ref.read(recentCurrencyProvider.notifier).recordUse(displayCurrency);
    }
    onPttSessionChanged(() {
      _lastFillWasVoice = true;
      if (nextAmount.isNotEmpty) {
        _currency = nextCurrency;
        _manualForeignRate = null;
        _replaceVoiceAmountInController(nextAmount, nextCurrency);
        _amount = nextAmount;
      }
    });
  }

  void _replaceVoiceAmountInController(String amount, String currency) {
    _controller.onCurrencyChange(currencyFractionDigitsFor(currency));
    while (_controller.text.isNotEmpty) {
      _controller.onDelete();
    }
    for (final character in amount.split('')) {
      if (character == '.') {
        _controller.onDot();
      } else {
        _controller.onDigit(character);
      }
    }
  }

  /// voice-consolidation P1-7 (R2): the inline voice panel builder — the
  /// `VoiceRecordPanel` construction from `build`'s bottom-slot ternary, moved
  /// verbatim (the ternary now calls this).
  UnifiedVoiceEntryState get _voiceDockState {
    if (!pttServiceInitialized || !isLocaleReady) {
      return UnifiedVoiceEntryState.unavailable;
    }
    if (_voiceIdleForNext) return UnifiedVoiceEntryState.idle;
    if (_voiceRerecordPreparing) return UnifiedVoiceEntryState.processing;
    return switch (pttListenStatus) {
      PttListenStatus.listening => UnifiedVoiceEntryState.listening,
      PttListenStatus.processing => UnifiedVoiceEntryState.processing,
      PttListenStatus.stopped =>
        pttTranscript.trim().isEmpty
            ? UnifiedVoiceEntryState.idle
            : UnifiedVoiceEntryState.review,
    };
  }

  Widget _buildVoicePanel() {
    final l10n = S.of(context);
    final state = _voiceDockState;
    final status = switch (state) {
      UnifiedVoiceEntryState.idle => l10n.entryVoiceIdleStatus,
      UnifiedVoiceEntryState.listening => l10n.entryVoiceListeningStatus,
      UnifiedVoiceEntryState.processing => l10n.entryVoiceProcessingStatus,
      UnifiedVoiceEntryState.review => l10n.entryVoiceReviewStatus,
      UnifiedVoiceEntryState.unavailable => l10n.entryVoiceUnavailableStatus,
    };
    // The transcript line is reserved for actual recognizer output. Status,
    // permission, and usage guidance already have dedicated header/help rows.
    final transcript = pttTranscript.trim();
    final help = switch (state) {
      UnifiedVoiceEntryState.idle => l10n.entryVoiceIdleHelp,
      UnifiedVoiceEntryState.listening => l10n.entryVoiceListeningHelp,
      UnifiedVoiceEntryState.processing => l10n.entryVoiceProcessingHelp,
      UnifiedVoiceEntryState.review => l10n.entryVoiceReviewHelp,
      UnifiedVoiceEntryState.unavailable => l10n.entryVoiceUnavailableHelp,
    };
    final coreSemanticLabel = switch (state) {
      UnifiedVoiceEntryState.idle => l10n.entryVoiceStartAction,
      UnifiedVoiceEntryState.listening => l10n.entryVoiceStopAction,
      UnifiedVoiceEntryState.processing => l10n.entryVoiceProcessingStatus,
      UnifiedVoiceEntryState.review => l10n.entryVoiceRerecordAction,
      UnifiedVoiceEntryState.unavailable => l10n.entryVoiceUnavailableStatus,
    };

    return UnifiedVoiceEntryDock(
      state: state,
      copy: UnifiedVoiceEntryCopy(
        privacy: l10n.entryVoicePrivacy,
        status: status,
        transcript: transcript,
        help: help,
        keyboardSemanticLabel: l10n.entryVoiceKeyboardAction,
        coreSemanticLabel: coreSemanticLabel,
        primaryAction: l10n.record,
        settingsAction: l10n.shoppingVoiceSettingsAction,
        continuousSummary: _continuousMode
            ? l10n.entryContinuousKeepNext
            : l10n.entryContinuousReturnHome,
        continuousAction: _continuousMode
            ? l10n.entryContinuousDisable
            : l10n.entryContinuousEnable,
      ),
      soundLevel: pttSoundLevel,
      continuousMode: _continuousMode,
      isSubmitting: _isSubmitting || _isVoiceDraftTransient || !_canSave,
      onKeyboard: _onVoiceKeyboard,
      onCore: _onVoiceCore,
      onCoreHoldStart: _onVoiceCoreHoldStart,
      onCoreHoldEnd: _onVoiceCoreHoldEnd,
      onCoreHoldCancel: _onVoiceCoreHoldCancel,
      onPrimary: _trySave,
      onSettings: () {
        showErrorFeedback(context, l10n.entryVoiceUnavailableHelp);
      },
      onToggleContinuous: () {
        if (_isSubmitting) return;
        onPttSessionChanged(() => _continuousMode = !_continuousMode);
      },
    );
  }
}
