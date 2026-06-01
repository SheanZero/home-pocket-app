import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/analytics_dao.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';

void main() {
  late AppDatabase db;
  late AnalyticsDao dao;

  final windowStart = DateTime(2026, 5);
  final windowEnd = DateTime(2026, 5, 31, 23, 59, 59);

  setUp(() {
    db = AppDatabase.forTesting();
    dao = AnalyticsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedTx({
    required String id,
    String bookId = 'book_joy',
    int amount = 1000,
    String type = 'expense',
    String categoryId = 'cat_joy',
    String ledgerType = 'joy',
    DateTime? timestamp,
    bool isDeleted = false,
    int joyFullness = 6,
    String entrySource = 'manual',
  }) {
    final effectiveTimestamp = timestamp ?? DateTime(2026, 5, 10, 12);
    return db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: id,
            bookId: bookId,
            deviceId: 'device_1',
            amount: amount,
            type: type,
            categoryId: categoryId,
            ledgerType: ledgerType,
            timestamp: effectiveTimestamp,
            currentHash: 'hash_$id',
            createdAt: effectiveTimestamp,
            isDeleted: Value(isDeleted),
            joyFullness: Value(joyFullness),
            entrySource: Value(entrySource),
          ),
        );
  }

  group('entrySourceFilter on best joy moment', () {
    test('null filter keeps all entry sources in ordering', () async {
      await seedTx(
        id: 'voice_best',
        joyFullness: 10,
        entrySource: 'voice',
      );
      await seedTx(
        id: 'manual_second',
        joyFullness: 9,
        entrySource: 'manual',
      );
      await seedTx(
        id: 'manual_third',
        joyFullness: 7,
        entrySource: 'manual',
      );

      final best = await dao.getBestJoyMoment(
        bookId: 'book_joy',
        startDate: windowStart,
        endDate: windowEnd,
        entrySourceFilter: null,
      );

      expect(best, isNotNull);
      expect(best!.transactionId, 'voice_best');
      expect(best.joyFullness, 10);
    });

    test('manual filter excludes voice rows from ordering', () async {
      await seedTx(
        id: 'voice_best',
        joyFullness: 10,
        entrySource: 'voice',
      );
      await seedTx(
        id: 'manual_second',
        joyFullness: 9,
        entrySource: 'manual',
      );
      await seedTx(
        id: 'manual_third',
        joyFullness: 7,
        entrySource: 'manual',
      );

      final best = await dao.getBestJoyMoment(
        bookId: 'book_joy',
        startDate: windowStart,
        endDate: windowEnd,
        entrySourceFilter: EntrySource.manual,
      );

      expect(best, isNotNull);
      expect(best!.transactionId, 'manual_second');
      expect(best.joyFullness, 9);
    });
  });

  group('entrySourceFilter on category totals', () {
    test('null filter includes mixed-source expense totals', () async {
      await seedTx(id: 'manual_100', amount: 100, categoryId: 'cat_food');
      await seedTx(
        id: 'voice_200',
        amount: 200,
        categoryId: 'cat_food',
        entrySource: 'voice',
      );
      await seedTx(id: 'manual_50', amount: 50, categoryId: 'cat_food');

      final totals = await dao.getCategoryTotals(
        bookId: 'book_joy',
        startDate: windowStart,
        endDate: windowEnd,
        entrySourceFilter: null,
      );

      expect(totals, hasLength(1));
      expect(totals.single.categoryId, 'cat_food');
      expect(totals.single.totalAmount, 350);
      expect(totals.single.transactionCount, 3);
    });

    test('manual filter excludes voice rows from expense totals', () async {
      await seedTx(id: 'manual_100', amount: 100, categoryId: 'cat_food');
      await seedTx(
        id: 'voice_200',
        amount: 200,
        categoryId: 'cat_food',
        entrySource: 'voice',
      );
      await seedTx(id: 'manual_50', amount: 50, categoryId: 'cat_food');

      final totals = await dao.getCategoryTotals(
        bookId: 'book_joy',
        startDate: windowStart,
        endDate: windowEnd,
        entrySourceFilter: EntrySource.manual,
      );

      expect(totals, hasLength(1));
      expect(totals.single.categoryId, 'cat_food');
      expect(totals.single.totalAmount, 150);
      expect(totals.single.transactionCount, 2);
    });
  });

  group('entrySourceFilter on across-books aggregates', () {
    test(
      'manual filter excludes voice rows across all requested books',
      () async {
        await seedTx(
          id: 'b1_manual',
          bookId: 'book_a',
          amount: 100,
          categoryId: 'cat_music',
          joyFullness: 8,
          entrySource: 'manual',
        );
        await seedTx(
          id: 'b1_voice',
          bookId: 'book_a',
          amount: 100,
          categoryId: 'cat_music',
          joyFullness: 10,
          entrySource: 'voice',
        );
        await seedTx(
          id: 'b2_manual',
          bookId: 'book_b',
          amount: 100,
          categoryId: 'cat_music',
          joyFullness: 6,
          entrySource: 'manual',
        );

        final rows = await dao.getPerCategorySoulBreakdownAcrossBooks(
          bookIds: ['book_a', 'book_b'],
          startDate: windowStart,
          endDate: windowEnd,
          entrySourceFilter: EntrySource.manual,
        );

        expect(rows, hasLength(1));
        expect(rows.single.categoryId, 'cat_music');
        expect(rows.single.totalCount, 2);
        expect(rows.single.avgSatisfaction, 7);
      },
    );
  });

  group('predicate drift guardrails', () {
    test('joy and daily predicate constants remain byte-identical', () {
      final source = File(
        'lib/data/daos/analytics_dao.dart',
      ).readAsStringSync();

      expect(
        source,
        contains(
          '"ledger_type = \'joy\' AND type = \'expense\' AND is_deleted = 0"',
        ),
      );
      expect(
        source,
        contains(
          '"ledger_type = \'daily\' AND type = \'expense\' AND is_deleted = 0"',
        ),
      );
    });
  });
}
