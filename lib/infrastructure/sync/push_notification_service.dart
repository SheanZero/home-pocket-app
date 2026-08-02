import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../generated/app_localizations.dart';
import 'relay_api_client.dart';

typedef PushMessageHandler = Future<void> Function(Map<String, dynamic> data);
typedef FirebaseInitializer = Future<void> Function();

enum PushNavigationDestination {
  memberApproval,
  groupManagement,
  memberRemoved,
  groupDissolved,
}

class PushNavigationIntent {
  const PushNavigationIntent._({required this.destination, this.groupId});

  const PushNavigationIntent.memberApproval({String? groupId})
    : this._(
        destination: PushNavigationDestination.memberApproval,
        groupId: groupId,
      );

  const PushNavigationIntent.groupManagement({String? groupId})
    : this._(
        destination: PushNavigationDestination.groupManagement,
        groupId: groupId,
      );

  const PushNavigationIntent.memberRemoved({String? groupId})
    : this._(
        destination: PushNavigationDestination.memberRemoved,
        groupId: groupId,
      );

  const PushNavigationIntent.groupDissolved({String? groupId})
    : this._(
        destination: PushNavigationDestination.groupDissolved,
        groupId: groupId,
      );

  final PushNavigationDestination destination;
  final String? groupId;

  @override
  bool operator ==(Object other) {
    return other is PushNavigationIntent &&
        other.destination == destination &&
        other.groupId == groupId;
  }

  @override
  int get hashCode => Object.hash(destination, groupId);
}

class ShownLocalNotification {
  const ShownLocalNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final Map<String, dynamic> payload;
}

abstract class PushMessagingClient {
  Future<void> requestPermission();

  Future<String?> getToken();

  Stream<String> get onTokenRefresh;

  Stream<Map<String, dynamic>> get onForegroundMessage;

  Stream<Map<String, dynamic>> get onMessageOpenedApp;

  Future<Map<String, dynamic>?> getInitialMessage();
}

abstract class LocalNotificationClient {
  Future<void> initialize(
    Future<void> Function(Map<String, dynamic> data) onTap,
  );

  Future<void> show({
    required int id,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  });
}

abstract interface class IdentityBoundLocalNotificationCleaner {
  /// Removes notifications whose payload belongs to the revoked identity.
  Future<void> cancelAll();
}

class FirebasePushMessagingClient implements PushMessagingClient {
  FirebasePushMessagingClient({FirebaseMessaging? messaging})
    : _messaging = messaging;

  final FirebaseMessaging? _messaging;

  FirebaseMessaging get _instance => _messaging ?? FirebaseMessaging.instance;

  @override
  Future<void> requestPermission() async {
    await _instance.requestPermission();
  }

  @override
  Future<String?> getToken() => _instance.getToken();

  @override
  Stream<String> get onTokenRefresh => _instance.onTokenRefresh;

  @override
  Stream<Map<String, dynamic>> get onForegroundMessage =>
      FirebaseMessaging.onMessage.map((message) => message.data);

  @override
  Stream<Map<String, dynamic>> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp.map((message) => message.data);

  @override
  Future<Map<String, dynamic>?> getInitialMessage() async {
    final message = await _instance.getInitialMessage();
    return message?.data;
  }
}

class FlutterLocalNotificationClient
    implements LocalNotificationClient, IdentityBoundLocalNotificationCleaner {
  FlutterLocalNotificationClient({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'family_sync';
  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> initialize(
    Future<void> Function(Map<String, dynamic> data) onTap,
  ) async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) async {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        await onTap(jsonDecode(payload) as Map<String, dynamic>);
      },
    );
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Family Sync',
        channelDescription: 'Family sync notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: jsonEncode(payload),
    );
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();
}

/// Minimal local state required to authorize an identity-bound family push.
///
/// The infrastructure layer intentionally receives this projection through a
/// callback so it does not depend on feature/domain models.
class FamilyPushAcceptanceContext {
  const FamilyPushAcceptanceContext({
    required this.deviceId,
    required this.groupId,
    required this.groupStatus,
    required this.groupRole,
    required this.memberStatus,
    this.controlRevision = 0,
  });

