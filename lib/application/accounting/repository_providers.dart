import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/app_database.dart';
import '../../infrastructure/crypto/providers.dart' as crypto;
import '../../infrastructure/crypto/services/field_encryption_service.dart';
import '../../infrastructure/crypto/services/hash_chain_service.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/security/providers.dart' as security;

part 'repository_providers.g.dart';

// All providers prefixed with `app` to eliminate symbol collision with feature-side
// definitions during Wave 2/3 coexistence (per Warning 7 fix).

/// Application-layer re-export of [AppDatabase].
///
/// Feature accounting presentation imports this instead of
/// infrastructure/security/providers.dart (HIGH-02 compliance).
@riverpod
AppDatabase appAppDatabase(Ref ref) {
  return ref.watch(security.appDatabaseProvider);
}

/// Application-layer re-export of [KeyManager].
///
/// Deduplicates the two-hop import via accounting feature's
/// infrastructure/crypto/providers.dart dependency.
@riverpod
KeyManager appKeyManager(Ref ref) {
  return ref.watch(crypto.keyManagerProvider);
}

/// Application-layer re-export of [FieldEncryptionService].
///
/// Feature accounting presentation uses this for TransactionRepository
/// construction without importing infrastructure/crypto directly (HIGH-02).
@riverpod
FieldEncryptionService appFieldEncryptionService(Ref ref) {
  return ref.watch(crypto.fieldEncryptionServiceProvider);
}

/// Application-layer re-export of [HashChainService].
///
/// Feature accounting presentation uses this for CreateTransactionUseCase
/// construction without importing infrastructure/crypto directly (HIGH-02).
@riverpod
HashChainService appHashChainService(Ref ref) {
  return ref.watch(crypto.hashChainServiceProvider);
}
