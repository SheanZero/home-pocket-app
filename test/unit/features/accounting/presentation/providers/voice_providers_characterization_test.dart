import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/voice/fuzzy_category_matcher.dart';
import 'package:home_pocket/application/voice/parse_voice_input_use_case.dart';
import 'package:home_pocket/application/voice/voice_satisfaction_estimator.dart';
import 'package:home_pocket/application/voice/voice_text_parser.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_keyword_preference_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/accounting/presentation/providers/use_case_providers.dart';
import 'package:home_pocket/features/accounting/presentation/providers/voice_providers.dart';
import 'package:home_pocket/infrastructure/ml/merchant_database.dart';
import 'package:mocktail/mocktail.dart';

// Inline Mocktail-only mocks (no @GenerateMocks, no package:mockito)
class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockCategoryKeywordPreferenceRepository extends Mock
    implements CategoryKeywordPreferenceRepository {}

class _MockCategoryService extends Mock implements CategoryService {}

void main() {
  late _MockCategoryRepository mockCategoryRepo;
  late _MockCategoryKeywordPreferenceRepository mockPreferenceRepo;
  late _MockCategoryService mockCategoryService;
  late ProviderContainer container;

  setUp(() {
    mockCategoryRepo = _MockCategoryRepository();
    mockPreferenceRepo = _MockCategoryKeywordPreferenceRepository();
    mockCategoryService = _MockCategoryService();

    when(
      () => mockCategoryRepo.findActive(),
    ).thenAnswer((_) async => []);
    when(
      () => mockCategoryRepo.findById(any()),
    ).thenAnswer((_) async => null);

    container = ProviderContainer(
      overrides: [
        categoryRepositoryProvider.overrideWithValue(mockCategoryRepo),
        categoryKeywordPreferenceRepositoryProvider.overrideWithValue(
          mockPreferenceRepo,
        ),
        categoryServiceProvider.overrideWithValue(mockCategoryService),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('voice_providers characterization tests (pre-refactor behavior)', () {
    test(
      'merchantDatabaseProvider constructs MerchantDatabase instance',
      () {
        final db = container.read(merchantDatabaseProvider);
        expect(db, isA<MerchantDatabase>());
      },
    );

    test(
      'merchantDatabaseProvider is keepAlive — same instance across two reads',
      () {
        // Read twice; keepAlive ensures same instance is returned
        final first = container.read(merchantDatabaseProvider);
        final second = container.read(merchantDatabaseProvider);
        expect(identical(first, second), isTrue,
            reason:
                'merchantDatabaseProvider must be keepAlive: true — same instance expected');
      },
    );

    test(
      'voiceTextParserProvider constructs VoiceTextParser without error',
      () {
        final parser = container.read(voiceTextParserProvider);
        expect(parser, isA<VoiceTextParser>());
      },
    );

    test(
      'fuzzyCategoryMatcherProvider constructs FuzzyCategoryMatcher with injected deps',
      () {
        // fuzzyCategoryMatcherProvider requires categoryServiceProvider too
        // We supply it via overrides on the repository providers it depends on
        final matcher = container.read(fuzzyCategoryMatcherProvider);
        expect(matcher, isA<FuzzyCategoryMatcher>());
      },
    );

    test(
      'parseVoiceInputUseCaseProvider constructs ParseVoiceInputUseCase',
      () {
        final useCase = container.read(parseVoiceInputUseCaseProvider);
        expect(useCase, isA<ParseVoiceInputUseCase>());
      },
    );

    test(
      'voiceSatisfactionEstimatorProvider constructs VoiceSatisfactionEstimator',
      () {
        final estimator = container.read(voiceSatisfactionEstimatorProvider);
        expect(estimator, isA<VoiceSatisfactionEstimator>());
      },
    );

    test(
      'voiceTextParserProvider returns non-null instance on each read',
      () {
        expect(container.read(voiceTextParserProvider), isNotNull);
        expect(container.read(voiceTextParserProvider), isNotNull);
      },
    );
  });
}
