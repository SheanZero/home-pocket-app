# Family Sync UI + Push Notification Implementation Plan

> Execution note: implement this plan on the `codex-dev` worktree/branch in batches, using TDD for all code changes.

## Goal

Implement the Family Sync UI flow for:
- invite code display
- invite code entry
- waiting for owner approval
- owner approval
- group management

and keep real-device push notifications in scope:
- Android via Firebase Cloud Messaging (FCM)
- iOS via native Apple Push Notification service (APNs)

## Repository Constraints

- Work only on `codex-dev`, never on `main`.
- Keep test paths aligned with the repo:
  - widget tests: `test/widget/...`
  - infrastructure tests: `test/infrastructure/...`
  - unit tests: `test/unit/...`
- Reuse existing Family Sync localization keys where possible; add only missing keys.
- Use current architecture as implemented in the repo:
  - presentation in `lib/features/family_sync/presentation/`
  - domain models and repository interfaces in `lib/features/family_sync/domain/`
  - use cases continue to follow the current repo placement until separately migrated
- Run `flutter gen-l10n` after ARB edits.
- Run `flutter pub run build_runner build --delete-conflicting-outputs` after `@riverpod` or generated-model changes.

## Current Baseline

- Existing screens:
  - `pairing_screen.dart`
  - `pair_management_screen.dart`
- Existing widgets:
  - `pair_code_display.dart`
  - `pair_code_input.dart`
- Existing push infrastructure:
  - `PushNotificationService` stub
  - `SyncTriggerService` with `member_confirmed` and `sync_available`
- Existing Android Firebase config:
  - `android/app/google-services.json`
- iOS native push still requires Runner target capability wiring and APNs real-device validation

## iOS Push Prerequisites

The implementation keeps iOS real-device push in scope, but the following are required for full end-to-end verification:

1. Apple Developer signing/capability setup must match the Runner target bundle id.
2. Runner target must enable:
   - Push Notifications
   - Background Modes / Remote notifications
3. Server must accept the raw APNs device token with `pushPlatform=apns`.
4. Real-device verification must be done on an iPhone signed with the same Apple Developer team/capabilities.

Code implementation proceeds without blocking on these assets, but final iOS push validation depends on them.

## UI Direction

- Use the existing IBM Plex Sans typography.
- Use current repo tokens from `AppColors`, even where they differ slightly from Pencil:
  - background: `AppColors.background` (`#F1F7FD`)
  - primary accent: `AppColors.survival` (`#5A9CC8`)
  - text: `AppColors.textPrimary`, `AppColors.textSecondary`
  - divider: `AppColors.divider`
- Preserve existing app navigation style unless a Family Sync screen requires a custom header.

## Revised Task Batches

### Batch 1: Foundation

1. Update Family Sync l10n.
   - Reuse existing keys such as `familySync`, `familySyncShowMyCode`, `familySyncEnterPartnerCode`, `familySyncPairCode`.
   - Add only missing keys needed for FS1-FS5, such as:
     - share
     - refresh
     - waiting approval
     - new join request
     - approval tip
     - group management title
     - members count label
     - last sync label
     - current user suffix
   - Verification:
     - `flutter gen-l10n`

2. Add `MemberAvatar` widget.
   - File: `lib/features/family_sync/presentation/widgets/member_avatar.dart`
   - Test: `test/widget/features/family_sync/presentation/widgets/member_avatar_test.dart`
   - Verification:
     - targeted widget test first failing, then passing

3. Add `GradientActionButton` widget.
   - File: `lib/features/family_sync/presentation/widgets/gradient_action_button.dart`
   - Test: `test/widget/features/family_sync/presentation/widgets/gradient_action_button_test.dart`
   - Verification:
     - targeted widget test first failing, then passing

### Batch 2: Remaining reusable UI

4. Add `InfoHintBox`
5. Add `OutlineActionButton`
6. Add `StatusBadge`
7. Add `DigitCodeDisplay`
8. Add `OtpDigitInput`
9. Add `SyncStatsCard`
10. Add `MemberListTile`

### Batch 3: Existing screen redesign

11. Redesign `PairCodeDisplay`
12. Redesign `PairCodeInput`
13. Update `PairingScreen`

### Batch 4: New Family Sync screens

14. Add `WaitingApprovalScreen`
   - Do not require `groupName` from `JoinGroupSuccess`.
   - Resolve display data from repository or API using `groupId`.
15. Add `MemberApprovalScreen`
16. Replace `PairManagementScreen` with `GroupManagementScreen`
17. Update navigation references
18. Remove deprecated screen/tests

### Batch 5: Push integration

19. Add Firebase messaging dependencies
20. Initialize Firebase in app startup for Android only
21. Implement platform-specific push messaging in `PushNotificationService`
22. Add local notification support for foreground messages
23. Extend `SyncTriggerService` for join-request/member-confirmed streams
24. Add presentation-side notification navigation provider
25. Wire notification navigation into the app shell/screens
26. Initialize push and local notifications on app start

### Batch 6: Verification

27. Run quality checks
28. Run build/codegen verification

## Execution Status

As of March 3, 2026, Batches 1-6 are implemented in the `codex-dev` worktree.

- Batch 1 completed:
  - localization updates
  - `MemberAvatar`
  - `GradientActionButton`
- Batch 2 completed:
  - additional Family Sync shared widgets
- Batch 3 completed:
  - redesigned pairing flow
  - waiting approval screen
- Batch 4 completed:
  - owner approval flow
  - group management flow
- Batch 5 completed:
  - Android FCM push registration and routing
  - iOS native APNs bridge and routing
  - foreground local notifications
  - notification-driven navigation intents
- Batch 6 completed:
  - `flutter analyze`
  - `flutter test`
  - `flutter build ios --debug --no-codesign`

## Remaining Manual Validation

- Android real-device push acceptance still requires end-to-end server-triggered FCM delivery validation.
- iOS real-device push acceptance still requires end-to-end APNs delivery validation on a signed iPhone.
- These manual validations are intentionally deferred until the final combined verification pass.

## Implementation Notes

- Follow strict TDD for each new widget or behavior change:
  - write test
  - verify failing
  - implement minimal code
  - verify passing
- Do not commit after every micro-task. Commit at stable batch boundaries after verification.
- For push navigation, convert `MainShellScreen` to a stateful consumer only if the listener genuinely belongs there.
- For stream merging in notification navigation, do not assume `rxdart`; add it explicitly only if needed. Prefer avoiding a new dependency if simple stream composition is sufficient.

## Batch 1 Deliverables

- ARB updates plus generated localization output
- `MemberAvatar`
- `GradientActionButton`
- Widget tests for both new widgets

## Batch 1 Verification

- `flutter gen-l10n`
- `flutter test test/widget/features/family_sync/presentation/widgets/member_avatar_test.dart`
- `flutter test test/widget/features/family_sync/presentation/widgets/gradient_action_button_test.dart`

After Batch 1, report changes and verification output, then wait for feedback before continuing.
