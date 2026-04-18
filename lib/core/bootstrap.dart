import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:workmanager/workmanager.dart';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/local/hive_init.dart';
import '../data/seed_data.dart';
import '../data/local/drift/outbox_database.dart';
import '../data/local/drift/outbox_repository.dart';
import '../data/local/drift/hive_to_drift_migration.dart';
import '../data/sync_worker.dart';
import '../providers/bootstrap_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/base_providers.dart';
import 'services/fcm_service.dart';
import 'services/hmac_service.dart';
import 'services/notification_service.dart';
import '../sync/midnight_engine.dart';

typedef BootstrapResult = ({bool hiveHealthy});

class AppBootstrap {
  static Future<BootstrapResult> initialize(ProviderContainer container) async {
    // --- TIER 1 (Blocking) ---
    WidgetsFlutterBinding.ensureInitialized();
    
    // 1. System UI
    _setupSystemUI();
    
    // 2. Hive Initialization
    debugPrint('Bootstrap Tier 1: Hive...');
    await HiveInit.openWithCorruptionGuard(); // This registers adapters too
    final hiveHealthy = Hive.isBoxOpen('events'); // Basic health check
    
    if (hiveHealthy) {
      await SeedData.seedIfEmpty();
    }
    
    // 3. Drift Initialization
    debugPrint('Bootstrap Tier 1: Drift...');
    container.read(outboxDatabaseProvider);
    
    // 4. Branding Delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Update State to Tier 1 Ready
    container.read(bootstrapStateProvider.notifier).state = BootstrapPhase.tier1Ready;
    
    // Schedule TIER 2
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _runTier2(container);
    });
    
    return (hiveHealthy: hiveHealthy);
  }

  static void _setupSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  static Future<void> _runTier2(ProviderContainer container) async {
    debugPrint('Bootstrap Tier 2: Starting...');
    
    try {
      // 1. Firebase (Web Bypassed)
      if (!kIsWeb) {
        debugPrint('Bootstrap Tier 2: Firebase...');
        await Firebase.initializeApp().timeout(const Duration(seconds: 30));
        
        // Notify AuthNotifier that Firebase is ready
        final auth = FirebaseAuth.instance;
        container.read(authProvider.notifier).onFirebaseReady(auth);
        
        debugPrint('Bootstrap Tier 2: FCM & Services...');
        await FcmService.init().timeout(const Duration(seconds: 20));
        await HmacService.init().timeout(const Duration(seconds: 20));
        await NotificationService.init().timeout(const Duration(seconds: 20));
        
        // 2. Background Tasks
        debugPrint('Bootstrap Tier 2: Workmanager...');
        await Workmanager().initialize(
          MidnightEngine.callbackDispatcher,
          isInDebugMode: kDebugMode,
        );
        await Workmanager().registerPeriodicTask(
          "1",
          "midnightTask",
          frequency: const Duration(hours: 12),
        );
      }

      // 3. Migration (Hive -> Drift)
      debugPrint('Bootstrap Tier 2: Migration...');
      final outboxRepo = container.read(outboxRepositoryProvider);
      await HiveToDriftMigration.runIfNeeded(outboxRepo);
      
      // 4. Start Sync Worker
      debugPrint('Bootstrap Tier 2: SyncWorker...');
      container.read(syncWorkerProvider).startPeriodicSync(const Duration(seconds: 30));

      container.read(bootstrapStateProvider.notifier).state = BootstrapPhase.tier2Ready;
      debugPrint('Bootstrap Tier 2: Complete.');
      
    } catch (e, stack) {
      debugPrint('Bootstrap Tier 2 Error: $e');
      debugPrint(stack.toString());
      container.read(bootstrapStateProvider.notifier).state = BootstrapPhase.tier2Degraded;
    }
  }
}
