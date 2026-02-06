import '../../features/accounting/domain/models/category.dart';
import '../../features/accounting/domain/models/transaction.dart';

/// System default categories.
///
/// All system categories use `isSystem: true`.
/// The `name` field stores a plain display string for now;
/// will be migrated to localization keys in a future i18n task.
abstract final class DefaultCategories {
  static final DateTime _epoch = DateTime(2026, 1, 1);

  /// All default categories (expense + income, all levels).
  static List<Category> get all => [...expense, ...income];

  /// Expense categories only.
  static List<Category> get expense => [..._expenseLevel1, ..._expenseLevel2];

  /// Income categories only.
  static List<Category> get income => _incomeLevel1;

  // -- Expense Level 1 --

  static final List<Category> _expenseLevel1 = [
    Category(
      id: 'cat_food',
      name: '餐饮',
      icon: 'restaurant',
      color: '#FF5722',
      level: 1,
      type: TransactionType.expense,
      isSystem: true,
      sortOrder: 1,
      createdAt: _epoch,
    ),
    Category(
      id: 'cat_transport',
      name: '交通',
      icon: 'directions_car',
      color: '#2196F3',
      level: 1,
      type: TransactionType.expense,
      isSystem: true,
      sortOrder: 2,
      createdAt: _epoch,
    ),
    Category(
      id: 'cat_shopping',
      name: '购物',
      icon: 'shopping_cart',
      color: '#E91E63',
      level: 1,
      type: TransactionType.expense,
      isSystem: true,
      sortOrder: 3,
      createdAt: _epoch,
    ),
    Category(
      id: 'cat_entertainment',
      name: '娱乐',
      icon: 'movie',
      color: '#9C27B0',
      level: 1,
      type: TransactionType.expense,
      isSystem: true,
      sortOrder: 4,
      createdAt: _epoch,
    ),
    Category(
      id: 'cat_housing',
      name: '住房',
      icon: 'home',
      color: '#795548',
      level: 1,
      type: TransactionType.expense,
      isSystem: true,
      sortOrder: 5,
      createdAt: _epoch,
    ),
    Category(
      id: 'cat_medical',
      name: '医疗',
      icon: 'local_hospital',
      color: '#F44336',
      level: 1,
      type: TransactionType.expense,
      isSystem: true,
      sortOrder: 6,
      createdAt: _epoch,
    ),
    Category(
      id: 'cat_education',
      name: '教育',
      icon: 'school',
      color: '#3F51B5',
      level: 1,
      type: TransactionType.expense,
      isSystem: true,
      sortOrder: 7,
      createdAt: _epoch,
    ),
    Category(
      id: 'cat_daily',
      name: '日用',
      icon: 'local_mall',
      color: '#00BCD4',
      level: 1,
      type: TransactionType.expense,
      isSystem: true,
      sortOrder: 8,
      createdAt: _epoch,
    ),
    Category(
      id: 'cat_social',
      name: '社交',
      icon: 'people',
      color: '#FF9800',
      level: 1,
      type: TransactionType.expense,
      isSystem: true,
      sortOrder: 9,
      createdAt: _epoch,
    ),
    Category(
      id: 'cat_other_expense',
      name: '其他',
      icon: 'more_horiz',
      color: '#607D8B',
      level: 1,
      type: TransactionType.expense,
      isSystem: true,
      sortOrder: 99,
      createdAt: _epoch,
    ),
  ];

  // -- Expense Level 2 (sub-categories) --

  static final List<Category> _expenseLevel2 = [
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
      createdAt: _epoch,
    ),
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
      createdAt: _epoch,
    ),
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
      createdAt: _epoch,
    ),
    Category(
      id: 'cat_food_snack',
      name: '零食',
      icon: 'icecream',
      color: '#FF5722',
      parentId: 'cat_food',
      level: 2,
      type: TransactionType.expense,
      isSystem: true,
      sortOrder: 4,
      createdAt: _epoch,
    ),
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
      createdAt: _epoch,
    ),
    Category(
      id: 'cat_transport_taxi',
      name: '打车',
      icon: 'local_taxi',
      color: '#2196F3',
      parentId: 'cat_transport',
      level: 2,
      type: TransactionType.expense,
      isSystem: true,
      sortOrder: 2,
      createdAt: _epoch,
    ),
  ];

  // -- Income Level 1 --

  static final List<Category> _incomeLevel1 = [
    Category(
      id: 'cat_salary',
      name: '工资',
      icon: 'account_balance',
      color: '#4CAF50',
      level: 1,
      type: TransactionType.income,
      isSystem: true,
      sortOrder: 1,
      createdAt: _epoch,
    ),
    Category(
      id: 'cat_bonus',
      name: '奖金',
      icon: 'stars',
      color: '#FFC107',
      level: 1,
      type: TransactionType.income,
      isSystem: true,
      sortOrder: 2,
      createdAt: _epoch,
    ),
    Category(
      id: 'cat_investment',
      name: '投资收益',
      icon: 'trending_up',
      color: '#009688',
      level: 1,
      type: TransactionType.income,
      isSystem: true,
      sortOrder: 3,
      createdAt: _epoch,
    ),
    Category(
      id: 'cat_other_income',
      name: '其他收入',
      icon: 'attach_money',
      color: '#8BC34A',
      level: 1,
      type: TransactionType.income,
      isSystem: true,
      sortOrder: 99,
      createdAt: _epoch,
    ),
  ];
}
