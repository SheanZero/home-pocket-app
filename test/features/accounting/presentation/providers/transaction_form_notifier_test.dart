import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/presentation/providers/transaction_form_notifier.dart';
import 'package:home_pocket/features/accounting/presentation/providers/transaction_form_state.dart';

void main() {
  group('TransactionFormNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize with default state', () {
      final notifier = container.read(transactionFormNotifierProvider.notifier);
      final state = container.read(transactionFormNotifierProvider);

      expect(state.amount, 0);
      expect(state.type, TransactionType.expense);
      expect(state.categoryId, isNull);
      expect(state.ledgerType, LedgerType.survival);
      expect(state.note, isNull);
      expect(state.merchant, isNull);
      expect(state.errors, isEmpty);
      expect(state.isSubmitting, false);
      expect(state.submitSuccess, false);
    });

    test('should update amount', () {
      final notifier = container.read(transactionFormNotifierProvider.notifier);

      notifier.updateAmount(10000);

      final state = container.read(transactionFormNotifierProvider);
      expect(state.amount, 10000);
    });

    test('should update transaction type', () {
      final notifier = container.read(transactionFormNotifierProvider.notifier);

      notifier.updateType(TransactionType.income);

      final state = container.read(transactionFormNotifierProvider);
      expect(state.type, TransactionType.income);
    });

    test('should update category', () {
      final notifier = container.read(transactionFormNotifierProvider.notifier);

      notifier.updateCategory('cat_food');

      final state = container.read(transactionFormNotifierProvider);
      expect(state.categoryId, 'cat_food');
    });

    test('should update ledger type', () {
      final notifier = container.read(transactionFormNotifierProvider.notifier);

      notifier.updateLedgerType(LedgerType.soul);

      final state = container.read(transactionFormNotifierProvider);
      expect(state.ledgerType, LedgerType.soul);
    });

    test('should update note', () {
      final notifier = container.read(transactionFormNotifierProvider.notifier);

      notifier.updateNote('Test note');

      final state = container.read(transactionFormNotifierProvider);
      expect(state.note, 'Test note');
    });

    test('should update merchant', () {
      final notifier = container.read(transactionFormNotifierProvider.notifier);

      notifier.updateMerchant('Test merchant');

      final state = container.read(transactionFormNotifierProvider);
      expect(state.merchant, 'Test merchant');
    });

    test('should validate amount > 0', () {
      final notifier = container.read(transactionFormNotifierProvider.notifier);

      // Set invalid amount
      notifier.updateAmount(0);

      final state = container.read(transactionFormNotifierProvider);
      expect(state.errors['amount'], isNotNull);
      expect(state.isValid, false);
    });

    test('should validate category is selected', () {
      final notifier = container.read(transactionFormNotifierProvider.notifier);

      // Set valid amount but no category
      notifier.updateAmount(10000);

      final state = container.read(transactionFormNotifierProvider);
      expect(state.errors['category'], isNotNull);
      expect(state.isValid, false);
    });

    test('should be valid when all required fields are set', () {
      final notifier = container.read(transactionFormNotifierProvider.notifier);

      notifier.updateAmount(10000);
      notifier.updateCategory('cat_food');

      final state = container.read(transactionFormNotifierProvider);
      expect(state.isValid, true);
      expect(state.canSubmit, true);
    });

    test('should reset form', () {
      final notifier = container.read(transactionFormNotifierProvider.notifier);

      // Set some values
      notifier.updateAmount(10000);
      notifier.updateCategory('cat_food');
      notifier.updateNote('Test');

      // Reset
      notifier.reset();

      final state = container.read(transactionFormNotifierProvider);
      expect(state.amount, 0);
      expect(state.categoryId, isNull);
      expect(state.note, isNull);
    });

    test('should clear errors when updating fields', () {
      final notifier = container.read(transactionFormNotifierProvider.notifier);

      // Trigger validation errors
      notifier.updateAmount(0);

      var state = container.read(transactionFormNotifierProvider);
      expect(state.errors['amount'], isNotNull);

      // Fix the error
      notifier.updateAmount(10000);

      state = container.read(transactionFormNotifierProvider);
      expect(state.errors['amount'], isNull);
    });
  });
}
