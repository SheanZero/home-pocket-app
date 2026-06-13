import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../application/currency/rate_result.dart';
import '../../features/currency/domain/models/exchange_rate.dart';
import '../../features/currency/domain/repositories/exchange_rate_repository.dart';
import 'exchange_rate_api_client.dart';

/// Cache-first orchestration for exchange-rate lookups (Phase 41).
///
/// Composes [ExchangeRateRepository] (Drift cache) and [ExchangeRateApiClient]
/// (three-source HTTP fallback) behind a single [getRate] entry point that
/// NEVER throws — every path returns a [RateResult] variant.
///
/// Decision coverage:
///   - D-01: today's rate valid for the day; cross-midnight invalidation via
///           the `fetchedAt < today` proxy guard.
///   - D-03: correctable proxy re-fetched once per day (fetchedAt-today guard
///           prevents the infinite re-fetch loop — RESEARCH.md Pitfall 4).
///   - D-05: connectivity gate skips the network when fully offline.
///   - D-06: in-memory cooldown after all-sources-fail (Pitfall 5 global).
///   - D-07: offline fallback prefers API-cached rows over manual rows.
///   - D-08: nothing cached → [RateUnavailable].
///   - D-09: 2-year TTL prune on every successful upsert.
class ExchangeRateCacheService {
  ExchangeRateCacheService({
    required ExchangeRateRepository repository,
    required ExchangeRateApiClient apiClient,
    Connectivity? connectivity,
  }) : _repository = repository,
       _apiClient = apiClient,
       _connectivity = connectivity ?? Connectivity();

  final ExchangeRateRepository _repository;
  final ExchangeRateApiClient _apiClient;
  final Connectivity _connectivity;

  /// D-06: in-memory only, no persistence — app restart clears it (acceptable
  /// for ephemeral outages; T-41-09).
  DateTime? _cooldownUntil;

  bool get _inCooldown =>
      _cooldownUntil != null && DateTime.now().isBefore(_cooldownUntil!);

  /// Resolve the JPY-per-[currency] rate for [date], cache-first.
  ///
  /// NEVER throws — all error paths fall through to the cache fallback and
  /// ultimately [RateUnavailable] (RATE-03).
  Future<RateResult> getRate(String currency, DateTime date) async {
    try {
      final normalized = _normalizeToUtcMidnight(date);

      // CACHE HIT (RATE-02): exact date+currency, not a correctable proxy.
      final cached = await _repository.findByDate(currency, normalized);
      if (cached != null && !_isCorrectableProxy(cached)) {
        return RateCached(
          rate: cached.rate,
          currency: currency,
          cachedDate: cached.rateDate,
          source: cached.source,
          isManualOverride: cached.source == 'manual',
        );
      }

      // D-05 connectivity gate + D-06 cooldown: skip the network when offline
      // or within the cooldown window, go straight to cache fallback.
      if (_inCooldown || await _isOffline()) {
        return _cacheFallback(currency);
      }

      // FETCH (cache miss or correctable proxy).
      try {
        final result = await _apiClient.fetchRate(currency, normalized);
        final row = ExchangeRate(
          currency: currency,
          rateDate: normalized,
          rate: result.rate,
          fetchedAt: DateTime.now(),
          source: result.source,
          actualRateDate: result.actualRateDate,
        );
        await _repository.upsert(row);
        // D-09: fire-and-forget TTL prune after persisting.
        unawaited(_pruneStaleCache());
        return RateFetched(
          rate: result.rate,
          currency: currency,
          rateDate: normalized,
          actualDate: result.actualRateDate,
          source: result.source,
        );
      } catch (e) {
        // D-06: all sources failed — back off for ~1 min, then fall back.
        _cooldownUntil = DateTime.now().add(const Duration(minutes: 1));
        if (kDebugMode) {
          debugPrint('[RateCache] fetch failed for $currency → cooldown');
        }
        return _cacheFallback(currency);
      }
    } catch (e) {
      // RATE-03: never throw — unexpected error still resolves to a variant.
      if (kDebugMode) {
        debugPrint('[RateCache] unexpected error for $currency: $e');
      }
      return _cacheFallback(currency);
    }
  }

  /// CACHE FALLBACK priority (D-07 / D-08):
  ///   1. latest API-cached row (non-manual)        → [RateFallback]
  ///   2. latest manual row                          → [RateManual]
  ///   3. nothing                                    → [RateUnavailable]
  Future<RateResult> _cacheFallback(String currency) async {
    try {
      final nonManual = await _repository.findLatestNonManual(currency);
      if (nonManual != null) {
        return RateFallback(
          rate: nonManual.rate,
          currency: currency,
          cachedDate: nonManual.rateDate,
        );
      }
      final latest = await _repository.findLatest(currency);
      if (latest != null && latest.source == 'manual') {
        return RateManual(
          rate: latest.rate,
          currency: currency,
          cachedDate: latest.rateDate,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RateCache] fallback lookup failed for $currency: $e');
      }
    }
    return RateUnavailable(currency: currency);
  }

  /// D-05: true when every reported connectivity result is `none`.
  Future<bool> _isOffline() async {
    final results = await _connectivity.checkConnectivity();
    return results.every((r) => r == ConnectivityResult.none);
  }

  /// D-03 correctable proxy guard (RESEARCH.md Pitfall 4): a proxy row whose
  /// rate date is now historical and that has not been re-fetched today.
  /// After one re-fetch today, `fetchedAt >= today midnight` → no further loop.
  bool _isCorrectableProxy(ExchangeRate row) {
    final today = _normalizeToUtcMidnight(DateTime.now());
    return row.actualRateDate != null &&
        row.rateDate.isBefore(today) &&
        row.fetchedAt.isBefore(today);
  }

  /// D-09: drop rows older than 2 years on every successful upsert.
  Future<void> _pruneStaleCache() async {
    final now = DateTime.now();
    final cutoff = DateTime.utc(now.year - 2, now.month, now.day);
    await _repository.deleteOlderThan(cutoff);
  }

  /// Normalize [d] to UTC midnight — the composite-key contract shared with
  /// [ExchangeRateRepositoryImpl].
  DateTime _normalizeToUtcMidnight(DateTime d) {
    final utc = d.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }
}
