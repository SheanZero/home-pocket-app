import 'package:flutter/foundation.dart';

import '../../features/currency/domain/models/exchange_rate.dart';
import '../../features/currency/domain/repositories/exchange_rate_repository.dart';
import '../../infrastructure/exchange_rate/exchange_rate_cache_service.dart';
import '../../features/currency/domain/models/rate_result.dart';

/// Immutable parameter object for [GetExchangeRateUseCase.execute].
///
/// Simple value object (no Freezed) per RESEARCH.md Pattern 4 — mirrors the
/// `GetTransactionsParams` shape.
class GetExchangeRateParams {
  const GetExchangeRateParams({
    required this.currency,
    required this.date,
    this.previousRate,
    this.wasManualOverride = false,
    this.manualOverrideRate,
  });

  /// ISO 4217 currency code to resolve.
  final String currency;

  /// The date the rate is requested for.
  final DateTime date;

  /// The rate the caller previously had — drives the ADR-022 D-03 >1% delta
  /// toast. Null on first lookup.
  final String? previousRate;

  /// ADR-022 D-02 flag: the previous rate was a user manual override.
  final bool wasManualOverride;

  /// RATE-04: when non-null, the user is supplying a manual rate to persist
  /// (source='manual') instead of fetching.
  final String? manualOverrideRate;
}

/// Application use case wrapping [ExchangeRateCacheService] with ADR-022 signal
/// logic (D-02 dialog / D-03 toast) and the RATE-04 manual-override write path.
///
/// NEVER throws — the outer try/catch resolves any error to a
/// [RateResultWithSignal] carrying [RateUnavailable] (RATE-03).
class GetExchangeRateUseCase {
  GetExchangeRateUseCase({
    required ExchangeRateCacheService cacheService,
    required ExchangeRateRepository repository,
  }) : _cacheService = cacheService,
       _repository = repository;

  final ExchangeRateCacheService _cacheService;
  final ExchangeRateRepository _repository;

  Future<RateResultWithSignal> execute(GetExchangeRateParams params) async {
    try {
      // RATE-04: manual override write path takes precedence.
      if (params.manualOverrideRate != null) {
        return _applyManualOverride(params);
      }

      final result = await _cacheService.getRate(params.currency, params.date);

      // ADR-022 D-02: override + previous rate present → signal a conflict
      // dialog. The use case does not decide which rate "wins" — Phase 42 does.
      if (params.wasManualOverride && params.previousRate != null) {
        final newRate = _extractRate(result);
        if (newRate != null) {
          return RateResultWithSignal(
            result: result,
            signal: RateSignalDialog(
              currency: params.currency,
              oldRate: params.previousRate!,
              newRate: newRate,
            ),
          );
        }
        return RateResultWithSignal(result: result);
      }

      // ADR-022 D-03: no override + previous rate present + >1% delta → toast.
      if (!params.wasManualOverride && params.previousRate != null) {
        final signal = _maybeToast(params.previousRate!, result);
        return RateResultWithSignal(result: result, signal: signal);
      }

      return RateResultWithSignal(result: result);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[GetExchangeRate] unexpected error: $e');
      }
      return RateResultWithSignal(
        result: RateUnavailable(currency: params.currency),
      );
    }
  }

  /// RATE-04: validate and persist a user manual override (source='manual').
  Future<RateResultWithSignal> _applyManualOverride(
    GetExchangeRateParams params,
  ) async {
    final raw = params.manualOverrideRate!;
    final rate = double.tryParse(raw);
    if (rate == null || rate.isNaN || rate.isInfinite || rate <= 0) {
      // T-41-13: invalid manual input → unavailable, no upsert.
      return RateResultWithSignal(
        result: RateUnavailable(currency: params.currency),
      );
    }

    final normalized = _normalizeToUtcMidnight(params.date);
    await _repository.upsert(
      ExchangeRate(
        currency: params.currency,
        rateDate: normalized,
        rate: raw,
        fetchedAt: DateTime.now(),
        source: 'manual',
        actualRateDate: null,
      ),
    );

    return RateResultWithSignal(
      result: RateCached(
        rate: raw,
        currency: params.currency,
        cachedDate: normalized,
        source: 'manual',
        isManualOverride: true,
      ),
    );
  }

  /// ADR-022 D-03: emit a toast when the rate moved more than 1%.
  ///
  /// Compares rate doubles for the threshold only (rates stay strings on the
  /// wire — ADR-020). Skips silently when either value is unparseable or the
  /// new result has no rate.
  ///
  /// WR-01: the toast carries the actual rate strings + the fractional change,
  /// not rounded int JPY amounts (which collapsed sub-1 rates to "0 → 0").
  RateSignal? _maybeToast(String previousRate, RateResult result) {
    final oldRate = double.tryParse(previousRate);
    final newRateStr = _extractRate(result);
    final newRate = newRateStr == null ? null : double.tryParse(newRateStr);
    if (oldRate == null || oldRate <= 0 || newRate == null) return null;

    final changeFraction = (newRate - oldRate).abs() / oldRate;
    if (changeFraction <= 0.01) return null;

    return RateSignalToast(
      oldRate: previousRate,
      newRate: newRateStr!,
      changeFraction: changeFraction,
    );
  }

  /// Extract the rate string from any rate-bearing variant ([RateUnavailable]
  /// carries no rate).
  String? _extractRate(RateResult result) => switch (result) {
    RateFetched(:final rate) => rate,
    RateCached(:final rate) => rate,
    RateFallback(:final rate) => rate,
    RateManual(:final rate) => rate,
    RateUnavailable() => null,
  };

  /// CR-02: local Y/M/D as UTC midnight — agrees with the cache service, the
  /// repo impl, and the API URL date. Do NOT `d.toUtc()` first (that shifted
  /// JST-midnight keys to the previous day).
  DateTime _normalizeToUtcMidnight(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day);
}
