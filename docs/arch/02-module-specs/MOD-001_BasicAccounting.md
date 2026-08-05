# MOD-001/002: 基础记账与分类管理 - 技术设计文档

**模块编号:** MOD-001/002
**文档版本:** 2.0
**创建日期:** 2026-02-03
**预估工时:** 13天
**优先级:** P0（MVP核心）
**状态:** 设计完成

---

## 📋 目录

1. [模块概述](#模块概述)
2. [功能需求](#功能需求)
3. [技术设计](#技术设计)
4. [数据模型](#数据模型)
5. [核心流程](#核心流程)
6. [UI组件设计](#ui组件设计)
7. [测试策略](#测试策略)
8. [性能优化](#性能优化)

---

## 模块概述

### 业务价值

基础记账模块是Happy Pocket的核心功能，提供快速、简洁的记账体验，支持三级分类管理。

### 核心功能

| 功能 | 说明 | 优先级 |
|------|------|--------|
| 快速记账 | 3秒内完成一笔记账 | P0 |
| 交易管理 | 查看、编辑、删除交易 | P0 |
| 三级分类 | 支持三级分类体系 | P0 |
| 分类管理 | 创建、编辑、删除分类 | P0 |
| 交易搜索 | 按时间、金额、分类搜索 | P1 |
| 交易导入 | 批量导入交易记录 | P2 |

### 技术栈

```yaml
状态管理: Riverpod 2.4+
数据库: Drift + SQLCipher
加密: ChaCha20-Poly1305 (备注加密)
哈希链: SHA-256
UI组件: Flutter Material 3
```

---

## 功能需求

### FR-001: 快速记账

**用户故事**: 作为用户，我希望能快速记录一笔交易，无需填写繁琐信息。

**验收标准**:
- ✅ 从打开记账界面到完成保存 < 3秒
- ✅ 默认值智能填充（上次分类、当前时间）
- ✅ 支持快捷金额按钮（10, 20, 50, 100）
- ✅ 支持语音输入金额
- ✅ 自动保存草稿

**技术要求**:
- 表单状态管理（Riverpod）
- 输入验证
- 智能默认值

### FR-002: 交易列表

**用户故事**: 作为用户，我希望查看所有交易记录，支持筛选和排序。

**验收标准**:
- ✅ 显示交易列表（日期降序）
- ✅ 分组显示（按日期分组）
- ✅ 支持下拉刷新
- ✅ 支持上拉加载更多（分页）
- ✅ 显示账本余额
- ✅ 快速操作（删除、编辑）

**技术要求**:
- 分页加载（50条/页）
- 缓存策略
- 滑动删除

### FR-003: 三级分类

**用户故事**: 作为用户，我希望使用三级分类来精细化管理我的支出。

**验收标准**:
- ✅ 系统预设20+分类（一级）
- ✅ 支持二级、三级分类
- ✅ 分类图标和颜色
- ✅ 分类排序
- ✅ 分类禁用（不可删除系统分类）

**示例分类树**:
```
餐饮 (一级)
  ├─ 早餐 (二级)
  │   ├─ 面包店 (三级)
  │   └─ 豆浆油条 (三级)
  ├─ 午餐 (二级)
  └─ 晚餐 (二级)

交通 (一级)
  ├─ 公共交通 (二级)
  │   ├─ 地铁 (三级)
  │   └─ 公交 (三级)
  └─ 打车 (二级)
```

### FR-004: 分类管理

**用户故事**: 作为用户，我希望自定义分类来满足我的个性化需求。

**验收标准**:
- ✅ 创建自定义分类
- ✅ 编辑分类名称、图标、颜色
- ✅ 删除自定义分类（系统分类不可删除）
- ✅ 调整分类排序
- ✅ 分类使用统计

---

## 技术设计

### 架构图

```
┌──────────────────────────────────────────────┐
│  Presentation Layer                          │
│  lib/features/accounting/presentation/       │
│  ┌──────────────┐  ┌──────────────────────┐  │
│  │ TransactionForm│  │ TransactionListScreen│  │
│  │    Screen      │  │                      │  │
│  └──────┬─────────┘  └──────────┬──────────┘  │
│         │                       │              │
│  ┌──────▼───────────────────────▼────────────┐ │
│  │  Providers (ref.watch use case providers)  │ │
│  └──────┬────────────────────────────────────┘ │
└─────────┼──────────────────────────────────────┘
          │ ref.watch()
┌─────────▼──────────────────────────────────────┐
│  Application Layer（全局）                      │
│  lib/application/accounting/                    │
│  ┌──────────────────────────────────────────┐  │
│  │  Use Cases                               │  │
│  │  - CreateTransactionUseCase              │  │
│  │  - UpdateTransactionUseCase              │  │
│  │  - DeleteTransactionUseCase              │  │
│  │  - GetTransactionsUseCase                │  │
│  │  - ManageCategoryUseCase                 │  │
│  └──────┬───────────────────────────────────┘  │
└─────────┼──────────────────────────────────────┘
          │ depends on
┌─────────▼──────────────────────────────────────┐
│  Domain Layer                                   │
│  lib/features/accounting/domain/                │
│  ┌──────────────────────────────────────────┐  │
│  │  Models: Transaction, Category, Book      │  │
│  │  Repos:  TransactionRepository (interface)│  │
│  │          CategoryRepository (interface)    │  │
│  │          BookRepository (interface)        │  │
│  └──────┬───────────────────────────────────┘  │
└─────────┼──────────────────────────────────────┘
          │ implements
┌─────────▼──────────────────────────────────────┐
│  Data Layer（全局）                              │
│  lib/data/                                      │
│  ┌──────────────────────────────────────────┐  │
│  │  Repos: TransactionRepositoryImpl         │  │
│  │  DAOs:  TransactionDao, CategoryDao       │  │
│  │  Tables: transactions_table, categories   │  │
│  └──────┬───────────────────────────────────┘  │
└─────────┼──────────────────────────────────────┘
          │ uses
┌─────────▼──────────────────────────────────────┐
│  Infrastructure Layer（全局）                    │
│  lib/infrastructure/crypto/                     │
│  - FieldEncryptionService (备注加密)             │
│  - HashChainService (哈希链)                     │
└────────────────────────────────────────────────┘
```

### 目录结构

```
# Feature 模块（瘦 Feature：ONLY domain/ + presentation/）
lib/features/accounting/
  ├── domain/                              # ONLY: models + repository interfaces
  │   ├── models/
  │   │   ├── transaction.dart
  │   │   ├── transaction.freezed.dart
  │   │   ├── category.dart
  │   │   ├── category.freezed.dart
  │   │   ├── book.dart
  │   │   └── book.freezed.dart
  │   └── repositories/
  │       ├── transaction_repository.dart   # 抽象接口
  │       ├── category_repository.dart      # 抽象接口
  │       └── book_repository.dart          # 抽象接口
  │
  └── presentation/
      ├── providers/
      │   ├── repository_providers.dart     # 单一 Repository Provider 来源
      │   ├── transaction_providers.dart    # Use Case Providers
      │   ├── transaction_form_provider.dart
      │   ├── transaction_list_provider.dart
      │   ├── category_list_provider.dart
      │   └── category_selector_provider.dart
      ├── screens/
      │   ├── transaction_form_screen.dart
      │   ├── transaction_list_screen.dart
      │   ├── transaction_detail_screen.dart
      │   └── category_management_screen.dart
      └── widgets/
          ├── amount_input.dart
          ├── category_selector.dart
          ├── transaction_list_tile.dart
          ├── quick_amount_buttons.dart
          └── category_icon_picker.dart

# Application 层（全局 Use Cases）
lib/application/accounting/
  ├── create_transaction_use_case.dart
  ├── update_transaction_use_case.dart
  ├── delete_transaction_use_case.dart
  ├── get_transactions_use_case.dart
  └── manage_category_use_case.dart

# Data 层（全局数据访问）
lib/data/
  ├── tables/
  │   ├── transactions_table.dart
  │   ├── categories_table.dart
  │   └── books_table.dart
  ├── daos/
  │   ├── transaction_dao.dart
  │   ├── category_dao.dart
  │   └── book_dao.dart
  └── repositories/
      ├── transaction_repository_impl.dart
      ├── category_repository_impl.dart
      └── book_repository_impl.dart
```

> ⚠️ **v2.0 变更:** `domain/use_cases/` 移至 `lib/application/accounting/`，
> `data/data_sources/local/` 移至 `lib/data/daos/` + `lib/data/tables/`，
> Feature 内部不再包含 `application/` 和 `data/` 目录

---

## 数据模型

### Transaction（交易）

领域模型定义见 [02_Data_Architecture.md](./02_Data_Architecture.md#2-transaction交易记录)。

### Category（分类）

领域模型定义见 [02_Data_Architecture.md](./02_Data_Architecture.md#3-category分类)。

### 系统预设分类

```dart
// lib/shared/constants/default_categories.dart

class DefaultCategories {
  static List<Category> get all => [
    // 一级分类
    ...level1Categories,
    // 二级分类
    ...level2Categories,
    // 三级分类
    ...level3Categories,
  ];

  /// 一级分类（支出）
  static List<Category> get level1Categories => [
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
    // ... 更多一级分类
  ];

  /// 二级分类（餐饮）
  static List<Category> get level2FoodCategories => [
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
    // ...
  ];

  /// 三级分类（早餐）
  static List<Category> get level3BreakfastCategories => [
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
    Category(
      id: 'cat_food_breakfast_chinese',
      name: '中式早餐',
      icon: 'ramen_dining',
      color: '#FF5722',
      parentId: 'cat_food_breakfast',
      level: 3,
      type: TransactionType.expense,
      isSystem: true,
      sortOrder: 2,
      createdAt: DateTime.now(),
    ),
    // ...
  ];
}
```

---

## 核心流程

### 1. 创建交易流程

```dart
// lib/application/accounting/create_transaction_use_case.dart

class CreateTransactionUseCase {
  final TransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;
  final HashChainService _hashChainService;
  final FieldEncryption _fieldEncryption;

  CreateTransactionUseCase({
    required TransactionRepository transactionRepo,
    required CategoryRepository categoryRepo,
    required HashChainService hashChainService,
    required FieldEncryption fieldEncryption,
  })  : _transactionRepo = transactionRepo,
        _categoryRepo = categoryRepo,
        _hashChainService = hashChainService,
        _fieldEncryption = fieldEncryption;

  Future<Result<Transaction>> execute(CreateTransactionParams params) async {
    try {
      // 1. 验证输入
      final validation = _validate(params);
      if (!validation.isSuccess) {
        return Result.error(validation.error!);
      }

      // 2. 验证分类存在
      final category = await _categoryRepo.findById(params.categoryId);
      if (category == null) {
        return Result.error('分类不存在');
      }

      // 3. 获取前一笔交易哈希（哈希链）
      final prevHash = await _hashChainService.getLatestHash(params.bookId);

      // 4. 获取当前设备ID
      final deviceId = await DeviceManager.instance.getCurrentDeviceId();

      // 5. 创建交易对象
      final transaction = Transaction.create(
        bookId: params.bookId,
        deviceId: deviceId,
        amount: params.amount,
        type: params.type,
        categoryId: params.categoryId,
        ledgerType: LedgerType.survival,  // 默认生存账本，MOD-003会智能分类
        timestamp: params.timestamp ?? DateTime.now(),
        note: params.note,
        prevHash: prevHash,
      );

      // 6. 插入数据库
      await _transactionRepo.insert(transaction);

      // 7. 发布事件
      EventBus.instance.publish(TransactionCreatedEvent(transaction));

      return Result.success(transaction);

    } catch (e, stackTrace) {
      await ErrorHandler.logError(e, stackTrace, context: {
        'operation': 'CreateTransaction',
        'bookId': params.bookId,
      });
      return Result.error('创建交易失败: $e');
    }
  }

  Result<void> _validate(CreateTransactionParams params) {
    if (params.amount <= 0) {
      return Result.error('金额必须大于0');
    }

    if (params.bookId.isEmpty) {
      return Result.error('账本ID不能为空');
    }

    if (params.categoryId.isEmpty) {
      return Result.error('请选择分类');
    }

    return Result.success(null);
  }
}

/// 参数对象
class CreateTransactionParams {
  final String bookId;
  final int amount;
  final TransactionType type;
  final String categoryId;
  final DateTime? timestamp;
  final String? note;

  CreateTransactionParams({
    required this.bookId,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.timestamp,
    this.note,
  });
}
```

### 2. 查询交易列表流程

```dart
// lib/features/accounting/presentation/providers/transaction_list_provider.dart

@riverpod
class TransactionList extends _$TransactionList {
  @override
  Future<List<Transaction>> build({
    required String bookId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    final repo = ref.watch(transactionRepositoryProvider);

    return repo.getTransactions(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      categoryIds: categoryId != null ? [categoryId] : null,
      limit: 100,
    );
  }

  /// 刷新列表
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// 删除交易
  Future<void> deleteTransaction(String transactionId) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final useCase = ref.read(deleteTransactionUseCaseProvider);
      final result = await useCase.execute(transactionId);

      if (result.isError) {
        throw Exception(result.error);
      }

      // 刷新列表
      return ref.refresh(transactionListProvider(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
        categoryId: categoryId,
      ));
    });
  }
}
```

### 3. 分类选择流程

```dart
// lib/features/accounting/presentation/providers/category_selector_provider.dart

@riverpod
class CategorySelector extends _$CategorySelector {
  @override
  CategorySelectorState build() {
    return CategorySelectorState(
      selectedLevel1: null,
      selectedLevel2: null,
      selectedLevel3: null,
    );
  }

  /// 获取一级分类列表
  Future<List<Category>> getLevel1Categories() async {
    final repo = ref.read(categoryRepositoryProvider);
    return repo.getCategoriesByLevel(1);
  }

  /// 获取二级分类列表
  Future<List<Category>> getLevel2Categories(String parentId) async {
    final repo = ref.read(categoryRepositoryProvider);
    return repo.getCategoriesByParent(parentId);
  }

  /// 获取三级分类列表
  Future<List<Category>> getLevel3Categories(String parentId) async {
    final repo = ref.read(categoryRepositoryProvider);
    return repo.getCategoriesByParent(parentId);
  }

  /// 选择一级分类
  void selectLevel1(Category category) {
    state = CategorySelectorState(
      selectedLevel1: category,
      selectedLevel2: null,
      selectedLevel3: null,
    );
  }

  /// 选择二级分类
  void selectLevel2(Category category) {
    state = state.copyWith(
      selectedLevel2: category,
      selectedLevel3: null,
    );
  }

  /// 选择三级分类
  void selectLevel3(Category category) {
    state = state.copyWith(selectedLevel3: category);
  }

  /// 获取最终选中的分类ID
  String? get selectedCategoryId {
    return state.selectedLevel3?.id ??
        state.selectedLevel2?.id ??
        state.selectedLevel1?.id;
  }

  /// 重置选择
  void reset() {
    state = CategorySelectorState(
      selectedLevel1: null,
      selectedLevel2: null,
      selectedLevel3: null,
    );
  }
}

@freezed
class CategorySelectorState with _$CategorySelectorState {
  const factory CategorySelectorState({
    Category? selectedLevel1,
    Category? selectedLevel2,
    Category? selectedLevel3,
  }) = _CategorySelectorState;
}
```

---

## UI组件设计

### 1. 交易表单界面

```dart
// lib/features/accounting/presentation/screens/transaction_form_screen.dart

class TransactionFormScreen extends ConsumerStatefulWidget {
  final String bookId;
  final Transaction? editingTransaction;

  const TransactionFormScreen({
    Key? key,
    required this.bookId,
    this.editingTransaction,
  }) : super(key: key);

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState
    extends ConsumerState<TransactionFormScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // 如果是编辑模式，填充数据
    if (widget.editingTransaction != null) {
      final tx = widget.editingTransaction!;
      _amountController.text = (tx.amount / 100).toStringAsFixed(2);
      _noteController.text = tx.note ?? '';

      // 设置分类
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // TODO: 设置选中的分类
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(transactionFormProvider);
    final formNotifier = ref.read(transactionFormProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editingTransaction == null ? '新增交易' : '编辑交易'),
        actions: [
          if (widget.editingTransaction != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _handleDelete,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 金额输入
                    AmountInput(
                      controller: _amountController,
                      onChanged: (value) {
                        final amount = (double.tryParse(value) ?? 0) * 100;
                        formNotifier.updateAmount(amount.toInt());
                      },
                      errorText: formState.errors['amount'],
                    ),

                    const SizedBox(height: 16),

                    // 快捷金额按钮
                    QuickAmountButtons(
                      amounts: [10, 20, 50, 100, 200, 500],
                      onSelected: (amount) {
                        _amountController.text = amount.toStringAsFixed(0);
                        formNotifier.updateAmount(amount * 100);
                      },
                    ),

                    const SizedBox(height: 24),

                    // 交易类型切换
                    SegmentedButton<TransactionType>(
                      segments: const [
                        ButtonSegment(
                          value: TransactionType.expense,
                          label: Text('支出'),
                          icon: Icon(Icons.remove_circle_outline),
                        ),
                        ButtonSegment(
                          value: TransactionType.income,
                          label: Text('收入'),
                          icon: Icon(Icons.add_circle_outline),
                        ),
                      ],
                      selected: {formState.type},
                      onSelectionChanged: (Set<TransactionType> selected) {
                        formNotifier.updateType(selected.first);
                      },
                    ),

                    const SizedBox(height: 24),

                    // 分类选择
                    CategorySelector(
                      selectedCategoryId: formState.categoryId,
                      onCategorySelected: formNotifier.updateCategory,
                      errorText: formState.errors['category'],
                    ),

                    const SizedBox(height: 24),

                    // 备注输入
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: '备注（可选）',
                        hintText: '添加备注信息',
                        border: const OutlineInputBorder(),
                        errorText: formState.errors['note'],
                      ),
                      maxLines: 3,
                      onChanged: formNotifier.updateNote,
                    ),

                    const SizedBox(height: 24),

                    // 日期时间选择
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('交易时间'),
                      subtitle: Text(
                        _formatDateTime(formState.timestamp),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _pickDateTime,
                    ),
                  ],
                ),
              ),
            ),

            // 底部操作栏
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: formState.isSubmitting ? null : _handleSubmit,
                    child: formState.isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('保存'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    ref.read(transactionFormProvider.notifier).updateTimestamp(dateTime);
  }

  Future<void> _handleSubmit() async {
    final formNotifier = ref.read(transactionFormProvider.notifier);
    final result = await formNotifier.submit();

    if (result.isSuccess && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存成功')),
      );
      Navigator.pop(context, result.data);
    } else if (result.isError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!)),
      );
    }
  }

  Future<void> _handleDelete() async {
    // 确认删除
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这笔交易吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 执行删除
    final useCase = ref.read(deleteTransactionUseCaseProvider);
    final result = await useCase.execute(widget.editingTransaction!.id);

    if (result.isSuccess && mounted) {
      Navigator.pop(context);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
```

### 2. 分类选择器组件

```dart
// lib/features/accounting/presentation/widgets/category_selector.dart

class CategorySelector extends ConsumerWidget {
  final String? selectedCategoryId;
  final Function(String categoryId) onCategorySelected;
  final String? errorText;

  const CategorySelector({
    Key? key,
    this.selectedCategoryId,
    required this.onCategorySelected,
    this.errorText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择分类',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),

        // 显示当前选中的分类
        if (selectedCategoryId != null)
          _SelectedCategoryChip(categoryId: selectedCategoryId!),

        const SizedBox(height: 8),

        // 选择分类按钮
        OutlinedButton.icon(
          onPressed: () => _showCategoryPicker(context, ref),
          icon: const Icon(Icons.category),
          label: Text(selectedCategoryId == null ? '选择分类' : '更换分类'),
        ),

        // 错误提示
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showCategoryPicker(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const CategoryPickerBottomSheet(),
    );

    if (result != null) {
      onCategorySelected(result);
    }
  }
}

/// 分类选择器底部弹窗
class CategoryPickerBottomSheet extends ConsumerStatefulWidget {
  const CategoryPickerBottomSheet({Key? key}) : super(key: key);

  @override
  ConsumerState<CategoryPickerBottomSheet> createState() =>
      _CategoryPickerBottomSheetState();
}

class _CategoryPickerBottomSheetState
    extends ConsumerState<CategoryPickerBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final selectorState = ref.watch(categorySelectorProvider);
    final selectorNotifier = ref.read(categorySelectorProvider.notifier);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '选择分类',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 面包屑导航
          if (selectorState.selectedLevel1 != null)
            _BreadcrumbNavigation(
              level1: selectorState.selectedLevel1,
              level2: selectorState.selectedLevel2,
              onLevel1Tap: selectorNotifier.reset,
              onLevel2Tap: () => selectorNotifier.selectLevel1(
                selectorState.selectedLevel1!,
              ),
            ),

          const SizedBox(height: 16),

          // 分类网格
          Expanded(
            child: _CategoryGrid(
              selectorState: selectorState,
              selectorNotifier: selectorNotifier,
              onCategorySelected: (categoryId) {
                Navigator.pop(context, categoryId);
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

### 3. 交易列表组件

```dart
// lib/features/accounting/presentation/widgets/transaction_list_tile.dart

class TransactionListTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionListTile({
    Key? key,
    required this.transaction,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认删除'),
            content: const Text('确定要删除这笔交易吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('删除'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        onDelete?.call();
      },
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(),
          child: Icon(
            _getCategoryIcon(),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(transaction.categoryName ?? '未分类'),
        subtitle: transaction.note != null && transaction.note!.isNotEmpty
            ? Text(
                transaction.note!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatAmount(transaction.amount, transaction.type),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: transaction.type == TransactionType.expense
                    ? Colors.red
                    : Colors.green,
              ),
            ),
            Text(
              _formatTime(transaction.timestamp),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    // TODO: 从分类获取颜色
    return Colors.blue;
  }

  IconData _getCategoryIcon() {
    // TODO: 从分类获取图标
    return Icons.category;
  }

  String _formatAmount(int amount, TransactionType type) {
    final sign = type == TransactionType.expense ? '-' : '+';
    final value = (amount / 100).toStringAsFixed(2);
    return '$sign¥$value';
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays == 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else {
      return '${timestamp.month}-${timestamp.day}';
    }
  }
}
```

---

## 测试策略

### 单元测试

```dart
// test/unit/application/accounting/create_transaction_use_case_test.dart

void main() {
  late MockTransactionRepository mockTransactionRepo;
  late MockCategoryRepository mockCategoryRepo;
  late MockHashChainService mockHashChainService;
  late MockFieldEncryption mockFieldEncryption;
  late CreateTransactionUseCase useCase;

  setUp(() {
    mockTransactionRepo = MockTransactionRepository();
    mockCategoryRepo = MockCategoryRepository();
    mockHashChainService = MockHashChainService();
    mockFieldEncryption = MockFieldEncryption();

    useCase = CreateTransactionUseCase(
      transactionRepo: mockTransactionRepo,
      categoryRepo: mockCategoryRepo,
      hashChainService: mockHashChainService,
      fieldEncryption: mockFieldEncryption,
    );
  });

  group('CreateTransactionUseCase', () {
    test('成功创建交易', () async {
      // Arrange
      final params = CreateTransactionParams(
        bookId: 'book_123',
        amount: 10000,  // 100.00元
        type: TransactionType.expense,
        categoryId: 'cat_food',
      );

      when(mockCategoryRepo.findById('cat_food'))
          .thenAnswer((_) async => Category(...));

      when(mockHashChainService.getLatestHash('book_123'))
          .thenAnswer((_) async => 'prev_hash');

      when(mockTransactionRepo.insert(any))
          .thenAnswer((_) async => Future.value());

      // Act
      final result = await useCase.execute(params);

      // Assert
      expect(result.isSuccess, true);
      expect(result.data, isA<Transaction>());
      expect(result.data!.amount, 10000);
      expect(result.data!.categoryId, 'cat_food');

      verify(mockTransactionRepo.insert(any)).called(1);
    });

    test('金额为0时返回错误', () async {
      // Arrange
      final params = CreateTransactionParams(
        bookId: 'book_123',
        amount: 0,
        type: TransactionType.expense,
        categoryId: 'cat_food',
      );

      // Act
      final result = await useCase.execute(params);

      // Assert
      expect(result.isError, true);
      expect(result.error, '金额必须大于0');
      verifyNever(mockTransactionRepo.insert(any));
    });

    test('分类不存在时返回错误', () async {
      // Arrange
      final params = CreateTransactionParams(
        bookId: 'book_123',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'invalid_category',
      );

      when(mockCategoryRepo.findById('invalid_category'))
          .thenAnswer((_) async => null);

      // Act
      final result = await useCase.execute(params);

      // Assert
      expect(result.isError, true);
      expect(result.error, '分类不存在');
    });
  });
}
```

### Widget测试

```dart
// test/features/accounting/presentation/screens/transaction_form_screen_test.dart

void main() {
  testWidgets('交易表单显示正确', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: TransactionFormScreen(bookId: 'book_123'),
        ),
      ),
    );

    // 验证UI元素
    expect(find.text('新增交易'), findsOneWidget);
    expect(find.byType(AmountInput), findsOneWidget);
    expect(find.byType(CategorySelector), findsOneWidget);
    expect(find.text('保存'), findsOneWidget);
  });

  testWidgets('提交空表单显示验证错误', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: TransactionFormScreen(bookId: 'book_123'),
        ),
      ),
    );

    // 点击保存按钮
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    // 验证错误提示
    expect(find.text('金额必须大于0'), findsOneWidget);
    expect(find.text('请选择分类'), findsOneWidget);
  });
}
```

---

## 性能优化

### 1. 列表虚拟化

使用`ListView.builder`实现虚拟滚动，只渲染可见项。

### 2. 分页加载

每页加载50条记录，减少内存占用。

### 3. 缓存分类数据

分类数据很少变化，缓存60秒。

```dart
@riverpod
Future<List<Category>> categories(CategoriesRef ref) async {
  // 缓存60秒
  ref.cacheFor(const Duration(seconds: 60));

  final repo = ref.watch(categoryRepositoryProvider);
  return repo.findAll();
}
```

### 4. 防抖搜索

搜索输入使用300ms防抖。

---

## 总结

MOD-001/002基础记账模块提供：

1. **快速记账**: 3秒完成记账，智能默认值
2. **三级分类**: 精细化管理，20+系统预设分类
3. **交易管理**: 查看、编辑、删除交易
4. **性能优化**: 分页加载、虚拟滚动、缓存
5. **数据安全**: 哈希链、字段加密

**开发优先级**: P0，预计13天完成。

**依赖模块**:
- ✅ MOD-006 (安全模块) - 密钥管理、加密服务
- ⏳ MOD-003 (双轨账本) - 智能分类引擎

---

**文档维护**:
- 最后更新: 2026-02-03
- 维护者: 功能团队
- 版本: 1.0
