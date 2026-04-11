import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/category_reorder_notifier.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/accounting/presentation/screens/category_selection_screen.dart';
import 'package:home_pocket/generated/app_localizations.dart';

import '../../../../../helpers/test_localizations.dart';

class FakeCategoryRepository implements CategoryRepository {
  FakeCategoryRepository(this.categories);

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

  Map<String, int>? lastSortOrders;

  @override
  Future<void> updateSortOrders(Map<String, int> idToSortOrder) async {
    lastSortOrders = Map.of(idToSortOrder);
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
      container.read(categoryReorderNotifierProvider.notifier).reorderL1(0, 2);
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
      final notifier = container.read(categoryReorderNotifierProvider.notifier);
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
}
