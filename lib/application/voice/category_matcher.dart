import '../../application/accounting/category_service.dart';
import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/models/voice_parse_result.dart';
import '../../features/accounting/domain/repositories/category_repository.dart';

/// Multilingual category matcher for voice input.
///
/// Matches text against a keyword map to suggest a category.
/// Delegates ledger type resolution to [CategoryService].
class CategoryMatcher {
  final CategoryRepository _categoryRepository;
  final CategoryService _categoryService;

  CategoryMatcher({
    required CategoryRepository categoryRepository,
    required CategoryService categoryService,
  })  : _categoryRepository = categoryRepository,
        _categoryService = categoryService;

  /// Multilingual keyword-to-category mapping.
  static const Map<String, _KeywordMapping> _keywordMap = {
    // ===== Food =====
    // Japanese
    '朝ごはん': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_breakfast'),
    '朝食': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_breakfast'),
    '昼ごはん': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_lunch'),
    '昼食': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_lunch'),
    'ランチ': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_lunch'),
    '晩ごはん': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_dinner'),
    '夕食': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_dinner'),
    '夕飯': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_dinner'),
    '食事': _KeywordMapping('cat_food', 0.85),
    'ご飯': _KeywordMapping('cat_food', 0.85),
    '弁当': _KeywordMapping('cat_food', 0.85),
    'コーヒー': _KeywordMapping('cat_food', 0.80),
    'カフェ': _KeywordMapping('cat_food', 0.80),
    'おやつ': _KeywordMapping('cat_food', 0.80),
    // Chinese
    '早饭': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_breakfast'),
    '早餐': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_breakfast'),
    '午饭': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_lunch'),
    '午餐': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_lunch'),
    '晚饭': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_dinner'),
    '晚餐': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_dinner'),
    '吃饭': _KeywordMapping('cat_food', 0.85),
    '外卖': _KeywordMapping('cat_food', 0.85),
    '咖啡': _KeywordMapping('cat_food', 0.80),
    // English
    'breakfast': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_breakfast'),
    'lunch': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_lunch'),
    'dinner': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_dinner'),
    'food': _KeywordMapping('cat_food', 0.85),
    'coffee': _KeywordMapping('cat_food', 0.80),
    'cafe': _KeywordMapping('cat_food', 0.80),

    // ===== Transport =====
    '電車': _KeywordMapping('cat_transport', 0.95, sub: 'cat_transport_commute'),
    '電車代': _KeywordMapping('cat_transport', 0.95, sub: 'cat_transport_commute'),
    'バス': _KeywordMapping('cat_transport', 0.90, sub: 'cat_transport_commute'),
    'バス代': _KeywordMapping('cat_transport', 0.90, sub: 'cat_transport_commute'),
    'タクシー': _KeywordMapping('cat_transport', 0.95, sub: 'cat_transport_taxi'),
    '交通費': _KeywordMapping('cat_transport', 0.95),
    '定期': _KeywordMapping('cat_transport', 0.85),
    'Suica': _KeywordMapping('cat_transport', 0.85),
    'PASMO': _KeywordMapping('cat_transport', 0.85),
    '地铁': _KeywordMapping('cat_transport', 0.95, sub: 'cat_transport_commute'),
    '公交': _KeywordMapping('cat_transport', 0.90, sub: 'cat_transport_commute'),
    '打车': _KeywordMapping('cat_transport', 0.95, sub: 'cat_transport_taxi'),
    'train': _KeywordMapping('cat_transport', 0.95, sub: 'cat_transport_commute'),
    'bus': _KeywordMapping('cat_transport', 0.90, sub: 'cat_transport_commute'),
    'taxi': _KeywordMapping('cat_transport', 0.95, sub: 'cat_transport_taxi'),

    // ===== Shopping =====
    '服': _KeywordMapping('cat_shopping', 0.80),
    '洋服': _KeywordMapping('cat_shopping', 0.85),
    '靴': _KeywordMapping('cat_shopping', 0.85),
    '衣服': _KeywordMapping('cat_shopping', 0.85),
    '鞋子': _KeywordMapping('cat_shopping', 0.85),
    'clothes': _KeywordMapping('cat_shopping', 0.85),
    'shoes': _KeywordMapping('cat_shopping', 0.85),

    // ===== Education =====
    '本': _KeywordMapping('cat_education', 0.80),
    '书': _KeywordMapping('cat_education', 0.80),
    'book': _KeywordMapping('cat_education', 0.80),

    // ===== Entertainment =====
    '映画': _KeywordMapping('cat_entertainment', 0.95),
    'ゲーム': _KeywordMapping('cat_entertainment', 0.90),
    'カラオケ': _KeywordMapping('cat_entertainment', 0.95),
    '電影': _KeywordMapping('cat_entertainment', 0.95),
    '电影': _KeywordMapping('cat_entertainment', 0.95),
    '游戏': _KeywordMapping('cat_entertainment', 0.90),
    'movie': _KeywordMapping('cat_entertainment', 0.95),
    'game': _KeywordMapping('cat_entertainment', 0.90),

    // ===== Medical =====
    '病院': _KeywordMapping('cat_medical', 0.95),
    '薬': _KeywordMapping('cat_medical', 0.90),
    '医院': _KeywordMapping('cat_medical', 0.95),
    '药': _KeywordMapping('cat_medical', 0.90),
    'hospital': _KeywordMapping('cat_medical', 0.95),
    'medicine': _KeywordMapping('cat_medical', 0.90),

    // ===== Housing =====
    '家賃': _KeywordMapping('cat_housing', 0.95),
    '水道': _KeywordMapping('cat_housing', 0.90),
    '電気': _KeywordMapping('cat_housing', 0.90),
    'ガス': _KeywordMapping('cat_housing', 0.90),
    '房租': _KeywordMapping('cat_housing', 0.95),
    '水费': _KeywordMapping('cat_housing', 0.90),
    '电费': _KeywordMapping('cat_housing', 0.90),
    'rent': _KeywordMapping('cat_housing', 0.95),
    'utilities': _KeywordMapping('cat_housing', 0.90),
  };

  /// Matches text against the keyword map to find the best category.
  ///
  /// Returns null if no keyword matches.
  Future<CategoryMatchResult?> matchFromText(String text) async {
    final lowerText = text.toLowerCase();
    CategoryMatchResult? bestMatch;

    for (final entry in _keywordMap.entries) {
      if (lowerText.contains(entry.key.toLowerCase())) {
        final mapping = entry.value;
        final subId = mapping.sub;

        // Validate that sub-category exists; fall back to L1 if not
        String effectiveId = mapping.categoryId;
        if (subId != null) {
          final subCategory = await _categoryRepository.findById(subId);
          if (subCategory != null) {
            effectiveId = subId;
          }
        } else {
          final category = await _categoryRepository.findById(mapping.categoryId);
          if (category == null) {
            continue; // Skip if category doesn't exist
          }
        }

        if (bestMatch == null || mapping.confidence > bestMatch.confidence) {
          bestMatch = CategoryMatchResult(
            categoryId: effectiveId,
            confidence: mapping.confidence,
            source: MatchSource.keyword,
          );
        }
      }
    }

    return bestMatch;
  }

  /// Resolves the ledger type for [categoryId] via [CategoryService].
  Future<LedgerType?> resolveLedgerType(String categoryId) async {
    return _categoryService.resolveLedgerType(categoryId);
  }
}

class _KeywordMapping {
  final String categoryId;
  final double confidence;
  final String? sub;

  const _KeywordMapping(this.categoryId, this.confidence, {this.sub});
}
