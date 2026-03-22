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
    // 1. Foreground
    FirebaseMessaging.onMessage.listen(processKillSignal);

    // 2. Background (handled by top-level function)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 3. Terminated
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) await processKillSignal(initial);
  }

  static Future<void> processKillSignal(RemoteMessage message) async {
    await _processKillSignalInternal(message);
    
    if (message.data['action'] == 'block_access') {
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/paywall', (_) => false);
    }
  }
}
