import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/shared/constants/default_categories.dart';

void main() {
  group('DefaultCategories', () {
    test('has 19 expense L1 categories', () {
      final l1s = DefaultCategories.expenseL1;
      expect(l1s.length, 19);
      expect(l1s.every((c) => c.level == 1), isTrue);
      expect(l1s.every((c) => c.parentId == null), isTrue);
    });

    test('L1 sort order matches PRD \u00a710.0', () {
      final l1s = DefaultCategories.expenseL1;
      expect(l1s[0].id, 'cat_food');
      expect(l1s[1].id, 'cat_daily');
      expect(l1s[2].id, 'cat_transport');
      expect(l1s[3].id, 'cat_hobbies');
      expect(l1s[4].id, 'cat_clothing');
      expect(l1s[5].id, 'cat_social');
      expect(l1s[6].id, 'cat_health');
      expect(l1s[7].id, 'cat_education');
      expect(l1s[8].id, 'cat_cash_card');
      expect(l1s[9].id, 'cat_utilities');
      expect(l1s[10].id, 'cat_communication');
      expect(l1s[11].id, 'cat_housing');
      expect(l1s[12].id, 'cat_car');
      expect(l1s[13].id, 'cat_tax');
      expect(l1s[14].id, 'cat_insurance');
      expect(l1s[15].id, 'cat_special');
      expect(l1s[16].id, 'cat_asset');
      expect(l1s[17].id, 'cat_other_expense');
      expect(l1s[18].id, 'cat_uncategorized');
    });

    test('has 4 income L1 categories', () {
      final l1s = DefaultCategories.incomeL1;
      expect(l1s.length, 4);
      expect(l1s.every((c) => c.level == 1 && c.parentId == null), isTrue);
    });

    test('has 103 expense L2 categories (PRD \u00a710.1\u201310.16)', () {
      final l2s = DefaultCategories.all
          .where((c) => c.level == 2)
          .toList();
      expect(l2s.length, 103);
      expect(l2s.every((c) => c.parentId != null), isTrue);
    });

    test('all L2 categories have valid parentId pointing to an L1', () {
      final l1Ids = DefaultCategories.all
          .where((c) => c.level == 1)
          .map((c) => c.id)
          .toSet();
      final l2s = DefaultCategories.all.where((c) => c.level == 2);
      for (final l2 in l2s) {
        expect(l1Ids.contains(l2.parentId), isTrue,
            reason: '${l2.id} parentId=${l2.parentId} not in L1 set');
      }
    });

    test('no duplicate IDs', () {
      final ids = DefaultCategories.all.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('all categories are isSystem true', () {
      expect(DefaultCategories.all.every((c) => c.isSystem), isTrue);
    });

    test('defaultLedgerConfigs covers all expense L1 categories', () {
      final configIds =
          DefaultCategories.defaultLedgerConfigs.map((c) => c.categoryId).toSet();
      final expenseL1Ids =
          DefaultCategories.expenseL1.map((c) => c.id).toSet();
      expect(configIds.containsAll(expenseL1Ids), isTrue);
    });
  });
}
