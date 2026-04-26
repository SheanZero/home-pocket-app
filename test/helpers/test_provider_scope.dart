import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/infrastructure/security/providers.dart';

/// Build a ProviderContainer that ALWAYS overrides `appDatabaseProvider`
/// with an in-memory `AppDatabase.forTesting()` (or the supplied [database]).
///
/// Per Phase 3 D-04 + CRIT-03 — this is the shared helper that satisfies
/// the "always provides the override" contract.
ProviderContainer createTestProviderScope({
  AppDatabase? database,
  List<Override> additionalOverrides = const [],
}) {
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(
        database ?? AppDatabase.forTesting(),
      ),
      ...additionalOverrides,
    ],
  );
}
