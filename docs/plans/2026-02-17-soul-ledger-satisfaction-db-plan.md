# 灵魂账本满意度（1-10）数据库管理技术方案

**日期**: 2026-02-17  
**范围**: 后台数据库管理（Drift Schema / DAO / Analytics Query）  
**目标**: 为灵魂账本交易增加满意度字段，支持后续统计分析，数据层强制约束并默认 5 分。

---

## 1. 需求边界与数据规则

### 1.1 业务规则
- 当交易属于 `ledgerType = soul` 时，必须记录满意度。
- 满意度取值范围固定为 `1..10`。
- 默认值为 `5`。

### 1.2 数据层约束策略
- 本需求直接使用强约束。
- 字段定义为 `NOT NULL` + `DEFAULT 5` + `CHECK(1 <= value <= 10)`。
- 不考虑历史迁移兼容逻辑。

---

## 2. 数据库 Schema 变更设计

### 2.1 Transactions 新增字段
文件: `lib/data/tables/transactions_table.dart`

现有字段（第6-32行）之后，新增列（非空，默认 5）:

```dart
// 在 isDeleted 之后、primaryKey 之前添加:
IntColumn get soulSatisfaction =>
    integer().withDefault(const Constant(5))();
```

> **CHECK 约束说明:** Drift 的 `check()` 方法中自引用列（`soulSatisfaction.isBetweenValues(1, 10)`）是边界用法。
> 为避免 code-gen 问题，**推荐使用 table-level 约束替代**:
>
> ```dart
> @override
> List<String> get customConstraints => [
>   'CHECK(soul_satisfaction BETWEEN 1 AND 10)',
> ];
> ```
>
> 实施时先验证生成的 SQL 是否正确，若列级 check 有问题则回退到 table-level。

完整变更 diff:

```dart
// lib/data/tables/transactions_table.dart
@DataClassName('TransactionRow')
class Transactions extends Table {
  // ... 现有字段保持不变 (第6-32行) ...

  // Flags
  BoolColumn get isPrivate => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

+ // Soul ledger satisfaction (1-10, default 5)
+ IntColumn get soulSatisfaction =>
+     integer().withDefault(const Constant(5))();

  @override
  Set<Column> get primaryKey => {id};

+ @override
+ List<String> get customConstraints => [
+   'CHECK(soul_satisfaction BETWEEN 1 AND 10)',
+ ];

  List<TableIndex> get customIndices => [
    // ... 现有 6 个索引保持不变 ...
  ];
}
```

### 2.2 索引设计

**决策：本期不新增索引。**

理由:
- 现有索引已有 `idx_tx_book_timestamp`（`{#bookId, #timestamp}`）和 `idx_tx_ledger_type`（`{#ledgerType}`）。
- 满意度统计查询的数据集已经过 `bookId + ledgerType + timeRange` 过滤，结果集很小（数十到数百条），`GROUP BY soul_satisfaction` 走回表聚合完全够用。
- Transactions 表当前已有 **6 个索引**，移动端每次 INSERT 都要更新所有索引，继续增加会影响快速记账（<3秒目标）。
- 若后续压测显示聚合性能不达标，再按需添加 `{#ledgerType, #soulSatisfaction}` 索引。

---

## 3. Schema 版本策略

文件: `lib/data/app_database.dart`

### 3.1 schemaVersion
- 从 `3` 升至 `4`。

### 3.2 迁移策略

**即使 app 未发布（v0.1.0），仍需添加迁移脚本。** 原因：开发团队成员本地可能已有 v3 数据库，无迁移脚本会导致 Drift 抛异常或丢数据。

```dart
// lib/data/app_database.dart
@override
int get schemaVersion => 4;

@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 3) {
        await migrator.addColumn(categories, categories.budgetAmount);
      }
+     if (from < 4) {
+       await migrator.addColumn(transactions, transactions.soulSatisfaction);
+     }
    },
  );
}
```

> **注意:** `addColumn` 会自动应用 `DEFAULT 5`，现有行将获得默认值。
> 但 `CHECK` 约束通过 `customConstraints` 定义，只在建表时生效；`addColumn` 不会追加 CHECK。
> 对于 v3→v4 的升级用户，需要在应用层（UseCase）保证约束。这是可接受的，因为数据入口只有 UseCase。

