// MerchantRepositoryImpl.loadAllForMatching() join-correctness test (Plan 50-01).
//
// Seeds an in-memory DB with 2 merchants × multiple surface forms, then asserts
// loadAllForMatching() returns one flat MerchantMatchEntry per surface — each
// carrying its parent merchant's categoryId/ledgerHint/displayName.

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/merchant_dao.dart';
import 'package:home_pocket/data/repositories/merchant_repository_impl.dart';

void main() {
  late AppDatabase db;
  late MerchantDao dao;
  late MerchantRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = MerchantDao(db);
    repository = MerchantRepositoryImpl(dao: dao);
  });

  tearDown(() async {
    await db.close();
  });

  MerchantsCompanion merchant(
    String id,
    String nameJa,
    String categoryId,
    String ledgerHint,
  ) => MerchantsCompanion.insert(
    id: id,
    nameJa: nameJa,
    categoryId: categoryId,
    ledgerHint: ledgerHint,
    nameZh: const Value(null),
    nameEn: const Value(null),
  );

  MerchantMatchKeysCompanion matchKey(
    String id,
    String merchantId,
    String surface,
    String key,
    String kind,
  ) => MerchantMatchKeysCompanion.insert(
    id: id,
    merchantId: merchantId,
    surface: surface,
    matchKey: key,
    kind: kind,
  );

  group('MerchantRepositoryImpl.loadAllForMatching', () {
    test('is empty on a fresh DB', () async {
      expect(await repository.loadAllForMatching(), isEmpty);
    });

    test(
      'returns one entry per surface form, each carrying its merchant fields',
      () async {
        // Merchant A: 3 surfaces. Merchant B: 2 surfaces. Total = 5 surfaces.
        await dao.insertSeed(
          [
            merchant(
              'mer_seven_eleven',
              'セブン-イレブン',
              'cat_food_convenience_store',
              'daily',
            ),
            merchant('mer_starbucks', 'スターバックス', 'cat_food_cafe', 'joy'),
          ],
          [
            matchKey('mk_1', 'mer_seven_eleven', 'セブン-イレブン', 'せぶんいれぶん',
                'name'),
            matchKey('mk_2', 'mer_seven_eleven', '7-Eleven', '7-eleven', 'alias'),
            matchKey('mk_3', 'mer_seven_eleven', '711', '711', 'alias'),
            matchKey('mk_4', 'mer_starbucks', 'スターバックス', 'すたーばっくす',
                'name'),
            matchKey('mk_5', 'mer_starbucks', 'Starbucks', 'starbucks', 'alias'),
          ],
        );

        final entries = await repository.loadAllForMatching();

        // (a) entry count == total surface count (NOT merchant count).
        expect(entries.length, 5);

        // (b) each entry's categoryId/ledgerHint matches its parent merchant.
        final sevenEntries =
            entries.where((e) => e.merchantId == 'mer_seven_eleven').toList();
        final starbucksEntries =
            entries.where((e) => e.merchantId == 'mer_starbucks').toList();

        expect(sevenEntries.length, 3);
        expect(starbucksEntries.length, 2);

        for (final e in sevenEntries) {
          expect(e.categoryId, 'cat_food_convenience_store');
          expect(e.ledgerHint, 'daily');
          expect(e.displayName, 'セブン-イレブン'); // sources from merchant.nameJa
        }
        for (final e in starbucksEntries) {
          expect(e.categoryId, 'cat_food_cafe');
          expect(e.ledgerHint, 'joy');
          expect(e.displayName, 'スターバックス');
        }

        // (c) all surfaces for one merchant share the same merchantId/categoryId.
        expect(
          sevenEntries.map((e) => e.categoryId).toSet(),
          {'cat_food_convenience_store'},
        );
        expect(
          starbucksEntries.map((e) => e.categoryId).toSet(),
          {'cat_food_cafe'},
        );

        // The matchKey/surface pairing is preserved per row.
        final byKey = {for (final e in entries) e.matchKey: e};
        expect(byKey['7-eleven']!.surface, '7-Eleven');
        expect(byKey['starbucks']!.surface, 'Starbucks');
      },
    );
  });
}
