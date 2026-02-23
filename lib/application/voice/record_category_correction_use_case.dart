import '../../features/accounting/domain/repositories/category_keyword_preference_repository.dart';

/// Records a user's category correction for voice input learning.
///
/// Called when the user changes the auto-matched category on
/// TransactionConfirmScreen. Increments the hitCount for the
/// (keyword, categoryId) pair in the learning table.
class RecordCategoryCorrectionUseCase {
  final CategoryKeywordPreferenceRepository _preferenceRepository;

  RecordCategoryCorrectionUseCase({
    required CategoryKeywordPreferenceRepository preferenceRepository,
  }) : _preferenceRepository = preferenceRepository;

  /// Records that [keyword] should map to [correctedCategoryId].
  ///
  /// Does nothing if [keyword] is empty.
  Future<void> execute({
    required String keyword,
    required String correctedCategoryId,
  }) async {
    if (keyword.isEmpty) return;

    await _preferenceRepository.recordCorrection(
      keyword: keyword,
      categoryId: correctedCategoryId,
    );
  }
}
