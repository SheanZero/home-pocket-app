# Home Pocket MVP - 完整架构技术指南

**文档版本:** 2.0
**创建日期:** 2026-02-03
**最后更新:** 2026-02-06
**文档类型:** 综合技术指南
**覆盖范围:** MVP总体架构 + 所有功能模块技术设计
**变更说明:** v2.0 - 基于 ARCH-008 层次标准重构，引入全局 Application 层、瘦 Feature 模式

---

## 📋 文档说明

本文档是Home Pocket MVP应用的**完整架构技术指南**，整合了以下内容：

1. **总体架构设计** - 技术栈、层次架构、核心设计决策
2. **数据架构** - 完整数据模型、加密策略
3. **安全架构** - E2EE、密钥管理、哈希链
4. **状态管理** - Riverpod架构模式
5. **集成模式** - Repository、Use Case、CRDT
6. **所有模块技术规格** - MOD-001至MOD-009的详细实现
7. **架构决策记录(ADR)** - 关键技术选型理由

---

## 第一部分：总体架构设计

### 1.1 技术栈全景

#### 核心技术栈

```yaml
# 平台与框架
Platform: Flutter 3.16+
Language: Dart 3.2+
Target: iOS 14+ / Android 7+ (API 24+)

# 架构模式
Architecture: Clean Architecture + Repository Pattern
Modularization: Feature-based modularization

# 状态管理
State Management: flutter_riverpod ^2.4.0
Code Generation: riverpod_annotation ^2.3.0, riverpod_generator ^2.3.0

# 本地数据库
Database ORM: drift ^2.14.0
Encryption: sqlcipher_flutter_libs ^0.6.0

# 安全与加密
Key Pairs: pointycastle ^3.7.3 (Ed25519)
Field Encryption: cryptography ^2.5.0 (ChaCha20-Poly1305)
Hashing: crypto ^3.0.3 (SHA-256)
Secure Storage: flutter_secure_storage ^9.0.0
Biometric: local_auth ^2.1.7

# 机器学习与OCR
OCR (Android): google_mlkit_text_recognition ^0.11.0
OCR (iOS): Native Vision Framework via platform channels
ML Inference: tflite_flutter ^0.10.4

# UI与导航
Navigation: go_router ^13.0.0
SVG: flutter_svg ^2.0.9
Animations: lottie ^3.0.0
Charts: fl_chart ^0.65.0

# 工具库
UUID: uuid ^4.2.1
Internationalization: intl ^0.19.0
Date Utilities: jiffy ^6.2.1
File Sharing: share_plus ^7.2.1
Path Provider: path_provider ^2.1.1

# 开发工具
Code Generation: build_runner ^2.4.7
JSON Serialization: json_serializable ^6.7.1
Immutable Models: freezed ^2.4.5, freezed_annotation ^2.4.1
Logging: logger ^2.0.2

# 测试
Unit Testing: flutter_test (SDK)
Widget Testing: flutter_test (SDK)
Integration Testing: integration_test (SDK)
Mocking: mocktail ^1.0.4
```

### 1.2 架构层次设计

#### Clean Architecture 实现

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│                         (展示层)                             │
│                                                              │
│  lib/features/{feature}/presentation/                        │
│  ├── screens/          # 页面组件                            │
│  ├── widgets/          # Feature 专用 UI 组件                │
│  └── providers/        # UI 状态 Provider                    │
│                                                              │
│  lib/core/theme/       # 全局主题系统                        │
│  └── warm_japanese_theme.dart                                │
│                                                              │
│  lib/shared/widgets/   # 跨 Feature 可复用 UI 组件           │
│                                                              │
│  职责：                                                      │
│  • 渲染 UI                                                   │
│  • 处理用户交互                                              │
│  • 消费 Application 层的 Use Cases（通过 Riverpod）           │
│  • 不包含业务逻辑                                            │
│  • 每个 Feature 独立管理自己的 Presentation                   │
└──────────────────────────┬───────────────────────────────────┘
                           │ Riverpod Providers
┌──────────────────────────▼───────────────────────────────────┐
│              APPLICATION LAYER (全局业务逻辑层)               │
│                                                              │
│  lib/application/          ← 全局层，独立于 features          │
│  ├── accounting/           # 记账业务逻辑                    │
│  │   ├── create_transaction_use_case.dart                    │
│  │   ├── update_transaction_use_case.dart                    │
│  │   ├── delete_transaction_use_case.dart                    │
│  │   ├── get_transactions_use_case.dart                      │
│  │   └── manage_category_use_case.dart                       │
│  ├── dual_ledger/          # 双轨账本业务逻辑                │
│  │   ├── classification_service.dart                         │
│  │   └── rule_engine.dart                                    │
│  ├── ocr/                  # OCR 业务逻辑                    │
│  │   ├── scan_receipt_use_case.dart                          │
│  │   ├── receipt_parser.dart                                 │
│  │   └── save_receipt_photo_use_case.dart                    │
│  ├── security/             # 安全业务逻辑                    │
│  │   ├── verify_hash_chain_use_case.dart                     │
│  │   └── generate_recovery_kit_use_case.dart                 │
│  ├── analytics/            # 分析业务逻辑                    │
│  │   ├── generate_monthly_report_use_case.dart               │
│  │   └── calculate_budget_use_case.dart                      │
│  └── settings/             # 设置业务逻辑                    │
│      ├── export_backup_use_case.dart                         │
│      └── import_backup_use_case.dart                         │
│                                                              │
│  职责：                                                      │
│  • 实现业务规则和 Use Cases                                  │
│  • 编排跨层协作（Domain + Data + Infrastructure）            │
│  • 按业务领域组织，不按技术分层                              │
│  • 不依赖 Presentation 层                                    │
│  ⚠️ 全局层：NEVER 放在 lib/features/ 内部                    │
└──────────────────────────┬───────────────────────────────────┘
                           │ Repository Interfaces
┌──────────────────────────▼───────────────────────────────────┐
│                     DOMAIN LAYER                             │
│                      (领域层)                                │
│                                                              │
│  lib/features/{feature}/domain/    ← 每个 Feature 独立       │
│  ├── models/           # 领域模型（Freezed）                 │
│  │   ├── transaction.dart                                    │
│  │   ├── category.dart                                       │
│  │   └── book.dart                                           │
│  └── repositories/     # Repository 接口（抽象定义）         │
│      ├── transaction_repository.dart                         │
│      ├── category_repository.dart                            │
│      └── book_repository.dart                                │
│                                                              │
│  职责：                                                      │
│  • 定义业务实体（models）                                    │
│  • 定义 Repository 接口（abstractions）                      │
│  • 完全独立，无外部依赖                                       │
│  ⚠️ ONLY models + repository interfaces                     │
│  ⚠️ 不含 use_cases/、services/、value_objects/               │
└──────────────────────────┬───────────────────────────────────┘
                           │ Implementation
┌──────────────────────────▼───────────────────────────────────┐
│                      DATA LAYER                              │
│                      (数据层)                                │
│                                                              │
│  lib/data/                 ← 全局层，跨 Feature 共享         │
│  ├── app_database.dart     # 主 Drift 数据库定义             │
│  ├── tables/               # ALL Drift 表定义                │
│  │   ├── transactions_table.dart                             │
│  │   ├── categories_table.dart                               │
│  │   ├── books_table.dart                                    │
│  │   ├── devices_table.dart                                  │
│  │   ├── recovery_kits_table.dart                            │
│  │   ├── audit_logs_table.dart                               │
│  │   ├── receipt_photos_table.dart                           │
│  │   └── sync_logs_table.dart                                │
│  ├── daos/                 # Data Access Objects              │
│  │   ├── transaction_dao.dart                                │
│  │   ├── category_dao.dart                                   │
│  │   ├── book_dao.dart                                       │
│  │   ├── device_dao.dart                                     │
│  │   └── receipt_photo_dao.dart                              │
│  ├── repositories/         # Repository 实现                 │
│  │   ├── transaction_repository_impl.dart                    │
│  │   ├── category_repository_impl.dart                       │
│  │   ├── book_repository_impl.dart                           │
│  │   ├── receipt_photo_repository_impl.dart                  │
│  │   └── sync_repository_impl.dart                           │
│  └── models/               # DTOs (Data Transfer Objects)    │
│                                                              │
│  职责：                                                      │
│  • 实现 Domain 层 Repository 接口                            │
│  • 管理数据持久化（Drift tables + DAOs）                     │
│  • DTO 与 Domain Model 转换                                  │
│  ⚠️ 全局层：ALL 表定义集中在 lib/data/tables/                │
│  ⚠️ NEVER 在 Feature 内部定义 Drift 表                       │
└──────────────────────────┬───────────────────────────────────┘
                           │ Platform APIs
