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

  group('VoiceTextParser - Date extraction: relative keywords', () {
    test('extracts 昨日 (Japanese yesterday)', () {
      final result = parser.extractDate('昨日マクドナルドで680円');
      final expected = DateTime.now().subtract(const Duration(days: 1));
      expect(result?.year, equals(expected.year));
      expect(result?.month, equals(expected.month));
      expect(result?.day, equals(expected.day));
    });

    test('extracts きのう (Japanese yesterday hiragana)', () {
      final result = parser.extractDate('きのうランチ680円');
      final expected = DateTime.now().subtract(const Duration(days: 1));
      expect(result?.day, equals(expected.day));
    });

    test('extracts 昨天 (Chinese yesterday)', () {
      final result = parser.extractDate('昨天午饭680块');
      final expected = DateTime.now().subtract(const Duration(days: 1));
      expect(result?.day, equals(expected.day));
    });

    test('extracts yesterday (English)', () {
      final result = parser.extractDate('yesterday lunch 680 yen');
      final expected = DateTime.now().subtract(const Duration(days: 1));
      expect(result?.day, equals(expected.day));
    });

    test('extracts 前天 (Chinese day before yesterday)', () {
      final result = parser.extractDate('前天买了咖啡');
      final expected = DateTime.now().subtract(const Duration(days: 2));
      expect(result?.day, equals(expected.day));
    });

    test('extracts 一昨日 (Japanese day before yesterday)', () {
      final result = parser.extractDate('一昨日のランチ');
      final expected = DateTime.now().subtract(const Duration(days: 2));
      expect(result?.day, equals(expected.day));
    });

    test('extracts 今日 (Japanese today)', () {
      final result = parser.extractDate('今日のランチ680円');
      final now = DateTime.now();
      expect(result?.year, equals(now.year));
      expect(result?.month, equals(now.month));
      expect(result?.day, equals(now.day));
    });

    test('extracts 今天 (Chinese today)', () {
      final result = parser.extractDate('今天午饭680块');
      final now = DateTime.now();
      expect(result?.day, equals(now.day));
    });

    test('extracts today (English)', () {
      final result = parser.extractDate('today lunch 680 yen');
      final now = DateTime.now();
      expect(result?.day, equals(now.day));
    });

    test('extracts 先週 (Japanese last week)', () {
      final result = parser.extractDate('先週のランチ');
      final expected = DateTime.now().subtract(const Duration(days: 7));
      expect(result?.day, equals(expected.day));
    });

    test('extracts 上周 (Chinese last week)', () {
      final result = parser.extractDate('上周午饭');
      final expected = DateTime.now().subtract(const Duration(days: 7));
      expect(result?.day, equals(expected.day));
    });

    test('extracts last week (English)', () {
      final result = parser.extractDate('last week lunch');
      final expected = DateTime.now().subtract(const Duration(days: 7));
      expect(result?.day, equals(expected.day));
    });

    test('extracts 先月 (Japanese last month)', () {
      final result = parser.extractDate('先月のガス代');
      final now = DateTime.now();
      final expected = DateTime(now.year, now.month - 1, now.day);
      expect(result?.month, equals(expected.month));
    });

    test('extracts 上个月 (Chinese last month)', () {
      final result = parser.extractDate('上个月房租');
      final now = DateTime.now();
      final expected = DateTime(now.year, now.month - 1, now.day);
      expect(result?.month, equals(expected.month));
    });

    test('extracts last month (English)', () {
      final result = parser.extractDate('last month rent');
      final now = DateTime.now();
      final expected = DateTime(now.year, now.month - 1, now.day);
      expect(result?.month, equals(expected.month));
    });
  });

  group('VoiceTextParser - Date extraction: N ago patterns', () {
    test('extracts 3日前 (Japanese 3 days ago)', () {
      final result = parser.extractDate('3日前のランチ');
      final expected = DateTime.now().subtract(const Duration(days: 3));
      expect(result?.day, equals(expected.day));
    });

    test('extracts 3天前 (Chinese 3 days ago)', () {
      final result = parser.extractDate('3天前午饭');
      final expected = DateTime.now().subtract(const Duration(days: 3));
      expect(result?.day, equals(expected.day));
    });

    test('extracts 3 days ago (English)', () {
      final result = parser.extractDate('3 days ago lunch');
      final expected = DateTime.now().subtract(const Duration(days: 3));
      expect(result?.day, equals(expected.day));
    });

    test('extracts 2週間前 (Japanese 2 weeks ago)', () {
      final result = parser.extractDate('2週間前のランチ');
      final expected = DateTime.now().subtract(const Duration(days: 14));
      expect(result?.day, equals(expected.day));
    });

    test('extracts 2周前 (Chinese 2 weeks ago)', () {
      final result = parser.extractDate('2周前午饭');
      final expected = DateTime.now().subtract(const Duration(days: 14));
      expect(result?.day, equals(expected.day));
    });

    test('extracts 2 weeks ago (English)', () {
      final result = parser.extractDate('2 weeks ago lunch');
      final expected = DateTime.now().subtract(const Duration(days: 14));
      expect(result?.day, equals(expected.day));
    });

    test('extracts 2ヶ月前 (Japanese 2 months ago)', () {
      final result = parser.extractDate('2ヶ月前の電気代');
      final now = DateTime.now();
      final expected = DateTime(now.year, now.month - 2, now.day);
      expect(result?.month, equals(expected.month));
    });

    test('extracts 2个月前 (Chinese 2 months ago)', () {
      final result = parser.extractDate('2个月前的电费');
      final now = DateTime.now();
      final expected = DateTime(now.year, now.month - 2, now.day);
      expect(result?.month, equals(expected.month));
    });

    test('extracts 2 months ago (English)', () {
      final result = parser.extractDate('2 months ago utilities');
      final now = DateTime.now();
      final expected = DateTime(now.year, now.month - 2, now.day);
      expect(result?.month, equals(expected.month));
    });
  });

  group('VoiceTextParser - Date extraction: absolute dates', () {
    test('extracts 2月20日 (ja/zh format)', () {
      final result = parser.extractDate('2月20日のランチ680円');
      expect(result?.month, equals(2));
      expect(result?.day, equals(20));
    });

    test('extracts 12月25日', () {
      final result = parser.extractDate('12月25日にプレゼント');
      expect(result?.month, equals(12));
      expect(result?.day, equals(25));
    });

    test('extracts 2/20 (slash format)', () {
      final result = parser.extractDate('2/20 lunch 680');
      expect(result?.month, equals(2));
      expect(result?.day, equals(20));
    });

    test('future date uses previous year', () {
      // Create a date that is always in the future
      final now = DateTime.now();
      final futureMonth = now.month == 12 ? 1 : now.month + 1;
      final result = parser.extractDate('$futureMonth月15日のランチ');
      if (futureMonth > now.month) {
        // Only applies if month is actually in the future of current year
        expect(result?.year, equals(now.year - 1));
      }
      expect(result?.month, equals(futureMonth));
      expect(result?.day, equals(15));
    });
  });

  group('VoiceTextParser - Date extraction: composite month + day', () {
    test('extracts 上个月15号 (Chinese last month + day)', () {
      final result = parser.extractDate('上个月15号看电影');
      final now = DateTime.now();
      final expected = DateTime(now.year, now.month - 1, 15);
      expect(result?.year, equals(expected.year));
      expect(result?.month, equals(expected.month));
      expect(result?.day, equals(15));
    });

    test('extracts 上個月20号 (Traditional Chinese last month + day)', () {
      final result = parser.extractDate('上個月20号买东西');
      final now = DateTime.now();
      final expected = DateTime(now.year, now.month - 1, 20);
      expect(result?.month, equals(expected.month));
      expect(result?.day, equals(20));
    });

    test('extracts 先月15日 (Japanese last month + day)', () {
      final result = parser.extractDate('先月15日のランチ');
      final now = DateTime.now();
      final expected = DateTime(now.year, now.month - 1, 15);
      expect(result?.month, equals(expected.month));
      expect(result?.day, equals(15));
    });

    test('extracts last month 15th (English)', () {
      final result = parser.extractDate('last month 15th dinner');
      final now = DateTime.now();
      final expected = DateTime(now.year, now.month - 1, 15);
      expect(result?.month, equals(expected.month));
      expect(result?.day, equals(15));
    });

    test('extracts 这个月10号 (Chinese this month + day)', () {
      final result = parser.extractDate('这个月10号看电影');
      final now = DateTime.now();
      expect(result?.year, equals(now.year));
      expect(result?.month, equals(now.month));
      expect(result?.day, equals(10));
    });

    test('extracts 這個月5号 (Traditional Chinese this month + day)', () {
      final result = parser.extractDate('這個月5号吃饭');
      final now = DateTime.now();
      expect(result?.month, equals(now.month));
      expect(result?.day, equals(5));
    });

    test('extracts 今月10日 (Japanese this month + day)', () {
      final result = parser.extractDate('今月10日のランチ');
      final now = DateTime.now();
      expect(result?.month, equals(now.month));
      expect(result?.day, equals(10));
    });

    test('extracts this month 10th (English)', () {
      final result = parser.extractDate('this month 10th dinner');
      final now = DateTime.now();
      expect(result?.month, equals(now.month));
      expect(result?.day, equals(10));
    });

    test('regression: 上个月 without day still works', () {
      final result = parser.extractDate('上个月房租');
      final now = DateTime.now();
      final expected = DateTime(now.year, now.month - 1, now.day);
      expect(result?.month, equals(expected.month));
      expect(result?.day, equals(expected.day));
    });

    test('regression: 先月 without day still works', () {
      final result = parser.extractDate('先月のガス代');
      final now = DateTime.now();
      final expected = DateTime(now.year, now.month - 1, now.day);
      expect(result?.month, equals(expected.month));
      expect(result?.day, equals(expected.day));
    });
  });

  group('VoiceTextParser - Date extraction: bare day', () {
    test('extracts 15号 (Chinese bare day)', () {
      final result = parser.extractDate('15号看电影');
      final now = DateTime.now();
      expect(result?.year, equals(now.year));
      expect(result?.month, equals(now.month));
      expect(result?.day, equals(15));
    });

    test('extracts 10日 bare day without month prefix', () {
      // 10日 alone (not preceded by a month number like 2月10日)
      final result = parser.extractDate('10日のランチ');
      final now = DateTime.now();
      expect(result?.month, equals(now.month));
      expect(result?.day, equals(10));
    });

    test('extracts the 15th (English bare day)', () {
      final result = parser.extractDate('the 15th dinner');
      final now = DateTime.now();
      expect(result?.month, equals(now.month));
      expect(result?.day, equals(15));
    });

    test('extracts the 1st (English bare day)', () {
      final result = parser.extractDate('the 1st lunch');
      final now = DateTime.now();
      expect(result?.month, equals(now.month));
      expect(result?.day, equals(1));
    });

    test('extracts the 2nd (English bare day)', () {
      final result = parser.extractDate('the 2nd lunch');
      final now = DateTime.now();
      expect(result?.month, equals(now.month));
      expect(result?.day, equals(2));
    });

    test('extracts the 3rd (English bare day)', () {
      final result = parser.extractDate('the 3rd lunch');
      final now = DateTime.now();
      expect(result?.month, equals(now.month));
      expect(result?.day, equals(3));
    });

    test('does not match invalid day 0号', () {
      final result = parser.extractDate('0号看电影用了50块钱');
      // Should not match as a bare day (0 is invalid)
      expect(result?.day, isNot(equals(0)));
    });

    test('does not match day > 31', () {
      final result = parser.extractDate('32号看电影');
      // Should not produce day=32
      expect(result == null || result.day <= 31, isTrue);
    });
  });

  group('VoiceTextParser - Date extraction: no date', () {
    test('returns null when no date expression found', () {
      expect(parser.extractDate('マクドナルドで680円'), isNull);
    });

    test('returns null for plain text without date', () {
      expect(parser.extractDate('ランチ食べた'), isNull);
    });

    test('returns null for amount-only input', () {
      expect(parser.extractDate('680'), isNull);
    });
  });

  group('VoiceTextParser - Date extraction: mixed input', () {
    test('extracts date from mixed ja input: 昨天在マクドナルド花了680円', () {
      final result = parser.extractDate('昨天在マクドナルド花了680円');
      final expected = DateTime.now().subtract(const Duration(days: 1));
      expect(result?.day, equals(expected.day));
    });

    test(
      'extracts date from mixed en input: yesterday spent 680 yen at McDonalds',
      () {
        final result = parser.extractDate(
          'yesterday spent 680 yen at McDonalds',
        );
        final expected = DateTime.now().subtract(const Duration(days: 1));
        expect(result?.day, equals(expected.day));
      },
    );
  });
}
