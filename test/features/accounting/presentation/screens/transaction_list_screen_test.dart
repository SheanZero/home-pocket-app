import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/accounting/application/use_cases/get_transactions_use_case.dart';
import 'package:home_pocket/features/accounting/presentation/screens/transaction_list_screen.dart';
import 'package:home_pocket/features/accounting/presentation/screens/transaction_form_screen.dart';
import 'package:home_pocket/features/accounting/presentation/providers/transaction_providers.dart';
import 'package:home_pocket/features/accounting/presentation/providers/current_book_provider.dart';
import 'package:home_pocket/features/accounting/presentation/providers/current_device_provider.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:home_pocket/generated/app_localizations.dart';

/// Helper to wrap widget with localization support for testing
Widget wrapWithLocalizations(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja'),
        Locale('en'),
        Locale('zh'),
      ],
      home: child,
    ),
  );
}

/// Default provider overrides for TransactionFormScreen tests
final defaultTestOverrides = [
  currentBookIdProvider.overrideWith((_) async => 'test_book_id'),
  currentDeviceIdProvider.overrideWith((_) async => 'test_device_id'),
];

void main() {
  group('TransactionListScreen', () {
    testWidgets('should render app bar with title', (WidgetTester tester) async {
      // Mock get transactions use case to return empty list
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getTransactionsUseCaseProvider.overrideWithValue(
              _MockGetTransactionsUseCase(<Transaction>[]),
            ),
          ],
          child: const MaterialApp(
            home: TransactionListScreen(bookId: 'book_001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home Pocket'), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('should show empty state when no transactions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getTransactionsUseCaseProvider.overrideWithValue(
              _MockGetTransactionsUseCase(<Transaction>[]),
            ),
          ],
          child: const MaterialApp(
            home: TransactionListScreen(bookId: 'book_001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No transactions yet'), findsOneWidget);
      expect(find.text('Tap the + button to add your first transaction'),
          findsOneWidget);
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    });

    testWidgets('should show transaction list with data',
        (WidgetTester tester) async {
      final transactions = [
        Transaction.create(
          bookId: 'book_001',
          deviceId: 'device_001',
          amount: 10000,
          type: TransactionType.expense,
          categoryId: 'cat_food',
          ledgerType: LedgerType.survival,
        currentHash: 'test_hash',
          note: 'Test note',
        ),
        Transaction.create(
          bookId: 'book_001',
          deviceId: 'device_001',
          amount: 5000,
          type: TransactionType.income,
          categoryId: 'cat_salary',
          ledgerType: LedgerType.survival,
        currentHash: 'test_hash',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getTransactionsUseCaseProvider.overrideWithValue(
              _MockGetTransactionsUseCase(transactions),
            ),
          ],
          child: const MaterialApp(
            home: TransactionListScreen(bookId: 'book_001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify transactions are displayed
      expect(find.text('-¥100.00'), findsOneWidget);
      expect(find.text('+¥50.00'), findsOneWidget);
      expect(find.text('cat_food'), findsOneWidget);
      expect(find.text('cat_salary'), findsOneWidget);
    });

    testWidgets('should show FAB to add transaction',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getTransactionsUseCaseProvider.overrideWithValue(
              _MockGetTransactionsUseCase(<Transaction>[]),
            ),
          ],
          child: const MaterialApp(
            home: TransactionListScreen(bookId: 'book_001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('add_transaction_fab')), findsOneWidget);
      expect(find.text('Add Transaction'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should navigate to form when FAB tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(
          const TransactionListScreen(bookId: 'book_001'),
          overrides: [
            getTransactionsUseCaseProvider.overrideWithValue(
              _MockGetTransactionsUseCase(<Transaction>[]),
            ),
            ...defaultTestOverrides,
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tap FAB
      await tester.tap(find.byKey(const Key('add_transaction_fab')));
      await tester.pumpAndSettle();

      // Verify form screen is shown
      expect(find.text('New Transaction'), findsOneWidget);
      expect(find.byType(TransactionFormScreen), findsOneWidget);
    });
  });
}

/// Mock GetTransactionsUseCase for testing
class _MockGetTransactionsUseCase extends GetTransactionsUseCase {
  final List<Transaction> _transactions;

  _MockGetTransactionsUseCase(this._transactions)
      : super(
          transactionRepository: _MockTransactionRepository(),
          fieldEncryptionService: _MockFieldEncryptionService(),
        );

  @override
  Future<Result<List<Transaction>>> execute({
    required String bookId,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categoryIds,
    LedgerType? ledgerType,
    int limit = 100,
    int offset = 0,
  }) async {
    return Result.success(_transactions);
  }
}

/// Mock repository (unused but required for constructor)
class _MockTransactionRepository implements TransactionRepository {
  @override
  Future<int> count(String bookId) => throw UnimplementedError();

  @override
  Future<void> delete(String id) => throw UnimplementedError();

  @override
  Future<List<Transaction>> findByBook({
    required String bookId,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categoryIds,
    LedgerType? ledgerType,
    int limit = 100,
    int offset = 0,
  }) =>
      throw UnimplementedError();

  @override
  Future<Transaction?> findById(String id) => throw UnimplementedError();

  @override
  Future<Transaction?> findLatest(String bookId) => throw UnimplementedError();

  @override
  Future<String?> getLatestHash(String bookId) => throw UnimplementedError();

  @override
  Future<Transaction> insert(Transaction transaction) =>
      throw UnimplementedError();

  @override
  Future<void> softDelete(String id) => throw UnimplementedError();

  @override
  Future<Transaction> update(Transaction transaction) =>
      throw UnimplementedError();

  @override
  Future<bool> verifyHashChain(String bookId) => throw UnimplementedError();
}

/// Mock encryption service (unused but required for constructor)
class _MockFieldEncryptionService implements FieldEncryptionService {
  @override
  Future<void> clearCache() => throw UnimplementedError();

  @override
  Future<double> decryptAmount(String encrypted) => throw UnimplementedError();

  @override
  Future<String> decryptField(String encrypted) => throw UnimplementedError();

  @override
  Future<String> encryptAmount(double amount) => throw UnimplementedError();

  @override
  Future<String> encryptField(String plaintext) => throw UnimplementedError();
}
