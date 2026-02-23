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
