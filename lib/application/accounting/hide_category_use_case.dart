import '../../features/accounting/domain/repositories/category_repository.dart';
import '../../features/settings/domain/repositories/unit_of_work.dart';
import '../../shared/utils/result.dart';

enum HideCategoryFailure { notFound, persistence }

/// Hides a category from future entry without deleting its historical row.
///
/// L2 categories are hidden individually. Hiding an L1 also hides its direct
/// L2 children so no orphaned child can be selected by manual or voice entry.
/// `isArchived` is a device-local preference and is deliberately independent
/// from the family-sync tombstone fields.
class HideCategoryUseCase {
  HideCategoryUseCase(this._categoryRepository, this._unitOfWork);

  final CategoryRepository _categoryRepository;
  final UnitOfWork _unitOfWork;

  Future<Result<void>> execute(String categoryId) async {
    try {
      final category = await _categoryRepository.findById(categoryId);
      if (category == null) {
        return Result.error(HideCategoryFailure.notFound.name);
      }
      if (category.isArchived) return Result.success(null);

      final children = category.level == 1
          ? await _categoryRepository.findByParent(category.id)
          : const [];

      await _unitOfWork.run(() async {
        for (final child in children) {
          if (!child.isArchived) {
            await _categoryRepository.update(id: child.id, isArchived: true);
          }
        }
        await _categoryRepository.update(id: category.id, isArchived: true);
      });
      return Result.success(null);
    } catch (_) {
      return Result.error(HideCategoryFailure.persistence.name);
    }
  }
}
