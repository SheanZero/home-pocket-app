import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/ensure_default_book_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/domain/repositories/book_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/device_identity_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockBookRepository extends Mock implements BookRepository {}

class _MockDeviceIdentityRepository extends Mock
    implements DeviceIdentityRepository {}

class _FakeBook extends Fake implements Book {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeBook());
  });

  late _MockBookRepository mockRepo;
  late _MockDeviceIdentityRepository mockDeviceIdentityRepo;
  late EnsureDefaultBookUseCase useCase;

  setUp(() {
    mockRepo = _MockBookRepository();
    mockDeviceIdentityRepo = _MockDeviceIdentityRepository();
    useCase = EnsureDefaultBookUseCase(
      bookRepository: mockRepo,
      deviceIdentityRepository: mockDeviceIdentityRepo,
    );
    when(
      () => mockDeviceIdentityRepo.getDeviceId(),
    ).thenAnswer((_) async => 'device_test_001');
  });

  group('EnsureDefaultBookUseCase', () {
    test('creates default book when none exist', () async {
      when(() => mockRepo.findAll()).thenAnswer((_) async => []);
      when(() => mockRepo.insert(any())).thenAnswer((_) async {});

      final result = await useCase.execute();

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.currency, 'JPY');
      expect(result.data!.deviceId, 'device_test_001');
      verify(() => mockRepo.insert(any())).called(1);
    });

    test('returns existing book when one already exists', () async {
      final existing = Book(
        id: 'book_existing',
        name: 'My Book',
        currency: 'JPY',
        deviceId: 'device_existing_001',
        createdAt: DateTime(2026, 1, 1),
      );
      when(() => mockRepo.findAll()).thenAnswer((_) async => [existing]);

      final result = await useCase.execute();

      expect(result.isSuccess, isTrue);
      expect(result.data!.id, 'book_existing');
      verifyNever(() => mockRepo.insert(any()));
      verifyNever(() => mockDeviceIdentityRepo.getDeviceId());
    });

    test('returns error when deviceId is unavailable', () async {
      when(() => mockRepo.findAll()).thenAnswer((_) async => []);
      when(
        () => mockDeviceIdentityRepo.getDeviceId(),
      ).thenAnswer((_) async => null);

      final result = await useCase.execute();

      expect(result.isError, isTrue);
      expect(result.error, contains('deviceId'));
      verifyNever(() => mockRepo.insert(any()));
    });
  });
}
