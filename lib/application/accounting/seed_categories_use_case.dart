import '../../features/accounting/domain/repositories/category_repository.dart';
import '../../shared/constants/default_categories.dart';
import '../../shared/utils/result.dart';

/// Seeds default system categories if none exist.
///
/// Called during app initialization. Idempotent — does nothing
/// if categories are already present.
class SeedCategoriesUseCase {
  SeedCategoriesUseCase({
    required CategoryRepository categoryRepository,
  }) : _categoryRepo = categoryRepository;

  final CategoryRepository _categoryRepo;

  Future<Result<void>> execute() async {
    final existing = await _categoryRepo.findAll();
    if (existing.isNotEmpty) {
      return Result.success(null);
    }

    await _categoryRepo.insertBatch(DefaultCategories.all);
    return Result.success(null);
  }
}
