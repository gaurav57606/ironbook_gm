import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'data/local/hive_init.dart';
import 'data/local/adapters/manual_adapters.dart';
import 'core/services/fcm_service.dart';
import 'core/services/hmac_service.dart';
import 'core/services/notification_service.dart';
import 'app.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Midnight engine logic
    return true;
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase Initialisation
  await Firebase.initializeApp();
  
  // 2. FCM & Notifications
  await FcmService.init();
  await HmacService.init();
  await NotificationService.init();
  
  // FCM Handlers
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  
  FirebaseMessaging.onMessage.listen(FcmService.processKillSignal);
  
  FirebaseMessaging.instance.getInitialMessage().then((msg) {
    if (msg != null) FcmService.processKillSignal(msg);
  });

  // 3. Hive Initialisation with Models
  await Hive.initFlutter();
  
  // Register all adapters
  Hive.registerAdapter(DomainEventAdapter());
  Hive.registerAdapter(MemberSnapshotAdapter());
  Hive.registerAdapter(PaymentAdapter());
  Hive.registerAdapter(PlanAdapter());
  Hive.registerAdapter(PlanComponentAdapter());
  Hive.registerAdapter(OwnerProfileAdapter());
  Hive.registerAdapter(AppSettingsAdapter());
  Hive.registerAdapter(JoinDateChangeAdapter());
  Hive.registerAdapter(PlanComponentSnapshotAdapter());
  Hive.registerAdapter(InvoiceSequenceAdapter());

  // Check Hive Health
  final hiveHealthy = await HiveInit.openWithCorruptionGuard();

  // 4. Background Job Initialisation - Android Only
  if (!kIsWeb) {
    Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    Workmanager().registerPeriodicTask(
      'midnight_engine',
      'midnightTask',
      frequency: const Duration(hours: 24),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  runApp(
    ProviderScope(
      child: IronBookApp(hiveHealthy: hiveHealthy),
    ),
  );
}

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  FcmService.processKillSignal(message);
}
