import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/settings/clear_all_data_use_case.dart';
import 'package:home_pocket/application/settings/export_backup_use_case.dart';
import 'package:home_pocket/application/settings/import_backup_use_case.dart';
import 'package:home_pocket/features/accounting/domain/repositories/book_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/settings/domain/repositories/settings_repository.dart';
import 'package:home_pocket/features/settings/presentation/providers/repository_providers.dart';
import 'package:mocktail/mocktail.dart';

// Inline Mocktail-only mocks (no @GenerateMocks, no package:mockito)
class _MockTransactionRepository extends Mock implements TransactionRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockBookRepository extends Mock implements BookRepository {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late _MockTransactionRepository mockTransactionRepo;
  late _MockCategoryRepository mockCategoryRepo;
  late _MockBookRepository mockBookRepo;
  late _MockSettingsRepository mockSettingsRepo;
  late ProviderContainer container;

  setUp(() {
    mockTransactionRepo = _MockTransactionRepository();
    mockCategoryRepo = _MockCategoryRepository();
    mockBookRepo = _MockBookRepository();
    mockSettingsRepo = _MockSettingsRepository();

    container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(mockTransactionRepo),
        categoryRepositoryProvider.overrideWithValue(mockCategoryRepo),
        bookRepositoryProvider.overrideWithValue(mockBookRepo),
        settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  group(
    'settings/backup_providers characterization tests (pre-refactor: all DI providers)',
    () {
      test('exportBackupUseCaseProvider constructs ExportBackupUseCase', () {
        final uc = container.read(exportBackupUseCaseProvider);
        expect(uc, isA<ExportBackupUseCase>());
      });

      test('importBackupUseCaseProvider constructs ImportBackupUseCase', () {
        final uc = container.read(importBackupUseCaseProvider);
        expect(uc, isA<ImportBackupUseCase>());
      });

      test('clearAllDataUseCaseProvider constructs ClearAllDataUseCase', () {
        final uc = container.read(clearAllDataUseCaseProvider);
        expect(uc, isA<ClearAllDataUseCase>());
      });

      test('all 3 backup use case providers return non-null instances', () {
        expect(container.read(exportBackupUseCaseProvider), isNotNull);
        expect(container.read(importBackupUseCaseProvider), isNotNull);
        expect(container.read(clearAllDataUseCaseProvider), isNotNull);
      });
    },
  );
}