---

## 4. 完整变更链路（逐文件）

> 以下按数据流方向（外→内→外）列出所有需要变更的文件。

### 4.1 Domain Model — `Transaction`

**文件:** `lib/features/accounting/domain/models/transaction.dart`

在现有 Flags 区块（第35-37行 `isPrivate`/`isSynced`/`isDeleted`）之后新增:

```dart
@freezed
abstract class Transaction with _$Transaction {
  const factory Transaction({
    // ... 现有字段保持不变 ...

    // Flags
    @Default(false) bool isPrivate,
    @Default(false) bool isSynced,
    @Default(false) bool isDeleted,

+   // Soul ledger satisfaction score (1-10, default 5)
+   @Default(5) int soulSatisfaction,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}
```

**要点:**
- 使用 `@Default(5)` 确保 Freezed `copyWith` 和 `fromJson` 都有默认值
- `fromJson` 兼容旧 JSON（无 `soulSatisfaction` 字段时自动取默认值 5）— 这对备份恢复至关重要

### 4.2 UseCase 入参 — `CreateTransactionParams`

**文件:** `lib/application/accounting/create_transaction_use_case.dart`（第18-36行）

```dart
class CreateTransactionParams {
  final String bookId;
  final int amount;
  final TransactionType type;
  final String categoryId;
  final DateTime? timestamp;
  final String? note;
  final String? merchant;
+ final int? soulSatisfaction; // null = 使用默认值 5

  const CreateTransactionParams({
    required this.bookId,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.timestamp,
    this.note,
    this.merchant,
+   this.soulSatisfaction,
  });
}
```

### 4.3 UseCase 校验 — `CreateTransactionUseCase.execute()`

**文件:** `lib/application/accounting/create_transaction_use_case.dart`

在现有步骤 4（分类，第97-101行）之后、步骤 5（获取 prevHash，第104行）之前，插入满意度校验:

```dart
    // 4. Classify transaction (dual ledger)
    final classification = await _classificationService.classify(
      categoryId: params.categoryId,
      merchant: params.merchant,
      note: params.note,
    );

+   // 4.5 Resolve & validate soul satisfaction
+   final int soulSatisfaction;
+   if (classification.ledgerType == LedgerType.soul) {
+     soulSatisfaction = params.soulSatisfaction ?? 5;
+     if (soulSatisfaction < 1 || soulSatisfaction > 10) {
+       return Result.error(
+         'soulSatisfaction must be between 1 and 10, got $soulSatisfaction',
+       );
+     }
+   } else {
+     // 非灵魂账本统一写入默认值
+     soulSatisfaction = 5;
+   }

    // 5. Get previous hash for chain
    final prevHash = ...
```

在步骤 8（构建 domain 对象，第129-143行）中添加字段:

```dart
    final transaction = Transaction(
      // ... 现有字段 ...
      merchant: params.merchant,
+     soulSatisfaction: soulSatisfaction,
    );
```

### 4.4 DAO 写入 — `TransactionDao.insertTransaction()`

**文件:** `lib/data/daos/transaction_dao.dart`（第11-51行）

```dart
  Future<void> insertTransaction({
    // ... 现有参数 ...
    bool isPrivate = false,
+   int soulSatisfaction = 5,
  }) async {
    await _db
        .into(_db.transactions)
        .insert(
          TransactionsCompanion.insert(
            // ... 现有字段 ...
            isPrivate: Value(isPrivate),
+           soulSatisfaction: Value(soulSatisfaction),
          ),
        );
  }
```

### 4.5 Repository 写入 — `TransactionRepositoryImpl.insert()`

**文件:** `lib/data/repositories/transaction_repository_impl.dart`（第52-68行）

```dart
    await _dao.insertTransaction(
      // ... 现有字段 ...
      isPrivate: transaction.isPrivate,
+     soulSatisfaction: transaction.soulSatisfaction,
    );
```

### 4.6 Repository 读取 — `TransactionRepositoryImpl._toModel()`

