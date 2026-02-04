import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/application/use_cases/create_transaction_use_case.dart';
import 'package:home_pocket/features/accounting/application/use_cases/get_transactions_use_case.dart';
import 'package:home_pocket/features/accounting/application/use_cases/update_transaction_use_case.dart';
import 'package:home_pocket/features/accounting/application/use_cases/delete_transaction_use_case.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';

part 'transaction_providers.g.dart';

/// Mock Transaction Repository Provider
///
/// TODO: Replace with actual implementation once Data Layer is complete
@riverpod
TransactionRepository transactionRepository(TransactionRepositoryRef ref) {
  // This will be replaced with actual implementation
  // For now, return a mock or throw unimplemented
  throw UnimplementedError(
    'TransactionRepository implementation pending Data Layer completion',
  );
}

/// Mock Category Repository Provider
///
/// TODO: Replace with actual implementation once Data Layer is complete
@riverpod
CategoryRepository categoryRepository(CategoryRepositoryRef ref) {
  // This will be replaced with actual implementation
  throw UnimplementedError(
    'CategoryRepository implementation pending Data Layer completion',
  );
}

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
