import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/state_list_transactions.dart';

/// Loading scaffold for the List tab.
///
/// Consumes [listTransactionsProvider] and shows a [CircularProgressIndicator]
/// while loading or on error. Data rendering is deferred to Phase 28.
class ListScreen extends ConsumerWidget {
  const ListScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(
      listTransactionsProvider(bookId: bookId),
    );

    return transactionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      // Phase 28: replace data branch with ListView of TaggedTransaction tiles
      data: (_) => const Center(child: CircularProgressIndicator()),
    );
  }
}
