# ADR-001: 选择Riverpod作为状态管理方案

**状态:** ✅ 已接受
**日期:** 2026-02-03
**决策者:** 技术架构团队
**影响范围:** 整个应用的状态管理层

---

## 背景与问题陈述

Home Pocket应用需要一个健壮的状态管理解决方案,用于处理以下场景:

### 业务需求
- 复杂的应用状态(交易列表、账本、用户设置等)
- 异步数据获取(数据库查询、文件I/O)
- 跨组件状态共享(当前账本、过滤器状态)
- 状态的可测试性和可维护性

### 技术要求
- 类型安全(编译时检查)
- 依赖注入支持
- DevTools调试支持
- 易于测试和Mock
- 学习曲线适中
- 社区支持活跃

---

## 决策驱动因素

### 关键考虑因素
1. **类型安全性** - Flutter/Dart的强类型特性需要充分利用
2. **可测试性** - 单元测试和Widget测试必须简单易行
3. **开发效率** - 减少样板代码,提高开发速度
4. **可维护性** - 清晰的代码结构,易于理解和修改
5. **性能** - 高效的状态更新和重建机制
6. **团队熟悉度** - 团队成员的学习成本

---

## 备选方案分析

### 方案1: flutter_riverpod 2.x ✅ (选择)

**优势:**
- ✅ **编译时类型安全** - 强类型Provider,减少运行时错误
- ✅ **编译时依赖注入** - 自动管理依赖关系
- ✅ **优秀的DevTools支持** - 可视化状态树,时间旅行调试
- ✅ **自动资源清理** - 自动dispose,防止内存泄漏
- ✅ **测试友好** - ProviderScope覆盖,易于Mock
- ✅ **代码生成支持** - riverpod_generator减少样板代码
- ✅ **学习曲线适中** - 概念清晰,文档完善
- ✅ **活跃的社区** - Remi Rousselet维护,社区响应快

**劣势:**
- ⚠️ 需要学习新概念(Provider、Ref等)
- ⚠️ 代码生成增加构建时间(可接受)

**性能:**
- 优秀的性能优化(细粒度更新)
- 自动缓存和懒加载
- 最小化rebuild

**代码示例:**
```dart
@riverpod
class TransactionList extends _$TransactionList {
  @override
  Future<List<Transaction>> build({required String bookId}) async {
    final repository = ref.watch(transactionRepositoryProvider);
    return repository.getTransactions(bookId: bookId);
  }

  Future<void> addTransaction(Transaction tx) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(transactionRepositoryProvider).insert(tx);
      return build(bookId: tx.bookId);
    });
  }
}
```

---

### 方案2: flutter_bloc 8.x

**优势:**
- ✅ 强类型,类型安全
- ✅ 清晰的单向数据流(Event → State)
- ✅ 优秀的DevTools支持
- ✅ 成熟的社区和生态

**劣势:**
- ❌ **样板代码多** - 需要定义Event、State、Bloc类
- ❌ **依赖注入手动管理** - 需要BlocProvider树
- ❌ **学习曲线陡峭** - Stream、Bloc概念较复杂
- ❌ 代码冗长,不够简洁

**代码示例:**
```dart
// Event
abstract class TransactionEvent {}
class LoadTransactions extends TransactionEvent {
  final String bookId;
  LoadTransactions(this.bookId);
}
class AddTransaction extends TransactionEvent {
  final Transaction transaction;
  AddTransaction(this.transaction);
}

// State
abstract class TransactionState {}
class TransactionInitial extends TransactionState {}
class TransactionLoading extends TransactionState {}
class TransactionLoaded extends TransactionState {
  final List<Transaction> transactions;
  TransactionLoaded(this.transactions);
}
class TransactionError extends TransactionState {
  final String message;
  TransactionError(this.message);
}

// Bloc
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository repository;

  TransactionBloc(this.repository) : super(TransactionInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<AddTransaction>(_onAddTransaction);
  }

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      final transactions = await repository.getTransactions(bookId: event.bookId);
      emit(TransactionLoaded(transactions));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  // ...
}
```

