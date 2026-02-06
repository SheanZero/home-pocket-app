import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/ensure_default_book_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/domain/repositories/book_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([BookRepository])
import 'ensure_default_book_use_case_test.mocks.dart';

void main() {
  late MockBookRepository mockRepo;
  late EnsureDefaultBookUseCase useCase;

  setUp(() {
    mockRepo = MockBookRepository();
    useCase = EnsureDefaultBookUseCase(bookRepository: mockRepo);
  });

  group('EnsureDefaultBookUseCase', () {
    test('creates default book when none exist', () async {
      when(mockRepo.findAll()).thenAnswer((_) async => []);
      when(mockRepo.insert(any)).thenAnswer((_) async {});

      final result = await useCase.execute();

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.currency, 'JPY');
      verify(mockRepo.insert(any)).called(1);
    });

    test('returns existing book when one already exists', () async {
      final existing = Book(
        id: 'book_existing',
        name: 'My Book',
        currency: 'JPY',
        deviceId: 'dev_local',
        createdAt: DateTime(2026, 1, 1),
      );
      when(mockRepo.findAll()).thenAnswer((_) async => [existing]);

      final result = await useCase.execute();

      expect(result.isSuccess, isTrue);
      expect(result.data!.id, 'book_existing');
      verifyNever(mockRepo.insert(any));
    });
  });
}
