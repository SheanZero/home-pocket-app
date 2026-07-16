@Tags(['golden'])
library;

// Golden tests for the DISP-02 FOREIGN-row annotation on ListTransactionTile —
// {ja,zh,en} × {light,dark}. A foreign row (originalCurrency != null && != 'JPY')
// shows a small secondary `USD 50.00` annotation (labelMedium / textSecondary)
// under the JPY amount.
//
// CURR-04 regression protection: the LAST test asserts that a JPY/domestic row
// (foreignAnnotation == null) still matches the EXISTING JPY baseline
// `goldens/list_transaction_tile_ja.png` — proving the annotation change keeps
// the JPY path byte-identical (no rebaseline of the JPY golden).
//
// Baselines (foreign variant only, macOS): goldens/list_transaction_tile_foreign_{ja,zh,en,dark_ja,dark_zh,dark_en}.png
// Run with: flutter test test/golden/list_transaction_tile_foreign_golden_test.dart
// Update:   flutter test test/golden/list_transaction_tile_foreign_golden_test.dart --update-goldens

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_palette.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/list/domain/models/tagged_transaction.dart';
import 'package:home_pocket/features/list/presentation/widgets/list_transaction_tile.dart';
import 'package:home_pocket/generated/app_localizations.dart';

/// Foreign-currency fixture: USD 50.00 (5000 minor units) → 7415 JPY @ 148.30.
/// Mirrors the SC-5 locked figure so the annotation reflects a real foreign row.
TaggedTransaction _makeForeignTx() {
  final now = DateTime(2026, 5, 1, 10, 30);
  return TaggedTransaction(
    transaction: Transaction(
      id: 'tx-foreign-golden',
      bookId: 'book_golden',
      deviceId: 'device1',
      amount: 7415,
      type: TransactionType.expense,
      categoryId: 'cat_food',
      ledgerType: LedgerType.daily,
      timestamp: now,
      currentHash: 'stub_hash',
      createdAt: now,
      entrySource: EntrySource.manual,
      originalCurrency: 'USD',
      originalAmount: 5000,
      appliedRate: '148.30',
    ),
  );
}

/// JPY/domestic fixture — identical to the existing JPY golden's fixture so the
/// CURR-04 byte-identical assertion can reuse that baseline.
TaggedTransaction _makeJpyTx() {
  final now = DateTime(2026, 5, 1, 10, 30);
  return TaggedTransaction(
    transaction: Transaction(
      id: 'tx-golden',
      bookId: 'book_golden',
      deviceId: 'device1',
      amount: 1234,
      type: TransactionType.expense,
      categoryId: 'cat_food',
      ledgerType: LedgerType.daily,
      timestamp: now,
      currentHash: 'stub_hash',
      createdAt: now,
      entrySource: EntrySource.manual,
    ),
  );
}

Widget _wrap({
  required Locale locale,
  required TaggedTransaction tx,
  String? foreignAnnotation,
  ThemeMode themeMode = ThemeMode.light,
  Color? tagBgColor,
  Color? tagTextColor,
  Color? categoryColor,
}) {
  final effectiveTagBgColor = tagBgColor ?? AppPalette.light.dailyLight;
  final effectiveTagTextColor = tagTextColor ?? AppPalette.light.daily;
  final effectiveCategoryColor = categoryColor ?? AppPalette.light.daily;
  return ProviderScope(
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
        body: SizedBox(
          width: 390,
          height: 68,
          child: ListTransactionTile(
            taggedTx: tx,
            bookId: 'book_golden',
            onTap: () {},
            onDeleted: () {},
            tagText: 'Survival',
            tagBgColor: effectiveTagBgColor,
            tagTextColor: effectiveTagTextColor,
            category: 'Food',
            categoryColor: effectiveCategoryColor,
            formattedAmount: '¥1,234',
            l1Icon: Icons.restaurant,
            locale: const Locale('ja'),
            merchant: null,
            satisfactionValue: null,
            foreignAnnotation: foreignAnnotation,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('ListTransactionTile foreign annotation golden (DISP-02)', () {
    for (final entry in <String, Locale>{
      'ja': Locale('ja'),
      'zh': Locale('zh'),
      'en': Locale('en'),
    }.entries) {
      final code = entry.key;
      final locale = entry.value;

      testWidgets('foreign row $code (light)', (tester) async {
        await tester.pumpWidget(
          _wrap(
            locale: locale,
            tx: _makeForeignTx(),
            foreignAnnotation: 'USD 50.00',
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(ListTransactionTile),
          matchesGoldenFile('goldens/list_transaction_tile_foreign_$code.png'),
        );
      });

      testWidgets('foreign row $code (dark)', (tester) async {
        await tester.pumpWidget(
          _wrap(
            locale: locale,
            tx: _makeForeignTx(),
            foreignAnnotation: 'USD 50.00',
            themeMode: ThemeMode.dark,
            tagBgColor: AppPalette.dark.dailyLight,
            tagTextColor: AppPalette.dark.daily,
            categoryColor: AppPalette.dark.daily,
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(ListTransactionTile),
          matchesGoldenFile(
            'goldens/list_transaction_tile_foreign_dark_$code.png',
          ),
        );
      });
    }

    // CURR-04: a JPY/domestic row (foreignAnnotation == null) must still match
    // the EXISTING JPY baseline — proves the annotation change kept the JPY path
    // byte-identical (no rebaseline). Reuses goldens/list_transaction_tile_ja.png.
    testWidgets('JPY row byte-identical to existing baseline (CURR-04)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(locale: const Locale('ja'), tx: _makeJpyTx()),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(ListTransactionTile),
        matchesGoldenFile('goldens/list_transaction_tile_ja.png'),
      );
    });
  });
}
