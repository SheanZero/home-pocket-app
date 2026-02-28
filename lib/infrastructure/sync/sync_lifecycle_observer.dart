import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Callback triggered on app lifecycle events relevant to sync.
typedef SyncResumeCallback = Future<void> Function();

/// Observes app lifecycle to trigger sync on resume.
///
/// When the app returns to the foreground (resumed), calls the registered
/// callback which should pull pending sync messages and drain the offline queue.
class SyncLifecycleObserver with WidgetsBindingObserver {
  SyncLifecycleObserver({required SyncResumeCallback onResume})
      : _onResume = onResume;

  final SyncResumeCallback _onResume;
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
    }
  }
}
