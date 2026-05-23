/// SC-4 integration test: ManualOneStepScreen save path stamps entry_source='manual'.
///
/// Uses a real AppDatabase.forTesting() + real CreateTransactionUseCase to prove
/// the schema v17 CHECK constraint accepts 'manual' through the actual UI save path.
/// Also verifies that passing entrySource: EntrySource.voice stamps 'voice' instead.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/create_transaction_use_case.dart';
import 'package:home_pocket/application/dual_ledger/classification_service.dart';
import 'package:home_pocket/application/dual_ledger/rule_engine.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/repositories/transaction_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/device_identity_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show
        categoryRepositoryProvider,
        createTransactionUseCaseProvider,
        merchantCategoryLearningServiceProvider;
import 'package:home_pocket/features/accounting/presentation/screens/manual_one_step_screen.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/smart_keyboard.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';
import 'package:home_pocket/infrastructure/security/providers.dart'
    show appDatabaseProvider;
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_localizations.dart';
import 'package:home_pocket/application/accounting/merchant_category_learning_service.dart';

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockDeviceIdentityRepository extends Mock
    implements DeviceIdentityRepository {}

class _MockFieldEncryptionService extends Mock
    implements FieldEncryptionService {}

class _MockMerchantCategoryLearningService extends Mock
    implements MerchantCategoryLearningService {}

class _FakeCreateTransactionParams extends Fake
    implements CreateTransactionParams {}

// Shared test category fixtures
final _parentCategory = Category(
  id: 'cat_food',
  name: 'Food',
  icon: 'restaurant',
  color: '#47B88A',
  level: 1,
  isSystem: true,
  sortOrder: 1,
  createdAt: DateTime.utc(2026, 1),
);

final _category = Category(
  id: 'cat_food_dining',
  name: 'Dining',
  icon: 'restaurant_menu',
  color: '#47B88A',
  parentId: 'cat_food',
  level: 2,
  isSystem: true,
  sortOrder: 1,
  createdAt: DateTime.utc(2026, 1),
);

