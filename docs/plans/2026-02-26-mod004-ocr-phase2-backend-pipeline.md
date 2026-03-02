# MOD-004 OCR Phase 2: Backend Pipeline Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement the complete OCR backend pipeline (Modules A/B/C/D) as specified in MOD-004 v4.0, wiring image preprocessing, native OCR engines, heuristic extraction, and financial validation into a working end-to-end receipt scanning flow.

**Architecture:** 4-module pipeline: [A] ImagePreprocessor (opencv_dart, Isolate) -> [B] PlatformOcrService (MethodChannel -> iOS Vision / Android ML Kit) -> [C] ReceiptParser (heuristic rules) -> [D] ReceiptValidator (financial logic). Orchestrated by ScanReceiptUseCase. Photo encrypted via AES-256-GCM and stored in Drift receipt_photos table.

**Tech Stack:** Flutter, opencv_dart ^2.2.x, image_picker ^1.1.x, MethodChannel (com.homepocket/ocr), Riverpod (@riverpod), Drift + SQLCipher, Freezed, cryptography (AES-GCM), mocktail (testing).

---

**Required execution skills:** `@test-driven-development`, `@verification-before-completion`, `@requesting-code-review`

## Existing Code (Phase 1 - Already Done)

These components are already implemented and should NOT be modified unless explicitly stated:

| Component | File | Status |
|-----------|------|--------|
| OcrScannerScreen (stub) | `lib/features/accounting/presentation/screens/ocr_scanner_screen.dart` | Stub UI |
| TransactionConfirmScreen | `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` | Complete |
| EntryModeSwitcher | `lib/features/accounting/presentation/widgets/entry_mode_switcher.dart` | Complete |
| MerchantDatabase | `lib/infrastructure/ml/merchant_database.dart` | Complete (~20 merchants) |
| Transaction model | `lib/features/accounting/domain/models/transaction.dart` | Has `photoHash` field |
| Navigation config | `lib/features/accounting/presentation/navigation/entry_mode_navigation_config.dart` | Complete |
| i18n basic keys | `lib/l10n/app_{ja,zh,en}.arb` | `ocrScan`, `ocrScanTitle`, `ocrHint` |

## Implementation Order & Dependencies

```
Task 1: OCR Data Models (Freezed)           ← no deps, foundation for everything
    │
    ├─► Task 2: Module C - ReceiptParser     ← pure Dart, TDD (most critical logic)
    │       │
    │       └─► Task 3: Module D - ReceiptValidator  ← pure Dart, TDD
    │
    ├─► Task 4: Module B - OCR Service Interface + PlatformOcrService (Dart)
    │       │
    │       ├─► Task 5: iOS Native OCR (OcrChannel.swift)
    │       └─► Task 6: Android Native OCR (OcrChannel.kt)
    │
    ├─► Task 7: Dependencies + Module A - ImagePreprocessor (opencv_dart)
    │
    └─► Task 8: Photo Encryption Service
            │
            └─► Task 9: Data Layer (receipt_photos table + DAO + repo)

Task 10: ScanReceiptUseCase  ← depends on Tasks 2-4, 7-8
Task 11: SaveReceiptPhotoUseCase  ← depends on Tasks 8-9
Task 12: OCR Providers (Riverpod wiring)  ← depends on Tasks 10-11
Task 13: Wire OcrScannerScreen  ← depends on Task 12
Task 14: Localization keys  ← independent, do anytime
Task 15: Final verification & cleanup
```

---

### Task 1: OCR Data Models (Freezed)

**Files:**
- Create: `lib/application/ocr/models/ocr_scan_result.dart`
- Create: `lib/application/ocr/models/parsed_receipt_data.dart`
- Create: `lib/application/ocr/models/validated_receipt_data.dart`

**Step 1: Create ParsedReceiptData model**

```dart
// lib/application/ocr/models/parsed_receipt_data.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'parsed_receipt_data.freezed.dart';
part 'parsed_receipt_data.g.dart';

/// A single line item extracted from a receipt.
@freezed
class ReceiptLineItem with _$ReceiptLineItem {
  const factory ReceiptLineItem({
    required String name,
    required int unitPrice,
    @Default(1) int quantity,
    required int subtotal,
  }) = _ReceiptLineItem;

  factory ReceiptLineItem.fromJson(Map<String, dynamic> json) =>
      _$ReceiptLineItemFromJson(json);
}

/// Raw parsed data from Module C (ReceiptParser).
/// All fields nullable because extraction may fail.
@freezed
class ParsedReceiptData with _$ParsedReceiptData {
  const factory ParsedReceiptData({
    int? amount,
    DateTime? date,
    String? merchant,
    @Default([]) List<ReceiptLineItem> items,
  }) = _ParsedReceiptData;

  factory ParsedReceiptData.fromJson(Map<String, dynamic> json) =>
      _$ParsedReceiptDataFromJson(json);
}
```

**Step 2: Create ValidatedReceiptData model**

```dart
// lib/application/ocr/models/validated_receipt_data.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'validated_receipt_data.freezed.dart';
part 'validated_receipt_data.g.dart';

enum ValidationWarning {
  negativeAmount,
  unusuallyLargeAmount,
  futureDate,
  ancientDate,
  itemsTotalMismatch,
}

/// Validated receipt data from Module D (ReceiptValidator).
/// Contains confidence score and any warnings.
@freezed
class ValidatedReceiptData with _$ValidatedReceiptData {
  const factory ValidatedReceiptData({
    int? amount,
    DateTime? date,
    String? merchant,
    @Default(1.0) double confidence,
    @Default([]) List<ValidationWarning> warnings,
  }) = _ValidatedReceiptData;

  factory ValidatedReceiptData.fromJson(Map<String, dynamic> json) =>
      _$ValidatedReceiptDataFromJson(json);
}
```

**Step 3: Create OcrScanResult model**

```dart
// lib/application/ocr/models/ocr_scan_result.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'validated_receipt_data.dart';

part 'ocr_scan_result.freezed.dart';
part 'ocr_scan_result.g.dart';

/// Final result of the full OCR scan pipeline.
/// Passed from ScanReceiptUseCase to TransactionConfirmScreen.
@freezed
class OcrScanResult with _$OcrScanResult {
  const factory OcrScanResult({
    /// Validated amount in JPY (integer).
    int? amount,
    /// Extracted date.
    DateTime? date,
    /// Merchant name (from OCR + MerchantDatabase matching).
    String? merchant,
    /// Matched category ID from MerchantDatabase.
    String? categoryId,
    /// Matched parent category ID.
    String? parentCategoryId,
    /// SHA-256 hash of encrypted photo (for linking to transaction).
    String? photoHash,
    /// Overall confidence score 0.0-1.0.
    @Default(0.0) double confidence,
    /// Validation warnings.
    @Default([]) List<ValidationWarning> warnings,
  }) = _OcrScanResult;

  factory OcrScanResult.fromJson(Map<String, dynamic> json) =>
      _$OcrScanResultFromJson(json);
}
```

**Step 4: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: `.freezed.dart` and `.g.dart` files generated without errors.

**Step 5: Verify compilation**

Run: `flutter analyze lib/application/ocr/models/`
Expected: No issues found.

**Step 6: Commit**

```bash
git add lib/application/ocr/models/
git commit -m "feat(ocr): add Freezed data models for OCR pipeline

Add ParsedReceiptData, ValidatedReceiptData, OcrScanResult models
with proper Freezed annotations for the 4-module OCR pipeline."
```

---

### Task 2: Module C - ReceiptParser (TDD)

This is the most critical module - pure Dart heuristic extraction logic.

**Files:**
- Create: `lib/application/ocr/receipt_parser.dart`
- Create: `test/unit/application/ocr/receipt_parser_test.dart`

**Step 1: Create test file with amount extraction tests**