┌──────────────────────────▼───────────────────────────────────┐
│                 INFRASTRUCTURE LAYER                         │
│                    (基础设施层)                               │
│                                                              │
│  lib/infrastructure/       ← 全局层，NEVER 放在 features 内  │
│  ├── crypto/               # 加密技术                        │
│  │   ├── services/                                           │
│  │   │   ├── key_manager.dart                                │
│  │   │   ├── field_encryption_service.dart                   │
│  │   │   ├── hash_chain_service.dart                         │
│  │   │   ├── photo_encryption_service.dart                   │
│  │   │   └── recovery_kit_service.dart                       │
│  │   ├── models/                                             │
│  │   │   ├── device_key_pair.dart        ← 唯一定义          │
│  │   │   └── chain_verification_result.dart ← 唯一定义       │
│  │   ├── repositories/                                       │
│  │   └── database/                                           │
│  ├── ml/                   # ML/OCR 技术                     │
│  │   ├── ocr/                                                │
│  │   │   ├── ocr_service.dart            # 抽象接口          │
│  │   │   ├── mlkit_ocr_service.dart      # Android 实现      │
│  │   │   └── vision_ocr_service.dart     # iOS 实现          │
│  │   ├── image_preprocessor.dart                             │
│  │   ├── tflite_classifier.dart          ← 唯一定义          │
│  │   └── merchant_database.dart          ← 唯一定义          │
│  ├── sync/                 # 同步技术                        │
│  │   ├── crdt_service.dart                                   │
│  │   ├── bluetooth_transport.dart                            │
│  │   ├── nfc_transport.dart                                  │
│  │   └── wifi_transport.dart                                 │
│  ├── security/             # 安全技术                        │
│  │   ├── biometric_service.dart                              │
│  │   ├── secure_storage_service.dart                         │
│  │   └── audit_logger.dart                                   │
│  └── platform/             # 平台封装                        │
│      ├── ios/                                                │
│      └── android/                                            │
│                                                              │
│  职责：                                                      │
│  • 提供全局技术能力                                          │
│  • 封装第三方库                                              │
│  • 平台特定实现                                              │
│  • 去重：每个技术能力只有唯一定义                            │
│  ⚠️ 全局层：NEVER 在 Feature 内创建 infrastructure/ 目录     │
└──────────────────────────────────────────────────────────────┘
```

**层间依赖规则（CRITICAL）：**

```
Presentation → Application → Domain ← Data ← Infrastructure

规则：
• Presentation 只依赖 Application（通过 Riverpod ref.watch）
• Application 依赖 Domain（models + repository interfaces）
• Data 实现 Domain 的 Repository 接口
• Infrastructure 提供技术能力给 Data 和 Application
• Domain 层完全独立，无外部依赖
```

**Feature 结构约束（CRITICAL）：**

```
lib/features/{feature}/
├── domain/              # ONLY: models + repository interfaces
│   ├── models/
│   └── repositories/
└── presentation/        # UI 层
    ├── screens/
    ├── widgets/
    └── providers/

⚠️ Feature 内部禁止包含：
  ❌ application/     → 移至 lib/application/{domain}/
  ❌ infrastructure/  → 移至 lib/infrastructure/
  ❌ data/tables/     → 移至 lib/data/tables/
  ❌ data/daos/       → 移至 lib/data/daos/
```

### 1.3 项目目录结构

```
home_pocket/
├── lib/
│   ├── main.dart                    # 应用入口
│   ├── app.dart                     # App 根组件
│   │
│   ├── infrastructure/              # 全局技术能力（NEVER in features/）
│   │   ├── crypto/                  # 加密技术
│   │   │   ├── services/
│   │   │   │   ├── key_manager.dart
│   │   │   │   ├── field_encryption_service.dart
│   │   │   │   ├── hash_chain_service.dart
│   │   │   │   ├── photo_encryption_service.dart
│   │   │   │   └── recovery_kit_service.dart
│   │   │   ├── models/
│   │   │   │   ├── device_key_pair.dart
│   │   │   │   └── chain_verification_result.dart
│   │   │   ├── repositories/
│   │   │   └── database/
│   │   │       └── encrypted_database.dart
│   │   ├── ml/                      # ML/OCR 技术
│   │   │   ├── ocr/
│   │   │   │   ├── ocr_service.dart         # 抽象接口
│   │   │   │   ├── mlkit_ocr_service.dart   # Android
│   │   │   │   └── vision_ocr_service.dart  # iOS
│   │   │   ├── image_preprocessor.dart
│   │   │   ├── tflite_classifier.dart
│   │   │   └── merchant_database.dart
│   │   ├── sync/                    # 同步技术
│   │   │   ├── crdt_service.dart
│   │   │   ├── bluetooth_transport.dart
│   │   │   ├── nfc_transport.dart
│   │   │   └── wifi_transport.dart
│   │   ├── i18n/                    # 国際化基盤
│   │   │   ├── formatters/
│   │   │   │   ├── date_formatter.dart
│   │   │   │   └── number_formatter.dart
│   │   │   ├── models/
│   │   │   │   └── locale_settings.dart
│   │   │   └── supported_locales.dart
│   │   ├── security/                # 安全技術
│   │   │   ├── biometric_service.dart
│   │   │   ├── secure_storage_service.dart
│   │   │   └── audit_logger.dart
│   │   └── platform/                # 平台封装
│   │       ├── ios/
│   │       └── android/
│   │
│   ├── application/                 # 全局业务逻辑层（独立于 features）
│   │   ├── accounting/              # 记账业务逻辑
│   │   │   ├── create_transaction_use_case.dart
│   │   │   ├── update_transaction_use_case.dart
│   │   │   ├── delete_transaction_use_case.dart
│   │   │   ├── get_transactions_use_case.dart
│   │   │   └── manage_category_use_case.dart
│   │   ├── dual_ledger/             # 双轨账本业务逻辑
│   │   │   ├── classification_service.dart
│   │   │   └── rule_engine.dart
│   │   ├── ocr/                     # OCR 业务逻辑
│   │   │   ├── scan_receipt_use_case.dart
│   │   │   ├── receipt_parser.dart
│   │   │   └── save_receipt_photo_use_case.dart
│   │   ├── security/                # 安全业务逻辑
│   │   │   ├── verify_hash_chain_use_case.dart
│   │   │   └── generate_recovery_kit_use_case.dart
│   │   ├── analytics/               # 分析业务逻辑
│   │   │   ├── generate_monthly_report_use_case.dart
│   │   │   └── calculate_budget_use_case.dart
│   │   └── settings/                # 设置业务逻辑
│   │       ├── export_backup_use_case.dart
│   │       └── import_backup_use_case.dart
│   │
│   ├── data/                        # 全局数据访问层
│   │   ├── app_database.dart        # 主 Drift 数据库定义
│   │   ├── tables/                  # ALL Drift 表定义
│   │   │   ├── transactions_table.dart
│   │   │   ├── categories_table.dart
│   │   │   ├── books_table.dart
│   │   │   ├── devices_table.dart
│   │   │   ├── recovery_kits_table.dart
│   │   │   ├── audit_logs_table.dart
│   │   │   ├── receipt_photos_table.dart
│   │   │   └── sync_logs_table.dart
│   │   ├── daos/                    # Data Access Objects
│   │   │   ├── transaction_dao.dart
│   │   │   ├── category_dao.dart
│   │   │   ├── book_dao.dart
│   │   │   ├── device_dao.dart
│   │   │   └── receipt_photo_dao.dart
│   │   ├── repositories/            # Repository 实现
│   │   │   ├── transaction_repository_impl.dart
│   │   │   ├── category_repository_impl.dart
│   │   │   ├── book_repository_impl.dart
│   │   │   ├── receipt_photo_repository_impl.dart
│   │   │   └── sync_repository_impl.dart
│   │   └── models/                  # DTOs
│   │
│   ├── features/                    # 功能模块（瘦 Feature）
│   │   ├── accounting/              # 记账 (MOD-001)
│   │   │   ├── domain/              # ONLY: models + repository interfaces
│   │   │   │   ├── models/
│   │   │   │   │   ├── transaction.dart
│   │   │   │   │   ├── category.dart
│   │   │   │   │   └── book.dart
│   │   │   │   └── repositories/
│   │   │   │       ├── transaction_repository.dart
│   │   │   │       ├── category_repository.dart
│   │   │   │       └── book_repository.dart
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       ├── widgets/
│   │   │       └── providers/
│   │   ├── dual_ledger/             # 双轨账本 (MOD-002)
│   │   │   ├── domain/
│   │   │   │   └── models/
│   │   │   │       ├── ledger_type.dart
│   │   │   │       └── classification_result.dart
│   │   │   └── presentation/
│   │   ├── ocr/                     # OCR 扫描 (MOD-004)
│   │   │   ├── domain/
│   │   │   │   ├── models/
│   │   │   │   │   ├── receipt_data.dart
│   │   │   │   │   └── ocr_result.dart
│   │   │   │   └── repositories/
│   │   │   │       └── receipt_photo_repository.dart
│   │   │   └── presentation/
│   │   ├── security/                # 安全模块 (MOD-005)
│   │   │   ├── domain/
│   │   │   │   └── models/
│   │   │   │       └── auth_result.dart
│   │   │   └── presentation/
│   │   ├── sync/                    # 家庭同步 (MOD-003)
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── analytics/               # 数据分析 (MOD-006)
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── settings/                # 设置管理 (MOD-007)
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │       └── providers/
│   │   │           └── locale_provider.dart
│   │   └── gamification/            # 趣味功能 (MOD-008)
│   │       ├── domain/
│   │       └── presentation/
│   │
│   ├── core/                        # 核心配置
│   │   ├── config/
│   │   │   └── app_config.dart
│   │   ├── constants/
│   │   │   └── app_constants.dart
│   │   ├── initialization/
│   │   │   └── app_initializer.dart
│   │   ├── router/
│   │   │   └── app_router.dart      # GoRouter 配置
│   │   └── theme/
│   │       └── warm_japanese_theme.dart
│   │
│   ├── shared/                      # 共享组件
│   │   ├── widgets/
│   │   ├── extensions/
│   │   └── utils/
│   │       └── result.dart
│   │
│   ├── l10n/                        # 国际化
│   │   ├── app_ja.arb               # 日语（默认）
│   │   ├── app_zh.arb               # 中文
│   │   └── app_en.arb               # 英语
│   │
│   └── generated/                   # 生成代码（gitignored）
│       ├── *.g.dart
│       └── *.freezed.dart
│
├── test/                            # 测试
│   ├── unit/
│   │   ├── application/
│   │   ├── domain/
│   │   └── infrastructure/
│   ├── widget/
│   └── helpers/
│       └── test_helpers.dart
│
├── integration_test/                # 集成测试
│
├── assets/                          # 资源文件
│   ├── images/
│   ├── animations/
│   │   └── lottie/
│   ├── models/
│   │   └── classifier.tflite        # TF Lite 模型
│   └── data/
│       └── merchants.json           # 商家数据库
│
├── android/
├── ios/
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

