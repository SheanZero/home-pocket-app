# Happy Pocket MVP - 状态管理架构

**文档版本:** 1.0
**创建日期:** 2026-02-03
**状态:** 完成
**作者:** Claude Sonnet 4.5 + senior-architect

---

## 📋 目录

1. [概述](#概述)
2. [Riverpod核心概念](#riverpod核心概念)
3. [Provider层次结构](#provider层次结构)
4. [状态管理模式](#状态管理模式)
5. [依赖注入](#依赖注入)
6. [最佳实践](#最佳实践)
7. [测试策略](#测试策略)

---

## 概述

### 为什么选择Riverpod？

详细决策理由参见 [14_ADR_State_Management.md](./14_ADR_State_Management.md)。

**核心优势**:

| 特性 | Riverpod | Bloc | GetX |
|------|----------|------|------|
| 编译时安全 | ✅ 强类型 | ✅ 强类型 | ❌ 动态 |
| 依赖注入 | ✅ 编译时 | ➖ 手动 | ✅ 运行时 |
| 测试性 | ✅ 优秀 | ✅ 优秀 | ➖ 中等 |
| DevTools | ✅ 优秀 | ✅ 优秀 | ➖ 基础 |
| 学习曲线 | ➖ 中等 | ➖ 陡峭 | ✅ 平缓 |
| 样板代码 | ✅ 少 | ❌ 多 | ✅ 少 |
| 社区支持 | ✅ 活跃 | ✅ 活跃 | ✅ 活跃 |

**选择Riverpod的理由**:
1. 编译时类型安全，减少运行时错误
2. 自动依赖注入和生命周期管理
3. 优秀的DevTools支持
4. 少样板代码，开发效率高
5. 易于测试和Mock

### 技术栈

```yaml
dependencies:
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0

dev_dependencies:
  riverpod_generator: ^2.3.0
  build_runner: ^2.4.0
```

---

## Riverpod核心概念

### 1. Provider类型

#### Provider（只读）

用于提供不可变的值或服务实例。

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

// 简单值Provider
@riverpod
String apiUrl(ApiUrlRef ref) {
  return 'https://api.homepocket.com';
}

// 服务实例Provider
@riverpod
AppDatabase database(DatabaseRef ref) {
  return AppDatabase();
}

// 依赖其他Provider
@riverpod
TransactionRepository transactionRepository(TransactionRepositoryRef ref) {
  final db = ref.watch(databaseProvider);
  return TransactionRepositoryImpl(db);
}
```

#### StateProvider（简单状态）

用于管理简单的可变状态。

```dart
// 简单状态
@riverpod
class SelectedLedgerType extends _$SelectedLedgerType {
  @override
  LedgerType build() => LedgerType.survival;

  void select(LedgerType type) {
    state = type;
  }

  void toggle() {
    state = state == LedgerType.survival
      ? LedgerType.soul
      : LedgerType.survival;
  }
}
```

#### FutureProvider（异步数据）

用于异步加载数据。

```dart
@riverpod
Future<List<Transaction>> recentTransactions(
  RecentTransactionsRef ref,
  String bookId,
) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getTransactions(
    bookId: bookId,
    limit: 10,
  );
}
```

#### StreamProvider（流式数据）

用于响应流式数据。

```dart
@riverpod
Stream<SyncStatus> syncStatus(SyncStatusRef ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.statusStream;
}
```

#### NotifierProvider（复杂状态）

用于管理复杂的可变状态（推荐）。

```dart
@riverpod
class TransactionList extends _$TransactionList {
  @override
  Future<List<Transaction>> build({
    required String bookId,
    LedgerType? filterLedger,
  }) async {
    final repo = ref.watch(transactionRepositoryProvider);
    return repo.getTransactions(
      bookId: bookId,
      ledgerType: filterLedger,
    );
  }

  // 业务方法
  Future<void> addTransaction(Transaction tx) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(transactionRepositoryProvider);
      await repo.insert(tx);
      // 重新加载数据
      return ref.refresh(transactionListProvider(
        bookId: bookId,
        filterLedger: filterLedger,
      ));
    });
  }

  Future<void> deleteTransaction(String txId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(transactionRepositoryProvider);
      await repo.delete(txId);
      return ref.refresh(transactionListProvider(
        bookId: bookId,
        filterLedger: filterLedger,
      ));
    });
  }
}
```

---

## Provider层次结构

Happy Pocket的Provider组织结构：

```
lib/
  ├── core/
  │   └── providers/
  │       ├── database_provider.dart         # 数据库实例
  │       ├── key_manager_provider.dart      # 密钥管理
  │       └── device_manager_provider.dart   # 设备管理
  │
  ├── features/
  │   ├── accounting/
  │   │   └── providers/
  │   │       ├── transaction_repository_provider.dart
  │   │       ├── transaction_list_provider.dart
  │   │       ├── transaction_form_provider.dart
  │   │       └── classification_service_provider.dart
  │   │
  │   ├── dual_ledger/
  │   │   └── providers/
  │   │       ├── ledger_filter_provider.dart
  │   │       ├── soul_config_provider.dart
  │   │       └── celebration_provider.dart
  │   │
  │   ├── sync/
  │   │   └── providers/
  │   │       ├── sync_service_provider.dart
  │   │       ├── sync_status_provider.dart
  │   │       └── device_list_provider.dart
  │   │
  │   └── ...
  │
  └── shared/
      └── providers/
          ├── current_book_provider.dart     # 当前账本
          └── app_state_provider.dart        # 全局应用状态
```

### 核心Provider定义

#### 1. 数据库Provider

```dart
// lib/core/providers/database_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../database/database.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
AppDatabase database(DatabaseRef ref) {
  final db = AppDatabase();

  // 清理
  ref.onDispose(() {
    db.close();
  });

  return db;
}
```

#### 2. Repository Providers

```dart
// lib/features/accounting/providers/transaction_repository_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transaction_repository_provider.g.dart';

@Riverpod(keepAlive: true)
TransactionRepository transactionRepository(TransactionRepositoryRef ref) {
  final db = ref.watch(databaseProvider);
  final fieldEncryption = ref.watch(fieldEncryptionProvider);

  return TransactionRepositoryImpl(
    db: db,
    fieldEncryption: fieldEncryption,
  );
}
```

#### 3. Use Case Providers

```dart
// lib/features/accounting/providers/create_transaction_use_case_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'create_transaction_use_case_provider.g.dart';

@riverpod
CreateTransactionUseCase createTransactionUseCase(
  CreateTransactionUseCaseRef ref,
) {
  return CreateTransactionUseCase(
    transactionRepo: ref.watch(transactionRepositoryProvider),
    categoryRepo: ref.watch(categoryRepositoryProvider),
    classificationService: ref.watch(classificationServiceProvider),
    fieldEncryption: ref.watch(fieldEncryptionProvider),
    hashChainService: ref.watch(hashChainServiceProvider),
  );
}
```

#### 4. 状态Provider（UI层）

```dart
// lib/features/accounting/providers/transaction_list_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transaction_list_provider.g.dart';

@riverpod
class TransactionList extends _$TransactionList {
  @override
  Future<List<Transaction>> build({
    required String bookId,
    LedgerType? filterLedger,
    String? filterCategory,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final repo = ref.watch(transactionRepositoryProvider);

    return repo.getTransactions(
      bookId: bookId,
      ledgerType: filterLedger,
      categoryIds: filterCategory != null ? [filterCategory] : null,
      startDate: startDate,
      endDate: endDate,
      limit: 100,
    );
  }

  // 刷新数据
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  // 添加交易
  Future<void> addTransaction(Transaction tx) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(transactionRepositoryProvider);
      await repo.insert(tx);
      return ref.refresh(transactionListProvider(
        bookId: bookId,
        filterLedger: filterLedger,
        filterCategory: filterCategory,
        startDate: startDate,
        endDate: endDate,
      ));
    });
  }
}
```

---

## 状态管理模式

### 1. 表单状态管理

#### 表单Provider

```dart
// lib/features/accounting/providers/transaction_form_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transaction_form_provider.g.dart';

