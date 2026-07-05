import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/settings/clear_all_data_use_case.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/book_dao.dart';
import 'package:home_pocket/data/daos/category_dao.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/repositories/book_repository_impl.dart';
import 'package:home_pocket/data/repositories/category_repository_impl.dart';
import 'package:home_pocket/data/repositories/transaction_repository_impl.dart';
import 'package:home_pocket/data/repositories/unit_of_work_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:home_pocket/features/settings/domain/repositories/settings_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockFieldEncryptionService extends Mock
    implements FieldEncryptionService {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

void main() {
  late AppDatabase db;
  late BookRepositoryImpl bookRepo;
  late CategoryRepositoryImpl categoryRepo;
  late TransactionRepositoryImpl transactionRepo;
  late _MockSettingsRepository settingsRepo;
  late _MockUserProfileRepository userProfileRepo;

  setUpAll(() {
    registerFallbackValue(const AppSettings());
  });

  setUp(() async {
    db = AppDatabase.forTesting();
    final mockEncryption = _MockFieldEncryptionService();
    when(
      () => mockEncryption.encryptField(any()),
    ).thenAnswer((inv) async => 'enc_${inv.positionalArguments[0]}');
    when(() => mockEncryption.decryptField(any())).thenAnswer(
      (inv) async =>
          (inv.positionalArguments[0] as String).replaceFirst('enc_', ''),
    );

    bookRepo = BookRepositoryImpl(dao: BookDao(db));
    categoryRepo = CategoryRepositoryImpl(dao: CategoryDao(db));
    transactionRepo = TransactionRepositoryImpl(
      dao: TransactionDao(db),
      encryptionService: mockEncryption,
    );
    settingsRepo = _MockSettingsRepository();
    userProfileRepo = _MockUserProfileRepository();
    when(() => userProfileRepo.find()).thenAnswer((_) async => null);

    await bookRepo.insert(
      Book(
        id: 'book_old',
        name: 'Old Book',
        currency: 'JPY',
        deviceId: 'dev_001',
        createdAt: DateTime(2026, 1, 1),
      ),
    );
    await categoryRepo.insert(
      Category(
        id: 'cat_old',
        name: 'Old Category',
        icon: 'food',
        color: '#5FAE72',
        level: 1,
        createdAt: DateTime(2026, 1, 1),
      ),
    );
    await transactionRepo.insert(
      Transaction(
        id: 'tx_old',
        bookId: 'book_old',
        deviceId: 'dev_001',
        amount: 1200,
        type: TransactionType.expense,
        categoryId: 'cat_old',
        ledgerType: LedgerType.daily,
        timestamp: DateTime(2026, 1, 2, 12),
        currentHash: 'hash_old',
        createdAt: DateTime(2026, 1, 2, 12),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'failed clear (settings reset throws) leaves existing data intact',
    () async {
      when(
        () => settingsRepo.updateSettings(any()),
      ).thenThrow(Exception('prefs write failed'));

      final useCase = ClearAllDataUseCase(
        transactionRepo: transactionRepo,
        categoryRepo: categoryRepo,
        bookRepo: bookRepo,
        settingsRepo: settingsRepo,
        userProfileRepo: userProfileRepo,
        unitOfWork: UnitOfWorkImpl(db: db),
      );

      final result = await useCase.execute();

      expect(result.isError, isTrue);

      final books = await bookRepo.findAll(
        includeArchived: true,
        includeShadow: true,
      );
      expect(
        books.map((b) => b.id),
        contains('book_old'),
        reason: 'a failed clear-all must roll back the database deletes',
      );
      expect(
        (await categoryRepo.findAll()).map((c) => c.id),
        contains('cat_old'),
      );
      expect(
        (await transactionRepo.findAllByBook('book_old')).map((t) => t.id),
        contains('tx_old'),
      );
    },
  );
}
