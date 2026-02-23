import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/models/voice_parse_result.dart';
import '../../features/accounting/domain/repositories/category_keyword_preference_repository.dart';
import '../../features/accounting/domain/repositories/category_repository.dart';
import '../accounting/category_service.dart';
import 'levenshtein.dart';

/// Multi-signal category matcher for voice input.
///
/// Runs three scoring signals in parallel and picks the highest match:
/// 1. Seed keyword match (existing hardcoded keyword map)
/// 2. Edit distance match (fuzzy against DB category names)
/// 3. User learned mapping (from correction history)
class FuzzyCategoryMatcher {
  final CategoryRepository _categoryRepository;
  final CategoryKeywordPreferenceRepository _preferenceRepository;
  final CategoryService _categoryService;

  FuzzyCategoryMatcher({
    required CategoryRepository categoryRepository,
    required CategoryKeywordPreferenceRepository preferenceRepository,
    required CategoryService categoryService,
  })  : _categoryRepository = categoryRepository,
        _preferenceRepository = preferenceRepository,
        _categoryService = categoryService;

  /// Matches [inputText] to a category using multi-signal scoring.
  ///
  /// [extractedKeyword] is the category-relevant word extracted from input
  /// (with amount, date, merchant removed).
  /// Returns null if no signal produces a match.
  Future<CategoryMatchResult?> match(
    String inputText,
    String extractedKeyword,
  ) async {
    if (extractedKeyword.isEmpty && inputText.isEmpty) return null;

    final keyword =
        extractedKeyword.isNotEmpty ? extractedKeyword : inputText;

    // Run all three signals
    final seedResult = await _matchSeedKeywords(inputText);
    final editDistResult = await _matchEditDistance(keyword);
    final learnedResult = await _matchLearned(keyword);

    // Collect all candidates with their scores
    final candidates = <_ScoredCandidate>[];

    if (seedResult != null) {
      candidates.add(_ScoredCandidate(
        categoryId: seedResult.categoryId,
        baseScore: seedResult.confidence,
        source: MatchSource.keyword,
      ));
    }

    if (editDistResult != null) {
      candidates.add(_ScoredCandidate(
        categoryId: editDistResult.categoryId,
        baseScore: editDistResult.confidence,
        source: MatchSource.keyword,
      ));
    }

    if (learnedResult != null) {
      candidates.add(_ScoredCandidate(
        categoryId: learnedResult.categoryId,
        baseScore: learnedResult.confidence,
        source: MatchSource.learning,
      ));
    }

    if (candidates.isEmpty) return null;

    // Apply learning bonus: if a learned mapping exists for this keyword,
    // boost candidates that match the learned categoryId.
    final learnedPrefs = await _preferenceRepository.findByKeyword(keyword);
    for (final candidate in candidates) {
      for (final pref in learnedPrefs) {
        if (pref.categoryId == candidate.categoryId) {
          candidate.learningBonus = pref.scoreBonus;
          if (pref.isLearned) {
            candidate.source = MatchSource.learning;
          }
        }
      }
    }

    // Pick highest scoring candidate
    candidates.sort((a, b) => b.finalScore.compareTo(a.finalScore));
    final best = candidates.first;

    // Minimum threshold: 0.5
    if (best.finalScore < 0.5) return null;

    return CategoryMatchResult(
      categoryId: best.categoryId,
      confidence: best.finalScore.clamp(0.0, 1.0),
      source: best.source,
    );
  }

  /// Resolves the ledger type for [categoryId].
  Future<LedgerType?> resolveLedgerType(String categoryId) async {
    return _categoryService.resolveLedgerType(categoryId);
  }

  // ── Signal 1: Seed Keyword Match ──