```dart
// test/unit/application/ocr/receipt_parser_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/ocr/receipt_parser.dart';
import 'package:home_pocket/infrastructure/ml/ocr/ocr_service.dart';

// Helper to create OCRLine with position
OCRLine _line(String text, {double y = 0.5, double confidence = 0.95}) {
  return OCRLine(
    text: text,
    x: 0.1,
    y: y,
    width: 0.8,
    height: 0.03,
    confidence: confidence,
  );
}

void main() {
  late ReceiptParser parser;

  setUp(() {
    parser = ReceiptParser();
  });

  group('extractAmount', () {
    group('Phase 1: keyword matching', () {
      test('extracts amount from 合計 ¥580', () {
        final result = parser.parse(OCRResult(
          text: '',
          lines: [
            _line('セブンイレブン', y: 0.05),
            _line('合計 ¥580', y: 0.6),
          ],
        ));
        expect(result.amount, 580);
      });

      test('extracts amount from 税込合計 1,280', () {
        final result = parser.parse(OCRResult(
          text: '',
          lines: [
            _line('税込合計 1,280', y: 0.7),
          ],
        ));
        expect(result.amount, 1280);
      });

      test('extracts amount from 小計 when no 合計', () {
        final result = parser.parse(OCRResult(
          text: '',
          lines: [
            _line('小計 ¥270', y: 0.5),
          ],
        ));
        expect(result.amount, 270);
      });

      test('extracts amount from TOTAL (case insensitive)', () {
        final result = parser.parse(OCRResult(
          text: '',
          lines: [
            _line('Total ¥1,500', y: 0.6),
          ],
        ));
        expect(result.amount, 1500);
      });

      test('extracts amount from 580円', () {
        final result = parser.parse(OCRResult(
          text: '',
          lines: [
            _line('580円', y: 0.6),
          ],
        ));
        expect(result.amount, 580);
      });

      test('extracts amount with commas ¥1,234,567', () {
        final result = parser.parse(OCRResult(
          text: '',
          lines: [
            _line('合計 ¥1,234,567', y: 0.6),
          ],
        ));
        expect(result.amount, 1234567);
      });
    });

    group('Phase 2: position weighting', () {
      test('prefers lower-half amount over upper-half', () {
        final result = parser.parse(OCRResult(
          text: '',
          lines: [
            _line('¥100', y: 0.2),   // upper half
            _line('¥500', y: 0.7),   // lower half - should win
          ],
        ));
        expect(result.amount, 500);
      });

      test('excludes お釣り lines', () {
        final result = parser.parse(OCRResult(
          text: '',
          lines: [
            _line('¥500', y: 0.5),
            _line('お釣り ¥200', y: 0.8),
          ],
        ));
        expect(result.amount, 500);
      });

      test('excludes 消費税 lines', () {
        final result = parser.parse(OCRResult(
          text: '',
          lines: [
            _line('¥1,000', y: 0.5),
            _line('消費税 ¥80', y: 0.6),
          ],
        ));
        expect(result.amount, 1000);
      });
    });

    group('Phase 3: fallback', () {
      test('falls back to largest ¥ amount when no keywords', () {
        final result = parser.parse(OCRResult(
          text: '',
          lines: [
            _line('¥150', y: 0.3),
            _line('¥300', y: 0.5),
            _line('¥250', y: 0.4),
          ],
        ));
        expect(result.amount, 300);
      });

      test('returns null when no amounts found', () {
        final result = parser.parse(OCRResult(
          text: '',
          lines: [
            _line('ありがとうございました', y: 0.9),
          ],
        ));
        expect(result.amount, isNull);
      });
    });
  });

  group('extractDate', () {
    test('extracts YYYY年MM月DD日', () {
      final result = parser.parse(OCRResult(
        text: '',
        lines: [_line('2026年02月25日', y: 0.1)],
      ));
      expect(result.date, DateTime(2026, 2, 25));
    });

    test('extracts YYYY/MM/DD', () {
      final result = parser.parse(OCRResult(
        text: '',
        lines: [_line('2026/02/25 14:30', y: 0.1)],
      ));
      expect(result.date, DateTime(2026, 2, 25));
    });

    test('extracts YYYY-MM-DD', () {
      final result = parser.parse(OCRResult(
        text: '',
        lines: [_line('2026-02-25', y: 0.1)],
      ));
      expect(result.date, DateTime(2026, 2, 25));
    });

    test('extracts YY/MM/DD and adds century', () {
      final result = parser.parse(OCRResult(
        text: '',
        lines: [_line('26/02/25', y: 0.1)],
      ));
      expect(result.date, DateTime(2026, 2, 25));
    });

    test('picks topmost date when multiple dates present', () {
      final result = parser.parse(OCRResult(
        text: '',
        lines: [
          _line('2026/02/25', y: 0.05),
          _line('2025/12/31', y: 0.5),
        ],
      ));
      expect(result.date, DateTime(2026, 2, 25));
    });

    test('returns null when no date found', () {
      final result = parser.parse(OCRResult(
        text: '',
        lines: [_line('セブンイレブン', y: 0.1)],
      ));
      expect(result.date, isNull);
    });

    test('rejects invalid date (Feb 30)', () {
      final result = parser.parse(OCRResult(
        text: '',
        lines: [_line('2026/02/30', y: 0.1)],
      ));
      // Should either return null or a corrected date
      expect(result.date, isNull);
    });
  });

  group('extractMerchant', () {
    test('returns first non-noise line as merchant', () {
      final result = parser.parse(OCRResult(
        text: '',
        lines: [
          _line('セブンイレブン新宿店', y: 0.02),
          _line('2026/02/25', y: 0.06),
          _line('合計 ¥580', y: 0.6),
        ],
      ));
      expect(result.merchant, 'セブンイレブン新宿店');
    });

    test('skips date-only lines', () {
      final result = parser.parse(OCRResult(
        text: '',
        lines: [
          _line('2026/02/25 14:30', y: 0.02),
          _line('セブンイレブン', y: 0.06),
        ],
      ));
      expect(result.merchant, 'セブンイレブン');
    });

    test('skips amount-only lines', () {
      final result = parser.parse(OCRResult(
        text: '',
        lines: [
          _line('¥580', y: 0.02),
          _line('マツモトキヨシ', y: 0.06),
        ],
      ));
      expect(result.merchant, 'マツモトキヨシ');
    });

    test('skips keyword lines (合計, TEL, etc)', () {
      final result = parser.parse(OCRResult(
        text: '',
        lines: [
          _line('合計', y: 0.02),
          _line('TEL:03-1234-5678', y: 0.04),
          _line('ローソン渋谷店', y: 0.06),
        ],
      ));
      expect(result.merchant, 'ローソン渋谷店');
    });

    test('skips very short lines (< 2 chars)', () {
      final result = parser.parse(OCRResult(
        text: '',
        lines: [
          _line('A', y: 0.02),
          _line('ファミリーマート', y: 0.06),
        ],
      ));
      expect(result.merchant, 'ファミリーマート');
    });

    test('returns null when all lines are noise', () {
      final result = parser.parse(OCRResult(
        text: '',
        lines: [
          _line('¥580', y: 0.02),
          _line('2026/02/25', y: 0.06),
        ],
      ));
      expect(result.merchant, isNull);
    });
  });

  group('full receipt parsing', () {
    test('parses typical convenience store receipt', () {
      final result = parser.parse(OCRResult(
        text: '',
        lines: [
          _line('セブンイレブン新宿店', y: 0.02),
          _line('東京都新宿区...', y: 0.05),
          _line('TEL:03-1234-5678', y: 0.08),
          _line('2026/02/25 14:30', y: 0.12),
          _line('おにぎり鮭 ¥150', y: 0.25),
          _line('コカ・コーラ ¥160', y: 0.30),
          _line('小計 ¥310', y: 0.50),
          _line('消費税(8%) ¥24', y: 0.55),
          _line('合計 ¥334', y: 0.60),
          _line('お預り ¥500', y: 0.70),
          _line('お釣り ¥166', y: 0.75),
        ],
      ));
      expect(result.amount, 334);
      expect(result.date, DateTime(2026, 2, 25));
      expect(result.merchant, 'セブンイレブン新宿店');
    });

    test('parses receipt with 税込合計', () {
      final result = parser.parse(OCRResult(
        text: '',
        lines: [
          _line('イオン品川店', y: 0.02),
          _line('2026/02/20', y: 0.06),
          _line('牛乳 ¥198', y: 0.20),
          _line('パン ¥128', y: 0.25),
          _line('小計 ¥326', y: 0.50),
          _line('内税 ¥24', y: 0.55),
          _line('税込合計 ¥326', y: 0.60),
        ],
      ));
      expect(result.amount, 326);
      expect(result.merchant, 'イオン品川店');
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/application/ocr/receipt_parser_test.dart`
Expected: FAIL - `receipt_parser.dart` and `ocr_service.dart` don't exist yet.

**Step 3: Create OCR Service interface (dependency for ReceiptParser)**

This is a minimal interface file needed by ReceiptParser's input type.

```dart
// lib/infrastructure/ml/ocr/ocr_service.dart

import 'dart:io';

/// A single recognized text line with position information.
class OCRLine {
  final String text;
  /// Normalized coordinates (0.0-1.0) relative to image dimensions.
  final double x, y, width, height;
  final double confidence;

  const OCRLine({
    required this.text,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.confidence = 1.0,
  });

  /// Center Y coordinate (for position-based weighting).
  double get centerY => y + height / 2;
}

/// Result of OCR text recognition.
class OCRResult {
  final String text;
  final List<OCRLine> lines;

  const OCRResult({required this.text, required this.lines});

  static const empty = OCRResult(text: '', lines: []);

  bool get isEmpty => text.isEmpty;
}

/// Abstract OCR service interface.
/// iOS: Apple Vision Framework, Android: ML Kit Text Recognition v2.
abstract class OCRService {
  Future<OCRResult> recognizeText(File imageFile);
  void dispose();
}
```

**Step 4: Implement ReceiptParser**

```dart
// lib/application/ocr/receipt_parser.dart

import 'package:home_pocket/application/ocr/models/parsed_receipt_data.dart';
import 'package:home_pocket/infrastructure/ml/ocr/ocr_service.dart';

/// Module C: Heuristic receipt information extraction.
///
/// Extracts amount, date, and merchant from OCR results using
/// keyword matching, position weighting, and regex patterns.
class ReceiptParser {
  // Phase 1: Keyword patterns (ordered by priority)
  static final _keywordPatterns = [
    RegExp(r'税込\s*合[計计]\s*[¥￥]?\s*([\d,]+)'),
    RegExp(r'合[計计]\s*[¥￥]?\s*([\d,]+)'),
    RegExp(r'小[計计]\s*[¥￥]?\s*([\d,]+)'),
    RegExp(r'TOTAL\s*[¥￥]?\s*([\d,]+)', caseSensitive: false),
    RegExp(r'([\d,]+)\s*円'),
  ];

  // Phase 2: Noise exclusion keywords
  static final _excludedKeywords =
      RegExp(r'(お釣り|釣銭|お預り|税\s|消費税|内税|外税)');

  // Yen amount pattern
  static final _yenPattern = RegExp(r'[¥￥]\s*([\d,]+)');

  // Date patterns
  static final _datePatterns = [
    RegExp(r'(\d{4})年(\d{1,2})月(\d{1,2})日'),
    RegExp(r'(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})'),
    RegExp(r'(\d{2})[/\-.](\d{1,2})[/\-.](\d{1,2})'),
  ];

  // Merchant noise patterns
  static final _dateLinePattern =
      RegExp(r'^\d{2,4}[/\-.]?\d{1,2}[/\-.]?\d{1,2}');
  static final _amountLinePattern = RegExp(r'^[¥￥]?\s*[\d,]+\s*(円)?$');
  static final _keywordLinePattern = RegExp(
    r'^(合[計计]|小[計计]|TOTAL|税込|お釣り|お預り|内税|外税|消費税|No\.|TEL)',
    caseSensitive: false,
  );
  static final _pureNumberPattern = RegExp(r'^[\d,.\s]+$');

  /// Parse OCR result into structured receipt data.
  ParsedReceiptData parse(OCRResult ocrResult) {
    final lines = ocrResult.lines;
    return ParsedReceiptData(
      amount: _extractAmount(lines),
      date: _extractDate(lines),
      merchant: _extractMerchant(lines),
      items: _extractLineItems(lines),
    );
  }

  int? _extractAmount(List<OCRLine> lines) {
    final fullText = lines.map((l) => l.text).join('\n');

    // Phase 1: Keyword proximity matching
    for (final pattern in _keywordPatterns) {
      final match = pattern.firstMatch(fullText);
      if (match != null) {
        final parsed = _parseNumber(match.group(1)!);
        if (parsed != null && parsed > 0) return parsed;
      }
    }

    // Phase 2: Position weighting + max value
    int? best;
    double bestScore = 0;

    for (final line in lines) {
      if (_excludedKeywords.hasMatch(line.text)) continue;

      for (final match in _yenPattern.allMatches(line.text)) {
        final parsed = _parseNumber(match.group(1)!);
        if (parsed == null || parsed <= 0) continue;

        // Position weight: lower half gets 1.5x
        final posWeight = line.centerY > 0.5 ? 1.5 : 1.0;
        final score = parsed * posWeight;

        if (score > bestScore) {
          bestScore = score;
          best = parsed;
        }
      }
    }
    if (best != null) return best;

    // Phase 3: Fallback - largest ¥ amount anywhere
    int? largest;
    for (final line in lines) {
      for (final match in _yenPattern.allMatches(line.text)) {
        final parsed = _parseNumber(match.group(1)!);
        if (parsed != null && parsed > 0 && (largest == null || parsed > largest)) {
          largest = parsed;
        }
      }
    }
    return largest;
  }

  DateTime? _extractDate(List<OCRLine> lines) {
    // Take the topmost matching date (receipt header)
    for (final line in lines) {
      for (final pattern in _datePatterns) {
        final match = pattern.firstMatch(line.text);
        if (match != null) {
          final date = _parseDate(match, pattern);
          if (date != null) return date;
        }
      }
    }
    return null;
  }

  String? _extractMerchant(List<OCRLine> lines) {
    for (final line in lines) {
      final text = line.text.trim();
      if (text.length < 2) continue;
      if (_dateLinePattern.hasMatch(text)) continue;
      if (_amountLinePattern.hasMatch(text)) continue;
      if (_keywordLinePattern.hasMatch(text)) continue;
      if (_pureNumberPattern.hasMatch(text)) continue;
      return text;
    }
    return null;
  }

  List<ReceiptLineItem> _extractLineItems(List<OCRLine> lines) {
    final itemPattern = RegExp(r'(.+?)\s+[¥￥]?\s*([\d,]+)\s*$');
    final items = <ReceiptLineItem>[];

    for (final line in lines) {
      if (_isKeywordLine(line.text)) continue;
      final match = itemPattern.firstMatch(line.text);
      if (match != null) {
        final name = match.group(1)!.trim();
        final price = _parseNumber(match.group(2)!);
        if (price != null && price > 0 && name.isNotEmpty) {
          items.add(ReceiptLineItem(
            name: name,
            unitPrice: price,
            quantity: 1,
            subtotal: price,
          ));
        }
      }
    }
    return items;
  }

  bool _isKeywordLine(String text) {
    return _keywordLinePattern.hasMatch(text.trim()) ||
        _excludedKeywords.hasMatch(text);
  }

  int? _parseNumber(String s) {
    final cleaned = s.replaceAll(',', '').trim();
    return int.tryParse(cleaned);
  }

  DateTime? _parseDate(RegExpMatch match, RegExp pattern) {
    try {
      int year, month, day;

      if (pattern == _datePatterns[2]) {
        // Short year format: YY/MM/DD
        year = 2000 + int.parse(match.group(1)!);
        month = int.parse(match.group(2)!);
        day = int.parse(match.group(3)!);
      } else {
        year = int.parse(match.group(1)!);
        month = int.parse(match.group(2)!);
        day = int.parse(match.group(3)!);
      }

      // Validate date components
      if (month < 1 || month > 12) return null;
      if (day < 1 || day > 31) return null;

      final date = DateTime(year, month, day);
      // DateTime auto-adjusts (Feb 30 -> Mar 2), check it didn't
      if (date.month != month || date.day != day) return null;

      return date;
    } catch (_) {
      return null;
    }
  }
}
```

