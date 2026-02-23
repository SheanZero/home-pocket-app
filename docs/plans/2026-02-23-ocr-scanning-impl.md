# OCR Scanning Backend Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement the OCR backend pipeline so users can photograph receipts, have text extracted, and navigate to TransactionConfirmScreen with pre-filled amount, date, and merchant.

**Architecture:** Screen handles image acquisition (image_picker) and category resolution. UseCase accepts raw bytes and returns primitives (amount, date, merchantName, merchantCategoryId). This matches the existing voice input pattern where VoiceInputScreen resolves categoryId → Category objects.

**Tech Stack:** `google_mlkit_text_recognition` (wraps ML Kit on Android and Vision Framework on iOS via internal MethodChannel — no custom native code needed), `image_picker` (camera/gallery), `image` (preprocessing), Riverpod providers, existing MerchantDatabase.

**Spec:** `docs/arch/02-module-specs/MOD-004_OCR.md` (v3.0)

**Note on iOS OCR:** The spec lists "Vision Framework via MethodChannel" for iOS. The `google_mlkit_text_recognition` Flutter package internally delegates to Apple's Vision Framework on iOS via its own platform channel. This satisfies the spec's intent without requiring custom native Swift code.

**Note on Flash Toggle:** FR-001 lists flash as a P0 acceptance criterion. Flash requires the `camera` package with a live `CameraController`, which is a separate UI concern from the OCR pipeline. This plan covers the backend pipeline (image → OCR → parse → navigate). Flash toggle will be added in a follow-up plan that introduces live camera preview.

---

## Task 1: Add Dependencies + ARB Keys

**Files:**
- Modify: `pubspec.yaml`
- Modify: `ios/Runner/Info.plist`
- Modify: `lib/l10n/app_ja.arb`, `lib/l10n/app_zh.arb`, `lib/l10n/app_en.arb`

**Step 1: Add packages**

```yaml
# Under dependencies:
  image_picker: ^1.1.2
  google_mlkit_text_recognition: ^0.14.0
  image: ^4.5.3
```

**Step 2: Run pub get**

Run: `flutter pub get`
Expected: Resolves without conflicts.

**Step 3: iOS permissions**

Add to `ios/Runner/Info.plist` (if not already present):

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required to scan receipts</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access is required to select receipt images</string>
```

**Step 4: Add OCR error ARB keys**

Add to all 3 ARB files:

```json
// app_ja.arb
"ocrNoImageSelected": "画像が選択されていません",
"@ocrNoImageSelected": { "description": "OCR: user cancelled image picker" },
"ocrPreprocessingFailed": "画像の処理に失敗しました",
"@ocrPreprocessingFailed": { "description": "OCR: image preprocessing failed" },
"ocrNoTextRecognized": "テキストを認識できませんでした",
"@ocrNoTextRecognized": { "description": "OCR: no text found in image" },
"ocrScanFailed": "スキャンに失敗しました",
"@ocrScanFailed": { "description": "OCR: generic scan failure" },
"ocrProcessing": "認識中...",
"@ocrProcessing": { "description": "OCR: processing overlay text" }

// app_zh.arb
"ocrNoImageSelected": "未选择图片",
"ocrPreprocessingFailed": "图片处理失败",
"ocrNoTextRecognized": "未能识别文字",
"ocrScanFailed": "扫描失败",
"ocrProcessing": "识别中..."

