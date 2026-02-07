import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/transaction_list_tile.dart';

void main() {
  final testTransaction = Transaction(
    id: 'tx_001',
    bookId: 'book_001',
    deviceId: 'dev_local',
    amount: 1500,
    type: TransactionType.expense,
    categoryId: 'cat_food',
    ledgerType: LedgerType.survival,
    timestamp: DateTime.now(),
    currentHash: 'hash_001',
    createdAt: DateTime.now(),
    note: 'Lunch at cafe',
  );

  group('TransactionListTile', () {
    testWidgets('displays amount with minus sign for expense', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionListTile(
              transaction: testTransaction,
              categoryName: 'Food',
            ),
          ),
        ),
      );

      expect(find.text('-1500'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Lunch at cafe'), findsOneWidget);
    });

    testWidgets('displays amount with plus sign for income', (tester) async {
      final incomeTx = Transaction(
        id: 'tx_002',
        bookId: 'book_001',
        deviceId: 'dev_local',
        amount: 50000,
        type: TransactionType.income,
        categoryId: 'cat_salary',
        ledgerType: LedgerType.survival,
        timestamp: DateTime.now(),
        currentHash: 'hash_002',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionListTile(
              transaction: incomeTx,
              categoryName: 'Salary',
            ),
          ),
        ),
      );

      expect(find.text('+50000'), findsOneWidget);
      expect(find.text('Salary'), findsOneWidget);
    });

    testWidgets('shows category ID when categoryName is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionListTile(transaction: testTransaction),
          ),
        ),
      );

      expect(find.text('cat_food'), findsOneWidget);
    });

    testWidgets('shows blue dot for survival transaction', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionListTile(
              transaction: testTransaction,
              categoryName: 'Food',
            ),
          ),
        ),
      );

      final dot = find.byKey(const Key('ledger_indicator'));
      expect(dot, findsOneWidget);

      final container = tester.widget<Container>(dot);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.blue);
    });

    testWidgets('shows purple dot for soul transaction', (tester) async {
      final soulTx = Transaction(
        id: 'tx_003',
        bookId: 'book_001',
        deviceId: 'dev_local',
        amount: 3000,
        type: TransactionType.expense,
        categoryId: 'cat_entertainment',
        ledgerType: LedgerType.soul,
        timestamp: DateTime.now(),
        currentHash: 'hash_003',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionListTile(
              transaction: soulTx,
              categoryName: 'Entertainment',
            ),
          ),
        ),
      );

      final dot = find.byKey(const Key('ledger_indicator'));
      expect(dot, findsOneWidget);

      final container = tester.widget<Container>(dot);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.purple);
    });
  });
}
