import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';

part 'transaction_form_state.freezed.dart';

/// Transaction Form State
///
/// Manages the state of transaction form UI
@freezed
class TransactionFormState with _$TransactionFormState {
  const factory TransactionFormState({
    /// Amount in cents (to avoid floating point issues)
    @Default(0) int amount,

    /// Transaction type (income/expense)
    @Default(TransactionType.expense) TransactionType type,

    /// Selected category ID
    String? categoryId,

    /// Ledger type (survival/soul)
    @Default(LedgerType.survival) LedgerType ledgerType,

    /// Optional note
    String? note,

    /// Optional merchant name
    String? merchant,

    /// Optional photo hash (for receipt photos)
    String? photoHash,

    /// Form validation errors
    @Default({}) Map<String, String> errors,

    /// Is form submitting
    @Default(false) bool isSubmitting,

    /// Submit error message
    String? submitError,

    /// Submit success flag
    @Default(false) bool submitSuccess,
  }) = _TransactionFormState;

  const TransactionFormState._();

  /// Check if form is valid
  bool get isValid =>
      amount > 0 && categoryId != null && categoryId!.isNotEmpty;

  /// Check if form has any errors
  bool get hasErrors => errors.isNotEmpty;

  /// Check if form can be submitted
  bool get canSubmit => isValid && !isSubmitting && !hasErrors;
}
