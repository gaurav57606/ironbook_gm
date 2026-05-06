import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:workmanager/workmanager.dart';

import '../firebase_options.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:ironbook_gm/core/data/local/hive_init.dart';
import 'package:ironbook_gm/core/data/seed_data.dart';
import 'package:ironbook_gm/core/data/local/drift/hive_to_drift_migration.dart';
import 'package:ironbook_gm/core/data/sync_worker.dart';
import 'package:ironbook_gm/core/providers/bootstrap_provider.dart';
import 'package:ironbook_gm/core/providers/auth_provider.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';
import 'services/fcm_service.dart';
import 'services/hmac_service.dart';
import 'services/notification_service.dart';
import 'services/config_service.dart';
import 'services/logger_service.dart';
import 'package:ironbook_gm/core/sync/midnight_engine.dart';

typedef BootstrapResult = ({bool hiveHealthy});

class AppBootstrap {
  static Future<BootstrapResult> initialize(ProviderContainer container) async {
    // --- TIER 1 (Blocking: Native/Local) ---
    // Note: WidgetsFlutterBinding.ensureInitialized() called in main()
    
    // 1. Core Config & Local Engine
    await container.read(configServiceProvider).init();
    await Hive.initFlutter();
    
    // 2. System UI Setup
    _setupSystemUI();
    
    // 2. Open Local Authorities (Hive)
    final logger = container.read(loggerProvider);
    logger.info('Bootstrap Tier 1: Hive Initialization...');
    await HiveInit.openWithCorruptionGuard();
    await HmacService.init(); // Initialize HMAC key early for signing
    final hiveHealthy = Hive.isBoxOpen('events');
    
    // 3. Open Secondary Authorities (Drift/SQLite)
    logger.info('Bootstrap Tier 1: Drift Initialization...');
    try {
      container.read(outboxDatabaseProvider);
    } catch (e) {
      logger.error('Bootstrap Tier 1: Drift Initialization FAILED', e);
    }
    
    if (hiveHealthy) {
      await SeedData.seedIfEmpty(container);
    }
    
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
      // 1. Firebase & Cloud Services (Unified Platform Config)
      debugPrint('Bootstrap Tier 2: Cloud Services...');
      
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 10));

        await Future.wait([
          if (!kIsWeb) FcmService.init(),
          if (!kIsWeb) NotificationService.init(),
        ]).timeout(const Duration(seconds: 10));

        // Notify AuthNotifier that Firebase is ready
        final auth = FirebaseAuth.instance;
        container.read(authProvider.notifier).onFirebaseReady(auth);
      } catch (e) {
        debugPrint('Firebase Tier 2 Warning: Cloud initialization failed or timed out: $e');
        // We continue anyway to allow "Audit/Offline Mode"
      }

      // 2. Background Tasks (Native Only)
      if (!kIsWeb) {
        debugPrint('Bootstrap Tier 2: Workmanager...');
        try {
          await Workmanager().initialize(
            MidnightEngine.callbackDispatcher,
          );
          await Workmanager().registerPeriodicTask(
            "1",
            "midnightTask",
            frequency: const Duration(hours: 12),
          );
        } catch (e) {
          debugPrint('Workmanager Init Failed: $e');
        }
      }

      // 3. Migration (Hive -> Drift)
      debugPrint('Bootstrap Tier 2: Migration...');
      final outboxRepo = container.read(outboxRepositoryProvider);
      await HiveToDriftMigration.runIfNeeded(outboxRepo);
      
      // 4. Reconciliation (Drift -> Hive)
      debugPrint('Bootstrap Tier 2: Reconciliation...');
      final unsyncedInDrift = await outboxRepo.getUnsyncedEvents();
      if (unsyncedInDrift.isNotEmpty) {
        final hiveRepo = container.read(eventRepositoryProvider);
        int reconciledCount = 0;
        for (final event in unsyncedInDrift) {
          final existing = await hiveRepo.getById(event.id);
          if (existing == null) {
            await hiveRepo.persistSynced(event); // Copy to Hive
            reconciledCount++;
          }
        }
        if (reconciledCount > 0) {
          debugPrint('Bootstrap Tier 2: Reconciled $reconciledCount missing events from Drift to Hive.');
        }
      }
      
      // 5. Start Sync Worker
      debugPrint('Bootstrap Tier 2: SyncWorker...');
      container.read(syncWorkerProvider).startPeriodicSync(const Duration(seconds: 30));

      // Successfully ready
      container.read(tier2StatusProvider.notifier).state = Tier2Status.ready;
      container.read(bootstrapStateProvider.notifier).state = BootstrapPhase.tier2Ready;
      debugPrint('Bootstrap Tier 2: Complete.');
      
    } catch (e) {
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











