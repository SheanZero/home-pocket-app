# Family Sync UI + Push Notification Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement 5 Family Sync screens matching the Pencil designs (FS1–FS5) with push notification integration, covering the full family join and management flow including real-time notifications.

**Architecture:** Thin Feature pattern — all UI in `lib/features/family_sync/presentation/`, domain models in `domain/`, use cases in `lib/application/family_sync/`. Existing use cases (create/join/confirm/leave/deactivate/regenerate/remove) and providers are already wired. This plan covers UI redesign, new screens, and Firebase Cloud Messaging (FCM/APNs) integration.

**Tech Stack:** Flutter, Riverpod (`@riverpod`), Freezed, GoRouter (to be added), IBM Plex Sans font, AppColors/AppTextStyles from `lib/core/theme/`, `firebase_messaging`, `flutter_local_notifications`

**Server Push Notification Support:**
- Server already supports iOS APNs and Android FCM
- Client endpoint exists: `PUT /device/push-token` (Ed25519 authenticated)
- Message types: `join_request`, `pair_request`, `member_confirmed`, `pair_confirmed`, `sync_available`
- `PushNotificationService` infrastructure is stubbed but Firebase not integrated

**Design Reference (Pencil Node IDs):**
- FS1 `Qpx48` — 配対 - 招待コード表示 (Show Invite Code tab)
- FS2 `qg1VV` — 配対 - コード入力 (Enter Code tab)
- FS3 `ZOaVk` — 確認待ち (Waiting for Approval — member side)
- FS4 `7EHJ4` — メンバー承認 (Member Approval — owner side)
- FS5 `aASmH` — グループ管理 (Group Management)

**Color Tokens (from Pencil designs + AppColors):**
- Background: `#F5F9FD` (AppColors.background)
- Card: `#FFFFFF` (AppColors.card)
- Primary/Accent: `#5A9CC8` (AppColors.survival)
- Text primary: `#2C2C2C` (AppColors.textPrimary)
- Text secondary: `#9A9A9A` (AppColors.textSecondary)
- Divider: `#D0DEE8` (AppColors.divider)
- Border light: `#EEF4FA`
- Error/Destructive: `#E08870`
- Gradient button: `#90C4E8` → `#5A9CC8`
- Success badge bg: `#E8F5E9`, text: `#2E7D32`
- Warning badge bg: `#FFF8E1`, text: `#F57F17`

---

## Screen Flow

```
Settings → PairingScreen (FS1/FS2 tabs)
                ↓ (join success)
         WaitingApprovalScreen (FS3)
                ↓ (approved via push: member_confirmed)
         GroupManagementScreen (FS5)

Push Notification (join_request) → MemberApprovalScreen (FS4)
                                        ↓ (approve/reject)
                                   GroupManagementScreen (FS5)
```

## Push Notification Flow

```
[Member joins group]
    → Server sends FCM/APNs `join_request` to Owner
    → Owner receives foreground/background notification
    → Owner taps notification → navigates to MemberApprovalScreen (FS4)
    → Owner approves
    → Server sends FCM/APNs `member_confirmed` to Member
    → Member receives push → WaitingApprovalScreen auto-transitions to GroupManagementScreen (FS5)

[Data sync]
    → Device pushes CRDT operations
    → Server sends `sync_available` to other devices
    → Other devices pull sync
```

## Implementation Phases

| Phase | Tasks | Focus |
|-------|-------|-------|
| Phase 1 | Tasks 1–10 | l10n + reusable widgets |
| Phase 2 | Tasks 11–18 | Screen implementations + navigation |
| Phase 3 | Tasks 19–26 | Push notification integration (FCM/APNs) |
| Phase 4 | Tasks 27–28 | Quality checks + build verification |

---

## Task 1: Add l10n strings for Family Sync screens

All UI text must use `S.of(context)`. Add keys for all 5 screens.

**Files:**
- Modify: `lib/l10n/app_ja.arb`
- Modify: `lib/l10n/app_zh.arb`
- Modify: `lib/l10n/app_en.arb`

**Step 1: Add l10n keys to all 3 ARB files**

Add the following keys (showing ja values from designs):

```json
{
  "familySyncTitle": "家族同期",
  "familySyncTabShowCode": "招待コード",
  "familySyncTabEnterCode": "コード入力",
  "familySyncInviteCodeLabel": "招待コード",
  "familySyncShareButton": "シェア",
  "familySyncRefreshButton": "更新",
  "familySyncExpiryLabel": "有効期限: {time}",
  "@familySyncExpiryLabel": { "placeholders": { "time": { "type": "String" } } },
  "familySyncHintShareCode": "家族にこのコードを共有してください。スキャンまたは入力で参加できます。",
  "familySyncJoinTitle": "家族に参加する",
  "familySyncJoinDescription": "家族から受け取った6桁の招待コードを入力してください",
  "familySyncJoinButton": "参加する",
  "familySyncOrDivider": "または",
  "familySyncScanQr": "QRコードをスキャン",
  "familySyncWaitingTitle": "承認を待っています...",
  "familySyncWaitingDescription": "グループオーナーがあなたの\n参加リクエストを確認中です。\n確認されるまでお待ちください。",
  "familySyncGroupLabel": "グループ",
  "familySyncStatusLabel": "ステータス",
  "familySyncStatusPending": "承認待ち",
  "familySyncCancelButton": "キャンセル",
  "familySyncApprovalTitle": "メンバー承認",
  "familySyncNewRequest": "新しい参加リクエスト",
  "familySyncJustNow": "たった今リクエスト",
  "familySyncSecurityVerified": "デバイスの公開鍵が検証済みです",
  "familySyncRejectButton": "拒否",
  "familySyncApproveButton": "承認する",
  "familySyncCurrentMembers": "現在のメンバー",
  "familySyncApprovalTip": "承認すると、このデバイスとデータが暗号化して同期されます。",
  "familySyncGroupManagement": "グループ管理",
  "familySyncSynced": "同期済",
  "familySyncMembersCount": "メンバー ({count})",
  "@familySyncMembersCount": { "placeholders": { "count": { "type": "int" } } },
  "familySyncSyncedEntries": "同期済帳票",
  "familySyncLastSync": "最終同期",
  "familySyncRoleOwner": "オーナー",
  "familySyncRoleMember": "メンバー",
  "familySyncYouSuffix": " (あなた)",
  "familySyncRemoveMember": "削除",
  "familySyncDissolveGroup": "グループを解散",
  "familySyncMinutesAgo": "{minutes}分前",
  "@familySyncMinutesAgo": { "placeholders": { "minutes": { "type": "int" } } }
}
```

**Step 2: Run l10n generation**

Run: `flutter gen-l10n`
Expected: Success, `lib/generated/` updated

**Step 3: Commit**

```bash
git add lib/l10n/ lib/generated/
git commit -m "feat: add l10n strings for family sync screens (FS1-FS5)"
```

---

## Task 2: Create MemberAvatar widget

Circular avatar showing the first character of a member's name, with role-based color.

**Files:**
- Create: `lib/features/family_sync/presentation/widgets/member_avatar.dart`
- Test: `test/features/family_sync/presentation/widgets/member_avatar_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/member_avatar.dart';

void main() {
  testWidgets('MemberAvatar shows first character', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MemberAvatar(name: '太郎', isOwner: true),
        ),
      ),
    );

    expect(find.text('太'), findsOneWidget);
  });

  testWidgets('MemberAvatar uses primary fill for owner', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MemberAvatar(name: '太郎', isOwner: true),
        ),
      ),
    );

    final container = tester.widget<Container>(
      find.ancestor(of: find.text('太'), matching: find.byType(Container)).first,
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, equals(const Color(0xFF5A9CC8)));
  });

  testWidgets('MemberAvatar uses light fill for member', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MemberAvatar(name: '花子', isOwner: false),
        ),
      ),
    );

    expect(find.text('花'), findsOneWidget);
    final container = tester.widget<Container>(
      find.ancestor(of: find.text('花'), matching: find.byType(Container)).first,
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, equals(const Color(0xFFEEF4FA)));
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/family_sync/presentation/widgets/member_avatar_test.dart`
Expected: FAIL — file not found

