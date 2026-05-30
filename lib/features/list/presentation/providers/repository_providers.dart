import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/list/get_list_transactions_use_case.dart';
import '../../../accounting/presentation/providers/repository_providers.dart'
    show transactionRepositoryProvider;

part 'repository_providers.g.dart';

/// GetListTransactionsUseCase provider.
///
/// Wires the list use case to the single [transactionRepositoryProvider]
/// from the accounting feature — no duplicate repository provider (T-26-02-DP
/// mitigated by importing with a `show` clause).
@riverpod
GetListTransactionsUseCase getListTransactionsUseCase(Ref ref) {
  return GetListTransactionsUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
  );
}
