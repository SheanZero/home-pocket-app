# Phase 04 Deferred Items

## Pre-existing Test Failures (Out of Scope)

**File:** `test/widget/features/family_sync/presentation/widgets/family_sync_notification_route_listener_test.dart`
**Status:** 4 pre-existing failures (confirmed present before Plan 04-05 changes)
**Failing tests:**
- routes join request notifications to the approval screen
- passes groupId from push intent to member approval builder
- passes groupId from push intent to group management builder
- pops to root and resets status on groupDissolved intent

**Root cause (not investigated):** These widget tests appear to have routing/widget-finding issues. The errors indicate `FamilySyncNotificationRouteListener` is not routing to the correct screen (0 widgets found with text "approval-screen").

**Discovered during:** Plan 04-05 Task 2 full test suite run
**Deferred to:** Phase 5 or dedicated investigation

## Pre-existing Analyzer Info Warnings (Out of Scope)

Two `info` level warnings remain in shadow_books_provider_characterization_test.dart (line 57, 73):
- `no_leading_underscores_for_local_identifiers` for `_n` parameter

These don't cause `flutter analyze` to exit non-zero and are minor style issues. The `(_, _n)` pattern used for ignored callback parameters is a common Dart convention. Deferred to Phase 5 cleanup.
