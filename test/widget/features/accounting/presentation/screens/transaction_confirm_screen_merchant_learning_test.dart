import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/accounting/create_transaction_use_case.dart';
import 'package:home_pocket/application/accounting/merchant_category_learning_service.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show createTransactionUseCaseProvider, categoryServiceProvider, merchantCategoryLearningServiceProvider;
import 'package:home_pocket/features/accounting/presentation/screens/transaction_confirm_screen.dart';
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

void main() {
  late MockCreateTransactionUseCase mockCreateUseCase;
  late MockCategoryService mockCategoryService;
  late MockMerchantCategoryLearningService mockLearningService;

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
    ledgerType: LedgerType.survival,
    timestamp: DateTime(2026, 2, 22),
    currentHash: 'hash_001',
    createdAt: DateTime(2026, 2, 22),
    soulSatisfaction: 5,
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
    ).thenAnswer((_) async => LedgerType.survival);

    when(
      () => mockLearningService.recordSelection(
        merchantRaw: any(named: 'merchantRaw'),
        selectedCategoryId: any(named: 'selectedCategoryId'),
      ),
    ).thenAnswer((_) async {});
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          createTransactionUseCaseProvider.overrideWithValue(mockCreateUseCase),
          categoryServiceProvider.overrideWithValue(mockCategoryService),
          merchantCategoryLearningServiceProvider.overrideWithValue(
            mockLearningService,
          ),
        ],
        child: testLocalizedApp(
          locale: const Locale('en'),
          child: Theme(
            data: ThemeData(splashFactory: NoSplash.splashFactory),
            child: Scaffold(
              body: TransactionConfirmScreen(
                bookId: 'book_001',
                amount: 1200,
                category: category,
                parentCategory: null,
                date: DateTime(2026, 2, 22),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  group('TransactionConfirmScreen merchant learning hook', () {
    testWidgets('shows emoji picker for soul ledger transactions', (
      tester,
    ) async {
      when(
        () => mockCategoryService.resolveLedgerType(any()),
      ).thenAnswer((_) async => LedgerType.soul);

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