**文件:** `lib/data/repositories/transaction_repository_impl.dart`（第141-161行）

```dart
  Future<Transaction> _toModel(TransactionRow row) async {
    // ... 现有解密逻辑 ...

    return Transaction(
      // ... 现有字段 ...
      isPrivate: row.isPrivate,
      isSynced: row.isSynced,
      isDeleted: row.isDeleted,
+     soulSatisfaction: row.soulSatisfaction,
    );
  }
```

### 4.7 DemoDataService — 生成演示数据

**文件:** `lib/application/analytics/demo_data_service.dart`（第131-149行）

在 `_generateMonthData` 的 expense 插入逻辑中添加满意度:

```dart
          final ledgerType = _classifyLedger(pattern.categoryId);

+         // 灵魂账本交易生成随机满意度（1-10），生存账本统一默认 5
+         final satisfaction = ledgerType == 'soul'
+             ? 1 + _random.nextInt(10) // 1..10
+             : 5;

          await transactionDao.insertTransaction(
            // ... 现有字段 ...
            ledgerType: ledgerType,
+           soulSatisfaction: satisfaction,
            timestamp: DateTime(...),
            // ...
          );
```

### 4.8 备份恢复兼容

**影响文件:**
- `lib/application/settings/export_backup_use_case.dart`
- `lib/application/settings/import_backup_use_case.dart`

**导出（ExportBackupUseCase）:** 无需改动。
- 第62行 `tx.toJson()` 会自动包含 `soulSatisfaction` 字段（Freezed 生成的 `toJson` 包含所有字段）。

**导入（ImportBackupUseCase）:** 无需改动。
- 第150行 `Transaction.fromJson(txJson)` 依赖 Freezed 生成的 `fromJson`。
- 因为 Domain Model 使用了 `@Default(5)`，当旧备份 JSON 缺少 `soulSatisfaction` 字段时，`fromJson` 自动填充默认值 `5`。

**验证点:** 实施后需补充测试用例：
```dart
test('fromJson without soulSatisfaction defaults to 5', () {
  final json = {
    'id': 'tx1', 'bookId': 'b1', 'deviceId': 'd1',
    'amount': 1000, 'type': 'expense', 'categoryId': 'c1',
    'ledgerType': 'soul', 'timestamp': '2026-02-17T00:00:00.000',
    'currentHash': 'hash1', 'createdAt': '2026-02-17T00:00:00.000',
    // 注意: 没有 soulSatisfaction 字段
  };
  final tx = Transaction.fromJson(json);
  expect(tx.soulSatisfaction, 5); // @Default(5) 生效
});
```

---

## 5. 统计查询扩展（Analytics DAO）

文件: `lib/data/daos/analytics_dao.dart`

### 5.0 新增 DTO 类

在文件顶部（现有 `LedgerTotalResult` 之后）新增:

```dart
/// Aggregate result for soul satisfaction overview.
class SatisfactionOverviewResult {
  final double avgSatisfaction;
  final int count;

  const SatisfactionOverviewResult({
    required this.avgSatisfaction,
    required this.count,
  });
}

/// Aggregate result for satisfaction score distribution.
class SatisfactionDistributionResult {
  final int score;
  final int count;

  const SatisfactionDistributionResult({
    required this.score,
    required this.count,
  });
}

/// Aggregate result for daily satisfaction trend.
class DailySatisfactionResult {
  final DateTime date;
  final double avgSatisfaction;
  final int count;

  const DailySatisfactionResult({
    required this.date,
    required this.avgSatisfaction,
    required this.count,
  });
}
```

### 5.1 灵魂账本满意度总览

```dart
  /// Get average satisfaction and count for soul transactions in a date range.
  Future<SatisfactionOverviewResult> getSoulSatisfactionOverview({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final results = await _db
        .customSelect(
          'SELECT AVG(soul_satisfaction) as avg_sat, COUNT(*) as cnt '
          'FROM transactions '
          'WHERE book_id = ? AND ledger_type = \'soul\' AND type = \'expense\' '
          'AND is_deleted = 0 '
          'AND timestamp >= ? AND timestamp <= ?',
          variables: [
            Variable.withString(bookId),
            Variable.withDateTime(startDate),
            Variable.withDateTime(endDate),
          ],
        )
        .get();

    if (results.isEmpty) {
      return const SatisfactionOverviewResult(avgSatisfaction: 0, count: 0);
    }

    final row = results.first;
    return SatisfactionOverviewResult(
      avgSatisfaction: (row.read<double?>('avg_sat') ?? 0),
      count: row.read<int>('cnt'),
    );
  }
```

