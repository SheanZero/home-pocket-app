import '../../features/accounting/domain/models/category_sync_snapshot.dart';
import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/repositories/category_sync_repository.dart';
import '../../shared/constants/default_categories.dart';
import '../app_database.dart';
import '../daos/category_dao.dart';

class CategorySyncRepositoryImpl implements CategorySyncRepository {
  CategorySyncRepositoryImpl({required this._dao});

  final CategoryDao _dao;
  static final _systemIds = DefaultCategories.all
      .map((entry) => entry.id)
      .toSet();

  @override
  Future<List<CategorySyncSnapshot>> buildReferenceSnapshots({
    required String categoryId,
    required String fallbackOriginDeviceId,
    required LedgerType ledgerTypeHint,
  }) async {
    final selected = await _dao.findById(categoryId);
    if (selected == null ||
        selected.isSystem ||
        _systemIds.contains(categoryId)) {
      return const [];
    }
    final rows = <CategoryRow>[];
    final parentId = selected.parentId;
    if (parentId != null) {
      final parent = await _dao.findById(parentId);
      if (parent != null &&
          !parent.isSystem &&
          !_systemIds.contains(parent.id)) {
        rows.add(parent);
      }
    }
    rows.add(selected);
    return rows
        .map(
          (row) => _toSnapshot(
            row,
            fallbackOriginDeviceId: fallbackOriginDeviceId,
            ledgerTypeHint: ledgerTypeHint,
          ),
        )
        .toList();
  }

  @override
  Future<void> applyReferenceSnapshots(
    List<CategorySyncSnapshot> snapshots,
  ) async {
    final rows = <CategoryRow>[];
    for (final snapshot in [
      ...snapshots,
    ]..sort((a, b) => a.level.compareTo(b.level))) {
      if (_systemIds.contains(snapshot.id)) continue;
      rows.add(
        CategoryRow(
          id: snapshot.id,
          name: snapshot.name,
          icon: snapshot.icon,
          color: snapshot.color,
          parentId: snapshot.parentId,
          level: snapshot.level,
          isSystem: false,
          // Personal preferences never cross the family wire.
          isArchived: false,
          sortOrder: 0,
          sharedRevision: snapshot.revision,
          sharedOriginDeviceId: snapshot.originDeviceId,
          sharedIsDeleted: snapshot.isDeleted,
          createdAt: snapshot.createdAt,
          updatedAt: snapshot.updatedAt,
        ),
      );
    }
    await _dao.applySharedSnapshots(rows);
  }

  CategorySyncSnapshot _toSnapshot(
    CategoryRow row, {
    required String fallbackOriginDeviceId,
    required LedgerType ledgerTypeHint,
  }) {
    final effectiveTime = row.updatedAt ?? row.createdAt;
    return CategorySyncSnapshot(
      id: row.id,
      name: row.name,
      icon: row.icon,
      color: row.color,
      parentId: row.parentId,
      level: row.level,
      revision: row.sharedRevision > 0
          ? row.sharedRevision
          : effectiveTime.toUtc().microsecondsSinceEpoch,
      originDeviceId: row.sharedOriginDeviceId.isNotEmpty
          ? row.sharedOriginDeviceId
          : fallbackOriginDeviceId,
      isDeleted: row.sharedIsDeleted,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      ledgerTypeHint: ledgerTypeHint,
    );
  }
}
