import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/daos/book_dao.dart';
import 'package:home_pocket/data/daos/category_dao.dart';
import 'package:home_pocket/data/repositories/transaction_repository_impl.dart';
import 'package:home_pocket/data/repositories/book_repository_impl.dart';
import 'package:home_pocket/features/accounting/data/repositories/category_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/book_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';

part 'repository_providers.g.dart';

/// Provides the main AppDatabase instance
///
/// TODO: In production, replace with encrypted executor:
/// ```dart
/// final keyManager = ref.watch(keyManagerProvider);
/// final executor = await createEncryptedExecutor(keyManager);
/// return AppDatabase(executor);
/// ```
///
/// For now, using in-memory database for development and testing.
@riverpod
AppDatabase appDatabase(AppDatabaseRef ref) {
  final executor = NativeDatabase.memory();
  return AppDatabase(executor);
}

/// Provides TransactionRepository implementation
///
/// Dependencies:
/// - AppDatabase for data access
/// - TransactionDao for database operations
/// - FieldEncryptionService for sensitive field encryption
/// - HashChainService for transaction integrity
@riverpod
TransactionRepository transactionRepository(TransactionRepositoryRef ref) {
  final database = ref.watch(appDatabaseProvider);
  final dao = TransactionDao(database);
  final encryptionService = ref.watch(fieldEncryptionServiceProvider);
  final hashChainService = ref.watch(hashChainServiceProvider);

  return TransactionRepositoryImpl(
    database: database,
    dao: dao,
    encryptionService: encryptionService,
    hashChainService: hashChainService,
  );
}

/// Provides CategoryRepository implementation
///
/// Dependencies:
/// - AppDatabase for data access
/// - CategoryDao for database operations
@riverpod
CategoryRepository categoryRepository(CategoryRepositoryRef ref) {
  final database = ref.watch(appDatabaseProvider);
  final dao = CategoryDao(database);

  return CategoryRepositoryImpl(dao);
}

/// Provides BookRepository implementation
///
/// Dependencies:
/// - AppDatabase for data access
/// - BookDao for database operations
@riverpod
BookRepository bookRepository(BookRepositoryRef ref) {
  final database = ref.watch(appDatabaseProvider);
  final dao = BookDao(database);

  return BookRepositoryImpl(dao);
}
