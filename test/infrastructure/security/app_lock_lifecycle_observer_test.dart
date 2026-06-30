import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/security/app_lock_lifecycle_observer.dart';

/// Drives [AppLockLifecycleObserver] through raw [AppLifecycleState]
/// transitions to pin the RESEARCH §2 two-flag guard (LOCK-03/04) without a
/// real device. Each scenario asserts explicit onRelock/onMask/onUnmask call
/// counts.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late int relockCount;
  late int maskCount;
  late int unmaskCount;
  late bool lockEffective;
  late AppLockLifecycleObserver observer;

  setUp(() {
    relockCount = 0;
    maskCount = 0;
    unmaskCount = 0;
    lockEffective = true;
    observer = AppLockLifecycleObserver(
      isLockEffective: () => lockEffective,
      onRelock: () => relockCount++,
      onMask: () => maskCount++,
      onUnmask: () => unmaskCount++,
    );
  });

  void feed(AppLifecycleState state) =>
      observer.didChangeAppLifecycleState(state);

  group('true background (paused round-trip)', () {
    test('inactive -> paused -> resumed relocks exactly once and masks', () {
      feed(AppLifecycleState.inactive);
      feed(AppLifecycleState.paused);
      feed(AppLifecycleState.resumed);

      expect(relockCount, 1, reason: 'real background must relock once');
      expect(maskCount, 1, reason: 'mask shows on inactive when effective');
      expect(unmaskCount, 1, reason: 'unmask on resume');
    });
  });

  group('Control Center / Notification Center (inactive-only)', () {
    test('inactive -> resumed (no paused) masks but never relocks', () {
      feed(AppLifecycleState.inactive);
      feed(AppLifecycleState.resumed);

      expect(relockCount, 0, reason: 'no paused => no relock (LOCK-03)');
      expect(maskCount, 1, reason: 'inactive still masks');
      expect(unmaskCount, 1);
    });
  });

  group('biometric sheet fence (_authInProgress)', () {
    test('inactive -> resumed during auth does NOT relock', () {
      observer.beginAuth();
      feed(AppLifecycleState.inactive);
      feed(AppLifecycleState.resumed);

      expect(relockCount, 0, reason: 'auth fence suppresses relock');
    });

    test('auth-fenced paused does not arm relock even after endAuth', () {
      observer.beginAuth();
      feed(AppLifecycleState.inactive);
      feed(AppLifecycleState.paused); // fenced: must NOT set _didPause
      observer.endAuth();
      feed(AppLifecycleState.resumed);

      expect(relockCount, 0,
          reason: 'pause seen only during auth must not arm relock');
    });

    test('after endAuth a real background round-trip relocks', () {
      observer.beginAuth();
      feed(AppLifecycleState.inactive);
      feed(AppLifecycleState.resumed);
      observer.endAuth();

      // A genuine subsequent backgrounding must relock normally.
      feed(AppLifecycleState.inactive);
      feed(AppLifecycleState.paused);
      feed(AppLifecycleState.resumed);

      expect(relockCount, 1, reason: 'fence cleared => normal relock resumes');
    });
  });

  group('lock disabled (LOCK-01 no-op)', () {
    setUp(() => lockEffective = false);

    test('inactive does not mask when lock not effective', () {
      feed(AppLifecycleState.inactive);
      expect(maskCount, 0);
    });

    test('paused -> resumed does not relock when lock not effective', () {
      feed(AppLifecycleState.inactive);
      feed(AppLifecycleState.paused);
      feed(AppLifecycleState.resumed);

      expect(relockCount, 0, reason: 'disabled lock never relocks');
    });
  });

  group('hidden/detached are no-ops', () {
    test('neither masks nor relocks', () {
      feed(AppLifecycleState.hidden);
      feed(AppLifecycleState.detached);

      expect(relockCount, 0);
      expect(maskCount, 0);
      expect(unmaskCount, 0);
    });
  });

  group('start/dispose idempotency', () {
    test('double start and double dispose do not throw', () {
      observer.start();
      observer.start();
      observer.dispose();
      observer.dispose();
    });
  });
}
