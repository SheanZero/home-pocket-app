import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/listen_to_push_notifications_use_case.dart';
import 'package:home_pocket/infrastructure/sync/push_notification_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockPushNotificationService extends Mock
    implements PushNotificationService {}

void main() {
  late _MockPushNotificationService mockService;
  late ListenToPushNotificationsUseCase useCase;

  setUp(() {
    mockService = _MockPushNotificationService();
    useCase = ListenToPushNotificationsUseCase(service: mockService);
  });

  group('ListenToPushNotificationsUseCase', () {
    test('execute() returns the navigationIntents stream from service', () {
      final fakeStream = const Stream<PushNavigationIntent>.empty();
      when(() => mockService.navigationIntents).thenAnswer((_) => fakeStream);

      final result = useCase.execute();

      expect(result, same(fakeStream));
    });

    test(
      'takePendingIntent delegates to service.takePendingNavigationIntent',
      () {
        const intent = PushNavigationIntent.memberApproval(groupId: 'g1');
        when(
          () => mockService.takePendingNavigationIntent(),
        ).thenReturn(intent);

        final result = useCase.takePendingIntent();

        expect(result, same(intent));
        verify(() => mockService.takePendingNavigationIntent()).called(1);
      },
    );

    test('takePendingIntent returns null when no pending intent', () {
      when(() => mockService.takePendingNavigationIntent()).thenReturn(null);

      final result = useCase.takePendingIntent();

      expect(result, isNull);
    });

    test('registerHandlers delegates to service', () {
      when(
        () => mockService.registerHandlers(
          onMemberConfirmed: any(named: 'onMemberConfirmed'),
          onSyncAvailable: any(named: 'onSyncAvailable'),
          onJoinRequest: any(named: 'onJoinRequest'),
          onMemberLeft: any(named: 'onMemberLeft'),
          onGroupDissolved: any(named: 'onGroupDissolved'),
        ),
      ).thenReturn(null);

      useCase.registerHandlers(onJoinRequest: (_) async {});

      verify(
        () => mockService.registerHandlers(
          onMemberConfirmed: any(named: 'onMemberConfirmed'),
          onSyncAvailable: any(named: 'onSyncAvailable'),
          onJoinRequest: any(named: 'onJoinRequest'),
          onMemberLeft: any(named: 'onMemberLeft'),
          onGroupDissolved: any(named: 'onGroupDissolved'),
        ),
      ).called(1);
    });
  });
}