**Step 5: Run tests to verify they pass**

Run: `flutter test test/unit/application/ocr/receipt_parser_test.dart`
Expected: All tests PASS.

**Step 6: Run analyzer**

Run: `flutter analyze lib/application/ocr/receipt_parser.dart`
Expected: No issues found.

**Step 7: Commit**

```bash
git add lib/infrastructure/ml/ocr/ocr_service.dart \
        lib/application/ocr/receipt_parser.dart \
        test/unit/application/ocr/receipt_parser_test.dart
git commit -m "feat(ocr): implement Module C - ReceiptParser with heuristic extraction

3-phase amount extraction (keyword → position weight → fallback max),
regex-based date extraction, merchant name extraction (first non-noise line).
Includes comprehensive unit tests for Japanese receipt formats."
```

---

### Task 3: Module D - ReceiptValidator (TDD)

**Files:**
- Create: `lib/application/ocr/receipt_validator.dart`
- Create: `test/unit/application/ocr/receipt_validator_test.dart`

**Step 1: Write the failing tests**

```dart
// test/unit/application/ocr/receipt_validator_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/ocr/models/parsed_receipt_data.dart';
import 'package:home_pocket/application/ocr/models/validated_receipt_data.dart';
import 'package:home_pocket/application/ocr/receipt_validator.dart';

void main() {
  late ReceiptValidator validator;

  setUp(() {
    validator = ReceiptValidator();
  });

  group('validate', () {
    test('normal data produces high confidence', () {
      final result = validator.validate(const ParsedReceiptData(
        amount: 580,
        date: null, // use a recent date in implementation
        merchant: 'セブンイレブン',
      ));
      expect(result.amount, 580);
      expect(result.merchant, 'セブンイレブン');
      expect(result.confidence, greaterThan(0.7));
      expect(result.warnings, isEmpty);
    });

    test('negative amount triggers warning and low confidence', () {
      final result = validator.validate(const ParsedReceiptData(
        amount: -100,
      ));
      expect(result.warnings, contains(ValidationWarning.negativeAmount));
      expect(result.confidence, lessThan(0.5));
    });

    test('zero amount triggers warning', () {
      final result = validator.validate(const ParsedReceiptData(
        amount: 0,
      ));
      expect(result.warnings, contains(ValidationWarning.negativeAmount));
    });

    test('amount over 1M triggers warning', () {
      final result = validator.validate(const ParsedReceiptData(
        amount: 1500000,
      ));
      expect(result.warnings, contains(ValidationWarning.unusuallyLargeAmount));
      expect(result.confidence, lessThan(0.8));
    });

    test('null amount reduces confidence', () {
      final result = validator.validate(const ParsedReceiptData());
      expect(result.confidence, lessThan(0.5));
    });

    test('future date triggers warning', () {
      final futureDate = DateTime.now().add(const Duration(days: 30));
      final result = validator.validate(ParsedReceiptData(
        amount: 500,
        date: futureDate,
      ));
      expect(result.warnings, contains(ValidationWarning.futureDate));
    });

    test('date before year 2000 triggers warning', () {
      final result = validator.validate(ParsedReceiptData(
        amount: 500,
        date: DateTime(1999, 12, 31),
      ));
      expect(result.warnings, contains(ValidationWarning.ancientDate));
    });

    test('null date slightly reduces confidence', () {
      final result = validator.validate(const ParsedReceiptData(
        amount: 500,
      ));
      // Should still be relatively high since amount is valid
      expect(result.confidence, greaterThan(0.5));
    });

    test('items total mismatch with amount triggers warning', () {
      final result = validator.validate(const ParsedReceiptData(
        amount: 1000,
        items: [
          ReceiptLineItem(name: 'A', unitPrice: 100, subtotal: 100),
          ReceiptLineItem(name: 'B', unitPrice: 200, subtotal: 200),
          // total = 300, but amount = 1000 (3x mismatch)
        ],
      ));
      expect(result.warnings, contains(ValidationWarning.itemsTotalMismatch));
    });

    test('items total closely matching amount boosts confidence', () {
      final resultWithItems = validator.validate(const ParsedReceiptData(
        amount: 310,
        items: [
          ReceiptLineItem(name: 'おにぎり', unitPrice: 150, subtotal: 150),
          ReceiptLineItem(name: 'コーラ', unitPrice: 160, subtotal: 160),
        ],
      ));
      final resultWithout = validator.validate(const ParsedReceiptData(
        amount: 310,
      ));
      expect(resultWithItems.confidence,
          greaterThanOrEqualTo(resultWithout.confidence));
    });

    test('preserves all parsed fields in output', () {
      final date = DateTime(2026, 2, 25);
      final result = validator.validate(ParsedReceiptData(
        amount: 500,
        date: date,
        merchant: 'テスト店',
      ));
      expect(result.amount, 500);
      expect(result.date, date);
      expect(result.merchant, 'テスト店');
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/application/ocr/receipt_validator_test.dart`
Expected: FAIL - `receipt_validator.dart` doesn't exist yet.

**Step 3: Implement ReceiptValidator**

```dart
// lib/application/ocr/receipt_validator.dart

import 'package:home_pocket/application/ocr/models/parsed_receipt_data.dart';
import 'package:home_pocket/application/ocr/models/validated_receipt_data.dart';

/// Module D: Financial logic validation and confidence scoring.
///
/// Validates parsed receipt data against financial rules:
/// - Amount reasonableness (0 < amount < 1,000,000 JPY)
/// - Date validity (not future, not pre-2000)
/// - Line items cross-check (items total vs declared total)
class ReceiptValidator {
  ValidatedReceiptData validate(ParsedReceiptData parsed) {
    final warnings = <ValidationWarning>[];
    double confidence = 1.0;

    // Rule 1: Amount reasonableness
    if (parsed.amount != null) {
      if (parsed.amount! <= 0) {
        warnings.add(ValidationWarning.negativeAmount);
        confidence *= 0.3;
      } else if (parsed.amount! > 1000000) {
        warnings.add(ValidationWarning.unusuallyLargeAmount);
        confidence *= 0.5;
      }
    } else {
      confidence *= 0.4; // No amount extracted
    }

    // Rule 2: Date reasonableness
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
      confidence *= 0.8; // Missing date is not critical
    }

    // Rule 3: Line items cross-check
    if (parsed.items.isNotEmpty && parsed.amount != null && parsed.amount! > 0) {
      final itemsTotal = parsed.items.fold<int>(0, (sum, i) => sum + i.subtotal);
      final ratio = itemsTotal / parsed.amount!;
      if (ratio < 0.7 || ratio > 1.3) {
        warnings.add(ValidationWarning.itemsTotalMismatch);
        confidence *= 0.6;
      } else if (ratio > 0.9 && ratio < 1.1) {
        confidence *= 1.1; // Close match boosts confidence
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
```

**Step 4: Run tests to verify they pass**

Run: `flutter test test/unit/application/ocr/receipt_validator_test.dart`
Expected: All tests PASS.

**Step 5: Run analyzer**

Run: `flutter analyze lib/application/ocr/receipt_validator.dart`
Expected: No issues found.

**Step 6: Commit**

```bash
git add lib/application/ocr/receipt_validator.dart \
        test/unit/application/ocr/receipt_validator_test.dart
git commit -m "feat(ocr): implement Module D - ReceiptValidator with financial logic

Amount reasonableness checks (0-1M JPY range), date validation
(not future, not ancient), line items cross-check with ±30% tolerance.
Produces confidence score 0.0-1.0 and ValidationWarning list."
```

