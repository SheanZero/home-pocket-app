import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as hash_lib;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../crypto/services/key_manager.dart';
import '../network/network_status_checker.dart';
import 'e2ee_service.dart';

/// A bounded page returned by the relay pull endpoint.
///
/// The HTTP client intentionally continues to expose JSON maps for backwards
/// compatibility with existing callers. Pull consumers should parse through
/// this model so the server's pagination contract is validated in one place.
class RelayPullResponse {
  RelayPullResponse({required this.messages, required this.hasMore});

  static const int maxMessagesPerPage = 100;

  final List<Map<String, dynamic>> messages;
  final bool hasMore;

  factory RelayPullResponse.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'];
    if (rawMessages is! List) {
      throw const FormatException('Relay pull response is missing messages');
    }
    if (rawMessages.length > maxMessagesPerPage) {
      throw const FormatException(
        'Relay pull response exceeds the 100-message page limit',
      );
    }

    final messages = <Map<String, dynamic>>[];
    for (final rawMessage in rawMessages) {
      if (rawMessage is! Map) {
        throw const FormatException('Relay pull message must be an object');
      }
      final message = Map<String, dynamic>.from(rawMessage);
      final payload = message['payload'];
      if (payload is! String) {
        throw const FormatException(
          'Relay pull message payload must be a string',
        );
      }
      try {
        E2EEService.validateInboundPayloadSize(payload);
      } on ArgumentError {
        throw const FormatException(
          'Relay pull message payload exceeds limits',
        );
      }
      messages.add(message);
    }

    final rawHasMore = json['hasMore'];
    if (rawHasMore != null && rawHasMore is! bool) {
      throw const FormatException('Relay pull hasMore must be a boolean');
    }
    return RelayPullResponse(
      messages: List.unmodifiable(messages),
      // Older relay fixtures predate pagination. A missing flag represents a
      // complete single page so those responses remain safely consumable.
      hasMore: rawHasMore as bool? ?? false,
    );
  }
}

/// Signs HTTP requests with Ed25519 device key for server authentication.
///
/// Authorization header format:
/// `Ed25519 <deviceId>:<timestamp>:<base64Signature>`
///
/// Signature message format:
/// `<method>:<path>:<timestamp>:<SHA256(body)>`
///
/// **IMPORTANT:** `path` must be the full URL path including the API version
/// prefix (e.g., `/api/v1/group/create`), not just the relative path.
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

    // SHA-256 hash of request body (lowercase hex)
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
/// - Default: https://sync.happypocket.app/api/v1
/// - Override: `--dart-define=SYNC_SERVER_URL=...`
class RelayApiClient {
  RelayApiClient({
    required this.baseUrl,
    required RequestSigner signer,
    http.Client? httpClient,
    NetworkStatusChecker? networkStatusChecker,
    Duration requestTimeout = const Duration(seconds: 15),
  }) : _signer = signer,
       _httpClient = httpClient ?? http.Client(),
       _networkStatusChecker =
           networkStatusChecker ?? ConnectivityNetworkStatusChecker(),
       _requestTimeout = requestTimeout;

  final String baseUrl;
  final RequestSigner _signer;
  final http.Client _httpClient;
  final NetworkStatusChecker _networkStatusChecker;
  final Duration _requestTimeout;

  /// The relay accepts a maximum 2 MiB API body. A pull response is limited to
  /// one maximum-size opaque message plus bounded envelope metadata until the
  /// server enforces an equivalent page budget.
  static const int maxPullResponseBytes =
      E2EEService.maxInboundPayloadBytes + 64 * 1024;

  static String get defaultBaseUrl {
    const url = String.fromEnvironment('SYNC_SERVER_URL', defaultValue: '');
    if (url.isNotEmpty) return url;
    return 'https://sync.happypocket.app/api/v1';
  }

