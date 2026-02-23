import '../../features/accounting/domain/models/category_keyword_preference.dart';
import '../../features/accounting/domain/repositories/category_keyword_preference_repository.dart';
import '../app_database.dart';
import '../daos/category_keyword_preference_dao.dart';

class CategoryKeywordPreferenceRepositoryImpl
    implements CategoryKeywordPreferenceRepository {
  CategoryKeywordPreferenceRepositoryImpl({
    required CategoryKeywordPreferenceDao dao,
  }) : _dao = dao;

  final CategoryKeywordPreferenceDao _dao;

  @override
  Future<List<CategoryKeywordPreference>> findByKeyword(
    String keyword,
  ) async {
    final rows = await _dao.findByKeyword(keyword);
    return rows.map(_toModel).toList();
  }

  @override
  Future<void> recordCorrection({
    required String keyword,
    required String categoryId,
  }) async {
    await _dao.upsert(keyword: keyword, categoryId: categoryId);
  }

  @override
  Future<CategoryKeywordPreference?> suggestForKeyword(
    String keyword,
  ) async {
    final rows = await _dao.findByKeyword(keyword);
    if (rows.isEmpty) return null;
    // Return highest hitCount entry (already ordered by DAO)
    return _toModel(rows.first);
  }

  @override
  Future<void> decayStalePreferences(Duration staleDuration) async {
    await _dao.decayStalePreferences(staleDuration);
  }

  CategoryKeywordPreference _toModel(CategoryKeywordPreferenceRow row) {
    return CategoryKeywordPreference(
      keyword: row.keyword,
      categoryId: row.categoryId,
      hitCount: row.hitCount,
      lastUsed: row.lastUsed,
    );
  }
}
