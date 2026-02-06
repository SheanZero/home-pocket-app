# Clean Architecture 层次职责澄清总结

**更新日期:** 2026-02-06
**问题:** Infrastructure层与Data层职责模糊 + Application层职责未定义 + Feature层次边界不清
**解决方案:** ADR-006 - Clean Architecture 层次职责划分标准（v2.0 扩展）

---

## 📋 问题描述

### 原始问题

在架构设计文档中存在以下职责模糊的情况：

1. **Infrastructure 层包含:**
   - `crypto/` - 加密服务
   - `ml/` - 机器学习
   - `sync/` - 同步协议

2. **Data 层也包含:**
   - `datasources/local/` - 本地数据源
   - `encrypted_file_storage.dart` - 加密文件存储

3. **困惑点:**
   - 密钥管理应该放在哪里？
   - 加密服务应该放在哪里？
   - 数据库配置应该放在哪里？
   - OCR服务应该放在哪里？

### 影响

- ❌ 开发者不清楚新组件应该放在哪一层
- ❌ 代码审查时缺乏明确标准
- ❌ 容易导致职责混乱和重复代码
- ❌ 降低代码可维护性

---

## ✅ 解决方案

### 核心原则：按职责划分，而非按技术划分

我们制定了明确的层次职责划分标准（ADR-006）：

```
Infrastructure Layer (基础设施层)
  职责: 提供技术能力
  特征: 与业务无关、可复用、可独立测试
  示例: 加密算法、OCR封装、CRDT算法、平台API

Data Layer (数据层)
  职责: 实现数据访问
  特征: Repository实现、DAO/DTO、使用Infrastructure的服务
  示例: TransactionRepositoryImpl、TransactionDao、Database配置
```

---

## 🎯 明确的职责划分

### Infrastructure Layer（基础设施层）

**核心职责:** 提供技术能力（与业务无关）

**包含内容:**
```
lib/infrastructure/                # 全局技术能力（NEVER in features/）
├── crypto/                        # ✅ 加密技术能力
│   ├── services/
│   │   ├── key_manager.dart           # 密钥生成和管理（Ed25519）
│   │   ├── field_encryption_service.dart # 字段加密（ChaCha20-Poly1305）
│   │   ├── hash_chain_service.dart    # 哈希计算（SHA-256）
│   │   ├── photo_encryption_service.dart # 照片加密（AES-GCM）← 从 MOD-004 聚合
│   │   └── recovery_kit_service.dart  # 助记词生成（BIP39）
│   ├── models/
│   │   ├── device_key_pair.dart       # ← 唯一定义（去重）
│   │   └── chain_verification_result.dart # ← 唯一定义（去重）
│   ├── repositories/
│   └── database/
│       └── encrypted_database.dart    # SQLCipher 数据库加密设置
│
├── ml/                            # ✅ ML/OCR 技术能力
│   ├── ocr/
│   │   ├── ocr_service.dart           # 抽象接口
│   │   ├── mlkit_ocr_service.dart     # Android 实现（ML Kit）
│   │   └── vision_ocr_service.dart    # iOS 实现（Vision Framework）
│   ├── image_preprocessor.dart        # 图像预处理 ← 从 MOD-004 聚合
│   ├── tflite_classifier.dart         # TF Lite 推理引擎 ← 唯一定义
│   └── merchant_database.dart         # 商家数据库 ← 唯一定义（去重）
│
├── sync/                          # ✅ 同步技术能力
│   ├── crdt_service.dart              # CRDT 算法实现（Yjs-inspired）
│   ├── bluetooth_transport.dart       # 蓝牙传输封装
│   ├── nfc_transport.dart             # NFC 传输封装
│   └── wifi_transport.dart            # WiFi 传输封装
│
├── security/                      # ✅ 安全技术能力
│   ├── biometric_service.dart         # 生物识别平台封装
│   ├── secure_storage_service.dart    # 安全存储封装
│   └── audit_logger.dart              # 审计日志工具
│
├── i18n/                          # ✅ 国際化基盤
│   ├── formatters/
│   │   ├── date_formatter.dart          # 日期格式化（Locale-aware）
│   │   └── number_formatter.dart        # 数字/通貨格式化（Locale-aware）
│   ├── models/
│   │   └── locale_settings.dart         # ロケール設定モデル（Freezed）
│   └── supported_locales.dart           # サポートロケール定義
│
└── platform/                      # ✅ 平台特定封装
    ├── ios/
    └── android/
```

