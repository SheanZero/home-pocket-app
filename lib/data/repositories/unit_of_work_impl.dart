import '../../features/settings/domain/repositories/unit_of_work.dart';
import '../app_database.dart';

/// [UnitOfWork] backed by a Drift transaction.
///
/// Drift transactions are zone-scoped, so any repository/DAO call that
/// reaches the same [AppDatabase] inside [run]'s action automatically joins
/// the transaction and rolls back together on failure.
class UnitOfWorkImpl implements UnitOfWork {
  UnitOfWorkImpl({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  @override
  Future<T> run<T>(Future<T> Function() action) => _db.transaction(action);
}
