import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockRequestSigner extends Mock implements RequestSigner {}

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

  test('createGroup posts bookId to /group/create', () async {
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

    final response = await apiClient.createGroup(bookId: 'book-1');

    expect(response['groupId'], 'group-1');
    verify(
      () => httpClient.post(
        Uri.parse('https://example.com/api/v1/group/create'),
        headers: any(named: 'headers'),
        body: jsonEncode({'bookId': 'book-1'}),
      ),
    ).called(1);
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
}
