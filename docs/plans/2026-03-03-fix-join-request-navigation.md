# Fix: Foreground join_request Not Opening Approval Screen

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** When a `join_request` push notification arrives while the app is in the foreground, automatically navigate to the MemberApprovalScreen.

**Architecture:** Two bugs prevent navigation: (1) `_handleIncomingMessage` only shows a local notification for foreground `join_request` but never emits a navigation intent, and (2) iOS `AppDelegate.willPresent` treats all notifications identically — suppressing local notification banners and re-emitting local notification metadata into the foreground stream, causing a spurious `type=null` message.

**Tech Stack:** Dart/Flutter, iOS Swift (AppDelegate), flutter_local_notifications, APNs

---

## Root Cause Analysis

### Log Trace

```
1. _handleIncomingMessage type=join_request source=foreground data={type: join_request}
2. foreground message received: {title: 新的加入請求, presentBadge: true, ...}
3. _handleIncomingMessage type=null source=foreground data={title: 新的加入請求, ...}
4. unknown message type: null
```

### Bug 1 (Primary): No navigation intent for foreground join_request

In `push_notification_service.dart:373-381`:

```dart
case 'join_request':
case 'pair_request':
  await _onJoinRequest?.call(data);
  if (source == _PushMessageSource.foreground) {
    await _showForegroundNotification(data);     // ← shows local notification
    // ← MISSING: handleNotificationTap(data) — no navigation intent!
  } else if (source != _PushMessageSource.direct) {
    await handleNotificationTap(data);            // ← only for appOpened/initialMessage
  }
```

`handleNotificationTap` (which emits `PushNavigationIntent.memberApproval`) is only called for non-foreground, non-direct sources. The foreground path only shows a local notification and relies on the user tapping it — but that banner is suppressed by Bug 2.

### Bug 2 (iOS): `willPresent` suppresses local notifications and re-emits data

In `AppDelegate.swift:124-136`:

```swift
override func userNotificationCenter(
  _ center: UNUserNotificationCenter,
  willPresent notification: UNNotification,
  withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
) {
  let payload = normalize(userInfo: notification.request.content.userInfo)
  if !payload.isEmpty {
    foregroundStreamHandler.emit(payload)   // ← re-emits local notification metadata
  }
  completionHandler([])                     // ← suppresses ALL banners (remote AND local)
}
```

iOS calls `willPresent` for **both** remote (APNs) and local notifications. This causes:
1. Local notification banner from `flutter_local_notifications` is suppressed (`completionHandler([])`)
2. Local notification metadata (title, presentBadge, etc.) is re-emitted to the foreground stream
3. Flutter receives a second message with `type=null` → "unknown message type"

---

## Fix Summary

| File | Change |
|------|--------|
| `lib/infrastructure/sync/push_notification_service.dart` | Emit navigation intent for foreground `join_request`; remove `_showForegroundNotification` for this case |
| `ios/Runner/AppDelegate.swift` | Distinguish remote vs local notifications in `willPresent` using `UNPushNotificationTrigger` |
| `test/infrastructure/sync/push_notification_service_test.dart` | Update existing test to expect navigation instead of "no navigation" |

---

## Task 1: Update Dart test to expect navigation for foreground join_request

**Files:**
- Modify: `test/infrastructure/sync/push_notification_service_test.dart:205-223`

**Step 1: Update the failing test**

Change the test at line 205-223 from asserting "no navigation" to asserting navigation intent IS emitted:

```dart
  test(
    'foreground join_request emits navigation intent for member approval',
    () async {
      await service.initialize();

      final intents = <PushNavigationIntent>[];
      service.navigationIntents.listen(intents.add);

      await messagingClient.emitForegroundMessage({
        'type': 'join_request',
        'groupId': 'group-1',
      });

      expect(joinRequestCalls, 1);
      expect(localNotificationClient.shownNotifications, isEmpty);
      expect(intents, [
        const PushNavigationIntent.memberApproval(groupId: 'group-1'),
      ]);
    },
  );
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/infrastructure/sync/push_notification_service_test.dart -v`
Expected: FAIL — current code shows local notification and does not emit navigation intent.

