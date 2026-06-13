@Tags(['golden'])
library;

// Widget + golden tests for [ConversionPreviewPanel] (Phase 42-07, DISP-01,
// D-03/D-04/D-05, CURR-04).
//
// Covers:
//  - loaded (fetched): main row ≈ ¥7,415 (USD 50 @ 148.30, single-site
//    convertToJpy figure) + rate sub-row, NO staleness label.
//  - fallback: amber "cached" staleness label present.
//  - weekend (fetched.actualDate ≠ txDate): amber business-day label present.
//  - loading: fixed-height skeleton, no layout jump (height == loaded height).
//  - JPY currency: panel not mounted (assert guards it — CURR-04).
//  - signals: D-02 dialog / D-03 toast surfaced via ref.listen (onSignal),
//    NOT a ref.watch rebuild.
//
// Goldens: {ja,zh,en} × {light,dark} subset per the analog. macOS baselines.
// currentLocaleProvider is overridden to avoid async retry timers.
//
// Run: flutter test test/features/accounting/presentation/widgets/conversion_preview_test.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/currency/rate_result.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/conversion_preview_panel.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;
import 'package:home_pocket/generated/app_localizations.dart';

// USD 50.00 entered → 5000 minor units; rate 148.30 → convertToJpy = 7415.
const _kCurrency = 'USD';
const _kMinorUnits = 5000;
const _kRate = '148.30';
final _kTxDate = DateTime(2026, 6, 11);

ConversionPreviewArgs _args() => ConversionPreviewArgs(
      currency: _kCurrency,
      date: _kTxDate,
      originalMinorUnits: _kMinorUnits,
    );

RateResultWithSignal _fetched() => RateResultWithSignal(
      result: RateFetched(
        rate: _kRate,
        currency: _kCurrency,
        rateDate: _kTxDate,
        source: 'frankfurter',
      ),
    );

RateResultWithSignal _fallback() => RateResultWithSignal(
      result: RateFallback(
        rate: _kRate,
        currency: _kCurrency,
        cachedDate: DateTime(2026, 6, 10),
      ),
    );

RateResultWithSignal _weekend() => RateResultWithSignal(
      result: RateFetched(
        rate: _kRate,
        currency: _kCurrency,
        rateDate: _kTxDate,
        // Requested Sun 2026-06-14, API returned Fri 2026-06-12 (proxy).
        actualDate: DateTime(2026, 6, 12),
        source: 'frankfurter',
      ),
    );

Widget _wrap({
  required Locale locale,
  required Override rateOverride,
  ThemeMode themeMode = ThemeMode.light,
  void Function(RateSignal signal)? onSignal,
  String currency = _kCurrency,
}) {
  return ProviderScope(
    overrides: [
      locale_providers.currentLocaleProvider.overrideWith((_) async => locale),
      rateOverride,
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 360,
            child: ConversionPreviewPanel(
              currency: currency,
              date: _kTxDate,
              originalMinorUnits: _kMinorUnits,
              onSignal: onSignal,
            ),
          ),
        ),
      ),
    ),
  );
}

Override _dataOverride(RateResultWithSignal value) =>
    conversionRateProvider(_args()).overrideWith((ref) async => value);