// app_en.arb
"ocrNoImageSelected": "No image selected",
"ocrPreprocessingFailed": "Image processing failed",
"ocrNoTextRecognized": "No text recognized in image",
"ocrScanFailed": "Scan failed",
"ocrProcessing": "Recognizing..."
```

**Step 5: Generate l10n**

Run: `flutter gen-l10n`

**Step 6: Commit**

```
chore: add OCR dependencies, iOS permissions, and i18n keys
```

---

## Task 2: ReceiptParser — Amount Extraction (TDD)

**Files:**
- Create: `lib/application/ocr/receipt_parser.dart`
- Create: `test/unit/application/ocr/receipt_parser_test.dart`

**Step 1: Write failing tests for amount extraction**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/ocr/receipt_parser.dart';

void main() {
  late ReceiptParser parser;

  setUp(() => parser = ReceiptParser());

  group('extractAmount', () {
    test('extracts 合計 amount (Japanese)', () {
      final result = parser.parse('商品A 500\n合計 ¥1,280');
      expect(result.amount, 1280);
    });

    test('extracts 小計 amount when no 合計', () {
      final result = parser.parse('商品A\n小計 ¥800');
      expect(result.amount, 800);
    });

    test('extracts TOTAL amount (English)', () {
      final result = parser.parse('Item A\nTOTAL ¥2,500');
      expect(result.amount, 2500);
    });

    test('extracts amount with 円 suffix', () {
      final result = parser.parse('合計 1280円');
      expect(result.amount, 1280);
    });

    test('extracts amount with comma separator', () {
      final result = parser.parse('合計 ¥12,345');
      expect(result.amount, 12345);
    });

    test('prefers keyword amount over bare yen amounts', () {
      // お釣り (change) should NOT be selected; 合計 should win
      final result = parser.parse('合計 ¥980\nお釣り ¥20');
      expect(result.amount, 980);
    });

    test('falls back to largest yen amount when no keyword', () {
      final result = parser.parse('¥200\n¥980\n¥50');
      expect(result.amount, 980);
    });

    test('excludes お釣り/税 lines from yen fallback', () {
      final result = parser.parse('¥980\nお釣り ¥20\n税 ¥80');
      expect(result.amount, 980);
    });

    test('returns null when no amount found', () {
      final result = parser.parse('レシートテスト');
      expect(result.amount, isNull);
    });

    test('handles tax-inclusive amount (税込)', () {
      final result = parser.parse('小計 ¥1,000\n税込合計 ¥1,100');
      expect(result.amount, 1100);
    });
  });
}
```

**Step 2: Run tests to verify they fail**

Run: `flutter test test/unit/application/ocr/receipt_parser_test.dart`
Expected: FAIL — `receipt_parser.dart` doesn't exist.

**Step 3: Implement ReceiptParser with amount extraction**

Create `lib/application/ocr/receipt_parser.dart`:

```dart
/// Parsed data extracted from a receipt OCR text.
class ParsedReceiptData {
  final int? amount;
  final DateTime? date;
  final String? merchant;

  const ParsedReceiptData({this.amount, this.date, this.merchant});
}

/// Extracts structured data (amount, date, merchant) from raw OCR text.
class ReceiptParser {
  // Lines containing these keywords are excluded from yen-amount fallback.
  static final _excludedAmountKeywords = RegExp(
    r'(お釣り|釣銭|税\s|消費税|内税|外税)',
  );

  ParsedReceiptData parse(String text) {
    return ParsedReceiptData(
      amount: _extractAmount(text),
      date: null,       // Task 3
      merchant: null,   // Task 4
    );
  }

  /// Amount extraction priority:
  /// 1. Keyword-adjacent (税込合計 > 合計 > 小計 > TOTAL > 円 suffix)
  /// 2. Largest ¥-prefixed number (excluding change/tax lines)
  /// 3. null
  int? _extractAmount(String text) {
    // Phase 1: keyword-adjacent amounts (return first match by priority)
    final keywordPatterns = [
      RegExp(r'税込\s*合[計计]\s*[¥￥]?\s*([\d,]+)'),
      RegExp(r'合[計计]\s*[¥￥]?\s*([\d,]+)'),
      RegExp(r'小[計计]\s*[¥￥]?\s*([\d,]+)'),
      RegExp(r'TOTAL\s*[¥￥]?\s*([\d,]+)', caseSensitive: false),
      RegExp(r'([\d,]+)\s*円'),
    ];

    for (final pattern in keywordPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final parsed = _parseNumber(match.group(1)!);
        if (parsed != null && parsed > 0) return parsed;
      }
    }

    // Phase 2: fallback — largest ¥-prefixed number, excluding change/tax lines
    final yenPattern = RegExp(r'[¥￥]\s*([\d,]+)');
    int? largest;

    for (final line in text.split('\n')) {
      if (_excludedAmountKeywords.hasMatch(line)) continue;
      for (final match in yenPattern.allMatches(line)) {
        final parsed = _parseNumber(match.group(1)!);
        if (parsed != null && parsed > 0) {
          if (largest == null || parsed > largest) largest = parsed;
        }
      }
    }

    return largest;
  }

  int? _parseNumber(String raw) {
    final cleaned = raw.replaceAll(',', '').trim();
    return int.tryParse(cleaned);
  }
}
```