---

### Task 4: Module B - PlatformOcrService (Dart Side)

**Files:**
- Modify: `lib/infrastructure/ml/ocr/ocr_service.dart` (already created in Task 2)
- Create: `lib/infrastructure/ml/ocr/platform_ocr_service.dart`
- Create: `test/unit/infrastructure/ml/ocr/platform_ocr_service_test.dart`

**Step 1: Write MethodChannel mock test**

```dart
// test/unit/infrastructure/ml/ocr/platform_ocr_service_test.dart

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/ml/ocr/platform_ocr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlatformOcrService service;

  setUp(() {
    service = PlatformOcrService();
  });

  group('PlatformOcrService', () {
    test('returns OCRResult from successful platform call', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.homepocket/ocr'),
        (MethodCall call) async {
          expect(call.method, 'recognizeText');
          expect(call.arguments['path'], isNotNull);
          return {
            'text': 'セブンイレブン\n合計 ¥580',
            'lines': [
              {
                'text': 'セブンイレブン',
                'x': 0.15,
                'y': 0.02,
                'width': 0.70,
                'height': 0.04,
                'confidence': 0.98,
              },
              {
                'text': '合計 ¥580',
                'x': 0.10,
                'y': 0.60,
                'width': 0.80,
                'height': 0.04,
                'confidence': 0.95,
              },
            ],
          };
        },
      );

      // Create a temp file for the test
      final tempFile = File('${Directory.systemTemp.path}/test_ocr.png');
      await tempFile.writeAsBytes([0x89, 0x50, 0x4E, 0x47]); // PNG header

      try {
        final result = await service.recognizeText(tempFile);
        expect(result.text, 'セブンイレブン\n合計 ¥580');
        expect(result.lines, hasLength(2));
        expect(result.lines[0].text, 'セブンイレブン');
        expect(result.lines[0].confidence, 0.98);
        expect(result.lines[1].text, '合計 ¥580');
        expect(result.lines[1].y, 0.60);
      } finally {
        tempFile.deleteSync();
      }
    });

    test('returns empty result when platform returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.homepocket/ocr'),
        (MethodCall call) async => null,
      );

      final tempFile = File('${Directory.systemTemp.path}/test_ocr.png');
      await tempFile.writeAsBytes([0x89, 0x50, 0x4E, 0x47]);

      try {
        final result = await service.recognizeText(tempFile);
        expect(result.isEmpty, isTrue);
        expect(result.lines, isEmpty);
      } finally {
        tempFile.deleteSync();
      }
    });

    test('throws on platform error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.homepocket/ocr'),
        (MethodCall call) async {
          throw PlatformException(code: 'OCR_ERROR', message: 'Failed');
        },
      );

      final tempFile = File('${Directory.systemTemp.path}/test_ocr.png');
      await tempFile.writeAsBytes([0x89, 0x50, 0x4E, 0x47]);

      try {
        expect(
          () => service.recognizeText(tempFile),
          throwsA(isA<PlatformException>()),
        );
      } finally {
        tempFile.deleteSync();
      }
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/infrastructure/ml/ocr/platform_ocr_service_test.dart`
Expected: FAIL - `platform_ocr_service.dart` doesn't exist.

**Step 3: Implement PlatformOcrService**

```dart
// lib/infrastructure/ml/ocr/platform_ocr_service.dart

import 'dart:io';
import 'package:flutter/services.dart';
import 'ocr_service.dart';

/// MethodChannel-based OCR service.
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

**Step 4: Run tests to verify they pass**

Run: `flutter test test/unit/infrastructure/ml/ocr/platform_ocr_service_test.dart`
Expected: All tests PASS.

**Step 5: Run analyzer**

Run: `flutter analyze lib/infrastructure/ml/ocr/`
Expected: No issues found.

**Step 6: Commit**

```bash
git add lib/infrastructure/ml/ocr/platform_ocr_service.dart \
        test/unit/infrastructure/ml/ocr/platform_ocr_service_test.dart
git commit -m "feat(ocr): implement Module B - PlatformOcrService via MethodChannel

Dart-side MethodChannel wrapper for native OCR. Parses platform response
into OCRResult with normalized bounding boxes. Tested with mock channel."
```

---

### Task 5: iOS Native OCR (OcrChannel.swift)

**Files:**
- Create: `ios/Runner/OcrChannel.swift`
- Modify: `ios/Runner/AppDelegate.swift` (register channel)

**Step 1: Read current AppDelegate**

Read: `ios/Runner/AppDelegate.swift`
Understand the existing structure.

**Step 2: Create OcrChannel.swift**

```swift
// ios/Runner/OcrChannel.swift

import Flutter
import Vision
import UIKit

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
        let url = URL(fileURLWithPath: path)
        guard let imageData = try? Data(contentsOf: url),
              let ciImage = CIImage(data: imageData) else {
            result(FlutterError(code: "LOAD_FAILED", message: "Cannot load image at \(path)", details: nil))
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                DispatchQueue.main.async {
                    result(FlutterError(code: "OCR_ERROR", message: error.localizedDescription, details: nil))
                }
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    result(["text": "", "lines": [[String: Any]]()]);
                }
                return
            }

            var lines = [[String: Any]]()
            var fullText = [String]()

            for obs in observations {
                guard let candidate = obs.topCandidates(1).first else { continue }
                let box = obs.boundingBox // Vision: bottom-left origin, normalized
                lines.append([
                    "text": candidate.string,
                    "x": box.origin.x,
                    "y": 1.0 - box.origin.y - box.height, // Convert to top-left origin
                    "width": box.width,
                    "height": box.height,
                    "confidence": candidate.confidence,
                ])
                fullText.append(candidate.string)
            }

            DispatchQueue.main.async {
                result(["text": fullText.joined(separator: "\n"), "lines": lines])
            }
        }

        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["ja", "zh-Hans", "zh-Hant", "en"]
        request.usesLanguageCorrection = true

        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "OCR_ERROR", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
}
```

**Step 3: Register channel in AppDelegate**

Modify `ios/Runner/AppDelegate.swift` to add:

```swift
// Inside application(_:didFinishLaunchingWithOptions:), after GeneratedPluginRegistrant.register:
let controller = window?.rootViewController as! FlutterViewController
OcrChannel.register(with: controller.binaryMessenger)
```

**Step 4: Verify iOS build**

Run: `cd ios && pod install && cd .. && flutter build ios --simulator --no-codesign`
Expected: Build succeeds without errors.

**Step 5: Commit**

```bash
git add ios/Runner/OcrChannel.swift ios/Runner/AppDelegate.swift
git commit -m "feat(ocr): add iOS native OCR via Vision Framework

VNRecognizeTextRequest with accurate recognition level.
Supports ja, zh-Hans, zh-Hant, en languages.
Returns normalized bounding boxes (top-left origin)."
```

---

### Task 6: Android Native OCR (OcrChannel.kt)

**Files:**
- Create: `android/app/src/main/kotlin/com/homepocket/home_pocket/OcrChannel.kt`
- Modify: `android/app/src/main/kotlin/com/homepocket/home_pocket/MainActivity.kt`
- Modify: `android/app/build.gradle` (add ML Kit dependency)

**Step 1: Read current MainActivity and build.gradle**

Read: `android/app/src/main/kotlin/com/homepocket/home_pocket/MainActivity.kt`
Read: `android/app/build.gradle`

**Step 2: Add ML Kit dependency to build.gradle**

In `android/app/build.gradle`, add to dependencies:

```groovy
// ML Kit Text Recognition v2 (Japanese)
implementation 'com.google.mlkit:text-recognition-japanese:16.0.1'
```

**Step 3: Create OcrChannel.kt**

```kotlin
// android/app/src/main/kotlin/com/homepocket/home_pocket/OcrChannel.kt

package com.homepocket.home_pocket

import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class OcrChannel(messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {

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

        val path = call.argument<String>("path")
        if (path == null) {
            result.error("INVALID_ARGS", "Missing 'path' argument", null)
            return
        }

        val file = File(path)
        if (!file.exists()) {
            result.error("FILE_NOT_FOUND", "Image file not found: $path", null)
            return
        }

        val image: InputImage
        try {
            image = InputImage.fromFilePath(
                android.app.Application().applicationContext,
                Uri.fromFile(file)
            )
        } catch (e: Exception) {
            // Fallback: load from file directly
            try {
                image = InputImage.fromFilePath(
                    null as android.content.Context,
                    Uri.fromFile(file)
                )
            } catch (e2: Exception) {
                result.error("LOAD_FAILED", "Cannot load image: ${e.message}", null)
                return
            }
        }

        recognizer.process(image)
            .addOnSuccessListener { visionText ->
                val lines = mutableListOf<Map<String, Any>>()

                // Compute image dimensions from bounding boxes
                var maxRight = 1
                var maxBottom = 1
                for (block in visionText.textBlocks) {
                    for (line in block.lines) {
                        val box = line.boundingBox ?: continue
                        if (box.right > maxRight) maxRight = box.right
                        if (box.bottom > maxBottom) maxBottom = box.bottom
                    }
                }
                val imageWidth = maxRight.toDouble()
                val imageHeight = maxBottom.toDouble()

                for (block in visionText.textBlocks) {
                    for (line in block.lines) {
                        val box = line.boundingBox ?: continue
                        lines.add(
                            mapOf(
                                "text" to line.text,
                                "x" to (box.left / imageWidth),
                                "y" to (box.top / imageHeight),
                                "width" to (box.width() / imageWidth),
                                "height" to (box.height() / imageHeight),
                                "confidence" to (line.confidence?.toDouble() ?: 1.0),
                            )
                        )
                    }
                }

                result.success(
                    mapOf(
                        "text" to visionText.text,
                        "lines" to lines,
                    )
                )
            }
            .addOnFailureListener { e ->
                result.error("OCR_ERROR", e.localizedMessage, null)
            }
    }
}
```

**Step 4: Register in MainActivity**

Modify `android/app/src/main/kotlin/com/homepocket/home_pocket/MainActivity.kt`:

```kotlin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        OcrChannel.register(flutterEngine.dartExecutor.binaryMessenger)
    }
}
```

**Step 5: Verify Android build**

Run: `flutter build apk --debug`
Expected: Build succeeds.

**Step 6: Commit**

```bash
git add android/app/src/main/kotlin/com/homepocket/home_pocket/OcrChannel.kt \
        android/app/src/main/kotlin/com/homepocket/home_pocket/MainActivity.kt \
        android/app/build.gradle
git commit -m "feat(ocr): add Android native OCR via ML Kit Text Recognition v2

