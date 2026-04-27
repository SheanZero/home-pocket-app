import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockRequestSigner extends Mock implements RequestSigner {}

class MockKeyManager extends Mock implements KeyManager {}

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockRequestSigner signer;
  late MockHttpClient httpClient;
  late RelayApiClient apiClient;

  setUp(() {
    signer = MockRequestSigner();
    httpClient = MockHttpClient();
    apiClient = RelayApiClient(
      baseUrl: 'https://example.com/api/v1',
      signer: signer,
      httpClient: httpClient,
    );

    when(
      () => signer.signRequest(
        method: any(named: 'method'),
        path: any(named: 'path'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => 'Ed25519 signed');
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
          'payload': 'encrypted',
          'vectorClock': {'device-a': 3},
          'operationCount': 4,
          'chunkIndex': 0,
          'totalChunks': 1,
        }),
      ),
    ).called(1);
  });

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
      _stubGet(httpClient, '/sync/pull', {'messages': <Object>[]});
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
