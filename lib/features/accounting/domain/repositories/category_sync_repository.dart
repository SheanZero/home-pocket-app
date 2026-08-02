import '../models/category_sync_snapshot.dart';
import '../models/transaction.dart';

/// Persistence boundary for E2EE custom-category reference snapshots.
abstract class CategorySyncRepository {
  /// Returns parent-first snapshots for a referenced custom category.
  /// System categories return an empty list.
  Future<List<CategorySyncSnapshot>> buildReferenceSnapshots({
    required String categoryId,
    required String fallbackOriginDeviceId,
    required LedgerType ledgerTypeHint,
  });

  /// Deterministically merges shared fields while preserving local preferences.
  Future<void> applyReferenceSnapshots(List<CategorySyncSnapshot> snapshots);
}
