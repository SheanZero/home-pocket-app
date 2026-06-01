import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../generated/app_localizations.dart';
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
class AmountEditBottomSheet extends StatelessWidget {
  const AmountEditBottomSheet({
    super.key,
    required this.initialAmount,
    required this.onConfirm,
  });

  /// Starting amount in the smallest currency unit (e.g. 3280 for ¥3,280).
  final int initialAmount;

  /// Called with the parsed and rounded amount when the user confirms.
  /// The sheet closes itself before invoking [onConfirm].
  final ValueChanged<int> onConfirm;

  /// Presents [AmountEditBottomSheet] modally.
  ///
  /// Returns a [Future] that completes when the sheet is dismissed.
  static Future<void> show(
    BuildContext context, {
    required int initialAmount,
    required ValueChanged<int> onConfirm,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AmountEditBottomSheet(
        initialAmount: initialAmount,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // editStr holds the raw digit string being built by the user.
    // Initialised from initialAmount; blank when initialAmount == 0.
    var editStr = initialAmount > 0 ? initialAmount.toString() : '';

    return StatefulBuilder(
      builder: (context, setSheetState) {
        final palette = context.palette;

        void onDigit(String digit) {
          final dotIndex = editStr.indexOf('.');
          if (dotIndex >= 0) {
            final decimals = editStr.length - dotIndex - 1;
            if (decimals >= 4) return;
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
            final decimals = editStr.length - dotIndex - 1;
            if (decimals >= 4) return;
            final zerosToAdd = (4 - decimals).clamp(0, 2);
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
            onConfirm(parsed.round());
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
                AmountDisplay(amount: editStr, onClear: onClear),
                SmartKeyboard(
                  onDigit: onDigit,
                  onDoubleZero: onDoubleZero,
                  onDot: onDot,
                  onDelete: onDelete,
                  onNext: onNext,
                  actionLabel: S.of(context).record,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
