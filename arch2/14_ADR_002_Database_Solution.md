# ADR-002: 选择Drift+SQLCipher作为数据库方案

**状态:** ✅ 已接受
**日期:** 2026-02-03
**决策者:** 技术架构团队
**影响范围:** 数据持久化层、安全架构

---

## 背景与问题陈述

Home Pocket应用需要一个本地数据库解决方案,用于存储财务数据。该方案必须满足以下需求:

### 业务需求
- **隐私优先:** 所有财务数据存储在本地,不上传到云端
- **离线可用:** 完全离线工作,无需网络连接
- **数据加密:** 静态数据必须加密存储
- **复杂查询:** 支持关系查询、聚合统计等
- **数据完整性:** 确保数据一致性和完整性

### 技术要求
- 类型安全的查询(编译时检查)
- 支持数据库级加密
- 良好的迁移支持
- 高性能(读写性能)
- Flutter生态集成良好
- 支持事务(ACID)
- 便于测试

---

## 决策驱动因素

### 关键考虑因素

1. **安全性** - 加密存储是硬性要求
2. **类型安全** - 减少SQL注入和运行时错误
3. **开发效率** - 类型安全的ORM,减少样板代码
4. **性能** - 良好的读写性能,支持大量数据
5. **可靠性** - 成熟稳定的解决方案
6. **迁移支持** - 版本升级时的数据迁移

---

## 备选方案分析

### 方案1: Drift + SQLCipher ✅ (选择)

**技术栈:**
- **Drift 2.14+** (原moor) - 类型安全的Flutter ORM
- **SQLCipher** - 透明的SQLite加密
- **sqlite3_flutter_libs** - SQLite原生库
- **sqlcipher_flutter_libs** - SQLCipher原生库

**优势:**

1. **类型安全查询** ✅✅✅
   ```dart
   // 编译时类型检查
   final query = select(transactions)
     ..where((t) => t.bookId.equals(bookId))
     ..where((t) => t.amount.isBiggerThanValue(100));
   ```

2. **透明加密** ✅✅✅
   ```dart
   // 整个数据库文件AES-256加密
   rawDb.execute("PRAGMA key = '$encryptionKey'");
   ```

3. **代码生成** ✅✅✅
   ```dart
   @DriftDatabase(tables: [Transactions, Categories])
   class AppDatabase extends _$AppDatabase {
     // 自动生成DAO、查询构建器
   }
   ```

4. **优秀的迁移支持** ✅✅✅
   ```dart
   @override
   MigrationStrategy get migration => MigrationStrategy(
     onCreate: (m) => m.createAll(),
     onUpgrade: (m, from, to) async {
       if (from == 1 && to == 2) {
         await m.addColumn(transactions, transactions.newColumn);
       }
     },
   );
   ```

5. **Stream支持** ✅✅✅
   ```dart
   // 实时响应数据变化
   Stream<List<Transaction>> watchTransactions(String bookId) {
     return (select(transactions)
       ..where((t) => t.bookId.equals(bookId)))
       .watch();
   }
   ```

6. **事务支持** ✅✅✅
   ```dart
   await transaction(() async {
     await into(transactions).insert(tx);
     await updateBookBalance(tx.bookId);
   });
   ```

**劣势:**
- ⚠️ 学习曲线中等(需要理解Drift DSL)
- ⚠️ 代码生成增加构建时间
- ⚠️ 包体积增加(SQLCipher约2-3MB)

**性能指标:**
- 插入: ~1000 tx/s
- 查询: ~5000 tx/s
- 加密overhead: ~5-10%

**安全特性:**
- AES-256-CBC加密
- PBKDF2密钥派生(256,000次迭代)
- HMAC-SHA512完整性验证
- 经过FIPS 140-2验证

**代码示例:**
```dart
// Table定义
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text()();
  IntColumn get amount => integer()();
  DateTimeColumn get timestamp => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Index> get customIndexes => [
    Index('tx_book_timestamp', [bookId, timestamp]),
  ];
}

// 数据库配置
@DriftDatabase(tables: [Transactions, Categories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'homepocket.db'));

      return NativeDatabase.createInBackground(
        file,
        setup: (rawDb) {
          // SQLCipher加密
          rawDb.execute("PRAGMA key = '$key'");
          // 性能优化
          rawDb.execute("PRAGMA journal_mode = WAL");
        },
      );
    });
  }
}

// DAO
@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(AppDatabase db) : super(db);

  Future<List<Transaction>> getTransactions(String bookId) {
    return (select(transactions)
      ..where((t) => t.bookId.equals(bookId))
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
      .get();
  }

  Stream<List<Transaction>> watchTransactions(String bookId) {
    return (select(transactions)
      ..where((t) => t.bookId.equals(bookId)))
      .watch();
  }
}
```

---

### 方案2: Hive + 自定义加密

**技术栈:**
- Hive - NoSQL键值存储
- 自定义AES加密层

**优势:**
- ✅ 性能优秀(纯内存操作)
- ✅ 学习曲线平缓
- ✅ 包体积小

