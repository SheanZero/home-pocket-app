// lib/features/accounting/presentation/screens/voice_locale_readiness_mixin.dart
//
// Phase 23 D-07 (WR-01) — voiceLocaleId cold-start gate.
//
// Gap-closure Plan 23-09: moves the D-07 gate out of voice_input_screen.dart
// so the screen file stays under the CLAUDE.md `<800` LOC cap. D-07 behavior
// is preserved verbatim — see Truth #10 of 23-VERIFICATION.md.
//
// The existing D-10 VoiceRecognitionEventHandlerMixin is `on State<W>` because
// it does not need `ref`. This mixin needs `ref.listenManual`, which is only on
// `ConsumerState`, so the constraint here is intentionally tighter:
// `on ConsumerState<W>`.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/presentation/providers/state_settings.dart';

/// Phase 23 D-07 (WR-01): cold-start gate that prevents the speech recognizer
/// from being started before [voiceLocaleIdProvider] has resolved.
///
/// The host State class wires this mixin into its `with` clause and calls
/// [initLocaleReadiness] from `_initSpeechService` (or `initState`). The
/// `_onLongPressStart` guard reads [isLocaleReady] via the public getter.
/// On resolution, the mixin invokes the host-supplied [onVoiceLocaleResolved]
/// so the host's locale-string mirror (e.g. `_voiceLocaleId`) stays current.
///
/// Why this mixin only owns readiness — not the locale string itself: the host
/// (`_VoiceInputScreenState`) already holds `_voiceLocaleId` (read by
/// `_startRecording` and `_parseFinalResult`). Moving the string here would
/// expand scope; this plan is a slim-down refactor, not a contract change.
mixin VoiceLocaleReadinessMixin<W extends ConsumerStatefulWidget>
    on ConsumerState<W> {
  // ── D-07 readiness flag ──────────────────────────────────────────────────

  /// Phase 23 D-07 (WR-01 cold-start race fix): the recognizer must not
  /// run with the wrong locale during the first ms after launch.
  /// Flipped to true when voiceLocaleIdProvider resolves OR errors —
  /// graceful degradation per RESEARCH Pitfall 3.
  bool _isLocaleReady = false;

  /// Subscription handle for explicit cleanup in [dispose]. `ref.listenManual`
  /// returns a [ProviderSubscription] which must be closed to avoid leaks
  /// once the host State is disposed.
  ProviderSubscription<AsyncValue<String>>? _localeSubscription;

  // ── Public surface ───────────────────────────────────────────────────────

  /// Whether the voice locale has been resolved (or has errored — graceful
  /// degradation). Read by the host's `_onLongPressStart` guard.
  bool get isLocaleReady => _isLocaleReady;

  /// Host-supplied locale-string mirror update hook. Called whenever
  /// [voiceLocaleIdProvider] emits `AsyncData`, so the host can update its
  /// own `_voiceLocaleId` field for synchronous use in `_startRecording`.
  ///
  /// Not called on `AsyncError` — host keeps its default fallback (typically
  /// `'zh-CN'`); the mic is still unlocked so the user is not soft-locked.
  void onVoiceLocaleResolved(String localeId);

  /// Wire the D-07 listener. Call this once from the host's `_initSpeechService`
  /// (or `initState`). Body is the verbatim semantics of the prior in-screen
  /// `ref.listenManual<AsyncValue<String>>(voiceLocaleIdProvider, ...)` block.
  ///
  /// `fireImmediately: true` ensures the flag flips synchronously when the
  /// provider has already resolved (common on warm launches) — RESEARCH
  /// §Pattern 2.
  void initLocaleReadiness() {
    // Phase 23 D-07 (WR-01): gate the mic on voiceLocaleIdProvider resolution
    // so the recognizer is never started with the wrong locale during cold start.
    // fireImmediately: true ensures the flag flips synchronously when the provider
    // has already resolved (common on warm launches). RESEARCH §Pattern 2.
    _localeSubscription = ref.listenManual<AsyncValue<String>>(
      voiceLocaleIdProvider,
      (prev, next) {
        if (next case AsyncData(:final value)) {
          onVoiceLocaleResolved(value);
          if (mounted && !_isLocaleReady) {
            setState(() => _isLocaleReady = true);
          }
        } else if (next case AsyncError()) {
          // RESEARCH Pitfall 3: graceful degradation. Fall back to
          // default locale (host already initialized to 'zh-CN') and
          // unlock the mic. Prevents soft-lock when AppSettings provider
          // errors (e.g. corrupted SharedPreferences).
          if (mounted && !_isLocaleReady) {
            setState(() => _isLocaleReady = true);
          }
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _localeSubscription?.close();
    super.dispose();
  }
}