⚠️ **重要约束（v2.0）：**
- Infrastructure 是全局层，NEVER 在 `lib/features/` 内创建 `infrastructure/` 子目录
- 每个技术能力只有唯一定义位置（去重原则）
- i18n 基盤（date_formatter, number_formatter, locale_settings）移至 `lib/infrastructure/i18n/`

**判断标准:**
- ✅ 这个服务在其他项目中也能用吗？
- ✅ 它与业务逻辑无关吗？
- ✅ 它是纯技术实现吗？

**示例:**
```dart
// ✅ Infrastructure: 提供加密算法
class EncryptionService {
  Future<String> encrypt(String plaintext) async {
    // ChaCha20-Poly1305 加密实现
    // 与业务无关，可在任何项目中使用
  }
}
```

---

### Data Layer（数据层）

**核心职责:** 实现数据访问逻辑

**包含内容:**
```
lib/data/                          # 全局数据访问层（跨 Feature 共享）
├── app_database.dart              # ✅ 主 Drift 数据库定义
├── tables/                        # ✅ ALL Drift 表定义（集中管理）
│   ├── transactions_table.dart
│   ├── categories_table.dart
│   ├── books_table.dart
│   ├── devices_table.dart
│   ├── recovery_kits_table.dart
│   ├── audit_logs_table.dart
│   ├── receipt_photos_table.dart
│   └── sync_logs_table.dart
│
├── daos/                          # ✅ Data Access Objects
│   ├── transaction_dao.dart
│   ├── category_dao.dart
│   ├── book_dao.dart
│   ├── device_dao.dart
│   └── receipt_photo_dao.dart
│
├── repositories/                  # ✅ Repository 实现
│   ├── transaction_repository_impl.dart
│   ├── category_repository_impl.dart
│   ├── book_repository_impl.dart
│   ├── receipt_photo_repository_impl.dart
│   └── sync_repository_impl.dart
│
└── models/                        # ✅ DTOs (Data Transfer Objects)
```

⚠️ **重要变更（v2.0）：**
- 移除了 `datasources/local/` 嵌套结构，改为扁平化的 `tables/` + `daos/`
- ALL Drift 表定义集中在 `lib/data/tables/`，NEVER 在 Feature 内定义
- ALL DAO 集中在 `lib/data/daos/`

**判断标准:**
- ✅ 这个类主要负责数据的存取吗？
- ✅ 它实现了Repository接口吗？
- ✅ 它使用Infrastructure的技术服务吗？

**示例:**
```dart
// ✅ Data: 实现数据访问，使用Infrastructure的服务
class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionDao _dao;
  final EncryptionService _encryptionService;  // 使用Infrastructure

  @override
  Future<void> insert(Transaction transaction) async {
    // 使用Infrastructure提供的加密能力
    final encryptedNote = await _encryptionService.encrypt(
      transaction.note,
    );

    final dto = transaction.toDto(encryptedNote: encryptedNote);
    await _dao.insertTransaction(dto);
  }
}
```

---

### Application Layer（业务逻辑层）— v2.0 新增

**核心职责:** 实现业务规则和 Use Cases（全局层，独立于 features）

**包含内容:**
```
lib/application/                   # 全局业务逻辑层（独立于 features）
├── accounting/                    # 记账业务逻辑
│   ├── create_transaction_use_case.dart
│   ├── update_transaction_use_case.dart
│   ├── delete_transaction_use_case.dart
│   ├── get_transactions_use_case.dart
│   └── manage_category_use_case.dart
├── dual_ledger/                   # 双轨账本业务逻辑
│   ├── classification_service.dart    # 三层分类引擎编排
│   └── rule_engine.dart               # 规则引擎（业务规则）
├── ocr/                           # OCR 业务逻辑
│   ├── scan_receipt_use_case.dart
│   ├── receipt_parser.dart            # 小票解析（业务逻辑）
│   └── save_receipt_photo_use_case.dart
├── security/                      # 安全业务逻辑
│   ├── verify_hash_chain_use_case.dart
│   └── generate_recovery_kit_use_case.dart
├── analytics/                     # 分析业务逻辑
│   ├── generate_monthly_report_use_case.dart
│   └── calculate_budget_use_case.dart
└── settings/                      # 设置业务逻辑
    ├── export_backup_use_case.dart
    └── import_backup_use_case.dart
```

