import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/presentation/providers/transaction_form_notifier.dart';
import 'package:home_pocket/features/accounting/presentation/providers/transaction_form_state.dart';
import 'package:home_pocket/features/accounting/presentation/providers/current_book_provider.dart';
import 'package:home_pocket/features/accounting/presentation/providers/current_device_provider.dart';

/// Transaction Form Screen
///
/// Allows users to create new transactions with:
/// - Amount input
/// - Transaction type selection (income/expense)
/// - Category selection
/// - Ledger type selection (survival/soul)
/// - Optional note and merchant name
class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key});

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _merchantController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(transactionFormNotifierProvider);
    final formNotifier = ref.read(transactionFormNotifierProvider.notifier);

    // Watch current book and device ID
    final currentBookAsync = ref.watch(currentBookIdProvider);
    final currentDeviceAsync = ref.watch(currentDeviceIdProvider);

    // Listen for submit success
    ref.listen<bool>(
      transactionFormNotifierProvider.select((state) => state.submitSuccess),
      (_, submitSuccess) {
        if (submitSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction created successfully')),
          );
          Navigator.of(context).pop();
        }
      },
    );

    // Handle loading/error states for book and device
    return currentBookAsync.when(
      data: (bookId) {
        if (bookId == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('New Transaction')),
            body: const Center(
              child: Text('Please create a book first'),
            ),
          );
        }

        return currentDeviceAsync.when(
          data: (deviceId) => _buildFormScaffold(
            context,
            formState,
            formNotifier,
            bookId,
            deviceId,
          ),
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Scaffold(
            appBar: AppBar(title: const Text('New Transaction')),
            body: Center(child: Text('Error loading device: $error')),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('New Transaction')),
        body: Center(child: Text('Error loading book: $error')),
      ),
    );
  }

  Widget _buildFormScaffold(
    BuildContext context,
    TransactionFormState formState,
    TransactionFormNotifier formNotifier,
    String bookId,
    String deviceId,
  ) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Transaction'),
        actions: [
          if (formState.isSubmitting)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Amount Input
            TextFormField(
              key: const Key('amount_field'),
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '¥ ',
                errorText: formState.errors['amount'],
                border: const OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              onChanged: (value) {
                final amount = (double.tryParse(value) ?? 0) * 100;
                formNotifier.updateAmount(amount.toInt());
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Amount must be greater than 0';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Transaction Type Selection
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Expense'),
                  icon: Icon(Icons.remove_circle_outline),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Income'),
                  icon: Icon(Icons.add_circle_outline),
                ),
              ],
              selected: {formState.type},
              onSelectionChanged: (Set<TransactionType> selected) {
                formNotifier.updateType(selected.first);
              },
            ),

            const SizedBox(height: 16),

            // Category Selection
            DropdownButtonFormField<String>(
              value: formState.categoryId,
              decoration: InputDecoration(
                labelText: 'Category',
                errorText: formState.errors['category'],
                border: const OutlineInputBorder(),
              ),
              items: Category.systemCategories
                  .where((cat) => cat.type == formState.type)
                  .map((category) => DropdownMenuItem(
                        value: category.id,
                        child: Row(
                          children: [
                            Icon(
                              Icons.category,
                              color: Color(
                                  int.parse(category.color.substring(1), radix: 16) +
                                      0xFF000000),
                            ),
                            const SizedBox(width: 8),
                            Text(category.name),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  formNotifier.updateCategory(value);
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a category';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Ledger Type Selection
            SegmentedButton<LedgerType>(
              segments: const [
                ButtonSegment(
                  value: LedgerType.survival,
                  label: Text('Survival'),
                  icon: Icon(Icons.restaurant),
                ),
                ButtonSegment(
                  value: LedgerType.soul,
                  label: Text('Soul'),
                  icon: Icon(Icons.self_improvement),
                ),
              ],
              selected: {formState.ledgerType},
              onSelectionChanged: (Set<LedgerType> selected) {
                formNotifier.updateLedgerType(selected.first);
              },
            ),

            const SizedBox(height: 16),

            // Note Input (Optional)
            TextFormField(
              key: const Key('note_field'),
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Add a note about this transaction',
              ),
              maxLines: 3,
              onChanged: (value) {
                formNotifier.updateNote(value.isEmpty ? null : value);
              },
            ),

            const SizedBox(height: 16),

            // Merchant Input (Optional)
            TextFormField(
              key: const Key('merchant_field'),
              controller: _merchantController,
              decoration: const InputDecoration(
                labelText: 'Merchant (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Where did you make this transaction?',
              ),
              onChanged: (value) {
                formNotifier.updateMerchant(value.isEmpty ? null : value);
              },
            ),

            const SizedBox(height: 24),

            // Submit Error Message
            if (formState.submitError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        formState.submitError!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),

            if (formState.submitError != null) const SizedBox(height: 16),

            // Submit Button
            FilledButton.icon(
              onPressed: formState.isSubmitting
                  ? null
                  : () async {
                      // Always trigger validation to show error messages
                      if (_formKey.currentState!.validate()) {
                        // Only submit if form validation passes
                        await formNotifier.submit(
                          bookId: bookId,
                          deviceId: deviceId,
                        );
                      }
                    },
              icon: formState.isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text(formState.isSubmitting ? 'Creating...' : 'Create Transaction'),
            ),

            const SizedBox(height: 8),

            // Cancel Button
            OutlinedButton(
              onPressed: formState.isSubmitting
                  ? null
                  : () {
                      Navigator.of(context).pop();
                    },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