**劣势:**
- ❌ **NoSQL限制** - 不支持复杂关系查询
- ❌ **无SQL支持** - 无法使用JOIN、GROUP BY等
- ❌ **自定义加密** - 需要自己实现,安全性未经验证
- ❌ **迁移困难** - 缺少内置迁移机制
- ❌ **类型安全性弱** - 需要手动序列化/反序列化

**代码示例:**
```dart
// Hive模型
@HiveType(typeId: 1)
class Transaction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int amount;

  // 需要手动加密
  @HiveField(2)
  String encryptedNote;
}

// 查询困难
// ❌ 无法执行: SELECT * FROM transactions WHERE amount > 100
final allTxs = box.values.toList();
final filtered = allTxs.where((tx) => tx.amount > 100).toList();
```

**为何不选择:**
- 财务应用需要复杂查询(按时间聚合、分类统计等)
- NoSQL不适合关系数据模型
- 自定义加密风险高,未经审计

---

### 方案3: Isar + 加密

**技术栈:**
- Isar - 高性能NoSQL数据库
- 内置加密支持

**优势:**
- ✅ 极高性能(比SQLite快10倍)
- ✅ 内置加密
- ✅ 支持索引和查询

**劣势:**
- ❌ **NoSQL限制** - 不支持JOIN等SQL特性
- ❌ **生态不成熟** - 较新的项目(2021年)
- ❌ **社区较小** - 问题解决难度大
- ❌ **迁移未知** - 数据库迁移机制不清晰
- ❌ **加密细节不透明** - 加密实现未开源

**代码示例:**
```dart
@collection
class Transaction {
  Id id = Isar.autoIncrement;

  late int amount;
  late DateTime timestamp;

  @Index()
  late String bookId;
}

// 查询
final txs = await isar.transactions
  .filter()
  .bookIdEqualTo(bookId)
  .amountGreaterThan(100)
  .findAll();
```

**为何不选择:**
- 生态不够成熟,存在未知风险
- 加密实现不透明,安全性存疑
- 复杂查询支持不如SQL

---

### 方案4: sqflite + SQLCipher

**技术栈:**
- sqflite - Flutter的SQLite插件
- SQLCipher加密

**优势:**
- ✅ 广泛使用,生态成熟
- ✅ SQLCipher透明加密

**劣势:**
- ❌ **无类型安全** - 需要手写SQL字符串
- ❌ **SQL注入风险** - 字符串拼接容易出错
- ❌ **样板代码多** - 需要大量手动序列化/反序列化
- ❌ **无编译时检查** - 运行时才发现SQL错误

**代码示例:**
```dart
// ❌ 类型不安全,易出错
final txs = await db.rawQuery(
  'SELECT * FROM transactions WHERE book_id = ? AND amount > ?',
  [bookId, 100],
);

// ❌ 手动序列化
final transactions = txs.map((map) => Transaction(
  id: map['id'] as String,
  amount: map['amount'] as int,
  // ...
)).toList();
```

**为何不选择:**
- 缺少类型安全,容易引入bug
- 开发效率低,需要大量样板代码
- Drift提供了更好的替代方案

---

## 决策对比矩阵

| 特性 | Drift+SQLCipher | Hive+加密 | Isar | sqflite+SQLCipher |
|------|----------------|-----------|------|-------------------|
| 类型安全 | ✅✅✅ | ⚠️ | ✅✅ | ❌ |
| SQL支持 | ✅✅✅ | ❌ | ⚠️ | ✅✅✅ |
| 加密安全 | ✅✅✅ | ⚠️ | ⚠️ | ✅✅✅ |
| 迁移支持 | ✅✅✅ | ⚠️ | ⚠️ | ✅✅ |
| 性能 | ✅✅ | ✅✅✅ | ✅✅✅ | ✅✅ |
| 开发效率 | ✅✅✅ | ✅✅ | ✅✅ | ⚠️ |
| 生态成熟度 | ✅✅✅ | ✅✅✅ | ⚠️ | ✅✅✅ |
| 学习曲线 | ✅✅ | ✅✅✅ | ✅✅ | ✅✅ |

**图例:**
- ✅✅✅ 优秀
- ✅✅ 良好
- ✅ 一般
- ⚠️ 较差
- ❌ 很差

---

## 最终决策

**选择 Drift + SQLCipher 组合**

### 核心理由

1. **类型安全 + 编译时检查**
   - 消除SQL字符串拼接错误
   - 编译时发现类型不匹配
   - 自动补全和重构支持

2. **透明加密,行业标准**
   - SQLCipher经过FIPS 140-2验证
   - AES-256加密,安全可靠
   - 无需自定义加密实现

3. **优秀的关系数据库支持**
   - 完整的SQL功能(JOIN、GROUP BY、聚合函数)
   - 适合财务应用的关系数据模型
   - 复杂查询性能优秀

4. **内置迁移系统**
   - 简单的版本升级迁移
   - 自动化schema变更
   - 向后兼容性保证

5. **成熟生态,活跃维护**
   - Simon Binder积极维护
   - 完善的文档和示例
   - 活跃的社区支持

