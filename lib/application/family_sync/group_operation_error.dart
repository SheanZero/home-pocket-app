import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../infrastructure/sync/relay_api_client.dart';

enum GroupOperationErrorKind { general, membershipConflict, networkUnavailable }

const networkUnavailableErrorMessage = 'Network unavailable';

bool isSingleGroupConflict(RelayApiException error) {
  return error.isConflict &&
      (error.code == 'device_already_grouped' ||
          error.code == 'group_membership_conflict');
}

/// Returns whether an operation failed before receiving a relay response.
///
/// Presentation code must never inspect exception strings. The string fallback
/// only handles wrapped platform errors whose public type is hidden by the HTTP
/// client, while keeping all technical details below the UI boundary.
bool isNetworkUnavailableError(Object error) {
  if (error is SocketException ||
      error is http.ClientException ||
      error is TimeoutException) {
    return true;
  }

  final message = error.toString().toLowerCase();
  return message.contains('socketexception') ||
      message.contains('failed host lookup') ||
      message.contains('network is unreachable') ||
      message.contains('connection refused') ||
      message.contains('connection reset') ||
      message.contains('connection closed') ||
      message.contains('timed out');
}
