import 'package:mocktail/mocktail.dart';
import 'package:ironbook_gm/core/services/notification_gateway.dart';

class MockNotificationGateway extends Mock implements NotificationGateway {}

MockNotificationGateway createMockNotificationGateway() {
  final gateway = MockNotificationGateway();
  when(() => gateway.init(any())).thenAnswer((_) async => {});
  when(() => gateway.show(any(), any(), any(), 
      payload: any(named: 'payload'),
      androidDetails: any(named: 'androidDetails'),
      iosDetails: any(named: 'iosDetails')))
      .thenAnswer((_) async => {});
  when(() => gateway.cancel(any())).thenAnswer((_) async => {});
  return gateway;
}
