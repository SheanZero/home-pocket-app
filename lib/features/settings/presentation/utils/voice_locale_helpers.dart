/// Converts a language code to a BCP-47 locale ID for speech recognition.
/// Public for testing.
String voiceLocaleIdFromLanguageCode(String code) {
  switch (code) {
    case 'zh':
      return 'zh-CN';
    case 'ja':
      return 'ja-JP';
    case 'en':
      return 'en-US';
    default:
      return 'zh-CN';
  }
}