void main() {
  group('ConversionPreviewPanel behavior', () {
    testWidgets('loaded fetched: ≈ ¥7,415 main row + rate sub-row, no staleness',
        (tester) async {
      await tester.pumpWidget(
        _wrap(locale: const Locale('en'), rateOverride: _dataOverride(_fetched())),
      );
      await tester.pumpAndSettle();

      // Single-site figure binding (T-42-17): 5000/100 * 148.30 = 7415.
      expect(find.text('≈ ¥7,415'), findsOneWidget);
      // Rate sub-row.
      expect(find.textContaining('USD 1 = ¥148.30'), findsOneWidget);
      // No staleness wording for a fresh same-day fetched rate.
      expect(find.textContaining('cached'), findsNothing);
      expect(find.textContaining('business day'), findsNothing);
    });

    testWidgets('fallback: amber cached staleness label present', (tester) async {
      await tester.pumpWidget(
        _wrap(locale: const Locale('en'), rateOverride: _dataOverride(_fallback())),
      );
      await tester.pumpAndSettle();

      expect(find.text('≈ ¥7,415'), findsOneWidget);
      expect(find.textContaining('Using cached rate'), findsOneWidget);
    });

    testWidgets('weekend: business-day staleness label present', (tester) async {
      await tester.pumpWidget(
        _wrap(locale: const Locale('en'), rateOverride: _dataOverride(_weekend())),
      );
      await tester.pumpAndSettle();

      expect(find.text('≈ ¥7,415'), findsOneWidget);
      expect(find.textContaining('most recent business day'), findsOneWidget);
    });

    testWidgets('loaded no-staleness content is the fixed block height',
        (tester) async {
      await tester.pumpWidget(
        _wrap(locale: const Locale('en'), rateOverride: _dataOverride(_fetched())),
      );
      await tester.pumpAndSettle();

      // The loaded (no-staleness) content sits in a fixed-height SizedBox so the
      // loading skeleton (same height) does not cause a jump (D-04).
      final loadedBox = tester.widgetList<SizedBox>(find.descendant(
        of: find.byType(ConversionPreviewPanel),
        matching: find.byType(SizedBox),
      ));
      expect(loadedBox.any((b) => b.height == kConversionPreviewBlockHeight), isTrue);
    });

    testWidgets('loading shows the fixed-height skeleton, no figure (D-04)',
        (tester) async {
      final completer = Completer<RateResultWithSignal>();
      addTearDown(() => completer.complete(_fetched()));
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('en'),
          rateOverride: conversionRateProvider(_args())
              .overrideWith((ref) => completer.future),
        ),
      );
      await tester.pump(); // settle into loading; never complete the future

      // No converted figure while loading.
      expect(find.text('≈ ¥7,415'), findsNothing);
      // Skeleton occupies the same fixed block height (no jump).
      final boxes = tester.widgetList<SizedBox>(find.descendant(
        of: find.byType(ConversionPreviewPanel),
        matching: find.byType(SizedBox),
      ));
      expect(boxes.any((b) => b.height == kConversionPreviewBlockHeight), isTrue);
    });

    testWidgets('D-03 toast signal surfaced via ref.listen (onSignal), not watch',
        (tester) async {
      RateSignal? received;
      const toast = RateSignalToast(
        oldRate: '140.00',
        newRate: _kRate,
        changeFraction: 0.059,
      );
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('en'),
          rateOverride: _dataOverride(
            RateResultWithSignal(result: _fetched().result, signal: toast),
          ),
          onSignal: (s) => received = s,
        ),
      );
      await tester.pumpAndSettle();

      // Listener fired exactly once with the toast (non-blocking; preview still
      // rendered its main row).
      expect(received, isA<RateSignalToast>());
      expect(find.text('≈ ¥7,415'), findsOneWidget);
    });

    testWidgets('D-02 dialog signal surfaced via ref.listen', (tester) async {
      RateSignal? received;
      const dialog = RateSignalDialog(
        currency: _kCurrency,
        oldRate: '150.00',
        newRate: _kRate,
      );
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('en'),
          rateOverride: _dataOverride(
            RateResultWithSignal(result: _fetched().result, signal: dialog),
          ),
          onSignal: (s) => received = s,
        ),
      );
      await tester.pumpAndSettle();

      expect(received, isA<RateSignalDialog>());
    });

    testWidgets('panel asserts/refuses to render for JPY (CURR-04)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('en'),
          currency: 'JPY',
          rateOverride: _dataOverride(_fetched()),
        ),
      );
      await tester.pump();

      // The JPY guard fires during build — CURR-04 regression protection.
      expect(tester.takeException(), isA<AssertionError>());
      // And no converted figure leaks for the JPY path.
      expect(find.text('≈ ¥7,415'), findsNothing);
    });
  });

  group('ConversionPreviewPanel golden', () {
    Future<void> goldenCase(
      WidgetTester tester, {
      required Locale locale,
      required RateResultWithSignal value,
      required String name,
      ThemeMode themeMode = ThemeMode.light,
    }) async {
      await tester.pumpWidget(
        _wrap(
          locale: locale,
          rateOverride: _dataOverride(value),
          themeMode: themeMode,
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(ConversionPreviewPanel),
        matchesGoldenFile('goldens/conversion_preview_$name.png'),
      );
    }

    testWidgets('loaded ja', (tester) async {
      await goldenCase(tester,
          locale: const Locale('ja'), value: _fetched(), name: 'loaded_ja');
    });

    testWidgets('loaded ja dark', (tester) async {
      await goldenCase(tester,
          locale: const Locale('ja'),
          value: _fetched(),
          name: 'loaded_dark_ja',
          themeMode: ThemeMode.dark);
    });

    testWidgets('loaded en', (tester) async {
      await goldenCase(tester,
          locale: const Locale('en'), value: _fetched(), name: 'loaded_en');
    });

    testWidgets('fallback ja', (tester) async {
      await goldenCase(tester,
          locale: const Locale('ja'), value: _fallback(), name: 'fallback_ja');
    });

    testWidgets('weekend ja', (tester) async {
      await goldenCase(tester,
          locale: const Locale('ja'), value: _weekend(), name: 'weekend_ja');
    });

    testWidgets('loading ja', (tester) async {
      final completer = Completer<RateResultWithSignal>();
      addTearDown(() => completer.complete(_fetched()));
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('ja'),
          rateOverride:
              conversionRateProvider(_args()).overrideWith((ref) => completer.future),
        ),
      );
      await tester.pump();
      await expectLater(
        find.byType(ConversionPreviewPanel),
        matchesGoldenFile('goldens/conversion_preview_loading_ja.png'),
      );
    });
  });
}
