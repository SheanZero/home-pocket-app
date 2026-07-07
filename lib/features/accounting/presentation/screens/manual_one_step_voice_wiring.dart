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
    if (!pttServiceInitialized || !isLocaleReady || _voiceModalOpen) return;
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
    onPttSessionChanged(() => _voiceModalOpen = true);
    startPttTapSession();
  }

  /// Tap the modal/scrim: stop listening + final fill + close, keep content.
  void _onVoiceModalExit() {
    exitPttTapSession();
    onPttSessionChanged(() => _voiceModalOpen = false);
    _voiceSnapshot = null;
  }

  /// 「重置·恢复账目」: restore the form to the pre-speech snapshot, clear the
  /// transcript/merger/parse buffers, and KEEP listening (the user can re-speak).
  void _onVoiceReset() {
    final snapshot = _voiceSnapshot;
    final form = _formKey.currentState;
    if (snapshot != null && form != null) {
      snapshot.restoreForm(form);
      // Phase 52 (RECUX-03 / D-05): a 「重置·恢复账目」 reset abandons the
      // current draft — discard any pending category correction with NO write
      // (restoreForm clears it only when the snapshot had a category).
      form.discardPendingCorrection();
      onPttSessionChanged(() {
        _currency = snapshot.currency;
        _amount = snapshot.restoreHostAmount(_controller);
        _manualForeignRate = snapshot.manualForeignRate;
        // Revert provenance: if the snapshot was a pure-manual slate, drop the
        // voice flag so a later keypad save stays manual (T-nhs-03).
        _lastFillWasVoice = snapshot.lastFillWasVoice;
      });
    }
    // 260622-nhs R4 (BUG A + BUG B): a reset must CANCEL the recognizer (to
    // clear its accumulated in-window buffer — the R3 buffer-only clear left the
    // iOS recognizer's prior transcript alive, so the next partial re-surfaced
    // the old text) and start a FRESH serialized listening session (the cancel→
    // start is guarded so onStatus can't double-start into a freeze).
    resetPttSessionAndRestart();
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
  Widget _buildVoicePanel() {
    return VoiceRecordPanel(
      transcript: pttTranscript,
      soundLevel: pttSoundLevel,
      // 260622-nhs R4 (BUG C): live recognizer status drives
      // the panel title + pulse-dot colour.
      status: pttListenStatus,
      onExit: _onVoiceModalExit,
      onReset: _onVoiceReset,
    );
  }
}
