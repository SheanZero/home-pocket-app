import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/presentation/providers/current_book_provider.dart';
import 'package:home_pocket/features/accounting/presentation/providers/current_device_provider.dart';
import 'package:home_pocket/features/accounting/presentation/providers/transaction_form_notifier.dart';
import 'package:home_pocket/features/accounting/presentation/providers/transaction_form_state.dart';
import 'package:home_pocket/generated/app_localizations.dart';

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
          final l10n = S.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.transactionCreatedSuccessfully)),
          );
          Navigator.of(context).pop();
        }
      },
    );

    // Handle loading/error states for book and device
    final l10n = S.of(context)!;

    return currentBookAsync.when(
      data: (bookId) {
        if (bookId == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.newTransaction)),
            body: Center(
              child: Text(l10n.pleaseCreateBookFirst),
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
            appBar: AppBar(title: Text(l10n.newTransaction)),
            body: Center(child: Text('${l10n.errorLoadingDevice}: $error')),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.newTransaction)),
        body: Center(child: Text('${l10n.errorLoadingBook}: $error')),
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
    final l10n = S.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.newTransaction),
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
                labelText: l10n.amount,
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
                  return l10n.pleaseEnterAmount;
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return l10n.amountMustBeGreaterThanZero;
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Transaction Type Selection
            SegmentedButton<TransactionType>(
              segments: [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text(l10n.transactionTypeExpense),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text(l10n.transactionTypeIncome),
                  icon: const Icon(Icons.add_circle_outline),
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
              initialValue: formState.categoryId,
              decoration: InputDecoration(
                labelText: l10n.category,
                errorText: formState.errors['category'],
                border: const OutlineInputBorder(),
              ),
              items: Category.systemCategories
                  .where((cat) => cat.type == formState.type)
                  .map(
                    (category) => DropdownMenuItem(
                      value: category.id,
                      child: Row(
                        children: [
                          Icon(
                            Icons.category,
                            color: Color(
                              int.parse(category.color.substring(1),
                                      radix: 16) +
                                  0xFF000000,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(category.name),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  formNotifier.updateCategory(value);
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.pleaseSelectCategory;
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Ledger Type Selection
            SegmentedButton<LedgerType>(
              segments: [
                ButtonSegment(
                  value: LedgerType.survival,
                  label: Text(l10n.survivalLedger),
                  icon: const Icon(Icons.restaurant),
                ),
                ButtonSegment(
                  value: LedgerType.soul,
                  label: Text(l10n.soulLedger),
                  icon: const Icon(Icons.self_improvement),
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
              decoration: InputDecoration(
                labelText: l10n.noteOptional,
                border: const OutlineInputBorder(),
                hintText: l10n.notePlaceholder,
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
              decoration: InputDecoration(
                labelText: l10n.merchantOptional,
                border: const OutlineInputBorder(),
                hintText: l10n.merchantPlaceholder,
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
              label: Text(formState.isSubmitting
                  ? l10n.creatingTransaction
                  : l10n.createTransaction),
            ),

            const SizedBox(height: 8),

            // Cancel Button
            OutlinedButton(
              onPressed: formState.isSubmitting
                  ? null
                  : () {
                      Navigator.of(context).pop();
                    },
              child: Text(l10n.cancel),
            ),
          ],
        ),
      ),
    );
  }
}
