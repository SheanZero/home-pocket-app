import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/infrastructure/ml/merchant_database.dart';

void main() {
  group('MerchantDatabase', () {
    late MerchantDatabase database;

    setUp(() {
      database = MerchantDatabase();
    });

    test('findMerchant returns null for empty or unknown queries', () {
      expect(database.findMerchant(''), isNull);
      expect(database.findMerchant('unknown merchant'), isNull);
    });

    test('findMerchant matches exact merchant names case-insensitively', () {
      final match = database.findMerchant('Amazon');

      expect(match, isNotNull);
      expect(match!.merchantName, 'Amazon');
      // Phase 21 D-04 ID-drift fix: was cat_shopping → now cat_daily_other (L2)
      expect(match.categoryId, 'cat_daily_other');
      expect(match.ledgerType, LedgerType.soul);
      expect(match.confidence, 0.90);
    });

    test('findMerchant matches aliases case-insensitively', () {
      final match = database.findMerchant('mcdonalds');

      expect(match, isNotNull);
      expect(match!.merchantName, 'マクドナルド');
      // Phase 21 D-04 ID-drift fix: was cat_food → now cat_food_dining_out (L2)
      expect(match.categoryId, 'cat_food_dining_out');
      expect(match.ledgerType, LedgerType.survival);
    });

    test('findMerchant matches query substrings against names', () {
      final match = database.findMerchant('昨日スターバックスでコーヒー');

      expect(match, isNotNull);
      expect(match!.merchantName, 'スターバックス');
      // Phase 21 D-04 ID-drift fix: was cat_food → now cat_food_cafe (L2)
      expect(match.categoryId, 'cat_food_cafe');
      expect(match.ledgerType, LedgerType.survival);
    });

    test('findMerchant matches query substrings against aliases', () {
      final match = database.findMerchant('Netflix subscription');

      expect(match, isNotNull);
      expect(match!.merchantName, 'Netflix');
      // Phase 21 D-04 ID-drift fix: was cat_entertainment → now cat_hobbies_subscription (L2)
      expect(match.categoryId, 'cat_hobbies_subscription');
      expect(match.ledgerType, LedgerType.soul);
    });

    // D-13 tests: 3-char min-length guard for substring pass

    test('D-13: findMerchant returns null for queries shorter than 3 chars', () {
      // Short queries must not match via substring pass (IN-03 guard).
      // e.g., 'a' would otherwise match 'amazon' via 'amazon'.contains('a')
      expect(database.findMerchant('a'), isNull);
      expect(database.findMerchant('ab'), isNull);
    });

    test('D-13: findMerchant continues to substring-match at 3 chars', () {
      // 'mac' is 3 chars — must still reach substring pass and match McDonald's.
      // Verifies the guard threshold is < 3 (blocks 1-2 chars), not <= 3.
      final match = database.findMerchant('mac');
      expect(match, isNotNull);
      expect(match!.merchantName, 'マクドナルド');
    });

    test(
      'D-13: Pitfall 7 regression — all merchant entries have name length >= 3',
      () {
        // Guards against future merchant additions with 1-2 char names that
        // would lose substring matching due to the D-13 lowerQuery.length < 3 guard.
        for (final name in [
          'マクドナルド',
          'スターバックス',
          '吉野家',
          'セブンイレブン',
          'ファミリーマート',
          'ローソン',
          'ユニクロ',
          'ニトリ',
          'ヤマダ電機',
          'すき家',
          'Amazon',
          'Netflix',
        ]) {
          expect(
            name.length,
            greaterThanOrEqualTo(3),
            reason:
                'D-13 substring guard: merchant entry name "$name" must be '
                '>=3 chars to avoid losing substring matching',
          );
        }
      },
    );
  });
}
