# Home Pocket MVP - 错误边界与异常处理架构

**文档版本:** 1.0
**创建日期:** 2026-02-03
**状态:** 完成
**作者:** Claude Sonnet 4.5 + senior-architect

---

## 📋 目录

1. [概述](#概述)
2. [错误分层架构](#错误分层架构)
3. [异常类型定义](#异常类型定义)
4. [Data层错误处理](#data层错误处理)
5. [Domain层错误处理](#domain层错误处理)
6. [Presentation层错误处理](#presentation层错误处理)
7. [错误转换规则](#错误转换规则)
8. [错误恢复策略](#错误恢复策略)
9. [监控与日志](#监控与日志)
10. [测试策略](#测试策略)

---

## 概述

### 设计原则

Home Pocket的错误处理遵循以下核心原则：

1. **分层责任（Layered Responsibility）**
   - 每层只处理该层的职责
   - 明确的错误转换边界
   - 向上传播业务异常

2. **用户友好（User-Friendly）**
   - Presentation层转换所有异常为用户可理解的消息
   - 提供可操作的解决方案
   - 避免技术术语

3. **可恢复性（Recoverability）**
   - 区分可恢复和不可恢复错误
   - 提供自动重试机制
   - 支持优雅降级

4. **可观测性（Observability）**
   - 详细的错误日志
   - 错误追踪和上报
   - 便于调试和监控

### 错误分类

| 错误类别 | 可恢复性 | 示例 | 处理策略 |
|---------|---------|------|---------|
| **网络错误** | ✅ 可恢复 | 超时、无网络 | 自动重试 + 提示 |
| **数据错误** | ⚠️ 部分可恢复 | 数据格式错误、约束冲突 | 验证 + 提示 |
| **业务错误** | ❌ 不可恢复 | 预算超限、权限不足 | 提示 + 引导 |
| **系统错误** | ❌ 不可恢复 | 内存不足、磁盘满 | 报告 + 降级 |
| **安全错误** | ❌ 不可恢复 | 加密失败、签名错误 | 报告 + 阻止 |

---

## 错误分层架构

```
┌─────────────────────────────────────────────────────────┐
│              Presentation Layer (UI)                    │
│  ✅ 捕获所有异常                                         │
│  ✅ 转换为用户友好消息                                   │
│  ✅ 显示错误UI/Toast                                     │
│  ✅ 提供可操作的解决方案                                 │
└────────────────────┬────────────────────────────────────┘
                     │ 抛出: DomainException
                     │
┌────────────────────▼────────────────────────────────────┐
│               Domain Layer (Use Cases)                  │
│  ✅ 仅抛出业务异常(DomainException)                      │
│  ✅ 验证业务规则                                         │
│  ✅ 不处理技术异常                                       │
│  ⛔ 不捕获Repository异常                                │
└────────────────────┬────────────────────────────────────┘
                     │ 抛出: DomainException
                     │ 传递: RepositoryException
                     │
┌────────────────────▼────────────────────────────────────┐
│                Data Layer (Repository)                  │
│  ✅ 捕获所有技术异常                                     │
│  ✅ 转换为RepositoryException                            │
│  ✅ 附加上下文信息                                       │
│  ✅ 记录详细日志                                         │
└────────────────────┬────────────────────────────────────┘
                     │ 原始异常: DatabaseException,
                     │           NetworkException, etc.
                     │
┌────────────────────▼────────────────────────────────────┐
│            Infrastructure (Drift, APIs)                 │
│  ⚠️ 抛出技术异常                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 异常类型定义

### 基础异常类

```dart
// lib/core/error/exceptions.dart

/// 基础应用异常
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? metadata;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
    this.metadata,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('$runtimeType: $message');
    if (code != null) buffer.writeln('Code: $code');
    if (metadata != null) buffer.writeln('Metadata: $metadata');
    if (originalError != null) {
      buffer.writeln('Original Error: $originalError');
    }
    return buffer.toString();
  }
}

/// 可恢复异常标记接口
abstract class RecoverableException {
  /// 是否支持自动重试
  bool get canRetry;

  /// 重试延迟（毫秒）
  int get retryDelay;

  /// 最大重试次数
  int get maxRetries;
}
```

---

### Data层异常（RepositoryException）

```dart
// lib/data/error/repository_exceptions.dart

/// Repository层基础异常
abstract class RepositoryException extends AppException {
  const RepositoryException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
    super.metadata,
  });
}

/// 数据库异常
class DatabaseException extends RepositoryException {
  const DatabaseException({
    required super.message,
    super.code = 'DATABASE_ERROR',
    super.originalError,
    super.stackTrace,
    super.metadata,
  });

  /// 工厂方法：查询错误
  factory DatabaseException.queryFailed({
    required String table,
    required dynamic error,
    StackTrace? stackTrace,
  }) =>
      DatabaseException(
        message: '数据库查询失败: $table',
        code: 'DB_QUERY_FAILED',
        originalError: error,
        stackTrace: stackTrace,
        metadata: {'table': table},
      );

  /// 工厂方法：插入错误
  factory DatabaseException.insertFailed({
    required String table,
    required dynamic error,
    StackTrace? stackTrace,
  }) =>
      DatabaseException(
        message: '数据插入失败: $table',
        code: 'DB_INSERT_FAILED',
        originalError: error,
        stackTrace: stackTrace,
        metadata: {'table': table},
      );

  /// 工厂方法：更新错误
  factory DatabaseException.updateFailed({
    required String table,
    required String id,
    required dynamic error,
    StackTrace? stackTrace,
  }) =>
      DatabaseException(
        message: '数据更新失败: $table#$id',
        code: 'DB_UPDATE_FAILED',
        originalError: error,
        stackTrace: stackTrace,
        metadata: {'table': table, 'id': id},
      );

  /// 工厂方法：删除错误
  factory DatabaseException.deleteFailed({
    required String table,
    required String id,
    required dynamic error,
    StackTrace? stackTrace,
  }) =>
      DatabaseException(
        message: '数据删除失败: $table#$id',
        code: 'DB_DELETE_FAILED',
        originalError: error,
        stackTrace: stackTrace,
        metadata: {'table': table, 'id': id},
      );

  /// 工厂方法：约束冲突
  factory DatabaseException.constraintViolation({
    required String constraint,
    required dynamic error,
    StackTrace? stackTrace,
  }) =>
      DatabaseException(
        message: '数据约束冲突: $constraint',
        code: 'DB_CONSTRAINT_VIOLATION',
        originalError: error,
        stackTrace: stackTrace,
        metadata: {'constraint': constraint},
      );
}

/// 加密异常
class EncryptionException extends RepositoryException {
  const EncryptionException({
    required super.message,
    super.code = 'ENCRYPTION_ERROR',
    super.originalError,
    super.stackTrace,
    super.metadata,
  });

  factory EncryptionException.encryptionFailed({
    required String data,
    required dynamic error,
    StackTrace? stackTrace,
  }) =>
      EncryptionException(
        message: '数据加密失败',
        code: 'ENCRYPT_FAILED',
        originalError: error,
        stackTrace: stackTrace,
      );

  factory EncryptionException.decryptionFailed({
    required String data,
    required dynamic error,
    StackTrace? stackTrace,
  }) =>
      EncryptionException(
        message: '数据解密失败',
        code: 'DECRYPT_FAILED',
        originalError: error,
        stackTrace: stackTrace,
      );

  factory EncryptionException.keyNotFound() =>
      const EncryptionException(
        message: '加密密钥未找到',
        code: 'KEY_NOT_FOUND',
      );
}

/// 网络异常（用于未来同步功能）
class NetworkException extends RepositoryException
    implements RecoverableException {
  const NetworkException({
    required super.message,
    super.code = 'NETWORK_ERROR',
    super.originalError,
    super.stackTrace,
    super.metadata,
  });

  @override
  bool get canRetry => true;

  @override
  int get retryDelay => 1000; // 1秒

  @override
  int get maxRetries => 3;

  factory NetworkException.timeout() =>
      const NetworkException(
        message: '网络请求超时',
        code: 'NETWORK_TIMEOUT',
      );

  factory NetworkException.noConnection() =>
      const NetworkException(
        message: '无网络连接',
        code: 'NO_CONNECTION',
      );

  factory NetworkException.serverError({
    required int statusCode,
    String? body,
  }) =>
      NetworkException(
        message: '服务器错误: $statusCode',
        code: 'SERVER_ERROR',
        metadata: {'statusCode': statusCode, 'body': body},
      );
}

/// 缓存异常
class CacheException extends RepositoryException {
  const CacheException({
    required super.message,
    super.code = 'CACHE_ERROR',
    super.originalError,
    super.stackTrace,
    super.metadata,
  });

  factory CacheException.readFailed({
    required String key,
    required dynamic error,
  }) =>
      CacheException(
        message: '缓存读取失败: $key',
        code: 'CACHE_READ_FAILED',
        originalError: error,
        metadata: {'key': key},
      );

  factory CacheException.writeFailed({
    required String key,
    required dynamic error,
  }) =>
      CacheException(
        message: '缓存写入失败: $key',
        code: 'CACHE_WRITE_FAILED',
        originalError: error,
        metadata: {'key': key},
      );
}
```

---

### Domain层异常（DomainException）

```dart
// lib/domain/error/domain_exceptions.dart

/// Domain层基础异常
abstract class DomainException extends AppException {
  const DomainException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
    super.metadata,
  });
}

/// 验证异常
class ValidationException extends DomainException {
  final Map<String, List<String>> errors;

  const ValidationException({
    required super.message,
    required this.errors,
    super.code = 'VALIDATION_ERROR',
  });

  factory ValidationException.single({
    required String field,
    required String error,
  }) =>
      ValidationException(
        message: '验证失败: $field',
        errors: {
          field: [error]
        },
      );

  factory ValidationException.multiple({
    required Map<String, List<String>> errors,
  }) =>
      ValidationException(
        message: '验证失败: ${errors.keys.join(', ')}',
        errors: errors,
      );

  /// 获取第一个错误消息
  String get firstError => errors.values.first.first;
}

/// 业务规则异常
class BusinessRuleException extends DomainException {
  const BusinessRuleException({
    required super.message,
    super.code = 'BUSINESS_RULE_VIOLATION',
    super.metadata,
  });

  /// 预算超限
  factory BusinessRuleException.budgetExceeded({
    required int amount,
    required int budgetLimit,
    required String categoryName,
  }) =>
      BusinessRuleException(
        message: '类别 "$categoryName" 预算超限',
        code: 'BUDGET_EXCEEDED',
        metadata: {
          'amount': amount,
          'budgetLimit': budgetLimit,
          'categoryName': categoryName,
          'exceeded': amount - budgetLimit,
        },
      );

  /// 账本已存在
  factory BusinessRuleException.bookAlreadyExists({
    required String bookName,
  }) =>
      BusinessRuleException(
        message: '账本 "$bookName" 已存在',
        code: 'BOOK_ALREADY_EXISTS',
        metadata: {'bookName': bookName},
      );

  /// 无法删除默认账本
  factory BusinessRuleException.cannotDeleteDefaultBook() =>
      const BusinessRuleException(
        message: '无法删除默认账本',
        code: 'CANNOT_DELETE_DEFAULT_BOOK',
      );

  /// 交易金额无效
  factory BusinessRuleException.invalidAmount({
    required int amount,
  }) =>
      BusinessRuleException(
        message: '交易金额无效: $amount',
        code: 'INVALID_AMOUNT',
        metadata: {'amount': amount},
      );

  /// 哈希链验证失败
  factory BusinessRuleException.hashChainBroken({
    required String transactionId,
    required String bookId,
  }) =>
      BusinessRuleException(
        message: '交易完整性验证失败',
        code: 'HASH_CHAIN_BROKEN',
        metadata: {
          'transactionId': transactionId,
          'bookId': bookId,
        },
      );
}

/// 未找到异常
class NotFoundException extends DomainException {
  const NotFoundException({
    required super.message,
    super.code = 'NOT_FOUND',
    super.metadata,
  });

  factory NotFoundException.book({required String bookId}) =>
      NotFoundException(
        message: '账本未找到',
        code: 'BOOK_NOT_FOUND',
        metadata: {'bookId': bookId},
      );

  factory NotFoundException.transaction({required String transactionId}) =>
      NotFoundException(
        message: '交易记录未找到',
        code: 'TRANSACTION_NOT_FOUND',
        metadata: {'transactionId': transactionId},
      );

  factory NotFoundException.category({required String categoryId}) =>
      NotFoundException(
        message: '分类未找到',
        code: 'CATEGORY_NOT_FOUND',
        metadata: {'categoryId': categoryId},
      );

  factory NotFoundException.budget({required String budgetId}) =>
      NotFoundException(
        message: '预算未找到',
        code: 'BUDGET_NOT_FOUND',
        metadata: {'budgetId': budgetId},
      );
}

/// 权限异常（未来多用户功能）
class PermissionException extends DomainException {
  const PermissionException({
    required super.message,
    super.code = 'PERMISSION_DENIED',
    super.metadata,
  });

  factory PermissionException.cannotModifyTransaction({
    required String transactionId,
  }) =>
      PermissionException(
        message: '无权修改此交易',
        code: 'CANNOT_MODIFY_TRANSACTION',
        metadata: {'transactionId': transactionId},
      );

  factory PermissionException.cannotDeleteBook({
    required String bookId,
  }) =>
      PermissionException(
        message: '无权删除此账本',
        code: 'CANNOT_DELETE_BOOK',
        metadata: {'bookId': bookId},
      );
}

/// 冲突异常
class ConflictException extends DomainException {
  const ConflictException({
    required super.message,
    super.code = 'CONFLICT',
    super.metadata,
  });

  factory ConflictException.categoryInUse({
    required String categoryId,
    required int transactionCount,
  }) =>
      ConflictException(
        message: '类别正在使用中，无法删除',
        code: 'CATEGORY_IN_USE',
        metadata: {
          'categoryId': categoryId,
          'transactionCount': transactionCount,
        },
      );

  factory ConflictException.bookInUse({
    required String bookId,
    required int transactionCount,
  }) =>
      ConflictException(
        message: '账本包含交易记录，无法删除',
        code: 'BOOK_IN_USE',
        metadata: {
          'bookId': bookId,
          'transactionCount': transactionCount,
        },
      );
}
```

---

### Presentation层错误（Failure）

```dart
// lib/presentation/core/error/failures.dart

/// Presentation层失败类（不是异常，是值对象）
abstract class Failure {
  final String message;
  final String? actionLabel;
  final VoidCallback? action;

  const Failure({
    required this.message,
    this.actionLabel,
    this.action,
  });
}

/// 网络失败
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = '网络连接失败，请检查网络设置',
    super.actionLabel = '重试',
    super.action,
  });
}

/// 服务器失败
class ServerFailure extends Failure {
  const ServerFailure({
    super.message = '服务器错误，请稍后再试',
    super.actionLabel = '重试',
    super.action,
  });
}

/// 数据失败
class DataFailure extends Failure {
  const DataFailure({
    super.message = '数据读取失败',
    super.actionLabel,
    super.action,
  });
}

/// 验证失败
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.actionLabel = '修改',
    super.action,
  });
}

