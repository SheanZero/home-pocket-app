import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/accounting/create_transaction_use_case.dart';
import '../../../../features/dual_ledger/presentation/widgets/soul_celebration_overlay.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/category/category_service.dart';
import '../../../settings/presentation/providers/locale_provider.dart';
import '../../domain/models/category.dart';
import '../../domain/models/transaction.dart';
import '../providers/repository_providers.dart';
import '../providers/use_case_providers.dart';

/// Transaction entry form.
///
/// Provides amount input, transaction type toggle (expense/income),
/// category selection, optional note, and save button.
/// Returns `true` via Navigator.pop on successful save.
class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key, required this.bookId});

  final String bookId;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String? _selectedCategoryId;
  List<Category> _categories = [];
  bool _isSubmitting = false;
  String? _amountError;
  String? _categoryError;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final repo = ref.read(categoryRepositoryProvider);
    final cats = await repo.findActive();
    if (mounted) {
      setState(() {
        _categories = cats.where((c) => c.level == 1).toList();
        if (_selectedCategoryId != null &&
            !_categories.any((c) => c.id == _selectedCategoryId)) {
          _selectedCategoryId = null;
        }
      });
    }
  }

  bool _validate() {
    bool valid = true;

    final amountText = _amountController.text.trim();
    final amount = int.tryParse(amountText);
    if (amountText.isEmpty || amount == null || amount <= 0) {
      setState(() => _amountError = S.of(context).amountMustBeGreaterThanZero);
      valid = false;
    } else {
      setState(() => _amountError = null);
    }

    if (_selectedCategoryId == null) {
      setState(() => _categoryError = S.of(context).pleaseSelectCategory);
      valid = false;
    } else {
      setState(() => _categoryError = null);
    }

    return valid;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() => _isSubmitting = true);

    final createUseCase = ref.read(createTransactionUseCaseProvider);
    final result = await createUseCase.execute(
      CreateTransactionParams(
        bookId: widget.bookId,
        amount: int.parse(_amountController.text.trim()),
        type: _type,
        categoryId: _selectedCategoryId!,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      ),
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (result.isSuccess) {
      final tx = result.data!;
      if (tx.ledgerType == LedgerType.soul) {
        // Show soul celebration overlay before popping
        await _showSoulCelebration();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.of(context).transactionSaved)));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.error ?? S.of(context).failedToSave)));
    }
  }

  Future<void> _showSoulCelebration() async {
    final completer = Completer<void>();

    final overlay = OverlayEntry(
      builder: (_) => SoulCelebrationOverlay(
        onDismissed: () {
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );

    Overlay.of(context).insert(overlay);
    await completer.future;
    overlay.remove();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(currentLocaleProvider);

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).newTransaction)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount input
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: S.of(context).amount,
                        prefixIcon: const Icon(Icons.attach_money),
                        border: const OutlineInputBorder(),
                        errorText: _amountError,
                      ),
                      autofocus: true,
                    ),

                    const SizedBox(height: 16),

                    // Type toggle
                    SegmentedButton<TransactionType>(
                      segments: [
                        ButtonSegment(
                          value: TransactionType.expense,
                          label: Text(S.of(context).transactionTypeExpense),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        ButtonSegment(
                          value: TransactionType.income,
                          label: Text(S.of(context).transactionTypeIncome),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (selected) {
                        setState(() => _type = selected.first);
                        _loadCategories();
                      },
                    ),

                    const SizedBox(height: 24),

                    // Category selector
                    Text(
                      'Category',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (_categoryError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _categoryError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final selected = _selectedCategoryId == cat.id;
                        return ChoiceChip(
                          label: Text(
                            CategoryService.resolve(cat.name, locale),
                          ),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              _selectedCategoryId = cat.id;
                              _categoryError = null;
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Note input
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: S.of(context).noteOptional,
                        prefixIcon: const Icon(Icons.note),
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),

            // Save button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(S.of(context).save),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
