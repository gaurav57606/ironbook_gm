import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> init() async {
    // 1. Request Permissions (Required for Android 13+)
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permissions');
      
      // 2. Get Token for backend targeting
      final token = await messaging.getToken();
      debugPrint('FCM Token: $token');
    } else {
      debugPrint('User declined or has not yet granted notification permissions');
    }

    // 3. Foreground
    FirebaseMessaging.onMessage.listen(processKillSignal);

    // 4. Background (handled by top-level function)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 5. Terminated
    final initial = await messaging.getInitialMessage();
    if (initial != null) await processKillSignal(initial);
  }

  static Future<void> processKillSignal(RemoteMessage message) async {
    await _processKillSignalInternal(message);
    
    if (message.data['action'] == 'block_access') {
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/paywall', (_) => false);
    }
  }
}











