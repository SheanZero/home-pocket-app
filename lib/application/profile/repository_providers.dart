import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/app_database.dart';
import '../../infrastructure/crypto/providers.dart' as crypto;
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/security/providers.dart' as security;

part 'repository_providers.g.dart';

// All providers prefixed with `app` to eliminate symbol collision with feature-side
// definitions during Wave 2/3 coexistence (per Warning 7 fix).

/// Application-layer re-export of [AppDatabase].
///
/// Profile feature presentation imports this instead of
/// infrastructure/security/providers.dart (HIGH-02 compliance).
@riverpod
AppDatabase appAppDatabase(Ref ref) {
  return ref.watch(security.appDatabaseProvider);
}

/// Application-layer re-export of [KeyManager].
///
/// Profile feature presentation imports this instead of
/// infrastructure/crypto/providers.dart (HIGH-02 compliance).
@riverpod
KeyManager appKeyManager(Ref ref) {
  return ref.watch(crypto.keyManagerProvider);
}
