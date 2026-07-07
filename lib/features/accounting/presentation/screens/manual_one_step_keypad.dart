// lib/features/accounting/presentation/screens/manual_one_step_keypad.dart
//
// quick-260707-kfb A2: the keypad segment of `_ManualOneStepScreenState`, moved
// out of `manual_one_step_screen.dart` as a same-library `part` (the host State
// class is private, so a part is the only split that keeps zero renames and
// zero visibility promotion). Covers the amount-tap handler, the digit
// handlers, and the amount→form sync — verbatim moves.
//
// ONE sanctioned rewrite (mirrors the `manual_one_step_voice_wiring.dart`
// precedent): the moved `setState(...)` calls became `_rebuild(...)` —
// `setState` is `@protected` and an extension member is not a subclass instance
// member, so the analyzer rejects the verbatim call. `_rebuild`'s body is
// exactly `if (mounted) setState(apply)`, so the substitution is
// behavior-identical.

part of 'manual_one_step_screen.dart';

extension _ManualOneStepKeypad on _ManualOneStepScreenState {
  // ── Amount tap handler (D-10) ──

  void _onAmountTap() {
    _restoreKeypadFocus();
  }

  // ── Digit handlers (Phase 42: delegated to the currency-aware controller) ──
  //
  // Each handler mutates [_controller] (which owns the D-06 dot-gating + D-07
  // decimal cap per currency) then mirrors the result into [_amount] and the
  // form via [_syncAmountToForm]. JPY (decimals==0) behaves byte-identically to
  // the old inline cap: dot gated off, no fractional digits (CURR-04).

  void _onDigit(String digit) {
    _controller.onDigit(digit);
    _syncAmountToForm();
  }

  void _onDoubleZero() {
    _controller.onDoubleZero();
    _syncAmountToForm();
  }

  void _onDot() {
    _controller.onDot();
    _syncAmountToForm();
  }

  void _onDelete() {
    _controller.onDelete();
    _syncAmountToForm();
  }

  void _onClear() {
    while (_controller.text.isNotEmpty) {
      _controller.onDelete();
    }
    // 260622-nhs: clearing the amount drops voice provenance — a row the user
    // re-enters by keypad after a clear is `manual`, not `voice` (T-nhs-03).
    _lastFillWasVoice = false;
    _syncAmountToForm();
  }

  /// Mirror the controller's text into [_amount] (for AmountDisplay + the empty
  /// / zero save guard) and push the converted JPY amount + currency triple into
  /// the form so `submit()` persists the right figures.
  ///
  /// - JPY (CURR-04): the entered figure IS the JPY amount; triple cleared so
  ///   the create use case persists a native JPY row, byte-identical to before.
  /// - Foreign: the JPY amount comes from the single-site [convertToJpy] using
  ///   the rate resolved by the preview's keyed provider; the triple is pushed
  ///   alongside. When no rate has resolved yet the JPY mirror stays 0 and the
  ///   triple is withheld (save is still guarded on a non-empty amount).
  void _syncAmountToForm() {
    _rebuild(() => _amount = _controller.text);
    if (!_isForeign) {
      final parsed = (double.tryParse(_amount) ?? 0.0).round();
      _formKey.currentState?.updateAmount(parsed);
      _formKey.currentState?.updateCurrencyTriple(
        originalCurrency: null,
        originalAmount: null,
        appliedRate: null,
      );
      return;
    }
    // Push the freshly-entered amount/triple immediately so an instant Save
    // persists the correct figure and the staleness guard compares against live
    // input. The FX card now reads the LIVE amount too (Quick 260613-wuv2): with
    // the amount out of the rate provider key, feeding it live refreshes only the
    // derived-JPY number with no whole-card reload, so no debounce is needed.
    _pushForeignTriple();
  }
}