---

## 实施计划

### Phase 1: 依赖配置

```yaml
dependencies:
  drift: ^2.14.0
  sqlite3_flutter_libs: ^0.5.18
  sqlcipher_flutter_libs: ^0.6.0
  path_provider: ^2.1.1

dev_dependencies:
  drift_dev: ^2.14.0
  build_runner: ^2.4.0
```

### Phase 2: 数据库架构设计

```dart
// 1. Table定义
lib/data/datasources/local/tables/
  ├── books.dart
  ├── transactions.dart
  ├── categories.dart
  ├── devices.dart
  └── sync_logs.dart

// 2. Database类
lib/data/datasources/local/database.dart

// 3. DAOs
lib/data/datasources/local/daos/
  ├── transaction_dao.dart
  ├── category_dao.dart
  └── book_dao.dart
```

### Phase 3: 加密配置

```dart
static QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'homepocket.db'));

    return NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        // SQLCipher 4.x配置
        final key = await KeyManager.instance.getDatabaseKey();
        rawDb.execute("PRAGMA key = '$key'");
        rawDb.execute("PRAGMA cipher_page_size = 4096");
        rawDb.execute("PRAGMA kdf_iter = 256000");
        rawDb.execute("PRAGMA cipher_hmac_algorithm = HMAC_SHA512");
        rawDb.execute("PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA512");

        // 性能优化
        rawDb.execute("PRAGMA journal_mode = WAL");
        rawDb.execute("PRAGMA synchronous = NORMAL");
      },
    );
  });
}
```

---

## 后果分析

### 正面影响

1. **安全性提升**
   - 数据库级加密,符合金融应用标准
   - SQLCipher经过充分审计和验证

2. **代码质量提升**
   - 类型安全减少SQL错误
   - 编译时检查捕获bug

3. **开发效率提升**
   - 代码生成减少样板代码
   - 自动化迁移简化版本升级

4. **可维护性提升**
   - 清晰的数据模型定义
   - 统一的数据访问层

### 负面影响

1. **包体积增加**
   - SQLCipher库约2-3MB
   - 对于财务应用,安全性优先,可接受

2. **构建时间增加**
   - 代码生成增加构建时间(约10-20秒)

   **缓解措施:**
   - 使用watch模式增量构建
   - CI/CD缓存build产物

3. **学习成本**
   - 团队需要学习Drift DSL

   **缓解措施:**
   - 内部培训和文档
   - 提供代码模板

4. **性能overhead**
   - 加密解密约5-10%性能损失

   **缓解措施:**
   - 使用WAL模式优化
   - 合理设计索引
   - 批量操作减少I/O

---

## 性能优化策略

### 1. 索引设计

```dart
@override
List<Index> get customIndexes => [
  Index('tx_book_timestamp', [bookId, timestamp]),
  Index('tx_category', [categoryId]),
  Index('tx_ledger_type', [ledgerType]),
];
```

### 2. 批量操作

```dart
await batch((batch) {
  for (final tx in transactions) {
    batch.insert(this.transactions, tx);
  }
});
```

### 3. 查询优化

```dart
// ✅ 使用索引
final txs = await (select(transactions)
  ..where((t) => t.bookId.equals(bookId))
  ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
  ..limit(100))
  .get();

// ❌ 避免全表扫描
final allTxs = await select(transactions).get();
```

---

## 安全考虑

### 1. 密钥管理

```dart
class KeyManager {
  Future<String> getDatabaseKey() async {
    // 从主密钥派生数据库密钥
    final masterKey = await getMasterKey();
    return await _deriveDatabaseKey(masterKey);
  }
}
```

### 2. 完整性验证

```dart
Future<bool> verifyDatabaseIntegrity() async {
  try {
    await customStatement('PRAGMA cipher_integrity_check');
    return true;
  } catch (e) {
    return false;
  }
}
```

### 3. 密钥轮换

```dart
Future<void> rekeyDatabase(String newKey) async {
  await customStatement("PRAGMA rekey = '$newKey'");
}
```

---

## 测试策略

### 单元测试

```dart
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(
      NativeDatabase.memory(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('插入交易', () async {
    final tx = Transaction(...);
    await db.into(db.transactions).insert(tx);

    final result = await db.select(db.transactions).getSingle();
    expect(result.id, equals(tx.id));
  });
}
```

---

## 相关决策

- **ADR-003:** 多层加密策略
- **ADR-004:** CRDT同步模式

---

## 参考资料

### 官方文档
- [Drift官方文档](https://drift.simonbinder.eu/)
- [SQLCipher文档](https://www.zetetic.net/sqlcipher/documentation/)

### 最佳实践
- [Drift最佳实践](https://drift.simonbinder.eu/docs/advanced-features/migrations/)
- [SQLite性能优化](https://www.sqlite.org/performance.html)

---

## 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|---------|------|
| 2026-02-03 | 1.0 | 初始版本 | 架构团队 |

---

**文档维护者:** 技术架构团队
**审核者:** CTO, 安全负责人
**下次Review日期:** 2026-08-03
