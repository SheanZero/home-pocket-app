// Wave-0 repository test scaffold — RED state expected.
// ShoppingItemDao, ShoppingItemRepositoryImpl, and ShoppingItem do not exist yet.
// This file will fail to analyze/compile until Plans 02, 04, 05, 06 are complete.
// Tests will turn GREEN after the full Phase 36 production implementation lands.

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/shopping_item_dao.dart'; // RED — does not exist yet
import 'package:home_pocket/data/repositories/shopping_item_repository_impl.dart'; // RED
import 'package:home_pocket/features/shopping_list/domain/models/shopping_item.dart'; // RED
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockFieldEncryptionService extends Mock
    implements FieldEncryptionService {}

/// Simulates decryption failure to test silent-failure behaviour (ITEM-05).
class _ThrowingFieldEncryptionService implements FieldEncryptionService {
  @override
  Future<String> encryptField(String plaintext) async =>
      'encrypted_$plaintext';

  /// Always throws — simulates wrong-device-key scenario.
  @override
  Future<String> decryptField(String ciphertext) async =>
      throw Exception('Cannot decrypt — wrong device key');

  @override
  Future<String> encryptAmount(double amount) async =>
      amount.toStringAsFixed(2);

  @override
  Future<double> decryptAmount(String encrypted) async =>
      double.parse(encrypted);

  @override
  Future<void> clearCache() async {}
}

void main() {
  late AppDatabase db;
  late ShoppingItemDao dao;
  late _MockFieldEncryptionService mockEncryption;
  late ShoppingItemRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = ShoppingItemDao(db);
    mockEncryption = _MockFieldEncryptionService();
    repo = ShoppingItemRepositoryImpl(
      dao: dao,
      encryptionService: mockEncryption,
    );

    // Default: encryption passthrough — enc_ prefix on encrypt, strip on decrypt
    when(
      () => mockEncryption.encryptField(any()),
    ).thenAnswer((inv) async => 'enc_${inv.positionalArguments[0]}');

    when(() => mockEncryption.decryptField(any())).thenAnswer((inv) async {
      final cipher = inv.positionalArguments[0] as String;
      return cipher.replaceFirst('enc_', '');
    });
  });

  tearDown(() async {
    await db.close();
  });

  group('ShoppingItemRepositoryImpl — ITEM-05 note encryption', () {
    test('insert encrypts note field', () async {
      final item = _makeItem(note: 'groceries');
      await repo.insert(item);

      verify(() => mockEncryption.encryptField('groceries')).called(1);
    });

    test('insert skips encryption for null note', () async {
      final item = _makeItem();
      await repo.insert(item);

      verifyNever(() => mockEncryption.encryptField(any()));
    });

    test('insert JSON-encodes tags and stores in DB', () async {
      final item = _makeItem(tags: ['milk', 'bread']);
      await repo.insert(item);

      final row = await dao.findById(item.id);
      expect(row, isNotNull);
      expect(row!.tags, equals('["milk","bread"]'));
    });

    test('insert with empty tags stores null', () async {
      final item = _makeItem(tags: []);
      await repo.insert(item);

      final row = await dao.findById(item.id);
      expect(row, isNotNull);
      expect(row!.tags, isNull);
    });

    test('findById decrypts note and decodes tags', () async {
      final item = _makeItem(note: 'groceries', tags: ['milk', 'bread']);
      await repo.insert(item);

      final result = await repo.findById(item.id);
      expect(result, isNotNull);
      expect(result!.note, equals('groceries'));
      expect(result.tags, equals(['milk', 'bread']));
    });

    test('estimatedPrice stored and retrieved as integer', () async {
      final item = _makeItem(estimatedPrice: 1500);
      await repo.insert(item);

      final result = await repo.findById(item.id);
      expect(result, isNotNull);
      expect(result!.estimatedPrice, equals(1500));
    });

    test('decrypt failure returns null note with other fields intact', () async {
      // Build a repo with the throwing service
      final throwingRepo = ShoppingItemRepositoryImpl(
        dao: dao,
        encryptionService: _ThrowingFieldEncryptionService(),
      );

      // Insert directly through DAO to simulate shadow-book ciphertext
      final item = _makeItem(id: 'item_shadow', note: 'some_ciphertext');
      // Insert via throwing repo (encrypt succeeds, returns encrypted_some_ciphertext)
      await throwingRepo.insert(item);

      // findById must return null note silently, all other fields intact
      final result = await throwingRepo.findById('item_shadow');
      expect(result, isNotNull);
      expect(result!.note, isNull);
      expect(result.id, equals('item_shadow'));
      expect(result.name, equals('Test'));
    });
  });
}

ShoppingItem _makeItem({
  String id = 'item_1',
  String? note,
  List<String> tags = const [],
  int? estimatedPrice,
}) {
  return ShoppingItem(
    id: id,
    deviceId: 'device_1',
    listType: 'private',
    name: 'Test',
    note: note,
    tags: tags,
    estimatedPrice: estimatedPrice,
    isCompleted: false,
    sortOrder: 0,
    isSynced: false,
    isDeleted: false,
    createdAt: DateTime(2026, 6, 7),
  );
}
