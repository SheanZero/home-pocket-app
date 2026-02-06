import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../data/daos/book_dao.dart';
import '../../../../data/daos/category_dao.dart';
import '../../../../data/daos/transaction_dao.dart';
import '../../../../data/repositories/book_repository_impl.dart';
import '../../../../data/repositories/category_repository_impl.dart';
import '../../../../data/repositories/transaction_repository_impl.dart';
import '../../../../infrastructure/crypto/providers.dart';
import '../../../../infrastructure/security/providers.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/transaction_repository.dart';

part 'repository_providers.g.dart';

/// BookRepository provider.
@riverpod
BookRepository bookRepository(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  final dao = BookDao(database);
  return BookRepositoryImpl(dao: dao);
}

/// CategoryRepository provider.
@riverpod
CategoryRepository categoryRepository(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  final dao = CategoryDao(database);
  return CategoryRepositoryImpl(dao: dao);
}

/// TransactionRepository provider.
@riverpod
TransactionRepository transactionRepository(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  final dao = TransactionDao(database);
  final encryptionService = ref.watch(fieldEncryptionServiceProvider);

  return TransactionRepositoryImpl(
    dao: dao,
    encryptionService: encryptionService,
  );
}
