import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../data/local/models/member_snapshot_model.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);
    await _plugin.initialize(initSettings);
  }

  static Future<void> sendMemberAlert({
    required MemberSnapshot snapshot,
    required String dedupKey,
  }) async {
    final notifId = dedupKey.hashCode.abs();
    await _plugin.cancel(notifId);

    final title = snapshot.status == MemberStatus.expired
        ? '${snapshot.name} — Membership Expired'
        : '${snapshot.name} — Expiring in ${snapshot.daysRemaining} days';

    const androidDetails = AndroidNotificationDetails(
      'member_alerts',
      'Member Alerts',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _plugin.show(
      notifId,
      title,
      'Tap to view member details',
      const NotificationDetails(android: androidDetails),
    );
  }
}
