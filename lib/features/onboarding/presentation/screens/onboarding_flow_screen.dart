import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/presentation/providers/repository_providers.dart';
import '../../../settings/presentation/providers/state_settings.dart';
import 'onboarding_intro_screen.dart';
import 'onboarding_lock_entry_screen.dart';
import 'onboarding_settings_screen.dart';

/// The first-boot onboarding flow host (ONBOARD-07 / D-11 / D-12 / D-13).
///
/// Composes the three step screens — intro → settings → lock-entry — inside a
/// nested [Navigator] (the app navigates with Navigator + MaterialPageRoute,
/// with no routing package). Forward navigation is wired through each screen's
/// callback:
///   - [OnboardingIntroScreen.onContinue]   → push the settings route
///   - [OnboardingSettingsScreen.onConfirmed] → push the lock-entry route
///   - [OnboardingLockEntryScreen.onComplete] → finish the flow
///
/// Back navigation is re-entrant: the nested Navigator pops settings → intro
/// and lock-entry → settings, while a root [PopScope] (`canPop: false`) guards
/// against popping out of onboarding on a fresh install — the flow can never
/// dead-lock or be exited before completion (D-12). There is intentionally NO
/// progress bar / step indicator (D-12); progress is conveyed only by the back
/// gesture.
///
/// `onboarding_complete` is written LAST — only on lock-entry completion (not
/// at settings-confirm) — immediately before entering the shell, so a flow
/// abandoned mid-way leaves the gate showing onboarding on the next boot.
class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({
    super.key,
    required this.bookId,
    required this.onCompleted,
  });

  final String bookId;

  /// Fired exactly once when onboarding finishes (after `onboarding_complete`
  /// has been persisted). The gate owner (`_HomePocketAppState`) wires this to
  /// flip `_needsOnboarding=false` + `setState`, so the live `'/'` home Builder
  /// renders the shell itself — the flow host MUST NOT replace the gate route
  /// (HI-01). `setupSecurity:true` requests the SecuritySection deep-link, which
  /// the gate owner pushes on top of the now-rendered shell (D-13).
  final void Function({required bool setupSecurity}) onCompleted;

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  final GlobalKey<NavigatorState> _nestedNavigatorKey =
      GlobalKey<NavigatorState>();

  void _pushSettings() {
    _nestedNavigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => OnboardingSettingsScreen(
          bookId: widget.bookId,
          onConfirmed: _pushLockEntry,
        ),
      ),
    );
  }

  void _pushLockEntry() {
    _nestedNavigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => OnboardingLockEntryScreen(onComplete: _complete),
      ),
    );
  }

  /// Final step (both 跳过 and 现在设置 land here). Writes
  /// `onboarding_complete = true` LAST, then hands off to the gate-owned
  /// [OnboardingFlowScreen.onCompleted] callback instead of navigating itself.
  ///
  /// Routing completion through the callback keeps the root `'/'` route bound to
  /// `_HomePocketAppState`'s live `_buildHome` gate (rather than replacing it
  /// with a detached shell), so a same-session delete-all / import-backup reset
  /// can still re-render the gate via `_reinitializeAfterDataReset` without an
  /// app restart (HI-01). On 现在设置 (`setupSecurity: true`) the gate owner
  /// deep-links to the SecuritySection on top of the freshly-rendered shell
  /// (D-13).
  Future<void> _complete({required bool setupSecurity}) async {
    await ref.read(settingsRepositoryProvider).setOnboardingComplete(true);
    ref.invalidate(appSettingsProvider);
    if (!mounted) {
      return;
    }

    widget.onCompleted(setupSecurity: setupSecurity);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // The fresh-install flow cannot be popped out of (D-12 / ONBOARD-07).
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        // Delegate the system back to the nested Navigator: pops settings →
        // intro and lock-entry → settings. On the intro (root) route this is a
        // no-op, so the flow stays mounted (re-entrant, cannot dead-lock).
        _nestedNavigatorKey.currentState?.maybePop();
      },
      child: Navigator(
        key: _nestedNavigatorKey,
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => OnboardingIntroScreen(onContinue: _pushSettings),
        ),
      ),
    );
  }
}
