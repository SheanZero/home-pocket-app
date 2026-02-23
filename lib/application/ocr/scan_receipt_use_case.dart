import 'dart:io';
import 'dart:typed_data';

import '../../infrastructure/ml/image_preprocessor.dart';
import '../../infrastructure/ml/ocr/ocr_service.dart';
import 'receipt_parser.dart';

/// Error types for OCR scanning — mapped to l10n keys in the UI layer.
enum OcrError {
  noImageSelected,
  preprocessingFailed,
  noTextRecognized,
  scanFailed,
}

/// Result of the OCR scan pipeline.
/// Contains primitives only — screen resolves merchantName → Category objects.
class OcrScanData {
  final int? amount;
  final DateTime? date;
  final String? merchantName;

  const OcrScanData({this.amount, this.date, this.merchantName});
}

/// Typed result wrapper for OCR scan operations.
class OcrScanResult {
  final OcrScanData? data;
  final OcrError? error;
  final bool isSuccess;

  const OcrScanResult._({this.data, this.error, required this.isSuccess});

  factory OcrScanResult.success(OcrScanData data) =>
      OcrScanResult._(data: data, isSuccess: true);

  factory OcrScanResult.failure(OcrError error) =>
      OcrScanResult._(error: error, isSuccess: false);

  bool get isError => !isSuccess;
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
  }) : _ocrService = ocrService,
       _preprocessor = preprocessor;

  /// Execute scan from raw image bytes.
  Future<OcrScanResult> executeFromBytes(Uint8List imageBytes) async {
    Directory? tempDir;
    try {
      // 1. Preprocess
      final processedBytes = _preprocessor.processBytes(imageBytes);
      if (processedBytes == null) {
        return OcrScanResult.failure(OcrError.preprocessingFailed);
      }

      // 2. Write to temp file for OCR engine
      tempDir = await Directory.systemTemp.createTemp('ocr_');
      final tempFile = File('${tempDir.path}/processed.png');
      await tempFile.writeAsBytes(processedBytes);

      // 3. OCR recognition
      final ocrResult = await _ocrService.recognizeText(tempFile);
      if (ocrResult.text.isEmpty) {
        return OcrScanResult.failure(OcrError.noTextRecognized);
      }

      // 4. Parse receipt data
      final parsed = _parser.parse(ocrResult.text);

      return OcrScanResult.success(
        OcrScanData(
          amount: parsed.amount,
          date: parsed.date,
          merchantName: parsed.merchant,
        ),
      );
    } catch (_) {
      return OcrScanResult.failure(OcrError.scanFailed);
    } finally {
      // Always clean up temp directory
      try {
        await tempDir?.delete(recursive: true);
      } catch (_) {}
    }
  }
}
