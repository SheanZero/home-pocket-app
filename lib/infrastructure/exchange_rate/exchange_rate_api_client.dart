import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Stateless HTTP wrapper for the three-source exchange-rate fallback chain.
///
/// Source order (RATE-01):
///   1. Frankfurter   — `https://api.frankfurter.dev/v1/{date}?from=JPY&to={C}`
///   2. fawazahmed0 jsDelivr — `https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@{date}/v1/currencies/jpy.min.json`
///   3. fawazahmed0 Cloudflare — `https://{date}.currency-api.pages.dev/v1/currencies/jpy.min.json`
///
/// A Frankfurter 404 means "currency not in this source" (e.g. TWD) and routes
/// onward to fawazahmed0 — it is NOT a fetch failure. Any other error (4xx/5xx,
/// timeout, exception) also routes onward. Only when all three sources fail does
/// this client throw [ExchangeRateApiException].
///
/// Privacy (SC-5 / T-41-05): every constructed URL contains ONLY a YYYY-MM-DD
/// date and an ISO 4217 currency code — no identifiers, ledger references,
/// monetary values, or other caller-derived data. The full URL is logged only
/// under [kDebugMode].
class ExchangeRateApiClient {
  ExchangeRateApiClient({http.Client? httpClient})
    : _client = httpClient ?? http.Client();

  final http.Client _client;

  static const String _frankfurterBase = 'https://api.frankfurter.dev/v1';
  static const String _fawazahmedJsDelivr =
      'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api';

  static const Duration _primaryTimeout = Duration(milliseconds: 1500);
  static const Duration _cloudflareTimeout = Duration(milliseconds: 1000);

  /// Fetch the JPY-per-[currency] rate for [date].
  ///
  /// Returns a record of the full-precision rate string, the actual rate date
  /// (non-null only when the API returned a different date — RATE-05), and the
  /// originating source ('frankfurter' | 'fawazahmed0').
  ///
  /// Throws [ExchangeRateApiException] when all three sources fail.
  Future<({String rate, DateTime? actualRateDate, String source})> fetchRate(
    String currency,
    DateTime date,
  ) async {
    final dateStr = _formatDate(date);
    final upper = currency.toUpperCase();
    final lower = currency.toLowerCase();

    if (kDebugMode) {
      debugPrint('[RateAPI] fetching $upper for $dateStr');
    } else {
      debugPrint('[RateAPI] fetching $upper');
    }

    // 1. Frankfurter primary.
    final frankfurter = await _tryFrankfurter(upper, dateStr);
    if (frankfurter != null) return frankfurter;

    // 2. fawazahmed0 jsDelivr.
    final jsDelivrUrl =
        '$_fawazahmedJsDelivr@$dateStr/v1/currencies/jpy.min.json';
    final jsDelivr = await _tryFawazahmed(
      jsDelivrUrl,
      lower,
      _primaryTimeout,
    );
    if (jsDelivr != null) return jsDelivr;

    // 3. fawazahmed0 Cloudflare fallback.
    final cloudflareUrl =
        'https://$dateStr.currency-api.pages.dev/v1/currencies/jpy.min.json';
    final cloudflare = await _tryFawazahmed(
      cloudflareUrl,
      lower,
      _cloudflareTimeout,
    );
    if (cloudflare != null) return cloudflare;

    throw ExchangeRateApiException(
      'All sources failed for $currency on $dateStr',
    );
  }

  Future<({String rate, DateTime? actualRateDate, String source})?>
  _tryFrankfurter(String upperCurrency, String dateStr) async {
    final url = Uri.parse(
      '$_frankfurterBase/$dateStr?from=JPY&to=$upperCurrency',
    );
    try {
      final response = await _client.get(url).timeout(_primaryTimeout);
      final status = response.statusCode;
      final rawJson = response.body;
      if (kDebugMode) {
        debugPrint('[RateAPI] frankfurter $status $url');
      }
      if (status != 200) {
        // 404 = currency not in Frankfurter; any non-200 routes onward.
        return null;
      }
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final rates = decoded['rates'] as Map<String, dynamic>?;
      final rawRate = (rates?[upperCurrency] as num?)?.toDouble();
      if (rawRate == null || rawRate == 0 || !rawRate.isFinite) {
        // T-41-06: guard against division by zero / non-finite.
        return null;
      }
      final responseDate = decoded['date'] as String?;
      final actualRateDate = (responseDate != null && responseDate != dateStr)
          ? DateTime.parse(responseDate)
          : null;
      return (
        rate: _invert(rawRate),
        actualRateDate: actualRateDate,
        source: 'frankfurter',
      );
    } catch (_) {
      return null;
    }
  }

  Future<({String rate, DateTime? actualRateDate, String source})?>
  _tryFawazahmed(String url, String lowerCurrency, Duration timeout) async {
    try {
      final response = await _client.get(Uri.parse(url)).timeout(timeout);
      final status = response.statusCode;
      final rawJson = response.body;
      if (kDebugMode) {
        debugPrint('[RateAPI] fawazahmed0 $status $url');
      }
      if (status != 200) return null;
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final jpy = decoded['jpy'] as Map<String, dynamic>?;
      final rawRate = (jpy?[lowerCurrency] as num?)?.toDouble();
      if (rawRate == null || rawRate == 0 || !rawRate.isFinite) {
        return null;
      }
      return (
        rate: _invert(rawRate),
        actualRateDate: null,
        source: 'fawazahmed0',
      );
    } catch (_) {
      return null;
    }
  }

  /// Invert a foreign-per-JPY rate into a JPY-per-unit string.
  ///
  /// 7 significant figures gives enough precision for JPY conversion without
  /// float bloat (RESEARCH.md).
  String _invert(double rawRate) =>
      (1.0 / rawRate).toStringAsPrecision(7);

  /// Local-date YYYY-MM-DD components — no timezone conversion (device local
  /// date matches the transaction date picker per CONTEXT.md).
  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

/// Thrown when every exchange-rate source in the fallback chain fails.
class ExchangeRateApiException implements Exception {
  const ExchangeRateApiException(this.message);

  final String message;

  @override
  String toString() => 'ExchangeRateApiException: $message';
}
