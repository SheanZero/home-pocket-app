import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/ocr/scan_receipt_use_case.dart';
import '../../../../infrastructure/ml/image_preprocessor.dart';
import '../../../../infrastructure/ml/ocr/mlkit_ocr_service.dart';
import '../../../../infrastructure/ml/ocr/ocr_service.dart';

part 'ocr_providers.g.dart';

/// OCRService — keepAlive because TextRecognizer is expensive to create.
/// Disposed when the app shuts down.
@Riverpod(keepAlive: true)
OCRService ocrService(Ref ref) {
  final service = MlKitOcrService();
  ref.onDispose(() => service.dispose());
  return service;
}

/// ImagePreprocessor — stateless, auto-disposed when not in use.
@riverpod
ImagePreprocessor imagePreprocessor(Ref ref) {
  return ImagePreprocessor();
}

/// ScanReceiptUseCase — wired to OCR service and preprocessor.
@riverpod
ScanReceiptUseCase scanReceiptUseCase(Ref ref) {
  return ScanReceiptUseCase(
    ocrService: ref.watch(ocrServiceProvider),
    preprocessor: ref.watch(imagePreprocessorProvider),
  );
}