Japanese text recognizer with bounding box normalization.
Registered via MainActivity.configureFlutterEngine."
```

---

### Task 7: Dependencies + Module A - ImagePreprocessor

**Files:**
- Modify: `pubspec.yaml` (add opencv_dart)
- Create: `lib/infrastructure/ml/image_preprocessor.dart`
- Create: `test/unit/infrastructure/ml/image_preprocessor_test.dart`

**Step 1: Add opencv_dart dependency**

In `pubspec.yaml`, add under dependencies:

```yaml
  opencv_dart: ^2.2.0
```

Run: `flutter pub get`
Expected: Resolves successfully.

**Step 2: Write basic test for ImagePreprocessor**

```dart
// test/unit/infrastructure/ml/image_preprocessor_test.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/ml/image_preprocessor.dart';

void main() {
  late ImagePreprocessor preprocessor;

  setUp(() {
    preprocessor = ImagePreprocessor();
  });

  group('ImagePreprocessor', () {
    test('returns null for empty bytes', () async {
      final result = await preprocessor.process(Uint8List(0));
      expect(result, isNull);
    });

    test('returns null for invalid image bytes', () async {
      final result = await preprocessor.process(Uint8List.fromList([1, 2, 3]));
      expect(result, isNull);
    });

    // Note: Tests with actual images require opencv_dart native libraries
    // and are better suited for integration tests on device.
    // The Isolate-based processing prevents testing in unit test environment.
  });
}
```

**Step 3: Implement ImagePreprocessor**

```dart
// lib/infrastructure/ml/image_preprocessor.dart

import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:opencv_dart/opencv_dart.dart' as cv;

/// Module A: Image preprocessing pipeline using OpenCV.
///
/// Transforms raw camera images into OCR-optimized images:
/// 1. Decode → 2. Resize → 3. Perspective correct → 4. Binarize → 5. Sharpen → 6. Encode
///
/// Runs in Isolate to avoid blocking UI thread.
class ImagePreprocessor {
  static const int _maxDimension = 2048;

  /// Full preprocessing pipeline. Runs in Isolate.
  /// Returns processed image file, or null on failure.
  Future<File?> process(Uint8List imageBytes) async {
    if (imageBytes.isEmpty) return null;
    try {
      return await Isolate.run(() => _processSync(imageBytes));
    } catch (_) {
      return null;
    }
  }

  static File? _processSync(Uint8List bytes) {
    // 1. Decode
    final mat = cv.imdecode(bytes, cv.IMREAD_COLOR);
    if (mat.isEmpty) return null;

    try {
      // 2. Resize (long edge <= 2048px)
      final resized = _resize(mat);

      // 3. Perspective correction (best effort)
      final corrected = _perspectiveCorrect(resized) ?? resized;

      // 4. Grayscale + adaptive threshold (binarization)
      final gray = cv.cvtColor(corrected, cv.COLOR_BGR2GRAY);
      final binary = cv.adaptiveThreshold(
        gray,
        255,
        cv.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv.THRESH_BINARY,
        blockSize: 15,
        C: 10,
      );

      // 5. Sharpen (unsharp mask for faded thermal paper)
      final sharpened = _sharpen(binary);

      // 6. Encode to PNG temp file
      final tempDir = Directory.systemTemp.createTempSync('ocr_');
      final outFile = File('${tempDir.path}/processed.png');
      cv.imwrite(outFile.path, sharpened);

      return outFile;
    } catch (_) {
      return null;
    }
  }

  static cv.Mat _resize(cv.Mat src) {
    final maxDim = src.width > src.height ? src.width : src.height;
    if (maxDim <= _maxDimension) return src;
    final scale = _maxDimension / maxDim;
    return cv.resize(
      src,
      (src.width * scale).round(),
      (src.height * scale).round(),
    );
  }

  static cv.Mat? _perspectiveCorrect(cv.Mat src) {
    try {
      // Grayscale → Blur → Canny edge detection
      final gray = cv.cvtColor(src, cv.COLOR_BGR2GRAY);
      final blurred = cv.gaussianBlur(gray, (5, 5), 0);
      final edges = cv.canny(blurred, 50, 150);

      // Find contours, look for largest quadrilateral
      final (contours, _) = cv.findContours(
        edges,
        cv.RETR_EXTERNAL,
        cv.CHAIN_APPROX_SIMPLE,
      );

      if (contours.isEmpty) return null;

      // Sort by area, largest first
      final sorted = contours.toList()
        ..sort((a, b) =>
            cv.contourArea(b).compareTo(cv.contourArea(a)));

      for (final contour in sorted.take(5)) {
        final peri = cv.arcLength(contour, true);
        final approx = cv.approxPolyDP(contour, 0.02 * peri, true);

        if (approx.length == 4) {
          // Found a quadrilateral - apply perspective transform
          return _applyPerspective(src, approx);
        }
      }

      return null; // No valid quadrilateral found
    } catch (_) {
      return null;
    }
  }

  static cv.Mat? _applyPerspective(cv.Mat src, cv.VecPoint approx) {
    try {
      // Order points: top-left, top-right, bottom-right, bottom-left
      final pts = <cv.Point>[];
      for (var i = 0; i < approx.length; i++) {
        pts.add(approx[i]);
      }

      // Sort by Y, then X to get ordered corners
      pts.sort((a, b) => a.y != b.y ? a.y.compareTo(b.y) : a.x.compareTo(b.x));
      final topLeft = pts[0].x < pts[1].x ? pts[0] : pts[1];
      final topRight = pts[0].x < pts[1].x ? pts[1] : pts[0];
      final bottomLeft = pts[2].x < pts[3].x ? pts[2] : pts[3];
      final bottomRight = pts[2].x < pts[3].x ? pts[3] : pts[2];

      // Calculate destination dimensions
      final widthTop = _distance(topLeft, topRight);
      final widthBottom = _distance(bottomLeft, bottomRight);
      final maxWidth = widthTop > widthBottom ? widthTop : widthBottom;

      final heightLeft = _distance(topLeft, bottomLeft);
      final heightRight = _distance(topRight, bottomRight);
      final maxHeight = heightLeft > heightRight ? heightLeft : heightRight;

      final srcPoints = cv.VecPoint([topLeft, topRight, bottomRight, bottomLeft]);
      final dstPoints = cv.VecPoint([
        cv.Point(0, 0),
        cv.Point(maxWidth.toInt(), 0),
        cv.Point(maxWidth.toInt(), maxHeight.toInt()),
        cv.Point(0, maxHeight.toInt()),
      ]);

      final m = cv.getPerspectiveTransform(srcPoints, dstPoints);
      return cv.warpPerspective(
        src,
        m,
        (maxWidth.toInt(), maxHeight.toInt()),
      );
    } catch (_) {
      return null;
    }
  }

  static double _distance(cv.Point a, cv.Point b) {
    final dx = (a.x - b.x).toDouble();
    final dy = (a.y - b.y).toDouble();
    return (dx * dx + dy * dy);
  }

  static cv.Mat _sharpen(cv.Mat src) {
    final blurred = cv.gaussianBlur(src, (0, 0), sigmaX: 3);
    return cv.addWeighted(src, 1.5, blurred, -0.5, 0);
  }
}
```

**Step 4: Run tests**

Run: `flutter test test/unit/infrastructure/ml/image_preprocessor_test.dart`
Expected: Basic tests pass. (Note: opencv_dart tests may require native libraries. If tests fail due to FFI issues in test environment, that's expected - mark as integration test.)

**Step 5: Run analyzer**

Run: `flutter analyze lib/infrastructure/ml/image_preprocessor.dart`
Expected: No issues found.

**Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock \
        lib/infrastructure/ml/image_preprocessor.dart \
        test/unit/infrastructure/ml/image_preprocessor_test.dart
git commit -m "feat(ocr): implement Module A - ImagePreprocessor with opencv_dart

6-step pipeline: decode → resize → perspective correct → binarize → sharpen → encode.
Runs in Isolate. Graceful degradation when perspective correction fails.
Added opencv_dart ^2.2.0 dependency."
```

---

### Task 8: Photo Encryption Service

**Files:**
- Create: `lib/infrastructure/crypto/services/photo_encryption_service.dart`
- Create: `test/unit/infrastructure/crypto/photo_encryption_service_test.dart`

**Step 1: Read existing crypto services for patterns**

Read: `lib/infrastructure/crypto/services/field_encryption_service.dart`
Understand encryption patterns used in the project.

**Step 2: Write tests**

```dart
// test/unit/infrastructure/crypto/photo_encryption_service_test.dart

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/crypto/services/photo_encryption_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';

class MockKeyManager extends Mock implements KeyManager {}

void main() {
  // Note: Full encryption tests require platform channels (flutter_secure_storage).
  // These tests verify the service's public API contract.

  group('PhotoEncryptionService', () {
    test('can be instantiated with KeyManager', () {
      final mockKeyManager = MockKeyManager();
      final service = PhotoEncryptionService(keyManager: mockKeyManager);
      expect(service, isNotNull);
    });

    // Integration tests on device will verify:
    // - encrypt() produces non-empty encrypted bytes
    // - decrypt() recovers original bytes
    // - computeHash() produces consistent SHA-256 hash
    // - encrypted data != original data
  });
}
```

**Step 3: Implement PhotoEncryptionService**

```dart
// lib/infrastructure/crypto/services/photo_encryption_service.dart

import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';

/// AES-256-GCM encryption service for receipt photos.
///
/// Encrypts photo bytes before storage and provides
/// SHA-256 hash for linking photos to transactions.
class PhotoEncryptionService {
  final KeyManager _keyManager;
  final AesGcm _aesGcm = AesGcm.with256bits();

  PhotoEncryptionService({required KeyManager keyManager})
      : _keyManager = keyManager;

  /// Encrypt photo bytes using AES-256-GCM.
  /// Returns encrypted bytes (nonce + ciphertext + mac).
  Future<Uint8List> encrypt(Uint8List photoBytes) async {
    final secretKey = await _derivePhotoKey();
    final secretBox = await _aesGcm.encrypt(
      photoBytes,
      secretKey: secretKey,
    );

    // Pack: nonce (12) + ciphertext + mac (16)
    final result = Uint8List(
      secretBox.nonce.length + secretBox.cipherText.length + secretBox.mac.bytes.length,
    );
    var offset = 0;
    result.setRange(offset, offset + secretBox.nonce.length, secretBox.nonce);
    offset += secretBox.nonce.length;
    result.setRange(offset, offset + secretBox.cipherText.length, secretBox.cipherText);
    offset += secretBox.cipherText.length;
    result.setRange(offset, offset + secretBox.mac.bytes.length, secretBox.mac.bytes);

    return result;
  }

  /// Decrypt photo bytes encrypted with encrypt().
  Future<Uint8List> decrypt(Uint8List encryptedBytes) async {
    final secretKey = await _derivePhotoKey();

    // Unpack: nonce (12) + ciphertext + mac (16)
    const nonceLength = 12;
    const macLength = 16;
    final nonce = encryptedBytes.sublist(0, nonceLength);
    final cipherText = encryptedBytes.sublist(
      nonceLength,
      encryptedBytes.length - macLength,
    );
    final mac = Mac(encryptedBytes.sublist(encryptedBytes.length - macLength));

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: mac,
    );

    final decrypted = await _aesGcm.decrypt(secretBox, secretKey: secretKey);
    return Uint8List.fromList(decrypted);
  }

  /// Compute SHA-256 hash of photo bytes for linking to transactions.
  Future<String> computeHash(Uint8List photoBytes) async {
    final hash = await Sha256().hash(photoBytes);
    return hash.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  Future<SecretKey> _derivePhotoKey() async {
    // Derive a photo-specific key from the device master key
    return _keyManager.deriveKey(purpose: 'photo_encryption');
  }
}
```

