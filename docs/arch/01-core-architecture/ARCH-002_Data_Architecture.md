# Home Pocket MVP - 数据架构设计

**文档版本:** 1.0
**创建日期:** 2026-02-03
**状态:** 完成
**作者:** Claude Sonnet 4.5 + senior-architect

---

## 📋 目录

1. [概述](#概述)
2. [Repository模式](#repository模式)
3. [数据模型设计](#数据模型设计)
4. [数据库架构](#数据库架构)
5. [加密策略](#加密策略)
6. [数据流设计](#数据流设计)
7. [数据同步](#数据同步)
8. [数据备份与恢复](#数据备份与恢复)
9. [性能优化](#性能优化)

---

## 概述

### 设计原则

Home Pocket的数据架构遵循以下核心原则：

1. **Local-First（本地优先）**
   - 所有数据默认存储在本地SQLite数据库
   - 应用完全离线可用
   - 同步是可选的增强功能

2. **Privacy by Design（隐私设计）**
   - 多层加密保护（数据库/字段/文件/传输）
   - 零知识架构，数据不离开设备
   - 用户完全控制数据

3. **Data Integrity（数据完整性）**
   - 哈希链确保交易不可篡改
   - 完整性验证机制
   - 审计轨迹

4. **Performance First（性能优先）**
   - 索引优化
   - 查询缓存
   - 分页加载

### 技术选型

| 组件 | 技术 | 版本 | 理由 |
|------|------|------|------|
| 数据库 | SQLite + Drift | Drift 2.14+ | 类型安全、迁移支持、Flutter集成好 |
| 加密 | SQLCipher | 4.5+ | 透明数据库级加密、行业标准 |
| ORM | Drift | 2.14+ | 编译时类型安全、代码生成、SQL支持 |
| 序列化 | Freezed | 2.4+ | 不可变模型、代码生成、性能好 |

---

## Repository模式

### 架构设计原则

Home Pocket 采用 Clean Architecture 的 Repository 模式，**接口与实现分离**：

> **核心规则:**
> - **Repository 接口** 定义在 **Domain 层**（`lib/features/*/domain/repositories/`）
> - **Repository 实现** 位于 **Data 层**（`lib/data/repositories/`）

这种分离确保了：
1. **依赖倒置** - 上层业务逻辑只依赖接口，不依赖具体实现
2. **可测试性** - 可以轻松 mock Repository 进行单元测试
3. **可替换性** - 可以切换不同的数据源实现（本地/远程）

### 目录结构

```
lib/
├── features/
│   └── accounting/
│       └── domain/
│           └── repositories/           # ✅ Repository 接口
│               ├── transaction_repository.dart
│               ├── category_repository.dart
│               └── book_repository.dart
│
└── data/
    └── repositories/                   # ✅ Repository 实现
        ├── transaction_repository_impl.dart
        ├── category_repository_impl.dart
        └── book_repository_impl.dart
```

### 接口定义示例

```dart
// lib/features/accounting/domain/repositories/transaction_repository.dart

/// 交易数据仓库接口
///
/// 定义所有交易数据访问操作的契约。
/// 具体实现在 data 层的 TransactionRepositoryImpl。
abstract class TransactionRepository {
  /// 创建交易
  Future<void> insert(Transaction transaction);

  /// 根据ID查询交易
  Future<Transaction?> findById(String id);

  /// 获取账本的所有交易
  Future<List<Transaction>> findByBookId(String bookId);

  /// 更新交易
  Future<void> update(Transaction transaction);

  /// 软删除交易
  Future<void> softDelete(String id);
}
```

### 实现示例

```dart
// lib/data/repositories/transaction_repository_impl.dart

/// 交易仓库实现
///
/// 实现 TransactionRepository 接口，负责：
/// - 数据库 CRUD 操作
/// - 字段加密/解密
/// - 哈希链计算
class TransactionRepositoryImpl implements TransactionRepository {
  final AppDatabase _database;
  final TransactionDao _dao;
  final FieldEncryptionService _encryptionService;
  final HashChainService _hashChainService;

  TransactionRepositoryImpl({
    required AppDatabase database,
    required TransactionDao dao,
    required FieldEncryptionService encryptionService,
    required HashChainService hashChainService,
  }) : _database = database,
       _dao = dao,
       _encryptionService = encryptionService,
       _hashChainService = hashChainService;

  @override
  Future<void> insert(Transaction transaction) async {
    // 1. 计算哈希链
    final currentHash = _hashChainService.calculateTransactionHash(...);

    // 2. 加密敏感字段
    final encryptedNote = await _encryptionService.encrypt(transaction.note);

    // 3. 持久化到数据库
    await _dao.insert(...);
  }

  // ... 其他方法实现
}
```

### Provider 配置

```dart
// lib/features/accounting/presentation/providers/repository_providers.dart

/// TransactionRepository Provider
///
/// 返回类型是接口 TransactionRepository，而非实现类。
/// 这样上层代码只依赖接口，可以轻松替换实现。
@riverpod
TransactionRepository transactionRepository(TransactionRepositoryRef ref) {
  final database = ref.watch(appDatabaseProvider);
  final dao = TransactionDao(database);
  final encryptionService = ref.watch(fieldEncryptionServiceProvider);
  final hashChainService = ref.watch(hashChainServiceProvider);

  return TransactionRepositoryImpl(
    database: database,
    dao: dao,
    encryptionService: encryptionService,
    hashChainService: hashChainService,
  );
}
```

### 相关文档

详细的层次职责划分请参阅：
- [ADR-007: Clean Architecture 层次职责划分](../03-adr/ADR-007_Layer_Responsibilities.md)

---

## 数据模型设计

### 实体关系图（ERD）

```
┌─────────────────┐
│     Books       │  账本（多账本支持）
│─────────────────│
│ id (PK)         │
│ name            │
│ currency        │
│ createdAt       │
│ deviceId (FK)   │────┐
└─────────────────┘    │
         │             │
         │ 1:N         │
         ▼             │
┌─────────────────┐    │
│  Transactions   │    │  交易记录
│─────────────────│    │
│ id (PK)         │    │
│ bookId (FK)     │    │
│ deviceId (FK)   │────┤
│ amount          │    │
│ type            │    │
│ categoryId (FK) │──┐ │
│ ledgerType      │  │ │
│ timestamp       │  │ │
│ note (加密)      │  │ │
│ photoHash       │  │ │
│ prevHash        │  │ │  哈希链
│ currentHash     │  │ │
│ createdAt       │  │ │
│ isPrivate       │  │ │
└─────────────────┘  │ │
         │           │ │
         │ N:1       │ │
         ▼           │ │
┌─────────────────┐  │ │
│   Categories    │  │ │  分类
│─────────────────│  │ │
│ id (PK)         │◀─┘ │
│ name            │    │
│ icon            │    │
│ color           │    │
│ parentId        │    │  三级分类
│ level           │    │
│ isSystem        │    │
└─────────────────┘    │
                       │
┌─────────────────┐    │
│    Devices      │◀───┘  设备（家庭成员）
│─────────────────│
│ id (PK)         │
│ name            │
│ publicKey       │
│ role            │
│ createdAt       │
│ lastSeenAt      │
└─────────────────┘
         │
         │ 1:N
         ▼
┌─────────────────┐
│   SyncLogs      │  同步日志
│─────────────────│
│ id (PK)         │
│ deviceId (FK)   │
│ transactionId   │
│ operation       │
│ vectorClock     │
│ syncedAt        │
└─────────────────┘

┌─────────────────┐
│ SoulAccountCfg  │  灵魂消费配置
│─────────────────│
│ id (PK)         │
│ bookId (FK)     │
│ categoryIds     │  JSON数组
│ celebrationType │
│ threshold       │
│ isEnabled       │
└─────────────────┘
```

### 领域模型定义

#### 1. Book（账本）

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'book.freezed.dart';
part 'book.g.dart';

@freezed
class Book with _$Book {
  const Book._();

  const factory Book({
    required String id,
    required String name,
    required String currency,  // ISO 4217, 如 "CNY", "USD"
    required String deviceId,  // 创建该账本的设备ID
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default(false) bool isArchived,

    // 统计字段（冗余，用于性能）
    @Default(0) int transactionCount,
    @Default(0) int survivalBalance,
    @Default(0) int soulBalance,
  }) = _Book;

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);

  /// 创建新账本
  factory Book.create({
    required String name,
    required String currency,
    required String deviceId,
  }) {
    return Book(
      id: _generateId(),
      name: name,
      currency: currency,
      deviceId: deviceId,
      createdAt: DateTime.now(),
    );
  }

  static String _generateId() {
    // 使用ULID（Universally Unique Lexicographically Sortable Identifier）
    return Ulid().toString();
  }
}
```

#### 2. Transaction（交易记录）

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

enum TransactionType {
  expense,   // 支出
  income,    // 收入
  transfer;  // 转账（未来扩展）
}

enum LedgerType {
  survival,  // 生存账本
  soul;      // 灵魂账本
}

@freezed
class Transaction with _$Transaction {
  const Transaction._();

  const factory Transaction({
    required String id,
    required String bookId,
    required String deviceId,  // 创建该交易的设备ID
    required int amount,       // 金额（分）
    required TransactionType type,
    required String categoryId,
    required LedgerType ledgerType,
    required DateTime timestamp,  // 交易发生时间

    // 可选字段
    String? note,              // 备注（加密存储）
    String? photoHash,         // 照片哈希（照片文件单独加密存储）
    String? merchant,          // 商家名称（用于分类）
    Map<String, dynamic>? metadata,  // 扩展元数据（JSON）

    // 哈希链字段
    String? prevHash,          // 前一笔交易的哈希
    required String currentHash,  // 当前交易的哈希

    // 时间戳
    required DateTime createdAt,   // 创建时间（本地）
    DateTime? updatedAt,           // 更新时间

    // 隐私标记
    @Default(false) bool isPrivate,  // 是否私密交易（仅创建者可见）

    // 同步状态（不参与哈希计算）
    @Default(false) bool isSynced,
    @Default(false) bool isDeleted,  // 软删除标记
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);

  /// 计算当前交易的哈希值
  String calculateHash() {
    // 哈希输入：关键字段拼接
    final input = [
      id,
      bookId,
      amount.toString(),
      type.name,
      categoryId,
      ledgerType.name,
      timestamp.millisecondsSinceEpoch.toString(),
      prevHash ?? 'genesis',
    ].join('|');

    return HashChainService.hash(input);
  }

  /// 验证哈希链完整性
  bool verifyHash() {
    return currentHash == calculateHash();
  }

  /// 创建新交易
  factory Transaction.create({
    required String bookId,
    required String deviceId,
    required int amount,
    required TransactionType type,
    required String categoryId,
    required LedgerType ledgerType,
    DateTime? timestamp,
    String? note,
    String? photoHash,
    String? merchant,
    String? prevHash,
    bool isPrivate = false,
  }) {
    final tx = Transaction(
      id: Ulid().toString(),
      bookId: bookId,
      deviceId: deviceId,
      amount: amount,
      type: type,
      categoryId: categoryId,
      ledgerType: ledgerType,
      timestamp: timestamp ?? DateTime.now(),
      note: note,
      photoHash: photoHash,
      merchant: merchant,
      prevHash: prevHash,
      currentHash: '',  // 占位，下一步计算
      createdAt: DateTime.now(),
      isPrivate: isPrivate,
    );

    // 计算哈希
    return tx.copyWith(currentHash: tx.calculateHash());
  }
}
```

#### 3. Category（分类）

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

@freezed
class Category with _$Category {
  const Category._();

  const factory Category({
    required String id,
    required String name,
    required String icon,      // Material Icon名称或emoji
    required String color,     // Hex颜色值
    String? parentId,          // 父分类ID（支持三级分类）
    required int level,        // 1, 2, 3
    required TransactionType type,  // expense或income
    @Default(false) bool isSystem,  // 系统预设分类不可删除
    @Default(0) int sortOrder,
    required DateTime createdAt,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);

  /// 系统预设分类
  static List<Category> get systemCategories => [
    // 一级分类：餐饮
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
    // 二级分类：餐饮 > 早餐
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
    // 三级分类：餐饮 > 早餐 > 面包店
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
    // ... 更多系统分类
  ];
}
```

#### 4. Device（设备）

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'device.freezed.dart';
part 'device.g.dart';

enum DeviceRole {
  owner,   // 账本所有者
  partner, // 配偶/伴侣
  child;   // 子女（未来扩展）
}

@freezed
class Device with _$Device {
  const Device._();

  const factory Device({
    required String id,
    required String name,
    required String publicKey,  // Ed25519公钥（Base64编码）
    required DeviceRole role,
    String? avatarUrl,          // 头像URL（本地文件路径）
    required DateTime createdAt,
    DateTime? lastSeenAt,
    @Default(false) bool isActive,
  }) = _Device;

  factory Device.fromJson(Map<String, dynamic> json) =>
      _$DeviceFromJson(json);

  /// 创建当前设备
  factory Device.createCurrent({
    required String name,
    required String publicKey,
    DeviceRole role = DeviceRole.owner,
  }) {
    return Device(
      id: _generateDeviceId(),
      name: name,
      publicKey: publicKey,
      role: role,
      createdAt: DateTime.now(),
      lastSeenAt: DateTime.now(),
      isActive: true,
    );
  }

  static String _generateDeviceId() {
    // 设备ID：platform + UUID
    final platform = Platform.isIOS ? 'ios' : 'android';
    final uuid = Uuid().v4();
    return '${platform}_$uuid';
  }
}
```

#### 5. SyncLog（同步日志）

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_log.freezed.dart';
part 'sync_log.g.dart';

enum SyncOperation {
  insert,
  update,
  delete;
}

@freezed
class SyncLog with _$SyncLog {
  const SyncLog._();

  const factory SyncLog({
    required String id,
    required String deviceId,
    required String transactionId,
    required SyncOperation operation,
    required Map<String, int> vectorClock,  // 向量时钟
    required DateTime syncedAt,
    String? errorMessage,
  }) = _SyncLog;

  factory SyncLog.fromJson(Map<String, dynamic> json) =>
      _$SyncLogFromJson(json);
}
```

#### 6. SoulAccountConfig（灵魂消费配置）

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'soul_account_config.freezed.dart';
part 'soul_account_config.g.dart';

enum CelebrationType {
  confetti,   // 彩纸动画
  fireworks,  // 烟花动画
  sparkle,    // 闪光动画
  none;       // 无动画
}

@freezed
class SoulAccountConfig with _$SoulAccountConfig {
  const SoulAccountConfig._();

  const factory SoulAccountConfig({
    required String id,
    required String bookId,
    required List<String> categoryIds,  // 灵魂消费分类ID列表
    required CelebrationType celebrationType,
    @Default(0) int threshold,  // 触发庆祝的金额阈值（分）
    @Default(true) bool isEnabled,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _SoulAccountConfig;

  factory SoulAccountConfig.fromJson(Map<String, dynamic> json) =>
      _$SoulAccountConfigFromJson(json);

  /// 默认配置
  factory SoulAccountConfig.createDefault(String bookId) {
    return SoulAccountConfig(
      id: Ulid().toString(),
      bookId: bookId,
      categoryIds: [
        'cat_entertainment',
        'cat_hobby',
        'cat_sport',
        'cat_education',
      ],
      celebrationType: CelebrationType.confetti,
      threshold: 0,  // 任何金额都触发
      isEnabled: true,
      createdAt: DateTime.now(),
    );
  }
}
```

---

## 数据库架构

### Drift表定义

#### 1. Books表

```dart
import 'package:drift/drift.dart';

@DataClassName('BookEntity')
class Books extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get currency => text().withLength(min: 3, max: 3)();
  TextColumn get deviceId => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  // 统计字段
  IntColumn get transactionCount => integer().withDefault(const Constant(0))();
  IntColumn get survivalBalance => integer().withDefault(const Constant(0))();
  IntColumn get soulBalance => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Index> get customIndexes => [
    Index('books_device_id', [deviceId]),
  ];
}
```

#### 2. Transactions表

```dart
import 'package:drift/drift.dart';

@DataClassName('TransactionEntity')
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text()();
  TextColumn get deviceId => text()();
  IntColumn get amount => integer()();
  TextColumn get type => text()();  // 'expense', 'income'
  TextColumn get categoryId => text()();
  TextColumn get ledgerType => text()();  // 'survival', 'soul'
  DateTimeColumn get timestamp => dateTime()();

  // 可选字段
  TextColumn get note => text().nullable()();  // 加密
  TextColumn get photoHash => text().nullable()();
  TextColumn get merchant => text().nullable()();
  TextColumn get metadata => text().nullable()();  // JSON

  // 哈希链
  TextColumn get prevHash => text().nullable()();
  TextColumn get currentHash => text()();

  // 时间戳
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  // 标记
  BoolColumn get isPrivate => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Index> get customIndexes => [
    Index('tx_book_id', [bookId]),
    Index('tx_device_id', [deviceId]),
    Index('tx_category_id', [categoryId]),
    Index('tx_timestamp', [timestamp]),
    Index('tx_ledger_type', [ledgerType]),
    Index('tx_created_at', [createdAt]),
    // 组合索引：查询账本的某个时间段的交易
    Index('tx_book_timestamp', [bookId, timestamp]),
  ];
}
```

#### 3. Categories表

```dart
import 'package:drift/drift.dart';

@DataClassName('CategoryEntity')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get icon => text()();
  TextColumn get color => text()();
  TextColumn get parentId => text().nullable()();
  IntColumn get level => integer()();  // 1, 2, 3
  TextColumn get type => text()();  // 'expense', 'income'
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Index> get customIndexes => [
    Index('cat_parent_id', [parentId]),
    Index('cat_level', [level]),
  ];
}
```

#### 4. Devices表

```dart
import 'package:drift/drift.dart';

@DataClassName('DeviceEntity')
class Devices extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get publicKey => text()();  // Ed25519公钥（Base64）
  TextColumn get role => text()();  // 'owner', 'partner', 'child'
  TextColumn get avatarUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastSeenAt => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
```

#### 5. SyncLogs表

```dart
import 'package:drift/drift.dart';

@DataClassName('SyncLogEntity')
class SyncLogs extends Table {
  TextColumn get id => text()();
  TextColumn get deviceId => text()();
  TextColumn get transactionId => text()();
  TextColumn get operation => text()();  // 'insert', 'update', 'delete'
  TextColumn get vectorClock => text()();  // JSON: {"device1": 5, "device2": 3}
  DateTimeColumn get syncedAt => dateTime()();
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Index> get customIndexes => [
    Index('sync_device_id', [deviceId]),
    Index('sync_transaction_id', [transactionId]),
    Index('sync_synced_at', [syncedAt]),
  ];
}
```

#### 6. SoulAccountConfigs表

```dart
import 'package:drift/drift.dart';

@DataClassName('SoulAccountConfigEntity')
class SoulAccountConfigs extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text()();
  TextColumn get categoryIds => text()();  // JSON数组
  TextColumn get celebrationType => text()();  // 'confetti', 'fireworks'
  IntColumn get threshold => integer().withDefault(const Constant(0))();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Index> get customIndexes => [
    Index('soul_book_id', [bookId]),
  ];
}
```

### 数据库配置

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Books,
    Transactions,
    Categories,
    Devices,
    SyncLogs,
    SoulAccountConfigs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();

      // 插入系统预设分类
      await batch((batch) {
        batch.insertAll(
          categories,
          Category.systemCategories.map((c) => c.toCompanion(true)),
        );
      });
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // 未来的数据库迁移逻辑
    },
  );

  /// 打开数据库连接
  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'home_pocket.db'));

      // 加载SQLCipher库
      await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();

      // 获取数据库密钥
      final key = await _getDatabaseKey();

      return NativeDatabase.createInBackground(
        file,
        setup: (rawDb) {
          // SQLCipher配置
          rawDb.execute("PRAGMA key = '$key'");
          rawDb.execute("PRAGMA cipher_page_size = 4096");
          rawDb.execute("PRAGMA kdf_iter = 256000");
          rawDb.execute("PRAGMA cipher_hmac_algorithm = HMAC_SHA512");
          rawDb.execute("PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA512");

          // 性能优化
          rawDb.execute("PRAGMA journal_mode = WAL");
          rawDb.execute("PRAGMA synchronous = NORMAL");
          rawDb.execute("PRAGMA temp_store = MEMORY");
          rawDb.execute("PRAGMA cache_size = -2000");  // 2MB
        },
      );
    });
  }

  /// 数据库密钥缓存（避免重复派生）
  ///
  /// 安全说明：
  /// 1. 数据库密钥是从主密钥确定性派生的，每次派生结果相同
  /// 2. 使用缓存避免不必要的HKDF计算，提升性能
  /// 3. 缓存存储在内存中，应用关闭后自动清除
  /// 4. 密钥轮换时需要调用clearKeyCache()清除缓存
  static String? _cachedDbKey;

  /// 获取数据库密钥
  static Future<String> _getDatabaseKey() async {
    // ✅ 使用缓存，避免每次都派生密钥
    // 数据库密钥是确定性的，从主密钥+固定salt派生，结果不变
    if (_cachedDbKey != null) return _cachedDbKey!;

    final keyManager = KeyManager.instance;
    final key = await keyManager.getDatabaseKey();

    // 缓存密钥（应用运行期间有效）
    _cachedDbKey = key;
    return key;
  }

  /// 清除密钥缓存（用于密钥轮换）
  ///
  /// 使用场景：
  /// 1. 密钥轮换操作后
  /// 2. 用户重新登录后
  /// 3. Recovery Kit恢复后
  static void clearKeyCache() {
    _cachedDbKey = null;
  }
}
```

---

## 加密策略

### 多层加密设计

Home Pocket采用四层加密设计：

```
Layer 4: 传输层加密（TLS 1.3 + E2EE）
         ↓
Layer 3: 文件层加密（AES-256-GCM，照片）
         ↓
Layer 2: 字段层加密（ChaCha20-Poly1305，交易备注）
         ↓
Layer 1: 数据库层加密（SQLCipher AES-256，整个数据库）
```

### Layer 1: 数据库层加密（SQLCipher）

**算法**: AES-256-CBC
**密钥**: 从主密钥派生（HKDF）
**范围**: 整个SQLite数据库文件

**实现**:

```dart
class DatabaseEncryption {
  /// 初始化数据库加密
  static Future<void> initializeEncryption(RawDatabase rawDb) async {
    final key = await KeyManager.instance.getDatabaseKey();

    // SQLCipher配置
    await rawDb.execute("PRAGMA key = '$key'");
    await rawDb.execute("PRAGMA cipher_page_size = 4096");
    await rawDb.execute("PRAGMA kdf_iter = 256000");
    await rawDb.execute("PRAGMA cipher_hmac_algorithm = HMAC_SHA512");
    await rawDb.execute("PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA512");
  }

  /// 更改数据库密钥
  static Future<void> rekeyDatabase(
    AppDatabase db,
    String newKey,
  ) async {
    final rawDb = db.executor as NativeDatabase;
    await rawDb.execute("PRAGMA rekey = '$newKey'");
  }

  /// 验证数据库完整性
  static Future<bool> verifyDatabase(AppDatabase db) async {
    try {
      final rawDb = db.executor as NativeDatabase;
      await rawDb.execute("PRAGMA cipher_integrity_check");
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

### Layer 2: 字段层加密（ChaCha20-Poly1305）

**算法**: ChaCha20-Poly1305（AEAD）
**密钥**: 从主密钥派生
**范围**: 敏感字段（交易备注、商家名称）

**实现**:

```dart
import 'package:cryptography/cryptography.dart';

class FieldEncryption {
  static final _algorithm = Chacha20.poly1305Aead();

  /// 加密字段
  static Future<String> encrypt(String plaintext) async {
    final keyManager = KeyManager.instance;
    final key = await keyManager.getFieldEncryptionKey();

    // 生成随机nonce
    final nonce = _algorithm.newNonce();

    // 加密
    final secretBox = await _algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
    );

    // 返回格式：nonce + ciphertext + mac
    final result = [
      ...nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ];

    return base64Encode(result);
  }

  /// 解密字段
  static Future<String> decrypt(String encrypted) async {
    final keyManager = KeyManager.instance;
    final key = await keyManager.getFieldEncryptionKey();

    // 解析数据
    final data = base64Decode(encrypted);
    final nonce = data.sublist(0, 12);
    final macBytes = data.sublist(data.length - 16);
    final cipherText = data.sublist(12, data.length - 16);

    // 解密
    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    final plaintext = await _algorithm.decrypt(
      secretBox,
      secretKey: key,
    );

    return utf8.decode(plaintext);
  }
}
```

### Layer 3: 文件层加密（AES-256-GCM）

**算法**: AES-256-GCM
**密钥**: 从主密钥派生
**范围**: 交易照片文件

**实现**:

```dart
import 'package:cryptography/cryptography.dart';

class FileEncryption {
  static final _algorithm = AesGcm.with256bits();

  /// 加密文件
  static Future<File> encryptFile(File sourceFile) async {
    final keyManager = KeyManager.instance;
    final key = await keyManager.getFileEncryptionKey();

    // 读取文件内容
    final plaintext = await sourceFile.readAsBytes();

    // 生成随机nonce
    final nonce = _algorithm.newNonce();

    // 加密
    final secretBox = await _algorithm.encrypt(
      plaintext,
      secretKey: key,
      nonce: nonce,
    );

    // 保存加密文件
    final encryptedPath = '${sourceFile.path}.enc';
    final encryptedFile = File(encryptedPath);

    // 写入：nonce + ciphertext + mac
    await encryptedFile.writeAsBytes([
      ...nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);

    return encryptedFile;
  }

  /// 解密文件
  static Future<Uint8List> decryptFile(File encryptedFile) async {
    final keyManager = KeyManager.instance;
    final key = await keyManager.getFileEncryptionKey();

    // 读取加密文件
    final data = await encryptedFile.readAsBytes();

    // 解析
    final nonce = data.sublist(0, 12);
    final macBytes = data.sublist(data.length - 16);
    final cipherText = data.sublist(12, data.length - 16);

    // 解密
    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    final plaintext = await _algorithm.decrypt(
      secretBox,
      secretKey: key,
    );

    return Uint8List.fromList(plaintext);
  }
}
```

### Layer 4: 传输层加密（E2EE）

**协议**: TLS 1.3 + 自定义E2EE层
**密钥**: Ed25519密钥对
**范围**: 设备间同步数据

详见 [03_Security_Architecture.md](./03_Security_Architecture.md) 和 [05_Integration_Patterns.md](./05_Integration_Patterns.md)。

---

## 数据流设计

### 1. 新增交易流程

```
用户输入
   ↓
表单验证
   ↓
分类识别（三层引擎）
   ↓
创建Transaction对象
   ↓
字段加密（note字段）
   ↓
计算哈希（包含prevHash）
   ↓
插入数据库（SQLCipher加密）
   ↓
更新账本统计
   ↓
触发UI刷新（Riverpod）
   ↓
加入同步队列（如果已配对）
```

**代码实现**:

```dart
class CreateTransactionUseCase {
  final TransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;
  final ClassificationService _classificationService;
  final FieldEncryption _fieldEncryption;
  final HashChainService _hashChainService;

  Future<Result<Transaction>> execute({
    required String bookId,
    required int amount,
    required TransactionType type,
    required String categoryId,
    DateTime? timestamp,
    String? note,
    File? photo,
    String? merchant,
  }) async {
    try {
      // 1. 验证输入
      if (amount <= 0) {
        return Result.error('金额必须大于0');
      }

      // 2. 获取分类信息
      final category = await _categoryRepo.findById(categoryId);
      if (category == null) {
        return Result.error('分类不存在');
      }

      // 3. 智能分类（三层引擎）
      final ledgerType = await _classificationService.classifyLedgerType(
        categoryId: categoryId,
        merchant: merchant,
        note: note,
      );

      // 4. 加密敏感字段
      String? encryptedNote;
      if (note != null && note.isNotEmpty) {
        encryptedNote = await _fieldEncryption.encrypt(note);
      }

      // 5. 处理照片（如果有）
      String? photoHash;
      if (photo != null) {
        final encryptedPhoto = await FileEncryption.encryptFile(photo);
        photoHash = await HashChainService.hashFile(encryptedPhoto);
      }

      // 6. 获取前一笔交易的哈希
      final prevHash = await _hashChainService.getLatestHash(bookId);

      // 7. 创建交易
      final deviceId = await DeviceManager.instance.getCurrentDeviceId();
      final transaction = Transaction.create(
        bookId: bookId,
        deviceId: deviceId,
        amount: amount,
        type: type,
        categoryId: categoryId,
        ledgerType: ledgerType,
        timestamp: timestamp ?? DateTime.now(),
        note: encryptedNote,
        photoHash: photoHash,
        merchant: merchant,
        prevHash: prevHash,
      );

      // 8. 插入数据库
      await _transactionRepo.insert(transaction);

      // 9. 更新账本统计
      await _transactionRepo.updateBookBalance(bookId);

      // 10. 加入同步队列
      await SyncQueue.instance.enqueue(transaction);

      return Result.success(transaction);

    } catch (e, stackTrace) {
      return Result.error('创建交易失败: $e');
    }
  }
}
```

### 2. 查询交易流程

```
用户请求
   ↓
构建查询条件
   ↓
应用过滤器（时间/分类/账本）
   ↓
数据库查询（索引优化）
   ↓
自动解密（note字段）
   ↓
返回结果
   ↓
Riverpod缓存
   ↓
UI渲染
```

**代码实现**:

```dart
class TransactionRepositoryImpl implements TransactionRepository {
  final AppDatabase _db;
  final FieldEncryption _fieldEncryption;

  @override
  Future<List<Transaction>> getTransactions({
    required String bookId,
    LedgerType? ledgerType,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categoryIds,
    int limit = 100,
    int offset = 0,
  }) async {
    // 构建查询
    var query = _db.select(_db.transactions)
      ..where((t) => t.bookId.equals(bookId));

    // 应用过滤器
    if (ledgerType != null) {
      query.where((t) => t.ledgerType.equals(ledgerType.name));
    }

    if (startDate != null) {
      query.where((t) => t.timestamp.isBiggerOrEqualValue(startDate));
    }

    if (endDate != null) {
      query.where((t) => t.timestamp.isSmallerThanValue(endDate));
    }

    if (categoryIds != null && categoryIds.isNotEmpty) {
      query.where((t) => t.categoryId.isIn(categoryIds));
    }

    // 排序和分页
    query
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
      ..limit(limit, offset: offset);

    // 执行查询
    final entities = await query.get();

    // 转换为领域模型并解密
    final transactions = await Future.wait(
      entities.map((e) async {
        final tx = _entityToModel(e);

        // 解密note字段
        if (tx.note != null && tx.note!.isNotEmpty) {
          final decryptedNote = await _fieldEncryption.decrypt(tx.note!);
          return tx.copyWith(note: decryptedNote);
        }

        return tx;
      }),
    );

    return transactions;
  }
}
```

---

## 数据同步

### CRDT（Conflict-free Replicated Data Type）

Home Pocket使用CRDT协议实现设备间同步，确保最终一致性。

**核心概念**:

1. **向量时钟（Vector Clock）**: 追踪每个设备的操作顺序
2. **Last-Write-Wins（LWW）**: 时间戳最新的操作胜出
3. **删除墓碑（Tombstone）**: 软删除标记

**数据结构**:

```dart
class CRDTDocument {
  final String id;
  final Map<String, int> vectorClock;  // {deviceId: counter}
  final int lamportTimestamp;          // Lamport逻辑时钟
  final Transaction data;
  final bool isDeleted;

  /// 合并两个版本
  CRDTDocument merge(CRDTDocument other) {
    // 比较向量时钟
    final comparison = _compareVectorClocks(vectorClock, other.vectorClock);

    if (comparison == ClockComparison.before) {
      return other;  // 对方更新
    } else if (comparison == ClockComparison.after) {
      return this;   // 本地更新
    } else {
      // 并发修改，使用LWW策略
      if (lamportTimestamp > other.lamportTimestamp) {
        return this;
      } else if (lamportTimestamp < other.lamportTimestamp) {
        return other;
      } else {
        // Lamport时间戳相同，使用设备ID字典序
        return data.deviceId.compareTo(other.data.deviceId) > 0
          ? this
          : other;
      }
    }
  }
}
```

详细实现参见 [08_MOD_FamilySync.md](./08_MOD_FamilySync.md)。

---

## 数据备份与恢复

### 备份格式

```json
{
  "version": "1.0",
  "exportedAt": "2026-02-03T10:30:00Z",
  "deviceId": "ios_abc123",
  "encryption": {
    "algorithm": "AES-256-GCM",
    "kdfIterations": 100000
  },
  "data": {
    "books": [...],
    "transactions": [...],
    "categories": [...],
    "devices": [...],
    "soulAccountConfigs": [...]
  }
}
```

### 备份流程

```dart
class ExportBackupUseCase {
  Future<File> execute({
    required String password,
  }) async {
    // 1. 导出所有数据
    final books = await _bookRepo.findAll();
    final transactions = await _transactionRepo.findAll();
    final categories = await _categoryRepo.findAll();
    // ...

    // 2. 构建JSON
    final json = {
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'deviceId': await DeviceManager.instance.getCurrentDeviceId(),
      'encryption': {
        'algorithm': 'AES-256-GCM',
        'kdfIterations': 100000,
      },
      'data': {
        'books': books.map((b) => b.toJson()).toList(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'categories': categories.map((c) => c.toJson()).toList(),
        // ...
      },
    };

    // 3. 序列化
    final plaintext = jsonEncode(json);

    // 4. 加密（使用用户密码）
    final encrypted = await BackupEncryption.encrypt(
      plaintext,
      password: password,
    );

    // 5. 保存到文件
    final file = await _saveBackupFile(encrypted);

    return file;
  }
}
```

---

## 性能优化

### 1. 索引策略

```dart
// 关键查询的索引
Index('tx_book_timestamp', [bookId, timestamp])  // 按账本+时间查询
Index('tx_category_id', [categoryId])            // 按分类查询
Index('tx_ledger_type', [ledgerType])            // 按账本类型查询
```

### 2. 查询优化

```dart
// ✅ 好的实践：使用索引，限制结果
final transactions = await (db.select(db.transactions)
  ..where((t) => t.bookId.equals(bookId))
  ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
  ..limit(50))
  .get();

// ❌ 避免：全表扫描
final allTransactions = await db.select(db.transactions).get();
```

### 3. 分页加载

```dart
@riverpod
class TransactionListPaginated extends _$TransactionListPaginated {
  int _page = 0;
  static const _pageSize = 50;

  @override
  Future<List<Transaction>> build({required String bookId}) async {
    return _loadPage(_page);
  }

  Future<void> loadMore() async {
    _page++;
    final newItems = await _loadPage(_page);
    state = AsyncValue.data([...state.value ?? [], ...newItems]);
  }

  Future<List<Transaction>> _loadPage(int page) async {
    final repo = ref.read(transactionRepositoryProvider);
    return repo.getTransactions(
      bookId: bookId,
      limit: _pageSize,
      offset: page * _pageSize,
    );
  }
}
```

### 4. 缓存策略

```dart
@riverpod
class CategoryCache extends _$CategoryCache {
  @override
  Future<List<Category>> build() async {
    final repo = ref.watch(categoryRepositoryProvider);
    final categories = await repo.findAll();
    return categories;
  }

  // 缓存60秒
  @override
  Duration? get keepAlive => const Duration(seconds: 60);
}
```

### 5. 批量操作

```dart
// 批量插入
await db.batch((batch) {
  for (final tx in transactions) {
    batch.insert(db.transactions, tx.toCompanion());
  }
});
```

---

## 总结

Home Pocket的数据架构设计核心特点：

1. **类型安全**: 使用Drift+Freezed确保编译时类型检查
2. **多层加密**: 数据库、字段、文件、传输四层保护
3. **完整性保证**: 哈希链防止交易篡改
4. **性能优化**: 索引、分页、缓存
5. **同步支持**: CRDT协议实现最终一致性
6. **备份恢复**: 加密导出，完整恢复

**下一步阅读**:
- [03_Security_Architecture.md](./03_Security_Architecture.md) - 详细的安全设计
- [04_State_Management.md](./04_State_Management.md) - Riverpod状态管理
- [05_Integration_Patterns.md](./05_Integration_Patterns.md) - 集成模式

---

**文档维护**:
- 最后更新: 2026-02-03
- 维护者: 架构团队
- 版本: 1.0
