import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../shared/utils/currency_conversion.dart'
    show currencyFractionDigitsFor, formatMinorAsMajor, subunitToUnitFor;
import 'amount_display.dart';
import 'smart_keyboard.dart';

/// Standalone bottom-sheet widget for editing a transaction amount.
///
/// Extracted from the form widget's _editAmount (Phase 19, D-14) so any
/// host can present amount editing without duplicating the ~100-line handler.
///
/// Usage:
/// ```dart
/// await AmountEditBottomSheet.show(
///   context,
///   initialAmount: currentAmount,
///   onConfirm: (value) => formKey.currentState!.updateAmount(value),
/// );
/// ```
///
/// [ManualOneStepScreen] does NOT use this sheet (it owns a persistent
/// SmartKeyboard instead). [TransactionEditScreen] and [OcrReviewScreen]
/// (Phase 18 hosts) use this sheet for tap-amount-to-edit affordance (D-14
/// spillover — Plan 04).
///
/// **P19-B2 fix:** Uses the POST-rename `actionLabel:` SmartKeyboard API so
/// Plan 02's constructor rename in smart_keyboard.dart does not break this
/// caller when they land in the same wave.
///
/// **Quick task 260613-mgc:** an OPTIONAL currency-aware (major-unit decimal)
/// mode. When [currency] is null (default), the sheet behaves byte-identically
/// to the legacy JPY-integer mode: [initialAmount] is the integer JPY figure,
/// [onConfirm] returns `parsed.round()`. When [currency] is non-null (a foreign
/// edit row), [initialAmount] is interpreted as MINOR units (e.g. 11290 cents),
/// the editStr is seeded as the MAJOR-unit decimal string ("112.90"), the
/// decimal cap follows the currency's ISO 4217 minor-unit count, and [onConfirm]
/// returns the value back in MINOR units. The keypad widget itself is reused —
/// no new keyboard component is created.
class AmountEditBottomSheet extends StatelessWidget {
  const AmountEditBottomSheet({
    super.key,
    required this.initialAmount,
    required this.onConfirm,
    this.currency,
    this.currencySymbol = '¥',
    this.currencyLabel = 'JPY',
  });

  /// Starting amount.
  ///
  /// - JPY (default) mode ([currency] == null): the integer JPY figure
  ///   (e.g. 3280 for ¥3,280).
  /// - Currency-aware mode ([currency] non-null): the amount in the currency's
  ///   MINOR unit (e.g. 11290 for $112.90).
  final int initialAmount;

  /// Called with the confirmed amount when the user confirms.
  ///
  /// - JPY mode: the parsed-and-rounded integer JPY value.
  /// - Currency-aware mode: the value in MINOR units (major decimal × subunit).
  ///
  /// The sheet closes itself before invoking [onConfirm].
  final ValueChanged<int> onConfirm;

  /// ISO 4217 code enabling the currency-aware (major-unit decimal) mode.
  /// Null (or 'JPY') keeps the legacy JPY-integer behavior.
  final String? currency;

  /// Currency symbol shown in the [AmountDisplay] badge (e.g. "¥", "$", "€").
  final String currencySymbol;

  /// Currency code label shown in the [AmountDisplay] badge (e.g. "JPY", "USD").
  final String currencyLabel;

  /// True when the sheet runs in the currency-aware (major-unit decimal) mode.
  bool get _isCurrencyAware =>
      currency != null && currency!.toUpperCase() != 'JPY';

  /// Presents [AmountEditBottomSheet] modally.
  ///
  /// Returns a [Future] that completes when the sheet is dismissed.
  static Future<void> show(
    BuildContext context, {
    required int initialAmount,
    required ValueChanged<int> onConfirm,
    String? currency,
    String currencySymbol = '¥',
    String currencyLabel = 'JPY',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AmountEditBottomSheet(
        initialAmount: initialAmount,
        onConfirm: onConfirm,
        currency: currency,
        currencySymbol: currencySymbol,
        currencyLabel: currencyLabel,
      ),
    );
  }

  /// Seeds the initial editStr.
  ///
  /// - JPY mode (null currency): the integer string (blank when 0), matching
  ///   legacy behavior byte-for-byte — [formatMinorAsMajor] is NOT used here
  ///   because it expects a real ISO currency.
  /// - Currency-aware mode: delegates to the shared [formatMinorAsMajor]
  ///   (260614-dx1) so the keypad seeds "12211" for a whole-number amount (no
  ///   useless ".00") while "112.90"/"12.50" keep their decimals.
  String _initialEditStr() {
    if (!_isCurrencyAware) {
      return initialAmount > 0 ? initialAmount.toString() : '';
    }
    return formatMinorAsMajor(initialAmount, currency!);
  }