**Note:** The exact `deriveKey` method signature depends on your existing KeyManager API. Check `lib/infrastructure/crypto/services/key_manager.dart` and adjust accordingly. If `deriveKey` doesn't exist, use whatever key derivation pattern is already established (e.g., HKDF).

**Step 4: Run tests**

Run: `flutter test test/unit/infrastructure/crypto/photo_encryption_service_test.dart`
Expected: Pass (basic instantiation test).

**Step 5: Commit**

```bash
git add lib/infrastructure/crypto/services/photo_encryption_service.dart \
        test/unit/infrastructure/crypto/photo_encryption_service_test.dart
git commit -m "feat(ocr): add PhotoEncryptionService for AES-256-GCM photo encryption

Encrypts receipt photos before storage. Provides SHA-256 hash
for linking encrypted photos to transactions."
```

---

### Task 9: Data Layer (receipt_photos table + DAO + Repository)

**Files:**
- Create: `lib/data/tables/receipt_photos_table.dart`
- Create: `lib/data/daos/receipt_photo_dao.dart`
- Create: `lib/data/repositories/receipt_photo_repository_impl.dart`
- Create: `lib/features/accounting/domain/repositories/receipt_photo_repository.dart`
- Modify: `lib/data/app_database.dart` (add table + DAO, bump schema version)

**Step 1: Read current database setup**

Read: `lib/data/app_database.dart`
Read: `lib/data/tables/` (list all files to understand patterns)
Read one existing table file for pattern reference.
Read one existing DAO file for pattern reference.

**Step 2: Create receipt_photos table**

```dart
// lib/data/tables/receipt_photos_table.dart

import 'package:drift/drift.dart';

/// Stores encrypted receipt photos linked to transactions.
class ReceiptPhotos extends Table {
  /// Unique photo ID (UUID).
  TextColumn get id => text()();

  /// SHA-256 hash of original photo (links to Transaction.photoHash).
  TextColumn get photoHash => text()();

  /// Encrypted photo blob (AES-256-GCM).
  BlobColumn get encryptedData => blob()();

  /// Original filename for reference.
  TextColumn get fileName => text().withDefault(const Constant(''))();

  /// File size in bytes (before encryption).
  IntColumn get originalSize => integer().withDefault(const Constant(0))();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime()();

  /// Optional link to transaction ID.
  TextColumn get transactionId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  List<TableIndex> get customIndices => [
    TableIndex(
      name: 'idx_receipt_photos_photo_hash',
      columns: {#photoHash},
    ),
    TableIndex(
      name: 'idx_receipt_photos_transaction_id',
      columns: {#transactionId},
    ),
  ];
}
```

**Step 3: Create ReceiptPhoto DAO**

```dart
// lib/data/daos/receipt_photo_dao.dart

import 'dart:typed_data';
import 'package:drift/drift.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/tables/receipt_photos_table.dart';

part 'receipt_photo_dao.g.dart';

@DriftAccessor(tables: [ReceiptPhotos])
class ReceiptPhotoDao extends DatabaseAccessor<AppDatabase>
    with _$ReceiptPhotoDaoMixin {
  ReceiptPhotoDao(super.db);

  /// Insert a new receipt photo.
  Future<void> insertPhoto({
    required String id,
    required String photoHash,
    required Uint8List encryptedData,
    required String fileName,
    required int originalSize,
    required DateTime createdAt,
    String? transactionId,
  }) async {
    await into(receiptPhotos).insert(
      ReceiptPhotosCompanion.insert(
        id: id,
        photoHash: photoHash,
        encryptedData: encryptedData,
        fileName: fileName,
        originalSize: Value(originalSize),
        createdAt: createdAt,
        transactionId: Value(transactionId),
      ),
    );
  }

  /// Get photo by hash.
  Future<ReceiptPhoto?> getByHash(String photoHash) async {
    return (select(receiptPhotos)
          ..where((t) => t.photoHash.equals(photoHash)))
        .getSingleOrNull();
  }

  /// Get photo by transaction ID.
  Future<ReceiptPhoto?> getByTransactionId(String transactionId) async {
    return (select(receiptPhotos)
          ..where((t) => t.transactionId.equals(transactionId)))
        .getSingleOrNull();
  }

  /// Link photo to transaction.
  Future<void> linkToTransaction(String photoHash, String transactionId) async {
    await (update(receiptPhotos)
          ..where((t) => t.photoHash.equals(photoHash)))
        .write(ReceiptPhotosCompanion(
      transactionId: Value(transactionId),
    ));
  }

  /// Delete photo by ID.
  Future<void> deletePhoto(String id) async {
    await (delete(receiptPhotos)..where((t) => t.id.equals(id))).go();
  }
}
```

**Step 4: Create abstract repository interface**

```dart
// lib/features/accounting/domain/repositories/receipt_photo_repository.dart

import 'dart:typed_data';

/// Abstract repository for receipt photo storage.
abstract class ReceiptPhotoRepository {
  /// Save encrypted photo and return its hash.
  Future<String> savePhoto({
    required Uint8List encryptedData,
    required String photoHash,
    required String fileName,
    required int originalSize,
  });

  /// Get encrypted photo data by hash.
  Future<Uint8List?> getPhotoByHash(String photoHash);

  /// Link photo to a transaction.
  Future<void> linkToTransaction(String photoHash, String transactionId);

  /// Delete photo by hash.
  Future<void> deleteByHash(String photoHash);
}
```

**Step 5: Create repository implementation**

```dart
// lib/data/repositories/receipt_photo_repository_impl.dart

import 'dart:typed_data';
import 'package:home_pocket/data/daos/receipt_photo_dao.dart';
import 'package:home_pocket/features/accounting/domain/repositories/receipt_photo_repository.dart';
import 'package:uuid/uuid.dart';

class ReceiptPhotoRepositoryImpl implements ReceiptPhotoRepository {
  final ReceiptPhotoDao _dao;
  final Uuid _uuid = const Uuid();

  ReceiptPhotoRepositoryImpl({required ReceiptPhotoDao dao}) : _dao = dao;

  @override
  Future<String> savePhoto({
    required Uint8List encryptedData,
    required String photoHash,
    required String fileName,
    required int originalSize,
  }) async {
    final id = _uuid.v4();
    await _dao.insertPhoto(
      id: id,
      photoHash: photoHash,
      encryptedData: encryptedData,
      fileName: fileName,
      originalSize: originalSize,
      createdAt: DateTime.now(),
    );
    return photoHash;
  }

  @override
  Future<Uint8List?> getPhotoByHash(String photoHash) async {
    final photo = await _dao.getByHash(photoHash);
    return photo?.encryptedData;
  }

  @override
  Future<void> linkToTransaction(String photoHash, String transactionId) async {
    await _dao.linkToTransaction(photoHash, transactionId);
  }

  @override
  Future<void> deleteByHash(String photoHash) async {
    final photo = await _dao.getByHash(photoHash);
    if (photo != null) {
      await _dao.deletePhoto(photo.id);
    }
  }
}
```

**Step 6: Register table in AppDatabase**

Modify `lib/data/app_database.dart`:
1. Add `ReceiptPhotos` to `@DriftDatabase(tables: [...])` list
2. Add `ReceiptPhotoDao` to `daos: [...]` list
3. Bump `schemaVersion` by 1
4. Add migration for the new table

**Step 7: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: All generated files created successfully.

**Step 8: Run analyzer**

Run: `flutter analyze lib/data/tables/receipt_photos_table.dart lib/data/daos/receipt_photo_dao.dart lib/data/repositories/receipt_photo_repository_impl.dart`
Expected: No issues.

**Step 9: Commit**

```bash
git add lib/data/tables/receipt_photos_table.dart \
        lib/data/daos/receipt_photo_dao.dart \
        lib/data/repositories/receipt_photo_repository_impl.dart \
        lib/features/accounting/domain/repositories/receipt_photo_repository.dart \
        lib/data/app_database.dart
git commit -m "feat(ocr): add receipt_photos data layer

Drift table with encrypted blob storage, DAO with hash/transaction lookups,
repository interface + implementation. Schema version bumped with migration."
```

---

### Task 10: ScanReceiptUseCase (Orchestration)

**Files:**
- Create: `lib/application/ocr/scan_receipt_use_case.dart`
- Create: `test/unit/application/ocr/scan_receipt_use_case_test.dart`

**Step 1: Write tests with mocked dependencies**

