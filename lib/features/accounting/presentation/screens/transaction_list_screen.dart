import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/accounting/get_transactions_use_case.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/category.dart';
import '../../domain/models/transaction.dart';
import '../providers/repository_providers.dart';
import '../providers/use_case_providers.dart';
import '../widgets/transaction_list_tile.dart';
import 'transaction_form_screen.dart';

/// Main transaction list screen.
///
/// Displays all transactions for the current book, with a FAB
/// to add new transactions. Supports swipe-to-delete.
class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({
    super.key,
    required this.bookId,
    this.ledgerType,
    this.embedded = false,
  });

  final String bookId;
  final LedgerType? ledgerType;
  final bool embedded;

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  List<Transaction> _transactions = [];
  Map<String, Category> _categoryMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final getTransactions = ref.read(getTransactionsUseCaseProvider);
    final categoryRepo = ref.read(categoryRepositoryProvider);

    final result = await getTransactions.execute(
      GetTransactionsParams(
        bookId: widget.bookId,
        ledgerType: widget.ledgerType,
      ),
    );

    final categories = await categoryRepo.findAll();
    final catMap = <String, Category>{};
    for (final cat in categories) {
      catMap[cat.id] = cat;
    }

    if (mounted) {
      setState(() {
        _transactions = result.isSuccess ? result.data! : [];
        _categoryMap = catMap;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTransaction(String id) async {
    final deleteUseCase = ref.read(deleteTransactionUseCaseProvider);
    await deleteUseCase.execute(id);
    await _loadData();
  }

  Future<void> _navigateToForm() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionFormScreen(bookId: widget.bookId),
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _transactions.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  S.of(context).noTransactionsYet,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(S.of(context).tapToAddFirstTransaction),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.separated(
              itemCount: _transactions.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final tx = _transactions[index];
                final cat = _categoryMap[tx.categoryId];
                return TransactionListTile(
                  transaction: tx,
                  categoryName: cat?.name,
                  onDelete: () => _deleteTransaction(tx.id),
                );
              },
            ),
          );

    final fab = FloatingActionButton(
      onPressed: _navigateToForm,
      child: const Icon(Icons.add),
    );

    if (widget.embedded) {
      return Stack(
        children: [
          body,
          Positioned(right: 16, bottom: 16, child: fab),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).transactions)),
      body: body,
      floatingActionButton: fab,
    );
  }
}
