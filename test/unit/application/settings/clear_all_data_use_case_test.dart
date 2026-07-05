import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/settings/clear_all_data_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:mocktail/mocktail.dart';

import 'package:home_pocket/features/accounting/domain/repositories/book_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/profile/domain/models/user_profile.dart';
import 'package:home_pocket/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:home_pocket/features/settings/domain/repositories/settings_repository.dart';
import 'package:home_pocket/features/settings/domain/repositories/unit_of_work.dart';

/// Passthrough — these mock-based tests assert repository interactions, not
/// transactional rollback (covered by the *_atomicity_test with a real DB).
class _FakeUnitOfWork implements UnitOfWork {
  @override
  Future<T> run<T>(Future<T> Function() action) => action();
}

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockBookRepository extends Mock implements BookRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

void main() {
  late ClearAllDataUseCase useCase;
  late MockTransactionRepository mockTransactionRepo;
  late MockCategoryRepository mockCategoryRepo;
  late MockBookRepository mockBookRepo;
  late MockSettingsRepository mockSettingsRepo;
  late MockUserProfileRepository mockUserProfileRepo;

  setUp(() {
    mockTransactionRepo = MockTransactionRepository();
    mockCategoryRepo = MockCategoryRepository();
    mockBookRepo = MockBookRepository();
    mockSettingsRepo = MockSettingsRepository();
    mockUserProfileRepo = MockUserProfileRepository();
    useCase = ClearAllDataUseCase(
      transactionRepo: mockTransactionRepo,
      categoryRepo: mockCategoryRepo,
      bookRepo: mockBookRepo,
      settingsRepo: mockSettingsRepo,
      userProfileRepo: mockUserProfileRepo,
      unitOfWork: _FakeUnitOfWork(),
    );
    // Default: no profile present unless a test overrides it.
    when(() => mockUserProfileRepo.find()).thenAnswer((_) async => null);
    when(() => mockUserProfileRepo.delete(any())).thenAnswer((_) async {});
  });

  setUpAll(() {
    registerFallbackValue(const AppSettings());
  });

  test('deletes all data and resets settings', () async {
    // Arrange
    final books = [
      Book(
        id: 'book-1',
        name: 'Test',
        currency: 'JPY',
        deviceId: 'dev',
        createdAt: DateTime(2026),
      ),
      Book(
        id: 'book-2',
        name: 'Test 2',
        currency: 'JPY',
        deviceId: 'dev',
        createdAt: DateTime(2026),
      ),
    ];

    when(
      () => mockBookRepo.findAll(includeArchived: true, includeShadow: true),
    ).thenAnswer((_) async => books);
    when(
      () => mockTransactionRepo.deleteAllByBook(any()),
    ).thenAnswer((_) async {});
    when(() => mockCategoryRepo.deleteAll()).thenAnswer((_) async {});
    when(() => mockBookRepo.deleteAll()).thenAnswer((_) async {});
    when(() => mockSettingsRepo.updateSettings(any())).thenAnswer((_) async {});

    // Act
    final result = await useCase.execute();

    // Assert
    expect(result.isSuccess, true);

    // Verify transactions deleted for each book
    verify(() => mockTransactionRepo.deleteAllByBook('book-1')).called(1);
    verify(() => mockTransactionRepo.deleteAllByBook('book-2')).called(1);

    // Verify categories and books deleted
    verify(() => mockCategoryRepo.deleteAll()).called(1);
    verify(() => mockBookRepo.deleteAll()).called(1);

    // Verify settings reset to defaults
    verify(
      () => mockSettingsRepo.updateSettings(const AppSettings()),
    ).called(1);
  });

  test(
    'D-05: resets settings to defaults so onboardingComplete is false',
    () async {
      when(
        () => mockBookRepo.findAll(includeArchived: true, includeShadow: true),
      ).thenAnswer((_) async => []);
      when(() => mockCategoryRepo.deleteAll()).thenAnswer((_) async {});
      when(() => mockBookRepo.deleteAll()).thenAnswer((_) async {});
      when(
        () => mockSettingsRepo.updateSettings(any()),
      ).thenAnswer((_) async {});

      final result = await useCase.execute();

      expect(result.isSuccess, true);
      final persisted =
          verify(
                () => mockSettingsRepo.updateSettings(captureAny()),
              ).captured.single
              as AppSettings;
      expect(persisted.onboardingComplete, false);
    },
  );

  test(
    'D-05: deletes the UserProfile when one exists (identity wiped)',
    () async {
      final profile = UserProfile(
        id: 'profile-1',
        displayName: 'Taro',
        avatarEmoji: '🦊',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      when(
        () => mockBookRepo.findAll(includeArchived: true, includeShadow: true),
      ).thenAnswer((_) async => []);
      when(() => mockCategoryRepo.deleteAll()).thenAnswer((_) async {});
      when(() => mockBookRepo.deleteAll()).thenAnswer((_) async {});
      when(
        () => mockSettingsRepo.updateSettings(any()),
      ).thenAnswer((_) async {});
      when(() => mockUserProfileRepo.find()).thenAnswer((_) async => profile);

      final result = await useCase.execute();

      expect(result.isSuccess, true);
      verify(() => mockUserProfileRepo.delete('profile-1')).called(1);
    },
  );

  test('D-05: no delete attempted when no UserProfile exists', () async {
    when(
      () => mockBookRepo.findAll(includeArchived: true, includeShadow: true),
    ).thenAnswer((_) async => []);
    when(() => mockCategoryRepo.deleteAll()).thenAnswer((_) async {});
    when(() => mockBookRepo.deleteAll()).thenAnswer((_) async {});
    when(() => mockSettingsRepo.updateSettings(any())).thenAnswer((_) async {});
    when(() => mockUserProfileRepo.find()).thenAnswer((_) async => null);

    final result = await useCase.execute();

    expect(result.isSuccess, true);
    verifyNever(() => mockUserProfileRepo.delete(any()));
  });

  test('returns error on failure', () async {
    when(
      () => mockBookRepo.findAll(includeArchived: true, includeShadow: true),
    ).thenThrow(Exception('DB error'));

    final result = await useCase.execute();

    expect(result.isError, true);
    expect(result.error, contains('Failed to clear data'));
  });
}
