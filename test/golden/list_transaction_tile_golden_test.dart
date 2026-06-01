@Tags(['golden'])
library;

// Golden tests for ListTransactionTile — 3 locales × light theme (D-01/D-02/D-03).
//
// Baselines: test/golden/goldens/list_transaction_tile_{ja,zh,en}.png
// Run with: flutter test test/golden/list_transaction_tile_golden_test.dart
// Update:   flutter test test/golden/list_transaction_tile_golden_test.dart --update-goldens

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

/// Fixed fixture — no DateTime.now() dependency; values chosen for stable rendering.
TaggedTransaction _makeTx() {
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

/// Wraps a ListTransactionTile inside a ProviderScope + MaterialApp.
///
/// ProviderScope is required because [ListTransactionTile] is a [ConsumerWidget]
/// (deleteTransactionUseCaseProvider read in onDismissed — not called during build,
/// so no override is needed for the golden render).
Widget _wrap({required Locale locale}) {
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
      home: Scaffold(
        body: SizedBox(
          width: 390,
          height: 80,
          child: ListTransactionTile(
            taggedTx: _makeTx(),
            bookId: 'book_golden',
            onTap: () {},
            onDeleted: () {},
            tagText: 'Survival',
            tagBgColor: AppPalette.light.dailyLight,
            tagTextColor: AppPalette.light.daily,
            category: 'Food',
            categoryColor: AppPalette.light.daily,
            formattedAmount: '¥1,234',
            l1Icon: Icons.restaurant,
            locale: const Locale('ja'),
            merchant: null,
            satisfactionIcon: null,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('ListTransactionTile golden', () {
    testWidgets('locale ja', (tester) async {
      await tester.pumpWidget(_wrap(locale: const Locale('ja')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(ListTransactionTile),
        matchesGoldenFile('goldens/list_transaction_tile_ja.png'),
      );
    });

    testWidgets('locale zh', (tester) async {
      await tester.pumpWidget(_wrap(locale: const Locale('zh')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(ListTransactionTile),
        matchesGoldenFile('goldens/list_transaction_tile_zh.png'),
      );
    });

    testWidgets('locale en', (tester) async {
      await tester.pumpWidget(_wrap(locale: const Locale('en')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(ListTransactionTile),
        matchesGoldenFile('goldens/list_transaction_tile_en.png'),
      );
    });
  });
}
