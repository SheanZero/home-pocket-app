import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';

part 'category.freezed.dart';
part 'category.g.dart';

@freezed
class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    required String icon, // Material Icon name or emoji
    required String color,
    required int
        level, // 1, 2, or 3, required TransactionType type,  // expense or income, required DateTime createdAt, // Hex color value
    String? parentId, // Parent category ID (3-level support)
    @Default(false) bool isSystem, // System categories cannot be deleted
    @Default(0) int sortOrder,
  }) = _Category;
  const Category._();

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);

  /// System preset categories
  static List<Category> get systemCategories => [
        // Level 1: Food
        Category(
          id: 'cat_food',
          name: '餐饮',
          icon: 'restaurant',
          color: '#FF5722',
          level: 1,
          type: TransactionType.expense,
          isSystem: true,
          sortOrder: 1,
          createdAt: DateTime.now(),
        ),

        // Level 2: Food > Breakfast
        Category(
          id: 'cat_food_breakfast',
          name: '早餐',
          icon: 'free_breakfast',
          color: '#FF5722',
          parentId: 'cat_food',
          level: 2,
          type: TransactionType.expense,
          isSystem: true,
          sortOrder: 1,
          createdAt: DateTime.now(),
        ),

        // Level 3: Food > Breakfast > Bakery
        Category(
          id: 'cat_food_breakfast_bakery',
          name: '面包店',
          icon: 'bakery_dining',
          color: '#FF5722',
          parentId: 'cat_food_breakfast',
          level: 3,
          type: TransactionType.expense,
          isSystem: true,
          sortOrder: 1,
          createdAt: DateTime.now(),
        ),

        // Level 2: Food > Lunch
        Category(
          id: 'cat_food_lunch',
          name: '午餐',
          icon: 'lunch_dining',
          color: '#FF5722',
          parentId: 'cat_food',
          level: 2,
          type: TransactionType.expense,
          isSystem: true,
          sortOrder: 2,
          createdAt: DateTime.now(),
        ),

        // Level 2: Food > Dinner
        Category(
          id: 'cat_food_dinner',
          name: '晚餐',
          icon: 'dinner_dining',
          color: '#FF5722',
          parentId: 'cat_food',
          level: 2,
          type: TransactionType.expense,
          isSystem: true,
          sortOrder: 3,
          createdAt: DateTime.now(),
        ),

        // Level 1: Transport
        Category(
          id: 'cat_transport',
          name: '交通',
          icon: 'directions_car',
          color: '#2196F3',
          level: 1,
          type: TransactionType.expense,
          isSystem: true,
          sortOrder: 2,
          createdAt: DateTime.now(),
        ),

        // Level 2: Transport > Public
        Category(
          id: 'cat_transport_public',
          name: '公共交通',
          icon: 'directions_bus',
          color: '#2196F3',
          parentId: 'cat_transport',
          level: 2,
          type: TransactionType.expense,
          isSystem: true,
          sortOrder: 1,
          createdAt: DateTime.now(),
        ),

        // Level 3: Transport > Public > Subway
        Category(
          id: 'cat_transport_public_subway',
          name: '地铁',
          icon: 'subway',
          color: '#2196F3',
          parentId: 'cat_transport_public',
          level: 3,
          type: TransactionType.expense,
          isSystem: true,
          sortOrder: 1,
          createdAt: DateTime.now(),
        ),

        // Level 3: Transport > Public > Bus
        Category(
          id: 'cat_transport_public_bus',
          name: '公交',
          icon: 'directions_bus',
          color: '#2196F3',
          parentId: 'cat_transport_public',
          level: 3,
          type: TransactionType.expense,
          isSystem: true,
          sortOrder: 2,
          createdAt: DateTime.now(),
        ),

        // Level 2: Transport > Taxi
        Category(
          id: 'cat_transport_taxi',
          name: '出租车',
          icon: 'local_taxi',
          color: '#2196F3',
          parentId: 'cat_transport',
          level: 2,
          type: TransactionType.expense,
          isSystem: true,
          sortOrder: 2,
          createdAt: DateTime.now(),
        ),

        // Level 1: Shopping
        Category(
          id: 'cat_shopping',
          name: '购物',
          icon: 'shopping_cart',
          color: '#E91E63',
          level: 1,
          type: TransactionType.expense,
          isSystem: true,
          sortOrder: 3,
          createdAt: DateTime.now(),
        ),

        // Level 2: Shopping > Clothing
        Category(
          id: 'cat_shopping_clothing',
          name: '服饰',
          icon: 'checkroom',
          color: '#E91E63',
          parentId: 'cat_shopping',
          level: 2,
          type: TransactionType.expense,
          isSystem: true,
          sortOrder: 1,
          createdAt: DateTime.now(),
        ),

        // Level 2: Shopping > Electronics
        Category(
          id: 'cat_shopping_electronics',
          name: '电子产品',
          icon: 'devices',
          color: '#E91E63',
          parentId: 'cat_shopping',
          level: 2,
          type: TransactionType.expense,
          isSystem: true,
          sortOrder: 2,
          createdAt: DateTime.now(),
        ),

        // Level 1: Entertainment
        Category(
          id: 'cat_entertainment',
          name: '娱乐',
          icon: 'movie',
          color: '#9C27B0',
          level: 1,
          type: TransactionType.expense,
          isSystem: true,
          sortOrder: 4,
          createdAt: DateTime.now(),
        ),

        // Level 2: Entertainment > Movie
        Category(
          id: 'cat_entertainment_movie',
          name: '电影',
          icon: 'movie',
          color: '#9C27B0',
          parentId: 'cat_entertainment',
          level: 2,
          type: TransactionType.expense,
          isSystem: true,
          sortOrder: 1,
          createdAt: DateTime.now(),
        ),

        // Level 2: Entertainment > Game
        Category(
          id: 'cat_entertainment_game',
          name: '游戏',
          icon: 'sports_esports',
          color: '#9C27B0',
          parentId: 'cat_entertainment',
          level: 2,
          type: TransactionType.expense,
          isSystem: true,
          sortOrder: 2,
          createdAt: DateTime.now(),
        ),

        // Level 1: Housing
        Category(
          id: 'cat_housing',
          name: '住房',
          icon: 'home',
          color: '#795548',
          level: 1,
          type: TransactionType.expense,
          isSystem: true,
          sortOrder: 5,
          createdAt: DateTime.now(),
        ),

        // Level 2: Housing > Rent
        Category(
          id: 'cat_housing_rent',
          name: '房租',
          icon: 'house',
          color: '#795548',
          parentId: 'cat_housing',
          level: 2,
          type: TransactionType.expense,
          isSystem: true,
          sortOrder: 1,
          createdAt: DateTime.now(),
        ),

        // Level 2: Housing > Utilities
        Category(
          id: 'cat_housing_utilities',
          name: '水电费',
          icon: 'power',
          color: '#795548',
          parentId: 'cat_housing',
          level: 2,
          type: TransactionType.expense,
          isSystem: true,
          sortOrder: 2,
          createdAt: DateTime.now(),
        ),

        // Level 1: Medical
        Category(
          id: 'cat_medical',
          name: '医疗',
          icon: 'local_hospital',
          color: '#F44336',
          level: 1,
          type: TransactionType.expense,
          isSystem: true,
          sortOrder: 6,
          createdAt: DateTime.now(),
        ),

        // Level 1: Education
        Category(
          id: 'cat_education',
          name: '教育',
          icon: 'school',
          color: '#3F51B5',
          level: 1,
          type: TransactionType.expense,
          isSystem: true,
          sortOrder: 7,
          createdAt: DateTime.now(),
        ),

        // Income categories
        Category(
          id: 'cat_income_salary',
          name: '工资',
          icon: 'payments',
          color: '#4CAF50',
          level: 1,
          type: TransactionType.income,
          isSystem: true,
          sortOrder: 1,
          createdAt: DateTime.now(),
        ),
      ];
}