  @override
  Widget build(BuildContext context) {
    // Currency-aware metadata is derived ONCE from the single decimals source
    // (currency_conversion.dart). In JPY mode these stay at their integer-mode
    // defaults and never gate the dot key (CURR-04: JPY path unchanged).
    final decimals = _isCurrencyAware
        ? currencyFractionDigitsFor(currency!)
        : 0;
    final subunit = _isCurrencyAware ? subunitToUnitFor(currency!) : 1;

    // editStr holds the raw digit string being built by the user.
    var editStr = _initialEditStr();

    // The fractional cap for the editor. In JPY mode the legacy 4-place cap is
    // preserved (decimal input is reachable but rounds to an integer on
    // confirm). In currency-aware mode it is the currency's ISO minor unit.
    final fractionalCap = _isCurrencyAware ? decimals : 4;

    // In currency-aware mode the dot is disabled for 0-decimal currencies
    // (JPY/KRW), mirroring the entry keypad. JPY default mode keeps the dot.
    final dotEnabled = !_isCurrencyAware || decimals > 0;

    return StatefulBuilder(
      builder: (context, setSheetState) {
        final palette = context.palette;

        void onDigit(String digit) {
          final dotIndex = editStr.indexOf('.');
          if (dotIndex >= 0) {
            final fractional = editStr.length - dotIndex - 1;
            if (fractional >= fractionalCap) return;
          }
          if (editStr == '0' && digit != '0') {
            setSheetState(() => editStr = digit);
          } else if (editStr == '0' && digit == '0') {
            return;
          } else {
            setSheetState(() => editStr += digit);
          }
        }

        void onDoubleZero() {
          if (editStr.isEmpty || editStr == '0') return;
          final dotIndex = editStr.indexOf('.');
          if (dotIndex >= 0) {
            final fractional = editStr.length - dotIndex - 1;
            if (fractional >= fractionalCap) return;
            final zerosToAdd = (fractionalCap - fractional).clamp(0, 2);
            setSheetState(() => editStr += '0' * zerosToAdd);
          } else {
            setSheetState(() => editStr += '00');
          }
        }

        void onDot() {
          if (editStr.contains('.')) return;
          if (editStr.isEmpty) {
            setSheetState(() => editStr = '0.');
          } else {
            setSheetState(() => editStr += '.');
          }
        }

        void onDelete() {
          if (editStr.isNotEmpty) {
            setSheetState(
              () => editStr = editStr.substring(0, editStr.length - 1),
            );
          }
        }

        void onClear() {
          setSheetState(() => editStr = '');
        }

        void onNext() {
          final cleaned = editStr.endsWith('.')
              ? editStr.substring(0, editStr.length - 1)
              : editStr;
          final parsed = double.tryParse(cleaned);
          if (parsed != null && parsed > 0) {
            Navigator.pop(context);
            // Currency-aware mode returns MINOR units; JPY mode rounds to the
            // integer JPY value (legacy path — byte-identical).
            onConfirm(
              _isCurrencyAware ? (parsed * subunit).round() : parsed.round(),
            );
          } else {
            Navigator.pop(context);
          }
        }

        return Container(
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.borderDefault,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                AmountDisplay(
                  amount: editStr,
                  onClear: onClear,
                  currencySymbol: currencySymbol,
                  currencyLabel: currencyLabel,
                ),
                SmartKeyboard(
                  onDigit: onDigit,
                  onDoubleZero: onDoubleZero,
                  // D-06: disabled dot tile for 0-decimal foreign currencies.
                  onDot: dotEnabled ? onDot : null,
                  onDelete: onDelete,
                  onNext: onNext,
                  // Foreign edit confirms with the 确认 (confirm) semantics
                  // (write-back only, not a whole-entry save); JPY mode keeps the
                  // record label (OCR/Voice/edit-JPY).
                  actionLabel: _isCurrencyAware
                      ? S.of(context).confirm
                      : S.of(context).record,
                  currencySymbol: currencySymbol,
                  currencyLabel: currencyLabel,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
