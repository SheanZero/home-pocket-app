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
}
