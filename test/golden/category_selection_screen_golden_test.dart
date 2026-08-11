@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_theme.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show categoryRepositoryProvider;
import 'package:home_pocket/features/accounting/presentation/screens/category_selection_screen.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/shared/constants/default_categories.dart';

class _FakeCategoryRepository implements CategoryRepository {
  final List<Category> categories = [...DefaultCategories.all];

  @override
  Future<List<Category>> findActive() async => categories;

  @override
  Future<Category?> findById(String id) async {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
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
  Future<void> insertBatch(List<Category> categories) async =>
      this.categories.addAll(categories);

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
  Future<void> updateSortOrders(Map<String, int> idToSortOrder) async {}

  @override
  Future<void> deleteAll() async => categories.clear();
}

Widget _subject({
  Brightness brightness = Brightness.light,
  String selectedCategoryId = 'cat_food_dining_out',
}) {
  const locale = Locale('ja');
  return ProviderScope(
    overrides: [
      categoryRepositoryProvider.overrideWithValue(_FakeCategoryRepository()),
      locale_providers.currentLocaleProvider.overrideWith((_) async => locale),
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
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      home: CategorySelectionScreen(selectedCategoryId: selectedCategoryId),
    ),
  );
}

void main() {
  void configureSurface(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  testWidgets('v16 category browse state', (tester) async {
    configureSurface(tester);
    await tester.pumpWidget(_subject());
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/category_selection_v16_light_ja.png'),
    );
  });

  testWidgets('v16 category browse state dark', (tester) async {
    configureSurface(tester);
    await tester.pumpWidget(
      _subject(
        brightness: Brightness.dark,
        selectedCategoryId: 'cat_clothing_clothes',
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/category_selection_v16_dark_ja.png'),
    );
  });

  testWidgets('v16 L1 creation sheet', (tester) async {
    configureSurface(tester);
    await tester.pumpWidget(_subject());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('category-add-l1')));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/category_creation_l1_v16_light_ja.png'),
    );
  });
}