  final String deviceId;
  final String groupId;
  final String groupStatus;
  final String groupRole;
  final String memberStatus;
  final int controlRevision;
}

abstract interface class PushAcceptancePolicy {
  /// Stable local identity marker captured by installed subscriptions.
  Future<String?> resolveIdentityGeneration();

  /// Revalidates a message against live local identity/family state.
  Future<bool> accepts(
    Map<String, dynamic> data, {
    required String? boundIdentityGeneration,
  });
}

/// Safe default used until the feature layer supplies its live repository
/// backed policy. Non-family messages remain outside this family gate.
class RejectIdentityBoundFamilyPushAcceptancePolicy
    implements PushAcceptancePolicy {
  const RejectIdentityBoundFamilyPushAcceptancePolicy();

  @override
  Future<String?> resolveIdentityGeneration() async => null;

  @override
  Future<bool> accepts(
    Map<String, dynamic> data, {
    required String? boundIdentityGeneration,
  }) async {
    final type = data['type'];
    return type is String &&
        type.isNotEmpty &&
        !IdentityBoundFamilyPushAcceptancePolicy.isFamilyType(type);
  }
}

class IdentityBoundFamilyPushAcceptancePolicy implements PushAcceptancePolicy {
  IdentityBoundFamilyPushAcceptancePolicy({
    required Future<String?> Function() identityGenerationResolver,
    required Future<FamilyPushAcceptanceContext?> Function() contextResolver,
  }) : _identityGenerationResolver = identityGenerationResolver,
       _contextResolver = contextResolver;

  static const _familyTypes = <String>{
    'member_confirmed',
    'pair_confirmed',
    'sync_available',
    'join_request',
    'pair_request',
    'join_request_rejected',
    'join_request_cancelled',
    'join_request_expired',
    'member_left',
    'group_dissolved',
    'group_name_updated',
    'owner_transferred',
    'group_key_requested',
  };

  static const _approvalTypes = <String>{'join_request', 'pair_request'};
  static const _preActivationLifecycleTypes = <String>{
    'member_confirmed',
    'pair_confirmed',
    'join_request_rejected',
    'join_request_cancelled',
    'join_request_expired',
  };

  final Future<String?> Function() _identityGenerationResolver;
  final Future<FamilyPushAcceptanceContext?> Function() _contextResolver;

  static bool isFamilyType(String type) => _familyTypes.contains(type);

  @override
  Future<String?> resolveIdentityGeneration() async {
    final identity = await _identityGenerationResolver();
    if (identity == null || identity.trim().isEmpty) return null;
    return identity;
  }

  @override
  Future<bool> accepts(
    Map<String, dynamic> data, {
    required String? boundIdentityGeneration,
  }) async {
    final typeValue = data['type'];
    if (typeValue is! String || typeValue.isEmpty) return false;
    if (!isFamilyType(typeValue)) return true;

    final currentIdentity = await resolveIdentityGeneration();
    if (currentIdentity == null) return false;
    if (boundIdentityGeneration != null &&
        currentIdentity != boundIdentityGeneration) {
      return false;
    }

    final payloadIdentity = data['identityGeneration'];
    if (payloadIdentity != null &&
        (payloadIdentity is! String || payloadIdentity != currentIdentity)) {
      return false;
    }
    final targetDeviceId = data['targetDeviceId'];
    if (targetDeviceId != null &&
        (targetDeviceId is! String || targetDeviceId != currentIdentity)) {
      return false;
    }

    // This event is deliberately metadata-free in the relay contract: it only
    // wakes an authenticated durable-ledger fetch. Identity generation is the
    // complete local authorization boundary; no navigation or payload state is
    // consumed from the notification itself.
    if (typeValue == 'group_key_requested') return true;

    final groupIdValue = data['groupId'];
    if (groupIdValue is! String || groupIdValue.trim().isEmpty) return false;

    final context = await _contextResolver();
    if (context == null ||
        context.deviceId != currentIdentity ||
        context.groupId != groupIdValue) {
      return false;
    }

    final revisionValue = data['controlRevision'];
    if (revisionValue != null) {
      final revision = switch (revisionValue) {
        int value => value,
        String value => int.tryParse(value),
        _ => null,
      };
      if (revision == null || revision < context.controlRevision) return false;
    }

    if (_approvalTypes.contains(typeValue)) {
      final isPrivileged =
          context.groupRole == 'owner' || context.groupRole == 'admin';
      return context.groupStatus == 'active' &&
          context.memberStatus == 'active' &&
          isPrivileged;
    }

    if (_preActivationLifecycleTypes.contains(typeValue)) {
      return context.groupStatus != 'inactive' &&
          context.memberStatus != 'removed';
    }

    return context.groupStatus == 'active' && context.memberStatus == 'active';
  }
}