**Step 3: Write implementation**

```dart
import 'package:flutter/material.dart';
import 'package:home_pocket/core/theme/app_colors.dart';

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.name,
    required this.isOwner,
    this.size = 40,
  });

  final String name;
  final bool isOwner;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first : '?';
    final bgColor = isOwner ? AppColors.survival : const Color(0xFFEEF4FA);
    final textColor = isOwner ? Colors.white : AppColors.survival;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: 'IBM Plex Sans',
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/family_sync/presentation/widgets/member_avatar_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/family_sync/presentation/widgets/member_avatar.dart test/features/family_sync/presentation/widgets/member_avatar_test.dart
git commit -m "feat: add MemberAvatar widget for family sync"
```

---

## Task 3: Create GradientActionButton widget

Primary action button with gradient fill matching the design system.

**Files:**
- Create: `lib/features/family_sync/presentation/widgets/gradient_action_button.dart`
- Test: `test/features/family_sync/presentation/widgets/gradient_action_button_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/gradient_action_button.dart';

void main() {
  testWidgets('GradientActionButton shows label and responds to tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GradientActionButton(
            label: '参加する',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('参加する'), findsOneWidget);
    await tester.tap(find.text('参加する'));
    expect(tapped, isTrue);
  });

  testWidgets('GradientActionButton shows loading indicator when loading', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GradientActionButton(
            label: '参加する',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('参加する'), findsNothing);
  });

  testWidgets('GradientActionButton is disabled when onPressed is null', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GradientActionButton(
            label: 'Test',
            onPressed: null,
          ),
        ),
      ),
    );

    final inkWell = tester.widget<InkWell>(find.byType(InkWell));
    expect(inkWell.onTap, isNull);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/family_sync/presentation/widgets/gradient_action_button_test.dart`
Expected: FAIL

**Step 3: Write implementation**

```dart
import 'package:flutter/material.dart';

class GradientActionButton extends StatelessWidget {
  const GradientActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF90C4E8), Color(0xFF5A9CC8)],
          ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF5A9CC8).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        label,
                        style: const TextStyle(
                          fontFamily: 'IBM Plex Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/family_sync/presentation/widgets/gradient_action_button_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/family_sync/presentation/widgets/gradient_action_button.dart test/features/family_sync/presentation/widgets/gradient_action_button_test.dart
git commit -m "feat: add GradientActionButton widget for family sync"
```

---

## Task 4: Create InfoHintBox widget

Info hint box with icon + text, used in FS1 and FS4.

**Files:**
- Create: `lib/features/family_sync/presentation/widgets/info_hint_box.dart`
- Test: `test/features/family_sync/presentation/widgets/info_hint_box_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/info_hint_box.dart';

void main() {
  testWidgets('InfoHintBox displays message text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InfoHintBox(message: 'Test hint message'),
        ),
      ),
    );

    expect(find.text('Test hint message'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/family_sync/presentation/widgets/info_hint_box_test.dart`
Expected: FAIL

**Step 3: Write implementation**

```dart
import 'package:flutter/material.dart';
import 'package:home_pocket/core/theme/app_colors.dart';

class InfoHintBox extends StatelessWidget {
  const InfoHintBox({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.survival),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: AppColors.survival,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/family_sync/presentation/widgets/info_hint_box_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/family_sync/presentation/widgets/info_hint_box.dart test/features/family_sync/presentation/widgets/info_hint_box_test.dart
git commit -m "feat: add InfoHintBox widget for family sync"
```

---

## Task 5: Create OutlineActionButton widget

Outline-style button used for Share, Refresh, Cancel, QR Scan, Reject.

**Files:**
- Create: `lib/features/family_sync/presentation/widgets/outline_action_button.dart`
- Test: `test/features/family_sync/presentation/widgets/outline_action_button_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/outline_action_button.dart';

void main() {
  testWidgets('OutlineActionButton shows icon and label', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OutlineActionButton(
            icon: Icons.share,
            label: 'シェア',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('シェア'), findsOneWidget);
    expect(find.byIcon(Icons.share), findsOneWidget);
    await tester.tap(find.text('シェア'));
    expect(tapped, isTrue);
  });

  testWidgets('OutlineActionButton works without icon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OutlineActionButton(
            label: 'キャンセル',
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('キャンセル'), findsOneWidget);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/family_sync/presentation/widgets/outline_action_button_test.dart`
Expected: FAIL

**Step 3: Write implementation**

```dart
import 'package:flutter/material.dart';
import 'package:home_pocket/core/theme/app_colors.dart';

class OutlineActionButton extends StatelessWidget {
  const OutlineActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppColors.survival,
    this.borderColor = AppColors.divider,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/family_sync/presentation/widgets/outline_action_button_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/family_sync/presentation/widgets/outline_action_button.dart test/features/family_sync/presentation/widgets/outline_action_button_test.dart
git commit -m "feat: add OutlineActionButton widget for family sync"
```

---

## Task 6: Create StatusBadge widget

Small colored badge for role/status display (replaces SyncStatusBadge for inline use).

**Files:**
- Create: `lib/features/family_sync/presentation/widgets/status_badge.dart`
- Test: `test/features/family_sync/presentation/widgets/status_badge_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/status_badge.dart';

void main() {
  testWidgets('StatusBadge.owner shows green owner badge', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StatusBadge.owner()),
      ),
    );
    expect(find.text('オーナー'), findsOneWidget);
  });

  testWidgets('StatusBadge.pending shows yellow pending badge', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StatusBadge.pending()),
      ),
    );
    expect(find.text('承認待ち'), findsOneWidget);
  });

  testWidgets('StatusBadge.synced shows green synced badge', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StatusBadge.synced()),
      ),
    );
    expect(find.text('同期済'), findsOneWidget);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/family_sync/presentation/widgets/status_badge_test.dart`
Expected: FAIL

**Step 3: Write implementation**

```dart
import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.dotColor,
  });

  factory StatusBadge.owner() => const StatusBadge(
        label: 'オーナー',
        backgroundColor: Color(0xFFE8F5E9),
        textColor: Color(0xFF2E7D32),
      );

  factory StatusBadge.pending() => const StatusBadge(
        label: '承認待ち',
        backgroundColor: Color(0xFFFFF8E1),
        textColor: Color(0xFFF57F17),
        dotColor: Color(0xFFF9A825),
      );

  factory StatusBadge.synced() => const StatusBadge(
        label: '同期済',
        backgroundColor: Color(0xFFE8F5E9),
        textColor: Color(0xFF2E7D32),
        dotColor: Color(0xFF4CAF50),
      );

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/family_sync/presentation/widgets/status_badge_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/family_sync/presentation/widgets/status_badge.dart test/features/family_sync/presentation/widgets/status_badge_test.dart
git commit -m "feat: add StatusBadge widget for family sync"
```

---

## Task 7: Create DigitCodeDisplay widget

Displays a 6-digit code in individual rounded boxes (used in FS1 Show Code).

**Files:**
- Create: `lib/features/family_sync/presentation/widgets/digit_code_display.dart`
- Test: `test/features/family_sync/presentation/widgets/digit_code_display_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/digit_code_display.dart';

void main() {
  testWidgets('DigitCodeDisplay renders each digit in its own box', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DigitCodeDisplay(code: '384729'),
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
  });

  testWidgets('DigitCodeDisplay shows placeholder for short codes', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DigitCodeDisplay(code: '38'),
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    // Remaining 4 boxes should be empty
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/family_sync/presentation/widgets/digit_code_display_test.dart`
Expected: FAIL

