import 'package:flutter/material.dart';

import '../../domain/models/transaction.dart';

/// Displays a single transaction as a list tile.
///
/// Shows category icon, amount (red for expense, green for income),
/// optional note, and relative timestamp.
class TransactionListTile extends StatelessWidget {
  const TransactionListTile({
    super.key,
    required this.transaction,
    this.categoryName,
    this.onTap,
    this.onDelete,
  });

  final Transaction transaction;
  final String? categoryName;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text('Delete this transaction?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete?.call(),
      child: ListTile(
        onTap: onTap,
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              backgroundColor: isExpense
                  ? Colors.red.shade100
                  : Colors.green.shade100,
              child: Icon(
                isExpense ? Icons.remove : Icons.add,
                color: isExpense ? Colors.red : Colors.green,
              ),
            ),
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                key: const Key('ledger_indicator'),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: transaction.ledgerType == LedgerType.soul
                      ? Colors.purple
                      : Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        title: Text(categoryName ?? transaction.categoryId),
        subtitle: transaction.note != null && transaction.note!.isNotEmpty
            ? Text(
                transaction.note!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isExpense ? "-" : "+"}${transaction.amount}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isExpense ? Colors.red : Colors.green,
              ),
            ),
            Text(
              _formatTime(transaction.timestamp),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, "0")}:${dt.minute.toString().padLeft(2, "0")}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    }
    return '${dt.month}/${dt.day}';
  }
}