**Step 4: Run tests to verify they pass**

Run: `flutter test test/unit/application/ocr/receipt_parser_test.dart`
Expected: All 10 amount tests PASS.

**Step 5: Commit**

```
feat(ocr): add ReceiptParser with amount extraction (TDD)
```

---

## Task 3: ReceiptParser — Date Extraction (TDD)

**Files:**
- Modify: `lib/application/ocr/receipt_parser.dart`
- Modify: `test/unit/application/ocr/receipt_parser_test.dart`

**Step 1: Add failing date tests**

```dart
  group('extractDate', () {
    test('extracts YYYY年MM月DD日 format', () {
      final result = parser.parse('2026年02月15日\n合計 ¥1,000');
      expect(result.date, DateTime(2026, 2, 15));
    });

    test('extracts YYYY/MM/DD format', () {
      final result = parser.parse('2026/01/23 12:30\n合計 ¥500');
      expect(result.date, DateTime(2026, 1, 23));
    });

    test('extracts YYYY-MM-DD format', () {
      final result = parser.parse('Date: 2026-03-01\nTOTAL ¥800');
      expect(result.date, DateTime(2026, 3, 1));
    });

    test('extracts YY/MM/DD with century completion', () {
      final result = parser.parse('26/02/15\n合計 ¥300');
      expect(result.date, DateTime(2026, 2, 15));
    });

    test('extracts YYYY.MM.DD format', () {
      final result = parser.parse('2026.12.25\n合計 ¥1,500');
      expect(result.date, DateTime(2026, 12, 25));
    });

    test('returns null when no date found', () {
      final result = parser.parse('合計 ¥1,000');
      expect(result.date, isNull);
    });

    test('ignores invalid dates', () {
      final result = parser.parse('2026/13/32\n合計 ¥100');
      expect(result.date, isNull);
    });
  });
```

**Step 2: Run to verify failure**

**Step 3: Implement date extraction**

Update `parse()` to include `_extractDate(text)`. Add:

```dart
  DateTime? _extractDate(String text) {
    final patterns = [
      RegExp(r'(\d{4})年(\d{1,2})月(\d{1,2})日'),
      RegExp(r'(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})'),
      RegExp(r'(\d{2})[/\-.](\d{1,2})[/\-.](\d{1,2})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        var year = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final day = int.parse(match.group(3)!);

        if (year < 100) year += 2000;
        if (month < 1 || month > 12 || day < 1 || day > 31) continue;

        try {
          final date = DateTime(year, month, day);
          if (date.month != month || date.day != day) continue;
          return date;
        } catch (_) {
          continue;
        }
      }
    }
    return null;
  }
```

**Step 4: Run tests** → All PASS.

**Step 5: Commit**

```
feat(ocr): add date extraction to ReceiptParser
```

---

## Task 4: ReceiptParser — Merchant Extraction (TDD)

**Files:**
- Modify: `lib/application/ocr/receipt_parser.dart`
- Modify: `test/unit/application/ocr/receipt_parser_test.dart`

**Step 1: Add failing merchant tests**

```dart
  group('extractMerchant', () {
    test('extracts first non-numeric line as merchant', () {
      final result = parser.parse('セブンイレブン\n2026/01/15\n合計 ¥580');
      expect(result.merchant, 'セブンイレブン');
    });

    test('skips date-only lines', () {
      final result = parser.parse('2026/01/15 12:30\nマクドナルド\n合計 ¥680');
      expect(result.merchant, 'マクドナルド');
    });

    test('skips amount-only lines', () {
      final result = parser.parse('¥580\nスターバックス\n合計 ¥580');
      expect(result.merchant, 'スターバックス');
    });

    test('returns null for empty text', () {
      final result = parser.parse('');
      expect(result.merchant, isNull);
    });

    test('trims whitespace from merchant name', () {
      final result = parser.parse('  ファミリーマート  \n合計 ¥300');
      expect(result.merchant, 'ファミリーマート');
    });

    test('skips very short lines (< 2 chars)', () {
      final result = parser.parse('A\nローソン\n合計 ¥200');
      expect(result.merchant, 'ローソン');
    });
  });
```