  /// WebSocket base URL derived from the REST base URL.
  ///
  /// Transforms `https://sync.happypocket.app/api/v1`
  /// into `wss://sync.happypocket.app`.
  static String get wsBaseUrl {
    final uri = Uri.parse(defaultBaseUrl);
    final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return '$wsScheme://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  }

  // ── Device ──

  /// Register device with server (unauthenticated, idempotent).
  Future<Map<String, dynamic>> registerDevice({
    required String deviceId,
    required String publicKey,
    required String deviceName,
    required String platform,
  }) async {
    final body = jsonEncode({
      'deviceId': deviceId,
      'publicKey': publicKey,
      'deviceName': deviceName,
      'platform': platform,
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

  Future<Map<String, dynamic>> createGroup({
    String? groupName,
    String? displayName,
    String? avatarEmoji,
    String? avatarImageHash,
  }) async {
    final body = jsonEncode({
      'groupName': ?groupName,
      'displayName': ?displayName,
      'avatarEmoji': ?avatarEmoji,
      'avatarImageHash': ?avatarImageHash,
    });

    final response = await _post('/group/create', body);
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> joinGroup({
    required String inviteCode,
    String? displayName,
    String? avatarEmoji,
    String? avatarImageHash,
  }) async {
    final response = await _post(
      '/group/join',
      jsonEncode({
        'inviteCode': inviteCode,
        'displayName': ?displayName,
        'avatarEmoji': ?avatarEmoji,
        'avatarImageHash': ?avatarImageHash,
      }),
    );
    return _parseResponse(response);
  }

  /// Joiner confirms join after previewing group info.
  Future<Map<String, dynamic>> confirmJoin({
    required String groupId,
    String? displayName,
    String? avatarEmoji,
    String? avatarImageHash,
  }) async {
    final response = await _post(
      '/group/$groupId/confirm-join',
      jsonEncode({
        'confirmed': true,
        'displayName': ?displayName,
        'avatarEmoji': ?avatarEmoji,
        'avatarImageHash': ?avatarImageHash,
      }),
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> getJoinRequestStatus(String groupId) async {
    final response = await _get('/group/$groupId/join-request');
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> rejectJoinRequest({
    required String groupId,
    required String deviceId,
  }) async {
    final response = await _post(
      '/group/$groupId/reject-join',
      jsonEncode({'deviceId': deviceId}),
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> cancelJoinRequest(String groupId) async {
    final response = await _post('/group/$groupId/cancel-join', '{}');
    return _parseResponse(response);
  }

  /// Owner renames group. Only owner-authenticated requests succeed.
  Future<Map<String, dynamic>> renameGroup({
    required String groupId,
    required String groupName,
  }) async {
    final response = await _put(
      '/group/$groupId/name',
      jsonEncode({'groupName': groupName}),
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> checkGroup() async {
    final response = await _get('/group/check');
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

  Future<Map<String, dynamic>> getGroupControlEvents({
    required String groupId,
    required int afterRevision,
    int limit = 100,
  }) async {
    final boundedLimit = limit.clamp(1, 100);
    final response = await _get(
      '/group/$groupId/events?afterRevision=$afterRevision&limit=$boundedLimit',
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> requestGroupKey({
    required String groupId,
    required int keyEpoch,
    bool forceNotify = false,
  }) async {
    final response = await _post(
      '/group/$groupId/request-key',
      jsonEncode({'keyEpoch': keyEpoch, 'forceNotify': forceNotify}),
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> getPendingGroupKeyRequests(
    String groupId,
  ) async {
    final response = await _get('/group/$groupId/key-requests');
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

  Future<Map<String, dynamic>> leaveGroupWithRotation(
    String groupId, {
    required String requestId,
    required int expectedKeyEpoch,
  }) async {
    final response = await _post(
      '/group/$groupId/leave',
      jsonEncode({
        'requestId': requestId,
        'expectedKeyEpoch': expectedKeyEpoch,
      }),
    );
    return _parseResponse(response);
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

  Future<Map<String, dynamic>> removeMemberWithPreparedRotation({
    required String groupId,
    required String deviceId,
    required String requestId,
    required int expectedKeyEpoch,
    required int newKeyEpoch,
    required List<Map<String, dynamic>> envelopes,
  }) async {
    final response = await _post(
      '/group/$groupId/remove',
      jsonEncode({
        'deviceId': deviceId,
        'requestId': requestId,
        'expectedKeyEpoch': expectedKeyEpoch,
        'newKeyEpoch': newKeyEpoch,
        'envelopes': envelopes,
      }),
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> completeMembershipRotation({
    required String groupId,
    required String requestId,
    required int expectedKeyEpoch,
    required int newKeyEpoch,
    required List<Map<String, dynamic>> envelopes,
  }) async {
    final response = await _post(
      '/group/$groupId/complete-rotation',
      jsonEncode({
        'requestId': requestId,
        'expectedKeyEpoch': expectedKeyEpoch,
        'newKeyEpoch': newKeyEpoch,
        'envelopes': envelopes,
      }),
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> transferOwner({
    required String groupId,
    required String requestId,
    required String targetDeviceId,
    required int expectedKeyEpoch,
    required int newKeyEpoch,
    required List<Map<String, dynamic>> envelopes,
  }) async {
    final response = await _post(
      '/group/$groupId/transfer-owner',
      jsonEncode({
        'requestId': requestId,
        'targetDeviceId': targetDeviceId,
        'expectedKeyEpoch': expectedKeyEpoch,
        'newKeyEpoch': newKeyEpoch,
        'envelopes': envelopes,
      }),
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
    required String syncId,
    required String payload,
    required Map<String, int> vectorClock,
    required int operationCount,
    int keyEpoch = 1,
    int chunkIndex = 0,
    int totalChunks = 1,
  }) async {
    final body = jsonEncode({
      'groupId': groupId,
      'syncId': syncId,
      'payload': payload,
      'vectorClock': vectorClock,
      'operationCount': operationCount,
      'keyEpoch': keyEpoch,
      'chunkIndex': chunkIndex,
      'totalChunks': totalChunks,
    });

    final response = await _post('/sync/push', body);
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> pushGroupKeyResponse({
    required String groupId,
    required String requestId,
    required String targetDeviceId,
    required String payload,
    required int keyEpoch,
    required String syncId,
  }) async {
    final response = await _post(
      '/sync/push-key',
      jsonEncode({
        'groupId': groupId,
        'requestId': requestId,
        'targetDeviceId': targetDeviceId,
        'payload': payload,
        'keyEpoch': keyEpoch,
        'syncId': syncId,
      }),
    );
    return _parseResponse(response);
  }

  /// Pull pending sync messages since cursor.
  ///
  /// Returns: {messages: SyncMessage[]}
  Future<Map<String, dynamic>> pullSync() async {
    const path = '/sync/pull';
    _logRequest('GET', path, '');
    final url = Uri.parse('$baseUrl$path');
    final headers = <String, String>{'Content-Type': 'application/json'};
    headers['Authorization'] = await _signer.signRequest(
      method: 'GET',
      path: _signingPath(path),
      body: '',
    );

    final request = http.Request('GET', url)..headers.addAll(headers);
    final response = await _sendStreamedHttp(() => _httpClient.send(request));
    _logResponse('GET', path, response);
    final body = await _readBoundedPullResponse(response);
    return _parseResponseBody(response.statusCode, body);
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

  /// Build the full URL path for signing (includes /api/v1 prefix).
  String _signingPath(String path) {
    final uri = Uri.parse(baseUrl);
    return '${uri.path}$path';
  }

  void _logRequest(String method, String path, String body) {
    if (kDebugMode) {
      debugPrint('[RelayAPI] request prepared: $method');
    }
  }

  void _logResponse(String method, String path, http.BaseResponse response) {
    if (kDebugMode) {
      debugPrint(
        '[RelayAPI] response received: $method ${response.statusCode}',
      );
    }
  }

  Future<http.Response> _get(String path, {bool authenticated = true}) async {
    _logRequest('GET', path, '');
    final url = Uri.parse('$baseUrl$path');
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (authenticated) {
      // Sign with path only (no query string) — server uses r.URL.Path
      final pathOnly = path.split('?').first;
      headers['Authorization'] = await _signer.signRequest(
        method: 'GET',
        path: _signingPath(pathOnly),
        body: '',
      );
    }

    final response = await _sendHttp(
      () => _httpClient.get(url, headers: headers),
    );
    _logResponse('GET', path, response);
    return response;
  }

  Future<http.Response> _post(
    String path,
    String body, {
    bool authenticated = true,
  }) async {
    _logRequest('POST', path, body);
    final url = Uri.parse('$baseUrl$path');
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (authenticated) {
      headers['Authorization'] = await _signer.signRequest(
        method: 'POST',
        path: _signingPath(path),
        body: body,
      );
    }

    final response = await _sendHttp(
      () => _httpClient.post(url, headers: headers, body: body),
    );
    _logResponse('POST', path, response);
    return response;
  }

  Future<http.Response> _put(
    String path,
    String body, {
    bool authenticated = true,
  }) async {
    _logRequest('PUT', path, body);
    final url = Uri.parse('$baseUrl$path');
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (authenticated) {
      headers['Authorization'] = await _signer.signRequest(
        method: 'PUT',
        path: _signingPath(path),
        body: body,
      );
    }

    final response = await _sendHttp(
      () => _httpClient.put(url, headers: headers, body: body),
    );
    _logResponse('PUT', path, response);
    return response;
  }

  Future<http.Response> _delete(
    String path, {
    bool authenticated = true,
  }) async {
    _logRequest('DELETE', path, '');
    final url = Uri.parse('$baseUrl$path');
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (authenticated) {
      headers['Authorization'] = await _signer.signRequest(
        method: 'DELETE',
        path: _signingPath(path),
        body: '',
      );
    }

    final response = await _sendHttp(
      () => _httpClient.delete(url, headers: headers),
    );
    _logResponse('DELETE', path, response);
    return response;
  }

  Future<http.Response> _sendHttp(
    Future<http.Response> Function() request,
  ) async {
    if (!await _networkStatusChecker.isNetworkAvailable) {
      throw const NetworkUnavailableException();
    }

    try {
      return await request().timeout(_requestTimeout);
    } catch (error) {
      if (isNetworkUnavailableError(error)) {
        throw const NetworkUnavailableException();
      }
      rethrow;
    }
  }

  Future<http.StreamedResponse> _sendStreamedHttp(
    Future<http.StreamedResponse> Function() request,
  ) async {
    if (!await _networkStatusChecker.isNetworkAvailable) {
      throw const NetworkUnavailableException();
    }

    try {
      return await request().timeout(_requestTimeout);
    } catch (error) {
      if (isNetworkUnavailableError(error)) {
        throw const NetworkUnavailableException();
      }
      rethrow;
    }
  }

  Future<String> _readBoundedPullResponse(
    http.StreamedResponse response,
  ) async {
    final contentLength = response.contentLength;
    if (contentLength != null && contentLength > maxPullResponseBytes) {
      throw const RelayApiException(
        statusCode: 413,
        message: 'Relay pull response exceeds the client byte limit',
      );
    }

    final bytes = BytesBuilder(copy: false);
    var receivedBytes = 0;
    try {
      await for (final chunk in response.stream.timeout(_requestTimeout)) {
        if (chunk.length > maxPullResponseBytes - receivedBytes) {
          throw const RelayApiException(
            statusCode: 413,
            message: 'Relay pull response exceeds the client byte limit',
          );
        }
        receivedBytes += chunk.length;
        bytes.add(chunk);
      }
    } catch (error) {
      if (isNetworkUnavailableError(error)) {
        throw const NetworkUnavailableException();
      }
      rethrow;
    }
    return utf8.decode(bytes.takeBytes());
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    return _parseResponseBody(response.statusCode, response.body);
  }

  Map<String, dynamic> _parseResponseBody(int statusCode, String body) {
    if (statusCode >= 200 && statusCode < 300) {
      if (body.isEmpty) return {};
      return jsonDecode(body) as Map<String, dynamic>;
    }

    Map<String, dynamic> errorBody;
    try {
      errorBody = body.isNotEmpty
          ? jsonDecode(body) as Map<String, dynamic>
          : <String, dynamic>{};
    } catch (_) {
      errorBody = <String, dynamic>{};
    }

    // Server may use "error" or "message" key for the error description.
    final errorMessage =
        (errorBody['error'] ?? errorBody['message'])?.toString() ??
        'HTTP $statusCode';

    throw RelayApiException(
      statusCode: statusCode,
      message: errorMessage,
      code: errorBody['code']?.toString(),
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