@riverpod
class TransactionForm extends _$TransactionForm {
  @override
  TransactionFormState build() {
    return TransactionFormState.initial();
  }

  // 更新金额
  void updateAmount(int amount) {
    state = state.copyWith(amount: amount);
  }

  // 更新分类
  void updateCategory(String categoryId) {
    state = state.copyWith(categoryId: categoryId);
  }

  // 更新备注
  void updateNote(String note) {
    state = state.copyWith(note: note);
  }

  // 验证表单
  bool validate() {
    final errors = <String, String>{};

    if (state.amount <= 0) {
      errors['amount'] = '金额必须大于0';
    }

    if (state.categoryId.isEmpty) {
      errors['category'] = '请选择分类';
    }

    state = state.copyWith(errors: errors);
    return errors.isEmpty;
  }

  // 提交表单
  Future<Result<Transaction>> submit() async {
    if (!validate()) {
      return Result.error('表单验证失败');
    }

    state = state.copyWith(isSubmitting: true);

    try {
      final useCase = ref.read(createTransactionUseCaseProvider);
      final result = await useCase.execute(
        bookId: state.bookId,
        amount: state.amount,
        type: state.type,
        categoryId: state.categoryId,
        note: state.note,
        photoFile: state.photoFile,
      );

      if (result.isSuccess) {
        state = TransactionFormState.initial();  // 重置表单
      } else {
        state = state.copyWith(
          isSubmitting: false,
          errors: {'submit': result.error!},
        );
      }

      return result;

    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errors: {'submit': e.toString()},
      );
      return Result.error(e.toString());
    }
  }

  // 重置表单
  void reset() {
    state = TransactionFormState.initial();
  }
}

