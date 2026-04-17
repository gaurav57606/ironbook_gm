import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_flutter/hive_flutter.dart';
// Background worker logic moved to dedicated file for mobile-only use

import 'data/local/hive_init.dart';
import 'data/local/adapters/manual_adapters.dart';
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

  // Set consistent system overlays
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  debugPrint('--- APP STARTING ---');

  try {
    // 1. Firebase Initialisation (Bypassed on Web for Audit)
    if (!kIsWeb) {
      debugPrint('Init: Firebase...');
      await Firebase.initializeApp().timeout(const Duration(seconds: 30));

      // 2. FCM & Notifications
      debugPrint('Init: FCM/Notifications...');
      await FcmService.init().timeout(const Duration(seconds: 20));
      await HmacService.init().timeout(const Duration(seconds: 20));
      await NotificationService.init().timeout(const Duration(seconds: 20));

      // Handlers are correctly registered inside FcmService.init()
      debugPrint('Init: Security/Auth services ready');
    } else {
      debugPrint('Init: Skipping Firebase/FCM on Web for Visual Audit');
    }

    debugPrint('Init: Step 3 starting...');

    // 3. Hive Initialisation with Models
    bool hiveHealthy = true;
    debugPrint('Init: Hive...');
    await Hive.initFlutter().timeout(const Duration(seconds: 5),
        onTimeout: () => debugPrint('Hive.init timeout'));

    // Register all adapters
    debugPrint('Init: Registering Hive Adapters...');
    HiveInit.registerAdapters();

    debugPrint('Init: Opening Hive boxes...');
    // Check Hive Health
    hiveHealthy = await HiveInit.openWithCorruptionGuard()
        .timeout(const Duration(seconds: 15), onTimeout: () {
      debugPrint('Hive Boxes timeout - defaulting to unhealthy');
      return false;
    });

    debugPrint('Init: hiveHealthy result: $hiveHealthy');
    
    // 3.1. Seed Data if empty
    if (hiveHealthy) {
        debugPrint('Init: Seeding data if empty...');
        await SeedData.seedIfEmpty();
    }

    // 4. Background Job Initialisation - Mobile Only
    if (!kIsWeb) {
      debugPrint('Init: Mobile background tasks...');
      await Workmanager().initialize(
        MidnightEngine.callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
      
      await Workmanager().registerPeriodicTask(
        "1", 
        "midnightTask", 
        frequency: const Duration(hours: 12), // Minimum 15 mins, using 12h for production efficiency
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
      );
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
    runApp(MaterialApp(
        home: Scaffold(body: Center(child: Text('Init Error: $e')))));
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  FcmService.processKillSignal(message);
}