### 5.2 满意度分布（1..10）

```dart
  /// Get satisfaction score distribution for soul transactions.
  Future<List<SatisfactionDistributionResult>> getSatisfactionDistribution({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final results = await _db
        .customSelect(
          'SELECT soul_satisfaction as score, COUNT(*) as cnt '
          'FROM transactions '
          'WHERE book_id = ? AND ledger_type = \'soul\' AND type = \'expense\' '
          'AND is_deleted = 0 '
          'AND timestamp >= ? AND timestamp <= ? '
          'GROUP BY soul_satisfaction '
          'ORDER BY soul_satisfaction ASC',
          variables: [
            Variable.withString(bookId),
            Variable.withDateTime(startDate),
            Variable.withDateTime(endDate),
          ],
        )
        .get();

    return results
        .map(
          (row) => SatisfactionDistributionResult(
            score: row.read<int>('score'),
            count: row.read<int>('cnt'),
          ),
        )
        .toList();
  }
```

### 5.3 满意度时间趋势（日）

```dart
  /// Get daily average satisfaction trend for soul transactions.
  Future<List<DailySatisfactionResult>> getDailySatisfactionTrend({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final results = await _db
        .customSelect(
          'SELECT DATE(timestamp, \'unixepoch\', \'localtime\') as day, '
          'AVG(soul_satisfaction) as avg_sat, COUNT(*) as cnt '
          'FROM transactions '
          'WHERE book_id = ? AND ledger_type = \'soul\' AND type = \'expense\' '
          'AND is_deleted = 0 '
          'AND timestamp >= ? AND timestamp <= ? '
          'GROUP BY day '
          'ORDER BY day ASC',
          variables: [
            Variable.withString(bookId),
            Variable.withDateTime(startDate),
            Variable.withDateTime(endDate),
          ],
        )
        .get();

    return results
        .map(
          (row) => DailySatisfactionResult(
            date: DateTime.parse(row.read<String>('day')),
            avgSatisfaction: row.read<double?>('avg_sat') ?? 0,
            count: row.read<int>('cnt'),
          ),
        )
        .toList();
  }
```

---

## 6. 查询口径定义（防止后续分析歧义）

- 满意度统计默认仅包含:
  - `ledgerType = soul`
  - `type = expense`
  - `isDeleted = false`
- 字段非空，均值直接计算。
- 报表必须展示样本量:
  - `count`

---

## 7. 测试方案

### 7.1 Schema 约束测试

文件: `test/unit/data/transactions_table_test.dart`

```dart
// 使用内存数据库验证
final db = AppDatabase.forTesting();

test('soulSatisfaction has default value 5', () async {
  await dao.insertTransaction(
    // ... 必填字段 ...
    // 不传 soulSatisfaction
  );
  final row = await dao.findById('tx1');
  expect(row!.soulSatisfaction, 5);
});

test('soulSatisfaction accepts value 1 (lower bound)', () async {
  await dao.insertTransaction(/* ... */ soulSatisfaction: 1);
  final row = await dao.findById('tx1');
  expect(row!.soulSatisfaction, 1);
});

test('soulSatisfaction accepts value 10 (upper bound)', () async {
  await dao.insertTransaction(/* ... */ soulSatisfaction: 10);
  final row = await dao.findById('tx1');
  expect(row!.soulSatisfaction, 10);
});

test('soulSatisfaction rejects value 0 (below range)', () async {
  // CHECK 约束应使此操作失败
  expect(
    () => dao.insertTransaction(/* ... */ soulSatisfaction: 0),
    throwsA(isA<Exception>()),
  );
});

test('soulSatisfaction rejects value 11 (above range)', () async {
  expect(
    () => dao.insertTransaction(/* ... */ soulSatisfaction: 11),
    throwsA(isA<Exception>()),
  );
});
```

