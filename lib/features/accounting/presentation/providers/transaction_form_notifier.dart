import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/presentation/providers/transaction_form_state.dart';
import 'package:home_pocket/features/accounting/presentation/providers/transaction_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transaction_form_notifier.g.dart';

/// Transaction Form Notifier
///
/// Manages transaction form state and submission
@riverpod
class TransactionFormNotifier extends _$TransactionFormNotifier {
  @override
  TransactionFormState build() {
    return const TransactionFormState();
  }

  /// Update amount (in cents)
  void updateAmount(int amount) {
    state = state.copyWith(
      amount: amount,
      errors: _removeError(state.errors, 'amount'),
    );
    _validate();
  }

  /// Update transaction type
  void updateType(TransactionType type) {
    state = state.copyWith(type: type);
  }

  /// Update category ID
  void updateCategory(String categoryId) {
    state = state.copyWith(
      categoryId: categoryId,
      errors: _removeError(state.errors, 'category'),
    );
    _validate();
  }

  /// Update ledger type
  void updateLedgerType(LedgerType ledgerType) {
    state = state.copyWith(ledgerType: ledgerType);
  }

  /// Update note
  void updateNote(String? note) {
    state = state.copyWith(note: note);
  }

  /// Update merchant
  void updateMerchant(String? merchant) {
    state = state.copyWith(merchant: merchant);
  }

  /// Update photo hash
  void updatePhotoHash(String? photoHash) {
    state = state.copyWith(photoHash: photoHash);
  }

  /// Validate form
  void _validate() {
    final errors = <String, String>{};

    if (state.amount <= 0) {
      errors['amount'] = 'Amount must be greater than 0';
    }

    if (state.categoryId == null || state.categoryId!.isEmpty) {
      errors['category'] = 'Please select a category';
    }

    state = state.copyWith(errors: errors);
  }

  /// Submit form (create new transaction)
  Future<void> submit({
    required String bookId,
    required String deviceId,
  }) async {
    // Validate first
    _validate();

    if (!state.isValid) {
      return;
    }

    // Set submitting state
    state = state.copyWith(
      isSubmitting: true,
      submitError: null,
      submitSuccess: false,
    );

    try {
      // Get use case
      final useCase = ref.read(createTransactionUseCaseProvider);

      // Execute use case
      final result = await useCase.execute(
        bookId: bookId,
        deviceId: deviceId,
        amount: state.amount,
        type: state.type,
        categoryId: state.categoryId!,
        ledgerType: state.ledgerType,
        note: state.note,
        merchant: state.merchant,
        photoHash: state.photoHash,
      );

      if (result.isSuccess) {
        // Success - reset form
        state = const TransactionFormState(submitSuccess: true);
      } else {
        // Error
        state = state.copyWith(
          isSubmitting: false,
          submitError: result.error,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: 'Failed to create transaction: ${e.toString()}',
      );
    }
  }

  /// Reset form
  void reset() {
    state = const TransactionFormState();
  }

  /// Helper to remove error from map
  Map<String, String> _removeError(Map<String, String> errors, String key) {
    final newErrors = Map<String, String>.from(errors);
    newErrors.remove(key);
    return newErrors;
  }
}
