import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/notify_member_approval_use_case.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/websocket_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockWebSocketService extends Mock implements WebSocketService {}

class _MockKeyManager extends Mock implements KeyManager {}

void main() {
  late _MockWebSocketService mockWsService;
  late _MockKeyManager mockKeyManager;
  late NotifyMemberApprovalUseCase useCase;

  setUp(() {
    mockWsService = _MockWebSocketService();
    mockKeyManager = _MockKeyManager();
    useCase = NotifyMemberApprovalUseCase(
      wsService: mockWsService,
      keyManager: mockKeyManager,
    );
  });

  group('NotifyMemberApprovalUseCase', () {
    test(
      'connect delegates to WebSocketService with groupId and deviceId',
      () async {
        when(
          () => mockKeyManager.getDeviceId(),
        ).thenAnswer((_) async => 'device-123');
        when(
          () => mockWsService.connect(
            groupId: any(named: 'groupId'),
            deviceId: any(named: 'deviceId'),
            signMessage: any(named: 'signMessage'),
          ),
        ).thenReturn(null);
        when(() => mockWsService.startLifecycleObservation()).thenReturn(null);

        await useCase.connectWebSocket(groupId: 'group-abc');

        verify(
          () => mockWsService.connect(
            groupId: 'group-abc',
            deviceId: 'device-123',
            signMessage: any(named: 'signMessage'),
          ),
        ).called(1);
        verify(() => mockWsService.startLifecycleObservation()).called(1);
      },
    );

    test('disconnect delegates to WebSocketService', () {
      when(() => mockWsService.stopLifecycleObservation()).thenReturn(null);
      when(() => mockWsService.disconnect()).thenReturn(null);

      useCase.disconnectWebSocket();

      verify(() => mockWsService.stopLifecycleObservation()).called(1);
      verify(() => mockWsService.disconnect()).called(1);
    });

    test('listenForJoinRequests returns WebSocketService eventStream', () {
      final fakeStream = const Stream<WebSocketEvent>.empty();
      when(() => mockWsService.eventStream).thenAnswer((_) => fakeStream);

      final result = useCase.listenForJoinRequests();

      expect(result, same(fakeStream));
    });

    test('connectWebSocket handles missing deviceId gracefully', () async {
      when(() => mockKeyManager.getDeviceId()).thenAnswer((_) async => null);

      // Should not throw even when deviceId is null
      await useCase.connectWebSocket(groupId: 'group-abc');

      verifyNever(
        () => mockWsService.connect(
          groupId: any(named: 'groupId'),
          deviceId: any(named: 'deviceId'),
          signMessage: any(named: 'signMessage'),
        ),
      );
    });

    test('signMessage callback signs and base64-encodes the message', () async {
      Future<String>? capturedCallback;

      when(() => mockKeyManager.getDeviceId()).thenAnswer((_) async => 'dev-1');
      when(
        () => mockWsService.connect(
          groupId: any(named: 'groupId'),
          deviceId: any(named: 'deviceId'),
          signMessage: any(named: 'signMessage'),
        ),
      ).thenAnswer((invocation) {
        capturedCallback =
            (invocation.namedArguments[#signMessage]
                    as Future<String> Function(String))
                .call('test-payload');
      });
      when(() => mockWsService.startLifecycleObservation()).thenReturn(null);
      when(() => mockKeyManager.signData(any())).thenAnswer(
        (_) async => Signature([
          1,
          2,
          3,
        ], publicKey: SimplePublicKey([], type: KeyPairType.ed25519)),
      );

      await useCase.connectWebSocket(groupId: 'group-abc');
      final result = await capturedCallback!;

      expect(result, isA<String>());
      expect(result.isNotEmpty, isTrue);
    });
  });
}
