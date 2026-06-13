/// Currency-aware decimal-input state machine for the amount keypad (CURR-05).
///
/// Extracted and generalized from the inline `_onDigit` / `_onDot` handlers in
/// `manual_one_step_screen.dart` (which hardcoded a 4-decimal cap). The cap is
/// now driven by the current currency's ISO 4217 minor unit (`decimals`),
/// sourced by the host from the single shared helper
/// `currencyFractionDigitsFor` (plan 42-02, intl-backed). This class does NOT
/// re-derive decimals — the host supplies them.
///
/// Locked behavior (D-06 / D-07 / D-08, see 42-CONTEXT.md):
///   - [onDigit] caps the fractional substring at [decimals] (D-07). A digit
///     past the cap is ignored. e.g. USD(2): "50.5" + "0" → "50.50"; +"1" no-op.
///   - [onDot] is only valid when [decimals] > 0 (D-06). For 0-decimal
///     currencies (JPY/KRW) it is a no-op, and the host passes `onDot:null`
///     so the keypad dot cell is disabled/blank.
///   - [onCurrencyChange] re-truncates the fractional substring as a pure
///     STRING op, never arithmetic rounding (D-08, RESEARCH Pitfall 3):
///     "50.50" → "50", "0.99" → "0", "50.567" → "50.56".
///
/// State is `{text, decimals}`. Each transition recomputes [text] to a freshly
/// derived string — no in-place mutation (CLAUDE.md immutability). The pure
/// transition logic is also exposed via static helpers so it can be reasoned
/// about and tested independently of the mutable handle.
class AmountInputController {
  AmountInputController({required int decimals})
      : _decimals = decimals,
        _text = '';

  String _text;
  int _decimals;

  /// Raw display string (e.g. "50.50", "507", "0.").
  String get text => _text;

  /// Current currency minor-unit count (ISO 4217). Drives the decimal cap and
  /// dot gating. Read-only; mutated only via [onCurrencyChange].
  int get decimals => _decimals;

  /// Append a single digit, respecting the D-07 fractional cap.
  void onDigit(String digit) {
    _text = appendDigit(_text, digit, _decimals);
  }

  /// Append a decimal point — only when [decimals] > 0 (D-06) and no point yet.
  void onDot() {
    _text = appendDot(_text, _decimals);
  }

  /// Append the double-zero shortcut, respecting the D-07 fractional cap.
  void onDoubleZero() {
    _text = appendDoubleZero(_text, _decimals);
  }

  /// Remove the last character.
  void onDelete() {
    if (_text.isNotEmpty) {
      _text = _text.substring(0, _text.length - 1);
    }
  }

  /// Switch the active currency. Re-truncates [text] to [newDecimals] places
  /// as a STRING op (D-08, never rounds) and adopts the new cap.
  void onCurrencyChange(int newDecimals) {
    _decimals = newDecimals;
    _text = truncateToDecimals(_text, newDecimals);
  }

  // ── Pure transition logic (no mutation) ─────────────────────────────────

  /// Returns [text] with [digit] appended if the D-07 cap permits, else [text].
  static String appendDigit(String text, String digit, int decimals) {
    final dotIndex = text.indexOf('.');
    if (dotIndex >= 0) {
      final fractional = text.length - dotIndex - 1;
      if (fractional >= decimals) return text; // D-07 cap reached
    }
    // Reject a leading lone zero (matches manual_one_step_screen semantics);
    // "0." remains reachable because '.' is appended via [appendDot].
    if (text.isEmpty && digit == '0') return text;
    return text + digit;
  }

  /// Returns [text] with '.' appended, or [text] unchanged when decimals == 0
  /// (D-06) or a point already exists.
  static String appendDot(String text, int decimals) {
    if (decimals <= 0) return text; // D-06: no decimals → dot unavailable
    if (text.contains('.')) return text;
    return text.isEmpty ? '0.' : '$text.';
  }

  /// Appends up to two '0' characters, never exceeding the D-07 cap.
  static String appendDoubleZero(String text, int decimals) {
    if (text.isEmpty) return text;
    final dotIndex = text.indexOf('.');
    if (dotIndex < 0) return '${text}00';
    final fractional = text.length - dotIndex - 1;
    final remaining = (decimals - fractional).clamp(0, 2);
    if (remaining == 0) return text;
    return text + ('0' * remaining);
  }

  /// Truncates the fractional substring of [text] to [decimals] places as a
  /// pure string cut (D-08). Never rounds. Strips a now-trailing lone '.'.
  ///
  ///   "50.50", 0  → "50"
  ///   "0.99",  0  → "0"
  ///   "50.567", 2 → "50.56"
  static String truncateToDecimals(String text, int decimals) {
    final dotIndex = text.indexOf('.');
    if (dotIndex < 0) return text; // no fractional part
    if (decimals <= 0) {
      return text.substring(0, dotIndex); // drop '.' and everything after
    }
    final maxLen = dotIndex + 1 + decimals;
    if (text.length <= maxLen) return text; // already within cap
    final cut = text.substring(0, maxLen);
    // A cut that lands exactly on the '.' would leave a trailing point.
    return cut.endsWith('.') ? cut.substring(0, cut.length - 1) : cut;
  }
}
