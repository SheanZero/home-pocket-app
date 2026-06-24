import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/voice_text_parser.dart';
import 'package:home_pocket/features/settings/presentation/utils/voice_locale_helpers.dart';

/// VEN-02 / D-14 + D-15.
///
/// Task 2: the en number-word fallback is hooked into [extractAmount] ONLY
/// after an Arabic miss, in en money context, and routes entirely AROUND the
/// CJK numeral state machines (guards the v1.8 WR-04 regression class).
///
/// Task 3: VERIFY the session voice locale is decoupled from the app UI locale
/// and threaded end-to-end as en-US (no new derivation path is built).
void main() {
  late VoiceTextParser parser;

  setUp(() {
    parser = VoiceTextParser();
  });

  group('en number-word fallback hook (Task 2)', () {
    test('"fifty dollars" (en-US) -> 50 via the en fallback', () {
      expect(
        parser.extractAmount('fifty dollars', localeId: 'en-US'),
        equals(50),
      );
    });

    test('"five fifty dollars" (en-US) -> 550 (X.50 idiom in money ctx)', () {
      expect(
        parser.extractAmount('five fifty dollars', localeId: 'en-US'),
        equals(550),
      );
    });

    test('Arabic still wins: "50 dollars" (en-US) -> 50 via Arabic path', () {
      // 「50 dollars」 has Arabic digits — _extractArabicAmount must win and the
      // word fallback is never consulted.
      expect(
        parser.extractAmount('50 dollars', localeId: 'en-US'),
        equals(50),
      );
    });

    test('no money context: "fifty" alone (en-US) -> null (fallback gated)', () {
      // No currency token / $ / dollar word → money context absent → no fire.
      expect(parser.extractAmount('fifty', localeId: 'en-US'), isNull);
    });

    test('"\$fifty" symbol money context (en-US) -> 50', () {
      expect(parser.extractAmount(r'$fifty', localeId: 'en-US'), equals(50));
    });
  });

  group('isolation: English NEVER enters the CJK numeral path (Task 2)', () {
    test('en-US utterance does not produce a value via the ja/zh machines', () {
      // 「five fifty dollars」 yields 550 — and it MUST come from the en
      // fallback, never from _jaMachine/_zhMachine. The CJK machines cannot
      // parse Latin words, so any non-null here proves the en branch fired.
      expect(
        parser.extractAmount('five fifty dollars', localeId: 'en-US'),
        equals(550),
      );
    });

    test(
      'a CJK numeral string under en-US does NOT parse via the CJK machine',
      () {
        // Under en-US the en branch routes around _runStateMachine entirely,
        // so a kanji-only amount with NO Arabic digits and NO en money words
        // must yield null (the CJK machines are never reached on the en path).
        expect(parser.extractAmount('五百円', localeId: 'en-US'), isNull);
      },
    );

    test('zh/ja amount parsing is byte-unchanged (fallback en-gated only)', () {
      // The same kanji amount under its own locale still parses via the CJK
      // machine — proving the en gate did not alter the zh/ja branches.
      expect(parser.extractAmount('五百円', localeId: 'ja-JP'), equals(500));
      expect(parser.extractAmount('五百元', localeId: 'zh-CN'), equals(500));
    });
  });

  group('D-15 voice-locale decoupling (Task 3, VERIFICATION)', () {
    test(
      'voiceLanguage="en" -> "en-US" regardless of app UI locale (decoupled)',
      () {
        // The session voice locale derives from AppSettings.voiceLanguage via
        // a pure helper, NOT from currentLocaleProvider. So with app UI = ja,
        // a voiceLanguage of "en" still yields en-US.
        expect(voiceLocaleIdFromLanguageCode('en'), equals('en-US'));
        // The decoupling: the helper takes no app-locale input at all.
        expect(voiceLocaleIdFromLanguageCode('zh'), equals('zh-CN'));
        expect(voiceLocaleIdFromLanguageCode('ja'), equals('ja-JP'));
      },
    );

    test(
      'an en-US session routes amounts through the en path (not zh/ja)',
      () {
        // Confirms the pttVoiceLocaleId mirror value ("en-US") carries the en
        // number-word fallback + en currency detection into the parse path.
        final voiceLocale = voiceLocaleIdFromLanguageCode('en');
        expect(
          parser.extractAmount('fifty dollars', localeId: voiceLocale),
          equals(50),
        );
        // And the same en-US session does NOT mis-route a CJK amount through
        // the CJK machine.
        expect(parser.extractAmount('五百円', localeId: voiceLocale), isNull);
      },
    );
  });
}
