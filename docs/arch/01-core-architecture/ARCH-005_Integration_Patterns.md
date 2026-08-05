# Happy Pocket MVP - 集成模式设计

**文档版本:** 1.0
**创建日期:** 2026-02-03
**状态:** 完成
**作者:** Claude Sonnet 4.5 + senior-architect

---

## 📋 目录

1. [概述](#概述)
2. [Repository模式](#repository模式)
3. [Use Case模式](#use-case模式)
4. [CRDT同步模式](#crdt同步模式)
5. [事件总线模式](#事件总线模式)
6. [错误处理模式](#错误处理模式)
7. [性能优化模式](#性能优化模式)

---

## 概述

### 集成模式目标

Happy Pocket的集成模式设计旨在：

1. **解耦**: 各层之间低耦合，高内聚
2. **可测试**: 易于Mock和单元测试
3. **可维护**: 清晰的职责划分
4. **可扩展**: 易于添加新功能
5. **类型安全**: 编译时类型检查

### 架构分层

```
Presentation Layer (展示层)
      ↓ 调用
Business Logic Layer (业务逻辑层)
      ↓ 依赖
Domain Layer (领域层)
      ↑ 实现
Data Layer (数据层)
      ↑ 使用
Infrastructure Layer (基础设施层)
```

---

## Repository模式

> **概念说明:** Repository模式的详细设计理念和架构决策请参见 [ARCH-002_Data_Architecture.md](./ARCH-002_Data_Architecture.md)。
> 本节聚焦于集成代码示例。

### 接口定义（Domain层）

```dart
// lib/features/accounting/domain/repositories/transaction_repository.dart  (Domain 层接口)

abstract class TransactionRepository {
  /// 插入交易
  Future<void> insert(Transaction transaction);

  /// 更新交易
  Future<void> update(Transaction transaction);

  /// 删除交易（软删除）
  Future<void> delete(String transactionId);

  /// 根据ID查找交易
  Future<Transaction?> findById(String transactionId);

  /// 查询交易列表
  Future<List<Transaction>> getTransactions({
    required String bookId,
    LedgerType? ledgerType,
    List<String>? categoryIds,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  });

  /// 获取账本的最新交易（用于哈希链）
  Future<Transaction?> getLatestTransaction(String bookId);

  /// 获取交易总数
  Future<int> getTransactionCount({
    required String bookId,
    LedgerType? ledgerType,
  });

  /// 批量插入（用于同步）
  Future<void> insertBatch(List<Transaction> transactions);

  /// 更新账本余额统计（冗余字段）
  @Deprecated('使用 recalculateBalance() 替代')
  Future<void> updateBookBalance(String bookId);

  /// 重新计算账本余额（用于修复不一致，ADR-008）
  Future<void> recalculateBalance(String bookId);

  /// 校验账本余额是否正确 (ADR-008)
  Future<bool> verifyBalance(String bookId);

  /// 批量删除交易 (ADR-008)
  Future<void> deleteBatch(List<String> transactionIds);

  /// 完整性验证（哈希链验证）
  Future<bool> verifyIntegrity(String bookId);
}
```

### 实现（Data层）

```dart
// lib/data/repositories/transaction_repository_impl.dart

import 'package:drift/drift.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final AppDatabase _db;
  final FieldEncryption _fieldEncryption;
  final HashChainService _hashChainService;

  TransactionRepositoryImpl({
    required AppDatabase db,
    required FieldEncryption fieldEncryption,
    required HashChainService hashChainService,
  })  : _db = db,
        _fieldEncryption = fieldEncryption,
        _hashChainService = hashChainService;

  @override
  Future<void> insert(Transaction transaction) async {
    // 使用数据库事务确保原子性 (ADR-008)
    await _db.transaction(() async {
      // 1. 加密敏感字段
      String? encryptedNote;
      if (transaction.note != null && transaction.note!.isNotEmpty) {
        encryptedNote = await _fieldEncryption.encrypt(transaction.note!);
      }

      // 2. 转换为Drift实体
      final entity = _toEntity(transaction.copyWith(note: encryptedNote));

      // 3. 插入数据库
      await _db.into(_db.transactions).insert(entity);

      // 4. 增量更新账本余额 (ADR-008)
      await _incrementBalance(
        bookId: transaction.bookId,
        ledgerType: transaction.ledgerType,
        amount: transaction.amount,
        increment: 1,
      );
    });
  }

  @override
  Future<void> update(Transaction transaction) async {
    await _db.transaction(() async {
      // 1. 查询原交易信息（用于计算余额差值）
      final oldTx = await findById(transaction.id);
      if (oldTx == null) {
        throw Exception('Transaction not found: ${transaction.id}');
      }

      // 2. 加密敏感字段
      String? encryptedNote;
      if (transaction.note != null && transaction.note!.isNotEmpty) {
        encryptedNote = await _fieldEncryption.encrypt(transaction.note!);
      }

      // 3. 更新数据库
      final entity = _toEntity(transaction.copyWith(note: encryptedNote));
      await (_db.update(_db.transactions)
            ..where((t) => t.id.equals(transaction.id)))
          .write(entity);

      // 4. 增量更新余额（处理金额或账本类型变化）
      if (oldTx.amount != transaction.amount ||
          oldTx.ledgerType != transaction.ledgerType) {
        // 先减去旧值
        await _incrementBalance(
          bookId: oldTx.bookId,
          ledgerType: oldTx.ledgerType,
          amount: -oldTx.amount,
          increment: 0,
        );
        // 再加上新值
        await _incrementBalance(
          bookId: transaction.bookId,
          ledgerType: transaction.ledgerType,
          amount: transaction.amount,
          increment: 0,
        );
      }
    });
  }

  @override
  Future<void> delete(String transactionId) async {
    await _db.transaction(() async {
      // 1. 查询交易信息（需要知道金额和账本类型）
      final tx = await findById(transactionId);
      if (tx == null) return;

      // 2. 软删除
      await (_db.update(_db.transactions)
            ..where((t) => t.id.equals(transactionId)))
          .write(const TransactionsCompanion(
            isDeleted: Value(true),
            updatedAt: Value(DateTime.now()),
          ));

      // 3. 减量更新余额 (ADR-008)
      await _incrementBalance(
        bookId: tx.bookId,
        ledgerType: tx.ledgerType,
        amount: -tx.amount,  // 负数表示减少
        increment: -1,       // 交易数量-1
      );
    });
  }

  @override
  Future<Transaction?> findById(String transactionId) async {
    final entity = await (_db.select(_db.transactions)
          ..where((t) => t.id.equals(transactionId)))
        .getSingleOrNull();

    if (entity == null) return null;

    return await _toModel(entity);
  }

  @override
  Future<List<Transaction>> getTransactions({
    required String bookId,
    LedgerType? ledgerType,
    List<String>? categoryIds,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    // 构建查询
    var query = _db.select(_db.transactions)
      ..where((t) => t.bookId.equals(bookId))
      ..where((t) => t.isDeleted.equals(false));

    // 应用过滤器
    if (ledgerType != null) {
      query.where((t) => t.ledgerType.equals(ledgerType.name));
    }

    if (categoryIds != null && categoryIds.isNotEmpty) {
      query.where((t) => t.categoryId.isIn(categoryIds));
    }

    if (startDate != null) {
      query.where((t) => t.timestamp.isBiggerOrEqualValue(startDate));
    }

    if (endDate != null) {
      query.where((t) => t.timestamp.isSmallerThanValue(endDate));
    }

    // 排序和分页
    query
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
      ..limit(limit, offset: offset);

    // 执行查询
    final entities = await query.get();

    // 转换为领域模型（并解密）
    return Future.wait(entities.map(_toModel));
  }

  @override
  Future<Transaction?> getLatestTransaction(String bookId) async {
    final entity = await (_db.select(_db.transactions)
          ..where((t) => t.bookId.equals(bookId))
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .getSingleOrNull();

    if (entity == null) return null;

    return await _toModel(entity);
  }

  @override
  Future<int> getTransactionCount({
    required String bookId,
    LedgerType? ledgerType,
  }) async {
    var query = _db.selectOnly(_db.transactions)
      ..where(_db.transactions.bookId.equals(bookId))
      ..where(_db.transactions.isDeleted.equals(false))
      ..addColumns([_db.transactions.id.count()]);

    if (ledgerType != null) {
      query.where(_db.transactions.ledgerType.equals(ledgerType.name));
    }

    final result = await query.getSingle();
    return result.read(_db.transactions.id.count()) ?? 0;
  }

  @override
  Future<void> insertBatch(List<Transaction> transactions) async {
    await _db.transaction(() async {
      // 1. 批量插入交易
      await _db.batch((batch) {
        for (final tx in transactions) {
          final entity = _toEntity(tx);
          batch.insert(_db.transactions, entity);
        }
      });

      // 2. 按账本分组计算增量 (ADR-008: 批量优化)
      final balanceDeltas = <String, _BalanceDelta>{};
      for (final tx in transactions) {
        final delta = balanceDeltas.putIfAbsent(
          tx.bookId,
          () => _BalanceDelta(),
        );

        if (tx.ledgerType == LedgerType.survival) {
          delta.survivalDelta += tx.amount;
        } else if (tx.ledgerType == LedgerType.soul) {
          delta.soulDelta += tx.amount;
        }
        delta.countDelta++;
      }

      // 3. 批量更新余额
      for (final entry in balanceDeltas.entries) {
        await _incrementBalance(
          bookId: entry.key,
          survivalDelta: entry.value.survivalDelta,
          soulDelta: entry.value.soulDelta,
          countDelta: entry.value.countDelta,
        );
      }
    });
  }

  /// 增量更新账本余额 (ADR-008: 性能优化)
  ///
  /// 使用增量更新而非全量计算，性能提升 40-400 倍
  Future<void> _incrementBalance({
    required String bookId,
    LedgerType? ledgerType,
    int? amount,
    int? increment,
    int? survivalDelta,
    int? soulDelta,
    int? countDelta,
  }) async {
    // 获取当前账本信息
    final book = await (_db.select(_db.books)
          ..where((b) => b.id.equals(bookId)))
        .getSingle();

    // 计算新余额
    final newSurvivalBalance = survivalDelta != null
        ? book.survivalBalance + survivalDelta
        : (ledgerType == LedgerType.survival && amount != null
            ? book.survivalBalance + amount
            : book.survivalBalance);

    final newSoulBalance = soulDelta != null
        ? book.soulBalance + soulDelta
        : (ledgerType == LedgerType.soul && amount != null
            ? book.soulBalance + amount
            : book.soulBalance);

    final newTxCount = countDelta != null
        ? book.transactionCount + countDelta
        : (increment != null
            ? book.transactionCount + increment
            : book.transactionCount);

    // 更新数据库
    await (_db.update(_db.books)..where((b) => b.id.equals(bookId))).write(
      BooksCompanion(
        survivalBalance: Value(newSurvivalBalance),
        soulBalance: Value(newSoulBalance),
        transactionCount: Value(newTxCount),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  @Deprecated('使用 recalculateBalance() 替代。保留用于兼容性。')
  Future<void> updateBookBalance(String bookId) async {
    await recalculateBalance(bookId);
  }

  @override
  Future<void> recalculateBalance(String bookId) async {
    // 全量重新计算余额（用于修复不一致，ADR-008）
    await _db.transaction(() async {
      final survivalBalance = await _calculateBalance(
        bookId: bookId,
        ledgerType: LedgerType.survival,
      );

      final soulBalance = await _calculateBalance(
        bookId: bookId,
        ledgerType: LedgerType.soul,
      );

      final txCount = await getTransactionCount(bookId: bookId);

      await (_db.update(_db.books)..where((b) => b.id.equals(bookId))).write(
        BooksCompanion(
          survivalBalance: Value(survivalBalance),
          soulBalance: Value(soulBalance),
          transactionCount: Value(txCount),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<bool> verifyBalance(String bookId) async {
    // 校验账本余额是否正确 (ADR-008)
    final book = await (_db.select(_db.books)
          ..where((b) => b.id.equals(bookId)))
        .getSingle();

    // 重新计算实际余额
    final actualSurvivalBalance = await _calculateBalance(
      bookId: bookId,
      ledgerType: LedgerType.survival,
    );

    final actualSoulBalance = await _calculateBalance(
      bookId: bookId,
      ledgerType: LedgerType.soul,
    );

    final actualTxCount = await getTransactionCount(bookId: bookId);

    // 对比
    return book.survivalBalance == actualSurvivalBalance &&
           book.soulBalance == actualSoulBalance &&
           book.transactionCount == actualTxCount;
  }

  @override
  Future<void> deleteBatch(List<String> transactionIds) async {
    // 批量删除交易 (ADR-008)
    await _db.transaction(() async {
      // 1. 批量查询交易信息
      final transactions = await (_db.select(_db.transactions)
            ..where((t) => t.id.isIn(transactionIds)))
          .get();

      // 2. 批量软删除
      await _db.batch((batch) {
        for (final txId in transactionIds) {
          batch.update(
            _db.transactions,
            const TransactionsCompanion(
              isDeleted: Value(true),
              updatedAt: Value(DateTime.now()),
            ),
            where: (_) => _db.transactions.id.equals(txId),
          );
        }
      });

      // 3. 按账本分组，批量更新余额
      final balanceDeltas = <String, _BalanceDelta>{};
      for (final tx in transactions) {
        final delta = balanceDeltas.putIfAbsent(
          tx.bookId,
          () => _BalanceDelta(),
        );

        if (tx.ledgerType == 'survival') {
          delta.survivalDelta -= tx.amount;
        } else if (tx.ledgerType == 'soul') {
          delta.soulDelta -= tx.amount;
        }
        delta.countDelta--;
      }

      for (final entry in balanceDeltas.entries) {
        await _incrementBalance(
          bookId: entry.key,
          survivalDelta: entry.value.survivalDelta,
          soulDelta: entry.value.soulDelta,
          countDelta: entry.value.countDelta,
        );
      }
    });
  }

  @override
  Future<bool> verifyIntegrity(String bookId) async {
    final result = await _hashChainService.verifyHashChain(
      bookId: bookId,
      repo: this,
    );
    return result.isValid;
  }

  /// 计算账本余额
  Future<int> _calculateBalance({
    required String bookId,
    required LedgerType ledgerType,
  }) async {
    final query = _db.selectOnly(_db.transactions)
      ..where(_db.transactions.bookId.equals(bookId))
      ..where(_db.transactions.ledgerType.equals(ledgerType.name))
      ..where(_db.transactions.isDeleted.equals(false))
      ..addColumns([_db.transactions.amount.sum()]);

    final result = await query.getSingle();
    return result.read(_db.transactions.amount.sum()) ?? 0;
  }

  /// 实体转模型
  Future<Transaction> _toModel(TransactionEntity entity) async {
    // 解密note字段
    String? decryptedNote;
    if (entity.note != null && entity.note!.isNotEmpty) {
      decryptedNote = await _fieldEncryption.decrypt(entity.note!);
    }

    return Transaction(
      id: entity.id,
      bookId: entity.bookId,
      deviceId: entity.deviceId,
      amount: entity.amount,
      type: TransactionType.values.byName(entity.type),
      categoryId: entity.categoryId,
      ledgerType: LedgerType.values.byName(entity.ledgerType),
      timestamp: entity.timestamp,
      note: decryptedNote,
      photoHash: entity.photoHash,
      merchant: entity.merchant,
      metadata: entity.metadata != null
          ? jsonDecode(entity.metadata!) as Map<String, dynamic>
          : null,
      prevHash: entity.prevHash,
      currentHash: entity.currentHash,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isPrivate: entity.isPrivate,
      isSynced: entity.isSynced,
      isDeleted: entity.isDeleted,
    );
  }

  /// 模型转实体
  TransactionsCompanion _toEntity(Transaction model) {
    return TransactionsCompanion.insert(
      id: model.id,
      bookId: model.bookId,
      deviceId: model.deviceId,
      amount: model.amount,
      type: model.type.name,
      categoryId: model.categoryId,
      ledgerType: model.ledgerType.name,
      timestamp: model.timestamp,
      note: Value(model.note),
      photoHash: Value(model.photoHash),
      merchant: Value(model.merchant),
      metadata: Value(
        model.metadata != null ? jsonEncode(model.metadata) : null,
      ),
      prevHash: Value(model.prevHash),
      currentHash: model.currentHash,
      createdAt: model.createdAt,
      updatedAt: Value(model.updatedAt),
      isPrivate: Value(model.isPrivate),
      isSynced: Value(model.isSynced),
      isDeleted: Value(model.isDeleted),
    );
  }
}

/// 批量余额增量计算辅助类 (ADR-008)
class _BalanceDelta {
  int survivalDelta = 0;
  int soulDelta = 0;
  int countDelta = 0;
}
```

### Provider集成

```dart
// lib/features/accounting/presentation/providers/repository_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transaction_repository_provider.g.dart';

@Riverpod(keepAlive: true)
TransactionRepository transactionRepository(TransactionRepositoryRef ref) {
  return TransactionRepositoryImpl(
    db: ref.watch(databaseProvider),
    fieldEncryption: ref.watch(fieldEncryptionProvider),
    hashChainService: ref.watch(hashChainServiceProvider),
  );
}
```

---

## Use Case模式

### 设计理念

Use Case（用例）封装业务逻辑，代表一个具体的用户操作。

**优势**:
- 单一职责，一个Use Case处理一个业务场景
- 可复用业务逻辑
- 易于测试
- 清晰的业务流程

### Use Case基类

```dart
// lib/shared/utils/use_case.dart

/// Use Case基类
abstract class UseCase<T, P> {
  /// 执行用例
  Future<Result<T>> execute(P params);
}

/// 无参数Use Case
abstract class NoParamsUseCase<T> {
  Future<Result<T>> execute();
}

/// Result类型（用于统一错误处理）
class Result<T> {
  final T? data;
  final String? error;

  Result._({this.data, this.error});

  factory Result.success(T data) => Result._(data: data);
  factory Result.error(String error) => Result._(error: error);

  bool get isSuccess => error == null;
  bool get isError => error != null;

  /// 转换数据
  Result<R> map<R>(R Function(T data) transform) {
    if (isSuccess) {
      return Result.success(transform(data!));
    } else {
      return Result.error(error!);
    }
  }

  /// 处理结果
  R when<R>({
    required R Function(T data) success,
    required R Function(String error) error,
  }) {
    if (isSuccess) {
      return success(data!);
    } else {
      return this.error(this.error!);
    }
  }
}
```

### 具体Use Case示例

#### 创建交易Use Case

```dart
// lib/application/accounting/create_transaction_use_case.dart

class CreateTransactionUseCase implements UseCase<Transaction, CreateTransactionParams> {
  final TransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;
  final ClassificationService _classificationService;
  final FieldEncryption _fieldEncryption;
  final HashChainService _hashChainService;

  CreateTransactionUseCase({
    required TransactionRepository transactionRepo,
    required CategoryRepository categoryRepo,
    required ClassificationService classificationService,
    required FieldEncryption fieldEncryption,
    required HashChainService hashChainService,
  })  : _transactionRepo = transactionRepo,
        _categoryRepo = categoryRepo,
        _classificationService = classificationService,
        _fieldEncryption = fieldEncryption,
        _hashChainService = hashChainService;

  @override
  Future<Result<Transaction>> execute(CreateTransactionParams params) async {
    try {
      // 1. 验证输入
      final validation = _validate(params);
      if (!validation.isSuccess) {
        return validation.map((_) => throw Exception());  // 不会执行
      }

      // 2. 获取分类信息
      final category = await _categoryRepo.findById(params.categoryId);
      if (category == null) {
        return Result.error('分类不存在');
      }

      // 3. 智能分类（三层引擎）
      final ledgerType = await _classificationService.classifyLedgerType(
        categoryId: params.categoryId,
        merchant: params.merchant,
        note: params.note,
      );

      // 4. 处理照片（如果有）
      String? photoHash;
      if (params.photoFile != null) {
        final encryptedPhoto = await FileEncryption.encryptFile(
          params.photoFile!,
        );
        photoHash = await HashChainService.hashFile(encryptedPhoto);
      }

      // 5. 获取前一笔交易哈希
      final prevHash = await _hashChainService.getLatestHash(params.bookId);

      // 6. 创建交易对象
      final deviceId = await DeviceManager.instance.getCurrentDeviceId();
      final transaction = Transaction.create(
        bookId: params.bookId,
        deviceId: deviceId,
        amount: params.amount,
        type: params.type,
        categoryId: params.categoryId,
        ledgerType: ledgerType,
        timestamp: params.timestamp ?? DateTime.now(),
        note: params.note,
        photoHash: photoHash,
        merchant: params.merchant,
        prevHash: prevHash,
        isPrivate: params.isPrivate,
      );

      // 7. 插入数据库
      await _transactionRepo.insert(transaction);

      // 8. 加入同步队列
      await SyncQueue.instance.enqueue(transaction);

      return Result.success(transaction);

    } catch (e, stackTrace) {
      print('创建交易失败: $e\n$stackTrace');
      return Result.error('创建交易失败: $e');
    }
  }

  /// 验证参数
  Result<void> _validate(CreateTransactionParams params) {
    if (params.amount <= 0) {
      return Result.error('金额必须大于0');
    }

    if (params.bookId.isEmpty) {
      return Result.error('账本ID不能为空');
    }

    if (params.categoryId.isEmpty) {
      return Result.error('分类ID不能为空');
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
  final File? photoFile;
  final String? merchant;
  final bool isPrivate;

  CreateTransactionParams({
    required this.bookId,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.timestamp,
    this.note,
    this.photoFile,
    this.merchant,
    this.isPrivate = false,
  });
}
```

#### 查询月度报表Use Case

```dart
// lib/application/analytics/generate_monthly_report_use_case.dart

class GetMonthlyReportUseCase
    implements UseCase<MonthlyReport, GetMonthlyReportParams> {
  final TransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;

  GetMonthlyReportUseCase({
    required TransactionRepository transactionRepo,
    required CategoryRepository categoryRepo,
  })  : _transactionRepo = transactionRepo,
        _categoryRepo = categoryRepo;

  @override
  Future<Result<MonthlyReport>> execute(GetMonthlyReportParams params) async {
    try {
      // 1. 计算日期范围
      final startDate = DateTime(params.year, params.month, 1);
      final endDate = DateTime(params.year, params.month + 1, 0);

      // 2. 获取交易
      final transactions = await _transactionRepo.getTransactions(
        bookId: params.bookId,
        startDate: startDate,
        endDate: endDate,
      );

      // 3. 按分类分组统计
      final categoryStats = await _calculateCategoryStats(transactions);

      // 4. 计算总计
      final totalExpense = transactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0, (sum, t) => sum + t.amount);

      final totalIncome = transactions
          .where((t) => t.type == TransactionType.income)
          .fold(0, (sum, t) => sum + t.amount);

      // 5. 双轨账本统计
      final survivalBalance = transactions
          .where((t) => t.ledgerType == LedgerType.survival)
          .fold(0, (sum, t) => sum + (t.type == TransactionType.expense ? -t.amount : t.amount));

      final soulBalance = transactions
          .where((t) => t.ledgerType == LedgerType.soul)
          .fold(0, (sum, t) => sum + (t.type == TransactionType.expense ? -t.amount : t.amount));

      // 6. 构建报表
      final report = MonthlyReport(
        year: params.year,
        month: params.month,
        totalExpense: totalExpense,
        totalIncome: totalIncome,
        survivalBalance: survivalBalance,
        soulBalance: soulBalance,
        categoryStats: categoryStats,
        transactionCount: transactions.length,
      );

      return Result.success(report);

    } catch (e) {
      return Result.error('生成报表失败: $e');
    }
  }

  Future<List<CategoryStat>> _calculateCategoryStats(
    List<Transaction> transactions,
  ) async {
    final Map<String, CategoryStat> statMap = {};

    for (final tx in transactions) {
      if (tx.type != TransactionType.expense) continue;

      final existing = statMap[tx.categoryId];
      if (existing != null) {
        statMap[tx.categoryId] = existing.copyWith(
          amount: existing.amount + tx.amount,
          count: existing.count + 1,
        );
      } else {
        final category = await _categoryRepo.findById(tx.categoryId);
        statMap[tx.categoryId] = CategoryStat(
          categoryId: tx.categoryId,
          categoryName: category?.name ?? '未知分类',
          amount: tx.amount,
          count: 1,
        );
      }
    }

    final stats = statMap.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return stats;
  }
}

class GetMonthlyReportParams {
  final String bookId;
  final int year;
  final int month;

  GetMonthlyReportParams({
    required this.bookId,
    required this.year,
    required this.month,
  });
}
```

### Provider集成

```dart
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

---

## CRDT同步模式

### CRDT设计

详细实现参见 [08_MOD_FamilySync.md](./08_MOD_FamilySync.md)。

### 核心接口

```dart
// lib/infrastructure/sync/crdt_service.dart

abstract class CRDTService {
  /// 合并远程变更
  Future<List<Transaction>> merge(List<Transaction> remoteTransactions);

  /// 获取本地变更（用于发送）
  Future<List<Transaction>> getLocalChanges({DateTime? since});

  /// 解决冲突
  Transaction resolveConflict(Transaction local, Transaction remote);
}
```

### 实现

```dart
class CRDTServiceImpl implements CRDTService {
  final TransactionRepository _transactionRepo;
  final VectorClockService _vectorClockService;

  @override
  Future<List<Transaction>> merge(List<Transaction> remoteTransactions) async {
    final merged = <Transaction>[];

    for (final remoteTx in remoteTransactions) {
      // 查找本地是否存在
      final localTx = await _transactionRepo.findById(remoteTx.id);

      if (localTx == null) {
        // 本地不存在，直接插入
        await _transactionRepo.insert(remoteTx);
        merged.add(remoteTx);
      } else {
        // 存在冲突，需要解决
        final resolved = resolveConflict(localTx, remoteTx);
        if (resolved.id != localTx.id) {
          await _transactionRepo.update(resolved);
          merged.add(resolved);
        }
      }
    }

    return merged;
  }

  @override
  Transaction resolveConflict(Transaction local, Transaction remote) {
    // Last-Write-Wins (LWW) 策略
    if (remote.updatedAt != null && local.updatedAt != null) {
      if (remote.updatedAt!.isAfter(local.updatedAt!)) {
        return remote;
      } else if (remote.updatedAt!.isBefore(local.updatedAt!)) {
        return local;
      }
    }

    // 时间戳相同，使用设备ID字典序
    return local.deviceId.compareTo(remote.deviceId) > 0 ? local : remote;
  }

  @override
  Future<List<Transaction>> getLocalChanges({DateTime? since}) async {
    // 获取未同步的交易
    final query = _db.select(_db.transactions)
      ..where((t) => t.isSynced.equals(false));

    if (since != null) {
      query.where((t) => t.updatedAt.isBiggerOrEqualValue(since));
    }

    final entities = await query.get();
    return entities.map(_toModel).toList();
  }
}
```

---

## 事件总线模式

### 设计理念

使用事件总线实现模块间解耦通信。

### 事件定义

```dart
// lib/core/domain/events/app_event.dart

abstract class AppEvent {
  final DateTime timestamp;

  AppEvent() : timestamp = DateTime.now();
}

/// 交易创建事件
class TransactionCreatedEvent extends AppEvent {
  final Transaction transaction;

  TransactionCreatedEvent(this.transaction);
}

/// 同步完成事件
class SyncCompletedEvent extends AppEvent {
  final int syncedCount;
  final List<String> deviceIds;

  SyncCompletedEvent({
    required this.syncedCount,
    required this.deviceIds,
  });
}

/// 哈希链异常事件
class HashChainBrokenEvent extends AppEvent {
  final String bookId;
  final String transactionId;

  HashChainBrokenEvent({
    required this.bookId,
    required this.transactionId,
  });
}
```

### 事件总线实现

```dart
// lib/core/domain/events/event_bus.dart

import 'dart:async';

class EventBus {
  static final EventBus instance = EventBus._();
  EventBus._();

  final _controller = StreamController<AppEvent>.broadcast();

  /// 事件流
  Stream<AppEvent> get stream => _controller.stream;

  /// 发布事件
  void publish(AppEvent event) {
    _controller.add(event);
  }

  /// 订阅特定类型事件
  Stream<T> on<T extends AppEvent>() {
    return stream.where((event) => event is T).cast<T>();
  }

  /// 清理
  void dispose() {
    _controller.close();
  }
}
```

### 使用示例

#### 发布事件

```dart
class CreateTransactionUseCase {
  Future<Result<Transaction>> execute(CreateTransactionParams params) async {
    // ...创建交易...

    // 发布事件
    EventBus.instance.publish(TransactionCreatedEvent(transaction));

    return Result.success(transaction);
  }
}
```

#### 订阅事件

```dart
@riverpod
class TransactionEventListener extends _$TransactionEventListener {
  StreamSubscription? _subscription;

  @override
  void build() {
    // 订阅交易创建事件
    _subscription = EventBus.instance.on<TransactionCreatedEvent>().listen(
      (event) {
        _handleTransactionCreated(event.transaction);
      },
    );

    // 清理
    ref.onDispose(() {
      _subscription?.cancel();
    });
  }

  void _handleTransactionCreated(Transaction tx) {
    // 刷新相关Provider
    ref.invalidate(transactionListProvider);
    ref.invalidate(monthlyReportProvider);

    // 触发同步
    if (tx.ledgerType == LedgerType.soul) {
      // 触发灵魂消费庆祝动画
      ref.read(celebrationServiceProvider).celebrate();
    }
  }
}
```

---

## 错误处理模式

### 自定义异常层次

```dart
// lib/core/domain/exceptions/app_exception.dart

abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    return 'AppException: $message (code: $code)';
  }
}

/// 数据库异常
class DatabaseException extends AppException {
  DatabaseException({
    required String message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// 验证异常
class ValidationException extends AppException {
  final Map<String, String> fieldErrors;

  ValidationException({
    required String message,
    required this.fieldErrors,
  }) : super(message: message, code: 'VALIDATION_ERROR');
}

/// 加密异常
class EncryptionException extends AppException {
  EncryptionException({
    required String message,
    dynamic originalError,
  }) : super(
          message: message,
          code: 'ENCRYPTION_ERROR',
          originalError: originalError,
        );
}

/// 同步异常
class SyncException extends AppException {
  SyncException({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

/// 完整性异常
class IntegrityException extends AppException {
  final String bookId;
  final String? transactionId;

  IntegrityException({
    required String message,
    required this.bookId,
    this.transactionId,
  }) : super(message: message, code: 'INTEGRITY_ERROR');
}
```

### 错误处理工具

```dart
// lib/core/utils/error_handler.dart

class ErrorHandler {
  /// 统一错误处理
  static String handleError(dynamic error, [StackTrace? stackTrace]) {
    if (error is AppException) {
      return error.message;
    }

    if (error is DriftException) {
      return '数据库操作失败';
    }

    if (error is PlatformException) {
      return _handlePlatformException(error);
    }

    print('未处理的错误: $error\n$stackTrace');
    return '操作失败，请稍后重试';
  }

  static String _handlePlatformException(PlatformException e) {
    switch (e.code) {
      case 'biometric_error':
        return '生物识别失败';
      case 'permission_denied':
        return '权限被拒绝';
      default:
        return e.message ?? '系统错误';
    }
  }

  /// 记录错误
  static Future<void> logError(
    dynamic error,
    StackTrace stackTrace, {
    Map<String, dynamic>? context,
  }) async {
    // 开发环境：打印
    print('Error: $error');
    print('StackTrace: $stackTrace');
    if (context != null) {
      print('Context: $context');
    }

    // 生产环境：上报到崩溃分析服务
    // await FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
}
```

### UI层错误处理

```dart
@riverpod
class TransactionList extends _$TransactionList {
  @override
  Future<List<Transaction>> build({required String bookId}) async {
    try {
      final repo = ref.watch(transactionRepositoryProvider);
      return await repo.getTransactions(bookId: bookId);
    } catch (e, stackTrace) {
      // 记录错误
      await ErrorHandler.logError(e, stackTrace, context: {
        'bookId': bookId,
        'operation': 'getTransactions',
      });

      // 重新抛出，让UI层AsyncValue.error捕获
      rethrow;
    }
  }
}

// UI层
class TransactionListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookId = ref.watch(currentBookIdProvider);
    final transactionsAsync = ref.watch(transactionListProvider(bookId: bookId));

    return transactionsAsync.when(
      loading: () => const LoadingWidget(),
      error: (error, stack) {
        final message = ErrorHandler.handleError(error, stack);
        return ErrorWidget(message: message);
      },
      data: (transactions) => ListView(...),
    );
  }
}
```

---

## 性能优化模式

### 1. 缓存策略

```dart
// lib/core/cache/cache_manager.dart

class CacheManager<K, V> {
  final Map<K, CacheEntry<V>> _cache = {};
  final Duration ttl;

  CacheManager({required this.ttl});

  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    return entry.value;
  }

  void put(K key, V value) {
    _cache[key] = CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(ttl),
    );
  }

  void invalidate(K key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }
}

class CacheEntry<V> {
  final V value;
  final DateTime expiresAt;

  CacheEntry({required this.value, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
```

### 2. 批量操作

```dart
// 批量插入交易
Future<void> importTransactions(List<Transaction> transactions) async {
  await _db.batch((batch) {
    for (final tx in transactions) {
      batch.insert(_db.transactions, tx.toCompanion());
    }
  });
}
```

### 3. 分页加载

```dart
@riverpod
class TransactionListPaginated extends _$TransactionListPaginated {
  static const _pageSize = 50;
  int _currentPage = 0;

  @override
  Future<PaginatedData<Transaction>> build({required String bookId}) async {
    return _loadPage(0);
  }

  Future<void> loadMore() async {
    if (state.value?.hasMore != true) return;

    _currentPage++;
    state = await AsyncValue.guard(() async {
      final newPage = await _loadPage(_currentPage);
      final current = state.value!;

      return PaginatedData(
        items: [...current.items, ...newPage.items],
        page: newPage.page,
        hasMore: newPage.hasMore,
      );
    });
  }

  Future<PaginatedData<Transaction>> _loadPage(int page) async {
    final repo = ref.read(transactionRepositoryProvider);
    final items = await repo.getTransactions(
      bookId: bookId,
      limit: _pageSize,
      offset: page * _pageSize,
    );

    return PaginatedData(
      items: items,
      page: page,
      hasMore: items.length == _pageSize,
    );
  }
}
```

### 4. 防抖/节流

```dart
// lib/core/utils/debouncer.dart

class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

// 使用
class SearchProvider extends _$SearchProvider {
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 300));

  void search(String query) {
    _debouncer(() {
      _performSearch(query);
    });
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }
}
```

---

## 总结

Happy Pocket集成模式设计的核心特点：

1. **Repository模式**: 抽象数据访问，易于测试和切换实现
2. **Use Case模式**: 封装业务逻辑，单一职责
3. **CRDT同步**: 实现最终一致性，无冲突同步
4. **事件总线**: 模块间解耦通信
5. **统一错误处理**: 清晰的异常层次，友好的错误提示
6. **性能优化**: 缓存、批量操作、分页加载

**下一步阅读**:
- [06_MOD_BasicAccounting.md](./06_MOD_BasicAccounting.md) - 基础记账模块实现
- [08_MOD_FamilySync.md](./08_MOD_FamilySync.md) - 家庭同步模块实现

---

**文档维护**:
- 最后更新: 2026-02-03
- 维护者: 架构团队
- 版本: 1.0
