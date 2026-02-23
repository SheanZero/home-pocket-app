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
