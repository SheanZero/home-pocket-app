# Data Layer (数据层)

> Tables, DAOs, Repositories, Domain Models, Database Schema

---

## 目录

- [1. 架构概览](#1-架构概览)
- [2. Drift 表定义](#2-drift-表定义)
- [3. DAOs (数据访问对象)](#3-daos-数据访问对象)
- [4. Repository 实现](#4-repository-实现)
- [5. Domain Models](#5-domain-models)
- [6. Repository 接口](#6-repository-接口)
- [7. 数据库版本与迁移](#7-数据库版本与迁移)
- [8. 数据转换流程](#8-数据转换流程)

---

## 1. 架构概览

```
lib/data/                          # 共享数据层 (跨功能)
├── app_database.dart              # Drift 数据库主定义 (v5)
├── app_database.g.dart            # 自动生成
├── tables/                        # 表定义
│   ├── books_table.dart
│   ├── categories_table.dart
│   ├── transactions_table.dart
│   ├── category_ledger_configs_table.dart
│   └── audit_logs_table.dart
├── daos/                          # 数据访问对象
│   ├── book_dao.dart
│   ├── category_dao.dart
│   ├── transaction_dao.dart
│   ├── category_ledger_config_dao.dart
│   └── analytics_dao.dart
└── repositories/                  # Repository 实现
    ├── book_repository_impl.dart
    ├── category_repository_impl.dart
    ├── transaction_repository_impl.dart
    ├── category_ledger_config_repository_impl.dart
    ├── analytics_repository_impl.dart
    ├── device_identity_repository_impl.dart
    └── settings_repository_impl.dart

lib/features/*/domain/             # 领域层 (薄 Feature)
├── models/                        # Freezed 模型
│   ├── transaction.dart
│   ├── book.dart
│   ├── category.dart
│   ├── category_ledger_config.dart
│   ├── monthly_report.dart
│   ├── budget_progress.dart
│   ├── daily_expense.dart
│   ├── expense_trend.dart
│   ├── month_comparison.dart
│   ├── app_settings.dart
│   └── backup_data.dart
└── repositories/                  # 抽象接口
    ├── transaction_repository.dart
    ├── book_repository.dart
    ├── category_repository.dart
    ├── category_ledger_config_repository.dart
    ├── device_identity_repository.dart
    ├── analytics_repository.dart
    └── settings_repository.dart
```

**层级关系**:
```
Domain Model (Freezed) ← Repository Interface (abstract)
         ↑ implements                  ↑ defines contract
Repository Impl → DAO → Table (Drift)
         ↓ uses
Infrastructure (EncryptionService, KeyManager)
```

---

## 2. Drift 表定义

### 2.1 Books (账本表)

**文件**: `lib/data/tables/books_table.dart`
**Row 类**: `BookRow`

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| `id` | text | PK | 唯一标识 |
| `name` | text | length(1,100) | 账本名称 |
| `currency` | text | length(3,3) | 货币代码 (JPY, USD...) |
| `deviceId` | text | indexed | 创建设备 |
| `createdAt` | dateTime | required | 创建时间 |
| `updatedAt` | dateTime | nullable | 更新时间 |
| `isArchived` | bool | default(false) | 软删除标记 |
| `transactionCount` | int | default(0) | 反范式统计 |
| `survivalBalance` | int | default(0) | 生存账本余额 |
| `soulBalance` | int | default(0) | 灵魂账本余额 |

**索引**:
- `idx_books_device_id` → `{#deviceId}`
- `idx_books_archived` → `{#isArchived}`

### 2.2 Categories (分类表)

**文件**: `lib/data/tables/categories_table.dart`
**Row 类**: `CategoryRow`

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| `id` | text | PK | 唯一标识 (如 cat_food) |
| `name` | text | length(1,50) | 名称或 i18n key |
| `icon` | text | required | 图标标识 |
| `color` | text | required | 颜色代码 |
| `parentId` | text | nullable, FK→Categories | 父分类 (L2) |
| `level` | int | CHECK(1\|2) | 层级 (1=父, 2=子) |
| `isSystem` | bool | default(false) | 系统预定义 |
| `isArchived` | bool | default(false) | 软删除标记 |
| `sortOrder` | int | default(0) | 排序顺序 |
| `createdAt` | dateTime | required | 创建时间 |
| `updatedAt` | dateTime | nullable | 更新时间 |

**索引**:
- `idx_categories_parent_id` → `{#parentId}`
- `idx_categories_level` → `{#level}`
- `idx_categories_archived` → `{#isArchived}`

**层级规则**:
- L1: `parentId = NULL`
- L2: `parentId = {L1 分类 ID}`

### 2.3 Transactions (交易表)

**文件**: `lib/data/tables/transactions_table.dart`
**Row 类**: `TransactionRow`

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| `id` | text | PK | 唯一标识 (ULID) |
| `bookId` | text | indexed | 所属账本 |
| `deviceId` | text | required | 创建设备 |
| `amount` | int | required | 金额 (分/円) |
| `type` | text | required | expense/income/transfer |
| `categoryId` | text | indexed | 分类 ID |
| `ledgerType` | text | indexed | survival/soul |
| `timestamp` | dateTime | indexed | 交易时间 |
| `note` | text | nullable | **加密字段** |
| `photoHash` | text | nullable | 收据照片哈希 |
| `merchant` | text | nullable | 商户名称 |
| `metadata` | text | nullable | JSON 元数据 |
| `prevHash` | text | nullable | 哈希链前项 |
| `currentHash` | text | required | 当前哈希 |
| `createdAt` | dateTime | required | 记录创建时间 |
| `updatedAt` | dateTime | nullable | 修改时间 |
| `isPrivate` | bool | default(false) | 隐私标记 |
| `isSynced` | bool | default(false) | 同步状态 |
| `isDeleted` | bool | default(false) | 软删除标记 |
| `soulSatisfaction` | int | default(5), CHECK(1-10) | 灵魂满意度 |

**索引**:
- `idx_tx_book_id` → `{#bookId}`
- `idx_tx_category_id` → `{#categoryId}`
- `idx_tx_timestamp` → `{#timestamp}`
- `idx_tx_ledger_type` → `{#ledgerType}`
- `idx_tx_book_timestamp` → `{#bookId, #timestamp}` (复合)
- `idx_tx_book_deleted` → `{#bookId, #isDeleted}` (复合)

### 2.4 CategoryLedgerConfigs (分类账本配置表)

**文件**: `lib/data/tables/category_ledger_configs_table.dart`
**Row 类**: `CategoryLedgerConfigRow`

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| `categoryId` | text | PK, FK→Categories | 分类 ID |
| `ledgerType` | text | CHECK(survival\|soul) | 账本类型 |
| `updatedAt` | dateTime | required | 配置更新时间 |

**用途**: 个人设备上的分类 → 账本映射，**不跨设备同步**

### 2.5 AuditLogs (审计日志表)

**文件**: `lib/data/tables/audit_logs_table.dart`
**Row 类**: `AuditLogs`

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| `id` | text | PK | ULID (时间可排序) |
| `event` | text | required | 事件类型名称 |
| `deviceId` | text | required | 产生事件的设备 |
| `bookId` | text | nullable | 关联账本 |
| `transactionId` | text | nullable | 关联交易 |
| `details` | text | nullable | JSON 详情 (禁止敏感数据) |
| `timestamp` | dateTime | required | 事件时间 |

---

## 3. DAOs (数据访问对象)

### 3.1 BookDao

**文件**: `lib/data/daos/book_dao.dart`

| 方法 | 签名 | 操作 |
|------|------|------|
| `insertBook` | `({id, name, currency, deviceId, createdAt, isArchived?})` | INSERT |
| `findById` | `(String id) → BookRow?` | SELECT WHERE id |
| `findAll` | `({includeArchived?}) → List<BookRow>` | SELECT ORDER BY createdAt DESC |
| `updateBook` | `({id, name?, currency?, isArchived?, updatedAt?})` | 部分 UPDATE |
| `archiveBook` | `(String id)` | UPDATE isArchived=true |
| `deleteAll` | `()` | 硬删除全部 |
| `updateBalances` | `({bookId, transactionCount, survivalBalance, soulBalance})` | UPDATE 反范式字段 |

### 3.2 CategoryDao

**文件**: `lib/data/daos/category_dao.dart`

**参数对象**: `CategoryInsertData` — 批量插入用

| 方法 | 签名 | 操作 |
|------|------|------|
| `insertCategory` | `({全部字段})` | INSERT (含 level/parent 验证) |
| `updateCategory` | `({id, name?, icon?, color?, isArchived?, sortOrder?, updatedAt})` | 部分 UPDATE |
| `findById` | `(String id) → CategoryRow?` | SELECT WHERE id |
| `findAll` | `() → List<CategoryRow>` | SELECT ORDER BY sortOrder |
| `findActive` | `() → List<CategoryRow>` | SELECT WHERE !isArchived ORDER BY sortOrder |
| `findByLevel` | `(int level) → List<CategoryRow>` | SELECT WHERE level |
| `findByParent` | `(String parentId) → List<CategoryRow>` | SELECT WHERE parentId |
| `deleteAll` | `()` | 硬删除全部 |
| `insertBatch` | `(List<CategoryInsertData>)` | 批量 INSERT |

**验证规则**:
- `assert(level == 1 || level == 2)`
- L1 必须 `parentId == null`
- L2 必须 `parentId != null`

### 3.3 TransactionDao

**文件**: `lib/data/daos/transaction_dao.dart`

| 方法 | 签名 | 操作 |
|------|------|------|
| `insertTransaction` | `({全部字段})` | INSERT |
| `findById` | `(String id) → TransactionRow?` | SELECT WHERE id |
| `findByBookId` | `(bookId, {ledgerType?, categoryId?, startDate?, endDate?, limit, offset}) → List<TransactionRow>` | SELECT WHERE bookId AND !isDeleted (分页、过滤) |
| `getLatestHash` | `(String bookId) → String?` | SELECT currentHash ORDER BY timestamp DESC LIMIT 1 |
| `softDelete` | `(String id)` | UPDATE isDeleted=true |
| `findAllByBook` | `(String bookId) → List<TransactionRow>` | SELECT WHERE bookId AND !isDeleted (不分页) |
| `deleteAllByBook` | `(String bookId)` | 硬删除 WHERE bookId |
| `countByBookId` | `(String bookId) → int` | SELECT COUNT WHERE bookId AND !isDeleted |

**默认排序**: `timestamp DESC, id DESC`（最新优先）

### 3.4 CategoryLedgerConfigDao

**文件**: `lib/data/daos/category_ledger_config_dao.dart`

**参数对象**: `LedgerConfigInsertData` — 批量操作用

| 方法 | 签名 | 操作 |
|------|------|------|
| `upsert` | `({categoryId, ledgerType, updatedAt})` | INSERT OR UPDATE |
| `findById` | `(String categoryId) → ConfigRow?` | SELECT WHERE categoryId |
| `findAll` | `() → List<ConfigRow>` | SELECT * |
| `delete` | `(String categoryId)` | DELETE WHERE categoryId |
| `deleteAll` | `()` | 硬删除全部 |
| `upsertBatch` | `(List<LedgerConfigInsertData>)` | 批量 INSERT OR UPDATE |

### 3.5 AnalyticsDao

**文件**: `lib/data/daos/analytics_dao.dart`

**结果对象**:
```dart
MonthlyTotalsResult    { int totalIncome, int totalExpenses }
CategoryTotalResult    { String categoryId, int totalAmount, int transactionCount }
DailyTotalResult       { DateTime date, int totalAmount }
LedgerTotalResult      { String ledgerType, int totalAmount }
SatisfactionOverviewResult   { double avgSatisfaction, int count }
SatisfactionDistributionResult { int score, int count }
DailySatisfactionResult      { DateTime date, double avgSatisfaction, int count }
```

| 方法 | 参数 | 返回 | SQL 聚合 |
|------|------|------|----------|
| `getMonthlyTotals` | bookId, startDate, endDate | MonthlyTotalsResult | SUM(amount) GROUP BY type |
| `getCategoryTotals` | bookId, startDate, endDate, type? | List\<CategoryTotalResult\> | SUM, COUNT GROUP BY category_id |
| `getDailyTotals` | bookId, startDate, endDate, type? | List\<DailyTotalResult\> | SUM GROUP BY DATE(timestamp) |
| `getLedgerTotals` | bookId, startDate, endDate | List\<LedgerTotalResult\> | SUM GROUP BY ledger_type |
| `getSoulSatisfactionOverview` | bookId, startDate, endDate | SatisfactionOverviewResult | AVG, COUNT WHERE soul |
| `getSatisfactionDistribution` | bookId, startDate, endDate | List\<SatisfactionDistributionResult\> | COUNT GROUP BY soul_satisfaction |
| `getDailySatisfactionTrend` | bookId, startDate, endDate | List\<DailySatisfactionResult\> | AVG, COUNT GROUP BY DATE |

---

## 4. Repository 实现

### 4.1 BookRepositoryImpl

**文件**: `lib/data/repositories/book_repository_impl.dart`
**实现**: `BookRepository`
**依赖**: `BookDao`

**转换**: `BookRow → Book` (直接字段映射)

| 方法 | 说明 |
|------|------|
| `insert(Book)` | 字段提取 → DAO.insertBook |
| `findById(id) → Book?` | DAO → _toModel |
| `findAll({includeArchived?}) → List<Book>` | DAO → map(_toModel) |
| `update(Book)` | DAO.updateBook + 当前时间 |
| `archive(id)` | DAO.archiveBook |
| `deleteAll()` | DAO.deleteAll |
| `updateBalances({...})` | DAO.updateBalances |

### 4.2 CategoryRepositoryImpl

**文件**: `lib/data/repositories/category_repository_impl.dart`
**实现**: `CategoryRepository`
**依赖**: `CategoryDao`

**转换**: `CategoryRow → Category` (直接字段映射)

| 方法 | 说明 |
|------|------|
| `insert(Category)` | DAO.insertCategory |
| `update({id, ...partial})` | DAO.updateCategory |
| `findById(id) → Category?` | DAO → _toModel |
| `findAll() → List<Category>` | DAO → map |
| `findActive() → List<Category>` | DAO (isArchived=false) |
| `findByLevel(level) → List<Category>` | DAO (L1 或 L2) |
| `findByParent(parentId) → List<Category>` | DAO (L2 子项) |
| `deleteAll()` | DAO.deleteAll |
| `insertBatch(categories)` | DAO.insertBatch |

### 4.3 TransactionRepositoryImpl (含加密)

**文件**: `lib/data/repositories/transaction_repository_impl.dart`
**实现**: `TransactionRepository`
**依赖**: `TransactionDao`, `FieldEncryptionService`

**核心特点**: **note 字段透明加密/解密**

**转换**: `TransactionRow → Transaction` (**异步**，因需解密)

```dart
Future<Transaction> _toModel(TransactionRow row) async {
  String? decryptedNote;
  if (row.note != null && row.note!.isNotEmpty) {
    decryptedNote = await encryptionService.decryptField(row.note!);
  }
  return Transaction(
    ...,
    type: TransactionType.values.byName(row.type),
    ledgerType: LedgerType.values.byName(row.ledgerType),
    note: decryptedNote,  // 已解密
    ...
  );
}
```

| 方法 | 说明 | 加密行为 |
|------|------|----------|
| `insert(Transaction)` | 加密 note → DAO | note 加密后存储 |
| `findById(id) → Transaction?` | DAO → async _toModel | note 解密后返回 |
| `findByBookId({filters}) → List<Transaction>` | DAO → Future.wait(_toModel) | 并行解密 |
| `update(Transaction)` | softDelete(旧) + insert(新) | 重新加密 |
| `softDelete(id)` | DAO.softDelete | 无 |
| `getLatestHash(bookId) → String?` | DAO | 无 |
| `countByBookId(bookId) → int` | DAO | 无 |
| `findAllByBook(bookId) → List<Transaction>` | DAO → Future.wait | 并行解密 |
| `deleteAllByBook(bookId)` | DAO.deleteAllByBook | 无 |

### 4.4 CategoryLedgerConfigRepositoryImpl

**文件**: `lib/data/repositories/category_ledger_config_repository_impl.dart`
**实现**: `CategoryLedgerConfigRepository`
**依赖**: `CategoryLedgerConfigDao`

**转换**: `ConfigRow → CategoryLedgerConfig` (含 `LedgerType` 枚举转换)

### 4.5 AnalyticsRepositoryImpl

**文件**: `lib/data/repositories/analytics_repository_impl.dart`
**实现**: `AnalyticsRepository`
**依赖**: `AnalyticsDao`

**转换**: DAO 结果对象 → 领域聚合模型

### 4.6 DeviceIdentityRepositoryImpl

**文件**: `lib/data/repositories/device_identity_repository_impl.dart`
**实现**: `DeviceIdentityRepository`
**依赖**: `KeyManager`

```dart
Future<String?> getDeviceId() → keyManager.getDeviceId()
```

### 4.7 SettingsRepositoryImpl

**文件**: `lib/data/repositories/settings_repository_impl.dart`
**实现**: `SettingsRepository`
**依赖**: `SharedPreferences`

**存储键**:
| 键 | 类型 | 默认值 |
|-----|------|--------|
| `theme_mode` | String (enum name) | system |
| `language` | String | 'ja' |
| `notifications_enabled` | bool | true |
| `biometric_lock_enabled` | bool | true |

---

## 5. Domain Models

### 5.1 Accounting 模型

#### Transaction

```dart
@freezed class Transaction {
  String id;                    // ULID
  String bookId;
  String deviceId;
  int amount;                   // 最小单位 (分/円)
  TransactionType type;         // expense / income / transfer
  String categoryId;
  LedgerType ledgerType;        // survival / soul
  DateTime timestamp;
  String? note;                 // 加密存储
  String? photoHash;
  String? merchant;
  String? prevHash;
  String currentHash;
  DateTime createdAt;
  DateTime? updatedAt;
  @Default(false) bool isPrivate;
  @Default(false) bool isSynced;
  @Default(false) bool isDeleted;
  @Default(5) int soulSatisfaction;  // 1-10
}

enum TransactionType { expense, income, transfer }
enum LedgerType { survival, soul }
```

#### Book

```dart
@freezed class Book {
  String id;
  String name;
  String currency;          // 3 字符货币代码
  String deviceId;
  DateTime createdAt;
  DateTime? updatedAt;
  @Default(false) bool isArchived;
  @Default(0) int transactionCount;    // 反范式
  @Default(0) int survivalBalance;     // 反范式
  @Default(0) int soulBalance;         // 反范式
}
```

#### Category

```dart
@freezed class Category {
  String id;                // 如 cat_food, cat_food_breakfast
  String name;              // 系统分类为 i18n key
  String icon;              // 图标名称
  String color;             // 十六进制颜色
  String? parentId;         // L2 的父分类 ID
  int level;                // 1 或 2
  @Default(false) bool isSystem;
  @Default(false) bool isArchived;
  @Default(0) int sortOrder;
  DateTime createdAt;
  DateTime? updatedAt;
}
```

#### CategoryLedgerConfig

```dart
@freezed class CategoryLedgerConfig {
  String categoryId;
  LedgerType ledgerType;    // survival / soul
  DateTime updatedAt;
}
```

### 5.2 Analytics 模型

#### MonthlyReport

```dart
@freezed class MonthlyReport {
  int year, month;
  int totalIncome, totalExpenses;
  int savings;                          // totalIncome - totalExpenses
  double savingsRate;                   // (savings / totalIncome) × 100
  int survivalTotal, soulTotal;
  List<CategoryBreakdown> categoryBreakdowns;
  List<DailyExpense> dailyExpenses;
  MonthComparison? previousMonthComparison;
}
```

#### CategoryBreakdown

```dart
@freezed class CategoryBreakdown {
  String categoryId, categoryName;
  String icon, color;
  int amount;
  double percentage;
  int transactionCount;
  int? budgetAmount;
  double? budgetProgress;
}
```

#### DailyExpense

```dart
@freezed class DailyExpense {
  DateTime date;
  int amount;
}
```

#### ExpenseTrendData / MonthlyTrend

```dart
@freezed class ExpenseTrendData {
  List<MonthlyTrend> months;
}

@freezed class MonthlyTrend {
  int year, month;
  int totalExpenses, totalIncome;
}
```

#### MonthComparison

```dart
@freezed class MonthComparison {
  int previousMonth, previousYear;
  int previousIncome, previousExpenses;
  double incomeChange;     // 百分比变化
  double expenseChange;    // 百分比变化
}
```

#### BudgetProgress

```dart
@freezed class BudgetProgress {
  String categoryId, categoryName;
  String icon, color;
  int budgetAmount, spentAmount, remainingAmount;
  double percentage;
  BudgetStatus status;     // safe / warning / exceeded
}
```

### 5.3 Settings 模型

#### AppSettings

```dart
@freezed class AppSettings {
  @Default(AppThemeMode.system) AppThemeMode themeMode;
  @Default('ja') String language;
  @Default(true) bool notificationsEnabled;
  @Default(true) bool biometricLockEnabled;
}

enum AppThemeMode { system, light, dark }
```

#### BackupData

```dart
@freezed class BackupData {
  BackupMetadata metadata;
  List<Map<String, dynamic>> transactions;
  List<Map<String, dynamic>> categories;
  List<Map<String, dynamic>> books;
  Map<String, dynamic> settings;
}

@freezed class BackupMetadata {
  String version;       // '1.0'
  int createdAt;        // Unix timestamp
  String deviceId;
  String appVersion;
}
```

---

## 6. Repository 接口

### 6.1 TransactionRepository

```dart
abstract class TransactionRepository {
  Future<void> insert(Transaction transaction);
  Future<Transaction?> findById(String id);
  Future<List<Transaction>> findByBookId(String bookId, {
    LedgerType? ledgerType,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    int limit,    // 默认 100
    int offset,   // 默认 0
  });
  Future<void> update(Transaction transaction);
  Future<void> softDelete(String id);
  Future<String?> getLatestHash(String bookId);
  Future<int> countByBookId(String bookId);
  Future<List<Transaction>> findAllByBook(String bookId);
  Future<void> deleteAllByBook(String bookId);
}
```

### 6.2 BookRepository

```dart
abstract class BookRepository {
  Future<void> insert(Book book);
  Future<Book?> findById(String id);
  Future<List<Book>> findAll({bool includeArchived});
  Future<void> update(Book book);
  Future<void> archive(String id);
  Future<void> updateBalances({
    required String bookId,
    required int transactionCount,
    required int survivalBalance,
    required int soulBalance,
  });
  Future<void> deleteAll();
}
```

### 6.3 CategoryRepository

```dart
abstract class CategoryRepository {
  Future<void> insert(Category category);
  Future<void> update({required String id, String? name, String? icon,
    String? color, bool? isArchived, int? sortOrder});
  Future<Category?> findById(String id);
  Future<List<Category>> findAll();
  Future<List<Category>> findActive();
  Future<List<Category>> findByLevel(int level);
  Future<List<Category>> findByParent(String parentId);
  Future<void> insertBatch(List<Category> categories);
  Future<void> deleteAll();
}
```

### 6.4 CategoryLedgerConfigRepository

```dart
abstract class CategoryLedgerConfigRepository {
  Future<void> upsert(CategoryLedgerConfig config);
  Future<CategoryLedgerConfig?> findById(String categoryId);
  Future<List<CategoryLedgerConfig>> findAll();
  Future<void> delete(String categoryId);
  Future<void> deleteAll();
  Future<void> upsertBatch(List<CategoryLedgerConfig> configs);
}
```

### 6.5 AnalyticsRepository

```dart
abstract class AnalyticsRepository {
  Future<MonthlyTotals> getMonthlyTotals({
    required String bookId, required DateTime startDate, required DateTime endDate,
  });
  Future<List<CategoryTotal>> getCategoryTotals({
    required String bookId, required DateTime startDate, required DateTime endDate,
    String type = 'expense',
  });
  Future<List<DailyTotal>> getDailyTotals({
    required String bookId, required DateTime startDate, required DateTime endDate,
    String type = 'expense',
  });
  Future<List<LedgerTotal>> getLedgerTotals({
    required String bookId, required DateTime startDate, required DateTime endDate,
  });
}
```

### 6.6 DeviceIdentityRepository

```dart
abstract class DeviceIdentityRepository {
  Future<String?> getDeviceId();
}
```

### 6.7 SettingsRepository

```dart
abstract class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> updateSettings(AppSettings settings);
  Future<void> setThemeMode(AppThemeMode themeMode);
  Future<void> setLanguage(String language);
  Future<void> setBiometricLock(bool enabled);
  Future<void> setNotificationsEnabled(bool enabled);
}
```

---

## 7. 数据库版本与迁移

**当前版本**: **5**

| 版本 | 变更内容 |
|------|----------|
| v1→v2 | 初始 Schema |
| v2→v3 | Categories 表添加 `budget_amount` 列 (后在 v5 中移除) |
| v3→v4 | Transactions 表添加 `soulSatisfaction` 列 |
| v4→v5 | Category 模型 v2：Categories 添加 `isArchived`, `updatedAt`；新建 `CategoryLedgerConfigs` 表；从旧 `type` 字段迁移数据至 ledger configs；修复 L1/L2 parentId 一致性 |

**文件**: `lib/data/app_database.dart`

---

## 8. 数据转换流程

### 8.1 写入路径 (Domain → Storage)

```
Transaction (Domain Model)
    ↓
TransactionRepositoryImpl
    ├── note → FieldEncryptionService.encryptField() → 加密文本
    ├── type.name → String
    └── ledgerType.name → String
    ↓
TransactionDao.insertTransaction({字段...})
    ↓
Drift → SQLCipher (数据库级加密)
```

### 8.2 读取路径 (Storage → Domain)

```
SQLCipher (数据库解密) → Drift
    ↓
TransactionDao.findByBookId() → List<TransactionRow>
    ↓
TransactionRepositoryImpl._toModel() [async]
    ├── row.note → FieldEncryptionService.decryptField() → 明文
    ├── row.type → TransactionType.values.byName()
    └── row.ledgerType → LedgerType.values.byName()
    ↓
List<Transaction> (Domain Model, 明文)
```

### 8.3 软删除模式

```
softDelete(id)
    → UPDATE isDeleted = true, updatedAt = now
    → 所有查询自动排除 WHERE isDeleted = false
    → 备份恢复时使用 deleteAllByBook() 硬删除
```

### 8.4 反范式统计

```
Book 表包含:
    transactionCount  — 交易总数
    survivalBalance   — 生存账本余额
    soulBalance       — 灵魂账本余额

更新方式: BookRepository.updateBalances()
优势: 避免 HOME 页面每次 SUM 查询
```

---

## ER 关系图

```
┌──────────────┐     ┌──────────────────┐
│    Books     │     │   Categories     │
│──────────────│     │──────────────────│
│ id (PK)      │     │ id (PK)          │
│ name         │     │ name             │
│ currency     │     │ icon, color      │
│ deviceId     │     │ parentId (FK→self)│
│ isArchived   │     │ level (1|2)      │
│ txCount      │     │ isSystem         │
│ survivalBal  │     │ isArchived       │
│ soulBal      │     │ sortOrder        │
└──────┬───────┘     └──────┬───────────┘
       │ 1:N                │ 1:N
       ↓                    ↓
┌──────────────────────────────────────┐
│            Transactions              │
│──────────────────────────────────────│
│ id (PK)                              │
│ bookId (FK→Books)                    │
│ categoryId (FK→Categories)           │
│ amount, type, ledgerType             │
│ note (ENCRYPTED), merchant           │
│ prevHash, currentHash (HASH CHAIN)   │
│ soulSatisfaction (1-10)              │
│ isDeleted (SOFT DELETE)              │
└──────────────────────────────────────┘

┌────────────────────────┐     ┌─────────────────┐
│ CategoryLedgerConfigs  │     │   AuditLogs     │
│────────────────────────│     │─────────────────│
│ categoryId (PK, FK)    │     │ id (PK, ULID)   │
│ ledgerType             │     │ event           │
│ updatedAt              │     │ deviceId        │
└────────────────────────┘     │ details (JSON)  │
                               └─────────────────┘
```

---

*最后更新: 2026-02-18*