enum _PushMessageSource { direct, foreground, appOpened, initialMessage }

class PushNotificationService {
  PushNotificationService({
    required RelayApiClient apiClient,
    PushMessagingClient? messagingClient,
    LocalNotificationClient? localNotificationClient,
    FirebaseInitializer? firebaseInitializer,
    Locale Function()? localeProvider,
    String? pushPlatform,
    PushAcceptancePolicy acceptancePolicy =
        const RejectIdentityBoundFamilyPushAcceptancePolicy(),
  }) : _apiClient = apiClient,
       _messagingClient = messagingClient ?? FirebasePushMessagingClient(),
       _localNotificationClient =
           localNotificationClient ?? FlutterLocalNotificationClient(),
       _firebaseInitializer =
           firebaseInitializer ??
           (Platform.isAndroid ? Firebase.initializeApp : null),
       _localeProvider =
           localeProvider ??
           (() => WidgetsBinding.instance.platformDispatcher.locale),
       _pushPlatform = pushPlatform,
       _acceptancePolicy = acceptancePolicy;

  final RelayApiClient _apiClient;
  final PushMessagingClient _messagingClient;
  final LocalNotificationClient _localNotificationClient;
  final FirebaseInitializer? _firebaseInitializer;
  final Locale Function() _localeProvider;
  final String? _pushPlatform;
  PushAcceptancePolicy _acceptancePolicy;

  final _navigationController =
      StreamController<PushNavigationIntent>.broadcast();

  final _joinRequestLifecycleController =
      StreamController<Map<String, dynamic>>.broadcast();

  PushMessageHandler? _onMemberConfirmed;
  PushMessageHandler? _onSyncAvailable;
  PushMessageHandler? _onJoinRequest;
  PushMessageHandler? _onMemberLeft;
  PushMessageHandler? _onGroupDissolved;
  PushMessageHandler? _onGroupSnapshotInvalidated;
  PushMessageHandler? _onGroupKeyRequested;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<Map<String, dynamic>>? _foregroundSubscription;
  StreamSubscription<Map<String, dynamic>>? _openedAppSubscription;

  PushNavigationIntent? _pendingNavigationIntent;
  int? _pendingNavigationGeneration;
  bool _initialized = false;
  Future<String?>? _initializationFuture;
  int _identityGeneration = 0;
  bool _identityRevoked = false;
  String? _boundIdentityGeneration;

  Stream<PushNavigationIntent> get navigationIntents =>
      _navigationController.stream;

  /// Terminal join-request events are exposed independently from the
  /// application handler callbacks. Pending applicants are not authorized for
  /// the group WebSocket, so the waiting screen consumes this direct stream
  /// and keeps REST polling as its fallback.
  Stream<Map<String, dynamic>> get joinRequestLifecycleEvents =>
      _joinRequestLifecycleController.stream;

  /// Installs the live, repository-backed policy before initialization.
  ///
  /// Tests may replace it between deliveries to model an identity transition;
  /// production configures it once through the feature provider.
  void configureAcceptancePolicy(PushAcceptancePolicy policy) {
    _acceptancePolicy = policy;
  }

  void registerHandlers({
    PushMessageHandler? onMemberConfirmed,
    PushMessageHandler? onSyncAvailable,
    PushMessageHandler? onJoinRequest,
    PushMessageHandler? onMemberLeft,
    PushMessageHandler? onGroupDissolved,
    PushMessageHandler? onGroupSnapshotInvalidated,
    PushMessageHandler? onGroupKeyRequested,
  }) {
    _onMemberConfirmed = onMemberConfirmed;
    _onSyncAvailable = onSyncAvailable;
    _onJoinRequest = onJoinRequest;
    _onMemberLeft = onMemberLeft;
    _onGroupDissolved = onGroupDissolved;
    _onGroupSnapshotInvalidated = onGroupSnapshotInvalidated;
    _onGroupKeyRequested = onGroupKeyRequested;
  }

