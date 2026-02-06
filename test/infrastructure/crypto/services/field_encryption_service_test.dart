import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/encryption_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:mocktail/mocktail.dart';

class MockEncryptionRepository extends Mock implements EncryptionRepository {}

void main() {
  late MockEncryptionRepository mockRepo;
  late FieldEncryptionService service;

  setUp(() {
    mockRepo = MockEncryptionRepository();
    service = FieldEncryptionService(repository: mockRepo);
  });

  group('encryptField', () {
    test('delegates to repository', () async {
      when(
        () => mockRepo.encryptField('test'),
      ).thenAnswer((_) async => 'encrypted_test');

      final result = await service.encryptField('test');

      expect(result, 'encrypted_test');
      verify(() => mockRepo.encryptField('test')).called(1);
    });
  });

  group('decryptField', () {
    test('delegates to repository', () async {
      when(
        () => mockRepo.decryptField('encrypted'),
      ).thenAnswer((_) async => 'decrypted');

      final result = await service.decryptField('encrypted');

      expect(result, 'decrypted');
    });
  });

  group('encryptAmount', () {
    test('delegates to repository', () async {
      when(
        () => mockRepo.encryptAmount(1234.56),
      ).thenAnswer((_) async => 'enc_amount');

      final result = await service.encryptAmount(1234.56);

      expect(result, 'enc_amount');
    });
  });

  group('decryptAmount', () {
    test('delegates to repository', () async {
      when(
        () => mockRepo.decryptAmount('enc'),
      ).thenAnswer((_) async => 1234.56);

      final result = await service.decryptAmount('enc');

      expect(result, 1234.56);
    });
  });

  group('clearCache', () {
    test('delegates to repository', () async {
      when(() => mockRepo.clearCache()).thenAnswer((_) async {});

      await service.clearCache();

      verify(() => mockRepo.clearCache()).called(1);
    });
  });
}
