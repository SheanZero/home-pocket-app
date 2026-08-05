import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/sync/avatar_mime_type.dart';

void main() {
  group('detectAvatarMimeType', () {
    test('detects JPEG, PNG, and WebP magic bytes', () {
      expect(detectAvatarMimeType([0xff, 0xd8, 0xff]), 'image/jpeg');
      expect(
        detectAvatarMimeType([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
        'image/png',
      );
      expect(
        detectAvatarMimeType([
          0x52,
          0x49,
          0x46,
          0x46,
          0,
          0,
          0,
          0,
          0x57,
          0x45,
          0x42,
          0x50,
        ]),
        'image/webp',
      );
    });

    test('rejects truncated signatures and near misses', () {
      expect(detectAvatarMimeType([0xff, 0xd8]), isNull);
      expect(
        detectAvatarMimeType([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a]),
        isNull,
      );
      expect(
        detectAvatarMimeType([
          0x52,
          0x49,
          0x46,
          0x46,
          0,
          0,
          0,
          0,
          0x57,
          0x45,
          0x42,
        ]),
        isNull,
      );
      expect(detectAvatarMimeType([0xff, 0xd8, 0x00]), isNull);
      expect(
        detectAvatarMimeType([
          0x52,
          0x49,
          0x46,
          0x46,
          0,
          0,
          0,
          0,
          0x57,
          0x45,
          0x42,
          0,
        ]),
        isNull,
      );
    });

    test('rejects unknown formats', () {
      expect(detectAvatarMimeType([0x47, 0x49, 0x46, 0x38]), isNull);
    });
  });
}
