import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/record_category_correction_use_case.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_keyword_preference_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([CategoryKeywordPreferenceRepository])
import 'record_category_correction_use_case_test.mocks.dart';

void main() {
  late MockCategoryKeywordPreferenceRepository mockRepo;
  late RecordCategoryCorrectionUseCase useCase;

  setUp(() {
    mockRepo = MockCategoryKeywordPreferenceRepository();
    useCase = RecordCategoryCorrectionUseCase(preferenceRepository: mockRepo);
  });

  test('execute calls recordCorrection on repository', () async {
    when(
      mockRepo.recordCorrection(
        keyword: anyNamed('keyword'),
        categoryId: anyNamed('categoryId'),
      ),
    ).thenAnswer((_) async {});

    await useCase.execute(
      keyword: '咖啡',
      correctedCategoryId: 'cat_entertainment_cafe',
    );

    verify(
      mockRepo.recordCorrection(
        keyword: '咖啡',
        categoryId: 'cat_entertainment_cafe',
      ),
    ).called(1);
  });

  test('execute does nothing for empty keyword', () async {
    await useCase.execute(keyword: '', correctedCategoryId: 'cat_food');

    verifyNever(
      mockRepo.recordCorrection(
        keyword: anyNamed('keyword'),
        categoryId: anyNamed('categoryId'),
      ),
    );
  });
}
