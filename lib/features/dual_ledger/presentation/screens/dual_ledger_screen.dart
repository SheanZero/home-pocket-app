import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/accounting/domain/models/transaction.dart';
import '../../../../features/accounting/presentation/screens/transaction_list_screen.dart';
import '../../../../generated/app_localizations.dart';
import '../providers/ledger_providers.dart';

class DualLedgerScreen extends ConsumerWidget {
  const DualLedgerScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLedger = ref.watch(ledgerViewProvider);

    return DefaultTabController(
      length: 2,
      initialIndex: currentLedger == LedgerType.survival ? 0 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).appName),
          bottom: TabBar(
            onTap: (index) {
              ref
                  .read(ledgerViewProvider.notifier)
                  .switchTo(index == 0 ? LedgerType.survival : LedgerType.soul);
            },
            tabs: [
              Tab(
                icon: Icon(
                  Icons.shield,
                  color: currentLedger == LedgerType.survival
                      ? Colors.blue
                      : null,
                ),
                text: S.of(context).survival,
              ),
              Tab(
                icon: Icon(
                  Icons.auto_awesome,
                  color: currentLedger == LedgerType.soul
                      ? Colors.purple
                      : null,
                ),
                text: S.of(context).soul,
              ),
            ],
          ),
        ),
        body: TransactionListScreen(
          key: ValueKey(currentLedger),
          bookId: bookId,
          ledgerType: currentLedger,
          embedded: true,
        ),
      ),
    );
  }
}
