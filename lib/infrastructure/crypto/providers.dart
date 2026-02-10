import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../security/providers.dart';
import 'repositories/master_key_repository.dart';
import 'repositories/master_key_repository_impl.dart';
import 'repositories/key_repository.dart';
import 'repositories/key_repository_impl.dart';
import 'repositories/encryption_repository.dart';
import 'repositories/encryption_repository_impl.dart';
import 'services/key_manager.dart';
import 'services/field_encryption_service.dart';
import 'services/hash_chain_service.dart';

part 'providers.g.dart';

/// Master key repository - manages 256-bit master key and HKDF derivation
@riverpod
MasterKeyRepository masterKeyRepository(Ref ref) {
  final storage = ref.watch(flutterSecureStorageProvider);
  return MasterKeyRepositoryImpl(secureStorage: storage);
}

/// Key repository - manages Ed25519 key pairs
@riverpod
KeyRepository keyRepository(Ref ref) {
  final storage = ref.watch(flutterSecureStorageProvider);
  return KeyRepositoryImpl(secureStorage: storage);
}

/// Key manager - high-level key operations
@riverpod
KeyManager keyManager(Ref ref) {
  final repository = ref.watch(keyRepositoryProvider);
  return KeyManager(repository: repository);
}

/// Check if device has a key pair
@riverpod
Future<bool> hasKeyPair(Ref ref) async {
  final km = ref.watch(keyManagerProvider);
  return km.hasKeyPair();
}

/// Encryption repository - ChaCha20-Poly1305 field encryption
@riverpod
EncryptionRepository encryptionRepository(Ref ref) {
  final masterKeyRepo = ref.watch(masterKeyRepositoryProvider);
  return EncryptionRepositoryImpl(masterKeyRepository: masterKeyRepo);
}

/// Field encryption service - high-level encryption operations
@riverpod
FieldEncryptionService fieldEncryptionService(Ref ref) {
  final repository = ref.watch(encryptionRepositoryProvider);
  return FieldEncryptionService(repository: repository);
}

/// Hash chain service - SHA-256 transaction integrity
@riverpod
HashChainService hashChainService(Ref ref) {
  return HashChainService();
}