/// 表单状态
@freezed
class TransactionFormState with _$TransactionFormState {
  const factory TransactionFormState({
    required String bookId,
    @Default(0) int amount,
    @Default(TransactionType.expense) TransactionType type,
    @Default('') String categoryId,
    @Default('') String note,
    File? photoFile,
    @Default({}) Map<String, String> errors,
    @Default(false) bool isSubmitting,
  }) = _TransactionFormState;

  factory TransactionFormState.initial() {
    return const TransactionFormState(bookId: '');
  }
}
```

#### UI使用

```dart
class TransactionFormScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(transactionFormProvider);
    final formNotifier = ref.read(transactionFormProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('新增交易')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 金额输入
            AmountInput(
              value: formState.amount,
              onChanged: formNotifier.updateAmount,
              error: formState.errors['amount'],
            ),

            // 分类选择
            CategorySelector(
              selectedId: formState.categoryId,
              onSelect: formNotifier.updateCategory,
              error: formState.errors['category'],
            ),

            // 备注输入
            TextField(
              decoration: InputDecoration(
                labelText: '备注',
                errorText: formState.errors['note'],
              ),
              onChanged: formNotifier.updateNote,
            ),

            const Spacer(),

            // 提交按钮
            ElevatedButton(
              onPressed: formState.isSubmitting
                ? null
                : () async {
                    final result = await formNotifier.submit();
                    if (result.isSuccess) {
                      Navigator.pop(context);
                    }
                  },
              child: formState.isSubmitting
                ? const CircularProgressIndicator()
                : const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 2. 列表状态管理

#### 分页列表Provider

```dart
@riverpod
class TransactionListPaginated extends _$TransactionListPaginated {
  static const _pageSize = 50;
  int _page = 0;

  @override
  Future<PaginatedList<Transaction>> build({
    required String bookId,
  }) async {
    return _loadPage(0);
  }

  // 加载更多
  Future<void> loadMore() async {
    if (state.value?.hasMore != true) return;

    _page++;

    state = await AsyncValue.guard(() async {
      final newPage = await _loadPage(_page);
      final current = state.value!;

      return PaginatedList(
        items: [...current.items, ...newPage.items],
        page: newPage.page,
        hasMore: newPage.hasMore,
      );
    });
  }

  // 刷新（重置到第一页）
  Future<void> refresh() async {
    _page = 0;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadPage(0));
  }

  Future<PaginatedList<Transaction>> _loadPage(int page) async {
    final repo = ref.read(transactionRepositoryProvider);
    final items = await repo.getTransactions(
      bookId: bookId,
      limit: _pageSize,
      offset: page * _pageSize,
    );

    return PaginatedList(
      items: items,
      page: page,
      hasMore: items.length == _pageSize,
    );
  }
}

/// 分页列表模型
class PaginatedList<T> {
  final List<T> items;
  final int page;
  final bool hasMore;

  PaginatedList({
    required this.items,
    required this.page,
    required this.hasMore,
  });
}
```

#### UI使用（无限滚动）

```dart
class TransactionListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookId = ref.watch(currentBookIdProvider);
    final listState = ref.watch(transactionListPaginatedProvider(bookId: bookId));

    return listState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => ErrorWidget(error: err),
      data: (paginatedList) {
        return RefreshIndicator(
          onRefresh: () => ref.read(
            transactionListPaginatedProvider(bookId: bookId).notifier
          ).refresh(),
          child: ListView.builder(
            itemCount: paginatedList.items.length + 1,
            itemBuilder: (context, index) {
              if (index == paginatedList.items.length) {
                // 加载更多指示器
                if (paginatedList.hasMore) {
                  // 触发加载更多
                  ref.read(
                    transactionListPaginatedProvider(bookId: bookId).notifier
                  ).loadMore();
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }

              final tx = paginatedList.items[index];
              return TransactionListTile(transaction: tx);
            },
          ),
        );
      },
    );
  }
}
```

### 3. 过滤器状态管理

```dart
@riverpod
class TransactionFilter extends _$TransactionFilter {
  @override
  TransactionFilterState build() {
    return TransactionFilterState.initial();
  }

  void setLedgerType(LedgerType? type) {
    state = state.copyWith(ledgerType: type);
    _notifyFilterChanged();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(startDate: start, endDate: end);
    _notifyFilterChanged();
  }

  void setCategory(String? categoryId) {
    state = state.copyWith(categoryId: categoryId);
    _notifyFilterChanged();
  }

  void reset() {
    state = TransactionFilterState.initial();
    _notifyFilterChanged();
  }

  void _notifyFilterChanged() {
    // 刷新交易列表
    ref.invalidate(transactionListProvider);
  }
}

@freezed
class TransactionFilterState with _$TransactionFilterState {
  const factory TransactionFilterState({
    LedgerType? ledgerType,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) = _TransactionFilterState;

  factory TransactionFilterState.initial() {
    return const TransactionFilterState();
  }
}
```

### 4. 全局应用状态

```dart
@riverpod
class AppState extends _$AppState {
  @override
  AppStateData build() {
    return AppStateData.initial();
  }

  // 设置当前账本
  void setCurrentBook(String bookId) {
    state = state.copyWith(currentBookId: bookId);
  }

  // 切换主题
  void toggleTheme() {
    state = state.copyWith(
      isDarkMode: !state.isDarkMode,
    );
  }

  // 设置语言
  void setLocale(Locale locale) {
    state = state.copyWith(locale: locale);
  }
}

@freezed
class AppStateData with _$AppStateData {
  const factory AppStateData({
    String? currentBookId,
    @Default(false) bool isDarkMode,
    @Default(Locale('zh', 'CN')) Locale locale,
    @Default(false) bool isLocked,
  }) = _AppStateData;

  factory AppStateData.initial() {
    return const AppStateData();
  }
}
```

---

## 依赖注入

### 自动依赖注入

Riverpod自动管理依赖关系：

```dart
// 依赖链：
// TransactionList → TransactionRepository → Database

@riverpod
class TransactionList extends _$TransactionList {
  @override
  Future<List<Transaction>> build({required String bookId}) async {
    // ref.watch会自动获取依赖
    final repo = ref.watch(transactionRepositoryProvider);
    return repo.getTransactions(bookId: bookId);
  }
}

// TransactionRepository依赖Database
@riverpod
TransactionRepository transactionRepository(TransactionRepositoryRef ref) {
  final db = ref.watch(databaseProvider);  // 自动注入
  return TransactionRepositoryImpl(db);
}
```

### 覆盖Provider（测试用）

```dart
void main() {
  testWidgets('测试交易列表', (tester) async {
    // Mock Repository
    final mockRepo = MockTransactionRepository();
    when(mockRepo.getTransactions(bookId: 'test'))
      .thenAnswer((_) async => [
        Transaction(...),
      ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // 覆盖真实Provider
          transactionRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MyApp(),
      ),
    );

    // 测试...
  });
}
```

---

## 最佳实践

### 1. Provider命名规范

```dart
// ✅ 好的命名
@riverpod
AppDatabase database(DatabaseRef ref) { ... }

@riverpod
TransactionRepository transactionRepository(TransactionRepositoryRef ref) { ... }

@riverpod
class TransactionList extends _$TransactionList { ... }

// ❌ 避免
@riverpod
AppDatabase db(DbRef ref) { ... }  // 太短

@riverpod
TransactionRepository getRepo(GetRepoRef ref) { ... }  // 动词前缀不必要
```

### 2. 状态最小化

```dart
// ✅ 好的实践：状态最小化
@riverpod
class TransactionForm extends _$TransactionForm {
  @override
  TransactionFormState build() {
    return TransactionFormState(amount: 0, categoryId: '');
  }
}

// ❌ 避免：存储派生状态
class TransactionFormState {
  final int amount;
  final String categoryId;
  final String formattedAmount;  // ❌ 可从amount派生
  final bool isValid;  // ❌ 可从amount和categoryId计算
}
```

### 3. 使用AsyncValue处理异步

```dart
// ✅ 好的实践：使用when处理所有状态
@override
Widget build(BuildContext context, WidgetRef ref) {
  final transactionsAsync = ref.watch(transactionListProvider(bookId: 'xxx'));

  return transactionsAsync.when(
    loading: () => const CircularProgressIndicator(),
    error: (err, stack) => ErrorWidget(error: err),
    data: (transactions) => ListView(...),
  );
}

// ❌ 避免：只处理data状态
@override
Widget build(BuildContext context, WidgetRef ref) {
  final transactions = ref.watch(transactionListProvider(bookId: 'xxx')).value;
  return ListView(...);  // ❌ loading和error未处理
}
```

### 4. 使用ref.listen监听变化

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // 监听同步状态变化
  ref.listen<AsyncValue<SyncStatus>>(
    syncStatusProvider,
    (previous, next) {
      next.whenData((status) {
        if (status == SyncStatus.completed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('同步完成')),
          );
        }
      });
    },
  );

  return Scaffold(...);
}
```

### 5. 缓存控制

```dart
// 短期缓存（60秒）
@riverpod
Future<List<Category>> categories(CategoriesRef ref) async {
  ref.cacheFor(const Duration(seconds: 60));

  final repo = ref.watch(categoryRepositoryProvider);
  return repo.findAll();
}

