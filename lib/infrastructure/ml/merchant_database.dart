import '../../features/accounting/domain/models/transaction.dart';

/// A merchant match result from the MerchantDatabase lookup.
///
/// Defined in infrastructure (lib/infrastructure/ml/) because it is the
/// return type of MerchantDatabase — an infrastructure component.
/// Domain models (VoiceParseResult) store merchant data as primitives
/// to avoid upward infrastructure -> domain dependency violations.
class MerchantMatch {
  final String merchantName;
  final String categoryId;
  final double confidence;
  final LedgerType ledgerType;

  const MerchantMatch({
    required this.merchantName,
    required this.categoryId,
    required this.confidence,
    required this.ledgerType,
  });
}

/// A seed entry in the merchant database.
class _MerchantEntry {
  final String name;
  final List<String> aliases;
  final String categoryId;
  final LedgerType ledgerType;

  const _MerchantEntry({
    required this.name,
    required this.aliases,
    required this.categoryId,
    required this.ledgerType,
  });
}

/// Merchant lookup database.
///
/// Provides fuzzy merchant matching for voice and OCR modules.
/// This is shared merchant lookup used by OCR and voice-input classification.
///
/// Current implementation: seed data (~20 well-known Japanese merchants).
/// Full 500+ merchant list is a backlog item.
class MerchantDatabase {
  static const List<_MerchantEntry> _entries = [
    _MerchantEntry(
      name: 'マクドナルド',
      aliases: ['マック', 'Mac', 'McDonald', 'mcdonalds'],
      categoryId: 'cat_food_dining_out',
      ledgerType: LedgerType.daily,
    ),
    _MerchantEntry(
      name: 'スターバックス',
      aliases: ['スタバ', 'Starbucks', 'starbucks'],
      categoryId: 'cat_food_cafe',
      ledgerType: LedgerType.daily,
    ),
    _MerchantEntry(
      name: '吉野家',
      aliases: ['Yoshinoya', 'yoshinoya'],
      categoryId: 'cat_food_dining_out',
      ledgerType: LedgerType.daily,
    ),
    _MerchantEntry(
      name: 'セブンイレブン',
      aliases: ['セブン', '7-Eleven', '7-11', '7eleven'],
      categoryId: 'cat_food_groceries',
      ledgerType: LedgerType.daily,
    ),
    _MerchantEntry(
      name: 'ファミリーマート',
      aliases: ['ファミマ', 'FamilyMart', 'familymart'],
      categoryId: 'cat_food_groceries',
      ledgerType: LedgerType.daily,
    ),
    _MerchantEntry(
      name: 'ローソン',
      aliases: ['Lawson', 'lawson'],
      categoryId: 'cat_food_groceries',
      ledgerType: LedgerType.daily,
    ),
    _MerchantEntry(
      name: 'ユニクロ',
      aliases: ['Uniqlo', 'UNIQLO', 'uniqlo'],
      // D-04 ID drift fix: prior id was a non-existent L1 (shopping bucket) → silently null on findById. Now points at L2 cat_clothing_clothes.
      categoryId: 'cat_clothing_clothes',
      ledgerType: LedgerType.joy,
    ),
    _MerchantEntry(
      name: 'ニトリ',
      aliases: ['Nitori', 'nitori'],
      categoryId: 'cat_housing_furniture',
      ledgerType: LedgerType.daily,
    ),
    _MerchantEntry(
      name: 'ヤマダ電機',
      aliases: ['ヤマダ', 'Yamada', 'yamada'],
      // D-04 ID drift fix: prior id was a non-existent L1 (shopping bucket) → silently null on findById. Now points at L2 cat_housing_appliances.
      categoryId: 'cat_housing_appliances',
      ledgerType: LedgerType.joy,
    ),
    _MerchantEntry(
      name: 'すき家',
      aliases: ['Sukiya', 'sukiya'],
      categoryId: 'cat_food_dining_out',
      ledgerType: LedgerType.daily,
    ),
    _MerchantEntry(
      name: 'Amazon',
      aliases: ['アマゾン', 'amazon'],
      // D-04 ID drift fix: prior id was a non-existent L1 (shopping bucket) → silently null on findById. Now points at L2 cat_daily_other.
      categoryId: 'cat_daily_other',
      ledgerType: LedgerType.joy,
    ),
    _MerchantEntry(
      name: 'Netflix',
      aliases: ['ネットフリックス', 'netflix'],
      // D-04 ID drift fix: prior id was a non-existent L1 (entertainment bucket) → silently null on findById. Now points at L2 cat_hobbies_subscription.
      categoryId: 'cat_hobbies_subscription',
      ledgerType: LedgerType.joy,
    ),
  ];

  /// Find a merchant by name, alias, or substring match.
  ///
  /// Tries exact name match first, then alias match, then substring match.
  /// Returns the first match or null if none found.
  MerchantMatch? findMerchant(String query) {
    if (query.isEmpty) return null;

    final lowerQuery = query.toLowerCase();

    // 1. Exact name match
    for (final entry in _entries) {
      if (entry.name.toLowerCase() == lowerQuery) {
        return _toMatch(entry);
      }
    }

    // 2. Alias match
    for (final entry in _entries) {
      for (final alias in entry.aliases) {
        if (alias.toLowerCase() == lowerQuery) {
          return _toMatch(entry);
        }
      }
    }

    // 3. Substring match (query contains entry name, or entry name contains query)
    // IN-03 guard (Phase 23 D-13): skip substring matching for queries shorter
    // than 3 chars because single/double-char queries match too many false
    // positives (e.g., 'a' matches 'amazon' via 'amazon'.contains('a')).
    // Exact-match pass (steps 1+2 above) is unaffected by this guard.
    if (lowerQuery.length < 3) return null;

    for (final entry in _entries) {
      if (lowerQuery.contains(entry.name.toLowerCase()) ||
          entry.name.toLowerCase().contains(lowerQuery)) {
        return _toMatch(entry);
      }
      for (final alias in entry.aliases) {
        if (lowerQuery.contains(alias.toLowerCase()) ||
            alias.toLowerCase().contains(lowerQuery)) {
          return _toMatch(entry);
        }
      }
    }

    return null;
  }

  MerchantMatch _toMatch(_MerchantEntry entry) {
    return MerchantMatch(
      merchantName: entry.name,
      categoryId: entry.categoryId,
      confidence: 0.90,
      ledgerType: entry.ledgerType,
    );
  }
}
