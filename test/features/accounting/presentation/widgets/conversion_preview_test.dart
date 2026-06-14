// Tests for the shared rate-resolution module in conversion_preview_panel.dart.
//
// Quick 260613-ufn: the standalone `ConversionPreviewPanel` widget (the large
// `≈¥{jpy}` add-screen block) was REMOVED — both screens now render the unified
// [CurrencyLinkedEditFields] card (D-1). What remains in this file is the SHARED
// rate plumbing both screens consume, so these tests pin that contract:
//   - rateStringOf / rateEffectiveDateOf — rate + effective-date extraction.
//   - stalenessNoteFor — the SINGLE staleness-derivation site (D-2): fallback →
//     cached label, weekend (fetched.actualDate ≠ txDate) → business-day label,
//     fresh same-day → null.
//   - ConversionPreviewArgs value-equality (keyed-provider stability, T-42-18).
//
// Run: flutter test test/features/accounting/presentation/widgets/conversion_preview_test.dart

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/currency/rate_result.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/conversion_preview_panel.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

const _kCurrency = 'USD';
const _kRate = '148.30';
final _kTxDate = DateTime(2026, 6, 11);

RateFetched _fetched({DateTime? actualDate}) => RateFetched(
      rate: _kRate,
      currency: _kCurrency,
      rateDate: _kTxDate,
      actualDate: actualDate,
      source: 'frankfurter',
    );

RateFallback _fallback() => RateFallback(
      rate: _kRate,
      currency: _kCurrency,
      cachedDate: DateTime(2026, 6, 10),
    );

/// Resolves the `en` [S] delegate for the staleness-label assertions.
Future<S> _enStrings() => S.delegate.load(const Locale('en'));

void main() {
  setUpAll(() async {
    // DateFormatter.formatDate needs locale date symbols initialized for the
    // staleness-label assertions (which format the effective rate date).
    await initializeDateFormatting('en');
  });

  group('rateStringOf — full-precision rate extraction (ADR-020)', () {
    test('rate-bearing variants return their rate; RateUnavailable → null', () {
      expect(rateStringOf(_fetched()), _kRate);
      expect(rateStringOf(_fallback()), _kRate);
      expect(
        rateStringOf(
          RateCached(
            rate: _kRate,
            currency: _kCurrency,
            cachedDate: _kTxDate,
            source: 'frankfurter',
          ),
        ),
        _kRate,
      );
      expect(
        rateStringOf(
          RateManual(rate: _kRate, currency: _kCurrency, cachedDate: _kTxDate),
        ),
        _kRate,
      );
      expect(rateStringOf(const RateUnavailable(currency: _kCurrency)), isNull);
    });
  });

  group('rateEffectiveDateOf — actualDate wins over requested (RATE-05)', () {
    test('fetched prefers actualDate when present', () {
      final actual = DateTime(2026, 6, 12);
      expect(rateEffectiveDateOf(_fetched(actualDate: actual), _kTxDate), actual);
    });

    test('fetched without actualDate falls back to rateDate', () {
      expect(rateEffectiveDateOf(_fetched(), _kTxDate), _kTxDate);
    });

    test('fallback uses its cachedDate', () {
      expect(rateEffectiveDateOf(_fallback(), _kTxDate), DateTime(2026, 6, 10));
    });
  });

  group('stalenessNoteFor — SINGLE staleness-derivation site (D-2)', () {
    testWidgets('fallback → cached staleness label', (tester) async {
      final l10n = await _enStrings();
      final note = stalenessNoteFor(
        result: _fallback(),
        requestedDate: _kTxDate,
        l10n: l10n,
        locale: const Locale('en'),
      );
      expect(note, isNotNull);
      expect(note, contains('cached'));
    });

    testWidgets('weekend (actualDate ≠ txDate) → business-day label', (
      tester,
    ) async {
      final l10n = await _enStrings();
      final note = stalenessNoteFor(
        result: _fetched(actualDate: DateTime(2026, 6, 12)),
        requestedDate: _kTxDate,
        l10n: l10n,
        locale: const Locale('en'),
      );
      expect(note, isNotNull);
      expect(note, contains('business day'));
    });

    testWidgets('fresh same-day fetched → null (no staleness)', (tester) async {
      final l10n = await _enStrings();
      final note = stalenessNoteFor(
        result: _fetched(),
        requestedDate: _kTxDate,
        l10n: l10n,
        locale: const Locale('en'),
      );
      expect(note, isNull);
    });

    testWidgets('cached / manual / unavailable → null', (tester) async {
      final l10n = await _enStrings();
      for (final r in <RateResult>[
        RateCached(
          rate: _kRate,
          currency: _kCurrency,
          cachedDate: _kTxDate,
          source: 'frankfurter',
        ),
        RateManual(rate: _kRate, currency: _kCurrency, cachedDate: _kTxDate),
        const RateUnavailable(currency: _kCurrency),
      ]) {
        expect(
          stalenessNoteFor(
            result: r,
            requestedDate: _kTxDate,
            l10n: l10n,
            locale: const Locale('en'),
          ),
          isNull,
        );
      }
    });
  });

  group('ConversionPreviewArgs — value equality (keyed-provider stability)', () {
    test('equal args are ==; differing date/currency are not; amount is NOT a '
        'key dimension (260613-wuv2)', () {
      final a = ConversionPreviewArgs(currency: _kCurrency, date: _kTxDate);
      final b = ConversionPreviewArgs(currency: _kCurrency, date: _kTxDate);
      expect(a, b);
      expect(a.hashCode, b.hashCode);

      expect(
        a == ConversionPreviewArgs(currency: _kCurrency, date: DateTime(2026, 6, 12)),
        isFalse,
      );
      expect(
        a == ConversionPreviewArgs(currency: 'EUR', date: _kTxDate),
        isFalse,
      );
    });
  });
}
