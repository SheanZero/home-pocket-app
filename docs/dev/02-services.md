# Services Layer (服务层)

> Application Use Cases, Business Logic, Classification Engine

---

## 目录

- [1. 架构概览](#1-架构概览)
- [2. Accounting 模块](#2-accounting-模块)
- [3. Analytics 模块](#3-analytics-模块)
- [4. Dual Ledger 模块](#4-dual-ledger-模块)
- [5. Settings 模块](#5-settings-模块)
- [6. 数据流示例](#6-数据流示例)
- [7. 错误处理模式](#7-错误处理模式)

---

## 1. 架构概览

```
lib/application/
├── accounting/          # 记账业务逻辑
│   ├── create_transaction_use_case.dart
│   ├── delete_transaction_use_case.dart
│   ├── get_transactions_use_case.dart
│   ├── ensure_default_book_use_case.dart
│   └── seed_categories_use_case.dart
├── analytics/           # 分析业务逻辑
│   ├── get_monthly_report_use_case.dart
│   ├── get_expense_trend_use_case.dart
│   ├── get_budget_progress_use_case.dart
│   └── demo_data_service.dart
├── dual_ledger/         # 双账本分类引擎
│   ├── classification_service.dart
│   ├── classification_result.dart
│   ├── rule_engine.dart
│   ├── resolve_ledger_type_service.dart
│   └── providers.dart
└── settings/            # 设置管理
    ├── export_backup_use_case.dart
    ├── import_backup_use_case.dart
    └── clear_all_data_use_case.dart
```

**通用模式**: 所有 Use Case 通过构造函数注入依赖，返回 `Result<T>` 类型。

---

## 2. Accounting 模块

### 2.1 CreateTransactionUseCase

**文件**: `lib/application/accounting/create_transaction_use_case.dart`

**职责**: 创建新交易，含验证、分类、哈希链

**依赖注入**:
| 依赖 | 类型 | 用途 |
|------|------|------|
| `transactionRepository` | TransactionRepository | 持久化交易 |
| `categoryRepository` | CategoryRepository | 验证分类存在 |
| `deviceIdentityRepository` | DeviceIdentityRepository | 获取设备 ID |
| `hashChainService` | HashChainService | 计算完整性哈希 |
| `classificationService` | ClassificationService | 生存/灵魂分类 |

**参数对象** `CreateTransactionParams`:
```dart
class CreateTransactionParams {
  final String bookId;
  final int amount;              // 金额（分）
  final TransactionType type;    // expense / income / transfer
  final String categoryId;
  final DateTime? timestamp;     // 可选，默认当前时间
  final String? note;            // 可选备注
  final String? merchant;        // 可选商户
  final int? soulSatisfaction;   // 灵魂满意度 1-10，默认 5
}
```

**执行流程**:
```
execute(params)
  1. 验证 bookId, categoryId 非空
  2. 验证 amount > 0
  3. 查询分类是否存在 → categoryRepository.findById()
  4. 获取设备 ID → deviceIdentityRepository.getDeviceId()
  5. 分类引擎判定 → classificationService.classify()
  6. 获取上一条哈希 → transactionRepository.getLatestHash()
  7. 生成 ULID 作为交易 ID
  8. 计算当前哈希 → hashChainService.calculateTransactionHash()
  9. 构建 Transaction 对象
  10. 持久化 → transactionRepository.insert()
  11. 返回 Result.success(transaction)
```

**验证规则**:
- `bookId` 不能为空
- `categoryId` 不能为空
- `amount` 必须 > 0
- 分类必须在数据库中存在
- 灵魂满意度必须在 1-10 之间（灵魂交易）

### 2.2 DeleteTransactionUseCase

**文件**: `lib/application/accounting/delete_transaction_use_case.dart`

**职责**: 软删除交易

**方法**: `Future<Result<void>> execute(String transactionId)`

**流程**:
1. 验证 transactionId 非空
2. 查询交易是否存在
3. 软删除（标记 `isDeleted=true`）

### 2.3 GetTransactionsUseCase

**文件**: `lib/application/accounting/get_transactions_use_case.dart`

**职责**: 按条件查询交易列表（分页、过滤）

**参数对象** `GetTransactionsParams`:
```dart
class GetTransactionsParams {
  final String bookId;           // 必须
  final LedgerType? ledgerType;  // 可选：生存/灵魂
  final String? categoryId;      // 可选分类过滤
  final DateTime? startDate;     // 可选开始日期
  final DateTime? endDate;       // 可选结束日期
  final int limit;               // 分页大小，默认 100
  final int offset;              // 分页偏移，默认 0
}
```

**方法**: `Future<Result<List<Transaction>>> execute(params)`

### 2.4 EnsureDefaultBookUseCase

**文件**: `lib/application/accounting/ensure_default_book_use_case.dart`

**职责**: 确保至少存在一个账本（应用初始化时调用）

**方法**: `Future<Result<Book>> execute()`

**流程**:
1. 查询是否存在任何账本
2. 如有 → 返回第一个
3. 如无 → 创建 "My Book" (JPY) 并返回

**幂等性**: 可安全多次调用

### 2.5 SeedCategoriesUseCase

**文件**: `lib/application/accounting/seed_categories_use_case.dart`

**职责**: 播种默认系统分类 + 账本配置映射

**依赖**:
- `categoryRepository` — 分类持久化
- `ledgerConfigRepository` — 账本配置持久化
- `DefaultCategories` (from `shared/constants`) — 默认分类数据

**方法**: `Future<Result<void>> execute()`

**流程**:
1. 检查是否已有分类
2. 已有 → 返回成功（幂等）
3. 无 → 批量插入 `DefaultCategories.all` + `DefaultCategories.defaultLedgerConfigs`

---

## 3. Analytics 模块

### 3.1 GetMonthlyReportUseCase

**文件**: `lib/application/analytics/get_monthly_report_use_case.dart`

**职责**: 生成综合月度报告

**依赖**:
- `analyticsRepository` — 聚合查询
- `categoryRepository` — 分类名称查找

**方法**:
```dart
Future<MonthlyReport> execute({
  required String bookId,
  required int year,
  required int month,
})
```

**执行流程**:
```
execute(bookId, year, month)
  1. 计算月份边界 (1日 00:00 → 月末 23:59:59)
  2. 并行执行 5 个查询 (Future.wait):
     ├── getMonthlyTotals(bookId, start, end)      → 总收支
     ├── getCategoryTotals(bookId, start, end)      → 分类统计
     ├── getDailyTotals(bookId, start, end)         → 每日统计
     ├── getLedgerTotals(bookId, start, end)         → 生存/灵魂
     └── findAll()                                   → 分类名称
  3. 计算衍生指标:
     ├── savings = totalIncome - totalExpenses
     └── savingsRate = (savings / totalIncome) × 100
  4. 构建分类明细 (百分比计算)
  5. 填充每日数据 (空日补零)
  6. 生存/灵魂分别汇总
  7. 月度同比 (上月增长率)
  8. 返回 MonthlyReport
```

**返回数据**:
```dart
MonthlyReport {
  year, month,
  totalIncome, totalExpenses, savings, savingsRate,
  survivalTotal, soulTotal,
  categoryBreakdowns: List<CategoryBreakdown>,
  dailyExpenses: List<DailyExpense>,
  previousMonthComparison: MonthComparison?,
}
```

### 3.2 GetExpenseTrendUseCase

**文件**: `lib/application/analytics/get_expense_trend_use_case.dart`

**职责**: 获取多月支出趋势（默认 6 个月）

**方法**:
```dart
Future<ExpenseTrendData> execute({
  required String bookId,
  int monthCount = 6,
})
```

**流程**: 向前回溯 N 个月，逐月查询月度总计，返回趋势列表。

### 3.3 GetBudgetProgressUseCase

**文件**: `lib/application/analytics/get_budget_progress_use_case.dart`

**状态**: **占位实现**（预算功能已延期）

- 当前返回空列表
- 待独立 Budget 表实现后重新开发

### 3.4 DemoDataService

**文件**: `lib/application/analytics/demo_data_service.dart`

**职责**: 生成模拟演示数据（3 个月交易）

**依赖**:
- `database: AppDatabase` — 直接数据库访问
- `categoryRepository` — 分类查询

**方法**: `Future<void> generateDemoData({required String bookId})`

**生成内容**:
- 3 个月数据
- 收入: 每月 25 日工资（300k-400k）
- 支出: 根据预定义消费模式生成（食物、交通、娱乐、购物等）
- 固定随机种子 (42) 确保可复现
- 自动分类为生存/灵魂
- 灵魂交易随机 soulSatisfaction (1-10)

---

## 4. Dual Ledger 模块

### 4.1 三层分类引擎

```
交易输入
    ↓
Layer 1: RuleEngine (规则引擎)
    ├── 匹配 → 返回 (confidence: 1.0)
    ↓ 未匹配
Layer 2: MerchantDatabase (商户数据库) [TODO]
    ├── 匹配 → 返回
    ↓ 未匹配
Layer 3: MLClassifier (ML 分类器) [TODO]
    ├── 匹配 → 返回
    ↓ 未匹配
Default: survival (confidence: 0.5)
```

### 4.2 ClassificationResult

**文件**: `lib/application/dual_ledger/classification_result.dart`

```dart
enum ClassificationMethod { rule, merchant, ml }

class ClassificationResult {
  final LedgerType ledgerType;       // survival / soul
  final double confidence;            // 0.0 - 1.0
  final ClassificationMethod method;  // 哪一层分类的
  final String reason;                // 人类可读原因
}
```

### 4.3 RuleEngine (Layer 1)

**文件**: `lib/application/dual_ledger/rule_engine.dart`

**职责**: 基于分类 ID 的规则匹配

**默认规则**:

| 生存 (Survival) | 灵魂 (Soul) |
|------------------|-------------|
| cat_food, cat_food_* | cat_entertainment |
| cat_transport, cat_transport_* | cat_shopping |
| cat_housing | cat_education |
| cat_medical | cat_social |
| cat_daily |  |
| cat_other_expense |  |

**公开方法**:
```dart
LedgerType? classify(String categoryId)  // 分类，无规则返回 null
void addRule(String categoryId, LedgerType ledgerType)
void removeRule(String categoryId)
```

### 4.4 ClassificationService

**文件**: `lib/application/dual_ledger/classification_service.dart`

**职责**: 编排三层分类流程

**依赖**: `RuleEngine`

**方法**:
```dart
Future<ClassificationResult> classify({
  required String categoryId,
  String? merchant,
  String? note,
})
```

**执行逻辑**:
1. **Layer 1** (RuleEngine): 检查分类 ID 规则 → 匹配则返回 (confidence=1.0, method=rule)
2. **Layer 2** (MerchantDatabase): TODO 待实现
3. **Layer 3** (MLClassifier): TODO 待实现
4. **Fallback**: survival (confidence=0.5, method=rule, reason="Default fallback")

### 4.5 ResolveLedgerTypeService

**文件**: `lib/application/dual_ledger/resolve_ledger_type_service.dart`

**职责**: 解析分类的有效账本类型（含继承逻辑）

**依赖**:
- `categoryRepository`
- `categoryLedgerConfigRepository`

**方法**:
```dart
Future<LedgerType?> resolve(String categoryId)
Future<String?> resolveL1(String categoryId)
```

**继承规则** (来自 PRD FR-004):
- L1 (顶层) 分类 → 返回自身的 LedgerConfig
- L2 (子分类) 有自定义配置 → 返回自身配置
- L2 无自定义配置 → 继承父级 L1 的配置
- 未找到 → 返回 null

### 4.6 Providers

**文件**: `lib/application/dual_ledger/providers.dart`

```dart
@Riverpod(keepAlive: true)
RuleEngine ruleEngine(Ref ref) → RuleEngine()    // 全局单例

@riverpod
ClassificationService classificationService(Ref ref)
  → ClassificationService(ruleEngine: ref.watch(ruleEngineProvider))
```

---

## 5. Settings 模块

### 5.1 ExportBackupUseCase

**文件**: `lib/application/settings/export_backup_use_case.dart`

**职责**: 加密导出全部数据为备份文件

**依赖**: transactionRepo, categoryRepo, bookRepo, settingsRepo

**方法**:
```dart
Future<Result<File>> execute({
  required String bookId,
  required String password,     // 最少 8 字符
  String? deviceId,
  String? appVersion,
  Directory? outputDirectory,
})
```

**流程**:
```
1. 验证密码长度 (≥8)
2. 并行收集数据:
   ├── 所有交易 (含指定 bookId)
   ├── 所有分类
   ├── 所有账本 (含已归档)
   └── 所有设置
3. 构建 BackupData (含元数据: 版本、时间、设备、App版本)
4. 序列化为 JSON
5. GZip 压缩
6. AES-256-GCM 加密:
   ├── PBKDF2 密钥导出 (100,000 次迭代)
   ├── 16 字节随机 salt
   └── 12 字节随机 nonce
7. 二进制格式: salt(16) + nonce(12) + ciphertext + mac(16)
8. 保存文件: homepocket_backup_YYYY-MM-DD.hpb
```

### 5.2 ImportBackupUseCase

**文件**: `lib/application/settings/import_backup_use_case.dart`

**职责**: 解密导入备份文件（**破坏性操作**：会清除所有现有数据）

**方法**:
```dart
Future<Result<void>> execute({
  required File backupFile,
  required String password,
})
```

**流程**:
```
1. 读取加密文件
2. 验证文件大小 (≥44 字节)
3. 提取 salt(16) + nonce(12) + ciphertext + mac(16)
4. PBKDF2 密钥导出 (提取的 salt)
5. AES-256-GCM 解密 (MAC 验证失败 → IncorrectPasswordException)
6. GZip 解压
7. 解析 JSON → 验证 BackupData 格式 + 版本
8. ⚠️ 清除所有现有数据
9. 恢复:
   ├── 导入所有账本
   ├── 导入所有分类
   ├── 导入所有交易
   └── 导入设置
```

**自定义异常**: `IncorrectPasswordException`

### 5.3 ClearAllDataUseCase

**文件**: `lib/application/settings/clear_all_data_use_case.dart`

**职责**: 清除全部用户数据（核选项）

**方法**: `Future<Result<void>> execute()`

**执行顺序**（遵循外键约束）:
1. 交易（依赖账本）
2. 分类
3. 账本
4. 设置重置

---

## 6. 数据流示例

### 6.1 创建交易

```
UI: TransactionConfirmScreen → 点击"记录"
  ↓
Provider: createTransactionUseCaseProvider
  ↓
UseCase: CreateTransactionUseCase.execute(params)
  ├─ CategoryRepository.findById()          → 验证分类
  ├─ DeviceIdentityRepository.getDeviceId() → 获取设备
  ├─ ClassificationService.classify()       → 判定生存/灵魂
  │   └─ RuleEngine.classify(categoryId)    → Layer 1 匹配
  ├─ TransactionRepository.getLatestHash()  → 获取链上一条
  ├─ HashChainService.calculateTransactionHash() → 计算哈希
  └─ TransactionRepository.insert()         → 持久化
  ↓
Result<Transaction> → UI 显示庆祝动画 → Pop 返回
  ↓
ref.invalidate(monthlyReportProvider)       → 刷新月报
ref.invalidate(todayTransactionsProvider)   → 刷新今日
```

### 6.2 生成月度报告

```
UI: AnalyticsScreen 加载
  ↓
Provider: monthlyReportProvider(bookId, year, month)
  ↓
UseCase: GetMonthlyReportUseCase.execute(bookId, year, month)
  ├─ [并行] AnalyticsRepository.getMonthlyTotals()
  ├─ [并行] AnalyticsRepository.getCategoryTotals()
  ├─ [并行] AnalyticsRepository.getDailyTotals()
  ├─ [并行] AnalyticsRepository.getLedgerTotals()
  └─ [并行] CategoryRepository.findAll()
  ↓
  计算: savings, savingsRate, categoryBreakdowns, dailyExpenses
  计算: 月度同比 (上月数据对比)
  ↓
MonthlyReport → UI 渲染 8 个子组件
```

### 6.3 导出备份

```
UI: SettingsScreen → "导出备份"
  ↓
UseCase: ExportBackupUseCase.execute(bookId, password)
  ├─ [并行] TransactionRepo.findAllByBook()
  ├─ [并行] CategoryRepo.findAll()
  ├─ [并行] BookRepo.findAll(includeArchived: true)
  └─ [并行] SettingsRepo.getSettings()
  ↓
  JSON → GZip → AES-256-GCM(PBKDF2 key)
  ↓
Result<File> → homepocket_backup_2026-02-18.hpb
```

---

## 7. 错误处理模式

### 7.1 统一 Result 模式

```dart
Future<Result<T>> execute(...) async {
  try {
    // 1. 验证
    if (invalid) return Result.error('描述性错误消息');

    // 2. 业务逻辑
    final data = await repository.operation();

    // 3. 成功
    return Result.success(data);
  } catch (e) {
    return Result.error('操作失败: $e');
  }
}
```

### 7.2 Result<T> 定义

```dart
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;
  bool get isError => !isSuccess;

  Result.success(T data)
  Result.error(String message)
}
```

---

## 依赖矩阵

| Use Case | TransactionRepo | CategoryRepo | BookRepo | SettingsRepo | DeviceIdentityRepo | HashChainService | ClassificationService | AnalyticsRepo | LedgerConfigRepo |
|----------|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| CreateTransaction | x | x | | | x | x | x | | |
| DeleteTransaction | x | | | | | | | | |
| GetTransactions | x | | | | | | | | |
| EnsureDefaultBook | | | x | | x | | | | |
| SeedCategories | | x | | | | | | | x |
| GetMonthlyReport | | x | | | | | | x | |
| GetExpenseTrend | | | | | | | | x | |
| ExportBackup | x | x | x | x | | | | | |
| ImportBackup | x | x | x | x | | | | | |
| ClearAllData | x | x | x | x | | | | | |
| ResolveLedgerType | | x | | | | | | | x |

---

*最后更新: 2026-02-18*
