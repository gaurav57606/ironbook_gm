import "package:flutter/foundation.dart";
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';
import '../router/app_router.dart';
import 'logger_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static ProviderContainer? _container;
  static String? _pendingPayload;

  @visibleForTesting
  static void setPlugin(FlutterLocalNotificationsPlugin plugin) => _plugin.runtimeType; // Mocking helper if needed

  static Future<void> init(ProviderContainer container) async {
    _container = container;
    final logger = container.read(loggerProvider);
    
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(android: android, iOS: ios);
      
      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onTap,
      );

      // Process any pending payload from cold start
      if (_pendingPayload != null) {
        logger.info('Processing pending cold-start payload', category: 'NOTIFICATION');
        final payload = _pendingPayload!;
        _pendingPayload = null;
        _handlePayload(payload);
      }
    } catch (e, stack) {
      logger.error('Failed to initialize local notifications', category: 'NOTIFICATION', error: e, stackTrace: stack);
    }
  }

  static void _onTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    if (_container == null) {
      // We can't log to loggerProvider if container is null, 
      // but we should avoid debugPrint if possible. 
      // However, in this static context without container, debugPrint is the only way.
      debugPrint('[NOTIFICATION] App not yet initialized. Queueing payload.');
      _pendingPayload = payload;
      return;
    }

    final logger = _container!.read(loggerProvider);
    logger.debug('Tap received with payload: $payload', category: 'NOTIFICATION');

    _handlePayload(payload);
  }

  static void _handlePayload(String payload) {
    if (_container == null) return;
    final logger = _container!.read(loggerProvider);

    try {
      if (payload.startsWith('member:')) {
        final parts = payload.split(':');
        if (parts.length < 2) {
          logger.warn('Invalid notification payload format: $payload', category: 'NOTIFICATION');
          return;
        }

        final memberId = parts[1];
        final router = _container?.read(routerProvider(true));
        
        if (router == null) {
          logger.warn('Router not ready. Re-queueing notification payload.', category: 'NOTIFICATION');
          _pendingPayload = payload;
          return;
        }

        logger.info('Navigating to member details from notification: $memberId', category: 'NAV');
        router.push('/gym/member-details/$memberId');
      }
    } catch (e, stack) {
      logger.error('Error handling notification payload: $payload', category: 'NOTIFICATION', error: e, stackTrace: stack);
    }
  }

  static Future<void> sendMemberAlert({
    required MemberSnapshot snapshot,
    required String dedupKey,
    DateTime? now,
  }) async {
    try {
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
        payload: 'member:${snapshot.memberId}',
      );
    } catch (e) {
      if (_container != null) {
        _container!.read(loggerProvider).error('Failed to send local notification alert', category: 'NOTIFICATION', error: e);
      }
    }
  }
}
