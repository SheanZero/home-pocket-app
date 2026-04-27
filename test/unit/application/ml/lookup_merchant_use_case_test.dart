import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/ml/lookup_merchant_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/infrastructure/ml/merchant_database.dart';
import 'package:mocktail/mocktail.dart';

class _MockMerchantDatabase extends Mock implements MerchantDatabase {}

void main() {
  late _MockMerchantDatabase mockDatabase;
  late LookupMerchantUseCase useCase;

  setUp(() {
    mockDatabase = _MockMerchantDatabase();
    useCase = LookupMerchantUseCase(database: mockDatabase);
  });

  group('LookupMerchantUseCase', () {
    test('returns MerchantMatch when database finds a match', () async {
      final expected = MerchantMatch(
        merchantName: 'スターバックス',
        categoryId: 'cat_food',
        confidence: 0.90,
        ledgerType: LedgerType.survival,
      );
      when(() => mockDatabase.findMerchant('スターバックス')).thenReturn(expected);

      final result = await useCase.execute('スターバックス');

      expect(result, same(expected));
      verify(() => mockDatabase.findMerchant('スターバックス')).called(1);
    });

    test('returns null when database finds no match', () async {
      when(() => mockDatabase.findMerchant('unknown')).thenReturn(null);

      final result = await useCase.execute('unknown');

      expect(result, isNull);
    });

    test('returns null gracefully when database throws', () async {
      when(
        () => mockDatabase.findMerchant(any()),
      ).thenThrow(Exception('Database error'));

      final result = await useCase.execute('anything');

      expect(result, isNull);
    });

    test('returns null for empty string input', () async {
      when(() => mockDatabase.findMerchant('')).thenReturn(null);

      final result = await useCase.execute('');

      expect(result, isNull);
    });
  });
}
