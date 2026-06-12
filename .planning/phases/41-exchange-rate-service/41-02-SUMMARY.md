---
phase: 41-exchange-rate-service
plan: "02"
subsystem: infra
tags: [connectivity_plus, dependency, ios-build, flutter, pubspec]

# Dependency graph
requires:
  - phase: 41-01
    provides: ExchangeRateRepository extensions (findLatestNonManual, deleteOlderThan) — data foundation the cache service will use
provides:
  - connectivity_plus ^7.1.1 dependency available for D-05 connectivity gate
  - iOS build verified green with the new native plugin (no SQLCipher/intl/win32 conflicts)
affects: [41-03, exchange_rate_cache_service, connectivity-gate]

# Tech tracking
tech-stack:
  added: [connectivity_plus ^7.1.1]
  patterns: [direct-pubspec-edit-over-pub-add to preserve pin comments]

key-files:
  created: []
  modified: [pubspec.yaml, pubspec.lock]

key-decisions:
  - "Added connectivity_plus via direct pubspec.yaml edit (not flutter pub add) to preserve existing pin comments and formatting"
  - "Placed connectivity_plus next to web_socket_channel in the network/database block"

patterns-established:
  - "New native-plugin dependencies require a blocking iOS-build human-verify checkpoint before any consuming code is written (CLAUDE.md iOS Build rule)"

requirements-completed: [RATE-03]

# Metrics
duration: 5min
completed: 2026-06-12
---

# Phase 41 Plan 02: connectivity_plus Dependency Summary

**Added connectivity_plus ^7.1.1 to pubspec.yaml and human-verified the iOS debug build stays green — no SQLCipher, intl, or win32 pin conflicts — unblocking the D-05 connectivity gate in Plan 03.**

## Performance

- **Duration:** ~5 min active execution (Dart-side); plus blocking iOS-build human-verify checkpoint wait
- **Started:** 2026-06-12T15:37:08Z
- **Completed:** 2026-06-12T23:54:36Z (after checkpoint approval)
- **Tasks:** 2 (1 auto + 1 blocking human-verify)
- **Files modified:** 2 (pubspec.yaml, pubspec.lock)

## Accomplishments

- `connectivity_plus: ^7.1.1` added to `pubspec.yaml`, resolved at exactly `7.1.1`
- `flutter pub get` succeeded (exit 0, "Changed 3 dependencies!") with zero version-solving conflicts
- All pinned versions confirmed unchanged: `file_picker 11.0.2`, `package_info_plus 9.0.1`, `share_plus 12.0.2`, `win32 5.15.0` (the locked trio + anchor), `intl 0.20.2`, `sqlcipher_flutter_libs 0.6.8`, `sqlite3 2.9.4` (no `sqlite3_flutter_libs`)
- iOS debug build human-verified green: `✓ Built build/ios/iphoneos/Runner.app`, Xcode 44.0s, `pod install` clean (480ms), no sqlite3 symbol conflict, no Swift errors

## Task Commits

Each task was committed atomically:

1. **Task 1: Add connectivity_plus to pubspec.yaml and resolve dependencies** - `38fa0ad0` (feat)
2. **Task 2: iOS build verification** - no code commit (blocking `checkpoint:human-verify`; verification evidence recorded below)

**Plan metadata:** committed with this SUMMARY (docs: complete plan)

## Files Created/Modified

- `pubspec.yaml` - Added `connectivity_plus: ^7.1.1` in the network/database dependency block (next to `web_socket_channel`)
- `pubspec.lock` - Locked `connectivity_plus 7.1.1` + 2 transitive deps (`connectivity_plus_platform_interface`, `nm`); all other pins unchanged

## Decisions Made

- Edited `pubspec.yaml` directly instead of `flutter pub add` — preserves the existing pin comments and formatting per the plan's explicit instruction.
- Positioned `connectivity_plus` alphabetically/contextually near `web_socket_channel` (network-related), keeping the database/networking block cohesive.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. `flutter pub get` resolved cleanly on the first attempt. The only build-time notice was the pre-existing, harmless `sqlcipher_flutter_libs` Swift Package Manager advisory (unrelated to this change and present before this plan).

## iOS Build Verification (Task 2 — blocking checkpoint)

Human ran `flutter build ios --debug --no-codesign`:

- `✓ Built build/ios/iphoneos/Runner.app`
- Xcode build completed in 44.0s; `pod install` ran clean (480ms)
- No sqlite3 symbol conflict, no Swift compile errors, no pod failures
- Only notice: pre-existing harmless `sqlcipher_flutter_libs` SPM warning (unrelated)
- Approved 2026-06-12

This satisfies the T-41-03 mitigation (Tampering — connectivity_plus CocoaPod must not introduce a duplicate sqlite3 symbol): the iOS build confirms no symbol conflict and the Podfile `-lsqlite3` strip remains intact.

## User Setup Required

None - no external service configuration required. `connectivity_plus` is a FlutterCommunity plugin fetched from pub.dev with no API keys or runtime configuration.

## Next Phase Readiness

- `connectivity_plus` is available for `ExchangeRateCacheService` (Plan 03) to implement the D-05 connectivity gate via `Connectivity().checkConnectivity()`.
- iOS native build is confirmed green, so Plan 03 can build consuming code without re-litigating the native dependency.
- No blockers.

## Self-Check: PASSED

- FOUND: `.planning/phases/41-exchange-rate-service/41-02-SUMMARY.md`
- FOUND: `pubspec.yaml` with `connectivity_plus: ^7.1.1`
- FOUND: commit `38fa0ad0` (Task 1)

---
*Phase: 41-exchange-rate-service*
*Completed: 2026-06-12*
