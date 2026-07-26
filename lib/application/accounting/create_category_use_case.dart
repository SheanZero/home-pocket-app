import 'package:uuid/uuid.dart';

import '../../features/accounting/domain/models/category.dart';
import '../../features/accounting/domain/models/category_ledger_config.dart';
import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/repositories/category_ledger_config_repository.dart';
import '../../features/accounting/domain/repositories/category_repository.dart';
import '../../features/settings/domain/repositories/unit_of_work.dart';
import '../../shared/utils/result.dart';

enum CreateCategoryFailure {
  emptyName,
  nameTooLong,
  duplicateName,
  invalidParent,
  missingLedgerType,
  persistence,
}

class CreateCategoryParams {
  const CreateCategoryParams({
    required this.name,
    this.parentId,
    this.ledgerType,
  });

  final String name;
  final String? parentId;
  final LedgerType? ledgerType;
}

/// Creates custom L1/L2 categories while preserving the ledger invariant.
///
/// Every L1 is written together with its mandatory ledger configuration in a
/// single [UnitOfWork]. L2 categories inherit the parent L1's ledger and visual
/// identity, so they do not create a redundant config row.
class CreateCategoryUseCase {
  CreateCategoryUseCase({
    required CategoryRepository categoryRepository,
    required CategoryLedgerConfigRepository ledgerConfigRepository,
    required UnitOfWork unitOfWork,
    String Function()? idGenerator,
    DateTime Function()? clock,
  }) : _categoryRepository = categoryRepository,
       _ledgerConfigRepository = ledgerConfigRepository,
       _unitOfWork = unitOfWork,
       _idGenerator = idGenerator ?? const Uuid().v4,
       _clock = clock ?? DateTime.now;

  static const maxNameLength = 50;
  static const _defaultL1Icon = 'category';
  static const _defaultL1Color = '#47B88A';

  final CategoryRepository _categoryRepository;
  final CategoryLedgerConfigRepository _ledgerConfigRepository;
  final UnitOfWork _unitOfWork;
  final String Function() _idGenerator;
  final DateTime Function() _clock;

  Future<Result<Category>> execute(CreateCategoryParams params) async {
    final name = params.name.trim();
    if (name.isEmpty) {
      return Result.error(CreateCategoryFailure.emptyName.name);
    }
    if (name.length > maxNameLength) {
      return Result.error(CreateCategoryFailure.nameTooLong.name);
    }

    final active = await _categoryRepository.findActive();
    final parentId = params.parentId;
    Category? parent;
    if (parentId != null) {
      for (final category in active) {
        if (category.id == parentId) {
          parent = category;
          break;
        }
      }
      if (parent == null || parent.level != 1 || parent.isArchived) {
        return Result.error(CreateCategoryFailure.invalidParent.name);
      }
    } else if (params.ledgerType == null) {
      return Result.error(CreateCategoryFailure.missingLedgerType.name);
    }

    final siblings = active.where(
      (category) => parentId == null
          ? category.level == 1
          : category.level == 2 && category.parentId == parentId,
    );
    final normalizedName = name.toLowerCase();
    if (siblings.any(
      (category) => category.name.trim().toLowerCase() == normalizedName,
    )) {
      return Result.error(CreateCategoryFailure.duplicateName.name);
    }

    final now = _clock();
    final nextSortOrder =
        siblings.fold<int>(
          -1,
          (current, category) =>
              category.sortOrder > current ? category.sortOrder : current,
        ) +
        1;
    final category = Category(
      id: _idGenerator(),
      name: name,
      icon: parent?.icon ?? _defaultL1Icon,
      color: parent?.color ?? _defaultL1Color,
      parentId: parentId,
      level: parent == null ? 1 : 2,
      isSystem: false,
      sortOrder: nextSortOrder,
      createdAt: now,
    );

    try {
      await _unitOfWork.run(() async {
        await _categoryRepository.insert(category);
        if (parent == null) {
          await _ledgerConfigRepository.upsert(
            CategoryLedgerConfig(
              categoryId: category.id,
              ledgerType: params.ledgerType!,
              updatedAt: now,
            ),
          );
        }
      });
      return Result.success(category);
    } catch (_) {
      return Result.error(CreateCategoryFailure.persistence.name);
    }
  }
}