**为何不选择:**
- 样板代码量是Riverpod的3-4倍
- 依赖注入需要手动管理BlocProvider
- 对于我们的场景,Stream的复杂性是不必要的

---

### 方案3: GetX 4.x

**优势:**
- ✅ 学习曲线平缓
- ✅ 样板代码少
- ✅ 集成路由、状态管理、依赖注入

**劣势:**
- ❌ **类型安全性差** - 使用Get.find<T>()动态获取
- ❌ **全局状态污染** - 单例模式,难以隔离
- ❌ **测试困难** - 全局状态难以Mock
- ❌ **DevTools支持弱** - 调试工具有限
- ❌ **社区分歧** - 部分开发者不推荐

**代码示例:**
```dart
class TransactionController extends GetxController {
  final TransactionRepository repository;
  TransactionController(this.repository);

  final transactions = <Transaction>[].obs;
  final isLoading = false.obs;

  Future<void> loadTransactions(String bookId) async {
    isLoading.value = true;
    try {
      transactions.value = await repository.getTransactions(bookId: bookId);
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}

// 使用
final controller = Get.find<TransactionController>();
```

**为何不选择:**
- 类型安全性不足,容易引入运行时错误
- 全局状态难以测试
- 不符合Flutter官方推荐的最佳实践

---

### 方案4: Provider 6.x

**优势:**
- ✅ Flutter官方推荐
- ✅ 简单易学
- ✅ 社区支持好

**劣势:**
- ❌ **功能较弱** - 缺少很多Riverpod的高级特性
- ❌ **类型安全性一般** - 需要BuildContext
- ❌ **依赖BuildContext** - 限制了使用场景
- ❌ **已被Riverpod取代** - Riverpod是Provider 2.0

**为何不选择:**
- Riverpod是Provider的进化版,功能更强大
- 官方推荐迁移到Riverpod

---

## 决策对比矩阵

| 特性 | Riverpod | Bloc | GetX | Provider |
|------|----------|------|------|----------|
| 类型安全 | ✅✅✅ | ✅✅✅ | ⚠️ | ✅✅ |
| 编译时DI | ✅✅✅ | ⚠️ | ✅✅ | ⚠️ |
| 测试性 | ✅✅✅ | ✅✅✅ | ⚠️ | ✅✅ |
| DevTools | ✅✅✅ | ✅✅✅ | ⚠️ | ✅✅ |
| 学习曲线 | ✅✅ | ⚠️ | ✅✅✅ | ✅✅✅ |
| 样板代码 | ✅✅✅ | ⚠️ | ✅✅✅ | ✅✅ |
| 社区支持 | ✅✅✅ | ✅✅✅ | ✅✅ | ✅✅✅ |
| 性能 | ✅✅✅ | ✅✅ | ✅✅ | ✅✅ |

**图例:**
- ✅✅✅ 优秀
- ✅✅ 良好
- ✅ 一般
- ⚠️ 较差

---

## 最终决策

**选择 Riverpod 2.x 作为状态管理方案**

### 核心理由

1. **编译时类型安全** - 最大化利用Dart的类型系统
2. **开发效率高** - 代码生成减少样板代码,比Bloc简洁3-4倍
3. **测试友好** - ProviderScope覆盖机制简化测试
4. **自动依赖注入** - 无需手动管理Provider树
5. **优秀的DevTools** - 可视化调试,提高开发效率
6. **活跃的维护** - Remi Rousselet(Provider作者)亲自维护

### 实施计划

**Phase 1: 基础设施搭建(Week 1)**
```yaml
dependencies:
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0

dev_dependencies:
  riverpod_generator: ^2.3.0
  build_runner: ^2.4.0
```

**Phase 2: Provider分层(Week 2)**
```
lib/
  ├── core/providers/          # 核心Provider(数据库、密钥管理)
  ├── features/
  │   ├── accounting/providers/
  │   ├── sync/providers/
  │   └── ...
  └── shared/providers/        # 共享Provider(当前账本、主题等)
```

