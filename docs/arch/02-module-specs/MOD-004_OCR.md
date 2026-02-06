# MOD-005: OCR扫描模块 - 技术设计文档

**模块编号:** MOD-005
**文档版本:** 2.0
**创建日期:** 2026-02-03
**预估工时:** 7天
**优先级:** P1（强烈建议）
**状态:** 设计完成

---

## 📋 目录

1. [模块概述](#模块概述)
2. [功能需求](#功能需求)
3. [技术设计](#技术设计)
4. [核心流程](#核心流程)
5. [UI组件设计](#ui组件设计)
6. [测试策略](#测试策略)
7. [性能优化](#性能优化)

---

## 模块概述

### 业务价值

OCR扫描模块通过相机扫描纸质收据，自动识别金额、日期、商家信息，将纸质收据数字化，显著提升记账效率。

### 核心功能

| 功能 | 说明 | 优先级 |
|------|------|--------|
| 收据扫描 | 拍照或从相册选择收据 | P0 |
| OCR文字识别 | 识别金额、日期、商家 | P0 |
| 商家自动分类 | 根据商家匹配分类和账户 | P0 |
| 图像预处理 | 去噪、二值化、对比度增强 | P0 |
| 照片加密存储 | 端到端加密保存收据照片 | P0 |
| 用户确认修正 | 编辑识别结果 | P0 |

### 技术栈

```yaml
OCR引擎:
  Android: ML Kit Text Recognition v2
  iOS: Vision Framework (Native)
图像处理: image ^4.1.7
相机/相册: image_picker ^1.0.7
加密: cryptography ^2.7.0 (AES-GCM)
状态管理: Riverpod 2.4+
```

### 准确率目标

根据可行性研究，准确率目标设定为：

| 字段 | 目标准确率 | 备注 |
|------|-----------|------|
| 金额 | >90% | 清晰收据可达95%+ |
| 日期 | >85% | 多种格式支持 |
| 商家 | >80% | 依赖商家数据库 |

---

## 功能需求

### FR-001: 收据拍照与选择

**用户故事**: 作为用户，我希望能够通过相机拍摄收据或从相册选择照片，快速开始OCR识别。

**验收标准**:
- ✅ 支持相机拍照
- ✅ 支持从相册选择
- ✅ 支持裁剪和旋转
- ✅ 拍照界面提供对焦辅助框
- ✅ 支持闪光灯开关

**技术要求**:
- 使用`image_picker`插件
- 图片格式支持：JPG、PNG
- 最大分辨率：4K (3840x2160)

### FR-002: OCR文字识别

**用户故事**: 作为用户，我希望系统能够自动识别收据上的金额、日期和商家，无需手动输入。

**验收标准**:
- ✅ 金额识别准确率>90%
- ✅ 日期识别准确率>85%
- ✅ 商家识别准确率>80%
- ✅ 识别速度<2秒
- ✅ 支持日语和英语混合文本
- ✅ 支持多种金额格式（¥1,280、1280円等）

**技术要求**:
- Android使用ML Kit Text Recognition v2
- iOS使用Vision Framework
- 支持离线识别
- 无数据上传（隐私保护）

### FR-003: 图像预处理

**用户故事**: 作为用户，即使我拍摄的照片模糊、倾斜或有褶皱，系统也应该能够尽可能准确地识别。

**验收标准**:
- ✅ 自动灰度化处理
- ✅ 自动对比度增强
- ✅ 自动二值化（Otsu算法）
- ✅ 支持倾斜校正
- ✅ 去除噪点

**处理流程**:
```
原始图像 → 灰度化 → 对比度增强 → 二值化 → OCR识别
```

### FR-004: 商家自动分类

**用户故事**: 作为用户，我希望系统能够根据商家名称自动推荐分类和账户类型。

**验收标准**:
- ✅ 内置500+日本常见商家数据库
- ✅ 支持精确匹配和模糊匹配
- ✅ 支持商家别名匹配
- ✅ 显示匹配置信度
- ✅ 用户可修改推荐结果

**商家数据库覆盖**:
- 便利店：セブンイレブン、ファミリーマート、ローソン等
- 超市：イオン、イトーヨーカドー、西友等
- 餐饮：吉野家、マクドナルド、スターバックス等
- 交通：JR东日本、东京メトロ等
- 购物：ヨドバシカメラ、ユニクロ等

### FR-005: 照片加密存储

**用户故事**: 作为用户，我希望我的收据照片能够安全加密保存，防止隐私泄露。

**验收标准**:
- ✅ 照片使用AES-GCM加密
- ✅ 加密密钥派生自设备密钥
- ✅ 照片哈希作为文件名（SHA-256）
- ✅ 加密文件存储在应用私有目录
- ✅ 支持照片解密查看
- ✅ 照片与交易记录关联

**安全要求**:
- 加密算法：AES-256-GCM
- 密钥派生：HKDF (RFC 5869)
- 文件命名：Base64(SHA256(原始图片))

---

## 技术设计

### 架构图

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  ┌────────────────┐  ┌────────────────┐ │
│  │ OCRScanScreen  │  │OCRConfirmScreen│ │
│  │  (相机拍照)    │  │  (结果确认)    │ │
│  └────────┬────────┘  └────────┬───────┘ │
│           │                    │         │
│  ┌────────▼────────────────────▼───────┐ │
│  │      OCR Providers                  │ │
│  │  - ocrScanProvider                  │ │
│  │  - receiptDataProvider              │ │
│  │  - merchantLookupProvider           │ │
│  └────────┬────────────────────────────┘ │
└───────────┼──────────────────────────────┘
            │
┌───────────▼──────────────────────────────┐
│        Business Logic Layer              │
│  ┌────────────────────────────────────┐  │
│  │      Use Cases                     │  │
│  │  - ScanReceiptUseCase              │  │
│  │  - ProcessImageUseCase             │  │
│  │  - ClassifyMerchantUseCase         │  │
│  │  - SaveReceiptPhotoUseCase         │  │
│  └────────┬───────────────────────────┘  │
│           │                              │
│  ┌────────▼───────────────────────────┐  │
│  │  Services                          │  │
│  │  - OCRService (Platform-specific)  │  │
│  │  - ImagePreprocessor               │  │
│  │  - ReceiptParser                   │  │
│  │  - MerchantDatabase                │  │
│  └────────┬───────────────────────────┘  │
└───────────┼──────────────────────────────┘
            │
┌───────────▼──────────────────────────────┐
│           Infrastructure Layer           │
│  ┌────────────────────────────────────┐  │
│  │  Platform Channels                 │  │
│  │  - MLKitOCRService (Android)       │  │
│  │  - VisionOCRService (iOS)          │  │
│  └────────┬───────────────────────────┘  │
│           │                              │
│  ┌────────▼───────────────────────────┐  │
│  │  Photo Storage                     │  │
│  │  - EncryptedPhotoRepository        │  │
│  │  - PhotoEncryptionService          │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

### 目录结构

```
# Feature 模块（瘦 Feature：ONLY domain/ + presentation/）
lib/features/ocr/
  ├── domain/                              # ONLY: models + repository interfaces
  │   ├── models/
  │   │   ├── receipt_data.dart
  │   │   ├── receipt_data.freezed.dart
  │   │   ├── ocr_result.dart
  │   │   └── merchant_match.dart
  │   └── repositories/
  │       └── receipt_photo_repository.dart  # 抽象接口
  │
  └── presentation/
      ├── screens/
      │   ├── ocr_scan_screen.dart
      │   ├── ocr_confirmation_screen.dart
      │   └── receipt_photo_viewer_screen.dart
      ├── widgets/
      │   ├── camera_view.dart
      │   ├── receipt_data_form.dart
      │   ├── confidence_badge.dart
      │   └── photo_preview.dart
      └── providers/
          ├── ocr_scan_provider.dart
          └── receipt_data_provider.dart

# Application 层（全局 Use Cases + 业务服务）
lib/application/ocr/
  ├── scan_receipt_use_case.dart
  ├── receipt_parser.dart                   # 业务解析逻辑
  └── save_receipt_photo_use_case.dart

# Infrastructure 层（全局技术能力）
lib/infrastructure/ml/
  ├── ocr/
  │   ├── ocr_service.dart                 # 抽象接口
  │   ├── mlkit_ocr_service.dart           # Android 实现（ML Kit）
  │   └── vision_ocr_service.dart          # iOS 实现（Vision Framework）
  ├── image_preprocessor.dart              # 图像预处理
  ├── tflite_classifier.dart               # 引用 MOD-002 唯一定义
  └── merchant_database.dart               # 引用 MOD-002 唯一定义

lib/infrastructure/crypto/services/
  └── photo_encryption_service.dart        # 照片加密（AES-GCM）

# Data 层（全局数据访问）
lib/data/
  ├── tables/
  │   └── receipt_photos_table.dart
  ├── daos/
  │   └── receipt_photo_dao.dart
  └── repositories/
      └── receipt_photo_repository_impl.dart  # 含加密存储逻辑
```

> ⚠️ **v2.0 变更:**
> - 删除 `features/ocr/infrastructure/` → 组件分散到 `lib/infrastructure/`
> - 删除 `features/ocr/application/` → Use Cases 移至 `lib/application/ocr/`
> - `domain/use_cases/` → `lib/application/ocr/`
> - `ImagePreprocessor` → `lib/infrastructure/ml/`
> - `PhotoEncryptionService` → `lib/infrastructure/crypto/services/`
> - `EncryptedPhotoRepository` → `lib/data/repositories/`
> - `MerchantDatabase` → 引用 `lib/infrastructure/ml/` 唯一定义（去重）

---

## 核心流程

### 1. 收据扫描流程

```dart
// lib/application/ocr/scan_receipt_use_case.dart

import 'package:image_picker/image_picker.dart';

class ScanReceiptUseCase {
  final OCRService _ocrService;
  final ImagePreprocessor _preprocessor;
  final ReceiptParser _parser;
  final MerchantDatabase _merchantDB;
  final SaveReceiptPhotoUseCase _savePhotoUseCase;

  ScanReceiptUseCase({
    required OCRService ocrService,
    required ImagePreprocessor preprocessor,
    required ReceiptParser parser,
    required MerchantDatabase merchantDB,
    required SaveReceiptPhotoUseCase savePhotoUseCase,
  })  : _ocrService = ocrService,
        _preprocessor = preprocessor,
        _parser = parser,
        _merchantDB = merchantDB,
        _savePhotoUseCase = savePhotoUseCase;

  Future<Result<ReceiptData>> execute({
    required ImageSource source,
  }) async {
    try {
      // 1. 获取图像
      final XFile? image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 3840,
        maxHeight: 2160,
        imageQuality: 85,
      );

      if (image == null) {
        return Result.error('用户取消选择');
      }

      // 2. 图像预处理
      final processedImage = await _preprocessor.process(image);

      // 3. OCR识别
      final ocrResult = await _ocrService.recognizeText(processedImage);

      if (ocrResult.text.isEmpty) {
        return Result.error('未识别到文字，请重新拍摄');
      }

      // 4. 解析结构化数据
      final parsedData = _parser.parse(ocrResult.text);

      // 5. 商家自动分类
      MerchantMatch? merchantMatch;
      if (parsedData.merchant != null) {
        merchantMatch = _merchantDB.findMerchant(parsedData.merchant!);
      }

      // 6. 加密保存照片
      final photoHash = await _savePhotoUseCase.execute(image);

      // 7. 构建结果
      final receiptData = ReceiptData(
        amount: parsedData.amount,
        date: parsedData.date,
        merchant: parsedData.merchant,
        suggestedCategory: merchantMatch?.categoryId,
        suggestedLedgerType: merchantMatch?.ledgerType,
        photoHash: photoHash,
        rawText: ocrResult.text,
        confidence: _calculateConfidence(parsedData),
      );

      return Result.success(receiptData);

    } catch (e, stackTrace) {
      await ErrorHandler.logError(e, stackTrace, context: {
        'operation': 'ScanReceipt',
      });
      return Result.error('扫描失败: $e');
    }
  }

  double _calculateConfidence(ParsedReceiptData data) {
    var confidence = 0.0;

    if (data.amount != null && data.amount! > 0) confidence += 0.4;
    if (data.date != null) confidence += 0.3;
    if (data.merchant != null && data.merchant!.isNotEmpty) confidence += 0.3;

    return confidence;
  }
}
```

### 2. 图像预处理服务

```dart
// lib/infrastructure/ml/image_preprocessor.dart

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ImagePreprocessor {
  /// 预处理图像以提高OCR准确率
  Future<File> process(XFile image) async {
    try {
      // 1. 读取图像
      final bytes = await image.readAsBytes();
      img.Image? decodedImage = img.decodeImage(bytes);

      if (decodedImage == null) {
        throw ImageProcessingException('图像解码失败');
      }

      // 2. 调整大小（如果太大）
      if (decodedImage.width > 2048 || decodedImage.height > 2048) {
        decodedImage = img.copyResize(
          decodedImage,
          width: decodedImage.width > decodedImage.height ? 2048 : null,
          height: decodedImage.height > decodedImage.width ? 2048 : null,
        );
      }

      // 3. 灰度化
      decodedImage = img.grayscale(decodedImage);

      // 4. 对比度增强
      decodedImage = img.contrast(decodedImage, contrast: 120);

      // 5. 二值化（Otsu算法）
      final threshold = _calculateOtsuThreshold(decodedImage);
      decodedImage = _applyThreshold(decodedImage, threshold);

      // 6. 保存处理后的图像
      final processedBytes = img.encodePng(decodedImage);
      final tempDir = await getTemporaryDirectory();
      final processedFile = File(
        '${tempDir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await processedFile.writeAsBytes(processedBytes);

      return processedFile;

    } catch (e) {
      throw ImageProcessingException('图像处理失败: $e');
    }
  }

  /// Otsu自动阈值算法
  int _calculateOtsuThreshold(img.Image image) {
    // 计算灰度直方图
    final histogram = List.filled(256, 0);
    final total = image.width * image.height;

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final gray = img.getLuminance(pixel).toInt();
        histogram[gray]++;
      }
    }

    // Otsu算法
    var sum = 0;
    for (var i = 0; i < 256; i++) {
      sum += i * histogram[i];
    }

    var sumB = 0;
    var wB = 0;
    var wF = 0;
    var maxVariance = 0.0;
    var threshold = 0;

    for (var i = 0; i < 256; i++) {
      wB += histogram[i];
      if (wB == 0) continue;

      wF = total - wB;
      if (wF == 0) break;

      sumB += i * histogram[i];

      final mB = sumB / wB;
      final mF = (sum - sumB) / wF;

      final variance = wB * wF * (mB - mF) * (mB - mF);

      if (variance > maxVariance) {
        maxVariance = variance;
        threshold = i;
      }
    }

    return threshold;
  }

  /// 应用阈值
  img.Image _applyThreshold(img.Image image, int threshold) {
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final gray = img.getLuminance(pixel).toInt();
        final newColor = gray > threshold ? 255 : 0;
        image.setPixel(x, y, img.ColorRgb8(newColor, newColor, newColor));
      }
    }
    return image;
  }
}

class ImageProcessingException implements Exception {
  final String message;
  ImageProcessingException(this.message);

  @override
  String toString() => 'ImageProcessingException: $message';
}
```

### 3. OCR服务实现（Android - ML Kit）

```dart
// lib/infrastructure/ml/ocr/mlkit_ocr_service.dart

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';

class MLKitOCRService implements OCRService {
  late final TextRecognizer _textRecognizer;

  MLKitOCRService() {
    _textRecognizer = TextRecognizer(
      script: TextRecognitionScript.japanese,
    );
  }

  @override
  Future<OCRResult> recognizeText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final textBlocks = recognizedText.blocks.map((block) {
        return TextBlock(
          text: block.text,
          boundingBox: Rect.fromLTRB(
            block.boundingBox.left,
            block.boundingBox.top,
            block.boundingBox.right,
            block.boundingBox.bottom,
          ),
          confidence: block.confidence ?? 0.0,
        );
      }).toList();

      return OCRResult(
        text: recognizedText.text,
        blocks: textBlocks,
      );

    } catch (e) {
      throw OCRException('ML Kit识别失败: $e');
    }
  }

  @override
  void dispose() {
    _textRecognizer.close();
  }
}
```

### 4. OCR服务实现（iOS - Vision Framework）

```dart
// lib/infrastructure/ml/ocr/vision_ocr_service.dart

import 'package:flutter/services.dart';
import 'dart:io';

class VisionOCRService implements OCRService {
  static const platform = MethodChannel('com.homepocket.ocr');

  @override
  Future<OCRResult> recognizeText(File imageFile) async {
    try {
      final result = await platform.invokeMethod('recognizeText', {
        'imagePath': imageFile.path,
        'languages': ['ja', 'en'],
        'recognitionLevel': 'accurate',
      });

      final text = result['text'] as String;
      final blocks = (result['blocks'] as List).map((blockData) {
        return TextBlock(
          text: blockData['text'],
          boundingBox: Rect.fromLTRB(
            blockData['left'],
            blockData['top'],
            blockData['right'],
            blockData['bottom'],
          ),
          confidence: blockData['confidence'] ?? 0.0,
        );
      }).toList();

      return OCRResult(
        text: text,
        blocks: blocks,
      );

    } on PlatformException catch (e) {
      throw OCRException('Vision Framework识别失败: ${e.message}');
    }
  }

  @override
  void dispose() {
    // Vision Framework无需手动释放
  }
}
```

### 5. 收据解析器

```dart
// lib/application/ocr/receipt_parser.dart

class ReceiptParser {
  /// 解析OCR文本为结构化数据
  ParsedReceiptData parse(String text) {
    final lines = text.split('\n').map((line) => line.trim()).toList();

    return ParsedReceiptData(
      amount: _extractAmount(text, lines),
      date: _extractDate(text, lines),
      merchant: _extractMerchant(lines),
    );
  }

  /// 提取金额
  int? _extractAmount(String text, List<String> lines) {
    // 优先级1: 合计金额
    final totalPatterns = [
      RegExp(r'合計[：:\s]*[¥￥]?\s*(\d{1,3}(?:,\d{3})*)', multiLine: true),
      RegExp(r'小計[：:\s]*[¥￥]?\s*(\d{1,3}(?:,\d{3})*)', multiLine: true),
      RegExp(r'TOTAL[：:\s]*[¥￥]?\s*(\d{1,3}(?:,\d{3})*)', multiLine: true, caseSensitive: false),
      RegExp(r'計[：:\s]*[¥￥]?\s*(\d{1,3}(?:,\d{3})*)', multiLine: true),
    ];

    for (final pattern in totalPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount > 0) {
        final amountStr = match.group(1)!.replaceAll(',', '');
        final amount = int.tryParse(amountStr);
        if (amount != null && amount > 0) {
          return amount;
        }
      }
    }

    // 优先级2: 金额格式
    final amountPatterns = [
      RegExp(r'[¥￥]\s*(\d{1,3}(?:,\d{3})*)\s*$', multiLine: true),
      RegExp(r'(\d{1,3}(?:,\d{3})*)\s*円\s*$', multiLine: true),
    ];

    for (final pattern in amountPatterns) {
      final matches = pattern.allMatches(text).toList();
      if (matches.isNotEmpty) {
        // 取最后一个匹配（通常是合计）
        final match = matches.last;
        final amountStr = match.group(1)!.replaceAll(',', '');
        final amount = int.tryParse(amountStr);
        if (amount != null && amount > 0) {
          return amount;
        }
      }
    }

    // 优先级3: 所有数字，取最大值
    final numbers = RegExp(r'\d{1,3}(?:,\d{3})*').allMatches(text);
    final amounts = numbers
        .map((m) => int.tryParse(m.group(0)!.replaceAll(',', '')))
        .where((a) => a != null && a > 0 && a < 1000000)  // 过滤不合理的数字
        .toList();

    if (amounts.isNotEmpty) {
      amounts.sort((a, b) => b!.compareTo(a!));
      return amounts.first;
    }

    return null;
  }

  /// 提取日期
  DateTime? _extractDate(String text, List<String> lines) {
    final patterns = [
      // YYYY年MM月DD日
      RegExp(r'(\d{4})\s*年\s*(\d{1,2})\s*月\s*(\d{1,2})\s*日?'),
      // YYYY/MM/DD 或 YYYY-MM-DD
      RegExp(r'(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})'),
      // YY/MM/DD
      RegExp(r'(\d{2})[/\-.](\d{1,2})[/\-.](\d{1,2})'),
      // YYYY.MM.DD
      RegExp(r'(\d{4})\.(\d{1,2})\.(\d{1,2})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          var year = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!);
          final day = int.parse(match.group(3)!);

          // 如果是两位年份，补全为完整年份
          if (year < 100) {
            final currentYear = DateTime.now().year;
            final century = (currentYear ~/ 100) * 100;
            year = century + year;
            // 如果日期在未来，减去100年
            if (year > currentYear) {
              year -= 100;
            }
          }

          // 验证日期有效性
          if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            final date = DateTime(year, month, day);
            // 确保日期不在未来
            if (date.isBefore(DateTime.now().add(const Duration(days: 1)))) {
              return date;
            }
          }
        } catch (e) {
          continue;
        }
      }
    }

    return null;
  }

  /// 提取商家名称
  String? _extractMerchant(List<String> lines) {
    for (final line in lines) {
      final trimmed = line.trim();

      // 跳过空行
      if (trimmed.isEmpty) continue;

      // 跳过纯数字
      if (RegExp(r'^\d+$').hasMatch(trimmed)) continue;

      // 跳过日期行
      if (RegExp(r'\d{4}[年/\-.]').hasMatch(trimmed)) continue;

      // 跳过金额行
      if (trimmed.contains('¥') ||
          trimmed.contains('￥') ||
          trimmed.contains('円') ||
          trimmed.contains('合計') ||
          trimmed.contains('小計') ||
          trimmed.toLowerCase().contains('total')) {
        continue;
      }

      // 跳过太短的行（可能是噪音）
      if (trimmed.length < 2) continue;

      // 跳过太长的行（可能是地址或其他信息）
      if (trimmed.length > 30) continue;

      // 可能是商家名称
      return trimmed;
    }

    return null;
  }
}

@freezed
class ParsedReceiptData with _$ParsedReceiptData {
  const factory ParsedReceiptData({
    int? amount,
    DateTime? date,
    String? merchant,
  }) = _ParsedReceiptData;
}
```

### 6. 商家数据库

```dart
// lib/infrastructure/ml/merchant_database.dart (唯一定义，与 MOD-002 共享)

class MerchantDatabase {
  /// 日本常见商家数据库（500+商家）
  static final Map<String, MerchantInfo> _merchants = {
    // ========== 便利店 (10家) ==========
    'セブンイレブン': MerchantInfo(
      categoryId: 'food_groceries',
      ledgerType: LedgerType.survival,
      confidence: 0.95,
      aliases: ['セブン', '7-11', '7-ELEVEN', 'SEVEN ELEVEN'],
    ),
    'ファミリーマート': MerchantInfo(
      categoryId: 'food_groceries',
      ledgerType: LedgerType.survival,
      confidence: 0.95,
      aliases: ['ファミマ', 'FamilyMart', 'FAMILY MART'],
    ),
    'ローソン': MerchantInfo(
      categoryId: 'food_groceries',
      ledgerType: LedgerType.survival,
      confidence: 0.95,
      aliases: ['LAWSON'],
    ),
    'ミニストップ': MerchantInfo(
      categoryId: 'food_groceries',
      ledgerType: LedgerType.survival,
      confidence: 0.9,
      aliases: ['MINISTOP'],
    ),

    // ========== 超市 (15家) ==========
    'イオン': MerchantInfo(
      categoryId: 'food_groceries',
      ledgerType: LedgerType.survival,
      confidence: 0.9,
      aliases: ['AEON'],
    ),
    'イトーヨーカドー': MerchantInfo(
      categoryId: 'food_groceries',
      ledgerType: LedgerType.survival,
      confidence: 0.9,
      aliases: ['ITO YOKADO', 'イトヨ'],
    ),
    '西友': MerchantInfo(
      categoryId: 'food_groceries',
      ledgerType: LedgerType.survival,
      confidence: 0.9,
      aliases: ['SEIYU', 'せいゆう'],
    ),
    'ライフ': MerchantInfo(
      categoryId: 'food_groceries',
      ledgerType: LedgerType.survival,
      confidence: 0.9,
      aliases: ['LIFE'],
    ),
    'マルエツ': MerchantInfo(
      categoryId: 'food_groceries',
      ledgerType: LedgerType.survival,
      confidence: 0.85,
      aliases: ['Maruetsu'],
    ),

    // ========== 餐饮 - 快餐 (20家) ==========
    '吉野家': MerchantInfo(
      categoryId: 'food_restaurant',
      ledgerType: LedgerType.soul,
      confidence: 0.95,
      aliases: ['YOSHINOYA', 'よしのや'],
    ),
    'マクドナルド': MerchantInfo(
      categoryId: 'food_restaurant',
      ledgerType: LedgerType.soul,
      confidence: 0.95,
      aliases: ["McDonald's", 'マック', 'McDonalds'],
    ),
    'すき家': MerchantInfo(
      categoryId: 'food_restaurant',
      ledgerType: LedgerType.soul,
      confidence: 0.95,
      aliases: ['SUKIYA', 'スキヤ'],
    ),
    '松屋': MerchantInfo(
      categoryId: 'food_restaurant',
      ledgerType: LedgerType.soul,
      confidence: 0.95,
      aliases: ['MATSUYA', 'まつや'],
    ),
    'モスバーガー': MerchantInfo(
      categoryId: 'food_restaurant',
      ledgerType: LedgerType.soul,
      confidence: 0.95,
      aliases: ['MOS BURGER', 'モス'],
    ),
    'ケンタッキー': MerchantInfo(
      categoryId: 'food_restaurant',
      ledgerType: LedgerType.soul,
      confidence: 0.95,
      aliases: ['KFC', 'ケンタ'],
    ),

    // ========== 餐饮 - 咖啡店 (10家) ==========
    'スターバックス': MerchantInfo(
      categoryId: 'food_restaurant',
      ledgerType: LedgerType.soul,
      confidence: 0.95,
      aliases: ['STARBUCKS', 'スタバ', 'Starbucks Coffee'],
    ),
    'ドトールコーヒー': MerchantInfo(
      categoryId: 'food_restaurant',
      ledgerType: LedgerType.soul,
      confidence: 0.9,
      aliases: ['DOUTOR', 'ドトール'],
    ),
    'タリーズコーヒー': MerchantInfo(
      categoryId: 'food_restaurant',
      ledgerType: LedgerType.soul,
      confidence: 0.9,
      aliases: ["TULLY'S", 'タリーズ'],
    ),
    'コメダ珈琲店': MerchantInfo(
      categoryId: 'food_restaurant',
      ledgerType: LedgerType.soul,
      confidence: 0.9,
      aliases: ['KOMEDA', 'コメダ'],
    ),

    // ========== 交通 (15家) ==========
    'JR東日本': MerchantInfo(
      categoryId: 'transport_commute',
      ledgerType: LedgerType.survival,
      confidence: 0.95,
      aliases: ['JR EAST', 'JR East'],
    ),
    '東京メトロ': MerchantInfo(
      categoryId: 'transport_commute',
      ledgerType: LedgerType.survival,
      confidence: 0.95,
      aliases: ['TOKYO METRO', 'Tokyo Metro'],
    ),
    '都営地下鉄': MerchantInfo(
      categoryId: 'transport_commute',
      ledgerType: LedgerType.survival,
      confidence: 0.95,
      aliases: ['TOEI'],
    ),

    // ========== 购物 - 电器 (10家) ==========
    'ヨドバシカメラ': MerchantInfo(
      categoryId: 'shopping_electronics',
      ledgerType: LedgerType.soul,
      confidence: 0.9,
      aliases: ['Yodobashi', 'ヨドバシ'],
    ),
    'ビックカメラ': MerchantInfo(
      categoryId: 'shopping_electronics',
      ledgerType: LedgerType.soul,
      confidence: 0.9,
      aliases: ['BIC CAMERA', 'ビック'],
    ),

    // ========== 购物 - 服装 (15家) ==========
    'ユニクロ': MerchantInfo(
      categoryId: 'shopping_fashion',
      ledgerType: LedgerType.soul,
      confidence: 0.9,
      aliases: ['UNIQLO'],
    ),
    'GU': MerchantInfo(
      categoryId: 'shopping_fashion',
      ledgerType: LedgerType.soul,
      confidence: 0.9,
      aliases: ['ジーユー'],
    ),
    '無印良品': MerchantInfo(
      categoryId: 'shopping_fashion',
      ledgerType: LedgerType.soul,
      confidence: 0.9,
      aliases: ['MUJI', 'むじ'],
    ),

    // ========== 药妆店 (10家) ==========
    'マツモトキヨシ': MerchantInfo(
      categoryId: 'medical',
      ledgerType: LedgerType.survival,
      confidence: 0.9,
      aliases: ['Matsumoto Kiyoshi', 'マツキヨ'],
    ),
    'ウエルシア': MerchantInfo(
      categoryId: 'medical',
      ledgerType: LedgerType.survival,
      confidence: 0.9,
      aliases: ['Welcia'],
    ),

    // ... 更多商家（总计500+）...
  };

  /// 查找商家
  MerchantMatch? findMerchant(String merchantName) {
    final normalizedName = merchantName.trim();

    // 1. 精确匹配
    if (_merchants.containsKey(normalizedName)) {
      final info = _merchants[normalizedName]!;
      return MerchantMatch(
        merchantName: normalizedName,
        categoryId: info.categoryId,
        ledgerType: info.ledgerType,
        confidence: info.confidence,
        matchType: MatchType.exact,
      );
    }

    // 2. 别名匹配
    for (final entry in _merchants.entries) {
      if (entry.value.aliases.contains(normalizedName)) {
        return MerchantMatch(
          merchantName: entry.key,
          categoryId: entry.value.categoryId,
          ledgerType: entry.value.ledgerType,
          confidence: entry.value.confidence,
          matchType: MatchType.alias,
        );
      }
    }

    // 3. 模糊匹配（包含）
    for (final entry in _merchants.entries) {
      if (normalizedName.contains(entry.key) || entry.key.contains(normalizedName)) {
        return MerchantMatch(
          merchantName: entry.key,
          categoryId: entry.value.categoryId,
          ledgerType: entry.value.ledgerType,
          confidence: entry.value.confidence * 0.8,  // 降低置信度
          matchType: MatchType.fuzzy,
        );
      }

      // 检查别名的模糊匹配
      for (final alias in entry.value.aliases) {
        if (normalizedName.contains(alias) || alias.contains(normalizedName)) {
          return MerchantMatch(
            merchantName: entry.key,
            categoryId: entry.value.categoryId,
            ledgerType: entry.value.ledgerType,
            confidence: entry.value.confidence * 0.75,
            matchType: MatchType.fuzzy,
          );
        }
      }
    }

    return null;
  }

  /// 获取所有商家名称（用于自动补全）
  List<String> getAllMerchantNames() {
    return _merchants.keys.toList()..sort();
  }

  /// 获取商家数量
  int get totalMerchants => _merchants.length;
}

@freezed
class MerchantInfo with _$MerchantInfo {
  const factory MerchantInfo({
    required String categoryId,
    required LedgerType ledgerType,
    required double confidence,
    @Default([]) List<String> aliases,
  }) = _MerchantInfo;
}

@freezed
class MerchantMatch with _$MerchantMatch {
  const factory MerchantMatch({
    required String merchantName,
    required String categoryId,
    required LedgerType ledgerType,
    required double confidence,
    required MatchType matchType,
  }) = _MerchantMatch;
}

enum MatchType {
  exact,   // 精确匹配
  alias,   // 别名匹配
  fuzzy,   // 模糊匹配
}
```

### 7. 照片加密存储

```dart
// lib/application/ocr/save_receipt_photo_use_case.dart

import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class SaveReceiptPhotoUseCase {
  final PhotoEncryptionService _encryptionService;
  final ReceiptPhotoRepository _repository;

  SaveReceiptPhotoUseCase({
    required PhotoEncryptionService encryptionService,
    required ReceiptPhotoRepository repository,
  })  : _encryptionService = encryptionService,
        _repository = repository;

  Future<String> execute(XFile image) async {
    try {
      // 1. 读取图像字节
      final bytes = await image.readAsBytes();

      // 2. 计算哈希（作为唯一标识）
      final hashBytes = sha256.convert(bytes);
      final photoHash = base64Encode(hashBytes.bytes);

      // 3. 检查是否已存在
      final exists = await _repository.exists(photoHash);
      if (exists) {
        return photoHash;
      }

      // 4. 加密图像
      final encryptedBytes = await _encryptionService.encrypt(bytes);

      // 5. 保存到文件系统
      await _repository.save(
        hash: photoHash,
        encryptedData: encryptedBytes,
        originalSize: bytes.length,
      );

      return photoHash;

    } catch (e, stackTrace) {
      await ErrorHandler.logError(e, stackTrace, context: {
        'operation': 'SaveReceiptPhoto',
      });
      throw Exception('照片保存失败: $e');
    }
  }
}

// lib/infrastructure/crypto/services/photo_encryption_service.dart

class PhotoEncryptionService {
  final KeyManager _keyManager;
  final AesGcm _algorithm = AesGcm.with256bits();

  PhotoEncryptionService({required KeyManager keyManager})
      : _keyManager = keyManager;

  /// 加密照片
  Future<Uint8List> encrypt(Uint8List plaintext) async {
    // 1. 获取加密密钥（从设备密钥派生）
    final secretKey = await _derivePhotoEncryptionKey();

    // 2. 生成随机nonce
    final nonce = _algorithm.newNonce();

    // 3. 加密
    final secretBox = await _algorithm.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: nonce,
    );

    // 4. 组合nonce + ciphertext + mac
    final result = BytesBuilder();
    result.add(nonce);  // 12 bytes
    result.add(secretBox.cipherText);
    result.add(secretBox.mac.bytes);  // 16 bytes

    return result.toBytes();
  }

  /// 解密照片
  Future<Uint8List> decrypt(Uint8List encryptedData) async {
    // 1. 获取解密密钥
    final secretKey = await _derivePhotoEncryptionKey();

    // 2. 分离nonce、ciphertext、mac
    final nonce = encryptedData.sublist(0, 12);
    final cipherText = encryptedData.sublist(12, encryptedData.length - 16);
    final macBytes = encryptedData.sublist(encryptedData.length - 16);

    // 3. 解密
    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    final plaintext = await _algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return Uint8List.fromList(plaintext);
  }

  /// 派生照片加密密钥
  Future<SecretKey> _derivePhotoEncryptionKey() async {
    final deviceKey = await _keyManager.getDevicePrivateKey();

    final hkdf = Hkdf(
      hmac: Hmac(Sha256()),
      outputLength: 32,
    );

    return await hkdf.deriveKey(
      secretKey: deviceKey,
      info: utf8.encode('photo_encryption_key'),
      nonce: Uint8List(32),  // 固定nonce，确保确定性派生
    );
  }
}

// lib/data/repositories/receipt_photo_repository_impl.dart

class EncryptedPhotoRepository implements ReceiptPhotoRepository {
  final AppDatabase _database;

  EncryptedPhotoRepository({required AppDatabase database})
      : _database = database;

  @override
  Future<void> save({
    required String hash,
    required Uint8List encryptedData,
    required int originalSize,
  }) async {
    // 1. 保存到文件系统
    final appDir = await getApplicationDocumentsDirectory();
    final photoDir = Directory('${appDir.path}/receipts');
    await photoDir.create(recursive: true);

    final filePath = '${photoDir.path}/$hash.enc';
    final file = File(filePath);
    await file.writeAsBytes(encryptedData);

    // 2. 保存元数据到数据库
    await _database.into(_database.receiptPhotos).insert(
      ReceiptPhotosCompanion.insert(
        hash: hash,
        filePath: filePath,
        fileSize: encryptedData.length,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<Uint8List> load(String hash) async {
    final photo = await (_database.select(_database.receiptPhotos)
          ..where((tbl) => tbl.hash.equals(hash)))
        .getSingleOrNull();

    if (photo == null) {
      throw Exception('照片不存在: $hash');
    }

    final file = File(photo.filePath);
    if (!await file.exists()) {
      throw Exception('照片文件丢失: ${photo.filePath}');
    }

    return await file.readAsBytes();
  }

  @override
  Future<bool> exists(String hash) async {
    final count = await (_database.select(_database.receiptPhotos)
          ..where((tbl) => tbl.hash.equals(hash)))
        .get()
        .then((rows) => rows.length);

    return count > 0;
  }

  @override
  Future<void> delete(String hash) async {
    final photo = await (_database.select(_database.receiptPhotos)
          ..where((tbl) => tbl.hash.equals(hash)))
        .getSingleOrNull();

    if (photo != null) {
      // 删除文件
      final file = File(photo.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // 删除数据库记录
      await (_database.delete(_database.receiptPhotos)
            ..where((tbl) => tbl.hash.equals(hash)))
          .go();
    }
  }
}
```

---

## UI组件设计

### 1. OCR扫描界面

```dart
// lib/features/ocr/presentation/screens/ocr_scan_screen.dart

class OCRScanScreen extends ConsumerStatefulWidget {
  const OCRScanScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OCRScanScreen> createState() => _OCRScanScreenState();
}

class _OCRScanScreenState extends ConsumerState<OCRScanScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('レシートスキャン'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 背景渐变
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Colors.white,
                ],
              ),
            ),
          ),

          // 主要内容
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),

                // 标题和说明
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        'レシートを撮影',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '金額、日付、店舗名を自動で読み取ります',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                // 扫描按钮
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 相机按钮
                        _ScanButton(
                          icon: Icons.camera_alt,
                          label: 'カメラで撮影',
                          color: Theme.of(context).colorScheme.primary,
                          onPressed: _isProcessing ? null : () => _scanReceipt(ImageSource.camera),
                        ),

                        const SizedBox(height: 24),

                        // 相册按钮
                        _ScanButton(
                          icon: Icons.photo_library,
                          label: 'ギャラリーから選択',
                          color: Theme.of(context).colorScheme.secondary,
                          onPressed: _isProcessing ? null : () => _scanReceipt(ImageSource.gallery),
                        ),
                      ],
                    ),
                  ),
                ),

                // 提示信息
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'レシートを明るい場所で撮影すると\n認識精度が向上します',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 加载遮罩
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'レシートを解析中...',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _scanReceipt(ImageSource source) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final useCase = ref.read(scanReceiptUseCaseProvider);
      final result = await useCase.execute(source: source);

      if (result.isSuccess && mounted) {
        // 跳转到确认页面
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OCRConfirmationScreen(
              receiptData: result.data!,
            ),
          ),
        );
      } else if (result.isError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error!)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}

class _ScanButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _ScanButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Material(
        color: onPressed != null ? color : Colors.grey[300],
        borderRadius: BorderRadius.circular(24),
        elevation: onPressed != null ? 8 : 0,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 80,
                color: onPressed != null ? Colors.white : Colors.grey[500],
              ),
              const SizedBox(height: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: onPressed != null ? Colors.white : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 2. OCR结果确认界面

```dart
// lib/features/ocr/presentation/screens/ocr_confirmation_screen.dart

class OCRConfirmationScreen extends ConsumerStatefulWidget {
  final ReceiptData receiptData;

  const OCRConfirmationScreen({
    Key? key,
    required this.receiptData,
  }) : super(key: key);

  @override
  ConsumerState<OCRConfirmationScreen> createState() =>
      _OCRConfirmationScreenState();
}

class _OCRConfirmationScreenState
    extends ConsumerState<OCRConfirmationScreen> {
  late TextEditingController _amountController;
  late TextEditingController _merchantController;
  late DateTime _selectedDate;
  String? _selectedCategoryId;
  LedgerType? _selectedLedgerType;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.receiptData.amount?.toString() ?? '',
    );
    _merchantController = TextEditingController(
      text: widget.receiptData.merchant ?? '',
    );
    _selectedDate = widget.receiptData.date ?? DateTime.now();
    _selectedCategoryId = widget.receiptData.suggestedCategory;
    _selectedLedgerType = widget.receiptData.suggestedLedgerType;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR認識結果'),
        actions: [
          TextButton(
            onPressed: _handleConfirm,
            child: const Text(
              '確認保存',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 照片预览
          _buildPhotoPreview(),

          const SizedBox(height: 24),

          // 置信度徽章
          _buildConfidenceBadge(),

          const SizedBox(height: 24),

          // 识别结果标题
          Text(
            '認識結果',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 16),

          // 金额输入
          _buildAmountField(),

          const SizedBox(height: 16),

          // 日期选择
          _buildDateField(),

          const SizedBox(height: 16),

          // 商家输入
          _buildMerchantField(),

          const SizedBox(height: 16),

          // 分类选择
          _buildCategoryField(),

          const SizedBox(height: 16),

          // 账户类型选择
          _buildLedgerTypeField(),

          const SizedBox(height: 24),

          // 警告提示
          _buildWarning(),

          const SizedBox(height: 24),

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('再スキャン'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _handleConfirm,
                  child: const Text('確認保存'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPreview() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FutureBuilder<Uint8List>(
          future: _loadPhoto(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge() {
    final confidence = widget.receiptData.confidence;
    final percentage = (confidence * 100).toInt();

    Color badgeColor;
    String message;

    if (confidence >= 0.8) {
      badgeColor = Colors.green;
      message = '認識精度：高';
    } else if (confidence >= 0.6) {
      badgeColor = Colors.orange;
      message = '認識精度：中';
    } else {
      badgeColor = Colors.red;
      message = '認識精度：低';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics, size: 20, color: badgeColor),
          const SizedBox(width: 12),
          Text(
            message,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Text(
            '$percentage%',
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    final hasValue = widget.receiptData.amount != null;
    return TextField(
      controller: _amountController,
      decoration: InputDecoration(
        labelText: '金額',
        prefixText: '¥',
        border: const OutlineInputBorder(),
        suffixIcon: Icon(
          hasValue ? Icons.check_circle : Icons.error,
          color: hasValue ? Colors.green : Colors.red,
        ),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
    );
  }

  Widget _buildDateField() {
    return ListTile(
      leading: const Icon(Icons.calendar_today),
      title: const Text('日付'),
      subtitle: Text(
        DateFormat('yyyy年M月d日').format(_selectedDate),
      ),
      trailing: Icon(
        widget.receiptData.date != null ? Icons.check_circle : Icons.error,
        color: widget.receiptData.date != null ? Colors.green : Colors.orange,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      onTap: _pickDate,
    );
  }

  Widget _buildMerchantField() {
    final hasValue = widget.receiptData.merchant != null;
    return TextField(
      controller: _merchantController,
      decoration: InputDecoration(
        labelText: '店舗名',
        border: const OutlineInputBorder(),
        suffixIcon: Icon(
          hasValue ? Icons.check_circle : Icons.error,
          color: hasValue ? Colors.green : Colors.orange,
        ),
      ),
    );
  }

  Widget _buildCategoryField() {
    return ListTile(
      leading: const Icon(Icons.category),
      title: const Text('分類'),
      subtitle: Text(
        _selectedCategoryId != null
            ? _getCategoryName(_selectedCategoryId!)
            : '選択してください',
      ),
      trailing: const Icon(Icons.chevron_right),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      onTap: _pickCategory,
    );
  }

  Widget _buildLedgerTypeField() {
    return SegmentedButton<LedgerType>(
      segments: const [
        ButtonSegment(
          value: LedgerType.survival,
          label: Text('生存'),
          icon: Icon(Icons.home),
        ),
        ButtonSegment(
          value: LedgerType.soul,
          label: Text('魂'),
          icon: Icon(Icons.favorite),
        ),
      ],
      selected: _selectedLedgerType != null ? {_selectedLedgerType!} : {},
      onSelectionChanged: (Set<LedgerType> selected) {
        setState(() {
          _selectedLedgerType = selected.first;
        });
      },
    );
  }

  Widget _buildWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '⚠️ 認識結果を確認してください',
              style: TextStyle(
                color: Colors.orange[900],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _pickCategory() async {
    // TODO: 实现分类选择器
  }

  Future<void> _handleConfirm() async {
    // 验证
    final amount = int.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入有效的金額')),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請選擇分類')),
      );
      return;
    }

    // 创建交易
    final useCase = ref.read(createTransactionUseCaseProvider);
    final result = await useCase.execute(CreateTransactionParams(
      bookId: await _getCurrentBookId(),
      amount: amount,
      type: TransactionType.expense,
      categoryId: _selectedCategoryId!,
      timestamp: _selectedDate,
      note: _merchantController.text.isNotEmpty ? _merchantController.text : null,
      photoHash: widget.receiptData.photoHash,
    ));

    if (result.isSuccess && mounted) {
      // 返回首页
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('取引を保存しました')),
      );
    } else if (result.isError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!)),
      );
    }
  }

  Future<Uint8List> _loadPhoto() async {
    final repository = ref.read(receiptPhotoRepositoryProvider);
    final encryptionService = ref.read(photoEncryptionServiceProvider);

    final encryptedData = await repository.load(widget.receiptData.photoHash);
    return await encryptionService.decrypt(encryptedData);
  }

  String _getCategoryName(String categoryId) {
    // TODO: 从分类仓库获取
    return categoryId;
  }

  Future<String> _getCurrentBookId() async {
    // TODO: 从当前用户获取
    return 'book_default';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    super.dispose();
  }
}
```

### 3. 收据照片查看器

```dart
// lib/features/ocr/presentation/screens/receipt_photo_viewer_screen.dart

class ReceiptPhotoViewerScreen extends ConsumerWidget {
  final String photoHash;
  final Transaction transaction;

  const ReceiptPhotoViewerScreen({
    Key? key,
    required this.photoHash,
    required this.transaction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('レシート', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => _sharePhoto(context, ref),
          ),
        ],
      ),
      body: Center(
        child: FutureBuilder<Uint8List>(
          future: _loadPhoto(ref),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(color: Colors.white);
            }

            if (snapshot.hasError) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'レシートの読み込みに失敗しました',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              );
            }

            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.memory(snapshot.data!),
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black87,
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '金額: ¥${(transaction.amount / 100).toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '日付: ${DateFormat('yyyy年M月d日').format(transaction.timestamp)}',
                style: const TextStyle(color: Colors.white70),
              ),
              if (transaction.note != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '店舗: ${transaction.note}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Uint8List> _loadPhoto(WidgetRef ref) async {
    final repository = ref.read(receiptPhotoRepositoryProvider);
    final encryptionService = ref.read(photoEncryptionServiceProvider);

    final encryptedData = await repository.load(photoHash);
    return await encryptionService.decrypt(encryptedData);
  }

  Future<void> _sharePhoto(BuildContext context, WidgetRef ref) async {
    // TODO: 实现分享功能
  }
}
```

---

## 测试策略

### 单元测试

```dart
// test/unit/application/ocr/receipt_parser_test.dart

void main() {
  late ReceiptParser parser;

  setUp(() {
    parser = ReceiptParser();
  });

  group('ReceiptParser - Amount Extraction', () {
    test('提取合计金额（日语）', () {
      final text = '''
        吉野家
        2026年2月3日
        牛丼 並 ¥380
        味噌汁 ¥100
        合計 ¥480
      ''';

      final result = parser.parse(text);

      expect(result.amount, 480);
    });

    test('提取合计金额（英语）', () {
      final text = '''
        McDonald's
        2026/2/3
        Big Mac ¥390
        French Fries ¥150
        TOTAL ¥540
      ''';

      final result = parser.parse(text);

      expect(result.amount, 540);
    });

    test('提取带逗号的金额', () {
      final text = '''
        ヨドバシカメラ
        2026.02.03
        合計 ¥12,800円
      ''';

      final result = parser.parse(text);

      expect(result.amount, 12800);
    });

    test('未找到金额时返回null', () {
      final text = '''
        吉野家
        2026年2月3日
      ''';

      final result = parser.parse(text);

      expect(result.amount, null);
    });
  });

  group('ReceiptParser - Date Extraction', () {
    test('提取日期（YYYY年MM月DD日）', () {
      final text = '2026年2月3日';

      final result = parser.parse(text);

      expect(result.date, DateTime(2026, 2, 3));
    });

    test('提取日期（YYYY/MM/DD）', () {
      final text = '2026/02/03';

      final result = parser.parse(text);

      expect(result.date, DateTime(2026, 2, 3));
    });

    test('提取日期（YY/MM/DD）', () {
      final text = '26/02/03';

      final result = parser.parse(text);

      expect(result.date, DateTime(2026, 2, 3));
    });

    test('未找到日期时返回null', () {
      final text = '吉野家 ¥480';

      final result = parser.parse(text);

      expect(result.date, null);
    });
  });

  group('ReceiptParser - Merchant Extraction', () {
    test('提取商家名称（第一行）', () {
      final text = '''
        吉野家
        2026年2月3日
        合計 ¥480
      ''';

      final result = parser.parse(text);

      expect(result.merchant, '吉野家');
    });

    test('跳过日期和金额行', () {
      final text = '''
        2026年2月3日
        吉野家
        合計 ¥480
      ''';

      final result = parser.parse(text);

      expect(result.merchant, '吉野家');
    });

    test('未找到商家时返回null', () {
      final text = '''
        2026年2月3日
        ¥480
        合計
      ''';

      final result = parser.parse(text);

      expect(result.merchant, null);
    });
  });
}

// test/unit/infrastructure/ml/merchant_database_test.dart

void main() {
  late MerchantDatabase database;

  setUp(() {
    database = MerchantDatabase();
  });

  group('MerchantDatabase', () {
    test('精确匹配商家', () {
      final result = database.findMerchant('セブンイレブン');

      expect(result, isNotNull);
      expect(result!.merchantName, 'セブンイレブン');
      expect(result.categoryId, 'food_groceries');
      expect(result.ledgerType, LedgerType.survival);
      expect(result.matchType, MatchType.exact);
    });

    test('别名匹配商家', () {
      final result = database.findMerchant('7-ELEVEN');

      expect(result, isNotNull);
      expect(result!.merchantName, 'セブンイレブン');
      expect(result.matchType, MatchType.alias);
    });

    test('模糊匹配商家', () {
      final result = database.findMerchant('セブン');

      expect(result, isNotNull);
      expect(result!.merchantName, 'セブンイレブン');
      expect(result.matchType, MatchType.fuzzy);
      expect(result.confidence, lessThan(0.95));  // 置信度降低
    });

    test('未找到商家返回null', () {
      final result = database.findMerchant('不存在的商家');

      expect(result, null);
    });
  });
}
```

### Widget测试

```dart
// test/features/ocr/presentation/screens/ocr_scan_screen_test.dart

void main() {
  testWidgets('OCR扫描界面显示正确', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: OCRScanScreen(),
        ),
      ),
    );

    // 验证UI元素
    expect(find.text('レシートを撮影'), findsOneWidget);
    expect(find.text('カメラで撮影'), findsOneWidget);
    expect(find.text('ギャラリーから選択'), findsOneWidget);
  });

  testWidgets('点击相机按钮触发扫描', (tester) async {
    // TODO: 实现测试
  });
}
```

### 集成测试

```dart
// integration_test/ocr_flow_test.dart

void main() {
  testWidgets('完整OCR流程测试', (tester) async {
    // 1. 启动应用
    // 2. 导航到OCR扫描界面
    // 3. 选择测试收据照片
    // 4. 验证识别结果
    // 5. 修正并保存交易
    // 6. 验证交易已创建
  });
}
```

---

## 性能优化

### 1. 图像处理优化

```dart
// 使用Isolate进行图像处理，避免阻塞UI线程
Future<File> processImageInBackground(XFile image) async {
  return await compute(_processImage, image);
}

static File _processImage(XFile image) {
  // 在独立的Isolate中执行耗时的图像处理
  // ...
}
```

### 2. OCR识别优化

- **图像尺寸控制**: 限制最大分辨率为2048px，减少OCR处理时间
- **预处理优化**: 使用高效的二值化算法
- **识别区域限制**: 如果可能，只识别收据的关键区域

### 3. 照片存储优化

```dart
// 压缩照片以节省存储空间
Future<Uint8List> compressImage(Uint8List imageBytes) async {
  final image = img.decodeImage(imageBytes);
  if (image == null) return imageBytes;

  // 压缩为JPEG，质量85
  final compressed = img.encodeJpg(image, quality: 85);

  return Uint8List.fromList(compressed);
}
```

### 4. 缓存策略

- **商家数据库**: 预加载到内存，避免重复读取
- **分类数据**: 使用Riverpod缓存Provider
- **照片缩略图**: 生成并缓存缩略图用于列表显示

---

## 总结

MOD-005 OCR扫描模块提供：

1. **高准确率OCR**: 金额>90%、日期>85%、商家>80%
2. **智能商家分类**: 500+日本商家数据库，自动匹配分类
3. **图像预处理**: 灰度化、对比度增强、二值化，提升识别率
4. **端到端加密**: AES-256-GCM加密存储收据照片
5. **用户友好**: 可视化确认界面，支持手动修正
6. **跨平台支持**: Android (ML Kit) + iOS (Vision Framework)

**开发优先级**: P1，预计7天完成。

**依赖模块**:
- ✅ MOD-001 (基础记账) - 交易创建
- ✅ MOD-003 (双轨账本) - 商家数据库
- ✅ MOD-006 (安全模块) - 照片加密

---

**文档维护**:
- 最后更新: 2026-02-03
- 维护者: 功能团队
- 版本: 1.0
