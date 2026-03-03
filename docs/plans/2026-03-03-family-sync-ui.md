# Family Sync UI + Push Notification Implementation Plan

> Execution note: implement this plan on the `codex-dev` worktree/branch in batches, using TDD for all code changes.

## Goal

Implement the Family Sync UI flow for:
- invite code display
- invite code entry
- waiting for owner approval
- owner approval
- group management

and keep Firebase-based push notifications, including iOS real-device support, in scope.

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
- Missing iOS Firebase config in repo:
  - `ios/Runner/GoogleService-Info.plist`

## iOS Push Prerequisites

The implementation keeps iOS real-device push in scope, but the following are required for full end-to-end verification:

1. `ios/Runner/GoogleService-Info.plist` must be present.
2. Runner target must enable:
   - Push Notifications
   - Background Modes / Remote notifications
3. APNs key/certificate must already be linked in Firebase Console.

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
20. Initialize Firebase in app startup
21. Implement Firebase Messaging in `PushNotificationService`
22. Add local notification support for foreground messages
23. Extend `SyncTriggerService` for join-request/member-confirmed streams
24. Add presentation-side notification navigation provider
25. Wire notification navigation into the app shell/screens
26. Initialize push and local notifications on app start

### Batch 6: Verification

27. Run quality checks
28. Run build/codegen verification

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