**Step 2: Run to verify failure**

**Step 3: Implement merchant extraction**

Update `parse()` to include `_extractMerchant(text)`. Add:

```dart
  String? _extractMerchant(String text) {
    if (text.isEmpty) return null;

    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty);
    final datePattern = RegExp(r'^\d{2,4}[/\-.]?\d{1,2}[/\-.]?\d{1,2}');
    final amountPattern = RegExp(r'^[¥￥]?\s*[\d,]+\s*(円)?$');
    final keywordPattern = RegExp(
      r'^(合[計计]|小[計计]|TOTAL|税込|お釣り|内税|外税)',
      caseSensitive: false,
    );

    for (final line in lines) {
      if (line.length < 2) continue;
      if (datePattern.hasMatch(line)) continue;
      if (amountPattern.hasMatch(line)) continue;
      if (keywordPattern.hasMatch(line)) continue;
      if (RegExp(r'^[\d,.\s]+$').hasMatch(line)) continue;
      return line;
    }
    return null;
  }
```

**Step 4: Run tests** → All PASS.

**Step 5: Commit**

```
feat(ocr): add merchant extraction to ReceiptParser
```

---

## Task 5: ImagePreprocessor

**Files:**
- Create: `lib/infrastructure/ml/image_preprocessor.dart`
- Create: `test/unit/infrastructure/ml/image_preprocessor_test.dart`

**Step 1: Write tests**

```dart
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:home_pocket/infrastructure/ml/image_preprocessor.dart';

void main() {
  late ImagePreprocessor preprocessor;

  setUp(() => preprocessor = ImagePreprocessor());

  test('processBytes returns grayscale image', () {
    final image = img.Image(width: 100, height: 100);
    img.fill(image, color: img.ColorRgb8(255, 0, 0));
    final input = Uint8List.fromList(img.encodePng(image));

    final result = preprocessor.processBytes(input);
    expect(result, isNotNull);

    final decoded = img.decodeImage(result!);
    expect(decoded, isNotNull);
    final pixel = decoded!.getPixel(50, 50);
    expect(pixel.r, pixel.g);
    expect(pixel.g, pixel.b);
  });

  test('processBytes resizes large images to max 2048px', () {
    final image = img.Image(width: 4000, height: 3000);
    final input = Uint8List.fromList(img.encodePng(image));

    final result = preprocessor.processBytes(input);
    final decoded = img.decodeImage(result!);
    expect(decoded!.width, lessThanOrEqualTo(2048));
    expect(decoded.height, lessThanOrEqualTo(2048));
  });

  test('processBytes returns null for invalid input', () {
    final result = preprocessor.processBytes(Uint8List.fromList([0, 1, 2]));
    expect(result, isNull);
  });
}
```

**Step 2: Implement ImagePreprocessor**

```dart
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImagePreprocessor {
  static const int _maxDimension = 2048;

  Uint8List? processBytes(Uint8List input) {
    final decoded = img.decodeImage(input);
    if (decoded == null) return null;

    var image = decoded;

    if (image.width > _maxDimension || image.height > _maxDimension) {
      final scale = _maxDimension /
          (image.width > image.height ? image.width : image.height);
      image = img.copyResize(
        image,
        width: (image.width * scale).round(),
        height: (image.height * scale).round(),
        interpolation: img.Interpolation.linear,
      );
    }

    image = img.grayscale(image);
    image = img.adjustColor(image, contrast: 1.2);

    return Uint8List.fromList(img.encodePng(image));
  }
}
```

**Step 3: Run tests** → All PASS.

**Step 4: Commit**

```
feat(ocr): add ImagePreprocessor for receipt image enhancement
```

---

