import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/presentation/screens/transaction_form_screen.dart';
import 'package:home_pocket/features/accounting/presentation/providers/transaction_list_provider.dart';

/// Transaction List Screen
///
/// Displays list of transactions with:
/// - Transaction list view with pull-to-refresh
/// - FAB to create new transaction
/// - Empty state when no transactions
/// - Swipe actions for edit/delete
class TransactionListScreen extends ConsumerWidget {
  final String bookId;

  const TransactionListScreen({
    super.key,
    this.bookId = 'book_001', // TODO: Get from app state
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the transaction list provider
    final transactionListAsync = ref.watch(
      transactionListProvider(bookId: bookId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Pocket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Show filter dialog in future iteration
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filter coming soon')),
              );
            },
          ),
        ],
      ),
      body: transactionListAsync.when(
        data: (transactions) => transactions.isEmpty
            ? _buildEmptyState(context)
            : _buildTransactionList(context, ref, transactions),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error.toString()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_transaction_fab'),
        onPressed: () async {
          // Navigate to form and refresh on return
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const TransactionFormScreen(),
            ),
          );
          // Refresh list after adding transaction
          ref.invalidate(transactionListProvider(bookId: bookId));
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'No transactions yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first transaction',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'Failed to load transactions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.red.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(
    BuildContext context,
    WidgetRef ref,
    List<Transaction> transactions,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh the list
        ref.invalidate(transactionListProvider(bookId: bookId));
        await ref.read(transactionListProvider(bookId: bookId).future);
      },
      child: ListView.builder(
        itemCount: transactions.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return _TransactionCard(
            key: Key('transaction_${transaction.id}'),
            transaction: transaction,
            onTap: () {
              // TODO: Navigate to transaction details in future iteration
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tapped: ${transaction.id}')),
              );
            },
            onEdit: () {
              // TODO: Navigate to edit form in future iteration
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Edit: ${transaction.id}')),
              );
            },
            onDelete: () => _showDeleteConfirmation(context, ref, transaction),
          );
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    Transaction transaction,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Are you sure you want to delete this transaction?\n\n'
          'Amount: ¥${(transaction.amount / 100).toStringAsFixed(2)}\n'
          'Category: ${transaction.categoryId}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        // Delete via provider
        await ref
            .read(transactionListProvider(bookId: bookId).notifier)
            .deleteTransaction(transaction.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TransactionCard({
    super.key,
    required this.transaction,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;
    final amount = transaction.amount / 100.0; // Convert cents to dollars

    return Dismissible(
      key: Key('dismissible_${transaction.id}'),
      background: Container(
        color: Colors.blue,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Delete action
          onDelete();
          return false; // Don't auto-dismiss, let dialog handle it
        } else {
          // Edit action
          onEdit();
          return false; // Don't dismiss
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isExpense
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isExpense
                        ? Icons.remove_circle_outline
                        : Icons.add_circle_outline,
                    color: isExpense ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(width: 12),

                // Transaction info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.categoryId,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (transaction.note != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          transaction.note!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Amount
                Text(
                  '${isExpense ? '-' : '+'}¥${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isExpense ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
