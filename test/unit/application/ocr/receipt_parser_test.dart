import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/ocr/receipt_parser.dart';

void main() {
  late ReceiptParser parser;

  setUp(() => parser = ReceiptParser());

  group('extractAmount', () {
    test('extracts 合計 amount (Japanese)', () {
      final result = parser.parse('商品A 500\n合計 ¥1,280');
      expect(result.amount, 1280);
    });

    test('extracts 小計 amount when no 合計', () {
      final result = parser.parse('商品A\n小計 ¥800');
      expect(result.amount, 800);
    });

    test('extracts TOTAL amount (English)', () {
      final result = parser.parse('Item A\nTOTAL ¥2,500');
      expect(result.amount, 2500);
    });

    test('extracts amount with 円 suffix', () {
      final result = parser.parse('合計 1280円');
      expect(result.amount, 1280);
    });

    test('extracts amount with comma separator', () {
      final result = parser.parse('合計 ¥12,345');
      expect(result.amount, 12345);
    });

    test('prefers keyword amount over bare yen amounts', () {
      // お釣り (change) should NOT be selected; 合計 should win
      final result = parser.parse('合計 ¥980\nお釣り ¥20');
      expect(result.amount, 980);
    });

    test('falls back to largest yen amount when no keyword', () {
      final result = parser.parse('¥200\n¥980\n¥50');
      expect(result.amount, 980);
    });

    test('excludes お釣り/税 lines from yen fallback', () {
      final result = parser.parse('¥980\nお釣り ¥20\n税 ¥80');
      expect(result.amount, 980);
    });

    test('returns null when no amount found', () {
      final result = parser.parse('レシートテスト');
      expect(result.amount, isNull);
    });

    test('handles tax-inclusive amount (税込)', () {
      final result = parser.parse('小計 ¥1,000\n税込合計 ¥1,100');
      expect(result.amount, 1100);
    });
  });

  group('extractDate', () {
    test('extracts YYYY年MM月DD日 format', () {
      final result = parser.parse('2026年02月15日\n合計 ¥1,000');
      expect(result.date, DateTime(2026, 2, 15));
    });

    test('extracts YYYY/MM/DD format', () {
      final result = parser.parse('2026/01/23 12:30\n合計 ¥500');
      expect(result.date, DateTime(2026, 1, 23));
    });

    test('extracts YYYY-MM-DD format', () {
      final result = parser.parse('Date: 2026-03-01\nTOTAL ¥800');
      expect(result.date, DateTime(2026, 3, 1));
    });

    test('extracts YY/MM/DD with century completion', () {
      final result = parser.parse('26/02/15\n合計 ¥300');
      expect(result.date, DateTime(2026, 2, 15));
    });

    test('extracts YYYY.MM.DD format', () {
      final result = parser.parse('2026.12.25\n合計 ¥1,500');
      expect(result.date, DateTime(2026, 12, 25));
    });

    test('returns null when no date found', () {
      final result = parser.parse('合計 ¥1,000');
      expect(result.date, isNull);
    });

    test('ignores invalid dates', () {
      final result = parser.parse('2026/13/32\n合計 ¥100');
      expect(result.date, isNull);
    });
  });

  group('extractMerchant', () {
    test('extracts first non-numeric line as merchant', () {
      final result = parser.parse('セブンイレブン\n2026/01/15\n合計 ¥580');
      expect(result.merchant, 'セブンイレブン');
    });

    test('skips date-only lines', () {
      final result = parser.parse('2026/01/15 12:30\nマクドナルド\n合計 ¥680');
      expect(result.merchant, 'マクドナルド');
    });

    test('skips amount-only lines', () {
      final result = parser.parse('¥580\nスターバックス\n合計 ¥580');
      expect(result.merchant, 'スターバックス');
    });

    test('returns null for empty text', () {
      final result = parser.parse('');
      expect(result.merchant, isNull);
    });

    test('trims whitespace from merchant name', () {
      final result = parser.parse('  ファミリーマート  \n合計 ¥300');
      expect(result.merchant, 'ファミリーマート');
    });

    test('skips very short lines (< 2 chars)', () {
      final result = parser.parse('A\nローソン\n合計 ¥200');
      expect(result.merchant, 'ローソン');
    });
  });
}
