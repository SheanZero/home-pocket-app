import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/settings/presentation/providers/settings_providers.dart';

void main() {
  group('voiceLocaleIdProvider', () {
    test('zh maps to zh-CN', () {
      expect(voiceLocaleIdFromLanguageCode('zh'), 'zh-CN');
    });

    test('ja maps to ja-JP', () {
      expect(voiceLocaleIdFromLanguageCode('ja'), 'ja-JP');
    });

    test('en maps to en-US', () {
      expect(voiceLocaleIdFromLanguageCode('en'), 'en-US');
    });

    test('unknown code defaults to zh-CN', () {
      expect(voiceLocaleIdFromLanguageCode('fr'), 'zh-CN');
    });
  });
}
