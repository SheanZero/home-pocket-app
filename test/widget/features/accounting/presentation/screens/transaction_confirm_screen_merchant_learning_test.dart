import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/accounting/create_transaction_use_case.dart';
import 'package:home_pocket/application/accounting/merchant_category_learning_service.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show
        createTransactionUseCaseProvider,
        categoryServiceProvider,
        merchantCategoryLearningServiceProvider,
        categoryRepositoryProvider;
import 'package:home_pocket/features/accounting/presentation/screens/manual_one_step_screen.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:mocktail/mocktail.dart';

import '../../../home/helpers/test_localizations.dart';

class MockCreateTransactionUseCase extends Mock
    implements CreateTransactionUseCase {}

class MockCategoryService extends Mock implements CategoryService {}

class MockMerchantCategoryLearningService extends Mock
    implements MerchantCategoryLearningService {}

class FakeCreateTransactionParams extends Fake
    implements CreateTransactionParams {}

/// Minimal fake that returns the seeded category in findActive/findById/etc.
/// Required because ManualOneStepScreen._initializeDefaultCategory calls
/// categoryRepositoryProvider.findActive() in initState.
class _FakeCategoryRepository implements CategoryRepository {
  _FakeCategoryRepository(this._category, this._parent);

  final Category _category;
  final Category? _parent;

  @override
  Future<List<Category>> findActive() async {
    return [if (_parent != null) _parent, _category].whereType<Category>().toList();
  }

  @override
  Future<Category?> findById(String id) async {
    if (id == _category.id) return _category;
    if (_parent != null && id == _parent.id) return _parent;
    return null;
  }

  @override
  Future<List<Category>> findAll() async => findActive();

  @override
  Future<List<Category>> findByLevel(int level) async =>
      (await findActive()).where((c) => c.level == level).toList();

  @override
  Future<List<Category>> findByParent(String parentId) async =>
      (await findActive())
          .where((c) => c.parentId == parentId)
          .toList();

  @override
  Future<void> insert(Category category) async {}

  @override
  Future<void> insertBatch(List<Category> categories) async {}

  @override
  Future<void> update({
    required String id,
    String? name,
    String? icon,
    String? color,
    bool? isArchived,
    int? sortOrder,
  }) async {}

  @override
  Future<void> deleteAll() async {}

  @override
  Future<void> updateSortOrders(Map<String, int> idToSortOrder) async {}
}

void main() {
  late MockCreateTransactionUseCase mockCreateUseCase;
  late MockCategoryService mockCategoryService;
  late MockMerchantCategoryLearningService mockLearningService;

  final parentCategory = Category(
    id: 'cat_food',
    name: 'Food',
    icon: 'restaurant',
    color: '#FF5722',
    level: 1,
    isSystem: true,
    sortOrder: 1,
    createdAt: DateTime(2026, 1, 1),
  );

  final category = Category(
    id: 'cat_food_groceries',
    name: 'Groceries',
    icon: 'shopping_basket',
    color: '#FF5722',
    parentId: 'cat_food',
    level: 2,
    isSystem: true,
    sortOrder: 1,
    createdAt: DateTime(2026, 1, 1),
  );

  final successTransaction = Transaction(
    id: 'tx_001',
    bookId: 'book_001',
    deviceId: 'device_001',
    amount: 1200,
    type: TransactionType.expense,
    categoryId: 'cat_food_groceries',
    ledgerType: LedgerType.daily,
    timestamp: DateTime(2026, 2, 22),
    currentHash: 'hash_001',
    createdAt: DateTime(2026, 2, 22),
    joyFullness: 5,
  );

  setUpAll(() {
    registerFallbackValue(FakeCreateTransactionParams());
  });

  setUp(() {
    mockCreateUseCase = MockCreateTransactionUseCase();
    mockCategoryService = MockCategoryService();
    mockLearningService = MockMerchantCategoryLearningService();

    when(
      () => mockCategoryService.resolveLedgerType(any()),
    ).thenAnswer((_) async => LedgerType.daily);

    when(
      () => mockLearningService.recordSelection(
        merchantRaw: any(named: 'merchantRaw'),
        selectedCategoryId: any(named: 'selectedCategoryId'),
      ),
    ).thenAnswer((_) async {});
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          createTransactionUseCaseProvider.overrideWithValue(mockCreateUseCase),
          categoryServiceProvider.overrideWithValue(mockCategoryService),
          merchantCategoryLearningServiceProvider.overrideWithValue(
            mockLearningService,
          ),
          categoryRepositoryProvider.overrideWithValue(
            _FakeCategoryRepository(category, parentCategory),
          ),
        ],
        child: testLocalizedApp(
          locale: const Locale('en'),
          child: Theme(
            data: ThemeData(splashFactory: NoSplash.splashFactory),
            child: ManualOneStepScreen(
              bookId: 'book_001',
              initialAmount: 1200,
              initialCategory: category,
              initialParentCategory: parentCategory,
              initialDate: DateTime(2026, 2, 22),
              entrySource: EntrySource.manual,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  group('ManualOneStepScreen merchant learning hook (via TransactionDetailsForm)', () {
    testWidgets('shows emoji picker for soul ledger transactions', (
      tester,
    ) async {
      when(
        () => mockCategoryService.resolveLedgerType(any()),
      ).thenAnswer((_) async => LedgerType.joy);

      await pumpScreen(tester);

      expect(find.byType(SatisfactionEmojiPicker), findsOneWidget);
    });

    testWidgets('calls recordSelection on successful save with merchant', (
      tester,
    ) async {
      when(
        () => mockCreateUseCase.execute(any()),
      ).thenAnswer((_) async => Result.success(successTransaction));

      await pumpScreen(tester);

      await tester.enterText(find.byType(TextField).first, '  セブン  ');
      await tester.tap(find.text('Record'));
      await tester.pumpAndSettle();

      verify(
        () => mockLearningService.recordSelection(
          merchantRaw: 'セブン',
          selectedCategoryId: 'cat_food_groceries',
        ),
      ).called(1);
    });

    testWidgets('does not call recordSelection when merchant is blank', (
      tester,
    ) async {
      when(
        () => mockCreateUseCase.execute(any()),
      ).thenAnswer((_) async => Result.success(successTransaction));

      await pumpScreen(tester);

      await tester.enterText(find.byType(TextField).first, '   ');
      await tester.tap(find.text('Record'));
      await tester.pumpAndSettle();

      verifyNever(
        () => mockLearningService.recordSelection(
          merchantRaw: any(named: 'merchantRaw'),
          selectedCategoryId: any(named: 'selectedCategoryId'),
        ),
      );
    });

    testWidgets('does not call recordSelection when save fails', (
      tester,
    ) async {
      when(
        () => mockCreateUseCase.execute(any()),
      ).thenAnswer((_) async => Result.error('save failed'));

      await pumpScreen(tester);

      await tester.enterText(find.byType(TextField).first, 'セブン');
      await tester.tap(find.text('Record'));
      await tester.pumpAndSettle();

      verifyNever(
        () => mockLearningService.recordSelection(
          merchantRaw: any(named: 'merchantRaw'),
          selectedCategoryId: any(named: 'selectedCategoryId'),
        ),
      );
    });
  });
}
