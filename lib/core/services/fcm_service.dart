import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:meta/meta.dart';

// Top-level handler for background/terminated messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await FcmService.processKillSignal(message);
}

Future<void> _processKillSignalInternal(RemoteMessage message, {FlutterSecureStorage? storage}) async {
  if (message.data['action'] != 'block_access') return;

  final secureStorage = storage ?? const FlutterSecureStorage();
  await secureStorage.delete(key: 'ent_expiry');
  await secureStorage.delete(key: 'ent_cached_at');
}

class FcmService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> init({FirebaseMessaging? messaging}) async {
    // 1. Request Permissions (Required for Android 13+)
    final fcm = messaging ?? FirebaseMessaging.instance;
    final settings = await fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permissions');
      
      // 2. Get Token for backend targeting
      final token = await fcm.getToken();
      debugPrint('FCM Token: $token');
    } else {
      debugPrint('User declined or has not yet granted notification permissions');
    }

    // 3. Foreground
    FirebaseMessaging.onMessage.listen((message) => processKillSignal(message));

    // 4. Background (handled by top-level function)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 5. Terminated
    final initial = await fcm.getInitialMessage();
    if (initial != null) await processKillSignal(initial);
  }

  static Future<void> processKillSignal(RemoteMessage message, {NavigatorState? navigator, FlutterSecureStorage? storage}) async {
    await _processKillSignalInternal(message, storage: storage);
    
    if (message.data['action'] == 'block_access') {
      final nav = navigator ?? navigatorKey.currentState;
      nav?.pushNamedAndRemoveUntil('/paywall', (_) => false);
    }
  }
}
