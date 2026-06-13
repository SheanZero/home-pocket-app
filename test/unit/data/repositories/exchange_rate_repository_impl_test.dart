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

  group('WR-03: findLatestManual', () {
    test('returns the latest manual row, ignoring newer non-manual rows',
        () async {
      await repository.upsert(
        ExchangeRate(
          currency: 'USD',
          rateDate: DateTime.utc(2026, 6, 1),
          rate: '149.0',
          fetchedAt: DateTime.utc(2026, 6, 1),
          source: 'manual',
        ),
      );
      await repository.upsert(
        ExchangeRate(
          currency: 'USD',
          rateDate: DateTime.utc(2026, 6, 12),
          rate: '151.0',
          fetchedAt: DateTime.utc(2026, 6, 12),
          source: 'frankfurter',
        ),
      );

      final manual = await repository.findLatestManual('USD');
      expect(manual, isNotNull);
      expect(manual!.source, equals('manual'));
      expect(manual.rate, equals('149.0'));
    });

    test('returns null when there is no manual row', () async {
      await repository.upsert(makeRate(rateDate: DateTime.utc(2026, 6, 1)));
      expect(await repository.findLatestManual('USD'), isNull);
    });
  });

  group('CR-02: local-calendar-date key (no UTC skew)', () {
    test(
        'a local-midnight DateTime (e.g. the transaction picker output) keys '
        'under its own calendar date, not the previous day', () async {
      // The transaction date picker produces DateTime(y, m, d) — a LOCAL
      // midnight. Under the old .toUtc()-first normalizer this stored the
      // rate under the previous UTC day for any UTC+ device (e.g. JST/UTC+9).
      final picked = DateTime(2026, 6, 14); // local midnight

      await repository.upsert(makeRate(rateDate: picked));

      // Read-side uses the same local DateTime → must round-trip.
      final found = await repository.findByDate('USD', picked);
      expect(found, isNotNull);
      // Stored rateDate carries the picked calendar digits, NOT day-1.
      expect(found!.rateDate, equals(DateTime.utc(2026, 6, 14)));
      expect(found.rateDate.day, equals(14));
    });

    test('write at local midnight and read at local noon hit the same row',
        () async {
      await repository.upsert(makeRate(rateDate: DateTime(2026, 6, 14)));

      final found = await repository.findByDate(
        'USD',
        DateTime(2026, 6, 14, 12, 30), // same local calendar day, midday
      );
      expect(found, isNotNull);
      expect(found!.rateDate, equals(DateTime.utc(2026, 6, 14)));
    });
  });
}
