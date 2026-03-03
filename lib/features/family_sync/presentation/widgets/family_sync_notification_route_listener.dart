import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/sync/push_notification_service.dart';
import '../providers/notification_navigation_provider.dart';
import '../screens/group_management_screen.dart';
import '../screens/member_approval_screen.dart';

class FamilySyncNotificationRouteListener extends ConsumerStatefulWidget {
  const FamilySyncNotificationRouteListener({
    super.key,
    required this.child,
    this.buildMemberApprovalScreen,
    this.buildGroupManagementScreen,
  });

  final Widget child;
  final WidgetBuilder? buildMemberApprovalScreen;
  final WidgetBuilder? buildGroupManagementScreen;

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
    final builder = switch (intent.destination) {
      PushNavigationDestination.memberApproval =>
        widget.buildMemberApprovalScreen ?? (_) => const MemberApprovalScreen(),
      PushNavigationDestination.groupManagement =>
        widget.buildGroupManagementScreen ??
            (_) => const GroupManagementScreen(),
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      ref.read(familySyncNotificationNavigationProvider.notifier).clear();
      Navigator.of(context).push(MaterialPageRoute<void>(builder: builder));
    });
  }
}