## 第二部分：数据架构设计

### 2.1 核心数据模型

#### Entity Relationship Diagram

```
┌─────────────┐
│    Books    │  账本（个人/家庭）
│             │
│ • id (PK)   │
│ • name      │
│ • type      │ 'personal' | 'family'
│ • created_at│
└──────┬──────┘
       │ 1:N
       │
┌──────▼──────┐         ┌──────────────┐
│   Devices   │ N:1 ───►│ SoulAccount  │ 灵魂账户配置
│             │          │   Config     │
│ • id (PK)   │          │              │
│ • book_id   │          │ • id (PK)    │
│ • public_key│          │ • device_id  │
│ • name      │          │ • soul_name  │
│ • created_at│          │ • icon       │
└──────┬──────┘          │ • budget     │
       │ 1:N             └──────────────┘
       │
┌──────▼──────────────────────────┐
│        Transactions              │  交易记录
│                                  │
│ • id (PK)                        │
│ • book_id (FK: Books)            │
│ • device_id (FK: Devices)        │
│ • amount                         │  金额(日元)
│ • type                           │  'expense'|'income'|'transfer'
│ • category_id (FK: Categories)   │
│ • ledger_type                    │  'survival'|'soul'
│ • timestamp                      │  发生时间
│ • note (encrypted)               │  备注(加密)
│ • photo_hash                     │  照片哈希
│ • prev_hash                      │  前一笔哈希
│ • current_hash                   │  当前哈希(哈希链)
│ • created_at                     │
│ • is_private                     │  是否私密
└──────┬────────────────────┬─────┘
       │ N:1                │ N:1
       │                    │
┌──────▼──────┐      ┌──────▼──────┐
│ Categories  │      │  SyncLogs   │  同步日志
│             │      │             │
│ • id (PK)   │      │ • id (PK)   │
│ • name      │      │ • book_id   │
│ • icon      │      │ • synced_at │
│ • color     │      │ • sync_count│
│ • ledger_t  │      │ • status    │
│ • is_system │      └─────────────┘
│ • is_archived│
│ • created_at│
└─────────────┘
```

#### Drift数据库表定义

```dart
// lib/data/tables/books_table.dart
class Books extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();  // 'personal' | 'family'
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// lib/data/tables/devices_table.dart
class Devices extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text().references(Books, #id)();
  TextColumn get publicKey => text()();
  TextColumn get name => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// lib/data/tables/transactions_table.dart
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text().references(Books, #id)();
  TextColumn get deviceId => text().references(Devices, #id)();
  IntColumn get amount => integer()();
  TextColumn get type => text()();  // 'expense' | 'income' | 'transfer'
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get ledgerType => text().withDefault(const Constant('survival'))();
  IntColumn get timestamp => integer()();
  TextColumn get note => text().nullable()();  // 加密存储
  TextColumn get photoHash => text().nullable()();
  TextColumn get prevHash => text().nullable()();
  TextColumn get currentHash => text()();  // 哈希链
  IntColumn get createdAt => integer()();
  IntColumn get isPrivate => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {bookId, currentHash},  // 哈希唯一性
  ];
}

// lib/data/tables/categories_table.dart
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text()();  // Emoji
  TextColumn get color => text()();  // Hex color
  TextColumn get ledgerType => text().withDefault(const Constant('auto'))();
  IntColumn get isSystem => integer().withDefault(const Constant(0))();
  IntColumn get isArchived => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// lib/data/tables/soul_account_configs_table.dart
class SoulAccountConfigs extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text().references(Books, #id)();
  TextColumn get deviceId => text().references(Devices, #id)();
  TextColumn get soulName => text().nullable()();  // "高达基金"
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  IntColumn get monthlyBudget => integer().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {bookId, deviceId},  // 每个设备在每个账本中唯一
  ];
}

// lib/data/tables/sync_logs_table.dart
class SyncLogs extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text().references(Books, #id)();
  IntColumn get syncedAt => integer()();
  IntColumn get syncCount => integer()();
  TextColumn get status => text()();  // 'success' | 'failed'
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

### 2.2 数据库配置

```dart
// lib/data/app_database.dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

