import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/category_keyword_preference_dao.dart';

void main() {
  late AppDatabase db;
  late CategoryKeywordPreferenceDao dao;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = CategoryKeywordPreferenceDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('CategoryKeywordPreferenceDao', () {
    test('upsert creates new entry with hitCount 1', () async {
      await dao.upsert(keyword: '咖啡', categoryId: 'cat_food');

      final results = await dao.findByKeyword('咖啡');
      expect(results, hasLength(1));
      expect(results.first.keyword, '咖啡');
      expect(results.first.categoryId, 'cat_food');
      expect(results.first.hitCount, 1);
    });

    test('upsert increments hitCount on duplicate', () async {
      await dao.upsert(keyword: '咖啡', categoryId: 'cat_food');
      await dao.upsert(keyword: '咖啡', categoryId: 'cat_food');

      final results = await dao.findByKeyword('咖啡');
      expect(results, hasLength(1));
      expect(results.first.hitCount, 2);
    });

    test('upsert different category creates separate entry', () async {
      await dao.upsert(keyword: '咖啡', categoryId: 'cat_food');
      await dao.upsert(keyword: '咖啡', categoryId: 'cat_entertainment');

      final results = await dao.findByKeyword('咖啡');
      expect(results, hasLength(2));
    });

    test('findByKeyword returns ordered by hitCount desc', () async {
      await dao.upsert(keyword: '咖啡', categoryId: 'cat_food');
      await dao.upsert(keyword: '咖啡', categoryId: 'cat_entertainment');
      await dao.upsert(keyword: '咖啡', categoryId: 'cat_entertainment');

      final results = await dao.findByKeyword('咖啡');
      expect(results.first.categoryId, 'cat_entertainment');
      expect(results.first.hitCount, 2);
    });

    test('findByKeyword returns empty for unknown keyword', () async {
      final results = await dao.findByKeyword('unknown');
      expect(results, isEmpty);
    });

    test('findByKeywordAndCategory returns specific entry', () async {
      await dao.upsert(keyword: '咖啡', categoryId: 'cat_food');

      final result = await dao.findByKeywordAndCategory('咖啡', 'cat_food');
      expect(result, isNotNull);
      expect(result!.hitCount, 1);

      final missing = await dao.findByKeywordAndCategory('咖啡', 'cat_nope');
      expect(missing, isNull);
    });

    test('deleteAll clears all entries', () async {
      await dao.upsert(keyword: 'a', categoryId: 'b');
      await dao.upsert(keyword: 'c', categoryId: 'd');

      await dao.deleteAll();

      final results = await dao.findByKeyword('a');
      expect(results, isEmpty);
    });
  });

  // ── Quick task 260526-pg6 (Option F — Task 3 + Task 4) ──
  group('Quick task 260526-pg6', () {
    test(
      'Test 3.A: findLearnedAtOrAbove(3) returns only rows with hitCount >= 3, '
      'ordered by hitCount DESC then lastUsed DESC',
      () async {
        // Seed-style row (hitCount = 0) via insertSeedBatch shape — use
        // upsert + post-bump for simplicity since we're not exercising the
        // seed/learned discriminator here.
        await dao.upsert(keyword: 'seedy', categoryId: 'cat_s');
        // hitCount = 2 (below threshold).
        await dao.upsert(keyword: 'below', categoryId: 'cat_b');
        await dao.upsert(keyword: 'below', categoryId: 'cat_b');
        // hitCount = 3 (at threshold).
        await dao.upsert(keyword: 'three', categoryId: 'cat_3');
        await dao.upsert(keyword: 'three', categoryId: 'cat_3');
        await dao.upsert(keyword: 'three', categoryId: 'cat_3');
        // hitCount = 5 (above threshold).
        for (var i = 0; i < 5; i++) {
          await dao.upsert(keyword: 'five', categoryId: 'cat_5');
        }

        final results = await dao.findLearnedAtOrAbove(3);

        // Only the >=3 rows surface.
        expect(results, hasLength(2));
        // Ordered hitCount DESC → 5 first, then 3.
        expect(results.first.keyword, equals('five'));
        expect(results.first.hitCount, equals(5));
        expect(results.last.keyword, equals('three'));
        expect(results.last.hitCount, equals(3));
        // Below-threshold row absent.
        expect(
          results.any((r) => r.keyword == 'below'),
          isFalse,
          reason: 'hitCount=2 row must NOT appear in findLearnedAtOrAbove(3)',
        );
        // hitCount=1 'seedy' (single upsert) absent.
        expect(
          results.any((r) => r.keyword == 'seedy'),
          isFalse,
          reason: 'hitCount=1 row must NOT appear in findLearnedAtOrAbove(3)',
        );
      },
    );

    test(
      'findLearnedAtOrAbove(threshold) returns empty when no row reaches it',
      () async {
        await dao.upsert(keyword: 'low', categoryId: 'cat_low');
        final results = await dao.findLearnedAtOrAbove(5);
        expect(results, isEmpty);
      },
    );

    test(
      'findTopLearned excludes seeds (hitCount=0) and orders by hitCount '
      'DESC then lastUsed DESC; honors limit',
      () async {
        // Insert a seed-style row via insertSeedBatch (the API used by
        // production code to create hitCount=0 rows).
        await dao.insertSeedBatch([
          (keyword: 'seed', categoryId: 'cat_seed'),
        ]);
        await dao.upsert(keyword: 'a', categoryId: 'cat_a'); // hitCount=1
        await dao.upsert(keyword: 'b', categoryId: 'cat_b');
        await dao.upsert(keyword: 'b', categoryId: 'cat_b'); // hitCount=2
        await dao.upsert(keyword: 'c', categoryId: 'cat_c');
        await dao.upsert(keyword: 'c', categoryId: 'cat_c');
        await dao.upsert(keyword: 'c', categoryId: 'cat_c'); // hitCount=3

        // Default limit = 20 — returns all 3 learned rows.
        final all = await dao.findTopLearned();
        expect(all, hasLength(3));
        // Seed excluded.
        expect(all.any((r) => r.keyword == 'seed'), isFalse);
        // Ordered hitCount DESC.
        expect(all[0].keyword, equals('c'));
        expect(all[1].keyword, equals('b'));
        expect(all[2].keyword, equals('a'));

        // Limit honored.
        final top2 = await dao.findTopLearned(limit: 2);
        expect(top2, hasLength(2));
        expect(top2[0].keyword, equals('c'));
        expect(top2[1].keyword, equals('b'));
      },
    );
  });
}
