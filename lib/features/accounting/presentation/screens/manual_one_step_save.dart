// lib/features/accounting/presentation/screens/manual_one_step_save.dart
//
// quick-260707-kfb A2: the save segment of `_ManualOneStepScreenState`, moved
// out of `manual_one_step_screen.dart` as a same-library `part` — no renames, no
// visibility promotion, a byte-faithful move. Covers the save guard, the core
// save handler, and the continuous-entry reset.
//
// ONE sanctioned rewrite (mirrors the `manual_one_step_voice_wiring.dart`
// precedent): the moved `setState(...)` calls became `_rebuild(...)` (whose body
// is exactly `if (mounted) setState(apply)`), because `setState` is `@protected`
// and cannot be called from an extension.

part of 'manual_one_step_screen.dart';

extension _ManualOneStepSave on _ManualOneStepScreenState {
  // ── Save path ──

  /// P19-W1: short-circuits with a top error toast when category hasn't loaded
  /// yet or the amount is empty/zero. Both SmartKeyboard.onNext and
  /// KeyboardToolbar.onSave point here.
  Future<void> _trySave() async {
    // 260603-nr1 #1: reject empty / zero amount before any save attempt.
    if (_amount.isEmpty || (double.tryParse(_amount) ?? 0) <= 0) {
      showErrorFeedback(context, S.of(context).pleaseEnterAmount);
      return;
    }
    if (!_canSave) {
      if (_selectedCategory == null) {
        showErrorFeedback(context, S.of(context).pleaseSelectCategory);
      }
      return;
    }
    await _save();
  }

  /// Core save handler — delegates to the embedded form's submit().
  /// Ported from transaction_confirm_screen.dart:55-81.
  ///
  /// WR-01: try/finally ensures _isSubmitting is always reset even if
  /// submit() throws an unexpected exception, preventing a permanent
  /// disabled-save-button deadlock.
  Future<void> _save() async {
    if (_isSubmitting) return;
    _rebuild(() => _isSubmitting = true);
    try {
      final result = await _formKey.currentState!.submit();
      if (!mounted) return;
      result.when(
        success: (_) {
          // 260614-iww: branch on continuousMode.
          if (widget.continuousMode) {
            // Continuous (FAB long-press) entry: keep the page open, show a
            // longer-lived warm "keep going" toast with an inline exit link
            // that returns ONCE to the page before recording, then reset the
            // form in place for the next entry.
            showSuccessFeedback(
              context,
              S.of(context).continuousKeepGoing,
              duration: const Duration(seconds: 5),
              actionLabel: S.of(context).recordingExitLink,
              onAction: () {
                if (!mounted) return;
                Navigator.of(context).pop();
              },
            );
            _resetForContinuousEntry();
          } else {
            // Single-tap entry: show a warm "recorded" toast then pop back to
            // the previous page (no form reset — the screen is closing).
            showSuccessFeedback(context, S.of(context).entrySavedDone);
            Navigator.of(context).pop();
          }
        },
        validationError: (msg) {
          showErrorFeedback(context, msg);
        },
        persistError: (msg) {
          showErrorFeedback(context, msg);
        },
      );
    } finally {
      if (mounted) _rebuild(() => _isSubmitting = false);
    }
  }

  /// 260603-nr1 #1: reset the form in place after a successful save so the user
  /// can keep entering without the page closing. Clears the amount (mirrors
  /// [_onClear]), resets merchant/note, resets the date to today, re-seeds the
  /// default category, and reclaims amount focus so the SmartKeyboard reappears.
  Future<void> _resetForContinuousEntry() async {
    if (!mounted) return;
    _rebuild(() {
      // Clear the controller text (mirrors _onClear) and reset to JPY so the
      // next entry starts on the CURR-04 native path.
      while (_controller.text.isNotEmpty) {
        _controller.onDelete();
      }
      _currency = 'JPY';
      _controller.onCurrencyChange(currencyFractionDigitsFor(_currency));
      _amount = '';
      _selectedDate = DateTime.now();
      _manualForeignRate = null;
      // 260622-nhs: a fresh continuous-entry slate starts as manual provenance.
      _lastFillWasVoice = false;
    });
    resetPttSessionState();
    final formState = _formKey.currentState;
    // Phase 52 (RECUX-03 / D-05): 连续记账 (continuous-entry) starts a fresh
    // slate after a successful save — discard any leftover pending correction
    // with NO write so the next entry never inherits a stale correction.
    formState?.discardPendingCorrection();
    formState?.updateAmount(0);
    formState?.updateCurrencyTriple(
      originalCurrency: null,
      originalAmount: null,
      appliedRate: null,
    );
    formState?.updateMerchant('');
    formState?.updateNote('');
    formState?.updateDate(DateTime.now());
    // Re-seed the default category for the next entry. _initializeDefaultCategory
    // now pushes the resolved default into the form itself (260603-ti2), so the
    // form's GlobalKey-preserved state is reset to the default category too.
    await _initializeDefaultCategory();
    if (!mounted) return;
    _restoreKeypadFocus();
  }
}
