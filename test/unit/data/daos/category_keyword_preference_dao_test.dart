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

      final result =
          await dao.findByKeywordAndCategory('咖啡', 'cat_food');
      expect(result, isNotNull);
      expect(result!.hitCount, 1);

      final missing =
          await dao.findByKeywordAndCategory('咖啡', 'cat_nope');
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
}
