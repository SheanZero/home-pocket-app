import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/security/app_lock_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/security/biometric_service.dart';
import '../../../../infrastructure/security/providers.dart';
import '../../../applock/presentation/screens/set_pin_screen.dart';
import '../../../applock/presentation/widgets/pin_dots.dart';
import '../../../applock/presentation/widgets/pin_keypad.dart';
import '../../domain/models/app_settings.dart';
import '../providers/repository_providers.dart';
import '../providers/state_settings.dart';

/// Settings control surface that arms/disarms the app lock (D-11 / LOCK-01/06).
///
/// Shape:
///   * **App-lock master** [SwitchListTile] — value mirrors [AppSettings.appLockEnabled].
///     OFF→ON pushes the double-entry [SetPinScreen]; `appLockEnabled` flips true
///     ONLY after a PIN is successfully set (else the toggle reverts — never lock
///     without a PIN, T-55-24). ON→OFF requires re-auth first (D-05).
///   * When enabled, two sub-items are revealed: the `生体認証で解除` sub-toggle
///     (gated by [biometricAvailabilityProvider]) and a `修改 PIN` entry that
///     re-authenticates before re-opening [SetPinScreen].
///   * The existing `notifications` [SwitchListTile] is unchanged.
///
/// All lock decisions/PIN operations route through the single [appLockServiceProvider]
/// so the Settings surface can never diverge from the cold-start gate. Plaintext
/// PINs are never stored or logged; strings via [S]; theme via [context.palette].
class SecuritySection extends ConsumerWidget {
  const SecuritySection({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = S.of(context);
    final biometricAvailable = switch (
        ref.watch(biometricAvailabilityProvider).value) {
      BiometricAvailability.faceId ||
      BiometricAvailability.fingerprint ||
      BiometricAvailability.strongBiometric ||
      BiometricAvailability.weakBiometric ||
      BiometricAvailability.generic =>
        true,
      _ => false,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l.security,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.lock_outline),
          title: Text(l.securityAppLock),
          subtitle: Text(l.securityAppLockDescription),
          value: settings.appLockEnabled,
          onChanged: (value) => value
              ? _enableLock(context, ref)
              : _disableLock(context, ref),
        ),
        if (settings.appLockEnabled) ...[
          if (biometricAvailable)
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: Text(l.securityBiometricUnlock),
              subtitle: Text(l.securityBiometricUnlockDescription),
              value: settings.biometricUnlockEnabled,
              onChanged: (value) async {
                await ref
                    .read(settingsRepositoryProvider)
                    .setBiometricUnlockEnabled(value);
                ref.invalidate(appSettingsProvider);
              },
            ),
          ListTile(
            leading: const Icon(Icons.password),
            title: Text(l.securityChangePin),
            onTap: () => _changePin(context, ref),
          ),
        ],
        SwitchListTile(
          secondary: const Icon(Icons.notifications),
          title: Text(S.of(context).notifications),
          subtitle: Text(S.of(context).notificationsDescription),
          value: settings.notificationsEnabled,
          onChanged: (value) async {
            await ref
                .read(settingsRepositoryProvider)
                .setNotificationsEnabled(value);
            ref.invalidate(appSettingsProvider);
          },
        ),
      ],
    );
  }

  /// OFF→ON: set a PIN first; only then persist `appLockEnabled=true`.
  Future<void> _enableLock(BuildContext context, WidgetRef ref) async {
    final ok = await _openSetPin(context, ref);
    if (!ok) return; // Cancelled / failed — never enable without a PIN.
    await ref.read(appLockServiceProvider).enableLock();
    ref.invalidate(appSettingsProvider);
  }

  /// ON→OFF: require re-auth (biometric or current PIN) before disabling (D-05).
  Future<void> _disableLock(BuildContext context, WidgetRef ref) async {
    final ok = await _reauthenticate(context, ref);
    if (!ok) return;
    await ref.read(appLockServiceProvider).disableLock();
    ref.invalidate(appSettingsProvider);
  }

  /// 修改 PIN: re-auth first (D-05), then open the double-entry flow again.
  Future<void> _changePin(BuildContext context, WidgetRef ref) async {
    final ok = await _reauthenticate(context, ref);
    if (!ok || !context.mounted) return;
    final changed = await _openSetPin(context, ref);
    if (changed) ref.invalidate(appSettingsProvider);
  }

  /// Pushes [SetPinScreen]; returns true only when a PIN was successfully set.
  Future<bool> _openSetPin(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const SetPinScreen()),
    );
    return result ?? false;
  }

  /// D-05 re-auth: biometric first (when enabled), falling back to verifying the
  /// current PIN in a minimal in-place surface. Returns true on success.
  Future<bool> _reauthenticate(BuildContext context, WidgetRef ref) async {
    final service = ref.read(appLockServiceProvider);
    if (await service.reauth()) return true;
    if (!context.mounted) return false;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _PinReauthDialog(service: service),
    );
    return ok ?? false;
  }
}

/// Minimal in-place PIN re-entry surface used for D-05 re-auth.
///
/// Deliberately NOT the wave-3 `AppLockScreen` (Plan 09) — that would create a
/// cross-plan dependency; this only needs `AppLockService.verifyPin` from Plan
/// 07, keeping Plan 10 race-free within wave 3. Composes the Plan 08
/// [PinKeypad]/[PinDots]; a correct PIN pops `true`, a wrong PIN shakes/clears
/// and stays retryable. Plaintext PINs are never logged.
class _PinReauthDialog extends StatefulWidget {
  const _PinReauthDialog({required this.service});

  final AppLockService service;

  @override
  State<_PinReauthDialog> createState() => _PinReauthDialogState();
}

class _PinReauthDialogState extends State<_PinReauthDialog> {
  static const int _pinLength = 4;

  String _entered = '';
  int _errorTrigger = 0;
  bool _verifying = false;

  void _onDigit(int digit) {
    if (_verifying || _entered.length >= _pinLength) return;
    setState(() => _entered += '$digit');
    if (_entered.length == _pinLength) {
      _verify();
    }
  }

  void _onBackspace() {
    if (_verifying || _entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _verify() async {
    final pin = _entered;
    setState(() => _verifying = true);
    final ok = await widget.service.verifyPin(pin);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _entered = '';
      _errorTrigger += 1;
      _verifying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l = S.of(context);
    return Dialog(
      backgroundColor: palette.background,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.appLockReauthReason,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: PinDots(
                  filledCount: _entered.length,
                  length: _pinLength,
                  errorTrigger: _errorTrigger,
                ),
              ),
              const SizedBox(height: 28),
              PinKeypad(onDigit: _onDigit, onBackspace: _onBackspace),
            ],
          ),
        ),
      ),
    );
  }
}
