import "package:flutter/foundation.dart";
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';
import '../router/app_router.dart';
import '../providers/base_providers.dart';
import '../data/local/drift/outbox_database.dart';
import 'logger_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static ProviderContainer? _container;
  static String? _pendingPayload;

  static Future<void> init(ProviderContainer container) async {
    _container = container;
    final logger = container.read(loggerProvider);
    final gateway = container.read(notificationGatewayProvider);
    
    try {
      await gateway.init(_onTap);

      // Process any pending payload from cold start
      if (_pendingPayload != null) {
        logger.info('Processing pending cold-start payload', category: 'NOTIFICATION');
        final payload = _pendingPayload!;
        _pendingPayload = null;
        handlePayload(payload);
      }
    } catch (e, stack) {
      logger.error('Failed to initialize local notifications', category: 'NOTIFICATION', error: e, stackTrace: stack);
    }
  }

  static Future<void> _onTap(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    if (_container == null) {
      debugPrint('[NOTIFICATION] App not yet initialized. Queueing payload.');
      _pendingPayload = payload;
      return;
    }

    final logger = _container!.read(loggerProvider);
    logger.debug('Tap received with payload: $payload', category: 'NOTIFICATION');

    handlePayload(payload);
  }

  static void handlePayload(String payload) {
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
        router.push('/members/member-details/$memberId');
      } else if (payload == 'sync') {
        final router = _container?.read(routerProvider(true));
        if (router == null) {
          _pendingPayload = payload;
          return;
        }
        logger.info('Navigating to backup settings from sync notification', category: 'NAV');
        router.push('/settings/backup');
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
    if (_container == null) return;
    
    final gateway = _container!.read(notificationGatewayProvider);
    final logger = _container!.read(loggerProvider);

    try {
      final now0 = now ?? DateTime.now();
      final notifId = dedupKey.hashCode.abs();
      await gateway.cancel(notifId);

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

      await gateway.show(
        notifId,
        title,
        'Tap to view member details',
        payload: 'member:${snapshot.memberId}',
        androidDetails: androidDetails,
        iosDetails: iosDetails,
      );

      // Persistence (Audit Check 5.1)
      final repo = _container!.read(outboxRepositoryProvider);
      await repo.insertNotification(Notification(
        id: dedupKey,
        title: title,
        body: 'Tap to view member details',
        timestamp: now0,
        category: 'Reminder',
        isRead: false,
        payload: 'member:${snapshot.memberId}',
      ));

      // ── Dispatch to Firestore events collection for Cloud Function fan-out ──
      try {
        final db = _container!.read(outboxDatabaseProvider);
        final ownerProfile = await (db.select(db.ownerProfiles)).getSingleOrNull();
        if (ownerProfile != null) {
          final gymId = ownerProfile.gymName;
          await FirebaseFirestore.instance
              .collection('gyms')
              .doc(gymId)
              .collection('events')
              .add({
                'title': title,
                'body': 'Tap to view member details',
                'category': 'expiry_reminder',
                'payload': {'memberId': snapshot.memberId},
                'createdAt': FieldValue.serverTimestamp(),
              });
          logger.info('FCM alert dispatched to Firestore for member ${snapshot.name}', category: 'NOTIFICATION');
        }
      } catch (fcmErr) {
        logger.warn('Failed to dispatch FCM cloud event: $fcmErr', category: 'NOTIFICATION');
      }
    } catch (e) {
      logger.error('Failed to send local notification alert', category: 'NOTIFICATION', error: e);
    }
  }

  static Future<void> sendNewMemberAlert({
    required String memberId,
    required String name,
    required String planName,
  }) async {
    final title = 'New Member Joined';
    final body = '$name has joined with $planName plan.';
    await sendGenericNotification(
      title: title,
      body: body,
      category: 'System',
      dedupKey: 'new_member_$memberId',
      payload: 'member:$memberId',
    );

    // ── Dispatch to Firestore events collection for Cloud Function fan-out ──
    if (_container != null) {
      try {
        final db = _container!.read(outboxDatabaseProvider);
        final ownerProfile = await (db.select(db.ownerProfiles)).getSingleOrNull();
        if (ownerProfile != null) {
          final gymId = ownerProfile.gymName;
          await FirebaseFirestore.instance
              .collection('gyms')
              .doc(gymId)
              .collection('events')
              .add({
                'title': title,
                'body': body,
                'category': 'new_member',
                'payload': {'memberId': memberId},
                'createdAt': FieldValue.serverTimestamp(),
              });
        }
      } catch (e) {
        _container!.read(loggerProvider).warn('Failed to sync new member event to Firestore: $e', category: 'NOTIFICATION');
      }
    }
  }

  static Future<void> dispatchGymNotification({
    required String title,
    required String body,
    required String category,
    String? payload,
  }) async {
    final dedupKey = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    await sendGenericNotification(
      title: title,
      body: body,
      category: category,
      dedupKey: dedupKey,
      payload: payload,
    );

    if (_container != null) {
      try {
        final db = _container!.read(outboxDatabaseProvider);
        final ownerProfile = await (db.select(db.ownerProfiles)).getSingleOrNull();
        if (ownerProfile != null) {
          final gymId = ownerProfile.gymName;
          await FirebaseFirestore.instance
              .collection('gyms')
              .doc(gymId)
              .collection('events')
              .add({
                'title': title,
                'body': body,
                'category': category,
                'payload': {'payload': payload},
                'createdAt': FieldValue.serverTimestamp(),
              });
        }
      } catch (e) {
        _container!.read(loggerProvider).warn('Failed to dispatch cloud notification event to Firestore: $e', category: 'NOTIFICATION');
      }
    }
  }

  static Future<void> sendSyncAlert({
    required String error,
  }) async {
    await sendGenericNotification(
      title: 'Cloud Sync Issue',
      body: 'Sync is currently unavailable. Tap to check backup settings.',
      category: 'System',
      dedupKey: 'sync_failure_alert',
      payload: 'sync',
    );
  }

  static Future<void> sendGenericNotification({
    required String title,
    required String body,
    required String category,
    required String dedupKey,
    String? payload,
    DateTime? timestamp,
  }) async {
    if (_container == null) return;
    
    final gateway = _container!.read(notificationGatewayProvider);
    final logger = _container!.read(loggerProvider);

    try {
      final now = timestamp ?? DateTime.now();
      final notifId = dedupKey.hashCode.abs();
      
      const androidDetails = AndroidNotificationDetails(
        'system_alerts',
        'System Alerts',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
      const iosDetails = DarwinNotificationDetails();

      await gateway.show(
        notifId,
        title,
        body,
        payload: payload,
        androidDetails: androidDetails,
        iosDetails: iosDetails,
      );

      final repo = _container!.read(outboxRepositoryProvider);
      await repo.insertNotification(Notification(
        id: dedupKey,
        title: title,
        body: body,
        timestamp: now,
        category: category,
        isRead: false,
        payload: payload,
      ));
    } catch (e) {
      logger.error('Failed to send generic notification', category: 'NOTIFICATION', error: e);
    }
  }

  static Future<void> markAsRead(String id) async {
    if (_container == null) return;
    final repo = _container!.read(outboxRepositoryProvider);
    await repo.markNotificationAsRead(id);
  }

  static Future<void> markAllAsRead() async {
    if (_container == null) return;
    final repo = _container!.read(outboxRepositoryProvider);
    await repo.markAllNotificationsAsRead();
  }
}
