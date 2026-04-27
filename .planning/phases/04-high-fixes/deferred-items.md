# Phase 04 Deferred Items

## Resolved: family_sync_notification_route_listener_test failures (2026-04-27)

**File:** `test/widget/features/family_sync/presentation/widgets/family_sync_notification_route_listener_test.dart`
**Original status:** 4 failing tests, mis-classified as "pre-existing" by 04-05 agent.
**Actual root cause:** Plan 04-02 (commit `c881d0d`) re-routed `FamilySyncNotificationRouteListener`'s DI through the application layer — `listenToPushNotificationsUseCaseProvider` now reads `appPushNotificationServiceProvider` instead of the feature-side `pushNotificationServiceProvider`. The tests still overrode the feature-side delegating provider, so the controller received an un-overridden service instance and never observed the test-injected `handleNotificationTap` calls.
**Fix:** Override `appPushNotificationServiceProvider` (application layer) instead of `pushNotificationServiceProvider` (feature delegating provider). All 4 tests now pass.

## Pre-existing Analyzer Info Warnings (Out of Scope)

Two `info` level warnings remain in shadow_books_provider_characterization_test.dart (line 57, 73):
- `no_leading_underscores_for_local_identifiers` for `_n` parameter

These don't cause `flutter analyze` to exit non-zero and are minor style issues. The `(_, _n)` pattern used for ignored callback parameters is a common Dart convention. Deferred to Phase 5 cleanup.
