import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/fuzzy_category_matcher.dart';
import 'package:home_pocket/application/voice/parse_voice_input_use_case.dart';
import 'package:home_pocket/application/voice/voice_text_parser.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/models/voice_parse_result.dart';
import 'package:home_pocket/infrastructure/ml/merchant_database.dart';
import 'package:mocktail/mocktail.dart';

class _MockFuzzyCategoryMatcher extends Mock implements FuzzyCategoryMatcher {}

class _MockMerchantDatabase extends Mock implements MerchantDatabase {}

void main() {
  late _MockFuzzyCategoryMatcher mockFuzzyCategoryMatcher;
  late _MockMerchantDatabase mockMerchantDatabase;
  late VoiceTextParser parser;
  late ParseVoiceInputUseCase useCase;

  setUp(() {
    mockFuzzyCategoryMatcher = _MockFuzzyCategoryMatcher();
    mockMerchantDatabase = _MockMerchantDatabase();
    parser = VoiceTextParser();

    useCase = ParseVoiceInputUseCase(
      textParser: parser,
      fuzzyCategoryMatcher: mockFuzzyCategoryMatcher,
      merchantDatabase: mockMerchantDatabase,
    );
  });

  group('ParseVoiceInputUseCase', () {
    test('parses amount correctly from text with 円', () async {
      when(() => mockMerchantDatabase.findMerchant(any())).thenReturn(null);
      when(() => mockFuzzyCategoryMatcher.match(any(), any())).thenAnswer(
        (_) async => const CategoryMatchResult(
          categoryId: 'cat_food',
          confidence: 0.9,
          source: MatchSource.keyword,
        ),
      );
      when(
        () => mockFuzzyCategoryMatcher.resolveLedgerType(any()),
      ).thenAnswer((_) async => LedgerType.survival);

      final result = await useCase.execute('昼ごはんに680円');

      expect(result.isSuccess, isTrue);
      expect(result.data!.amount, equals(680));
      expect(result.data!.rawText, equals('昼ごはんに680円'));
    });

    test('merchant match overrides keyword category', () async {
      final merchantMatch = MerchantMatch(
        merchantName: 'マクドナルド',
        categoryId: 'cat_food',
        confidence: 0.95,
        ledgerType: LedgerType.survival,
      );
      when(
        () => mockMerchantDatabase.findMerchant(any()),
      ).thenReturn(merchantMatch);

      final result = await useCase.execute('マクドナルドで680円');

      expect(result.isSuccess, isTrue);
      expect(result.data!.merchantName, equals('マクドナルド'));
      expect(result.data!.categoryMatch!.source, equals(MatchSource.merchant));
      // FuzzyCategoryMatcher.match should NOT be called when merchant found
      verifyNever(() => mockFuzzyCategoryMatcher.match(any(), any()));
    });

    test('falls back to fuzzy match when no merchant found', () async {
      when(() => mockMerchantDatabase.findMerchant(any())).thenReturn(null);
      when(() => mockFuzzyCategoryMatcher.match(any(), any())).thenAnswer(
        (_) async => const CategoryMatchResult(
          categoryId: 'cat_transport',
          confidence: 0.95,
          source: MatchSource.keyword,
        ),
      );
      when(
        () => mockFuzzyCategoryMatcher.resolveLedgerType(any()),
      ).thenAnswer((_) async => LedgerType.survival);

      final result = await useCase.execute('電車代320円');

      expect(result.isSuccess, isTrue);
      expect(result.data!.categoryMatch!.source, equals(MatchSource.keyword));
    });

    test(
      'returns success with nulls when text has no recognizable content',
      () async {
        when(() => mockMerchantDatabase.findMerchant(any())).thenReturn(null);
        when(
          () => mockFuzzyCategoryMatcher.match(any(), any()),
        ).thenAnswer((_) async => null);

        final result = await useCase.execute('test');

        expect(result.isSuccess, isTrue);
        expect(result.data!.amount, isNull);
        expect(result.data!.merchantName, isNull);
        expect(result.data!.categoryMatch, isNull);
      },
    );
  });
}
