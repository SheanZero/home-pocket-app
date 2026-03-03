import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/sync/push_notification_service.dart';
import 'repository_providers.dart';

final familySyncNotificationNavigationProvider =
    StateNotifierProvider.autoDispose<
      FamilySyncNotificationNavigationController,
      PushNavigationIntent?
    >((ref) {
      final service = ref.watch(pushNotificationServiceProvider);
      return FamilySyncNotificationNavigationController(service);
    });

class FamilySyncNotificationNavigationController
    extends StateNotifier<PushNavigationIntent?> {
  FamilySyncNotificationNavigationController(PushNotificationService service)
    : _service = service,
      super(service.takePendingNavigationIntent()) {
    _subscription = _service.navigationIntents.listen((intent) {
      state = intent;
    });
  }

  final PushNotificationService _service;
  StreamSubscription<PushNavigationIntent>? _subscription;

  void clear() {
    state = null;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
