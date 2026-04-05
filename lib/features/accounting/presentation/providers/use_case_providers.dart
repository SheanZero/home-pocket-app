import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/accounting/category_service.dart';
import '../../../../application/accounting/create_transaction_use_case.dart';
import '../../../../application/accounting/delete_transaction_use_case.dart';
import '../../../../application/accounting/ensure_default_book_use_case.dart';
import '../../../../application/accounting/get_transactions_use_case.dart';
import '../../../../application/accounting/merchant_category_learning_service.dart';
import '../../../../application/accounting/seed_categories_use_case.dart';
import '../../../../application/dual_ledger/providers.dart';
import '../../../../application/voice/record_category_correction_use_case.dart';
// ignore: deprecated_member_use_from_same_package
import '../../../../application/dual_ledger/resolve_ledger_type_service.dart';
import '../../../../features/family_sync/presentation/providers/sync_providers.dart';
import '../../../../infrastructure/crypto/providers.dart';
import 'repository_providers.dart';

part 'use_case_providers.g.dart';

@riverpod
CreateTransactionUseCase createTransactionUseCase(Ref ref) {
  return CreateTransactionUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    categoryRepository: ref.watch(categoryRepositoryProvider),
    deviceIdentityRepository: ref.watch(deviceIdentityRepositoryProvider),
    hashChainService: ref.watch(hashChainServiceProvider),
    classificationService: ref.watch(classificationServiceProvider),
    syncEngine: ref.watch(syncEngineProvider),
    changeTracker: ref.watch(transactionChangeTrackerProvider),
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
    syncEngine: ref.watch(syncEngineProvider),
    changeTracker: ref.watch(transactionChangeTrackerProvider),
  );
}

@riverpod
SeedCategoriesUseCase seedCategoriesUseCase(Ref ref) {
  return SeedCategoriesUseCase(
    categoryRepository: ref.watch(categoryRepositoryProvider),
    ledgerConfigRepository: ref.watch(categoryLedgerConfigRepositoryProvider),
  );
}

@riverpod
CategoryService categoryService(Ref ref) {
  return CategoryService(
    categoryRepository: ref.watch(categoryRepositoryProvider),
    ledgerConfigRepository: ref.watch(categoryLedgerConfigRepositoryProvider),
  );
}

// ignore: deprecated_member_use_from_same_package
@riverpod
ResolveLedgerTypeService resolveLedgerTypeService(Ref ref) {
  // ignore: deprecated_member_use_from_same_package
  return ResolveLedgerTypeService(
    categoryRepository: ref.watch(categoryRepositoryProvider),
    ledgerConfigRepository: ref.watch(categoryLedgerConfigRepositoryProvider),
  );
}

@riverpod
EnsureDefaultBookUseCase ensureDefaultBookUseCase(Ref ref) {
  return EnsureDefaultBookUseCase(
    bookRepository: ref.watch(bookRepositoryProvider),
    deviceIdentityRepository: ref.watch(deviceIdentityRepositoryProvider),
  );
}

@riverpod
MerchantCategoryLearningService merchantCategoryLearningService(Ref ref) {
  return MerchantCategoryLearningService(
    repository: ref.watch(merchantCategoryPreferenceRepositoryProvider),
    categoryRepository: ref.watch(categoryRepositoryProvider),
  );
}

@riverpod
RecordCategoryCorrectionUseCase recordCategoryCorrectionUseCase(Ref ref) {
  return RecordCategoryCorrectionUseCase(
    preferenceRepository: ref.watch(
      categoryKeywordPreferenceRepositoryProvider,
    ),
  );
}
