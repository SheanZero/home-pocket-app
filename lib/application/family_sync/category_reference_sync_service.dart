import '../../features/accounting/domain/models/category_sync_snapshot.dart';
import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/repositories/category_sync_repository.dart';

/// Attaches and applies custom-category reference snapshots inside E2EE bills.
class CategoryReferenceSyncService {
  CategoryReferenceSyncService({required this._repository});

  final CategorySyncRepository _repository;

  Future<Map<String, dynamic>> attachToBillOperation({
    required Transaction transaction,
    required Map<String, dynamic> operation,
  }) async {
    final List<CategorySyncSnapshot> snapshots;
    try {
      snapshots = await _repository.buildReferenceSnapshots(
        categoryId: transaction.categoryId,
        fallbackOriginDeviceId: transaction.syncOriginDeviceId.isNotEmpty
            ? transaction.syncOriginDeviceId
            : transaction.deviceId,
        ledgerTypeHint: transaction.ledgerType,
      );
    } catch (_) {
      // Local-first: a category lookup failure must not make an already
      // committed bill appear to fail. The bill remains syncable and a later
      // full reconciliation can repair its optional reference snapshot.
      return operation;
    }
    if (snapshots.isEmpty) return operation;
    final result = Map<String, dynamic>.of(operation);
    final rawData = operation['data'];
    if (rawData is! Map<String, dynamic>) return operation;
    result['data'] = Map<String, dynamic>.of(rawData)
      ..['categorySnapshots'] = snapshots
          .map((snapshot) => snapshot.toSyncMap())
          .toList();
    return result;
  }

  Future<void> applyFromBillData(Map<String, dynamic> data) async {
    final raw = data['categorySnapshots'];
    if (raw == null) return;
    if (raw is! List || raw.isEmpty || raw.length > 2) {
      throw const FormatException('invalid category snapshot collection');
    }
    final snapshots = raw.map((entry) {
      if (entry is! Map) {
        throw const FormatException('invalid category snapshot entry');
      }
      return CategorySyncSnapshot.fromSyncMap(Map<String, dynamic>.from(entry));
    }).toList();
    final categoryId = data['categoryId'];
    if (categoryId is! String ||
        !snapshots.any((snapshot) => snapshot.id == categoryId)) {
      throw const FormatException('referenced category snapshot missing');
    }
    final ids = snapshots.map((snapshot) => snapshot.id).toSet();
    if (ids.length != snapshots.length) {
      throw const FormatException('duplicate category snapshot');
    }
    final selected = snapshots.singleWhere(
      (snapshot) => snapshot.id == categoryId,
    );
    if (selected.level == 2 &&
        snapshots.any(
          (snapshot) => snapshot.level == 1 && snapshot.id != selected.parentId,
        )) {
      throw const FormatException('category parent snapshot mismatch');
    }
    await _repository.applyReferenceSnapshots(snapshots);
  }
}
