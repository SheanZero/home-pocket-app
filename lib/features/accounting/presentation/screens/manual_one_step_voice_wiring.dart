// lib/features/accounting/presentation/screens/manual_one_step_voice_wiring.dart
//
// voice-consolidation P1-7 (R2): the voice wiring segment of
// `_ManualOneStepScreenState`, moved out of `manual_one_step_screen.dart` as a
// same-library `part` (the host State class is private, so a part is the only
// split that keeps zero renames and zero visibility promotion). Covers the
// tap-modal voice-record lifecycle, the PTT-commit keypad mirror, and the
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
  // ── 260622-nhs R2: tap-modal voice-record lifecycle ───────────────────────

  /// Tap 「语音记录」: snapshot the form (D-2 reset-restore), then start a
  /// continuous auto-fill listening session and raise the modal.
  void _onVoiceRecordTap() {
    if (_voiceModalOpen || _isSubmitting) return;
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
    // 260622-nhs R6 (BUG 1): open the modal (panel visibility) independent of
    // the recognizer lifecycle, then start the one-shot listening session.
    onPttSessionChanged(() {
      _voiceModalOpen = true;
      _voiceIdleForNext = false;
    });
    if (pttServiceInitialized && isLocaleReady) {
      unawaited(startPttTapSession());
    }
  }

  Future<void> _onVoiceKeyboard() async {
    if (_isSubmitting) return;
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

  Future<void> _onVoiceCore() async {
    if (_isSubmitting) return;
    switch (_voiceDockState) {
      case UnifiedVoiceEntryState.idle:
        onPttSessionChanged(() => _voiceIdleForNext = false);
        await startPttTapSession();
      case UnifiedVoiceEntryState.listening:
        await exitPttTapSession();
      case UnifiedVoiceEntryState.review:
        await _onVoiceReset();
      case UnifiedVoiceEntryState.processing:
      case UnifiedVoiceEntryState.unavailable:
        return;
    }
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

  /// 「重置·恢复账目」: restore the form to the pre-speech snapshot, clear the
  /// transcript/merger/parse buffers, and KEEP listening (the user can re-speak).
  Future<void> _onVoiceReset() async {
    _restoreVoiceSnapshot();
    // 260622-nhs R4 (BUG A + BUG B): a reset must CANCEL the recognizer (to
    // clear its accumulated in-window buffer — the R3 buffer-only clear left the
    // iOS recognizer's prior transcript alive, so the next partial re-surfaced
    // the old text) and start a FRESH serialized listening session (the cancel→
    // start is guarded so onStatus can't double-start into a freeze).
    await resetPttSessionAndRestart();
  }

  /// 260622-nhs (T-nhs-03) / voice-consolidation P1-7 (R2): the PTT-commit
  /// keypad mirror — the body of the host's [onPttCommitted] override, moved
  /// verbatim (the `@override` itself stays in the class as a one-line
  /// delegate; overrides cannot live in an extension).
  void _mirrorPttFillIntoKeypad() {
    if (!mounted) return;
    // A PTT fill happened — the session mixin already pushed amount / category /
    // merchant / date / satisfaction (+ foreign triple) into _formKey's state.
    // Mirror the booked JPY amount into AmountDisplay's string + the keypad
    // controller so an edit continues from the fill, and flip provenance to
    // voice so the saved row stamps EntrySource.voice (T-nhs-03). Keep the
    // keypad on the JPY native path: the form already carries the real foreign
    // triple for the save, so the headline shows the booked JPY figure (mirrors
    // the legacy voice screen, D-4) without re-driving _syncAmountToForm.
    onPttSessionChanged(() {
      _lastFillWasVoice = true;
      final filled = pttLastFilledAmount;
      if (filled > 0) {
        while (_controller.text.isNotEmpty) {
          _controller.onDelete();
        }
        for (final ch in filled.toString().split('')) {
          _controller.onDigit(ch);
        }
        _amount = _controller.text;
      }
    });
  }

  /// voice-consolidation P1-7 (R2): the inline voice panel builder — the
  /// `VoiceRecordPanel` construction from `build`'s bottom-slot ternary, moved
  /// verbatim (the ternary now calls this).
  UnifiedVoiceEntryState get _voiceDockState {
    if (!pttServiceInitialized || !isLocaleReady) {
      return UnifiedVoiceEntryState.unavailable;
    }
    if (_voiceIdleForNext) return UnifiedVoiceEntryState.idle;
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
    final fallbackTranscript = switch (state) {
      UnifiedVoiceEntryState.idle => l10n.entryVoiceIdleTranscript,
      UnifiedVoiceEntryState.listening => l10n.entryVoiceListeningPlaceholder,
      UnifiedVoiceEntryState.processing => l10n.entryVoiceProcessingPlaceholder,
      UnifiedVoiceEntryState.review => l10n.entryVoiceProcessingPlaceholder,
      UnifiedVoiceEntryState.unavailable =>
        l10n.voiceMicrophonePermissionRequired,
    };
    final transcript = pttTranscript.trim().isEmpty
        ? fallbackTranscript
        : pttTranscript;
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
