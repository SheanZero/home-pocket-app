import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImagePreprocessor {
  static const int _maxDimension = 2048;

  Uint8List? processBytes(Uint8List input) {
    final img.Image? decoded;
    try {
      decoded = img.decodeImage(input);
    } catch (_) {
      return null;
    }
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