**判断标准:**
- ✅ 这个类实现了业务规则或编排多个服务吗？
- ✅ 它是 Use Case（用户场景的入口点）吗？
- ✅ 它需要协调 Domain models + Data repos + Infrastructure services 吗？

**示例:**
```dart
// ✅ Application: 编排业务逻辑，使用 Domain + Data + Infrastructure
// lib/application/accounting/create_transaction_use_case.dart
class CreateTransactionUseCase {
  final TransactionRepository _repository;       // Domain interface
  final FieldEncryptionService _encryption;       // Infrastructure
  final HashChainService _hashChain;              // Infrastructure
  final ClassificationService _classifier;        // Application

  Future<Result<Transaction>> execute(TransactionInput input) async {
    // 1. 自动分类 → 业务规则
    final ledgerType = await _classifier.classifyLedgerType(...);
    // 2. 加密 → 使用 Infrastructure
    final encryptedNote = await _encryption.encryptField(input.note);
    // 3. 哈希链 → 使用 Infrastructure
    final hash = await _hashChain.calculateTransactionHash(...);
    // 4. 持久化 → 使用 Data（通过 Domain interface）
    await _repository.insert(transaction);
    return Result.success(transaction);
  }
}
```

⚠️ **关键约束:**
- Application 层是**全局层**，按业务领域组织（accounting/、dual_ledger/、ocr/ 等）
- NEVER 放在 `lib/features/{feature}/application/` 内部
- 每个 Use Case 文件对应一个用户操作场景

---

### Domain Layer（领域层）— v2.0 更新

**核心职责:** 定义业务实体和 Repository 接口（Feature 内部）

**包含内容:**
```
lib/features/{feature}/domain/     # 每个 Feature 独立
├── models/                        # ONLY: 领域模型（Freezed）
│   ├── transaction.dart
│   ├── category.dart
│   └── book.dart
└── repositories/                  # ONLY: Repository 接口（抽象）
    ├── transaction_repository.dart
    └── category_repository.dart
```

⚠️ **v2.0 约束（CRITICAL）:**
- Domain 层 **ONLY** 包含 `models/` 和 `repositories/`
- ❌ 不含 `use_cases/`（移至 `lib/application/`）
- ❌ 不含 `services/`（移至 `lib/application/` 或 `lib/infrastructure/`）
- ❌ 不含 `value_objects/`（合并到 `models/`）

---

### Feature 层次约束（v2.0 新增 — CRITICAL）

**瘦 Feature 模式:**

```
lib/features/{feature}/
├── domain/              # ONLY: models + repository interfaces
│   ├── models/
│   └── repositories/
└── presentation/        # UI 层
    ├── screens/
    ├── widgets/
    └── providers/
```

**Feature 内部禁止包含以下目录:**

| 禁止目录 | 原因 | 正确位置 |
|----------|------|----------|
| `application/` | Use Cases 是全局业务逻辑 | `lib/application/{domain}/` |
| `infrastructure/` | 技术能力是全局共享的 | `lib/infrastructure/` |
| `data/tables/` | Drift 表定义是跨 Feature 的 | `lib/data/tables/` |
| `data/daos/` | DAO 是跨 Feature 的 | `lib/data/daos/` |
| `data/datasources/` | 数据源是全局的 | `lib/data/` |

**验证规则:**
```bash
# 搜索违规的 Feature 内 infrastructure 目录
find lib/features -type d -name "infrastructure" | wc -l  # 应该为 0

# 搜索违规的 Feature 内 application 目录
find lib/features -type d -name "application" | wc -l    # 应该为 0
```

---

### 聚合核心能力清单（v2.0 新增）

以下是全部 Infrastructure 层技术能力的唯一定义位置，禁止在其他位置重复定义：

