import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
import 'data/local/models/member_snapshot_model.dart';
import 'app.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == 'midnightTask') {
        debugPrint('--- MIDNIGHT ENGINE STARTING ---');
        // 1. Initialize Hive
        await Hive.initFlutter();
        
        // 2. Open necessary boxes
        if (!Hive.isBoxOpen('snapshots')) {
          await Hive.openBox<MemberSnapshot>('snapshots');
        }
        
        final snapshotsBox = Hive.box<MemberSnapshot>('snapshots');
        final now = DateTime.now();
        
        for (final member in snapshotsBox.values) {
          final status = member.getStatus(now);
          if (status == MemberStatus.expiring || status == MemberStatus.expired) {
            await NotificationService.sendMemberAlert(
              snapshot: member,
              dedupKey: 'midnight_${member.memberId}_${now.day}',
              now: now,
            );
          }
        }
        debugPrint('--- MIDNIGHT ENGINE COMPLETE ---');
      }
      return true;
    } catch (e) {
      debugPrint('MIDNIGHT ENGINE ERROR: $e');
      return false;
    }
  });
}

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
      await Firebase.initializeApp().timeout(const Duration(seconds: 10));

      // 2. FCM & Notifications
      debugPrint('Init: FCM/Notifications...');
      await FcmService.init().timeout(const Duration(seconds: 5));
      await HmacService.init().timeout(const Duration(seconds: 5));
      await NotificationService.init().timeout(const Duration(seconds: 5));

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      FirebaseMessaging.onMessage.listen(FcmService.processKillSignal);
      FirebaseMessaging.instance.getInitialMessage().then((msg) {
        if (msg != null) FcmService.processKillSignal(msg);
      });
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
    Hive.registerAdapter(ProductAdapter());
    Hive.registerAdapter(SaleAdapter());
    Hive.registerAdapter(SaleItemAdapter());

    debugPrint('Init: Opening Hive boxes...');
    // Check Hive Health
    hiveHealthy = await HiveInit.openWithCorruptionGuard()
        .timeout(const Duration(seconds: 15), onTimeout: () {
      debugPrint('Hive Boxes timeout - defaulting to unhealthy');
      return false;
    });

    debugPrint('Init: hiveHealthy result: $hiveHealthy');

    // 4. Background Job Initialisation - Android Only
    if (!kIsWeb) {
      debugPrint('Init: Workmanager...');
      Workmanager().initialize(callbackDispatcher);
      Workmanager().registerPeriodicTask(
        'midnight_engine',
        'midnightTask',
        frequency: const Duration(hours: 24),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
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