@DriftDatabase(tables: [
  Books,
  Devices,
  Transactions,
  Categories,
  SoulAccountConfigs,
  SyncLogs,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _insertDefaultCategories();
      await _createIndexes();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // 未来版本迁移逻辑
    },
  );

  // 插入预设分类
  Future<void> _insertDefaultCategories() async {
    await batch((batch) {
      batch.insertAll(categories, _getDefaultCategories());
    });
  }

  List<CategoriesCompanion> _getDefaultCategories() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return [
      // 生存账户分类 (8个)
      CategoriesCompanion.insert(
        id: 'food_groceries',
        name: '食費（スーパー）',
        icon: '🛒',
        color: '#4CAF50',
        ledgerType: const Value('survival'),
        isSystem: const Value(1),
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        id: 'housing_rent',
        name: '住宅（家賃）',
        icon: '🏠',
        color: '#795548',
        ledgerType: const Value('survival'),
        isSystem: const Value(1),
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        id: 'utilities',
        name: '光熱費',
        icon: '💡',
        color: '#FF9800',
        ledgerType: const Value('survival'),
        isSystem: const Value(1),
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        id: 'transport_commute',
        name: '交通費（通勤）',
        icon: '🚇',
        color: '#2196F3',
        ledgerType: const Value('survival'),
        isSystem: const Value(1),
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        id: 'medical',
        name: '医療費',
        icon: '💊',
        color: '#F44336',
        ledgerType: const Value('survival'),
        isSystem: const Value(1),
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        id: 'insurance',
        name: '保険',
        icon: '🛡️',
        color: '#9C27B0',
        ledgerType: const Value('survival'),
        isSystem: const Value(1),
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        id: 'communication',
        name: '通信費',
        icon: '📱',
        color: '#3F51B5',
        ledgerType: const Value('survival'),
        isSystem: const Value(1),
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        id: 'daily_goods',
        name: '日用品',
        icon: '🧴',
        color: '#00BCD4',
        ledgerType: const Value('survival'),
        isSystem: const Value(1),
        createdAt: now,
      ),

      // 灵魂账户分类 (7个)
      CategoriesCompanion.insert(
        id: 'food_restaurant',
        name: '食費（外食）',
        icon: '🍜',
        color: '#FF9800',
        ledgerType: const Value('soul'),
        isSystem: const Value(1),
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        id: 'entertainment',
        name: '娯楽',
        icon: '🎮',
        color: '#E91E63',
        ledgerType: const Value('soul'),
        isSystem: const Value(1),
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        id: 'hobby',
        name: '趣味',
        icon: '🎨',
        color: '#9C27B0',
        ledgerType: const Value('soul'),
        isSystem: const Value(1),
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        id: 'shopping_fashion',
        name: 'ファッション',
        icon: '👔',
        color: '#FF5722',
        ledgerType: const Value('soul'),
        isSystem: const Value(1),
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        id: 'beauty',
        name: '美容',
        icon: '💅',
        color: '#E91E63',
        ledgerType: const Value('soul'),
        isSystem: const Value(1),
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        id: 'travel',
        name: '旅行',
        icon: '✈️',
        color: '#00BCD4',
        ledgerType: const Value('soul'),
        isSystem: const Value(1),
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        id: 'education_hobby',
        name: '学習（趣味）',
        icon: '📚',
        color: '#3F51B5',
        ledgerType: const Value('soul'),
        isSystem: const Value(1),
        createdAt: now,
      ),

      // 收入分类 (5个)
      CategoriesCompanion.insert(
        id: 'income_salary',
        name: '給料（月給）',
        icon: '💼',
        color: '#4CAF50',
        ledgerType: const Value('income'),
        isSystem: const Value(1),
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        id: 'income_bonus',
        name: 'ボーナス',
        icon: '🎁',
        color: '#8BC34A',
        ledgerType: const Value('income'),
        isSystem: const Value(1),
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        id: 'income_sidejob',
        name: '副業',
        icon: '💻',
        color: '#CDDC39',
        ledgerType: const Value('income'),
        isSystem: const Value(1),
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        id: 'income_investment',
        name: '投資収益',
        icon: '📈',
        color: '#FFC107',
        ledgerType: const Value('income'),
        isSystem: const Value(1),
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        id: 'income_other',
        name: 'その他収入',
        icon: '💰',
        color: '#FF9800',
        ledgerType: const Value('income'),
        isSystem: const Value(1),
        createdAt: now,
      ),
    ];
  }

  // 创建性能优化索引
  Future<void> _createIndexes() async {
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_transactions_book_timestamp
      ON transactions(book_id, timestamp DESC)
    ''');

    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_transactions_category
      ON transactions(category_id)
    ''');

    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_transactions_ledger
      ON transactions(ledger_type, timestamp DESC)
    ''');

    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_transactions_device
      ON transactions(device_id, timestamp DESC)
    ''');
  }

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'homepocket.db'));

      return NativeDatabase.createInBackground(
        file,
        setup: (rawDb) {
          // 启用SQLCipher加密
          final key = _getDatabaseKey();
          rawDb.execute("PRAGMA key = '$key'");
          rawDb.execute("PRAGMA cipher_page_size = 4096");
          rawDb.execute("PRAGMA kdf_iter = 256000");
          rawDb.execute("PRAGMA cipher_hmac_algorithm = HMAC_SHA512");
          rawDb.execute("PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA512");

          // 性能优化
          rawDb.execute("PRAGMA journal_mode = WAL");
          rawDb.execute("PRAGMA synchronous = NORMAL");
          rawDb.execute("PRAGMA temp_store = MEMORY");
          rawDb.execute("PRAGMA mmap_size = 30000000000");
          rawDb.execute("PRAGMA page_size = 4096");
          rawDb.execute("PRAGMA cache_size = -64000");  // 64MB cache
        },
      );
    });
  }

  static String _getDatabaseKey() {
    // 从安全存储获取密钥
    // 生产环境从flutter_secure_storage获取
    // 开发环境使用固定密钥
    return SecureKeyStorage.instance.getDatabaseKey();
  }
}
```

### 2.3 领域模型定义

```dart
// lib/features/accounting/domain/models/transaction.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

@freezed
class Transaction with _$Transaction {
  const Transaction._();

  const factory Transaction({
    required String id,
    required String bookId,
    required String deviceId,
    required int amount,  // 日元，整数
    required TransactionType type,
    required String categoryId,
    required LedgerType ledgerType,
    required DateTime timestamp,
    String? note,  // 加密存储
    String? photoHash,
    String? prevHash,
    required String currentHash,  // 哈希链
    required DateTime createdAt,
    @Default(false) bool isPrivate,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);

  // 业务逻辑方法
  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;
  bool get isTransfer => type == TransactionType.transfer;
  bool get isSoulExpense => ledgerType == LedgerType.soul && isExpense;

  // 计算哈希
  String calculateHash() {
    final data = '$id|$amount|${type.name}|$categoryId|'
                 '${timestamp.millisecondsSinceEpoch}|${prevHash ?? "genesis"}';
    return HashChainService.hash(data);
  }

  // 验证哈希
  bool verifyHash() {
    return currentHash == calculateHash();
  }
}

enum TransactionType {
  expense,   // 支出
  income,    // 收入
  transfer,  // 转账
}

enum LedgerType {
  survival,  // 生存账户
  soul,      // 灵魂账户
  income,    // 收入（不区分）
}

// lib/features/accounting/domain/models/category.dart
@freezed
class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    required String icon,  // Emoji
    required String color,  // Hex color
    required LedgerType ledgerType,  // survival | soul | auto | income
    required bool isSystem,
    required bool isArchived,
    required DateTime createdAt,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}

// lib/features/accounting/domain/models/book.dart
@freezed
class Book with _$Book {
  const factory Book({
    required String id,
    required String name,
    required BookType type,
    required DateTime createdAt,
  }) = _Book;

  factory Book.fromJson(Map<String, dynamic> json) =>
      _$BookFromJson(json);
}

enum BookType {
  personal,  // 个人账本
  family,    // 家庭账本
}

// lib/features/sync/domain/models/device.dart
@freezed
class Device with _$Device {
  const factory Device({
    required String id,
    required String bookId,
    required String publicKey,  // Ed25519公钥
    String? name,
    required DateTime createdAt,
  }) = _Device;

  factory Device.fromJson(Map<String, dynamic> json) =>
      _$DeviceFromJson(json);
}
```

---

## 第三部分：所有模块技术设计

由于文档长度限制，我将创建一个完整的模块技术总览，包含所有8个功能模块的核心技术设计。

### MOD-001/002: 基础记账与分类管理

#### 核心组件

```dart
// lib/application/accounting/create_transaction_use_case.dart
class CreateTransactionUseCase {
  final TransactionRepository _repository;
  final HashChainService _hashChain;
  final ClassificationService _classifier;
  final EncryptionService _encryption;

  Future<Result<Transaction>> execute(TransactionInput input) async {
    try {
      // 1. 验证输入
      _validateInput(input);

      // 2. 自动分类账户类型
      final ledgerType = await _classifier.classifyLedgerType(
        categoryId: input.categoryId,
        merchant: input.merchant,
        note: input.note,
      );

      // 3. 加密敏感字段
      final encryptedNote = input.note != null
          ? await _encryption.encrypt(input.note!)
          : null;

      // 4. 计算哈希链
      final prevHash = await _repository.getLastHash(input.bookId);
      final transaction = Transaction(
        id: Uuid().v4(),
        bookId: input.bookId,
        deviceId: await _getDeviceId(),
        amount: input.amount,
        type: input.type,
        categoryId: input.categoryId,
        ledgerType: ledgerType,
        timestamp: input.timestamp ?? DateTime.now(),
        note: encryptedNote,
        photoHash: input.photoHash,
        prevHash: prevHash,
        currentHash: '',  // 稍后计算
        createdAt: DateTime.now(),
        isPrivate: input.isPrivate,
      );

      final hash = transaction.calculateHash();
      final finalTransaction = transaction.copyWith(currentHash: hash);

      // 5. 保存到数据库
      await _repository.insert(finalTransaction);

      // 6. 返回结果
      return Result.success(finalTransaction);
    } on ValidationException catch (e) {
      return Result.failure(e);
    } catch (e, stackTrace) {
      _logger.error('Failed to create transaction', error: e, stackTrace: stackTrace);
      return Result.failure(InfrastructureException(e.toString()));
    }
  }

  void _validateInput(TransactionInput input) {
    if (input.amount <= 0) {
      throw ValidationException('金额必须大于0');
    }
    if (input.amount > 99999999) {
      throw ValidationException('金额超过上限（9999万日元）');
    }
    if (input.categoryId.isEmpty) {
      throw ValidationException('必须选择分类');
    }
  }
}

// lib/features/accounting/presentation/providers/transaction_list_provider.dart
@riverpod
class TransactionList extends _$TransactionList {
  @override
  Future<List<Transaction>> build({
    required String bookId,
    LedgerType? filterLedger,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final repository = ref.watch(transactionRepositoryProvider);
    return repository.getTransactions(
      bookId: bookId,
      ledgerType: filterLedger,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<void> addTransaction(TransactionInput input) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(createTransactionUseCaseProvider);
      final result = await useCase.execute(input);

      if (result.isFailure) {
        throw result.error!;
      }

      return build(
        bookId: input.bookId,
        filterLedger: filterLedger,
        startDate: startDate,
        endDate: endDate,
      );
    });
  }
}
```

#### 关键接口

```dart
// lib/features/accounting/domain/repositories/transaction_repository.dart
abstract class TransactionRepository {
  Future<void> insert(Transaction transaction);
  Future<void> update(Transaction transaction);
  Future<Transaction?> getById(String id);
  Future<List<Transaction>> getTransactions({
    required String bookId,
    LedgerType? ledgerType,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  });
  Future<String?> getLastHash(String bookId);
  Future<bool> verifyHashChain(String bookId);
  Future<int> getTotalAmount({
    required String bookId,
    required LedgerType ledgerType,
    required DateTime startDate,
    required DateTime endDate,
  });
}
```

### MOD-003: 双轨账本

#### 分类引擎架构

```dart
// lib/application/dual_ledger/classification_service.dart
class ClassificationService {
  final RuleEngine _ruleEngine;
  final MerchantDatabase _merchantDB;
  final TFLiteClassifier _tfliteClassifier;

