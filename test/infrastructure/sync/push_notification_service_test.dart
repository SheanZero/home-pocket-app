import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/sync/push_notification_service.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:mocktail/mocktail.dart';

class MockRelayApiClient extends Mock implements RelayApiClient {}

void main() {
  late PushNotificationService service;
  late int memberConfirmedCalls;
  late int syncAvailableCalls;

  setUp(() {
    service = PushNotificationService(apiClient: MockRelayApiClient());
    memberConfirmedCalls = 0;
    syncAvailableCalls = 0;
    service.registerHandlers(
      onMemberConfirmed: (_) async {
        memberConfirmedCalls++;
      },
      onSyncAvailable: (_) async {
        syncAvailableCalls++;
      },
    );
  });

  test('dispatches member_confirmed and sync_available', () async {
    await service.handleMessage({'type': 'member_confirmed'});
    await service.handleMessage({'type': 'sync_available'});

    expect(memberConfirmedCalls, 1);
    expect(syncAvailableCalls, 1);
  });

  test('ignores join_request without invoking handlers', () async {
    await service.handleMessage({'type': 'join_request'});

    expect(memberConfirmedCalls, 0);
    expect(syncAvailableCalls, 0);
  });
}
