import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../features/currency/domain/models/rate_result.dart';
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

  /// D-06: back-off window applied after an online all-sources-fail.
  static const Duration _cooldownDuration = Duration(minutes: 1);

  /// D-06: in-memory only, no persistence — app restart clears it (acceptable
  /// for ephemeral outages; T-41-09). Cleared on the next successful fetch
  /// (WR-04) so a recovered API is not blocked for the full window.
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
      final isCorrectableProxy = cached != null && _isCorrectableProxy(cached);
      if (cached != null && !isCorrectableProxy) {
        return RateCached(
          rate: cached.rate,
          currency: currency,
          cachedDate: cached.rateDate,
          source: cached.source,
          isManualOverride: cached.source == 'manual',
        );
      }

      // WR-04: consult connectivity BEFORE the cooldown. A regained connection
      // must not be suppressed by an in-memory cooldown — and the cooldown is
      // cleared on the next successful fetch below, so a recovered API isn't
      // blocked for the full window once we're back online.
      // D-05: fully offline → skip the network, go straight to cache fallback.
      if (await _isOffline()) {
        return _proxyAwareFallback(currency, cached, isCorrectableProxy);
      }
      // D-06: online but still inside the all-sources-fail cooldown → skip.
      if (_inCooldown) {
        return _proxyAwareFallback(currency, cached, isCorrectableProxy);
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
        // WR-04: a successful fetch proves the network/API recovered — clear
        // any lingering cooldown so subsequent lookups aren't gated.
        _cooldownUntil = null;
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
        _cooldownUntil = DateTime.now().add(_cooldownDuration);
        if (kDebugMode) {
          debugPrint('[RateCache] fetch failed for $currency → cooldown');
        }
        // WR-02: if we already hold an exact-date proxy row that we could not
        // refresh, prefer it over a latest-any-date fallback.
        return _proxyAwareFallback(currency, cached, isCorrectableProxy);
      }
    } catch (e) {
      // RATE-03: never throw — unexpected error still resolves to a variant.
      if (kDebugMode) {
        debugPrint('[RateCache] unexpected error for $currency: $e');
      }
      return _cacheFallback(currency);
    }
  }

  /// WR-02: when the requested date already had an exact-date correctable
  /// proxy row that we could NOT refresh (offline / cooldown / fetch failed),
  /// return that exact-date proxy rather than a latest-any-date fallback —
  /// the proxy holds the rate for the date the caller actually asked for,
  /// whereas [_cacheFallback] may surface a neighboring date's rate.
  Future<RateResult> _proxyAwareFallback(
    String currency,
    ExchangeRate? cached,
    bool isCorrectableProxy,
  ) async {
    if (isCorrectableProxy && cached != null) {
      return RateFallback(
        rate: cached.rate,
        currency: currency,
        cachedDate: cached.rateDate,
      );
    }
    return _cacheFallback(currency);
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
      // WR-03: query the latest MANUAL row directly rather than inferring it
      // from findLatest (which returns the newest row of any source and only
      // happens to be manual in some histories). Removes the dependency on
      // which source is newest.
      final manual = await _repository.findLatestManual(currency);
      if (manual != null) {
        return RateManual(
          rate: manual.rate,
          currency: currency,
          cachedDate: manual.rateDate,
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
  ///
  /// The guard is date-level, not instant-level: `today` is the local calendar
  /// day stamped as UTC midnight (`_normalizeToUtcMidnight`). `fetchedAt` is
  /// stored raw via `DateTime.now()` (a local wall-clock instant), so it MUST be
  /// normalized to its own local calendar day before comparison — otherwise, in
  /// any timezone east of UTC, a row fetched in the early-morning hours has an
  /// absolute `fetchedAt` instant that precedes the UTC-midnight `today` and is
  /// wrongly judged stale, re-fetching once per lookup every morning (the D-03
  /// "no re-fetch loop" guarantee silently breaks for the UTC-offset window).
  /// `.toLocal()` keeps this correct whether the row arrives local (in-memory)
  /// or UTC (Drift round-trip); it is the inverse of the CR-02 `.toUtc()` trap.
  bool _isCorrectableProxy(ExchangeRate row) {
    final today = _normalizeToUtcMidnight(DateTime.now());
    return row.actualRateDate != null &&
        row.rateDate.isBefore(today) &&
        _normalizeToUtcMidnight(row.fetchedAt.toLocal()).isBefore(today);
  }

  /// D-09: drop rows older than 2 years on every successful upsert.
  Future<void> _pruneStaleCache() async {
    final now = DateTime.now();
    final cutoff = DateTime.utc(now.year - 2, now.month, now.day);
    await _repository.deleteOlderThan(cutoff);
  }

  /// Normalize [d] to the canonical composite-key date: its LOCAL calendar
  /// Y/M/D, stamped as a UTC midnight `DateTime` so the epoch second is
  /// deterministic.
  ///
  /// CR-02: must use local Y/M/D (NOT `d.toUtc()` first), to agree with
  /// [ExchangeRateApiClient._formatDate] which builds the URL date from local
  /// components, and with the transaction date picker
  /// (`DateTime(y, m, d)` — local midnight). Shifting to UTC first stored each
  /// JST day's rate under the previous UTC day's key. Same contract shared
  /// with [ExchangeRateRepositoryImpl].
  DateTime _normalizeToUtcMidnight(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day);
}
