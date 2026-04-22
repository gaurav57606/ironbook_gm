import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';
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
    // --- TIER 1 (Blocking: Native/Local) ---
    // Note: WidgetsFlutterBinding.ensureInitialized() called in main()
    
    // 1. System UI Setup
    _setupSystemUI();
    
    // 2. Open Local Authorities (Hive)
    debugPrint('Bootstrap Tier 1: Hive Initialization...');
    await HiveInit.openWithCorruptionGuard();
    final hiveHealthy = Hive.isBoxOpen('events');
    
    if (hiveHealthy) {
      await SeedData.seedIfEmpty();
    }
    
    // 3. Open Secondary Authorities (Drift/SQLite)
    debugPrint('Bootstrap Tier 1: Drift Initialization...');
    container.read(outboxDatabaseProvider);
    
    // 4. Set Initial State
    container.read(bootstrapStateProvider.notifier).state = BootstrapPhase.tier1Ready;
    
    // Schedule TIER 2 (Post-Frame: Cloud/Background)
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
    container.read(tier2StatusProvider.notifier).state = Tier2Status.pending;
    
    try {
      // 1. Firebase & Cloud Services (Web Bypassed) with 10s global timeout
      if (!kIsWeb) {
        debugPrint('Bootstrap Tier 2: Cloud Services (10s timeout)...');
        
        await Future.wait([
          Firebase.initializeApp(),
          FcmService.init(),
          HmacService.init(),
          NotificationService.init(),
        ]).timeout(const Duration(seconds: 10));

        // Notify AuthNotifier that Firebase is ready
        final auth = FirebaseAuth.instance;
        container.read(authProvider.notifier).onFirebaseReady(auth);
        
        // 2. Background Tasks (Doesn't block 'ready' state if slightly slower)
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

      // Successfully ready
      container.read(tier2StatusProvider.notifier).state = Tier2Status.ready;
      container.read(bootstrapStateProvider.notifier).state = BootstrapPhase.tier2Ready;
      debugPrint('Bootstrap Tier 2: Complete.');
      
    } catch (e, stack) {
      debugPrint('Bootstrap Tier 2 (Degraded): $e');
      if (e is TimeoutException) {
        debugPrint('Bootstrap Tier 2: Cloud services timed out after 10s.');
      }
      
      container.read(tier2StatusProvider.notifier).state = Tier2Status.degraded;
      container.read(bootstrapStateProvider.notifier).state = BootstrapPhase.tier2Degraded;
      
      // Still attempt to start local services even if cloud timed out
      try {
        final outboxRepo = container.read(outboxRepositoryProvider);
        await HiveToDriftMigration.runIfNeeded(outboxRepo);
        container.read(syncWorkerProvider).startPeriodicSync(const Duration(seconds: 30));
      } catch (_) {}
    }
  }
}
