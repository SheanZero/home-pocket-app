import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/network/network_status_checker.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockRequestSigner extends Mock implements RequestSigner {}

class MockKeyManager extends Mock implements KeyManager {}

class MockHttpClient extends Mock implements http.Client {}

class FakeBaseRequest extends Fake implements http.BaseRequest {}

class FakeNetworkStatusChecker implements NetworkStatusChecker {
  FakeNetworkStatusChecker(this.isAvailable);

  bool isAvailable;

  @override
  Future<bool> get isNetworkAvailable async => isAvailable;
}

void main() {
  late MockRequestSigner signer;
  late MockHttpClient httpClient;
  late FakeNetworkStatusChecker networkStatusChecker;
  late RelayApiClient apiClient;

  setUpAll(() {
    registerFallbackValue(FakeBaseRequest());
  });

  setUp(() {
    signer = MockRequestSigner();
    httpClient = MockHttpClient();
    networkStatusChecker = FakeNetworkStatusChecker(true);
    apiClient = RelayApiClient(
      baseUrl: 'https://example.com/api/v1',
      signer: signer,
      httpClient: httpClient,
      networkStatusChecker: networkStatusChecker,
    );

    when(
      () => signer.signRequest(
        method: any(named: 'method'),
        path: any(named: 'path'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => 'Ed25519 signed');
  });

  test('fails before HTTP when no network interface is available', () async {
    networkStatusChecker.isAvailable = false;

    await expectLater(
      apiClient.checkGroup(),
      throwsA(isA<NetworkUnavailableException>()),
    );
    verifyNever(
      () => httpClient.get(
        Uri.parse('https://example.com/api/v1/group/check'),
        headers: any(named: 'headers'),
      ),
    );
  });

  test('normalizes socket failures from the HTTP client', () async {
    when(
      () => httpClient.get(
        Uri.parse('https://example.com/api/v1/group/check'),
        headers: any(named: 'headers'),
      ),
    ).thenThrow(const SocketException('Failed host lookup: example.com'));

    await expectLater(
      apiClient.checkGroup(),
      throwsA(isA<NetworkUnavailableException>()),
    );
  });

  test('createGroup posts to /group/create', () async {
    when(
      () => httpClient.post(
        Uri.parse('https://example.com/api/v1/group/create'),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => http.Response(
        jsonEncode({
          'groupId': 'group-1',
          'inviteCode': 'ABC123',
          'expiresAt': 1,
        }),
        200,
      ),
    );

    final response = await apiClient.createGroup();

    expect(response['groupId'], 'group-1');
    verify(
      () => httpClient.post(
        Uri.parse('https://example.com/api/v1/group/create'),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).called(1);
  });

  test('checkGroup gets current group membership state', () async {
    when(
      () => httpClient.get(
        Uri.parse('https://example.com/api/v1/group/check'),
        headers: any(named: 'headers'),
      ),
    ).thenAnswer(
      (_) async => http.Response(
        jsonEncode({
          'groupExisted': true,
          'groupId': '550e8400-e29b-41d4-a716-446655440000',
        }),
        200,
      ),
    );

    final response = await apiClient.checkGroup();

    expect(response['groupExisted'], true);
    expect(response['groupId'], '550e8400-e29b-41d4-a716-446655440000');
    verify(
      () => httpClient.get(
        Uri.parse('https://example.com/api/v1/group/check'),
        headers: any(named: 'headers'),
      ),
    ).called(1);
  });

  test('control event requests clamp the signed page limit to 100', () async {
    _stubGet(httpClient, '/group/group-1/events?afterRevision=7&limit=100', {
      'events': <Object>[],
      'hasMore': false,
      'nextRevision': 7,
    });

    final response = await apiClient.getGroupControlEvents(
      groupId: 'group-1',
      afterRevision: 7,
      limit: 500,
    );

    expect(response['nextRevision'], 7);
  });

  test(
    'checkGroup returns false when server reports no active group',
    () async {
      when(
        () => httpClient.get(
          Uri.parse('https://example.com/api/v1/group/check'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode({'groupExisted': false}), 200),
      );

      final response = await apiClient.checkGroup();

      expect(response['groupExisted'], false);
      expect(response['groupId'], isNull);
    },
  );

  test('join request lifecycle uses dedicated authenticated routes', () async {
    when(
      () => httpClient.get(
        Uri.parse('https://example.com/api/v1/group/group-1/join-request'),
        headers: any(named: 'headers'),
      ),
    ).thenAnswer(
      (_) async => http.Response(jsonEncode({'status': 'pending'}), 200),
    );
    when(
      () => httpClient.post(
        Uri.parse('https://example.com/api/v1/group/group-1/reject-join'),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => http.Response(jsonEncode({'status': 'rejected'}), 200),
    );
    when(
      () => httpClient.post(
        Uri.parse('https://example.com/api/v1/group/group-1/cancel-join'),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => http.Response(jsonEncode({'status': 'cancelled'}), 200),
    );

    expect(
      (await apiClient.getJoinRequestStatus('group-1'))['status'],
      'pending',
    );
    expect(
      (await apiClient.rejectJoinRequest(
        groupId: 'group-1',
        deviceId: 'applicant',
      ))['status'],
      'rejected',
    );
    expect(
      (await apiClient.cancelJoinRequest('group-1'))['status'],
      'cancelled',
    );

    final rejectBody =
        verify(
              () => httpClient.post(
                Uri.parse(
                  'https://example.com/api/v1/group/group-1/reject-join',
                ),
                headers: any(named: 'headers'),
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as String;
    expect(jsonDecode(rejectBody), {'deviceId': 'applicant'});
  });

  test('pushSync sends group payload without targetDeviceId', () async {
    when(
      () => httpClient.post(
        Uri.parse('https://example.com/api/v1/sync/push'),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => http.Response(jsonEncode({'recipientCount': 2}), 200),
    );

    final response = await apiClient.pushSync(
      groupId: 'group-1',
      syncId: 'sync-stable-1',
      payload: 'encrypted',
      vectorClock: const {'device-a': 3},
      operationCount: 4,
    );

    expect(response['recipientCount'], 2);
    verify(
      () => httpClient.post(
        Uri.parse('https://example.com/api/v1/sync/push'),
        headers: any(named: 'headers'),
        body: jsonEncode({
          'groupId': 'group-1',
          'syncId': 'sync-stable-1',
          'payload': 'encrypted',
          'vectorClock': {'device-a': 3},
          'operationCount': 4,
          'keyEpoch': 1,
          'chunkIndex': 0,
          'totalChunks': 1,
        }),
      ),
    ).called(1);
  });

  test(
    'group key recovery uses request ledger and targeted push routes',
    () async {
      _stubPost(httpClient, '/group/group-1/request-key', {
        'requestId': 'request-1',
        'keyEpoch': 4,
      });
      _stubGet(httpClient, '/group/group-1/key-requests', {
        'requests': <Object>[],
      });
      _stubPost(httpClient, '/sync/push-key', {'recipientCount': 1});

      expect(
        await apiClient.requestGroupKey(
          groupId: 'group-1',
          keyEpoch: 0,
          forceNotify: true,
        ),
        containsPair('requestId', 'request-1'),
      );
      expect(
        await apiClient.getPendingGroupKeyRequests('group-1'),
        contains('requests'),
      );
      expect(
        await apiClient.pushGroupKeyResponse(
          groupId: 'group-1',
          requestId: 'request-1',
          targetDeviceId: 'member-1',
          payload: 'sealed',
          keyEpoch: 4,
          syncId: 'sync-1',
        ),
        containsPair('recipientCount', 1),
      );

      final requestBody =
          verify(
                () => httpClient.post(
                  Uri.parse(
                    'https://example.com/api/v1/group/group-1/request-key',
                  ),
                  headers: any(named: 'headers'),
                  body: captureAny(named: 'body'),
                ),
              ).captured.single
              as String;
      final responseBody =
          verify(
                () => httpClient.post(
                  Uri.parse('https://example.com/api/v1/sync/push-key'),
                  headers: any(named: 'headers'),
                  body: captureAny(named: 'body'),
                ),
              ).captured.single
              as String;
      expect(jsonDecode(requestBody), {'keyEpoch': 0, 'forceNotify': true});
      expect(jsonDecode(responseBody), {
        'groupId': 'group-1',
        'requestId': 'request-1',
        'targetDeviceId': 'member-1',
        'payload': 'sealed',
        'keyEpoch': 4,
        'syncId': 'sync-1',
      });
    },
  );

  test('default URLs derive REST and WebSocket endpoints', () {
    expect(
      RelayApiClient.defaultBaseUrl,
      'https://sync.happypocket.app/api/v1',
    );
    expect(RelayApiClient.wsBaseUrl, 'wss://sync.happypocket.app');
  });

  test('RequestSigner signs canonical request payload', () async {
    final keyManager = MockKeyManager();
    when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'device-1');
    when(() => keyManager.signData(any())).thenAnswer(
      (_) async => Signature([
        1,
        2,
        3,
      ], publicKey: SimplePublicKey([4, 5, 6], type: KeyPairType.ed25519)),
    );

    final header = await RequestSigner(keyManager: keyManager).signRequest(
      method: 'POST',
      path: '/api/v1/sync/push',
      body: '{"ok":true}',
    );

    expect(header, startsWith('Ed25519 device-1:'));
    expect(header, endsWith(':AQID'));
    verify(() => keyManager.signData(any())).called(1);
  });

  test('RequestSigner fails when device id is missing', () async {
    final keyManager = MockKeyManager();
    when(() => keyManager.getDeviceId()).thenAnswer((_) async => null);

    expect(
      () => RequestSigner(
        keyManager: keyManager,
      ).signRequest(method: 'GET', path: '/api/v1/group/check', body: ''),
      throwsStateError,
    );
  });

  test('group management methods use expected HTTP verbs and paths', () async {
    _stubPost(httpClient, '/group/join', {'groupId': 'group-1'});
    _stubPost(httpClient, '/group/group-1/confirm-join', {'confirmed': true});
    _stubPut(httpClient, '/group/group-1/name', {'groupName': 'Family'});
    _stubPost(httpClient, '/group/confirm', {'ok': true});
    _stubGet(httpClient, '/group/group-1/status', {'status': 'active'});
    _stubDelete(httpClient, '/group/group-1', {});
    _stubPost(httpClient, '/group/group-1/leave', {});
    _stubPost(httpClient, '/group/group-1/remove', {'removed': true});
    _stubPost(httpClient, '/group/group-1/invite', {'inviteCode': 'NEWCODE'});

    expect(
      await apiClient.joinGroup(inviteCode: 'ABC123'),
      containsPair('groupId', 'group-1'),
    );
    expect(
      await apiClient.confirmJoin(groupId: 'group-1'),
      containsPair('confirmed', true),
    );
    expect(
      await apiClient.renameGroup(groupId: 'group-1', groupName: 'Family'),
      containsPair('groupName', 'Family'),
    );
    expect(
      await apiClient.confirmMember(groupId: 'group-1', deviceId: 'device-2'),
      containsPair('ok', true),
    );
    expect(
      await apiClient.getGroupStatus('group-1'),
      containsPair('status', 'active'),
    );
    await apiClient.deactivateGroup('group-1');
    await apiClient.leaveGroup('group-1');
    expect(
      await apiClient.removeMember(groupId: 'group-1', deviceId: 'device-2'),
      containsPair('removed', true),
    );
    expect(
      await apiClient.regenerateInvite('group-1'),
      containsPair('inviteCode', 'NEWCODE'),
    );
  });

  test(
    'device and sync methods cover unauthenticated, put, pull, and ack',
    () async {
      _stubPost(httpClient, '/device/register', {'deviceId': 'device-1'});
      _stubPut(httpClient, '/device/push-token', {});
      _stubPull(httpClient, {'messages': <Object>[]});
      _stubPost(httpClient, '/sync/ack', {'acked': true});

      expect(
        await apiClient.registerDevice(
          deviceId: 'device-1',
          publicKey: 'pub',
          deviceName: 'Phone',
          platform: 'ios',
        ),
        containsPair('deviceId', 'device-1'),
      );
      await apiClient.updatePushToken(pushToken: 'push', pushPlatform: 'fcm');
      expect(await apiClient.pullSync(), contains('messages'));
      expect(
        await apiClient.ackSync(messageIds: ['m1']),
        containsPair('acked', true),
      );

      verifyNever(
        () => signer.signRequest(
          method: 'POST',
          path: '/api/v1/device/register',
          body: any(named: 'body'),
        ),
      );
    },
  );

  test(
    'rejects an oversized pull response from Content-Length before reading it',
    () async {
      var streamListened = false;
      when(() => httpClient.send(any())).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream<List<int>>.multi((controller) {
            streamListened = true;
            controller.close();
          }),
          200,
          contentLength: RelayApiClient.maxPullResponseBytes + 1,
        ),
      );

      await expectLater(
        apiClient.pullSync(),
        throwsA(
          isA<RelayApiException>()
              .having((error) => error.statusCode, 'statusCode', 413)
              .having(
                (error) => error.message,
                'message',
                contains('response exceeds'),
              ),
        ),
      );

      expect(streamListened, isFalse);
    },
  );

  test('rejects a chunked oversized pull response while streaming', () async {
    final firstChunk = List<int>.filled(
      RelayApiClient.maxPullResponseBytes - 16,
      0x20,
    );
    final overflowChunk = List<int>.filled(17, 0x20);
    when(() => httpClient.send(any())).thenAnswer(
      (_) async => http.StreamedResponse(
        Stream<List<int>>.fromIterable([firstChunk, overflowChunk]),
        200,
      ),
    );

    await expectLater(
      apiClient.pullSync(),
      throwsA(
        isA<RelayApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          413,
        ),
      ),
    );
  });

  test(
    'error responses parse error, message, fallback, and malformed bodies',
    () async {
      _stubGet(httpClient, '/group/error-json/status', {
        'error': 'bad',
        'code': 'E_BAD',
      }, status: 400);
      _stubGet(httpClient, '/group/error-message/status', {
        'message': 'missing',
      }, status: 404);
      when(
        () => httpClient.get(
          Uri.parse('https://example.com/api/v1/group/error-text/status'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response('not json', 500));
      when(
        () => httpClient.get(
          Uri.parse('https://example.com/api/v1/group/error-empty/status'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response('', 403));

      await expectLater(
        apiClient.getGroupStatus('error-json'),
        throwsA(
          isA<RelayApiException>()
              .having((e) => e.message, 'message', 'bad')
              .having((e) => e.code, 'code', 'E_BAD')
              .having((e) => e.isConflict, 'isConflict', false),
        ),
      );
      await expectLater(
        apiClient.getGroupStatus('error-message'),
        throwsA(
          isA<RelayApiException>().having((e) => e.isNotFound, '404', true),
        ),
      );
      await expectLater(
        apiClient.getGroupStatus('error-text'),
        throwsA(
          isA<RelayApiException>()
              .having((e) => e.isUnauthorized, '401', false)
              .having((e) => e.toString(), 'text', contains('500')),
        ),
      );
      await expectLater(
        apiClient.getGroupStatus('error-empty'),
        throwsA(
          isA<RelayApiException>().having((e) => e.isForbidden, '403', true),
        ),
      );
    },
  );
}

void _stubGet(
  MockHttpClient httpClient,
  String path,
  Map<String, dynamic> body, {
  int status = 200,
}) {
  when(
    () => httpClient.get(
      Uri.parse('https://example.com/api/v1$path'),
      headers: any(named: 'headers'),
    ),
  ).thenAnswer((_) async => http.Response(jsonEncode(body), status));
}

void _stubPull(MockHttpClient httpClient, Map<String, dynamic> body) {
  when(() => httpClient.send(any())).thenAnswer(
    (_) async => http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(jsonEncode(body))),
      200,
    ),
  );
}

void _stubPost(
  MockHttpClient httpClient,
  String path,
  Map<String, dynamic> body, {
  int status = 200,
}) {
  when(
    () => httpClient.post(
      Uri.parse('https://example.com/api/v1$path'),
      headers: any(named: 'headers'),
      body: any(named: 'body'),
    ),
  ).thenAnswer((_) async => http.Response(jsonEncode(body), status));
}

void _stubPut(
  MockHttpClient httpClient,
  String path,
  Map<String, dynamic> body, {
  int status = 200,
}) {
  when(
    () => httpClient.put(
      Uri.parse('https://example.com/api/v1$path'),
      headers: any(named: 'headers'),
      body: any(named: 'body'),
    ),
  ).thenAnswer((_) async => http.Response(jsonEncode(body), status));
}

void _stubDelete(
  MockHttpClient httpClient,
  String path,
  Map<String, dynamic> body, {
  int status = 200,
}) {
  when(
    () => httpClient.delete(
      Uri.parse('https://example.com/api/v1$path'),
      headers: any(named: 'headers'),
    ),
  ).thenAnswer((_) async => http.Response(jsonEncode(body), status));
}
