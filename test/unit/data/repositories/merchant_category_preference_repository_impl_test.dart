import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/merchant_category_preference_dao.dart';
import 'package:home_pocket/data/repositories/merchant_category_preference_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/merchant_category_preference.dart';

void main() {
  late AppDatabase db;
  late MerchantCategoryPreferenceRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.forTesting();
    repository = MerchantCategoryPreferenceRepositoryImpl(
      dao: MerchantCategoryPreferenceDao(db),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('MerchantCategoryPreferenceRepositoryImpl', () {
    test('upsert and findByMerchantKey map correctly', () async {
      final now = DateTime(2026, 2, 22, 11, 0);
      await repository.upsert(
        MerchantCategoryPreference(
          merchantKey: 'seven',
          preferredCategoryId: 'cat_food_groceries',
          lastOverrideCategoryId: null,
          overrideStreak: 0,
          updatedAt: now,
        ),
      );

      final pref = await repository.findByMerchantKey('seven');
      expect(pref, isNotNull);
      expect(pref!.merchantKey, 'seven');
      expect(pref.preferredCategoryId, 'cat_food_groceries');
      expect(pref.overrideStreak, 0);
    });

    test('recordSelection creates preference on first selection', () async {
      await repository.recordSelection(
        merchantKey: 'seven',
        selectedCategoryId: 'cat_food_groceries',
      );

      expect(await repository.suggestCategoryId('seven'), 'cat_food_groceries');
    });

    test(
      'recordSelection updates preferred category after two same overrides',
      () async {
        await repository.recordSelection(
          merchantKey: 'seven',
          selectedCategoryId: 'cat_food_groceries',
        );

        await repository.recordSelection(
          merchantKey: 'seven',
          selectedCategoryId: 'cat_food_dining_out',
        );

        expect(
          await repository.suggestCategoryId('seven'),
          'cat_food_groceries',
        );

        await repository.recordSelection(
          merchantKey: 'seven',
          selectedCategoryId: 'cat_food_dining_out',
        );

        final pref = await repository.findByMerchantKey('seven');
        expect(pref!.preferredCategoryId, 'cat_food_dining_out');
        expect(pref.overrideStreak, 0);
        expect(pref.lastOverrideCategoryId, isNull);
      },
    );

    test(
      'recordSelection keeps old preferred category when second override differs',
      () async {
        await repository.recordSelection(
          merchantKey: 'seven',
          selectedCategoryId: 'cat_food_groceries',
        );
        await repository.recordSelection(
          merchantKey: 'seven',
          selectedCategoryId: 'cat_food_dining_out',
        );
        await repository.recordSelection(
          merchantKey: 'seven',
          selectedCategoryId: 'cat_transport_train',
        );

        final pref = await repository.findByMerchantKey('seven');
        expect(pref!.preferredCategoryId, 'cat_food_groceries');
        expect(pref.lastOverrideCategoryId, 'cat_transport_train');
        expect(pref.overrideStreak, 1);
      },
    );
  });
}
