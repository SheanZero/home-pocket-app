import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/family_sync/listen_to_push_notifications_use_case.dart';
import '../../../../application/family_sync/repository_providers.dart'
    as app_family_sync;
import '../../../../application/family_sync/repository_providers.dart'
    show PushNavigationIntent;

export '../../../../application/family_sync/repository_providers.dart'
    show PushNavigationIntent, PushNavigationDestination;

final familySyncNotificationNavigationProvider =
    StateNotifierProvider.autoDispose<
      FamilySyncNotificationNavigationController,
      PushNavigationIntent?
    >((ref) {
      final useCase = ref.watch(
        app_family_sync.listenToPushNotificationsUseCaseProvider,
      );
      return FamilySyncNotificationNavigationController(useCase);
    });

class FamilySyncNotificationNavigationController
    extends StateNotifier<PushNavigationIntent?> {
  FamilySyncNotificationNavigationController(
    ListenToPushNotificationsUseCase useCase,
  ) : _useCase = useCase,
      super(useCase.takePendingIntent()) {
    _subscription = _useCase.execute().listen((intent) {
      state = intent;
    });
  }

  final ListenToPushNotificationsUseCase _useCase;
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
