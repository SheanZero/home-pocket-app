# ADR-006: Clean Architecture 层次职责划分

**状态:** ✅ 已接受
**日期:** 2026-02-03
**决策者:** 技术架构团队
**优先级:** 高（架构基础）

---

## 📋 目录

1. [背景](#背景)
2. [问题陈述](#问题陈述)
3. [决策](#决策)
4. [层次职责详解](#层次职责详解)
5. [具体示例](#具体示例)
6. [决策树指南](#决策树指南)
7. [常见误区](#常见误区)
8. [验证清单](#验证清单)

---

## 背景

在 Clean Architecture 实践中，Infrastructure 层和 Data 层的职责边界容易模糊，导致：

- **问题1:** 加密服务既可以放在 Infrastructure，也可以放在 Data
- **问题2:** 数据库访问代码分散在多个层次
- **问题3:** 开发者对组件放置位置产生困惑
- **问题4:** 代码审查时缺乏明确标准

**现状:**
```
lib/
├── data/
│   ├── datasources/local/
│   │   ├── database.dart          # ❓ 这是Data还是Infrastructure?
│   │   └── encrypted_file.dart    # ❓ 加密文件存储放哪里?
└── infrastructure/
    ├── crypto/
    │   └── encryption_service.dart # ❓ 这和Data层的加密重复?
    └── ml/
```

---

## 问题陈述

### 核心困惑

**困惑1: 加密服务的位置**
- `EncryptionService` 提供加密算法实现 → Infrastructure?
- 但 `EncryptedFileStorage` 需要使用加密 → Data?

**困惑2: 数据库配置**
- `Database` 类配置 SQLCipher → Data?
- 但 SQLCipher 是底层技术能力 → Infrastructure?

**困惑3: 平台通道**
- iOS/Android Platform Channels → Infrastructure?
- 但如果用于数据读取 → Data?

---

## 决策

### 明确原则：按职责划分，而非按技术划分

我们采用以下**职责边界定义**：

```
┌─────────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                            │
│  职责: UI渲染、用户交互、状态展示                                   │
│  依赖: Business Logic Layer                                      │
└─────────────────────────────────────────────────────────────────┘
                              ↓ 仅依赖接口
┌─────────────────────────────────────────────────────────────────┐
│                 BUSINESS LOGIC LAYER                             │
│  职责: 业务规则、用例编排、业务验证                                  │
│  依赖: Domain Layer 接口                                          │
└─────────────────────────────────────────────────────────────────┘
                              ↓ 仅依赖接口
┌─────────────────────────────────────────────────────────────────┐
│                      DOMAIN LAYER                                │
│  职责: 核心业务实体、业务接口定义、领域逻辑                           │
│  依赖: 无（完全独立）                                              │
└─────────────────────────────────────────────────────────────────┘
                              ↑ 实现接口
           ┌──────────────────┴──────────────────┐
           │                                     │
┌──────────▼──────────────┐      ┌──────────────▼───────────────┐
│     DATA LAYER          │      │   INFRASTRUCTURE LAYER       │
│                         │      │                              │
│  职责:                   │      │  职责:                        │
│  • 数据访问实现          │      │  • 技术能力提供               │
│  • Repository 实现      │      │  • 第三方库封装               │
│  • DAO/DTO              │      │  • 平台 API 封装             │
│  • 数据源整合            │      │  • 算法实现                  │
│  • 缓存策略              │      │  • 工具服务                  │
│                         │      │                              │
│  依赖:                   │      │  依赖:                        │
│  • Domain 接口          │      │  • Domain 接口（可选）        │
│  • Infrastructure 服务  │      │  • 外部 SDK                  │
└─────────────────────────┘      └──────────────────────────────┘
```

---

## 层次职责详解

### 1. Presentation Layer（展示层）

**核心职责:**
- UI 组件渲染
- 用户交互处理
- 状态展示（加载、错误、成功）
- 导航控制

**包含内容:**
```
lib/presentation/
├── screens/          # 页面组件
├── widgets/          # 可复用 UI 组件
├── themes/           # 主题配置
└── providers/        # UI 状态 Provider（仅UI状态）
```

**不应包含:**
- ❌ 业务逻辑
- ❌ 数据访问代码
- ❌ 算法实现
- ❌ 技术服务调用

**判断标准:**
> "这个组件只负责展示和用户交互吗？"

---

### 2. Business Logic Layer（业务逻辑层）

**核心职责:**
- 业务用例实现（Use Cases）
- 业务规则验证
- 业务流程编排
- 应用服务（Application Services）

**包含内容:**
```
lib/application/
├── use_cases/        # 业务用例
│   ├── create_transaction_use_case.dart
│   └── classify_ledger_use_case.dart
├── services/         # 应用服务（业务层面）
│   ├── classification_service.dart    # 分类业务逻辑
│   └── analytics_service.dart         # 分析业务逻辑
└── providers/        # 业务状态 Provider
```

**不应包含:**
- ❌ 数据库访问代码
- ❌ 加密算法实现
- ❌ 平台特定代码
- ❌ UI 组件

**判断标准:**
> "这个逻辑是业务规则的一部分吗？"

---

### 3. Domain Layer（领域层）

**核心职责:**
- 核心业务实体定义
- Repository 接口定义
- 领域值对象
- 领域逻辑（实体内部）

**包含内容:**
```
lib/domain/
├── models/           # 领域实体
│   ├── transaction.dart
│   ├── category.dart
│   └── book.dart
├── repositories/     # Repository 接口（仅接口）
│   ├── transaction_repository.dart
│   └── category_repository.dart
└── value_objects/    # 值对象
    ├── money.dart
    └── ledger_type.dart
```

**不应包含:**
- ❌ 任何实现代码
- ❌ 外部依赖
- ❌ 技术细节

**判断标准:**
> "这个概念是业务核心概念吗？与技术无关吗？"

---

### 4. Data Layer（数据层）

**核心职责:**
- **Repository 接口的实现**
- **数据访问逻辑（CRUD）**
- **数据源整合（本地+远程）**
- **DTO ↔ Domain Model 转换**
- **缓存策略实现**
- **数据同步逻辑**

**包含内容:**
```
lib/data/
├── repositories/     # Repository 实现
│   ├── transaction_repository_impl.dart
│   └── category_repository_impl.dart
│
├── datasources/      # 数据源
│   ├── local/        # 本地数据源
│   │   ├── database.dart              # ✅ Drift 数据库配置
│   │   ├── database.g.dart
│   │   ├── daos/                      # ✅ DAO 实现
│   │   │   ├── transaction_dao.dart
│   │   │   └── category_dao.dart
│   │   └── tables/                    # ✅ 表定义
│   │       ├── transactions.dart
│   │       └── categories.dart
│   │
│   ├── remote/       # 远程数据源（未来）
│   │   └── api_client.dart
│   │
│   └── file/         # 文件数据源
│       ├── file_storage.dart          # ✅ 文件读写逻辑
│       └── backup_file_handler.dart   # ✅ 备份文件处理
│
└── models/           # DTO (Data Transfer Objects)
    ├── transaction_dto.dart
    └── category_dto.dart
```

**关键特征:**
- ✅ 使用 Infrastructure 层提供的技术能力
- ✅ 关注"数据怎么存、怎么取"
- ✅ 实现 Repository 接口
- ✅ 处理数据转换和映射

**不应包含:**
- ❌ 加密算法实现（使用 Infrastructure 的）
- ❌ 哈希算法实现（使用 Infrastructure 的）
- ❌ ML 推理逻辑（使用 Infrastructure 的）
- ❌ 平台 API 封装（使用 Infrastructure 的）

**判断标准:**
> "这个类主要负责数据的存取吗？"

---

### 5. Infrastructure Layer（基础设施层）

**核心职责:**
- **提供技术能力（不关心业务）**
- **封装第三方库和平台 API**
- **实现算法和工具服务**
- **提供可复用的技术组件**

**包含内容:**
```
lib/infrastructure/
├── crypto/           # ✅ 加密技术能力
│   ├── encryption_service.dart        # 加密/解密算法
│   ├── key_manager.dart               # 密钥生成和管理
│   ├── hash_chain_service.dart        # 哈希计算
│   └── recovery_kit.dart              # 助记词生成
│
├── ml/               # ✅ 机器学习技术能力
│   ├── ocr_service.dart               # OCR 平台封装
│   ├── tflite_classifier.dart         # TF Lite 推理
│   └── merchant_database.dart         # 商家数据库（静态数据）
│
├── sync/             # ✅ 同步技术能力
│   ├── crdt_service.dart              # CRDT 算法实现
│   ├── bluetooth_transport.dart       # 蓝牙传输封装
│   ├── nfc_transport.dart             # NFC 传输封装
│   └── wifi_transport.dart            # WiFi 传输封装
│
├── security/         # ✅ 安全技术能力
│   ├── biometric_service.dart         # 生物识别平台封装
│   ├── secure_storage_service.dart    # 安全存储封装
│   └── audit_logger.dart              # 审计日志工具
│
├── platform/         # ✅ 平台特定封装
│   ├── ios/
│   │   └── vision_ocr_channel.dart    # iOS Vision Framework
│   └── android/
│       └── mlkit_ocr_channel.dart     # Android ML Kit
│
└── utils/            # ✅ 工具函数
    ├── date_formatter.dart
    ├── currency_formatter.dart
    └── error_handler.dart
```

**关键特征:**
- ✅ 与业务无关，纯技术实现
- ✅ 可独立测试
- ✅ 可跨项目复用
- ✅ 对外提供清晰接口

**不应包含:**
- ❌ Repository 实现
- ❌ 业务逻辑
- ❌ 数据访问代码
- ❌ DTO/DAO

**判断标准:**
> "这个服务在其他项目中也能用吗？与业务无关吗？"

---

## 具体示例

### 示例 1: 加密功能的层次划分

**场景:** 交易备注需要加密存储

#### ❌ 错误做法（职责不清）

```dart
// ❌ 在 Data 层直接实现加密算法
// lib/data/datasources/local/daos/transaction_dao.dart
class TransactionDao {
  Future<void> insertTransaction(Transaction tx) async {
    // ❌ 在 DAO 中直接实现加密
    final encrypted = _encryptNote(tx.note);  // 职责混乱！

    await database.into(transactions).insert(
      TransactionsCompanion(note: Value(encrypted)),
    );
  }

  // ❌ 加密算法不应在 Data 层
  String _encryptNote(String note) {
    // ChaCha20 加密实现...
  }
}
```

#### ✅ 正确做法（职责清晰）

```dart
// ✅ Infrastructure 层：提供加密技术能力
// lib/infrastructure/crypto/encryption_service.dart
class EncryptionService {
  /// 加密字符串（ChaCha20-Poly1305）
  Future<String> encrypt(String plaintext) async {
    final algorithm = Chacha20.poly1305Aead();
    final secretKey = await _getSecretKey();
    final nonce = _generateNonce();

    final secretBox = await algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: nonce,
    );

    return base64Encode(secretBox.concatenation());
  }

  /// 解密字符串
  Future<String> decrypt(String ciphertext) async {
    // 解密实现...
  }
}

// ✅ Data 层：使用加密服务实现数据访问
// lib/data/repositories/transaction_repository_impl.dart
class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionDao _dao;
  final EncryptionService _encryptionService;  // ✅ 依赖注入

  @override
  Future<void> insert(Transaction transaction) async {
    // ✅ 使用 Infrastructure 提供的加密能力
    final encryptedNote = transaction.note != null
        ? await _encryptionService.encrypt(transaction.note!)
        : null;

    final dto = transaction.toDto(encryptedNote: encryptedNote);
    await _dao.insertTransaction(dto);
  }
}

// ✅ Business Logic 层：业务逻辑
// lib/application/use_cases/create_transaction_use_case.dart
class CreateTransactionUseCase {
  final TransactionRepository _repository;  // ✅ 只依赖接口

  Future<void> execute(TransactionInput input) async {
    // 业务验证
    _validateInput(input);

    final transaction = Transaction(
      id: Uuid().v4(),
      note: input.note,  // ✅ 原始数据，不关心加密细节
      // ...
    );

    // ✅ Repository 内部会处理加密
    await _repository.insert(transaction);
  }
}
```

**职责分配总结:**
- 🔧 **Infrastructure:** 提供加密算法实现
- 💾 **Data:** 在数据访问时使用加密服务
- 🎯 **Business Logic:** 只关心业务逻辑，不知道加密细节

---

### 示例 2: OCR 功能的层次划分

**场景:** 扫描小票提取交易信息

#### ✅ 正确做法

```dart
// ✅ Infrastructure 层：OCR 技术能力封装
// lib/infrastructure/ml/ocr_service.dart
abstract class OCRService {
  /// 从图片中识别文本
  Future<String> recognizeText(File imageFile);
}

// 平台特定实现
class MLKitOCRService implements OCRService {
  @override
  Future<String> recognizeText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(
      script: TextRecognitionScript.japanese,
    );
    final recognizedText = await textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }
}

// ✅ Business Logic 层：OCR 业务应用
// lib/application/use_cases/scan_receipt_use_case.dart
class ScanReceiptUseCase {
  final OCRService _ocrService;             // ✅ 技术能力
  final ReceiptParser _receiptParser;       // ✅ 业务逻辑
  final ClassificationService _classifier;  // ✅ 业务逻辑

  Future<ReceiptData> execute(File imageFile) async {
    // 1. 使用 Infrastructure 的 OCR 能力
    final rawText = await _ocrService.recognizeText(imageFile);

    // 2. 业务逻辑：解析小票
    final receiptData = _receiptParser.parse(rawText);

    // 3. 业务逻辑：分类
    final category = await _classifier.classifyMerchant(
      receiptData.merchant,
    );

    return receiptData.copyWith(suggestedCategory: category);
  }
}
```

**职责分配总结:**
- 🔧 **Infrastructure:** 封装 ML Kit/Vision Framework，提供纯粹的文本识别能力
- 🎯 **Business Logic:** 使用 OCR 结果，应用业务规则（解析、分类）
- 💾 **Data:** （本例不涉及）

---

### 示例 3: 数据库配置的层次划分

**场景:** SQLCipher 加密数据库配置

#### ✅ 正确做法

```dart
// ✅ Infrastructure 层：密钥管理
// lib/infrastructure/crypto/key_manager.dart
class KeyManager {
  /// 派生数据库加密密钥
  Future<String> deriveDatabaseKey() async {
    final privateKey = await _secureStorage.read(key: 'device_private_key');

    final hkdf = Hkdf(hmac: Hmac(Sha256()), outputLength: 32);
    final derivedKey = await hkdf.deriveKey(
      secretKey: SecretKey(base64Decode(privateKey!)),
      info: utf8.encode('database_encryption_key'),
      nonce: Uint8List(32),
    );

    final bytes = await derivedKey.extractBytes();
    return base64Encode(bytes);
  }
}

// ✅ Data 层：数据库配置（使用密钥管理服务）
// lib/data/datasources/local/database.dart
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'homepocket.db'));

      return NativeDatabase.createInBackground(
        file,
        setup: (rawDb) {
          // ✅ 使用 Infrastructure 提供的密钥
          final key = KeyManager().deriveDatabaseKey();
          rawDb.execute("PRAGMA key = '$key'");
          rawDb.execute("PRAGMA cipher_page_size = 4096");
          // ...其他配置
        },
      );
    });
  }
}
```

**职责分配总结:**
- 🔧 **Infrastructure:** 密钥派生算法（HKDF）
- 💾 **Data:** 数据库配置和初始化（使用密钥服务）

---

### 示例 4: 哈希链的层次划分

**场景:** 交易哈希链完整性验证

#### ✅ 正确做法

```dart
// ✅ Infrastructure 层：哈希计算工具
// lib/infrastructure/crypto/hash_chain_service.dart
class HashChainService {
  /// 计算 SHA-256 哈希
  static String hash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 验证哈希
  static bool verify(String data, String expectedHash) {
    final actualHash = hash(data);
    return actualHash == expectedHash;
  }
}

// ✅ Domain 层：实体包含哈希计算逻辑
// lib/domain/models/transaction.dart
@freezed
class Transaction with _$Transaction {
  const Transaction._();

  const factory Transaction({
    required String id,
    required int amount,
    String? prevHash,
    required String currentHash,
    // ...
  }) = _Transaction;

  /// 计算当前交易的哈希
  String calculateHash() {
    final data = '$id|$amount|${prevHash ?? "genesis"}';
    // ✅ 使用 Infrastructure 的哈希工具
    return HashChainService.hash(data);
  }

  /// 验证哈希是否正确
  bool verifyHash() {
    return currentHash == calculateHash();
  }
}

// ✅ Business Logic 层：完整性验证业务逻辑
// lib/application/use_cases/verify_integrity_use_case.dart
class VerifyIntegrityUseCase {
  final TransactionRepository _repository;

  Future<IntegrityReport> execute(String bookId) async {
    final transactions = await _repository.getTransactions(bookId: bookId);
    transactions.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    String prevHash = 'genesis';
    final tamperedTransactions = <Transaction>[];

    for (final tx in transactions) {
      // ✅ 使用 Domain 实体的验证方法
      if (!tx.verifyHash()) {
        tamperedTransactions.add(tx);
      }

      if (tx.prevHash != prevHash) {
        tamperedTransactions.add(tx);
      }

      prevHash = tx.currentHash;
    }

    return IntegrityReport(
      isValid: tamperedTransactions.isEmpty,
      tamperedTransactions: tamperedTransactions,
    );
  }
}
```

**职责分配总结:**
- 🔧 **Infrastructure:** 提供 SHA-256 哈希算法
- 🏛️ **Domain:** 实体包含自身的哈希计算和验证方法
- 🎯 **Business Logic:** 完整性验证的业务流程

---

## 决策树指南

### 判断代码应该放在哪一层

```
开始
 │
 ├─ 这是 UI 相关的吗？
 │   └─ 是 → Presentation Layer
 │
 ├─ 这是业务规则吗？
 │   └─ 是 → Business Logic Layer
 │
 ├─ 这是核心业务概念吗？（与技术无关）
 │   └─ 是 → Domain Layer
 │
 ├─ 这是数据访问逻辑吗？
 │   ├─ Repository 实现？ → Data Layer
 │   ├─ DAO/DTO？ → Data Layer
 │   └─ 数据库配置？ → Data Layer
 │
 └─ 这是技术能力吗？
     ├─ 算法实现？ → Infrastructure Layer
     ├─ 平台 API 封装？ → Infrastructure Layer
     ├─ 第三方库封装？ → Infrastructure Layer
     └─ 工具服务？ → Infrastructure Layer
```

### 具体判断问题

#### 问：这个加密服务放哪里？

```
问题分解：
1. 它提供加密算法实现吗？ → 是
2. 它与数据存储直接相关吗？ → 否
3. 它可以在其他项目中复用吗？ → 是

结论：Infrastructure Layer
位置：lib/infrastructure/crypto/encryption_service.dart
```

#### 问：这个 TransactionDao 放哪里？

```
问题分解：
1. 它是数据访问对象吗？ → 是
2. 它实现了数据 CRUD 吗？ → 是
3. 它与业务逻辑无关吗？ → 是（纯数据访问）

结论：Data Layer
位置：lib/data/datasources/local/daos/transaction_dao.dart
```

#### 问：这个 HashChainService 放哪里？

```
问题分解：
1. 它提供哈希算法吗？ → 是
2. 它是纯技术实现吗？ → 是（SHA-256）
3. 它与业务逻辑无关吗？ → 是

结论：Infrastructure Layer
位置：lib/infrastructure/crypto/hash_chain_service.dart

注意：
- Domain 实体可以调用它来计算自己的哈希
- Business Logic 可以调用它来验证完整性
```

#### 问：这个 OCRService 放哪里？

```
问题分解：
1. 它封装平台 API（ML Kit/Vision）吗？ → 是
2. 它提供纯技术能力（文本识别）吗？ → 是
3. 它包含业务逻辑（解析小票）吗？ → 否

结论：Infrastructure Layer
位置：lib/infrastructure/ml/ocr_service.dart

注意：
- 小票解析逻辑应该在 Business Logic Layer
- OCR 只负责提取原始文本
```

---

## 常见误区

### ❌ 误区 1: 所有技术实现都放 Infrastructure

**错误示例:**
```dart
// ❌ 把 Repository 实现放在 Infrastructure
lib/infrastructure/repositories/
  └── transaction_repository_impl.dart  // 错误！
```

**正确做法:**
```dart
// ✅ Repository 实现属于 Data Layer
lib/data/repositories/
  └── transaction_repository_impl.dart  // 正确！
```

**原因:** Repository 是数据访问的实现，不是技术能力。

---

### ❌ 误区 2: 在 Data 层实现算法

**错误示例:**
```dart
// ❌ 在 DAO 中实现加密算法
class TransactionDao {
  String _encrypt(String data) {
    // ChaCha20 实现...  // 错误！应该用 Infrastructure 的服务
  }
}
```

**正确做法:**
```dart
// ✅ 使用 Infrastructure 提供的加密服务
class TransactionRepositoryImpl {
  final EncryptionService _encryptionService;  // 正确！

  Future<void> insert(Transaction tx) async {
    final encrypted = await _encryptionService.encrypt(tx.note);
    // ...
  }
}
```

---

### ❌ 误区 3: 业务逻辑放在 Infrastructure

**错误示例:**
```dart
// ❌ 在 OCRService 中包含业务逻辑
class OCRService {
  Future<ReceiptData> scanReceipt(File image) async {
    final text = await recognizeText(image);

    // ❌ 业务逻辑：解析小票、分类商家
    final amount = _parseAmount(text);  // 错误！
    final merchant = _parseMerchant(text);  // 错误！
    final category = _classifyMerchant(merchant);  // 错误！

    return ReceiptData(amount: amount, merchant: merchant);
  }
}
```

**正确做法:**
```dart
// ✅ Infrastructure：只提供文本识别能力
class OCRService {
  Future<String> recognizeText(File image) async {
    // 纯粹的文本识别
    return rawText;
  }
}

// ✅ Business Logic：小票解析和分类
class ScanReceiptUseCase {
  final OCRService _ocrService;
  final ReceiptParser _parser;  // 业务逻辑

  Future<ReceiptData> execute(File image) async {
    final text = await _ocrService.recognizeText(image);
    return _parser.parse(text);  // 业务逻辑在这里
  }
}
```

---

### ❌ 误区 4: Domain 实体依赖具体实现

**错误示例:**
```dart
// ❌ Domain 实体直接依赖 Infrastructure 具体类
import 'package:home_pocket/infrastructure/crypto/encryption_service.dart';

class Transaction {
  String calculateHash() {
    // ❌ 直接使用具体实现类
    return EncryptionService().hash(data);  // 错误！
  }
}
```

**正确做法:**
```dart
// ✅ Domain 实体调用静态工具方法（或不依赖）
import 'package:home_pocket/infrastructure/crypto/hash_chain_service.dart';

class Transaction {
  String calculateHash() {
    // ✅ 调用无状态的静态工具方法（可接受）
    return HashChainService.hash(data);
  }
}

// 或者更好的做法：在 Use Case 中处理
class CreateTransactionUseCase {
  final HashChainService _hashService;

  Future<Transaction> execute(input) async {
    final tx = Transaction(...);
    final hash = _hashService.hash(tx.toHashInput());
    return tx.copyWith(currentHash: hash);
  }
}
```

---

## 验证清单

### 代码审查时的检查项

#### Presentation Layer 检查

- [ ] 没有业务逻辑
- [ ] 没有数据访问代码
- [ ] 只消费 Provider，不实现业务规则
- [ ] 所有文字使用国际化 API

#### Business Logic Layer 检查

- [ ] Use Case 只调用 Repository 接口
- [ ] 不包含 UI 代码
- [ ] 不包含数据访问实现
- [ ] 不包含算法实现
- [ ] 业务规则清晰可读

#### Domain Layer 检查

- [ ] 没有外部依赖（除了极少数工具）
- [ ] 只定义接口，不实现
- [ ] 实体包含领域逻辑
- [ ] 完全可测试

#### Data Layer 检查

- [ ] 实现了 Repository 接口
- [ ] 不包含业务逻辑
- [ ] 不包含算法实现（使用 Infrastructure 的）
- [ ] DTO ↔ Domain Model 转换正确
- [ ] 依赖 Infrastructure 服务（通过接口）

#### Infrastructure Layer 检查

- [ ] 与业务无关
- [ ] 可独立测试
- [ ] 可跨项目复用
- [ ] 封装了第三方库或平台 API
- [ ] 提供清晰的接口

---

## 总结

### 核心原则

1. **Infrastructure = 技术能力提供者**
   - 算法、封装、工具
   - 与业务无关
   - 可复用

2. **Data = 数据访问实现者**
   - Repository 实现
   - DAO/DTO
   - 使用 Infrastructure 的技术能力

3. **清晰的依赖方向**
   ```
   Presentation → Business Logic → Domain
                                      ↑
                    Data ──────────────┘
                     ↓
                Infrastructure
   ```

### 快速参考表

| 组件类型 | 放置层次 | 示例 |
|---------|---------|------|
| Repository 实现 | Data | `TransactionRepositoryImpl` |
| DAO | Data | `TransactionDao` |
| DTO | Data | `TransactionDto` |
| Database 配置 | Data | `AppDatabase` |
| 加密服务 | Infrastructure | `EncryptionService` |
| 哈希服务 | Infrastructure | `HashChainService` |
| OCR 服务 | Infrastructure | `OCRService` |
| 密钥管理 | Infrastructure | `KeyManager` |
| CRDT 算法 | Infrastructure | `CRDTService` |
| 平台通道 | Infrastructure | `VisionOCRChannel` |
| Use Case | Business Logic | `CreateTransactionUseCase` |
| Application Service | Business Logic | `ClassificationService` |
| 实体 | Domain | `Transaction` |
| Repository 接口 | Domain | `TransactionRepository` |
| UI 组件 | Presentation | `TransactionScreen` |

---

**相关决策:**
- ADR-001: Riverpod 状态管理
- ADR-002: Drift + SQLCipher 数据库

**下一步行动:**
1. 审查现有代码，调整不符合此规范的组件
2. 更新架构文档，添加本 ADR 参考
3. 在代码审查清单中加入本规范

---

**文档状态:** ✅ 完成
**实施状态:** 🟡 待应用到代码
**审核状态:** 待审核

**变更日志:**
- 2026-02-03: 创建 ADR-006，明确层次职责划分标准
