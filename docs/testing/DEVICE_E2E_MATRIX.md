# Device E2E Matrix

This matrix is the release-facing device test contract for Happy Pocket. The
automated lane runs inside a booted iOS simulator and Android emulator; host VM
tests remain useful but do not count as device coverage.

## Automated device lane

| Critical path | Device assertion | Test |
|---|---|---|
| First launch and onboarding | The full `HomePocketApp` gate reaches onboarding, persists completion, and enters the shell | `device_critical_journey_test.dart` |
| Ledger creation | The user enters an amount through the production keypad and the transaction is read back from the encrypted repository | `device_critical_journey_test.dart` |
| SQLCipher initialization | `PRAGMA cipher_version` is non-empty on the native executor; the encrypted file closes and reopens with the same key | `device_critical_journey_test.dart`, `merchant_migration_ladder_test.dart` |
| Cold-start app lock | A PIN hash and toggle survive a fresh container/database reopen; the lock gate blocks the shell until the correct PIN | `device_critical_journey_test.dart` |
| Encrypted backup/restore | Production export writes an HPB file, local rows are removed, and production import restores them | `device_critical_journey_test.dart` |
| Offline queue | Ciphertext, vector clock, retry state, key epoch, and withdrawal receipt survive a SQLCipher reopen | `device_sync_delivery_test.dart` |
| Push and relay ACK | A queued push is removed only after relay acceptance; withdrawal settlement runs on the ACK path | `device_sync_delivery_test.dart` |
| Pull and ACK ordering | A pulled operation is durably applied before its message is acknowledged, then the queued push lane drains | `device_sync_delivery_test.dart` |
| Push routing | Provider initialization, permission request, token registration, and foreground `sync_available` routing execute in order | `device_sync_delivery_test.dart` |

The test databases use the production HKDF and SQLCipher setup, but live in a
unique temporary directory. Test preferences, device identity, and PIN storage
are isolated in memory, so the suite never reads or destroys an installed user's
database or encryption root.

## CI and local commands

The blocking workflow is [`.github/workflows/device-e2e.yml`](../../.github/workflows/device-e2e.yml).
It runs the whole `integration_test/` directory on Android API 35 and an
available iPhone simulator for relevant pull requests and pushes to `main`. It
can also be started manually before a release.

```bash
flutter devices
flutter test integration_test/ -d <android-emulator-id> -r expanded
flutter test integration_test/ -d <ios-simulator-id> -r expanded
```

## Provider-backed release UAT

Cloud CI cannot prove APNs/FCM delivery, notification-tap launch, or a real
two-device relay exchange without production-like signing, push entitlements,
server credentials, and two registered devices. Before a release candidate is
approved, record the following on one physical iOS device and one physical
Android device:

1. Fresh install, onboarding, one ledger entry, terminate, and cold relaunch.
2. Enable the app lock, background and relaunch, then unlock by PIN and an
   enrolled biometric where supported.
3. Export an HPB, remove the test ledger entry, import the HPB, and verify it is
   restored after another cold relaunch.
4. Pair two devices, create/update/delete a shared entry while the receiver is
   offline, reconnect it, and verify push → pull → ACK convergence on both.
5. Open the app from a family notification and verify the intended destination.
6. Capture app versions, OS versions, device models, relay environment, UTC
   timestamps, result, and redacted screenshots/logs. Never attach payloads,
   notes, amounts, keys, tokens, or recovery material.

The provider-backed lane is intentionally labelled manual UAT; mocked provider
adapters in CI are not presented as evidence of real APNs/FCM delivery.