---

## Task 2: Fix `_handleIncomingMessage` to navigate on foreground join_request

**Files:**
- Modify: `lib/infrastructure/sync/push_notification_service.dart:373-381`

**Step 3: Update the join_request/pair_request handling**

Replace the current `join_request` case (lines 373-381):

```dart
      case 'join_request':
      case 'pair_request':
        await _onJoinRequest?.call(data);
        if (source == _PushMessageSource.foreground) {
          await _showForegroundNotification(data);
        } else if (source != _PushMessageSource.direct) {
          await handleNotificationTap(data);
        }
        break;
```

With:

```dart
      case 'join_request':
      case 'pair_request':
        await _onJoinRequest?.call(data);
        if (source != _PushMessageSource.direct) {
          await handleNotificationTap(data);
        }
        break;
```

This removes the foreground special-case that only showed a local notification, and instead always emits a navigation intent (except for `direct` source which is programmatic).

**Step 4: Run test to verify it passes**

Run: `flutter test test/infrastructure/sync/push_notification_service_test.dart -v`
Expected: PASS

---

## Task 3: Fix iOS `willPresent` to distinguish remote vs local notifications

**Files:**
- Modify: `ios/Runner/AppDelegate.swift:124-136`

**Step 5: Update `willPresent` to check notification trigger type**

Replace the current `willPresent` override (lines 124-136):

```swift
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    NSLog("[APNs] willPresent (foreground): \(notification.request.content.userInfo)")
    let payload = normalize(userInfo: notification.request.content.userInfo)
    NSLog("[APNs] normalized payload: \(payload), isEmpty: \(payload.isEmpty), hasListener: \(foregroundStreamHandler.hasListener)")
    if !payload.isEmpty {
      foregroundStreamHandler.emit(payload)
    }
    completionHandler([])
  }
```

With:

```swift
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if notification.request.trigger is UNPushNotificationTrigger {
      // Remote APNs push — forward payload to Flutter, suppress system banner
      NSLog("[APNs] willPresent (remote push): \(notification.request.content.userInfo)")
      let payload = normalize(userInfo: notification.request.content.userInfo)
      if !payload.isEmpty {
        foregroundStreamHandler.emit(payload)
      }
      completionHandler([])
    } else {
      // Local notification (from flutter_local_notifications) — let plugin handle presentation
      NSLog("[APNs] willPresent (local notification): forwarding to super")
      super.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
    }
  }
```

This ensures:
- Remote APNs notifications → forwarded to Flutter stream, banner suppressed
- Local notifications (from `flutter_local_notifications`) → handled by the plugin (banner shown if configured), NOT re-emitted to Flutter stream

**Step 6: Verify the iOS build compiles**

Run: `flutter build ios --debug --no-codesign`
Expected: BUILD SUCCEEDED

---

## Task 4: Verify all tests pass

**Step 7: Run full test suite**

Run: `flutter test`
Expected: All tests pass

**Step 8: Run analyzer**

Run: `flutter analyze`
Expected: No issues found

---

## Task 5: Commit

**Step 9: Commit the fix**

```bash
git add lib/infrastructure/sync/push_notification_service.dart \
        ios/Runner/AppDelegate.swift \
        test/infrastructure/sync/push_notification_service_test.dart
git commit -m "fix: auto-navigate to approval screen on foreground join_request

- Remove local notification for foreground join_request; emit navigation
  intent directly so MemberApprovalScreen opens immediately
- Fix iOS willPresent to distinguish remote vs local notifications using
  UNPushNotificationTrigger, preventing double message emission and
  local notification banner suppression"
```

---

## Verification Checklist

- [ ] Foreground `join_request` emits `PushNavigationIntent.memberApproval`
- [ ] `FamilySyncNotificationRouteListener` navigates to `MemberApprovalScreen`
- [ ] iOS `willPresent` no longer re-emits local notification data to foreground stream
- [ ] No "unknown message type: null" log spam
- [ ] `member_confirmed` foreground behavior unchanged (still shows local notification)
- [ ] `flutter test` passes
- [ ] `flutter analyze` clean
- [ ] iOS build succeeds