| 能力 | 唯一定义位置 | 来源 |
|------|------------|------|
| KeyManager | `lib/infrastructure/crypto/services/key_manager.dart` | MOD-005 |
| FieldEncryptionService | `lib/infrastructure/crypto/services/field_encryption_service.dart` | MOD-005 |
| HashChainService | `lib/infrastructure/crypto/services/hash_chain_service.dart` | MOD-005 |
| PhotoEncryptionService | `lib/infrastructure/crypto/services/photo_encryption_service.dart` | MOD-004 |
| RecoveryKitService | `lib/infrastructure/crypto/services/recovery_kit_service.dart` | MOD-005 |
| DeviceKeyPair | `lib/infrastructure/crypto/models/device_key_pair.dart` | MOD-005（去重） |
| ChainVerificationResult | `lib/infrastructure/crypto/models/chain_verification_result.dart` | MOD-005（去重） |
| MLKitOCRService | `lib/infrastructure/ml/ocr/mlkit_ocr_service.dart` | MOD-004 |
| VisionOCRService | `lib/infrastructure/ml/ocr/vision_ocr_service.dart` | MOD-004 |
| ImagePreprocessor | `lib/infrastructure/ml/image_preprocessor.dart` | MOD-004 |
| TFLiteClassifier | `lib/infrastructure/ml/tflite_classifier.dart` | MOD-002+004（去重） |
| MerchantDatabase | `lib/infrastructure/ml/merchant_database.dart` | MOD-002+004（去重） |
| CRDTService | `lib/infrastructure/sync/crdt_service.dart` | MOD-003 |
| BiometricService | `lib/infrastructure/security/biometric_service.dart` | MOD-005 |
| SecureStorageService | `lib/infrastructure/security/secure_storage_service.dart` | MOD-005 |
| AuditLogger | `lib/infrastructure/security/audit_logger.dart` | MOD-005 |
| DateFormatter | `lib/infrastructure/i18n/formatters/date_formatter.dart` | MOD-014 |
| NumberFormatter | `lib/infrastructure/i18n/formatters/number_formatter.dart` | MOD-014 |
| LocaleSettings | `lib/infrastructure/i18n/models/locale_settings.dart` | MOD-014 |
| SupportedLocales | `lib/infrastructure/i18n/supported_locales.dart` | MOD-014 |

---

## 📊 具体示例对照

### 示例 1: 加密功能

#### ❌ 错误做法（职责混乱）

```dart
// ❌ 在Data层实现加密算法
class TransactionDao {
  String _encrypt(String data) {
    // ChaCha20实现...  // 错误！这是技术能力，应该在Infrastructure
  }
}
```

#### ✅ 正确做法（职责清晰）

```dart
// ✅ Infrastructure: 提供加密能力
class EncryptionService {
  Future<String> encrypt(String plaintext) async {
    // ChaCha20-Poly1305实现
  }
}

// ✅ Data: 使用加密服务实现数据访问
class TransactionRepositoryImpl {
  final EncryptionService _encryptionService;

  Future<void> insert(Transaction tx) async {
    final encrypted = await _encryptionService.encrypt(tx.note);
    // 保存到数据库
  }
}
```

---

### 示例 2: OCR功能

#### ❌ 错误做法（职责混乱）

```dart
// ❌ 在Infrastructure中包含业务逻辑
class OCRService {
  Future<ReceiptData> scanReceipt(File image) async {
    final text = await recognizeText(image);

    // ❌ 业务逻辑不应在Infrastructure
    final amount = _parseAmount(text);
    final merchant = _parseMerchant(text);
    final category = _classifyMerchant(merchant);

    return ReceiptData(...);
  }
}
```

#### ✅ 正确做法（职责清晰）

```dart
// ✅ Infrastructure: 只提供文本识别能力
class OCRService {
  Future<String> recognizeText(File image) async {
    // 调用ML Kit/Vision Framework
    // 返回原始文本，不包含业务逻辑
  }
}

// ✅ Business Logic: 小票解析和分类
class ScanReceiptUseCase {
  final OCRService _ocrService;
  final ReceiptParser _parser;

  Future<ReceiptData> execute(File image) async {
    final text = await _ocrService.recognizeText(image);
    return _parser.parse(text);  // 业务逻辑在这里
  }
}
```

---

### 示例 3: 数据库配置

#### ✅ 正确做法

```dart
// ✅ Infrastructure: 密钥管理
class KeyManager {
  Future<String> deriveDatabaseKey() async {
    // HKDF密钥派生算法
  }
}

// ✅ Data: 数据库配置（使用Infrastructure的服务）
class AppDatabase extends _$AppDatabase {
  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final file = await _getDatabaseFile();

      return NativeDatabase.createInBackground(
        file,
        setup: (rawDb) {
          // 使用Infrastructure提供的密钥
          final key = await KeyManager().deriveDatabaseKey();
          rawDb.execute("PRAGMA key = '$key'");
        },
      );
    });
  }
}
```

**职责分配:**
- 🔧 Infrastructure: 密钥派生算法（HKDF）
- 💾 Data: 数据库配置和初始化（使用密钥服务）

---

## 🔍 决策树

### 判断代码应该放在哪一层

