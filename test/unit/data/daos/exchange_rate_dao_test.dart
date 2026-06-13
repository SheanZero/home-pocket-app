// ExchangeRateDao behavior test stubs (Wave 0 RED state).
//
// These tests fail at compile time because ExchangeRateDao and
// ExchangeRatesCompanion do not exist yet — they are created in Wave 1
// (Plan 40-02). The compile error IS the correct RED state for Wave 0.

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/exchange_rate_dao.dart';

void main() {
  late AppDatabase db;
  late ExchangeRateDao dao;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = ExchangeRateDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ExchangeRateDao', () {
    test('findByDate returns null when table is empty', () async {
      // RED: ExchangeRateDao does not exist yet — compile failure expected.
      final result = await dao.findByDate('USD', DateTime.utc(2026, 6, 1));
      expect(result, isNull);
    });

    test('upsert inserts a row and findByDate retrieves it', () async {
      // RED: ExchangeRateDao and ExchangeRatesCompanion do not exist yet.
      await dao.upsert(
        ExchangeRatesCompanion(
          currency: const Value('USD'),
          rateDate: Value(DateTime.utc(2026, 6, 1)),
          rate: const Value('149.5'),
          fetchedAt: Value(DateTime.now()),
          source: const Value('frankfurter'),
        ),
      );
      final row = await dao.findByDate('USD', DateTime.utc(2026, 6, 1));
      expect(row, isNotNull);
      expect(double.parse(row!.rate), closeTo(149.5, 0.001));
    });

    test('findLatest returns the most-recent row when multiple rows exist',
        () async {
      // RED: ExchangeRateDao and ExchangeRatesCompanion do not exist yet.
      await dao.upsert(
        ExchangeRatesCompanion(
          currency: const Value('USD'),
          rateDate: Value(DateTime.utc(2026, 5, 1)),
          rate: const Value('148.0'),
          fetchedAt: Value(DateTime.now()),
          source: const Value('frankfurter'),
        ),
      );
      await dao.upsert(
        ExchangeRatesCompanion(
          currency: const Value('USD'),
          rateDate: Value(DateTime.utc(2026, 6, 1)),
          rate: const Value('149.5'),
          fetchedAt: Value(DateTime.now()),
          source: const Value('frankfurter'),
        ),
      );
      final row = await dao.findLatest('USD');
      expect(row, isNotNull);
      expect(row!.rateDate, equals(DateTime.utc(2026, 6, 1)));
    });

    test('upsert on conflict updates the existing rate', () async {
      // RED: ExchangeRateDao and ExchangeRatesCompanion do not exist yet.
      final date = DateTime.utc(2026, 6, 1);
      await dao.upsert(
        ExchangeRatesCompanion(
          currency: const Value('USD'),
          rateDate: Value(date),
          rate: const Value('149.5'),
          fetchedAt: Value(DateTime.now()),
          source: const Value('frankfurter'),
        ),
      );
      // Upsert same (currency, rateDate) with a different rate.
      await dao.upsert(
        ExchangeRatesCompanion(
          currency: const Value('USD'),
          rateDate: Value(date),
          rate: const Value('150.0'),
          fetchedAt: Value(DateTime.now()),
          source: const Value('frankfurter'),
        ),
      );
      final row = await dao.findByDate('USD', date);
      expect(row, isNotNull);
      expect(double.parse(row!.rate), closeTo(150.0, 0.001));
    });

    test(
        'WR-03: findLatestManual returns the newest manual row, ignoring '
        'newer non-manual rows', () async {
      await dao.upsert(
        ExchangeRatesCompanion(
          currency: const Value('USD'),
          rateDate: Value(DateTime.utc(2026, 6, 1)),
          rate: const Value('149.0'),
          fetchedAt: Value(DateTime.now()),
          source: const Value('manual'),
        ),
      );
      // A newer NON-manual row must not shadow the manual lookup.
      await dao.upsert(
        ExchangeRatesCompanion(
          currency: const Value('USD'),
          rateDate: Value(DateTime.utc(2026, 6, 12)),
          rate: const Value('151.0'),
          fetchedAt: Value(DateTime.now()),
          source: const Value('frankfurter'),
        ),
      );

      final manual = await dao.findLatestManual('USD');
      expect(manual, isNotNull);
      expect(manual!.source, equals('manual'));
      expect(manual.rateDate, equals(DateTime.utc(2026, 6, 1)));
    });

    test('WR-03: findLatestManual returns null when no manual row exists',
        () async {
      await dao.upsert(
        ExchangeRatesCompanion(
          currency: const Value('USD'),
          rateDate: Value(DateTime.utc(2026, 6, 1)),
          rate: const Value('149.0'),
          fetchedAt: Value(DateTime.now()),
          source: const Value('frankfurter'),
        ),
      );

      expect(await dao.findLatestManual('USD'), isNull);
    });

    test(
        'fetchedAt and actualRateDate round-trip as UTC DateTimes (WR-05)',
        () async {
      final fetchedAt = DateTime.utc(2026, 6, 12, 9, 30, 15);
      final actualRateDate = DateTime.utc(2026, 6, 10);
      await dao.upsert(
        ExchangeRatesCompanion(
          currency: const Value('USD'),
          rateDate: Value(DateTime.utc(2026, 6, 12)),
          rate: const Value('149.5'),
          fetchedAt: Value(fetchedAt),
          source: const Value('frankfurter'),
          actualRateDate: Value(actualRateDate),
        ),
      );
      final row = await dao.findByDate('USD', DateTime.utc(2026, 6, 12));
      expect(row, isNotNull);
      // DateTime.== requires matching isUtc — plain dateTime() columns would
      // come back local-zone and fail these equality checks.
      expect(row!.fetchedAt.isUtc, isTrue);
      expect(row.fetchedAt, equals(fetchedAt));
      expect(row.actualRateDate?.isUtc, isTrue);
      expect(row.actualRateDate, equals(actualRateDate));
    });
  });
}
