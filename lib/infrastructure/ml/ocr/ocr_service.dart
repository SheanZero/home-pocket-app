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
