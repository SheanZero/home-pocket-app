import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/sync/push_notification_service.dart';
import '../providers/notification_navigation_provider.dart';
import '../screens/group_management_screen.dart';
import '../screens/member_approval_screen.dart';

typedef NotificationRouteBuilder =
    Widget Function(BuildContext context, String? groupId);

class FamilySyncNotificationRouteListener extends ConsumerStatefulWidget {
  const FamilySyncNotificationRouteListener({
    super.key,
    required this.child,
    this.buildMemberApprovalScreen,
    this.buildGroupManagementScreen,
  });

  final Widget child;
  final NotificationRouteBuilder? buildMemberApprovalScreen;
  final NotificationRouteBuilder? buildGroupManagementScreen;

  @override
  ConsumerState<FamilySyncNotificationRouteListener> createState() =>
      _FamilySyncNotificationRouteListenerState();
}

class _FamilySyncNotificationRouteListenerState
    extends ConsumerState<FamilySyncNotificationRouteListener> {
  PushNavigationIntent? _lastHandledIntent;

  @override
  Widget build(BuildContext context) {
    final intent = ref.watch(familySyncNotificationNavigationProvider);
    if (intent == null) {
      _lastHandledIntent = null;
      return widget.child;
    }

    if (intent != _lastHandledIntent) {
      _lastHandledIntent = intent;
      _scheduleNavigation(intent);
    }

    return widget.child;
  }

  void _scheduleNavigation(PushNavigationIntent intent) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      ref.read(familySyncNotificationNavigationProvider.notifier).clear();
      switch (intent.destination) {
        case PushNavigationDestination.memberApproval:
          final builder =
              widget.buildMemberApprovalScreen ??
              (context, groupId) => MemberApprovalScreen(groupId: groupId);
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => builder(context, intent.groupId),
            ),
          );
          break;
        case PushNavigationDestination.groupManagement:
          final builder =
              widget.buildGroupManagementScreen ??
              (context, groupId) => GroupManagementScreen(groupId: groupId);
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => builder(context, intent.groupId),
            ),
          );
          break;
        case PushNavigationDestination.memberRemoved:
        case PushNavigationDestination.groupDissolved:
          // SyncEngine manages status automatically via HandleMemberLeft/HandleGroupDissolved
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).familySyncStatusUnpaired)),
          );
          break;
      }
    });
  }
}
