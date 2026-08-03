import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

/// Lightweight preflight for operations that require a live network path.
///
/// Connectivity only reports whether the device has a network interface; it
/// cannot prove that the Internet is reachable or that the OS allows this app
/// to use mobile data. Callers must therefore still normalize transport
/// failures from the actual request.
abstract interface class NetworkStatusChecker {
  Future<bool> get isNetworkAvailable;
}

class ConnectivityNetworkStatusChecker implements NetworkStatusChecker {
  ConnectivityNetworkStatusChecker({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> get isNetworkAvailable async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((result) => result != ConnectivityResult.none);
    } catch (_) {
      // A failed preflight must not block a request that could still succeed.
      // The real transport remains the authoritative availability check.
      return true;
    }
  }
}

/// Sanitized transport failure shared by all relay operations.
///
/// The cause is deliberately not exposed so presentation code cannot leak host
/// names, socket details, or platform error strings to the user.
class NetworkUnavailableException implements Exception {
  const NetworkUnavailableException();

  @override
  String toString() => 'NetworkUnavailableException';
}

/// Recognizes failures that mean the request never received a relay response.
bool isNetworkUnavailableError(Object error) {
  if (error is NetworkUnavailableException ||
      error is SocketException ||
      error is http.ClientException ||
      error is TimeoutException) {
    return true;
  }

  // Some platform/client wrappers hide the public exception type. Keep this
  // fallback below the presentation boundary and never display the value.
  final message = error.toString().toLowerCase();
  return message.contains('socketexception') ||
      message.contains('failed host lookup') ||
      message.contains('network is unreachable') ||
      message.contains('connection refused') ||
      message.contains('connection reset') ||
      message.contains('connection closed') ||
      message.contains('timed out');
}