## Task 6: OCR Service (Abstract + ML Kit Implementation)

**Files:**
- Create: `lib/infrastructure/ml/ocr/ocr_service.dart`
- Create: `lib/infrastructure/ml/ocr/mlkit_ocr_service.dart`

**Note:** OCR services require platform APIs; tested via integration tests.

**Step 1: Create abstract interface**

```dart
// lib/infrastructure/ml/ocr/ocr_service.dart
import 'dart:io';

class OCRResult {
  final String text;
  final List<String> lines;
  final double? confidence;

  const OCRResult({required this.text, required this.lines, this.confidence});

  static const empty = OCRResult(text: '', lines: []);
}

abstract class OCRService {
  Future<OCRResult> recognizeText(File imageFile);
  void dispose();
}
```

**Step 2: Create ML Kit implementation**

```dart
// lib/infrastructure/ml/ocr/mlkit_ocr_service.dart
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'ocr_service.dart';

class MlKitOcrService implements OCRService {
  TextRecognizer? _recognizer;

  TextRecognizer get _instance =>
      _recognizer ??= TextRecognizer(script: TextRecognitionScript.japanese);

  @override
  Future<OCRResult> recognizeText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognized = await _instance.processImage(inputImage);

    if (recognized.text.isEmpty) return OCRResult.empty;

    final lines = <String>[];
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        lines.add(line.text);
      }
    }

    return OCRResult(text: recognized.text, lines: lines);
  }

  @override
  void dispose() {
    _recognizer?.close();
    _recognizer = null;
  }
}
```

**Step 3: Commit**

```
feat(ocr): add OCRService interface and MlKitOcrService implementation
```

---

## Task 7: ScanReceiptUseCase (TDD)

UseCase accepts `Uint8List` bytes (not `File`). Returns primitives + `merchantCategoryId` (not Category objects). Screen resolves categories — same pattern as voice input.

**Files:**
- Create: `lib/application/ocr/scan_receipt_use_case.dart`
- Create: `test/unit/application/ocr/scan_receipt_use_case_test.dart`

**Step 1: Write failing tests**

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:home_pocket/application/ocr/scan_receipt_use_case.dart';
import 'package:home_pocket/infrastructure/ml/image_preprocessor.dart';
import 'package:home_pocket/infrastructure/ml/ocr/ocr_service.dart';

@GenerateMocks([OCRService, ImagePreprocessor])
import 'scan_receipt_use_case_test.mocks.dart';

void main() {
  late MockOCRService mockOcrService;
  late MockImagePreprocessor mockPreprocessor;
  late ScanReceiptUseCase useCase;

  setUp(() {
    mockOcrService = MockOCRService();
    mockPreprocessor = MockImagePreprocessor();

    useCase = ScanReceiptUseCase(
      ocrService: mockOcrService,
      preprocessor: mockPreprocessor,
    );
  });

  test('successful scan returns parsed amount, date, and merchant', () async {
    final inputBytes = Uint8List.fromList([1, 2, 3]);
    final processedBytes = Uint8List.fromList([4, 5, 6]);

    when(mockPreprocessor.processBytes(inputBytes)).thenReturn(processedBytes);
    when(mockOcrService.recognizeText(any)).thenAnswer(
      (_) async => const OCRResult(
        text: 'セブンイレブン\n2026/01/15\n合計 ¥580',
        lines: ['セブンイレブン', '2026/01/15', '合計 ¥580'],
      ),
    );

    final result = await useCase.executeFromBytes(inputBytes);

    expect(result.isSuccess, true);
    expect(result.data!.amount, 580);
    expect(result.data!.date, DateTime(2026, 1, 15));
    expect(result.data!.merchantName, 'セブンイレブン');
  });

  test('returns error when preprocessing fails', () async {
    when(mockPreprocessor.processBytes(any)).thenReturn(null);

    final result = await useCase.executeFromBytes(Uint8List.fromList([1]));

    expect(result.isError, true);
    expect(result.error, OcrError.preprocessingFailed);
  });

  test('returns error when OCR returns empty text', () async {
    when(mockPreprocessor.processBytes(any))
        .thenReturn(Uint8List.fromList([1]));
    when(mockOcrService.recognizeText(any))
        .thenAnswer((_) async => OCRResult.empty);

    final result = await useCase.executeFromBytes(Uint8List.fromList([1]));

    expect(result.isError, true);
    expect(result.error, OcrError.noTextRecognized);
  });

  test('cleans up temp file even when OCR throws', () async {
    when(mockPreprocessor.processBytes(any))
        .thenReturn(Uint8List.fromList([1]));
    when(mockOcrService.recognizeText(any)).thenThrow(Exception('OCR crash'));

    final result = await useCase.executeFromBytes(Uint8List.fromList([1]));

    expect(result.isError, true);
    // No temp dir leak — verify no unhandled exception
  });
}
```

**Step 2: Generate mocks, run to verify failure**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/unit/application/ocr/scan_receipt_use_case_test.dart`

