# Flutter项目结构说明

**生成日期:** 2026-02-03
**基于架构:** arch2/01-core-architecture/

---

## 📁 项目目录结构

```
home-pocket-app/
├── lib/                          # 源代码目录
│   ├── main.dart                 # 应用入口
│   ├── app.dart                  # App根组件
│   │
│   ├── core/                     # 核心配置
│   │   ├── config/
│   │   │   └── app_config.dart           # 应用配置
│   │   ├── constants/
│   │   │   └── app_constants.dart        # 常量定义
│   │   ├── router/
│   │   │   └── app_router.dart           # GoRouter路由配置
│   │   └── theme/
│   │       └── warm_japanese_theme.dart  # 主题配置
│   │
│   ├── features/                 # 功能模块 (按Clean Architecture组织)
│   │   │
│   │   ├── accounting/           # MOD-001: 基础记账
│   │   │   ├── presentation/     # 展示层
│   │   │   │   ├── screens/      # 页面
│   │   │   │   │   ├── transaction_list_screen.dart
│   │   │   │   │   └── transaction_form_screen.dart
│   │   │   │   ├── widgets/      # UI组件
│   │   │   │   └── providers/    # UI状态Provider
│   │   │   │       └── transaction_list_provider.dart
│   │   │   │
│   │   │   ├── application/      # 业务逻辑层
│   │   │   │   ├── use_cases/    # Use Cases
│   │   │   │   └── services/     # 应用服务
│   │   │   │
│   │   │   ├── domain/           # 领域层
│   │   │   │   ├── models/       # 领域模型
│   │   │   │   └── repositories/ # Repository接口
│   │   │   │
│   │   │   └── data/             # 数据层
│   │   │       ├── repositories/ # Repository实现
│   │   │       ├── datasources/  # 数据源
│   │   │       │   ├── local/
│   │   │       │   │   ├── daos/      # Data Access Objects
│   │   │       │   │   └── tables/    # Drift表定义
│   │   │       │   └── file/
│   │   │       └── models/       # DTOs
│   │   │
│   │   ├── dual_ledger/          # MOD-003: 双轨账本
│   │   │   ├── presentation/
│   │   │   ├── application/
│   │   │   ├── domain/
│   │   │   └── data/
│   │   │
│   │   ├── family_sync/          # MOD-004: 家庭同步
│   │   │   ├── presentation/
│   │   │   ├── application/
│   │   │   ├── domain/
│   │   │   └── data/
│   │   │
│   │   ├── security/             # MOD-006: 安全模块
│   │   │   ├── presentation/
│   │   │   ├── application/
│   │   │   ├── domain/
│   │   │   └── data/
│   │   │
│   │   ├── analytics/            # MOD-007: 数据分析
│   │   │   ├── presentation/
│   │   │   ├── application/
│   │   │   ├── domain/
│   │   │   └── data/
│   │   │
│   │   ├── settings/             # MOD-008: 设置管理
│   │   │   ├── presentation/
│   │   │   ├── application/
│   │   │   ├── domain/
│   │   │   └── data/
│   │   │
│   │   └── ocr/                  # MOD-005: OCR扫描
│   │       ├── presentation/
│   │       ├── application/
│   │       ├── domain/
│   │       └── data/
│   │
│   ├── shared/                   # 共享组件
│   │   ├── widgets/              # 可复用UI组件
│   │   │   ├── buttons/
│   │   │   ├── cards/
│   │   │   ├── dialogs/
│   │   │   └── inputs/
│   │   ├── extensions/           # 扩展方法
│   │   └── utils/                # 工具函数
│   │
│   ├── l10n/                     # 国际化
│   │   ├── app_ja.arb            # 日文
│   │   ├── app_zh.arb            # 中文
│   │   └── app_en.arb            # 英文
│   │
│   └── generated/                # 生成代码 (自动生成，不手动编辑)
│       ├── *.g.dart              # build_runner生成
│       └── *.freezed.dart        # freezed生成
│
├── test/                         # 测试目录
│   ├── unit/                     # 单元测试
│   ├── widget/                   # Widget测试
│   └── integration/              # 集成测试
│
├── integration_test/             # E2E集成测试
│
├── assets/                       # 资源文件
│   ├── images/                   # 图片
│   ├── animations/               # 动画 (Lottie)
│   ├── models/                   # ML模型 (TFLite)
│   └── data/                     # 静态数据 (商户数据库等)
│
├── arch2/                        # 架构文档
│   ├── 01-core-architecture/     # 整体架构
│   ├── 02-module-specs/          # 模块规范
│   └── 03-adr/                   # 架构决策记录
│
├── worklog/                      # 开发日志
│
├── pubspec.yaml                  # 项目配置
├── analysis_options.yaml         # 代码分析配置
├── build.yaml                    # 代码生成配置
├── l10n.yaml                     # 国际化配置
└── README.md                     # 项目说明
```

---

## 🏗️ Clean Architecture 层次说明

### 1. Presentation Layer (展示层)

**位置:** `lib/features/*/presentation/`

**职责:**
- 渲染UI
- 处理用户交互
- 消费业务逻辑层Provider
- **不包含业务逻辑**

**包含:**
- `screens/` - 页面组件
- `widgets/` - 可复用UI组件
- `providers/` - UI状态Provider

**示例:**
```dart
// lib/features/accounting/presentation/screens/transaction_list_screen.dart
class TransactionListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionListProvider);
    // 只负责渲染UI
  }
}
```

### 2. Application Layer (业务逻辑层)

**位置:** `lib/features/*/application/`

