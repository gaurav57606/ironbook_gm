import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/bootstrap.dart';
import 'core/services/fcm_service.dart';
import 'app.dart';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

void main() async {
  // 1. Core Binding
  WidgetsFlutterBinding.ensureInitialized();

  // Register FCM background handler BEFORE any Firebase init
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // 2. Provider Container
  final container = ProviderContainer();
  
  // 3. Tier 1 Initialization (Hive/Drift) - Fast & Blocking
  final result = await AppBootstrap.initialize(container);

  // 4. Global Error Handling (Production Hardening)
  if (!kIsWeb) {
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // 5. Run App (Spawns Router -> Splash)
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: IronBookApp(hiveHealthy: result.hiveHealthy),
    ),
  );
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  FcmService.processKillSignal(message);
}