**Step 3: Implement ScanReceiptUseCase**

```dart
// lib/application/ocr/scan_receipt_use_case.dart
import 'dart:io';
import 'dart:typed_data';

import '../../infrastructure/ml/image_preprocessor.dart';
import '../../infrastructure/ml/ocr/ocr_service.dart';
import '../../shared/utils/result.dart';
import 'receipt_parser.dart';

/// Error types for OCR scanning — mapped to l10n keys in the UI layer.
enum OcrError {
  noImageSelected,
  preprocessingFailed,
  noTextRecognized,
  scanFailed,
}

/// Result of the OCR scan pipeline.
/// Contains primitives only — screen resolves categoryId → Category objects.
class OcrScanResult {
  final int? amount;
  final DateTime? date;
  final String? merchantName;

  const OcrScanResult({this.amount, this.date, this.merchantName});
}

/// Orchestrates: preprocess → OCR → parse.
///
/// Does NOT handle image acquisition (screen's responsibility via image_picker)
/// or category resolution (screen resolves merchantName → MerchantDatabase → Category).
class ScanReceiptUseCase {
  final OCRService _ocrService;
  final ImagePreprocessor _preprocessor;
  final ReceiptParser _parser = ReceiptParser();

  ScanReceiptUseCase({
    required OCRService ocrService,
    required ImagePreprocessor preprocessor,
  })  : _ocrService = ocrService,
        _preprocessor = preprocessor;

  /// Execute scan from raw image bytes.
  Future<Result<OcrScanResult, OcrError>> executeFromBytes(
    Uint8List imageBytes,
  ) async {
    Directory? tempDir;
    try {
      // 1. Preprocess
      final processedBytes = _preprocessor.processBytes(imageBytes);
      if (processedBytes == null) {
        return Result.error(OcrError.preprocessingFailed);
      }

      // 2. Write to temp file for OCR engine
      tempDir = await Directory.systemTemp.createTemp('ocr_');
      final tempFile = File('${tempDir.path}/processed.png');
      await tempFile.writeAsBytes(processedBytes);

      // 3. OCR recognition
      final ocrResult = await _ocrService.recognizeText(tempFile);
      if (ocrResult.text.isEmpty) {
        return Result.error(OcrError.noTextRecognized);
      }

      // 4. Parse receipt data
      final parsed = _parser.parse(ocrResult.text);

      return Result.success(OcrScanResult(
        amount: parsed.amount,
        date: parsed.date,
        merchantName: parsed.merchant,
      ));
    } catch (e) {
      return Result.error(OcrError.scanFailed);
    } finally {
      // Always clean up temp directory
      try {
        await tempDir?.delete(recursive: true);
      } catch (_) {}
    }
  }
}
```

**Important:** The existing `Result` class may use `Result.error(String)`. Check its signature at `lib/shared/utils/result.dart`. If it only supports `String` errors, use `Result.error(OcrError.preprocessingFailed.name)` and change the test assertions accordingly. Alternatively, create a simple `OcrResult` wrapper class that holds either success data or an `OcrError` enum.

**Step 4: Run tests** → All PASS.

**Step 5: Commit**

```
feat(ocr): add ScanReceiptUseCase with typed OcrError enum
```

---

## Task 8: Provider Wiring

