import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(initSettings);
  }

  static Future<void> sendMemberAlert({
    required MemberSnapshot snapshot,
    required String dedupKey,
    DateTime? now,
  }) async {
    final now0 = now ?? DateTime.now();
    final notifId = dedupKey.hashCode.abs();
    await _plugin.cancel(notifId);

    final title = snapshot.getStatus(now0) == MemberStatus.expired
        ? '${snapshot.name} — Membership Expired'
        : '${snapshot.name} — Expiring in ${snapshot.getDaysRemaining(now0)} days';

    const androidDetails = AndroidNotificationDetails(
      'member_alerts',
      'Member Alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      notifId,
      title,
      'Tap to view member details',
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }
}









