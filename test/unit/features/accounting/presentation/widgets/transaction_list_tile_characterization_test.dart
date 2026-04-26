// Characterization test for TransactionListTile.
// Verifies observable widget behavior before Plan 04-02 routes
// DateFormatter through formatterServiceProvider.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/transaction_list_tile.dart';
import 'package:home_pocket/generated/app_localizations.dart';

// No providers needed — TransactionListTile is a pure StatelessWidget
// that takes Transaction as a parameter (no provider deps).

Widget _buildApp(Widget child) {
  return MaterialApp(
    locale: const Locale('ja'),
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  final testTx = Transaction(
    id: 'tx-001',
    bookId: 'book-001',
    deviceId: 'dev-01',
    amount: 1500,
    type: TransactionType.expense,
    categoryId: 'cat-food',
    ledgerType: LedgerType.survival,
    timestamp: DateTime(2026, 3, 15, 12, 30),
    currentHash: 'hash-001',
    createdAt: DateTime(2026, 3, 15),
  );

  group('TransactionListTile characterization tests (pre-refactor behavior)', () {
    testWidgets('renders without crashing with a valid transaction', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(TransactionListTile(transaction: testTx, categoryName: 'Food')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('shows category name when provided', (tester) async {
      await tester.pumpWidget(
        _buildApp(TransactionListTile(transaction: testTx, categoryName: 'Food')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('shows minus sign for expense amounts', (tester) async {
      await tester.pumpWidget(
        _buildApp(TransactionListTile(transaction: testTx, categoryName: 'Food')),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('-'), findsWidgets);
    });

    testWidgets('ledger indicator dot exists for survival transaction', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(TransactionListTile(transaction: testTx, categoryName: 'Food')),
      );
      await tester.pumpAndSettle();
      // blue dot for survival
      expect(find.byKey(const Key('ledger_indicator')), findsOneWidget);
    });

    testWidgets('DateFormatter call site present — formats time correctly', (
      tester,
    ) async {
      // Transaction from yesterday — DateFormatter.formatDate is called for dates != today
      final oldTx = Transaction(
        id: 'tx-002',
        bookId: 'book-001',
        deviceId: 'dev-01',
        amount: 2000,
        type: TransactionType.expense,
        categoryId: 'cat-food',
        ledgerType: LedgerType.soul,
        timestamp: DateTime(2020, 1, 1),
        currentHash: 'hash-002',
        createdAt: DateTime(2020, 1, 1),
      );
      await tester.pumpWidget(
        _buildApp(
          TransactionListTile(transaction: oldTx, categoryName: 'Entertainment'),
        ),
      );
      await tester.pumpAndSettle();
      // Japanese date format: yyyy/MM/dd — DateFormatter.formatDate is called here
      expect(find.textContaining('/'), findsOneWidget);
    });
  });
}
