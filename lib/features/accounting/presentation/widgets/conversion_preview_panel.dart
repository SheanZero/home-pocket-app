import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/currency/get_exchange_rate_use_case.dart';
import '../../../../application/currency/rate_result.dart';
import '../../../../application/currency/repository_providers.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/date_formatter.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../../../shared/utils/currency_conversion.dart';
import '../../../settings/presentation/providers/state_locale.dart';

part 'conversion_preview_panel.g.dart';

/// Fixed height of the preview block (main row + sub-row + gaps). The loading
/// skeleton uses the SAME height so the panel does not jump when the rate
/// resolves (D-04, RESEARCH Pitfall 5 — no text jump, no keyboard occlusion).
const double kConversionPreviewBlockHeight = 56;

/// Immutable key for [conversionRate]: the preview rate is recomputed only when
/// one of (currency, date, original minor units) changes. Value equality keeps
/// the keyed [FutureProvider] from refetching on unrelated rebuilds (T-42-18).
@immutable
class ConversionPreviewArgs {
  const ConversionPreviewArgs({
    required this.currency,
    required this.date,
    required this.originalMinorUnits,
    this.previousRate,
    this.wasManualOverride = false,
  });

  /// ISO 4217 code of the foreign currency being entered. Never `'JPY'`
  /// (the panel is not mounted for JPY — CURR-04).
  final String currency;

  /// Transaction date the rate is requested for.
  final DateTime date;

  /// Entered amount in the currency's minor units (e.g. cents for USD).
  final int originalMinorUnits;

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
      other.originalMinorUnits == originalMinorUnits &&
      other.previousRate == previousRate &&
      other.wasManualOverride == wasManualOverride;

  @override
  int get hashCode => Object.hash(
        currency,
        date,
        originalMinorUnits,
        previousRate,
        wasManualOverride,
      );
}

/// Keyed rate provider for the preview. Resolves the [RateResultWithSignal] for
/// the given (currency, date, amount) via the already-wired P41
/// `appGetExchangeRateUseCaseProvider`. The result carries the D-02 dialog /
/// D-03 toast signals pre-computed by the use case — the panel never
/// recomputes the >1% threshold (RESEARCH Don't-Hand-Roll).
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

/// Live JPY conversion preview shown below the amount during foreign entry
/// (DISP-01, D-03/D-04/D-05).
///
/// - Main row `≈ ¥{jpy}` (`AppTextStyles.amountLarge`) where `jpy` is computed
///   via the single-site [convertToJpy] — NEVER an inline `rate * amount`
///   (ADR-020 / UI-SPEC invariant #4), guaranteeing the figure matches the list
///   annotation and the edit read-only JPY.
/// - Sub-row `{CODE} 1 = ¥{rate} · {date}` (`AppTextStyles.labelMedium`).
/// - Loading is an in-place fixed-height skeleton (no jump, no keyboard
///   occlusion — D-04).
/// - A warning-amber staleness label appears below the sub-row for
///   [RateFallback] (cached) or when `fetched.actualDate ≠ txDate`
///   (weekend/holiday proxy — D-05). Warning amber is reserved for this only.
/// - The [RateSignal] (dialog/toast) is surfaced via `ref.listen` — NEVER
///   `ref.watch` (Riverpod 3 side-effect rule).
class ConversionPreviewPanel extends ConsumerWidget {
  const ConversionPreviewPanel({
    required this.currency,
    required this.date,
    required this.originalMinorUnits,
    this.previousRate,
    this.wasManualOverride = false,
    this.onSignal,
    super.key,
  });

  /// ISO 4217 code of the foreign currency. Must NOT be `'JPY'` — the host
  /// guards mounting (42-08); this panel also asserts it (CURR-04).
  final String currency;

  /// Transaction date the rate is requested for.
  final DateTime date;

  /// Entered amount in the currency's minor units.
  final int originalMinorUnits;

  /// Previously-applied rate, forwarded to the use case for the D-03 toast.
  final String? previousRate;

  /// ADR-022 D-02 flag, forwarded to the use case for the conflict dialog.
  final bool wasManualOverride;

  /// Side-effect sink for the ADR-022 [RateSignal] (D-02 dialog / D-03 toast).
  /// Invoked from `ref.listen`, never from a `ref.watch` rebuild. The host
  /// (42-08) decides how to render the dialog/toast.
  final void Function(RateSignal signal)? onSignal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // CURR-04 hard invariant: the preview never renders for JPY.
    assert(
      currency.toUpperCase() != 'JPY',
      'ConversionPreviewPanel must not be mounted for JPY (CURR-04)',
    );

    final palette = context.palette;
    final l10n = S.of(context);
    final localeAsync = ref.watch(currentLocaleProvider);
    final locale = localeAsync.value ?? const Locale('ja');

    final args = ConversionPreviewArgs(
      currency: currency,
      date: date,
      originalMinorUnits: originalMinorUnits,
      previousRate: previousRate,
      wasManualOverride: wasManualOverride,
    );

    // Side-effects (D-02 dialog / D-03 toast) belong in ref.listen, not
    // ref.watch (Riverpod 3 — CLAUDE.md / RESEARCH Pitfall 4).
    ref.listen<AsyncValue<RateResultWithSignal>>(
      conversionRateProvider(args),
      (previous, next) {
        final signal = next.value?.signal;
        if (signal != null) {
          onSignal?.call(signal);
        }
      },
    );

