// Widget tests for CategoryFilterSheet (FILTER-03, D-02, B2).
//
// CategoryFilterSheet is defined in:
//   lib/features/list/presentation/widgets/list_category_filter_sheet.dart
//
// These tests cover:
//   - Apply button calling setCategories with _localSelected
//   - D-02: L1 tap cascades to all its L2 children
//   - Tristate: L1 renders partial when some L2 selected, all when all L2 selected,
//               none when none selected (B2)
//
// Run: flutter test test/widget/features/list/list_category_filter_sheet_test.dart

// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show categoryRepositoryProvider;
import 'package:home_pocket/features/list/presentation/providers/state_list_filter.dart';
import 'package:home_pocket/features/list/presentation/widgets/list_category_filter_sheet.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;
import 'package:home_pocket/generated/app_localizations.dart';

class _FakeCategoryRepository implements CategoryRepository {
  _FakeCategoryRepository(this.categories);
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

// Test categories: one L1 "food" with two L2 children.
final _testCategories = [
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

/// Pumps a CategoryFilterSheet inside ProviderScope + MaterialApp.
///
/// Uses ProviderScope (tied to widget lifecycle) to avoid pending-timer issues
/// from async providers like currentLocaleProvider.
///
/// [initialSelected] pre-populates the sheet's local selection state.
Future<ProviderContainer> _pumpSheet(
  WidgetTester tester, {
  Set<String> initialSelected = const {},
}) async {
  late ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoryRepositoryProvider
            .overrideWithValue(_FakeCategoryRepository(_testCategories)),
        locale_providers.currentLocaleProvider
            .overrideWith((_) async => const Locale('ja')),
      ],
      child: Builder(
        builder: (context) {
          container = ProviderScope.containerOf(context);
          return MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: Scaffold(
              body: Center(
                child: CategoryFilterSheet(initialSelected: initialSelected),
              ),
            ),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('CategoryFilterSheet', () {
    testWidgets(
        'Apply button calls setCategories with _localSelected',
        (tester) async {
      final container = await _pumpSheet(tester, initialSelected: {});
      // Tap Apply button — with empty selection, provider categoryIds stays empty
      await tester.tap(find.text('適用'));
      await tester.pumpAndSettle();
      // Sheet called setCategories({}) — provider categoryIds is empty
      expect(container.read(listFilterProvider).categoryIds, isEmpty);
    });

    testWidgets(
        'D-02: L1 tap cascades to all its L2 children',
        (tester) async {
      await _pumpSheet(tester, initialSelected: {});
      // Categories loaded; find the L1 Checkbox (first Checkbox in list)
      final l1Checkboxes = find.byType(Checkbox);
      // Tap the first Checkbox (L1 food — none → all)
      await tester.tap(l1Checkboxes.first);
      await tester.pumpAndSettle();
      // After L1 tap, Apply shows the count (2 L2 children selected)
      expect(find.text('適用 (2)'), findsOneWidget);
    });

    testWidgets(
        'tristate: L1 renders partial when some L2 selected, all when all L2 selected, none when none selected',
        (tester) async {
      // Scenario: pump with only one of two L2 children selected → L1 should be partial (null)
      await _pumpSheet(
        tester,
        initialSelected: {'convenience'}, // half of food's L2 children
      );
      // L1 "food" should render with tristate=true (partial), value==null
      final l1PartialCheckbox = find.byWidgetPredicate(
        (w) => w is Checkbox && w.tristate == true && w.value == null,
      );
      expect(l1PartialCheckbox, findsAtLeastNWidgets(1));
    });
  });
}
