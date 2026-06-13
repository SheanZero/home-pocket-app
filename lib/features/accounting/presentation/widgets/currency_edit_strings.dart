/// Null-safe string resolver for the Phase 42-09 currency edit host.
///
/// The Wave-0 RED test (`edit_currency_linked_test.dart`, from 42-01) pumps the
/// edit host inside a bare `MaterialApp` with NO `S` localization delegate —
/// it asserts only on the derived JPY value, the dialog buttons, and the undo
/// toast, never on a localized label. `S.of(context)` null-asserts and would
/// throw in that harness, so the edit widgets resolve their copy through this
/// helper instead: it returns the localized string when the delegate IS present
/// (production / integration tests) and a stable English fallback when it is not.
///
/// Production hosts ALWAYS register `S.delegate`, so users only ever see the
/// localized ja/zh/en copy — the fallbacks exist solely to keep the delegate-less
/// unit harness renderable.
library;

import 'package:flutter/widgets.dart';

import '../../../../generated/app_localizations.dart';

/// Localized copy for the currency edit host, with English fallbacks for the
/// delegate-less test harness. Resolve once per build via [CurrencyEditStrings.of].
class CurrencyEditStrings {
  const CurrencyEditStrings._(this._s);

  final S? _s;

  /// Reads the [S] delegate if registered; otherwise wraps null so every getter
  /// falls back to its English literal.
  factory CurrencyEditStrings.of(BuildContext context) {
    return CurrencyEditStrings._(Localizations.of<S>(context, S));
  }

  String get originalAmountLabel =>
      _s?.editOriginalAmountLabel ?? 'Original amount';
  String get rateLabel => _s?.editRateLabel ?? 'Rate';
  String get jpyDerivedLabel => _s?.editJpyDerivedLabel ?? 'JPY (derived)';
  String get rateRequired => _s?.editRateRequired ?? 'Please enter a rate';
  String get rateInvalid => _s?.editRateInvalid ?? 'Enter a positive number';
  String get amountRequired => _s?.editAmountRequired ?? 'Please enter an amount';
  String get amountInvalid =>
      _s?.editAmountInvalid ?? 'Enter a positive number';
  String get dateLabel => _s?.date ?? 'Date';

  String get dialogTitle => _s?.changeRateDialogTitle ?? 'Rate confirmation';
  String get dialogBody =>
      _s?.changeRateDialogBody ??
      'You set the rate manually. Re-fetch the rate for the new date?';
  String get keepManual => _s?.changeRateKeepManual ?? 'Keep manual rate';
  String get refetch => _s?.changeRateRefetch ?? 'Re-fetch for new date';

  String rateChangedToast(String oldJpy, String newJpy) =>
      _s?.rateChangedToast(oldJpy, newJpy) ??
      'JPY adjusted: $oldJpy → $newJpy (rate updated)';
  String get undo => _s?.rateChangedUndo ?? 'Undo';
}
