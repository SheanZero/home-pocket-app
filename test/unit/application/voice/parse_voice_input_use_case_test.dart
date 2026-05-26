import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/parse_voice_input_use_case.dart';
import 'package:home_pocket/application/voice/voice_category_resolver.dart';
import 'package:home_pocket/application/voice/voice_text_parser.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/models/voice_parse_result.dart';
import 'package:home_pocket/infrastructure/ml/merchant_database.dart';
import 'package:mocktail/mocktail.dart';

// Phase 21 D-09 — ParseVoiceInputUseCase consumes VoiceCategoryResolver.
// PATTERNS.md §9 caveat — the merchant branch routes the derived categoryId
// through resolver.normalizeToL2 (WR-05 — was resolve+findMerchant double-pass)
// so the always-L2 contract has no escape hatch.

class _MockVoiceCategoryResolver extends Mock
    implements VoiceCategoryResolver {}

class _MockMerchantDatabase extends Mock implements MerchantDatabase {}

class _MockVoiceTextParser extends Mock implements VoiceTextParser {}

class _FakeMerchantDatabase extends Fake implements MerchantDatabase {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeMerchantDatabase());
  });

  late _MockVoiceCategoryResolver mockResolver;
  late _MockMerchantDatabase mockMerchantDatabase;
  late VoiceTextParser parser;
  late ParseVoiceInputUseCase useCase;

  setUp(() {
    mockResolver = _MockVoiceCategoryResolver();
    mockMerchantDatabase = _MockMerchantDatabase();
    parser = VoiceTextParser();

    useCase = ParseVoiceInputUseCase(
      textParser: parser,
      voiceCategoryResolver: mockResolver,
      merchantDatabase: mockMerchantDatabase,
    );
  });

  group('ParseVoiceInputUseCase', () {
    test('parses amount correctly from text with 円', () async {
      when(() => mockMerchantDatabase.findMerchant(any())).thenReturn(null);
      when(() => mockResolver.resolve(any())).thenAnswer(
        (_) async => const CategoryMatchResult(
          categoryId: 'cat_food_dining_out',
          confidence: 0.9,
          source: MatchSource.keyword,
        ),
      );
      when(
        () => mockResolver.resolveLedgerType(any()),
      ).thenAnswer((_) async => LedgerType.survival);

      final result = await useCase.execute('昼ごはんに680円');

      expect(result.isSuccess, isTrue);
      expect(result.data!.amount, equals(680));
      expect(result.data!.rawText, equals('昼ごはんに680円'));
    });

    test(
      'merchant match routes through normalizeToL2 (PATTERNS.md §9 — always-L2; WR-05)',
      () async {
        // Merchant lookup hits — the use case MUST call normalizeToL2 on the
        // derived categoryId, NOT re-run resolve() against the canonical name.
        final merchantMatch = MerchantMatch(
          merchantName: 'マクドナルド',
          categoryId: 'cat_food_dining_out',
          confidence: 0.95,
          ledgerType: LedgerType.survival,
        );
        when(
          () => mockMerchantDatabase.findMerchant(any()),
        ).thenReturn(merchantMatch);
        when(
          () => mockResolver.normalizeToL2('cat_food_dining_out'),
        ).thenAnswer((_) async => 'cat_food_dining_out');

        final result = await useCase.execute('マクドナルドで680円');

        expect(result.isSuccess, isTrue);
        expect(result.data!.merchantName, equals('マクドナルド'));
        expect(
          result.data!.categoryMatch!.source,
          equals(MatchSource.merchant),
        );
        expect(
          result.data!.categoryMatch!.categoryId,
          equals('cat_food_dining_out'),
        );
        // Original confidence preserved (WR-05 — no longer overwritten by
        // the resolver's hard-coded 0.90 for canonical-name re-match)
        expect(result.data!.categoryMatch!.confidence, equals(0.95));
        // merchant-specific ledgerType wins
        expect(result.data!.ledgerType, equals(LedgerType.survival));
        // resolve() MUST NOT be consulted on the merchant branch — only
        // normalizeToL2 is.
        verifyNever(() => mockResolver.resolve(any()));
        verify(
          () => mockResolver.normalizeToL2('cat_food_dining_out'),
        ).called(1);
      },
    );

    test(
      'merchant branch defensive fallback: when normalizeToL2 returns null, '
      'raw merchant categoryId is surfaced',
      () async {
        final merchantMatch = MerchantMatch(
          merchantName: 'マクドナルド',
          categoryId: 'cat_food_dining_out',
          confidence: 0.95,
          ledgerType: LedgerType.survival,
        );
        when(
          () => mockMerchantDatabase.findMerchant(any()),
        ).thenReturn(merchantMatch);
        // normalizeToL2 miss — defensive branch kicks in.
        when(
          () => mockResolver.normalizeToL2(any()),
        ).thenAnswer((_) async => null);

        final result = await useCase.execute('マクドナルドで680円');

        expect(result.isSuccess, isTrue);
        expect(result.data!.categoryMatch, isNotNull);
        expect(
          result.data!.categoryMatch!.categoryId,
          equals('cat_food_dining_out'),
        );
        expect(
          result.data!.categoryMatch!.source,
          equals(MatchSource.merchant),
        );
        // ledgerType still wins from merchantMatch
        expect(result.data!.ledgerType, equals(LedgerType.survival));
      },
    );

    test('falls back to resolver when no merchant found', () async {
      when(() => mockMerchantDatabase.findMerchant(any())).thenReturn(null);
      when(() => mockResolver.resolve(any())).thenAnswer(
        (_) async => const CategoryMatchResult(
          categoryId: 'cat_transport_train',
          confidence: 0.95,
          source: MatchSource.keyword,
        ),
      );
      when(
        () => mockResolver.resolveLedgerType(any()),
      ).thenAnswer((_) async => LedgerType.survival);

      final result = await useCase.execute('電車代320円');

      expect(result.isSuccess, isTrue);
      expect(
        result.data!.categoryMatch!.source,
        equals(MatchSource.keyword),
      );
      expect(
        result.data!.categoryMatch!.categoryId,
        equals('cat_transport_train'),
      );
      expect(result.data!.ledgerType, equals(LedgerType.survival));
    });

    test(
      'returns success with nulls when text has no recognizable content',
      () async {
        when(() => mockMerchantDatabase.findMerchant(any())).thenReturn(null);
        when(
          () => mockResolver.resolve(any()),
        ).thenAnswer((_) async => null);

        final result = await useCase.execute('test');

        expect(result.isSuccess, isTrue);
        expect(result.data!.amount, isNull);
        expect(result.data!.merchantName, isNull);
        expect(result.data!.categoryMatch, isNull);
      },
    );
  });

  // ─── Quick task 260526-pg6 (Option F — Task 1): resolvedKeyword surface ───
  //
  // The use case must populate `VoiceParseResult.resolvedKeyword` with the
  // SAME string the resolver internally received (post-strip). This closes
  // the silent-orphan bug where form-side recordCorrection wrote keys that
  // never matched the resolver's lookup key.
  group('Quick task 260526-pg6 — resolvedKeyword surface', () {
    test(
      'Test 1.A: keyword branch — resolvedKeyword equals the post-strip key '
      'the resolver received (zh)',
      () async {
        // Capture the keyword the resolver actually sees so the assertion
        // pins the contract: resolvedKeyword == resolver-input keyword.
        String? resolverSawKeyword;
        when(() => mockMerchantDatabase.findMerchant(any())).thenReturn(null);
        when(() => mockResolver.resolve(any())).thenAnswer((invocation) async {
          resolverSawKeyword = invocation.positionalArguments.first as String;
          return null;
        });

        // Input: "去外食12,450日元" with zh-CN locale.
        // `_extractKeyword` strips `12,450日元` (amount + 日元 currency suffix
        // via VoiceCurrencySuffixes.regexAlternation) and zh particles, but
        // `去外食` contains no listed particles → stays intact.
        final result = await useCase.execute(
          '去外食12,450日元',
          localeId: 'zh-CN',
        );

        expect(result.isSuccess, isTrue);
        expect(resolverSawKeyword, equals('去外食'));
        expect(result.data!.resolvedKeyword, equals('去外食'));
        // Pin: resolvedKeyword is EXACTLY what the resolver saw.
        expect(result.data!.resolvedKeyword, equals(resolverSawKeyword));
      },
    );

    test(
      'Test 1.B: merchant branch — resolvedKeyword populated even when '
      'resolver.resolve never runs',
      () async {
        // Merchant DB hit short-circuits the resolver, but the use case still
        // computes the post-strip keyword so the form has a usable key for
        // future recordCorrection calls.
        final merchantMatch = MerchantMatch(
          merchantName: '星巴克',
          categoryId: 'cat_food_cafe',
          confidence: 0.92,
          ledgerType: LedgerType.survival,
        );
        when(
          () => mockMerchantDatabase.findMerchant(any()),
        ).thenReturn(merchantMatch);
        when(
          () => mockResolver.normalizeToL2('cat_food_cafe'),
        ).thenAnswer((_) async => 'cat_food_cafe');

        final result = await useCase.execute(
          '去星巴克500日元',
          localeId: 'zh-CN',
        );

        expect(result.isSuccess, isTrue);
        // Merchant branch took over but resolvedKeyword is still populated.
        expect(result.data!.resolvedKeyword, isNotNull);
        expect(result.data!.resolvedKeyword!.isNotEmpty, isTrue);
        // resolver.resolve must NOT have been consulted (merchant short-circuit).
        verifyNever(() => mockResolver.resolve(any()));
      },
    );

    test(
      'Test 1.C: amount-only utterance yields null resolvedKeyword',
      () async {
        // Input "500日元" strips amount+currency → empty keyword → use case
        // surfaces null so consumers can guard on `!= null && isNotEmpty`.
        when(() => mockMerchantDatabase.findMerchant(any())).thenReturn(null);
        when(() => mockResolver.resolve(any())).thenAnswer((_) async => null);

        final result = await useCase.execute('500日元', localeId: 'zh-CN');

        expect(result.isSuccess, isTrue);
        expect(
          result.data!.resolvedKeyword,
          isNull,
          reason: 'amount-only utterance must yield null resolvedKeyword, '
              'not empty-string — consumer null-guards are explicit',
        );
      },
    );

    test(
      'Test 1.D: existing VoiceParseResult fields remain populated alongside '
      'resolvedKeyword (additive, non-breaking)',
      () async {
        when(() => mockMerchantDatabase.findMerchant(any())).thenReturn(null);
        when(() => mockResolver.resolve(any())).thenAnswer(
          (_) async => const CategoryMatchResult(
            categoryId: 'cat_food_dining_out',
            confidence: 0.9,
            source: MatchSource.keyword,
          ),
        );
        when(
          () => mockResolver.resolveLedgerType(any()),
        ).thenAnswer((_) async => LedgerType.survival);

        final result = await useCase.execute(
          '昼ごはんに680円',
          localeId: 'ja-JP',
        );

        expect(result.isSuccess, isTrue);
        // All pre-existing fields still flow.
        expect(result.data!.amount, equals(680));
        expect(result.data!.rawText, equals('昼ごはんに680円'));
        expect(
          result.data!.categoryMatch!.categoryId,
          equals('cat_food_dining_out'),
        );
        expect(result.data!.ledgerType, equals(LedgerType.survival));
        // NEW field also populated.
        expect(result.data!.resolvedKeyword, isNotNull);
        expect(result.data!.resolvedKeyword!.isNotEmpty, isTrue);
      },
    );
  });

  group('ParseVoiceInputUseCase - localeId routing', () {
    late _MockVoiceTextParser mockTextParser;
    late _MockVoiceCategoryResolver localMockResolver;
    late _MockMerchantDatabase localMockDb;
    late ParseVoiceInputUseCase useCaseWithMockParser;

    setUp(() {
      mockTextParser = _MockVoiceTextParser();
      localMockResolver = _MockVoiceCategoryResolver();
      localMockDb = _MockMerchantDatabase();
      useCaseWithMockParser = ParseVoiceInputUseCase(
        textParser: mockTextParser,
        voiceCategoryResolver: localMockResolver,
        merchantDatabase: localMockDb,
      );
    });

    test(
      'execute(text, localeId: x) forwards localeId to textParser.extractAmount',
      () async {
        when(
          () => mockTextParser.extractAmount(
            any(),
            localeId: any(named: 'localeId'),
          ),
        ).thenReturn(2204);
        when(() => mockTextParser.extractDate(any())).thenReturn(null);
        when(
          () => mockTextParser.extractAndMatchMerchant(any(), any()),
        ).thenReturn(null);
        when(
          () => localMockResolver.resolve(any()),
        ).thenAnswer((_) async => null);
        when(() => localMockDb.findMerchant(any())).thenReturn(null);

        await useCaseWithMockParser.execute('test text', localeId: 'ja-JP');

        verify(
          () => mockTextParser.extractAmount('test text', localeId: 'ja-JP'),
        ).called(1);
      },
    );
  });
}
