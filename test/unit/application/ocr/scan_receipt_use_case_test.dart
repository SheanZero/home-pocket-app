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
    expect(result.error, OcrError.scanFailed);
  });
}
