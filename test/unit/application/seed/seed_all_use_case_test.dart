import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/seed_categories_use_case.dart';
import 'package:home_pocket/application/accounting/seed_merchants_use_case.dart';
import 'package:home_pocket/application/accounting/seed_voice_synonyms_use_case.dart';
import 'package:home_pocket/application/seed/seed_all_use_case.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:mocktail/mocktail.dart';

class _MockSeedCategoriesUseCase extends Mock implements SeedCategoriesUseCase {}

class _MockSeedVoiceSynonymsUseCase extends Mock
    implements SeedVoiceSynonymsUseCase {}

class _MockSeedMerchantsUseCase extends Mock
    implements SeedMerchantsUseCase {}

void main() {
  late _MockSeedCategoriesUseCase mockCategories;
  late _MockSeedVoiceSynonymsUseCase mockSynonyms;
  late _MockSeedMerchantsUseCase mockMerchants;
  late SeedAllUseCase useCase;

  setUp(() {
    mockCategories = _MockSeedCategoriesUseCase();
    mockSynonyms = _MockSeedVoiceSynonymsUseCase();
    mockMerchants = _MockSeedMerchantsUseCase();
    useCase = SeedAllUseCase(
      seedCategories: mockCategories,
      seedVoiceSynonyms: mockSynonyms,
      seedMerchants: mockMerchants,
    );
  });

  group('SeedAllUseCase', () {
    test('D-14: seeds categories before synonyms', () async {
      DateTime? categoriesCompletedAt;
      DateTime? synonymsStartedAt;

      when(() => mockCategories.execute()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        categoriesCompletedAt = DateTime.now();
        return Result.success(null);
      });

      when(() => mockSynonyms.execute()).thenAnswer((_) async {
        synonymsStartedAt = DateTime.now();
        return Result.success(null);
      });

      when(() => mockMerchants.execute()).thenAnswer(
        (_) async => Result.success(null),
      );

      await useCase.execute();

      expect(categoriesCompletedAt, isNotNull);
      expect(synonymsStartedAt, isNotNull);
      expect(
        categoriesCompletedAt!.isBefore(synonymsStartedAt!),
        isTrue,
        reason:
            'Phase 23 D-14: categories must complete before synonyms start',
      );
    });

    test('D-14: synonyms not invoked when categories fails', () async {
      when(() => mockCategories.execute()).thenAnswer(
        (_) async => Result.error('categories seed failed'),
      );
      when(() => mockSynonyms.execute()).thenAnswer(
        (_) async => Result.success(null),
      );
      when(() => mockMerchants.execute()).thenAnswer(
        (_) async => Result.success(null),
      );

      final result = await useCase.execute();

      expect(result.isSuccess, isFalse);
      verifyNever(() => mockSynonyms.execute());
    });

    test('Phase 49 D-05/Pitfall 1: seeds merchants after categories', () async {
      DateTime? categoriesCompletedAt;
      DateTime? merchantsStartedAt;

      when(() => mockCategories.execute()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        categoriesCompletedAt = DateTime.now();
        return Result.success(null);
      });
      when(() => mockSynonyms.execute()).thenAnswer(
        (_) async => Result.success(null),
      );
      when(() => mockMerchants.execute()).thenAnswer((_) async {
        merchantsStartedAt = DateTime.now();
        return Result.success(null);
      });

      final result = await useCase.execute();

      expect(result.isSuccess, isTrue);
      expect(categoriesCompletedAt, isNotNull);
      expect(merchantsStartedAt, isNotNull);
      expect(
        categoriesCompletedAt!.isBefore(merchantsStartedAt!),
        isTrue,
        reason:
            'Phase 49: merchant categoryIds reference seeded L2 categories, '
            'so categories must complete before merchants seed',
      );
      verify(() => mockMerchants.execute()).called(1);
    });

    test('Phase 49: merchants not invoked when categories fails', () async {
      when(() => mockCategories.execute()).thenAnswer(
        (_) async => Result.error('categories seed failed'),
      );
      when(() => mockSynonyms.execute()).thenAnswer(
        (_) async => Result.success(null),
      );
      when(() => mockMerchants.execute()).thenAnswer(
        (_) async => Result.success(null),
      );

      final result = await useCase.execute();

      expect(result.isSuccess, isFalse);
      verifyNever(() => mockMerchants.execute());
    });
  });
}
