import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/settings/export_backup_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:mocktail/mocktail.dart';

import 'package:home_pocket/features/accounting/domain/repositories/book_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/settings/domain/repositories/settings_repository.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockBookRepository extends Mock implements BookRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late ExportBackupUseCase useCase;
  late MockTransactionRepository mockTransactionRepo;
  late MockCategoryRepository mockCategoryRepo;
  late MockBookRepository mockBookRepo;
  late MockSettingsRepository mockSettingsRepo;
  late Directory tempDir;

  setUp(() async {
    mockTransactionRepo = MockTransactionRepository();
    mockCategoryRepo = MockCategoryRepository();
    mockBookRepo = MockBookRepository();
    mockSettingsRepo = MockSettingsRepository();
    useCase = ExportBackupUseCase(
      transactionRepo: mockTransactionRepo,
      categoryRepo: mockCategoryRepo,
      bookRepo: mockBookRepo,
      settingsRepo: mockSettingsRepo,
    );

    tempDir = await Directory.systemTemp.createTemp('backup_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('rejects password shorter than 8 characters', () async {
    final result = await useCase.execute(bookId: 'book-1', password: 'short');

    expect(result.isError, true);
    expect(result.error, contains('at least 8 characters'));
  });

  test('exports backup with correct encrypted format', () async {
    // Arrange
    final now = DateTime(2026, 2, 7);
    when(() => mockTransactionRepo.findAllByBook('book-1')).thenAnswer(
      (_) async => [
        Transaction(
          id: 'tx-1',
          bookId: 'book-1',
          deviceId: 'dev',
          amount: 1000,
          type: TransactionType.expense,
          categoryId: 'cat-1',
          ledgerType: LedgerType.survival,
          timestamp: now,
          currentHash: 'hash1',
          createdAt: now,
        ),
      ],
    );
    when(() => mockCategoryRepo.findAll()).thenAnswer(
      (_) async => [
        Category(
          id: 'cat-1',
          name: 'Food',
          icon: 'food',
          color: '#FF0000',
          level: 1,
          createdAt: now,
        ),
      ],
    );
    when(() => mockBookRepo.findAll(includeArchived: true)).thenAnswer(
      (_) async => [
        Book(
          id: 'book-1',
          name: 'Default',
          currency: 'JPY',
          deviceId: 'dev',
          createdAt: now,
        ),
      ],
    );
    when(
      () => mockSettingsRepo.getSettings(),
    ).thenAnswer((_) async => const AppSettings());

    // Act - use temp directory to avoid path_provider dependency in test
    final result = await useCase.execute(
      bookId: 'book-1',
      password: 'test-password-123',
      deviceId: 'test-device',
      appVersion: '0.1.0',
      outputDirectory: tempDir,
    );

    // Assert
    expect(result.isSuccess, true);
    final file = result.data!;
    expect(await file.exists(), true);
    expect(file.path.endsWith('.hpb'), true);

    // Verify encrypted format: salt(16) + nonce(12) + ciphertext + mac(16)
    final bytes = await file.readAsBytes();
    expect(bytes.length, greaterThan(44)); // minimum size

    // Verify we can decrypt back
    final salt = bytes.sublist(0, 16);
    final nonce = bytes.sublist(16, 28);
    final cipherText = bytes.sublist(28, bytes.length - 16);
    final mac = Mac(bytes.sublist(bytes.length - 16));

    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );
    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode('test-password-123')),
      nonce: salt,
    );

    final algorithm = AesGcm.with256bits();
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);
    final plaintext = await algorithm.decrypt(secretBox, secretKey: secretKey);

    // Decompress
    final jsonBytes = gzip.decode(plaintext);
    final jsonString = utf8.decode(jsonBytes);
    final json = jsonDecode(jsonString) as Map<String, dynamic>;

    expect(json['metadata']['version'], '1.0');
    expect(json['metadata']['deviceId'], 'test-device');
    expect((json['transactions'] as List).length, 1);
    expect((json['categories'] as List).length, 1);
    expect((json['books'] as List).length, 1);

    // Cleanup
    await file.delete();
  });
}
