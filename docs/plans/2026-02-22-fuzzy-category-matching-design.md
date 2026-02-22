# Fuzzy Category Matching Design

**Date:** 2026-02-22
**Status:** Draft
**Module:** Voice Input / Category Matching

---

## Problem

Current `CategoryMatcher` has three limitations:

1. **Hardcoded keywords** — The static `_keywordMap` (~70 entries) cannot be extended by users. When users add custom L2 categories, they are invisible to voice matching.
2. **No fuzzy tolerance** — Uses exact `contains()` substring matching. Speech recognition errors (e.g., "朝ご飯" → "朝御飯") break matching entirely.
3. **No learning** — User corrections on TransactionConfirm/edit screens are discarded. The same wrong match repeats every time.

## Requirements

- Match voice input to L2 (sub-category) level
- User-added L2 categories must participate in matching without code changes
- Tolerate speech recognition transcription errors
- Learn from user corrections (adopt new mapping after 2-3 corrections)
- Pure local algorithm, no network, no ML models
- Support all 3 languages (ja, zh, en)

## Approach: Multi-Signal Scoring Engine

Replace the current `CategoryMatcher` with `FuzzyCategoryMatcher` that runs 3 scoring signals in parallel and picks the highest-scoring result.

```
Voice Text → keyword extraction → FuzzyCategoryMatcher
                                     ├── Signal 1: Seed Keyword Match
                                     ├── Signal 2: Edit Distance Match
                                     ├── Signal 3: User Learned Mappings
                                     └── Score Aggregator → Best (L1, L2) match
```

### Signal 1: Seed Keyword Match (Baseline)

Keep the existing `_keywordMap` as seed data. Each keyword maps to `(categoryId, subCategoryId, confidence)`.

- Matching: `normalizedInput.contains(keyword)` (case-insensitive)
- Score: keyword's confidence value (0.80–0.95)
- This provides day-1 functionality for common keywords

The seed keywords remain hardcoded in Dart (no DB migration needed). They serve as the initial "vocabulary" that the system starts with.

### Signal 2: Edit Distance Match (Fuzzy)

Query all L1 + L2 category names from the database. For each category, compute normalized Levenshtein distance between input tokens and category display name.

**Algorithm:**
```
For each category in DB:
  For each locale name (ja, zh, en):
    distance = levenshtein(inputToken, categoryName)
    similarity = 1.0 - (distance / max(inputToken.length, categoryName.length))
    if similarity >= 0.6:
      candidateScore = similarity * 0.85  // scale factor
```

**Key behaviors:**
- "咖啡厅" (user-added L2 name) will match input "咖啡" with similarity ~0.67
- "朝御飯" (speech error) will match "朝ごはん" seed keyword via edit distance
- Short tokens (1-2 chars) require higher similarity threshold (≥ 0.8) to avoid false positives

**Optimization:** Cache category names on first call, invalidate when categories change (watch `categoryListProvider`).

### Signal 3: User Learned Mappings (Adaptive)

When a user corrects a category (on TransactionConfirm or transaction edit screen), the system records `(keyword, chosenCategoryId)` in a learning table.

