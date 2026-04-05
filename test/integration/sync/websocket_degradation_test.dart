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
  test('WebSocket disconnect triggers state change for polling fallback',
      () async {
    final incomingController = StreamController<dynamic>.broadcast();
    final sink = MockWebSocketSink();
    when(() => sink.close(any(), any())).thenAnswer((_) async {});
    when(() => sink.add(any())).thenReturn(null);

    final service = WebSocketService(
      baseUrl: 'wss://test.example.com',
      channelFactory: ({required String url}) {
        final channel = MockWebSocketChannel();
        when(() => channel.stream)
            .thenAnswer((_) => incomingController.stream);
        when(() => channel.sink).thenReturn(sink);
        return channel;
      },
    );

    final states = <WebSocketConnectionState>[];
    service.connectionStateStream.listen(states.add);

    // Connect and authenticate
    service.connect(
      groupId: 'group-1',
      deviceId: 'device-1',
      signMessage: (msg) async => 'sig',
    );
    incomingController.add(
      jsonEncode({'type': 'auth_success', 'groupId': 'group-1'}),
    );
    await Future<void>.delayed(Duration.zero);

    expect(service.connectionState, WebSocketConnectionState.connected);

    // Simulate disconnect
    await incomingController.close();
    await Future<void>.delayed(Duration.zero);

    expect(service.connectionState, WebSocketConnectionState.disconnected);
    expect(states, contains(WebSocketConnectionState.disconnected));

    service.dispose();
  });

  test('WebSocket event is forwarded to eventStream', () async {
    final incomingController = StreamController<dynamic>.broadcast();
    final sink = MockWebSocketSink();
    when(() => sink.close(any(), any())).thenAnswer((_) async {});
    when(() => sink.add(any())).thenReturn(null);

    final service = WebSocketService(
      baseUrl: 'wss://test.example.com',
      channelFactory: ({required String url}) {
        final channel = MockWebSocketChannel();
        when(() => channel.stream)
            .thenAnswer((_) => incomingController.stream);
        when(() => channel.sink).thenReturn(sink);
        return channel;
      },
    );

    final events = <WebSocketEvent>[];
    service.eventStream.listen(events.add);

    service.connect(
      groupId: 'group-1',
      deviceId: 'device-1',
      signMessage: (msg) async => 'sig',
    );
    incomingController.add(
      jsonEncode({'type': 'auth_success', 'groupId': 'group-1'}),
    );
    await Future<void>.delayed(Duration.zero);

    incomingController.add(jsonEncode({
      'type': 'member_confirmed',
      'groupId': 'group-1',
    }));
    await Future<void>.delayed(Duration.zero);

    expect(events, hasLength(1));
    expect(events.first.type, WebSocketEventType.memberConfirmed);

    service.dispose();
    await incomingController.close();
  });
}
