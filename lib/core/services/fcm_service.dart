import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../router/app_router.dart';
import 'notification_service.dart';

// Top-level handler for background/terminated messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await _processKillSignalInternal(message);
}

Future<void> _processKillSignalInternal(RemoteMessage message) async {
  if (message.data['action'] != 'block_access') return;

  const storage = FlutterSecureStorage();
  await storage.delete(key: 'ent_expiry');
  await storage.delete(key: 'ent_cached_at');
}

class FcmService {
  static ProviderContainer? _container;

  static Future<void> init(ProviderContainer container) async {
    _container = container;
    
    // 1. Request Permissions (Required for Android 13+)
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (!kReleaseMode) {
        debugPrint('[FCM] User granted notification permissions');
        
        // 2. Get Token for backend targeting
        final token = await messaging.getToken();
        debugPrint('[FCM] Token retrieved successfully.');
      }
    }

    // 3. Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await processKillSignal(message);
      
      final notification = message.notification;
      if (notification != null) {
        final title = notification.title ?? '';
        final body = notification.body ?? '';
        final category = message.data['category'] ?? 'general';
        final payload = message.data['payload'];
        
        await NotificationService.sendGenericNotification(
          title: title,
          body: body,
          category: category,
          dedupKey: 'fcm_${message.messageId ?? DateTime.now().millisecondsSinceEpoch}',
          payload: payload,
        );
      }
    });

    // 4. Background (handled by top-level function)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 5. Terminated
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      await processKillSignal(initial);
      
      final notification = initial.notification;
      if (notification != null) {
        final title = notification.title ?? '';
        final body = notification.body ?? '';
        final category = initial.data['category'] ?? 'general';
        final payload = initial.data['payload'];
        
        await NotificationService.sendGenericNotification(
          title: title,
          body: body,
          category: category,
          dedupKey: 'fcm_${initial.messageId ?? DateTime.now().millisecondsSinceEpoch}',
          payload: payload,
        );
      }
    }

    // 6. Notification Tap Handling
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final payload = message.data['payload'];
      if (payload != null && payload.isNotEmpty) {
        NotificationService._handlePayload(payload);
      }
    });
  }

  static Future<void> processKillSignal(RemoteMessage message) async {
    await _processKillSignalInternal(message);
    
    if (message.data['action'] == 'block_access') {
      debugPrint('[FCM] Block access signal received. Redirecting to paywall.');
      // routerProvider(true) is used as fallback for storageHealthy
      final router = _container?.read(routerProvider(true));
      router?.go('/paywall');
    }
  }
}