**Learning rules:**
- `hitCount = 1`: Partial bonus (+0.15 to the base score of that keyword's best signal)
- `hitCount >= 2`: Full learning bonus (+0.30), effectively overrides seed keywords
- Decay: If a learned mapping is not used for 90 days, reduce hitCount by 1 (prevents stale mappings)

**Example flow:**
```
Correction 1: "咖啡" → cat_entertainment_cafe (hitCount: 1)
  Next match: seed=cat_food_snack(0.85), learned=cat_entertainment_cafe(0.85+0.15=1.00)
  → System picks learned mapping

Correction 2: "咖啡" → cat_entertainment_cafe (hitCount: 2, fully learned)
  Next match: learned=cat_entertainment_cafe(0.85+0.30=1.15) → confident match
```

### Score Aggregation

```dart
// For each candidate category:
double finalScore = 0.0;

// Signal 1: Seed keyword
if (seedMatch != null) finalScore = max(finalScore, seedMatch.confidence);

// Signal 2: Edit distance
if (editDistScore >= threshold) finalScore = max(finalScore, editDistScore * 0.85);

// Signal 3: Learned mapping bonus (additive on top of best base score)
if (learnedMapping != null) {
  double bonus = learnedMapping.hitCount >= 2 ? 0.30 : 0.15;
  finalScore += bonus;
}

// Pick category with highest finalScore
```

Simple max-wins strategy with additive learning bonus.

## Keyword Extraction

To match against categories, we need to extract the "category-relevant word" from voice input.

**Strategy:** After the existing `VoiceTextParser` extracts amount, date, and merchant, the remaining text is the keyword candidate.

```dart
String extractKeyword(String input, VoiceParseResult partial) {
  String remaining = input;

  // Remove matched amount text
  if (partial.amountText != null) remaining = remaining.replaceFirst(partial.amountText!, '');

  // Remove matched date text
  if (partial.dateText != null) remaining = remaining.replaceFirst(partial.dateText!, '');

  // Remove matched merchant name
  if (partial.merchantName != null) remaining = remaining.replaceFirst(partial.merchantName!, '');

  // Normalize: trim, remove particles (の, に, で, を, は, が, etc.)
  return normalize(remaining.trim());
}
```

The extracted keyword is:
- Used for signal matching
- Stored as the key in the learning table when user corrects

## Data Layer

### New Drift Table

```dart
// lib/data/tables/category_keyword_preferences.dart
class CategoryKeywordPreferences extends Table {
  TextColumn get keyword => text()();           // normalized keyword
  TextColumn get categoryId => text()();        // chosen L2 (or L1) category ID
  IntColumn get hitCount => integer().withDefault(const Constant(1))();
  DateTimeColumn get lastUsed => dateTime()();

  @override
  Set<Column> get primaryKey => {keyword, categoryId};

  List<TableIndex> get customIndices => [
    TableIndex(
      name: 'idx_keyword_prefs_keyword',
      columns: {#keyword},
    ),
  ];
}
```

### DAO

```dart
// lib/data/daos/category_keyword_preference_dao.dart
@DriftAccessor(tables: [CategoryKeywordPreferences])
class CategoryKeywordPreferenceDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryKeywordPreferenceDaoMixin {

  Future<List<CategoryKeywordPreference>> findByKeyword(String keyword);
  Future<void> upsertPreference(String keyword, String categoryId);
  Future<void> decayStalePreferences(Duration staleDuration);
}
```

### Repository

Interface in `lib/features/accounting/domain/repositories/`, implementation in `lib/data/repositories/`.

## Application Layer

### FuzzyCategoryMatcher

```dart
// lib/application/voice/fuzzy_category_matcher.dart
class FuzzyCategoryMatcher {
  final CategoryRepository categoryRepository;
  final CategoryKeywordPreferenceRepository preferenceRepository;
  final CategoryService categoryService;

  Future<CategoryMatchResult?> match(String inputText, String extractedKeyword);
}
```

### RecordCategoryCorrectionUseCase

```dart
// lib/application/voice/record_category_correction_use_case.dart
class RecordCategoryCorrectionUseCase {
  final CategoryKeywordPreferenceRepository preferenceRepository;

  /// Called when user corrects the auto-matched category
  Future<void> execute({
    required String keyword,
    required String correctedCategoryId,
  });
}
```

## Levenshtein Implementation

Pure Dart, no external dependency:

```dart
// lib/application/voice/levenshtein.dart
int levenshteinDistance(String a, String b) {
  // Standard dynamic programming implementation
  // O(n*m) time, O(min(n,m)) space with rolling array optimization
}

double normalizedSimilarity(String a, String b) {
  if (a.isEmpty && b.isEmpty) return 1.0;
  final dist = levenshteinDistance(a, b);
  return 1.0 - (dist / max(a.length, b.length));
}
```

## Integration Points

### 1. Replace CategoryMatcher in ParseVoiceInputUseCase

Current:
```dart
final categoryMatch = await _categoryMatcher.matchCategory(text);
```

New:
```dart
final keyword = _extractKeyword(text, partialResult);
final categoryMatch = await _fuzzyCategoryMatcher.match(text, keyword);
```

### 2. Record corrections from TransactionConfirm screen

When user changes category on the confirm screen:
```dart
// In TransactionConfirmScreen or its provider
if (userSelectedCategory != autoMatchedCategory) {
  ref.read(recordCategoryCorrectionUseCaseProvider).execute(
    keyword: extractedKeyword,
    correctedCategoryId: userSelectedCategory.id,
  );
}
```

### 3. Record corrections from transaction edit

Same logic when user edits an existing transaction's category.

## Testing Strategy

- Unit test Levenshtein implementation with known distance pairs
- Unit test each signal independently with mocked category data
- Unit test score aggregation with various signal combinations
- Unit test learning: verify hitCount increments, verify score boost at threshold
- Integration test: full pipeline from voice text to matched category
- Edge cases: empty input, single character, all-same characters, mixed language input

## Performance Considerations

- Category name cache: Load all category names once, watch for changes via Riverpod
- Levenshtein on ~50-100 categories is negligible (< 1ms)
- Learning table queries by keyword are indexed
- No background processing needed, all synchronous within the parse pipeline

## Migration Path

1. Add `CategoryKeywordPreferences` table to Drift database (schema version bump)
2. Create `FuzzyCategoryMatcher` alongside existing `CategoryMatcher`
3. Swap `CategoryMatcher` → `FuzzyCategoryMatcher` in `ParseVoiceInputUseCase`
4. Add correction recording in TransactionConfirm and edit screens
5. Remove old `CategoryMatcher` class

## File Structure

```
lib/
├── application/voice/
│   ├── fuzzy_category_matcher.dart      # NEW: Multi-signal matcher
│   ├── levenshtein.dart                 # NEW: Edit distance algorithm
│   ├── record_category_correction_use_case.dart  # NEW: Learning
│   ├── parse_voice_input_use_case.dart  # MODIFIED: Use fuzzy matcher
│   └── category_matcher.dart            # DELETED after migration
├── data/
│   ├── tables/
│   │   └── category_keyword_preferences.dart  # NEW: Learning table
│   ├── daos/
│   │   └── category_keyword_preference_dao.dart  # NEW
│   └── repositories/
│       └── category_keyword_preference_repository_impl.dart  # NEW
├── features/accounting/domain/
│   └── repositories/
│       └── category_keyword_preference_repository.dart  # NEW: Interface
```
