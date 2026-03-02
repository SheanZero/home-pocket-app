# MOD-004: OCR扫描模块 - 技术设计文档

**模块编号:** MOD-004
**文档版本:** 4.0
**创建日期:** 2026-02-03
**最后更新:** 2026-02-25
**预估工时:** 10天（后端实现）
**优先级:** P1（强烈建议）
**状态:** 前端 UI Stub 已实现，后端 OCR 管道待实现

---

## 目录

1. [模块概述](#模块概述)
2. [当前实现状态](#当前实现状态)
3. [四模块管道架构](#四模块管道架构)
4. [模块 A：图像预处理](#模块-a图像预处理-image-preprocessing)
5. [模块 B：文字识别引擎](#模块-b文字识别引擎-ocr-engine)
6. [模块 C：结构化提取](#模块-c结构化提取-information-extraction)
7. [模块 D：数据纠错与校验](#模块-d数据纠错与校验-validation)
8. [层次结构与目录](#层次结构与目录)
9. [导航流程](#导航流程)
10. [Provider 装配](#provider-装配)
11. [测试策略](#测试策略)
12. [性能优化](#性能优化)
13. [未来演进路线](#未来演进路线)

---

## 模块概述

### 业务价值

OCR扫描模块通过相机扫描纸质收据，自动识别金额、日期、商家信息，将纸质收据数字化，显著提升记账效率。

### 核心管道

```
拍照/选图 → [A]图像预处理 → [B]OCR识别 → [C]结构化提取 → [D]数据校验 → 确认页
```

四模块各自独立、可单独测试，通过 `ScanReceiptUseCase` 编排串联。

### 技术栈

```yaml
图像预处理: opencv_dart ^2.2.x        # OpenCV 全功能（边缘检测、透视矫正、自适应二值化）
OCR引擎:
  iOS: Apple Vision Framework         # VNRecognizeTextRequest via MethodChannel
  Android: ML Kit Text Recognition v2  # 原生 Kotlin 集成 via MethodChannel
相机/相册: image_picker ^1.1.x
状态管理: Riverpod 2.4+ (riverpod_annotation)
加密: 复用 lib/infrastructure/crypto/services/photo_encryption_service.dart
```

> **关键决策：不使用 Flutter OCR 插件包**
>
> `google_mlkit_text_recognition` 等 Flutter 插件在 Apple Silicon 模拟器上 [无法构建](https://github.com/googlesamples/mlkit/issues/810)，
> 会阻塞整个应用在模拟器上的开发。
> 本方案改用 **MethodChannel + 原生代码** 直接调用平台 OCR API，
> 既保证模拟器兼容性，又获得最佳日语识别效果。

### 准确率目标

| 字段 | MVP 目标 | 正式版目标 | 备注 |
|------|----------|-----------|------|
| 金额 | >90% | >98% | 启发式规则 → CORD 模型 |
| 日期 | >85% | >95% | 正则匹配 → 模型辅助 |
| 商家 | >80% | >90% | 首行提取 → NER 模型 |

---

## 当前实现状态

### 已实现（Phase 1 - UI Stub）

| 组件 | 文件 | 状态 |
|------|------|------|
| OcrScannerScreen | `lib/features/accounting/presentation/screens/ocr_scanner_screen.dart` | ✅ Stub UI |
| TransactionConfirmScreen | `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` | ✅ 已实现 |
| EntryModeSwitcher | `lib/features/accounting/presentation/widgets/entry_mode_switcher.dart` | ✅ 已实现 |
| MerchantDatabase | `lib/infrastructure/ml/merchant_database.dart` | ✅ 已实现 |
| l10n 基础 keys | `lib/l10n/app_{ja,zh,en}.arb` | ✅ ocrScanTitle, ocrHint |

### 待实现（Phase 2 - 后端管道）

| 模块 | 层次 | 组件 |
|------|------|------|
| A 图像预处理 | Infrastructure | `ImagePreprocessor` (opencv_dart) |
| B OCR 引擎 | Infrastructure | `OCRService` 抽象 + iOS/Android 原生实现 |
| C 结构化提取 | Application | `ReceiptParser` (启发式规则) |
| D 数据校验 | Application | `ReceiptValidator` (财务逻辑) |
| 编排 | Application | `ScanReceiptUseCase` |
| 照片加密 | Application | `SaveReceiptPhotoUseCase` |
| 数据持久化 | Data | `receipt_photos` 表 + DAO + Repository |

---

## 四模块管道架构

```
                          ScanReceiptUseCase（编排层）
                    ┌──────────────────────────────────────┐
                    │                                      │
 image_picker       │  ┌──────────┐    ┌──────────┐       │
 ─────────────►     │  │  模块 A  │    │  模块 B  │       │
 Uint8List          │  │ 图像预处理│───►│ OCR 引擎 │       │
                    │  └──────────┘    └────┬─────┘       │
                    │                       │              │
                    │                       ▼              │
                    │  ┌──────────┐    ┌──────────┐       │
                    │  │  模块 D  │◄───│  模块 C  │       │
                    │  │ 数据校验  │    │ 结构化提取│       │
                    │  └────┬─────┘    └──────────┘       │
                    │       │                              │
                    └───────┼──────────────────────────────┘
                            ▼
                    OcrScanResult
                            │
              ┌─────────────┼─────────────┐
              ▼             ▼             ▼
        MerchantDB    SavePhoto    TransactionConfirmScreen
        商家匹配      照片加密           确认页
```

### 数据流类型

```dart
// 模块 A 输出
typedef PreprocessedImage = File; // 矫正后的二值化图像临时文件

// 模块 B 输出
class OCRResult {
  final String text;                    // 全文
  final List<OCRLine> lines;            // 带位置信息的行
}

class OCRLine {
  final String text;
  final Rect boundingBox;               // 行在图像中的位置 (归一化 0.0~1.0)
  final double confidence;
}

// 模块 C 输出
class ParsedReceiptData {
  final int? amount;                    // 总金额（日元整数）
  final DateTime? date;
  final String? merchant;
  final List<ReceiptLineItem>? items;   // 明细行（可选，用于模块 D 校验）
}

class ReceiptLineItem {
  final String name;
  final int unitPrice;
  final int quantity;
  final int subtotal;
}

// 模块 D 输出
class ValidatedReceiptData {
  final int? amount;
  final DateTime? date;
  final String? merchant;
  final double confidence;              // 整体置信度 0.0~1.0
  final List<ValidationWarning> warnings;
}
```

---

## 模块 A：图像预处理 (Image Preprocessing)

### 目标

将手机拍摄的"烂图"变成"标准图"——矫正倾斜、消除阴影、突出文字。

### 技术方案：opencv_dart

使用 [opencv_dart](https://pub.dev/packages/opencv_dart) v2.2.x，纯 Dart FFI 调用 OpenCV C++ 库。
支持 iOS 模拟器 (arm64 + x64)、Android、桌面。

### 处理流程

```
原始图像 (Uint8List)
    │
    ▼  Step 1: 解码
    Mat (BGR)
    │
    ▼  Step 2: 缩放（长边 ≤ 2048px）
    Mat (resized)
    │
    ▼  Step 3: 边缘检测与透视矫正
    │  3a. 灰度化 → cvtColor(COLOR_BGR2GRAY)
    │  3b. 高斯模糊 → GaussianBlur(ksize: 5)
    │  3c. Canny 边缘检测 → Canny(threshold1: 50, threshold2: 150)
    │  3d. 轮廓检测 → findContours → 找最大四边形
    │  3e. 四点透视变换 → getPerspectiveTransform + warpPerspective
    Mat (矫正后)
    │
    ▼  Step 4: 光线补偿与去噪
    │  4a. 转灰度 → cvtColor(COLOR_BGR2GRAY)
    │  4b. 自适应二值化 → adaptiveThreshold(
    │       maxValue: 255,
    │       adaptiveMethod: ADAPTIVE_THRESH_GAUSSIAN_C,
    │       thresholdType: THRESH_BINARY,
    │       blockSize: 15,
    │       C: 10
    │      )
    Mat (二值化)
    │
    ▼  Step 5: 锐化（增强褪色热敏纸文字）
    │  unsharpMask: GaussianBlur → addWeighted(src, 1.5, blur, -0.5)
    Mat (最终)
    │
    ▼  Step 6: 编码输出
    File (PNG 临时文件)
```

### 实现

```dart
// lib/infrastructure/ml/image_preprocessor.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class ImagePreprocessor {
  static const int _maxDimension = 2048;

  /// 完整预处理管道。在 Isolate 中执行。
  /// 返回矫正后的二值化图像临时文件路径，失败返回 null。
  Future<File?> process(Uint8List imageBytes) async {
    return Isolate.run(() => _processSync(imageBytes));
  }

  static File? _processSync(Uint8List bytes) {
    // 1. 解码
    final mat = cv.imdecode(bytes, cv.IMREAD_COLOR);
    if (mat.isEmpty) return null;

    // 2. 缩放
    final resized = _resize(mat);

    // 3. 边缘检测 + 透视矫正
    final corrected = _perspectiveCorrect(resized) ?? resized;

    // 4. 灰度化 + 自适应二值化
    final gray = cv.cvtColor(corrected, cv.COLOR_BGR2GRAY);
    final binary = cv.adaptiveThreshold(
      gray, 255,
      cv.ADAPTIVE_THRESH_GAUSSIAN_C,
      cv.THRESH_BINARY,
      blockSize: 15, C: 10,
    );

    // 5. 锐化
    final sharpened = _sharpen(binary);

    // 6. 编码输出
    final tempDir = Directory.systemTemp.createTempSync('ocr_');
    final outFile = File('${tempDir.path}/processed.png');
    cv.imwrite(outFile.path, sharpened);

    return outFile;
  }

  static cv.Mat _resize(cv.Mat src) {
    final maxDim = src.width > src.height ? src.width : src.height;
    if (maxDim <= _maxDimension) return src;
    final scale = _maxDimension / maxDim;
    return cv.resize(src, (src.width * scale).round(), (src.height * scale).round());
  }

  static cv.Mat? _perspectiveCorrect(cv.Mat src) {
    // 3a-3c: 灰度 → 模糊 → Canny
    final gray = cv.cvtColor(src, cv.COLOR_BGR2GRAY);
    final blurred = cv.gaussianBlur(gray, (5, 5), 0);
    final edges = cv.canny(blurred, 50, 150);

    // 3d: 找最大四边形轮廓
    final contours = cv.findContours(edges, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE);
    // 按面积排序，找最大近似四边形
    // ...（详细实现：approxPolyDP，筛选4点凸包）

    // 3e: 四点透视变换
    // final M = cv.getPerspectiveTransform(srcPoints, dstPoints);
    // return cv.warpPerspective(src, M, dstSize);

    return null; // 未找到有效四边形时返回 null，跳过矫正
  }

  static cv.Mat _sharpen(cv.Mat src) {
    final blurred = cv.gaussianBlur(src, (0, 0), sigmaX: 3);
    return cv.addWeighted(src, 1.5, blurred, -0.5, 0);
  }
}
```

### 降级策略

当透视矫正失败（无法检测到有效四边形）时，跳过 Step 3，直接执行 Step 4-5。
这确保即使拍摄角度不理想，仍能输出可用图像。

---

## 模块 B：文字识别引擎 (OCR Engine)

### 目标

提取图片中的文字及其位置信息（Bounding Box），支持日语、中文、英语。

### 技术方案：MethodChannel + 原生 API

**为什么不用 Flutter OCR 插件：**

| 方案 | iOS 模拟器 | 日语支持 | 控制力 | 风险 |
|------|-----------|----------|--------|------|
| `google_mlkit_text_recognition` | ❌ 无法构建 | ✅ | 中 | **阻塞所有开发** |
| `flutter_native_ocr` (v0.1.0) | ⚠️ 未验证 | ✅ | 低 | 版本过早 |
| **MethodChannel + 原生代码** | ✅ | ✅ | **高** | 需写原生代码 |

选择 MethodChannel 方案：一次写好，永久可控。

### 抽象接口

```dart
// lib/infrastructure/ml/ocr/ocr_service.dart

import 'dart:io';

class OCRLine {
  final String text;
  final double x, y, width, height;  // 归一化坐标 (0.0~1.0)
  final double confidence;

  const OCRLine({
    required this.text,
    required this.x, required this.y,
    required this.width, required this.height,
    this.confidence = 1.0,
  });

  /// 行中心点 Y 坐标（用于位置权重判断）
  double get centerY => y + height / 2;
}

class OCRResult {
  final String text;
  final List<OCRLine> lines;

  const OCRResult({required this.text, required this.lines});
  static const empty = OCRResult(text: '', lines: []);

  bool get isEmpty => text.isEmpty;
}

abstract class OCRService {
  Future<OCRResult> recognizeText(File imageFile);
  void dispose();
}
```

### iOS 实现（Apple Vision Framework）

```swift
// ios/Runner/OcrChannel.swift

import Flutter
import Vision

class OcrChannel {
    static let channelName = "com.homepocket/ocr"

    static func register(with messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
        channel.setMethodCallHandler { call, result in
            guard call.method == "recognizeText",
                  let args = call.arguments as? [String: Any],
                  let path = args["path"] as? String else {
                result(FlutterMethodNotImplemented)
                return
            }
            recognizeText(path: path, result: result)
        }
    }

    private static func recognizeText(path: String, result: @escaping FlutterResult) {
        guard let image = CGImage.load(from: URL(fileURLWithPath: path)) else {
            result(FlutterError(code: "LOAD_FAILED", message: "Cannot load image", details: nil))
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                result(FlutterError(code: "OCR_ERROR", message: error.localizedDescription, details: nil))
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                result(["text": "", "lines": [[String: Any]]()])
                return
            }

            var lines = [[String: Any]]()
            var fullText = [String]()

            for obs in observations {
                guard let candidate = obs.topCandidates(1).first else { continue }
                let box = obs.boundingBox  // Vision: 左下角原点，归一化
                lines.append([
                    "text": candidate.string,
                    "x": box.origin.x,
                    "y": 1.0 - box.origin.y - box.height,  // 转换为左上角原点
                    "width": box.width,
                    "height": box.height,
                    "confidence": candidate.confidence,
                ])
                fullText.append(candidate.string)
            }

            result(["text": fullText.joined(separator: "\n"), "lines": lines])
        }

        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["ja", "zh-Hans", "zh-Hant", "en"]
        request.usesLanguageCorrection = true

        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do { try handler.perform([request]) }
            catch { DispatchQueue.main.async {
                result(FlutterError(code: "OCR_ERROR", message: error.localizedDescription, details: nil))
            }}
        }
    }
}
```

### Android 实现（ML Kit Text Recognition v2）

```kotlin
// android/app/src/main/kotlin/.../OcrChannel.kt

class OcrChannel(private val messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "com.homepocket/ocr"

        fun register(messenger: BinaryMessenger) {
            val channel = MethodChannel(messenger, CHANNEL)
            channel.setMethodCallHandler(OcrChannel(messenger))
        }
    }

    private val recognizer = TextRecognition.getClient(
        JapaneseTextRecognizerOptions.Builder().build()
    )

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "recognizeText") {
            result.notImplemented()
            return
        }

        val path = call.argument<String>("path") ?: run {
            result.error("INVALID_ARGS", "Missing 'path'", null)
            return
        }

        val image = InputImage.fromFilePath(context, Uri.fromFile(File(path)))
        recognizer.process(image)
            .addOnSuccessListener { visionText ->
                val lines = mutableListOf<Map<String, Any>>()
                val imageWidth = visionText.width.toDouble()
                val imageHeight = visionText.height.toDouble()

                for (block in visionText.textBlocks) {
                    for (line in block.lines) {
                        val box = line.boundingBox ?: continue
                        lines.add(mapOf(
                            "text" to line.text,
                            "x" to box.left / imageWidth,
                            "y" to box.top / imageHeight,
                            "width" to box.width() / imageWidth,
                            "height" to box.height() / imageHeight,
                            "confidence" to (line.confidence ?: 1.0),
                        ))
                    }
                }

                result.success(mapOf(
                    "text" to visionText.text,
                    "lines" to lines,
                ))
            }
            .addOnFailureListener { e ->
                result.error("OCR_ERROR", e.localizedDescription, null)
            }
    }
}
```

### Dart 端统一封装

```dart
// lib/infrastructure/ml/ocr/platform_ocr_service.dart

import 'dart:io';
import 'package:flutter/services.dart';
import 'ocr_service.dart';

/// 通过 MethodChannel 调用平台原生 OCR。
/// iOS: Apple Vision Framework
/// Android: ML Kit Text Recognition v2 (Japanese)
class PlatformOcrService implements OCRService {
  static const _channel = MethodChannel('com.homepocket/ocr');

  @override
  Future<OCRResult> recognizeText(File imageFile) async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'recognizeText',
      {'path': imageFile.path},
    );

    if (result == null) return OCRResult.empty;

    final text = result['text'] as String? ?? '';
    final rawLines = result['lines'] as List? ?? [];

    final lines = rawLines.cast<Map>().map((m) => OCRLine(
      text: m['text'] as String,
      x: (m['x'] as num).toDouble(),
      y: (m['y'] as num).toDouble(),
      width: (m['width'] as num).toDouble(),
      height: (m['height'] as num).toDouble(),
      confidence: (m['confidence'] as num?)?.toDouble() ?? 1.0,
    )).toList();

    return OCRResult(text: text, lines: lines);
  }

  @override
  void dispose() {}
}
```

---

## 模块 C：结构化提取 (Information Extraction)

### 目标

从 OCR 结果中提取总金额、日期、商家名称。MVP 使用启发式规则（95% 收据遵循固定格式），
正式版演进为 CORD 训练模型。

### 提取策略概览

```
OCRResult (text + lines with positions)
    │
    ├─► _extractAmount()    → int?       关键词优先 + 位置权重 + 最大值兜底
    ├─► _extractDate()      → DateTime?  正则暴力匹配，取最上面的
    ├─► _extractMerchant()  → String?    首个非噪声行
    └─► _extractLineItems() → List?      可选，用于模块 D 校验
```

### 金额提取（最关键）

**三层优先级策略：**

```
Phase 1: 关键词邻近匹配（最可靠）
    税込合計 > 合計 > 小計 > TOTAL > 円 suffix
    ↓ 未命中

Phase 2: 位置权重 + 最大值原则
    ① 筛选包含 ¥/￥ 或纯数字的行
    ② 排除噪声行（お釣り、釣銭、税、消費税、内税、外税）
    ③ 位置权重：Y > 50%（下半部分）的行权重 ×1.5
    ④ 在高权重行的上下 2 行内，取最大数字
    ↓ 未命中

Phase 3: 全文最大 ¥ 金额兜底
    扫描全文所有 ¥/￥ 后的数字，取最大值
```

```dart
// lib/application/ocr/receipt_parser.dart

class ReceiptParser {
  // Phase 1: 关键词邻近
  static final _keywordPatterns = [
    RegExp(r'税込\s*合[計计]\s*[¥￥]?\s*([\d,]+)'),
    RegExp(r'合[計计]\s*[¥￥]?\s*([\d,]+)'),
    RegExp(r'小[計计]\s*[¥￥]?\s*([\d,]+)'),
    RegExp(r'TOTAL\s*[¥￥]?\s*([\d,]+)', caseSensitive: false),
    RegExp(r'([\d,]+)\s*円'),
  ];

  // Phase 2: 噪声排除
  static final _excludedKeywords = RegExp(r'(お釣り|釣銭|税\s|消費税|内税|外税)');

  int? _extractAmount(List<OCRLine> lines) {
    final fullText = lines.map((l) => l.text).join('\n');

    // Phase 1: 关键词邻近
    for (final pattern in _keywordPatterns) {
      final match = pattern.firstMatch(fullText);
      if (match != null) {
        final parsed = _parseNumber(match.group(1)!);
        if (parsed != null && parsed > 0) return parsed;
      }
    }

    // Phase 2: 位置权重 + 最大值
    int? best;
    double bestScore = 0;
    final yenPattern = RegExp(r'[¥￥]\s*([\d,]+)');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_excludedKeywords.hasMatch(line.text)) continue;

      for (final match in yenPattern.allMatches(line.text)) {
        final parsed = _parseNumber(match.group(1)!);
        if (parsed == null || parsed <= 0) continue;

        // 位置权重：下半部分 ×1.5
        final posWeight = line.centerY > 0.5 ? 1.5 : 1.0;
        final score = parsed * posWeight;

        if (score > bestScore) {
          bestScore = score;
          best = parsed;
        }
      }
    }

    return best;
  }
}
```

### 日期提取

```dart
DateTime? _extractDate(List<OCRLine> lines) {
  final patterns = [
    // 日本語
    RegExp(r'(\d{4})年(\d{1,2})月(\d{1,2})日'),
    // ISO / 日本标准
    RegExp(r'(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})'),
    // 短年份
    RegExp(r'(\d{2})[/\-.](\d{1,2})[/\-.](\d{1,2})'),
    // 英文月份 (15-Feb-2026)
    RegExp(r'(\d{1,2})-(\w{3})-(\d{4})'),
  ];

  // 优先取最上面的匹配（打印时间通常在头部）
  for (final line in lines) {
    for (final pattern in patterns) {
      final match = pattern.firstMatch(line.text);
      if (match != null) {
        final date = _parseDate(match, pattern);
        if (date != null) return date;
      }
    }
  }
  return null;
}
```

### 商家提取

```dart
String? _extractMerchant(List<OCRLine> lines) {
  // 第一个非噪声行通常是店名
  final datePattern = RegExp(r'^\d{2,4}[/\-.]?\d{1,2}[/\-.]?\d{1,2}');
  final amountPattern = RegExp(r'^[¥￥]?\s*[\d,]+\s*(円)?$');
  final keywordPattern = RegExp(
    r'^(合[計计]|小[計计]|TOTAL|税込|お釣り|内税|外税|消費税|No\.|TEL)',
    caseSensitive: false,
  );

  for (final line in lines) {
    final text = line.text.trim();
    if (text.length < 2) continue;
    if (datePattern.hasMatch(text)) continue;
    if (amountPattern.hasMatch(text)) continue;
    if (keywordPattern.hasMatch(text)) continue;
    if (RegExp(r'^[\d,.\s]+$').hasMatch(text)) continue;
    return text;
  }
  return null;
}
```

### 明细行提取（可选，供模块 D 使用）

```dart
/// 尝试提取商品明细（品名 + 金额）
/// 格式示例: "コカ・コーラ    ¥150" 或 "コーラ 3x50  150"
List<ReceiptLineItem> _extractLineItems(List<OCRLine> lines) {
  final itemPattern = RegExp(r'(.+?)\s+[¥￥]?\s*([\d,]+)\s*$');
  final items = <ReceiptLineItem>[];

  for (final line in lines) {
    // 跳过关键词行
    if (_isKeywordLine(line.text)) continue;
    final match = itemPattern.firstMatch(line.text);
    if (match != null) {
      final name = match.group(1)!.trim();
      final price = _parseNumber(match.group(2)!);
      if (price != null && price > 0 && name.isNotEmpty) {
        items.add(ReceiptLineItem(name: name, unitPrice: price, quantity: 1, subtotal: price));
      }
    }
  }

  return items;
}
```

---

## 模块 D：数据纠错与校验 (Validation)

### 目标

利用财务逻辑修正 OCR 错误，提供置信度评分。

### 校验规则

```dart
// lib/application/ocr/receipt_validator.dart

class ReceiptValidator {
  ValidatedReceiptData validate(ParsedReceiptData parsed) {
    final warnings = <ValidationWarning>[];
    double confidence = 1.0;

    // Rule 1: 金额合理性检查
    if (parsed.amount != null) {
      if (parsed.amount! <= 0) {
        warnings.add(ValidationWarning.negativeAmount);
        confidence *= 0.3;
      } else if (parsed.amount! > 1000000) {
        // 超过 100万円 → 可能是 OCR 错误（多读了一位）
        warnings.add(ValidationWarning.unusuallyLargeAmount);
        confidence *= 0.5;
      }
    } else {
      confidence *= 0.4;  // 未提取到金额
    }

    // Rule 2: 日期合理性检查
    if (parsed.date != null) {
      final now = DateTime.now();
      if (parsed.date!.isAfter(now.add(const Duration(days: 1)))) {
        warnings.add(ValidationWarning.futureDate);
        confidence *= 0.5;
      } else if (parsed.date!.isBefore(DateTime(2000))) {
        warnings.add(ValidationWarning.ancientDate);
        confidence *= 0.5;
      }
    } else {
      confidence *= 0.8;  // 日期缺失但不严重
    }

    // Rule 3: 明细交叉校验（当有明细时）
    if (parsed.items != null && parsed.items!.isNotEmpty && parsed.amount != null) {
      final itemsTotal = parsed.items!.fold<int>(0, (sum, i) => sum + i.subtotal);
      // 允许 ±10% 误差（税费可能未被提取）
      final ratio = itemsTotal / parsed.amount!;
      if (ratio < 0.7 || ratio > 1.3) {
        warnings.add(ValidationWarning.itemsTotalMismatch);
        confidence *= 0.6;
      } else if (ratio > 0.9 && ratio < 1.1) {
        confidence *= 1.1;  // 明细与合计吻合 → 提升置信度
      }
    }

    return ValidatedReceiptData(
      amount: parsed.amount,
      date: parsed.date,
      merchant: parsed.merchant,
      confidence: confidence.clamp(0.0, 1.0),
      warnings: warnings,
    );
  }
}

enum ValidationWarning {
  negativeAmount,
  unusuallyLargeAmount,
  futureDate,
  ancientDate,
  itemsTotalMismatch,
}
```

---

## 层次结构与目录

### 5 层 Clean Architecture 分层

```
┌──────────────────────────────────────────────────────────────────────┐
│  Presentation  lib/features/accounting/presentation/                  │
│  ├── screens/ocr_scanner_screen.dart          ← 已实现 stub          │
│  ├── screens/transaction_confirm_screen.dart  ← 已实现               │
│  ├── widgets/entry_mode_switcher.dart         ← 已实现               │
│  └── providers/ocr_providers.dart             ← 待实现               │
├──────────────────────────────────────────────────────────────────────┤
│  Application  lib/application/ocr/              ← 待实现              │
│  ├── scan_receipt_use_case.dart                                       │
│  ├── receipt_parser.dart                       ← 模块 C              │
│  ├── receipt_validator.dart                    ← 模块 D              │
│  └── save_receipt_photo_use_case.dart                                 │
├──────────────────────────────────────────────────────────────────────┤
│  Domain  lib/features/accounting/domain/                              │
│  ├── models/transaction.dart                  ← 含 photoHash 字段    │
│  └── models/category.dart                                            │
├──────────────────────────────────────────────────────────────────────┤
│  Infrastructure  lib/infrastructure/ml/         ← 待实现              │
│  ├── ocr/                                                            │
│  │   ├── ocr_service.dart                     ← 抽象接口（含 OCRLine）│
│  │   └── platform_ocr_service.dart            ← MethodChannel 封装   │
│  ├── image_preprocessor.dart                  ← 模块 A (opencv_dart) │
│  └── merchant_database.dart                   ← 已实现               │
├──────────────────────────────────────────────────────────────────────┤
│  Native                                                              │
│  ├── ios/Runner/OcrChannel.swift              ← Vision Framework     │
│  └── android/.../OcrChannel.kt                ← ML Kit               │
├──────────────────────────────────────────────────────────────────────┤
│  Data  lib/data/                               ← 待实现              │
│  ├── tables/receipt_photos_table.dart                                 │
│  ├── daos/receipt_photo_dao.dart                                      │
│  └── repositories/receipt_photo_repository_impl.dart                  │
└──────────────────────────────────────────────────────────────────────┘
```

### 目标目录结构

```
# 新增依赖 (pubspec.yaml)
opencv_dart: ^2.2.0
image_picker: ^1.1.2

# Infrastructure 层
lib/infrastructure/ml/
├── ocr/
│   ├── ocr_service.dart           # 抽象 OCRService + OCRLine + OCRResult
│   └── platform_ocr_service.dart  # MethodChannel 调用原生 OCR
├── image_preprocessor.dart        # opencv_dart 预处理管道
├── merchant_database.dart         # 已实现（与 MOD-002 共享）
└── tflite_classifier.dart         # 未来 CORD 模型推理

# Application 层
lib/application/ocr/
├── scan_receipt_use_case.dart     # 编排：预处理 → OCR → 解析 → 校验
├── receipt_parser.dart            # 模块 C：启发式结构化提取
├── receipt_validator.dart         # 模块 D：财务逻辑校验
└── save_receipt_photo_use_case.dart

# Presentation 层（Provider）
lib/features/accounting/presentation/providers/
└── ocr_providers.dart             # Riverpod provider 装配

# Native 代码
ios/Runner/OcrChannel.swift        # iOS Vision Framework
android/app/.../OcrChannel.kt     # Android ML Kit

# Data 层
lib/data/tables/receipt_photos_table.dart
lib/data/daos/receipt_photo_dao.dart
lib/data/repositories/receipt_photo_repository_impl.dart
```

---

## 导航流程

### 完整用户流程

```
Home Screen
    │
    ▼  [+ 记账]
TransactionEntryScreen (Manual)
    │
    │  EntryModeSwitcher → tap OCR tab (pushReplacement)
    ▼
OcrScannerScreen
    │
    │  [快门/相册] → ScanReceiptUseCase
    │  ┌────────────────────────────────────────────┐
    │  │ 1. image_picker 获取图像 (Uint8List)       │
    │  │ 2. 模块 A: ImagePreprocessor.process()     │
    │  │    → 边缘检测 → 透视矫正 → 二值化 → 锐化  │
    │  │ 3. 模块 B: OCRService.recognizeText()      │
    │  │    → 文字 + 位置 (OCRLine[])                │
    │  │ 4. 模块 C: ReceiptParser.parse()           │
    │  │    → 金额/日期/商家 (启发式规则)           │
    │  │ 5. 模块 D: ReceiptValidator.validate()     │
    │  │    → 置信度 + 警告                          │
    │  │ 6. MerchantDatabase.findMerchant()         │
    │  │    → 分类匹配                               │
    │  │ 7. SaveReceiptPhotoUseCase.execute()        │
    │  │    → 加密存储 → photoHash                   │
    │  └────────────────────────────────────────────┘
    │
    │  识别成功 → Navigator.push
    ▼
TransactionConfirmScreen(
  bookId: bookId,
  amount: validatedAmount,           // 可编辑
  category: matchedCategory,         // 可编辑
  parentCategory: parentCategory,
  date: validatedDate,               // 可编辑
  initialMerchant: merchantName,     // 可编辑
  // photoHash, confidence, warnings
)
    │
    │  [确认记录] → CreateTransactionUseCase.execute()
    ▼
Navigator.popUntil(isFirst)
```

---

## Provider 装配

```dart
// lib/features/accounting/presentation/providers/ocr_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ocr_providers.g.dart';

/// OCRService — keepAlive，MethodChannel 无需反复创建
@Riverpod(keepAlive: true)
OCRService ocrService(Ref ref) {
  final service = PlatformOcrService();
  ref.onDispose(() => service.dispose());
  return service;
}

/// ImagePreprocessor — 无状态
@riverpod
ImagePreprocessor imagePreprocessor(Ref ref) {
  return ImagePreprocessor();
}

/// ReceiptParser — 无状态
@riverpod
ReceiptParser receiptParser(Ref ref) {
  return ReceiptParser();
}

/// ReceiptValidator — 无状态
@riverpod
ReceiptValidator receiptValidator(Ref ref) {
  return ReceiptValidator();
}

/// ScanReceiptUseCase — 编排所有模块
@riverpod
ScanReceiptUseCase scanReceiptUseCase(Ref ref) {
  return ScanReceiptUseCase(
    ocrService: ref.watch(ocrServiceProvider),
    preprocessor: ref.watch(imagePreprocessorProvider),
    parser: ref.watch(receiptParserProvider),
    validator: ref.watch(receiptValidatorProvider),
  );
}
```

---

## 测试策略

### 单元测试（TDD，模块隔离）

```
test/unit/application/ocr/
├── receipt_parser_test.dart        # 模块 C: 金额/日期/商家提取
├── receipt_validator_test.dart     # 模块 D: 校验逻辑
└── scan_receipt_use_case_test.dart  # 编排层（Mock A/B/C/D）

test/unit/infrastructure/ml/
├── image_preprocessor_test.dart    # 模块 A: 预处理输出验证
└── platform_ocr_service_test.dart  # 模块 B: MethodChannel Mock
```

#### 模块 C 测试重点（ReceiptParser）

```dart
group('extractAmount', () {
  // 关键词匹配
  test('提取 合計 ¥580',         ...);
  test('提取 税込合計 1,280',     ...);
  test('提取 小計 when no 合計', ...);
  test('提取 TOTAL $12.50',      ...);
  test('提取 580円',              ...);
  test('提取带逗号 ¥1,234,567',  ...);

  // 位置权重
  test('下半部分金额优先于上半部分', ...);
  test('关键词行附近的最大数字',    ...);

  // 噪声排除
  test('排除 お釣り 行',          ...);
  test('排除 消費税 行',          ...);

  // 兜底
  test('无关键词时取最大 ¥ 金额', ...);
  test('无金额时返回 null',       ...);
});

group('extractDate', () {
  test('YYYY年MM月DD日',          ...);
  test('YYYY/MM/DD',              ...);
  test('YYYY-MM-DD',              ...);
  test('YY/MM/DD 补全世纪',      ...);
  test('DD-MMM-YYYY (15-Feb-2026)', ...);
  test('多个日期取最上面的',       ...);
  test('拒绝无效日期 (2月30日)',   ...);
});

group('extractMerchant', () {
  test('第一个非噪声行',           ...);
  test('跳过日期行',               ...);
  test('跳过金额行',               ...);
  test('跳过关键词行',             ...);
  test('去除空白',                 ...);
});
```

#### 模块 D 测试重点（ReceiptValidator）

```dart
group('validate', () {
  test('正常数据 → 高置信度',            ...);
  test('金额为 0 → 警告 + 低置信度',     ...);
  test('金额超 100万 → 警告',            ...);
  test('未来日期 → 警告',                ...);
  test('2000年前日期 → 警告',            ...);
  test('明细合计与总额不符 → 警告',      ...);
  test('明细合计与总额吻合 → 提升置信度', ...);
});
```

### 覆盖率要求

- 目标 ≥80%
- 模块 C (ReceiptParser) 要求 ≥90%（核心业务逻辑）

---

## 性能优化

### 图像预处理（Isolate）

```dart
// opencv_dart 操作在 Isolate 中执行，避免阻塞 UI
Future<File?> process(Uint8List bytes) async {
  return Isolate.run(() => _processSync(bytes));
}
```

### 性能预算

| 阶段 | 预算 | 优化手段 |
|------|------|----------|
| 图像预处理 (A) | <1s | Isolate 并行，缩放至 2048px |
| OCR 识别 (B) | <2s | 原生 API，accuracy 模式 |
| 结构化提取 (C) | <50ms | 纯 Dart 正则，无 I/O |
| 数据校验 (D) | <10ms | 纯逻辑计算 |
| **总计** | **<3s** | |

### 照片存储优化

```dart
// 压缩后再加密
final compressed = img.encodeJpg(decoded, quality: 85);
final encrypted = await photoEncryptionService.encrypt(compressed);
```

### 缓存策略

- **商家数据库**: 进程内单例，预加载到内存
- **OCRService**: keepAlive，MethodChannel 复用
- **OpenCV**: opencv_dart 通过 FFI 直接调用，零开销

---

## 未来演进路线

### Phase 1: MVP（当前计划）

```
启发式规则提取 → 准确率 80-90%
├── 关键词匹配 + 正则
├── 位置权重
└── 财务逻辑校验
```

### Phase 2: CORD 模型集成

```
Key Information Extraction (KIE) 模型
├── 训练数据: CORD dataset (Consolidated Receipt Dataset)
│   └── 11,000+ 带标注收据图像
├── 模型: LayoutLMv3 或 Donut (document understanding transformer)
├── 推理: TFLite 量化模型，设备端运行
└── 目标准确率: >98% 金额，>95% 日期
```

```dart
// 未来 lib/infrastructure/ml/tflite_classifier.dart
class ReceiptKIEModel {
  /// CORD 训练的 KIE 模型，直接从图像提取结构化数据
  /// 不依赖 OCR 文字识别，端到端抽取
  Future<ParsedReceiptData> extract(File image) async {
    final interpreter = await Interpreter.fromAsset('receipt_kie.tflite');
    // ...
  }
}
```

### Phase 3: 用户反馈闭环

```
用户修正 → 记录到本地训练集 → 模型微调 → 提升准确率
├── RecordCorrectionUseCase（已有类似 voice 模块实现）
└── 增量学习或规则优化
```

---

## 总结

| 维度 | 设计决策 |
|------|----------|
| **预处理** | opencv_dart (边缘检测 → 透视矫正 → 自适应二值化 → 锐化) |
| **OCR 引擎** | MethodChannel: iOS Vision + Android ML Kit（不用 Flutter 插件） |
| **提取** | 启发式规则 (关键词 → 位置权重 → 最大值兜底 → 正则) |
| **校验** | 财务逻辑 (金额范围 → 日期合理性 → 明细交叉验证) |
| **架构** | 4 模块管道，模块间通过类型化数据流连接 |
| **模拟器** | ✅ 全部兼容（opencv_dart + Vision Framework 均支持模拟器） |
| **未来** | CORD 训练模型替换模块 C，端到端 KIE |

**开发优先级**: P1，预计 10 天完成后端实现。

**依赖模块**:
- ✅ MOD-001（基础记账）— CreateTransactionUseCase
- ✅ MOD-002（双轨账本）— MerchantDatabase
- ✅ MOD-006（安全模块）— PhotoEncryptionService

---

**文档维护**:
- v1.0: 2026-02-03 — 初始版本
- v2.0: 2026-02-06 — ARCH-008 重构
- v3.0: 2026-02-22 — 基于实际代码更新
- v4.0: 2026-02-25 — 重新设计：四模块管道架构，opencv_dart 预处理，MethodChannel OCR，启发式提取 + 财务校验，CORD 演进路线
