import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_flutter/hive_flutter.dart';
// Background worker logic moved to dedicated file for mobile-only use

import 'data/local/hive_init.dart';
import 'core/services/fcm_service.dart';
import 'core/services/hmac_service.dart';
import 'core/services/notification_service.dart';
import 'package:workmanager/workmanager.dart';
import 'sync/midnight_engine.dart';
import 'data/seed_data.dart';
import 'app.dart';

// Background worker logic moved to dedicated file for mobile-only use

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _setupSystemUI();

  debugPrint('--- APP STARTING ---');

  try {
    if (!kIsWeb) {
      await _initFirebaseAndServices();
    } else {
      debugPrint('Init: Skipping Firebase/FCM on Web for Visual Audit');
    }

    final hiveHealthy = await _initHive();

    if (hiveHealthy) {
      debugPrint('Init: Seeding data if empty...');
      await SeedData.seedIfEmpty();
    }

    if (!kIsWeb) {
      await _initBackgroundTasks();
    }

    debugPrint('Init: runApp starting...');
    runApp(
      ProviderScope(
        child: IronBookApp(hiveHealthy: hiveHealthy),
      ),
    );
  } catch (e, stack) {
    debugPrint('CRITICAL INIT ERROR: $e');
    debugPrint(stack.toString());
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Init Error: $e'),
          ),
        ),
      ),
    );
  }
}

void _setupSystemUI() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
}

Future<void> _initFirebaseAndServices() async {
  debugPrint('Init: Firebase...');
  await Firebase.initializeApp().timeout(const Duration(seconds: 30));

  debugPrint('Init: FCM/Notifications...');
  await FcmService.init().timeout(const Duration(seconds: 20));
  await HmacService.init().timeout(const Duration(seconds: 20));
  await NotificationService.init().timeout(const Duration(seconds: 20));

  debugPrint('Init: Security/Auth services ready');
}

Future<bool> _initHive() async {
  debugPrint('Init: Hive...');
  await Hive.initFlutter().timeout(
    const Duration(seconds: 5),
    onTimeout: () => debugPrint('Hive.init timeout'),
  );

  debugPrint('Init: Registering Hive Adapters...');
  HiveInit.registerAdapters();

  debugPrint('Init: Opening Hive boxes...');
  final hiveHealthy = await HiveInit.openWithCorruptionGuard().timeout(
    const Duration(seconds: 15),
    onTimeout: () {
      debugPrint('Hive Boxes timeout - defaulting to unhealthy');
      return false;
    },
  );

  debugPrint('Init: hiveHealthy result: $hiveHealthy');
  return hiveHealthy;
}

Future<void> _initBackgroundTasks() async {
  debugPrint('Init: Mobile background tasks...');
  await Workmanager().initialize(
    MidnightEngine.callbackDispatcher,
    isInDebugMode: kDebugMode,
  );

  await Workmanager().registerPeriodicTask(
    "1",
    "midnightTask",
    frequency: const Duration(hours: 12),
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: true,
    ),
  );
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  FcmService.processKillSignal(message);
}