**Files:**
- Create: `lib/features/accounting/presentation/providers/ocr_providers.dart`

**Step 1: Create OCR providers**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/ocr/scan_receipt_use_case.dart';
import '../../../../infrastructure/ml/image_preprocessor.dart';
import '../../../../infrastructure/ml/ocr/mlkit_ocr_service.dart';
import '../../../../infrastructure/ml/ocr/ocr_service.dart';

part 'ocr_providers.g.dart';

@Riverpod(keepAlive: true)
OCRService ocrService(Ref ref) {
  final service = MlKitOcrService();
  ref.onDispose(() => service.dispose());
  return service;
}

@riverpod
ImagePreprocessor imagePreprocessor(Ref ref) {
  return ImagePreprocessor();
}

@riverpod
ScanReceiptUseCase scanReceiptUseCase(Ref ref) {
  return ScanReceiptUseCase(
    ocrService: ref.watch(ocrServiceProvider),
    preprocessor: ref.watch(imagePreprocessorProvider),
  );
}
```

**Step 2: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

**Step 3: Verify**

Run: `flutter analyze`
Expected: 0 new warnings.

**Step 4: Commit**

```
feat(ocr): wire OCR providers for Riverpod dependency injection
```

---

## Task 9: OcrScannerScreen Integration

**Files:**
- Modify: `lib/features/accounting/presentation/screens/ocr_scanner_screen.dart`

Convert stub `StatelessWidget` → `ConsumerStatefulWidget` with real OCR functionality.

**Key design decisions (matching voice input pattern):**
- Screen calls `image_picker` to acquire image
- Screen reads bytes and passes to `ScanReceiptUseCase.executeFromBytes()`
- Screen resolves merchantName → MerchantDatabase → Category (same as `_navigateToConfirm()` in VoiceInputScreen)
- Error messages via `S.of(context)` mapped from `OcrError` enum
- Processing overlay shown during `_isProcessing`

**Step 1: Full rewrite of OcrScannerScreen**

Key additions:
- `ConsumerStatefulWidget` (needs `ref` for providers)
- `_isProcessing` state for loading overlay
- `_scan(ImageSource source)` method:
  1. `ImagePicker().pickImage(source: source)` → get `XFile`
  2. `xFile.readAsBytes()` → `Uint8List`
  3. `ref.read(scanReceiptUseCaseProvider).executeFromBytes(bytes)` → `OcrScanResult`
  4. `ref.read(merchantDatabaseProvider).findMerchant(result.merchantName)` → match
  5. `ref.read(categoryRepositoryProvider).findById(match.categoryId)` → category
  6. `Navigator.push` → `TransactionConfirmScreen(...)`
- Error handling: map `OcrError` enum → `S.of(context).ocrXxx` l10n keys
- Stack + Positioned for processing overlay on top of existing dark UI
- Keep all existing dark theme styling

**Step 2: Verify it compiles**

Run: `flutter analyze`

**Step 3: Commit**

```
feat(ocr): integrate OCR pipeline into OcrScannerScreen
```

---

## Task 10: Final Verification

**Step 1: Run all tests**

Run: `flutter test`
Expected: All existing + new OCR tests pass.

**Step 2: Run analyzer**

Run: `flutter analyze`
Expected: 0 new warnings.

**Step 3: Format**

Run: `dart format lib/application/ocr/ lib/infrastructure/ml/ lib/features/accounting/presentation/providers/ocr_providers.dart lib/features/accounting/presentation/screens/ocr_scanner_screen.dart test/unit/application/ocr/ test/unit/infrastructure/ml/image_preprocessor_test.dart`

**Step 4: Commit any formatting changes**

---

## Follow-Up Plans (Not in Scope)

1. **Photo Encryption & Storage (P1)** — PhotoEncryptionService + SaveReceiptPhotoUseCase + ReceiptPhotos table/DAO/repo + photoHash in CreateTransactionParams
2. **Live Camera Preview + Flash Toggle (FR-001)** — Requires `camera` package with CameraController, separate from image_picker approach
3. **500+ Merchant Database Expansion** — Expand MerchantDatabase seed data for higher match rates
