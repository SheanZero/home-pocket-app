import 'package:home_pocket/features/accounting/application/use_cases/create_transaction_use_case.dart';
import 'package:home_pocket/features/accounting/application/use_cases/delete_transaction_use_case.dart';
import 'package:home_pocket/features/accounting/application/use_cases/get_transactions_use_case.dart';
import 'package:home_pocket/features/accounting/application/use_cases/update_transaction_use_case.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transaction_providers.g.dart';

/// Create Transaction Use Case Provider
@riverpod
CreateTransactionUseCase createTransactionUseCase(
  CreateTransactionUseCaseRef ref,
) {
  return CreateTransactionUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    categoryRepository: ref.watch(categoryRepositoryProvider),
    hashChainService: ref.watch(hashChainServiceProvider),
  );
}

/// Get Transactions Use Case Provider
@riverpod
GetTransactionsUseCase getTransactionsUseCase(
  GetTransactionsUseCaseRef ref,
) {
  return GetTransactionsUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    fieldEncryptionService: ref.watch(fieldEncryptionServiceProvider),
  );
}

/// Update Transaction Use Case Provider
@riverpod
UpdateTransactionUseCase updateTransactionUseCase(
  UpdateTransactionUseCaseRef ref,
) {
  return UpdateTransactionUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    categoryRepository: ref.watch(categoryRepositoryProvider),
  );
}

/// Delete Transaction Use Case Provider
@riverpod
DeleteTransactionUseCase deleteTransactionUseCase(
  DeleteTransactionUseCaseRef ref,
) {
  return DeleteTransactionUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
  );
}
