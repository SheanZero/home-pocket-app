import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/record_category_correction_use_case.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_keyword_preference_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockCategoryKeywordPreferenceRepository extends Mock
    implements CategoryKeywordPreferenceRepository {}

void main() {
  late _MockCategoryKeywordPreferenceRepository mockRepo;
  late RecordCategoryCorrectionUseCase useCase;

  setUp(() {
    mockRepo = _MockCategoryKeywordPreferenceRepository();
    useCase = RecordCategoryCorrectionUseCase(preferenceRepository: mockRepo);
  });

  test('execute calls recordCorrection on repository', () async {
    when(
      () => mockRepo.recordCorrection(
        keyword: any(named: 'keyword'),
        categoryId: any(named: 'categoryId'),
      ),
    ).thenAnswer((_) async {});

    await useCase.execute(
      keyword: '咖啡',
      correctedCategoryId: 'cat_entertainment_cafe',
    );

    verify(
      () => mockRepo.recordCorrection(
        keyword: '咖啡',
        categoryId: 'cat_entertainment_cafe',
      ),
    ).called(1);
  });

  test('execute does nothing for empty keyword', () async {
    await useCase.execute(keyword: '', correctedCategoryId: 'cat_food');

    verifyNever(
      () => mockRepo.recordCorrection(
        keyword: any(named: 'keyword'),
        categoryId: any(named: 'categoryId'),
      ),
    );
  });
}
