import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/voice/parse_voice_input_use_case.dart';
import 'package:home_pocket/application/voice/recognition/category_recognizer.dart';
import 'package:home_pocket/application/voice/recognition/merchant_recognizer.dart';
import 'package:home_pocket/application/voice/voice_satisfaction_estimator.dart';
import 'package:home_pocket/application/voice/voice_text_parser.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_keyword_preference_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/merchant_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:mocktail/mocktail.dart';

// Inline Mocktail-only mocks (no @GenerateMocks, no package:mockito)
class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockCategoryKeywordPreferenceRepository extends Mock
    implements CategoryKeywordPreferenceRepository {}

class _MockCategoryService extends Mock implements CategoryService {}

class _MockMerchantRepository extends Mock implements MerchantRepository {}

void main() {
  late _MockCategoryRepository mockCategoryRepo;
  late _MockCategoryKeywordPreferenceRepository mockPreferenceRepo;
  late _MockCategoryService mockCategoryService;
  late _MockMerchantRepository mockMerchantRepo;
  late ProviderContainer container;

  setUp(() {
    mockCategoryRepo = _MockCategoryRepository();
    mockPreferenceRepo = _MockCategoryKeywordPreferenceRepository();
    mockCategoryService = _MockCategoryService();
    mockMerchantRepo = _MockMerchantRepository();

    when(() => mockCategoryRepo.findActive()).thenAnswer((_) async => []);
    when(() => mockCategoryRepo.findById(any())).thenAnswer((_) async => null);
    when(
      () => mockMerchantRepo.loadAllForMatching(),
    ).thenAnswer((_) async => []);

    container = ProviderContainer(
      overrides: [
        categoryRepositoryProvider.overrideWithValue(mockCategoryRepo),
        categoryKeywordPreferenceRepositoryProvider.overrideWithValue(
          mockPreferenceRepo,
        ),
        categoryServiceProvider.overrideWithValue(mockCategoryService),
        merchantRepositoryProvider.overrideWithValue(mockMerchantRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  group(
    'voice DI providers characterization tests (post-refactor: folded into repository_providers)',
    () {
      test(
        'merchantRecognizerProvider constructs MerchantRecognizer instance',
        () {
          final recognizer = container.read(merchantRecognizerProvider);
          expect(recognizer, isA<MerchantRecognizer>());
        },
      );

      test(
        'merchantRecognizerProvider is keepAlive — same instance across two reads',
        () {
          // merchantRecognizerProvider is @Riverpod(keepAlive: true) — it warms
          // an in-memory match-key cache once per app session.
          final first = container.read(merchantRecognizerProvider);
          final second = container.read(merchantRecognizerProvider);
          expect(
            identical(first, second),
            isTrue,
            reason:
                'merchantRecognizerProvider must be keepAlive: true — same instance expected',
          );
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
        'categoryRecognizerProvider constructs CategoryRecognizer with injected deps',
        () {
          final recognizer = container.read(categoryRecognizerProvider);
          expect(recognizer, isA<CategoryRecognizer>());
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
    },
  );
}