  Future<LedgerType> classifyLedgerType({
    required String categoryId,
    String? merchant,
    String? note,
  }) async {
    // Layer 1: 规则引擎（优先级最高）
    final ruleResult = _ruleEngine.classify(categoryId);
    if (ruleResult != null) {
      return ruleResult;
    }

    // Layer 2: 商家数据库
    if (merchant != null) {
      final merchantResult = _merchantDB.lookup(merchant);
      if (merchantResult != null && merchantResult.confidence > 0.8) {
        return merchantResult.ledgerType;
      }
    }

    // Layer 3: TF Lite ML模型
    if (note != null) {
      return await _tfliteClassifier.predict(
        merchant: merchant ?? '',
        note: note,
        categoryId: categoryId,
      );
    }

    // 默认：保守策略，归类为生存账户
    return LedgerType.survival;
  }
}

// lib/application/dual_ledger/rule_engine.dart
class RuleEngine {
  static final _rules = <String, LedgerType>{
    'food_groceries': LedgerType.survival,
    'housing_rent': LedgerType.survival,
    'utilities': LedgerType.survival,
    'transport_commute': LedgerType.survival,
    'medical': LedgerType.survival,
    'insurance': LedgerType.survival,
    'communication': LedgerType.survival,
    'daily_goods': LedgerType.survival,

    'food_restaurant': LedgerType.soul,
    'entertainment': LedgerType.soul,
    'hobby': LedgerType.soul,
    'shopping_fashion': LedgerType.soul,
    'beauty': LedgerType.soul,
    'travel': LedgerType.soul,
    'education_hobby': LedgerType.soul,
  };

  LedgerType? classify(String categoryId) {
    return _rules[categoryId];
  }
}

// lib/infrastructure/ml/merchant_database.dart
class MerchantDatabase {
  static final _merchants = <String, MerchantInfo>{
    '吉野家': MerchantInfo(LedgerType.soul, 0.95),
    'マクドナルド': MerchantInfo(LedgerType.soul, 0.95),
    'セブンイレブン': MerchantInfo(LedgerType.survival, 0.9),
    'イオン': MerchantInfo(LedgerType.survival, 0.85),
    'JR東日本': MerchantInfo(LedgerType.survival, 0.95),
    'ヨドバシカメラ': MerchantInfo(LedgerType.soul, 0.7),
    // ... 500+ 商家
  };

  MerchantInfo? lookup(String merchant) {
    // 模糊匹配
    for (final entry in _merchants.entries) {
      if (merchant.contains(entry.key) || entry.key.contains(merchant)) {
        return entry.value;
      }
    }
    return null;
  }
}

class MerchantInfo {
  final LedgerType ledgerType;
  final double confidence;

  MerchantInfo(this.ledgerType, this.confidence);
}

// lib/infrastructure/ml/tflite_classifier.dart
class TFLiteClassifier {
  late Interpreter _interpreter;

  Future<void> initialize() async {
    _interpreter = await Interpreter.fromAsset('assets/models/classifier.tflite');
  }

  Future<LedgerType> predict({
    required String merchant,
    required String note,
    required String categoryId,
  }) async {
    // 特征提取
    final input = _buildInputTensor(merchant, note, categoryId);

    // 推理
    final output = List.filled(2, 0.0);
    _interpreter.run(input, output);

    // 解析结果
    final survivalProb = output[0];
    final soulProb = output[1];

    return soulProb > survivalProb ? LedgerType.soul : LedgerType.survival;
  }

  List<double> _buildInputTensor(String merchant, String note, String categoryId) {
    // 简化版特征提取
    // 实际实现需要词嵌入等复杂处理
    final features = <double>[];

    // 商家特征（100维）
    features.addAll(_merchantEmbedding(merchant));

    // 备注特征（50维）
    features.addAll(_noteEmbedding(note));

    // 分类特征（20维）
    features.addAll(_categoryEmbedding(categoryId));

    return features;
  }

  List<double> _merchantEmbedding(String merchant) {
    // 简化实现：实际需要预训练词向量
    return List.filled(100, 0.0);
  }

  List<double> _noteEmbedding(String note) {
    return List.filled(50, 0.0);
  }

  List<double> _categoryEmbedding(String categoryId) {
    return List.filled(20, 0.0);
  }
}
```

### MOD-004: 家庭同步

#### CRDT同步协议

```dart
// lib/infrastructure/sync/crdt_service.dart
class CRDTService {
  // 生成CRDT操作
  Future<List<CRDTOperation>> generateOperations(
    List<Transaction> transactions,
  ) async {
    return transactions.map((tx) => CRDTOperation(
      id: Uuid().v4(),
      type: CRDTOperationType.insert,
      entityType: 'transaction',
      entityId: tx.id,
      timestamp: tx.createdAt.millisecondsSinceEpoch,
      deviceId: tx.deviceId,
      data: tx.toJson(),
    )).toList();
  }

  // 应用CRDT操作
  Future<void> applyOperations(
    List<CRDTOperation> operations,
  ) async {
    // 按时间戳排序
    operations.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (final op in operations) {
      switch (op.type) {
        case CRDTOperationType.insert:
          await _handleInsert(op);
          break;
        case CRDTOperationType.update:
          await _handleUpdate(op);
          break;
        case CRDTOperationType.delete:
          await _handleDelete(op);
          break;
      }
    }
  }

  // Last-Write-Wins策略
  Future<void> _handleInsert(CRDTOperation op) async {
    final existing = await _repository.getById(op.entityId);

    if (existing == null) {
      // 不存在，直接插入
      await _repository.insert(Transaction.fromJson(op.data));
    } else {
      // 存在，比较时间戳
      final existingTimestamp = existing.createdAt.millisecondsSinceEpoch;
      if (op.timestamp > existingTimestamp) {
        // 远程更新更新，覆盖本地
        await _repository.update(Transaction.fromJson(op.data));
      }
      // 否则保留本地版本
    }
  }
}

// lib/application/sync/sync_service.dart
class SyncService {
  final TransactionRepository _repository;
  final CRDTService _crdt;
  final EncryptionService _encryption;
  final SyncTransport _transport;

  Future<SyncResult> syncNow() async {
    try {
      // 1. 获取本地未同步的交易
      final localChanges = await _repository.getUnsynced();

      // 2. 生成CRDT操作
      final operations = await _crdt.generateOperations(localChanges);

      // 3. 加密操作
      final encryptedPayload = await _encryption.encryptSyncPayload(operations);

      // 4. 通过传输层发送
      final response = await _transport.send(encryptedPayload);

      // 5. 解密响应
      final remoteOperations = await _encryption.decryptSyncPayload(response);

      // 6. 应用远程操作
      await _crdt.applyOperations(remoteOperations);

      // 7. 标记为已同步
      await _repository.markAsSynced(localChanges.map((tx) => tx.id).toList());

      return SyncResult.success(
        localCount: localChanges.length,
        remoteCount: remoteOperations.length,
      );
    } catch (e, stackTrace) {
      _logger.error('Sync failed', error: e, stackTrace: stackTrace);
      return SyncResult.failure(e.toString());
    }
  }
}

// lib/application/sync/pairing_service.dart
class PairingService {
  Future<PairingData> generateQRCode(String bookId) async {
    final deviceId = await _getDeviceId();
    final publicKey = await _keyManager.getPublicKey();

    final data = PairingData(
      bookId: bookId,
      deviceId: deviceId,
      publicKey: base64Encode(publicKey),
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    return data;
  }

  Future<Device> scanQRCode(String qrData) async {
    final data = PairingData.fromJson(jsonDecode(qrData));

    // 验证时间戳（5分钟内有效）
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - data.timestamp > 5 * 60 * 1000) {
      throw PairingException('QR码已过期');
    }

    // 保存对方设备信息
    final device = Device(
      id: data.deviceId,
      bookId: data.bookId,
      publicKey: data.publicKey,
      name: '伴侣的设备',
      createdAt: DateTime.now(),
    );

    await _deviceRepository.insert(device);

    return device;
  }
}
```

### MOD-005: OCR扫描

#### OCR服务实现

```dart
// lib/infrastructure/ml/ocr/ocr_service.dart
abstract class OCRService {
  Future<ReceiptData> scanReceipt(XFile image);
}

