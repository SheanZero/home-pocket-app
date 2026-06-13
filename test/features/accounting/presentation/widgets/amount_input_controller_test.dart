// WAVE 0 RED SCAFFOLD — Phase 42, producing plan 42-05 (AmountInputController).
//
// This file references AmountInputController — a class that DOES NOT EXIST yet.
// It is therefore EXPECTED to fail to compile (RED) until plan 42-05 extracts
// the decimal-cap / truncation state machine from manual_one_step_screen's
// inline _onDigit/_onDot handlers.
//
// Locked behavior under test (CURR-05 / D-07 / D-08):
//   - onDigit caps fractional length at the currency's minor-unit count
//     (USD = 2: "50.5" + "0" → "50.50"; a further digit is ignored).
//   - onCurrencyChange(0) TRUNCATES (string op, NOT round): "50.50" → "50",
//     "0.99" → "0", "50.5" → "50".
//   - onCurrencyChange(2) on "50.567" → "50.56" (truncate to 2 places).
//   - onDot is a no-op / unavailable when decimals == 0 (JPY/KRW).
//
// The controller's surface assumed here (to be ratified by plan 42-05):
//   AmountInputController({required int decimals})  // current currency minor unit
//   String get text                                  // raw display string
//   void onDigit(String d)
//   void onDot()
//   void onCurrencyChange(int newDecimals)           // re-truncates `text`
//
// Do NOT weaken assertions to make them pass. RED is the intended state.
//
// See: lib/features/accounting/presentation/screens/manual_one_step_screen.dart
//      (inline _onDigit/_onDot 4-decimal cap — the behavior being generalized),
//      .planning/phases/42-entry-ui-display-voice/42-CONTEXT.md (D-07/D-08).

import 'package:flutter_test/flutter_test.dart';
// ignore: uri_does_not_exist
import 'package:home_pocket/features/accounting/presentation/widgets/amount_input_controller.dart';

void main() {
  group('AmountInputController — D-07 decimal cap', () {
    test('USD (2 decimals): caps fractional length at 2', () {
      final c = AmountInputController(decimals: 2);
      for (final d in ['5', '0', '.', '5', '0']) {
        d == '.' ? c.onDot() : c.onDigit(d);
      }
      expect(c.text, '50.50');
      c.onDigit('7'); // 3rd decimal — must be ignored
      expect(c.text, '50.50');
    });

    test('JPY (0 decimals): onDot is a no-op', () {
      final c = AmountInputController(decimals: 0);
      c.onDigit('5');
      c.onDigit('0');
      c.onDot(); // unavailable when decimals == 0
      c.onDigit('7');
      expect(c.text, '507');
      expect(c.text, isNot(contains('.')));
    });
  });

  group('AmountInputController — D-08 truncation on currency switch', () {
    test('onCurrencyChange(0) truncates "50.50" → "50" (NOT round)', () {
      final c = AmountInputController(decimals: 2);
      for (final d in ['5', '0', '.', '5', '0']) {
        d == '.' ? c.onDot() : c.onDigit(d);
      }
      expect(c.text, '50.50');
      c.onCurrencyChange(0);
      expect(c.text, '50');
    });

    test('onCurrencyChange(0) truncates "0.99" → "0" (NOT round to 1)', () {
      final c = AmountInputController(decimals: 2);
      for (final d in ['0', '.', '9', '9']) {
        d == '.' ? c.onDot() : c.onDigit(d);
      }
      expect(c.text, '0.99');
      c.onCurrencyChange(0);
      expect(c.text, '0');
    });

    test('onCurrencyChange(0) truncates "50.5" → "50"', () {
      final c = AmountInputController(decimals: 2);
      for (final d in ['5', '0', '.', '5']) {
        d == '.' ? c.onDot() : c.onDigit(d);
      }
      expect(c.text, '50.5');
      c.onCurrencyChange(0);
      expect(c.text, '50');
    });

    test('onCurrencyChange(2) truncates "50.567" → "50.56"', () {
      // Start at 4-decimal capacity to allow "50.567" to be entered.
      final c = AmountInputController(decimals: 4);
      for (final d in ['5', '0', '.', '5', '6', '7']) {
        d == '.' ? c.onDot() : c.onDigit(d);
      }
      expect(c.text, '50.567');
      c.onCurrencyChange(2);
      expect(c.text, '50.56');
    });
  });
}
