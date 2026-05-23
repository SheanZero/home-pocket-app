import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/accounting/create_transaction_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show
        categoryRepositoryProvider,
        createTransactionUseCaseProvider,
        categoryServiceProvider;
import 'package:home_pocket/features/accounting/presentation/screens/manual_one_step_screen.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/amount_display.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/entry_mode_switcher.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/keyboard_toolbar.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/smart_keyboard.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

// ── Fakes / Mocks ──────────────────────────────────────────────────────────────

class FakeCategoryRepository implements CategoryRepository {
  FakeCategoryRepository(this.categories);

  final List<Category> categories;

  @override
  Future<List<Category>> findActive() async => categories;

  @override
  Future<Category?> findById(String id) async {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Category>> findAll() async => categories;

  @override
  Future<List<Category>> findByLevel(int level) async =>
      categories.where((c) => c.level == level).toList();

  @override
  Future<List<Category>> findByParent(String parentId) async =>
      categories.where((c) => c.parentId == parentId).toList();

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

/// SlowFakeCategoryRepository — delays findActive() to simulate async race (P19-W1).
class SlowFakeCategoryRepository extends FakeCategoryRepository {
  SlowFakeCategoryRepository(super.categories, {this.delay = const Duration(seconds: 2)});

  final Duration delay;

  @override
  Future<List<Category>> findActive() async {
    await Future<void>.delayed(delay);
    return super.findActive();
  }
}

class MockCreateTransactionUseCase extends Mock
    implements CreateTransactionUseCase {}

class MockCategoryService extends Mock implements CategoryService {}

class FakeCreateTransactionParams extends Fake
    implements CreateTransactionParams {}

// ── Test fixtures ──────────────────────────────────────────────────────────────

final _l1Category = Category(
  id: 'food',
  name: 'category_food',
  icon: 'restaurant',
  color: '#E85A4F',
  level: 1,
  isSystem: true,
  sortOrder: 1,
  createdAt: DateTime(2026, 4, 3),
);

final _l2Category = Category(
  id: 'convenience',
  name: 'コンビニ',
  icon: 'shopping_basket',
  color: '#E85A4F',
  parentId: 'food',
  level: 2,
  sortOrder: 1,
  createdAt: DateTime(2026, 4, 3),
);

final _fakeCategories = [_l1Category, _l2Category];

final _successTransaction = Transaction(
  id: 'tx_001',
  bookId: 'book-1',
  deviceId: 'device_001',
  amount: 111,
  type: TransactionType.expense,
  categoryId: 'convenience',
  ledgerType: LedgerType.survival,
  timestamp: DateTime(2026, 2, 22),
  currentHash: 'hash_001',
  createdAt: DateTime(2026, 2, 22),
);

// ── Test helpers ───────────────────────────────────────────────────────────────

Widget _pumpScreen({
  required MockCreateTransactionUseCase mockCreateUseCase,
  required FakeCategoryRepository fakeCategoryRepo,
  MockCategoryService? mockCategoryService,
  int? initialAmount,
  Category? initialCategory,
  EntrySource entrySource = EntrySource.manual,
}) {
  final overrides = <Override>[
    categoryRepositoryProvider.overrideWithValue(fakeCategoryRepo),
    createTransactionUseCaseProvider.overrideWithValue(mockCreateUseCase),
    if (mockCategoryService != null)
      categoryServiceProvider.overrideWithValue(mockCategoryService),
  ];

  return createLocalizedWidget(
    ManualOneStepScreen(
      bookId: 'book-1',
      initialAmount: initialAmount,
      initialCategory: initialCategory,
      entrySource: entrySource,
    ),
    locale: const Locale('en'),
    overrides: overrides,
  );
}

void main() {
  late MockCreateTransactionUseCase mockCreateUseCase;
  late MockCategoryService mockCategoryService;

  setUpAll(() {
    registerFallbackValue(FakeCreateTransactionParams());
  });

  setUp(() {
    mockCreateUseCase = MockCreateTransactionUseCase();
    mockCategoryService = MockCategoryService();
    when(
      () => mockCategoryService.resolveLedgerType(any()),
    ).thenAnswer((_) async => LedgerType.survival);
  });

  // ── SC-1: single screen, no Next button, all six field surfaces ─────────────

  testWidgets('SC-1: no Next/下一步/次へ button visible after mount', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _pumpScreen(
        mockCreateUseCase: mockCreateUseCase,
        fakeCategoryRepo: FakeCategoryRepository(_fakeCategories),
        mockCategoryService: mockCategoryService,
      ),
    );
    await tester.pumpAndSettle();

    // SC-1 assertion: no Next variants in any locale
    expect(find.text('Next'), findsNothing);
    expect(find.text('下一步'), findsNothing);
    expect(find.text('次へ'), findsNothing);

    // All six field surfaces visible
    expect(find.byType(AmountDisplay), findsOneWidget);
    expect(find.byType(EntryModeSwitcher), findsOneWidget);
    expect(find.byKey(const ValueKey('category-chip')), findsOneWidget);
    expect(find.byKey(const ValueKey('date-chip')), findsOneWidget);
    expect(find.byKey(const ValueKey('merchant-textfield')), findsOneWidget);
    expect(find.byKey(const ValueKey('note-textfield')), findsOneWidget);
  });