// lib/infrastructure/ml/ocr/mlkit_ocr_service.dart (Android)
class MLKitOCRService implements OCRService {
  @override
  Future<ReceiptData> scanReceipt(XFile image) async {
    // 1. 图像预处理
    final processedImage = await _preprocessImage(image);

    // 2. ML Kit识别
    final inputImage = InputImage.fromFile(File(processedImage.path));
    final textRecognizer = TextRecognizer(
      script: TextRecognitionScript.japanese,
    );
    final recognizedText = await textRecognizer.processImage(inputImage);

    // 3. 解析结果
    final parser = ReceiptParser();
    final data = parser.parse(recognizedText.text);

    // 4. 商家分类
    final classifier = ref.read(merchantClassifierProvider);
    final category = await classifier.classify(data.merchant);

    // 5. 返回结果
    return data.copyWith(suggestedCategory: category);
  }

  Future<XFile> _preprocessImage(XFile image) async {
    // 图像预处理：去噪、二值化、旋转校正
    final imageLib = img.decodeImage(await image.readAsBytes());
    if (imageLib == null) throw OCRException('无法解析图像');

    // 转灰度
    final grayscale = img.grayscale(imageLib);

    // 提高对比度
    final contrast = img.contrast(grayscale, 120);

    // 二值化
    final threshold = _otsuThreshold(contrast);
    final binary = img.threshold(contrast, threshold: threshold);

    // 保存处理后的图像
    final tempDir = await getTemporaryDirectory();
    final tempPath = '${tempDir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.png';
    File(tempPath).writeAsBytesSync(img.encodePng(binary));

    return XFile(tempPath);
  }

  int _otsuThreshold(img.Image image) {
    // Otsu自动阈值算法
    // 简化实现
    return 128;
  }
}

// lib/infrastructure/ml/ocr/vision_ocr_service.dart (iOS)
class VisionOCRService implements OCRService {
  @override
  Future<ReceiptData> scanReceipt(XFile image) async {
    // 通过platform channel调用iOS Vision Framework
    const platform = MethodChannel('com.homepocket.ocr');
    final result = await platform.invokeMethod('recognizeText', {
      'imagePath': image.path,
      'languages': ['ja', 'en'],
    });

    final text = result['text'] as String;

    // 解析和分类（与Android相同）
    final parser = ReceiptParser();
    final data = parser.parse(text);

    final classifier = ref.read(merchantClassifierProvider);
    final category = await classifier.classify(data.merchant);

    return data.copyWith(suggestedCategory: category);
  }
}

// lib/application/ocr/receipt_parser.dart
class ReceiptParser {
  ReceiptData parse(String text) {
    final lines = text.split('\n');

    // 提取金额
    final amount = _extractAmount(lines);

    // 提取日期
    final date = _extractDate(lines);

    // 提取商家
    final merchant = _extractMerchant(lines);

    return ReceiptData(
      amount: amount,
      date: date,
      merchant: merchant,
      rawText: text,
    );
  }

  int? _extractAmount(List<String> lines) {
    // 查找"合計"、"小計"、"TOTAL"等关键词
    final patterns = [
      RegExp(r'合計[：:]\s*¥?\s*([\d,]+)'),
      RegExp(r'小計[：:]\s*¥?\s*([\d,]+)'),
      RegExp(r'TOTAL[：:]\s*¥?\s*([\d,]+)', caseSensitive: false),
      RegExp(r'¥\s*([\d,]+)\s*円?$'),  // 最后一行的金额
    ];

    for (final line in lines.reversed) {  // 从后往前查找
      for (final pattern in patterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final amountStr = match.group(1)!.replaceAll(',', '');
          return int.tryParse(amountStr);
        }
      }
    }

    return null;
  }

  DateTime? _extractDate(List<String> lines) {
    // 日期格式：2026年2月3日, 2026/02/03, 26.02.03等
    final patterns = [
      RegExp(r'(\d{4})[年/.-](\d{1,2})[月/.-](\d{1,2})'),
      RegExp(r'(\d{2})[/.-](\d{1,2})[/.-](\d{1,2})'),
    ];

    for (final line in lines) {
      for (final pattern in patterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          try {
            int year = int.parse(match.group(1)!);
            if (year < 100) year += 2000;  // 26 -> 2026
            final month = int.parse(match.group(2)!);
            final day = int.parse(match.group(3)!);
            return DateTime(year, month, day);
          } catch (e) {
            continue;
          }
        }
      }
    }

    return null;
  }

  String? _extractMerchant(List<String> lines) {
    // 通常商家名在第一行或第二行
    if (lines.isEmpty) return null;

    // 清理和标准化
    final firstLine = lines[0].trim();
    if (firstLine.length > 2 && firstLine.length < 30) {
      return firstLine;
    }

    if (lines.length > 1) {
      final secondLine = lines[1].trim();
      if (secondLine.length > 2 && secondLine.length < 30) {
        return secondLine;
      }
    }

    return null;
  }
}

@freezed
class ReceiptData with _$ReceiptData {
  const factory ReceiptData({
    int? amount,
    DateTime? date,
    String? merchant,
    String? suggestedCategory,
    required String rawText,
  }) = _ReceiptData;
}
```

### MOD-006: 安全模块

#### 密钥管理

```dart
// lib/infrastructure/crypto/services/key_manager.dart
class KeyManager {
  final FlutterSecureStorage _secureStorage;

  // 生成设备密钥对（Ed25519）
  Future<KeyPair> generateDeviceKeyPair() async {
    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPair();

    // 保存私钥到安全存储
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    await _secureStorage.write(
      key: 'device_private_key',
      value: base64Encode(privateKeyBytes),
      iOptions: IOSOptions(accessibility: IOSAccessibility.first_unlock_this_device),
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );

    // 保存公钥（不敏感，可存储在数据库）
    final publicKey = await keyPair.extractPublicKey();
    final publicKeyBytes = publicKey.bytes;
    await _secureStorage.write(
      key: 'device_public_key',
      value: base64Encode(publicKeyBytes),
    );

    return keyPair;
  }

  // 生成Recovery Kit（24词助记词）
  Future<List<String>> generateRecoveryKit() async {
    // BIP39-like助记词生成
    final entropy = _generateEntropy(256);  // 256 bits
    final mnemonic = _entropyToMnemonic(entropy);

    // 从助记词派生密钥
    final seed = _mnemonicToSeed(mnemonic);
    final keyPair = await _seedToKeyPair(seed);

    // 保存密钥
    await _saveKeyPair(keyPair);

    return mnemonic;
  }

  Uint8List _generateEntropy(int bits) {
    final random = Random.secure();
    final bytes = Uint8List(bits ~/ 8);
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  List<String> _entropyToMnemonic(Uint8List entropy) {
    // 简化实现：实际需要BIP39词表
    final wordList = _getBIP39WordList();
    final mnemonic = <String>[];

    for (int i = 0; i < entropy.length; i += 2) {
      final index = (entropy[i] << 8) | entropy[i + 1];
      mnemonic.add(wordList[index % wordList.length]);
    }

    return mnemonic;
  }

  List<String> _getBIP39WordList() {
    // 日语BIP39词表（简化）
    return ['あい', 'あう', 'あかり', /* ... 2048个词 */];
  }

  // 从Recovery Kit恢复
  Future<KeyPair> recoverFromMnemonic(List<String> mnemonic) async {
    final seed = _mnemonicToSeed(mnemonic);
    final keyPair = await _seedToKeyPair(seed);
    await _saveKeyPair(keyPair);
    return keyPair;
  }

  Uint8List _mnemonicToSeed(List<String> mnemonic) {
    // PBKDF2派生种子
    final mnemonicStr = mnemonic.join(' ');
    final salt = utf8.encode('homepocket-seed');
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha512(),
      iterations: 2048,
      bits: 512,
    );
    return pbkdf2.deriveKeyFromPassword(
      password: mnemonicStr,
      nonce: salt,
    ).bytes as Uint8List;
  }

  Future<KeyPair> _seedToKeyPair(Uint8List seed) async {
    final algorithm = Ed25519();
    return await algorithm.newKeyPairFromSeed(seed.sublist(0, 32));
  }

  // 派生数据库加密密钥
  Future<String> deriveDatabaseKey() async {
    final privateKeyStr = await _secureStorage.read(key: 'device_private_key');
    if (privateKeyStr == null) {
      throw SecurityException('设备密钥不存在');
    }

    final privateKeyBytes = base64Decode(privateKeyStr);

    // HKDF派生
    final hkdf = Hkdf(hmac: Hmac(Sha256()), outputLength: 32);
    final derivedKey = await hkdf.deriveKey(
      secretKey: SecretKey(privateKeyBytes),
      info: utf8.encode('database_encryption_key'),
      nonce: Uint8List(32),  // 固定nonce，确保确定性
    );

    final derivedBytes = await derivedKey.extractBytes();
    return base64Encode(derivedBytes);
  }
}

// lib/infrastructure/crypto/services/hash_chain_service.dart
class HashChainService {
  static String hash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> verifyIntegrity(String bookId) async {
    final repository = ref.read(transactionRepositoryProvider);
    final transactions = await repository.getTransactions(
      bookId: bookId,
      // 按时间戳升序
    )..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    String prevHash = 'genesis';
    for (final tx in transactions) {
      if (!tx.verifyHash()) {
        _logTamperDetection(tx);
        return false;
      }

      if (tx.prevHash != prevHash) {
        _logTamperDetection(tx);
        return false;
      }

      prevHash = tx.currentHash;
    }

    return true;
  }