  Future<String?> initialize() {
    if (_initialized) {
      return _messagingClient.getToken();
    }
    return _initializationFuture ??= _runInitialization();
  }

  Future<String?> _runInitialization() async {
    try {
      return await _initializeOnce();
    } finally {
      _initializationFuture = null;
    }
  }

  Future<String?> _initializeOnce() async {
    final generation = ++_identityGeneration;
    _identityRevoked = true;
    _boundIdentityGeneration = null;
    try {
      final identity = await _acceptancePolicy.resolveIdentityGeneration();
      if (generation != _identityGeneration || identity == null) return null;
      _boundIdentityGeneration = identity;
      _identityRevoked = false;

      if (kDebugMode) {
        debugPrint('PushNotificationService: initializing');
      }
      if (_firebaseInitializer != null) {
        await _firebaseInitializer();
      }
      if (!_isGenerationCurrent(generation)) return null;
      await _localNotificationClient.initialize(
        (data) => _handleNotificationTap(data, generation: generation),
      );
      if (!_isGenerationCurrent(generation)) return null;
      await _messagingClient.requestPermission();
      if (!_isGenerationCurrent(generation)) return null;

      final token = await _messagingClient.getToken();
      if (_isGenerationCurrent(generation) &&
          token != null &&
          token.isNotEmpty) {
        await _registerTokenBestEffort(token);
      }
      if (!_isGenerationCurrent(generation)) return null;

      _tokenRefreshSubscription = _messagingClient.onTokenRefresh.listen((
        token,
      ) {
        if (!_isGenerationCurrent(generation)) return;
        if (kDebugMode) {
          debugPrint(
            'PushNotificationService: registration credential refreshed',
          );
        }
        unawaited(_registerTokenBestEffort(token));
      });

      _foregroundSubscription = _messagingClient.onForegroundMessage.listen((
        data,
      ) {
        if (!_isGenerationCurrent(generation)) return;
        if (kDebugMode) {
          debugPrint(
            'PushNotificationService: foreground notification received',
          );
        }
        unawaited(
          // Every installed callback is permanently bound to this local
          // identity generation. A wipe invalidates it synchronously.
          _handleIncomingMessage(
            data,
            source: _PushMessageSource.foreground,
            generation: generation,
          ),
        );
      });

      _openedAppSubscription = _messagingClient.onMessageOpenedApp.listen((
        data,
      ) {
        if (!_isGenerationCurrent(generation)) return;
        if (kDebugMode) {
          debugPrint('PushNotificationService: notification opened app');
        }
        unawaited(
          _handleIncomingMessage(
            data,
            source: _PushMessageSource.appOpened,
            generation: generation,
          ),
        );
      });

      // The delivery pipeline is live from this point. Mark initialized before
      // consuming the cold-start message so a handler failure cannot cause a
      // later retry to install duplicate stream subscriptions.
      if (!_isGenerationCurrent(generation)) return null;
      _initialized = true;
      final initialMessage = await _messagingClient.getInitialMessage();
      if (kDebugMode) {
        debugPrint('PushNotificationService: launch notification checked');
      }
      if (initialMessage != null) {
        await _handleIncomingMessage(
          initialMessage,
          source: _PushMessageSource.initialMessage,
          generation: generation,
        );
      }

      return token;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PushNotificationService: initialization failed: $e');
      }
      return null;
    }
  }

  Future<String?> getToken() => _messagingClient.getToken();

  /// Replays the current registration credential after `/device/register`.
  ///
  /// App bootstrap can run before the relay knows this device. Group entry
  /// flows call this once registration succeeds so the token is not stranded.
  Future<void> registerCurrentToken() async {
    if (!_initialized || _identityRevoked || _boundIdentityGeneration == null) {
      await initialize();
    }
    final generation = _identityGeneration;
    if (!_isGenerationCurrent(generation)) return;
    try {
      final token = await _messagingClient.getToken();
      if (_isGenerationCurrent(generation) &&
          token != null &&
          token.isNotEmpty) {
        await _registerTokenBestEffort(token);
      }
    } catch (_) {
      if (kDebugMode) {
        debugPrint(
          'PushNotificationService: current credential replay deferred',
        );
      }
    }
  }

  Future<void> _registerTokenBestEffort(String token) async {
    try {
      await registerToken(token);
    } catch (_) {
      if (kDebugMode) {
        debugPrint(
          'PushNotificationService: push endpoint registration deferred',
        );
      }
    }
  }

  Future<void> registerToken(String token) async {
    final platform = _pushPlatform ?? (Platform.isIOS ? 'apns' : 'fcm');
    if (kDebugMode) {
      debugPrint(
        'PushNotificationService: registering push endpoint for $platform',
      );
    }
    await _apiClient.updatePushToken(pushToken: token, pushPlatform: platform);
    if (kDebugMode) {
      debugPrint('PushNotificationService: push endpoint registered');
    }
  }

  Future<void> handleMessage(Map<String, dynamic> data) async {
    final generation = _identityGeneration;
    await _handleIncomingMessage(
      data,
      source: _PushMessageSource.direct,
      generation: generation,
    );
  }

  Future<void> handleNotificationTap(Map<String, dynamic> data) async {
    await _handleNotificationTap(data, generation: _identityGeneration);
  }

  Future<void> _handleNotificationTap(
    Map<String, dynamic> data, {
    required int generation,
  }) async {
    if (!await _accepts(data, generation: generation)) return;
    final intent = _intentForMessage(data);
    if (intent == null) return;

    _pendingNavigationIntent = intent;
    _pendingNavigationGeneration = generation;
    if (!_navigationController.isClosed) {
      _navigationController.add(intent);
    }
  }

  PushNavigationIntent? takePendingNavigationIntent() {
    if (_pendingNavigationGeneration != _identityGeneration ||
        _identityRevoked) {
      _pendingNavigationIntent = null;
      _pendingNavigationGeneration = null;
      return null;
    }
    final intent = _pendingNavigationIntent;
    _pendingNavigationIntent = null;
    _pendingNavigationGeneration = null;
    return intent;
  }

  /// Discards navigation state derived from the identity/group that has just
  /// been erased locally.
  ///
  /// Revocation happens synchronously before the first cancellation await, so
  /// already queued callbacks cannot mutate state for the erased identity.
  /// This performs no relay call, keeping the wipe strictly local/offline.
  Future<void> clearIdentityBoundState() {
    _identityRevoked = true;
    _identityGeneration++;
    _boundIdentityGeneration = null;
    _initialized = false;
    _pendingNavigationIntent = null;
    _pendingNavigationGeneration = null;
    final cancellation = _cancelPipelineSubscriptions();
    return Future.wait<void>([
      cancellation,
      _cancelIdentityBoundLocalNotifications(),
    ]);
  }

  Future<void> dispose() async {
    _identityRevoked = true;
    _identityGeneration++;
    await _cancelPipelineSubscriptions();
    await _navigationController.close();
    await _joinRequestLifecycleController.close();
  }

  Future<void> _handleIncomingMessage(
    Map<String, dynamic> data, {
    required _PushMessageSource source,
    int? generation,
  }) async {
    final messageGeneration = generation ?? _identityGeneration;
    if (!await _accepts(data, generation: messageGeneration)) return;
    final type = data['type'] as String?;
    if (kDebugMode) {
      debugPrint(
        'PushNotificationService: routing notification type=$type source=$source',
      );
    }

    switch (type) {
      case 'member_confirmed':
      case 'pair_confirmed':
        await _onMemberConfirmed?.call(data);
        if (!_isGenerationCurrent(messageGeneration)) return;
        if (source == _PushMessageSource.foreground) {
          await _showForegroundNotification(
            data,
            generation: messageGeneration,
          );
        } else if (source != _PushMessageSource.direct) {
          await _handleNotificationTap(data, generation: messageGeneration);
        }
        break;
      case 'sync_available':
        await _onSyncAvailable?.call(data);
        break;
      case 'join_request':
      case 'pair_request':
        await _onJoinRequest?.call(data);
        if (!_isGenerationCurrent(messageGeneration)) return;
        if (source != _PushMessageSource.direct) {
          await _handleNotificationTap(data, generation: messageGeneration);
        }
        break;
      case 'join_request_rejected':
      case 'join_request_cancelled':
      case 'join_request_expired':
        if (_isGenerationCurrent(messageGeneration) &&
            !_joinRequestLifecycleController.isClosed) {
          _joinRequestLifecycleController.add(data);
        }
        break;
      case 'member_left':
        await _onMemberLeft?.call(data);
        break;
      case 'group_dissolved':
        await _onGroupDissolved?.call(data);
        if (!_isGenerationCurrent(messageGeneration)) return;
        if (source != _PushMessageSource.direct) {
          await _handleNotificationTap(data, generation: messageGeneration);
        }
        break;
      case 'group_name_updated':
      case 'owner_transferred':
        await _onGroupSnapshotInvalidated?.call(data);
        break;
      case 'group_key_requested':
        await _onGroupKeyRequested?.call(data);
        break;
      default:
        if (kDebugMode) {
          debugPrint(
            'PushNotificationService: unknown notification type: $type',
          );
        }
    }
  }

  Future<void> _showForegroundNotification(
    Map<String, dynamic> data, {
    required int generation,
  }) async {
    if (!_isGenerationCurrent(generation)) return;
    final l10n = lookupS(_localeProvider());
    final type = data['type'] as String?;

    switch (type) {
      case 'join_request':
      case 'pair_request':
        await _localNotificationClient.show(
          id: 1001,
          title: l10n.familySyncNewRequest,
          body: l10n.familySyncJoinRequestNotificationBody,
          payload: data,
        );
        if (!_isGenerationCurrent(generation)) {
          await _cancelIdentityBoundLocalNotifications();
        }
        break;
      case 'member_confirmed':
      case 'pair_confirmed':
        await _localNotificationClient.show(
          id: 1002,
          title: l10n.familySyncMemberConfirmedNotificationTitle,
          body: l10n.familySyncMemberConfirmedNotificationBody,
          payload: data,
        );
        if (!_isGenerationCurrent(generation)) {
          await _cancelIdentityBoundLocalNotifications();
        }
        break;
    }
  }

  PushNavigationIntent? _intentForMessage(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final groupId = data['groupId'] as String?;

    return switch (type) {
      'join_request' ||
      'pair_request' => PushNavigationIntent.memberApproval(groupId: groupId),
      'member_confirmed' || 'pair_confirmed' =>
        PushNavigationIntent.groupManagement(groupId: groupId),
      'group_dissolved' => PushNavigationIntent.groupDissolved(
        groupId: groupId,
      ),
      _ => null,
    };
  }

  bool _isGenerationCurrent(int generation) {
    return !_identityRevoked && generation == _identityGeneration;
  }

  Future<bool> _accepts(
    Map<String, dynamic> data, {
    required int generation,
  }) async {
    if (!_isGenerationCurrent(generation)) return false;
    try {
      final accepted = await _acceptancePolicy.accepts(
        data,
        boundIdentityGeneration: _boundIdentityGeneration,
      );
      return accepted && _isGenerationCurrent(generation);
    } catch (_) {
      return false;
    }
  }

  Future<void> _cancelPipelineSubscriptions() async {
    final tokenSubscription = _tokenRefreshSubscription;
    final foregroundSubscription = _foregroundSubscription;
    final openedSubscription = _openedAppSubscription;
    _tokenRefreshSubscription = null;
    _foregroundSubscription = null;
    _openedAppSubscription = null;
    await Future.wait<void>([
      if (tokenSubscription != null) tokenSubscription.cancel(),
      if (foregroundSubscription != null) foregroundSubscription.cancel(),
      if (openedSubscription != null) openedSubscription.cancel(),
    ]);
  }

  Future<void> _cancelIdentityBoundLocalNotifications() async {
    final client = _localNotificationClient;
    if (client is IdentityBoundLocalNotificationCleaner) {
      await (client as IdentityBoundLocalNotificationCleaner).cancelAll();
    }
  }
}
