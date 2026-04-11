import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_colors.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/accounting/presentation/screens/transaction_entry_screen.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/detail_info_card.dart';

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

  @override
  Future<void> updateSortOrders(Map<String, int> idToSortOrder) async {}
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
      id: 'convenience',
      name: 'コンビニ',
      icon: 'shopping_basket',
      color: '#E85A4F',
      parentId: 'food',
      level: 2,
      sortOrder: 1,
      createdAt: DateTime(2026, 4, 3),
    ),
  ];

  testWidgets('renders detail card and warm background', (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      createLocalizedWidget(
        const TransactionEntryScreen(bookId: 'book-1'),
        locale: const Locale('ja'),
        overrides: [
          categoryRepositoryProvider.overrideWithValue(
            FakeCategoryRepository(categories),
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(DetailInfoCard), findsOneWidget);
    expect(find.text('日付'), findsOneWidget);
    expect(find.text('カテゴリ'), findsOneWidget);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, AppColors.backgroundWarm);
  });
}
