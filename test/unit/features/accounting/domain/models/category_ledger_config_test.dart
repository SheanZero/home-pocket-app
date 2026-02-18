import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/category_ledger_config.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';

void main() {
  group('CategoryLedgerConfig', () {
    test('creates with required fields', () {
      final now = DateTime(2026, 2, 18);
      final config = CategoryLedgerConfig(
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        updatedAt: now,
      );

      expect(config.categoryId, 'cat_food');
      expect(config.ledgerType, LedgerType.survival);
      expect(config.updatedAt, now);
    });

    test('serializes to and from JSON', () {
      final now = DateTime(2026, 2, 18);
      final config = CategoryLedgerConfig(
        categoryId: 'cat_entertainment',
        ledgerType: LedgerType.soul,
        updatedAt: now,
      );

      final json = config.toJson();
      final restored = CategoryLedgerConfig.fromJson(json);

      expect(restored.categoryId, config.categoryId);
      expect(restored.ledgerType, config.ledgerType);
    });

    test('copyWith creates new instance', () {
      final config = CategoryLedgerConfig(
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        updatedAt: DateTime(2026, 2, 18),
      );

      final updated = config.copyWith(ledgerType: LedgerType.soul);
      expect(updated.ledgerType, LedgerType.soul);
      expect(updated.categoryId, 'cat_food');
    });
  });
}
