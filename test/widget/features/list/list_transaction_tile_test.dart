// Wave 0 widget test stubs for ListTransactionTile (ROW-01 / ROW-02).
//
// ListTransactionTile is defined in:
//   lib/features/list/presentation/widgets/list_transaction_tile.dart
// TODO: created in 28-03 — that widget does not exist yet; the import below
// will fail to resolve until Wave 2 (28-03) creates the file.
//
// Run: flutter test test/widget/features/list/list_transaction_tile_test.dart

// ignore_for_file: unused_import, unused_element
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/delete_transaction_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/list/domain/models/tagged_transaction.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
// TODO: created in 28-03
// import 'package:home_pocket/features/list/presentation/widgets/list_transaction_tile.dart';

class _MockDeleteTransactionUseCase extends Mock
    implements DeleteTransactionUseCase {}

/// Minimal TaggedTransaction fixture for widget tests.
TaggedTransaction _makeTx({String id = 'tx-1'}) {
  final now = DateTime(2026, 5, 1, 10, 30);
  return TaggedTransaction(
    transaction: Transaction(
      id: id,
      bookId: 'book1',
      deviceId: 'device1',
      amount: 1500,
      type: TransactionType.expense,
      categoryId: 'cat_food',
      ledgerType: LedgerType.survival,
      timestamp: now,
      currentHash: 'stub_hash',
      createdAt: now,
      entrySource: EntrySource.manual,
    ),
  );
}

/// Pumps a ListTransactionTile inside UncontrolledProviderScope + MaterialApp.
///
/// TODO: uncomment and wire ListTransactionTile once 28-03 creates it.
Future<void> _pumpTile(
  WidgetTester tester,
  ProviderContainer container,
  TaggedTransaction tx,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Center(
            // TODO: created in 28-03 — replace Center placeholder with:
            // ListTransactionTile(
            //   taggedTx: tx,
            //   bookId: 'book1',
            //   onTap: () {},
            //   tagText: '生存',
            //   tagBgColor: const Color(0xFFE8F0F8),
            //   tagTextColor: const Color(0xFF5A9CC8),
            //   category: '食費',
            //   categoryColor: const Color(0xFF5A9CC8),
            //   formattedAmount: '¥1,500',
            //   formattedTime: '10:30',
            // ),
            child: Text('stub: ${tx.transaction.id}'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ListTransactionTile', () {
    testWidgets('ROW-01: tapping tile navigates to TransactionEditScreen',
        (tester) async {
      final container = ProviderContainer.test();
      final tx = _makeTx();
      await _pumpTile(tester, container, tx);
      // TODO: created in 28-03 — implement after ListTransactionTile exists:
      //   await tester.tap(find.byType(ListTransactionTile));
      //   await tester.pumpAndSettle();
      //   expect(find.byType(TransactionEditScreen), findsOneWidget);
      fail('implement in 28-03 after ListTransactionTile is created');
    });

    testWidgets('ROW-02: left swipe shows confirm dialog', (tester) async {
      final container = ProviderContainer.test();
      final tx = _makeTx();
      await _pumpTile(tester, container, tx);
      // TODO: created in 28-03 — implement after ListTransactionTile wraps Dismissible:
      //   await tester.drag(
      //     find.byType(ListTransactionTile),
      //     const Offset(-500, 0),
      //   );
      //   await tester.pumpAndSettle();
      //   expect(find.byType(AlertDialog), findsOneWidget);
      fail('implement in 28-03 after ListTransactionTile with Dismissible is created');
    });
  });
}
