import '../../infrastructure/sync/push_notification_service.dart';

/// Application-layer use case wrapping [PushNotificationService] for screens
/// and providers that listen to push-navigation intents (e.g.,
/// `notification_navigation_provider.dart`, `family_sync_notification_route_listener.dart`).
///
/// Surfaces the `navigationIntents` stream and helper methods so callers
/// no longer need to import infrastructure/ directly.
class ListenToPushNotificationsUseCase {
  ListenToPushNotificationsUseCase({required PushNotificationService service})
      : _service = service;

  final PushNotificationService _service;

  /// Returns the stream of [PushNavigationIntent]s emitted by the service.
  ///
  /// Screens use this to react to incoming push notifications.
  Stream<PushNavigationIntent> execute() => _service.navigationIntents;

  /// Takes and clears the pending navigation intent (for cold-start use).
  PushNavigationIntent? takePendingIntent() =>
      _service.takePendingNavigationIntent();

  /// Registers optional message handlers on the underlying service.
  void registerHandlers({
    PushMessageHandler? onMemberConfirmed,
    PushMessageHandler? onSyncAvailable,
    PushMessageHandler? onJoinRequest,
    PushMessageHandler? onMemberLeft,
    PushMessageHandler? onGroupDissolved,
  }) =>
      _service.registerHandlers(
        onMemberConfirmed: onMemberConfirmed,
        onSyncAvailable: onSyncAvailable,
        onJoinRequest: onJoinRequest,
        onMemberLeft: onMemberLeft,
        onGroupDissolved: onGroupDissolved,
      );
}
