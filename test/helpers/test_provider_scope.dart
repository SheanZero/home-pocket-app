import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
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

/// Waits for an async (Future/Stream) provider to settle to data or error.
///
/// Riverpod 3 disposes orphan reads sooner than 2.x, so the bare
/// `await container.read(provider.future)` pattern errors with
/// "disposed during loading state" before the build finishes. Use this
/// helper to hold an active `container.listen` subscription across the
/// async emit and resolve with the terminal [AsyncValue].
Future<AsyncValue<T>> waitForFirstValue<T>(
  ProviderContainer container,
  ProviderListenable<AsyncValue<T>> provider,
) {
  final completer = Completer<AsyncValue<T>>();
  final sub = container.listen<AsyncValue<T>>(provider, (_, next) {
    if ((next.hasError || next.hasValue) && !completer.isCompleted) {
      completer.complete(next);
    }
  }, fireImmediately: true);
  return completer.future.whenComplete(sub.close);
}
