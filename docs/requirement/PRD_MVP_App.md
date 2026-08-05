# Happy Pocket MVP - App端总体PRD

**文档版本:** 1.0
**创建日期:** 2026年2月3日
**状态:** Draft
**相关文档:** PRD_MVP_Global.md

---

## 目录

1. [App端架构设计](#1-app端架构设计)
2. [功能模块清单](#2-功能模块清单)
3. [数据模型设计](#3-数据模型设计)
4. [UI/UX设计原则](#4-uiux设计原则)
5. [性能与安全要求](#5-性能与安全要求)
6. [开发规范](#6-开发规范)

---

## 1. App端架构设计

### 1.1 整体架构

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────┐ │
│  │  UI Widgets  │  │    Screens   │  │    Themes     │ │
│  │ (Material 3) │  │  (Routes)    │  │ (和风/赛博)   │ │
│  └──────────────┘  └──────────────┘  └───────────────┘ │
└─────────────────────────────────────────────────────────┘
                          ↓↑
┌─────────────────────────────────────────────────────────┐
│                   Business Logic Layer                   │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────┐ │
│  │ State Mgmt   │  │   Services   │  │   Use Cases   │ │
│  │ (Riverpod)   │  │ (分类/同步)   │  │  (交易创建)   │ │
│  └──────────────┘  └──────────────┘  └───────────────┘ │
└─────────────────────────────────────────────────────────┘
                          ↓↑
┌─────────────────────────────────────────────────────────┐
│                     Data Layer                           │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────┐ │
│  │ Repositories │  │  Local DB    │  │  File Storage │ │
│  │              │  │  (Drift)     │  │  (加密照片)   │ │
│  └──────────────┘  └──────────────┘  └───────────────┘ │
└─────────────────────────────────────────────────────────┘
                          ↓↑
┌─────────────────────────────────────────────────────────┐
│                  Infrastructure Layer                    │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────┐ │
│  │   Crypto     │  │   ML Kit     │  │  Biometric    │ │
│  │ (Ed25519)    │  │   (OCR)      │  │  (Face ID)    │ │
│  └──────────────┘  └──────────────┘  └───────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### 1.2 技术栈详细

**核心框架:**
```yaml
flutter_sdk: ">=3.16.0"
dart_sdk: ">=3.2.0"

dependencies:
  # 状态管理
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0

  # 本地数据库
  drift: ^2.14.0
  sqlite3_flutter_libs: ^0.5.18
  sqlcipher_flutter_libs: ^0.6.0

  # 加密
  pointycastle: ^3.7.3
  cryptography: ^2.5.0

  # ML/OCR
  google_mlkit_text_recognition: ^0.11.0
  tflite_flutter: ^0.10.4

  # UI/UX
  go_router: ^13.0.0
  flutter_svg: ^2.0.9
  lottie: ^3.0.0

  # 工具
  intl: ^0.19.0
  path_provider: ^2.1.1
  share_plus: ^7.2.1

dev_dependencies:
  flutter_test:
  riverpod_generator: ^2.3.0
  build_runner: ^2.4.7
  drift_dev: ^2.14.0
  flutter_launcher_icons: ^0.13.1
```

### 1.3 文件夹结构

```
lib/
├── main.dart
├── app.dart
│
├── core/                        # 核心基础设施
│   ├── config/                  # 配置文件
│   │   ├── app_config.dart
│   │   └── flavor_config.dart
│   ├── crypto/                  # 加密工具
│   │   ├── key_manager.dart
│   │   ├── hash_chain.dart
│   │   └── encryption_service.dart
│   ├── database/                # 数据库配置
│   │   ├── database.dart        # Drift database
│   │   └── database.g.dart
│   ├── router/                  # 路由配置
│   │   └── app_router.dart
│   └── theme/                   # 主题系统
│       ├── warm_japanese_theme.dart
│       ├── cyber_kawaii_theme.dart
│       └── theme_manager.dart
│
├── features/                    # 功能模块
│   ├── onboarding/              # 引导流程
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── providers/
│   ├── transaction/             # 交易记录
│   │   ├── domain/              # 领域模型
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── application/         # 应用逻辑
│   │   │   ├── services/
│   │   │   └── use_cases/
│   │   └── presentation/        # 展示层
│   │       ├── screens/
│   │       ├── widgets/
│   │       └── providers/
│   ├── category/                # 分类管理
│   ├── dual_ledger/             # 双轨账本
│   ├── ocr/                     # OCR扫描
│   ├── family/                  # 家庭协作
│   │   ├── pairing/
│   │   ├── sync/
│   │   └── transfer/
│   ├── analytics/               # 数据分析
│   ├── gamification/            # 趣味功能
│   │   ├── ohtani_converter/
│   │   ├── omikuji/
│   │   └── soul_celebration/
│   └── settings/                # 设置
│
├── shared/                      # 共享组件
│   ├── widgets/                 # 通用UI组件
│   │   ├── buttons/
│   │   ├── cards/
│   │   └── dialogs/
│   ├── extensions/              # 扩展方法
│   └── utils/                   # 工具函数
│
└── l10n/                        # 多语言
    ├── app_ja.arb               # 日语
    └── app_zh.arb               # 中文
```

### 1.4 状态管理架构

**使用Riverpod 2.x的Provider模式:**

```dart
// 示例：交易列表状态管理
@riverpod
class TransactionList extends _$TransactionList {
  @override
  Future<List<Transaction>> build({
    required String bookId,
    LedgerType? filterLedger,
  }) async {
    final repo = ref.read(transactionRepositoryProvider);
    return repo.getTransactions(
      bookId: bookId,
      ledgerType: filterLedger,
    );
  }

  // 添加交易
  Future<void> addTransaction(Transaction tx) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(transactionRepositoryProvider).insert(tx);
      return build(bookId: tx.bookId, filterLedger: filterLedger);
    });
  }
}

// 在UI中使用
class TransactionListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTransactions = ref.watch(
      transactionListProvider(
        bookId: currentBookId,
        filterLedger: LedgerType.survival,
      ),
    );

    return asyncTransactions.when(
      data: (transactions) => ListView.builder(...),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => ErrorWidget(err),
    );
  }
}
```

### 1.5 依赖注入

```dart
// 使用Riverpod的Provider作为依赖注入容器

// Repository层
@riverpod
TransactionRepository transactionRepository(TransactionRepositoryRef ref) {
  final database = ref.watch(databaseProvider);
  return TransactionRepositoryImpl(database);
}

// Service层
@riverpod
ClassificationService classificationService(ClassificationServiceRef ref) {
  final merchantDB = ref.watch(merchantDatabaseProvider);
  final tfLite = ref.watch(tfLiteModelProvider);
  return ClassificationService(
    merchantDB: merchantDB,
    tfLite: tfLite,
  );
}

// Use Case层
@riverpod
CreateTransactionUseCase createTransactionUseCase(CreateTransactionUseCaseRef ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  final classifier = ref.watch(classificationServiceProvider);
  final hashChain = ref.watch(hashChainServiceProvider);

  return CreateTransactionUseCase(
    repository: repo,
    classifier: classifier,
    hashChain: hashChain,
  );
}
```

---

## 2. 功能模块清单

### 2.1 MVP必备模块（P0）

| 模块ID | 模块名称 | 负责范围 | 工时估算 | 详细PRD |
|--------|---------|---------|---------|---------|
| MOD-001 | 基础记账 | 支出/收入记录、编辑、删除 | 8天 | PRD_Module_BasicAccounting.md |
| MOD-002 | 分类管理 | 预设分类、自定义分类、图标颜色 | 5天 | PRD_Module_BasicAccounting.md |
| MOD-003 | 双轨账本 | 生存/灵魂账户分离、自动分类 | 8天 | PRD_Module_DualLedger.md |
| MOD-004 | 家庭同步 | 配对、同步、冲突解决 | 12天 | PRD_Module_FamilySync.md |
| MOD-005 | OCR扫描 | 小票识别、自动填充 | 7天 | PRD_Module_OCR.md |
| MOD-006 | 安全模块 | 加密、密钥管理、哈希链 | 10天 | PRD_Module_Security.md |
| MOD-007 | 数据分析 | 月度报表、饼图、热图 | 5天 | (本文档包含) |
| MOD-008 | 设置 | 隐私宣言、密钥备份、生物识别 | 5天 | PRD_Module_Security.md |

**总计P0工时:** 60天（12周 × 5天/周，符合10-12周计划）

### 2.2 MVP可选模块（P1-P2）

| 模块ID | 模块名称 | 负责范围 | 工时估算 | 条件 |
|--------|---------|---------|---------|------|
| MOD-009 | 趣味功能 | 大谷换算器、运势占卜、庆祝动画 | 7天 | A/B测试通过 |
| MOD-010 | Widget | iOS/Android桌面Widget | 4天 | 时间允许 |
| MOD-011 | 高级搜索 | 多条件筛选、FTS全文搜索 | 4天 | V1.0 |

### 2.3 模块依赖关系

```
MOD-006 (安全模块)
    ├─ 所有模块的基础（加密、密钥）
    │
MOD-001 (基础记账) + MOD-002 (分类管理)
    ├─ MOD-003 (双轨账本) 依赖
    ├─ MOD-005 (OCR) 依赖
    │
MOD-003 (双轨账本)
    ├─ MOD-009 (趣味功能) 依赖
    │
MOD-006 (安全模块)
    ├─ MOD-004 (家庭同步) 依赖
    │
MOD-001 + MOD-003
    ├─ MOD-007 (数据分析) 依赖
```

---

## 3. 数据模型设计

### 3.1 核心实体关系图（ERD）

```
┌─────────────┐         ┌─────────────┐
│    Books    │1      N │   Devices   │
│ (账本)      ├─────────┤  (设备)     │
│             │         │             │
│ - id        │         │ - id        │
│ - name      │         │ - book_id   │
│ - type      │         │ - public_key│
└──────┬──────┘         └──────┬──────┘
       │                       │
       │1                      │1
       │                       │
       │N                      │N
┌──────┴──────────────────────┴──────┐
│          Transactions               │
│           (交易)                    │
│                                     │
│ - id                                │
│ - book_id        (FK: Books)        │
│ - device_id      (FK: Devices)      │
│ - amount                            │
│ - type          (expense|income)    │
│ - category_id   (FK: Categories)    │
│ - ledger_type   (survival|soul)     │
│ - timestamp                         │
│ - note          (加密)              │
│ - prev_hash                         │
│ - current_hash  (哈希链)            │
└─────────────────────────────────────┘
       │
       │N
       │
┌──────┴──────┐         ┌─────────────┐
│ Categories  │         │  SyncLog    │
│  (分类)     │         │  (同步日志) │
│             │         │             │
│ - id        │         │ - id        │
│ - name      │         │ - book_id   │
│ - icon      │         │ - synced_at │
│ - color     │         │ - status    │
│ - ledger_t  │         └─────────────┘
└─────────────┘
```

### 3.2 Drift数据库定义

```dart
// lib/core/database/database.dart

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

part 'database.g.dart';

// 账本表
class Books extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();  // 'personal' | 'family'
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// 设备表
class Devices extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text().references(Books, #id)();
  TextColumn get publicKey => text()();
  TextColumn get name => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// 交易表
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text().references(Books, #id)();
  TextColumn get deviceId => text().references(Devices, #id)();
  IntColumn get amount => integer()();
  TextColumn get type => text()();  // 'expense' | 'income' | 'transfer'
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get ledgerType => text().withDefault(const Constant('survival'))();
  IntColumn get timestamp => integer()();
  TextColumn get note => text().nullable()();
  TextColumn get photoHash => text().nullable()();
  TextColumn get prevHash => text().nullable()();
  TextColumn get currentHash => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {bookId, currentHash},  // 哈希唯一性
  ];
}

// 分类表
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  TextColumn get color => text()();
  TextColumn get ledgerType => text().withDefault(const Constant('auto'))();
  IntColumn get isSystem => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// 同步日志表
class SyncLogs extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text().references(Books, #id)();
  IntColumn get syncedAt => integer()();
  IntColumn get syncCount => integer()();
  TextColumn get status => text()();  // 'success' | 'failed'

  @override
  Set<Column> get primaryKey => {id};
}

// Database类
@DriftDatabase(tables: [
  Books,
  Devices,
  Transactions,
  Categories,
  SyncLogs,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // 数据库迁移
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _insertDefaultCategories();
    },
  );

  // 插入预设分类
  Future<void> _insertDefaultCategories() async {
    await batch((batch) {
      batch.insertAll(categories, [
        CategoriesCompanion.insert(
          id: 'food_groceries',
          name: '食費（スーパー）',
          icon: '🛒',
          color: '#4CAF50',
          ledgerType: const Value('survival'),
          isSystem: const Value(1),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
        CategoriesCompanion.insert(
          id: 'food_restaurant',
          name: '食費（外食）',
          icon: '🍜',
          color: '#FF9800',
          ledgerType: const Value('soul'),
          isSystem: const Value(1),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
        // ... 其余18个预设分类
      ]);
    });
  }

  static QueryExecutor _openConnection() {
    return NativeDatabase.createInBackground(
      // SQLCipher加密
      databasePath: databaseFactoryFfi.getDatabasesPath() + '/homepocket.db',
      setup: (rawDb) {
        rawDb.execute("PRAGMA key = '${_getDatabaseKey()}'");
      },
    );
  }

  static String _getDatabaseKey() {
    // 从安全密钥存储中获取
    // 生产环境使用flutter_secure_storage
    return SecureKeyStorage.instance.getDatabaseKey();
  }
}
```

### 3.3 领域模型（Domain Models）

```dart
// lib/features/transaction/domain/models/transaction.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required String bookId,
    required String deviceId,
    required int amount,
    required TransactionType type,
    required String categoryId,
    required LedgerType ledgerType,
    required DateTime timestamp,
    String? note,
    String? photoHash,
    String? prevHash,
    required String currentHash,
    required DateTime createdAt,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}

enum TransactionType {
  expense,
  income,
  transfer,
}

enum LedgerType {
  survival,  // 生存账户
  soul,      // 灵魂账户
}

// 扩展方法
extension TransactionX on Transaction {
  // 计算哈希
  String calculateHash() {
    final data = '$id|$amount|${timestamp.millisecondsSinceEpoch}|$prevHash';
    return HashChainService.hash(data);
  }

  // 验证哈希
  bool verifyHash() {
    return currentHash == calculateHash();
  }

  // 是否为支出
  bool get isExpense => type == TransactionType.expense;

  // 是否为收入
  bool get isIncome => type == TransactionType.income;

  // 是否为灵魂消费
  bool get isSoulExpense => ledgerType == LedgerType.soul && isExpense;
}
```

### 3.4 Repository接口

```dart
// lib/features/transaction/domain/repositories/transaction_repository.dart

abstract class TransactionRepository {
  // 查询
  Future<List<Transaction>> getTransactions({
    required String bookId,
    LedgerType? ledgerType,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Transaction?> getById(String id);

  // 写入
  Future<void> insert(Transaction transaction);

  Future<void> update(Transaction transaction);

  // 哈希链验证
  Future<bool> verifyHashChain(String bookId);

  // 统计
  Future<int> getTotalAmount({
    required String bookId,
    required LedgerType ledgerType,
    required DateTime month,
  });

  // 同步相关
  Future<List<Transaction>> getUnsynced(String bookId);
  Future<void> markAsSynced(List<String> transactionIds);
}
```

---

## 4. UI/UX设计原则

### 4.1 双主题系统

**主题A：和风治愈系（Warm Japanese Healing）**
- 适用场景：生存账户、家庭模式、设置页面
- 色彩：暖米色背景、深棕木色主色、朱红警示色
- 字体：Noto Serif JP（标题）+ Noto Sans JP（正文）
- 组件：16px圆角、柔和阴影、无边框
- 动效：淡入淡出、弹性回弹、季节元素

**主题B：赛博可爱风（Cyber Kawaii）**
- 适用场景：灵魂账户、趣味功能、成就系统
- 色彩：深空紫背景、霓虹粉主色、电子蓝辅助色
- 字体：M PLUS Rounded 1c（圆润可爱）
- 组件：8px圆角、霓虹发光、渐变边框
- 动效：粒子爆发、像素展开、光晕效果

### 4.2 首页信息融合设计

**设计原则:**
1. 个人与家庭信息自然融合，避免突兀的模式切换
2. 通过视觉层次区分数据来源，而非完全分离
3. 关键信息一目了然，详细信息下钻可得
4. 灵魂账户保护隐私：伴侣只看到进度条，不看到明细

**首页布局（家庭模式）:**
```
┌─────────────────────────────────────┐
│ ≡  Happy Pocket      🟢 [家庭名] 👤  │  ← 顶部导航栏
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ 🏠 家庭总览 · 2月                │ │  ← 家庭整体财务
│ │ ━━━━━━━━━━━━━━━━━━━━━━━━━━━   │ │
│ │ 家庭支出 ¥234,500               │ │
│ │ 家庭收入 ¥450,000               │ │
│ │ 预算池剩余：¥65,500              │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌──────────┐  ┌───────────┐        │
│ │👤 我的本月│  │💑 TA的本月│        │  ← 双方对比
│ │生存 ¥95K │  │生存 ¥85K │        │
│ │💖灵魂70% │  │💖灵魂65% │        │
│ └──────────┘  └───────────┘        │
│                                     │
│ 🔮 今日运势          [点击预测] ►   │  ← 趣味功能入口
│                                     │
│ 今日の記録（融合视图）               │
│ ┌─────────────────────────────────┐ │
│ │👨 食費 ¥1,280  14:30  🏠       │ │  ← 标记同步状态
│ │   午餐 @ 吉野家  [已同步]       │ │
│ ├─────────────────────────────────┤ │
│ │👩 日用品 ¥2,100  11:20  🏠     │ │
│ │   ドラッグストア                │ │
│ ├─────────────────────────────────┤ │
│ │👨 交通費 ¥210  09:15  👤       │ │
│ │   JR通勤  [仅个人]             │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│ 🏠   📊   ➕   🛒   ⚙️              │  ← 底部导航栏
│ 首页  报表  记账  购物  设置        │
└─────────────────────────────────────┘
```

### 4.3 关键交互规范

**记账流程（支出）:**
1. 点击底部"➕"按钮
2. 大数字键盘输入金额
3. 自动推荐分类（基于OCR或历史）
4. 系统自动判定生存/灵魂（可手动切换）
5. 可选添加备注、照片、位置
6. 点击"保存"
7. 如为灵魂消费，播放庆祝动画（可关闭）
8. 如启用换算器，显示趣味换算Toast

**家庭配对流程:**
1. 双方都进入"设置 > 家庭配对"
2. 一方点击"发起配对"，生成QR码
3. 另一方点击"扫描配对"，扫描QR码
4. 验证指纹（显示公钥后4位，电话核对）
5. 双方确认配对
6. 设置家庭名称（如"我们的小窝"）
7. 开始同步历史数据

**同步状态指示:**
- 🟢 绿色：同步正常，数据一致
- 🟡 黄色：同步中，请等待
- 🔴 红色：同步失败，需要手动处理
- ⚫ 灰色：未配对或离线模式

### 4.4 无障碍设计

**大字体模式:**
- 支持iOS/Android系统动态字体缩放
- 最小字号14sp → 18sp（放大模式）
- 关键按钮最小点击区域：48x48dp

**色盲友好:**
- 不仅依靠颜色，还使用形状/图标区分
- 生存账户：🏠 + 蓝色
- 灵魂账户：💖 + 橙色
- 同步状态：图标 + 颜色

**语音辅助:**
- 所有交互元素标记Semantics
- 支持TalkBack（Android）和VoiceOver（iOS）

### 4.5 动画规范

**流畅性原则:**
- 所有动画60fps
- 使用Flutter的Implicit Animations优先
- 复杂动画使用Lottie预渲染

**动画时长标准:**
- 快速反馈：100-200ms（按钮点击）
- 页面切换：300-400ms（淡入淡出）
- 庆祝动画：1500-2000ms（粒子效果）

**关键动画:**
1. **灵魂消费庆祝:**
   - 粒子从中心爆发
   - 彩虹光晕扩散
   - 正向文案弹出
   - 持续2秒，可跳过

2. **大谷换算器Toast:**
   - 从底部滑入
   - 显示3秒后淡出
   - 可点击查看详情

3. **运势占卜翻转:**
   - 卡片3D翻转动画
   - 正面显示"抽签中..."
   - 反面显示运势结果
   - 撒花特效（大吉/中吉）

---

## 5. 性能与安全要求

### 5.1 性能指标

| 指标 | 目标值 | 测试方法 |
|------|--------|---------|
| 冷启动时间 | <3秒 | 从点击图标到首页可交互 |
| 热启动时间 | <1秒 | 从后台恢复 |
| 列表滚动FPS | 60fps | 1000+条交易记录 |
| OCR识别速度 | <2秒 | 标准收据照片 |
| 同步速度 | <10秒 | 1000条交易记录 |
| 数据库查询 | <100ms | 单次查询 |
| 内存占用 | <150MB | 空闲状态 |
| 包体积（APK/IPA）| <50MB | 压缩后 |

### 5.2 性能优化策略

**启动优化:**
1. 延迟初始化非关键服务
2. 数据库连接池复用
3. 预加载首页必需数据
4. 使用SplashScreen遮罩加载

**列表优化:**
1. ListView.builder + AutomaticKeepAlive
2. 图片懒加载 + 缓存
3. 分页加载（每页50条）
4. 计算密集操作移至Isolate

**数据库优化:**
1. 建立索引（bookId, timestamp, categoryId）
2. 批量操作使用batch()
3. 定期VACUUM清理碎片
4. 使用Prepared Statements

**网络优化（V1.0）:**
1. 同步采用增量更新
2. CRDT操作压缩传输
3. 支持断点续传
4. 失败自动重试（指数退避）

### 5.3 安全要求

**数据加密层级:**

| 层级 | 保护对象 | 加密算法 | 密钥来源 |
|------|---------|---------|---------|
| L1 | 整个数据库 | SQLCipher (AES-256) | 设备密钥派生 |
| L2 | 交易备注字段 | ChaCha20-Poly1305 | 用户密钥 |
| L3 | 照片文件 | AES-GCM | 照片专用密钥 |
| L4 | 同步传输 | TLS 1.3 + E2EE | 设备公钥加密 |

**密钥管理:**
```dart
class KeyManager {
  // 设备主密钥（首次生成，永不改变）
  Future<KeyPair> generateDeviceKeyPair() async {
    final keyPair = await Ed25519().newKeyPair();
    await _secureStorage.write(
      key: 'device_private_key',
      value: base64Encode(keyPair.privateKey.bytes),
    );
    return keyPair;
  }

  // 从Recovery Kit恢复密钥
  Future<KeyPair> recoverFromMnemonic(String mnemonic) async {
    final seed = mnemonicToSeed(mnemonic);
    return Ed25519().newKeyPairFromSeed(seed);
  }

  // 派生数据库加密密钥
  Future<String> deriveDatabaseKey() async {
    final privateKey = await getDevicePrivateKey();
    final hkdf = Hkdf(hmac: Hmac(Sha256()));
    final derivedKey = await hkdf.deriveKey(
      secretKey: SecretKey(privateKey.bytes),
      info: utf8.encode('database_encryption'),
      outputLength: 32,
    );
    return base64Encode(await derivedKey.extractBytes());
  }
}
```

**哈希链防篡改:**
```dart
class HashChainService {
  static String hash(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }

  Future<bool> verifyIntegrity(String bookId) async {
    final transactions = await _repo.getTransactions(
      bookId: bookId,
      orderBy: 'timestamp ASC',
    );

    String prevHash = 'genesis';
    for (var tx in transactions) {
      final expectedHash = hash(
        '${tx.id}|${tx.amount}|${tx.timestamp}|$prevHash',
      );

      if (tx.currentHash != expectedHash) {
        await _logTamperDetection(tx.id);
        return false;  // 检测到篡改
      }

      prevHash = tx.currentHash;
    }

    return true;  // 哈希链完整
  }
}
```

**生物识别保护:**
```dart
class BiometricLock {
  Future<bool> authenticate({
    required String reason,
  }) async {
    final localAuth = LocalAuthentication();

    // 检查设备支持
    final canCheckBiometrics = await localAuth.canCheckBiometrics;
    if (!canCheckBiometrics) {
      return _authenticateWithPIN();
    }

    // 尝试生物识别
    try {
      return await localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,  // 允许PIN备用
        ),
      );
    } catch (e) {
      return _authenticateWithPIN();
    }
  }

  Future<bool> _authenticateWithPIN() async {
    // 显示PIN输入对话框
    final pin = await showDialog<String>(...);
    final storedPinHash = await _secureStorage.read(key: 'pin_hash');
    return hash(pin) == storedPinHash;
  }
}
```

### 5.4 错误处理与日志

**错误处理原则:**
1. 用户可理解的错误信息（日语）
2. 提供恢复操作建议
3. 关键错误上报（匿名化）
4. 不暴露敏感信息

**日志分级:**
```dart
enum LogLevel {
  debug,   // 仅开发环境
  info,    // 一般信息
  warning, // 警告（如同步延迟）
  error,   // 错误（如OCR失败）
  fatal,   // 致命错误（如数据库损坏）
}

class Logger {
  static void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    // 生产环境只记录warning及以上
    if (!kDebugMode && level.index < LogLevel.warning.index) {
      return;
    }

    // 本地日志文件
    _writeToLocalLog(level, message, error, stackTrace);

    // 匿名化后上报（仅error和fatal）
    if (level.index >= LogLevel.error.index) {
      _reportToCrashlytics(level, message, error, stackTrace, metadata);
    }
  }

  static void _writeToLocalLog(...) {
    // 写入本地加密日志文件
    // 用户可在设置中导出用于调试
  }

  static void _reportToCrashlytics(...) {
    // 移除敏感信息后上报Firebase Crashlytics
    final sanitized = _sanitize(metadata);
    FirebaseCrashlytics.instance.recordError(error, stackTrace, ...);
  }

  static Map<String, dynamic> _sanitize(Map<String, dynamic>? data) {
    // 移除金额、备注、用户ID等敏感字段
    return data?.map((key, value) {
      if (_isSensitiveKey(key)) {
        return MapEntry(key, '[REDACTED]');
      }
      return MapEntry(key, value);
    }) ?? {};
  }
}
```

---

## 6. 开发规范

### 6.1 代码风格

**遵循Dart官方风格指南:**
- 使用`dart format`自动格式化
- 使用`dart analyze`静态检查
- 启用所有`analysis_options.yaml`建议规则

**命名规范:**
```dart
// 类名：UpperCamelCase
class TransactionListScreen extends ConsumerWidget {}

// 变量/函数：lowerCamelCase
int totalAmount = 0;
Future<void> syncData() async {}

// 常量：lowerCamelCase
const maxSyncRetries = 3;

// 枚举：UpperCamelCase
enum LedgerType { survival, soul }

// 文件名：snake_case
// transaction_list_screen.dart
// hash_chain_service.dart
```

### 6.2 Git工作流

**分支策略:**
```
main                    # 生产分支（受保护）
  ├─ develop            # 开发主分支
  │   ├─ feature/MOD-001-basic-accounting
  │   ├─ feature/MOD-003-dual-ledger
  │   └─ bugfix/fix-ocr-crash
  └─ release/v1.0.0     # 发布分支
```

**提交信息规范:**
```bash
# 格式: <type>(<scope>): <subject>

# 类型（type）
feat:     新功能
fix:      Bug修复
docs:     文档更新
style:    代码格式（不影响功能）
refactor: 重构
perf:     性能优化
test:     测试
chore:    构建/工具链

# 示例
feat(transaction): 实现双轨账本自动分类
fix(ocr): 修复小票识别金额错误
docs(readme): 更新安装说明
refactor(database): 优化查询性能
```

### 6.3 测试策略

**测试金字塔:**
```
        ┌─────────┐
        │   E2E   │  10%  # 关键用户流程
        └─────────┘
      ┌─────────────┐
      │ Integration │  30%  # 模块集成
      └─────────────┘
    ┌───────────────────┐
    │   Unit Tests      │  60%  # 业务逻辑
    └───────────────────┘
```

**单元测试示例:**
```dart
// test/features/transaction/domain/models/transaction_test.dart

void main() {
  group('Transaction', () {
    test('calculateHash should return consistent hash', () {
      final tx = Transaction(
        id: 'tx-001',
        bookId: 'book-001',
        deviceId: 'device-001',
        amount: 1280,
        type: TransactionType.expense,
        categoryId: 'food_restaurant',
        ledgerType: LedgerType.soul,
        timestamp: DateTime(2026, 2, 3, 14, 30),
        prevHash: 'prev-hash',
        currentHash: '',
        createdAt: DateTime.now(),
      );

      final hash1 = tx.calculateHash();
      final hash2 = tx.calculateHash();

      expect(hash1, equals(hash2));
      expect(hash1.length, equals(64));  // SHA-256
    });

    test('verifyHash should detect tampered transaction', () {
      final validTx = Transaction(..., currentHash: 'valid-hash');
      final tamperedTx = validTx.copyWith(amount: 9999);

      expect(validTx.verifyHash(), isTrue);
      expect(tamperedTx.verifyHash(), isFalse);
    });
  });
}
```

**集成测试示例:**
```dart
// integration_test/features/transaction/create_transaction_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('should create transaction and update list', (tester) async {
    await tester.pumpWidget(const MyApp());

    // 点击添加按钮
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // 输入金额
    await tester.enterText(find.byType(AmountInput), '1280');

    // 选择分类
    await tester.tap(find.text('食費'));
    await tester.pumpAndSettle();

    // 保存
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    // 验证：列表中显示新交易
    expect(find.text('¥1,280'), findsOneWidget);
    expect(find.text('食費'), findsOneWidget);
  });
}
```

### 6.4 CI/CD Pipeline

**GitHub Actions工作流:**
```yaml
# .github/workflows/ci.yml

name: CI

on:
  pull_request:
    branches: [develop, main]
  push:
    branches: [develop, main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'

      - name: Install dependencies
        run: flutter pub get

      - name: Run analyzer
        run: flutter analyze

      - name: Run unit tests
        run: flutter test --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info

  build:
    needs: test
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2

      - name: Build APK
        run: flutter build apk --release

      - name: Build iOS (no sign)
        run: flutter build ios --release --no-codesign

      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: app-release
          path: |
            build/app/outputs/flutter-apk/app-release.apk
            build/ios/iphoneos/Runner.app
```

### 6.5 文档要求

**每个功能模块必须包含:**
1. README.md：模块概述、使用示例
2. API文档：公共类/方法的dartdoc注释
3. 架构图：关键流程的Mermaid图表
4. 测试覆盖报告：覆盖率>80%

**dartdoc注释示例:**
```dart
/// 交易创建用例
///
/// 负责处理新交易的创建，包括：
/// - 自动分类（生存/灵魂）
/// - 哈希链计算
/// - 数据库持久化
/// - 同步标记
///
/// 示例:
/// ```dart
/// final useCase = ref.read(createTransactionUseCaseProvider);
/// await useCase.execute(
///   amount: 1280,
///   categoryId: 'food_restaurant',
///   note: '午餐',
/// );
/// ```
class CreateTransactionUseCase {
  /// 创建新交易
  ///
  /// [amount] 金额（日元，正整数）
  /// [categoryId] 分类ID，必须存在于数据库
  /// [note] 可选备注，将被加密存储
  ///
  /// 返回创建的交易对象
  ///
  /// 抛出:
  /// - [InvalidAmountException] 如果金额<=0
  /// - [CategoryNotFoundException] 如果分类不存在
  Future<Transaction> execute({
    required int amount,
    required String categoryId,
    String? note,
  }) async {
    // 实现...
  }
}
```

---

## 7. 附录

### 7.1 第三方库清单

| 库名 | 版本 | 用途 | 许可证 |
|------|------|------|--------|
| flutter_riverpod | 2.4.0 | 状态管理 | MIT |
| drift | 2.14.0 | 本地数据库 | MIT |
| pointycastle | 3.7.3 | 加密算法 | MIT |
| google_mlkit_text_recognition | 0.11.0 | OCR识别 | BSD-3 |
| tflite_flutter | 0.10.4 | TensorFlow Lite | Apache 2.0 |
| go_router | 13.0.0 | 路由导航 | BSD-3 |
| freezed | 2.4.5 | 不可变模型 | MIT |
| flutter_secure_storage | 9.0.0 | 安全密钥存储 | BSD-3 |
| local_auth | 2.1.7 | 生物识别 | BSD-3 |
| share_plus | 7.2.1 | 分享功能 | BSD-3 |

### 7.2 性能Benchmark基线

**测试设备:**
- iOS: iPhone 12 (iOS 17.0)
- Android: Pixel 6 (Android 14)

**基线数据（MVP目标）:**
| 操作 | iOS | Android |
|------|-----|---------|
| 冷启动 | 2.1秒 | 2.8秒 |
| 热启动 | 0.6秒 | 0.9秒 |
| 创建交易 | 0.3秒 | 0.4秒 |
| OCR识别 | 1.5秒 | 1.8秒 |
| 加载1000条记录 | 0.8秒 | 1.1秒 |
| 同步500条记录 | 4.2秒 | 5.1秒 |

### 7.3 相关文档

- [PRD_MVP_Global.md](./PRD_MVP_Global.md) - MVP全局需求
- [PRD_MVP_Server.md](./PRD_MVP_Server.md) - Server端需求（V1.0）
- [PRD_Module_BasicAccounting.md](./PRD_Module_BasicAccounting.md) - 基础记账模块
- [PRD_Module_DualLedger.md](./PRD_Module_DualLedger.md) - 双轨账本模块
- [PRD_Module_FamilySync.md](./PRD_Module_FamilySync.md) - 家庭同步模块
- [PRD_Module_OCR.md](./PRD_Module_OCR.md) - OCR扫描模块
- [PRD_Module_Gamification.md](./PRD_Module_Gamification.md) - 趣味功能模块
- [PRD_Module_Security.md](./PRD_Module_Security.md) - 安全与隐私模块

---

**文档状态:** Draft
**需要评审:** 技术架构师、前端开发团队、UI/UX设计师
**下一步行动:** 细化各模块PRD，准备技术选型评审会议
