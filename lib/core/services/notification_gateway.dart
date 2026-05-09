import 'package:flutter_local_notifications/flutter_local_notifications.dart';

abstract class NotificationGateway {
  Future<void> init(Future<void> Function(NotificationResponse) onTap);
  Future<void> show(
    int id,
    String title,
    String body, {
    String? payload,
    AndroidNotificationDetails? androidDetails,
    DarwinNotificationDetails? iosDetails,
  });
  Future<void> cancel(int id);
}

class FlutterLocalNotificationGateway implements NotificationGateway {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  @override
  Future<void> init(Future<void> Function(NotificationResponse) onTap) async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(initSettings, onDidReceiveNotificationResponse: onTap);
  }

  @override
  Future<void> show(
    int id,
    String title,
    String body, {
    String? payload,
    AndroidNotificationDetails? androidDetails,
    DarwinNotificationDetails? iosDetails,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }
}
