import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/sync/websocket_connection_state.dart';
import 'package:home_pocket/infrastructure/sync/websocket_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MockWebSocketChannel extends Mock implements WebSocketChannel {}

class MockWebSocketSink extends Mock implements WebSocketSink {}

Future<void> expectUnsafeControlMessageIsRejected({
  required WebSocketService service,
  required StreamController<dynamic> incomingController,
  required MockWebSocketSink sink,
  required String raw,
}) async {
  final events = <WebSocketEvent>[];
  service.eventStream.listen(events.add);
  service.connect(
    groupId: 'group-1',
    deviceId: 'device-1',
    signMessage: (_) async => 'mock-signature',
  );

  incomingController.add(raw);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);

  expect(events, isEmpty);
  expect(service.connectionState, WebSocketConnectionState.disconnected);
  verify(() => sink.close(any(), any())).called(1);
}

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

    test('events compare by type and group only', () {
      expect(
        const WebSocketEvent(
          type: WebSocketEventType.groupStatus,
          groupId: 'group-1',
          data: {'members': 1},
        ),
        const WebSocketEvent(
          type: WebSocketEventType.groupStatus,
          groupId: 'group-1',
          data: {'members': 2},
        ),
      );
      expect(
        const WebSocketEvent(
          type: WebSocketEventType.groupStatus,
          groupId: 'group-1',
        ).hashCode,
        const WebSocketEvent(
          type: WebSocketEventType.groupStatus,
          groupId: 'group-1',
        ).hashCode,
      );
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

    test(
      'auth error emits a reconciliation signal before disconnect',
      () async {
        final events = <WebSocketEvent>[];
        service.eventStream.listen(events.add);
        service.connect(
          groupId: 'group-1',
          deviceId: 'device-1',
          signMessage: (msg) async => 'mock-signature',
        );

        incomingController.add(jsonEncode({'type': 'auth_error'}));
        await Future<void>.delayed(Duration.zero);

        expect(
          events,
          contains(
            const WebSocketEvent(
              type: WebSocketEventType.authError,
              groupId: 'group-1',
            ),
          ),
        );
        expect(service.connectionState, WebSocketConnectionState.disconnected);
      },
    );

    test('connect replaces an active connection', () async {
      service.connect(
        groupId: 'group-1',
        deviceId: 'device-1',
        signMessage: (msg) async => 'mock-signature',
      );
      service.connect(
        groupId: 'group-2',
        deviceId: 'device-2',
        signMessage: (msg) async => 'mock-signature',
      );

      verify(() => sink.close(any(), any())).called(greaterThanOrEqualTo(1));
    });

    test(
      'repeated connect for the same identity reuses the active transport',
      () {
        var connectionAttempts = 0;
        final reusedService = WebSocketService(
          baseUrl: 'wss://sync.happypocket.app',
          channelFactory: ({required String url}) {
            connectionAttempts++;
            final channel = MockWebSocketChannel();
            when(
              () => channel.stream,
            ).thenAnswer((_) => incomingController.stream);
            when(() => channel.sink).thenReturn(sink);
            return channel;
          },
        );
        addTearDown(reusedService.dispose);

        reusedService.connect(
          groupId: 'group-1',
          deviceId: 'device-1',
          signMessage: (msg) async => 'mock-signature',
        );
        reusedService.connect(
          groupId: 'group-1',
          deviceId: 'device-1',
          signMessage: (msg) async => 'mock-signature',
        );

        expect(connectionAttempts, 1);
        verifyNever(() => sink.close(any(), any()));
      },
    );

    test('identity change replaces the transport exactly once', () {
      var connectionAttempts = 0;
      final identityService = WebSocketService(
        baseUrl: 'wss://sync.happypocket.app',
        channelFactory: ({required String url}) {
          connectionAttempts++;
          final channel = MockWebSocketChannel();
          when(
            () => channel.stream,
          ).thenAnswer((_) => incomingController.stream);
          when(() => channel.sink).thenReturn(sink);
          return channel;
        },
      );
      addTearDown(identityService.dispose);

      identityService.connect(
        groupId: 'group-1',
        deviceId: 'device-1',
        signMessage: (msg) async => 'mock-signature',
      );
      identityService.connect(
        groupId: 'group-2',
        deviceId: 'device-1',
        signMessage: (msg) async => 'mock-signature',
      );

      expect(connectionAttempts, 2);
      verify(() => sink.close(any(), any())).called(1);
    });

    test('same identity does not replace a scheduled reconnect', () async {
      var connectionAttempts = 0;
      final reconnectingService = WebSocketService(
        baseUrl: 'wss://sync.happypocket.app',
        channelFactory: ({required String url}) {
          connectionAttempts++;
          final channel = MockWebSocketChannel();
          when(
            () => channel.stream,
          ).thenAnswer((_) => incomingController.stream);
          when(() => channel.sink).thenReturn(sink);
          return channel;
        },
      );
      addTearDown(reconnectingService.dispose);

      reconnectingService.connect(
        groupId: 'group-1',
        deviceId: 'device-1',
        signMessage: (msg) async => 'mock-signature',
      );
      incomingController.addError(StateError('socket failed'));
      await Future<void>.delayed(Duration.zero);

      reconnectingService.connect(
        groupId: 'group-1',
        deviceId: 'device-1',
        signMessage: (msg) async => 'mock-signature',
      );

      expect(connectionAttempts, 1);
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

    test(
      'parses terminal join request event with applicant and status',
      () async {
        final events = <WebSocketEvent>[];
        service.eventStream.listen(events.add);

        service.connect(
          groupId: 'group-1',
          deviceId: 'owner',
          signMessage: (msg) async => 'mock-sig',
        );
        incomingController.add(
          jsonEncode({'type': 'auth_success', 'groupId': 'group-1'}),
        );
        await Future<void>.delayed(Duration.zero);

        incomingController.add(
          jsonEncode({
            'type': 'join_request_cancelled',
            'groupId': 'group-1',
            'deviceId': 'applicant',
            'data': {'status': 'cancelled'},
          }),
        );
        await Future<void>.delayed(Duration.zero);

        expect(events.single.type, WebSocketEventType.joinRequestResolved);
        expect(events.single.data, {
          'status': 'cancelled',
          'deviceId': 'applicant',
        });
      },
    );

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

    test('ignores malformed raw messages and handles pong frames', () async {
      service.connect(
        groupId: 'group-1',
        deviceId: 'device-1',
        signMessage: (msg) async => 'mock-sig',
      );

      incomingController.add(42);
      incomingController.add('{not json');
      incomingController.add(jsonEncode({'payload': 'missing-type'}));
      incomingController.add(jsonEncode({'type': 'pong'}));
      await Future<void>.delayed(Duration.zero);

      expect(service.connectionState, WebSocketConnectionState.connecting);
    });

    for (final malformedFrame in <({String name, String raw})>[
      (
        name: 'a non-string type',
        raw: jsonEncode({'type': 1}),
      ),
      (
        name: 'a non-string group id',
        raw: jsonEncode({'type': 'sync_available', 'groupId': 1}),
      ),
      (
        name: 'a non-map data payload',
        raw: jsonEncode({'type': 'group_status', 'data': []}),
      ),
    ]) {
      test(
        'rejects a control frame with ${malformedFrame.name}',
        () async {
          await expectUnsafeControlMessageIsRejected(
            service: service,
            incomingController: incomingController,
            sink: sink,
            raw: malformedFrame.raw,
          );
        },
      );
    }

    test(
      'rejects oversized raw control messages before JSON decoding',
      () async {
        await expectUnsafeControlMessageIsRejected(
          service: service,
          incomingController: incomingController,
          sink: sink,
          raw: jsonEncode({
            'type': 'sync_available',
            'padding': 'x' * (64 * 1024),
          }),
        );
      },
    );

    test('rejects excessively nested control JSON', () async {
      Object nested = 'leaf';
      for (var index = 0; index < 32; index++) {
        nested = {'child': nested};
      }

      await expectUnsafeControlMessageIsRejected(
        service: service,
        incomingController: incomingController,
        sink: sink,
        raw: jsonEncode({'type': 'sync_available', 'data': nested}),
      );
    });

    test('rejects oversized data maps in control messages', () async {
      await expectUnsafeControlMessageIsRejected(
        service: service,
        incomingController: incomingController,
        sink: sink,
        raw: jsonEncode({
          'type': 'group_status',
          'data': {
            for (var index = 0; index < 128; index++) 'field$index': index,
          },
        }),
      );
    });

    test('rejects oversized control-message collections', () async {
      await expectUnsafeControlMessageIsRejected(
        service: service,
        incomingController: incomingController,
        sink: sink,
        raw: jsonEncode({
          'type': 'group_status',
          'data': List<int>.generate(128, (index) => index),
        }),
      );
    });

    test('rejects control messages with oversized field names', () async {
      await expectUnsafeControlMessageIsRejected(
        service: service,
        incomingController: incomingController,
        sink: sink,
        raw: jsonEncode({'type': 'sync_available', 'f' * 512: 'value'}),
      );
    });

    test(
      'rejecting a malformed schema frame does not close its replacement generation',
      () async {
        final controllers = <StreamController<dynamic>>[];
        final sinks = <MockWebSocketSink>[];
        final replacementService = WebSocketService(
          baseUrl: 'wss://sync.happypocket.app',
          channelFactory: ({required String url}) {
            final controller = StreamController<dynamic>.broadcast();
            final localSink = MockWebSocketSink();
            when(() => localSink.close(any(), any())).thenAnswer((_) async {});
            when(() => localSink.add(any())).thenReturn(null);
            final channel = MockWebSocketChannel();
            when(() => channel.stream).thenAnswer((_) => controller.stream);
            when(() => channel.sink).thenReturn(localSink);
            controllers.add(controller);
            sinks.add(localSink);
            return channel;
          },
        );
        addTearDown(() async {
          replacementService.dispose();
          for (final controller in controllers) {
            await controller.close();
          }
        });

        replacementService.connect(
          groupId: 'group-a',
          deviceId: 'device-a',
          signMessage: (_) async => 'signature-a',
        );
        controllers.first.add(jsonEncode({'type': 1}));
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(
          replacementService.connectionState,
          WebSocketConnectionState.disconnected,
        );
        verify(() => sinks.first.close(any(), any())).called(1);

        replacementService.connect(
          groupId: 'group-b',
          deviceId: 'device-b',
          signMessage: (_) async => 'signature-b',
        );
        controllers.last.add(jsonEncode({'type': 'auth_success'}));
        await Future<void>.delayed(Duration.zero);

        expect(
          replacementService.connectionState,
          WebSocketConnectionState.connected,
        );
        verifyNever(() => sinks.last.close(any(), any()));
      },
    );

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

    test('parses group_name_updated invalidation event', () async {
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
          'type': 'group_name_updated',
          'groupId': 'group-1',
          'data': {'groupName': 'New name'},
        }),
      );
      await Future<void>.delayed(Duration.zero);

      expect(events.single.type, WebSocketEventType.groupNameUpdated);
      expect(events.single.groupId, 'group-1');
      expect(events.single.data, {'groupName': 'New name'});
    });

    test('parses owner_transferred control-plane invalidation', () async {
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
          'type': 'owner_transferred',
          'groupId': 'group-1',
          'eventId': 'event-17',
          'revision': 17,
          'occurredAt': '2026-08-01T12:00:00Z',
          'actorDeviceId': 'owner-a',
          'reason': 'transferred',
          'requestId': 'request-9',
          'data': {
            'previousOwnerDeviceId': 'owner-a',
            'newOwnerDeviceId': 'member-b',
            'keyEpoch': 5,
          },
        }),
      );
      await Future<void>.delayed(Duration.zero);

      expect(events.single.type, WebSocketEventType.ownerTransferred);
      expect(events.single.data?['newOwnerDeviceId'], 'member-b');
      expect(events.single.data?['keyEpoch'], 5);
      expect(events.single.data?['eventId'], 'event-17');
      expect(events.single.data?['revision'], 17);
      expect(events.single.data?['occurredAt'], '2026-08-01T12:00:00Z');
      expect(events.single.data?['actorDeviceId'], 'owner-a');
      expect(events.single.data?['reason'], 'transferred');
      expect(events.single.data?['requestId'], 'request-9');
      expect(events.single.data?['controlEventType'], 'owner_transferred');
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

    test('member_left merges terminal device id with rotation data', () async {
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
          'type': 'member_left',
          'groupId': 'group-1',
          'deviceId': 'device-2',
          'data': {'reason': 'removed', 'keyEpoch': 3},
        }),
      );
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.single.type, WebSocketEventType.memberLeft);
      expect(events.single.data, {
        'reason': 'removed',
        'keyEpoch': 3,
        'deviceId': 'device-2',
      });
    });

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

    test('parses authenticated group_key_requested invalidation', () async {
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
          'type': 'group_key_requested',
          'groupId': 'group-1',
          'data': {
            'requestId': 'request-1',
            'keyEpoch': 4,
            'expiresAt': '2026-08-01T01:10:00Z',
          },
        }),
      );
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.single.type, WebSocketEventType.groupKeyRequested);
      expect(events.single.groupId, 'group-1');
      expect(events.single.data?['requestId'], 'request-1');
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

    test('stream errors disconnect and schedule reconnect', () async {
      final states = <WebSocketConnectionState>[];
      service.connectionStateStream.listen(states.add);
      service.connect(
        groupId: 'group-1',
        deviceId: 'device-1',
        signMessage: (msg) async => 'mock-sig',
      );

      incomingController.addError(StateError('socket failed'));
      await Future<void>.delayed(Duration.zero);

      expect(states, contains(WebSocketConnectionState.disconnected));
    });

    test('heartbeat sends ping and reconnects on pong timeout', () {
      fakeAsync((async) {
        final controller = StreamController<dynamic>.broadcast(sync: true);
        final localSink = MockWebSocketSink();
        when(() => localSink.close(any(), any())).thenAnswer((_) async {});
        when(() => localSink.add(any())).thenReturn(null);
        final localService = WebSocketService(
          baseUrl: 'wss://sync.happypocket.app',
          channelFactory: ({required String url}) {
            final channel = MockWebSocketChannel();
            when(() => channel.stream).thenAnswer((_) => controller.stream);
            when(() => channel.sink).thenReturn(localSink);
            return channel;
          },
        );
        localService.connect(
          groupId: 'group-1',
          deviceId: 'device-1',
          signMessage: (msg) async => 'mock-sig',
        );
        async.flushMicrotasks();
        controller.add(jsonEncode({'type': 'auth_success'}));
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 30));
        verify(() => localSink.add(jsonEncode({'type': 'ping'}))).called(1);

        async.elapse(const Duration(seconds: 45));

        localService.dispose();
        unawaited(controller.close());
      });
    });

    testWidgets('lifecycle observer schedules and clears background timer', (
      tester,
    ) async {
      service.startLifecycleObservation();
      service.connect(
        groupId: 'group-1',
        deviceId: 'device-1',
        signMessage: (msg) async => 'mock-signature',
      );
      incomingController.add(
        jsonEncode({'type': 'auth_success', 'groupId': 'group-1'}),
      );
      await tester.pump();

      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      service.stopLifecycleObservation();

      expect(service.connectionState, WebSocketConnectionState.connected);
      service.disconnect();
    });

    testWidgets('lifecycle observation is a single active registration', (
      tester,
    ) async {
      service.startLifecycleObservation();
      service.startLifecycleObservation();

      expect(service.isLifecycleObservationActive, isTrue);

      service.stopLifecycleObservation();
      service.stopLifecycleObservation();

      expect(service.isLifecycleObservationActive, isFalse);
    });

    testWidgets('dispose stops its one lifecycle registration', (tester) async {
      service.startLifecycleObservation();

      service.dispose();

      expect(service.isLifecycleObservationActive, isFalse);
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

    test('signer failures close the current connection and retry', () {
      fakeAsync((async) {
        final controller = StreamController<dynamic>.broadcast(sync: true);
        final localSink = MockWebSocketSink();
        var connectionAttempts = 0;
        when(() => localSink.close(any(), any())).thenAnswer((_) async {});
        when(() => localSink.add(any())).thenReturn(null);
        final localService = WebSocketService(
          baseUrl: 'wss://sync.happypocket.app',
          channelFactory: ({required String url}) {
            connectionAttempts++;
            final channel = MockWebSocketChannel();
            when(() => channel.stream).thenAnswer((_) => controller.stream);
            when(() => channel.sink).thenReturn(localSink);
            return channel;
          },
        );
        addTearDown(() {
          localService.dispose();
          unawaited(controller.close());
        });

        localService.connect(
          groupId: 'group-1',
          deviceId: 'device-1',
          signMessage: (_) => Future<String>.error(StateError('sign failed')),
        );
        async.flushMicrotasks();

        expect(
          localService.connectionState,
          WebSocketConnectionState.disconnected,
        );
        verify(() => localSink.close(any(), any())).called(1);

        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();

        expect(connectionAttempts, 2);
      });
    });

    test('auth sink failures close the current connection and retry', () {
      fakeAsync((async) {
        final controller = StreamController<dynamic>.broadcast(sync: true);
        final localSink = MockWebSocketSink();
        var connectionAttempts = 0;
        when(() => localSink.close(any(), any())).thenAnswer((_) async {});
        when(() => localSink.add(any())).thenThrow(StateError('sink failed'));
        final localService = WebSocketService(
          baseUrl: 'wss://sync.happypocket.app',
          channelFactory: ({required String url}) {
            connectionAttempts++;
            final channel = MockWebSocketChannel();
            when(() => channel.stream).thenAnswer((_) => controller.stream);
            when(() => channel.sink).thenReturn(localSink);
            return channel;
          },
        );
        addTearDown(() {
          localService.dispose();
          unawaited(controller.close());
        });

        localService.connect(
          groupId: 'group-1',
          deviceId: 'device-1',
          signMessage: (_) async => 'signature',
        );
        async.flushMicrotasks();

        expect(
          localService.connectionState,
          WebSocketConnectionState.disconnected,
        );
        verify(() => localSink.close(any(), any())).called(1);

        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();

        expect(connectionAttempts, 2);
      });
    });

    test(
      'stale authentication never writes to a replacement channel',
      () async {
        final delayedSignature = Completer<String>();
        final sinks = <MockWebSocketSink>[];
        final controllers = <StreamController<dynamic>>[];
        final replacementService = WebSocketService(
          baseUrl: 'wss://sync.happypocket.app',
          channelFactory: ({required String url}) {
            final controller = StreamController<dynamic>.broadcast();
            final localSink = MockWebSocketSink();
            when(() => localSink.close(any(), any())).thenAnswer((_) async {});
            when(() => localSink.add(any())).thenReturn(null);
            final channel = MockWebSocketChannel();
            when(() => channel.stream).thenAnswer((_) => controller.stream);
            when(() => channel.sink).thenReturn(localSink);
            controllers.add(controller);
            sinks.add(localSink);
            return channel;
          },
        );
        addTearDown(() async {
          replacementService.dispose();
          for (final controller in controllers) {
            await controller.close();
          }
        });

        replacementService.connect(
          groupId: 'group-a',
          deviceId: 'device-a',
          signMessage: (_) => delayedSignature.future,
        );
        replacementService.connect(
          groupId: 'group-b',
          deviceId: 'device-b',
          signMessage: (_) async => 'signature-b',
        );
        await Future<void>.delayed(Duration.zero);

        delayedSignature.complete('signature-a');
        await Future<void>.delayed(Duration.zero);

        verifyNever(() => sinks[0].add(any()));
        verify(() => sinks[1].add(any())).called(1);
      },
    );

    test('a stale signer failure cannot disconnect a replacement connection',
        () async {
      final delayedSignature = Completer<String>();
      final sinks = <MockWebSocketSink>[];
      final controllers = <StreamController<dynamic>>[];
      final replacementService = WebSocketService(
        baseUrl: 'wss://sync.happypocket.app',
        channelFactory: ({required String url}) {
          final controller = StreamController<dynamic>.broadcast();
          final localSink = MockWebSocketSink();
          when(() => localSink.close(any(), any())).thenAnswer((_) async {});
          when(() => localSink.add(any())).thenReturn(null);
          final channel = MockWebSocketChannel();
          when(() => channel.stream).thenAnswer((_) => controller.stream);
          when(() => channel.sink).thenReturn(localSink);
          controllers.add(controller);
          sinks.add(localSink);
          return channel;
        },
      );
      addTearDown(() async {
        replacementService.dispose();
        for (final controller in controllers) {
          await controller.close();
        }
      });

      replacementService.connect(
        groupId: 'group-a',
        deviceId: 'device-a',
        signMessage: (_) => delayedSignature.future,
      );
      replacementService.connect(
        groupId: 'group-b',
        deviceId: 'device-b',
        signMessage: (_) async => 'signature-b',
      );
      controllers[1].add(jsonEncode({'type': 'auth_success'}));
      await Future<void>.delayed(Duration.zero);

      delayedSignature.completeError(StateError('old sign failed'));
      await Future<void>.delayed(Duration.zero);

      expect(
        replacementService.connectionState,
        WebSocketConnectionState.connected,
      );
      verifyNever(() => sinks[1].close(any(), any()));
    });

    test('disconnect invalidates pending authentication', () async {
      final delayedSignature = Completer<String>();
      service.connect(
        groupId: 'group-1',
        deviceId: 'device-1',
        signMessage: (_) => delayedSignature.future,
      );

      service.disconnect();
      delayedSignature.complete('signature');
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => sink.add(any()));
    });

    test(
      'a stale stream error cannot disconnect the replacement connection',
      () async {
        final controllers = <StreamController<dynamic>>[];
        final replacementService = WebSocketService(
          baseUrl: 'wss://sync.happypocket.app',
          channelFactory: ({required String url}) {
            final controller = StreamController<dynamic>.broadcast(sync: true);
            final localSink = MockWebSocketSink();
            when(() => localSink.close(any(), any())).thenAnswer((_) async {});
            when(() => localSink.add(any())).thenReturn(null);
            final channel = MockWebSocketChannel();
            when(() => channel.stream).thenAnswer((_) => controller.stream);
            when(() => channel.sink).thenReturn(localSink);
            controllers.add(controller);
            return channel;
          },
        );
        addTearDown(() async {
          replacementService.dispose();
          for (final controller in controllers) {
            await controller.close();
          }
        });

        replacementService.connect(
          groupId: 'group-a',
          deviceId: 'device-a',
          signMessage: (_) async => 'signature-a',
        );
        replacementService.connect(
          groupId: 'group-b',
          deviceId: 'device-b',
          signMessage: (_) async => 'signature-b',
        );
        controllers[1].add(jsonEncode({'type': 'auth_success'}));

        controllers[0].addError(StateError('stale socket failed'));

        expect(
          replacementService.connectionState,
          WebSocketConnectionState.connected,
        );
      },
    );
  });
}