// 长期缓存（keepAlive）
@Riverpod(keepAlive: true)
AppDatabase database(DatabaseRef ref) {
  return AppDatabase();
}
```

### 6. 家族Provider（Family）

```dart
// 为每个bookId创建独立的Provider实例
@riverpod
Future<Book> book(BookRef ref, String bookId) async {
  final repo = ref.watch(bookRepositoryProvider);
  return repo.findById(bookId);
}

// 使用
Widget build(BuildContext context, WidgetRef ref) {
  final book = ref.watch(bookProvider('book_123'));
  return Text(book.value?.name ?? '');
}
```

---

## 测试策略

### 1. 单元测试Provider

```dart
void main() {
  test('TransactionForm验证逻辑', () {
    final container = ProviderContainer();
    final formNotifier = container.read(transactionFormProvider.notifier);

    // 测试验证
    formNotifier.updateAmount(0);
    expect(formNotifier.validate(), false);

    formNotifier.updateAmount(100);
    formNotifier.updateCategory('cat_food');
    expect(formNotifier.validate(), true);

    container.dispose();
  });
}
```

### 2. Widget测试

```dart
void main() {
  testWidgets('显示交易列表', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: TransactionListScreen(),
        ),
      ),
    );

    // 等待异步加载
    await tester.pumpAndSettle();

    // 验证
    expect(find.byType(TransactionListTile), findsWidgets);
  });
}
```

### 3. Mock Provider

```dart
void main() {
  testWidgets('测试表单提交', (tester) async {
    // Mock UseCase
    final mockUseCase = MockCreateTransactionUseCase();
    when(mockUseCase.execute(any))
      .thenAnswer((_) async => Result.success(Transaction(...)));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          createTransactionUseCaseProvider.overrideWithValue(mockUseCase),
        ],
        child: MaterialApp(
          home: TransactionFormScreen(),
        ),
      ),
    );

    // 填写表单
    await tester.enterText(find.byType(AmountInput), '100');
    await tester.tap(find.byType(CategorySelector));
    await tester.pumpAndSettle();

    // 提交
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    // 验证
    verify(mockUseCase.execute(any)).called(1);
  });
}
```

---

## 总结

Happy Pocket状态管理架构的核心特点：

1. **类型安全**: Riverpod提供编译时类型检查
2. **自动依赖注入**: 简化代码，提高可测试性
3. **清晰的层次**: Provider分层组织，职责明确
4. **响应式更新**: 自动追踪依赖，高效更新UI
5. **易于测试**: 简单的Mock和覆盖机制
6. **DevTools支持**: 强大的调试工具

**下一步阅读**:
- [05_Integration_Patterns.md](./05_Integration_Patterns.md) - 集成模式设计
- [14_ADR_State_Management.md](./14_ADR_State_Management.md) - Riverpod选型决策

---

**文档维护**:
- 最后更新: 2026-02-03
- 维护者: 架构团队
- 版本: 1.0
