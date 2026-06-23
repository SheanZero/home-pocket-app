// MerchantDao behavior test (Wave 2 RED state).
//
// These tests fail at compile time because MerchantDao does not exist yet —
// it is created in Task 3 of Plan 49-04. The compile error IS the correct RED
// state. Once MerchantDao + the insertSeed transaction exist, they go GREEN.

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/merchant_dao.dart';

void main() {
  late AppDatabase db;
  late MerchantDao dao;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = MerchantDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  MerchantsCompanion merchant(String id) => MerchantsCompanion.insert(
    id: id,
    nameJa: 'セブン-イレブン',
    categoryId: 'cat_food_convenience_store',
    ledgerHint: 'daily',
    nameZh: const Value('7-11'),
    nameEn: const Value('7-Eleven'),
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

  group('MerchantDao', () {
    test('findAllMerchantRows is empty on a fresh DB', () async {
      expect(await dao.findAllMerchantRows(), isEmpty);
      expect(await dao.findAllMatchKeyRows(), isEmpty);
    });

    test('insertSeed inserts merchant + match-key rows in one transaction',
        () async {
      await dao.insertSeed(
        [merchant('mer_seven_eleven'), merchant('mer_lawson')],
        [
          matchKey('mk_1', 'mer_seven_eleven', 'セブン-イレブン', 'せぶんいれぶん',
              'name'),
          matchKey('mk_2', 'mer_seven_eleven', '7-Eleven', '7-eleven', 'alias'),
          matchKey('mk_3', 'mer_lawson', 'ローソン', 'ろーそん', 'name'),
        ],
      );

      expect((await dao.findAllMerchantRows()).length, 2);
      expect((await dao.findAllMatchKeyRows()).length, 3);
    });

    test('findById returns the inserted merchant row', () async {
      await dao.insertSeed([merchant('mer_seven_eleven')], const []);
      final row = await dao.findById('mer_seven_eleven');
      expect(row, isNotNull);
      expect(row!.id, 'mer_seven_eleven');
      expect(await dao.findById('mer_missing'), isNull);
    });

    test('re-running the SAME batch leaves row counts UNCHANGED (idempotent)',
        () async {
      final merchants = [merchant('mer_seven_eleven'), merchant('mer_lawson')];
      final keys = [
        matchKey('mk_1', 'mer_seven_eleven', 'セブン-イレブン', 'せぶんいれぶん', 'name'),
        matchKey('mk_3', 'mer_lawson', 'ローソン', 'ろーそん', 'name'),
      ];

      await dao.insertSeed(merchants, keys);
      await dao.insertSeed(merchants, keys); // same ids → INSERT OR IGNORE

      expect((await dao.findAllMerchantRows()).length, 2);
      expect((await dao.findAllMatchKeyRows()).length, 2);
    });

    test('duplicate (merchant_id, match_key) does not crash and inserts once',
        () async {
      // name == alias after normalization → two surface rows share match_key.
      // Different PK ids, so both rows physically exist (collision is legal:
      // match_key index is NON-UNIQUE). The point: no crash on the duplicate
      // match_key value, and a re-run of the identical PK is a no-op.
      await dao.insertSeed(
        [merchant('mer_aeon')],
        [
          matchKey('mk_a', 'mer_aeon', 'イオン', 'いおん', 'name'),
          matchKey('mk_b', 'mer_aeon', 'AEON', 'いおん', 'alias'),
        ],
      );

      expect((await dao.findAllMatchKeyRows()).length, 2);

      // Re-insert with the SAME PKs → idempotent, still 2 rows.
      await dao.insertSeed(
        [merchant('mer_aeon')],
        [
          matchKey('mk_a', 'mer_aeon', 'イオン', 'いおん', 'name'),
          matchKey('mk_b', 'mer_aeon', 'AEON', 'いおん', 'alias'),
        ],
      );
      expect((await dao.findAllMatchKeyRows()).length, 2);
    });
  });
}
