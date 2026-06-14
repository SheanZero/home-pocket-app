import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
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
import 'package:home_pocket/generated/app_localizations.dart';
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
  ledgerType: LedgerType.daily,
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
    ).thenAnswer((_) async => LedgerType.daily);
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
    expect(digitOneFinder, findsOneWidget,
        reason: 'SmartKeyboard digit "1" must be visible');
    await tester.tap(digitOneFinder);
    await tester.pump();

    // Just pump — the guard should prevent use case invocation
    await tester.pump(const Duration(milliseconds: 100));

    // Assert use case was NEVER invoked (P19-W1 guard)
    verifyNever(() => mockCreateUseCase.execute(any()));

    // Now advance past the 2s delay
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // After category loads, _canSave should be true and the chip must show the
    // resolved default (food → コンビニ), not the "Please select" placeholder.
    final chip = find.byKey(const ValueKey('category-chip'));
    expect(chip, findsOneWidget);
    expect(
      find.descendant(of: chip, matching: find.textContaining('コンビニ')),
      findsOneWidget,
      reason: 'default category must be visible in the chip after async load',
    );
  });

  // ── 260603-ti2: default category must auto-fill the form on initial load ──
  // Regression: the embedded TransactionDetailsForm reads `initialCategory`
  // only in its own initState, which runs (with null) BEFORE the host's async
  // default-category load resolves. A host setState/rebuild alone never reaches
  // the form (its GlobalKey state persists), so the form stays on "Please
  // select a category" forever. The fix pushes the resolved default into the
  // form via its imperative updateCategory() API — mirroring the already-
  // working _resetForContinuousEntry path.
  testWidgets(
    '260603-ti2: default category auto-fills into the form after async init',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _pumpScreen(
          mockCreateUseCase: mockCreateUseCase,
          fakeCategoryRepo: FakeCategoryRepository(_fakeCategories),
          mockCategoryService: mockCategoryService,
          // No initialCategory — exercise the async default-resolution path.
        ),
      );
      await tester.pumpAndSettle();

      final chip = find.byKey(const ValueKey('category-chip'));
      expect(chip, findsOneWidget);

      // The chip must show the resolved default (food → コンビニ), NOT the
      // "Please select a category" placeholder.
      expect(
        find.descendant(of: chip, matching: find.textContaining('コンビニ')),
        findsOneWidget,
        reason:
            'default L2 category should auto-fill the form on initial load, '
            'not stay on the please-select placeholder',
      );
      expect(
        find.descendant(
          of: chip,
          matching: find.textContaining('Please select'),
        ),
        findsNothing,
        reason: 'placeholder must be gone once the default resolves',
      );
    },
  );

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

  // ── 260526-r8y Item 3: regression — toolbar 记录 must save when TextField focused ──
  //
  // Bug: TextField's `onTapOutside: (_) => FocusScope.of(context).unfocus()`
  // fires on pointer-down before the floating KeyboardToolbar's InkWell.onTap
  // can resolve on pointer-up. The unfocus causes `_handleFocusChange` to flip
  // `_isTextFieldFocused = false`, which unmounts the toolbar via
  // `if (_isTextFieldFocused) Positioned(...)`. The pending pointer-up reaches
  // a disposed widget and `onSave` is never invoked.
  //
  // Fix (Task 2): wrap KeyboardToolbar in `TapRegion(groupId: …)` and set
  // `TextField.groupId` to the same constant on the merchant + note TextFields.
  // This test MUST FAIL on current main (proves bug) and PASS after Task 2.
  testWidgets(
    '260526-r8y Item 3: KeyboardToolbar 记录 button saves transaction when merchant TextField is focused',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(
        () => mockCreateUseCase.execute(any()),
      ).thenAnswer((_) async => Result.success(_successTransaction));

      // D-08 popUntil fix mirrors voice_input_screen_test._TwoRouteHost: push
      // ManualOneStepScreen on top of a dummy home so Navigator.popUntil
      // ((r) => r.isFirst) actually pops the screen.
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: ProviderScope(
            overrides: [
              categoryRepositoryProvider.overrideWithValue(
                FakeCategoryRepository(_fakeCategories),
              ),
              createTransactionUseCaseProvider.overrideWithValue(
                mockCreateUseCase,
              ),
              categoryServiceProvider.overrideWithValue(mockCategoryService),
            ],
            child: Navigator(
              onGenerateRoute: (settings) {
                if (settings.name == '/') {
                  return MaterialPageRoute<void>(
                    builder: (ctx) => Scaffold(
                      body: Builder(
                        builder: (ctx) {
                          // Push the screen on top of the home route after the
                          // first frame so the toolbar/save flow can pop back.
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            Navigator.of(ctx).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => ManualOneStepScreen(
                                  bookId: 'book-1',
                                  initialCategory: _l2Category,
                                  initialParentCategory: _l1Category,
                                  entrySource: EntrySource.manual,
                                ),
                              ),
                            );
                          });
                          return const Center(child: Text('home'));
                        },
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap digit '1' on SmartKeyboard to seed an amount.
      final digit1Finder = find.descendant(
        of: find.byType(SmartKeyboard),
        matching: find.text('1'),
      );
      expect(digit1Finder, findsOneWidget);
      await tester.tap(digit1Finder);
      await tester.pumpAndSettle();

      // Focus the merchant TextField → KeyboardToolbar mounts.
      await tester.tap(find.byKey(const ValueKey('merchant-textfield')));
      await tester.pumpAndSettle();

      expect(
        find.byType(KeyboardToolbar),
        findsOneWidget,
        reason: 'KeyboardToolbar must be visible while merchant field is focused',
      );

      // Tap the toolbar's 记录 button (en locale → "Record").
      final toolbarSaveFinder = find.descendant(
        of: find.byType(KeyboardToolbar),
        matching: find.text('Record'),
      );
      expect(
        toolbarSaveFinder,
        findsOneWidget,
        reason: 'toolbar must render the Record label',
      );

      // Use an explicit down + up gesture (not tester.tap which fast-paths
      // both events) so the production race between TextField.onTapOutside
      // (fires on pointer-down) and the InkWell's onTap (resolves on
      // pointer-up after the toolbar may have unmounted) is exercised
      // faithfully. With pumpAndSettle between down and up, the
      // _handleFocusChange → setState → toolbar unmount happens between
      // the events on the unfixed build.
      final gesture = await tester.startGesture(
        tester.getCenter(toolbarSaveFinder),
      );
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();

      // CORE BUG ASSERTION: save use case MUST be invoked exactly once.
      // Pre-fix: TextField.onTapOutside fires on pointer-down, unfocuses the
      // field, unmounts the toolbar, and the InkWell never receives the tap-up
      // — so verify(...).called(1) sees zero calls.
      verify(() => mockCreateUseCase.execute(any())).called(1);

      // 260614-iww: single-tap (continuousMode:false, the default) save now pops
      // back to the previous page with a warm entrySavedDone toast. (The legacy
      // 260603-nr1 always-keep-going behavior is now gated behind continuousMode,
      // which only the FAB long-press path sets.)
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('manual-one-step-screen')),
        findsNothing,
        reason:
            'single-tap save (continuousMode:false) must pop back to the previous page (260614-iww)',
      );
      expect(
        find.text('home'),
        findsOneWidget,
        reason: 'after popping, the home route is visible again',
      );
    },
  );

  // ── 260614-iww: continuous-mode (FAB long-press) save stays open ──────────

  testWidgets(
    '260614-iww: continuousMode save stays open, resets form, shows exit affordance',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(
        () => mockCreateUseCase.execute(any()),
      ).thenAnswer((_) async => Result.success(_successTransaction));

      await tester.pumpWidget(
        createLocalizedWidget(
          ManualOneStepScreen(
            bookId: 'book-1',
            initialCategory: _l2Category,
            initialParentCategory: _l1Category,
            entrySource: EntrySource.manual,
            continuousMode: true,
          ),
          locale: const Locale('en'),
          overrides: [
            categoryRepositoryProvider.overrideWithValue(
              FakeCategoryRepository(_fakeCategories),
            ),
            createTransactionUseCaseProvider.overrideWithValue(
              mockCreateUseCase,
            ),
            categoryServiceProvider.overrideWithValue(mockCategoryService),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Continuous-mode exit affordance + hint are surfaced on the page.
      expect(
        find.text('Exit'),
        findsOneWidget,
        reason: 'continuous mode surfaces a discoverable exit control',
      );
      expect(
        find.text('Tap exit anytime to finish'),
        findsOneWidget,
        reason: 'continuous mode surfaces the exit hint',
      );

      // Seed an amount and save.
      final digit1Finder = find.descendant(
        of: find.byType(SmartKeyboard),
        matching: find.text('1'),
      );
      await tester.tap(digit1Finder);
      await tester.pump();
      final saveButtonFinder = find.descendant(
        of: find.byType(SmartKeyboard),
        matching: find.text('Record'),
      );
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();

      verify(() => mockCreateUseCase.execute(any())).called(1);

      // Continuous mode: the screen MUST stay open after save (no pop).
      expect(
        find.byKey(const ValueKey('manual-one-step-screen')),
        findsOneWidget,
        reason: 'continuousMode save keeps the page open for the next entry',
      );
      // Form resets in place — the amount display clears back to empty.
      expect(
        find.text('Saved — keep going!'),
        findsOneWidget,
        reason: 'continuous mode shows the warm keep-going toast',
      );
    },
  );

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

  // ── CR-01: decimal-point parsing regression ────────────────────────────────
  //
  // Phase 42 (D-06): the default currency is JPY (0 decimals), so the dot key is
  // now GATED OFF — `onDot:null` → a disabled blank tile, no '.' glyph (CURR-04).
  // The original CR-01 concern (typing "123." must not collapse to 0) is now
  // structurally impossible on the JPY path because the dot can't be typed at
  // all. The regression intent — Record submits amount=123 — is preserved; the
  // dot-tap step is replaced with an assertion that the dot is absent/gated.

  testWidgets(
      'CR-01: typing 1,2,3 (dot gated for JPY) then Record submits amount=123',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    when(
      () => mockCreateUseCase.execute(any()),
    ).thenAnswer((_) async => Result.success(_successTransaction));

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

    final keyboard = find.byType(SmartKeyboard);
    expect(keyboard, findsOneWidget);

    // Tap '1', '2', '3'
    for (final digit in ['1', '2', '3']) {
      final finder = find.descendant(
        of: keyboard,
        matching: find.text(digit),
      );
      expect(finder, findsOneWidget);
      await tester.tap(finder);
      await tester.pump();
    }

    // Phase 42 D-06: JPY gates the dot key off — no '.' glyph is rendered, and
    // the disabled tile is present instead. Typing a dot is impossible on the
    // JPY path, so the old int.tryParse("123.") = null → 0 hazard cannot occur.
    expect(
      find.descendant(of: keyboard, matching: find.text('.')),
      findsNothing,
      reason: 'JPY (0 decimals) gates the dot key off (D-06 / CURR-04)',
    );
    expect(
      find.byKey(const ValueKey('smart_keyboard_dot_disabled')),
      findsOneWidget,
      reason: 'gated dot renders a disabled blank tile, not a tappable key',
    );

    // Tap 'Record' — the form should submit with amount=123 (not 0)
    final recordFinder = find.descendant(
      of: keyboard,
      matching: find.text('Record'),
    );
    expect(recordFinder, findsOneWidget);
    await tester.tap(recordFinder);
    await tester.pumpAndSettle();

    final captured = verify(
      () => mockCreateUseCase.execute(captureAny()),
    ).captured;
    expect(captured.length, 1,
        reason: 'use case must be called exactly once');
    final params = captured.first as CreateTransactionParams;
    expect(
      params.amount,
      123,
      reason:
          'After typing "123." the parsed amount must be 123, not 0 (CR-01 regression)',
    );
  });

  // ── WR-01: _isSubmitting deadlock recovery ────────────────────────────────

  testWidgets(
      'WR-01: after persistError result, _isSubmitting resets and second save is possible',
      (tester) async {
    // WR-01 adds a try/finally to _save() so _isSubmitting is always reset.
    // This test verifies the reset path by:
    //   1. First save → use case returns an error result (snackbar, no nav).
    //   2. Second save → use case returns success.
    // If _isSubmitting were NOT reset after step 1, step 2 would be a no-op
    // and the verify would see only 1 call instead of 2.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // First tap: use case returns a persist error (not a throw).
    when(
      () => mockCreateUseCase.execute(any()),
    ).thenAnswer((_) async => Result.error('DB write failed'));

    await tester.pumpWidget(
      createLocalizedWidget(
        ManualOneStepScreen(
          bookId: 'book-1',
          initialAmount: 500,
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

    final recordFinder = find.descendant(
      of: find.byType(SmartKeyboard),
      matching: find.text('Record'),
    );
    expect(recordFinder, findsOneWidget);

    // First tap — use case returns persist error, _isSubmitting should reset.
    await tester.tap(recordFinder);
    await tester.pumpAndSettle();

    // Second tap — use case returns success this time.
    when(
      () => mockCreateUseCase.execute(any()),
    ).thenAnswer((_) async => Result.success(_successTransaction));

    await tester.tap(recordFinder);
    await tester.pumpAndSettle();

    // Both taps must have invoked the use case — proving _isSubmitting reset
    // after the first error result so the second save was not blocked.
    final calls = verify(
      () => mockCreateUseCase.execute(any()),
    ).callCount;
    expect(
      calls,
      2,
      reason:
          'WR-01: _isSubmitting must reset after persistError so a second save is not deadlocked',
    );
  });
}