### 7.2 DAO 单测

文件: `test/unit/data/transaction_dao_satisfaction_test.dart`

- 插入 soul + 评分（1/5/10）→ 读取验证值正确
- 插入 survival + 不传评分 → 默认入库为 `5`
- `findByBookId` 返回的行包含 soulSatisfaction 字段

### 7.3 UseCase 校验测试

文件: `test/unit/application/create_transaction_satisfaction_test.dart`

```dart
test('soul transaction with valid satisfaction (7) succeeds', () async {
  final result = await useCase.execute(CreateTransactionParams(
    bookId: 'b1', amount: 1000, type: TransactionType.expense,
    categoryId: 'cat_entertainment',
    soulSatisfaction: 7,
  ));
  expect(result.isSuccess, true);
  expect(result.data!.soulSatisfaction, 7);
});

test('soul transaction with satisfaction 0 returns error', () async {
  final result = await useCase.execute(CreateTransactionParams(
    bookId: 'b1', amount: 1000, type: TransactionType.expense,
    categoryId: 'cat_entertainment',
    soulSatisfaction: 0,
  ));
  expect(result.isSuccess, false);
  expect(result.error, contains('between 1 and 10'));
});

test('soul transaction without satisfaction defaults to 5', () async {
  final result = await useCase.execute(CreateTransactionParams(
    bookId: 'b1', amount: 1000, type: TransactionType.expense,
    categoryId: 'cat_entertainment',
    // soulSatisfaction 不传
  ));
  expect(result.isSuccess, true);
  expect(result.data!.soulSatisfaction, 5);
});

test('survival transaction always gets satisfaction 5', () async {
  final result = await useCase.execute(CreateTransactionParams(
    bookId: 'b1', amount: 1000, type: TransactionType.expense,
    categoryId: 'cat_food',
    soulSatisfaction: 9, // 即使传了 9
  ));
  expect(result.isSuccess, true);
  expect(result.data!.soulSatisfaction, 5); // 被强制覆盖为 5
});
```

### 7.4 Analytics 聚合测试

文件: `test/unit/data/analytics_dao_satisfaction_test.dart`

- 构造混合数据（soul/survival、不同评分 1-10、已删除/未删除）
- 验证 `getSoulSatisfactionOverview`: 平均分准确、样本数排除 survival 和 isDeleted
- 验证 `getSatisfactionDistribution`: 分布准确、10 个桶都能覆盖
- 验证 `getDailySatisfactionTrend`: 日粒度聚合正确、跨天边界正确

### 7.5 备份恢复兼容测试

文件: `test/unit/domain/transaction_json_compat_test.dart`

```dart
test('fromJson without soulSatisfaction defaults to 5', () {
  final json = {
    'id': 'tx1', 'bookId': 'b1', 'deviceId': 'd1',
    'amount': 1000, 'type': 'expense', 'categoryId': 'c1',
    'ledgerType': 'soul', 'timestamp': '2026-02-17T00:00:00.000',
    'currentHash': 'h1', 'createdAt': '2026-02-17T00:00:00.000',
  };
  final tx = Transaction.fromJson(json);
  expect(tx.soulSatisfaction, 5);
});

test('fromJson with soulSatisfaction preserves value', () {
  final json = {
    'id': 'tx1', 'bookId': 'b1', 'deviceId': 'd1',
    'amount': 1000, 'type': 'expense', 'categoryId': 'c1',
    'ledgerType': 'soul', 'timestamp': '2026-02-17T00:00:00.000',
    'currentHash': 'h1', 'createdAt': '2026-02-17T00:00:00.000',
    'soulSatisfaction': 8,
  };
  final tx = Transaction.fromJson(json);
  expect(tx.soulSatisfaction, 8);
});

test('toJson includes soulSatisfaction', () {
  final tx = Transaction(/* ... */ soulSatisfaction: 9);
  final json = tx.toJson();
  expect(json['soulSatisfaction'], 9);
});
```

---

## 8. 发布与回滚

