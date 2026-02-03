# Clean Architecture 层次职责澄清总结

**更新日期:** 2026-02-03
**问题:** Infrastructure层与Data层职责模糊
**解决方案:** ADR-006 - Clean Architecture 层次职责划分标准

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
lib/infrastructure/
├── crypto/                    # ✅ 加密技术能力
│   ├── encryption_service.dart    # 加密/解密算法（ChaCha20）
│   ├── key_manager.dart           # 密钥生成和管理（Ed25519）
│   ├── hash_chain_service.dart    # 哈希计算（SHA-256）
│   └── recovery_kit.dart          # 助记词生成（BIP39）
│
├── ml/                        # ✅ 机器学习技术能力
│   ├── ocr_service.dart           # OCR平台封装（ML Kit/Vision）
│   ├── tflite_classifier.dart     # TF Lite推理引擎
│   └── merchant_database.dart     # 商家数据库（静态数据）
│
├── sync/                      # ✅ 同步技术能力
│   ├── crdt_service.dart          # CRDT算法实现（Yjs-inspired）
│   ├── bluetooth_transport.dart   # 蓝牙传输封装
│   ├── nfc_transport.dart         # NFC传输封装
│   └── wifi_transport.dart        # WiFi传输封装
│
├── security/                  # ✅ 安全技术能力
│   ├── biometric_service.dart     # 生物识别平台封装
│   ├── secure_storage_service.dart # 安全存储封装
│   └── audit_logger.dart          # 审计日志工具
│
├── platform/                  # ✅ 平台特定封装
│   ├── ios/
│   │   └── vision_ocr_channel.dart
│   └── android/
│       └── mlkit_ocr_channel.dart
│
└── utils/                     # ✅ 工具函数
    ├── date_formatter.dart
    ├── currency_formatter.dart
    └── error_handler.dart
```

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
lib/data/
├── repositories/              # ✅ Repository实现
│   ├── transaction_repository_impl.dart
│   ├── category_repository_impl.dart
│   └── sync_repository_impl.dart
│
├── datasources/               # ✅ 数据源
│   ├── local/                 # 本地数据源
│   │   ├── database.dart          # Drift数据库配置
│   │   ├── database.g.dart
│   │   ├── daos/                  # Data Access Objects
│   │   │   ├── transaction_dao.dart
│   │   │   └── category_dao.dart
│   │   └── tables/                # 表定义
│   │       ├── transactions.dart
│   │       └── categories.dart
│   │
│   ├── remote/                # 远程数据源（未来）
│   │   └── api_client.dart
│   │
│   └── file/                  # 文件数据源
│       ├── file_storage.dart      # 文件读写逻辑
│       └── backup_file_handler.dart
│
└── models/                    # ✅ DTO (Data Transfer Objects)
    ├── transaction_dto.dart
    └── category_dto.dart
```

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
 ├─ 这是UI相关的吗？
 │   └─ 是 → Presentation Layer
 │
 ├─ 这是业务规则吗？
 │   └─ 是 → Business Logic Layer
 │
 ├─ 这是核心业务概念吗？（与技术无关）
 │   └─ 是 → Domain Layer
 │
 ├─ 这是数据访问逻辑吗？
 │   ├─ Repository实现？ → Data Layer
 │   ├─ DAO/DTO？ → Data Layer
 │   └─ 数据库配置？ → Data Layer
 │
 └─ 这是技术能力吗？
     ├─ 算法实现？ → Infrastructure Layer
     ├─ 平台API封装？ → Infrastructure Layer
     ├─ 第三方库封装？ → Infrastructure Layer
     └─ 工具服务？ → Infrastructure Layer
```

---

## 📋 快速参考表

| 组件类型 | 放置层次 | 示例 |
|---------|---------|------|
| Repository实现 | Data | `TransactionRepositoryImpl` |
| DAO | Data | `TransactionDao` |
| DTO | Data | `TransactionDto` |
| Database配置 | Data | `AppDatabase` |
| 文件读写逻辑 | Data | `FileStorage` |
| 备份文件处理 | Data | `BackupFileHandler` |
| 加密服务 | Infrastructure | `EncryptionService` |
| 哈希服务 | Infrastructure | `HashChainService` |
| OCR服务 | Infrastructure | `OCRService` |
| 密钥管理 | Infrastructure | `KeyManager` |
| CRDT算法 | Infrastructure | `CRDTService` |
| 平台通道 | Infrastructure | `VisionOCRChannel` |
| TF Lite推理 | Infrastructure | `TFLiteClassifier` |
| 蓝牙传输 | Infrastructure | `BluetoothTransport` |
| 生物识别 | Infrastructure | `BiometricService` |

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
Infrastructure提供"能力"（How to do）
Data实现"访问"（Where to store）
Business Logic定义"规则"（What to do）
Domain定义"概念"（What it is）
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
- 2026-02-03: 创建层次职责澄清总结，基于ADR-006
