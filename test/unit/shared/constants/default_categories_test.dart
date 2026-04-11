import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/shared/constants/default_categories.dart';

void main() {
  group('DefaultCategories v2 (Japan-optimized)', () {
    // ─── L1 counts ───
    group('L1 counts', () {
      test('has 19 expense L1 categories', () {
        final l1s = DefaultCategories.expenseL1;
        expect(l1s.length, 19);
        expect(l1s.every((c) => c.level == 1), isTrue);
        expect(l1s.every((c) => c.parentId == null), isTrue);
      });

    });

    // ─── L1 presence & absence ───
    group('L1 presence', () {
      test('contains cat_pet and cat_allowance (new L1s)', () {
        final ids = DefaultCategories.expenseL1.map((c) => c.id).toSet();
        expect(ids, contains('cat_pet'));
        expect(ids, contains('cat_allowance'));
      });

      test('does NOT contain cat_cash_card or cat_uncategorized', () {
        final ids = DefaultCategories.expenseL1.map((c) => c.id).toSet();
        expect(ids, isNot(contains('cat_cash_card')));
        expect(ids, isNot(contains('cat_uncategorized')));
      });

      test('retains all 17 preserved baseline L1s', () {
        final ids = DefaultCategories.expenseL1.map((c) => c.id).toSet();
        const kept = {
          'cat_food', 'cat_daily', 'cat_transport', 'cat_hobbies',
          'cat_clothing', 'cat_social', 'cat_health', 'cat_education',
          'cat_utilities', 'cat_communication', 'cat_housing', 'cat_car',
          'cat_tax', 'cat_insurance', 'cat_special', 'cat_asset',
          'cat_other_expense',
        };
        for (final id in kept) {
          expect(ids, contains(id), reason: 'L1 $id should be kept');
        }
      });
    });

    // ─── L2 counts per L1 ───
    group('L2 counts per L1', () {
      const expected = <String, int>{
        'cat_food': 6,
        'cat_daily': 6,
        'cat_pet': 7,
        'cat_transport': 7,
        'cat_hobbies': 10,
        'cat_clothing': 10,
        'cat_social': 5,
        'cat_health': 8,
        'cat_education': 10,
        'cat_utilities': 5,
        'cat_communication': 8,
        'cat_housing': 10,
        'cat_car': 10,
        'cat_tax': 7,
        'cat_insurance': 5,
        'cat_special': 8,
        'cat_allowance': 4,
        'cat_asset': 8,
        'cat_other_expense': 4,
      };

      test('total expense L2 count is 138', () {
        final l2s = DefaultCategories.all.where((c) => c.level == 2).toList();
        expect(l2s.length, 138);
      });

      for (final entry in expected.entries) {
        test('${entry.key} has ${entry.value} L2 children', () {
          final l2s = DefaultCategories.all
              .where((c) => c.level == 2 && c.parentId == entry.key)
              .toList();
          expect(l2s.length, entry.value);
        });
      }
    });

    // ─── L2 integrity ───
    group('L2 integrity', () {
      test('every L2 has a parentId pointing to an existing L1', () {
        final l1Ids = DefaultCategories.expenseL1.map((c) => c.id).toSet();
        final orphans = DefaultCategories.all
            .where((c) => c.level == 2 && !l1Ids.contains(c.parentId))
            .toList();
        expect(orphans, isEmpty, reason: 'Found L2 categories with orphaned parentId');
      });

      test('no duplicate IDs across L1+L2', () {
        final all = DefaultCategories.all.map((c) => c.id).toList();
        expect(all.toSet().length, all.length);
      });

      test('all system categories have isSystem=true', () {
        expect(
          DefaultCategories.all.every((c) => c.isSystem),
          isTrue,
        );
      });
    });

    // ─── Ledger configs ───
    group('Ledger configs', () {
      test('every L1 has a ledger config', () {
        final configuredIds = DefaultCategories.defaultLedgerConfigs
            .map((c) => c.categoryId)
            .toSet();
        for (final l1 in DefaultCategories.expenseL1) {
          expect(configuredIds, contains(l1.id),
              reason: 'L1 ${l1.id} should have a ledger config');
        }
      });

      test('cat_pet and cat_allowance are soul ledger', () {
        final configs = DefaultCategories.defaultLedgerConfigs;
        expect(
          configs.firstWhere((c) => c.categoryId == 'cat_pet').ledgerType,
          LedgerType.soul,
        );
        expect(
          configs.firstWhere((c) => c.categoryId == 'cat_allowance').ledgerType,
          LedgerType.soul,
        );
      });

      test('L2 clothing overrides to survival', () {
        final configs = DefaultCategories.defaultLedgerConfigs;
        const overrides = {
          'cat_clothing_clothes',
          'cat_clothing_shoes',
          'cat_clothing_underwear',
          'cat_clothing_cleaning',
        };
        for (final id in overrides) {
          final c = configs.firstWhere(
            (x) => x.categoryId == id,
            orElse: () => throw StateError('Missing ledger override for $id'),
          );
          expect(c.ledgerType, LedgerType.survival,
              reason: '$id should override to survival');
        }
      });

      test('L2 social drinks/gifts override to soul', () {
        final configs = DefaultCategories.defaultLedgerConfigs;
        for (final id in ['cat_social_drinks', 'cat_social_gifts']) {
          final c = configs.firstWhere(
            (x) => x.categoryId == id,
            orElse: () => throw StateError('Missing ledger override for $id'),
          );
          expect(c.ledgerType, LedgerType.soul);
        }
      });

      test('L2 special wedding/movement/newyear override to soul', () {
        final configs = DefaultCategories.defaultLedgerConfigs;
        for (final id in [
          'cat_special_wedding',
          'cat_special_movement',
          'cat_special_newyear',
        ]) {
          final c = configs.firstWhere(
            (x) => x.categoryId == id,
            orElse: () => throw StateError('Missing ledger override for $id'),
          );
          expect(c.ledgerType, LedgerType.soul);
        }
      });
    });

    // ─── Key new L2 presence (Japan-specific) ───
    group('Key new L2 presence', () {
      const mustExist = {
        // tax
        'cat_tax_furusato',
        // education
        'cat_education_gakushi_hoken',
        'cat_education_entrance_exam',
        // health
        'cat_health_dock',
        'cat_health_dental',
        // communication
        'cat_communication_nhk',
        // hobbies
        'cat_hobbies_oshikatsu',
        // asset
        'cat_asset_nisa',
        'cat_asset_ideco',
        // pet
        'cat_pet_food',
        'cat_pet_medical',
        'cat_pet_insurance',
        // allowance
        'cat_allowance_self',
        'cat_allowance_spouse',
      };

      test('all Japan-specific L2 categories exist', () {
        final ids = DefaultCategories.all.map((c) => c.id).toSet();
        for (final id in mustExist) {
          expect(ids, contains(id), reason: '$id must exist in v2 seed');
        }
      });
    });

    // ─── Removed L2 absence ───
    group('Removed L2 absence', () {
      const mustNotExist = {
        // food time-slots removed
        'cat_food_general',
        'cat_food_breakfast',
        'cat_food_lunch',
        'cat_food_dinner',
        // general placeholders
        'cat_daily_general',
        'cat_transport_general',
        'cat_social_general',
        'cat_utilities_general',
        'cat_insurance_general',
        'cat_special_general',
        // moved to pet L1
        'cat_daily_pets',
        // communication
        'cat_communication_info',
        // special overlapping with housing
        'cat_special_furniture',
        'cat_special_housing',
        // moved to allowance L1
        'cat_other_allowance',
        // removed (should become transfer primitives)
        'cat_other_advances',
        'cat_other_business',
        'cat_other_debt',
      };

      test('all deprecated L2 categories are absent', () {
        final ids = DefaultCategories.all.map((c) => c.id).toSet();
        for (final id in mustNotExist) {
          expect(ids, isNot(contains(id)), reason: '$id must be removed in v2');
        }
      });
    });
  });
}
