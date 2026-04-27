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
      expect(match.categoryId, 'cat_shopping');
      expect(match.ledgerType, LedgerType.soul);
      expect(match.confidence, 0.90);
    });

    test('findMerchant matches aliases case-insensitively', () {
      final match = database.findMerchant('mcdonalds');

      expect(match, isNotNull);
      expect(match!.merchantName, 'マクドナルド');
      expect(match.categoryId, 'cat_food');
      expect(match.ledgerType, LedgerType.survival);
    });

    test('findMerchant matches query substrings against names', () {
      final match = database.findMerchant('昨日スターバックスでコーヒー');

      expect(match, isNotNull);
      expect(match!.merchantName, 'スターバックス');
      expect(match.categoryId, 'cat_food');
      expect(match.ledgerType, LedgerType.survival);
    });

    test('findMerchant matches query substrings against aliases', () {
      final match = database.findMerchant('Netflix subscription');

      expect(match, isNotNull);
      expect(match!.merchantName, 'Netflix');
      expect(match.categoryId, 'cat_entertainment');
      expect(match.ledgerType, LedgerType.soul);
    });
  });
}