**Phase 3: 团队培训(Week 1-2)**
- Riverpod核心概念培训
- 代码生成工具使用
- 最佳实践分享
- Code Review规范

---

## 后果分析

### 正面影响

1. **代码质量提升**
   - 编译时类型检查减少bug
   - 清晰的Provider分层提高可维护性

2. **开发效率提升**
   - 代码生成减少手写代码
   - 自动依赖注入简化架构

3. **测试覆盖率提升**
   - 易于Mock的Provider
   - 简单的测试用例编写

4. **团队协作改善**
   - 统一的状态管理模式
   - 清晰的代码结构

### 负面影响

1. **学习成本**
   - 团队需要学习Riverpod概念(约1-2周)
   - 代码生成工具的使用

   **缓解措施:**
   - 提供内部培训
   - 编写最佳实践文档
   - Code Review帮助团队成长

2. **构建时间增加**
   - 代码生成增加build_runner时间(约5-10秒)

   **缓解措施:**
   - 使用增量构建
   - 开发时使用watch模式

3. **生态系统依赖**
   - 依赖第三方库(Riverpod)

   **缓解措施:**
   - Riverpod维护活跃,风险低
   - 如需切换,接口抽象降低迁移成本

---

## 实施示例

### 基础Provider定义

```dart
// lib/core/providers/database_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
AppDatabase database(DatabaseRef ref) {
  final db = AppDatabase();

  ref.onDispose(() {
    db.close();
  });

  return db;
}
```

### Repository Provider

```dart
// lib/features/accounting/providers/transaction_repository_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transaction_repository_provider.g.dart';

@Riverpod(keepAlive: true)
TransactionRepository transactionRepository(TransactionRepositoryRef ref) {
  return TransactionRepositoryImpl(
    db: ref.watch(databaseProvider),
    fieldEncryption: ref.watch(fieldEncryptionProvider),
  );
}
```

### 状态Provider

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
  }) async {
    final repo = ref.watch(transactionRepositoryProvider);
    return repo.getTransactions(
      bookId: bookId,
      ledgerType: filterLedger,
    );
  }

  Future<void> addTransaction(Transaction tx) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(transactionRepositoryProvider);
      await repo.insert(tx);
      return build(bookId: tx.bookId, filterLedger: filterLedger);
    });
  }
}
```

### UI使用

```dart
class TransactionListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookId = ref.watch(currentBookIdProvider);
    final transactionsAsync = ref.watch(
      transactionListProvider(bookId: bookId),
    );

    return transactionsAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => ErrorWidget(error: err),
      data: (transactions) => ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          return TransactionTile(transaction: transactions[index]);
        },
      ),
    );
  }
}
```

---

## 相关决策

- **ADR-005:** Use Case模式与Provider集成
- **ADR-006:** 测试策略(Provider覆盖和Mock)

---

## 参考资料

### 官方文档
- [Riverpod官方文档](https://riverpod.dev/)
- [Riverpod Generator](https://pub.dev/packages/riverpod_generator)
- [Flutter状态管理指南](https://docs.flutter.dev/development/data-and-backend/state-mgmt/intro)

### 社区资源
- [Riverpod示例项目](https://github.com/rrousselGit/riverpod/tree/master/examples)
- [Flutter状态管理对比](https://medium.com/flutter-community/state-management-comparison)

### 最佳实践
- [Riverpod最佳实践](https://codewithandrea.com/articles/flutter-state-management-riverpod/)
- [Clean Architecture + Riverpod](https://resocoder.com/flutter-clean-architecture-riverpod/)

---

## 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|---------|------|
| 2026-02-03 | 1.0 | 初始版本 | 架构团队 |

---

**文档维护者:** 技术架构团队
**审核者:** CTO, 技术负责人
**下次Review日期:** 2026-08-03 (6个月后)