    final rateAsync = ref.watch(conversionRateProvider(args));

    return rateAsync.when(
      loading: () => const _PreviewSkeleton(),
      // Network failure degrades to fallback upstream; an error here is
      // unexpected — surface the mandatory-rate prompt rather than crash.
      error: (_, _) => _RateRequiredPrompt(palette: palette, l10n: l10n),
      data: (withSignal) => _PreviewContent(
        result: withSignal.result,
        currency: currency,
        date: date,
        originalMinorUnits: originalMinorUnits,
        locale: locale,
        palette: palette,
        l10n: l10n,
      ),
    );
  }
}

/// Fixed-height in-place loading skeleton (D-04). Same height as the loaded
/// content so the surrounding layout does not jump.
class _PreviewSkeleton extends StatelessWidget {
  const _PreviewSkeleton();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      height: kConversionPreviewBlockHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SkeletonBar(width: 140, height: 28, color: palette.backgroundMuted),
          const SizedBox(height: 8),
          _SkeletonBar(width: 180, height: 14, color: palette.backgroundMuted),
        ],
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
      child: SizedBox(width: width, height: height),
    );
  }
}

/// Loaded preview: main JPY row + rate sub-row (+ optional staleness label).
class _PreviewContent extends StatelessWidget {
  const _PreviewContent({
    required this.result,
    required this.currency,
    required this.date,
    required this.originalMinorUnits,
    required this.locale,
    required this.palette,
    required this.l10n,
  });

  final RateResult result;
  final String currency;
  final DateTime date;
  final int originalMinorUnits;
  final Locale locale;
  final AppPalette palette;
  final S l10n;

  @override
  Widget build(BuildContext context) {
    // RateUnavailable (D-08): no rate to render — prompt for a manual rate.
    final rate = _rateOf(result);
    if (rate == null) {
      return _RateRequiredPrompt(palette: palette, l10n: l10n);
    }

    // Single conversion site — NEVER inline rate * amount (ADR-020).
    final jpy = convertToJpy(
      originalMinorUnits: originalMinorUnits,
      appliedRate: rate,
      subunitToUnit: subunitToUnitFor(currency),
    );

    final rateDate = _rateDateOf(result);
    final staleness = _stalenessLabel(result, rateDate);

    return SizedBox(
      height: staleness == null ? kConversionPreviewBlockHeight : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main row — ≈ ¥{jpy}, tabular amount (D-03).
          Text(
            '≈ ${NumberFormatter.formatCurrency(jpy, 'JPY', locale)}',
            style: AppTextStyles.amountLarge.copyWith(
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          // Sub-row — {CODE} 1 = ¥{rate} · {date} (D-03).
          Text(
            l10n.conversionPreviewRateRow(
              currency.toUpperCase(),
              rate,
              DateFormatter.formatDate(rateDate, locale),
            ),
            style: AppTextStyles.labelMedium.copyWith(
              color: palette.textSecondary,
            ),
          ),
          // Staleness label (D-05) — warning amber, reserved for this only.
          if (staleness != null) ...[
            const SizedBox(height: 4),
            Text(
              staleness,
              style: AppTextStyles.labelMedium.copyWith(
                color: palette.warning,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Rate string for any rate-bearing variant ([RateUnavailable] carries none).
  String? _rateOf(RateResult r) => switch (r) {
        RateFetched(:final rate) => rate,
        RateCached(:final rate) => rate,
        RateFallback(:final rate) => rate,
        RateManual(:final rate) => rate,
        RateUnavailable() => null,
      };

  /// The date the displayed rate is keyed to (for the sub-row + staleness).
  DateTime _rateDateOf(RateResult r) => switch (r) {
        RateFetched(:final rateDate, :final actualDate) => actualDate ?? rateDate,
        RateCached(:final cachedDate) => cachedDate,
        RateFallback(:final cachedDate) => cachedDate,
        RateManual(:final cachedDate) => cachedDate,
        RateUnavailable() => date,
      };

  /// D-05: warning label for a stale rate — cached fallback, OR a fetched rate
  /// whose `actualDate` differs from the requested transaction date
  /// (weekend/holiday business-day proxy). Returns null for a fresh same-day
  /// rate.
  String? _stalenessLabel(RateResult r, DateTime rateDate) {
    switch (r) {
      case RateFallback():
        return l10n.conversionStalenessCached(
          DateFormatter.formatDate(rateDate, locale),
        );
      case RateFetched(:final actualDate):
        if (actualDate != null && !_sameDay(actualDate, date)) {
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
}

/// Mandatory-manual-rate prompt (P41 D-08 / RateUnavailable). Fixed-height to
/// preserve layout stability. Error color — save is gated on a present rate.
class _RateRequiredPrompt extends StatelessWidget {
  const _RateRequiredPrompt({required this.palette, required this.l10n});

  final AppPalette palette;
  final S l10n;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kConversionPreviewBlockHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          l10n.conversionRateRequired,
          style: AppTextStyles.labelMedium.copyWith(color: palette.error),
        ),
      ),
    );
  }
}
