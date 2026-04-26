import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/app_database.dart';
import '../../infrastructure/security/providers.dart' as security;

part 'repository_providers.g.dart';

// All providers prefixed with `app` to eliminate symbol collision with feature-side
// definitions during Wave 2/3 coexistence (per Warning 7 fix).

/// Application-layer re-export of [AppDatabase].
///
/// Analytics feature presentation imports this instead of
/// infrastructure/security/providers.dart (HIGH-02 compliance).
@riverpod
AppDatabase appAppDatabase(Ref ref) {
  return ref.watch(security.appDatabaseProvider);
}
