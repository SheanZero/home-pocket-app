import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/group_operation_error.dart';
import 'package:http/http.dart' as http;

void main() {
  group('isNetworkUnavailableError', () {
    test('recognizes transport and timeout failures', () {
      expect(
        isNetworkUnavailableError(const SocketException('Network is down')),
        isTrue,
      );
      expect(
        isNetworkUnavailableError(
          http.ClientException('Failed host lookup: sync.example.com'),
        ),
        isTrue,
      );
      expect(
        isNetworkUnavailableError(TimeoutException('request timed out')),
        isTrue,
      );
    });

    test('does not classify unrelated failures as network unavailable', () {
      expect(isNetworkUnavailableError(StateError('invalid state')), isFalse);
    });
  });
}
