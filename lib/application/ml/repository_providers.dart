import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../infrastructure/ml/merchant_database.dart';
import 'lookup_merchant_use_case.dart';

part 'repository_providers.g.dart';

/// Application-layer MerchantDatabase provider.
///
/// CRITICAL: `keepAlive: true` is REQUIRED — this provider is on the HIGH-05
/// hard list (`merchantDatabaseProvider`). The `app` prefix is used because:
///   - The original `merchantDatabaseProvider` (in voice_providers.dart) remains
///     during Wave 2/3 coexistence until Plan 04-02 Task 5 deletes it.
///   - Plan 04-05's hard list is updated to reference `appMerchantDatabaseProvider`.
///   - Riverpod codegen creates symbols at library level; `app` prefix guarantees
///     no collision between the two definitions.
///
/// MerchantDatabase is kept alive because it holds an in-memory seed dataset
/// that should be instantiated once per app session.
@Riverpod(keepAlive: true)
MerchantDatabase appMerchantDatabase(Ref ref) {
  return MerchantDatabase();
}

/// Application-layer LookupMerchantUseCase provider.
@riverpod
LookupMerchantUseCase lookupMerchantUseCase(Ref ref) {
  return LookupMerchantUseCase(database: ref.watch(appMerchantDatabaseProvider));
}
