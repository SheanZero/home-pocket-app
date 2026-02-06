import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/accounting/create_transaction_use_case.dart';
import '../../../../application/accounting/delete_transaction_use_case.dart';
import '../../../../application/accounting/ensure_default_book_use_case.dart';
import '../../../../application/accounting/get_transactions_use_case.dart';
import '../../../../application/accounting/seed_categories_use_case.dart';
import '../../../../infrastructure/crypto/providers.dart';
import 'repository_providers.dart';

part 'use_case_providers.g.dart';

@riverpod
CreateTransactionUseCase createTransactionUseCase(Ref ref) {
  return CreateTransactionUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    categoryRepository: ref.watch(categoryRepositoryProvider),
    hashChainService: ref.watch(hashChainServiceProvider),
  );
}

@riverpod
GetTransactionsUseCase getTransactionsUseCase(Ref ref) {
  return GetTransactionsUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
  );
}

@riverpod
DeleteTransactionUseCase deleteTransactionUseCase(Ref ref) {
  return DeleteTransactionUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
  );
}

@riverpod
SeedCategoriesUseCase seedCategoriesUseCase(Ref ref) {
  return SeedCategoriesUseCase(
    categoryRepository: ref.watch(categoryRepositoryProvider),
  );
}

@riverpod
EnsureDefaultBookUseCase ensureDefaultBookUseCase(Ref ref) {
  return EnsureDefaultBookUseCase(
    bookRepository: ref.watch(bookRepositoryProvider),
  );
}
