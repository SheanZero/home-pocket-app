// lib/features/accounting/presentation/screens/manual_one_step_snapshot.dart
//
// Quick task 260622-nhs R2 (D-2 reset-restore): an immutable snapshot of the
// manual-entry form taken the moment the user taps 「语音记录」, so the modal's
// 「重置·恢复账目」 button can roll the form back to its pre-speech state. Kept in
// its own file to hold manual_one_step_screen.dart under the LOC cap.

import '../../../../shared/utils/currency_conversion.dart'
    show currencyFractionDigitsFor;
import '../../domain/models/category.dart';
import '../widgets/amount_input_controller.dart';
import '../widgets/transaction_details_form.dart';

/// Immutable pre-speech form snapshot. Captures the host-owned amount/currency
/// triplet plus the form-owned category/merchant/note/date/satisfaction so the
/// restore re-applies the exact pre-speech state.
class ManualEntrySnapshot {
  const ManualEntrySnapshot({
    required this.amountText,
    required this.currency,
    required this.manualForeignRate,
    required this.lastFillWasVoice,
    required this.category,
    required this.parentCategory,
    required this.date,
    required this.merchant,
    required this.note,
    required this.satisfaction,
    required this.originalCurrency,
    required this.originalAmount,
    required this.appliedRate,
  });

  // Host-owned amount/currency state.
  final String amountText;
  final String currency;
  final String? manualForeignRate;
  final bool lastFillWasVoice;

  // Form-owned state.
  final Category? category;
  final Category? parentCategory;
  final DateTime date;
  final String merchant;
  final String note;
  final int satisfaction;
  final String? originalCurrency;
  final int? originalAmount;
  final String? appliedRate;

  /// Capture the current form state (plus host amount/currency context).
  static ManualEntrySnapshot capture({
    required String amountText,
    required String currency,
    required String? manualForeignRate,
    required bool lastFillWasVoice,
    required TransactionDetailsFormState form,
  }) {
    return ManualEntrySnapshot(
      amountText: amountText,
      currency: currency,
      manualForeignRate: manualForeignRate,
      lastFillWasVoice: lastFillWasVoice,
      category: form.currentCategory,
      parentCategory: form.currentParentCategory,
      date: form.currentDate,
      merchant: form.currentMerchant,
      note: form.currentNote,
      satisfaction: form.currentSatisfaction,
      originalCurrency: form.currentOriginalCurrency,
      originalAmount: form.currentOriginalAmount,
      appliedRate: form.currentAppliedRate,
    );
  }

  /// Re-apply this snapshot's host-owned amount/currency into [controller]
  /// (clears it, restores the currency cap, then replays the digits/dot) and
  /// return the resulting controller text. The host mirrors this into `_amount`.
  String restoreHostAmount(AmountInputController controller) {
    while (controller.text.isNotEmpty) {
      controller.onDelete();
    }
    controller.onCurrencyChange(currencyFractionDigitsFor(currency));
    for (final ch in amountText.split('')) {
      if (ch == '.') {
        controller.onDot();
      } else {
        controller.onDigit(ch);
      }
    }
    return controller.text;
  }

  /// Re-apply this snapshot's form-owned fields via the imperative form API.
  /// The host re-applies the amount/currency context separately (it owns the
  /// AmountInputController + currency state).
  void restoreForm(TransactionDetailsFormState form) {
    final cat = category;
    if (cat != null) form.updateCategory(cat, parentCategory);
    form.updateMerchant(merchant);
    form.updateNote(note);
    form.updateDate(date);
    form.updateSatisfaction(satisfaction);
    form.updateCurrencyTriple(
      originalCurrency: originalCurrency,
      originalAmount: originalAmount,
      appliedRate: appliedRate,
    );
  }
}
