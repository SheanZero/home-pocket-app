# MOD-004: OCR扫描模块 - 技术设计文档

**模块编号:** MOD-004
**文档版本:** 3.0
**创建日期:** 2026-02-03
**最后更新:** 2026-02-22
**预估工时:** 7天（后端实现）
**优先级:** P1（强烈建议）
**状态:** 前端 UI Stub 已实现，后端 OCR 管道待实现

---

## 📋 目录

1. [模块概述](#模块概述)
2. [当前实现状态](#当前实现状态)
3. [功能需求](#功能需求)
4. [架构设计](#架构设计)
5. [实际导航流程](#实际导航流程)
6. [UI组件设计（已实现）](#ui组件设计已实现)
7. [后端实现计划](#后端实现计划)
8. [测试策略](#测试策略)
9. [性能优化](#性能优化)

---

## 模块概述

### 业务价值

OCR扫描模块通过相机扫描纸质收据，自动识别金额、日期、商家信息，将纸质收据数字化，显著提升记账效率。

### 核心功能

| 功能 | 说明 | 优先级 | 状态 |
|------|------|--------|------|
| 扫描入口 UI | 相机取景器 stub，含相册/快门/闪光灯控件 | P0 | ✅ Stub 已实现 |
| 帐单确认页 | 与手动录入共用 TransactionConfirmScreen | P0 | ✅ 已实现 |
| 拍照/相册选择 | image_picker 接入 | P0 | ⏳ 待实现 |
| OCR文字识别 | 识别金额、日期、商家 | P0 | ⏳ 待实现 |
| 图像预处理 | 灰度化、二值化、对比度增强 | P0 | ⏳ 待实现 |
| 商家自动分类 | 根据商家匹配分类和账本类型 | P0 | ⏳ 待实现 |
| 照片加密存储 | AES-GCM 端到端加密保存收据照片 | P1 | ⏳ 待实现 |

### 技术栈

```yaml
OCR引擎:
  Android: ML Kit Text Recognition v2 (google_mlkit_text_recognition)
  iOS: Vision Framework (Native via MethodChannel)
图像处理: image ^4.x
相机/相册: image_picker ^1.0.x
加密: 复用 lib/infrastructure/crypto/services/photo_encryption_service.dart
状态管理: Riverpod 2.4+ (riverpod_annotation)
路由: 复用 EntryModeNavigationConfig (pushReplacement 模式切换)
```

### 准确率目标

| 字段 | 目标准确率 | 备注 |
|------|-----------|------|
| 金额 | >90% | 清晰收据可达95%+ |
| 日期 | >85% | 多种格式支持 |
| 商家 | >80% | 依赖商家数据库 |

---

## 当前实现状态

### 已实现（Phase 1 - UI Stub）

#### OcrScannerScreen（lib/features/accounting/presentation/screens/ocr_scanner_screen.dart）

```
实现内容:
- 深色相机风格 UI（背景色 #1A2530）
- 取景框占位符（带 scan guide 边框）
- 相册/快门/闪光灯三按钮控件（全部 stub，onTap: () {}）
- 快门按钮当前仅执行 Navigator.pop(context)
- EntryModeSwitcher 集成（InputMode.ocr 高亮）
- 多语言支持（ocrScanTitle, ocrHint）

缺失内容（待实现）:
- 实际相机预览（camera / CameraController）
- 图像捕获和 OCR 处理
- 导航至 TransactionConfirmScreen（带识别结果）
```

#### TransactionConfirmScreen（lib/features/accounting/presentation/screens/transaction_confirm_screen.dart）

```
实现内容（手动和 OCR 共用）:
- 金额（可编辑：底部弹窗 + SmartKeyboard）
- 分类（可编辑：跳转 CategorySelectionScreen）
- 日期（可编辑：DatePicker，首次为今天）
- 商家名称（TextEditingController，可编辑）
- 备注（TextEditingController，多行）
- 账本类型选择（LedgerTypeSelector：生存/灵魂）
- 灵魂满足感滑条（仅灵魂账本时显示）
- 添加照片按钮（stub，尚未接入 OCR 图片）
- 保存：CreateTransactionUseCase.execute()
- 保存成功：灵魂账本显示 SoulCelebrationOverlay，然后 popUntil(first)

参数（构造函数）:
  String bookId
  int amount
  Category category
  Category? parentCategory
  DateTime date
```

---

## 功能需求

### FR-001: 收据拍照与选择

**用户故事**: 作为用户，我希望能通过相机拍摄收据或从相册选择照片，快速开始 OCR 识别。

**验收标准**:
- ✅ 支持相机拍照
- ✅ 支持从相册选择
- ✅ 拍照界面提供取景辅助框
- ✅ 支持闪光灯开关
- ✅ 快门捕获后，UI 显示处理中状态

**技术要求**:
- 使用 `image_picker` 插件
- 图片格式：JPG、PNG
- 最大分辨率：4K（3840×2160）

### FR-002: OCR文字识别

**用户故事**: 作为用户，我希望系统能自动识别收据上的金额、日期和商家，无需手动输入。

**验收标准**:
- ✅ 金额识别准确率 >90%
- ✅ 日期识别准确率 >85%
- ✅ 商家识别准确率 >80%
- ✅ 识别速度 <2秒
- ✅ 支持日语和英语混合文本
- ✅ 支持多种金额格式（¥1,280、1280円等）

**技术要求**:
- Android：ML Kit Text Recognition v2（支持 Japanese 脚本）
- iOS：Vision Framework（`recognizeTextRequest`，accuracy=accurate）
- 支持离线识别，无数据上传

### FR-003: 图像预处理

**验收标准**:
- ✅ 自动灰度化
- ✅ 自动对比度增强
- ✅ 自动二值化（Otsu 算法）
- ✅ 支持倾斜校正

**处理流程**:
```
原始图像 → 灰度化 → 对比度增强 → 二值化 → OCR识别
```

### FR-004: 商家自动分类

**验收标准**:
- ✅ 内置 500+ 日本常见商家数据库
- ✅ 精确匹配 + 别名匹配 + 模糊匹配
- ✅ 显示匹配置信度
- ✅ 自动预填账本类型（生存/灵魂）
- ✅ 用户可在 TransactionConfirmScreen 修改

### FR-005: 照片加密存储

**验收标准**:
- ✅ 照片使用 AES-256-GCM 加密
- ✅ 密钥派生自设备密钥（HKDF）
- ✅ SHA-256 哈希作为文件名
- ✅ 加密文件存储在应用私有目录
- ✅ 支持照片解密查看
- ✅ photoHash 关联到 Transaction 记录

---

## 架构设计

### 层次结构

按照 5 层 Clean Architecture 严格分层：

```
┌──────────────────────────────────────────────────────────────────┐
│  Presentation                                                     │
│  lib/features/accounting/presentation/                            │
│  ├── screens/                                                     │
│  │   ├── ocr_scanner_screen.dart       ← OCR 入口（已实现 stub） │
│  │   └── transaction_confirm_screen.dart ← 确认保存（已实现）    │
│  ├── widgets/                                                     │
│  │   ├── entry_mode_switcher.dart      ← 3模式标签切换           │
│  │   └── input_mode_tabs.dart          ← Manual/OCR/Voice tabs   │
│  ├── navigation/                                                  │
│  │   └── entry_mode_navigation_config.dart ← 模式路由配置        │
│  └── providers/                                                   │
│      ├── repository_providers.dart                                │
│      └── use_case_providers.dart                                  │
└─────────────────────────────┬────────────────────────────────────┘
                              │ ref.read()
┌─────────────────────────────▼────────────────────────────────────┐
│  Application  lib/application/                                    │
│  ├── accounting/                                                  │
│  │   └── create_transaction_use_case.dart  ← 保存交易（已实现）  │
│  └── ocr/                                  ← 待实现              │
│      ├── scan_receipt_use_case.dart                               │
│      ├── receipt_parser.dart                                      │
│      └── save_receipt_photo_use_case.dart                         │
└─────────────────────────────┬────────────────────────────────────┘
                              │
┌─────────────────────────────▼────────────────────────────────────┐
│  Domain  lib/features/accounting/domain/                          │
│  ├── models/                                                      │
│  │   ├── transaction.dart              ← 含 photoHash 字段        │
│  │   └── category.dart                                            │
│  └── repositories/                    ← 接口定义                  │
└─────────────────────────────┬────────────────────────────────────┘
                              │
┌─────────────────────────────▼────────────────────────────────────┐
│  Infrastructure  lib/infrastructure/                               │
│  ├── ml/                               ← 待实现                   │
│  │   ├── ocr/                                                     │
│  │   │   ├── ocr_service.dart          ← 抽象接口                 │
│  │   │   ├── mlkit_ocr_service.dart    ← Android ML Kit           │
│  │   │   └── vision_ocr_service.dart  ← iOS Vision Framework      │
│  │   ├── image_preprocessor.dart                                  │
│  │   ├── merchant_database.dart        ← 唯一定义（与 MOD-002 共享）│
│  │   └── tflite_classifier.dart                                   │
│  └── crypto/services/                                             │
│      └── photo_encryption_service.dart ← 已实现                  │
└─────────────────────────────┬────────────────────────────────────┘
                              │
┌─────────────────────────────▼────────────────────────────────────┐
│  Data  lib/data/                                                  │
│  ├── tables/                                                      │
│  │   └── receipt_photos_table.dart     ← 待实现                   │
│  ├── daos/                                                        │
│  │   └── receipt_photo_dao.dart        ← 待实现                   │
│  └── repositories/                                                │
│      └── receipt_photo_repository_impl.dart ← 待实现             │
└──────────────────────────────────────────────────────────────────┘
```

### 目录结构（目标状态）

```
# 已实现（accounting feature 的 presentation 层）
lib/features/accounting/presentation/
├── screens/
│   ├── ocr_scanner_screen.dart          # OCR 扫描入口（当前 stub）
│   ├── transaction_confirm_screen.dart  # 手动 + OCR 共用确认页（已实现）
│   ├── transaction_entry_screen.dart    # 手动录入（已实现）
│   └── ...
├── navigation/
│   └── entry_mode_navigation_config.dart  # 3模式路由（已实现）
└── widgets/
    ├── entry_mode_switcher.dart           # 模式切换标签栏（已实现）
    └── input_mode_tabs.dart               # Manual/OCR/Voice（已实现）

# 待实现（全局 Application 层）
lib/application/ocr/
├── scan_receipt_use_case.dart
├── receipt_parser.dart
└── save_receipt_photo_use_case.dart

# 待实现（全局 Infrastructure 层）
lib/infrastructure/ml/
├── ocr/
│   ├── ocr_service.dart
│   ├── mlkit_ocr_service.dart
│   └── vision_ocr_service.dart
├── image_preprocessor.dart
├── tflite_classifier.dart               # 唯一定义
└── merchant_database.dart               # 唯一定义（与 MOD-002 共享）

# 待实现（全局 Data 层）
lib/data/
├── tables/
│   └── receipt_photos_table.dart
├── daos/
│   └── receipt_photo_dao.dart
└── repositories/
    └── receipt_photo_repository_impl.dart
```

> **注意：** OCR 扫描 UI 不使用单独的 `lib/features/ocr/` feature，而是直接集成在 `lib/features/accounting/` 的 Presentation 层中，与手动录入共用确认流程。这遵循"thin feature"模式，避免不必要的 feature 分裂。

---

## 实际导航流程

### 入口路由（EntryModeNavigationConfig）

```dart
// lib/features/accounting/presentation/navigation/entry_mode_navigation_config.dart

final _entryModeRouteConfigs = <InputMode, EntryModeRouteConfig>{
  InputMode.manual: EntryModeRouteConfig(
    mode: InputMode.manual,
    builder: (bookId) => TransactionEntryScreen(bookId: bookId),
  ),
  InputMode.ocr: EntryModeRouteConfig(
    mode: InputMode.ocr,
    builder: (bookId) => OcrScannerScreen(bookId: bookId),
  ),
  InputMode.voice: EntryModeRouteConfig(
    mode: InputMode.voice,
    builder: (bookId) => VoiceInputScreen(bookId: bookId),
  ),
};
```

模式切换使用 `Navigator.pushReplacement`，保持相同 back stack 层级。

### 完整用户流程（目标状态）

```
Home Screen
    │
    ▼  [+ 记账 按钮]
TransactionEntryScreen (InputMode.manual)
    │
    │  EntryModeSwitcher → tap OCR tab
    │  (pushReplacement)
    ▼
OcrScannerScreen (InputMode.ocr)
    │
    │  [快门] → 调用 ScanReceiptUseCase
    │  ┌─────────────────────────────────┐
    │  │ 1. image_picker 获取图像        │
    │  │ 2. ImagePreprocessor 预处理     │
    │  │ 3. OCRService 识别文字          │
    │  │ 4. ReceiptParser 解析结构化数据 │
    │  │ 5. MerchantDatabase 商家匹配    │
    │  │ 6. SaveReceiptPhotoUseCase 加密存储 │
    │  └─────────────────────────────────┘
    │  识别成功 → Navigator.push
    ▼
TransactionConfirmScreen(
  bookId: bookId,
  amount: parsedAmount,           // 来自 OCR 识别（可编辑）
  category: suggestedCategory,    // 来自商家匹配（可编辑）
  parentCategory: parentCategory, // 来自商家匹配
  date: parsedDate,               // 来自 OCR 识别（可编辑）
  // 以下字段在 confirm screen 内填写:
  // merchant: merchantName (TextField)
  // memo: note (TextField)
  // ledgerType: auto from category (可切换)
  // photoHash: 已加密存储的图片哈希
)
    │
    │  [确认记录] → CreateTransactionUseCase.execute()
    ▼
Navigator.popUntil(isFirst)       // 返回首页
```

### 手动录入流程对比

```
TransactionEntryScreen → [下一步] → TransactionConfirmScreen
    (手动输入 amount/category/date)     (同一个 screen，复用)
```

> **关键设计决策：** OCR 和手动录入共用同一个 `TransactionConfirmScreen`。OCR 流程将识别结果作为构造函数参数传入，用户在确认页可以修正任意字段后保存。

---

## UI组件设计（已实现）

### OcrScannerScreen

```dart
// lib/features/accounting/presentation/screens/ocr_scanner_screen.dart

class OcrScannerScreen extends StatelessWidget {
  const OcrScannerScreen({super.key, required this.bookId});

  final String bookId;

  // 布局:
  // - Header: 返回按钮 + 标题（l10n.ocrScanTitle）
  // - EntryModeSwitcher（InputMode.ocr 高亮）
  // - Expanded: 取景框容器（Border + rounded corners）
  //   └── 占位图标 + l10n.ocrHint 文字
  // - 状态胶囊（status pill）
  // - 底部控件行:
  //   ├── _CircleButton(icon: gallery)    → 待实现
  //   ├── 快门按钮（72px 圆形白色）      → 当前: Navigator.pop()
  //   └── _CircleButton(icon: flash_off)  → 待实现
}
```

**后续实现要点：**
- 集成 `CameraController`（camera 包）或 `image_picker` 启动相机
- 快门按钮触发 `ScanReceiptUseCase.execute(source: camera)`
- 相册按钮触发 `ScanReceiptUseCase.execute(source: gallery)`
- 闪光灯按钮切换 `CameraController.setFlashMode()`
- 处理中时显示遮罩 + 进度动画

### TransactionConfirmScreen

```dart
// lib/features/accounting/presentation/screens/transaction_confirm_screen.dart

class TransactionConfirmScreen extends ConsumerStatefulWidget {
  // 参数（构造函数传入，手动录入 and OCR 共用）:
  final String bookId;
  final int amount;           // 整数金额（JPY: 四舍五入）
  final Category category;    // 叶级分类
  final Category? parentCategory; // 父级分类
  final DateTime date;        // 交易日期

  // 内部状态（可编辑）:
  // _amount (int), _category, _parentCategory, _date
  // _storeController (TextEditingController) → merchant
  // _memoController (TextEditingController)  → note
  // _ledgerType (LedgerType)                → soul/survival
  // _soulSatisfaction (int 1-10)            → 灵魂满足感

  // 金额编辑: showModalBottomSheet + AmountDisplay + SmartKeyboard
  // 分类编辑: Navigator.push → CategorySelectionScreen
  // 日期编辑: showDatePicker (theme: AppColors.survival)
  // 账本类型: LedgerTypeSelector 切换，初始由 _resolveLedgerType() 自动填充
  // 灵魂满足: SoulSatisfactionSlider（仅 LedgerType.soul 时显示）

  // 保存流程:
  // createTransactionUseCase.execute(CreateTransactionParams(
  //   bookId, amount, type: expense, categoryId, timestamp,
  //   note, merchant, soulSatisfaction, ledgerType
  // ))
  // isSuccess → 灵魂账本显示 SoulCelebrationOverlay
  //           → SnackBar "保存成功"
  //           → Navigator.popUntil(isFirst)
  // isError   → SnackBar 错误信息
}
```

**待接入（OCR 阶段）：**
- "添加照片"按钮目前是 stub，需接入 `ReceiptPhotoRepository` 展示已加密的收据照片
- 将 `photoHash` 传入 `CreateTransactionParams`（当前 model 需扩展该字段）

---

## 后端实现计划

### Phase 2: OCR 后端管道

#### Step 1: 图像获取与预处理

```dart
// lib/infrastructure/ml/image_preprocessor.dart

class ImagePreprocessor {
  Future<File> process(XFile image) async {
    // 1. 读取图像字节
    // 2. 调整大小（最大 2048px）
    // 3. 灰度化：img.grayscale()
    // 4. 对比度增强：img.contrast(contrast: 120)
    // 5. Otsu 二值化
    // 6. 保存到临时文件
    // 注：使用 compute() 在 Isolate 执行，避免阻塞 UI
  }
}
```

#### Step 2: OCR 服务（双平台）

```dart
// lib/infrastructure/ml/ocr/ocr_service.dart
abstract class OCRService {
  Future<OCRResult> recognizeText(File imageFile);
  void dispose();
}

// lib/infrastructure/ml/ocr/mlkit_ocr_service.dart (Android)
// 使用 google_mlkit_text_recognition，script: Japanese

// lib/infrastructure/ml/ocr/vision_ocr_service.dart (iOS)
// 使用 MethodChannel('com.homepocket.ocr')
// 调用 VNRecognizeTextRequest，recognitionLevel: accurate
// 支持语言: ja, en
```

#### Step 3: 收据解析器

```dart
// lib/application/ocr/receipt_parser.dart

class ReceiptParser {
  ParsedReceiptData parse(String text) {
    return ParsedReceiptData(
      amount: _extractAmount(text),   // 优先合計 > 小計 > TOTAL > ¥金额
      date: _extractDate(text),       // 多种格式：年月日/YYYY/MM/DD/YY/MM/DD
      merchant: _extractMerchant(lines), // 第一个非数字/非日期/非金额行
    );
  }
}
```

**金额提取优先级：**
1. 合計/小計/TOTAL 关键字后的数字
2. 行尾的 ¥数字 或 数字円
3. 所有数字中取最大值（兜底）

**日期支持格式：**
- `YYYY年MM月DD日`
- `YYYY/MM/DD`、`YYYY-MM-DD`、`YYYY.MM.DD`
- `YY/MM/DD`（自动补全世纪）

#### Step 4: 商家数据库

```dart
// lib/infrastructure/ml/merchant_database.dart（唯一定义，与 MOD-002 共享）

class MerchantDatabase {
  // 500+ 日本常见商家（便利店/超市/餐饮/交通/购物/药妆）
  // 匹配策略（优先级）:
  //   1. 精确匹配 → confidence * 1.0
  //   2. 别名匹配 → confidence * 1.0
  //   3. 模糊匹配（contains）→ confidence * 0.8
  //   4. 别名模糊匹配 → confidence * 0.75
}
```

#### Step 5: ScanReceiptUseCase

```dart
// lib/application/ocr/scan_receipt_use_case.dart

class ScanReceiptUseCase {
  final OCRService _ocrService;
  final ImagePreprocessor _preprocessor;
  final ReceiptParser _parser;
  final MerchantDatabase _merchantDB;
  final SaveReceiptPhotoUseCase _savePhotoUseCase;

  Future<Result<ScannedReceiptResult>> execute({
    required ImageSource source,
  }) async {
    // 1. image_picker 获取图像
    // 2. ImagePreprocessor.process()（Isolate）
    // 3. OCRService.recognizeText()
    // 4. ReceiptParser.parse()
    // 5. MerchantDatabase.findMerchant()
    // 6. SaveReceiptPhotoUseCase.execute() → photoHash
    // 7. 返回 ScannedReceiptResult（供 OcrScannerScreen 传给 TransactionConfirmScreen）
  }
}

// 返回结果用于构造 TransactionConfirmScreen 参数
class ScannedReceiptResult {
  final int? amount;
  final DateTime? date;
  final String? merchantName;
  final Category? suggestedCategory;
  final Category? suggestedParentCategory;
  final LedgerType? suggestedLedgerType;
  final String? photoHash;
  final double confidence;       // 整体置信度 0.0~1.0
}
```

#### Step 6: 照片加密存储

```dart
// lib/application/ocr/save_receipt_photo_use_case.dart

class SaveReceiptPhotoUseCase {
  // 1. 读取图像字节
  // 2. SHA-256 哈希 → 文件名
  // 3. 查重（已存在则复用）
  // 4. PhotoEncryptionService.encrypt() → AES-256-GCM
  // 5. 写入 {appDir}/receipts/{hash}.enc
  // 6. 元数据存入 receipt_photos 表
}

// 复用已实现的:
// lib/infrastructure/crypto/services/photo_encryption_service.dart
```

#### Step 7: OcrScannerScreen 接入

```dart
// 在 OcrScannerScreen 中:
Future<void> _onShutter() async {
  setState(() => _isProcessing = true);
  try {
    final useCase = ref.read(scanReceiptUseCaseProvider);
    final result = await useCase.execute(source: ImageSource.camera);

    if (result.isSuccess && mounted) {
      final data = result.data!;
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => TransactionConfirmScreen(
            bookId: widget.bookId,
            amount: data.amount ?? 0,
            category: data.suggestedCategory ?? _defaultCategory,
            parentCategory: data.suggestedParentCategory,
            date: data.date ?? DateTime.now(),
          ),
        ),
      );
    } else if (result.isError && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.error!)));
    }
  } finally {
    if (mounted) setState(() => _isProcessing = false);
  }
}
```

---

## 测试策略

### 单元测试

```dart
// test/unit/application/ocr/receipt_parser_test.dart
group('ReceiptParser', () {
  test('提取合計金額（日語）', () { ... });
  test('提取合計金額（英語 TOTAL）', () { ... });
  test('提取带逗号的金额', () { ... });
  test('未找到金额时返回null', () { ... });
  test('提取日期 YYYY年MM月DD日', () { ... });
  test('提取日期 YYYY/MM/DD', () { ... });
  test('提取日期 YY/MM/DD（补全世纪）', () { ... });
  test('提取商家名称', () { ... });
});

// test/unit/infrastructure/ml/merchant_database_test.dart
group('MerchantDatabase', () {
  test('精确匹配返回 exact matchType', () { ... });
  test('别名匹配返回 alias matchType', () { ... });
  test('模糊匹配置信度降低', () { ... });
  test('未知商家返回 null', () { ... });
});
```

### Widget 测试

```dart
// test/widget/ocr_scanner_screen_test.dart
testWidgets('OcrScannerScreen 显示正确 UI 元素', (tester) async {
  // 验证: ocrScanTitle 文字, 取景框, 相册/快门/闪光灯按钮
});
```

### 集成测试

```dart
// integration_test/ocr_flow_test.dart
testWidgets('完整 OCR 流程：扫描 → 确认 → 保存', (tester) async {
  // 1. 启动应用
  // 2. 切换到 OCR 模式（EntryModeSwitcher）
  // 3. 模拟选择测试收据照片（gallery）
  // 4. 验证 TransactionConfirmScreen 预填数据
  // 5. 点击确认记录
  // 6. 验证交易已创建
});
```

### 覆盖率要求

- 目标 ≥80%（含 ReceiptParser、MerchantDatabase 的全路径）

---

## 性能优化

### 图像处理（Isolate）

```dart
// 使用 Flutter compute() 在独立 Isolate 执行图像处理，避免阻塞 UI 线程
Future<File> processImageInBackground(XFile image) async {
  return await compute(_processImageSync, image.path);
}
```

### OCR识别优化

- **分辨率控制**: 最大 2048px，减少处理时间
- **识别区域**: 优先识别收据关键区域（金额区、日期区）
- **超时机制**: OCR 超时 5 秒，返回空结果，引导手动录入

### 照片存储优化

```dart
// 压缩后再加密（节省存储空间）
final compressed = img.encodeJpg(decoded, quality: 85);
final encrypted = await photoEncryptionService.encrypt(compressed);
```

### 缓存策略

- **商家数据库**: 进程内单例，预加载到内存，`O(1)` 查找
- **分类数据**: Riverpod provider 缓存
- **收据缩略图**: 解密后生成 256px 缩略图，缓存于内存

---

## 总结

MOD-004 OCR扫描模块：

1. **当前状态**: 前端 UI Stub 已集成至 accounting feature 的 presentation 层
2. **共用确认页**: OCR 和手动录入共用 `TransactionConfirmScreen`，识别结果作为参数传入
3. **导航模式**: 通过 `EntryModeNavigationConfig` + `pushReplacement` 在三种录入模式间切换
4. **待实现**: 后端 OCR 管道（`lib/application/ocr/`、`lib/infrastructure/ml/`、`lib/data/` 相关表）
5. **安全**: 照片 AES-256-GCM 加密，复用已实现的 `PhotoEncryptionService`

**开发优先级**: P1，预计 7 天完成后端实现。

**依赖模块**:
- ✅ MOD-001（基础记账）— 交易创建（已实现）
- ✅ MOD-002（双轨账本）— 商家数据库分类（MerchantDatabase 唯一定义）
- ✅ MOD-006（安全模块）— 照片加密（PhotoEncryptionService 已实现）

---

**文档维护**:
- v1.0: 2026-02-03 — 初始版本
- v2.0: 2026-02-06 — 架构重构（ARCH-008），移除 features/ocr/ 分层
- v3.0: 2026-02-22 — 基于实际代码更新，反映 stub 现状，更正模块编号为 MOD-004，明确 TransactionConfirmScreen 共用设计