## 8.1 发布顺序
1. 上线包含新 schema（v4）的版本。
2. 上线 UI 评分入口与 UseCase 校验。
3. 上线 analytics 报表消费逻辑。

## 8.2 回滚策略
- 本需求不定义历史版本回滚兼容策略（因不考虑迁移）。

---

## 9. 实施任务清单

按实施顺序排列，每个步骤标注受影响文件:

| # | 任务 | 文件 | 类型 |
|---|------|------|------|
| 1 | Drift 表结构新增 `soulSatisfaction` 列 + CHECK 约束 | `lib/data/tables/transactions_table.dart` | 修改 |
| 2 | `AppDatabase` 升版至 v4 + 添加迁移脚本 | `lib/data/app_database.dart` | 修改 |
| 3 | `flutter pub run build_runner build --delete-conflicting-outputs` | — | 命令 |
| 4 | Domain `Transaction` 添加 `@Default(5) int soulSatisfaction` | `lib/features/accounting/domain/models/transaction.dart` | 修改 |
| 5 | `flutter pub run build_runner build --delete-conflicting-outputs` | — | 命令 |
| 6 | `TransactionDao.insertTransaction()` 增加参数 | `lib/data/daos/transaction_dao.dart` | 修改 |
| 7 | `TransactionRepositoryImpl.insert()` 传入字段 | `lib/data/repositories/transaction_repository_impl.dart` | 修改 |
| 8 | `TransactionRepositoryImpl._toModel()` 映射字段 | `lib/data/repositories/transaction_repository_impl.dart` | 修改 |
| 9 | `CreateTransactionParams` 增加 `soulSatisfaction` | `lib/application/accounting/create_transaction_use_case.dart` | 修改 |
| 10 | `CreateTransactionUseCase.execute()` 步骤 4.5 增加校验 | `lib/application/accounting/create_transaction_use_case.dart` | 修改 |
| 11 | `DemoDataService._generateMonthData()` 添加满意度 | `lib/application/analytics/demo_data_service.dart` | 修改 |
| 12 | Analytics DAO 新增 3 个查询 + 3 个 DTO | `lib/data/daos/analytics_dao.dart` | 修改 |
| 13 | 单测：Schema 约束 | `test/unit/data/transactions_table_test.dart` | 新建 |
| 14 | 单测：DAO 插入/读取/边界 | `test/unit/data/transaction_dao_satisfaction_test.dart` | 新建 |
| 15 | 单测：UseCase 校验逻辑 | `test/unit/application/create_transaction_satisfaction_test.dart` | 新建 |
| 16 | 单测：Analytics 聚合查询 | `test/unit/data/analytics_dao_satisfaction_test.dart` | 新建 |
| 17 | 单测：备份恢复 fromJson 兼容 | `test/unit/domain/transaction_json_compat_test.dart` | 新建 |
| 18 | `flutter analyze` + `dart format .` | — | 命令 |

**变更文件总计:**
- 修改: 7 个文件
- 新建: 5 个测试文件
- 未变更（自动兼容）: `export_backup_use_case.dart`, `import_backup_use_case.dart`, `transaction_repository.dart`（接口层无变化）

---

## 10. 风险与决策记录

| 项目 | 类型 | 内容 | 对策 |
|------|------|------|------|
| 索引过多影响写入 | 风险 | Transactions 已有 6 索引 | **本期不新增索引**，压测后按需添加 |
| CHECK 约束 Drift 语法 | 风险 | 列级 `check()` 自引用可能 code-gen 异常 | 优先用 `customConstraints` table-level 约束 |
| 迁移丢数据 | 风险 | 开发环境 v3→v4 无迁移脚本 | **添加 `addColumn` 迁移**（详见 3.2） |
| 旧备份无字段 | 风险 | 旧版本导出的 JSON 无 `soulSatisfaction` | Freezed `@Default(5)` 自动兜底 + 测试覆盖 |
| 强约束策略 | 决策 | `NOT NULL + DEFAULT 5 + CHECK 1..10` | 需求明确"强制输入"，数据层直接约束 |
| 非 soul 交易写默认值 | 决策 | `ledgerType != soul` 时写入 5 | UseCase 层统一处理，不依赖 UI 传值 |
