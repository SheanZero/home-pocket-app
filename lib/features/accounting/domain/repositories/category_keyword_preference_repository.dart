import '../models/category_keyword_preference.dart';

/// Repository interface for keyword→category learning data.
abstract class CategoryKeywordPreferenceRepository {
  /// Find all learned mappings for a given keyword.
  Future<List<CategoryKeywordPreference>> findByKeyword(String keyword);

  /// Record a user correction: keyword was mapped to categoryId.
  /// Increments hitCount if mapping already exists.
  Future<void> recordCorrection({
    required String keyword,
    required String categoryId,
  });

  /// Suggest the best category for a keyword based on learning data.
  /// Returns null if no learned mapping exists.
  Future<CategoryKeywordPreference?> suggestForKeyword(String keyword);

  /// Decay stale preferences older than [staleDuration].
  Future<void> decayStalePreferences(Duration staleDuration);
}
