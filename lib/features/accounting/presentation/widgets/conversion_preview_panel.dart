import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/currency/get_exchange_rate_use_case.dart';
import '../../../../application/currency/rate_result.dart';
import '../../../../application/currency/repository_providers.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/date_formatter.dart';

part 'conversion_preview_panel.g.dart';

/// Keyed rate-resolution module for the foreign-currency conversion UI.
///
/// Quick 260613-ufn: the standalone `ConversionPreviewPanel` widget (the large
/// `≈¥{jpy}` block on the add screen) was REMOVED — both the add and edit
/// screens now render the unified [CurrencyLinkedEditFields] card (D-1). This
/// file retains the SHARED rate plumbing both screens consume:
///   - [ConversionPreviewArgs] — the value-equal provider key.
///   - [conversionRateProvider] — the keyed `appGetExchangeRateUseCaseProvider`
///     resolver.
///   - [rateStringOf] / [rateEffectiveDateOf] / [stalenessNoteFor] — the SINGLE
///     staleness-derivation site reused by the add-screen wrapper and the edit
///     host (no duplicated `_stalenessLabel`).

/// Immutable key for [conversionRate]: the rate is recomputed only when one of
/// (currency, date, previousRate, wasManualOverride) changes. Value equality
/// keeps the keyed [FutureProvider] from refetching on unrelated rebuilds
/// (T-42-18).
///
/// Quick 260613-wuv2: the entered AMOUNT is deliberately NOT part of this key.
/// The rate depends only on (currency, date) — the use case never reads the
/// amount — so keying on it forced a brand-new provider (a fresh `AsyncLoading`
/// → spinner flash → whole-card re-collapse) on every settled keystroke. The
/// amount flows to the card separately (`originalAmount`) where it drives only
/// the derived-JPY recompute, so typing now refreshes the converted number
/// alone, never the whole card.
@immutable
class ConversionPreviewArgs {
  const ConversionPreviewArgs({
    required this.currency,
    required this.date,
    this.previousRate,
    this.wasManualOverride = false,
  });

  /// ISO 4217 code of the foreign currency being entered. Never `'JPY'`
  /// (foreign rows only — CURR-04).
  final String currency;

  /// Transaction date the rate is requested for.
  final DateTime date;

  /// Previously-applied rate (drives the ADR-022 D-03 >1% toast in the use
  /// case). Null on first lookup.
  final String? previousRate;

  /// ADR-022 D-02 flag — the previous rate was a user manual override.
  final bool wasManualOverride;

  @override
  bool operator ==(Object other) =>
      other is ConversionPreviewArgs &&
      other.currency == currency &&
      other.date == date &&
      other.previousRate == previousRate &&
      other.wasManualOverride == wasManualOverride;

  @override
  int get hashCode => Object.hash(
        currency,
        date,
        previousRate,
        wasManualOverride,
      );
}

/// Keyed rate provider. Resolves the [RateResultWithSignal] for the given
/// (currency, date, amount) via the already-wired P41
/// `appGetExchangeRateUseCaseProvider`. The result carries the D-02 dialog /
/// D-03 toast signals pre-computed by the use case — callers never recompute
/// the >1% threshold (RESEARCH Don't-Hand-Roll).
@riverpod
Future<RateResultWithSignal> conversionRate(
  Ref ref,
  ConversionPreviewArgs args,
) {
  final useCase = ref.watch(appGetExchangeRateUseCaseProvider);
  return useCase.execute(
    GetExchangeRateParams(
      currency: args.currency,
      date: args.date,
      previousRate: args.previousRate,
      wasManualOverride: args.wasManualOverride,
    ),
  );
}

/// Full-precision rate string for any rate-bearing [RateResult] variant; null
/// for [RateUnavailable]. Single extraction site (ADR-020).
String? rateStringOf(RateResult r) => switch (r) {
      RateFetched(:final rate) => rate,
      RateCached(:final rate) => rate,
      RateFallback(:final rate) => rate,
      RateManual(:final rate) => rate,
      RateUnavailable() => null,
    };

/// The date the displayed rate is effectively keyed to (for the 汇率日期 row +
/// staleness). For a [RateFetched] this prefers `actualDate` (weekend/holiday
/// business-day proxy, RATE-05) over the requested `rateDate`.
DateTime rateEffectiveDateOf(RateResult r, DateTime requestedDate) =>
    switch (r) {
      RateFetched(:final rateDate, :final actualDate) => actualDate ?? rateDate,
      RateCached(:final cachedDate) => cachedDate,
      RateFallback(:final cachedDate) => cachedDate,
      RateManual(:final cachedDate) => cachedDate,
      RateUnavailable() => requestedDate,
    };

/// SINGLE staleness-derivation site (D-2). Returns the localized warning label
/// for a stale rate — a cached fallback, OR a fetched rate whose `actualDate`
/// differs from the requested transaction date (weekend/holiday business-day
/// proxy). Returns null for a fresh same-day rate. Reused by the add-screen
/// wrapper and the edit host so the staleness string is derived in exactly one
/// place (CLAUDE.md many-small-files; no duplicated `_stalenessLabel`).
String? stalenessNoteFor({
  required RateResult result,
  required DateTime requestedDate,
  required S l10n,
  required Locale locale,
}) {
  switch (result) {
    case RateFallback(:final cachedDate):
      return l10n.conversionStalenessCached(
        DateFormatter.formatDate(cachedDate, locale),
      );
    case RateFetched(:final actualDate):
      if (actualDate != null && !_sameDay(actualDate, requestedDate)) {
        return l10n.conversionStalenessWeekend(
          DateFormatter.formatDate(actualDate, locale),
        );
      }
      return null;
    case RateCached():
    case RateManual():
    case RateUnavailable():
      return null;
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