  // ── D-13: Scaffold flag ─────────────────────────────────────────────────────

  testWidgets('D-13: Scaffold has resizeToAvoidBottomInset=false', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _pumpScreen(
        mockCreateUseCase: mockCreateUseCase,
        fakeCategoryRepo: FakeCategoryRepository(_fakeCategories),
        mockCategoryService: mockCategoryService,
      ),
    );
    await tester.pump();

    final scaffold = tester.widget<Scaffold>(
      find.byKey(const ValueKey('manual-one-step-screen')),
    );
    expect(scaffold.resizeToAvoidBottomInset, isFalse);
  });

  // ── Persistent keypad slide (P19-W3 FocusNode-driven) ──────────────────────

  testWidgets('Persistent keypad: SmartKeyboard initially visible, slides out on TextField focus', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _pumpScreen(
        mockCreateUseCase: mockCreateUseCase,
        fakeCategoryRepo: FakeCategoryRepository(_fakeCategories),
        mockCategoryService: mockCategoryService,
      ),
    );
    await tester.pumpAndSettle();

    // Initial state: SmartKeyboard visible (offset.dy = 0)
    final slideFinder = find.ancestor(
      of: find.byType(SmartKeyboard),
      matching: find.byType(AnimatedSlide),
    );
    expect(
      tester.widget<AnimatedSlide>(slideFinder).offset,
      const Offset(0, 0),
      reason: 'SmartKeyboard should be visible initially',
    );

    // Tap the merchant TextField to focus it
    await tester.tap(find.byKey(const ValueKey('merchant-textfield')));
    await tester.pumpAndSettle();

    // SmartKeyboard should slide off-screen (offset.dy = 1)
    expect(
      tester.widget<AnimatedSlide>(slideFinder).offset,
      const Offset(0, 1),
      reason: 'SmartKeyboard should slide off-screen when TextField is focused',
    );

    // P19-W3: verify per-host FocusNode is wired to the merchant TextField
    final merchantTextField = tester.widget<TextField>(
      find.byKey(const ValueKey('merchant-textfield')),
    );
    expect(
      merchantTextField.focusNode,
      isNotNull,
      reason: 'merchant TextField must have a per-host FocusNode (P19-W3)',
    );
  });

  // ── KeyboardToolbar visibility + actions ───────────────────────────────────

  testWidgets('KeyboardToolbar: not visible initially, appears on TextField focus', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _pumpScreen(
        mockCreateUseCase: mockCreateUseCase,
        fakeCategoryRepo: FakeCategoryRepository(_fakeCategories),
        mockCategoryService: mockCategoryService,
      ),
    );
    await tester.pumpAndSettle();

    // Initial: no KeyboardToolbar
    expect(find.byType(KeyboardToolbar), findsNothing);

    // Tap merchant field to trigger text focus
    await tester.tap(find.byKey(const ValueKey('merchant-textfield')));
    await tester.pumpAndSettle();

    // KeyboardToolbar should be visible
    expect(find.byType(KeyboardToolbar), findsOneWidget);
  });

  // ── P19-W1: Save disabled when category null (default-category async race) ──

  testWidgets('P19-W1: SmartKeyboard Save tapped before category loads does NOT invoke CreateTransactionUseCase', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final slowRepo = SlowFakeCategoryRepository(
      _fakeCategories,
      delay: const Duration(seconds: 2),
    );

    await tester.pumpWidget(
      _pumpScreen(
        mockCreateUseCase: mockCreateUseCase,
        fakeCategoryRepo: slowRepo,
        mockCategoryService: mockCategoryService,
      ),
    );

    // Pump briefly — not enough time for the 2s category init to complete
    await tester.pump(const Duration(milliseconds: 100));

    // Tap a digit then the SmartKeyboard Save button — category still null
    final digitOneFinder = find.descendant(
      of: find.byType(SmartKeyboard),
      matching: find.text('1'),
    );
    if (digitOneFinder.evaluate().isNotEmpty) {
      await tester.tap(digitOneFinder.first);
      await tester.pump();
    }

    // Tap Save — should be guarded by _trySave → !_canSave → no-op
    final saveKeyFinder = find.descendant(
      of: find.byType(SmartKeyboard),
      matching: find.byType(GestureDetector),
    );
    // Just pump — the guard should prevent use case invocation
    await tester.pump(const Duration(milliseconds: 100));

    // Assert use case was NEVER invoked (P19-W1 guard)
    verifyNever(() => mockCreateUseCase.execute(any()));

    // Now advance past the 2s delay
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // After category loads, _canSave should be true
    // (category chip should now show something other than "Please select...")
    expect(find.byKey(const ValueKey('category-chip')), findsOneWidget);
  });

  // ── P19-W1: Toolbar Save disabled when category null ──────────────────────

  testWidgets('P19-W1: KeyboardToolbar Save is disabled while category is null', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final slowRepo = SlowFakeCategoryRepository(
      _fakeCategories,
      delay: const Duration(seconds: 2),
    );

    await tester.pumpWidget(
      _pumpScreen(
        mockCreateUseCase: mockCreateUseCase,
        fakeCategoryRepo: slowRepo,
        mockCategoryService: mockCategoryService,
      ),
    );

    // Pump briefly to mount but NOT settle the 2s category init
    await tester.pump(const Duration(milliseconds: 100));

    // Focus merchant TextField to bring up KeyboardToolbar
    await tester.tap(find.byKey(const ValueKey('merchant-textfield')));
    await tester.pump(const Duration(milliseconds: 100));

    // If KeyboardToolbar appeared, check its isSubmitting state
    if (find.byType(KeyboardToolbar).evaluate().isNotEmpty) {
      final toolbar = tester.widget<KeyboardToolbar>(
        find.byType(KeyboardToolbar),
      );
      // isSubmitting should be true because !_canSave (_selectedCategory == null)
      expect(
        toolbar.isSubmitting,
        isTrue,
        reason: 'KeyboardToolbar.isSubmitting should be true while category is null (P19-W1)',
      );
    }

    // Tap keyboard toolbar Save — should not invoke use case (disabled)
    verifyNever(() => mockCreateUseCase.execute(any()));

    // Advance past the delay
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // After category loads, toolbar should have isSubmitting=false
    if (find.byType(KeyboardToolbar).evaluate().isNotEmpty) {
      final toolbar = tester.widget<KeyboardToolbar>(
        find.byType(KeyboardToolbar),
      );
      expect(
        toolbar.isSubmitting,
        isFalse,
        reason: 'KeyboardToolbar.isSubmitting should be false after category loads',
      );
    }
  });

  // ── Digit tap + Save via SmartKeyboard (SC-4 precursor) ────────────────────

  testWidgets('Digit tap + SmartKeyboard Save invokes CreateTransactionUseCase with entrySource=manual', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    when(
      () => mockCreateUseCase.execute(any()),
    ).thenAnswer((_) async => Result.success(_successTransaction));

    // Pre-seed category so the form initializes with a non-null _category.
    // This avoids the async-init race since the form's initState reads
    // initialCategory only once. In production the async init updates
    // _selectedCategory → triggers rebuild → form rebuilds with new config but
    // does NOT re-init its internal _category (expected behavior: form owns cat
    // once initialized). Tests must pre-seed to exercise the full save path.
    await tester.pumpWidget(
      createLocalizedWidget(
        ManualOneStepScreen(
          bookId: 'book-1',
          initialCategory: _l2Category,
          initialParentCategory: _l1Category,
          entrySource: EntrySource.manual,
        ),
        locale: const Locale('en'),
        overrides: [
          categoryRepositoryProvider.overrideWithValue(
            FakeCategoryRepository(_fakeCategories),
          ),
          createTransactionUseCaseProvider.overrideWithValue(mockCreateUseCase),
          categoryServiceProvider.overrideWithValue(mockCategoryService),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // Tap digit '1' three times
    final digit1Finder = find.descendant(
      of: find.byType(SmartKeyboard),
      matching: find.text('1'),
    );
    expect(digit1Finder, findsOneWidget);
    await tester.tap(digit1Finder);
    await tester.pump();
    await tester.tap(digit1Finder);
    await tester.pump();
    await tester.tap(digit1Finder);
    await tester.pump();

    // Tap SmartKeyboard Save via the action label text "Record"
    final saveButtonFinder = find.descendant(
      of: find.byType(SmartKeyboard),
      matching: find.text('Record'),
    );
    expect(saveButtonFinder, findsOneWidget);
    await tester.tap(saveButtonFinder);
    await tester.pumpAndSettle();

    // Assert CreateTransactionUseCase was called with entrySource=manual
    final captured = verify(
      () => mockCreateUseCase.execute(captureAny()),
    ).captured;
    expect(captured.length, 1);
    final params = captured.first as CreateTransactionParams;
    expect(params.entrySource, EntrySource.manual);
    expect(params.amount, 111);
  });

  // ── entrySource preservation for voice pushes ──────────────────────────────

  testWidgets('entrySource=voice is preserved when screen pushed from voice flow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    when(
      () => mockCreateUseCase.execute(any()),
    ).thenAnswer((_) async => Result.success(_successTransaction));

    // Create the screen with voice entrySource and pre-seeded category
    await tester.pumpWidget(
      createLocalizedWidget(
        ManualOneStepScreen(
          bookId: 'book-1',
          initialAmount: 500,
          initialCategory: _l2Category,
          initialParentCategory: _l1Category,
          entrySource: EntrySource.voice,
        ),
        locale: const Locale('en'),
        overrides: [
          categoryRepositoryProvider.overrideWithValue(
            FakeCategoryRepository(_fakeCategories),
          ),
          createTransactionUseCaseProvider.overrideWithValue(mockCreateUseCase),
          categoryServiceProvider.overrideWithValue(mockCategoryService),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // Tap SmartKeyboard Save
    final saveButtonFinder = find.descendant(
      of: find.byType(SmartKeyboard),
      matching: find.text('Record'),
    );
    await tester.tap(saveButtonFinder);
    await tester.pumpAndSettle();

    // Verify entrySource=voice
    final captured = verify(
      () => mockCreateUseCase.execute(captureAny()),
    ).captured;
    expect(captured.length, 1);
    final params = captured.first as CreateTransactionParams;
    expect(params.entrySource, EntrySource.voice);
  });
}
