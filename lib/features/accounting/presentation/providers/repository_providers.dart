import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/accounting/category_service.dart';
import '../../../../application/accounting/create_transaction_use_case.dart';
import '../../../../application/accounting/delete_transaction_use_case.dart';
import '../../../../application/accounting/ensure_default_book_use_case.dart';
import '../../../../application/accounting/get_transactions_use_case.dart';
import '../../../../application/accounting/merchant_category_learning_service.dart';
import '../../../../application/accounting/repository_providers.dart' as app_accounting;
import '../../../../application/accounting/seed_categories_use_case.dart';
import '../../../../application/dual_ledger/repository_providers.dart';
import '../../../../application/ml/repository_providers.dart' as app_ml;
import '../../../../application/voice/fuzzy_category_matcher.dart';
import '../../../../application/voice/parse_voice_input_use_case.dart';
import '../../../../application/voice/record_category_correction_use_case.dart';
import '../../../../application/voice/voice_satisfaction_estimator.dart';
import '../../../../application/voice/voice_text_parser.dart';
import '../../../../data/daos/book_dao.dart';
import '../../../../data/daos/category_dao.dart';
import '../../../../data/daos/category_keyword_preference_dao.dart';
import '../../../../data/daos/category_ledger_config_dao.dart';
import '../../../../data/daos/merchant_category_preference_dao.dart';
import '../../../../data/daos/transaction_dao.dart';
import '../../../../data/repositories/book_repository_impl.dart';
import '../../../../data/repositories/category_keyword_preference_repository_impl.dart';
import '../../../../data/repositories/category_ledger_config_repository_impl.dart';
import '../../../../data/repositories/category_repository_impl.dart';
import '../../../../data/repositories/device_identity_repository_impl.dart';
import '../../../../data/repositories/merchant_category_preference_repository_impl.dart';
import '../../../../data/repositories/transaction_repository_impl.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/repositories/category_keyword_preference_repository.dart';
import '../../domain/repositories/category_ledger_config_repository.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/device_identity_repository.dart';
import '../../domain/repositories/merchant_category_preference_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../../family_sync/presentation/providers/state_sync.dart';

part 'repository_providers.g.dart';

// ── Repository providers ──────────────────────────────────────────────────────

/// BookRepository provider.
@riverpod
BookRepository bookRepository(Ref ref) {
  final database = ref.watch(app_accounting.appAppDatabaseProvider);
  final dao = BookDao(database);
  return BookRepositoryImpl(dao: dao);
}

/// CategoryRepository provider.
@riverpod
CategoryRepository categoryRepository(Ref ref) {
  final database = ref.watch(app_accounting.appAppDatabaseProvider);
  final dao = CategoryDao(database);
  return CategoryRepositoryImpl(dao: dao);
}

/// CategoryLedgerConfigRepository provider.
@riverpod
CategoryLedgerConfigRepository categoryLedgerConfigRepository(Ref ref) {
  final database = ref.watch(app_accounting.appAppDatabaseProvider);
  final dao = CategoryLedgerConfigDao(database);
  return CategoryLedgerConfigRepositoryImpl(dao: dao);
}

/// TransactionRepository provider.
@riverpod
TransactionRepository transactionRepository(Ref ref) {
  final database = ref.watch(app_accounting.appAppDatabaseProvider);
  final dao = TransactionDao(database);
  final encryptionService = ref.watch(
    app_accounting.appFieldEncryptionServiceProvider,
  );

  return TransactionRepositoryImpl(
    dao: dao,
    encryptionService: encryptionService,
  );
}

/// MerchantCategoryPreferenceRepository provider.
@riverpod
MerchantCategoryPreferenceRepository merchantCategoryPreferenceRepository(
  Ref ref,
) {
  final database = ref.watch(app_accounting.appAppDatabaseProvider);
  final dao = MerchantCategoryPreferenceDao(database);
  return MerchantCategoryPreferenceRepositoryImpl(dao: dao);
}

/// CategoryKeywordPreferenceRepository provider.
@riverpod
CategoryKeywordPreferenceRepository categoryKeywordPreferenceRepository(
  Ref ref,
) {
  final database = ref.watch(app_accounting.appAppDatabaseProvider);
  final dao = CategoryKeywordPreferenceDao(database);
  return CategoryKeywordPreferenceRepositoryImpl(dao: dao);
}

/// DeviceIdentityRepository provider.
final deviceIdentityRepositoryProvider = Provider<DeviceIdentityRepository>((
  ref,
) {
  final keyManager = ref.watch(app_accounting.appKeyManagerProvider);
  return DeviceIdentityRepositoryImpl(keyManager: keyManager);
});

// ── Use case providers (folded from use_case_providers.dart) ─────────────────

@riverpod
CreateTransactionUseCase createTransactionUseCase(Ref ref) {
  return CreateTransactionUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    categoryRepository: ref.watch(categoryRepositoryProvider),
    deviceIdentityRepository: ref.watch(deviceIdentityRepositoryProvider),
    hashChainService: ref.watch(app_accounting.appHashChainServiceProvider),
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

// ── Voice DI providers (folded from voice_providers.dart) ────────────────────
// NOTE: merchantDatabaseProvider is now appMerchantDatabaseProvider from
// lib/application/ml/repository_providers.dart (keepAlive via Plan 04-01).
// Consumers reference app_ml.appMerchantDatabaseProvider directly.

/// VoiceTextParser — stateless NLP parser, auto-disposed when not in use.
@riverpod
VoiceTextParser voiceTextParser(Ref ref) {
  return VoiceTextParser();
}

/// FuzzyCategoryMatcher — multi-signal category matcher with learning.
@riverpod
FuzzyCategoryMatcher fuzzyCategoryMatcher(Ref ref) {
  return FuzzyCategoryMatcher(
    categoryRepository: ref.watch(categoryRepositoryProvider),
    preferenceRepository: ref.watch(
      categoryKeywordPreferenceRepositoryProvider,
    ),
    categoryService: ref.watch(categoryServiceProvider),
  );
}

/// ParseVoiceInputUseCase — wired to all voice application services.
@riverpod
ParseVoiceInputUseCase parseVoiceInputUseCase(Ref ref) {
  return ParseVoiceInputUseCase(
    textParser: ref.watch(voiceTextParserProvider),
    fuzzyCategoryMatcher: ref.watch(fuzzyCategoryMatcherProvider),
    merchantDatabase: ref.watch(app_ml.appMerchantDatabaseProvider),
  );
}

/// VoiceSatisfactionEstimator — pure stateless class.
@riverpod
VoiceSatisfactionEstimator voiceSatisfactionEstimator(Ref ref) {
  return VoiceSatisfactionEstimator();
}
