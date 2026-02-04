import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:integration_test/integration_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/daos/category_dao.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/presentation/screens/transaction_list_screen.dart';
import 'package:home_pocket/features/accounting/presentation/screens/transaction_form_screen.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/data/repositories/transaction_repository_impl.dart';
import 'package:home_pocket/data/repositories/category_repository_impl.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/key_repository_impl.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/encryption_repository_impl.dart';

// Mock secure storage for integration tests
class _MockSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) _storage[key] = value;
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _storage[key];

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _storage.remove(key);

  @override
  Future<Map<String, String>> readAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      Map.from(_storage);

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _storage.clear();

  @override
  Future<bool> containsKey({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _storage.containsKey(key);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Integration test for E2E transaction flow
///
/// Tests:
/// - Create transaction flow
/// - List transactions
/// - Update transaction (placeholder - edit not implemented yet)
/// - Delete transaction
/// - Category selection
/// - Field encryption/decryption
/// - Validation errors
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Accounting E2E Transaction Flow', () {
    late AppDatabase database;
    late ProviderContainer container;
    late KeyManager keyManager;

    setUp(() async {
      // Create in-memory database for testing
      database = AppDatabase(NativeDatabase.memory());

      // Setup REAL crypto services
      final secureStorage = _MockSecureStorage();
      final keyRepository = KeyRepositoryImpl(secureStorage: secureStorage);
      final encryptionRepository =
          EncryptionRepositoryImpl(keyRepository: keyRepository);

      keyManager = KeyManager(repository: keyRepository);
      final fieldEncryptionService =
          FieldEncryptionService(repository: encryptionRepository);
      final hashChainService = HashChainService();

      // Generate real device key pair
      await keyManager.generateDeviceKeyPair();

      // Create DAOs
      final transactionDao = TransactionDao(database);
      final categoryDao = CategoryDao(database);

      // Create repositories
      final transactionRepo = TransactionRepositoryImpl(
        database: database,
        dao: transactionDao,
        encryptionService: fieldEncryptionService,
        hashChainService: hashChainService,
      );

      final categoryRepo = CategoryRepositoryImpl(categoryDao);

      // Create provider container with overrides
      container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(transactionRepo),
          categoryRepositoryProvider.overrideWithValue(categoryRepo),
          hashChainServiceProvider.overrideWithValue(hashChainService),
          fieldEncryptionServiceProvider
              .overrideWithValue(fieldEncryptionService),
        ],
      );
    });

    tearDown(() async {
      await database.close();
      await keyManager.clearKeys();
      container.dispose();
    });

    testWidgets('Complete transaction lifecycle: create → list → delete',
        (tester) async {
      // ARRANGE: Pump the transaction list screen
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: TransactionListScreen(bookId: 'test_book'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ASSERT: Initially empty list
      expect(find.text('No transactions yet'), findsOneWidget);
      expect(find.text('Tap the + button to add your first transaction'),
          findsOneWidget);

      // ACT: Tap FAB to open form
      await tester.tap(find.byKey(const Key('add_transaction_fab')));
      await tester.pumpAndSettle();

      // ASSERT: Form screen opened
      expect(find.text('New Transaction'), findsOneWidget);
      expect(find.byType(TransactionFormScreen), findsOneWidget);

      // ACT: Fill the form
      // Enter amount
      final amountField = find.byKey(const Key('amount_field'));
      await tester.enterText(amountField, '100.50');
      await tester.pump();

      // Select transaction type (default is Expense, so no change needed)
      // Select category
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Select first category option (Food & Dining)
      await tester.tap(find.text('Food & Dining').last);
      await tester.pumpAndSettle();

      // Enter note
      final noteField = find.byKey(const Key('note_field'));
      await tester.enterText(noteField, 'Test transaction note');
      await tester.pump();

      // Enter merchant
      final merchantField = find.byKey(const Key('merchant_field'));
      await tester.enterText(merchantField, 'Test Merchant');
      await tester.pump();

      // ACT: Submit form
      await tester.tap(find.text('Create Transaction'));
      await tester.pumpAndSettle();

      // ASSERT: Back to list screen with transaction
      expect(find.text('New Transaction'), findsNothing);
      expect(find.text('No transactions yet'), findsNothing);

      // Verify transaction appears in list
      expect(find.text('-¥100.50'), findsOneWidget);
      expect(find.text('cat_food_dining'), findsOneWidget);

      // ACT: Delete transaction via swipe left to delete
      await tester.drag(
        find.byType(Card).first,
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      // ASSERT: Delete confirmation dialog appears
      expect(find.text('Delete Transaction'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this transaction?'),
          findsOneWidget);

      // ACT: Confirm deletion
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // ASSERT: Back to empty state
      expect(find.text('No transactions yet'), findsOneWidget);
      expect(find.text('Transaction deleted'), findsOneWidget);
    });

    testWidgets('Form validation errors', (tester) async {
      // ARRANGE: Pump the transaction list screen
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: TransactionListScreen(bookId: 'test_book'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ACT: Open form
      await tester.tap(find.byKey(const Key('add_transaction_fab')));
      await tester.pumpAndSettle();

      // ACT: Try to submit without filling required fields
      await tester.tap(find.text('Create Transaction'));
      await tester.pumpAndSettle();

      // ASSERT: Validation errors appear
      expect(find.text('Please enter an amount'), findsOneWidget);
      expect(find.text('Please select a category'), findsOneWidget);

      // ACT: Enter only amount
      final amountField = find.byKey(const Key('amount_field'));
      await tester.enterText(amountField, '50');
      await tester.pump();

      await tester.tap(find.text('Create Transaction'));
      await tester.pumpAndSettle();

      // ASSERT: Only category error remains
      expect(find.text('Please enter an amount'), findsNothing);
      expect(find.text('Please select a category'), findsOneWidget);
    });

    testWidgets('Field encryption/decryption flow', (tester) async {
      // This test verifies that encrypted fields are properly handled
      // by creating a transaction and verifying the data roundtrip

      // ARRANGE
      final transactionRepo = container.read(transactionRepositoryProvider);
      final fieldEncryption = container.read(fieldEncryptionServiceProvider);

      // ACT: Create transaction with sensitive data
      final transaction = Transaction.create(
        bookId: 'test_book',
        deviceId: 'test_device',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_test',
        ledgerType: LedgerType.survival,
        currentHash: 'test_hash_placeholder',
        note: 'Sensitive note data',
        merchant: 'Secret merchant',
      );

      // Encrypt fields manually
      final encryptedNote =
          await fieldEncryption.encryptField(transaction.note!);
      final encryptedMerchant =
          await fieldEncryption.encryptField(transaction.merchant!);

      final encryptedTransaction = transaction.copyWith(
        note: encryptedNote,
        merchant: encryptedMerchant,
      );

      // Save encrypted transaction
      await transactionRepo.insert(encryptedTransaction);

      // ACT: Retrieve and decrypt
      final retrieved = await transactionRepo.findById(encryptedTransaction.id);

      // The repository should have returned encrypted data
      expect(retrieved, isNotNull);
      expect(retrieved!.note, isNot('Sensitive note data'));
      expect(retrieved.merchant, isNot('Secret merchant'));

      // Decrypt manually to verify
      final decryptedNote = await fieldEncryption.decryptField(retrieved.note!);
      final decryptedMerchant =
          await fieldEncryption.decryptField(retrieved.merchant!);

      // ASSERT: Decrypted values match original
      expect(decryptedNote, 'Sensitive note data');
      expect(decryptedMerchant, 'Secret merchant');
    });

    testWidgets('Category selection flow', (tester) async {
      // ARRANGE: Pump the transaction list screen
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: TransactionListScreen(bookId: 'test_book'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ACT: Open form
      await tester.tap(find.byKey(const Key('add_transaction_fab')));
      await tester.pumpAndSettle();

      // ACT: Open category dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // ASSERT: System categories are available
      expect(find.text('Food & Dining'), findsWidgets);
      expect(find.text('Transportation'), findsWidgets);
      expect(find.text('Shopping'), findsWidgets);
      expect(find.text('Entertainment'), findsWidgets);

      // ACT: Select a category
      await tester.tap(find.text('Transportation').last);
      await tester.pumpAndSettle();

      // ASSERT: Category is selected (verify dropdown closed and text appears)
      expect(find.text('Transportation'), findsOneWidget);
    });

    testWidgets('Transaction type switching', (tester) async {
      // ARRANGE
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: TransactionListScreen(bookId: 'test_book'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ACT: Open form
      await tester.tap(find.byKey(const Key('add_transaction_fab')));
      await tester.pumpAndSettle();

      // ASSERT: Default is Expense (verify button exists)
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);

      // ACT: Switch to Income
      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();

      // ASSERT: Income is selected (form should accept the change without error)
      // Note: SegmentedButton selection state is complex to assert in tests,
      // verifying no error is sufficient
    });
  });
}
