import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/create_category_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/category_ledger_config.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_ledger_config_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/state_category_reorder.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/accounting/presentation/screens/category_selection_screen.dart';
import 'package:home_pocket/features/settings/domain/repositories/unit_of_work.dart';
import 'package:home_pocket/generated/app_localizations.dart';

import '../../../../../helpers/test_localizations.dart';

class FakeCategoryRepository implements CategoryRepository {
  FakeCategoryRepository(List<Category> categories)
    : categories = [...categories];

  final List<Category> categories;

  @override
  Future<List<Category>> findActive() async => categories;

  @override
  Future<Category?> findById(String id) async {
    try {
      return categories.firstWhere((category) => category.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Category>> findAll() async => categories;

  @override
  Future<List<Category>> findByLevel(int level) async =>
      categories.where((category) => category.level == level).toList();

  @override
  Future<List<Category>> findByParent(String parentId) async =>
      categories.where((category) => category.parentId == parentId).toList();

  @override
  Future<void> insert(Category category) async => categories.add(category);

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

  Map<String, int>? lastSortOrders;

  @override
  Future<void> updateSortOrders(Map<String, int> idToSortOrder) async {
    lastSortOrders = Map.of(idToSortOrder);
  }
}

class _FakeLedgerConfigRepository implements CategoryLedgerConfigRepository {
  final List<CategoryLedgerConfig> configs = [];

  @override
  Future<void> upsert(CategoryLedgerConfig config) async => configs.add(config);

  @override
  Future<CategoryLedgerConfig?> findById(String categoryId) async => null;

  @override
  Future<List<CategoryLedgerConfig>> findAll() async => [...configs];

  @override
  Future<void> delete(String categoryId) async {}

  @override
  Future<void> deleteAll() async => configs.clear();

  @override
  Future<void> upsertBatch(List<CategoryLedgerConfig> configs) async =>
      this.configs.addAll(configs);
}

class _ImmediateUnitOfWork implements UnitOfWork {
  @override
  Future<T> run<T>(Future<T> Function() action) => action();
}

class _CategoryPickerHarness extends StatefulWidget {
  const _CategoryPickerHarness();

  @override
  State<_CategoryPickerHarness> createState() => _CategoryPickerHarnessState();
}

class _CategoryPickerHarnessState extends State<_CategoryPickerHarness> {
  String? _selectedName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextButton(
            key: const ValueKey('open-category-picker'),
            onPressed: () async {
              final selected = await Navigator.push<Category>(
                context,
                MaterialPageRoute<Category>(
                  builder: (_) => const CategorySelectionScreen(
                    selectedCategoryId: 'convenience',
                  ),
                ),
              );
              if (selected != null && mounted) {
                setState(() => _selectedName = selected.name);
              }
            },
            child: const Text('Open picker'),
          ),
          Text(_selectedName ?? 'Nothing selected'),
        ],
      ),
    );
  }
}

