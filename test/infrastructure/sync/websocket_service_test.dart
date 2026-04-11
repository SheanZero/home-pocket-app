import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/sync/websocket_connection_state.dart';
import 'package:home_pocket/infrastructure/sync/websocket_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MockWebSocketChannel extends Mock implements WebSocketChannel {}

class MockWebSocketSink extends Mock implements WebSocketSink {}

void main() {
  group('WebSocketService', () {
    late WebSocketService service;
    late StreamController<dynamic> incomingController;
    late MockWebSocketSink sink;

    setUp(() {
      incomingController = StreamController<dynamic>.broadcast();
      sink = MockWebSocketSink();
      when(() => sink.close(any(), any())).thenAnswer((_) async {});
      when(() => sink.add(any())).thenReturn(null);

      service = WebSocketService(
        baseUrl: 'wss://sync.happypocket.app',
        channelFactory: ({required String url}) {
          final channel = MockWebSocketChannel();
          when(
            () => channel.stream,
          ).thenAnswer((_) => incomingController.stream);
          when(() => channel.sink).thenReturn(sink);
          return channel;
        },
      );
    });

    tearDown(() async {
      service.dispose();
      await incomingController.close();
    });

    test('initial state is disconnected', () {
      expect(service.connectionState, WebSocketConnectionState.disconnected);
    });

    test('connect transitions to connecting then connected', () async {
      final states = <WebSocketConnectionState>[];
      service.connectionStateStream.listen(states.add);

      service.connect(
        groupId: 'group-1',
        deviceId: 'device-1',
        signMessage: (msg) async => 'mock-signature',
      );

      incomingController.add(
        jsonEncode({'type': 'auth_success', 'groupId': 'group-1'}),
      );

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(states, contains(WebSocketConnectionState.connecting));
      expect(service.connectionState, WebSocketConnectionState.connected);
    });

    test('disconnect transitions to disconnected', () async {
      service.connect(
        groupId: 'group-1',
        deviceId: 'device-1',
        signMessage: (msg) async => 'mock-signature',
      );
      incomingController.add(
        jsonEncode({'type': 'auth_success', 'groupId': 'group-1'}),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      service.disconnect();

      expect(service.connectionState, WebSocketConnectionState.disconnected);
    });

    test('parses member_confirmed event from WebSocket', () async {
      final events = <WebSocketEvent>[];
      service.eventStream.listen(events.add);

      service.connect(
        groupId: 'group-1',
        deviceId: 'device-1',
        signMessage: (msg) async => 'mock-sig',
      );
      incomingController.add(
        jsonEncode({'type': 'auth_success', 'groupId': 'group-1'}),
      );
      await Future<void>.delayed(Duration.zero);

      incomingController.add(
        jsonEncode({
          'type': 'member_confirmed',
          'groupId': 'group-1',
          'deviceId': 'device-2',
          'timestamp': '2026-04-04T12:00:00Z',
        }),
      );
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.first.type, WebSocketEventType.memberConfirmed);
      expect(events.first.groupId, 'group-1');
    });

    test('parses join_request event from WebSocket', () async {
      final events = <WebSocketEvent>[];
      service.eventStream.listen(events.add);

      service.connect(
        groupId: 'group-1',
        deviceId: 'device-1',
        signMessage: (msg) async => 'mock-sig',
      );
      incomingController.add(
        jsonEncode({'type': 'auth_success', 'groupId': 'group-1'}),
      );
      await Future<void>.delayed(Duration.zero);

      incomingController.add(
        jsonEncode({
          'type': 'join_request',
          'groupId': 'group-1',
          'deviceId': 'device-3',
          'timestamp': '2026-04-04T12:00:00Z',
        }),
      );
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.first.type, WebSocketEventType.joinRequest);
    });

    test('ignores unknown event types', () async {
      final events = <WebSocketEvent>[];
      service.eventStream.listen(events.add);

      service.connect(
        groupId: 'group-1',
        deviceId: 'device-1',
        signMessage: (msg) async => 'mock-sig',
      );
      incomingController.add(
        jsonEncode({'type': 'auth_success', 'groupId': 'group-1'}),
      );
      await Future<void>.delayed(Duration.zero);

      incomingController.add(
        jsonEncode({'type': 'unknown_event', 'groupId': 'group-1'}),
      );
      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty);
    });

    test('parses group_status event with data payload', () async {
      final events = <WebSocketEvent>[];
      service.eventStream.listen(events.add);

      service.connect(
        groupId: 'group-1',
        deviceId: 'device-1',
        signMessage: (msg) async => 'mock-sig',
      );
      incomingController.add(
        jsonEncode({'type': 'auth_success', 'groupId': 'group-1'}),
      );
      await Future<void>.delayed(Duration.zero);

      incomingController.add(
        jsonEncode({
          'type': 'group_status',
          'groupId': 'group-1',
          'data': {
            'memberCount': 3,
            'pendingRequests': 1,
            'groupName': 'My Family',
          },
        }),
      );
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.first.type, WebSocketEventType.groupStatus);
      expect(events.first.groupId, 'group-1');
      expect(events.first.data, isNotNull);
      expect(events.first.data!['memberCount'], 3);
      expect(events.first.data!['groupName'], 'My Family');
    });

    test(
      'existing events carry null data when no data field present',
      () async {
        final events = <WebSocketEvent>[];
        service.eventStream.listen(events.add);

        service.connect(
          groupId: 'group-1',
          deviceId: 'device-1',
          signMessage: (msg) async => 'mock-sig',
        );
        incomingController.add(
          jsonEncode({'type': 'auth_success', 'groupId': 'group-1'}),
        );
        await Future<void>.delayed(Duration.zero);

        incomingController.add(
          jsonEncode({
            'type': 'member_confirmed',
            'groupId': 'group-1',
            'deviceId': 'device-2',
            'timestamp': '2026-04-04T12:00:00Z',
          }),
        );
        await Future<void>.delayed(Duration.zero);

        expect(events, hasLength(1));
        expect(events.first.type, WebSocketEventType.memberConfirmed);
        expect(events.first.data, isNull);
      },
    );

    test('parses sync_available event from WebSocket', () async {
      final events = <WebSocketEvent>[];
      service.eventStream.listen(events.add);

      service.connect(
        groupId: 'group-1',
        deviceId: 'device-1',
        signMessage: (msg) async => 'mock-sig',
      );
      incomingController.add(
        jsonEncode({'type': 'auth_success', 'groupId': 'group-1'}),
      );
      await Future<void>.delayed(Duration.zero);

      incomingController.add(
        jsonEncode({
          'type': 'sync_available',
          'groupId': 'group-1',
          'deviceId': 'device-2',
          'timestamp': '2026-04-05T12:00:00Z',
        }),
      );
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.first.type, WebSocketEventType.syncAvailable);
      expect(events.first.groupId, 'group-1');
    });

    test('auth_error disconnects without reconnect', () async {
      service.connect(
        groupId: 'group-1',
        deviceId: 'device-1',
        signMessage: (msg) async => 'mock-sig',
      );

      incomingController.add(
        jsonEncode({'type': 'auth_error', 'message': 'invalid signature'}),
      );
      await Future<void>.delayed(Duration.zero);

      expect(service.connectionState, WebSocketConnectionState.disconnected);
    });

    test('sends auth message on connect', () async {
      service.connect(
        groupId: 'group-1',
        deviceId: 'device-1',
        signMessage: (msg) async => 'mock-signature',
      );

      await Future<void>.delayed(Duration.zero);

      final captured = verify(() => sink.add(captureAny())).captured;
      expect(captured, isNotEmpty);

      final authMessage =
          jsonDecode(captured.first as String) as Map<String, dynamic>;
      expect(authMessage['deviceId'], 'device-1');
      expect(authMessage['protocolVersion'], 1);
      expect(authMessage, contains('timestamp'));
      expect(authMessage, contains('signature'));
    });
  });
}
