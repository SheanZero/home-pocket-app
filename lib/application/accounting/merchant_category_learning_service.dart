import 'dart:developer' as dev;

import '../../features/accounting/domain/repositories/category_repository.dart';
import '../../features/accounting/domain/repositories/merchant_category_preference_repository.dart';

class MerchantCategoryLearningService {
  MerchantCategoryLearningService({
    required MerchantCategoryPreferenceRepository repository,
    required CategoryRepository categoryRepository,
  }) : _repository = repository,
       _categoryRepository = categoryRepository;

  final MerchantCategoryPreferenceRepository _repository;
  final CategoryRepository _categoryRepository;

  String normalizeMerchant(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';

    final normalizedChars = StringBuffer();
    for (final rune in trimmed.runes) {
      if (rune == 0x3000) {
        normalizedChars.writeCharCode(0x20);
        continue;
      }
      if (rune >= 0xFF01 && rune <= 0xFF5E) {
        normalizedChars.writeCharCode(rune - 0xFEE0);
        continue;
      }
      normalizedChars.writeCharCode(rune);
    }

    final normalized = normalizedChars
        .toString()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return normalized;
  }

  Future<String?> suggestCategoryId(String merchantRaw) async {
    final merchantKey = normalizeMerchant(merchantRaw);
    if (merchantKey.isEmpty) return null;
    return _repository.suggestCategoryId(merchantKey);
  }

  Future<void> recordSelection({
    required String merchantRaw,
    required String selectedCategoryId,
  }) async {
    final merchantKey = normalizeMerchant(merchantRaw);
    if (merchantKey.isEmpty) return;

    final category = await _categoryRepository.findById(selectedCategoryId);
    if (category == null || category.level != 2) {
      dev.log(
        'Skip merchant preference update: category must be L2. '
        'categoryId=$selectedCategoryId',
        name: 'MerchantCategoryLearning',
      );
      return;
    }

    await _repository.recordSelection(
      merchantKey: merchantKey,
      selectedCategoryId: selectedCategoryId,
    );
  }
}