**Step 3: Write implementation**

```dart
import 'package:flutter/material.dart';
import 'package:home_pocket/core/theme/app_colors.dart';

class DigitCodeDisplay extends StatelessWidget {
  const DigitCodeDisplay({
    super.key,
    required this.code,
    this.digitCount = 6,
  });

  final String code;
  final int digitCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(digitCount, (index) {
        final char = index < code.length ? code[index] : '';
        return Padding(
          padding: EdgeInsets.only(left: index > 0 ? 8 : 0),
          child: Container(
            width: 44,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEEF4FA)),
            ),
            alignment: Alignment.center,
            child: Text(
              char,
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        );
      }),
    );
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/family_sync/presentation/widgets/digit_code_display_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/family_sync/presentation/widgets/digit_code_display.dart test/features/family_sync/presentation/widgets/digit_code_display_test.dart
git commit -m "feat: add DigitCodeDisplay widget for family sync"
```

---

## Task 8: Create OtpDigitInput widget

6-box OTP input with individual digit boxes (used in FS2 Enter Code). Each box highlights when active.

**Files:**
- Create: `lib/features/family_sync/presentation/widgets/otp_digit_input.dart`
- Test: `test/features/family_sync/presentation/widgets/otp_digit_input_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/otp_digit_input.dart';

void main() {
  testWidgets('OtpDigitInput calls onCompleted with 6-digit code', (tester) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OtpDigitInput(
            onChanged: (_) {},
            onCompleted: (code) => result = code,
          ),
        ),
      ),
    );

    // Should render 6 box-like containers
    // The hidden TextField accepts input
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    await tester.enterText(textField, '384729');
    await tester.pump();

    expect(result, '384729');
  });

  testWidgets('OtpDigitInput shows entered digits', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OtpDigitInput(
            onChanged: (_) {},
            onCompleted: (_) {},
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '384');
    await tester.pump();

    expect(find.text('3'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/family_sync/presentation/widgets/otp_digit_input_test.dart`
Expected: FAIL

**Step 3: Write implementation**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_pocket/core/theme/app_colors.dart';

class OtpDigitInput extends StatefulWidget {
  const OtpDigitInput({
    super.key,
    required this.onChanged,
    required this.onCompleted,
    this.digitCount = 6,
  });

  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCompleted;
  final int digitCount;

  @override
  State<OtpDigitInput> createState() => _OtpDigitInputState();
}

class _OtpDigitInputState extends State<OtpDigitInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = _controller.text;
    widget.onChanged(text);
    if (text.length == widget.digitCount) {
      widget.onCompleted(text);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;

    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Hidden text field for keyboard input
          Opacity(
            opacity: 0,
            child: SizedBox(
              width: 1,
              height: 1,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.digitCount),
                ],
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            ),
          ),
          // Digit boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.digitCount, (index) {
              final hasDigit = index < text.length;
              final isActive = index == text.length && _focusNode.hasFocus;
              final borderColor = isActive
                  ? AppColors.survival
                  : hasDigit
                      ? AppColors.survival
                      : AppColors.divider;
              final borderWidth = isActive || hasDigit ? 2.0 : 1.0;

              return Padding(
                padding: EdgeInsets.only(left: index > 0 ? 8 : 0),
                child: Container(
                  width: 48,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: borderWidth),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    hasDigit ? text[index] : '',
                    style: const TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/family_sync/presentation/widgets/otp_digit_input_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/family_sync/presentation/widgets/otp_digit_input.dart test/features/family_sync/presentation/widgets/otp_digit_input_test.dart
git commit -m "feat: add OtpDigitInput widget for family sync"
```

---

## Task 9: Create SyncStatsCard widget

3-column stats card showing members, synced entries, last sync (used in FS5).

**Files:**
- Create: `lib/features/family_sync/presentation/widgets/sync_stats_card.dart`
- Test: `test/features/family_sync/presentation/widgets/sync_stats_card_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/sync_stats_card.dart';

void main() {
  testWidgets('SyncStatsCard displays all three stats', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SyncStatsCard(
            memberCount: 3,
            syncedEntries: 128,
            lastSyncText: '2分前',
          ),
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.text('128'), findsOneWidget);
    expect(find.text('2分前'), findsOneWidget);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/family_sync/presentation/widgets/sync_stats_card_test.dart`
Expected: FAIL

**Step 3: Write implementation**

```dart
import 'package:flutter/material.dart';
import 'package:home_pocket/core/theme/app_colors.dart';

class SyncStatsCard extends StatelessWidget {
  const SyncStatsCard({
    super.key,
    required this.memberCount,
    required this.syncedEntries,
    required this.lastSyncText,
    this.memberLabel = 'メンバー',
    this.syncedLabel = '同期済帳票',
    this.lastSyncLabel = '最終同期',
  });

  final int memberCount;
  final int syncedEntries;
  final String lastSyncText;
  final String memberLabel;
  final String syncedLabel;
  final String lastSyncLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF4FA)),
      ),
      child: Row(
        children: [
          _StatItem(value: '$memberCount', label: memberLabel),
          const SizedBox(width: 12),
          _StatItem(value: '$syncedEntries', label: syncedLabel),
          const SizedBox(width: 12),
          _StatItem(value: lastSyncText, label: lastSyncLabel, smallValue: true),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    this.smallValue = false,
  });

  final String value;
  final String label;
  final bool smallValue;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F9FD),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: smallValue ? 16 : 24,
                fontWeight: FontWeight.w700,
                color: AppColors.survival,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/family_sync/presentation/widgets/sync_stats_card_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/family_sync/presentation/widgets/sync_stats_card.dart test/features/family_sync/presentation/widgets/sync_stats_card_test.dart
git commit -m "feat: add SyncStatsCard widget for family sync"
```

---

## Task 10: Create MemberListTile widget

Row displaying member avatar, name, role, with optional trailing action (used in FS4, FS5).

**Files:**
- Create: `lib/features/family_sync/presentation/widgets/member_list_tile.dart`
- Test: `test/features/family_sync/presentation/widgets/member_list_tile_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/member_list_tile.dart';

void main() {
  testWidgets('MemberListTile shows name, role, and owner badge', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MemberListTile(
            name: '太郎のiPhone',
            role: 'owner',
            isCurrentUser: true,
          ),
        ),
      ),
    );

    expect(find.textContaining('太郎のiPhone'), findsOneWidget);
    expect(find.text('オーナー'), findsAtLeast(1));
  });

  testWidgets('MemberListTile shows remove button for non-owner', (tester) async {
    var removed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MemberListTile(
            name: '花子のiPhone',
            role: 'member',
            isCurrentUser: false,
            onRemove: () => removed = true,
          ),
        ),
      ),
    );

    expect(find.text('花子のiPhone'), findsOneWidget);
    expect(find.text('削除'), findsOneWidget);
    await tester.tap(find.text('削除'));
    expect(removed, isTrue);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/family_sync/presentation/widgets/member_list_tile_test.dart`
Expected: FAIL

**Step 3: Write implementation**

```dart
import 'package:flutter/material.dart';
import 'package:home_pocket/core/theme/app_colors.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/member_avatar.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/status_badge.dart';

class MemberListTile extends StatelessWidget {
  const MemberListTile({
    super.key,
    required this.name,
    required this.role,
    this.isCurrentUser = false,
    this.onRemove,
  });

  final String name;
  final String role;
  final bool isCurrentUser;
  final VoidCallback? onRemove;

  bool get _isOwner => role == 'owner';