void main() {
  late AppDatabase db;
  late TransactionDao transactionDao;
  late CreateTransactionUseCase useCase;
  late _MockCategoryRepository categoryRepository;
  late _MockDeviceIdentityRepository deviceIdentityRepository;
  late _MockFieldEncryptionService encryptionService;
  late _MockMerchantCategoryLearningService learningService;

  setUpAll(() {
    registerFallbackValue(_FakeCreateTransactionParams());
  });

  setUp(() {
    db = AppDatabase.forTesting();
    transactionDao = TransactionDao(db);
    categoryRepository = _MockCategoryRepository();
    deviceIdentityRepository = _MockDeviceIdentityRepository();
    encryptionService = _MockFieldEncryptionService();
    learningService = _MockMerchantCategoryLearningService();

    // Category repo: return the test category by id
    when(() => categoryRepository.findById(_category.id))
        .thenAnswer((_) async => _category);
    when(() => categoryRepository.findById(_parentCategory.id))
        .thenAnswer((_) async => _parentCategory);
    when(() => categoryRepository.findById(any()))
        .thenAnswer((_) async => _category);
    when(() => categoryRepository.findActive())
        .thenAnswer((_) async => [_parentCategory, _category]);
    when(() => categoryRepository.findAll())
        .thenAnswer((_) async => [_parentCategory, _category]);

    // Device identity
    when(() => deviceIdentityRepository.getDeviceId())
        .thenAnswer((_) async => 'device-local');

    // Encryption: pass-through (no real crypto in test)
    when(() => encryptionService.encryptField(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as String,
    );
    when(() => encryptionService.decryptField(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as String,
    );

    // Merchant learning: no-op (behavior tested separately)
    when(
      () => learningService.recordSelection(
        merchantRaw: any(named: 'merchantRaw'),
        selectedCategoryId: any(named: 'selectedCategoryId'),
      ),
    ).thenAnswer((_) async {});

    final transactionRepository = TransactionRepositoryImpl(
      dao: transactionDao,
      encryptionService: encryptionService,
    );
    useCase = CreateTransactionUseCase(
      transactionRepository: transactionRepository,
      categoryRepository: categoryRepository,
      deviceIdentityRepository: deviceIdentityRepository,
      hashChainService: HashChainService(),
      classificationService: ClassificationService(ruleEngine: RuleEngine()),
    );
  });

  tearDown(() async {
    await db.close();
  });

  /// Helper: pump ManualOneStepScreen with real DB-backed use case, simulate
  /// digit taps (amount = 500), and tap the Save/Record button.
  Future<void> pumpAndSave(
    WidgetTester tester, {
    EntrySource entrySource = EntrySource.manual,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      createLocalizedWidget(
        ManualOneStepScreen(
          bookId: 'book-1',
          // Seed category so _canSave is true immediately (P19-W1).
          initialCategory: _category,
          initialParentCategory: _parentCategory,
          entrySource: entrySource,
        ),
        locale: const Locale('en'),
        overrides: [
          // Provide real in-memory DB so any provider that chains into
          // appDatabaseProvider (e.g. settingsRepositoryProvider → locale)
          // doesn't throw the "not overridden" StateError.
          appDatabaseProvider.overrideWithValue(db),
          categoryRepositoryProvider.overrideWithValue(categoryRepository),
          createTransactionUseCaseProvider.overrideWithValue(useCase),
          merchantCategoryLearningServiceProvider.overrideWithValue(
            learningService,
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();

    // Tap '5', '0', '0' in the SmartKeyboard → amount = 500
    final keyboardFinder = find.byType(SmartKeyboard);
    expect(keyboardFinder, findsOneWidget);

    // Tap '5'
    final fiveFinder = find.descendant(
      of: keyboardFinder,
      matching: find.text('5'),
    );
    expect(fiveFinder, findsOneWidget,
        reason: 'SmartKeyboard digit "5" must be visible');
    await tester.tap(fiveFinder);
    await tester.pump();

    // Tap '0' twice
    final zeroFinder = find.descendant(
      of: keyboardFinder,
      matching: find.text('0'),
    );
    for (var i = 0; i < 2; i++) {
      expect(zeroFinder, findsOneWidget,
          reason: 'SmartKeyboard digit "0" must be visible');
      await tester.tap(zeroFinder);
      await tester.pump();
    }

    // Tap 'Record' (actionLabel = l10n.record = "Record" in English)
    final recordFinder = find.descendant(
      of: keyboardFinder,
      matching: find.text('Record'),
    );
    expect(recordFinder, findsOneWidget,
        reason: 'SmartKeyboard Record button must be visible');
    await tester.tap(recordFinder);
    await tester.pumpAndSettle();
  }

  testWidgets('SC-4: ManualOneStepScreen save stamps entry_source=manual in DB',
      (tester) async {
    await pumpAndSave(tester, entrySource: EntrySource.manual);

    // Query DB directly — bypass repo to confirm the schema CHECK constraint
    // actually accepted the literal 'manual'.
    final rows = await transactionDao.findByBookId('book-1');
    expect(rows.length, 1,
        reason: 'Exactly one transaction should be saved');
    expect(rows.first.entrySource, 'manual',
        reason: 'entry_source must equal the literal string "manual"');
    expect(rows.first.amount, 500,
        reason: 'Amount should be 500 (5 → 0 → 0 key taps)');
  });

  testWidgets(
      'SC-4 idempotency: entrySource=voice constructor arg stamps entry_source=voice',
      (tester) async {
    await pumpAndSave(tester, entrySource: EntrySource.voice);

    final rows = await transactionDao.findByBookId('book-1');
    expect(rows.length, 1);
    expect(rows.first.entrySource, 'voice',
        reason: 'Screen constructed with EntrySource.voice must stamp "voice"');
  });
}
