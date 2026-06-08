import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/accounting/repository_providers.dart'
    as app_accounting;
import '../../../../data/daos/shopping_item_dao.dart';
import '../../../../data/repositories/shopping_item_repository_impl.dart';
import '../../domain/repositories/shopping_item_repository.dart';

part 'repository_providers.g.dart';

/// ShoppingItemRepository provider.
///
/// Uses [ShoppingItemRepositoryImpl] wired with the application-layer database
/// and field encryption service.
@riverpod
ShoppingItemRepository shoppingItemRepository(Ref ref) {
  final database = ref.watch(app_accounting.appAppDatabaseProvider);
  final dao = ShoppingItemDao(database);
  final encryptionService = ref.watch(
    app_accounting.appFieldEncryptionServiceProvider,
  );
  return ShoppingItemRepositoryImpl(
    dao: dao,
    encryptionService: encryptionService,
  );
}