  Future<void> _logTamperDetection(Transaction tx) async {
    final logger = ref.read(auditLoggerProvider);
    await logger.log(
      level: LogLevel.critical,
      event: 'TAMPER_DETECTED',
      message: '检测到篡改尝试',
      metadata: {
        'transaction_id': tx.id,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}
```

### MOD-007: 数据分析

#### 报表生成

```dart
// lib/application/analytics/generate_monthly_report_use_case.dart
class GenerateMonthlyReportUseCase {
  final TransactionRepository _repository;

  Future<MonthlyReport> execute({
    required String bookId,
    required DateTime month,
  }) async {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    // 获取所有交易
    final transactions = await _repository.getTransactions(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
    );

    // 按账户类型分组
    final survivalTxs = transactions.where((tx) => tx.ledgerType == LedgerType.survival && tx.isExpense).toList();
    final soulTxs = transactions.where((tx) => tx.ledgerType == LedgerType.soul && tx.isExpense).toList();
    final incomeTxs = transactions.where((tx) => tx.isIncome).toList();

    // 计算总额
    final survivalTotal = survivalTxs.fold<int>(0, (sum, tx) => sum + tx.amount);
    final soulTotal = soulTxs.fold<int>(0, (sum, tx) => sum + tx.amount);
    final incomeTotal = incomeTxs.fold<int>(0, (sum, tx) => sum + tx.amount);

    // 按分类汇总
    final categoryBreakdown = _calculateCategoryBreakdown(transactions);

    // 日均消费
    final daysInMonth = endDate.day;
    final dailyAverage = (survivalTotal + soulTotal) ~/ daysInMonth;

    // 与上月对比
    final previousMonth = DateTime(month.year, month.month - 1);
    final comparison = await _compareWithPreviousMonth(
      bookId,
      previousMonth,
      survivalTotal,
      soulTotal,
    );

    return MonthlyReport(
      month: month,
      totalIncome: incomeTotal,
      totalExpense: survivalTotal + soulTotal,
      survivalExpense: survivalTotal,
      soulExpense: soulTotal,
      categoryBreakdown: categoryBreakdown,
      dailyAverage: dailyAverage,
      transactionCount: transactions.length,
      comparison: comparison,
    );
  }

  Map<String, CategoryExpense> _calculateCategoryBreakdown(
    List<Transaction> transactions,
  ) {
    final breakdown = <String, CategoryExpense>{};

    for (final tx in transactions) {
      if (!tx.isExpense) continue;

      if (breakdown.containsKey(tx.categoryId)) {
        breakdown[tx.categoryId] = breakdown[tx.categoryId]!.copyWith(
          amount: breakdown[tx.categoryId]!.amount + tx.amount,
          count: breakdown[tx.categoryId]!.count + 1,
        );
      } else {
        breakdown[tx.categoryId] = CategoryExpense(
          categoryId: tx.categoryId,
          amount: tx.amount,
          count: 1,
        );
      }
    }

    return breakdown;
  }
}

@freezed
class MonthlyReport with _$MonthlyReport {
  const factory MonthlyReport({
    required DateTime month,
    required int totalIncome,
    required int totalExpense,
    required int survivalExpense,
    required int soulExpense,
    required Map<String, CategoryExpense> categoryBreakdown,
    required int dailyAverage,
    required int transactionCount,
    MonthComparison? comparison,
  }) = _MonthlyReport;

  factory MonthlyReport.fromJson(Map<String, dynamic> json) =>
      _$MonthlyReportFromJson(json);
}
```

### MOD-008: 设置管理

#### 导出导入

```dart
// lib/application/settings/export_backup_use_case.dart
class ExportBackupUseCase {
  final TransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;
  final EncryptionService _encryption;

  Future<File> execute({
    required String bookId,
    required String password,
  }) async {
    // 1. 导出所有数据
    final transactions = await _transactionRepo.getTransactions(bookId: bookId);
    final categories = await _categoryRepo.getAll();

    final backup = BackupData(
      version: '1.0',
      exportedAt: DateTime.now(),
      bookId: bookId,
      transactions: transactions,
      categories: categories,
    );

    // 2. 序列化
    final json = jsonEncode(backup.toJson());

    // 3. 使用用户密码加密
    final encrypted = await _encryption.encryptWithPassword(
      plaintext: json,
      password: password,
    );

    // 4. 保存到文件
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/backup_$timestamp.homepocket');
    await file.writeAsBytes(encrypted);

    return file;
  }
}

// lib/application/settings/import_backup_use_case.dart
class ImportBackupUseCase {
  Future<void> execute({
    required File backupFile,
    required String password,
  }) async {
    // 1. 读取文件
    final encrypted = await backupFile.readAsBytes();

    // 2. 使用密码解密
    final json = await _encryption.decryptWithPassword(
      ciphertext: encrypted,
      password: password,
    );

    // 3. 反序列化
    final backup = BackupData.fromJson(jsonDecode(json));

    // 4. 验证版本兼容性
    if (backup.version != '1.0') {
      throw ImportException('不支持的备份版本：${backup.version}');
    }

    // 5. 导入数据
    await _importTransactions(backup.transactions);
    await _importCategories(backup.categories);

    // 6. 验证完整性
    await _verifyIntegrity(backup.bookId);
  }
}
```

### MOD-009: 语音记账

#### 大谷翔平换算器

```dart
// lib/features/gamification/domain/services/ohtani_converter_service.dart
class OhtaniConverterService {
  static final _conversionUnits = <ConversionUnit>[
    ConversionUnit(
      name: '大谷翔平のホームラン',
      icon: '⚾',
      valueInYen: 10000000,  // 1000万日元
      description: '大谷選手の年俸換算',
    ),
    ConversionUnit(
      name: 'ガンダムのプラモデル',
      icon: '🤖',
      valueInYen: 2500,
      description: 'MG 1/100 標準価格',
    ),
    ConversionUnit(
      name: 'ラーメン一杯',
      icon: '🍜',
      valueInYen: 900,
      description: '平均的なラーメン価格',
    ),
    ConversionUnit(
      name: 'コーヒー一杯',
      icon: '☕',
      valueInYen: 400,
      description: 'カフェのコーヒー',
    ),
    // ... 更多单位
  ];

  String convert(int amount) {
    // 找到最接近的单位
    final sortedUnits = _conversionUnits
      ..sort((a, b) => a.valueInYen.compareTo(b.valueInYen));

    ConversionUnit? bestMatch;
    double bestRatio = 0;

    for (final unit in sortedUnits) {
      final ratio = amount / unit.valueInYen;
      if (ratio >= 1 && ratio < 100) {
        bestMatch = unit;
        bestRatio = ratio;
      }
    }

    if (bestMatch == null) {
      return '${amount}円は大きすぎます！';
    }

    final formattedRatio = bestRatio.toStringAsFixed(1);
    return '${bestMatch.icon} ${bestMatch.name} × $formattedRatio';
  }
}

// 灵魂消费庆祝动画
class SoulCelebrationAnimation extends StatefulWidget {
  final Transaction transaction;
  final VoidCallback onComplete;

  @override
  _SoulCelebrationAnimationState createState() => _SoulCelebrationAnimationState();
}

class _SoulCelebrationAnimationState extends State<SoulCelebrationAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward().then((_) => widget.onComplete());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 粒子效果
        Positioned.fill(
          child: Lottie.asset(
            'assets/animations/particle_burst.json',
            controller: _controller,
          ),
        ),

        // 文案
        Center(
          child: FadeTransition(
            opacity: _controller,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '精神資産 +1 💖',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getRandomMessage(),
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getRandomMessage() {
    final messages = [
      '快楽値充能中 ⚡',
      '魂満足度 UP ✨',
      'これは自分への投資！🎉',
      '生活には小確幸が必要 🌟',
    ];
    return messages[Random().nextInt(messages.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

---

## 第四部分：架构决策记录(ADR)

### ADR-001: 选择Riverpod作为状态管理方案

**状态**: ✅ 已接受
**日期**: 2026-02-03
**决策者**: 技术架构团队

#### 背景

Flutter应用需要一个健壮的状态管理解决方案，以处理：
- 复杂的应用状态
- 异步数据获取
- 依赖注入
- 状态的可测试性

#### 备选方案

1. **Riverpod 2.x**
2. **Bloc/flutter_bloc**
3. **GetX**
4. **Provider**

#### 决策

选择**Riverpod 2.x**作为状态管理方案。

#### 理由

**优势:**
- ✅ 编译时类型安全
- ✅ 编译时依赖注入
- ✅ 优秀的DevTools支持
- ✅ 自动资源清理
- ✅ 测试友好（易于mock）
- ✅ 代码生成支持（riverpod_generator）
- ✅ 学习曲线适中
- ✅ 活跃的社区和文档

**对比Bloc:**
- Riverpod代码更简洁（无需大量Boilerplate）
- 状态管理更直观
- 依赖注入内置

**对比GetX:**
- Riverpod类型安全性更好
- 更符合Flutter最佳实践
- 更容易测试

**对比Provider:**
- Riverpod是Provider的进化版
- 更强大的功能
- 更好的性能

#### 实现示例

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

#### 后果

**正面影响:**
- 开发效率提升
- 代码可维护性好
- 测试覆盖率高

**负面影响:**
- 学习成本（团队需要时间适应）
- 代码生成增加构建时间

#### 相关决策

- ADR-005: Use Case模式与Provider集成

---

### ADR-002: 选择Drift+SQLCipher作为数据库方案

**状态**: ✅ 已接受
**日期**: 2026-02-03

#### 背景

需要一个支持以下特性的本地数据库：
- 加密存储
- 类型安全的查询
- 复杂的关系查询
- 数据库迁移支持
- 良好的性能

#### 备选方案

1. **Drift + SQLCipher**
2. **Hive + custom encryption**
3. **Isar + encryption**
4. **sqflite + SQLCipher**

#### 决策

选择**Drift + SQLCipher**组合。

#### 理由

**Drift优势:**
- ✅ 类型安全的SQL查询（编译时检查）
- ✅ 优秀的关系数据库支持
- ✅ 内置迁移系统
- ✅ 原生支持Stream和Future
- ✅ 良好的文档和社区支持

**SQLCipher优势:**
- ✅ 行业标准加密（AES-256）
- ✅ 透明加密（应用层无感知）
- ✅ 经过验证的安全性
- ✅ 支持FIPS 140-2标准

**对比Hive:**
- Drift支持复杂SQL查询
- 更好的关系数据支持
- 迁移更可靠

**对比Isar:**
- Drift生态更成熟
- SQL标准化（可移植性）
- 加密支持更好

#### 实现

```dart
@DriftDatabase(tables: [Transactions, Categories, Books])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  static QueryExecutor _openConnection() {
    return NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        rawDb.execute("PRAGMA key = '${_getKey()}'");
      },
    );
  }
}
```

#### 后果

**正面:**
- 数据安全有保障
- 开发体验好
- 性能优秀

**负面:**
- 包体积增加（SQLCipher库）
- 查询性能略低于NoSQL方案

---

### ADR-003: 多层加密策略

**状态**: ✅ 已接受
**日期**: 2026-02-03

#### 背景

需要设计一个安全的数据保护方案，平衡安全性和性能。

#### 决策

采用4层加密策略：

**Layer 1: 数据库级 (SQLCipher)**
- 算法: AES-256
- 保护: 整个数据库文件
- 性能影响: 轻微（透明加密）

**Layer 2: 字段级 (ChaCha20-Poly1305)**
- 算法: ChaCha20-Poly1305
- 保护: 交易备注等敏感字段
- 性能影响: 中等（加密/解密开销）

**Layer 3: 文件级 (AES-GCM)**
- 算法: AES-GCM
- 保护: 照片文件
- 性能影响: 中等

**Layer 4: 传输级 (TLS 1.3 + E2EE)**
- 算法: TLS 1.3 + 设备公钥加密
- 保护: 同步传输
- 性能影响: 高（但仅在同步时）

#### 理由

- Layer 1保护静态数据
- Layer 2保护最敏感信息
- Layer 3保护大文件
- Layer 4保护传输中的数据

完整的深度防御策略。

---

### ADR-004: 选择Yjs-inspired CRDT方案

**状态**: ✅ 已接受
**日期**: 2026-02-03

#### 背景

家庭同步需要处理：
- 离线修改
- 并发修改
- 自动冲突解决
- 最终一致性

#### 备选方案

1. **Yjs-inspired CRDT**
2. **Automerge**
3. **Custom operational transformation**
4. **Last-write-wins with vector clocks**

#### 决策

采用**Yjs-inspired CRDT**实现。

#### 理由

**优势:**
- ✅ 自动冲突解决
- ✅ 最终一致性保证
- ✅ 性能优秀
- ✅ 已在生产环境验证

**对比Automerge:**
- Yjs性能更好（针对实时协作优化）
- 二进制格式更紧凑
- Dart移植更简单

**对比自研:**
- 降低开发风险
- 成熟度高
- 经过充分测试

#### 实现要点

```dart
class CRDTService {
  Future<void> applyOperations(List<CRDTOperation> ops) async {
    ops.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (final op in ops) {
      // Last-Write-Wins + Lamport timestamps
      await _applyWithLWW(op);
    }
  }
}
```

---

### ADR-005: OCR和ML技术选型

**状态**: ✅ 已接受
**日期**: 2026-02-03

#### 背景

OCR和ML功能需要：
- 离线工作
- 隐私保护（不发送到云端）
- 足够的准确率
- 跨平台支持

#### 决策

**OCR方案:**
- Android: ML Kit Text Recognition v2
- iOS: Vision Framework

**ML分类方案:**
- TensorFlow Lite (跨平台)

**不采用Gemini Nano:**
- 移至V1.0 Premium功能
- 设备限制太多（仅高端Android）
- iOS无等价方案

#### 理由

**ML Kit / Vision Framework:**
- ✅ 本地处理，隐私保护
- ✅ 无API成本
- ✅ 日语支持好
- ✅ 准确率足够（>85%）

**TF Lite:**
- ✅ 跨平台一致
- ✅ 模型小（<5MB）
- ✅ 推理快（<100ms）
- ✅ 离线可用

#### 实现

```dart
// Platform-specific OCR
abstract class OCRService {
  Future<ReceiptData> scanReceipt(XFile image);
}

class MLKitOCRService implements OCRService { /* Android */ }
class VisionOCRService implements OCRService { /* iOS */ }

// Cross-platform ML
class TFLiteClassifier {
  Future<LedgerType> predict({
    required String merchant,
    required String note,
  }) async {
    final input = _buildInputTensor(merchant, note);
    final output = await _interpreter.run(input);
    return _parseOutput(output);
  }
}
```

---

## 第五部分：开发指南

### 5.1 开发环境搭建

```bash
# 1. 安装Flutter
flutter upgrade
flutter doctor

# 2. 克隆项目
git clone <repository>
cd home-pocket-app

# 3. 安装依赖
flutter pub get

# 4. 代码生成
flutter pub run build_runner build --delete-conflicting-outputs

# 5. 运行应用
flutter run

# 6. 运行测试
flutter test
flutter test integration_test
```

### 5.2 代码规范

遵循：
- Dart官方风格指南
- Effective Dart最佳实践
- 项目analysis_options.yaml配置

关键规则：
- 使用`const`构造函数
- 优先使用`final`
- 避免`dynamic`类型
- 所有公开API添加文档注释
- 使用命名参数（required标记必需参数）

### 5.3 Git工作流

```
main (受保护)
  ├─ develop (开发主分支)
  │   ├─ feature/MOD-001-basic-accounting
  │   ├─ feature/MOD-003-dual-ledger
  │   └─ bugfix/fix-hash-chain
  └─ release/v1.0.0
```

提交信息格式：
```
<type>(<scope>): <subject>

type: feat, fix, docs, style, refactor, perf, test, chore
scope: mod-001, mod-003, security, etc.
```

### 5.4 测试策略

**单元测试（60%覆盖率目标）:**
- 所有Use Cases
- 所有Services
- 所有Repository实现
- 关键工具函数

**Widget测试（30%）:**
- 关键交互组件
- 表单验证
- 导航流程

**集成测试（10%）:**
- 端到端用户流程
- 关键业务场景

### 5.5 性能优化清单

- [ ] 列表使用ListView.builder
- [ ] 图片使用CachedNetworkImage
- [ ] 大计算使用Isolate
- [ ] 数据库查询添加索引
- [ ] 使用const构造函数
- [ ] 避免不必要的rebuild
- [ ] 实现数据分页加载
- [ ] 优化asset bundle大小

---

## 总结

本文档提供了Home Pocket MVP应用的完整架构技术设计，涵盖：

✅ **总体架构** - 技术栈、层次设计、项目结构
✅ **数据架构** - 完整数据模型、数据库设计、加密策略
✅ **所有模块** - 8个功能模块的详细技术实现
✅ **架构决策** - 5个关键ADR记录
✅ **开发指南** - 环境搭建、规范、测试策略

**文档状态**: 🟢 完整版，可直接用于开发

**下一步**:
1. Review架构文档
2. 搭建开发环境
3. 创建项目骨架
4. 开始Phase 1开发（MOD-006 + MOD-001/002）

---

**文档信息**:
- **版本**: 2.0
- **创建日期**: 2026-02-03
- **最后更新**: 2026-02-06
- **作者**: Claude Sonnet 4.5 + senior-architect skill
- **PRD基础**: 12个PRD文档完整分析
- **v2.0变更**: 基于 ARCH-008 层次澄清标准，重构为全局 Application 层 + 瘦 Feature 模式