```
开始
 │
 ├─ 这是 UI 相关的吗？（screens, widgets, providers）
 │   └─ 是 → Presentation Layer (lib/features/{feature}/presentation/)
 │
 ├─ 这是业务规则或 Use Case 吗？
 │   ├─ Use Case（编排多个服务）？ → Application Layer (lib/application/{domain}/)
 │   ├─ 业务服务（分类引擎、规则引擎）？ → Application Layer
 │   └─ 业务解析逻辑（小票解析）？ → Application Layer
 │
 ├─ 这是核心业务概念吗？（与技术无关）
 │   ├─ 领域模型（entity）？ → Domain Layer (lib/features/{feature}/domain/models/)
 │   └─ Repository 接口（抽象）？ → Domain Layer (lib/features/{feature}/domain/repositories/)
 │
 ├─ 这是数据访问逻辑吗？
 │   ├─ Repository 实现？ → Data Layer (lib/data/repositories/)
 │   ├─ DAO？ → Data Layer (lib/data/daos/)
 │   ├─ Drift 表定义？ → Data Layer (lib/data/tables/)
 │   ├─ 数据库配置？ → Data Layer (lib/data/app_database.dart)
 │   └─ DTO？ → Data Layer (lib/data/models/)
 │
 └─ 这是技术能力吗？
     ├─ 加密/密钥算法？ → Infrastructure (lib/infrastructure/crypto/)
     ├─ ML/OCR 引擎？ → Infrastructure (lib/infrastructure/ml/)
     ├─ 同步协议/传输？ → Infrastructure (lib/infrastructure/sync/)
     ├─ 安全服务（生物识别等）？ → Infrastructure (lib/infrastructure/security/)
     ├─ i18n 基盤（格式化、ロケール）？ → Infrastructure (lib/infrastructure/i18n/)
     └─ 平台 API 封装？ → Infrastructure (lib/infrastructure/platform/)
```

---

## 📋 快速参考表

| 组件类型 | 放置层次 | 位置 | 示例 |
|---------|---------|------|------|
| UI 页面 | Presentation | `lib/features/{f}/presentation/screens/` | `TransactionListScreen` |
| UI Provider | Presentation | `lib/features/{f}/presentation/providers/` | `TransactionListProvider` |
| Use Case | Application | `lib/application/{domain}/` | `CreateTransactionUseCase` |
| 业务服务 | Application | `lib/application/{domain}/` | `ClassificationService` |
| 领域模型 | Domain | `lib/features/{f}/domain/models/` | `Transaction` |
| Repository 接口 | Domain | `lib/features/{f}/domain/repositories/` | `TransactionRepository` |
| Repository 实现 | Data | `lib/data/repositories/` | `TransactionRepositoryImpl` |
| DAO | Data | `lib/data/daos/` | `TransactionDao` |
| Drift 表定义 | Data | `lib/data/tables/` | `TransactionsTable` |
| Database 配置 | Data | `lib/data/app_database.dart` | `AppDatabase` |
| DTO | Data | `lib/data/models/` | `TransactionDto` |
| 加密服务 | Infrastructure | `lib/infrastructure/crypto/services/` | `FieldEncryptionService` |
| 哈希服务 | Infrastructure | `lib/infrastructure/crypto/services/` | `HashChainService` |
| 密钥管理 | Infrastructure | `lib/infrastructure/crypto/services/` | `KeyManager` |
| OCR 服务 | Infrastructure | `lib/infrastructure/ml/ocr/` | `MLKitOCRService` |
| TF Lite 推理 | Infrastructure | `lib/infrastructure/ml/` | `TFLiteClassifier` |
| 商家数据库 | Infrastructure | `lib/infrastructure/ml/` | `MerchantDatabase` |
| CRDT 算法 | Infrastructure | `lib/infrastructure/sync/` | `CRDTService` |
| 蓝牙传输 | Infrastructure | `lib/infrastructure/sync/` | `BluetoothTransport` |
| 生物识别 | Infrastructure | `lib/infrastructure/security/` | `BiometricService` |
| 日期格式化 | Infrastructure | `lib/infrastructure/i18n/formatters/` | `DateFormatter` |
| 数字格式化 | Infrastructure | `lib/infrastructure/i18n/formatters/` | `NumberFormatter` |
| ロケール設定 | Infrastructure | `lib/infrastructure/i18n/models/` | `LocaleSettings` |

---

## ✅ 验证清单

