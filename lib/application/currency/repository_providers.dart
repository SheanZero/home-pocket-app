import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/daos/exchange_rate_dao.dart';
import '../../data/repositories/exchange_rate_repository_impl.dart';
import '../../features/currency/domain/repositories/exchange_rate_repository.dart';
import '../../infrastructure/security/providers.dart' as security;

part 'repository_providers.g.dart';

/// Application-layer Riverpod provider for [ExchangeRateRepository].
///
/// Returns the [ExchangeRateRepository] interface (not the implementation) so
/// callers depend only on the domain contract (HIGH-02 compliance).
///
/// Wired with the shared [AppDatabase] from security providers following the
/// same `app` prefix convention as accounting/repository_providers.dart.
@riverpod
ExchangeRateRepository appExchangeRateRepository(Ref ref) {
  final db = ref.watch(security.appDatabaseProvider);
  final dao = ExchangeRateDao(db);
  return ExchangeRateRepositoryImpl(dao: dao);
}