```dart
// test/unit/application/ocr/scan_receipt_use_case_test.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:home_pocket/application/ocr/scan_receipt_use_case.dart';
import 'package:home_pocket/application/ocr/receipt_parser.dart';
import 'package:home_pocket/application/ocr/receipt_validator.dart';
import 'package:home_pocket/infrastructure/ml/ocr/ocr_service.dart';
import 'package:home_pocket/infrastructure/ml/image_preprocessor.dart';

class MockOCRService extends Mock implements OCRService {}
class MockImagePreprocessor extends Mock implements ImagePreprocessor {}

// We use real ReceiptParser and ReceiptValidator (pure logic, no mocking needed)

void main() {
  late ScanReceiptUseCase useCase;
  late MockOCRService mockOcr;
  late MockImagePreprocessor mockPreprocessor;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(File(''));
  });

  setUp(() {
    mockOcr = MockOCRService();
    mockPreprocessor = MockImagePreprocessor();

    useCase = ScanReceiptUseCase(
      ocrService: mockOcr,
      preprocessor: mockPreprocessor,
      parser: ReceiptParser(),
      validator: ReceiptValidator(),
    );
  });

  group('ScanReceiptUseCase', () {
    test('full pipeline returns validated result', () async {
      final tempFile = File('${Directory.systemTemp.path}/test_processed.png');
      await tempFile.writeAsBytes([1, 2, 3]);

      when(() => mockPreprocessor.process(any()))
          .thenAnswer((_) async => tempFile);

      when(() => mockOcr.recognizeText(any()))
          .thenAnswer((_) async => const OCRResult(
                text: 'セブンイレブン\n2026/02/25\n合計 ¥580',
                lines: [
                  OCRLine(
                    text: 'セブンイレブン',
                    x: 0.15, y: 0.02, width: 0.7, height: 0.04,
                  ),
                  OCRLine(
                    text: '2026/02/25',
                    x: 0.2, y: 0.06, width: 0.6, height: 0.03,
                  ),
                  OCRLine(
                    text: '合計 ¥580',
                    x: 0.1, y: 0.6, width: 0.8, height: 0.04,
                  ),
                ],
              ));

      final result = await useCase.execute(Uint8List.fromList([1, 2, 3]));

      expect(result.amount, 580);
      expect(result.date, DateTime(2026, 2, 25));
      expect(result.merchant, 'セブンイレブン');
      expect(result.confidence, greaterThan(0.5));

      // Cleanup
      if (tempFile.existsSync()) tempFile.deleteSync();
    });

    test('returns empty result when preprocessing fails', () async {
      when(() => mockPreprocessor.process(any()))
          .thenAnswer((_) async => null);

      final result = await useCase.execute(Uint8List.fromList([1, 2, 3]));

      expect(result.amount, isNull);
      expect(result.confidence, 0.0);
    });

    test('returns empty result when OCR returns empty', () async {
      final tempFile = File('${Directory.systemTemp.path}/test_processed.png');
      await tempFile.writeAsBytes([1, 2, 3]);

      when(() => mockPreprocessor.process(any()))
          .thenAnswer((_) async => tempFile);

      when(() => mockOcr.recognizeText(any()))
          .thenAnswer((_) async => OCRResult.empty);

      final result = await useCase.execute(Uint8List.fromList([1, 2, 3]));

      expect(result.amount, isNull);

      if (tempFile.existsSync()) tempFile.deleteSync();
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/application/ocr/scan_receipt_use_case_test.dart`
Expected: FAIL - `scan_receipt_use_case.dart` doesn't exist.

**Step 3: Implement ScanReceiptUseCase**

```dart
// lib/application/ocr/scan_receipt_use_case.dart

import 'dart:typed_data';
import 'package:home_pocket/application/ocr/models/ocr_scan_result.dart';
import 'package:home_pocket/application/ocr/receipt_parser.dart';
import 'package:home_pocket/application/ocr/receipt_validator.dart';
import 'package:home_pocket/infrastructure/ml/image_preprocessor.dart';
import 'package:home_pocket/infrastructure/ml/ocr/ocr_service.dart';

/// Orchestrates the complete OCR scan pipeline:
/// [A] ImagePreprocessor → [B] OCRService → [C] ReceiptParser → [D] ReceiptValidator
class ScanReceiptUseCase {
  final OCRService ocrService;
  final ImagePreprocessor preprocessor;
  final ReceiptParser parser;
  final ReceiptValidator validator;

  ScanReceiptUseCase({
    required this.ocrService,
    required this.preprocessor,
    required this.parser,
    required this.validator,
  });

  /// Execute the full scan pipeline on raw image bytes.
  Future<OcrScanResult> execute(Uint8List imageBytes) async {
    // Module A: Image preprocessing
    final processedFile = await preprocessor.process(imageBytes);
    if (processedFile == null) {
      return const OcrScanResult(confidence: 0.0);
    }

    try {
      // Module B: OCR text recognition
      final ocrResult = await ocrService.recognizeText(processedFile);
      if (ocrResult.isEmpty) {
        return const OcrScanResult(confidence: 0.0);
      }

      // Module C: Heuristic extraction
      final parsed = parser.parse(ocrResult);

      // Module D: Validation
      final validated = validator.validate(parsed);

      return OcrScanResult(
        amount: validated.amount,
        date: validated.date,
        merchant: validated.merchant,
        confidence: validated.confidence,
        warnings: validated.warnings,
      );
    } finally {
      // Cleanup temp file
      try {
        if (processedFile.existsSync()) {
          processedFile.parent.deleteSync(recursive: true);
        }
      } catch (_) {}
    }
  }
}
```

**Step 4: Run tests**

Run: `flutter test test/unit/application/ocr/scan_receipt_use_case_test.dart`
Expected: All tests PASS.

**Step 5: Run analyzer**

Run: `flutter analyze lib/application/ocr/scan_receipt_use_case.dart`
Expected: No issues.

**Step 6: Commit**

```bash
git add lib/application/ocr/scan_receipt_use_case.dart \
        test/unit/application/ocr/scan_receipt_use_case_test.dart
git commit -m "feat(ocr): implement ScanReceiptUseCase orchestrating A→B→C→D pipeline

Chains preprocessing, OCR recognition, heuristic parsing, and validation.
Returns OcrScanResult with amount, date, merchant, confidence.
Tested with mocked preprocessor and OCR service."
```

---

### Task 11: SaveReceiptPhotoUseCase

**Files:**
- Create: `lib/application/ocr/save_receipt_photo_use_case.dart`
- Create: `test/unit/application/ocr/save_receipt_photo_use_case_test.dart`

**Step 1: Write tests**

```dart
// test/unit/application/ocr/save_receipt_photo_use_case_test.dart

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:home_pocket/application/ocr/save_receipt_photo_use_case.dart';
import 'package:home_pocket/infrastructure/crypto/services/photo_encryption_service.dart';
import 'package:home_pocket/features/accounting/domain/repositories/receipt_photo_repository.dart';

class MockPhotoEncryptionService extends Mock implements PhotoEncryptionService {}
class MockReceiptPhotoRepository extends Mock implements ReceiptPhotoRepository {}

void main() {
  late SaveReceiptPhotoUseCase useCase;
  late MockPhotoEncryptionService mockEncryption;
  late MockReceiptPhotoRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    mockEncryption = MockPhotoEncryptionService();
    mockRepo = MockReceiptPhotoRepository();

    useCase = SaveReceiptPhotoUseCase(
      encryptionService: mockEncryption,
      repository: mockRepo,
    );
  });

  group('SaveReceiptPhotoUseCase', () {
    test('encrypts photo and saves, returns hash', () async {
      final originalBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final encryptedBytes = Uint8List.fromList([10, 20, 30, 40, 50]);
      const expectedHash = 'abc123def456';

      when(() => mockEncryption.encrypt(any()))
          .thenAnswer((_) async => encryptedBytes);
      when(() => mockEncryption.computeHash(any()))
          .thenAnswer((_) async => expectedHash);
      when(() => mockRepo.savePhoto(
            encryptedData: any(named: 'encryptedData'),
            photoHash: any(named: 'photoHash'),
            fileName: any(named: 'fileName'),
            originalSize: any(named: 'originalSize'),
          )).thenAnswer((_) async => expectedHash);

      final result = await useCase.execute(
        photoBytes: originalBytes,
        fileName: 'receipt_001.jpg',
      );

      expect(result, expectedHash);

      verify(() => mockEncryption.encrypt(originalBytes)).called(1);
      verify(() => mockEncryption.computeHash(originalBytes)).called(1);
      verify(() => mockRepo.savePhoto(
            encryptedData: encryptedBytes,
            photoHash: expectedHash,
            fileName: 'receipt_001.jpg',
            originalSize: 5,
          )).called(1);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/application/ocr/save_receipt_photo_use_case_test.dart`
Expected: FAIL.

**Step 3: Implement SaveReceiptPhotoUseCase**

```dart
// lib/application/ocr/save_receipt_photo_use_case.dart

import 'dart:typed_data';
import 'package:home_pocket/infrastructure/crypto/services/photo_encryption_service.dart';
import 'package:home_pocket/features/accounting/domain/repositories/receipt_photo_repository.dart';

/// Encrypts and persists receipt photos.
/// Returns photoHash for linking to transaction.
class SaveReceiptPhotoUseCase {
  final PhotoEncryptionService encryptionService;
  final ReceiptPhotoRepository repository;

  SaveReceiptPhotoUseCase({
    required this.encryptionService,
    required this.repository,
  });

  /// Encrypt photo and save to repository.
  /// Returns SHA-256 hash of original photo.
  Future<String> execute({
    required Uint8List photoBytes,
    required String fileName,
  }) async {
    // 1. Compute hash of original (for linking)
    final photoHash = await encryptionService.computeHash(photoBytes);

    // 2. Encrypt
    final encrypted = await encryptionService.encrypt(photoBytes);

    // 3. Persist
    await repository.savePhoto(
      encryptedData: encrypted,
      photoHash: photoHash,
      fileName: fileName,
      originalSize: photoBytes.length,
    );

    return photoHash;
  }
}
```

**Step 4: Run tests**

Run: `flutter test test/unit/application/ocr/save_receipt_photo_use_case_test.dart`
Expected: All tests PASS.

**Step 5: Commit**

```bash
git add lib/application/ocr/save_receipt_photo_use_case.dart \
        test/unit/application/ocr/save_receipt_photo_use_case_test.dart
git commit -m "feat(ocr): implement SaveReceiptPhotoUseCase

Encrypts receipt photos with AES-256-GCM, computes SHA-256 hash,
persists via ReceiptPhotoRepository. Returns photoHash for transaction linking."
```

---

### Task 12: OCR Providers (Riverpod Wiring)

**Files:**
- Create: `lib/features/accounting/presentation/providers/ocr_providers.dart`
- Modify: `lib/features/accounting/presentation/providers/repository_providers.dart` (add receipt photo repo provider)

**Step 1: Read current repository_providers.dart**

Read: `lib/features/accounting/presentation/providers/repository_providers.dart`
Understand the existing provider pattern.

**Step 2: Add receipt photo repository provider to repository_providers.dart**

Add to `repository_providers.dart`:

```dart
@riverpod
ReceiptPhotoRepository receiptPhotoRepository(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  final dao = ReceiptPhotoDao(database);
  return ReceiptPhotoRepositoryImpl(dao: dao);
}
```

**Step 3: Create ocr_providers.dart**

