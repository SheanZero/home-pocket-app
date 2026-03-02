import 'dart:convert';

import 'package:crypto/crypto.dart' as hash_lib;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../crypto/services/key_manager.dart';

/// Signs HTTP requests with Ed25519 device key for server authentication.
///
/// Authorization header format:
/// `Ed25519 <deviceId>:<timestamp>:<base64Signature>`
///
/// Signature message format:
/// `<method>:<path>:<timestamp>:<SHA256(body)>`
class RequestSigner {
  RequestSigner({required KeyManager keyManager}) : _keyManager = keyManager;

  final KeyManager _keyManager;

  /// Generate signed Authorization header.
  Future<String> signRequest({
    required String method,
    required String path,
    required String body,
  }) async {
    final deviceId = await _keyManager.getDeviceId();
    if (deviceId == null) {
      throw StateError('Device ID not found');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // SHA-256 hash of request body
    final bodyHash = hash_lib.sha256.convert(utf8.encode(body));
    final message = '$method:$path:$timestamp:$bodyHash';

    // Ed25519 sign
    final signature = await _keyManager.signData(utf8.encode(message));

    return 'Ed25519 $deviceId:$timestamp:${base64Encode(signature.bytes)}';
  }
}

/// HTTP client for the sync relay server.
///
/// Wraps all server API calls with Ed25519 authentication.
/// Server URL selection:
/// - Release: https://sync.happypocket.app/api/v1
/// - Debug: https://dev-sync.happypocket.app/api/v1
/// - Override: `--dart-define=SYNC_SERVER_URL=...`
class RelayApiClient {
  RelayApiClient({
    required this.baseUrl,
    required RequestSigner signer,
    http.Client? httpClient,
  }) : _signer = signer,
       _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final RequestSigner _signer;
  final http.Client _httpClient;

  static String get defaultBaseUrl {
    const url = String.fromEnvironment('SYNC_SERVER_URL', defaultValue: '');
    if (url.isNotEmpty) return url;
    return kReleaseMode
        ? 'https://sync.happypocket.app/api/v1'
        : 'https://dev-sync.happypocket.app/api/v1';
  }

  // ── Device ──

  /// Register device with server (unauthenticated, idempotent).
  Future<Map<String, dynamic>> registerDevice({
    required String deviceId,
    required String publicKey,
    required String deviceName,
    required String platform,
    String? pushToken,
  }) async {
    final body = jsonEncode({
      'deviceId': deviceId,
      'publicKey': publicKey,
      'deviceName': deviceName,
      'platform': platform,
      ...?pushToken == null ? null : {'pushToken': pushToken},
    });

    final response = await _post(
      '/device/register',
      body,
      authenticated: false,
    );
    return _parseResponse(response);
  }

  /// Update push token (authenticated).
  Future<void> updatePushToken({
    required String pushToken,
    required String pushPlatform,
  }) async {
    final body = jsonEncode({
      'pushToken': pushToken,
      'pushPlatform': pushPlatform,
    });

    final response = await _put('/device/push-token', body);
    _parseResponse(response);
  }

  // ── Groups ──

  Future<Map<String, dynamic>> createGroup({required String bookId}) async {
    final response = await _post(
      '/group/create',
      jsonEncode({'bookId': bookId}),
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> joinGroup({required String inviteCode}) async {
    final response = await _post(
      '/group/join',
      jsonEncode({'inviteCode': inviteCode}),
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> confirmMember({
    required String groupId,
    required String deviceId,
  }) async {
    final response = await _post(
      '/group/confirm',
      jsonEncode({'groupId': groupId, 'deviceId': deviceId}),
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> getGroupStatus(String groupId) async {
    final response = await _get('/group/$groupId/status');
    return _parseResponse(response);
  }

  Future<void> deactivateGroup(String groupId) async {
    final response = await _delete('/group/$groupId');
    _parseResponse(response);
  }

  Future<void> leaveGroup(String groupId) async {
    final response = await _post('/group/$groupId/leave', '{}');
    _parseResponse(response);
  }

  Future<Map<String, dynamic>> removeMember({
    required String groupId,
    required String deviceId,
  }) async {
    final response = await _post(
      '/group/$groupId/remove',
      jsonEncode({'deviceId': deviceId}),
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> regenerateInvite(String groupId) async {
    final response = await _post('/group/$groupId/invite', '{}');
    return _parseResponse(response);
  }

  // ── Sync ──

  /// Push encrypted sync data to a group.
  ///
  /// Returns: {recipientCount}
  Future<Map<String, dynamic>> pushSync({
    required String groupId,
    required String payload,
    required Map<String, int> vectorClock,
    required int operationCount,
    int chunkIndex = 0,
    int totalChunks = 1,
  }) async {
    final body = jsonEncode({
      'groupId': groupId,
      'payload': payload,
      'vectorClock': vectorClock,
      'operationCount': operationCount,
      'chunkIndex': chunkIndex,
      'totalChunks': totalChunks,
    });

    final response = await _post('/sync/push', body);
    return _parseResponse(response);
  }

  /// Pull pending sync messages since cursor.
  ///
  /// Returns: {messages: [...], hasMore: bool}
  Future<Map<String, dynamic>> pullSync({int? since}) async {
    final query = since != null ? '?since=$since' : '';
    final response = await _get('/sync/pull$query');
    return _parseResponse(response);
  }

  /// ACK received messages (triggers server-side deletion).
  Future<Map<String, dynamic>> ackSync({
    required List<String> messageIds,
  }) async {
    final body = jsonEncode({'messageIds': messageIds});
    final response = await _post('/sync/ack', body);
    return _parseResponse(response);
  }

  // ── Private HTTP helpers ──

  Future<http.Response> _get(String path, {bool authenticated = true}) async {
    final url = Uri.parse('$baseUrl$path');
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (authenticated) {
      headers['Authorization'] = await _signer.signRequest(
        method: 'GET',
        path: path,
        body: '',
      );
    }

    return _httpClient.get(url, headers: headers);
  }

  Future<http.Response> _post(
    String path,
    String body, {
    bool authenticated = true,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (authenticated) {
      headers['Authorization'] = await _signer.signRequest(
        method: 'POST',
        path: path,
        body: body,
      );
    }

    return _httpClient.post(url, headers: headers, body: body);
  }

  Future<http.Response> _put(
    String path,
    String body, {
    bool authenticated = true,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (authenticated) {
      headers['Authorization'] = await _signer.signRequest(
        method: 'PUT',
        path: path,
        body: body,
      );
    }

    return _httpClient.put(url, headers: headers, body: body);
  }

  Future<http.Response> _delete(
    String path, {
    bool authenticated = true,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (authenticated) {
      headers['Authorization'] = await _signer.signRequest(
        method: 'DELETE',
        path: path,
        body: '',
      );
    }

    return _httpClient.delete(url, headers: headers);
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final errorBody = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

    throw RelayApiException(
      statusCode: response.statusCode,
      message: errorBody['error'] as String? ?? 'Unknown error',
      code: errorBody['code'] as String?,
    );
  }
}

/// Exception thrown when relay server returns an error response.
class RelayApiException implements Exception {
  const RelayApiException({
    required this.statusCode,
    required this.message,
    this.code,
  });

  final int statusCode;
  final String message;
  final String? code;

  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isForbidden => statusCode == 403;
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'RelayApiException($statusCode): $message';
}