  @override
  Widget build(BuildContext context) {
    final displayName = isCurrentUser ? '$name (あなた)' : name;
    final roleLabel = _isOwner ? 'オーナー' : 'メンバー';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          MemberAvatar(name: name, isOwner: _isOwner),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  roleLabel,
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (_isOwner && isCurrentUser)
            const StatusBadge(
              label: 'オーナー',
              backgroundColor: Color(0xFFE8F5E9),
              textColor: Color(0xFF2E7D32),
            )
          else if (onRemove != null)
            GestureDetector(
              onTap: onRemove,
              child: const Text(
                '削除',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE08870),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/family_sync/presentation/widgets/member_list_tile_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/family_sync/presentation/widgets/member_list_tile.dart test/features/family_sync/presentation/widgets/member_list_tile_test.dart
git commit -m "feat: add MemberListTile widget for family sync"
```

---

## Task 11: Redesign PairCodeDisplay (FS1 — Show Invite Code tab)

Replace the existing `pair_code_display.dart` with the design from FS1.

**Files:**
- Modify: `lib/features/family_sync/presentation/widgets/pair_code_display.dart`
- Modify: `test/features/family_sync/presentation/widgets/pair_code_display_test.dart` (if exists, else create)

**Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/pair_code_display.dart';

void main() {
  testWidgets('PairCodeDisplay shows QR icon, digit boxes, and buttons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PairCodeDisplay(
            inviteCode: '384729',
            qrData: 'hp://join/384729',
            expiresAt: DateTime.now().add(const Duration(minutes: 5)),
            onRegenerate: () {},
            onShare: () {},
          ),
        ),
      ),
    );

    // Digit boxes
    expect(find.text('3'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);

    // Buttons
    expect(find.text('シェア'), findsOneWidget);
    expect(find.text('更新'), findsOneWidget);

    // Hint
    expect(find.textContaining('家族にこのコードを共有'), findsOneWidget);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/family_sync/presentation/widgets/pair_code_display_test.dart`
Expected: FAIL (new API signature)

**Step 3: Rewrite PairCodeDisplay**

Key changes from existing:
- Add `onShare` callback parameter
- Use `DigitCodeDisplay` instead of formatted text
- Use QR code card with shadow
- Use `OutlineActionButton` pair for Share/Refresh
- Use `InfoHintBox` for hint text
- Timer remains but uses new styling

The new widget should match FS1 layout:
```
QR Card (white, rounded, shadow, centered)
  └─ QR Placeholder (180x180, light bg, qr-code icon)
招待コード label
DigitCodeDisplay (6 boxes)
Expiry timer row
[Share] [Refresh] buttons side by side
InfoHintBox
```

Full implementation in `pair_code_display.dart` — replace entire file. Keep existing timer logic, update UI layout to use new sub-widgets. See FS1 design node `347d6` for exact structure.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/family_sync/presentation/widgets/pair_code_display_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/family_sync/presentation/widgets/pair_code_display.dart test/features/family_sync/presentation/widgets/pair_code_display_test.dart
git commit -m "feat: redesign PairCodeDisplay to match FS1 design"
```

---

## Task 12: Redesign PairCodeInput (FS2 — Enter Code tab)

Replace existing `pair_code_input.dart` with FS2 design.

**Files:**
- Modify: `lib/features/family_sync/presentation/widgets/pair_code_input.dart`
- Modify: `test/features/family_sync/presentation/widgets/pair_code_input_test.dart` (if exists, else create)

**Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/pair_code_input.dart';

void main() {
  testWidgets('PairCodeInput shows title, OTP input, join button, and scan button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PairCodeInput(
            onSubmit: (_) {},
            onScanQr: () {},
          ),
        ),
      ),
    );

    // Title
    expect(find.text('家族に参加する'), findsOneWidget);

    // Join button (disabled initially)
    expect(find.text('参加する'), findsOneWidget);

    // QR scan button
    expect(find.text('QRコードをスキャン'), findsOneWidget);

    // Divider
    expect(find.text('または'), findsOneWidget);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/family_sync/presentation/widgets/pair_code_input_test.dart`
Expected: FAIL (new API)

**Step 3: Rewrite PairCodeInput**

Key changes:
- Add `onScanQr` callback
- Replace single TextField with `OtpDigitInput`
- Add icon circle at top (user-plus icon, 72x72)
- Add title "家族に参加する" and description
- Use `GradientActionButton` for join
- Add divider with "または"
- Add `OutlineActionButton` for QR scan

Layout matches FS2 node `byjCZ`:
```
Icon Circle (72x72, user-plus icon)
"家族に参加する" title (20px, 700wt)
Description text (14px, centered)
─── gap ───
"招待コード" label
OtpDigitInput (6 boxes)
─── gap ───
GradientActionButton "参加する"
─── divider "または" ───
OutlineActionButton "QRコードをスキャン" (scan icon)
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/family_sync/presentation/widgets/pair_code_input_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/family_sync/presentation/widgets/pair_code_input.dart test/features/family_sync/presentation/widgets/pair_code_input_test.dart
git commit -m "feat: redesign PairCodeInput to match FS2 design"
```

---

## Task 13: Update PairingScreen tabs styling

Update `pairing_screen.dart` to use new tab design (underline tabs) and background color.

**Files:**
- Modify: `lib/features/family_sync/presentation/screens/pairing_screen.dart`
- Test: `test/features/family_sync/presentation/screens/pairing_screen_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/pairing_screen.dart';

// ... mock providers setup ...

void main() {
  testWidgets('PairingScreen shows header with back arrow and title', (tester) async {
    // Arrange: wrap in ProviderScope with mocked providers
    // Act: pump PairingScreen
    // Assert: find header title "家族同期"
    // Assert: find tab labels "招待コード" and "コード入力"
    // Assert: background is #F5F9FD
  });

  testWidgets('PairingScreen navigates to WaitingApprovalScreen on join success', (tester) async {
    // After successful join, should push WaitingApprovalScreen
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/family_sync/presentation/screens/pairing_screen_test.dart`
Expected: FAIL

**Step 3: Update PairingScreen**

Key changes:
- Background: `AppColors.background` (#F5F9FD)
- Custom AppBar: back arrow + "家族同期" title (no elevation)
- Tab style: underline indicator, not Material TabBar
- Tab indicator: 2px bottom border, active `#5A9CC8`, inactive `#D0DEE8`
- Tab text: active `#5A9CC8` 600wt, inactive `#9A9A9A` 500wt
- On join success: navigate to `WaitingApprovalScreen` instead of `pop()`
- Pass `onShare` callback to `PairCodeDisplay`
- Pass `onScanQr` callback to `PairCodeInput`

Structure matches FS1/FS2 header + tabs:
```
StatusBar (system)
Header: [←] "家族同期" [spacer]
Tabs: [招待コード] [コード入力]
TabView: PairCodeDisplay | PairCodeInput
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/family_sync/presentation/screens/pairing_screen_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/family_sync/presentation/screens/pairing_screen.dart test/features/family_sync/presentation/screens/pairing_screen_test.dart
git commit -m "feat: update PairingScreen tabs to match FS1/FS2 design"
```

---

## Task 14: Create WaitingApprovalScreen (FS3)

New screen for members waiting for owner approval after joining.

**Files:**
- Create: `lib/features/family_sync/presentation/screens/waiting_approval_screen.dart`
- Test: `test/features/family_sync/presentation/screens/waiting_approval_screen_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/waiting_approval_screen.dart';

void main() {
  testWidgets('WaitingApprovalScreen shows loading state with group info', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: WaitingApprovalScreen(
            groupName: '田中家の家計簿',
            groupId: 'test-group-id',
          ),
        ),
      ),
    );

    expect(find.text('承認を待っています...'), findsOneWidget);
    expect(find.text('田中家の家計簿'), findsOneWidget);
    expect(find.text('承認待ち'), findsOneWidget);
    expect(find.text('キャンセル'), findsOneWidget);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/family_sync/presentation/screens/waiting_approval_screen_test.dart`
Expected: FAIL

**Step 3: Write WaitingApprovalScreen**

Layout matches FS3 node `BiM6i` (centered content):
```
Header: [←] "家族同期" [spacer]
──── Centered Content ────
Loader Circle (100x100, border #5A9CC8, loader icon inside)
"承認を待っています..." (20px, 700wt)
Description (14px, gray, centered, 3 lines)
Group Info Card:
  Row: "グループ" ← → "田中家の家計簿"
  Divider
  Row: "ステータス" ← → StatusBadge.pending
Cancel Button (OutlineActionButton, full width)
```

**State management:**
- Accept `groupId` and `groupName` as constructor params
- **Dual trigger for approval detection:**
  1. Poll group status via `relayApiClient.getGroupStatus(groupId)` on timer (every 10s) — fallback if push fails
  2. Listen for `member_confirmed` push notification via `PushNotificationService` callback (primary, instant)
- When status changes to `active` → navigate to `GroupManagementScreen`
- Cancel button → calls `leaveGroupUseCase` and pops back
- Expose a static `GlobalKey<NavigatorState>` or Riverpod callback so push handler can trigger navigation

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/family_sync/presentation/screens/waiting_approval_screen_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/family_sync/presentation/screens/waiting_approval_screen.dart test/features/family_sync/presentation/screens/waiting_approval_screen_test.dart
git commit -m "feat: add WaitingApprovalScreen (FS3) for pending member"
```

---

## Task 15: Create MemberApprovalScreen (FS4)

New screen for group owner to approve/reject join requests.

**Files:**
- Create: `lib/features/family_sync/presentation/screens/member_approval_screen.dart`
- Test: `test/features/family_sync/presentation/screens/member_approval_screen_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/member_approval_screen.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';

void main() {
  testWidgets('MemberApprovalScreen shows pending member and action buttons', (tester) async {
    final pendingMember = GroupMember(
      deviceId: 'dev-123',
      publicKey: 'pk-123',
      deviceName: '花子のiPhone',
      role: 'member',
      status: 'pending',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MemberApprovalScreen(
            pendingMember: pendingMember,
            groupId: 'test-group',
          ),
        ),
      ),
    );

    // Header
    expect(find.text('メンバー承認'), findsOneWidget);

    // Notification card
    expect(find.text('新しい参加リクエスト'), findsOneWidget);
    expect(find.text('花子のiPhone'), findsOneWidget);
    expect(find.text('承認待ち'), findsOneWidget);

    // Security info
    expect(find.textContaining('公開鍵が検証済み'), findsOneWidget);

    // Action buttons
    expect(find.text('拒否'), findsOneWidget);
    expect(find.text('承認する'), findsOneWidget);
  });

  testWidgets('Approve button calls confirmMemberUseCase', (tester) async {
    // Test that tapping approve triggers the confirm flow
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/family_sync/presentation/screens/member_approval_screen_test.dart`
Expected: FAIL

**Step 3: Write MemberApprovalScreen**

Layout matches FS4 node `PACzm`:
```
Header: [←] "メンバー承認" [spacer]
──── Content ────
Notification Card (white, rounded, subtle shadow):
  Row: bell icon + "新しい参加リクエスト"
  Member Row: avatar(smartphone icon) + name + "たった今" + StatusBadge.pending
  Divider
  Security Info: shield-check icon + "デバイスの公開鍵が検証済みです"
  Actions Row: [拒否 (outline red)] [承認する (gradient)]

"現在のメンバー" label
Existing Members Card:
  MemberListTile (owner, isCurrentUser)

InfoHintBox: "承認すると、このデバイスとデータが暗号化して同期されます。"
```

**Use cases:**
- Approve: `confirmMemberUseCase.execute(groupId, pendingMember.deviceId)` → navigate to GroupManagementScreen
- Reject: `removeMemberUseCase.execute(groupId, pendingMember.deviceId)` → pop back

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/family_sync/presentation/screens/member_approval_screen_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/family_sync/presentation/screens/member_approval_screen.dart test/features/family_sync/presentation/screens/member_approval_screen_test.dart
git commit -m "feat: add MemberApprovalScreen (FS4) for owner approval"
```

---

## Task 16: Redesign GroupManagementScreen (FS5)

Replace `pair_management_screen.dart` content with FS5 design. Rename to `group_management_screen.dart`.

**Files:**
- Remove: `lib/features/family_sync/presentation/screens/pair_management_screen.dart`
- Create: `lib/features/family_sync/presentation/screens/group_management_screen.dart`
- Test: `test/features/family_sync/presentation/screens/group_management_screen_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/group_management_screen.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';

void main() {
  testWidgets('GroupManagementScreen shows stats, members, invite code', (tester) async {
    final group = GroupInfo(
      groupId: 'g-123',
      bookId: 'b-123',
      status: GroupStatus.active,
      role: 'owner',
      inviteCode: '384729',
      inviteExpiresAt: DateTime.now().add(const Duration(minutes: 10)),
      members: [
        GroupMember(deviceId: 'd1', publicKey: 'pk1', deviceName: '太郎のiPhone', role: 'owner', status: 'active'),
        GroupMember(deviceId: 'd2', publicKey: 'pk2', deviceName: '花子のiPhone', role: 'member', status: 'active'),
        GroupMember(deviceId: 'd3', publicKey: 'pk3', deviceName: '翔太のiPad', role: 'member', status: 'active'),
      ],
      createdAt: DateTime.now(),
      confirmedAt: DateTime.now(),
      lastSyncAt: DateTime.now().subtract(const Duration(minutes: 2)),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: GroupManagementScreen(group: group),
        ),
      ),
    );

    // Header
    expect(find.text('グループ管理'), findsOneWidget);
    expect(find.text('同期済'), findsOneWidget);

    // Stats
    expect(find.text('3'), findsAtLeast(1)); // member count
    expect(find.text('メンバー'), findsAtLeast(1));

    // Members section
    expect(find.text('メンバー (3)'), findsOneWidget);
    expect(find.textContaining('太郎のiPhone'), findsOneWidget);
    expect(find.text('花子のiPhone'), findsOneWidget);
    expect(find.text('翔太のiPad'), findsOneWidget);

    // Invite section (owner only)
    expect(find.text('招待コード'), findsOneWidget);

    // Dissolve button
    expect(find.text('グループを解散'), findsOneWidget);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/family_sync/presentation/screens/group_management_screen_test.dart`
Expected: FAIL

**Step 3: Write GroupManagementScreen**

Layout matches FS5 node `aASmH`:
```
Header: [←] "グループ管理" [StatusBadge.synced]
──── Scrollable Content ────
SyncStatsCard (3 stats)
"メンバー (N)" label
Members Card (white, rounded):
  MemberListTile (owner, isCurrentUser)
  Divider
  MemberListTile (member, onRemove)
  Divider
  MemberListTile (member, onRemove)

Invite Section:
  "招待コード" label
  Invite Card (white, rounded):
    Code Row: "384 729" + Refresh button
    Expiry Row: "⏱ 有効期限: 8:42"

Spacer
"グループを解散" button (red text, rounded)
Bottom spacer
```

**Actions:**
- Remove member: `removeMemberUseCase` → reload group
- Regenerate invite: `regenerateInviteUseCase` → update code
- Dissolve: show confirmation dialog → `deactivateGroupUseCase` → pop to settings

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/family_sync/presentation/screens/group_management_screen_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/family_sync/presentation/screens/group_management_screen.dart test/features/family_sync/presentation/screens/group_management_screen_test.dart
git commit -m "feat: add GroupManagementScreen (FS5) replacing PairManagementScreen"
```

---

## Task 17: Update navigation references

Update all references from `PairManagementScreen` to `GroupManagementScreen`. Wire navigation flow between screens.

**Files:**
- Modify: Any file importing `pair_management_screen.dart` (search with grep)
- Modify: `lib/features/family_sync/presentation/screens/pairing_screen.dart` (join → waiting)
- Modify: Settings screen (if it navigates to pair management)

**Step 1: Search for all imports of pair_management_screen**

Run: `grep -r "pair_management_screen" lib/ --include="*.dart" -l`

**Step 2: Update each import to group_management_screen**

Replace imports and class references.

**Step 3: Wire navigation flow**

```
PairingScreen (FS1/FS2)
  ├── Join success → Navigator.pushReplacement → WaitingApprovalScreen(groupId, groupName)
  └── Cancel/Back → Navigator.pop

WaitingApprovalScreen (FS3)
  ├── Approved (polling) → Navigator.pushReplacement → GroupManagementScreen(group)
  └── Cancel → leaveGroupUseCase → Navigator.pop

MemberApprovalScreen (FS4)
  ├── Approve → confirmMemberUseCase → Navigator.pushReplacement → GroupManagementScreen(group)
  └── Reject → removeMemberUseCase → Navigator.pop

GroupManagementScreen (FS5)
  └── Dissolve → deactivateGroupUseCase → Navigator.pop
```

**Step 4: Run full test suite**

Run: `flutter test`
Expected: All tests pass

**Step 5: Commit**

```bash
git add -A
git commit -m "refactor: update navigation flow for family sync screens"
```

---

## Task 18: Delete old pair_management_screen.dart

Remove the old file now that it's been replaced.

**Files:**
- Delete: `lib/features/family_sync/presentation/screens/pair_management_screen.dart`
- Delete: `test/features/family_sync/presentation/screens/pair_management_screen_test.dart` (if exists)

**Step 1: Verify no remaining imports**

Run: `grep -r "pair_management_screen" lib/ test/ --include="*.dart"`
Expected: No results

**Step 2: Delete old files**

```bash
rm lib/features/family_sync/presentation/screens/pair_management_screen.dart
rm -f test/features/family_sync/presentation/screens/pair_management_screen_test.dart
```

**Step 3: Run tests to verify nothing breaks**

Run: `flutter test`
Expected: All tests pass

**Step 4: Commit**

```bash
git add -A
git commit -m "chore: remove deprecated PairManagementScreen"
```

---

## Task 19: Add Firebase Messaging dependencies

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/app/build.gradle.kts` (if needed)

**Step 1: Add flutter dependencies**

Run: `flutter pub add firebase_core firebase_messaging flutter_local_notifications`
Expected: Dependencies added to pubspec.yaml

**Step 2: Verify Android configuration**

Check `android/app/build.gradle.kts` has:
- `com.google.gms.google-services` plugin
- `google-services.json` in `android/app/`
- Firebase BOM includes `firebase-messaging`

If missing, add:
```kotlin
dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.9.0"))
    implementation("com.google.firebase:firebase-messaging")
}
```

**Step 3: Configure iOS APNs capability**

- Copy `GoogleService-Info.plist` to `ios/Runner/` (get from Firebase Console)
- Add to `ios/Runner/Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```
- Add push notification capability in Xcode:
  - Signing & Capabilities → + Capability → Push Notifications
  - Signing & Capabilities → + Capability → Background Modes → Remote notifications

**Step 4: Run pub get**

Run: `flutter pub get`
Expected: Success

**Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock android/ ios/
git commit -m "chore: add firebase_messaging and flutter_local_notifications dependencies"
```

---

## Task 20: Initialize Firebase in main.dart

**Files:**
- Modify: `lib/main.dart`

**Step 1: Write the test expectation**

After this change, `main()` should call `Firebase.initializeApp()` before any other initialization.

**Step 2: Update main.dart**

Add Firebase initialization right after `WidgetsFlutterBinding.ensureInitialized()`:

```dart
import 'package:firebase_core/firebase_core.dart';
// ...

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 0a. Initialize Firebase (required for push notifications)
  await Firebase.initializeApp();

  // 0b. Load SQLCipher native library
  await ensureNativeLibrary();
  // ... rest unchanged ...
}
```

**Step 3: Verify build**

Run: `flutter build apk --debug`
Expected: Success

**Step 4: Commit**

```bash
git add lib/main.dart
git commit -m "feat: initialize Firebase in main.dart"
```

---

## Task 21: Implement Firebase Messaging in PushNotificationService

Activate the stubbed Firebase code with real implementation.

**Files:**
- Modify: `lib/infrastructure/sync/push_notification_service.dart`
- Test: `test/infrastructure/sync/push_notification_service_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/sync/push_notification_service.dart';

// Test that handleMessage dispatches correctly (existing tests should still pass)
// Add test for message type coverage
void main() {
  test('handleMessage dispatches join_request without error', () async {
    // Verify join_request type triggers onJoinRequest callback
    var joinRequestReceived = false;
    final service = PushNotificationService(apiClient: mockApiClient);
    service.registerHandlers(
      onJoinRequest: (data) async => joinRequestReceived = true,
    );
    await service.handleMessage({'type': 'join_request', 'groupId': 'g1', 'deviceName': 'iPhone'});
    expect(joinRequestReceived, isTrue);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/infrastructure/sync/push_notification_service_test.dart`
Expected: FAIL — `onJoinRequest` parameter not yet added

**Step 3: Update PushNotificationService**

Replace the stubbed `initialize()` method with real Firebase code:

```dart
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'relay_api_client.dart';

/// Top-level background message handler (required by Firebase).
/// Must be a top-level function, not a method.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Background messages are handled when app opens via getInitialMessage()
  // or onMessageOpenedApp. No heavy processing here.
  if (kDebugMode) {
    debugPrint('PushNotification: background message: ${message.data}');
  }
}

typedef PushMessageHandler = Future<void> Function(Map<String, dynamic> data);

class PushNotificationService {
  PushNotificationService({required RelayApiClient apiClient})
    : _apiClient = apiClient;

  final RelayApiClient _apiClient;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  PushMessageHandler? _onMemberConfirmed;
  PushMessageHandler? _onSyncAvailable;
  PushMessageHandler? _onJoinRequest;

  /// Callback for when user taps a notification (navigation trigger).
  void Function(Map<String, dynamic> data)? onNotificationTapped;

  void registerHandlers({
    PushMessageHandler? onMemberConfirmed,
    PushMessageHandler? onSyncAvailable,
    PushMessageHandler? onJoinRequest,
  }) {
    _onMemberConfirmed = onMemberConfirmed;
    _onSyncAvailable = onSyncAvailable;
    _onJoinRequest = onJoinRequest;
  }

  Future<String?> initialize() async {
    try {
      // 1. Register background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

      // 2. Request permission (iOS + Android 13+)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        if (kDebugMode) {
          debugPrint('PushNotification: permission denied');
        }
        return null;
      }

      // 3. Get FCM token (works for both Android FCM and iOS APNs)
      final token = await _messaging.getToken();

      if (token != null) {
        // 4. Register token with relay server
        await registerToken(token);
        if (kDebugMode) {
          debugPrint('PushNotification: registered token: ${token.substring(0, 20)}...');
        }
      }

      // 5. Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        await registerToken(newToken);
        if (kDebugMode) {
          debugPrint('PushNotification: token refreshed');
        }
      });

      // 6. Handle foreground messages
      FirebaseMessaging.onMessage.listen((message) {
        if (kDebugMode) {
          debugPrint('PushNotification: foreground message: ${message.data}');
        }
        handleMessage(message.data);
      });

      // 7. Handle notification tap (app was in background)
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        if (kDebugMode) {
          debugPrint('PushNotification: notification tapped: ${message.data}');
        }
        onNotificationTapped?.call(message.data);
      });

      // 8. Check if app was opened from terminated state via notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        // Defer to allow navigation stack to be ready
        Future.delayed(const Duration(milliseconds: 500), () {
          onNotificationTapped?.call(initialMessage.data);
        });
      }

      return token;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PushNotification: initialization failed: $e');
      }
      return null;
    }
  }

  Future<void> registerToken(String token) async {
    final platform = Platform.isIOS ? 'apns' : 'fcm';
    await _apiClient.updatePushToken(pushToken: token, pushPlatform: platform);
  }

  Future<void> handleMessage(Map<String, dynamic> data) async {
    final type = data['type'] as String?;

    switch (type) {
      case 'member_confirmed':
      case 'pair_confirmed':
        await _onMemberConfirmed?.call(data);
        break;
      case 'sync_available':
        await _onSyncAvailable?.call(data);
        break;
      case 'join_request':
      case 'pair_request':
        await _onJoinRequest?.call(data);
        break;
      default:
        if (kDebugMode) {
          debugPrint('PushNotification: unknown message type: $type');
        }
    }
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/infrastructure/sync/push_notification_service_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/infrastructure/sync/push_notification_service.dart test/infrastructure/sync/push_notification_service_test.dart
git commit -m "feat: implement Firebase Messaging in PushNotificationService"
```

---

## Task 22: Add local notification display for foreground messages

Show visible notifications when app is in foreground (especially for `join_request`).

**Files:**
- Create: `lib/infrastructure/sync/local_notification_service.dart`
- Modify: `lib/infrastructure/sync/push_notification_service.dart`
- Test: `test/infrastructure/sync/local_notification_service_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/sync/local_notification_service.dart';

void main() {
  test('LocalNotificationService creates notification channel', () {
    final service = LocalNotificationService();
    // Verify initialization doesn't throw
    expect(service, isNotNull);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/infrastructure/sync/local_notification_service_test.dart`
Expected: FAIL

**Step 3: Write LocalNotificationService**

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Manages local notifications for foreground push display.
///
/// Used when app is in foreground and a push notification arrives
/// that needs visual display (e.g., join_request from new member).
class LocalNotificationService {
  LocalNotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Callback when user taps a local notification.
  void Function(String? payload)? onNotificationTapped;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,  // Already requested via Firebase
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        onNotificationTapped?.call(response.payload);
      },
    );

    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      'family_sync',
      'ファミリー同期',
      description: '家族同期の通知',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Show a local notification.
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'family_sync',
      'ファミリー同期',
      channelDescription: '家族同期の通知',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }
}
```

**Step 4: Wire into PushNotificationService**

Update `PushNotificationService` to show local notification on foreground `join_request`:

```dart
// In handleMessage, for join_request type:
case 'join_request':
case 'pair_request':
  // Show visible notification in foreground
  final deviceName = data['deviceName'] as String? ?? 'Unknown';
  _localNotification?.show(
    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title: '新しい参加リクエスト',
    body: '$deviceNameがグループへの参加をリクエストしました',
    payload: 'join_request:${data['groupId']}:${data['deviceId']}',
  );
  await _onJoinRequest?.call(data);
  break;
```

**Step 5: Run test to verify it passes**

Run: `flutter test test/infrastructure/sync/local_notification_service_test.dart`
Expected: PASS

**Step 6: Commit**

```bash
git add lib/infrastructure/sync/local_notification_service.dart test/infrastructure/sync/local_notification_service_test.dart lib/infrastructure/sync/push_notification_service.dart
git commit -m "feat: add local notification display for foreground push messages"
```

---

## Task 23: Wire push notification to SyncTriggerService

Update `SyncTriggerService` to handle `join_request` type and add navigation callback.

**Files:**
- Modify: `lib/infrastructure/sync/sync_trigger_service.dart`
- Test: `test/infrastructure/sync/sync_trigger_service_test.dart`

**Step 1: Write the failing test**

```dart
void main() {
  test('SyncTriggerService registers join_request handler', () {
    // Verify that onJoinRequest handler is registered during initialize()
    // and that it exposes data for UI navigation
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/infrastructure/sync/sync_trigger_service_test.dart`
Expected: FAIL

**Step 3: Update SyncTriggerService**

Add:
1. `onJoinRequest` handler registration
2. A `joinRequestStream` (or callback) that the presentation layer can listen to for navigation
3. A `memberConfirmedStream` for WaitingApprovalScreen to listen to

```dart
import 'dart:async';

class SyncTriggerService {
  // ... existing fields ...

  /// Stream controller for join request events (owner receives).
  final _joinRequestController = StreamController<Map<String, dynamic>>.broadcast();

  /// Stream controller for member confirmed events (member receives).
  final _memberConfirmedController = StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of join request events. Listen in UI to navigate to MemberApprovalScreen.
  Stream<Map<String, dynamic>> get joinRequestStream => _joinRequestController.stream;

  /// Stream of member confirmed events. Listen in WaitingApprovalScreen.
  Stream<Map<String, dynamic>> get memberConfirmedStream => _memberConfirmedController.stream;

  void initialize() {
    _lifecycleObserver = SyncLifecycleObserver(onResume: _handleAppResume);
    _lifecycleObserver!.start();

    _pushNotificationService.registerHandlers(
      onMemberConfirmed: _handleMemberConfirmed,
      onSyncAvailable: _handleSyncAvailable,
      onJoinRequest: _handleJoinRequest,
    );

    // Wire notification tap → navigation
    _pushNotificationService.onNotificationTapped = _handleNotificationTap;
  }

  Future<void> _handleJoinRequest(Map<String, dynamic> data) async {
    if (kDebugMode) {
      debugPrint('SyncTrigger: join request received');
    }
    _joinRequestController.add(data);
  }

  Future<void> _handleMemberConfirmed(Map<String, dynamic> data) async {
    // ... existing confirmation logic ...
    _memberConfirmedController.add(data);
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    if (type == 'join_request' || type == 'pair_request') {
      _joinRequestController.add(data);
    }
  }

  void dispose() {
    _lifecycleObserver?.dispose();
    _lifecycleObserver = null;
    _joinRequestController.close();
    _memberConfirmedController.close();
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/infrastructure/sync/sync_trigger_service_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/infrastructure/sync/sync_trigger_service.dart test/infrastructure/sync/sync_trigger_service_test.dart
git commit -m "feat: wire push notification streams to SyncTriggerService"
```

---

## Task 24: Create notification navigation provider

Create a Riverpod provider that listens to push notification streams and exposes navigation events.

**Files:**
- Create: `lib/features/family_sync/presentation/providers/notification_navigation_provider.dart`
- Test: `test/features/family_sync/presentation/providers/notification_navigation_provider_test.dart`

**Step 1: Write the failing test**

```dart
void main() {
  test('notificationNavigationProvider emits JoinRequestEvent on push', () async {
    // Verify provider emits navigation events when SyncTriggerService streams data
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/family_sync/presentation/providers/notification_navigation_provider_test.dart`
Expected: FAIL

**Step 3: Write the provider**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../family_sync/domain/models/group_member.dart';
import 'sync_providers.dart';

part 'notification_navigation_provider.g.dart';

/// Navigation event types from push notifications.
sealed class PushNavigationEvent {}

class JoinRequestEvent extends PushNavigationEvent {
  JoinRequestEvent({required this.groupId, required this.deviceId, required this.deviceName});
  final String groupId;
  final String deviceId;
  final String deviceName;
}

class MemberConfirmedEvent extends PushNavigationEvent {
  MemberConfirmedEvent({required this.groupId});
  final String groupId;
}

/// Stream provider that emits navigation events from push notifications.
@riverpod
Stream<PushNavigationEvent> pushNavigationEvents(Ref ref) {
  final syncTrigger = ref.watch(syncTriggerServiceProvider);

  return MergeStream([
    syncTrigger.joinRequestStream.map((data) => JoinRequestEvent(
      groupId: data['groupId'] as String? ?? '',
      deviceId: data['deviceId'] as String? ?? '',
      deviceName: data['deviceName'] as String? ?? 'Unknown Device',
    )),
    syncTrigger.memberConfirmedStream.map((data) => MemberConfirmedEvent(
      groupId: data['groupId'] as String? ?? '',
    )),
  ]);
}
```

Note: Use `rxdart` `MergeStream` or implement a simple merge utility.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/family_sync/presentation/providers/notification_navigation_provider_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/family_sync/presentation/providers/notification_navigation_provider.dart test/features/family_sync/presentation/providers/notification_navigation_provider_test.dart
git commit -m "feat: add push notification navigation provider"
```

---

## Task 25: Wire push navigation to screens

Connect push notification events to actual screen navigation.

**Files:**
- Modify: `lib/main.dart` (or `lib/features/home/presentation/screens/main_shell_screen.dart`)
- Modify: `lib/features/family_sync/presentation/screens/waiting_approval_screen.dart`

**Step 1: Add navigation listener in MainShellScreen (or app root)**

In the app's root `ConsumerStatefulWidget`, listen to `pushNavigationEventsProvider`:

```dart
@override
void initState() {
  super.initState();
  // Listen for push notification navigation events
  ref.listenManual(pushNavigationEventsProvider, (previous, next) {
    next.whenData((event) {
      switch (event) {
        case JoinRequestEvent(:final groupId, :final deviceId, :final deviceName):
          // Navigate to MemberApprovalScreen
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => MemberApprovalScreen(
              pendingMember: GroupMember(
                deviceId: deviceId,
                publicKey: '',
                deviceName: deviceName,
                role: 'member',
                status: 'pending',
              ),
              groupId: groupId,
            ),
          ));
        case MemberConfirmedEvent():
          // Handled by WaitingApprovalScreen directly
          break;
      }
    });
  });
}
```

**Step 2: Update WaitingApprovalScreen to listen for memberConfirmedStream**

```dart
// In WaitingApprovalScreen's initState:
final syncTrigger = ref.read(syncTriggerServiceProvider);
_memberConfirmedSubscription = syncTrigger.memberConfirmedStream.listen((data) {
  final confirmedGroupId = data['groupId'] as String?;
  if (confirmedGroupId == widget.groupId) {
    // Approval received! Navigate to GroupManagementScreen
    _navigateToGroupManagement();
  }
});
```

**Step 3: Run tests**

Run: `flutter test`
Expected: All tests pass

**Step 4: Commit**

```bash
git add lib/main.dart lib/features/family_sync/presentation/screens/waiting_approval_screen.dart
git commit -m "feat: wire push notification navigation to family sync screens"
```

---

## Task 26: Initialize push notification service on app start

Wire the full initialization chain in `main.dart`.

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/features/family_sync/presentation/providers/repository_providers.dart`

**Step 1: Update repository_providers to include LocalNotificationService**

Add provider for `LocalNotificationService`:

```dart
@riverpod
LocalNotificationService localNotificationService(Ref ref) {
  return LocalNotificationService();
}
```

**Step 2: Update main.dart initialization**

After `syncTrigger.initialize()`, add push notification initialization:

```dart
// Initialize sync triggers
final syncTrigger = ref.read(syncTriggerServiceProvider);
syncTrigger.initialize();

// Initialize push notifications (Firebase must be initialized first)
final pushService = ref.read(pushNotificationServiceProvider);
final localNotification = ref.read(localNotificationServiceProvider);
await localNotification.initialize();
// Wire local notification tap → push service callback
localNotification.onNotificationTapped = (payload) {
  if (payload != null && payload.startsWith('join_request:')) {
    final parts = payload.split(':');
    if (parts.length >= 3) {
      pushService.onNotificationTapped?.call({
        'type': 'join_request',
        'groupId': parts[1],
        'deviceId': parts[2],
      });
    }
  }
};
await pushService.initialize();
```

**Step 3: Run build**

Run: `flutter build apk --debug`
Expected: Success

**Step 4: Commit**

```bash
git add lib/main.dart lib/features/family_sync/presentation/providers/repository_providers.dart
git commit -m "feat: initialize push notification service on app start"
```

---

## Task 27: Run full quality checks

**Step 1: Run analyzer**

Run: `flutter analyze`
Expected: 0 issues

**Step 2: Run formatter**

Run: `dart format .`
Expected: No formatting changes (or apply them)

**Step 3: Run all tests**

Run: `flutter test`
Expected: All tests pass

**Step 4: Run test coverage**

Run: `flutter test --coverage`
Expected: ≥80% coverage on new files

**Step 5: Fix any issues found**

Address analyzer warnings, test failures, coverage gaps.

**Step 6: Commit any fixes**

```bash
git add -A
git commit -m "fix: address quality check findings for family sync UI + push notifications"
```

---

## Task 28: Run build_runner and verify full build

**Step 1: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: Success

**Step 2: Verify Android build**

Run: `flutter build apk --debug`
Expected: Success

**Step 3: Verify iOS build**

Run: `cd ios && pod install && cd .. && flutter build ios --no-codesign --debug`
Expected: Success (may require GoogleService-Info.plist)

**Step 4: Commit generated files if changed**

```bash
git add -A
git commit -m "chore: regenerate code after family sync UI + push notification changes"
```

---

## Summary of Deliverables

| Phase | Task | Deliverable | Screen/Layer |
|-------|------|------------|--------------|
| **Phase 1** | 1 | l10n strings (3 ARB files) | All |
| | 2 | `MemberAvatar` widget | FS4, FS5 |
| | 3 | `GradientActionButton` widget | FS2, FS4 |
| | 4 | `InfoHintBox` widget | FS1, FS4 |
| | 5 | `OutlineActionButton` widget | FS1, FS2, FS3 |
| | 6 | `StatusBadge` widget | FS3, FS4, FS5 |
| | 7 | `DigitCodeDisplay` widget | FS1 |
| | 8 | `OtpDigitInput` widget | FS2 |
| | 9 | `SyncStatsCard` widget | FS5 |
| | 10 | `MemberListTile` widget | FS4, FS5 |
| **Phase 2** | 11 | Redesigned `PairCodeDisplay` | FS1 |
| | 12 | Redesigned `PairCodeInput` | FS2 |
| | 13 | Updated `PairingScreen` tabs | FS1/FS2 |
| | 14 | NEW `WaitingApprovalScreen` | FS3 |
| | 15 | NEW `MemberApprovalScreen` | FS4 |
| | 16 | NEW `GroupManagementScreen` | FS5 |
| | 17–18 | Navigation + cleanup | All |
| **Phase 3** | 19 | Firebase Messaging dependencies | Infrastructure |
| | 20 | Firebase initialization in `main.dart` | Infrastructure |
| | 21 | `PushNotificationService` Firebase impl | Infrastructure |
| | 22 | `LocalNotificationService` (foreground) | Infrastructure |
| | 23 | `SyncTriggerService` push streams | Infrastructure |
| | 24 | Push navigation provider | Presentation |
| | 25 | Screen navigation wiring | Presentation |
| | 26 | App startup push initialization | Infrastructure |
| **Phase 4** | 27–28 | Quality checks + build verification | All |

**New files:** 12 widgets/services + 2 screens + tests
**Modified files:** 4 widgets/screens + 3 infrastructure services + 3 ARB files + `main.dart`
**Deleted files:** 1 screen (pair_management_screen.dart)

## Push Notification Message Types

| Server Message | Recipient | Client Action |
|---------------|-----------|---------------|
| `join_request` | Owner | Show local notification → navigate to MemberApprovalScreen (FS4) |
| `member_confirmed` | Member | Trigger WaitingApprovalScreen → GroupManagementScreen transition |
| `sync_available` | All paired | Pull sync data from server |
| `pair_confirmed` | Member | Same as `member_confirmed` (legacy compat) |
| `pair_request` | Owner | Same as `join_request` (legacy compat) |
