// ExchangeRateRepositoryImpl tests — WR-06 (Phase 40 review).
//
// The (currency, rateDate) composite-key contract is "UTC midnight". The
// repository is the domain-facing boundary, so it must normalize any incoming
// DateTime (local-zone, non-midnight) to UTC midnight on both lookup and
// upsert. Without normalization, callers passing DateTime.now() or local
// dates get silent cache misses and near-duplicate rows.

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/exchange_rate_dao.dart';
import 'package:home_pocket/data/repositories/exchange_rate_repository_impl.dart';
import 'package:home_pocket/features/currency/domain/models/exchange_rate.dart';

void main() {
  late AppDatabase db;
  late ExchangeRateRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.forTesting();
    repository = ExchangeRateRepositoryImpl(dao: ExchangeRateDao(db));
  });

  tearDown(() async {
    await db.close();
  });

  ExchangeRate makeRate({required DateTime rateDate, String rate = '149.5'}) {
    return ExchangeRate(
      currency: 'USD',
      rateDate: rateDate,
      rate: rate,
      fetchedAt: DateTime.utc(2026, 6, 12, 9, 30),
      source: 'frankfurter',
    );
  }

  group('ExchangeRateRepositoryImpl UTC-midnight normalization (WR-06)', () {
    test('upsert normalizes a non-midnight UTC rateDate to UTC midnight',
        () async {
      await repository.upsert(
        makeRate(rateDate: DateTime.utc(2026, 6, 12, 15, 23, 45)),
      );

      final found =
          await repository.findByDate('USD', DateTime.utc(2026, 6, 12));
      expect(found, isNotNull);
      expect(found!.rateDate, equals(DateTime.utc(2026, 6, 12)));
    });

    test('findByDate normalizes a non-midnight lookup DateTime', () async {
      await repository.upsert(makeRate(rateDate: DateTime.utc(2026, 6, 12)));

      final found = await repository.findByDate(
        'USD',
        DateTime.utc(2026, 6, 12, 8, 45, 1),
      );
      expect(found, isNotNull);
      expect(found!.rate, equals('149.5'));
    });

    test('findByDate accepts a local-zone DateTime for the same UTC day',
        () async {
      await repository.upsert(makeRate(rateDate: DateTime.utc(2026, 6, 12)));

      // Local-zone representation of 2026-06-12 12:00 UTC — same instant,
      // same UTC day regardless of the host timezone.
      final localNoon = DateTime.utc(2026, 6, 12, 12).toLocal();
      final found = await repository.findByDate('USD', localNoon);
      expect(found, isNotNull);
      expect(found!.rateDate, equals(DateTime.utc(2026, 6, 12)));
    });

    test(
        'two upserts on the same UTC day with different times update one row '
        '(no near-duplicates)', () async {
      await repository.upsert(
        makeRate(rateDate: DateTime.utc(2026, 6, 12, 9), rate: '149.5'),
      );
      await repository.upsert(
        makeRate(rateDate: DateTime.utc(2026, 6, 12, 18), rate: '150.0'),
      );

      final rows = await db.select(db.exchangeRates).get();
      expect(rows.length, equals(1));
      expect(rows.single.rate, equals('150.0'));
    });
  });
}
