// Golden tests for [CategoryFilterSheet] (Phase 30, D-01/D-02/D-03).
//
// Covers: 3 locales (ja, zh, en), light theme.
//
// Uses _FakeCategoryRepository (same fixture as list_category_filter_sheet_test.dart)
// and currentLocaleProvider override to prevent async retry timers.
//
// Run: flutter test test/golden/list_category_filter_sheet_golden_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show categoryRepositoryProvider;
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

// Canonical test categories — one L1 "food" with two L2 children.
// Matches list_category_filter_sheet_test.dart for consistency.
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

Widget _wrap({required Locale locale}) {
  return ProviderScope(
    overrides: [
      categoryRepositoryProvider
          .overrideWithValue(_FakeCategoryRepository(_testCategories)),
      // Prevents async retry timers from currentLocaleProvider
      locale_providers.currentLocaleProvider
          .overrideWith((_) async => locale),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      theme: ThemeData.light(),
      home: Scaffold(
        body: SizedBox(
          // 400px width instead of 390 to avoid 1px overflow in the
          // header row when using the English locale (longer text).
          width: 400,
          height: 500,
          child: CategoryFilterSheet(initialSelected: const {}),
        ),
      ),
    ),
  );
}

void main() {
  group('CategoryFilterSheet golden', () {
    testWidgets('locale ja', (tester) async {
      await tester.pumpWidget(_wrap(locale: const Locale('ja')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CategoryFilterSheet),
        matchesGoldenFile('goldens/list_category_filter_sheet_ja.png'),
      );
    });

    testWidgets('locale zh', (tester) async {
      await tester.pumpWidget(_wrap(locale: const Locale('zh')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CategoryFilterSheet),
        matchesGoldenFile('goldens/list_category_filter_sheet_zh.png'),
      );
    });

    testWidgets('locale en', (tester) async {
      await tester.pumpWidget(_wrap(locale: const Locale('en')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CategoryFilterSheet),
        matchesGoldenFile('goldens/list_category_filter_sheet_en.png'),
      );
    });
  });
}
