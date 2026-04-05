import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Callback triggered on app lifecycle events relevant to sync.
typedef SyncResumeCallback = Future<void> Function();
typedef SyncPausedCallback = void Function();

/// Observes app lifecycle to trigger sync on resume and flush on pause.
///
/// When the app returns to the foreground (resumed), calls [onResume].
/// When the app enters the background (paused), calls [onPaused].
class SyncLifecycleObserver with WidgetsBindingObserver {
  SyncLifecycleObserver({
    required SyncResumeCallback onResume,
    SyncPausedCallback? onPaused,
  }) : _onResume = onResume,
       _onPaused = onPaused;

  final SyncResumeCallback _onResume;
  final SyncPausedCallback? _onPaused;
  bool _isActive = false;

  /// Start observing lifecycle events.
  void start() {
    if (_isActive) return;
    WidgetsBinding.instance.addObserver(this);
    _isActive = true;
  }

  /// Stop observing lifecycle events.
  void dispose() {
    if (!_isActive) return;
    WidgetsBinding.instance.removeObserver(this);
    _isActive = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onResume().catchError((Object e) {
        if (kDebugMode) {
          debugPrint('SyncLifecycleObserver: resume sync failed: $e');
        }
      });
    } else if (state == AppLifecycleState.paused) {
      _onPaused?.call();
    }
  }
}
