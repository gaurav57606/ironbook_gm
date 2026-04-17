import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ironbook_gm/core/services/notification_service.dart';
import 'package:ironbook_gm/data/local/models/member_snapshot_model.dart';

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

void main() {
  late MockFlutterLocalNotificationsPlugin mockPlugin;

  setUpAll(() {
    registerFallbackValue(const InitializationSettings(
      android: AndroidInitializationSettings(''),
      iOS: DarwinInitializationSettings(),
    ));
    registerFallbackValue(const NotificationDetails());
  });

  setUp(() {
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    NotificationService.setPlugin(mockPlugin);

    when(() => mockPlugin.initialize(any(),
            onDidReceiveNotificationResponse: any(named: 'onDidReceiveNotificationResponse'),
            onDidReceiveBackgroundNotificationResponse: any(named: 'onDidReceiveBackgroundNotificationResponse')))
        .thenAnswer((_) async => true);

    when(() => mockPlugin.cancel(any())).thenAnswer((_) async => {});

    when(() => mockPlugin.show(
          any(),
          any(),
          any(),
          any(),
          payload: any(named: 'payload'),
        )).thenAnswer((_) async => {});
  });

  group('NotificationService', () {
    test('init calls initialize on plugin', () async {
      await NotificationService.init();

      verify(() => mockPlugin.initialize(
            any(),
            onDidReceiveNotificationResponse: any(named: 'onDidReceiveNotificationResponse'),
            onDidReceiveBackgroundNotificationResponse: any(named: 'onDidReceiveBackgroundNotificationResponse'),
          )).called(1);
    });

    test('sendMemberAlert sends correct notification for expired member', () async {
      final now = DateTime(2024, 1, 10);
      final snapshot = MemberSnapshot(
        memberId: 'm1',
        name: 'John Doe',
        joinDate: DateTime(2024, 1, 1),
        expiryDate: DateTime(2024, 1, 9), // Expired
      );

      await NotificationService.sendMemberAlert(
        snapshot: snapshot,
        dedupKey: 'm1_key',
        now: now,
      );

      final expectedId = 'm1_key'.hashCode.abs();
      verify(() => mockPlugin.cancel(expectedId)).called(1);
      verify(() => mockPlugin.show(
            expectedId,
            'John Doe — Membership Expired',
            'Tap to view member details',
            any(),
          )).called(1);
    });

    test('sendMemberAlert sends correct notification for expiring member', () async {
      final now = DateTime(2024, 1, 10);
      final snapshot = MemberSnapshot(
        memberId: 'm1',
        name: 'Jane Doe',
        joinDate: DateTime(2024, 1, 1),
        expiryDate: DateTime(2024, 1, 15), // Expiring in 5 days
      );

      await NotificationService.sendMemberAlert(
        snapshot: snapshot,
        dedupKey: 'm1_key',
        now: now,
      );

      final expectedId = 'm1_key'.hashCode.abs();
      verify(() => mockPlugin.show(
            expectedId,
            'Jane Doe — Expiring in 5 days',
            'Tap to view member details',
            any(),
          )).called(1);
    });
  });
}