  /// Matches text against the hardcoded seed keyword map.
  Future<CategoryMatchResult?> _matchSeedKeywords(String text) async {
    final lowerText = text.toLowerCase();
    CategoryMatchResult? bestMatch;

    for (final entry in _seedKeywordMap.entries) {
      if (lowerText.contains(entry.key.toLowerCase())) {
        final mapping = entry.value;
        final subId = mapping.sub;

        // Validate sub-category exists; fall back to L1 if not
        String effectiveId = mapping.categoryId;
        if (subId != null) {
          final subCategory = await _categoryRepository.findById(subId);
          if (subCategory != null) {
            effectiveId = subId;
          }
        } else {
          final category =
              await _categoryRepository.findById(mapping.categoryId);
          if (category == null) continue;
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

  // ── Signal 2: Edit Distance Match ──

  /// Fuzzy-matches keyword against all category names in the database.
  Future<CategoryMatchResult?> _matchEditDistance(String keyword) async {
    if (keyword.isEmpty) return null;

    final categories = await _categoryRepository.findAll();
    CategoryMatchResult? bestMatch;

    // Single-char tokens are too ambiguous for fuzzy matching
    final threshold = keyword.length <= 1 ? 0.8 : 0.6;

    for (final category in categories) {
      if (category.isArchived) continue;

      final similarity = normalizedSimilarity(
        keyword.toLowerCase(),
        category.name.toLowerCase(),
      );

      if (similarity >= threshold) {
        final score = similarity * 0.85; // scale factor
        if (bestMatch == null || score > bestMatch.confidence) {
          bestMatch = CategoryMatchResult(
            categoryId: category.id,
            confidence: score,
            source: MatchSource.keyword,
          );
        }
      }
    }

    return bestMatch;
  }

  // ── Signal 3: Learned Mapping ──

  /// Looks up learned preference for this keyword.
  Future<CategoryMatchResult?> _matchLearned(String keyword) async {
    if (keyword.isEmpty) return null;

    final pref = await _preferenceRepository.suggestForKeyword(keyword);
    if (pref == null) return null;

    // Validate category still exists
    final category = await _categoryRepository.findById(pref.categoryId);
    if (category == null) return null;

    // Base score from keyword or edit distance (use 0.85 as baseline)
    // Plus learning bonus
    return CategoryMatchResult(
      categoryId: pref.categoryId,
      confidence: (0.85 + pref.scoreBonus).clamp(0.0, 1.0),
      source: MatchSource.learning,
    );
  }

  // ── Seed keyword map (migrated from CategoryMatcher) ──

  static const Map<String, _KeywordMapping> _seedKeywordMap = {
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
    '電車代':
        _KeywordMapping('cat_transport', 0.95, sub: 'cat_transport_commute'),
    'バス': _KeywordMapping('cat_transport', 0.90, sub: 'cat_transport_commute'),
    'バス代':
        _KeywordMapping('cat_transport', 0.90, sub: 'cat_transport_commute'),
    'タクシー':
        _KeywordMapping('cat_transport', 0.95, sub: 'cat_transport_taxi'),
    '交通費': _KeywordMapping('cat_transport', 0.95),
    '定期': _KeywordMapping('cat_transport', 0.85),
    'Suica': _KeywordMapping('cat_transport', 0.85),
    'PASMO': _KeywordMapping('cat_transport', 0.85),
    '地铁':
        _KeywordMapping('cat_transport', 0.95, sub: 'cat_transport_commute'),
    '公交':
        _KeywordMapping('cat_transport', 0.90, sub: 'cat_transport_commute'),
    '打车': _KeywordMapping('cat_transport', 0.95, sub: 'cat_transport_taxi'),
    'train':
        _KeywordMapping('cat_transport', 0.95, sub: 'cat_transport_commute'),
    'bus':
        _KeywordMapping('cat_transport', 0.90, sub: 'cat_transport_commute'),
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
}

class _KeywordMapping {
  final String categoryId;
  final double confidence;
  final String? sub;

  const _KeywordMapping(this.categoryId, this.confidence, {this.sub});
}

class _ScoredCandidate {
  final String categoryId;
  final double baseScore;
  MatchSource source;
  double learningBonus = 0.0;

  _ScoredCandidate({
    required this.categoryId,
    required this.baseScore,
    required this.source,
  });

  double get finalScore => baseScore + learningBonus;
}