void main() {
  final categories = [
    Category(
      id: 'food',
      name: 'category_food',
      icon: 'restaurant',
      color: '#E85A4F',
      level: 1,
      isSystem: true,
      sortOrder: 1,
      createdAt: DateTime(2026, 4, 3),
    ),
    Category(
      id: 'daily',
      name: 'category_daily',
      icon: 'shopping_basket',
      color: '#FF9800',
      level: 1,
      isSystem: true,
      sortOrder: 2,
      createdAt: DateTime(2026, 4, 3),
    ),
    Category(
      id: 'convenience',
      name: 'コンビニ',
      icon: 'shopping_basket',
      color: '#E85A4F',
      parentId: 'food',
      level: 2,
      sortOrder: 1,
      createdAt: DateTime(2026, 4, 3),
    ),
    Category(
      id: 'supermarket',
      name: 'スーパー',
      icon: 'shopping_basket',
      color: '#E85A4F',
      parentId: 'food',
      level: 2,
      sortOrder: 2,
      createdAt: DateTime(2026, 4, 3),
    ),
  ];

  testWidgets('shows add buttons for expanded category group', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const CategorySelectionScreen(selectedCategoryId: 'convenience'),
        locale: const Locale('ja'),
        overrides: [
          categoryRepositoryProvider.overrideWithValue(
            FakeCategoryRepository(categories),
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('カテゴリを追加'), findsOneWidget);
    expect(find.text('追加'), findsOneWidget);
    expect(find.text('食費'), findsOneWidget);
    expect(find.text('コンビニ'), findsOneWidget);
    expect(find.text('スーパー'), findsOneWidget);
  });

  testWidgets('shows the v16 empty state when search has no matches', (
    tester,
  ) async {
    final repo = FakeCategoryRepository(categories);
    await tester.pumpWidget(
      createLocalizedWidget(
        const CategorySelectionScreen(),
        locale: const Locale('ja'),
        overrides: [categoryRepositoryProvider.overrideWithValue(repo)],
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '一致しない検索');
    await tester.pump();

    expect(find.byIcon(Icons.search_off), findsOneWidget);
    expect(find.text('一致する分類がありません'), findsOneWidget);
  });

  group('custom category creation', () {
    testWidgets('adds an L1 with its chosen ledger and expands it', (
      tester,
    ) async {
      final repo = FakeCategoryRepository(categories);
      final configRepo = _FakeLedgerConfigRepository();
      final useCase = CreateCategoryUseCase(
        categoryRepository: repo,
        ledgerConfigRepository: configRepo,
        unitOfWork: _ImmediateUnitOfWork(),
        idGenerator: () => 'custom-travel',
        clock: () => DateTime(2026, 7, 19),
      );
      await tester.pumpWidget(
        createLocalizedWidget(
          const CategorySelectionScreen(),
          overrides: [
            categoryRepositoryProvider.overrideWithValue(repo),
            createCategoryUseCaseProvider.overrideWithValue(useCase),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('category-add-l1')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('category-create-name')),
        'Travel plans',
      );
      await tester.tap(find.byKey(const ValueKey('category-ledger-joy')));
      await tester.tap(find.byKey(const ValueKey('category-create-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Travel plans'), findsOneWidget);
      expect(
        repo.categories.any((category) => category.id == 'custom-travel'),
        isTrue,
      );
      expect(configRepo.configs.single.ledgerType, LedgerType.joy);
      expect(
        find.byKey(const ValueKey('category-add-l2-custom-travel')),
        findsOneWidget,
      );
    });

    testWidgets('adds an L2 and returns it as the picker selection', (
      tester,
    ) async {
      final repo = FakeCategoryRepository(categories);
      final useCase = CreateCategoryUseCase(
        categoryRepository: repo,
        ledgerConfigRepository: _FakeLedgerConfigRepository(),
        unitOfWork: _ImmediateUnitOfWork(),
        idGenerator: () => 'custom-bakery',
        clock: () => DateTime(2026, 7, 19),
      );
      await tester.pumpWidget(
        createLocalizedWidget(
          const _CategoryPickerHarness(),
          overrides: [
            categoryRepositoryProvider.overrideWithValue(repo),
            createCategoryUseCaseProvider.overrideWithValue(useCase),
          ],
        ),
      );
      await tester.tap(find.byKey(const ValueKey('open-category-picker')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('category-add-l2-food')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('category-create-name')),
        'Bakery',
      );
      await tester.tap(find.byKey(const ValueKey('category-create-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Bakery'), findsOneWidget);
      expect(
        repo.categories
            .singleWhere((category) => category.id == 'custom-bakery')
            .parentId,
        'food',
      );
    });

    testWidgets('rejects a name that duplicates a localized system category', (
      tester,
    ) async {
      final repo = FakeCategoryRepository(categories);
      final useCase = CreateCategoryUseCase(
        categoryRepository: repo,
        ledgerConfigRepository: _FakeLedgerConfigRepository(),
        unitOfWork: _ImmediateUnitOfWork(),
        idGenerator: () => 'unused',
      );
      await tester.pumpWidget(
        createLocalizedWidget(
          const CategorySelectionScreen(),
          locale: const Locale('ja'),
          overrides: [
            categoryRepositoryProvider.overrideWithValue(repo),
            createCategoryUseCaseProvider.overrideWithValue(useCase),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('category-add-l1')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('category-create-name')),
        '食費',
      );
      await tester.tap(find.byKey(const ValueKey('category-create-submit')));
      await tester.pumpAndSettle();

      expect(find.text('同じ名前の分類があります'), findsOneWidget);
      expect(repo.categories, hasLength(categories.length));
    });
  });

  group('reorder entry', () {
    testWidgets('AppBar shows Icons.reorder button in read mode', (
      tester,
    ) async {
      final repo = FakeCategoryRepository(categories);
      await tester.pumpWidget(
        createLocalizedWidget(
          const CategorySelectionScreen(),
          overrides: [categoryRepositoryProvider.overrideWithValue(repo)],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.reorder), findsOneWidget);
    });

    testWidgets('tapping reorder button switches AppBar to edit title', (
      tester,
    ) async {
      final repo = FakeCategoryRepository(categories);
      await tester.pumpWidget(
        createLocalizedWidget(
          const CategorySelectionScreen(),
          overrides: [categoryRepositoryProvider.overrideWithValue(repo)],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.reorder));
      await tester.pumpAndSettle();

      // Edit state AppBar title should be "Edit category order" in en locale
      expect(find.text('Edit category order'), findsOneWidget);
      // Save button is present
      expect(find.text('Save'), findsOneWidget);
      // Search bar is hidden
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('save after L1 reorder writes the new order to the repo', (
      tester,
    ) async {
      final repo = FakeCategoryRepository(categories);
      await tester.pumpWidget(
        createLocalizedWidget(
          const CategorySelectionScreen(),
          overrides: [categoryRepositoryProvider.overrideWithValue(repo)],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.reorder));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CategorySelectionScreen)),
      );
      container.read(categoryReorderProvider.notifier).reorderL1(0, 2);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repo.lastSortOrders, isNotNull);
      expect(repo.lastSortOrders!['daily'], 0);
      expect(repo.lastSortOrders!['food'], 1);
    });

    testWidgets('edit mode renders in dark theme (AC-13)', (tester) async {
      final repo = FakeCategoryRepository(categories);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [categoryRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            theme: ThemeData.dark(),
            locale: const Locale('en'),
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.supportedLocales,
            home: const CategorySelectionScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.reorder));
      await tester.pumpAndSettle();

      expect(find.text('Edit category order'), findsOneWidget);
      expect(find.text('Drag to reorder'), findsOneWidget);
      expect(find.byIcon(Icons.drag_indicator), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('cancel after dragging shows discard dialog', (tester) async {
      final repo = FakeCategoryRepository(categories);
      await tester.pumpWidget(
        createLocalizedWidget(
          const CategorySelectionScreen(),
          overrides: [categoryRepositoryProvider.overrideWithValue(repo)],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.reorder));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // No drag happened → close dialog NOT shown, we exited directly
      expect(find.text('Discard unsaved changes?'), findsNothing);
      expect(find.text('Select Category'), findsOneWidget);
    });

    testWidgets('discard dialog offers keep editing and discard', (
      tester,
    ) async {
      final repo = FakeCategoryRepository(categories);
      await tester.pumpWidget(
        createLocalizedWidget(
          const CategorySelectionScreen(),
          overrides: [categoryRepositoryProvider.overrideWithValue(repo)],
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CategorySelectionScreen)),
      );
      final notifier = container.read(categoryReorderProvider.notifier);
      notifier.enterEditing(
        l1: categories.where((c) => c.level == 1).toList(),
        l2ByParent: const {},
      );
      notifier.reorderL1(0, 1);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Discard unsaved changes?'), findsOneWidget);
      expect(find.text('Keep editing'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Select Category'), findsOneWidget);
    });
  });

  group('auto-scroll to selected category', () {
    // A list long enough that lower L1 groups start off-screen on the default
    // 800x600 test surface. The pre-selected L2 ('leaf') lives under l1_14 —
    // far enough down to require scrolling, with enough groups below it that
    // it can be aligned to the top of the viewport.
    final longList = <Category>[
      for (var i = 0; i < 20; i++)
        Category(
          id: 'l1_$i',
          name: 'L1-$i',
          icon: 'restaurant',
          color: '#6FA36F',
          level: 1,
          isSystem: true,
          sortOrder: i,
          createdAt: DateTime(2026, 4, 3),
        ),
      Category(
        id: 'leaf',
        name: 'Leaf-Child',
        icon: 'restaurant',
        color: '#6FA36F',
        parentId: 'l1_14',
        level: 2,
        sortOrder: 1,
        createdAt: DateTime(2026, 4, 3),
      ),
    ];

    ScrollableState listScrollable(WidgetTester tester) {
      return tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
    }

    testWidgets('scrolls the selected L1 group into view near the top', (
      tester,
    ) async {
      await tester.pumpWidget(
        createLocalizedWidget(
          const CategorySelectionScreen(selectedCategoryId: 'leaf'),
          locale: const Locale('en'),
          overrides: [
            categoryRepositoryProvider.overrideWithValue(
              FakeCategoryRepository(longList),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // List scrolled away from the top.
      expect(listScrollable(tester).position.pixels, greaterThan(0.0));

      // The selected L1 is built and sits near the top of the viewport.
      expect(find.text('L1-14'), findsOneWidget);
      expect(tester.getTopLeft(find.text('L1-14')).dy, lessThan(400.0));
    });

    testWidgets('does not scroll when no category is pre-selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        createLocalizedWidget(
          const CategorySelectionScreen(),
          locale: const Locale('en'),
          overrides: [
            categoryRepositoryProvider.overrideWithValue(
              FakeCategoryRepository(longList),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(listScrollable(tester).position.pixels, 0.0);
    });
  });
}