### Data Layer 检查项

审查Data层代码时，检查以下项：

- [ ] 实现了Repository接口
- [ ] 不包含业务逻辑
- [ ] 不包含算法实现（应使用Infrastructure的）
- [ ] DTO ↔ Domain Model转换正确
- [ ] 依赖Infrastructure服务（通过接口或构造注入）
- [ ] 数据库配置使用Infrastructure的密钥服务
- [ ] 文件操作使用Infrastructure的加密服务

### Infrastructure Layer 检查项

审查Infrastructure层代码时，检查以下项：

- [ ] 与业务逻辑完全无关
- [ ] 可以在其他项目中复用
- [ ] 可以独立测试
- [ ] 封装了第三方库或平台API
- [ ] 提供了清晰的接口
- [ ] 不包含Repository实现
- [ ] 不包含DAO/DTO
- [ ] 不包含数据库访问代码

---

## 📚 相关文档

1. **ADR-006: Clean Architecture 层次职责划分**
   - 文件: `ADR-006_Layer_Responsibilities.md`
   - 详细的职责定义、示例、常见误区

2. **主架构文档**
   - 文件: `01_MVP_Complete_Architecture_Guide.md`
   - 包含完整的架构设计

3. **主索引**
   - 文件: `00_MASTER_INDEX.md`
   - 已更新ADR-006引用

---

## 🎯 后续行动

### 立即行动

1. **审查现有代码**
   - [ ] 检查`lib/data/`下是否有算法实现
   - [ ] 检查`lib/infrastructure/`下是否有Repository实现
   - [ ] 检查`lib/infrastructure/`下是否有业务逻辑

2. **调整不符合规范的代码**
   - [ ] 将Data层的算法实现移到Infrastructure
   - [ ] 确保Repository实现在Data层
   - [ ] 确保DAO/DTO在Data层

3. **更新开发指南**
   - [ ] 在代码审查清单中加入本规范
   - [ ] 更新团队培训材料
   - [ ] 创建示例代码

### 长期维护

1. **代码审查**
   - 使用ADR-006作为审查标准
   - 确保新代码遵循职责划分

2. **文档维护**
   - 保持ADR-006与代码同步
   - 添加更多实际案例

3. **团队培训**
   - 定期回顾Clean Architecture原则
   - 分享最佳实践案例

---

## 📊 影响分析

### 正面影响

- ✅ **职责清晰** - 开发者明确知道代码应该放在哪里
- ✅ **可维护性提升** - 代码组织更合理
- ✅ **可复用性提高** - Infrastructure层可跨项目复用
- ✅ **可测试性增强** - 每层都可独立测试
- ✅ **审查标准明确** - 代码审查有清晰依据

### 潜在挑战

- ⚠️ **学习成本** - 团队需要理解新的职责划分标准
- ⚠️ **重构工作** - 需要调整部分现有代码
- ⚠️ **边界判断** - 某些边缘情况可能需要讨论

### 解决方案

- 📖 提供详细的ADR文档和示例
- 👥 进行团队培训和代码审查
- 💬 建立技术决策讨论机制

---

## 🏆 总结

### 核心原则

**Infrastructure = 技术能力提供者**
- 算法、封装、工具
- 与业务无关
- 可复用

**Data = 数据访问实现者**
- Repository实现
- DAO/DTO
- 使用Infrastructure的技术能力

### 记忆口诀

```
Infrastructure 提供"能力"（How to do）     → lib/infrastructure/
Data 实现"访问"（Where to store）          → lib/data/
Application 定义"规则"（What to do）       → lib/application/
Domain 定义"概念"（What it is）            → lib/features/{f}/domain/
Presentation 渲染"界面"（What to show）    → lib/features/{f}/presentation/
```

### 快速判断

问自己三个问题：
1. **这个代码与业务有关吗？** → 有 = Business Logic, 无 = Infrastructure/Data
2. **这个代码主要做什么？** → 算法/封装 = Infrastructure, 数据访问 = Data
3. **这个代码能跨项目复用吗？** → 能 = Infrastructure, 不能 = Data

---

**文档状态:** ✅ 完成
**实施状态:** 🟡 待应用到代码
**优先级:** 高（架构基础）

**变更日志:**
- 2026-02-06: v2.0 - 新增 Application 层职责、Feature 禁止规则、聚合核心能力清单、更新决策树和参考表
- 2026-02-03: v1.0 - 创建层次职责澄清总结，基于ADR-006