```dart
// lib/features/accounting/presentation/providers/ocr_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:home_pocket/application/ocr/receipt_parser.dart';
import 'package:home_pocket/application/ocr/receipt_validator.dart';
import 'package:home_pocket/application/ocr/scan_receipt_use_case.dart';
import 'package:home_pocket/application/ocr/save_receipt_photo_use_case.dart';
import 'package:home_pocket/infrastructure/ml/image_preprocessor.dart';
import 'package:home_pocket/infrastructure/ml/ocr/ocr_service.dart';
import 'package:home_pocket/infrastructure/ml/ocr/platform_ocr_service.dart';
import 'package:home_pocket/infrastructure/crypto/services/photo_encryption_service.dart';
import 'repository_providers.dart';

part 'ocr_providers.g.dart';

/// OCRService - keepAlive, MethodChannel should not be recreated
@Riverpod(keepAlive: true)
OCRService ocrService(Ref ref) {
  final service = PlatformOcrService();
  ref.onDispose(() => service.dispose());
  return service;
}

/// ImagePreprocessor - stateless
@riverpod
ImagePreprocessor imagePreprocessor(Ref ref) {
  return ImagePreprocessor();
}

/// ReceiptParser - stateless
@riverpod
ReceiptParser receiptParser(Ref ref) {
  return ReceiptParser();
}

/// ReceiptValidator - stateless
@riverpod
ReceiptValidator receiptValidator(Ref ref) {
  return ReceiptValidator();
}

/// ScanReceiptUseCase - orchestrates all pipeline modules
@riverpod
ScanReceiptUseCase scanReceiptUseCase(Ref ref) {
  return ScanReceiptUseCase(
    ocrService: ref.watch(ocrServiceProvider),
    preprocessor: ref.watch(imagePreprocessorProvider),
    parser: ref.watch(receiptParserProvider),
    validator: ref.watch(receiptValidatorProvider),
  );
}

/// PhotoEncryptionService
@riverpod
PhotoEncryptionService photoEncryptionService(Ref ref) {
  final keyManager = ref.watch(keyManagerProvider);
  return PhotoEncryptionService(keyManager: keyManager);
}

/// SaveReceiptPhotoUseCase
@riverpod
SaveReceiptPhotoUseCase saveReceiptPhotoUseCase(Ref ref) {
  return SaveReceiptPhotoUseCase(
    encryptionService: ref.watch(photoEncryptionServiceProvider),
    repository: ref.watch(receiptPhotoRepositoryProvider),
  );
}
```

**Note:** Adjust the `keyManagerProvider` import based on where it's currently defined in the project.

**Step 4: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: `.g.dart` files generated.

**Step 5: Run analyzer**

Run: `flutter analyze lib/features/accounting/presentation/providers/ocr_providers.dart`
Expected: No issues.

**Step 6: Commit**

```bash
git add lib/features/accounting/presentation/providers/ocr_providers.dart \
        lib/features/accounting/presentation/providers/repository_providers.dart
git commit -m "feat(ocr): add Riverpod providers for OCR pipeline

Wire all OCR modules: ImagePreprocessor, PlatformOcrService, ReceiptParser,
ReceiptValidator, ScanReceiptUseCase, SaveReceiptPhotoUseCase.
OCRService is keepAlive (MethodChannel reuse)."
```

---

### Task 13: Wire OcrScannerScreen to Real Pipeline

**Files:**
- Modify: `lib/features/accounting/presentation/screens/ocr_scanner_screen.dart`

**Step 1: Read current OcrScannerScreen stub**

Read: `lib/features/accounting/presentation/screens/ocr_scanner_screen.dart`
Understand the current stub UI structure.

**Step 2: Update OcrScannerScreen to use real pipeline**

Replace the stub logic with actual image_picker + ScanReceiptUseCase flow:

Key changes:
1. Add `image_picker` import for gallery/camera
2. Add shutter button handler that calls `ScanReceiptUseCase`
3. Add loading state during processing
4. Navigate to `TransactionConfirmScreen` with results
5. Handle errors with user-friendly messages

The screen should:
- On shutter tap: capture image via `image_picker`
- On gallery tap: pick from gallery via `image_picker`
- Show loading overlay during processing (Module A→B→C→D)
- On success: navigate to `TransactionConfirmScreen` with pre-filled data
- On failure: show error message with retry option

**Key implementation pattern:**

```dart
Future<void> _scanReceipt(WidgetRef ref, ImageSource source) async {
  final picker = ImagePicker();
  final image = await picker.pickImage(source: source);
  if (image == null) return; // User cancelled

  setState(() => _isProcessing = true);

  try {
    final bytes = await image.readAsBytes();

    // Save photo (encrypt + persist)
    final saveUseCase = ref.read(saveReceiptPhotoUseCaseProvider);
    final photoHash = await saveUseCase.execute(
      photoBytes: bytes,
      fileName: image.name,
    );

    // Scan receipt (A→B→C→D pipeline)
    final scanUseCase = ref.read(scanReceiptUseCaseProvider);
    final result = await scanUseCase.execute(bytes);

    // Navigate to confirm screen with results
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TransactionConfirmScreen(
            bookId: bookId,
            amount: result.amount,
            date: result.date,
            initialMerchant: result.merchant,
            categoryId: result.categoryId,
            parentCategoryId: result.parentCategoryId,
            photoHash: photoHash,
          ),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).ocrScanFailed)),
      );
    }
  } finally {
    if (mounted) setState(() => _isProcessing = false);
  }
}
```

**Step 3: Run analyzer**

Run: `flutter analyze lib/features/accounting/presentation/screens/ocr_scanner_screen.dart`
Expected: No issues.

**Step 4: Commit**

```bash
git add lib/features/accounting/presentation/screens/ocr_scanner_screen.dart
git commit -m "feat(ocr): wire OcrScannerScreen to real OCR pipeline

Connect image_picker to ScanReceiptUseCase for full A→B→C→D processing.
Navigate to TransactionConfirmScreen with extracted amount/date/merchant.
Includes loading state and error handling."
```

---

### Task 14: Localization Keys

**Files:**
- Modify: `lib/l10n/app_ja.arb`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_zh.arb`

**Step 1: Add missing OCR-related keys to all 3 ARB files**

```json
// Keys to add:
{
  "scanningReceipt": "レシートを読み取り中...",
  "@scanningReceipt": {"description": "OCR processing indicator"},

  "ocrScanFailed": "読み取りに失敗しました。もう一度お試しください。",
  "@ocrScanFailed": {"description": "OCR scan failure message"},

  "ocrLowConfidence": "読み取り結果の精度が低い可能性があります。確認してください。",
  "@ocrLowConfidence": {"description": "Low confidence warning"},

  "takePhoto": "撮影",
  "@takePhoto": {"description": "Camera capture button"},

  "chooseFromGallery": "アルバムから選択",
  "@chooseFromGallery": {"description": "Gallery selection button"},

  "receiptPhoto": "レシート写真",
  "@receiptPhoto": {"description": "Receipt photo label"}
}
```

Add equivalent translations for `app_en.arb` (English) and `app_zh.arb` (Chinese).

**Step 2: Run localization generation**

Run: `flutter gen-l10n`
Expected: No errors.

**Step 3: Run analyzer**

Run: `flutter analyze`
Expected: No issues related to localization.

**Step 4: Commit**

```bash
git add lib/l10n/app_ja.arb lib/l10n/app_en.arb lib/l10n/app_zh.arb \
        lib/generated/
git commit -m "feat(ocr): add localization keys for OCR scanning flow

Add keys: scanningReceipt, ocrScanFailed, ocrLowConfidence,
takePhoto, chooseFromGallery, receiptPhoto in ja/en/zh."
```

---

### Task 15: Final Verification & Cleanup

**Step 1: Run all tests**

Run: `flutter test`
Expected: All tests pass with 0 failures.

**Step 2: Run analyzer**

Run: `flutter analyze`
Expected: No issues found.

**Step 3: Verify code generation is clean**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: No errors.

**Step 4: Run formatter**

Run: `dart format .`
Expected: All files formatted.

**Step 5: Check test coverage**

Run: `flutter test --coverage`
Expected: ReceiptParser and ReceiptValidator at 90%+, overall OCR module at 80%+.

**Step 6: Review all new files**

Verify architectural compliance:
- [ ] Infrastructure code in `lib/infrastructure/ml/` and `lib/infrastructure/crypto/`
- [ ] Application code in `lib/application/ocr/`
- [ ] Data layer in `lib/data/`
- [ ] Domain interfaces in `lib/features/accounting/domain/repositories/`
- [ ] Providers in `lib/features/accounting/presentation/providers/`
- [ ] No feature folder contains `application/`, `infrastructure/`, or `data/` subdirectories

**Step 7: Final commit (if any remaining changes)**

```bash
git add -A
git commit -m "chore(ocr): final cleanup and verification for Phase 2 pipeline"
```

---

## Summary

| Task | Module | Effort | Testability |
|------|--------|--------|-------------|
| 1. Data Models | Foundation | 30 min | N/A (types) |
| 2. ReceiptParser | C | 2-3 hrs | Full TDD |
| 3. ReceiptValidator | D | 1-2 hrs | Full TDD |
| 4. PlatformOcrService | B (Dart) | 1-2 hrs | Mock MethodChannel |
| 5. iOS OcrChannel | B (Native) | 2-3 hrs | Device test only |
| 6. Android OcrChannel | B (Native) | 2-3 hrs | Device test only |
| 7. ImagePreprocessor | A | 2-3 hrs | Integration test |
| 8. PhotoEncryptionService | Crypto | 1-2 hrs | Integration test |
| 9. Data Layer | Data | 2-3 hrs | Integration test |
| 10. ScanReceiptUseCase | Orchestration | 1-2 hrs | Full TDD (mocked) |
| 11. SaveReceiptPhotoUseCase | Orchestration | 1 hr | Full TDD (mocked) |
| 12. OCR Providers | Wiring | 1 hr | N/A (config) |
| 13. Wire UI | Presentation | 2-3 hrs | Widget test |
| 14. Localization | i18n | 30 min | N/A |
| 15. Final Verification | QA | 1 hr | All tests |
| **Total** | | **~20-30 hrs** | |

## Key Risks

| Risk | Mitigation |
|------|------------|
| opencv_dart FFI incompatibility | Graceful degradation: skip preprocessing, pass raw image to OCR |
| MethodChannel not working on simulator | iOS Vision works on simulator; Android needs device |
| Perspective correction quality | Fallback: skip correction, proceed with binarization only |
| ML Kit Japanese model size (~15MB) | Downloaded on first use by Google Play Services |
| Photo encryption key derivation API mismatch | Check KeyManager API in Task 8, adapt as needed |
