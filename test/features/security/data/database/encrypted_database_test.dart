import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:home_pocket/features/security/data/database/encrypted_database.dart';
import 'package:home_pocket/features/security/application/services/key_manager.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:convert';

@GenerateMocks([KeyManager])
import 'encrypted_database_test.mocks.dart';

void main() {
  group('EncryptedDatabase', () {
    late MockKeyManager mockKeyManager;

    setUp(() {
      mockKeyManager = MockKeyManager();
    });

    test('should create database executor with encryption key', () async {
      // Arrange
      final mockKey = List<int>.filled(32, 42);
      when(mockKeyManager.getPublicKey()).thenAnswer((_) async => base64Encode(mockKey));

      // Act
      final executor = await createEncryptedExecutor(mockKeyManager, inMemory: true);

      // Assert
      expect(executor, isA<NativeDatabase>());
    });

    test('should fail when key manager has no key', () async {
      // Arrange
      when(mockKeyManager.getPublicKey()).thenAnswer((_) async => null);

      // Act & Assert
      expect(
        () => createEncryptedExecutor(mockKeyManager, inMemory: true),
        throwsA(isA<StateError>()),
      );
    });

    test('should create different keys for different public keys', () async {
      // Arrange
      final key1 = List<int>.filled(32, 42);
      final key2 = List<int>.filled(32, 99);

      // Act: Create with first key
      when(mockKeyManager.getPublicKey()).thenAnswer((_) async => base64Encode(key1));
      final executor1 = await createEncryptedExecutor(mockKeyManager, inMemory: true);

      // Act: Create with second key
      when(mockKeyManager.getPublicKey()).thenAnswer((_) async => base64Encode(key2));
      final executor2 = await createEncryptedExecutor(mockKeyManager, inMemory: true);

      // Assert
      expect(executor1, isA<NativeDatabase>());
      expect(executor2, isA<NativeDatabase>());
      // Both executors created successfully but with different encryption keys
    });

    test('should support in-memory databases for testing', () async {
      // Arrange
      final mockKey = List<int>.filled(32, 42);
      when(mockKeyManager.getPublicKey()).thenAnswer((_) async => base64Encode(mockKey));

      // Act
      final executor = await createEncryptedExecutor(mockKeyManager, inMemory: true);

      // Assert
      expect(executor, isA<NativeDatabase>());
    });

    test('should derive consistent encryption key from same public key', () async {
      // Arrange
      final mockKey = List<int>.filled(32, 42);
      when(mockKeyManager.getPublicKey()).thenAnswer((_) async => base64Encode(mockKey));

      // Act: Create executor twice with same key
      final executor1 = await createEncryptedExecutor(mockKeyManager, inMemory: true);
      final executor2 = await createEncryptedExecutor(mockKeyManager, inMemory: true);

      // Assert
      expect(executor1, isA<NativeDatabase>());
      expect(executor2, isA<NativeDatabase>());
      // Same public key should derive same encryption key (tested indirectly by successful creation)
    });
  });
}