/// 业务规则失败
class BusinessRuleFailure extends Failure {
  const BusinessRuleFailure({
    required super.message,
    super.actionLabel,
    super.action,
  });
}

/// 未找到失败
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = '未找到请求的数据',
    super.actionLabel,
    super.action,
  });
}

/// 权限失败
class PermissionFailure extends Failure {
  const PermissionFailure({
    super.message = '您没有权限执行此操作',
    super.actionLabel,
    super.action,
  });
}

/// 未知失败
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = '发生未知错误，请重试',
    super.actionLabel = '重试',
    super.action,
  });
}
```

---

## Data层错误处理

### 错误转换策略

**原则**: 捕获所有技术异常，转换为RepositoryException

```dart
// lib/data/repositories/transaction_repository_impl.dart

class TransactionRepositoryImpl implements TransactionRepository {
  final AppDatabase _db;
  final ErrorLogger _logger;

  TransactionRepositoryImpl(this._db, this._logger);

  @override
  Future<Transaction> create(CreateTransactionDto dto) async {
    try {
      // 1. 验证数据
      _validateDto(dto);

      // 2. 加密敏感字段
      final encryptedNote = await _encryptField(dto.note);

      // 3. 计算哈希
      final hash = await _calculateHash(dto);

      // 4. 插入数据库
      final entity = TransactionEntity(
        id: Ulid().toString(),
        bookId: dto.bookId,
        amount: dto.amount,
        type: dto.type,
        categoryId: dto.categoryId,
        note: encryptedNote,
        currentHash: hash,
        prevHash: dto.prevHash,
        timestamp: dto.timestamp,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _db.into(_db.transactions).insert(entity);

      return entity.toDomain();
    } on SqliteException catch (e, st) {
      // ✅ 转换SQLite异常
      _logger.error('Database error creating transaction', e, st);

      if (e.extendedResultCode == 19) {  // CONSTRAINT_VIOLATION
        throw DatabaseException.constraintViolation(
          constraint: _parseConstraint(e.message),
          error: e,
          stackTrace: st,
        );
      }

      throw DatabaseException.insertFailed(
        table: 'transactions',
        error: e,
        stackTrace: st,
      );
    } on EncryptionException {
      // ✅ 直接重新抛出Repository层异常
      rethrow;
    } catch (e, st) {
      // ✅ 捕获未知异常
      _logger.error('Unknown error creating transaction', e, st);

      throw DatabaseException(
        message: '创建交易失败: ${e.toString()}',
        code: 'CREATE_TRANSACTION_FAILED',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<Transaction> findById(String id) async {
    try {
      final entity = await (_db.select(_db.transactions)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();

      if (entity == null) {
        // ⚠️ 注意：未找到不是异常，返回null或使用Option类型
        // 但为了演示，这里抛出异常
        throw NotFoundException.transaction(transactionId: id);
      }

      // 解密敏感字段
      final decryptedNote = await _decryptField(entity.note);

      return entity.toDomain(note: decryptedNote);
    } on SqliteException catch (e, st) {
      _logger.error('Database error finding transaction', e, st);

      throw DatabaseException.queryFailed(
        table: 'transactions',
        error: e,
        stackTrace: st,
      );
    } on EncryptionException {
      rethrow;
    } on NotFoundException {
      // ✅ Domain异常直接传递
      rethrow;
    } catch (e, st) {
      _logger.error('Unknown error finding transaction', e, st);

      throw DatabaseException(
        message: '查询交易失败: ${e.toString()}',
        code: 'FIND_TRANSACTION_FAILED',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> update(Transaction transaction) async {
    try {
      // 1. 检查存在性
      final existing = await findById(transaction.id);

      // 2. 加密敏感字段
      final encryptedNote = await _encryptField(transaction.note);

      // 3. 更新数据库
      final entity = transaction.toEntity(note: encryptedNote);

      final updated = await (_db.update(_db.transactions)
            ..where((t) => t.id.equals(transaction.id)))
          .write(entity);

      if (updated == 0) {
        throw NotFoundException.transaction(transactionId: transaction.id);
      }
    } on SqliteException catch (e, st) {
      _logger.error('Database error updating transaction', e, st);

      throw DatabaseException.updateFailed(
        table: 'transactions',
        id: transaction.id,
        error: e,
        stackTrace: st,
      );
    } on RepositoryException {
      // ✅ Repository异常直接传递
      rethrow;
    } on DomainException {
      // ✅ Domain异常直接传递
      rethrow;
    } catch (e, st) {
      _logger.error('Unknown error updating transaction', e, st);

      throw DatabaseException(
        message: '更新交易失败: ${e.toString()}',
        code: 'UPDATE_TRANSACTION_FAILED',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      final deleted = await (_db.delete(_db.transactions)
            ..where((t) => t.id.equals(id)))
          .go();

      if (deleted == 0) {
        throw NotFoundException.transaction(transactionId: id);
      }
    } on SqliteException catch (e, st) {
      _logger.error('Database error deleting transaction', e, st);

      throw DatabaseException.deleteFailed(
        table: 'transactions',
        id: id,
        error: e,
        stackTrace: st,
      );
    } on DomainException {
      rethrow;
    } catch (e, st) {
      _logger.error('Unknown error deleting transaction', e, st);

      throw DatabaseException(
        message: '删除交易失败: ${e.toString()}',
        code: 'DELETE_TRANSACTION_FAILED',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  // 辅助方法
  Future<String> _encryptField(String? value) async {
    if (value == null || value.isEmpty) return '';

    try {
      return await FieldEncryption.encrypt(value);
    } catch (e, st) {
      throw EncryptionException.encryptionFailed(
        data: 'note',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<String?> _decryptField(String? value) async {
    if (value == null || value.isEmpty) return null;

    try {
      return await FieldEncryption.decrypt(value);
    } catch (e, st) {
      throw EncryptionException.decryptionFailed(
        data: 'note',
        error: e,
        stackTrace: st,
      );
    }
  }
}
```

### 错误日志记录

```dart
// lib/data/error/error_logger.dart

class ErrorLogger {
  final LoggingService _loggingService;

  ErrorLogger(this._loggingService);

  /// 记录错误
  void error(String message, dynamic error, StackTrace? stackTrace) {
    _loggingService.error(
      message,
      error: error,
      stackTrace: stackTrace,
      context: {
        'layer': 'data',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // 上报到监控系统（未来）
    // _analyticsService.logException(error, stackTrace);
  }

  /// 记录警告
  void warning(String message, {Map<String, dynamic>? context}) {
    _loggingService.warning(
      message,
      context: {
        'layer': 'data',
        'timestamp': DateTime.now().toIso8601String(),
        ...?context,
      },
    );
  }
}
```

---

## Domain层错误处理

### 错误处理策略

**原则**: 仅抛出业务异常，不处理技术异常

```dart
// lib/domain/usecases/create_transaction_usecase.dart

class CreateTransactionUseCase {
  final TransactionRepository _transactionRepository;
  final CategoryRepository _categoryRepository;
  final BudgetRepository _budgetRepository;
  final HashChainService _hashChainService;

  CreateTransactionUseCase(
    this._transactionRepository,
    this._categoryRepository,
    this._budgetRepository,
    this._hashChainService,
  );

  Future<Transaction> execute(CreateTransactionDto dto) async {
    // ⚠️ Domain层不捕获Repository异常，直接向上传递
    // ✅ Domain层仅处理业务规则验证

    // 1. 业务规则验证
    await _validateBusinessRules(dto);

    // 2. 计算哈希链
    final prevHash = await _hashChainService.getLatestHash(
      dto.bookId,
      _transactionRepository,
    );

    // 3. 创建交易
    final transaction = await _transactionRepository.create(
      dto.copyWith(prevHash: prevHash),
    );

    // 4. 验证哈希
    final isValid = _hashChainService.verifyTransaction(transaction);
    if (!isValid) {
      throw BusinessRuleException.hashChainBroken(
        transactionId: transaction.id,
        bookId: transaction.bookId,
      );
    }

    return transaction;
  }

  Future<void> _validateBusinessRules(CreateTransactionDto dto) async {
    // 1. 验证金额
    if (dto.amount <= 0) {
      throw BusinessRuleException.invalidAmount(amount: dto.amount);
    }

    // 2. 验证分类存在性
    try {
      await _categoryRepository.findById(dto.categoryId);
    } on NotFoundException {
      // ✅ 捕获Domain异常并转换为更具体的业务异常
      throw NotFoundException.category(categoryId: dto.categoryId);
    }

    // 3. 验证预算限制（仅支出类交易）
    if (dto.type == TransactionType.expense) {
      await _checkBudgetLimit(dto);
    }
  }

  Future<void> _checkBudgetLimit(CreateTransactionDto dto) async {
    try {
      // 获取类别的预算
      final budget = await _budgetRepository.findByCategoryAndPeriod(
        categoryId: dto.categoryId,
        year: dto.timestamp.year,
        month: dto.timestamp.month,
      );

      if (budget == null) return;  // 无预算限制

      // 计算当前支出
      final currentExpense = await _transactionRepository.getTotalExpense(
        categoryId: dto.categoryId,
        year: dto.timestamp.year,
        month: dto.timestamp.month,
      );

      // 检查是否超限
      if (currentExpense + dto.amount > budget.limit) {
        final category = await _categoryRepository.findById(dto.categoryId);

        throw BusinessRuleException.budgetExceeded(
          amount: currentExpense + dto.amount,
          budgetLimit: budget.limit,
          categoryName: category.name,
        );
      }
    } on NotFoundException {
      // ✅ 未找到预算，忽略
      return;
    }
    // ⚠️ 注意：不捕获RepositoryException，让其向上传播
  }
}
```

### 业务规则验证

```dart
// lib/domain/usecases/update_transaction_usecase.dart

class UpdateTransactionUseCase {
  final TransactionRepository _transactionRepository;
  final HashChainService _hashChainService;

  UpdateTransactionUseCase(
    this._transactionRepository,
    this._hashChainService,
  );

  Future<void> execute(Transaction transaction) async {
    // 1. 验证交易存在
    final existing = await _transactionRepository.findById(transaction.id);

    // 2. 业务规则：不能修改已归档的交易（未来功能）
    if (existing.isArchived) {
      throw PermissionException.cannotModifyTransaction(
        transactionId: transaction.id,
      );
    }

    // 3. 业务规则：修改后需重新计算哈希链
    // ⚠️ 简化实现：暂不支持修改已有交易的金额/类别
    // ⚠️ 仅允许修改备注和照片
    if (existing.amount != transaction.amount ||
        existing.categoryId != transaction.categoryId) {
      throw BusinessRuleException(
        message: '不允许修改交易金额和类别',
        code: 'CANNOT_MODIFY_CORE_FIELDS',
      );
    }

    // 4. 更新交易
    await _transactionRepository.update(transaction);
  }
}
```

---

## Presentation层错误处理

### 错误转换器

```dart
// lib/presentation/core/error/exception_to_failure_mapper.dart

/// 异常转换为Failure
class ExceptionToFailureMapper {
  /// 转换异常
  static Failure map(Object error, {VoidCallback? onRetry}) {
    if (error is ValidationException) {
      return ValidationFailure(
        message: error.firstError,
      );
    }

    if (error is BusinessRuleException) {
      return _mapBusinessRuleException(error);
    }

    if (error is NotFoundException) {
      return _mapNotFoundException(error);
    }

    if (error is PermissionException) {
      return PermissionFailure(
        message: error.message,
      );
    }

    if (error is ConflictException) {
      return BusinessRuleFailure(
        message: error.message,
      );
    }

    if (error is DatabaseException) {
      return DataFailure(
        message: '数据操作失败，请重试',
        actionLabel: '重试',
        action: onRetry,
      );
    }

    if (error is EncryptionException) {
      return DataFailure(
        message: '数据加密失败，请检查设备安全设置',
      );
    }

    if (error is NetworkException) {
      return NetworkFailure(
        message: error.message,
        actionLabel: '重试',
        action: onRetry,
      );
    }

    // 未知异常
    return UnknownFailure(
      message: '操作失败，请重试',
      actionLabel: '重试',
      action: onRetry,
    );
  }

  static Failure _mapBusinessRuleException(BusinessRuleException e) {
    switch (e.code) {
      case 'BUDGET_EXCEEDED':
        final exceeded = e.metadata?['exceeded'] ?? 0;
        final categoryName = e.metadata?['categoryName'] ?? '';
        return BusinessRuleFailure(
          message: '类别 "$categoryName" 预算超限 ¥${exceeded / 100}',
          actionLabel: '查看预算',
        );

      case 'BOOK_ALREADY_EXISTS':
        return BusinessRuleFailure(
          message: e.message,
        );

      case 'CANNOT_DELETE_DEFAULT_BOOK':
        return BusinessRuleFailure(
          message: '无法删除默认账本，请先设置其他默认账本',
        );

      case 'INVALID_AMOUNT':
        return ValidationFailure(
          message: '交易金额必须大于0',
        );

      case 'HASH_CHAIN_BROKEN':
        return DataFailure(
          message: '数据完整性验证失败，请联系技术支持',
        );

      default:
        return BusinessRuleFailure(
          message: e.message,
        );
    }
  }

  static Failure _mapNotFoundException(NotFoundException e) {
    switch (e.code) {
      case 'BOOK_NOT_FOUND':
        return NotFoundFailure(message: '账本未找到');

      case 'TRANSACTION_NOT_FOUND':
        return NotFoundFailure(message: '交易记录未找到');

      case 'CATEGORY_NOT_FOUND':
        return NotFoundFailure(message: '分类未找到');

      case 'BUDGET_NOT_FOUND':
        return NotFoundFailure(message: '预算未找到');

      default:
        return NotFoundFailure(message: e.message);
    }
  }
}
```

### Provider错误处理

```dart
// lib/presentation/features/transaction/providers/transaction_provider.dart

@riverpod
class TransactionNotifier extends _$TransactionNotifier {
  @override
  AsyncValue<Transaction?> build() {
    return const AsyncValue.data(null);
  }

  /// 创建交易
  Future<void> create(CreateTransactionDto dto) async {
    // 设置loading状态
    state = const AsyncValue.loading();

    try {
      // 执行Use Case
      final useCase = ref.read(createTransactionUseCaseProvider);
      final transaction = await useCase.execute(dto);

      // ✅ 成功：更新状态
      state = AsyncValue.data(transaction);

      // 显示成功提示
      ref.read(toastServiceProvider).showSuccess('交易创建成功');
    } catch (error, stackTrace) {
      // ✅ 失败：转换异常为Failure
      final failure = ExceptionToFailureMapper.map(
        error,
        onRetry: () => create(dto),
      );

      // 设置错误状态
      state = AsyncValue.error(failure, stackTrace);

      // 显示错误提示
      ref.read(toastServiceProvider).showError(failure.message);

      // 记录错误（用于分析）
      ref.read(analyticsServiceProvider).logError(
        error: error,
        stackTrace: stackTrace,
        context: {'operation': 'create_transaction'},
      );
    }
  }

  /// 更新交易
  Future<void> update(Transaction transaction) async {
    state = const AsyncValue.loading();

    try {
      final useCase = ref.read(updateTransactionUseCaseProvider);
      await useCase.execute(transaction);

      state = AsyncValue.data(transaction);

      ref.read(toastServiceProvider).showSuccess('交易更新成功');
    } catch (error, stackTrace) {
      final failure = ExceptionToFailureMapper.map(
        error,
        onRetry: () => update(transaction),
      );

      state = AsyncValue.error(failure, stackTrace);
      ref.read(toastServiceProvider).showError(failure.message);
      ref.read(analyticsServiceProvider).logError(
        error: error,
        stackTrace: stackTrace,
        context: {'operation': 'update_transaction'},
      );
    }
  }

  /// 删除交易
  Future<void> delete(String id) async {
    state = const AsyncValue.loading();

    try {
      final useCase = ref.read(deleteTransactionUseCaseProvider);
      await useCase.execute(id);

      state = const AsyncValue.data(null);

      ref.read(toastServiceProvider).showSuccess('交易删除成功');
    } catch (error, stackTrace) {
      final failure = ExceptionToFailureMapper.map(
        error,
        onRetry: () => delete(id),
      );

      state = AsyncValue.error(failure, stackTrace);
      ref.read(toastServiceProvider).showError(failure.message);
      ref.read(analyticsServiceProvider).logError(
        error: error,
        stackTrace: stackTrace,
        context: {'operation': 'delete_transaction'},
      );
    }
  }
}
```

### UI错误显示

```dart
// lib/presentation/features/transaction/pages/transaction_list_page.dart

class TransactionListPage extends ConsumerWidget {
  const TransactionListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('交易列表')),
      body: transactionsAsync.when(
        // ✅ 成功：显示数据
        data: (transactions) {
          if (transactions.isEmpty) {
            return const EmptyStateWidget(
              message: '暂无交易记录',
              icon: Icons.receipt_long,
            );
          }

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              return TransactionListTile(
                transaction: transactions[index],
              );
            },
          );
        },

        // ✅ 加载中：显示骨架屏
        loading: () => const TransactionListSkeletonLoader(),

        // ✅ 错误：显示错误UI
        error: (error, stackTrace) {
          // error是Failure对象
          if (error is Failure) {
            return ErrorStateWidget(
              message: error.message,
              actionLabel: error.actionLabel,
              onAction: error.action,
            );
          }

          // 未知错误
          return const ErrorStateWidget(
            message: '加载失败，请重试',
            actionLabel: '重试',
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateTransactionPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### 错误UI组件

```dart
// lib/presentation/core/widgets/error_state_widget.dart

class ErrorStateWidget extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// lib/presentation/core/widgets/empty_state_widget.dart

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

## 错误转换规则

### 转换流程图

```
Infrastructure Layer
       ↓
[SqliteException]
[PlatformException]
[SocketException]
       ↓
──────────────────────
Data Layer
  try-catch转换
       ↓
[DatabaseException]
[EncryptionException]
[NetworkException]
       ↓
──────────────────────
Domain Layer
  不捕获技术异常
  仅抛出业务异常
       ↓
[ValidationException]
[BusinessRuleException]
[NotFoundException]
[PermissionException]
       ↓
──────────────────────
Presentation Layer
  转换为Failure
       ↓
[ValidationFailure]
[BusinessRuleFailure]
[NotFoundFailure]
[NetworkFailure]
[DataFailure]
       ↓
──────────────────────
UI Layer
  显示用户友好消息
```

### 转换矩阵

| 原始异常 | Data层转换 | Domain层传递 | Presentation层转换 | 用户消息 |
|---------|-----------|-------------|-------------------|---------|
| **SqliteException** | DatabaseException | 传递 | DataFailure | "数据操作失败，请重试" |
| **EncryptionError** | EncryptionException | 传递 | DataFailure | "数据加密失败" |
| **SocketException** | NetworkException | 传递 | NetworkFailure | "网络连接失败" |
| **ValidationError** | - | ValidationException | ValidationFailure | 具体验证错误 |
| **BusinessRule** | - | BusinessRuleException | BusinessRuleFailure | 具体业务规则 |
| **NotFound** | - | NotFoundException | NotFoundFailure | "未找到数据" |
| **Permission** | - | PermissionException | PermissionFailure | "无权限" |

---

## 错误恢复策略

### 自动重试机制

```dart
// lib/core/error/retry_policy.dart

class RetryPolicy {
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;

  const RetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
  });

  /// 执行带重试的操作
  Future<T> execute<T>(Future<T> Function() operation) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      attempt++;

      try {
        return await operation();
      } catch (error) {
        // 检查是否可重试
        if (!_isRetryable(error) || attempt >= maxAttempts) {
          rethrow;
        }

        // 等待后重试
        await Future.delayed(delay);

        // 指数退避
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).toInt(),
        );

        if (delay > maxDelay) {
          delay = maxDelay;
        }
      }
    }
  }

  bool _isRetryable(Object error) {
    if (error is RecoverableException) {
      return error.canRetry;
    }

    if (error is NetworkException) {
      return true;
    }

    if (error is DatabaseException) {
      // 某些数据库错误可重试（如锁超时）
      return error.code == 'DB_LOCKED';
    }

    return false;
  }
}

// 使用示例
@riverpod
class SyncService extends _$SyncService {
  final _retryPolicy = const RetryPolicy(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 2),
  );

  Future<void> syncData() async {
    try {
      await _retryPolicy.execute(() async {
        // 执行同步操作
        await _performSync();
      });

      state = const AsyncValue.data(SyncStatus.completed);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> _performSync() async {
    // 同步逻辑
  }
}
```

### 降级策略

```dart
// lib/core/error/fallback_strategy.dart

class FallbackStrategy {
  /// 缓存降级：网络失败时使用缓存
  static Future<T> cacheFirst<T>({
    required Future<T> Function() fetchFromNetwork,
    required Future<T?> Function() fetchFromCache,
    required Future<void> Function(T data) saveToCache,
  }) async {
    try {
      // 1. 尝试从网络获取
      final data = await fetchFromNetwork();

      // 2. 保存到缓存
      await saveToCache(data);

      return data;
    } on NetworkException {
      // 3. 网络失败，从缓存读取
      final cachedData = await fetchFromCache();

      if (cachedData != null) {
        return cachedData;
      }

      // 4. 缓存也没有，重新抛出异常
      rethrow;
    }
  }

  /// 默认值降级：操作失败时返回默认值
  static Future<T> withDefault<T>({
    required Future<T> Function() operation,
    required T defaultValue,
  }) async {
    try {
      return await operation();
    } catch (error) {
      // 记录错误
      print('Operation failed, using default value: $error');

      return defaultValue;
    }
  }
}

// 使用示例
@riverpod
class CategoryRepository extends _$CategoryRepository {
  Future<List<Category>> getCategories() async {
    return await FallbackStrategy.cacheFirst(
      fetchFromNetwork: () async {
        // 从网络获取（未来功能）
        return await _api.getCategories();
      },
      fetchFromCache: () async {
        // 从本地数据库获取
        return await _db.getCategories();
      },
      saveToCache: (categories) async {
        // 保存到本地数据库
        await _db.saveCategories(categories);
      },
    );
  }
}
```

---

## 监控与日志

### 错误监控服务

```dart
// lib/core/monitoring/error_monitoring_service.dart

class ErrorMonitoringService {
  final AnalyticsService _analytics;
  final LoggingService _logging;

  ErrorMonitoringService(this._analytics, this._logging);

  /// 记录异常
  Future<void> recordException({
    required Object error,
    required StackTrace stackTrace,
    required String layer,
    Map<String, dynamic>? context,
  }) async {
    // 1. 记录到本地日志
    _logging.error(
      'Exception in $layer',
      error: error,
      stackTrace: stackTrace,
      context: context,
    );

    // 2. 上报到分析平台（未来）
    await _analytics.logException(
      error: error,
      stackTrace: stackTrace,
      fatal: _isFatal(error),
      context: {
        'layer': layer,
        ...?context,
      },
    );

    // 3. 如果是严重错误，发送报警（未来）
    if (_isCritical(error)) {
      await _sendAlert(error, stackTrace, context);
    }
  }

  bool _isFatal(Object error) {
    return error is EncryptionException ||
        error is BusinessRuleException &&
            error.code == 'HASH_CHAIN_BROKEN';
  }

  bool _isCritical(Object error) {
    return error is EncryptionException ||
        error is DatabaseException &&
            error.code == 'DB_CORRUPTION';
  }

  Future<void> _sendAlert(
    Object error,
    StackTrace stackTrace,
    Map<String, dynamic>? context,
  ) async {
    // 发送到监控系统（未来）
    // await _alertingService.send(...);
  }
}
```

### 结构化日志

```dart
// lib/core/logging/logging_service.dart

class LoggingService {
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    final logEntry = {
      'level': 'error',
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      'error': error?.toString(),
      'stackTrace': stackTrace?.toString(),
      'context': context,
    };

    // 开发环境：打印到控制台
    if (kDebugMode) {
      print('❌ ERROR: ${jsonEncode(logEntry)}');
    }

    // 生产环境：写入文件或上报
    _writeToFile(logEntry);
  }

  void warning(String message, {Map<String, dynamic>? context}) {
    final logEntry = {
      'level': 'warning',
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      'context': context,
    };

    if (kDebugMode) {
      print('⚠️  WARNING: ${jsonEncode(logEntry)}');
    }

    _writeToFile(logEntry);
  }

  void info(String message, {Map<String, dynamic>? context}) {
    final logEntry = {
      'level': 'info',
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      'context': context,
    };

    if (kDebugMode) {
      print('ℹ️  INFO: ${jsonEncode(logEntry)}');
    }
  }

  Future<void> _writeToFile(Map<String, dynamic> logEntry) async {
    // 写入日志文件（未来）
    // final file = await _getLogFile();
    // await file.writeAsString(jsonEncode(logEntry) + '\n', mode: FileMode.append);
  }
}
```

---

## 测试策略

### 单元测试：异常处理

```dart
// test/data/repositories/transaction_repository_test.dart

void main() {
  group('TransactionRepository 异常处理', () {
    late TransactionRepositoryImpl repository;
    late MockAppDatabase mockDb;
    late MockErrorLogger mockLogger;

    setUp(() {
      mockDb = MockAppDatabase();
      mockLogger = MockErrorLogger();
      repository = TransactionRepositoryImpl(mockDb, mockLogger);
    });

    test('创建交易时数据库异常应转换为DatabaseException', () async {
      // Arrange
      when(() => mockDb.into(any()).insert(any()))
          .thenThrow(SqliteException(19, 'UNIQUE constraint failed'));

      final dto = CreateTransactionDto(/* ... */);

      // Act & Assert
      expect(
        () => repository.create(dto),
        throwsA(isA<DatabaseException>()
            .having((e) => e.code, 'code', 'DB_CONSTRAINT_VIOLATION')),
      );

      // 验证错误日志
      verify(() => mockLogger.error(any(), any(), any())).called(1);
    });

    test('加密失败应抛出EncryptionException', () async {
      // Arrange
      when(() => FieldEncryption.encrypt(any()))
          .thenThrow(Exception('Encryption failed'));

      final dto = CreateTransactionDto(note: 'secret');

      // Act & Assert
      expect(
        () => repository.create(dto),
        throwsA(isA<EncryptionException>()
            .having((e) => e.code, 'code', 'ENCRYPT_FAILED')),
      );
    });

    test('未找到交易应抛出NotFoundException', () async {
      // Arrange
      when(() => mockDb.select(any()).getSingleOrNull())
          .thenAnswer((_) async => null);

      // Act & Assert
      expect(
        () => repository.findById('non-existent-id'),
        throwsA(isA<NotFoundException>()
            .having((e) => e.code, 'code', 'TRANSACTION_NOT_FOUND')),
      );
    });
  });
}
```

### 集成测试：端到端错误流

```dart
// test/integration/error_handling_test.dart

void main() {
  group('端到端错误处理', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(/* ... */);
    });

    tearDown(() {
      container.dispose();
    });

    test('预算超限异常应正确传播到UI层', () async {
      // Arrange
      final notifier = container.read(transactionNotifierProvider.notifier);

      // 设置预算限制
      await container.read(budgetRepositoryProvider).create(
            Budget(
              categoryId: 'food',
              limit: 50000,  // ¥500
              year: 2026,
              month: 2,
            ),
          );

      // 创建交易（超出预算）
      final dto = CreateTransactionDto(
        bookId: 'default',
        amount: 60000,  // ¥600
        type: TransactionType.expense,
        categoryId: 'food',
        timestamp: DateTime(2026, 2, 3),
      );

      // Act
      await notifier.create(dto);

      // Assert
      final state = container.read(transactionNotifierProvider);

      expect(state.hasError, isTrue);
      expect(state.error, isA<BusinessRuleFailure>());

      final failure = state.error as BusinessRuleFailure;
      expect(failure.message, contains('预算超限'));
    });

    test('数据库错误应转换为DataFailure', () async {
      // Arrange
      final notifier = container.read(transactionNotifierProvider.notifier);

      // 模拟数据库错误（通过注入错误）
      container.read(transactionRepositoryProvider).close();

      final dto = CreateTransactionDto(/* ... */);

      // Act
      await notifier.create(dto);

      // Assert
      final state = container.read(transactionNotifierProvider);

      expect(state.hasError, isTrue);
      expect(state.error, isA<DataFailure>());

      final failure = state.error as DataFailure;
      expect(failure.message, contains('数据操作失败'));
      expect(failure.action, isNotNull);  // 应有重试操作
    });
  });
}
```

---

## 总结

### 错误处理最佳实践

✅ **DO（推荐做法）**

1. **明确的分层责任**
   - Data层：捕获并转换所有技术异常
   - Domain层：仅抛出业务异常
   - Presentation层：转换为用户友好消息

2. **详细的错误上下文**
   - 附加元数据（表名、ID等）
   - 保留原始异常和堆栈跟踪
   - 记录详细日志

3. **用户友好的错误消息**
   - 避免技术术语
   - 提供可操作的解决方案
   - 区分可恢复和不可恢复错误

4. **优雅的降级**
   - 自动重试机制
   - 缓存降级
   - 默认值兜底

❌ **DON'T（避免做法）**

1. **不要捕获异常后静默忽略**
   ```dart
   // ❌ 错误
   try {
     await operation();
   } catch (e) {
     // 静默忽略
   }
   ```

2. **不要在Domain层捕获Repository异常**
   ```dart
   // ❌ 错误
   try {
     await repository.create(dto);
   } on RepositoryException {
     // Domain层不应处理技术异常
   }
   ```

3. **不要向用户显示技术错误**
   ```dart
   // ❌ 错误
   showError('SqliteException: UNIQUE constraint failed');

   // ✅ 正确
   showError('该记录已存在，请修改后重试');
   ```

4. **不要丢失错误上下文**
   ```dart
   // ❌ 错误
   throw Exception('操作失败');

   // ✅ 正确
   throw DatabaseException.insertFailed(
     table: 'transactions',
     error: e,
     stackTrace: st,
   );
   ```

---

**下一步阅读**:
- [05_Integration_Patterns.md](./05_Integration_Patterns.md) - 集成模式
- [04_State_Management.md](./04_State_Management.md) - 状态管理

---

**文档维护**:
- 最后更新: 2026-02-03
- 维护者: 架构团队
- 版本: 1.0
