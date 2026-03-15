import 'package:drift/drift.dart';

/// Stores learned keyword→category mappings from user corrections.
///
/// Primary key is (keyword, categoryId) — one row per unique mapping.
/// hitCount tracks how many times the user selected this mapping;
/// after hitCount >= 2 the mapping is considered "learned".
@DataClassName('CategoryKeywordPreferenceRow')
class CategoryKeywordPreferences extends Table {
  /// Normalized keyword extracted from voice input.
  TextColumn get keyword => text()();

  /// The category ID the user corrected to.
  TextColumn get categoryId => text()();

  /// Number of times the user selected this mapping.
  IntColumn get hitCount => integer().withDefault(const Constant(1))();

  /// When this mapping was last used/updated.
  DateTimeColumn get lastUsed => dateTime()();

  @override
  Set<Column> get primaryKey => {keyword, categoryId};

  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_keyword_prefs_keyword', columns: {#keyword}),
  ];
}
