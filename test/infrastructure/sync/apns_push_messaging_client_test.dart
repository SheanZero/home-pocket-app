import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/sync/apns_push_messaging_client.dart';

class FakeApnsPushBridge implements ApnsPushBridge {
  FakeApnsPushBridge({this.initialToken, this.initialMessage});

  final String? initialToken;
  final Map<String, dynamic>? initialMessage;
  bool permissionRequested = false;

  final _tokenController = StreamController<String>.broadcast();
  final _foregroundController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _openedController = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Future<String?> getToken() async => initialToken;

  @override
  Future<Map<String, dynamic>?> getInitialMessage() async => initialMessage;

  @override
  Stream<Map<String, dynamic>> get onForegroundMessage =>
      _foregroundController.stream;

  @override
  Stream<Map<String, dynamic>> get onMessageOpenedApp =>
      _openedController.stream;

  @override
  Stream<String> get onTokenRefresh => _tokenController.stream;

  @override
  Future<void> requestPermission() async {
    permissionRequested = true;
  }

  Future<void> emitToken(String token) async {
    _tokenController.add(token);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> emitForeground(Map<String, dynamic> data) async {
    _foregroundController.add(data);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> emitOpened(Map<String, dynamic> data) async {
    _openedController.add(data);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> dispose() async {
    await _tokenController.close();
    await _foregroundController.close();
    await _openedController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'delegates permission, token, and initial message access to APNs bridge',
    () async {
      final bridge = FakeApnsPushBridge(
        initialToken: 'apns-token',
        initialMessage: {'type': 'join_request', 'groupId': 'group-1'},
      );
      final client = ApnsPushMessagingClient(bridge: bridge);

      await client.requestPermission();

      expect(bridge.permissionRequested, isTrue);
      expect(await client.getToken(), 'apns-token');
      expect(await client.getInitialMessage(), {
        'type': 'join_request',
        'groupId': 'group-1',
      });

      await bridge.dispose();
    },
  );

  test('forwards APNs token and notification event streams', () async {
    final bridge = FakeApnsPushBridge();
    final client = ApnsPushMessagingClient(bridge: bridge);

    final tokens = <String>[];
    final foregroundEvents = <Map<String, dynamic>>[];
    final openedEvents = <Map<String, dynamic>>[];

    final tokenSub = client.onTokenRefresh.listen(tokens.add);
    final foregroundSub = client.onForegroundMessage.listen(
      foregroundEvents.add,
    );
    final openedSub = client.onMessageOpenedApp.listen(openedEvents.add);

    await bridge.emitToken('apns-token-2');
    await bridge.emitForeground({'type': 'join_request', 'groupId': 'group-2'});
    await bridge.emitOpened({'type': 'member_confirmed', 'groupId': 'group-2'});

    expect(tokens, ['apns-token-2']);
    expect(foregroundEvents, [
      {'type': 'join_request', 'groupId': 'group-2'},
    ]);
    expect(openedEvents, [
      {'type': 'member_confirmed', 'groupId': 'group-2'},
    ]);

    await tokenSub.cancel();
    await foregroundSub.cancel();
    await openedSub.cancel();
    await bridge.dispose();
  });
}
