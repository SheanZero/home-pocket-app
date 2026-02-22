import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/voice_text_parser.dart';

void main() {
  late VoiceTextParser parser;

  setUp(() {
    parser = VoiceTextParser();
  });

  group('VoiceTextParser - Arabic amount extraction', () {
    test('extracts yen with 円 suffix: 680円', () {
      expect(parser.extractAmount('昼ごはんに680円'), equals(680));
    });

    test('extracts yen with ¥ prefix: ¥1,280', () {
      expect(parser.extractAmount('マクドナルドで¥1,280'), equals(1280));
    });

    test('extracts yuan with 块 suffix: 480块', () {
      expect(parser.extractAmount('午饭480块'), equals(480));
    });

    test('extracts yen with "yen" suffix: 550 yen', () {
      expect(parser.extractAmount('lunch 550 yen'), equals(550));
    });

    test('extracts standalone number >= 3 digits: 3980', () {
      expect(parser.extractAmount('ユニクロで3980'), equals(3980));
    });

    test('returns null when no amount present', () {
      expect(parser.extractAmount('昼ごはん食べた'), isNull);
    });

    test('returns null for amount of zero', () {
      expect(parser.extractAmount('0円'), isNull);
    });

    test('extracts comma-formatted amount: 1,280円', () {
      expect(parser.extractAmount('1,280円'), equals(1280));
    });
  });

  group('VoiceTextParser - Kanji amount extraction', () {
    test('extracts 六百八十円 -> 680', () {
      expect(parser.extractAmount('六百八十円'), equals(680));
    });

    test('extracts 千二百円 -> 1200', () {
      expect(parser.extractAmount('千二百円'), equals(1200));
    });

    test('extracts 三千九百八十 -> 3980', () {
      expect(parser.extractAmount('三千九百八十'), equals(3980));
    });

    test('extracts 一千二百元 -> 1200', () {
      expect(parser.extractAmount('一千二百元'), equals(1200));
    });
  });
}
