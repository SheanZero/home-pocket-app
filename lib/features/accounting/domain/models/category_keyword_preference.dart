/// A learned keyword→category mapping from user voice input corrections.
class CategoryKeywordPreference {
  const CategoryKeywordPreference({
    required this.keyword,
    required this.categoryId,
    required this.hitCount,
    required this.lastUsed,
  });

  /// The normalized keyword from voice input.
  final String keyword;

  /// The category ID the user corrected to.
  final String categoryId;

  /// How many times the user selected this mapping.
  final int hitCount;

  /// When this mapping was last used.
  final DateTime lastUsed;

  /// Whether this mapping is "fully learned" (hitCount >= 2).
  bool get isLearned => hitCount >= 2;

  /// Score bonus for this learned mapping.
  /// hitCount >= 2 → 0.30 (fully learned)
  /// hitCount == 1 → 0.15 (partial)
  double get scoreBonus => isLearned ? 0.30 : 0.15;
}