**职责:**
- 实现业务规则
- 编排Use Cases
- 管理应用状态
- **不依赖具体实现**

**包含:**
- `use_cases/` - 业务用例
- `services/` - 应用服务
- `providers/` - 业务状态Provider

**示例:**
```dart
// lib/features/accounting/application/use_cases/create_transaction_use_case.dart
class CreateTransactionUseCase {
  Future<Result<Transaction>> execute(TransactionInput input) {
    // 业务逻辑：验证 → 分类 → 加密 → 保存
  }
}
```

### 3. Domain Layer (领域层)

**位置:** `lib/features/*/domain/`

**职责:**
- 定义业务实体
- 定义Repository接口
- 包含领域逻辑
- **完全独立，无外部依赖**

**包含:**
- `models/` - 领域模型 (Freezed)
- `repositories/` - Repository接口

**示例:**
```dart
// lib/features/accounting/domain/models/transaction.dart
@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required int amount,
    // ...
  }) = _Transaction;
}

// lib/features/accounting/domain/repositories/transaction_repository.dart
abstract class TransactionRepository {
  Future<void> insert(Transaction transaction);
  Future<List<Transaction>> getTransactions({required String bookId});
}
```

### 4. Data Layer (数据层)

**位置:** `lib/features/*/data/`

**职责:**
- 实现数据访问
- 管理数据持久化
- DTO ↔ Domain Model转换
- 缓存策略

**包含:**
- `repositories/` - Repository实现
- `datasources/` - 数据源 (Database, File)
- `models/` - DTOs (Data Transfer Objects)

**示例:**
```dart
// lib/features/accounting/data/repositories/transaction_repository_impl.dart
class TransactionRepositoryImpl implements TransactionRepository {
  final AppDatabase _db;
  final FieldEncryption _encryption;

  @override
  Future<void> insert(Transaction transaction) async {
    // 实现数据访问逻辑
  }
}
```

### 5. Infrastructure Layer (基础设施层)

**位置:** `lib/infrastructure/` (共享)

**职责:**
- 提供技术能力
- 封装第三方库
- 平台特定实现
- **与业务无关，可复用**

**包含:**
- `crypto/` - 加密服务
- `ml/` - 机器学习
- `sync/` - 同步协议
- `security/` - 安全服务

**示例:**
```dart
// lib/infrastructure/crypto/encryption_service.dart
class EncryptionService {
  Future<String> encrypt(String plaintext) {
    // 提供加密算法，与业务无关
  }
}
```

---

## 📦 依赖关系

```
┌─────────────────────────────────────┐
│   Presentation (UI)                 │
└──────────────┬──────────────────────┘
               │ depends on
┌──────────────▼──────────────────────┐
│   Application (Business Logic)      │
└──────────────┬──────────────────────┘
               │ depends on
┌──────────────▼──────────────────────┐
│   Domain (Entities & Interfaces)    │
└──────────────▲──────────────────────┘
               │ implements
┌──────────────┴──────────────────────┐
│   Data (Repository Implementations) │
└──────────────┬──────────────────────┘
               │ uses
┌──────────────▼──────────────────────┐
│   Infrastructure (Technical)        │
└─────────────────────────────────────┘
```

**依赖规则:**
- 外层依赖内层
- 内层不知道外层的存在
- Domain层完全独立

---

## 🔧 代码生成

项目使用以下代码生成工具：

### 1. Riverpod Generator

**作用:** 为 `@riverpod` 注解生成 `.g.dart` 文件

**示例:**
```dart
// transaction_list_provider.dart
@riverpod
class TransactionList extends _$TransactionList {
  // ...
}

// 生成 → transaction_list_provider.g.dart
```

### 2. Freezed

**作用:** 为 `@freezed` 注解生成不可变模型

**示例:**
```dart
// transaction.dart
@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required int amount,
  }) = _Transaction;
}

// 生成 → transaction.freezed.dart, transaction.g.dart
```

### 3. Drift

**作用:** 为数据库表生成 DAO 和查询代码

**示例:**
```dart
// database.dart
@DriftDatabase(tables: [Transactions, Categories])
class AppDatabase extends _$AppDatabase {
  // ...
}

// 生成 → database.g.dart
```

### 运行代码生成

```bash
# 一次性生成
flutter pub run build_runner build

# 持续监听
flutter pub run build_runner watch
```

---

## 🌍 国际化

### ARB文件

- `lib/l10n/app_ja.arb` - 日文 (默认)
- `lib/l10n/app_zh.arb` - 中文
- `lib/l10n/app_en.arb` - 英文

### 使用方法

```dart
import 'package:flutter/material.dart';
import 'package:home_pocket/generated/l10n.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(S.of(context).appName);
  }
}
```

---

## 🧪 测试

### 目录结构

```
test/
├── unit/                  # 单元测试
│   ├── application/       # Use Cases, Services
│   ├── domain/            # 领域模型
│   └── infrastructure/    # 基础服务
├── widget/                # Widget测试
│   └── presentation/
└── integration/           # 集成测试

integration_test/          # E2E测试
└── app_test.dart
```

### 测试命令

```bash
# 单元测试
flutter test test/unit/

# Widget测试
flutter test test/widget/

# 集成测试
flutter test integration_test/

# 覆盖率报告
flutter test --coverage
```

---

## 🎯 下一步

1. **运行代码生成:** `flutter pub run build_runner build`
2. **运行应用:** `flutter run`
3. **查看文档:** 阅读 `arch2/` 目录下的架构文档
4. **开始开发:** 从 Phase 1 (MOD-006 安全模块) 开始

---

**文档维护者:** 架构团队
**最后更新:** 2026-02-03
