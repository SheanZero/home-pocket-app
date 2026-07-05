import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/security/app_lock_service.dart';
import '../../../../infrastructure/security/providers.dart';
import '../../../settings/presentation/providers/repository_providers.dart';

part 'repository_providers.g.dart';

/// Application-layer app-lock service — single source of truth for the lock
/// decision (D-01) and all PIN operations (LOCK-01/06).
///
/// Consumed by the cold-start gate (Plan 11), lock screen (Plan 09), and the
/// Settings security section (Plan 10). Wires the keychain (pinHash slot), the
/// biometric service (re-auth, D-05), and the settings repository (toggles).
///
/// Lives in the applock composition root (not infrastructure/security) — an
/// infrastructure provider watching a feature's settingsRepositoryProvider is
/// a reverse layer dependency (quality report P1-2).
@riverpod
AppLockService appLockService(Ref ref) {
  return AppLockService(
    settingsRepository: ref.watch(settingsRepositoryProvider),
    secureStorage: ref.watch(secureStorageServiceProvider),
    biometricService: ref.watch(biometricServiceProvider),
  );
}
